# Who: Prüfung der UI-Erreichbarkeit und Testanleitung

Diese Anleitung gehört zum Branch `codex/who-regressions` mit der vorbereiteten Version 3.1.4 auf Basis von 3.1.3. Die Worktree-Version ist 3.1.4; es wurde noch keine neue Version veröffentlicht.

## Ergebnis der erneuten Prüfung

Zwei Who-Änderungen beheben Fehler, für die ein vollständiger normaler UI-Einstieg im Quellcode und im Test nachgewiesen wurde: die Classic-Sortierung über Name, Level und Klasse sowie das Überschreiben des Suchfelds bei abgewiesenem `/who` auf Retail/Forever. Die anderen drei Änderungen bleiben interne bzw. defensive Korrekturen; sie stehen nicht mehr im öffentlichen Draft-Changelog.

| Änderung | Tatsächlicher Einstieg | Bewertung |
| --- | --- | --- |
| Classic behält die Sortierung | Klick auf Name, Level oder Klasse; Tabwechsel; Enter oder Aktualisieren und eine neue Antwort. | Normaler UI-Fehler, über die ausgelieferten Header- und Sichtbarkeitsskripte vor/nach dem Fix nachgestellt. |
| Suchfeld bei schnellem `/who` | Zwei normale `/who`-Eingaben innerhalb der lokalen Fünf-Sekunden-Sperre. | Normal erreichbarer Fehler auf Retail und Forever, über den installierten Slashhandler vor/nach dem Fix nachgestellt. Die Sperre selbst bleibt bestehen. |
| Verborgene Antworten mit gleicher Trefferzahl | Der bisherige Test injiziert eine externe Antwort in eine bereits gefüllte, verborgene Liste. | Kein normaler BFL-UI-Fehler für die geprüften Enter-/Button-Abläufe nachgewiesen. Diese leeren die alte Liste bereits vor dem Senden. Defensive Korrektur; kein öffentlicher Fix-Eintrag. |
| Alte sortierte Zeilen nach externen Nulltreffern | Der bisherige Test injiziert eine externe Nullantwort, ohne BFLs Suchstart zu durchlaufen. | Kein Fehler der geprüften eigenen BFL-Suchen: Auch hier leert der Suchstart vorher. Ein natürlicher Einstieg für externe Abfragen existiert über Shift-Linksklick im Chat; ob dabei die benötigte Nullantwort als `WHO_LIST_UPDATE` ankommt, ist nicht live nachgewiesen. Daher derzeit kein öffentlicher Fix-Eintrag. |
| Gildensortierfeld | Nur ein direkter Aufruf von `SortByColumn("guild")`. | Kein normaler UI-Einstieg. Das Dropdown ändert nur die angezeigte Spalte. Die interne Feldkorrektur ergänzt keine bedienbare Gildensortierung. |

Das Vorhandensein eines fehlerhaften internen Zweigs allein belegt keinen Nutzerfehler. Die Testauswertung unterscheidet deshalb normale UI-Pfade, Kontrollen unveränderten Verhaltens und künstlich eingespeiste Zustände. Eine Ursache der ursprünglichen beiden Who-Meldungen ist weiterhin nicht belegt.

## Quellstände und Grenzen

Geprüft wurden diese lokalen Blizzard-Quellen:

| Client | Quellbranch | Build |
| --- | --- | --- |
| Retail | live | 12.1.5.70783 |
| Forever | forever | 1.60.1.70888 |
| Classic Progression | classic | 5.5.4.70631 |
| Classic Era | classic_era | 1.15.9.70576 |
| Anniversary | classic_anniversary | 2.5.6.70577 |

Die zuvor bereitgestellte CleanCopy enthielt die Runtime-Korrekturen auf allen zehn lokalen Clients; die Dateihashes wurden verglichen. Die erneute Prüfung ändert die Testabdeckung und die Dokumentation, nicht die Runtime-Logik. Der synchronisierte Ingame-Changelog enthält die eingegrenzten Aussagen im Worktree.

Die beschriebenen Vorher-/Nachher-Nachweise führen produktive Lua- und XML-Skripte mit simulierten Client-APIs und Widgets aus. Sie belegen keine echten Serverantworten, Hardwarefreigaben oder Taint-Sicherheit. Die folgende manuelle Prüfung übernimmt der Maintainer im echten Client.

## Vorbereitung

1. Den bereitgestellten Fix-Stand verwenden und `/reload` ausführen.
2. Client, tatsächlichen Build, BFL-Darstellung und Sprache notieren. Auf Retail/Forever die angebotenen Modern- und Legacy-Darstellungen berücksichtigen.
3. Zunächst außerhalb des Kampfes testen. Zwischen unabhängigen Suchanfragen mindestens zehn Sekunden warten. Nur T2 unterschreitet die Sperre absichtlich.
4. Den vorhandenen Fehlerlogger verwenden. Alternativ lassen sich Lua-Fehler mit `/console scriptErrors 1` anzeigen; eine zuvor abweichende Einstellung danach wiederherstellen.
5. Eine bereits funktionierende Suche und für Sortiertests mehrere Ergebnisse mit unterschiedlichen Namen bzw. Werten verwenden. Es müssen keine Freunde hinzugefügt oder Nachrichten gesendet werden.

Eine ausbleibende Serverantwort ist keine bestätigte Nullantwort. Bei Timeout oder Drosselung den Fall offen lassen und erst nach mindestens zehn Sekunden erneut versuchen.

## T1: Normale BFL-Suche als Kontrolle

Auf Retail, Forever, Classic Progression, Era und Anniversary:

1. BetterFriendlist öffnen und Who auswählen.
2. Eine bereits funktionierende Suche direkt in das BFL-Suchfeld eingeben und Enter drücken. Die Antwort abwarten.
3. Nach der Wartezeit mit dem Aktualisieren-Button wiederholen.
4. Einen eindeutigen Fantasienamen suchen, für den der Server null Treffer zurückliefert, und danach wieder die erfolgreiche Suche ausführen.
5. Zusätzlich eine Suche starten, nach dem Suchstart auf Kontakte wechseln und nach der Antwort zu Who zurückkehren. Bei Aktualisieren zunächst die kurze automatische Rückkehr zu Who abwarten, bevor zu Kontakte gewechselt wird.

Erwartet: Die angezeigten Daten entsprechen den Antworten. Eine echte Nullantwort entfernt die Zeilen; eine folgende erfolgreiche Suche funktioniert wieder. Nach einem verborgenen Antwortempfang erscheinen die neuen Ergebnisse.

Dieser Ablauf ist eine Kontrolle, kein Nachweis der zuvor behaupteten Ergebnislisten-Bugs. In den Gegenproben bestehen die eigenen Enter- und Aktualisieren-Abläufe bereits mit dem ursprünglichen 3.1.3-Code. Der Suchstart ruft `ShowPendingState()` auf und entfernt alte Zeilen, bevor die Antwort verarbeitet wird.

## T2: Suchfeld bei zwei schnellen /who-Eingaben

Gezielter UI-Regressionstest auf Retail und Forever. Die folgenden beiden Suchtexte sind absichtlich direkt verwendbare Levelbereiche, keine Namensplatzhalter:

1. Mindestens zehn Sekunden warten.
2. `/who 1-10` eingeben.
3. Innerhalb von ein bis zwei Sekunden `/who 20-30` eingeben.
4. Den Text im BFL-Who-Suchfeld prüfen.
5. Mindestens fünf Sekunden seit Schritt 2 verstreichen lassen, ohne erneut zu suchen.
6. `/who 20-30` nochmals eingeben.

Erwartet mit Fix: Schritt 3 wird durch die bestehende Sperre abgewiesen und überschreibt den Feldinhalt `1-10` nicht. Es wird keine Anfrage automatisch nachgesendet. Erst Schritt 6 setzt das Feld auf `20-30` und startet die zweite Anfrage. Die Trefferzahl ist für diese Prüfung unerheblich.

Vor dem Fix schrieb Schritt 3 bereits `20-30` ins Feld, obwohl die Anfrage nicht gesendet wurde. Das ist der behobene Fehler. Manuelles Bearbeiten des BFL-Suchfelds und externe Abfragen sind davon getrennt; es wird keine allgemeine Synchronisierung aller fremden Who-Sender versprochen.

Der native Classic-Slashhandler wurde nicht verändert. Dort ist T2 kein Test dieses Fixes.

## T3: Verborgene externe Antworten (nur defensive Testabdeckung)

Kein manueller Pflicht-Test und kein öffentlicher Fix-Nachweis.

Der interne Test hält alte Zeilen im Cache, verbirgt Who und injiziert eine andere externe Antwort mit gleicher Trefferzahl. Die Korrektur bewahrt dann die notwendige Vormerkung zum Neuaufbau bis zum tatsächlichen Rendern des Who-Tabs. Das Öffnen auf Kontakte verbraucht die Vormerkung nicht mehr.

Für eigene BFL-Abfragen wurde dagegen über die echten Enter-/Button-Skripte nachgewiesen, dass der alte Cache vorher leer ist. Diese normalen Abläufe zeigen den behaupteten alten Fehler in den Gegenproben nicht.

Auf Retail führte der vom Maintainer ausprobierte direkte API-Befehl außerdem automatisch zum Who-Tab. Dieser Durchlauf erfüllte die erforderliche verborgene Bedingung nicht. Eine über die normale UI reproduzierbare vollständige Abfolge für den spezifischen alten Cachezustand wurde nicht belegt. Deshalb enthält diese Anleitung dafür keinen manuellen `/run`-Auftrag mehr.

## T4: Externe Nullantworten (nur bedingte Testabdeckung)

Kein manueller Pflicht-Test und derzeit kein öffentlicher Fix-Nachweis.

Der interne Test injiziert eine leere externe Antwort, während bereits sortierte alte Zeilen vorhanden sind. Die ursprüngliche Sortierfunktion kehrte bei null Treffern zurück, ohne diese Zeilen zu entfernen. Die Korrektur verarbeitet auch die leere Ergebnisliste.

Eigene Suchen über Enter und Aktualisieren leeren die Liste jedoch bereits vorher. Die Gegenproben zeigen deshalb bei diesen normalen BFL-Abläufen keinen Unterschied zwischen altem und korrigiertem Verhalten.

Blizzards normaler Shift-Linksklick auf einen Chatnamen kann ebenfalls eine Who-Anfrage senden, ohne BFLs eigenen Suchstart zu durchlaufen. Die lokalen `ItemRefHandlers.lua` zeigen diesen Einstieg. Der anschließende Serverpfad mit einer echten Nullantwort und einem entsprechenden `WHO_LIST_UPDATE` ist damit noch nicht bestätigt. Ein künstliches Einspeisen dieses Events oder ein direkter API-Befehl ersetzt diesen fehlenden Live-Nachweis nicht.

Eine optionale Beobachtung normaler Chatnamen-Lookups kann bei bereits sortierter Who-Liste dokumentiert werden. Ohne bestätigte Nullantwort samt passendem Ergebnisupdate ist sie kein bestandener oder fehlgeschlagener T4-Nachweis. Es ist kein zusätzlicher Testkontakt erforderlich.

## T5: Classic-Sortierung über die vorhandenen Header

Gezielter UI-Regressionstest auf Classic Progression, Era und Anniversary, jeweils einzeln:

1. BetterFriendlist öffnen, Who auswählen und mehrere Ergebnisse laden.
2. Auf Name klicken, bis die Namen erkennbar absteigend sortiert sind. Die Richtung bzw. erste und letzte sichtbare Zeile notieren.
3. Auf Kontakte und wieder auf Who wechseln.
4. BFL schließen und erneut auf Who öffnen.
5. Nach der Wartezeit mit Aktualisieren eine neue Antwort anfordern.
6. Mit Level und Klasse wiederholen; dafür unterschiedliche Werte in der jeweiligen Spalte verwenden.

Erwartet mit Fix: Das Sortierkriterium und seine Richtung bleiben erhalten. Durch eine neue Serverantwort darf sich die Spielermenge ändern; sie muss weiterhin nach der gewählten Spalte und Richtung geordnet sein.

Vor dem Fix führte die normale Classic-Aktualisierung wieder den unsortierten Aufbau in API-Reihenfolge aus. Die Gegenprobe über die tatsächlichen XML-Header und das XML-OnShow-Skript schlägt für Name, Level und Klasse auf allen drei Classic-Varianten fehl und besteht mit dem Fix. Retail und Forever dienen hier als unveränderte Vergleichsfälle.

## T6: Gildensortierzweig (nur interner Test)

Die UI bietet keine Gildensortierung an. Das Dropdown zeigt Gilden in der variablen Spalte, ohne eine Gildensortierung aufzurufen. Sortierbare Header gibt es für Name, Level und Klasse.

Intern wurde das falsch gelesene Feld `guild` auf das dokumentierte `fullGuildName` korrigiert. Der automatisierte direkte Funktionsaufruf prüft diesen Zweig. Das ist keine über die normale UI erreichbare Fehlerbehebung und keine neue UI-Funktion. Es gibt dafür keinen manuellen Pflicht-Test und keinen Eintrag im öffentlichen Draft-Changelog.

## T7: Integration und Kampf (zusätzliche Prüfung)

T1 und auf Retail/Forever T2 nach dem normalen Durchlauf im Kampf wiederholen. Festhalten, ob der Client die Anfrage annimmt oder eine Beschränkung meldet. Diese Prüfung kontrolliert mögliche Nebenwirkungen; es wird kein neu behobener Kampf- oder Taint-Fehler behauptet.

Auf Forever zusätzlich die normale Gruppensuche öffnen und schließen sowie einen Chatnamen mit Shift-Linksklick verwenden. Das automatische Öffnen von BFLs Who-Tab muss weiterhin der vorhandenen Einstellung folgen. Bei abgeschalteter Einstellung darf der Tab geschlossen bleiben. Kein zusätzliches natives Who-/Gruppensuche-Fenster soll allein durch BFLs eigene Suche erscheinen.

Bei Lua-Fehlern oder blockierten Aktionen den vollständigen Fehler bzw. den relevanten Taint-Log-Ausschnitt sichern. Server-Timeouts sind getrennt zu dokumentieren.

## Automatisierte Belege und ihre Aussagekraft

Im Worktree ausführen:

```powershell
lua tools/BFL-WhoResultsSmoke.lua .
```

Der erweiterte Test hat 62 Fälle mit 908 Prüfungen. Er umfasst:

- 15 Header-Szenarien über die echten XML-Klickskripte für Name, Level und Klasse auf fünf Clientvarianten.
- 20 Kontrollen über die tatsächlichen Enter- und Aktualisieren-Skripte: verborgene eigene Antworten mit gleicher Trefferzahl sowie eigene sortierte Nullantworten.
- Zwei Szenarien über den installierten normalen Mainline-Slashhandler.
- 25 Fälle mit direkt aufgerufener Sortierung bzw. künstlich eingespeisten externen Zuständen. Diese sind kein eigenständiger Beweis normaler UI-Erreichbarkeit.

Mit dem Fix bestehen 62/62 Fälle. Gegen den ursprünglichen Runtime-Code scheitern 25 Fälle: elf der 37 UI-/Slash-Szenarien (neun Classic-Headerfälle und zwei Mainline-Slashfälle) sowie 14 der 25 internen Zustandsfälle. Die 20 eigenen Enter-/Aktualisieren-Kontrollen bestehen auch vor dem Fix. Die Gesamtzahl bestandener Prüfungen darf daher nicht als Anzahl nachgewiesener Nutzerfehler gelesen werden.

Für den Vorher-/Nachher-Vergleich wird derselbe korrigierte Test-Harness verwendet. Sein Secret-Mock behandelt ein fehlendes optionales Argument nicht mehr fälschlich als Secret Value. Das betrifft die Testumgebung, nicht einen Produktfix.

Die vollständige Smoke-Suite enthält 59 Tests, darunter 150 Prüfungen für den Diagnosezugriff auf Blizzards Freundesliste. Ihre aktuellen Ergebnisse sowie Paket- und Lokalisierungsprüfung sind von den fehlenden Ingame-Nachweisen zu unterscheiden.

## Rückmeldung zu den manuellen Tests

```text
Client / tatsächlicher Build:
BFL-Darstellung / Sprache:
Test-ID T1, T2, T5 oder T7:
Bestanden / Fehlgeschlagen / Offen:
Suchtext / Aktion: Enter, Aktualisieren, Header oder /who:
Erwartete und beobachtete Sortierung bzw. Feldinhalt:
Tabwechsel / Fenster geöffnet oder geschlossen:
Im Kampf: ja / nein
Vollständiger Fehler / Screenshot / relevanter Taint-Log-Ausschnitt:
```

T3, T4 und T6 sind ausdrücklich keine manuell abzuarbeitenden Pflichtfälle. Unbeantwortete Serveranfragen oder unpassende Voraussetzungen als offen dokumentieren.

## Blizzard-Wartehinweis im Who-Tab

Auf Forever eine normale Who-Suche in BFL starten. Wenn WoW einen Wartehinweis
als `CHAT_MSG_SYSTEM` liefert, muss der Originaltext in der Spielsprache im
Who-Tab erscheinen. Der Ladezustand endet, der Chat behält seine Meldung. Nach
acht Sekunden und nach einem Tabwechsel bleibt der Hinweis sichtbar. Die nächste
Suche zeigt wieder ihren eigenen Zustand.

Bei einem Suchversuch ohne Ergebnisereignis oder erkannten Wartehinweis erscheint
nach acht Sekunden `No response. Try again.`. Ein echter Nulltreffer wird getrennt
als leere Ergebnisliste angezeigt. BFL erkennt die von Forever bereitgestellten
GlobalStrings `WHO_COOLDOWN` (mit Sekundenangabe) und `WHO_COOLDOWN_SHORT`.
Für Clients ohne diese Vorlagen gibt es einen englischen Fallback. Unlesbare und
andere Systemtexte gelten nicht als Who-Rückmeldung. Eine zusätzliche ungeplante
Suche kann die Zuordnung eines Wartehinweises verhindern, weil das Systemereignis
keine Anfrage-ID enthält.

`tools/BFL-WhoResultsSmoke.lua` prüft diese Fälle mit simulierten Ereignissen und
den echten BFL-Einstiegen für Enter und Refresh. Für die manuelle Prüfung genügt
ein natürlich auftretender Hinweis oder Timeout. Der Wartehinweis kann auch bei
einer nativen Drosselung vollständig ausbleiben.

## Diagnosezugriff in 3.1.4

Zusätzlich zu den Who-Änderungen wurde die Option für Blizzards Freundesliste nach Advanced unter Diagnostics verschoben. Beim ersten Laden mit der 3.1.4-Migration wird sie einmalig ausgeschaltet. Eine spätere bestätigte Aktivierung bleibt bei weiteren Logins erhalten. Ältere importierte Profile ohne den Migrationsmarker werden ebenfalls einmalig zurückgesetzt; bereits migrierte Sicherungen behalten die spätere Benutzerwahl.

Manuelle Prüfung auf Retail, Forever, Classic Progression, Era und Anniversary:

1. Nach dem Update neu laden. Der Blizzard-Menüeintrag darf bei ausgeschalteter Option auch in der Modern-Darstellung nicht erscheinen. Unter Behavior darf die Option nicht mehr stehen.
2. Advanced öffnen und unter Diagnostics die Option einschalten. Vor der Bestätigung bleiben gespeicherter Wert und Menüeintrag ausgeschaltet.
3. Den Hinweis mit Escape oder Abbrechen schließen. Die Option bleibt aus.
4. Erneut einschalten und den Warnhinweis ausdrücklich bestätigen. Erst jetzt werden Option und Menüeintrag aktiv. Der Hinweis erklärt Diagnosezweck, vollständigen Ersatz der Blizzard-Liste und fehlende Unterstützung parallelen Betriebs.
5. `/reload` ausführen. Die bestätigte Aktivierung bleibt erhalten; die Migration darf sie nicht nochmals ausschalten.
6. Die Option ausschalten. Dafür erscheint keine Bestätigung.
7. Optional `/bfl show` und `/bfl toggle` prüfen: Auch diese normalen Einstiege dürfen die Aktivierung nicht ohne denselben Warnhinweis durchführen.

Die Migration wird mit künstlichen alten und neuen Profilen automatisiert geprüft. Keine echte SavedVariables-Datei nur für diesen Test bearbeiten oder löschen.
