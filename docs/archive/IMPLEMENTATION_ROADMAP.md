# BetterFriendlist - Vollständige Implementierungs-Roadmap

## Übersicht
Dieses Dokument dient als detaillierter Leitfaden zur vollständigen Implementierung aller fehlenden Features aus Blizzards FriendsFrame. Ziel ist es, 1:1 Parität mit Blizzards Original-UI zu erreichen.

---

## 🎯 Status-Übersicht

### ✅ Vollständig implementiert
- **Friends List**: Modern, mit Gruppen-System, Status Dropdown, Quick Filter Dropdown
- **Ignore List**: Vollständig funktionsfähig mit separatem Fenster
- **Recent Allies**: Header-Tab vorhanden

### 🔶 Teilweise implementiert
- **Who Frame**: UI existiert, aber schwerwiegende Probleme mit Layout und Funktionalität
- **Raid Frame**: Minimale Implementierung, fehlt Großteil der Funktionalität
- **Quick Join**: Nicht implementiert

### ❌ Nicht implementiert
- **Recruit-A-Friend**: Tab vorhanden, aber keine Funktionalität

---

## 📋 Phase 1: WHO FRAME - Vollständige Neuimplementierung

### Probleme (aktuell)
- UI ist verschoben und überlappend
- EditBox-Höhe passt sich nicht richtig an
- Dropdown-Menü (Zone/Guild/Race) funktioniert nicht korrekt
- Spaltenbreiten sind nicht richtig eingestellt
- Scrolling funktioniert nicht optimal
- Keine dynamische Höhenanpassung für skalierbare Schrift

### Referenz-Dateien (Blizzard)
- **Quelle**: `Interface/AddOns/Blizzard_FriendsFrame/Mainline/FriendsFrame.lua`
- **Zeilen**: 1466-1600 (WhoFrame-spezifisch)
- **XML**: `Interface/AddOns/Blizzard_FriendsFrame/Mainline/FriendsFrame.xml`

### Implementierungs-Schritte

#### 1.1 WhoFrame XML - Komplette Neustrukturierung
**Datei**: `BetterFriendlist.xml` (Zeilen ~1540-1700)

**Aktuelle Probleme beheben**:
- [ ] `WhoFrameEditBox` mit `WhoFrameEditBoxMixin` ausstatten
- [ ] Korrekte `instructionsFontObject="UserScaledFontGameFontNormalSmall"` verwenden
- [ ] `OnShow`, `OnHide`, `OnEnter`, `OnLeave`, `OnEnterPressed` Scripts implementieren
- [ ] Height-Adjustment-Logik für Instructions (siehe Blizzard Zeile 1485-1494)

**Erforderliche Mixins**:
```lua
WhoFrameEditBoxMixin = {}
function WhoFrameEditBoxMixin:OnLoad()
    self.Left:Hide()
    self.Middle:Hide()
    self.Right:Hide()
    self.searchIcon:SetAtlas("glues-characterSelect-icon-search", TextureKitConstants.IgnoreAtlasSize)
    self.Instructions:SetFontObject(self.instructionsFontObject)
    self.Instructions:SetMaxLines(2)
end

function WhoFrameEditBoxMixin:OnShow()
    EventRegistry:RegisterCallback("TextSizeManager.OnTextScaleUpdated", function()
        self:AdjustHeightToFitInstructions()
    end, self)
    self:AdjustHeightToFitInstructions()
    EditBox_ClearFocus(self)
end

function WhoFrameEditBoxMixin:AdjustHeightToFitInstructions()
    local linesShown = math.min(self.Instructions:GetNumLines(), self.Instructions:GetMaxLines())
    local totalInstructionHeight = linesShown * self.Instructions:GetLineHeight()
    local padding = 20
    self:SetHeight(totalInstructionHeight + padding)
end

function WhoFrameEditBoxMixin:OnEnterPressed()
    C_FriendList.SendWho(self:GetText(), Enum.SocialWhoOrigin.Social)
    self:ClearFocus()
end
```

#### 1.2 WhoFrame Column Headers - Korrekte Implementierung
**Problem**: Dropdown für Zone/Guild/Race fehlt oder funktioniert nicht

**Blizzard-Referenz**: Zeilen 1603-1680 (FriendsFrame.lua)

**Key-Features**:
- [ ] `WowStyle1DropdownTemplate` für Variable Column verwenden
- [ ] User-Scalable Font Support (`UserScaledFontGameFontNormalSmall`)
- [ ] Dynamische Radio-Button-Höhe basierend auf Font-Größe
- [ ] Sort-Callbacks: `C_FriendList.SortWho(sortType)` mit "zone", "guild", "race"
- [ ] `whoSortValue` global Variable (1=Zone, 2=Guild, 3=Race)

```lua
function WhoFrameDropdown_Initialize(self)
    self.Text:SetFontObject(self.fontObject)
    self.Text:ClearAllPoints()
    self.Text:SetPoint("LEFT", self, 8, 0)
    self.Text:SetPoint("RIGHT", self.Arrow, "LEFT", -8, 0)
    self.Arrow:SetPoint("RIGHT", self, -1, -2)
end

function WhoFrameDropdown_OnLoad(self)
    WowStyle1DropdownMixin.OnLoad(self)
    if not C_Glue.IsOnGlueScreen() then
        local function IsSelected(sortData)
            return sortData.value == whoSortValue
        end
        
        local function SetSelected(sortData)
            whoSortValue = sortData.value
            C_FriendList.SortWho(sortData.sortType)
            WhoList_Update()
        end
        
        WhoFrameDropdown_Initialize(self)
        self:SetupMenu(function(dropdown, rootDescription)
            rootDescription:SetTag("MENU_FRIENDS_WHO")
            local userScaledFontObject = self.fontObject
            local radioHeight = GetFontInfo(userScaledFontObject).height + 8
            
            local zoneOption = rootDescription:CreateRadio(ZONE, IsSelected, SetSelected, {value = 1, sortType = "zone"})
            zoneOption:AddInitializer(function(button, description, menu)
                button.fontString:SetFontObject(userScaledFontObject)
                button:SetHeight(radioHeight)
            end)
            
            -- Guild und Race analog
        end)
    end
end
```

#### 1.3 WhoList ScrollBox - Korrekte Datenstruktur

**Blizzard verwendet**: `elementData = {index=index, info=info, fontObject=UserScaledFontGameNormalSmall}`

**Wichtig**: Font-Object muss für dynamische Extent-Berechnung mitgegeben werden!

```lua
function WhoList_Update()
    local numWhos, totalCount = C_FriendList.GetNumWhoResults()
    
    local displayedText = ""
    if totalCount > MAX_WHOS_FROM_SERVER then
        displayedText = format(WHO_FRAME_SHOWN_TEMPLATE, MAX_WHOS_FROM_SERVER)
    end
    WhoFrameTotals:SetText(format(WHO_FRAME_TOTAL_TEMPLATE, totalCount).." "..displayedText)
    
    local dataProvider = CreateDataProvider()
    for index = 1, numWhos do
        local info = C_FriendList.GetWhoInfo(index)
        dataProvider:Insert({
            index = index,
            info = info,
            fontObject = UserScaledFontGameNormalSmall -- CRITICAL!
        })
    end
    
    WhoFrame.ScrollBox:SetDataProvider(dataProvider, ScrollBoxConstants.RetainScrollPosition)
end
```

#### 1.4 Extent Calculator für skalierbare Schrift

**Blizzard Zeile 1362-1368**:
```lua
view:SetElementExtentCalculator(function(dataIndex, elementData)
    local fontHeight = GetFontInfo(elementData.fontObject).height
    local padding = fontHeight + 2
    return fontHeight + padding
end)
```

**Kritisch**: Ohne diesen Calculator wird die Zeilen-Höhe nicht korrekt berechnet wenn User Font-Größe ändert!

#### 1.5 WhoList Button Template

**Referenz**: `WhoListButtonTemplate` und `WhoListButtonMixin`

**Key-Features**:
- [ ] Name, Level, Class, Variable (Zone/Guild/Race) Spalten
- [ ] Tooltip für abgeschnittenen Text
- [ ] Selection State (LockHighlight/UnlockHighlight)
- [ ] Timerunning-Icon-Support (`TimerunningUtil.AddTinyIcon`)
- [ ] Class-Color für Class-Spalte

```lua
function WhoList_InitButton(button, elementData)
    local index = elementData.index
    local info = elementData.info
    
    button.index = index
    
    local classTextColor
    if info.filename then
        classTextColor = RAID_CLASS_COLORS[info.filename]
    else
        classTextColor = HIGHLIGHT_FONT_COLOR
    end
    
    local name = info.fullName
    if info.timerunningSeasonID then
        name = TimerunningUtil.AddTinyIcon(name)
        button.OriginalName = info.fullName
    end
    
    button.Name:SetText(name)
    button.Level:SetText(info.level)
    button.Class:SetText(info.classStr)
    button.Class:SetTextColor(classTextColor.r, classTextColor.g, classTextColor.b)
    
    -- Variable column based on whoSortValue
    local variableColumnTable = { info.area, info.fullGuildName, info.raceStr }
    local variableText = variableColumnTable[whoSortValue]
    button.Variable:SetText(variableText)
    
    -- Tooltip handling for truncated text
    if button.Variable:IsTruncated() or button.Level:IsTruncated() or button.Name:IsTruncated() then
        button.tooltip1 = info.fullName
        button.tooltip2 = WHO_LIST_LEVEL_TOOLTIP:format(info.level)
        button.tooltip3 = variableText
    else
        button.tooltip1 = nil
        button.tooltip2 = nil
        button.tooltip3 = nil
    end
    
    local selected = WhoFrame.selectedWho == index
    WhoListButton_SetSelected(button, selected)
end
```

#### 1.6 Who Frame Action Buttons

**Buttons**: GroupInvite, AddFriend

**Current State**: Implementiert in BetterFriendlist.lua (~Zeilen 3000-3050)

**Zu prüfen**:
- [ ] `WhoFrameGroupInviteButton` Enable/Disable basierend auf Selection
- [ ] `WhoFrameAddFriendButton` Enable/Disable basierend auf Selection
- [ ] Funktionalität: `C_PartyInfo.InviteUnit(name)` und `C_FriendList.AddFriend(name)`

---

## 📋 Phase 2: RAID FRAME - Vollständige Implementierung

### Herausforderung: Protected Functions
Viele Raid-Funktionen sind **protected** (dürfen nur in Combat oder durch Secure-Templates aufgerufen werden).

### Referenz-Dateien (Blizzard)
- **Hauptdatei**: `Interface/AddOns/Blizzard_RaidFrame/RaidFrame.lua`
- **XML**: `Interface/AddOns/Blizzard_RaidFrame/RaidFrame.xml`
- **Compact Frames**: `Interface/AddOns/Blizzard_CompactRaidFrames/` (für moderne Raid-Frames)

### 2.1 Raid Frame Grundstruktur

**Tabs**: Raid Info + Raid Control (2 Tabs wie in Blizzard)

**Blizzard verwendet**:
- `RaidParentFrame` als Container
- `RaidFrame` für Raid-Mitglieder-Liste
- `RaidInfoFrame` für Saved Instances

#### 2.1.1 Tab-System

```lua
function RaidParentFrame_OnLoad(self)
    self:SetPortraitToAsset("Interface\\LFGFrame\\UI-LFR-PORTRAIT")
    PanelTemplates_SetNumTabs(self, 2)
    PanelTemplates_SetTab(self, 1)
end

function RaidParentFrame_SetView(tab)
    RaidParentFrame.selectTab = tab
    if tab == 1 then
        ClaimRaidFrame(RaidParentFrame)
        RaidFrame:Show()
        PanelTemplates_Tab_OnClick(RaidParentFrameTab1, RaidParentFrame)
    elseif tab == 2 then
        if RaidFrame:GetParent() == RaidParentFrame then
            RaidFrame:Hide()
        end
        PanelTemplates_Tab_OnClick(RaidParentFrameTab2, RaidParentFrame)
    end
end
```

### 2.2 Raid Member List (Tab 1)

**Blizzard Zeile 29-62 (RaidFrame.lua)**:

**Features**:
- [ ] ScrollBox mit Raid-Mitgliedern
- [ ] Anzeige von: Name, Class, Level, Rank (Leader/Assist), Zone, Note
- [ ] Selection-System (markieren von Mitgliedern)
- [ ] Context-Menu (Right-Click) mit Protected-Actions

#### 2.2.1 Raid Roster Data Provider

```lua
function RaidFrame_Update()
    if not IsInRaid() then
        RaidFrameConvertToRaidButton:Show()
        local convertToRaid = true
        local canConvertToRaid = C_PartyInfo.AllowedToDoPartyConversion(convertToRaid)
        RaidFrameConvertToRaidButton:SetEnabled(canConvertToRaid)
        RaidFrameNotInRaid:Show()
        ButtonFrameTemplate_ShowButtonBar(FriendsFrame)
    else
        RaidFrameConvertToRaidButton:Hide()
        RaidFrameNotInRaid:Hide()
        ButtonFrameTemplate_HideButtonBar(FriendsFrame)
    end
    
    -- Update Raid List
    local dataProvider = CreateDataProvider()
    for i = 1, GetNumGroupMembers() do
        local name, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML, assignedRole = GetRaidRosterInfo(i)
        if name then
            dataProvider:Insert({
                index = i,
                name = name,
                rank = rank,
                subgroup = subgroup,
                level = level,
                class = class,
                fileName = fileName,
                zone = zone,
                online = online,
                isDead = isDead,
                role = role,
                isML = isML,
                assignedRole = assignedRole
            })
        end
    end
    
    RaidFrame.ScrollBox:SetDataProvider(dataProvider, ScrollBoxConstants.RetainScrollPosition)
end
```

### 2.3 Protected Functions - Sicherer Umgang

**Problem**: Funktionen wie `PromoteToLeader`, `DemoteAssistant`, `UninviteUnit` sind protected.

**Lösungen**:

#### 2.3.1 Secure Templates verwenden

```xml
<!-- Secure Button für Promote/Demote -->
<Button name="RaidFramePromoteButton" inherits="SecureActionButtonTemplate" parent="RaidFrame">
    <Attributes>
        <Attribute name="type" type="string" value="macro"/>
        <Attribute name="macrotext" type="string" value="/promote %s"/>
    </Attributes>
</Button>
```

#### 2.3.2 Slash Commands nutzen

```lua
-- Statt direct API call:
-- PromoteToLeader("PlayerName") -- PROTECTED!

-- Nutze Slash Command:
function RaidFrame_PromoteMember(name)
    if not issecure() then
        -- Not in combat, can use slash command
        SlashCmdList["PROMOTE"](name)
    else
        print("Cannot promote during combat")
    end
end
```

#### 2.3.3 Context Menu mit UnitPopup

**Blizzard verwendet**: `UnitPopup_OpenMenu("RAID_PLAYER", contextData)`

```lua
function RaidFrameButton_OnClick(self, button)
    if button == "RightButton" then
        local name = self.name
        local contextData = {
            name = name,
            unit = "raid"..self.index,
            guid = UnitGUID("raid"..self.index)
        }
        UnitPopup_OpenMenu("RAID_PLAYER", contextData)
    end
end
```

### 2.4 Raid Control Features

**Features die implementiert werden müssen**:

#### 2.4.1 Convert to Raid / Convert to Party
```lua
function RaidFrameConvertToRaidButton_OnClick()
    C_PartyInfo.ConvertToRaid()
end

function RaidFrameConvertToPartyButton_OnClick()
    C_PartyInfo.ConvertToParty()
end
```

**Enable-Logic**:
- Convert to Raid: Nur wenn in Party (nicht Raid) und Leader
- Convert to Party: Nur wenn in Raid und ≤5 Mitglieder

#### 2.4.2 Raid Difficulty Dropdown

**Blizzard Zeile 189-218 (CompactRaidFrameManager.lua)**:

```lua
local dropdown = RaidFrame.DifficultyDropdown
dropdown:SetupMenu(function(dropdown, rootDescription)
    rootDescription:SetTag("MENU_RAID_FRAME_DIFFICULTY")
    
    if IsInRaid() then
        local raidDifficultyID = GetRaidDifficultyID()
        local dungeonDifficultyID = GetDungeonDifficultyID()
        
        -- Normal, Heroic, Mythic options
        for i, info in ipairs(DIFFICULTY_INFO) do
            local radio = rootDescription:CreateRadio(
                info.name,
                function() return raidDifficultyID == info.id end,
                function() SetRaidDifficultyID(info.id) end
            )
        end
    end
end)
```

#### 2.4.3 Ready Check

```lua
function RaidFrameReadyCheckButton_OnClick()
    DoReadyCheck()
end
```

**Wichtig**: Nur Leader oder Assist kann Ready Check starten!

```lua
function RaidFrameReadyCheckButton_Update()
    if UnitIsGroupLeader("player") or UnitIsGroupAssistant("player") then
        RaidFrameReadyCheckButton:Enable()
    else
        RaidFrameReadyCheckButton:Disable()
    end
end
```

#### 2.4.4 Role Poll

```lua
function RaidFrameRolePollButton_OnClick()
    InitiateRolePoll()
end
```

#### 2.4.5 Everyone is Assistant

```lua
function RaidFrameEveryoneIsAssistButton_OnClick(self)
    SetEveryoneIsAssistant(self:GetChecked())
end

function RaidFrameEveryoneIsAssistButton_Update(self)
    self:SetChecked(IsEveryoneAssistant())
    if UnitIsGroupLeader("player") then
        self:Enable()
    else
        self:Disable()
    end
end
```

#### 2.4.6 Restrict Pings

```lua
function RaidFrameRestrictPingsButton_OnClick(self)
    -- Dropdown with options: Everyone, Leader+Assist Only, Leader Only
    local dropdown = self.Dropdown
    dropdown:SetupMenu(function(dropdown, rootDescription)
        rootDescription:CreateRadio("Everyone", ...)
        rootDescription:CreateRadio("Leader and Assistants", ...)
        rootDescription:CreateRadio("Leader Only", ...)
    end)
end
```

### 2.5 Raid Info Frame (Tab 2)

**Features**:
- [ ] Liste aller Saved Instances
- [ ] Anzeige: Instance Name, Difficulty, Bosses Killed, Lockout Time
- [ ] "Extend Raid Lock" Button

**Blizzard-Referenz**: `Interface/AddOns/Blizzard_RaidFrame/RaidInfo.lua`

```lua
function RaidInfoFrame_Update()
    local dataProvider = CreateDataProvider()
    
    -- Saved Instances
    local numSavedInstances = GetNumSavedInstances()
    for i = 1, numSavedInstances do
        local name, id, reset, difficulty, locked, extended, instanceIDMostSig, isRaid, maxPlayers, difficultyName, numEncounters, encounterProgress = GetSavedInstanceInfo(i)
        if locked then
            dataProvider:Insert({
                type = "instance",
                name = name,
                id = id,
                reset = reset,
                difficulty = difficulty,
                locked = locked,
                extended = extended,
                encounterProgress = encounterProgress,
                numEncounters = numEncounters
            })
        end
    end
    
    -- World Bosses
    local numSavedWorldBosses = GetNumSavedWorldBosses()
    for i = 1, numSavedWorldBosses do
        local name, id, reset = GetSavedWorldBossInfo(i)
        dataProvider:Insert({
            type = "worldboss",
            name = name,
            id = id,
            reset = reset
        })
    end
    
    RaidInfoFrame.ScrollBox:SetDataProvider(dataProvider, ScrollBoxConstants.RetainScrollPosition)
end
```

---

## 📋 Phase 3: QUICK JOIN - Vollständige Implementierung

### Referenz-Dateien (Blizzard)
- **Quelle**: `Interface/AddOns/Blizzard_SocialQueue/Blizzard_SocialQueue.lua`
- **Frame**: `QuickJoinFrame.xml`

### 3.1 Quick Join Grundkonzept

**Quick Join zeigt**:
- Gruppen von Freunden die man joinen kann
- Battle.net Game-Account-Aktivitäten
- LFG-Queue-Status von Freunden

### 3.2 Social Queue System

**API-Funktionen**:
- `C_SocialQueue.GetAllGroups()` - Liste aller verfügbaren Gruppen
- `C_SocialQueue.GetGroupForPlayer(guid)` - Gruppe eines Spielers
- `C_SocialQueue.GetGroupMembers(guid)` - Mitglieder einer Gruppe
- `C_SocialQueue.RequestToJoin(guid)` - Join-Request senden

### 3.3 Quick Join Frame Struktur

```lua
QuickJoinFrameMixin = {}

function QuickJoinFrameMixin:OnLoad()
    self:RegisterEvent("SOCIAL_QUEUE_UPDATE")
    self:RegisterEvent("GROUP_JOINED")
    self:RegisterEvent("GROUP_LEFT")
    
    local view = CreateScrollBoxListLinearView()
    view:SetElementInitializer("QuickJoinButtonTemplate", function(button, elementData)
        self:InitializeButton(button, elementData)
    end)
    
    ScrollUtil.InitScrollBoxListWithScrollBar(self.ScrollBox, self.ScrollBar, view)
end

function QuickJoinFrameMixin:OnEvent(event, ...)
    if event == "SOCIAL_QUEUE_UPDATE" or event == "GROUP_JOINED" or event == "GROUP_LEFT" then
        self:UpdateGroups()
    end
end

function QuickJoinFrameMixin:UpdateGroups()
    local groups = C_SocialQueue.GetAllGroups()
    local dataProvider = CreateDataProvider()
    
    for i, guid in ipairs(groups) do
        local members = C_SocialQueue.GetGroupMembers(guid)
        local groupQueues = C_SocialQueue.GetGroupQueues(guid)
        
        dataProvider:Insert({
            guid = guid,
            members = members,
            queues = groupQueues
        })
    end
    
    self.ScrollBox:SetDataProvider(dataProvider, ScrollBoxConstants.RetainScrollPosition)
end
```

### 3.4 Quick Join Button Template

**Features pro Button**:
- [ ] Leader-Name anzeigen
- [ ] Activity-Type (z.B. "Queued for Random Dungeon")
- [ ] Anzahl Mitglieder
- [ ] "Request Invite" Button
- [ ] Icon für Activity-Type

```lua
function QuickJoinButton_Init(button, elementData)
    local guid = elementData.guid
    local members = elementData.members
    local queues = elementData.queues
    
    -- Finde Leader
    local leaderName = nil
    for i, member in ipairs(members) do
        if member.guid == guid then
            leaderName = member.name
            break
        end
    end
    
    button.Name:SetText(leaderName or UNKNOWN)
    button.Members:SetText(#members.." "..FRIENDS_IN_GROUP)
    
    -- Queue Info
    if queues and #queues > 0 then
        local queueInfo = queues[1]
        button.Activity:SetText(queueInfo.queueName or UNKNOWN)
        
        -- Icon setzen basierend auf queueType
        if queueInfo.queueType == "dungeon" then
            button.Icon:SetAtlas("socialqueuing-icon-group")
        elseif queueInfo.queueType == "raid" then
            button.Icon:SetAtlas("socialqueuing-icon-raid")
        end
    else
        button.Activity:SetText(SOCIAL_QUEUE_PLAYING)
    end
    
    button.RequestInviteButton:SetScript("OnClick", function()
        C_SocialQueue.RequestToJoin(guid)
    end)
end
```

### 3.5 Quick Join Toast Button

**Der kleine Button rechts neben der Minimap**:

```lua
QuickJoinToastButtonMixin = {}

function QuickJoinToastButtonMixin:OnLoad()
    self:RegisterEvent("SOCIAL_QUEUE_UPDATE")
    self:UpdateDisplayedFriendCount()
end

function QuickJoinToastButtonMixin:UpdateDisplayedFriendCount()
    local groups = C_SocialQueue.GetAllGroups(false) -- false = don't include offline
    local numGroups = #groups
    
    if numGroups > 0 then
        self.FriendsButton.Count:SetText(numGroups)
        self.FriendsButton.Count:Show()
        self:Show()
    else
        self:Hide()
    end
end

function QuickJoinToastButtonMixin:OnClick()
    -- Open FriendsFrame to Quick Join tab
    PanelTemplates_SetTab(FriendsFrame, 4) -- Tab 4 = Quick Join
    if FriendsFrame:IsShown() then
        FriendsFrame_OnShow(FriendsFrame)
    else
        ShowUIPanel(FriendsFrame)
    end
end
```

### 3.6 Social Queue Events

**Wichtige Events**:
- `SOCIAL_QUEUE_UPDATE` - Gruppen-Liste hat sich geändert
- `GROUP_JOINED` - Spieler ist Gruppe beigetreten
- `GROUP_LEFT` - Spieler hat Gruppe verlassen
- `BN_FRIEND_ACCOUNT_ONLINE` / `BN_FRIEND_ACCOUNT_OFFLINE` - Friend Online-Status

---

## 📋 Phase 4: RECRUIT-A-FRIEND - Vollständige Implementierung

### Referenz-Dateien (Blizzard)
- **Quelle**: `Interface/AddOns/Blizzard_RecruitAFriend/Blizzard_RecruitAFriendFrame.lua`
- **XML**: `Interface/AddOns/Blizzard_RecruitAFriend/Blizzard_RecruitAFriendFrame.xml`

### 4.1 RAF System Übersicht

**Features**:
- [ ] RAF-Link-Status anzeigen
- [ ] Recruited Friends Liste
- [ ] Rewards-System
- [ ] Summon Friend Button
- [ ] Recruitment Link generieren

### 4.2 RAF Frame Grundstruktur

```lua
RecruitAFriendFrameMixin = {}

function RecruitAFriendFrameMixin:OnLoad()
    self:RegisterEvent("RAF_RECRUIT_LIST_UPDATE")
    self:RegisterEvent("RAF_INFO_UPDATED")
    
    self:UpdateRecruitList()
end

function RecruitAFriendFrameMixin:UpdateRecruitList()
    local recruitInfo = C_RecruitAFriend.GetRAFInfo()
    local dataProvider = CreateDataProvider()
    
    for i, recruit in ipairs(recruitInfo.recruits) do
        dataProvider:Insert({
            name = recruit.name,
            level = recruit.level,
            monthsRemaining = recruit.monthsRemaining,
            canSummon = recruit.canSummon,
            guid = recruit.guid
        })
    end
    
    self.ScrollBox:SetDataProvider(dataProvider, ScrollBoxConstants.RetainScrollPosition)
end
```

### 4.3 Summon Friend Feature

```lua
function RecruitAFriendFrame_SummonFriend(guid)
    if C_RecruitAFriend.CanSummonFriend(guid) then
        local start, duration = C_RecruitAFriend.GetSummonFriendCooldown()
        if duration == 0 then
            C_RecruitAFriend.RequestSummon(guid)
        else
            print("Summon on cooldown")
        end
    else
        print("Cannot summon friend")
    end
end
```

---

## 🛠️ Technische Implementierungs-Hinweise

### Protected Functions - Best Practices

**Do's**:
1. ✅ Verwende `issecure()` um zu prüfen ob Code im protected context läuft
2. ✅ Nutze Secure Templates für kritische Actions
3. ✅ Verwende Slash Commands als Fallback
4. ✅ Nutze UnitPopup-System für Context-Menüs
5. ✅ Registriere alle Events die du brauchst

**Don'ts**:
1. ❌ Rufe keine protected functions direkt aus Addon-Code auf
2. ❌ Versuche nicht Protected-Status zu umgehen (kann zum Ban führen)
3. ❌ Verwende keine Hacks oder versteckte APIs
4. ❌ Setze keine restricted attributes außerhalb von Secure-Templates

### Testing-Strategie

**Phase-by-Phase Testing**:
1. **WHO**: Teste mit verschiedenen Servern, verschiedenen Zonen, verschiedenen Font-Größen
2. **RAID**: Teste in 5-man group, 10-man raid, 20-man raid, 40-man raid
3. **QUICK JOIN**: Teste mit Online-Freunden in verschiedenen Activities
4. **RAF**: Teste mit aktivem RAF-Link

### Performance-Optimierung

**Wichtige Punkte**:
- Verwende `ScrollBoxConstants.RetainScrollPosition` wo möglich
- Cache Font-Info für skalierbare Schrift
- Nutze DataProvider statt manueller Frame-Verwaltung
- Event-Throttling für häufige Updates (z.B. SOCIAL_QUEUE_UPDATE)

### Debugging-Tools

```lua
-- Debug-Ausgabe für Events
local debugEvents = false
local function DebugEvent(event, ...)
    if not debugEvents then return end
    print("DEBUG:", event, ...)
end

-- Registriere Debug-Events
if debugEvents then
    frame:RegisterEvent("RAID_ROSTER_UPDATE")
    frame:RegisterEvent("GROUP_ROSTER_UPDATE")
    frame:RegisterEvent("SOCIAL_QUEUE_UPDATE")
    -- etc.
end
```

---

## 📊 Prioritäts-Reihenfolge

### Empfohlene Implementierungs-Reihenfolge:

1. **WHO FRAME** (Höchste Priorität)
   - Grund: Aktuell kaputt, häufig genutzt
   - Aufwand: 2-3 Tage
   - Komplexität: Mittel

2. **RAID FRAME** (Hohe Priorität)
   - Grund: Essentiell für Raids, Protected-Functions sind Herausforderung
   - Aufwand: 3-5 Tage
   - Komplexität: Hoch

3. **QUICK JOIN** (Mittlere Priorität)
   - Grund: Nützlich aber nicht kritisch
   - Aufwand: 2-3 Tage
   - Komplexität: Mittel

4. **RAF** (Niedrige Priorität)
   - Grund: Nur relevant für User mit aktivem RAF
   - Aufwand: 1-2 Tage
   - Komplexität: Niedrig

---

## 📝 Checkliste pro Feature

### WHO Frame
- [ ] EditBox mit InstructionsMixin
- [ ] Dynamic Height Adjustment
- [ ] Column Header Dropdown (Zone/Guild/Race)
- [ ] ScrollBox mit Extent Calculator
- [ ] Button Template mit Selection
- [ ] Tooltip für truncated text
- [ ] Action Buttons (Invite, Add Friend)
- [ ] SendWho auf Enter-Press

### RAID Frame
- [ ] Tab-System (Raid List + Raid Info)
- [ ] Raid Member List mit ScrollBox
- [ ] Selection System
- [ ] Context Menu (UnitPopup)
- [ ] Convert to Raid/Party Buttons
- [ ] Difficulty Dropdown
- [ ] Ready Check Button
- [ ] Role Poll Button
- [ ] Everyone is Assistant Checkbox
- [ ] Restrict Pings Dropdown
- [ ] Raid Info mit Saved Instances
- [ ] Extend Raid Lock Button

### QUICK JOIN
- [ ] Social Queue API Integration
- [ ] Group List mit ScrollBox
- [ ] Request Invite Buttons
- [ ] Quick Join Toast Button
- [ ] Event Handling (SOCIAL_QUEUE_UPDATE)
- [ ] Activity Icons
- [ ] Member Count Display

### RAF
- [ ] RAF Info API
- [ ] Recruit List
- [ ] Summon Friend Button
- [ ] Cooldown Display
- [ ] Rewards Display
- [ ] Generate Link Button

---

## 🔍 Wichtige API-Referenzen

### WHO
- `C_FriendList.SendWho(query, origin)`
- `C_FriendList.GetNumWhoResults()`
- `C_FriendList.GetWhoInfo(index)`
- `C_FriendList.SortWho(sortType)` -- "zone", "guild", "race"

### RAID
- `GetNumGroupMembers()` - Anzahl Raid-Mitglieder
- `GetRaidRosterInfo(index)` - Details zu Raid-Mitglied
- `IsInRaid()` - Prüfen ob in Raid
- `C_PartyInfo.ConvertToRaid()` - Party zu Raid konvertieren
- `C_PartyInfo.ConvertToParty()` - Raid zu Party konvertieren
- `DoReadyCheck()` - Ready Check starten
- `InitiateRolePoll()` - Role Poll starten
- `SetEveryoneIsAssistant(enabled)` - Everyone Assist setzen
- `IsEveryoneAssistant()` - Everyone Assist Status

### QUICK JOIN
- `C_SocialQueue.GetAllGroups()`
- `C_SocialQueue.GetGroupForPlayer(guid)`
- `C_SocialQueue.GetGroupMembers(guid)`
- `C_SocialQueue.GetGroupQueues(guid)`
- `C_SocialQueue.RequestToJoin(guid)`

### RAF
- `C_RecruitAFriend.GetRAFInfo()`
- `C_RecruitAFriend.CanSummonFriend(guid)`
- `C_RecruitAFriend.RequestSummon(guid)`
- `C_RecruitAFriend.GetSummonFriendCooldown()`
- `C_RecruitAFriend.IsEnabled()`

---

## 🎓 Lern-Ressourcen

### Blizzard Source Code
- **Hauptquelle**: https://github.com/Gethe/wow-ui-source/tree/live/Interface/AddOns/Blizzard_FriendsFrame
- **Raid Frames**: https://github.com/Gethe/wow-ui-source/tree/live/Interface/AddOns/Blizzard_RaidFrame
- **Social Queue**: https://github.com/Gethe/wow-ui-source/tree/live/Interface/AddOns/Blizzard_SocialQueue

### WoW API Documentation
- **Wiki**: https://warcraft.wiki.gg/wiki/World_of_Warcraft_API
- **Friends API**: https://warcraft.wiki.gg/wiki/Category:API_functions/Friends
- **Group API**: https://warcraft.wiki.gg/wiki/Category:API_functions/Group
- **Protected Functions**: https://warcraft.wiki.gg/wiki/Protected_function

---

## ✅ Erfolgs-Kriterien

**Die Implementierung gilt als erfolgreich wenn**:
1. ✅ Alle Features von Blizzards FriendsFrame 1:1 nachgebaut sind
2. ✅ Keine Lua-Errors auftreten
3. ✅ UI ist responsive und performant
4. ✅ Protected Functions werden korrekt behandelt
5. ✅ Alle Edge-Cases sind getestet
6. ✅ Code ist dokumentiert und wartbar

---

**Letzte Aktualisierung**: 28. Oktober 2025
**Version**: 1.0
**Autor**: GitHub Copilot für BetterFriendlist Projekt
