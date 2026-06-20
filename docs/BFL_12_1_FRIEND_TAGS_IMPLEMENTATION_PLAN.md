# BFL 12.1 Friend Tags And Chip Implementation Plan

Stand: 2026-06-20

## Ziel

Dieses Dokument beschreibt einen ausfuehrlichen Implementierungsplan fuer WoW Retail 12.1 Friend Tags in BetterFriendlist.

Der Plan soll auch ohne die aktuelle Codex-Session weiterverwendbar sein. Er fasst zusammen:

- was Blizzard mit den neuen Battle.net Friend Tags in 12.1 plant
- was sich fachlich hinter Friend Tags verbirgt
- wie BFL Blizzard Friend Tags sicher lesen und schreiben kann
- wie BFL zusaetzliche Custom Tags einfuehren kann
- wie Tags als eigenstaendig gerenderte Chips in Friend Rows, Tooltips, Broker und Menues erscheinen koennen
- wie die neue Tag-Logik mit dem bestehenden BFL Group System zusammenspielt
- welche Settings, Datenmodelle, Guards, QA-Schritte und Risiken fuer die Umsetzung wichtig sind

Dieses Dokument ergaenzt:

- `docs/BFL_12_1_API_IMPACT_ANALYSIS.md`
- `docs/BFL_12_1_MIGRATION_PLAN.md`
- `docs/UI_CONVENTIONS.md`
- `docs/BLIZZARD_BNET_FAVORITES_BUG_REPORT.md`

## Quellenstand

Retail PTR Quelle:

- Pfad: `C:\Users\hofer\Documents\BFL\references\wow-ui-source-ptr`
- Branch: `ptr`
- Build: `12.1.0.68209`
- Letzter Fetch: `2026-06-19 08:17:09`

Retail Live Vergleich:

- Pfad: `C:\Users\hofer\Documents\BFL\references\wow-ui-source-live`
- Branch: `live`
- Build: `12.0.7.68256`
- Ergebnis: keine Friend Tags API im Live-Source gefunden

Classic Vergleich:

- `classic` Build `5.5.4.68159`
- API-Suche in den generierten Classic-Dokumenten findet keine Friend Tags API
- Schlussfolgerung: Friend Tags muessen fuer Classic vollstaendig capability-geguardet sein

Relevante PTR-Dateien:

- `Blizzard_APIDocumentationGenerated/BattleNetDocumentation.lua`
- `Blizzard_APIDocumentationGenerated/BattleNetSharedDocumentation.lua`
- `Blizzard_APIDocumentationGenerated/FriendListDocumentation.lua`
- `Blizzard_SocialUIShared/SocialUIUtil.lua`
- `Blizzard_UnitPopup/Standard/UnitPopupButtons.lua`
- `Blizzard_UnitPopup/Standard/UnitPopupMenus.lua`
- `Blizzard_FriendsFrame/Mainline/FriendsListTemplates.lua`

## Blizzard 12.1 Verhalten

### Neue API

Retail 12.1 fuehrt fuer Battle.net Freunde folgende Friend Tag APIs ein:

```lua
C_BattleNet.AreFriendTagsEnabled()
C_BattleNet.SetFriendTags(accountID, friendTags)
```

`BNetAccountInfo` erhaelt zusaetzlich:

```lua
friendLevel
friendTags
```

Ausserdem gibt es ein neues Event:

```lua
BATTLE_NET_FRIEND_TAG_ENABLED_STATUS_UPDATED
```

`C_BattleNet.SetFriendTags` ist in den generierten API-Dokumenten als Secret-sensitive markiert:

```text
SecretArguments = "AllowedWhenUntainted"
```

Das bedeutet fuer BFL: Tag-Schreibzugriffe sollen nur aus klaren, user-initiierten und untainted UI-Pfaden passieren. BFL darf diese API nicht als beliebigen Hintergrund-Sync behandeln.

### Blizzard Enum

Blizzard Tags sind kein freies Textsystem. Es gibt eine feste Enum-Liste:

| Enum | Wert | Bedeutung |
| --- | ---: | --- |
| `Enum.BattleNetFriendTag.Professions` | 0 | Berufe |
| `Enum.BattleNetFriendTag.PvP` | 1 | PvP |
| `Enum.BattleNetFriendTag.Raiding` | 2 | Raids |
| `Enum.BattleNetFriendTag.Dungeons` | 3 | Dungeons |
| `Enum.BattleNetFriendTag.Delves` | 4 | Tiefen/Delves |
| `Enum.BattleNetFriendTag.Questing` | 5 | Questen |
| `Enum.BattleNetFriendTag.Roleplaying` | 6 | Rollenspiel |
| `Enum.BattleNetFriendTag.DamagerRole` | 7 | Schaden |
| `Enum.BattleNetFriendTag.HealerRole` | 8 | Heilung |
| `Enum.BattleNetFriendTag.TankRole` | 9 | Tank |

Blizzard gruppiert diese Tags in der UI in zwei Bereiche:

- Interests: Professions, PvP, Raiding, Dungeons, Delves, Questing, Roleplaying
- Roles: DamagerRole, HealerRole, TankRole

Die Labels kommen bei Blizzard ueber `SocialUIUtil.GetLabelForBattleNetFriendTag(tag)`.

### Blizzard UI-Absicht

Aus dem PTR-Code laesst sich ableiten:

- Blizzard integriert Friend Tags in das Battle.net-Freund-Kontextmenue.
- Der Menueeintrag zeigt eine Tag-Anzahl.
- Im Untermenue gibt es Checkboxen fuer die festen Enum-Tags.
- Aenderungen werden erst beim Schliessen/Freigeben des Menues mit `C_BattleNet.SetFriendTags` geschrieben.
- Blizzard rendert keine auffaelligen Row Chips in der Standard-Freundesliste.
- Blizzard zeigt Tags im Tooltip als kommagetrennte Textzeile.
- Bei `BN_FRIEND_INFO_CHANGED` und `BATTLE_NET_FRIEND_TAG_ENABLED_STATUS_UPDATED` wird die FriendsFrame-Liste aktualisiert.

Interpretation fuer BFL:

Blizzard plant Friend Tags als leichtgewichtiges soziales Metadaten-System fuer Battle.net Kontakte. Es ist eher eine Interessen-/Rollen-Kategorisierung als ein vollwertiges Gruppen- oder Label-System. BFL kann daraus aber eine bessere, sichtbare Organisationsschicht machen, solange wir Blizzard-Tags und BFL-Custom-Tags sauber trennen.

## Produktentscheidung Fuer BFL

BFL soll Friend Tags als eigene Tag-Schicht einfuehren:

- Blizzard Tags werden gelesen und geschrieben, wenn die 12.1 API verfuegbar und aktiviert ist.
- Custom Tags werden von BFL selbst angeboten und in `BetterFriendlistDB` gespeichert.
- Beide Quellen werden ueber einen gemeinsamen BFL-Wrapper gelesen.
- Tags ersetzen BFL-Gruppen nicht.
- Tags koennen optional als dynamische Gruppenansicht genutzt werden.
- Tags werden visuell als BFL-eigene Chips gerendert.
- Pro Tag kann der Nutzer Chip Label, Chip Icon und Chip Color einstellen.
- Leeres Chip Label ist erlaubt. Wenn ein Icon gesetzt ist, wird dann ein Icon-only Chip gerendert.

Empfohlene Default-Entscheidungen:

- Friend Row Chips bekommen eine eigene kompakte Chip-Zeile unter der normalen Row-Information.
- Custom Tags gelten fuer Battle.net Freunde und WoW Freunde.
- Blizzard Tags gelten nur fuer Battle.net Freunde, weil Blizzard sie per Battle.net API persistiert.
- Standardmaessig sind Row Chips aktiv, aber begrenzt und layout-schonend.
- Streamer Mode blendet Tag-Chips standardmaessig aus, bis der Nutzer sie explizit erlaubt.

## Begriffe

### Blizzard Tag

Ein Tag aus `Enum.BattleNetFriendTag`, der von Blizzard vorgegeben ist und ueber `C_BattleNet.SetFriendTags` am Battle.net Account gespeichert wird.

Beispiel-ID in BFL:

```lua
"blizzard:raiding"
"blizzard:tank"
```

### Custom Tag

Ein BFL-eigener Tag mit frei waehlbarem Namen, der nicht ueber Blizzard persistiert wird. Die Zuordnung wird in `BetterFriendlistDB` gespeichert.

Beispiel-ID in BFL:

```lua
"custom:mythic_plus"
"custom:work_friend"
```

### Chip

Die visuelle Darstellung eines Tags. Ein Chip besteht optional aus:

- Hintergrundfarbe
- Border
- Icon
- Label
- Tooltip

Ein Tag ist die Datenebene. Ein Chip ist die UI-Ebene.

### Chip Profile

Die pro Tag gespeicherte Konfiguration fuer die Chip-Darstellung:

- Label Override
- Icon
- Farbe
- Sichtbarkeit pro Oberflaeche
- Reihenfolge

## Zielarchitektur

### Neue Module

Empfohlen sind zwei neue Module:

```text
Modules/FriendTags.lua
Modules/TagChips.lua
```

`FriendTags.lua` gehoert die Daten- und API-Schicht:

- Capability Checks
- Blizzard Tag Mapping
- Custom Tag CRUD
- Zuordnungen von Tags zu Freunden
- Persistenz
- Cache
- Events
- Search-/Filter-Hilfen
- Group-Integration auf Datenebene

`TagChips.lua` gehoert die Rendering-Schicht:

- Chip Frame Pool
- Chip Sizing
- Icon + Label Layout
- Tooltip-Zeilen
- Row Container Aktualisierung
- Theme-/Skin-Hooks
- Icon-only Darstellung
- `+N` Overflow Chip

Alternative:

Man kann alles in `Modules/FriendTags.lua` starten und `TagChips.lua` erst auslagern, wenn die Row- und Tooltip-Logik zu gross wird. Fuer die geplante Featurebreite ist eine Trennung aber sauberer.

### Bestehende Module, Die Angefasst Werden

Wahrscheinliche Integrationspunkte:

| Datei | Grund |
| --- | --- |
| `Modules/Database.lua` | Defaults, Migration, SavedVariables |
| `Modules/FriendsList.lua` | BNet Daten erfassen, Row Chips, Suche, Refresh, Events |
| `Modules/Broker.lua` | Broker Tooltip/Listen um Tags/Chips erweitern |
| `Modules/Groups.lua` | optionale dynamische Tag-Gruppen |
| `Modules/FilterSortRegistry.lua` | Tag-Feld fuer Filter/Sorter |
| `Modules/MenuSystem.lua` | BFL Kontextmenue um Tag-Zuordnung erweitern |
| `BetterFriendlist.lua` | Secret-values Kontextmenue und BNet Account Info Pfad |
| `Modules/Settings.lua` | Legacy Settings Einstieg oder Kategorie |
| `Modules/SettingsDesigner.lua` | Settings Center Seite fuer Tags & Chips |
| `Locales/*.lua` | neue Strings in allen 11 Locales |
| `Modules/TestSuite.lua` | Wrapper-/Filter-/Migrationstests |
| `Modules/PreviewMode.lua` | Demo-Daten fuer Row Chip QA |

## Datenmodell

### SavedVariables Defaults

Neue Defaults in `Modules/Database.lua`:

```lua
friendTagSettings = {
    enabled = true,
    showRowChips = true,
    showTooltipChips = true,
    showBrokerChips = true,
    showMenuTagCounts = true,
    showTagsInStreamerMode = false,
    rowMode = "chip_line",
    compactRowMode = "icon_only",
    maxRowChips = 3,
    maxTooltipChips = 8,
    enableDynamicTagGroups = false,
    includeCustomTagsInSearch = true,
    includeBlizzardTagsInSearch = true,
}
```

Pro Tag ein Chip-Profil:

```lua
friendTagProfiles = {
    ["blizzard:raiding"] = {
        chipLabel = nil,
        iconType = "atlas",
        iconValue = "groupfinder-icon-raid",
        color = { r = 0.75, g = 0.35, b = 1.0, a = 1.0 },
        visible = true,
        rowVisible = true,
        tooltipVisible = true,
        brokerVisible = true,
        order = 30,
    },
}
```

Custom Tag Definitionen:

```lua
customFriendTags = {
    ["custom:mythic_plus"] = {
        id = "custom:mythic_plus",
        name = "Mythic+",
        enabled = true,
        order = 1000,
        createdAt = 1781913600,
        updatedAt = 1781913600,
    },
}
```

Custom Tag Zuordnungen:

```lua
friendCustomTags = {
    ["bnet_Player#1234"] = {
        ["custom:mythic_plus"] = true,
    },
    ["wow_Name-Realm"] = {
        ["custom:work_friend"] = true,
    },
}
```

### Label Semantik

`chipLabel` braucht eine klare Semantik:

| Wert | Bedeutung |
| --- | --- |
| `nil` | Standardlabel verwenden |
| `""` | Kein Label anzeigen |
| `"Text"` | Dieses Label anzeigen |

Wenn `chipLabel == ""` und ein Icon vorhanden ist:

- Icon-only Chip rendern
- Tooltip zeigt weiterhin den vollstaendigen Tag-Namen
- Hitbox bleibt gross genug fuer Mouseover

Wenn `chipLabel == ""` und kein Icon vorhanden ist:

- Chip nicht rendern
- Tag bleibt trotzdem zugeordnet und in Settings sichtbar
- In Debug/QA als unvollstaendiges Profil behandelbar

### ID Normalisierung

BFL sollte intern stabile String-IDs verwenden, nicht rohe Enum-Werte.

Mapping-Beispiel:

```lua
local BLIZZARD_TAGS = {
    {
        id = "blizzard:professions",
        enumKey = "Professions",
        enumValue = Enum.BattleNetFriendTag.Professions,
        defaultLabelKey = "FRIEND_TAG_PROFESSIONS",
        defaultIcon = { type = "atlas", value = "professions-icon-firstcraft" },
        defaultColor = { r = 0.95, g = 0.70, b = 0.25, a = 1 },
    },
}
```

Warum String-IDs:

- Custom Tags und Blizzard Tags koennen in einer Liste leben.
- Filter, Settings, Groups und Search koennen mit stabilen IDs arbeiten.
- DB wird robuster, falls Blizzard Enum-Werte spaeter erweitert.

## BFL FriendTags Wrapper

### Oeffentliche Modul-API

`Modules/FriendTags.lua` soll eine kleine, stabile API anbieten:

```lua
local FriendTags = BFL:RegisterModule("FriendTags", {})
```

Empfohlene Methoden:

```lua
function FriendTags:IsEnabled()
function FriendTags:IsBlizzardTagAPIAvailable()
function FriendTags:AreBlizzardTagsEnabled()
function FriendTags:GetBlizzardTagDefinitions()
function FriendTags:GetCustomTagDefinitions()
function FriendTags:GetAllTagDefinitions()
function FriendTags:GetTagsForFriend(friend)
function FriendTags:GetTagIdsForFriend(friend)
function FriendTags:GetChipProfile(tagId)
function FriendTags:SetChipProfile(tagId, profilePatch)
function FriendTags:SetBlizzardTagsForFriend(friend, tagIds)
function FriendTags:SetCustomTagsForFriend(friendUID, tagIds)
function FriendTags:AddCustomTag(name)
function FriendTags:RenameCustomTag(tagId, name)
function FriendTags:DeleteCustomTag(tagId)
function FriendTags:GetSearchText(friend)
function FriendTags:FriendHasTag(friend, tagId)
function FriendTags:Invalidate(reason)
```

### Capability Guards

```lua
function FriendTags:IsBlizzardTagAPIAvailable()
    return BFL.IsRetail
        and C_BattleNet
        and C_BattleNet.AreFriendTagsEnabled
        and C_BattleNet.SetFriendTags
        and Enum
        and Enum.BattleNetFriendTag
end
```

```lua
function FriendTags:AreBlizzardTagsEnabled()
    if not self:IsBlizzardTagAPIAvailable() then
        return false
    end

    local ok, enabled = pcall(C_BattleNet.AreFriendTagsEnabled)
    return ok and enabled == true
end
```

### Blizzard Tag Schreiben

Schreiben nur:

- fuer Battle.net Freunde
- wenn API verfuegbar und enabled ist
- wenn `friend.bnetAccountID` oder `contextData.bnetIDAccount` sicher vorhanden ist
- aus user-initiierten Menue-/Settings-Aktionen
- nicht aus automatischem Import im Hintergrund

```lua
function FriendTags:SetBlizzardTagsForFriend(friend, tagIds)
    if not self:AreBlizzardTagsEnabled() then
        return false, "api_unavailable"
    end

    if not friend or friend.type ~= "bnet" or not friend.bnetAccountID then
        return false, "not_bnet_friend"
    end

    local enumTags = self:ConvertTagIdsToBlizzardEnums(tagIds)
    local ok = pcall(C_BattleNet.SetFriendTags, friend.bnetAccountID, enumTags)
    if ok then
        self:Invalidate("set_blizzard_tags")
    end
    return ok
end
```

### Custom Tag Schreiben

Custom Tags werden in BFL gespeichert:

```lua
function FriendTags:SetCustomTagsForFriend(friendUID, tagIds)
    if not friendUID or friendUID == "" then
        return false, "missing_friend_uid"
    end

    BetterFriendlistDB.friendCustomTags = BetterFriendlistDB.friendCustomTags or {}
    BetterFriendlistDB.friendCustomTags[friendUID] = {}

    for _, tagId in ipairs(tagIds or {}) do
        if self:IsCustomTag(tagId) then
            BetterFriendlistDB.friendCustomTags[friendUID][tagId] = true
        end
    end

    self:Invalidate("set_custom_tags")
    return true
end
```

### Combined Read Model

`GetTagsForFriend(friend)` liefert beide Quellen normalisiert:

```lua
{
    {
        id = "blizzard:raiding",
        source = "blizzard",
        name = "Raiding",
        chipProfile = { ... },
    },
    {
        id = "custom:mythic_plus",
        source = "custom",
        name = "Mythic+",
        chipProfile = { ... },
    },
}
```

Blizzard Tags sollen vor Custom Tags erscheinen, ausser die Settings-Reihenfolge sagt explizit etwas anderes.

## Event- Und Cache-Plan

### Neue Version Counter

Analog zu bestehenden Cache-Versionen:

```lua
BFL.FriendTagsVersion = 0
```

`FriendTags:Invalidate(reason)`:

- inkrementiert `BFL.FriendTagsVersion`
- loescht interne Tag-Text-/Chip-Caches
- ruft bei Bedarf FriendsList/Broker Refresh an
- nutzt `BFL:DebugPrint()` fuer Debug, kein raw `print()`

### Events

Retail-only, capability-geguardet:

```lua
BATTLE_NET_FRIEND_TAG_ENABLED_STATUS_UPDATED
BN_FRIEND_INFO_CHANGED
BN_FRIEND_ACCOUNT_ONLINE
BN_FRIEND_ACCOUNT_OFFLINE
```

`BATTLE_NET_FRIEND_TAG_ENABLED_STATUS_UPDATED` bedeutet:

- Blizzard Tag API Status neu pruefen
- Friend Tags Caches leeren
- Row Chips neu aufbauen
- Settings Controls fuer Blizzard Tags ggf. ein-/ausblenden

`BN_FRIEND_INFO_CHANGED` bedeutet:

- `accountInfo.friendTags` kann sich geaendert haben
- DisplayList Cache muss Tag-Version beruecksichtigen

### DisplayList Cache

`Modules/FriendsList.lua` baut die Anzeige ueber `BuildDisplayList`. Der Cache-Key muss erweitert werden:

```lua
FriendTagsVersion = BFL.FriendTagsVersion or 0
```

Sonst wuerden Tag-Zuordnungen, Tag-Gruppen, Suche oder Filter nicht zuverlaessig neu auswerten.

## Friend Data Capture

Beim Erstellen von BNet Friend Objekten in `Modules/FriendsList.lua` sollten neue Felder uebernommen werden:

```lua
friend.friendTags = accountInfo.friendTags
friend.friendLevel = accountInfo.friendLevel
```

Optional:

```lua
friend.classFilename = gameAccountInfo.classFilename
```

Wichtig:

- `accountInfo.friendTags` nur als Blizzard-Rohdaten betrachten
- nicht direkt in UI-Modulen mit Enum-Details arbeiten
- UI liest immer ueber `FriendTags:GetTagsForFriend(friend)`

## Chip Rendering

### Design-Ziel

Die Chips sollen nach BFL aussehen, aber nicht wie Fremdkoerper in der Blizzard FriendsFrame wirken:

- kompakt
- ruhig
- gut lesbar
- farbcodiert, aber nicht grell
- mit Icon-only Modus
- geeignet fuer Blizzard Theme, BFL Dark Theme und ElvUI Skin
- stabil bei langen Namen, langen Tags, vielen Tags und Compact Mode

### Empfohlene Chip Masse

Normal Mode:

```text
Chip height: 16 px
Icon: 12 x 12 px
Horizontal padding: 5 px
Gap icon-label: 3 px
Border alpha: 0.55
Background alpha: 0.20 bis 0.28
Text: GameFontNormalSmall oder vorhandener BFL Small Font
```

Compact Mode:

```text
Chip height: 14 px
Icon-only bevorzugt
Max sichtbar: 2
Overflow: +N
```

### Row Layout

Empfohlener Standard:

- Row bekommt unter Name/Info eine eigene Chip-Zeile.
- Normale Row-Hoehe darf nur kontrolliert erhoeht werden.
- Compact Rows bleiben moeglichst stabil und nutzen Icon-only oder `+N`.

Beispiel:

```text
Name                                            Favorite
Character - Realm - Activity
[Raid] [M+] [Tank] [+2]
```

Fuer BFL sollte gelten:

- Row Chips duerfen Name, Game Icon, Favorite Icon, Multi-Account Badge und Status-Text nicht ueberdecken.
- Maximal sichtbare Chips kommen aus `friendTagSettings.maxRowChips`.
- Wenn mehr Tags vorhanden sind, rendert BFL einen Overflow Chip:

```text
+2
```

Overflow Tooltip:

- zeigt die ausgeblendeten Tags
- unterscheidet optional Blizzard und Custom

### Icon-only Chips

Wenn `chipLabel == ""`:

```text
[icon]
```

Regeln:

- Mindestbreite bleibt groesser als das Icon, z.B. 18 px.
- Tooltip zeigt Tag-Namen und Quelle.
- Icon-only Chips zaehlen normal gegen `maxRowChips`.
- Wenn kein Icon gesetzt ist, wird der Chip nicht gerendert.

### Tooltip Rendering

Blizzard zeigt Tags im Tooltip als Textzeile. BFL kann besser sein:

Variante 1 fuer v1:

- Tags als farbige Textsegmente oder kleine Inline-Chip-Zeilen im Tooltip
- technische Umsetzung einfach halten
- keine komplexen interaktiven Frames im Tooltip

Empfehlung:

- v1: Tooltip-Zeile mit farbigen Tag-Namen und kleinen Icon-Markern, falls leicht moeglich
- v2: echte Chip-Frames im eigenen BFL Tooltip, falls spaeter noetig

Beispiel:

```text
Tags: Raiding, Mythic+, Tank
```

Bei Streamer Mode:

- Standard: Tags nicht anzeigen
- Wenn `showTagsInStreamerMode = true`: nur Custom-/Blizzard-Chips anzeigen, sofern sie keine privaten Namen enthalten

### Broker Rendering

Broker sollte Tags nicht ueberladen:

- Im Friend Tooltip pro Freund maximal `maxTooltipChips`
- Gruppierte Broker-Ausgaben koennen Tag-Labels in der Detailzeile zeigen
- Keine Row-Hoehen-Explosion im Broker Tooltip
- Tag-Gruppen nur anzeigen, wenn `enableDynamicTagGroups` aktiv ist

## Chip Settings

### Settings Umfang

Der Nutzer soll pro Tag einstellen koennen:

- Chip Label
- Chip Icon
- Chip Color
- Sichtbarkeit allgemein
- Sichtbarkeit in Friend Rows
- Sichtbarkeit in Tooltips
- Sichtbarkeit im Broker
- Reihenfolge

Global:

- Tags Feature aktiv/inaktiv
- Row Chips aktiv/inaktiv
- Tooltip Chips aktiv/inaktiv
- Broker Chips aktiv/inaktiv
- Dynamic Tag Groups aktiv/inaktiv
- Tags in Suche einschliessen
- Tags in Streamer Mode anzeigen
- Max Row Chips
- Max Tooltip Chips
- Compact Mode Verhalten

### Settings Center

Neue Settings Center Kategorie oder Seite:

```text
Groups & Sorting -> Friend Tags & Chips
```

Oder, falls die Settings Center Navigation dichter werden soll:

```text
Friends List -> Tags & Chips
```

Empfehlung:

`Groups & Sorting -> Friend Tags & Chips`, weil die Funktion organisatorisch mit Gruppen, Filtern und Sortierung verwandt ist.

### Page Struktur

Abschnitt 1: Global

- Enable Friend Tags
- Show Row Chips
- Show Tooltip Chips
- Show Broker Chips
- Show Tags in Streamer Mode
- Enable Dynamic Tag Groups
- Max Row Chips
- Compact Row Mode

Abschnitt 2: Blizzard Tags

- Liste aller Blizzard Tags
- Statushinweis, wenn API nicht verfuegbar oder deaktiviert ist
- Pro Tag: Preview, Label, Icon, Color, Visibility

Abschnitt 3: Custom Tags

- Custom Tag anlegen
- Custom Tag umbenennen
- Custom Tag loeschen
- Pro Tag: Preview, Label, Icon, Color, Visibility

Abschnitt 4: Import/Utilities spaeter optional

- Custom Groups in Custom Tags kopieren
- Custom Tags als Gruppen anzeigen
- Ungenutzte Custom Tag Zuordnungen bereinigen

### LibSettingsDesigner Einbindung

Einfache Controls koennen direkt ueber LibSettingsDesigner kommen:

- `toggle`
- `dropdown`
- `slider`
- `input`
- `colorpicker`
- `reorderlist`

Der eigentliche per-Tag Chip Editor ist komplexer. Empfehlung:

- Settings Center zeigt eine Tag-Liste mit Preview und einem "Edit" Action Button.
- Der Button oeffnet einen BFL-eigenen Editor-Dialog.
- Dieser Dialog wird auch vom Legacy Settings UI wiederverwendet.
- LibSettingsDesigner wird nicht fuer BFL-spezifische Chip-Editor-Interna geforkt.

### Chip Editor Dialog

Der Dialog sollte enthalten:

- Tag Name oder Blizzard Tag Label
- Source Badge: Blizzard oder Custom
- Chip Preview
- Label Input
- Icon Auswahl
- Color Picker
- Visibility Toggles
- Reset to Default
- Save/Cancel

Icon Auswahl:

- v1: kuratierte Dropdown-Liste mit bekannten WoW Atlas/Texture Icons
- optional: Advanced Custom Icon Path Input
- keine grosse Icon-Bibliothek einfuehren

### Standard Icons

Mogliche kuratierte Defaults:

| Tag | Icon Richtung | Farbe |
| --- | --- | --- |
| Professions | Handwerk/Profession | Gold |
| PvP | Schwerter/Badge | Rot |
| Raiding | Raid/Skull/Group | Violett |
| Dungeons | Portal/Shield | Blau |
| Delves | Compass/Cave | Gruen |
| Questing | Quest/Exclamation | Gelb |
| Roleplaying | Chat/Scroll | Pink |
| DamagerRole | DPS Icon | Rot |
| HealerRole | Heal Icon | Gruen |
| TankRole | Shield Icon | Blau |

Die konkreten Texture-/Atlas-Namen muessen in Retail und Classic sicher geprueft werden. Wenn ein Atlas nicht existiert, muss BFL auf eine neutrale Texture oder reinen Label-Chip zurueckfallen.

## Kontextmenue

### BNet Freunde

Im BFL Kontextmenue soll es einen Eintrag geben:

```text
Tags
```

Untermenue:

- Blizzard Tags
- Custom Tags
- Manage Tags

Blizzard Tags:

- nur sichtbar, wenn `FriendTags:AreBlizzardTagsEnabled()` true ist
- Checkboxen fuer die Blizzard Enum Tags
- Trennung in Interests und Roles, wie Blizzard
- Schreiben ueber `FriendTags:SetBlizzardTagsForFriend(friend, tagIds)`

Custom Tags:

- fuer BNet Freunde sichtbar
- Checkboxen fuer BFL Custom Tags
- Schreiben ueber `FriendTags:SetCustomTagsForFriend(friendUID, tagIds)`

Manage Tags:

- oeffnet Settings Center Tag Page oder Chip Editor

### WoW Freunde

WoW-only Freunde haben keine Blizzard Tags.

Untermenue:

- Custom Tags
- Manage Tags

### Secret Values Und Taint

BFL nutzt auf Secret-Values Clients bereits eigene Kontextmenues. Die neue Tag-UI sollte dort integriert werden, statt rohe Blizzard UnitPopup-Pfade zu erzwingen.

Wichtig:

- Anzeigenamen ueber BFL Display Helper lesen
- keine RealID-/Secret-Daten in Settings oder Debug loggen
- `SetFriendTags` nur aus user-initiierten UI-Aktionen
- Fehler mit `pcall` abfangen

## Group System Kompatibilitaet

### Grundsatz

Tags ersetzen Gruppen nicht.

BFL-Gruppen sind explizite Ordnungscontainer. Tags sind Metadaten. Ein Freund kann mehrere Tags haben, aber in den bestehenden Custom Groups weiterhin nach BFL-Logik einsortiert bleiben.

### Integration v1

In v1:

- Bestehende Gruppenlogik bleibt unveraendert.
- Tags werden in Friend Rows, Tooltips, Search und Filter sichtbar.
- Optional koennen Tags als dynamische Gruppen angezeigt werden, aber standardmaessig aus.

### Dynamische Tag-Gruppen

Wenn `friendTagSettings.enableDynamicTagGroups = true`:

```text
Tags
  Raiding
  Mythic+
  Tank
```

Technisch:

```lua
groupId = "tag:blizzard:raiding"
groupId = "tag:custom:mythic_plus"
```

Dynamische Tag-Gruppen:

- werden nicht als normale Custom Groups in `friendGroups` gespeichert
- haben keine Drag-and-drop Assignment Semantik in v1
- zeigen Freunde, die den Tag besitzen
- koennen optional kollabierbar sein
- muessen in der DisplayList Cache-Signatur enthalten sein

### Warum Kein Drag-and-drop In Tag-Gruppen In v1

Drag-and-drop auf Tag-Gruppen waere semantisch moeglich, aber riskant:

- Bei Blizzard Tags wuerde ein Drop eine Battle.net API Write-Operation ausloesen.
- `SetFriendTags` ist Secret-sensitive.
- Ein Freund kann in mehreren Tag-Gruppen auftauchen.
- Entfernen aus einer Tag-Gruppe waere mehrdeutig, wenn andere Gruppen/Filter aktiv sind.

Empfehlung:

- v1: Tag-Zuordnung ueber Kontextmenue und Editor
- v2: Drag-and-drop auf Custom Tag Gruppen pruefen
- v2+: Blizzard Tag Drop nur, wenn Taint/UX sicher ist

### Gruppenimport

Optional spaeter:

- BFL Custom Groups koennen in Custom Tags kopiert werden.
- Kein automatisches Verschieben.
- Kein automatischer Schreibzugriff auf Blizzard Tags.

Beispiel:

```text
Group "Raid" -> Custom Tag "Raid"
```

Der Import soll nur Custom Tags erzeugen und Zuordnungen in `friendCustomTags` speichern.

## Suche, Filter Und Sortierung

### Suche

`FriendsList:PassesFilters(friend)` soll Tags in die Suche einbeziehen, wenn aktiviert:

- Blizzard Tag Labels
- Custom Tag Namen
- Chip Label Overrides, wenn vorhanden

Nicht suchen:

- versteckte Tags, wenn `visible = false`
- Tags im Streamer Mode, wenn `showTagsInStreamerMode = false`

### FilterSortRegistry

Neue Felder:

```text
tag
tagSource
tagCount
hasTag
```

Moegliche Operatoren:

- has tag
- does not have tag
- tag contains
- source is Blizzard
- source is Custom
- tag count greater than

### Sortierung

Sortierung nach Tags ist optional fuer v1.

Wenn umgesetzt:

- primaer nach erstem sichtbaren Tag in definierter Reihenfolge
- dann bestehende Sortierung weiterverwenden
- keine instabile Sortierung, wenn mehrere Tags vorhanden sind

## Streamer Mode Und Datenschutz

Tags koennen private soziale Informationen enthalten:

- "Work"
- "Family"
- "Raid Lead"
- "Avoid"
- "Real Life"

Daher:

- Custom Tags im Streamer Mode standardmaessig ausblenden
- Blizzard Tags ebenfalls ausblenden, um keine Rollen/Interessen offenzulegen
- Setting `showTagsInStreamerMode` muss explizit aktiviert werden
- Tooltips und Broker muessen denselben Guard verwenden wie Rows

Keine RealID-, BattleTag- oder Secret-Value-Daten in:

- Custom Tag Namen
- Debug Logs
- Settings Previews
- Export/Import Texte ohne Warnung

## Cross-Flavor Verhalten

Retail 12.1:

- Blizzard Tags verfuegbar, wenn API enabled ist
- Custom Tags immer verfuegbar, sofern BFL Feature aktiv ist

Retail 12.0.7:

- keine Blizzard Tags API
- Custom Tags funktionieren lokal
- Blizzard Tag Settings werden versteckt oder als unavailable angezeigt

Classic:

- keine Blizzard Tags API
- Custom Tags funktionieren lokal
- keine Retail-only API-Aufrufe ohne Guard
- keine Atlas-/Texture-Annahme ohne Fallback

## Migration

### DB Migration

Beim ersten Laden nach Feature-Einfuehrung:

- fehlende `friendTagSettings` Defaults einfuegen
- fehlende `friendTagProfiles` Defaults einfuegen
- fehlende `customFriendTags` Tabelle einfuegen
- fehlende `friendCustomTags` Tabelle einfuegen
- keine bestehenden Gruppen veraendern

### Profil Defaults

Blizzard Tag Profile koennen jederzeit aus Defaults rekonstruiert werden.

Regel:

- Nur User Overrides speichern.
- Wenn kein Profil vorhanden ist, Default aus `FriendTags:GetDefaultChipProfile(tagId)` verwenden.

Vorteil:

- neue Blizzard Tags koennen spaeter automatisch erscheinen
- DB bleibt kleiner
- Reset to Default ist einfach

### Cleanup

Custom Tag Loeschen:

- Definition entfernen oder deaktivieren
- Zuordnungen in `friendCustomTags` entfernen
- `BFL.FriendTagsVersion` erhoehen

Freund nicht mehr vorhanden:

- Zuordnungen koennen vorerst bleiben
- optionaler Cleanup spaeter in Settings

## Implementierungsphasen

### Phase 0: Vorbereitung Und Dokumentation

Ziel:

- Dieses Plan-Dokument liegt in `docs`.
- PTR API Fakten sind dokumentiert.
- Produktentscheidungen sind festgehalten.

Akzeptanz:

- Datei ist eigenstaendig nutzbar.
- Blizzard Tags, Custom Tags, Chips, Settings und Groups sind beschrieben.

### Phase 1: Daten- Und Wrapper-Schicht

Dateien:

- `Modules/FriendTags.lua`
- `Modules/Database.lua`
- `BetterFriendlist.toc`
- Classic/Retail TOCs falls noetig

Aufgaben:

- Modul registrieren
- DB Defaults einfuegen
- Blizzard Tag Definitionen mappen
- Custom Tag CRUD einfuehren
- `GetTagsForFriend`
- `SetBlizzardTagsForFriend`
- `SetCustomTagsForFriend`
- Capability Guards
- `BFL.FriendTagsVersion`
- Events registrieren
- Tests/Stubs vorbereiten

Akzeptanz:

- AddOn laedt in Retail 12.1, Retail 12.0.7 und Classic.
- Keine raw API Errors, wenn `C_BattleNet.AreFriendTagsEnabled` fehlt.
- Custom Tags koennen ohne UI per Modul-API gesetzt/gelesen werden.
- Blizzard Tags werden nur geschrieben, wenn API verfuegbar und enabled ist.

### Phase 2: Friend Data, Search Und Filter

Dateien:

- `Modules/FriendsList.lua`
- `Modules/FilterSortRegistry.lua`
- `Modules/TestSuite.lua`

Aufgaben:

- `friend.friendTags` und `friend.friendLevel` erfassen
- DisplayList Cache um `FriendTagsVersion` erweitern
- Suche um Tag-Text erweitern
- FilterSortRegistry um Tag-Felder erweitern
- Preview/Testdaten mit Tags ausstatten

Akzeptanz:

- Suche findet Freunde ueber Tag Namen.
- Filter koennen Freunde mit/ohne Tag auswerten.
- Aenderungen an Tag-Zuordnungen refreshen die Liste.
- Ohne Tags bleibt bestehendes Verhalten unveraendert.

### Phase 3: Chip Renderer

Dateien:

- `Modules/TagChips.lua`
- `Modules/FriendsList.lua`
- `Modules/Broker.lua`
- Theme/Skin Module bei Bedarf

Aufgaben:

- Chip Frame Pool bauen
- Label/Icon/Color Rendering
- Icon-only Modus
- Overflow Chip
- Row Container in Friend Rows
- Tooltip-/Broker-Helfer
- Theme-/ElvUI-kompatible Farben

Akzeptanz:

- Row Chips erscheinen in normalen Friend Rows.
- Compact Mode bleibt stabil.
- Icon-only Chips funktionieren mit leerem Label.
- Overflow zeigt `+N`.
- Kein Overlap mit Name, Status, Favorite Icon, Game Icon, Multi-Account Badge.
- Tooltips/Broker zeigen Tags konsistent.

### Phase 4: Kontextmenue

Dateien:

- `Modules/MenuSystem.lua`
- `BetterFriendlist.lua`
- `Utils/ClassicCompat.lua` falls noetig

Aufgaben:

- Tags Untermenue fuer BNet Freunde
- Custom Tags Untermenue fuer WoW Freunde
- Blizzard Interests/Roles Gruppen
- User-initiated Write Flow
- Manage Tags Einstieg

Akzeptanz:

- BNet Freunde koennen Blizzard Tags togglen, wenn 12.1 API verfuegbar ist.
- Custom Tags koennen fuer BNet und WoW Freunde togglen.
- Kein Fehler auf Classic oder 12.0.7.
- Menue bleibt mit Secret Values kompatibel.

### Phase 5: Settings Center Und Legacy Settings

Dateien:

- `Modules/SettingsDesigner.lua`
- `Modules/Settings.lua`
- `Modules/Database.lua`
- `Locales/*.lua`

Aufgaben:

- Settings Center Seite `Friend Tags & Chips`
- Globale Toggles
- Max Row Chips Slider
- Compact Mode Dropdown
- Tag-Liste mit Chip Preview
- Editor Dialog fuer Label/Icon/Color
- Custom Tag erstellen/umbenennen/loeschen
- Reset to Default
- Legacy Settings Einstieg
- alle Locale Keys in 11 Dateien

Akzeptanz:

- Pro Tag koennen Label, Icon und Color gesetzt werden.
- Leeres Label erzeugt Icon-only Chip, wenn Icon gesetzt ist.
- Reset stellt Default wieder her.
- Blizzard Tag Controls sind auf unsupported Clients korrekt versteckt/deaktiviert.
- Custom Tags sind auf allen Flavors nutzbar.

### Phase 6: Dynamic Tag Groups

Dateien:

- `Modules/Groups.lua`
- `Modules/FriendsList.lua`
- `Modules/Broker.lua`
- `Modules/FilterSortRegistry.lua`

Aufgaben:

- Optionale dynamische Tag-Gruppen erzeugen
- Group IDs `tag:<tagId>`
- Collapsed State speichern
- DisplayList Integration
- Broker kompatibel halten
- Kein v1 Drag-and-drop Assignment

Akzeptanz:

- Bei deaktivierter Option keine Aenderung an Gruppen.
- Bei aktivierter Option erscheinen Tag-Gruppen.
- Freunde koennen in mehreren Tag-Gruppen sichtbar sein.
- Custom Groups bleiben unveraendert.

### Phase 7: QA, Polishing Und Docs

Aufgaben:

- UI QA mit langen Namen und vielen Tags
- `enUS` und `deDE` pruefen
- Streamer Mode pruefen
- Blizzard Theme, BFL Dark Theme, ElvUI Skin pruefen
- Retail 12.1 PTR pruefen
- Retail 12.0.7 pruefen
- Classic pruefen
- Changelog Draft Eintrag
- interne API Docs aktualisieren, falls noetig

Akzeptanz:

- Keine Lua Errors.
- Keine Classic API Fehler.
- Keine fehlenden Locale Keys.
- Keine sichtbaren Ueberlappungen.
- Keine ungewollten Battle.net API Writes.

## QA Matrix

| Bereich | Retail 12.1 PTR | Retail 12.0.7 | Classic |
| --- | --- | --- | --- |
| AddOn Load | keine Lua Errors | keine Lua Errors | keine Lua Errors |
| Blizzard Tag API | read/write guarded | unavailable, kein Fehler | unavailable, kein Fehler |
| Custom Tags | funktioniert | funktioniert | funktioniert |
| Row Chips | sichtbar | Custom-only sichtbar | Custom-only sichtbar |
| Icon-only Chips | funktioniert | funktioniert | funktioniert |
| Tooltip Tags | sichtbar, guarded | Custom-only | Custom-only |
| Broker Tags | sichtbar, guarded | Custom-only | Custom-only |
| Context Menu | Blizzard + Custom | Custom-only | Custom-only |
| Dynamic Groups | optional | Custom-only optional | Custom-only optional |
| Streamer Mode | Tags hidden by default | Tags hidden by default | Tags hidden by default |
| Dark Theme | lesbar | lesbar | lesbar |
| ElvUI Skin | keine harte Abhaengigkeit | keine harte Abhaengigkeit | keine harte Abhaengigkeit |

## Testfaelle

### Daten

- BNet Freund ohne Tags
- BNet Freund mit einem Blizzard Tag
- BNet Freund mit mehreren Blizzard Tags
- BNet Freund mit Blizzard und Custom Tags
- WoW Freund mit Custom Tags
- Offline BNet Freund mit Tags
- Freund mit leerem Custom Tag Label und Icon
- Freund mit leerem Custom Tag Label ohne Icon
- Freund mit mehr Tags als `maxRowChips`

### UI

- normale Row Hoehe
- Compact Mode
- langer Account Name
- langer Character Name
- langer Realm
- lange Note
- lange Custom Tag Namen
- Hover State
- Selected State
- Offline State
- Favorite Icon aktiv
- Multi-Account Badge aktiv
- Game Icon aktiv

### Settings

- Label setzen
- Label leeren
- Icon setzen
- Icon entfernen
- Farbe setzen
- Reset to Default
- Tag in Rows ausblenden
- Tag in Tooltips ausblenden
- Custom Tag loeschen
- Custom Tag umbenennen

### API

- `AreFriendTagsEnabled` true
- `AreFriendTagsEnabled` false
- `C_BattleNet.AreFriendTagsEnabled` fehlt
- `C_BattleNet.SetFriendTags` wirft Fehler
- `accountInfo.friendTags` leer
- `accountInfo.friendTags` nil oder unexpected
- `BATTLE_NET_FRIEND_TAG_ENABLED_STATUS_UPDATED` feuert

## Risiken Und Gegenmassnahmen

### Risiko: Blizzard API Aendert Sich Vor Release

Gegenmassnahme:

- Alle API-Zugriffe ueber `FriendTags` Wrapper.
- Keine direkten `C_BattleNet.SetFriendTags` Calls ausser im Modul.
- PTR vor Implementierung oder Merge erneut pruefen.

### Risiko: Taint Oder Secret Values Beim Schreiben

Gegenmassnahme:

- Nur user-initiated Writes.
- Kein Hintergrund-Sync.
- `pcall`.
- BFL eigenes Menue fuer Secret Values verwenden.
- Kein Schreiben im Combat oder aus unsicheren Callback-Ketten, falls Tests Probleme zeigen.

### Risiko: Row Layout Wird Zu Voll

Gegenmassnahme:

- Max Row Chips.
- Overflow Chip.
- Compact Mode Icon-only.
- eigene Chip-Zeile nur in normaler Row.
- Screenshot QA mit langen Namen.

### Risiko: Custom Tags Verraten Private Informationen

Gegenmassnahme:

- Streamer Mode versteckt Tags default.
- Settings Preview respektiert Streamer Mode.
- Export/Debug vorsichtig.

### Risiko: Gruppenlogik Wird Unklar

Gegenmassnahme:

- Tags nicht als normale Custom Groups speichern.
- Dynamic Tag Groups optional.
- Kein Drag-and-drop Assignment in v1.
- Kontextmenue/Editor als eindeutiger Assignment-Weg.

### Risiko: Settings UI Wird Zu Komplex

Gegenmassnahme:

- Simple Controls mit LibSettingsDesigner.
- Komplexer Chip Editor als BFL-eigener Dialog.
- Keine LibSettingsDesigner Forks fuer BFL Speziallogik.

## Offene Produktfragen

Diese Fragen muessen nicht vor Phase 1 entschieden werden, aber vor Phase 3/5:

1. Soll Row Chip Rendering standardmaessig aktiviert sein oder als Beta/Preview starten?
2. Sollen Custom Tags im ersten Release auch fuer WoW-only Freunde sichtbar sein? Empfehlung: ja.
3. Sollen Tag-Gruppen initial sichtbar sein oder default off? Empfehlung: default off.
4. Soll BFL eine Importhilfe von Custom Groups zu Custom Tags anbieten? Empfehlung: spaeter, nicht v1.
5. Soll der Nutzer eigene Texture Paths fuer Icons eingeben duerfen? Empfehlung: Advanced Option, nicht prominent.

## Empfohlene Erste Implementierung

Fuer den ersten umsetzbaren Slice:

1. `Modules/FriendTags.lua` mit Wrapper, DB Defaults und Custom Tags.
2. BNet Friend Data Capture in `Modules/FriendsList.lua`.
3. Suche nach Tags.
4. Einfaches Kontextmenue fuer Custom Tags und Blizzard Tags.
5. Minimaler Chip Renderer fuer Friend Rows und Tooltips.
6. Settings Center Seite mit globalen Toggles und per-Tag Editor.
7. Dynamic Tag Groups erst danach.

Warum diese Reihenfolge:

- Datenmodell und Wrapper muessen zuerst stabil sein.
- Row Chips und Settings brauchen dieselbe Chip Profile Quelle.
- Gruppenintegration sollte erst passieren, wenn Tag-Zuordnungen und Sichtbarkeit robust sind.

## Definition Of Done

Das Feature gilt als abgeschlossen, wenn:

- BFL auf Retail 12.1 PTR ohne Lua Errors laedt.
- BFL auf Retail 12.0.7 ohne Friend Tags API ohne Lua Errors laedt.
- BFL auf Classic ohne Friend Tags API ohne Lua Errors laedt.
- Blizzard Tags fuer BNet Freunde gelesen werden, wenn API verfuegbar ist.
- Blizzard Tags fuer BNet Freunde user-initiiert geschrieben werden koennen.
- Custom Tags fuer BNet und WoW Freunde gespeichert werden.
- Chips in Friend Rows erscheinen.
- Chips in Tooltips und Broker-Ausgaben erscheinen, sofern aktiviert.
- Leeres Chip Label Icon-only Chips erlaubt.
- Pro Tag Label, Icon und Color einstellbar sind.
- Streamer Mode Tags default versteckt.
- Group System unveraendert bleibt, wenn Dynamic Tag Groups deaktiviert sind.
- Dynamic Tag Groups optional funktionieren, falls sie im Scope enthalten sind.
- Alle neuen Strings in allen 11 Locale-Dateien vorhanden sind.
- Package Check und relevante Pre-Commit Checks erfolgreich sind.

