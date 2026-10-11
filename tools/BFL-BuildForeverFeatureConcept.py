"""Build the German, source-backed Forever feature concept using ReportLab.

Run with the Codex bundled Python runtime. No addon/release files are changed.
"""
from pathlib import Path
import argparse
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, PageBreak, Flowable


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_OUTPUT = ROOT / "docs" / "output" / "pdf" / "BFL_Forever_Featurekonzept.pdf"
NAVY = colors.HexColor("#183348")
TEAL = colors.HexColor("#007D85")
INK = colors.HexColor("#233443")
MUTED = colors.HexColor("#536472")
LINE = colors.HexColor("#CCD7DF")
PALE = colors.HexColor("#F1F5F7")
WIDTH = A4[0] - 92

pdfmetrics.registerFont(TTFont("Arial", "C:/Windows/Fonts/arial.ttf"))
pdfmetrics.registerFont(TTFont("ArialBold", "C:/Windows/Fonts/arialbd.ttf"))
pdfmetrics.registerFontFamily("Arial", normal="Arial", bold="ArialBold", italic="Arial", boldItalic="ArialBold")
STYLES = {
    "title": ParagraphStyle("Title", fontName="ArialBold", fontSize=26, leading=31, textColor=NAVY, spaceAfter=13),
    "h1": ParagraphStyle("H1", fontName="ArialBold", fontSize=20, leading=24, textColor=NAVY, spaceAfter=10),
    "h2": ParagraphStyle("H2", fontName="ArialBold", fontSize=12, leading=16, textColor=NAVY, spaceBefore=9, spaceAfter=4),
    "body": ParagraphStyle("Body", fontName="Arial", fontSize=10.4, leading=14.3, textColor=INK, spaceAfter=5),
    "lead": ParagraphStyle("Lead", fontName="Arial", fontSize=12, leading=17, textColor=MUTED, spaceAfter=13),
    "small": ParagraphStyle("Small", fontName="Arial", fontSize=8.5, leading=11.5, textColor=MUTED, spaceAfter=6),
    "cell": ParagraphStyle("Cell", fontName="Arial", fontSize=9.3, leading=12.6, textColor=INK),
    "headcell": ParagraphStyle("HeadCell", fontName="ArialBold", fontSize=9.3, leading=12.6, textColor=colors.white),
}


def p(text, style="body"):
    return Paragraph(text, STYLES[style])


def table(headers, rows, widths):
    data = [[p(label, "headcell") for label in headers]]
    data += [[p(str(cell), "cell") for cell in row] for row in rows]
    result = Table(data, colWidths=widths, hAlign="LEFT", repeatRows=1)
    result.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, 0), NAVY),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("LEFTPADDING", (0, 0), (-1, -1), 9),
        ("RIGHTPADDING", (0, 0), (-1, -1), 9),
        ("TOPPADDING", (0, 0), (-1, -1), 6.5),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 6.5),
        ("LINEBELOW", (0, 1), (-1, -1), 0.45, LINE),
        ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, PALE]),
    ]))
    return result


class UISketch(Flowable):
    """A vector wireframe: illustrative layout, not a screenshot of shipped UI."""
    def __init__(self, kind):
        super().__init__()
        self.kind = kind
        self.width = WIDTH
        self.height = 181

    def draw(self):
        c = self.canv
        w, h = self.width, self.height
        bg = colors.HexColor("#14232E")
        row = colors.HexColor("#233847")
        text = colors.HexColor("#EDF4F8")
        dim = colors.HexColor("#B2C3CE")
        accent = colors.HexColor("#64D5CE")

        def label(x, y, value, size=9, color=text, bold=False):
            c.setFont("ArialBold" if bold else "Arial", size)
            c.setFillColor(color)
            c.drawString(x, y, value)

        def box(x, y, bw, bh, fill=row, stroke=None):
            c.setFillColor(fill)
            c.setStrokeColor(stroke or fill)
            c.roundRect(x, y, bw, bh, 4, fill=1, stroke=bool(stroke))

        def friend(y, name, detail, focus=False):
            box(12, y, w-24, 31, row, accent if focus else None)
            label(24, y+18, name, bold=True)
            label(24, y+6, detail, 8, dim)
            label(w-77, y+13, "Einladen", 8.5, accent)

        box(0, 0, w, h, bg)
        label(15, h-21, "BetterFriendlist", 11, bold=True)
        label(w-78, h-20, "ENTWURF", 8, dim)
        box(12, h-52, w-24, 22)
        label(22, h-44, "Suchen ...", 8.5, dim)

        if self.kind == "filter":
            label(15, 111, "Filter: Online  |  WoW-Version: Forever", 9, accent)
            friend(65, "Ada-Lovelace", "WoW Forever | Krieger | Gruppe 3/5")
            friend(29, "Mira-Stern", "WoW Forever | Druide | Weltkarte")
            box(w-168, 16, 153, 135, colors.HexColor("#344B5C"))
            for y, value in [(133, "WoW-Version"), (111, "Alle WoW-Versionen"), (91, "Mein Client"),
                             (71, "Retail"), (51, "Forever  [ausgewählt]"), (31, "Classic")]:
                label(w-157, y, value, 8.8, accent if y == 51 else text, y == 133)
        elif self.kind == "inspect":
            friend(91, "Ada-Lovelace", "WoW Forever | in deiner Gruppe", True)
            friend(54, "Mira-Stern", "Battle.net | anderer Realm")
            box(w-201, 13, 187, 113, colors.HexColor("#344B5C"))
            label(w-188, 106, "Ada-Lovelace", 9.5, bold=True)
            label(w-188, 86, "Flüstern")
            label(w-188, 67, "Einladen")
            box(w-193, 37, 171, 22, colors.HexColor("#007D85"))
            label(w-186, 45, "Talente ansehen", 9, bold=True)
            label(w-188, 22, "Blizzards Talentfenster öffnen", 8, dim)
        elif self.kind == "voice":
            friend(91, "Ada-Lovelace", "WoW Forever | Gruppe 3/5")
            friend(54, "Mira-Stern", "WoW Forever | Online")
            box(12, 14, w-24, 28, colors.HexColor("#2D4857"))
            label(23, 31, "DEIN SPRACHSTATUS", 7.5, dim, True)
            label(23, 20, "Discord | Gruppenkanal", 9, accent)
            label(w-151, 24, "Sprachoptionen öffnen", 8.5)
        else:
            friend(91, "Ada-Lovelace", "WoW Forever | Online", True)
            friend(54, "Mira-Stern", "WoW Forever | Online")
            label(17, 23, "[Gerätetaste] Einladen     [Gerätetaste] Kontext     [Gerätetaste] Zurück", 8.7, accent)


def section(title, body):
    return [p(title, "h2"), p(body)]


def feature_header(number, title, subtitle, kind):
    return [p(f"{number:02d} / Vorschlag", "small"), p(title, "h1"), p(subtitle, "lead"),
            UISketch(kind), Spacer(1, 5),
            p("UI-Skizze: konzeptionelles Layout. Namen, Texte und Zustände sind Beispieldaten.", "small")]


def footer(canvas, doc):
    canvas.saveState()
    canvas.setStrokeColor(LINE)
    canvas.line(46, 39, A4[0]-46, 39)
    canvas.setFont("Arial", 8)
    canvas.setFillColor(MUTED)
    canvas.drawString(46, 25, "BetterFriendlist | Featurekonzept | 11.10.2026")
    canvas.drawRightString(A4[0]-46, 25, str(doc.page))
    canvas.restoreState()


def build(output):
    output.parent.mkdir(parents=True, exist_ok=True)
    s = [p("BETTERFRIENDLIST / PRODUKT &amp; KOMPATIBILITÄT", "small"),
         p("Featurekonzept für<br/>WoW Forever", "title"),
         p("Vier Ausbaustufen auf Basis der aktualisierten Blizzard-UI-Quellen. Stand: 11. Oktober 2026.", "lead"),
         p("<b>Empfehlung:</b> nach dem umgesetzten Forever-Schnellfilter die native Talent-Inspektion prüfen. "
           "Voice/Discord und Controller-Navigation als getrennte, zunächst deaktivierte Beta-Prototypen prüfen."),
         p("Status sauber getrennt", "h2"),
         p("Der Worktree <b>forever-invite-compat</b> enthält bereits den Invite-Fix und die folgenden "
           "Kompatibilitätsergänzungen. Der <b>Forever-Schnellfilter ist umgesetzt</b>. Weitere Filter-UI, "
           "Talent-Inspektion, Voice/Discord und Controller-Navigation bleiben Vorschläge."),
         table(["Im Worktree ergänzt", "Wirkung"], [
             ["Title-Freunde &amp; Block-Aktionen", "Nicht berechtigte und unvollständige moderne Kontakte werden nicht zum Blockieren angeboten. Identität und Berechtigung werden beim Klick erneut geprüft."],
             ["WHO-Klassen", "Verfügbare Klassen-IDs statt einer Schleife über die Anzahl; Classic behält auch nicht fortlaufende IDs wie Druide (11)."],
             ["Regionale Namen", "Konto-Picker und QuickJoin hängen keinen redundanten Realm an. Nachnamen, Links und Kontakt-IDs bleiben korrekt."],
             ["Sichere UI-Ebenen", "Secret- oder unzugängliche Frame-Strata werden nicht in Settings-, Skin- und WHO-Overlays übernommen."],
         ], [176, WIDTH-176]),
         p("Feature-Priorisierung", "h2"),
         table(["Vorschlag", "Startumfang", "Reihenfolge"], [
             ["Forever-Filter", "Schnellfilter für Liste und Broker; Ausbau optional", "Umgesetzt"],
             ["Talente ansehen", "Native Talent-UI für tatsächlich inspizierbare Spieler", "2 / MVP"],
             ["Voice/Discord", "Eigener Sprachstatus; LFG-Badge nur mit echten Daten", "3 / PoC"],
             ["Controller", "Fokusroute und geräteabhängige Aktionshinweise", "4 / PoC"],
         ], [132, 272, WIDTH-404]),
         Spacer(1, 9),
         p("Prüfstand: Invite-, Social-, Listen- und Tooltip-Smokes sowie Lua/XML-, Sprach- und Paketprüfungen bestanden. "
           "Keine neuen statischen Warnungen. Auf neun Clients deployt; Live- und Taint-QA der jüngsten Änderungen "
           "steht noch aus. Quellen und Einschränkungen: Seite 7.", "small"),
         PageBreak()]

    s += feature_header(1, "Ein eigener Forever-Filter", "Das richtige WoW-Projekt finden, ohne die Bedeutung von Retail zu verändern.", "filter")
    s += section("Umgesetzt und möglicher Ausbau", "Der zusätzliche Schnellfilter <b>WoW Forever</b> ist in der "
                 "vorhandenen Filterauswahl verfügbar und wird auch vom Broker ausgewertet. Die Skizze zeigt "
                 "einen optionalen weiteren Ausbau: die Gruppe <b>WoW-Version</b> mit "
                 "Alle WoW-Versionen, Mein Client, Retail, Forever und Classic. Ein aktiver Filter wird als kurzer "
                 "Chip neben der Suche angezeigt. Die Gruppe und der Chip sind <b>noch nicht umgesetzt</b>; "
                 "weitere Classic-Untergruppen und frei kombinierbare Projektfilter folgen nur bei Bedarf.")
    s += section("Verhalten und Daten", "Forever verwendet das Projekt <b>WOW_PROJECT_CAMELOT (18)</b>. "
                 "Die Mainline-UI-Familie ist nicht gleichbedeutend mit dem Retail-Produkt. Retail bleibt Projekt 1. "
                 "Der Filter prüft alle verfügbaren, tatsächlich online gemeldeten WoW-Spielkonten eines Freundes, "
                 "nicht nur das fokussierte Konto. Lokale WoW-Freunde werden dem eigenen Client zugeordnet. [Q1]")
    s += section("Einbau in BetterFriendlist", "Die Auswertung gehört in <b>FilterSortRegistry</b>; "
                 "FriendsList, QuickFilters und Broker verwenden denselben Vertrag. Vorhandene Filter-IDs und "
                 "gespeicherte Kontakt-Schlüssel werden nicht umgedeutet. Optional kann später die Sortierung "
                 "<b>Mein Client zuerst</b> ergänzt werden, ausdrücklich auswählbar und mit stabilen Gleichständen.")
    s += section("Leer- und Randfälle", "Für den Forever-Onlinefilter zählen Offline-Freunde und "
                 "unbekannte Projekt-IDs nicht als Treffer. Vorschlag für den weiteren Ausbau: "
                 "Leerer Zustand <b>Keine Freunde in WoW Forever online</b>, "
                 "mit Aktion <b>Filter zurücksetzen</b>. Der breite WoW-Filter bleibt die Ausweichmöglichkeit. "
                 "Die bestehenden Retail-Regeln werden im MVP nicht stillschweigend verschärft.")
    s += section("Abnahmekriterien", "Ein Freund mit Retail- und Forever-Login erscheint unter beiden passenden "
                 "Filtern; App-only und andere Projekte erscheinen nicht unter Forever. Liste und Broker liefern "
                 "dieselben Treffer. Ein Filterwechsel verändert weder Invite-Ziel noch Favoriten, Notizen oder UIDs.")
    s.append(PageBreak())

    s += feature_header(2, "Talente direkt ansehen", "Ein kleiner Kontextmenü-Eintrag, der Blizzards vorhandene Talentansicht nutzt.", "inspect")
    s += section("So sieht es aus", "Bei einem geeigneten Spieler ergänzt das Kontextmenü <b>Talente ansehen</b> "
                 "neben der normalen Inspektion. Ein Klick öffnet die native Talentansicht. BetterFriendlist "
                 "baut keinen zweiten Talentbaum und speichert keine fremden Talentprofile. [Q2]")
    s += section("Wann der Eintrag angeboten wird", "Voraussetzung ist ein echter, noch gültiger <b>Unit-Token</b>, "
                 "zum Beispiel target oder party1, mit überprüfter Spieleridentität. Gegner und reine "
                 "Battle.net-Kontakte ohne passenden Unit-Token erhalten keinen Eintrag. Ist die native "
                 "Inspektion nicht möglich, ist die Aktion deaktiviert; der Hinweis sollte neutral lauten: "
                 "<b>Der Spieler kann aktuell nicht inspiziert werden</b>. Nicht jede Ablehnung bedeutet Entfernung.")
    s += section("Technischer Ablauf", "Beim Klick Unit-Token und GUID erneut abgleichen, Spieler- und "
                 "Gegnerprüfung sowie <b>CanInspect(unit)</b> wiederholen und den Zustand des eigenen Spielers "
                 "berücksichtigen. Danach Blizzards Muster verwenden: <b>NotifyInspect(unit)</b> und "
                 "<b>PlayerSpellsUtil.OpenToClassTalentsTab(unit)</b>. Die native Hilfsfunktion lädt die UI "
                 "bei Bedarf und setzt die Inspect-Unit. Ein GUID-String ist kein Ersatz für einen Unit-Token.")
    s += section("Grenzen und Fallback", "Funktion und native Talent-UI werden nach Fähigkeit geprüft, nicht "
                 "nur nach Versionsnummer. Fehlen sie auf einem Client, bleibt die bisherige Inspektion erhalten. "
                 "Während Combat wird die neue Aktion zunächst konservativ deaktiviert, bis das konkrete "
                 "Addon-Verhalten mit Taint-Logging geprüft ist. Keine Hintergrund-Inspektionen, kein Polling.")
    s += section("Abnahmekriterien", "Die Aktion öffnet den richtigen Spieler; ein neu belegtes party1 "
                 "öffnet niemals einen anderen Kontakt. Offline-, gegnerische und nicht inspizierbare Ziele "
                 "lösen keinen Inspect-Aufruf aus. Combat, ausstehende Serverdaten und nicht geladene "
                 "Talent-UI führen weder zu Lua-Fehlern noch zu geschützten Aktionen.")
    s.append(PageBreak())

    s += feature_header(3, "Voice/Discord als Status", "Zuerst den eigenen Sprachzustand zeigen; Kontakte nicht mit vermuteten Daten anreichern.", "voice")
    s += section("So sieht es aus", "Eine optionale, kompakte Leiste am unteren Rand zeigt <b>deinen</b> "
                 "aktiven Sprachprovider und einen freigegebenen Kanalnamen. <b>Sprachoptionen öffnen</b> "
                 "führt in die native Oberfläche. In Compact Mode genügt ein Symbol mit Tooltip. "
                 "Kein Kanal wird beim Öffnen von BetterFriendlist automatisch betreten.")
    s += section("Was die Quellen tatsächlich ermöglichen", "Der neue Provider-Vertrag umfasst "
                 "<b>C_VoiceChat.GetActiveVoiceProviderID</b> und die Enum-Werte Legacy/Discord. "
                 "<b>C_Discord.IsVoiceEnabled</b> liefert eine lokale Fähigkeitsprüfung, keine Discord-Präsenz "
                 "aller Freunde. [Q3] Die geprüften Änderungen belegen keine verlässliche Zuordnung von "
                 "Battle.net-Freund zu Discord-Nutzer. Deshalb erhalten Freundeszeilen im MVP <b>keinen "
                 "angeblichen Discord-Online-Status</b>.")
    s += section("Sinnvolle zweite Stufe", "Wo eine echte LFG-Listing-ID auf freigegebene Listing-Daten "
                 "aufgelöst wird, kann ein Badge den dort angegebenen <b>voiceMode</b> anzeigen: Keine Angabe, "
                 "WoW, Discord oder Benutzerdefiniert. Das ist eine Anforderung der Gruppe, kein Beweis "
                 "eines bereits verbundenen Freundes. QuickJoin erhält dieses Badge nur bei belegbarer "
                 "Datenzuordnung. Fehlt sie, bleibt es verborgen. [Q4]")
    s += section("Umsetzung und Schutz", "Ein capability-gesteuerter Adapter aktualisiert den Zustand auf "
                 "Provider- und Kanalereignisse, ohne Dauer-Polling. DiscordParty ist für Chat-Zuordnungen "
                 "nicht blind mit dem normalen Party-Kanal gleichzusetzen; Blizzard bildet dafür auf "
                 "PrivateParty ab. Discord-Opaque-IDs nicht in eigene Kontakt-IDs umwandeln oder persistieren. "
                 "Auth-, Join- und Provider-Wechsel bleiben im MVP der nativen UI vorbehalten. [Q3]")
    s += section("Abnahmekriterien", "Ohne verfügbare APIs oder Freigabe bleibt die Leiste verborgen. "
                 "Providerwechsel, Disconnect und Altersbeschränkungen erzeugen keine falschen Statusanzeigen. "
                 "Streamer Mode blendet sensible Kanal-/Nutzerangaben aus. Freigabe erst nach einem "
                 "Read-only-Prototyp auf dem tatsächlich verwendeten Client.")
    s.append(PageBreak())

    s += feature_header(4, "Controller-Navigation", "Sichtbarer Fokus und echte Gerätetasten statt einer ausschließlich mauszentrierten Liste.", "controller")
    s += section("So sieht es aus", "Die fokussierte Freundeszeile erhält einen klaren Rahmen. Unten "
                 "erscheinen geräteabhängige Hinweise für <b>Einladen</b>, <b>Kontext</b> und <b>Zurück</b>. "
                 "Die Skizze zeigt nur Aktionsrollen; konkrete Tasten und Symbole stammen aus dem "
                 "aktiven Gerät und den vorhandenen Bindings. Es werden keine Xbox-Tasten fest eingebaut.")
    s += section("Vorgeschlagene Fokusroute", "Suche - Filter - Gruppenüberschriften - sichtbare "
                 "Freundeszeilen - Tabs. Beim Listenwechsel wird der Fokus über die stabile Kontakt-UID "
                 "wiedergefunden, nicht über eine wiederverwendete ScrollBox-Zeile. Die aktive Zeile wird "
                 "sichtbar gehalten. Zurück schließt zuerst Untermenü, dann Kontextmenü und zuletzt die "
                 "Liste; der Fokus kehrt jeweils zum auslösenden Element zurück.")
    s += section("Welche neuen Muster helfen", "Blizzard erweitert <b>FocusEffects</b> und verwaltet "
                 "geräteabhängige Symbolsets über <b>InputDeviceIconSetManager</b> und InputUtil. Diese "
                 "Muster sind ein Ansatz für den Prototyp, kein Nachweis einer vollständig unterstützten "
                 "Addon-Fokus-API. Insbesondere Registrierung, Tab-Routing und geschützte "
                 "Invite-Aktionen müssen auf dem Zielclient geprüft werden. [Q5]")
    s += section("MVP und Fallback", "Zunächst nur die Freundesliste mit Filter und Kontextmenü unterstützen. "
                 "WHO, Raid-Verwaltung und Settings folgen erst nach stabiler Navigation. Maus und Tastatur "
                 "bleiben unverändert nutzbar. Beim Eingabegerätewechsel verschwindet die Prompt-Leiste "
                 "ohne Fokusfalle. Keine globalen Bindings überschreiben; die Beta-Option ist standardmäßig aus.")
    s += section("Abnahmekriterien", "Suchen, filtern, einen Freund auswählen, das richtige Spielkonto "
                 "einladen und zurücknavigieren funktionieren ohne Maus. Mehrfach-Logins, eingeklappte "
                 "Gruppen, leere Listen und scrollende Aktualisierungen verlieren nicht das Ziel. "
                 "Combat und ein fehlendes Framework führen zu einem sicheren Maus-/Tastatur-Fallback. "
                 "Ohne sichere Registrierung bleibt dieser Vorschlag ein Konzept.")
    s.append(PageBreak())

    s += [p("Auslieferung und Qualität", "h1"),
          p("Kleine Ausbaustufen mit klaren Freigaben statt einer gemeinsamen großen Feature-Schaltung.", "lead"),
          table(["Stufe", "Ergebnis", "Freigabebedingung"], [
              ["A / Basis", "Projekt- und Capability-Verträge, deterministische Testdaten", "Forever bleibt Mainline-UI, Classic behält native Realm-Regeln."],
              ["B / Nutzwert", "Forever-Schnellfilter, danach Talent-Kontextaktion", "Liste/Broker konsistent; Inspect nur für gültige Ziele; Ingame-QA bestanden."],
              ["C / Voice-PoC", "Read-only-Sprachstatus und belegbare LFG-Badges", "APIs, Events, Alters-/Auth-Grenzen und Datenschutz nachgewiesen."],
              ["D / Controller-PoC", "Fokusroute, Prompt-Leiste und Account-Untermenü", "Keine Fokusfallen, Binding-Konflikte oder Taint-Probleme."],
          ], [92, 195, WIDTH-287]),
          p("Gemeinsame Regeln", "h2"),
          p("Fähigkeiten pro API prüfen; keine neuen Dienste allein wegen einer Mainline-Markierung "
            "aktivieren. Alle neuen UI-Texte in den 11 bestehenden Locales ergänzen. Bestehende "
            "Streamer-Mode-, Theme-, Dichte- und Compact-Verträge nutzen. Bei Settings-Ergänzungen "
            "im BFL-Host arbeiten, nicht im vendorten LibSettingsDesigner-Runtime. "
            "Nicht unterstützte Features verschwinden vollständig, statt funktionslose Einträge zu zeigen."),
          p("Pflichtfälle vor einem Release", "h2"),
          table(["Bereich", "Mindestens prüfen"], [
              ["Clients", "Forever, Retail, Classic Era, Anniversary und progression Classic; weitere APIs über fehlende-Fähigkeit-Fixtures."],
              ["Kontakte", "Title, normale Freunde, unvollständige Metadaten, App-only, Offline, Mehrfach-Logins und unterschiedliche Regionen."],
              ["UI-Zustand", "Combat, sichtbare/verborgene Liste, Resize, Compact Mode, Themes, Menü offen bei Datenwechsel, native UI noch nicht geladen."],
              ["Daten &amp; Leistung", "Keine UID-/Notiz-Migration, keine ungewollten SavedVariables, kein Dauer-Polling; Ereignisse bündeln und Cache-Lebensdauer begrenzen."],
          ], [93, WIDTH-93]),
          p("Bewusste Nicht-Ziele", "h2"),
          p("Kein eigener Discord-Client oder Login; keine erfundene Freundes-Präsenz; keine automatische "
            "Sprachverbindung; keine Offline-/Remote-Talentdatenbank; kein globales Controller-Rebinding. "
            "Die UI-Skizzen sind Vorschläge, keine Zusage einer Blizzard-Freigabe oder eines Release-Termins."),
          p("Für die Umsetzung zu entscheiden", "h2"),
          p("Der Forever-Schnellfilter aus Stufe B ist umgesetzt. Talent-Inspektion separat freigeben. "
            "Voice zunächst nur lokal/read-only, Controller als "
            "explizite Beta. Optionen und Texte nach dem Prototyp festlegen; die stabile Oberfläche "
            "nutzt nur im Client geprüfte Addon-Aufrufe."),
          PageBreak()]

    s += [p("Quellenbasis und Nachweise", "h1"),
          p("Lokale Gethe/wow-ui-source-Klone, nach der angeforderten Aktualisierung geprüft. "
            "Quellcode belegt den Build-Vertrag, nicht die Verfügbarkeit eines Servers oder "
            "die Freigabe jedes nativen Aufrufs für Addons.", "body"),
          table(["Flavor / Branch", "Build", "Commit"], [
              ["Forever / forever", "1.60.1.70291", "9465cb2"],
              ["Retail / live", "12.1.0.69933", "09b9db794"],
              ["PTR / ptr", "12.1.0.69587", "a89e9d0c"],
              ["PTR2 / ptr2", "12.1.5.70077", "07ac548d"],
              ["Classic / classic", "5.5.4.70032", "a53b9b28"],
              ["Era / classic_era", "1.15.9.70003", "8165d4cd"],
              ["Anniversary / classic_anniversary", "2.5.6.69795", "1463c68"],
              ["Classic PTR / classic_ptr", "5.5.4.67849", "ea6f4ee4"],
          ], [240, 132, WIDTH-372]),
          Spacer(1, 9),
          p("Forever-Vergleich: bd2470a (1.60.1.70009) zu 9465cb2. 298 geänderte Dateien, darunter "
            "19 generierte API-Dokumentationen. Unverwandte Kampf-, Quest-, Shop- und Welt-UI-Änderungen "
            "begründen keinen eigenen Ausbau der Freundesliste.", "small"),
          p("Konkrete Implementierungsbelege", "h2")]

    base = "https://github.com/Gethe/wow-ui-source/blob/9465cb273b5513495d8ecc12fbb19930dd6b8957/Interface/AddOns/"
    refs = [
        ("Q1", "Projekt und Filter", [
            ("Blizzard_ProjectConstants/Camelot/ProjectConstants.lua", "WOW_PROJECT_CAMELOT = 18"),
            ("Blizzard_FriendsFrame/Camelot/FriendsFrame.lua", "FriendsFrame_GetInviteRestriction")],
         "BFL-Anknüpfung: Modules/FilterSortRegistry.lua, FriendsList.lua, Broker.lua."),
        ("Q2", "Native Talent-Inspektion", [
            ("Blizzard_UnitPopupShared/UnitPopupSharedButtonMixins.lua", "UnitPopupInspectTalentsButtonMixin"),
            ("Blizzard_FrameXMLUtil/Mainline/PlayerSpellsUtil.lua", "OpenToClassTalentsTab")], ""),
        ("Q3", "Voice-Provider und Discord", [
            ("Blizzard_APIDocumentationGenerated/VoiceChatDocumentation.lua", "VoiceChatDocumentation"),
            ("Blizzard_APIDocumentationGenerated/DiscordDocumentation.lua", "DiscordDocumentation"),
            ("Blizzard_Channels/Mainline/VoiceUtils.lua", "Voice_GetChatChannelType")],
         "Events: VOICE_CHAT_ACTIVE_VOICE_PROVIDER_CHANGED, VOICE_CHAT_VOICE_PROVIDER_CHANGED und VOICE_CHAT_VOICE_PROVIDERS_AVAILABLE_CHANGED."),
        ("Q4", "LFG-Sprachmodus", [
            ("Blizzard_APIDocumentationGenerated/LFGListInfoDocumentation.lua", "LfgEntryData / voiceMode"),
            ("Blizzard_GroupFinder_VanillaStyle/Blizzard_LFGVanilla_VoiceChat.lua", "VoiceModeLabels")], ""),
        ("Q5", "Controller-Muster", [
            ("Blizzard_SharedXMLBase/FocusEffects.lua", "FocusEffects"),
            ("Blizzard_SharedXML/Shared/InputIcons/InputDeviceIconSetManager.lua", "InputDeviceIconSetManager")], ""),
        ("Q6", "Weitere Kompatibilität", [
            ("Blizzard_APIDocumentationGenerated/SpecializationInfoDocumentation.lua", "GetAllClassIDs"),
            ("Blizzard_APIDocumentationGenerated/SimpleFrameAPIDocumentation.lua", "GetFrameStrata / SecretReturnsForAspect"),
            ("Blizzard_FriendsFrame/Mainline/FriendsListTemplates.lua", "RegionalUniqueNamesEnabled")],
         "Block-Guard: FriendsListUtil sowie UnitPopupBnetBlockButtonMixin; Secret-Strata-Schutz ist kein allgemeiner Taint-Nachweis."),
    ]
    for key, title, links, note in refs:
        link_text = " / ".join(f'<link href="{base + path}" color="#007D85">{label}</link>' for path, label in links)
        s.append(p(f"<b>[{key}] {title}.</b> {link_text}." + (" " + note if note else ""), "small"))
    s.append(p("Verifikation im Worktree: tools/BFL-InviteCompatibilitySmoke.lua, "
               "tools/BFL-SocialCompatibilitySmoke.lua und tools/BFL-ReadyForQA.ps1. "
               "Offline-Fixtures ersetzen keine Prüfung von Serverregeln, Secure-Ausführung und Taint im WoW-Client.", "small"))
    doc = SimpleDocTemplate(str(output), pagesize=A4, rightMargin=46, leftMargin=46,
                            topMargin=43, bottomMargin=52, title="BetterFriendlist - Featurekonzept für WoW Forever",
                            author="BetterFriendlist", subject="UI-Vorschläge, Capability-Grenzen und QA für vier neue Features")
    doc.build(s, onFirstPage=footer, onLaterPages=footer)
    print(output)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    args = parser.parse_args()
    build(args.output)
