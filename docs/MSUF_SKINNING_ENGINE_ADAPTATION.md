# MSUF-Skinning-Analyse und BFL-Adaption

Stand: 2026-09-25
Zielversion: BetterFriendlist 2.9.1

## Referenz und Lizenzgrenze

Analysiert wurde `MSUF_Suite (2).zip` aus dem Download-Verzeichnis (SHA-256: `66F1D724B92C3EB6338222C99C8293F98C3218A9C02B1A61BB7F9426D030A286`), insbesondere das enthaltene AddOn `MSUF_Suite_Skin` in Version `6.5-beta6`.

Der MSUF-Code und seine Assets sind mit „All rights reserved“ und einer Einschränkung auf private Nutzung versehen. Deshalb wurden weder Quellcode noch Assets übernommen. Die BFL-Umsetzung ist eine eigenständige Implementierung der beobachteten Architekturprinzipien.

## Architekturvergleich

| Bereich | MSUF Suite Skin | BFL vor der Adaption | BFL 2.9.1 |
|---|---|---|---|
| Zielerfassung | Explizite Adapter und geprüfte Control-Verträge | Explizite BFL-Pfade plus generische `SkinTree`-Erkennung | Bestehende Erfassung bleibt für den Erstaufbau; Repaints verwenden gebundene Renderer |
| Zustände | Schwache Target-Registries, Owner-Zuordnung | Reversible Zustände direkt am Frame, starke zentrale Registry | Reversible Zustände bleiben; zentrale Registry und Token-Consumer verwenden schwache Schlüssel |
| Theme-Abhängigkeiten | Semantische Tokens mit gezielten Consumern | Globale Farbversion; Theme-Reapply konnte bekannte Frame-Bäume erneut durchlaufen | Renderer deklarieren ihre Tokens; nur abhängige Targets werden aktualisiert |
| Rendering | Regionen einmal erzeugen/erfassen, danach direkte Referenzen lackieren | Gute Snapshot- und Region-Caches, aber Reapply über höhere Skin-Funktionen | Stabile Token-Tabellen plus direkte Renderer-Callbacks auf den bereits bekannten Targets |
| Aktualisierung | Ereignis- und Callback-gesteuert | Hooks vorhanden, Theme-Änderungen jedoch mit breiterem Reapply | Interaktions-Hooks bleiben; reine Palettenänderungen überspringen den vollständigen DarkTheme-Pass |
| Aufräumen | Owner-scoped Enable/Disable | Globales `RestoreAll` und einzelnes `RestoreFrame` | Zusätzlich owner-scoped Renderer-Freigabe; Restore entfernt alle Abhängigkeiten |
| Blizzard-Restore | Kontrollspezifische native Snapshots | Umfassende reversible Property-Snapshots | Unverändert beibehalten und in den neuen Lifecycle integriert |

## Übernommene Prinzipien

### 1. Semantischer Renderer-Graph

`SkinEngine:RegisterRenderer(target, key, tokens, refresh, owner, spec)` bindet einen kleinen Renderer an ein konkretes Ziel. Jeder Renderer nennt ausschließlich die Theme-Tokens, von denen seine Ausgabe abhängt. `RefreshToken` und `RefreshTokens` bilden daraus eine deduplizierte Target-Menge und führen nur passende Renderer aus.

Mehrere Renderer desselben Targets behalten ihre Registrierungsreihenfolge. Dadurch kann zuerst die Basissurface und danach der zustandsabhängige Button- oder Row-Renderer lackieren.

### 2. Schwache Registries und Owner-Lifecycle

Frame-Registry, Token-Consumer und Owner-Target-Mengen verwenden schwache Schlüssel. Nicht mehr referenzierte UI-Objekte werden damit nicht allein durch die SkinEngine am Leben gehalten.

`ReleaseRendererOwner(owner, restoreFrames)` entfernt ausschließlich Renderer eines Besitzers. Der bestehende vollständige Blizzard-Restore bleibt über `RestoreFrame` und `RestoreAll` verfügbar und räumt nun zugleich Token- und Owner-Mitgliedschaften auf.

### 3. Stabile Theme-Tokens

Die Einträge in `SkinEngine.colors` behalten ihre Tabellenidentität. Ein Theme-Refresh schreibt neue RGBA-Werte in die vorhandenen Token-Tabellen, statt sie zu ersetzen. Bereits gebundene Renderzustände können deshalb sichere Referenzen auf semantische Farben behalten.

Der Backdrop-Paint-Cache speichert demgegenüber Wert-Snapshots. So erkennt er eine Änderung trotz stabiler Token-Referenz und vermeidet gleichzeitig redundante `SetBackdropColor`-Aufrufe.

### 4. Gezielte Repaints

Token-Renderer sind für folgende bestehende Primitiven gebunden:

- Backdrop-Varianten und deren Zierlinien
- Buttons, Tabs, Navigation, Icon- und Pfeilbuttons
- Checkboxes
- Dropdown-Indikatoren und geöffnete Custom-Dropdown-Menüs
- Scrollbar-Thumbs und Slider
- Friend-/Listenzeilen einschließlich ihrer Invite-Actions
- Frame-Titel und Control-Labels

Reine Dark-/Custom-Palettenänderungen aktualisieren diese gebundenen Targets und überspringen `DarkTheme:SkinKnownFrames`. Erstaktivierung, Theme-Wechsel und strukturelle Reapply-Gründe verwenden weiterhin den vollständigen Erfassungspfad.

## Bewusst beibehaltene BFL-Eigenschaften

- Alle bisherigen reversiblen Snapshots für Alpha, Desaturation, Vertex-Farben, Blend-Modi, Fonts, Punkte, Größen, Sichtbarkeit und native Backdrops bleiben erhalten.
- Retail-, Classic- und Forever-Pfade verwenden weiterhin dieselben öffentlichen Skin-Primitiven.
- `SkinTree` bleibt als kompatibler Erstaufbau- und Fallback-Mechanismus bestehen. Die Optimierung betrifft die wiederkehrende Theme-Lackierung, nicht die sichere Erkennung neu erzeugter Controls.
- Interaktionszustände wie Hover, Pressed, Disabled, Selected und Scroll-Dragging werden beim Token-Repaint erneut aus dem gespeicherten Zustand abgeleitet.
- Es gibt weder einen permanenten `OnUpdate` noch einen globalen Frame-Scan für Farbänderungen.

## Performance-Auswirkung

Die Komplexität einer Palettenänderung richtet sich nun nach der Zahl der Consumer der tatsächlich geänderten Tokens. Unabhängige Controls werden nicht aufgerufen, Targets mit mehreren passenden Tokens werden pro Refresh nur einmal besucht, und ihre Renderer greifen auf bereits bekannte Regionen und Zustände zu.

Der vollständige Frame-Pass bleibt absichtlich für strukturelle Änderungen erhalten. Damit wird der häufige Pfad (Farb- und Opacity-Regler sowie Reset einer Palette) beschleunigt, ohne die Robustheit bei dynamisch erzeugten Blizzard- oder BFL-Frames zu reduzieren.

## Erweiterungsregel für neue Themes und Controls

Neue Skin-Primitiven sollen beim Erstaufbau einen benannten Renderer registrieren, eine möglichst kleine Token-Liste deklarieren und im Refresh ausschließlich bereits bekannte Objekte lackieren. Strukturfindung, Hooks und Snapshot-Erfassung gehören in den einmaligen Apply-Pfad; Farbschreibzugriffe gehören in den Renderer. Ein Owner sollte verwendet werden, wenn ein Modul seine Renderer unabhängig freigeben können muss.

## Verifikation

Die Testsuite enthält einen neuen Datenvertrag für:

- schwache Frame-Registrierung,
- token-genaue Target-Auswahl,
- stabile Renderer-Reihenfolge,
- deduplizierte Target-Refreshes und
- owner-scoped Freigabe.

Zusätzlich bleiben die bestehenden Tests für Backdrop-Reparatur, Desaturation-Cache, Disabled-Button-Alpha und vollständige Blizzard-Wiederherstellung maßgeblich.
