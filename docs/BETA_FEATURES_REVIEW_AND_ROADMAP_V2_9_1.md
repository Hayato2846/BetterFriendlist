# Beta Features: Review und Roadmap für v2.9.1

Stand: 25. September 2026
Branch/Worktree: `v2.9.1`
Retail-Referenz: `wow-ui-source-live`, Branch `live`, Build `12.1.0.69933`, Commit `09b9db794`
UI-Referenz: lokales EnhanceQoL `13.3.3`, Interface `120100`
LibSettingsDesigner: Upstream `0ca7ccebfa7220b3b8972d4c8da035e2b6cafe35`

## Kurzfassung

BFL hat aktuell drei echte Beta-Bereiche:

1. **New Settings Center**: eigener Schalter `enableSettingsCenterBeta`; unabhängig vom globalen Beta-Schalter.
2. **QuickFilter & Sorter Editor**: über `enableBetaFeatures` sichtbar.
3. **Guild Roster Tab**: über `enableBetaFeatures` und `enableGuildTab` sichtbar; nur auf Clients mit passender Guild-Roster-Fähigkeit.

`Debug Prints` liegt zwar auf der Beta-Seite, ist aber ein Diagnosewerkzeug und kein Produkt-Feature. Private Notes, Friend Tags, Theme Customization, Global Sync, Data Broker und External AddOn Menu Bridge sind stabile Funktionen.

## 1. New Settings Center

### Erkenntnisse aus EnhanceQoL

Der auffällig andere Darstellungsmodus von EnhanceQoL entsteht nicht durch einen eigenen Settings-Renderer, sondern durch die neueren Layout-Fähigkeiten von LibSettingsDesigner:

- direkte Feature- und Seitennavigation statt einer zusätzlichen Kategorie-Zwischenebene;
- kompakte Matrix-Zeilen mit Beschriftung links und Control rechts;
- standardmäßig zwei Control-Spalten;
- Seiten ohne zusätzliche rechte Detailspalte;
- thematisierte Dropdowns und Eingabefelder;
- feststehende Gruppen-/Tab-Navigation auf langen Seiten.

EnhanceQoL vendort exakt den geprüften aktuellen Upstream der Library. BFL verwendete zuvor einen Stand vom Juni 2026 und hatte nur eine kleine lokale Erweiterung für dauerhaft sichtbare, farbige Beschreibungstexte.

### In v2.9.1 umgesetzt

- LibSettingsDesigner auf `0ca7cce` aktualisiert, einschließlich Attribution und Superellipse-Asset.
- Direkte Feature-Navigation und Sidebar-Suche aktiviert.
- Matrix-Zeilen, zweispaltige Controls sowie thematisierte Dropdowns und Inputs aktiviert.
- BFLs umschaltbare Dichte bleibt erhalten; EnhanceQoL erzwingt dagegen dauerhaft `compact`.
- `Advanced > Tools` verwendet bewusst weiterhin beschreibende Standardzeilen. Dadurch bleibt der rote Hinweis der External AddOn Menu Bridge unter der deaktivierten Checkbox sichtbar.
- BFL-spezifische Logik verbleibt außerhalb der Library. Die einzige vendoring-nahe Erweiterung bleibt die generische Unterstützung für `alwaysShowDescription` und `descriptionColor`.

### Empfehlung zur Stabilisierung

Der Settings Center sollte nach einer gezielten visuellen QA aus dem Beta-Status herausgenommen werden. Vorher sollten folgende Abnahmepunkte erfüllt sein:

- alle Seiten in `compact` und `comfortable` bei minimaler und maximaler Fenstergröße prüfen;
- Matrix-Zeilen mit langen deutschen, französischen, russischen, koreanischen und chinesischen Labels prüfen;
- Custom Pages für QuickFilter, Global Sync, Friend Tags und Friends UI kontrollieren;
- Blizzard-, Dark-, Custom-, ElvUI- und EllesmereUI-Skin jeweils öffnen, Theme live wechseln und anschließend auf Blizzard zurückschalten;
- Suchtreffer, New-Tags, Dashboard-Navigation, Zurück-Navigation und Reload-Hinweis prüfen;
- External Menu Bridge mit geladenem, deaktiviertem und fehlendem Companion-AddOn prüfen.

Nach erfolgreicher QA ist die bevorzugte Migration:

1. `enableSettingsCenterBeta` für bestehende Profile respektieren, aber für neue Profile standardmäßig aktivieren.
2. Einen Release später den Legacy-Dialog nur noch als Fallback anbieten.
3. Nach einer weiteren Release-Periode Legacy-UI und doppelten Settings-Code entfernen.

## 2. QuickFilter & Sorter

### Aktuelle Probleme

Die Datenbasis ist bereits leistungsfähig: Filter unterstützen verschachtelte AND/OR-Gruppen, Negation und typisierte Operatoren; Sorter unterstützen mehrstufige Ketten, Richtung und Leerwertbehandlung. Die UI bildet diese Fähigkeiten jedoch zu technisch und zu dicht ab:

- Manager und Editor wirken wie zwei lose zusammengesetzte Werkzeuge.
- Controls besitzen starre, sehr schmale Breiten; Feld, Operator und Wert konkurrieren in einer Zeile.
- `Up`, `Down`, `not` und `X` dominieren die Oberfläche stärker als der eigentliche Regelausdruck.
- Änderungen werden sofort gespeichert und lösen häufig einen vollständigen Neuaufbau des Editors aus.
- Es gibt keinen klaren Draft-/Dirty-State, keine Undo-Möglichkeit und keine zusammengefasste Validierung.
- Die Vorschau zeigt zwar Trefferzahlen beziehungsweise kann den Sorter live anwenden, erklärt aber nicht, *warum* ein Kontakt passt oder an welcher Sortierstufe zwei Einträge getrennt werden.
- Built-ins, Kopien, deaktivierte Einträge und benutzerdefinierte Einträge sind visuell nur schwach unterscheidbar.

### Zielbild

Empfohlen wird ein eigenständiger, full-width **Filter & Sort Studio** als Custom Page:

#### A. Manager

- Kopfzeile mit Segmenten `QuickFilters` und `Sorter`, Suche sowie primärem `Neu`-Button.
- Linke Inventarliste mit Icon, Name, Typ-Badge (`Built-in`, `Custom`, `Hidden`), Sichtbarkeitsschalter und Drag Handle.
- Kontextaktionen über ein dezentes Drei-Punkte-Menü: Duplizieren, Umbenennen, Exportieren, Zurücksetzen/Löschen.
- Built-ins werden nicht wie löschbare Datensätze dargestellt; `Reset` und `Duplizieren` sind klar getrennt.
- Leere Zustände und Vorlagen werden als verständliche Startpunkte angeboten.

#### B. QuickFilter-Editor

- Regeln als lesbare Satzbausteine: **Feld – Operator – Wert**, nicht als Sammlung gleichgewichteter Mini-Buttons.
- AND/OR-Gruppen als Karten mit farbigem linken Gruppenindikator und eingerückten Kindregeln.
- `NOT` als klarer Negationsschalter mit vollständigem Text, nicht als wechselndes `not/NOT`-Kürzel.
- Drag-and-drop innerhalb einer Gruppe; Verschieben in andere Gruppen über Drag-Ziel oder Kontextaktion.
- `Regel hinzufügen` und `Gruppe hinzufügen` am Ende der jeweiligen Gruppe.
- Inline-Validierung für leere Werte, unzulässige Operatoren und unerreichbare/kontradiktorische Regeln.
- Eine automatisch erzeugte Zusammenfassung in Alltagssprache oberhalb des Builders.

#### C. Sorter-Editor

- Sortierkette als nummerierte, per Drag Handle sortierbare Karten.
- Jede Stufe zeigt Feld, Auf-/Ab-Richtung und Leerwerte kompakt, aber mit vollständigen Bezeichnungen.
- Warnung bei doppelten oder wirkungslosen Sortierstufen.
- Primär- und Tie-Breaker-Wirkung werden in einer kleinen Beispielansicht sichtbar gemacht.

#### D. Vorschau und Speichern

- Rechter beziehungsweise unterer Preview-Bereich mit Trefferzahl und bis zu 20 realen, anonymisierbaren Beispielzeilen.
- Bei Filtern kann eine Zeile anzeigen, welche Regelgruppen erfüllt oder nicht erfüllt wurden.
- Bei Sortern kann die maßgebliche Sortierstufe pro Übergang hervorgehoben werden.
- Änderungen erfolgen in einem Draft. `Speichern`, `Verwerfen` und `Zurücksetzen` sind explizit.
- Ein kleiner Undo/Redo-Stack deckt die aktuelle Bearbeitungssitzung ab.
- `Live anwenden` bleibt optional und darf den vor dem Preview aktiven Filter/Sorter zuverlässig wiederherstellen.

### Technische Struktur

Der heutige Editor liegt größtenteils in `Modules/Settings.lua` und baut bei vielen Änderungen alle Frames neu auf. Für die Neugestaltung sollte er in ein eigenes Modul verschoben werden, beispielsweise `Modules/FilterSortEditor.lua`:

- `FilterSortRegistry` bleibt alleiniger Besitzer von Schema, Normalisierung und Persistenz.
- `FilterSortEditor` hält Draft, Auswahl, Validierungsfehler, Undo/Redo und Preview-State.
- Kleine Renderer für Managerzeile, Regelgruppe, Bedingungszeile, Sortierstufe und Preview vermeiden eine monolithische Refresh-Funktion.
- Unveränderte Frames werden aktualisiert statt zerstört und neu aufgebaut.
- Persistenz erfolgt erst bei `Speichern`; Migrationen der vorhandenen SavedVariables sind nicht nötig.

### Umsetzungsphasen

1. **State und Modulgrenze**: Draft-Modell, Validator, Undo/Redo und Preview isolieren; vorhandene UI zunächst weiterverwenden.
2. **Manager neu bauen**: Inventarliste, Suche, Badges, Sichtbarkeit und sichere Aktionen.
3. **QuickFilter-Builder neu bauen**: Gruppen-/Regelkarten, Drag-and-drop, Validierung und Zusammenfassung.
4. **Sorter neu bauen**: Sortierkarten, Duplikatwarnungen und Beispielsortierung.
5. **Polish und QA**: Tastaturfokus, Tooltips, alle Locales, beide Dichten, Theme-Wechsel, große Datenmengen und Classic-Fallback.

### Abnahmekriterien

- Kein Datenverlust bei Öffnen, Abbrechen, Speichern, Duplizieren oder Löschen.
- Bestehende Filter-ASTs und Sortierketten bleiben ohne Migration verwendbar.
- Kein vollständiger Seiten-Rebuild bei jeder einzelnen Werteingabe.
- Alle Aktionen sind bei 100 %, 125 % und 150 % UI-Skalierung ohne Überlappung erreichbar.
- Bedienung bleibt mit langen Locale-Strings und ohne Maus möglich.
- Preview verändert die aktive Friendlist nur auf ausdrückliche Anforderung und stellt den vorherigen Zustand vollständig wieder her.

## 3. Guild Roster

### API- und Taint-Ergebnis

In `GuildInfoDocumentation.lua` ist keine der geprüften Guild-Funktionen als `Protected = true` markiert. Mehrere schreibende APIs besitzen jedoch `HasRestrictions = true` und/oder `SecretArguments = "AllowedWhenUntainted"`. Das ist nicht dasselbe wie eine Protected Function, verlangt aber eine strikte Verwendung:

- nur aus einem direkten Benutzer-Klick;
- keine Ausführung im Combat Lockdown oder während aktiver AddOn-Restrictions;
- Namen, GUIDs, Club- und Member-IDs ausschließlich aus unveränderten Blizzard-Rosterdaten;
- Berechtigungen unmittelbar vor der Aktion erneut prüfen;
- optionale und Flavor-abhängige APIs capability-basiert prüfen;
- keine Hooks, Attribute oder Frame-Veränderungen an geschützten Blizzard-Controls.

| API/Quelle | Sinnvolle Nutzung in BFL | Bewertung |
|---|---|---|
| `C_Club.GetGuildClubId`, `GetClubMembers`, `GetMemberInfo` | GUID, Member-ID, Präsenz, Berufe, Notizen und Rank-Metadaten auflösen | Read-only; nicht protected. In Chat-Messaging-Lockdowns können Werte secret werden, daher weiterhin `pcall`/Secret-Guards. |
| `C_GuildInfo.GuildRoster`, `CanViewOfficerNote`, `CanEditOfficerNote`, `IsGuildRankAssignmentAllowed` | Roster aktualisieren und UI anhand realer Rechte aufbauen | Nicht protected; capability- und permission-basiert verwenden. |
| `C_GuildInfo.SetGuildRankOrder`, `SetNote`, `RemoveFromGuild` | Rang, öffentliche/Officer-Notiz und Entfernen | Restricted, aber nicht protected. Am sichersten über Blizzards eigene Member-Detail-UI. |
| `C_GuildInfo.Promote`, `Demote`, `Uninvite`, `SetLeader` | bestehende Verwaltungsaktionen | Secret arguments nur untainted; BFL prüft Rechte und AddOn-Restrictions und fordert Bestätigung an. |
| `C_FriendList.AddFriend`, `AddOrDelIgnore` | Charakterfreund hinzufügen, ignorieren/entfernen | Restricted beziehungsweise untainted arguments; ausschließlich aus dem Kontextmenü und außerhalb eingeschränkter Zustände. |
| `Blizzard_Communities` Member Detail | Notizen und Rang über Blizzard-UI bearbeiten | Bevorzugter Weg: BFL öffnet die native Oberfläche und verändert keine geschützten Frames. |
| `Blizzard_HouseList` / `HouseListFrame:InitWithContextData` | Häuser eines Gildenmitglieds anzeigen | Retail-12.1-Feature; nur anzeigen, wenn die Oberfläche/API tatsächlich vorhanden ist. |
| `C_GuildInfo.QueryGuildMemberRecipes` | Rezepte eines Mitglieds zu einem Beruf laden | Nicht protected; geeignet für einen späteren Beruf-/Rezept-Finder mit Event- und Cache-Steuerung. |
| `C_GuildInfo.GetGuildNewsInfo` | kompakte Gilden-News oder Aktivitätsübersicht | Read-only und geeignet für eine optionale Infofläche; Secret-Werte weiter defensiv behandeln. |

`TargetUnit` wurde bewusst nicht ergänzt. Blizzard zeigt diese Aktion nur in einem sicheren Kontext und außerhalb von Combat Lockdown; eine eigene BFL-Schaltfläche würde keinen verlässlichen taintfreien Mehrwert bieten.

### In v2.9.1 umgesetztes Kontextmenü

Die redundante `Who`-Aktion wurde entfernt. Das Menü bietet nun capability-basiert:

- Whisper und Gruppeneinladung;
- Charakterfreund hinzufügen;
- Ignorieren beziehungsweise Ignorieren entfernen;
- native Blizzard-Mitgliedsdetails öffnen, einschließlich der dort erlaubten Notiz- und Rangfunktionen;
- Häuser anzeigen, wenn Retail die 12.1-Housing-Oberfläche bereitstellt;
- BFL-Nickname setzen, Namen kopieren;
- Befördern, Degradieren, aus der Gilde entfernen und Gildenleitung übertragen, sofern erlaubt.

### In v2.9.1 ergänzte Ausbaustufen

Die vorgeschlagenen Ausbaustufen wurden als gemeinsame, capability-basierte Werkzeugleiste innerhalb der Rosterfläche umgesetzt:

1. **Berufsmodus und Berufsfilter**
   - `ClubMemberInfo.profession1/2*` wird nur bei aktivierter Option aus `C_Club` gelesen und für zehn Sekunden im gemeinsamen Roster-Provider gecacht.
   - Der Berufsfilter zeigt ausschließlich Mitglieder des gewählten Berufs und stellt Berufsname und Rang in der sekundären Zeile dar.
   - Das Zeilenwerkzeug sowie das Kontextmenü lösen `C_GuildInfo.QueryGuildMemberRecipes` ausschließlich nach einem direkten Benutzer-Klick aus. Es gibt keine automatische Rezeptabfrage.
2. **Native Mitgliedsdetails**
   - Jede Zeile besitzt ein dezentes Info-Icon.
   - Ein optionaler Doppelklick öffnet dieselbe native `Blizzard_Communities`-Mitgliedsdetailfläche wie das Kontextmenü.
   - BFL verändert keine Secure-Attribute und implementiert keine eigene Schreiboberfläche für Rang oder Notizen.
3. **Ereignisgesteuerte Gilden-News-Karte**
   - Die Karte ist standardmäßig deaktiviert und kann in den Guild-Einstellungen aktiviert werden.
   - Beim ersten Öffnen wird genau eine `QueryGuildNews`-Anforderung ausgelöst; danach reagiert BFL auf `GUILD_NEWS_UPDATE`.
   - Eine erneute Anfrage erfolgt ausschließlich über den News-Button. Es existiert kein Timer und kein Hintergrund-Polling.
4. **MOTD-/Info-Header**
   - Die vorhandene MOTD bleibt Teil des kompakten Guild-Headers.
   - Das Info-Icon liest `C_GuildInfo.GetInfoText` erst beim Aufklappen der Info-Karte und zeigt höchstens zwei Zeilen in der Rosterfläche.
5. **Kontextsensitive Aktionen**
   - Whisper und Gruppeneinladung bleiben auf tatsächlich online verfügbare Mitglieder begrenzt.
   - Freund-, Ignore-, Housing-, Rezept- und Verwaltungsaktionen erscheinen nur bei passender API-, Daten- und Berechtigungsfähigkeit.
   - Die redundante native Mitgliedsdetailaktion entfällt; die vorhandenen Mitgliedsinformationen bleiben direkt im Tooltip sichtbar.

Persistente Optionen:

- `guildTabEnableProfessions = false`
- `guildTabShowNews = false`

Nicht empfohlen und weiterhin bewusst nicht umgesetzt sind eigene Target-/Focus-Aktionen, Secure-Button-Attribute, automatische Verwaltungsaktionen oder Hooks in Blizzards UnitPopup- und Communities-Frames.

## 4. Bereinigung veralteter Beta-Verweise

In v2.9.1 bereinigt:

- XML-Kommentare für Friend Tags, Private Notes und Global Sync bezeichnen diese Funktionen nicht mehr als Beta.
- Der veraltete ElvUI-Kommentar stellt Global Sync nicht mehr in einen Beta-Kontext.
- die ungenutzten Locale-Keys `SETTINGS_BETA_FEATURE_THEME_CUSTOMIZATION` und `SETTINGS_BETA_FEATURE_THEME_CUSTOMIZATION_DESC` wurden in allen Locales entfernt;
- der nach Entfernung der Aktion ungenutzte Locale-Key `GUILD_BROKER_MENU_WHO` wurde in allen Locales entfernt.

Die verbleibenden Beta-Texte beziehen sich weiterhin korrekt auf New Settings Center, QuickFilter & Sorter sowie Guild Roster.
