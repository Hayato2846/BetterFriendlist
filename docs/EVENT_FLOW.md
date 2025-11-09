# BetterFriendlist - Event Flow Documentation
**Version 0.13** | Last Updated: October 31, 2025

## 📡 Overview

BetterFriendlist uses an **event-driven architecture** with a centralized callback system. This document describes how events flow through the addon and how modules respond to WoW events.

## 🔄 Event System Architecture

### Core Event System (Core.lua)

The event callback system is implemented in `Core.lua`:

```lua
BFL.EventCallbacks = {}

-- Register a callback for an event
function BFL:RegisterEventCallback(event, callback, priority)
    priority = priority or 100
    
    if not self.EventCallbacks[event] then
        self.EventCallbacks[event] = {}
    end
    
    table.insert(self.EventCallbacks[event], {
        callback = callback,
        priority = priority
    })
    
    -- Sort by priority (lower = runs first)
    table.sort(self.EventCallbacks[event], function(a, b)
        return a.priority < b.priority
    end)
end

-- Fire all callbacks for an event
function BFL:FireEventCallbacks(event, ...)
    if self.EventCallbacks[event] then
        for _, callbackData in ipairs(self.EventCallbacks[event]) do
            callbackData.callback(...)
        end
    end
end
```

### Priority System

- **Lower priority = runs first**
- Default priority: 100
- Recommended ranges:
  - **1-25**: Critical pre-processing
  - **26-75**: Data updates
  - **76-100**: UI updates (default)
  - **101+**: Post-processing, logging

---

## 📋 Registered Events by Module

### FriendsList Module

**Events:**
- `FRIENDLIST_UPDATE` - WoW friend list changed
- `BN_FRIEND_LIST_SIZE_CHANGED` - Number of BNet friends changed
- `BN_FRIEND_ACCOUNT_ONLINE` - BNet friend came online
- `BN_FRIEND_ACCOUNT_OFFLINE` - BNet friend went offline
- `BN_FRIEND_INFO_CHANGED` - BNet friend info updated

**Registration (in Modules/FriendsList.lua):**
```lua
-- Register event callbacks
BFL:RegisterEventCallback("FRIENDLIST_UPDATE", function(...)
    FriendsList:OnFriendListUpdate(...)
end, 50)

BFL:RegisterEventCallback("BN_FRIEND_LIST_SIZE_CHANGED", function(...)
    FriendsList:OnFriendListUpdate(...)
end, 50)

BFL:RegisterEventCallback("BN_FRIEND_ACCOUNT_ONLINE", function(...)
    FriendsList:OnFriendListUpdate(...)
end, 50)

BFL:RegisterEventCallback("BN_FRIEND_ACCOUNT_OFFLINE", function(...)
    FriendsList:OnFriendListUpdate(...)
end, 50)

BFL:RegisterEventCallback("BN_FRIEND_INFO_CHANGED", function(...)
    FriendsList:OnFriendListUpdate(...)
end, 50)
```

**Handler:**
```lua
function FriendsList:OnFriendListUpdate(...)
    -- Update internal friend list
    -- This runs BEFORE UI updates (priority 50)
end
```

### WhoFrame Module

**Events:**
- `WHO_LIST_UPDATE` - WHO query results received

**Registration (in Modules/WhoFrame.lua):**
```lua
BFL:RegisterEventCallback("WHO_LIST_UPDATE", function(...)
    WhoFrame:OnWhoListUpdate(...)
end, 50)
```

**Handler:**
```lua
function WhoFrame:OnWhoListUpdate(...)
    -- Process WHO results
end
```

---

## 🌊 Event Flow Examples

### Example 1: Friend Comes Online

```
┌─────────────────────────────────────────────────────┐
│ WoW Event: BN_FRIEND_ACCOUNT_ONLINE                  │
└───────────────────┬─────────────────────────────────┘
                    ▼
┌─────────────────────────────────────────────────────┐
│ Event Handler (BetterFriendlist.lua:759)             │
│ frame:SetScript("OnEvent", function(self, event...)  │
└───────────────────┬─────────────────────────────────┘
                    ▼
┌─────────────────────────────────────────────────────┐
│ BFL:FireEventCallbacks("BN_FRIEND_ACCOUNT_ONLINE")  │
│ (Core.lua)                                           │
└───────────────────┬─────────────────────────────────┘
                    ▼
┌─────────────────────────────────────────────────────┐
│ Module Callbacks (Priority Order)                    │
│                                                       │
│ 1. FriendsList:OnFriendListUpdate() [Priority 50]   │
│    - Update friendsList array                        │
│    - Refresh friend data from WoW API                │
│                                                       │
│ 2. [Other modules if registered]                     │
└───────────────────┬─────────────────────────────────┘
                    ▼
┌─────────────────────────────────────────────────────┐
│ UI Update (BetterFriendlist.lua:769)                 │
│ if BetterFriendsFrame:IsShown() then                 │
│     RequestUpdate() -- Throttled update              │
│ end                                                   │
└───────────────────┬─────────────────────────────────┘
                    ▼
┌─────────────────────────────────────────────────────┐
│ Throttled Update (BetterFriendlist.lua:433)         │
│ - Check throttle timer (0.1s)                        │
│ - UpdateFriendsList()                                │
│ - UpdateFriendsDisplay()                             │
└───────────────────┬─────────────────────────────────┘
                    ▼
┌─────────────────────────────────────────────────────┐
│ UpdateFriendsList() → FriendsList:UpdateFriendsList()│
│ - Fetch friend data from WoW API                     │
│ - Apply search filter                                │
│ - Apply filter mode (all/online/offline/wow/bnet)    │
│ - Sort friends                                       │
└───────────────────┬─────────────────────────────────┘
                    ▼
┌─────────────────────────────────────────────────────┐
│ BuildDisplayList() → FriendsList:BuildDisplayList() │
│ - Group friends by custom groups                     │
│ - Create display list with headers                   │
└───────────────────┬─────────────────────────────────┘
                    ▼
┌─────────────────────────────────────────────────────┐
│ UpdateFriendsDisplay() → FriendsList:RenderDisplay()│
│ - Get/create buttons from ButtonPool                 │
│ - Render friend list to UI                           │
│ - Update ScrollBar                                   │
└─────────────────────────────────────────────────────┘
```

### Example 2: User Searches for Friend

```
┌─────────────────────────────────────────────────────┐
│ User Types in Search Box                             │
└───────────────────┬─────────────────────────────────┘
                    ▼
┌─────────────────────────────────────────────────────┐
│ BetterFriendsFrame_OnSearchTextChanged()             │
│ (XML Callback in BetterFriendlist.lua:480)          │
└───────────────────┬─────────────────────────────────┘
                    ▼
┌─────────────────────────────────────────────────────┐
│ FriendsList:SetSearchText(searchText)                │
└───────────────────┬─────────────────────────────────┘
                    ▼
┌─────────────────────────────────────────────────────┐
│ RequestUpdate() [Throttled]                          │
│ - Prevents lag from rapid typing                     │
│ - Only updates every 0.1 seconds                     │
└───────────────────┬─────────────────────────────────┘
                    ▼
┌─────────────────────────────────────────────────────┐
│ UpdateFriendsList() + UpdateFriendsDisplay()         │
│ - Search filter applied in UpdateFriendsList()       │
│ - UI updated in RenderDisplay()                      │
└─────────────────────────────────────────────────────┘
```

### Example 3: User Adds Friend to Group

```
┌─────────────────────────────────────────────────────┐
│ User Right-Clicks Friend → Select Group              │
└───────────────────┬─────────────────────────────────┘
                    ▼
┌─────────────────────────────────────────────────────┐
│ Context Menu Callback                                │
│ MenuSystem:AddGroupsToFriendMenu()                   │
└───────────────────┬─────────────────────────────────┘
                    ▼
┌─────────────────────────────────────────────────────┐
│ Groups:ToggleFriendInGroup(friendUID, groupId)      │
│ - Add/remove friend from group                       │
└───────────────────┬─────────────────────────────────┘
                    ▼
┌─────────────────────────────────────────────────────┐
│ Database:SaveFriendGroups(friendUID, groupIds)      │
│ - Update BetterFriendlistDB.friendGroups             │
└───────────────────┬─────────────────────────────────┘
                    ▼
┌─────────────────────────────────────────────────────┐
│ BetterFriendsFrame_UpdateDisplay()                   │
│ - Rebuild display list with new grouping             │
│ - Re-render UI                                       │
└─────────────────────────────────────────────────────┘
```

---

## ⏱️ Throttling System

To prevent lag from rapid events (e.g., friend list spam), BetterFriendlist implements throttling:

```lua
local lastUpdateTime = 0
local UPDATE_THROTTLE = 0.1 -- Only update every 0.1 seconds
local pendingUpdate = false

local function RequestUpdate()
    local currentTime = GetTime()
    
    -- If enough time has passed, update immediately
    if currentTime - lastUpdateTime >= UPDATE_THROTTLE then
        lastUpdateTime = currentTime
        pendingUpdate = false
        UpdateFriendsList()
        UpdateFriendsDisplay()
    else
        -- Otherwise, schedule a delayed update
        if not pendingUpdate then
            pendingUpdate = true
            C_Timer.After(UPDATE_THROTTLE, function()
                if pendingUpdate then
                    lastUpdateTime = GetTime()
                    pendingUpdate = false
                    UpdateFriendsList()
                    UpdateFriendsDisplay()
                end
            end)
        end
    end
end
```

**Benefits:**
- Prevents 100+ rapid FRIENDLIST_UPDATE events from lagging UI
- Batches updates together
- Guarantees update within 0.1 seconds of last event

---

## 📊 Event Priority Guidelines

### FriendsList Module Events

| Event | Priority | Reason |
|-------|----------|--------|
| FRIENDLIST_UPDATE | 50 | Update data before UI |
| BN_FRIEND_* | 50 | Update data before UI |

### WhoFrame Module Events

| Event | Priority | Reason |
|-------|----------|--------|
| WHO_LIST_UPDATE | 50 | Update data before UI |

### UI Updates (Main File)

| Operation | Priority | Location |
|-----------|----------|----------|
| Event → FireCallbacks | - | Event handler |
| RequestUpdate() | 100 (implicit) | After callbacks |
| UpdateFriendsList() | - | Throttled |
| UpdateFriendsDisplay() | - | Throttled |

---

## 🔧 Adding New Event Handlers

### In a Module

```lua
-- 1. Register event callback
BFL:RegisterEventCallback("YOUR_EVENT", function(...)
    YourModule:OnYourEvent(...)
end, 50) -- Priority 50 = runs before UI updates

-- 2. Implement handler
function YourModule:OnYourEvent(...)
    -- Process event
    -- Update module state
end
```

### In Main File

```lua
-- 3. Add event to frame registration (if not already registered)
frame:RegisterEvent("YOUR_EVENT")

-- 4. Fire callbacks in event handler
elseif event == "YOUR_EVENT" then
    -- Fire callbacks for modules
    BFL:FireEventCallbacks(event, ...)
    
    -- UI update (if needed)
    if BetterFriendsFrame and BetterFriendsFrame:IsShown() then
        RequestUpdate()
    end
end
```

---

## 🧪 Event Testing

### Simulating Events

```lua
-- Trigger friend list update
BFL:FireEventCallbacks("FRIENDLIST_UPDATE")

-- Trigger WHO update
BFL:FireEventCallbacks("WHO_LIST_UPDATE")

-- Check registered callbacks
for event, callbacks in pairs(BFL.EventCallbacks) do
    print("Event:", event, "#Callbacks:", #callbacks)
    for i, cb in ipairs(callbacks) do
        print("  Priority:", cb.priority)
    end
end
```

### Debugging Event Flow

```lua
-- Add logging to Core.lua
function BFL:FireEventCallbacks(event, ...)
    print("Firing callbacks for event:", event)
    if self.EventCallbacks[event] then
        for _, callbackData in ipairs(self.EventCallbacks[event]) do
            print("  Running callback (priority " .. callbackData.priority .. ")")
            callbackData.callback(...)
        end
    end
end
```

---

## 📝 Registered Events Summary

### Core WoW Events

| Event | Modules | Purpose |
|-------|---------|---------|
| **ADDON_LOADED** | Main | Initialize addon |
| **PLAYER_LOGIN** | Main | Setup UI, hooks |
| **FRIENDLIST_UPDATE** | FriendsList | Friend list changed |
| **BN_FRIEND_LIST_SIZE_CHANGED** | FriendsList | BNet friends changed |
| **BN_FRIEND_ACCOUNT_ONLINE** | FriendsList | Friend came online |
| **BN_FRIEND_ACCOUNT_OFFLINE** | FriendsList | Friend went offline |
| **BN_FRIEND_INFO_CHANGED** | FriendsList | Friend info updated |
| **WHO_LIST_UPDATE** | WhoFrame | WHO query results |
| **SOCIAL_QUEUE_UPDATE** | Main | Quick Join changed |
| **GROUP_LEFT** | Main | Left group |
| **GROUP_JOINED** | Main | Joined group |

### Module-Specific Events

| Module | Events Handled |
|--------|----------------|
| **FriendsList** | FRIENDLIST_UPDATE, BN_FRIEND_* (5 events) |
| **WhoFrame** | WHO_LIST_UPDATE |
| **IgnoreList** | (No events - manual update) |
| **RecentAllies** | (No events - manual update) |
| **RAF** | (Handled via frame OnEvent) |

---

## 🚀 Performance Considerations

### Event Throttling
- **FRIENDLIST_UPDATE** can fire 100+ times rapidly
- **Throttle to 0.1s** prevents lag
- **Batch updates** improve performance

### Priority Optimization
- **Data updates first** (priority 50)
- **UI updates last** (priority 100+)
- **Minimize UI redraws** per event

### Button Pooling
- **Reduces GC pressure** from button creation/destruction
- **Improves performance** with large friend lists
- **ButtonPool module** handles recycling

---

*For architecture overview, see [ARCHITECTURE.md](ARCHITECTURE.md)*  
*For API reference, see [API_REFERENCE.md](API_REFERENCE.md)*
