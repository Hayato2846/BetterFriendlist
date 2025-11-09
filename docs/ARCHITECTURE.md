# BetterFriendlist - Architecture Documentation
**Version 0.13** | Last Updated: October 31, 2025

## 📐 Overview

BetterFriendlist follows a **modular architecture** with clear separation of concerns:
- **Core Layer**: Event system, module registry
- **Business Logic Layer**: Feature modules (13 modules)
- **Utility Layer**: Shared utilities (3 utilities)
- **Presentation Layer**: UI glue code, XML callbacks

## 🏗️ Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                      PRESENTATION LAYER                      │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ BetterFriendlist.lua (1515 lines)                     │  │
│  │ - XML Callbacks (21 functions)                        │  │
│  │ - Event Handlers (UI updates)                         │  │
│  │ - Thin Wrappers (delegate to modules)                 │  │
│  └───────────────────────────────────────────────────────┘  │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ BetterFriendlist.xml                                  │  │
│  │ - Frame Definitions                                    │  │
│  │ - Templates                                            │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                    BUSINESS LOGIC LAYER                      │
│  ┌─────────────────────┐  ┌─────────────────────┐          │
│  │ Core Modules        │  │ Feature Modules      │          │
│  │ - Database (394)    │  │ - FriendsList (1344) │          │
│  │ - Groups (696)      │  │ - WhoFrame (640)     │          │
│  │ - Settings (241)    │  │ - IgnoreList (137)   │          │
│  │                     │  │ - RecentAllies (133) │          │
│  │                     │  │ - RAF (305)          │          │
│  └─────────────────────┘  └─────────────────────┘          │
│  ┌─────────────────────┐  ┌─────────────────────┐          │
│  │ UI Modules          │  │ System Modules       │          │
│  │ - MenuSystem (420)  │  │ - QuickFilters (75)  │          │
│  │ - Dialogs (159)     │  │ - ButtonPool (378)   │          │
│  │ - FrameInit (313)   │  │                      │          │
│  └─────────────────────┘  └─────────────────────┘          │
└─────────────────────────────────────────────────────────────┘
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                       UTILITY LAYER                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ FontManager  │  │ ColorManager │  │ AnimHelpers  │      │
│  │ (113 lines)  │  │ (71 lines)   │  │ (40 lines)   │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                         CORE LAYER                           │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ Core.lua (107 lines)                                  │  │
│  │ - Module Registry (RegisterModule, GetModule)         │  │
│  │ - Event Callback System (RegisterEventCallback)       │  │
│  │ - Version Management                                   │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## 📦 Module Inventory

### Core Modules (3)
| Module | Lines | Purpose |
|--------|-------|---------|
| **Database.lua** | 394 | SavedVariables management, migration system |
| **Groups.lua** | 696 | Friend group management, group operations |
| **Settings.lua** | 241 | Settings framework, getters/setters |

### Feature Modules (6)
| Module | Lines | Purpose |
|--------|-------|---------|
| **FriendsList.lua** | 1344 | Friends list core logic, display rendering |
| **WhoFrame.lua** | 640 | WHO system, player search |
| **IgnoreList.lua** | 137 | Ignore list management |
| **RecentAllies.lua** | 133 | Recent allies tracking |
| **RAF.lua** | 305 | Recruit-A-Friend system |
| **QuickFilters.lua** | 75 | Filter logic (all/online/offline/wow/bnet) |

### UI Modules (3)
| Module | Lines | Purpose |
|--------|-------|---------|
| **MenuSystem.lua** | 420 | Context menus, UnitPopup integration |
| **Dialogs.lua** | 159 | StaticPopup dialogs |
| **ButtonPool.lua** | 378 | Button recycling, drag & drop |

### System Modules (1)
| Module | Lines | Purpose |
|--------|-------|---------|
| **FrameInitializer.lua** | 313 | UI initialization (dropdowns, tabs, etc.) |

### Utilities (3)
| Utility | Lines | Purpose |
|---------|-------|---------|
| **FontManager.lua** | 113 | Font scaling system |
| **ColorManager.lua** | 71 | Color management (groups, classes) |
| **AnimationHelpers.lua** | 40 | Animation utilities |

## 🔄 Data Flow

### Friend List Update Flow
```
User Action / WoW Event
    ▼
Event Handler (BetterFriendlist.lua)
    ▼
BFL:FireEventCallbacks(event, ...)
    ▼
Module Event Callbacks (FriendsList, WhoFrame, etc.)
    ▼
Update Module State
    ▼
UpdateFriendsList() → FriendsList:UpdateFriendsList()
    ▼
BuildDisplayList() → FriendsList:BuildDisplayList()
    ▼
UpdateFriendsDisplay() → FriendsList:RenderDisplay()
    ▼
ButtonPool:GetOrCreateFriendButton()
    ▼
UI Update Complete
```

### Group Management Flow
```
User Right-Click → Context Menu
    ▼
MenuSystem:AddGroupsToFriendMenu()
    ▼
User Selects Group
    ▼
Groups:ToggleFriendInGroup(friendUID, groupId)
    ▼
Database:SaveFriendGroups()
    ▼
UpdateFriendsList() + UpdateFriendsDisplay()
```

## 🎯 Design Principles

### 1. Separation of Concerns
- **Business Logic** lives in Modules/
- **UI Code** (XML callbacks) lives in BetterFriendlist.lua
- **Shared Utilities** live in Utils/

### 2. Module Independence
- Modules don't depend on each other directly
- Communication via Core.lua event system
- Modules accessed via `BFL:GetModule("Name")`

### 3. Thin UI Layer
- BetterFriendlist.lua is **pure glue code** (1515 lines)
- Only contains:
  - XML-required callback functions (21)
  - Event handlers for UI updates
  - Thin wrappers delegating to modules

### 4. Event-Driven Architecture
- Core.lua provides event callback system
- Modules register for WoW events they care about
- Loose coupling between components

### 5. Button Pooling
- ButtonPool.lua manages object recycling
- Reduces memory allocation/GC pressure
- Improves performance with large friend lists

## 📊 Code Statistics (v0.13)

| Metric | Value |
|--------|-------|
| **Total Lines** | ~6,800 |
| **Main File** | 1,515 lines (-66% from original) |
| **Modules** | 13 modules, 5,061 lines |
| **Utils** | 3 utilities, 224 lines |
| **Core** | 107 lines |
| **Reduction** | -2,785 lines from original (~4500+) |

## 🔧 Extension Points

### Adding a New Module

1. Create `Modules/YourModule.lua`:
```lua
local ADDON_NAME, BFL = ...
local YourModule = BFL:RegisterModule("YourModule", {})

function YourModule:Initialize()
    -- Setup
end

-- Register for events
BFL:RegisterEventCallback("YOUR_EVENT", function(...)
    YourModule:OnEvent(...)
end, 10)

return YourModule
```

2. Add to `BetterFriendlist.toc`:
```
Modules\YourModule.lua
```

3. Access from main file:
```lua
local YourModule = BFL:GetModule("YourModule")
```

### Adding Event Callbacks

```lua
-- In your module
BFL:RegisterEventCallback("FRIENDLIST_UPDATE", function(...)
    MyModule:OnFriendListUpdate(...)
end, priority) -- Lower priority = runs first
```

## 🚀 Future Architecture

### Planned Modules (v0.14-1.0)
- **RaidFrame.lua** - Raid management system
- **QuickJoin.lua** - Social queue integration

### Post-1.0 Enhancements
- **Notifications.lua** - Friend online/offline notifications
- **Statistics.lua** - Friend activity tracking
- **Themes.lua** - UI theming system

## 📝 Notes

- **XML Callbacks**: 21 functions MUST remain in BetterFriendlist.lua (called from XML)
- **Module Load Order**: Defined in .toc file (Core → Utils → Modules → UI → Main)
- **Performance**: Throttling system prevents lag from rapid events (0.1s throttle)
- **Memory**: Button pooling reduces GC pressure
- **Compatibility**: WoW 11.0.2+ (Interface 110205)

---

*For API reference, see [API_REFERENCE.md](API_REFERENCE.md)*  
*For event flow details, see [EVENT_FLOW.md](EVENT_FLOW.md)*
