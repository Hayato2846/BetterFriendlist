# BetterFriendlist - API Reference
**Version 0.13** | Last Updated: October 31, 2025

## 📚 Table of Contents

- [Core API](#core-api)
- [Module APIs](#module-apis)
  - [Database](#database-module)
  - [Groups](#groups-module)
  - [FriendsList](#friendslist-module)
  - [WhoFrame](#whoframe-module)
  - [IgnoreList](#ignorelist-module)
  - [RecentAllies](#recentallies-module)
  - [MenuSystem](#menusystem-module)
  - [QuickFilters](#quickfilters-module)
  - [Settings](#settings-module)
  - [Dialogs](#dialogs-module)
  - [ButtonPool](#buttonpool-module)
  - [RAF](#raf-module)
  - [FrameInitializer](#frameinitializer-module)
- [Utility APIs](#utility-apis)
  - [FontManager](#fontmanager)
  - [ColorManager](#colormanager)
  - [AnimationHelpers](#animationhelpers)

---

## Core API

### BFL (Core Namespace)

#### `BFL:RegisterModule(name, module)`
Register a new module with the addon.

**Parameters:**
- `name` (string) - Unique module name
- `module` (table) - Module object

**Returns:** The registered module

**Example:**
```lua
local MyModule = BFL:RegisterModule("MyModule", {})
```

---

#### `BFL:GetModule(name)`
Retrieve a registered module.

**Parameters:**
- `name` (string) - Module name

**Returns:** Module object or nil

**Example:**
```lua
local DB = BFL:GetModule("DB")
```

---

#### `BFL:RegisterEventCallback(event, callback, priority)`
Register a callback for a WoW event.

**Parameters:**
- `event` (string) - WoW event name (e.g., "FRIENDLIST_UPDATE")
- `callback` (function) - Callback function
- `priority` (number, optional) - Priority (lower = runs first, default: 100)

**Example:**
```lua
BFL:RegisterEventCallback("FRIENDLIST_UPDATE", function(...)
    print("Friend list updated!")
end, 50)
```

---

#### `BFL:FireEventCallbacks(event, ...)`
Fire all registered callbacks for an event.

**Parameters:**
- `event` (string) - Event name
- `...` - Event arguments

**Example:**
```lua
BFL:FireEventCallbacks("FRIENDLIST_UPDATE")
```

---

## Module APIs

### Database Module

#### `DB:Initialize()`
Initialize the database and perform migrations.

**Returns:** void

---

#### `DB:Get(key, default)`
Get a setting value.

**Parameters:**
- `key` (string) - Setting key (dot notation supported, e.g., "ui.compactMode")
- `default` (any, optional) - Default value if key doesn't exist

**Returns:** Setting value or default

**Example:**
```lua
local compactMode = DB:Get("ui.compactMode", false)
```

---

#### `DB:Set(key, value)`
Set a setting value.

**Parameters:**
- `key` (string) - Setting key
- `value` (any) - Value to set

**Returns:** void

**Example:**
```lua
DB:Set("ui.compactMode", true)
```

---

#### `DB:GetFriendGroups(friendUID)`
Get group IDs for a friend.

**Parameters:**
- `friendUID` (string) - Friend unique ID (e.g., "bnet_12345")

**Returns:** Array of group IDs

---

#### `DB:SaveFriendGroups(friendUID, groupIds)`
Save group assignments for a friend.

**Parameters:**
- `friendUID` (string) - Friend unique ID
- `groupIds` (table) - Array of group IDs

**Returns:** void

---

### Groups Module

#### `Groups:Initialize()`
Initialize groups system with default groups.

**Returns:** void

---

#### `Groups:GetAll()`
Get all groups.

**Returns:** Table of group data keyed by group ID

**Example:**
```lua
local groups = Groups:GetAll()
for groupId, groupData in pairs(groups) do
    print(groupData.name)
end
```

---

#### `Groups:Get(groupId)`
Get a specific group.

**Parameters:**
- `groupId` (string) - Group ID

**Returns:** Group data table or nil

---

#### `Groups:Create(groupId, name, color, icon)`
Create a new group.

**Parameters:**
- `groupId` (string) - Unique group ID
- `name` (string) - Group display name
- `color` (table, optional) - RGB color {r, g, b}
- `icon` (string, optional) - Icon texture path

**Returns:** Created group data

---

#### `Groups:Delete(groupId)`
Delete a group.

**Parameters:**
- `groupId` (string) - Group ID to delete

**Returns:** boolean (success)

---

#### `Groups:Rename(groupId, newName)`
Rename a group.

**Parameters:**
- `groupId` (string) - Group ID
- `newName` (string) - New name

**Returns:** boolean (success)

---

#### `Groups:ToggleFriendInGroup(friendUID, groupId)`
Toggle friend membership in a group.

**Parameters:**
- `friendUID` (string) - Friend unique ID
- `groupId` (string) - Group ID

**Returns:** void

---

#### `Groups:IsFriendInGroup(friendUID, groupId)`
Check if friend is in a group.

**Parameters:**
- `friendUID` (string) - Friend unique ID
- `groupId` (string) - Group ID

**Returns:** boolean

---

#### `Groups:RemoveFriendFromGroup(friendUID, groupId)`
Remove friend from a group.

**Parameters:**
- `friendUID` (string) - Friend unique ID
- `groupId` (string) - Group ID

**Returns:** void

---

#### `Groups:GetFriendsInGroup(groupId)`
Get all friends in a group.

**Parameters:**
- `groupId` (string) - Group ID

**Returns:** Array of friend UIDs

---

### FriendsList Module

#### `FriendsList:Initialize()`
Initialize friends list system.

**Returns:** void

---

#### `FriendsList:SetSearchText(text)`
Set search filter text.

**Parameters:**
- `text` (string) - Search query (lowercase)

**Returns:** void

---

#### `FriendsList:SetFilterMode(mode)`
Set filter mode.

**Parameters:**
- `mode` (string) - Filter mode: "all", "online", "offline", "wow", "bnet"

**Returns:** void

---

#### `FriendsList:SetSortMode(mode)`
Set sort mode.

**Parameters:**
- `mode` (string) - Sort mode: "status", "name", "level", "zone"

**Returns:** void

---

#### `FriendsList:UpdateFriendsList()`
Fetch and update friend data from WoW API.

**Returns:** void

---

#### `FriendsList:BuildDisplayList()`
Build sorted/filtered display list with groups.

**Returns:** void

---

#### `FriendsList:RenderDisplay()`
Render friends list to UI (main display function).

**Returns:** void

**Note:** This is the largest function (680+ lines) containing all UI rendering logic:
- ScrollBox/ScrollBar synchronization
- Button pooling
- BNet vs WoW friend rendering
- Compact mode support
- Game icons, status icons, TravelPass buttons

---

### WhoFrame Module

#### `WhoFrame:Initialize()`
Initialize WHO system.

**Returns:** void

---

#### `WhoFrame:Update()`
Update WHO list display.

**Returns:** void

---

#### `WhoFrame:SendQuery(name, level, class, race, zone, guild)`
Send WHO query to server.

**Parameters:**
- `name` (string, optional) - Player name filter
- `level` (number, optional) - Level filter
- `class` (string, optional) - Class filter
- `race` (string, optional) - Race filter
- `zone` (string, optional) - Zone filter
- `guild` (string, optional) - Guild filter

**Returns:** void

---

#### `WhoFrame:GetSortMode()`
Get current WHO sort mode.

**Returns:** number (1=Zone, 2=Level, 3=Class, 4=Race, 5=Name, 6=Guild)

---

#### `WhoFrame:SetSortMode(mode)`
Set WHO sort mode.

**Parameters:**
- `mode` (number) - Sort mode (1-6)

**Returns:** void

---

### IgnoreList Module

#### `IgnoreList:Initialize()`
Initialize ignore list system.

**Returns:** void

---

#### `IgnoreList:Update()`
Update ignore list display.

**Returns:** void

---

#### `IgnoreList:GetNumIgnores()`
Get number of ignored players.

**Returns:** number

---

### RecentAllies Module

#### `RecentAllies:Initialize()`
Initialize recent allies tracking.

**Returns:** void

---

#### `RecentAllies:Update()`
Update recent allies display.

**Returns:** void

---

#### `RecentAllies:ClearAllRecent()`
Clear all recent allies.

**Returns:** void

---

### MenuSystem Module

#### `MenuSystem:Initialize()`
Initialize context menu system.

**Returns:** void

---

#### `MenuSystem:AddGroupsToFriendMenu(rootDescription, contextData)`
Add group management options to friend context menu.

**Parameters:**
- `rootDescription` (table) - Menu root
- `contextData` (table) - Context data with friend info

**Returns:** void

---

### QuickFilters Module

#### `QuickFilters:Initialize()`
Initialize quick filter buttons.

**Returns:** void

---

#### `QuickFilters:SetActiveFilter(filterMode)`
Set active filter and update UI.

**Parameters:**
- `filterMode` (string) - "all", "online", "offline", "wow", "bnet"

**Returns:** void

---

#### `QuickFilters:Update()`
Update filter button states.

**Returns:** void

---

### Settings Module

#### `Settings:Initialize()`
Initialize settings framework.

**Returns:** void

---

#### `Settings:RegisterSetting(key, default, validator, callback)`
Register a setting.

**Parameters:**
- `key` (string) - Setting key
- `default` (any) - Default value
- `validator` (function, optional) - Validation function
- `callback` (function, optional) - Change callback

**Returns:** void

---

#### `Settings:Get(key)`
Get setting value.

**Parameters:**
- `key` (string) - Setting key

**Returns:** Setting value

---

#### `Settings:Set(key, value)`
Set setting value.

**Parameters:**
- `key` (string) - Setting key
- `value` (any) - New value

**Returns:** boolean (success)

---

### Dialogs Module

#### `Dialogs:Initialize()`
Initialize StaticPopup dialogs.

**Returns:** void

---

#### `Dialogs:ShowCreateGroup()`
Show "Create Group" dialog.

**Returns:** void

---

#### `Dialogs:ShowRenameGroup(groupId)`
Show "Rename Group" dialog.

**Parameters:**
- `groupId` (string) - Group to rename

**Returns:** void

---

#### `Dialogs:ShowDeleteGroup(groupId)`
Show "Delete Group" confirmation.

**Parameters:**
- `groupId` (string) - Group to delete

**Returns:** void

---

### ButtonPool Module

#### `ButtonPool:Initialize(parentFrame)`
Initialize button pool.

**Parameters:**
- `parentFrame` (frame) - Parent frame for buttons

**Returns:** void

---

#### `ButtonPool:GetOrCreateFriendButton()`
Get or create a friend button from pool.

**Returns:** Button frame

---

#### `ButtonPool:GetOrCreateHeaderButton()`
Get or create a group header button from pool.

**Returns:** Button frame

---

#### `ButtonPool:ReleaseFriendButton(button)`
Return friend button to pool.

**Parameters:**
- `button` (frame) - Button to release

**Returns:** void

---

#### `ButtonPool:ReleaseHeaderButton(button)`
Return header button to pool.

**Parameters:**
- `button` (frame) - Button to release

**Returns:** void

---

#### `ButtonPool:ReleaseAllButtons()`
Release all buttons back to pool.

**Returns:** void

---

#### `ButtonPool:GetFriendButtonCount()`
Get number of active friend buttons.

**Returns:** number

---

#### `ButtonPool:GetHeaderButtonCount()`
Get number of active header buttons.

**Returns:** number

---

### RAF Module

#### `RAF:Initialize()`
Initialize Recruit-A-Friend system.

**Returns:** void

---

#### `RAF:Update()`
Update RAF display.

**Returns:** void

---

#### `RAF:GetRecruitInfo()`
Get recruit information.

**Returns:** Table with recruit data

---

### FrameInitializer Module

#### `FrameInitializer:Initialize(frame)`
Initialize all UI components.

**Parameters:**
- `frame` (frame) - Main addon frame

**Returns:** void

---

#### `FrameInitializer:InitializeStatusDropdown()`
Initialize status dropdown menu.

**Returns:** void

---

#### `FrameInitializer:InitializeSortDropdown()`
Initialize sort dropdown menu.

**Returns:** void

---

#### `FrameInitializer:InitializeTabs()`
Initialize bottom tabs.

**Returns:** void

---

#### `FrameInitializer:SetupBroadcastFrame()`
Setup broadcast/status message frame.

**Returns:** void

---

## Utility APIs

### FontManager

#### `FontManager:ApplyFontSize(fontString, multiplier)`
Apply font size with multiplier.

**Parameters:**
- `fontString` (fontString) - Font string object
- `multiplier` (number, optional) - Size multiplier (default: 1.0)

**Returns:** void

---

#### `FontManager:GetButtonHeight()`
Get button height based on font size.

**Returns:** number (height in pixels)

---

#### `FontManager:GetFontSizeMultiplier()`
Get current font size multiplier.

**Returns:** number

---

### ColorManager

#### `ColorManager:GetGroupColorCode(groupId)`
Get color code string for a group.

**Parameters:**
- `groupId` (string) - Group ID

**Returns:** string ("|cFFRRGGBB" format)

---

#### `ColorManager:GetClassColor(className)`
Get class color.

**Parameters:**
- `className` (string) - Class name (e.g., "WARRIOR")

**Returns:** table {r, g, b}

---

#### `ColorManager:GetStatusColor(status)`
Get status color.

**Parameters:**
- `status` (string) - "online", "away", "busy", "offline"

**Returns:** table {r, g, b}

---

### AnimationHelpers

#### `AnimationHelpers:CreatePulseAnimation(frame)`
Create pulse animation for a frame.

**Parameters:**
- `frame` (frame) - Frame to animate

**Returns:** AnimationGroup

**Example:**
```lua
local anim = AnimationHelpers:CreatePulseAnimation(myButton)
anim:Play()
```

---

## 🔧 Common Usage Patterns

### Getting Friend Data
```lua
local FriendsList = BFL:GetModule("FriendsList")
FriendsList:UpdateFriendsList()
local friends = FriendsList.friendsList
```

### Managing Groups
```lua
local Groups = BFL:GetModule("Groups")
Groups:Create("guild", "Guild Members", {r=0.5, g=1.0, b=0.5})
Groups:ToggleFriendInGroup("bnet_12345", "guild")
```

### Setting Filters
```lua
local FriendsList = BFL:GetModule("FriendsList")
FriendsList:SetSearchText("bob")
FriendsList:SetFilterMode("online")
FriendsList:SetSortMode("name")
FriendsList:UpdateFriendsList()
FriendsList:RenderDisplay()
```

### Using Button Pool
```lua
local ButtonPool = BFL:GetModule("ButtonPool")
local button = ButtonPool:GetOrCreateFriendButton()
button:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -offset)
button:Show()
-- Later...
ButtonPool:ReleaseFriendButton(button)
```

---

*For architecture overview, see [ARCHITECTURE.md](ARCHITECTURE.md)*  
*For event flow details, see [EVENT_FLOW.md](EVENT_FLOW.md)*
