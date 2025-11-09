# Raid Frame Implementation Roadmap
**Ziel: 1:1 visuell und funktional Blizzards klassischen Raid Frame replizieren**

## Übersicht
Basierend auf Analyse von:
- `Blizzard_RaidUI/Blizzard_RaidUI.lua` (klassisches Raid Frame)
- `Blizzard_RaidFrame/RaidFrame.lua` (modernes Interface)
- API-Dokumentation (warcraft.wiki.gg)
- Cell Addon als Referenz für Drag & Drop

---

## Phase 8.8: Visual & Functional Raid Frame Replication ✅ ABGESCHLOSSEN

### Status: Vollständig implementiert (v0.13)
- ✅ 8 Group Structure mit je 5 Slots
- ✅ Rich UI Member Buttons mit allen visuellen Elementen
- ✅ Visual Indicators (Online, Dead, Class Colors)
- ✅ Ready Check System (Icons, Colors, Sounds)
- ✅ Combat-Aware Overlay System
- ✅ Drag & Drop (deaktiviert im Combat)
- ✅ Role Icons (Tank/Healer/DPS)
- ✅ Rank Icons (Leader/Assistant)
- ✅ Control Panel mit Ready Check Button
- ✅ Everyone is Assistant Checkbox
- ✅ Role Summary Display
- ✅ **Raid Info Button mit Blizzard's RaidInfoFrame Integration**
  - Hijackt temporär Blizzard's RaidInfoFrame
  - Zeigt es als Pop-out rechts neben BetterFriendsFrame
  - Top-aligned positioning
  - Movable & ESC-closable
  - Automatische Wiederherstellung beim Schließen
  - Button disabled wenn keine saved instances

### 8.8.1: Member List Layout - 8 Group Structure ✅
**Status**: Vollständig implementiert

**Implementation Details**:
- XML Structure mit 8 RaidGroup Frames
- Je 5 Slots pro Group (total 40 Slots)
- Layout: 2 Reihen à 4 Groups
- Group Titles mit Nummerierung
- Background Textures mit Blizzard's Raid-Bar-Hp-Bg

**Dateien**:
- `BetterFriendlist.xml` (RaidGroupTemplate, BetterRaidMemberButtonTemplate)
- `Modules/RaidFrame.lua` (Layout Logic)

---

### 8.8.2: Member Button Template - Rich UI Elements ✅
```xml
<!-- XML Structure -->
<Frame name="$parentGroup1" inherits="RaidGroupTemplate">
    <Frames>
        <Button name="$parentSlot1" inherits="RaidMemberButtonTemplate"/>
        <Button name="$parentSlot2" inherits="RaidMemberButtonTemplate"/>
        <Button name="$parentSlot3" inherits="RaidMemberButtonTemplate"/>
        <Button name="$parentSlot4" inherits="RaidMemberButtonTemplate"/>
        <Button name="$parentSlot5" inherits="RaidMemberButtonTemplate"/>
    </Frames>
</Frame>
<!-- Repeat for Group 2-8 -->
```

**Layout**:
- 8 Group Frames horizontal angeordnet (oder 2 Reihen à 4 Groups)
- Jede Group: 5 vertikale Slots
- Group Title: "Group 1", "Group 2", etc.
- Gesamtgröße: ~600px breit × 400px hoch

**Tasks**:
- [ ] RaidGroupTemplate in XML definieren
- [ ] 8 Group Frames erstellen (RaidGroup1-8)
- [ ] Je 5 Slot Frames pro Group (RaidGroup1Slot1-5, etc.)
- [ ] Layout Anchoring (horizontal flow)
- [ ] Group Title Labels
- [ ] **TODO: Role Icons visuell unterscheidbar machen** - Aktuelle groupfinder-icon-role-large-* Atlas Icons sehen alle gleich aus, alternative Icons recherchieren und implementieren

**Dateien**:
- `BetterFriendlist.xml` (neue RaidGroupTemplate)
- `Modules/RaidFrame.lua` (Update Layout Logic)

---

### 8.8.2: Member Button Template - Rich UI Elements
**Ziel**: Erstelle einen detailreichen Member Button mit allen visuellen Elementen

**Template Structure**:
```xml
<Button name="RaidMemberButtonTemplate" inherits="SecureActionButtonTemplate" virtual="true">
    <Size x="120" y="22"/>
    <Layers>
        <Layer level="BACKGROUND">
            <Texture parentKey="Background"/>
            <Texture parentKey="CombatOverlay" hidden="true"/>  <!-- CRITICAL -->
        </Layer>
        <Layer level="ARTWORK">
            <FontString parentKey="Name" inherits="GameFontNormalSmall"/>
            <FontString parentKey="Class" inherits="GameFontNormalSmall"/>
            <FontString parentKey="Level" inherits="GameFontNormalSmall"/>
        </Layer>
        <Layer level="OVERLAY">
            <Texture parentKey="RankIcon"/>       <!-- Leader/Assistant -->
            <Texture parentKey="RoleIcon"/>       <!-- Tank/Healer/DPS -->
            <Texture parentKey="ReadyCheckIcon"/> <!-- Ready/Not Ready/Waiting -->
        </Layer>
    </Layers>
    <Scripts>
        <OnLoad>BetterRaidMemberButton_OnLoad(self)</OnLoad>
        <OnEnter>BetterRaidMemberButton_OnEnter(self)</OnEnter>
        <OnLeave>BetterRaidMemberButton_OnLeave(self)</OnLeave>
        <OnClick>BetterRaidMemberButton_OnClick(self, button)</OnClick>
        <OnDragStart>BetterRaidMemberButton_OnDragStart(self)</OnDragStart>
        <OnDragStop>BetterRaidMemberButton_OnDragStop(self)</OnDragStop>
    </Scripts>
</Button>
```

**Subframe Layout**:
- **Name**: Left-aligned, mit Class Color
- **Class**: Right-aligned (oder unter Name)
- **Level**: Prefix vor Name (z.B. "80 PlayerName")
- **RankIcon**: Top-right (16×16px)
  * Leader: Interface\GroupFrame\UI-Group-LeaderIcon
  * Assistant: Interface\GroupFrame\UI-Group-AssistantIcon
- **RoleIcon**: Bottom-right (16×16px)
  * Tank: Interface\LFGFrame\UI-LFG-ICON-PORTRAITROLES (coords für Tank)
  * Healer: Interface\LFGFrame\UI-LFG-ICON-PORTRAITROLES (coords für Healer)
  * DPS: Interface\LFGFrame\UI-LFG-ICON-PORTRAITROLES (coords für DPS)
- **ReadyCheckIcon**: Center-overlay (32×32px)
  * Ready: Interface\RaidFrame\ReadyCheck-Ready
  * Not Ready: Interface\RaidFrame\ReadyCheck-NotReady
  * Waiting: Interface\RaidFrame\ReadyCheck-Waiting
- **CombatOverlay**: Full-size gray overlay (hidden by default)

**Tasks**:
- [ ] RaidMemberButtonTemplate XML Template erstellen
- [ ] OnLoad: RegisterForDrag("LeftButton"), RegisterForClicks
- [ ] OnEnter: UnitFrame_UpdateTooltip (zeigt Unit Info)
- [ ] OnLeave: GameTooltip:Hide()
- [ ] OnClick: Left = Select, Right = Context Menu
- [ ] Subframe Positioning

**Dateien**:
- `BetterFriendlist.xml` (RaidMemberButtonTemplate)
- `BetterFriendlist.lua` (Button Handler Functions)

---

### 8.8.3: Visual Indicators - Status & Colors
**Ziel**: Implementiere alle visuellen Status-Anzeigen (Online, Dead, Class Colors, etc.)

**Color States**:
```lua
-- Online & Alive: Class Color
local color = RAID_CLASS_COLORS[fileName]
button.Name:SetTextColor(color.r, color.g, color.b)

-- Offline: Gray
button.Name:SetTextColor(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b)

-- Dead: Red
button.Name:SetTextColor(RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b)
```

**Icon States**:
```lua
-- Rank Icon (Leader/Assistant)
if rank == 2 then  -- Leader
    button.RankIcon:SetTexture("Interface\\GroupFrame\\UI-Group-LeaderIcon")
    button.RankIcon:Show()
elseif rank == 1 then  -- Assistant
    button.RankIcon:SetTexture("Interface\\GroupFrame\\UI-Group-AssistantIcon")
    button.RankIcon:Show()
else
    button.RankIcon:Hide()
end

-- Role Icon (Assigned Role)
if combatRole == "TANK" then
    button.RoleIcon:SetAtlas("roleicon-tiny-tank")
    button.RoleIcon:Show()
elseif combatRole == "HEALER" then
    button.RoleIcon:SetAtlas("roleicon-tiny-healer")
    button.RoleIcon:Show()
elseif combatRole == "DAMAGER" then
    button.RoleIcon:SetAtlas("roleicon-tiny-dps")
    button.RoleIcon:Show()
else
    button.RoleIcon:Hide()
end

-- Ready Check Icon
local readyStatus = GetReadyCheckStatus("raid"..raidIndex)
if readyStatus == "ready" then
    button.ReadyCheckIcon:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
    button.ReadyCheckIcon:Show()
elseif readyStatus == "notready" then
    button.ReadyCheckIcon:SetTexture("Interface\\RaidFrame\\ReadyCheck-NotReady")
    button.ReadyCheckIcon:Show()
elseif readyStatus == "waiting" then
    button.ReadyCheckIcon:SetTexture("Interface\\RaidFrame\\ReadyCheck-Waiting")
    button.ReadyCheckIcon:Show()
else
    button.ReadyCheckIcon:Hide()
end
```

**Range Check** (Optional Feature):
```lua
-- Alpha Fade für Out-of-Range Members
local inRange = UnitInRange("raid"..raidIndex)
if not inRange then
    button:SetAlpha(0.5)  -- RAID_RANGE_ALPHA
else
    button:SetAlpha(1.0)
end
```

**Tasks**:
- [ ] UpdateMemberButton() Funktion in RaidFrame.lua
- [ ] Class Color Application
- [ ] Online/Offline Detection (via GetRaidRosterInfo)
- [ ] Dead Detection (via UnitIsDead or GetRaidRosterInfo isDead)
- [ ] Rank Icon Update (Leader/Assistant)
- [ ] Role Icon Update (Tank/Healer/DPS)
- [ ] Ready Check Icon Update
- [ ] Range Check (optional, performance-intensiv)
- [ ] Event Handlers:
  * RAID_ROSTER_UPDATE
  * UNIT_HEALTH (für Dead Status)
  * READY_CHECK, READY_CHECK_CONFIRM, READY_CHECK_FINISHED

**Dateien**:
- `Modules/RaidFrame.lua` (UpdateMemberButton, Color Logic)
- `BetterFriendlist.lua` (Event Handler Wrapper)

---

### 8.8.4: Drag & Drop System Base
**Ziel**: Implementiere Drag & Drop für Member Reordering (ohne Combat-Check)

**Blizzard Pattern** (Blizzard_RaidUI.lua, lines 576-627):
```lua
-- Global State
local MOVING_RAID_MEMBER = nil
local TARGET_RAID_SLOT = nil

function BetterRaidMemberButton_OnDragStart(self)
    -- Permission Check
    if not (UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")) then
        return
    end
    
    -- Start Moving
    self:StartMoving()
    MOVING_RAID_MEMBER = self
end

function BetterRaidMemberButton_OnDragStop(self)
    -- Permission Check
    if not (UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")) then
        return
    end
    
    -- Stop Moving
    self:StopMovingOrSizing()
    self:ClearAllPoints()
    self:SetPoint("TOPLEFT", self.slot, "TOPLEFT", 0, 0)
    
    MOVING_RAID_MEMBER = nil
    
    -- Target Slot vorhanden?
    if TARGET_RAID_SLOT then
        local targetGroup = TARGET_RAID_SLOT:GetParent():GetID()
        local sourceGroup = self.subgroup
        
        -- Verschiedene Groups? → SetRaidSubgroup oder SwapRaidSubgroup
        if targetGroup ~= sourceGroup then
            if TARGET_RAID_SLOT.button then
                -- Swap mit anderem Member
                SwapRaidSubgroup(self:GetID(), TARGET_RAID_SLOT.button:GetID())
            else
                -- Leerer Slot → Move
                SetRaidSubgroup(self:GetID(), targetGroup)
            end
        end
        
        TARGET_RAID_SLOT:UnlockHighlight()
        TARGET_RAID_SLOT = nil
    end
end

-- Slot OnEnter während Drag
function BetterRaidSlot_OnEnter(self)
    if MOVING_RAID_MEMBER then
        TARGET_RAID_SLOT = self
        self:LockHighlight()
    end
end

-- Slot OnLeave während Drag
function BetterRaidSlot_OnLeave(self)
    if MOVING_RAID_MEMBER and TARGET_RAID_SLOT == self then
        self:UnlockHighlight()
        TARGET_RAID_SLOT = nil
    end
end
```

**Protected Functions**:
- `SetRaidSubgroup(raidIndex, subgroup)` - Verschiebt Member zu Gruppe
- `SwapRaidSubgroup(raidIndex1, raidIndex2)` - Tauscht zwei Members
- **RESTRICTED**: #nocombat - Seit Patch 4.0.1 nicht im Kampf aufrufbar

**Tasks**:
- [ ] Global State Variables (MOVING_RAID_MEMBER, TARGET_RAID_SLOT)
- [ ] OnDragStart Handler (StartMoving + Permission Check)
- [ ] OnDragStop Handler (StopMoving + SetRaidSubgroup/SwapRaidSubgroup)
- [ ] Slot OnEnter/OnLeave (Highlight Target Slot)
- [ ] Anchor System (selbst Buttons zu Slots zuordnen)
- [ ] Visual Feedback während Drag (z.B. Button Alpha)

**Dateien**:
- `BetterFriendlist.lua` (Drag & Drop Handlers)
- `BetterFriendlist.xml` (Slot Templates mit OnEnter/OnLeave)

---

### 8.8.5: Combat-Aware Overlay System ⭐ **CRITICAL**
**Ziel**: Graues Overlay über Buttons während Combat + Disable Drag & Drop

**User Requirement**:
> "Diese Funktion ist innerhalb des Kampfes für Addons nicht verfügbar. Es wäre also schön, wenn Frame, das für den Drag and Drop genutzt wird, im Kampf ein graues Overlay hat und darauf hinweist, dass diese Funktion innerhalb des Kampfes nicht zur Verfügung steht."

**Implementation**:
```lua
-- Combat State Tracking
local inCombat = false

-- Event Handler
function BetterRaidFrame_OnCombatStart()
    inCombat = true
    
    -- Show gray overlay on ALL member buttons
    for i = 1, 40 do
        local button = _G["RaidGroupButton"..i]
        if button and button:IsShown() then
            button.CombatOverlay:Show()
        end
    end
end

function BetterRaidFrame_OnCombatEnd()
    inCombat = false
    
    -- Hide gray overlay on ALL member buttons
    for i = 1, 40 do
        local button = _G["RaidGroupButton"..i]
        if button then
            button.CombatOverlay:Hide()
        end
    end
end

-- Drag Check Integration
function BetterRaidMemberButton_OnDragStart(self)
    -- Combat Check FIRST
    if InCombatLockdown() then
        return  -- Abort drag
    end
    
    -- Permission Check
    if not (UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")) then
        return
    end
    
    self:StartMoving()
    MOVING_RAID_MEMBER = self
end

-- Tooltip on Hover während Combat
function BetterRaidMemberButton_OnEnter(self)
    UnitFrame_UpdateTooltip(self)  -- Normal tooltip
    
    if InCombatLockdown() then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Drag & Drop is unavailable during combat", RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b)
        GameTooltip:Show()
    end
end
```

**Overlay Texture**:
```xml
<Texture parentKey="CombatOverlay" hidden="true" setAllPoints="true">
    <Color r="0.5" g="0.5" b="0.5" a="0.5"/>
</Texture>
```

**Events**:
- `PLAYER_REGEN_DISABLED` → BetterRaidFrame_OnCombatStart()
- `PLAYER_REGEN_ENABLED` → BetterRaidFrame_OnCombatEnd()

**Tasks**:
- [ ] CombatOverlay Texture in RaidMemberButtonTemplate
- [ ] PLAYER_REGEN_DISABLED Event Handler
- [ ] PLAYER_REGEN_ENABLED Event Handler
- [ ] InCombatLockdown() Check in OnDragStart
- [ ] Tooltip Enhancement während Combat
- [ ] Visual Feedback (gray overlay, 50% alpha)

**Dateien**:
- `BetterFriendlist.xml` (CombatOverlay Texture)
- `Modules/RaidFrame.lua` (Combat Event Handlers)
- `BetterFriendlist.lua` (OnDragStart Check)

---

### 8.8.6: Class Filter Buttons - 12 Button System
**Ziel**: 12 Filter Buttons wie Blizzard's Raid Frame (9 Classes + PETS + MAINTANK + MAINASSIST)

**Button List**:
1. Warrior
2. Paladin
3. Hunter
4. Rogue
5. Priest
6. Death Knight
7. Shaman
8. Mage
9. Warlock
10. Monk
11. Demon Hunter
12. Druid
13. Evoker
14. **PETS** (Hunter/Warlock Pets)
15. **MAINTANK** (Assigned Main Tanks)
16. **MAINASSIST** (Assigned Main Assists)

**Button Template**:
```xml
<Button name="RaidClassButtonTemplate" virtual="true">
    <Size x="40" y="40"/>
    <Layers>
        <Layer level="BACKGROUND">
            <Texture parentKey="Icon"/>
        </Layer>
        <Layer level="OVERLAY">
            <FontString parentKey="Count" inherits="NumberFontNormal"/>
        </Layer>
    </Layers>
    <Scripts>
        <OnClick>BetterRaidClassButton_OnClick(self)</OnClick>
        <OnEnter>BetterRaidClassButton_OnEnter(self)</OnEnter>
        <OnLeave>GameTooltip:Hide()</OnLeave>
    </Scripts>
</Button>
```

**Functionality**:
```lua
-- OnClick: Filter Raid List
function BetterRaidClassButton_OnClick(self)
    local className = self.className  -- "WARRIOR", "PRIEST", etc.
    local RaidFrame = BFL:GetModule("RaidFrame")
    
    -- Toggle Filter
    if RaidFrame.classFilter == className then
        RaidFrame.classFilter = nil  -- Show all
    else
        RaidFrame.classFilter = className  -- Show only this class
    end
    
    -- Update Display
    BetterRaidFrame_Update()
end

-- OnEnter: Tooltip mit Namen
function BetterRaidClassButton_OnEnter(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(self.className .. " (" .. self.count .. ")", 1, 1, 1)
    
    -- List Member Names
    local RaidFrame = BFL:GetModule("RaidFrame")
    local members = RaidFrame:GetMembersByClass(self.className)
    for _, name in ipairs(members) do
        GameTooltip:AddLine(name, 1, 1, 1)
    end
    
    GameTooltip:Show()
end

-- Update Count Badge
function BetterRaidClassButton_Update(button, className)
    local RaidFrame = BFL:GetModule("RaidFrame")
    local count = RaidFrame:GetClassCount(className)
    
    button.Count:SetText(count)
    
    if count > 0 then
        button:Enable()
        button.Icon:SetAlpha(1.0)
    else
        button:Disable()
        button.Icon:SetAlpha(0.5)
    end
end
```

**Icon Coordinates** (CLASS_ICON_TCOORDS):
```lua
local CLASS_ICON_TCOORDS = {
    ["WARRIOR"]     = { 0,      0.25,   0,      0.25 },
    ["MAGE"]        = { 0.25,   0.49609375, 0, 0.25 },
    ["ROGUE"]       = { 0.49609375, 0.7421875, 0, 0.25 },
    ["DRUID"]       = { 0.7421875, 0.98828125, 0, 0.25 },
    ["HUNTER"]      = { 0, 0.25, 0.25, 0.5 },
    ["SHAMAN"]      = { 0.25, 0.49609375, 0.25, 0.5 },
    ["PRIEST"]      = { 0.49609375, 0.7421875, 0.25, 0.5 },
    ["WARLOCK"]     = { 0.7421875, 0.98828125, 0.25, 0.5 },
    ["PALADIN"]     = { 0, 0.25, 0.5, 0.75 },
    ["DEATHKNIGHT"] = { 0.25, 0.49609375, 0.5, 0.75 },
    ["MONK"]        = { 0.49609375, 0.7421875, 0.5, 0.75 },
    ["DEMONHUNTER"] = { 0.7421875, 0.98828125, 0.5, 0.75 },
    ["EVOKER"]      = { 0.0, 0.25, 0.75, 1.0 },
}
```

**Layout**:
- Horizontal Row über der Member List
- Oder 2 Reihen (7 + 7 buttons)
- Spacing: 2px zwischen Buttons

**Tasks**:
- [ ] RaidClassButtonTemplate XML
- [ ] 16 Class Buttons erstellen (inkl. PETS, MAINTANK, MAINASSIST)
- [ ] Icon Textures setzen (CLASS_ICON_TCOORDS)
- [ ] OnClick Filter Logic
- [ ] OnEnter Tooltip mit Namen
- [ ] Count Badge Update
- [ ] RaidFrame:GetMembersByClass(className)
- [ ] RaidFrame:GetClassCount(className)
- [ ] Filter Logic in BuildDisplayList()

**Dateien**:
- `BetterFriendlist.xml` (Class Buttons)
- `BetterFriendlist.lua` (Click/Tooltip Handlers)
- `Modules/RaidFrame.lua` (Filter Logic, Class Counting)

---

### 8.8.7: Enhanced Control Panel - Additional Features
**Ziel**: Erweitere Control Panel um fehlende Blizzard-Features

**Neue Features**:

1. **Role Count Display** (Tank/Healer/DPS Counter):
```xml
<Frame parentKey="RoleCount">
    <Layers>
        <Layer level="ARTWORK">
            <Texture parentKey="TankIcon" atlas="roleicon-tiny-tank"/>
            <FontString parentKey="TankCount" text="0"/>
            
            <Texture parentKey="HealerIcon" atlas="roleicon-tiny-healer"/>
            <FontString parentKey="HealerCount" text="0"/>
            
            <Texture parentKey="DPSIcon" atlas="roleicon-tiny-dps"/>
            <FontString parentKey="DPSCount" text="0"/>
        </Layer>
    </Layers>
</Frame>
```

```lua
function BetterRaidFrame_UpdateRoleCount()
    local RaidFrame = BFL:GetModule("RaidFrame")
    local tankCount, healerCount, dpsCount = RaidFrame:GetRoleCounts()
    
    frame.RoleCount.TankCount:SetText(tankCount)
    frame.RoleCount.HealerCount:SetText(healerCount)
    frame.RoleCount.DPSCount:SetText(dpsCount)
end
```

2. **Difficulty Dropdown**:
```lua
-- Dropdown Menu
local function SetDifficulty(difficultyID)
    local RaidFrame = BFL:GetModule("RaidFrame")
    RaidFrame:SetRaidDifficulty(difficultyID)
end

local difficultyDropdown = CreateFrame("DropdownButton", nil, controlPanel, "WowStyle1DropdownTemplate")
difficultyDropdown:SetupMenu(function(dropdown, rootDescription)
    rootDescription:CreateRadio("Normal (10/25)", IsSelected, SetDifficulty, 14)
    rootDescription:CreateRadio("Heroic (10/25)", IsSelected, SetDifficulty, 15)
    rootDescription:CreateRadio("Mythic (20)", IsSelected, SetDifficulty, 16)
    rootDescription:CreateRadio("Looking For Raid", IsSelected, SetDifficulty, 17)
end)
```

3. **Raid Info Button** (Opens Saved Instances):
```xml
<Button parentKey="RaidInfoButton" inherits="UIPanelButtonTemplate" text="Raid Info">
    <Scripts>
        <OnClick>
            BetterRaidFrame_ToggleInfoTab();
        </OnClick>
    </Scripts>
</Button>
```

**Tasks**:
- [ ] Role Count Frame + Icons
- [ ] RaidFrame:GetRoleCounts() (zählt TANK/HEALER/DAMAGER)
- [ ] Difficulty Dropdown Button
- [ ] Difficulty Selection Logic
- [ ] Raid Info Button (Toggle zu Info Tab)
- [ ] Layout Integration im Control Panel

**Dateien**:
- `BetterFriendlist.xml` (Role Count, Difficulty Dropdown, Info Button)
- `Modules/RaidFrame.lua` (GetRoleCounts, SetRaidDifficulty)
- `BetterFriendlist.lua` (Button Handlers)

---

### 8.8.8: Tab System - Roster/Info Toggle
**Ziel**: Implementiere Tab-System für Roster (Member List) und Info (Saved Instances)

**Tab Structure**:
```xml
<Frame parentKey="RaidFrame">
    <!-- Tab Buttons -->
    <Frame parentKey="Tabs">
        <Button parentKey="RosterTab" text="Raid Roster">
            <OnClick>BetterRaidFrame_SetTab(1)</OnClick>
        </Button>
        <Button parentKey="InfoTab" text="Raid Info">
            <OnClick>BetterRaidFrame_SetTab(2)</OnClick>
        </Button>
    </Frame>
    
    <!-- Content Frames -->
    <Frame parentKey="RosterContent" hidden="false">
        <!-- Member List, Groups, Class Buttons, Control Panel -->
    </Frame>
    
    <Frame parentKey="InfoContent" hidden="true">
        <!-- Saved Instances List (from Phase 8.4) -->
    </Frame>
</Frame>
```

**Tab Logic**:
```lua
function BetterRaidFrame_SetTab(tabIndex)
    local RaidFrame = BFL:GetModule("RaidFrame")
    RaidFrame:SetTab(tabIndex)
    
    local frame = BetterFriendsFrame.RaidFrame
    
    if tabIndex == 1 then
        -- Raid Roster
        frame.RosterContent:Show()
        frame.InfoContent:Hide()
        PanelTemplates_SetTab(frame, 1)
    elseif tabIndex == 2 then
        -- Raid Info
        frame.RosterContent:Hide()
        frame.InfoContent:Show()
        PanelTemplates_SetTab(frame, 2)
        
        -- Request Instance Info
        RaidFrame:RequestInstanceInfo()
        RaidFrame:UpdateSavedInstances()
    end
end
```

**Info Tab Content** (aus Phase 8.4):
- Saved Instances Liste (ScrollFrame)
- Instance Name, Difficulty, Progress, Reset Time
- "Extend Lock" Button pro Instance

**Tasks**:
- [ ] Tab Buttons (Roster, Info)
- [ ] Tab Content Frames (RosterContent, InfoContent)
- [ ] BetterRaidFrame_SetTab() Function
- [ ] PanelTemplates Integration (Tab Highlighting)
- [ ] Info Tab: Saved Instances Display
- [ ] Info Tab: Extend Lock Functionality

**Dateien**:
- `BetterFriendlist.xml` (Tab Buttons, Content Frames)
- `BetterFriendlist.lua` (SetTab Handler)
- `Modules/RaidFrame.lua` (SetTab, UpdateSavedInstances)

---

### 8.8.9: Context Menus - Right-Click Actions
**Ziel**: Implementiere UnitPopup Context Menu für Raid Members

**Implementation**:
```lua
function BetterRaidMemberButton_OnClick(self, button)
    if button == "LeftButton" then
        -- Selection (z.B. Target setzen)
        if self.unit then
            TargetUnit(self.unit)
        end
    elseif button == "RightButton" then
        -- Context Menu öffnen
        if self.unit and self.name then
            local contextData = {
                unit = self.unit,
                name = self.name,
            }
            UnitPopup_OpenMenu("RAID", contextData)
        end
    end
end
```

**UnitPopup Actions** (Blizzard Default):
- Whisper
- Invite
- Request Invite
- Promote to Assistant
- Demote from Assistant
- Set as Main Tank
- Set as Main Assist
- Remove from Group
- Report Player
- Add Friend
- Ignore
- Trade
- Follow
- Inspect
- Achievement
- Compare Achievements

**Tasks**:
- [ ] OnClick Handler (Left = Select, Right = Menu)
- [ ] UnitPopup_OpenMenu("RAID", contextData)
- [ ] Unit/Name Tracking pro Button
- [ ] Ensure context menu only opens für valid units

**Dateien**:
- `BetterFriendlist.lua` (OnClick Handler)

---

### 8.8.10: Range Check & Performance Optimization
**Ziel**: Optional: Range Check mit Alpha Fade + Performance für 40-man Raids

**Range Check** (Performance-Intensiv):
```lua
-- Optional Feature: Alpha Fade für Out-of-Range Members
function BetterRaidFrame_UpdateRange()
    -- Only if CVar "showRaidRange" is enabled
    if not GetCVarBool("showRaidRange") then
        return
    end
    
    for i = 1, 40 do
        local button = _G["RaidGroupButton"..i]
        if button and button:IsShown() and button.unit then
            local inRange = UnitInRange(button.unit)
            if inRange == false then
                button:SetAlpha(0.5)  -- RAID_RANGE_ALPHA
            else
                button:SetAlpha(1.0)
            end
        end
    end
end

-- Throttle Updates (max 10 Hz = alle 0.1s)
local rangeCheckThrottle = 0
function BetterRaidFrame_OnUpdate(elapsed)
    rangeCheckThrottle = rangeCheckThrottle + elapsed
    if rangeCheckThrottle >= 0.1 then
        rangeCheckThrottle = 0
        BetterRaidFrame_UpdateRange()
    end
end
```

**Performance Optimization**:
1. **Throttling**: Range Check max 10 Hz (alle 0.1s)
2. **Lazy Updates**: Nur sichtbare Buttons updaten
3. **Event Batching**: Mehrere ROSTER_UPDATE Events in 0.1s zusammenfassen
4. **Memory Pooling**: Button Reuse statt ständiges Create/Destroy

**Tasks**:
- [ ] Range Check Logic (UnitInRange)
- [ ] OnUpdate Handler mit Throttling
- [ ] CVar Check (showRaidRange)
- [ ] Performance Profiling (40-man raid)
- [ ] Memory Leak Check
- [ ] Event Throttling (ROSTER_UPDATE batching)

**Dateien**:
- `Modules/RaidFrame.lua` (Range Check, Throttling)
- `BetterFriendlist.xml` (OnUpdate Script)

---

## API Reference

### Protected Functions (Combat Restricted)
```lua
-- Move member to different subgroup
SetRaidSubgroup(raidIndex, subgroup)
-- raidIndex: 1-40 (raid member ID)
-- subgroup: 1-8 (target group)
-- RESTRICTED: #nocombat (since Patch 4.0.1)

-- Swap two members between subgroups
SwapRaidSubgroup(raidIndex1, raidIndex2)
-- RESTRICTED: #nocombat (since Patch 4.0.1)
```

### Raid Roster Info
```lua
-- Get raid member info
name, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML, combatRole = GetRaidRosterInfo(raidIndex)
-- raidIndex: 1-40
-- name: "PlayerName-ServerName" (cross-realm)
-- rank: 2=Leader, 1=Assistant, 0=Member
-- subgroup: 1-8 (raid group)
-- level: 1-80 (0 if offline)
-- class: Localized class name ("Priest")
-- fileName: System class name ("PRIEST")
-- zone: Current zone (or "Offline")
-- online: 1=online, nil=offline
-- isDead: 1=dead, nil=alive
-- role: "MAINTANK" or "MAINASSIST" (special roles)
-- isML: 1=Master Looter, nil=not
-- combatRole: "TANK", "HEALER", "DAMAGER", "NONE"
```

### Combat Lockdown
```lua
-- Check if in combat lockdown
inLockdown = InCombatLockdown()
-- Returns true if restricted, false otherwise

-- Events
PLAYER_REGEN_DISABLED  -- Combat starts
PLAYER_REGEN_ENABLED   -- Combat ends
```

### Ready Check
```lua
-- Get ready check status
status = GetReadyCheckStatus(unit)
-- Returns: "ready", "notready", "waiting", or nil

-- Events
READY_CHECK            -- Ready check started
READY_CHECK_CONFIRM    -- Player responded
READY_CHECK_FINISHED   -- Ready check ended
```

### Class Icons
```lua
-- Texture coordinates for class icons
CLASS_ICON_TCOORDS["WARRIOR"] = { 0, 0.25, 0, 0.25 }
-- etc. (siehe 8.8.6)

-- Texture file
"Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes"
```

---

## Testing Checklist

### Functional Tests
- [ ] **5-man Party**: Alle 5 Members angezeigt
- [ ] **10-man Raid**: 2 Groups à 5 Members
- [ ] **20-man Raid**: 4 Groups à 5 Members
- [ ] **40-man Raid**: 8 Groups à 5 Members (full load test)
- [ ] **Drag & Drop**: Member verschieben zwischen Groups
- [ ] **Drag & Drop in Combat**: Overlay erscheint, Drag disabled
- [ ] **Combat Exit**: Overlay verschwindet, Drag enabled
- [ ] **Class Filter**: Click auf Warrior → nur Warriors angezeigt
- [ ] **Class Filter Count**: Badge zeigt korrekte Anzahl
- [ ] **Ready Check**: Icons erscheinen korrekt (Ready, Not Ready, Waiting)
- [ ] **Leader/Assistant Icons**: Gold Crown, Shield Icons
- [ ] **Role Icons**: Tank, Healer, DPS Icons
- [ ] **Online/Offline**: Graue Farbe für Offline
- [ ] **Dead**: Rote Farbe für Dead
- [ ] **Context Menu**: Right-Click öffnet Raid Menu
- [ ] **Tab Toggle**: Wechsel zwischen Roster und Info Tab
- [ ] **Saved Instances**: Info Tab zeigt Instances
- [ ] **Role Count**: Tank/Healer/DPS Counter aktualisiert
- [ ] **Difficulty Dropdown**: Auswahl ändert Difficulty
- [ ] **Convert to Raid/Party**: Buttons funktionieren
- [ ] **Everyone is Assistant**: Checkbox funktioniert

### Performance Tests
- [ ] **40-man Raid**: FPS bleibt stabil (>30 FPS)
- [ ] **Memory Usage**: Kein Memory Leak über Zeit
- [ ] **Event Spam**: ROSTER_UPDATE Events throttled
- [ ] **Range Check**: Optional, max 10% FPS Impact

### Visual Tests
- [ ] **Layout**: Alle 8 Groups sichtbar, keine Überlappung
- [ ] **Icons**: Alle Textures laden korrekt
- [ ] **Colors**: Class Colors korrekt (RAID_CLASS_COLORS)
- [ ] **Font Sizes**: Lesbar bei allen UI Scales
- [ ] **Tooltips**: Alle Hover-Tooltips funktionieren
- [ ] **Combat Overlay**: Grau, 50% Alpha, über gesamtem Button

---

## Estimated Time & Complexity

| Phase | Tasks | Complexity | Time Estimate |
|-------|-------|------------|---------------|
| 8.8.1 | Member List Layout | Medium | 2-3 hours |
| 8.8.2 | Member Button Template | High | 4-5 hours |
| 8.8.3 | Visual Indicators | Medium | 3-4 hours |
| 8.8.4 | Drag & Drop Base | High | 4-5 hours |
| 8.8.5 | Combat Overlay System | Medium | 2-3 hours |
| 8.8.6 | Class Filter Buttons | Medium | 3-4 hours |
| 8.8.7 | Enhanced Control Panel | Low | 2-3 hours |
| 8.8.8 | Tab System | Low | 1-2 hours |
| 8.8.9 | Context Menus | Low | 1-2 hours |
| 8.8.10 | Range Check & Perf | Medium | 2-3 hours |
| **TOTAL** | **10 Sub-Phases** | **High** | **25-35 hours** |

---

## Dependencies & Prerequisites

**Already Implemented** (Phase 8.1-8.6):
- ✅ RaidFrame.lua Modul (546 Zeilen Backend Logic)
- ✅ UpdateRaidMembers(), BuildDisplayList(), SortDisplayList()
- ✅ ConvertToRaid/Party(), DoReadyCheck(), DoRolePoll()
- ✅ Event System (6 Events: RAID_ROSTER_UPDATE, GROUP_ROSTER_UPDATE, etc.)
- ✅ XML UI Base Structure (ScrollFrame + Control Panel)
- ✅ 8 XML Callbacks (OnShow, OnHide, Update, Button Handlers)

**New Requirements**:
- Blizzard_RaidUI Referenz für Layout/Design
- Cell Addon Referenz für Drag & Drop
- Extensive XML Templates (RaidGroupTemplate, RaidMemberButtonTemplate, RaidSlotTemplate)
- Button Pooling System (40 buttons)
- Class Icon Textures
- Role Icon Atlases

---

## Notes & Warnings

⚠️ **CRITICAL COMBAT RESTRICTIONS**:
- `SetRaidSubgroup()` und `SwapRaidSubgroup()` sind #nocombat restricted
- MUSS Combat Overlay implementieren (User Requirement!)
- Tooltip muss User informieren: "Unavailable during combat"

⚠️ **PERFORMANCE**:
- 40 Buttons gleichzeitig = viele UI Updates
- Range Check ist optional (CPU-intensiv)
- Throttle Updates auf max 10 Hz (alle 0.1s)
- Event Batching für ROSTER_UPDATE

⚠️ **BLIZZARD API**:
- GetRaidRosterInfo() kann "holes" haben (index 1-40, nicht alle belegt)
- Immer auf nil-Checks achten
- UnitPopup_OpenMenu benötigt contextData mit unit + name

⚠️ **VISUAL FIDELITY**:
- User will 1:1 Replica, keine "simpleren Lösungen"
- Alle Icons, Colors, States müssen exakt sein
- Layout muss identisch zu Blizzard sein

---

## Success Criteria

✅ **Phase 8.8 Complete** wenn:
1. 8 Raid Groups mit je 5 Slots visuell korrekt dargestellt
2. Alle 40 Member Buttons mit Name, Class, Level, Icons (Rank, Role, Ready Check)
3. Class Colors, Online/Offline, Dead States korrekt
4. Drag & Drop funktioniert (Leader/Assistant only, außerhalb Combat)
5. **Combat Overlay** erscheint im Kampf mit Tooltip
6. 12 Class Filter Buttons funktionieren mit Count Badges
7. Role Count Display (Tank/Healer/DPS)
8. Difficulty Dropdown funktioniert
9. Tab System (Roster/Info) funktioniert
10. Context Menu (Right-Click) funktioniert
11. Performance OK bei 40-man Raid (>30 FPS)
12. Keine Lua Errors, keine Memory Leaks

---

## Next Steps After Phase 8.8

Nach Completion von Phase 8.8 ist der Raid Tab **vollständig funktional**. Dann:

**Phase 9: Quick Join Tab** (nächste große Feature-Phase)
**Phase 10: Polish & Testing** (finale Tests, Bug Fixes, Performance)
**Phase 11: Version 1.0 Release** (nach Feature-Parität mit Blizzard)

---

**Revision History**:
- v1.0 (2025-10-31): Initial Roadmap erstellt nach API-Recherche
