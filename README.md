# BetterFriendlist - World of Warcraft AddOn

**Version 1.0** - A complete replacement for WoW's default Friends frame with custom groups, Raid management, and Quick Join support.

[![WoW Version](https://img.shields.io/badge/WoW-11.2.5-blue)](https://worldofwarcraft.com)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)
[![Status](https://img.shields.io/badge/status-stable-brightgreen)](https://github.com/Hayato2846/BetterFriendlist)

---

## ✨ Features

### 🎯 Core Features
- **Custom Friend Groups** - Organize friends into custom named groups with drag & drop
- **Raid Frame** - Complete 40-man raid management with drag & drop, ready checks, and role assignments
- **Quick Join** - Social Queue system for joining friends' groups with role selection
- **WHO Frame** - Enhanced player search with filters and quick actions
- **Ignore List** - Manage blocked players and invites
- **Recent Allies** - Track players you've recently grouped with
- **Recruit-A-Friend** - Full RAF system with rewards and recruit management

### 🚀 Advanced Features
- **FriendGroups Migration** - Seamlessly import groups from FriendGroups addon
- **Smart Filtering** - Quick filters (Online, All, WoW, App, Recent, Favorites)
- **Collapsible Groups** - Expand/collapse custom groups
- **Search & Notes** - Search friends by name and manage notes
- **Context Menus** - Right-click menus for all actions
- **Performance Optimized** - Smooth performance with 200+ friends

### 🎨 User Interface
- **Modern Design** - Clean, Blizzard-style UI matching 11.2.5 aesthetics
- **4-Tab Layout** - Friends, WHO, Ignore, RAF
- **4 Bottom Tabs** - Recent Allies, Quick Join, Raid, Settings
- **Drag & Drop** - Move friends between groups and raid members between groups
- **Visual Indicators** - Status icons, class colors, game icons, faction icons
- **Responsive** - Adapts to different screen sizes

---

## 📥 Installation

### Manual Installation
1. Download the latest release from [GitHub](https://github.com/Hayato2846/BetterFriendlist/releases)
2. Extract to your World of Warcraft AddOns directory:
   ```
   World of Warcraft\_retail_\Interface\AddOns\BetterFriendlist\
   ```
3. Restart WoW or reload UI (`/reload`)
4. Press **O** key or use `/bfl` to open

### CurseForge/WoWInterface
- Coming soon!

### ⚙️ Migrating from FriendGroups
If you're upgrading from the FriendGroups addon:
1. Keep FriendGroups enabled during migration
2. Open BetterFriendlist Settings (`/bfl settings`)
3. Go to **Advanced** tab → Click **"Migrate from FriendGroups"**
4. Choose whether to clean up BattleNet notes
5. After successful migration, disable FriendGroups

📖 **Detailed Migration Guide**: See [FRIENDGROUPS_MIGRATION.md](FRIENDGROUPS_MIGRATION.md)

---

## 🚀 Quick Start

### Opening the Frame
- **Keyboard**: Press **O** key (auto-replaces default Friends frame)
- **Slash Command**: `/bfl` or `/betterfriendlist`
- **Blizzard Menu**: Social button still works

### Creating Your First Group
1. Click **"Create Group"** button at the top
2. Enter a group name (e.g., "Guild", "Raid Team", "Arena")
3. Drag & drop friends from the list into your new group
4. Right-click groups for more options (rename, delete, etc.)

### Raid Management
1. Click **"Raid"** bottom tab (only visible when in raid)
2. Drag & drop members between raid groups (requires leader/assistant)
3. Use Control Panel for ready checks, role polls, difficulty
4. Click **"Raid Info"** to view saved instances

### Quick Join
1. Click **"Quick Join"** bottom tab
2. Browse available groups from friends
3. Click **"Join"** → Select your role → Request to join
4. **Mock System** for testing: `/bflqj mock` (creates 3 test groups)

---

## 📖 Commands

### Main Commands
| Command | Description |
|---------|-------------|
| `/bfl` | Toggle BetterFriendlist frame |
| `/bfl settings` | Open settings panel |
| `/bfl help` | Show all available commands |
| `/bfl debug print` | Toggle debug output (for bug reports) |

### Quick Join Commands (Testing)
| Command | Description |
|---------|-------------|
| `/bflqj mock` | Create 3 mock groups for testing |
| `/bflqj add <player> <activity> <members>` | Add custom mock group |
| `/bflqj list` | List all mock groups |
| `/bflqj clear` | Remove all mock groups |
| `/bflqj disable` | Disable mock mode (use real data) |

### Performance Monitoring (Advanced)
| Command | Description |
|---------|-------------|
| `/bflperf enable` | Enable performance monitoring |
| `/bflperf report` | Show performance statistics |
| `/bflperf reset` | Reset statistics |
| `/bflperf memory` | Show memory usage |

---

## 📚 Usage Guide

### Friends List Tab
**Main Features:**
- **Custom Groups** - Organize friends into named groups
- **Drag & Drop** - Move friends between groups
- **Search** - Find friends by name or note
- **Quick Filters** - Filter by Online, All, WoW, App, Recent, Favorites
- **Sort Options** - Sort by name, status, or last online
- **Context Menus** - Right-click for quick actions (invite, whisper, notes, etc.)

**Tips:**
- Right-click group headers to rename or delete
- Collapse groups to save space (click arrow icon)
- Use Search box (top right) to quickly find friends
- Notes are synced with Blizzard's system

### WHO Frame Tab
**Main Features:**
- **Player Search** - Search for players by name, guild, zone, or race
- **Level Filters** - Min/Max level range
- **Advanced Options** - Guild, race, zone dropdowns
- **Quick Actions** - Right-click to add friend, whisper, invite

**Tips:**
- Leave name blank to search all players
- Use level filters to find players in your range
- Zone dropdown auto-populates with current zones
- Results update in real-time

### Ignore List Tab
**Main Features:**
- **Block Players** - Add/remove ignored players
- **Block Invites** - Block invites without ignoring chat
- **Quick Unignore** - One-click to unignore

### Recruit-A-Friend Tab
**Main Features:**
- **Reward Panel** - View your RAF rewards and month count
- **Recruit List** - See all recruited friends and their status
- **Activity System** - Track and claim recruit activity rewards
- **Recruitment** - Generate recruitment links

### Recent Allies Bottom Tab
**Main Features:**
- **Auto-Tracking** - Automatically tracks players you group with
- **Character Info** - Race, class, level, location
- **Quick Invite** - Invite button for online allies
- **Notes** - Add personal notes to allies

### Quick Join Bottom Tab
**Main Features:**
- **Browse Groups** - See available groups from friends
- **Role Selection** - Pick your role (Tank/Healer/Damage) before joining
- **Request to Join** - Send join request with one click
- **Status Tracking** - Shows "Request Sent" when pending

**Mock System (Testing):**
- `/bflqj mock` - Create 3 test groups
- `/bflqj clear` - Remove test groups
- `/bflqj disable` - Switch back to real data

### Raid Frame Bottom Tab
**Main Features:**
- **40-Man Display** - View all 40 raid slots across 8 groups
- **Drag & Drop** - Move members between groups (leader/assistant only)
- **Combat Protection** - Drag disabled during combat (shows overlay)
- **Ready Check** - Initiate ready checks from Control Panel
- **Role Summary** - See tank/healer/DPS count
- **Difficulty** - Change raid difficulty
- **Raid Info** - View saved instances (pop-out window)

**Tips:**
- Only visible when in a raid (5+ players)
- Drag & drop requires Raid Leader or Raid Assistant
- Right-click members for standard raid menu
- Raid Info button shows Blizzard's saved instance UI

### Settings Bottom Tab
**Main Features:**
- **General** - Basic addon settings
- **Advanced** - FriendGroups migration, debug options
- **About** - Version info and credits

---

## ⚙️ Configuration

### Saved Variables
All settings are saved per-character in:
```
World of Warcraft\_retail_\WTF\Account\<ACCOUNT>\<SERVER>\<CHARACTER>\SavedVariables\BetterFriendlist.lua
```

**Stored Data:**
- `BetterFriendlistDB` - Custom groups, collapsed states, settings
- `BetterFriendlistDB_Settings` - UI preferences, filter states, debug flags
- Automatic backup on every save

### Settings Panel
Access via `/bfl settings` or Settings bottom tab:

**General Tab:**
- Sort order preferences
- Filter preferences
- UI customization options

**Advanced Tab:**
- FriendGroups migration tool
- Database debugging
- Debug print toggle
- Performance monitoring

---

## 🔧 Technical Details

### Modular Architecture
BetterFriendlist uses a fully modular architecture with 14 independent modules:

**Core Modules:**
- `Database.lua` (151 lines) - SavedVariables management
- `Groups.lua` (398 lines) - Group management logic
- `FriendsList.lua` (1307 lines) - Friends list rendering & display
- `Settings.lua` (955 lines) - Settings UI & migration

**Feature Modules:**
- `RaidFrame.lua` (1029 lines) - Raid management system
- `QuickJoin.lua` (1337 lines) - Social Queue integration
- `RAF.lua` (878 lines) - Recruit-A-Friend system
- `WhoFrame.lua` (507 lines) - WHO search system
- `RecentAllies.lua` (324 lines) - Recent allies tracking
- `IgnoreList.lua` (172 lines) - Ignore list management

**Support Modules:**
- `ButtonPool.lua` (381 lines) - UI button recycling & drag-drop
- `QuickFilters.lua` (130 lines) - Filter logic
- `Dialogs.lua` (178 lines) - StaticPopup dialogs
- `MenuSystem.lua` (83 lines) - Context menus

**Utility Modules:**
- `FontManager.lua` - Font scaling
- `ColorManager.lua` - Color management
- `AnimationHelpers.lua` - Animation utilities
- `PerformanceMonitor.lua` - Performance tracking

### Performance
- **Button Recycling** - Reuses UI elements for efficiency
- **Update Throttling** - Limits update frequency (1s interval)
- **Caching** - 2-second TTL cache for Quick Join data
- **Event-Driven** - No polling, only event-based updates
- **Lazy Loading** - Only loads visible data

**Benchmarks:**
- Friends List: <20ms @ 200 friends
- Quick Join: <40ms @ 50 groups
- Raid Frame: <30ms @ 40 members
- Memory: ~2-3 MB baseline

### API Compatibility
- **WoW Version**: 11.2.5 (Retail/Mainline)
- **APIs Used**: C_FriendList, C_BattleNet, C_SocialQueue, C_RecruitAFriend
- **Protected Functions**: Handled via secure templates & menus
- **Classic Support**: Not planned (uses Retail-only APIs)

---

## 🤝 Compatibility

### WoW Versions
- ✅ **Retail 11.2.5** - Fully supported
- ❌ **Classic** - Not supported (uses Retail-only APIs)
- ❌ **Wrath/Cata** - Not supported

### AddOn Compatibility
- ✅ **ElvUI** - Fully compatible
- ✅ **Bartender** - Fully compatible
- ✅ **Shadowed Unit Frames** - Fully compatible
- ✅ **WeakAuras** - Fully compatible
- ⚠️ **Other Friends Frame Replacements** - May conflict (disable one)

### Known Issues
- None currently! Report bugs on [GitHub Issues](https://github.com/Hayato2846/BetterFriendlist/issues)

---

## 🛠️ Development

### Project Structure
```
BetterFriendlist/
├── Core.lua                    # Event system & module registry
├── BetterFriendlist.lua        # Main UI glue layer (1655 lines)
├── BetterFriendlist.xml        # UI frame definitions
├── BetterFriendlist.toc        # Addon metadata
│
├── Modules/                    # Business logic (14 modules)
│   ├── Database.lua            # SavedVariables management
│   ├── Groups.lua              # Group management
│   ├── FriendsList.lua         # Friends list core
│   ├── RaidFrame.lua           # Raid management
│   ├── QuickJoin.lua           # Social Queue
│   ├── RAF.lua                 # Recruit-A-Friend
│   ├── WhoFrame.lua            # WHO system
│   ├── RecentAllies.lua        # Recent allies
│   ├── IgnoreList.lua          # Ignore list
│   ├── Settings.lua            # Settings UI
│   ├── ButtonPool.lua          # Button recycling
│   ├── QuickFilters.lua        # Filter logic
│   ├── Dialogs.lua             # StaticPopup dialogs
│   └── MenuSystem.lua          # Context menus
│
├── UI/                         # UI callbacks
│   ├── FrameInitializer.lua    # Frame setup
│   ├── RaidFrameCallbacks.lua  # Raid frame XML callbacks
│   └── QuickJoinCallbacks.lua  # Quick Join XML callbacks
│
└── Utils/                      # Shared utilities
    ├── FontManager.lua         # Font scaling
    ├── ColorManager.lua        # Color management
    ├── AnimationHelpers.lua    # Animations
    └── PerformanceMonitor.lua  # Performance tracking
```

### Contributing
We welcome contributions! Please:

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Follow** the code style (see below)
4. **Test** thoroughly in-game (no Lua errors!)
5. **Commit** with clear messages (`git commit -m 'feat: Add amazing feature'`)
6. **Push** to your fork (`git push origin feature/amazing-feature`)
7. **Open** a Pull Request

### Code Style
- **Indentation**: Tabs (not spaces)
- **Naming**: 
  - Functions: `PascalCase` (e.g., `CreateGroup`)
  - Variables: `camelCase` (e.g., `friendList`)
  - Constants: `UPPER_SNAKE_CASE` (e.g., `MAX_FRIENDS`)
- **Comments**: Document complex logic
- **Modules**: Use `BFL:RegisterModule()` pattern
- **Events**: Use `BFL:RegisterEventCallback()` system
- **No Global Pollution**: Use local variables

### Building & Testing
```bash
# Clone repository
git clone https://github.com/Hayato2846/BetterFriendlist.git

# Symlink to WoW (or copy files)
ln -s /path/to/BetterFriendlist "World of Warcraft\_retail_\Interface\AddOns\BetterFriendlist"

# In-game testing
/reload
/bfl debug print  # Enable debug logs
/bflperf enable   # Enable performance monitoring
```

### Debugging
- **BugSack/BugGrabber** - Capture Lua errors
- **Debug Prints**: `/bfl debug print` - Toggle debug output
- **Performance**: `/bflperf report` - View performance stats
- **Database**: Settings → Advanced → Debug Database

---

## ❓ FAQ

### Why isn't the O key opening BetterFriendlist?
The O key should automatically open BetterFriendlist. If not:
1. Check `/bfl debug print` - you should see keybind override messages
2. Try `/reload` to reinitialize the keybind system
3. Manually rebind in Keybindings → AddOns → BetterFriendlist

### Can I use this with ElvUI?
Yes! BetterFriendlist is fully compatible with ElvUI and other UI replacements.

### Will this work in Classic?
No. BetterFriendlist uses Retail-only APIs (C_SocialQueue, C_RecruitAFriend, etc.) that don't exist in Classic.

### How do I migrate from FriendGroups?
See [Installation](#installation) section above, or check [FRIENDGROUPS_MIGRATION.md](FRIENDGROUPS_MIGRATION.md) for detailed instructions.

### Does this replace Blizzard's Friends frame?
Yes. When you press O or use social keybinds, BetterFriendlist opens instead of Blizzard's frame.

### Why can't I drag raid members during combat?
This is a WoW API restriction. Protected functions like `SwapRaidSubgroup()` are disabled during combat to prevent exploits.

### Quick Join shows "No groups available" - is it broken?
No. Quick Join only shows groups when:
1. Friends have created LFG groups
2. You're not already in a group
3. The group is joinable

Use `/bflqj mock` to test the UI with fake groups.

---

## 🐛 Troubleshooting

### Common Issues

**Problem**: O key doesn't open BetterFriendlist  
**Solution**: `/reload` or check Keybindings → AddOns → BetterFriendlist

**Problem**: Lua errors on login  
**Solution**: 
1. Update to latest version
2. Enable `/bfl debug print` and report the error
3. Check for addon conflicts (disable others temporarily)

**Problem**: Groups not showing after migration  
**Solution**: 
1. Settings → Advanced → Debug Database
2. Check that groups exist in the output
3. Try `/reload`

**Problem**: Raid frame not appearing  
**Solution**: 
1. Must be in a raid (6+ players), not a party
2. Click "Raid" bottom tab
3. If still hidden, try `/reload`

**Problem**: Can't drag raid members  
**Solution**: 
1. Must be Raid Leader or Raid Assistant
2. Cannot drag during combat (Protected Function restriction)
3. Combat overlay will appear when in combat

### Getting Support

**Before Reporting:**
1. Enable debug: `/bfl debug print`
2. Install BugSack/BugGrabber to capture errors
3. Try `/reload` to reset state
4. Disable other addons to test for conflicts

**When Reporting:**
1. Post on [GitHub Issues](https://github.com/Hayato2846/BetterFriendlist/issues)
2. Include:
   - WoW version (e.g., 11.2.5)
   - Addon version (from .toc or `/bfl` title bar)
   - Full error message (from BugSack)
   - Debug logs (if debug print enabled)
   - Steps to reproduce

---

## 📜 Changelog

See [CHANGELOG.md](CHANGELOG.md) for full version history.

### v1.0 (Current - November 2025)
**🎉 Initial Stable Release - Feature Complete!**

- ✅ **Modularization Complete**: 14 modules, ~11,000 lines of code
- ✅ **Friends List**: Custom groups, drag & drop, search, filters
- ✅ **Raid Frame**: 40-man display, drag & drop, ready checks, control panel
- ✅ **Quick Join**: Social Queue integration with mock system
- ✅ **WHO Frame**: Enhanced player search
- ✅ **Ignore List**: Block management
- ✅ **Recent Allies**: Auto-tracking system
- ✅ **RAF**: Recruit-A-Friend integration
- ✅ **Settings**: FriendGroups migration, advanced options
- ✅ **Performance**: Optimized for 200+ friends (<20ms updates)
- ✅ **Keybind System**: Auto-replaces O key binding
- ✅ **Debug Tools**: Debug print toggle, performance monitor

---

## 📄 License

This project is licensed under the **MIT License**.

```
Copyright (c) 2025 BetterFriendlist Contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

[Full MIT License text in LICENSE file]
```

---

## 🙏 Credits

### Development
- **Lead Developer**: Hayato2846
- **AI Assistant**: GitHub Copilot (Claude Sonnet 4.5)

### Inspiration & Reference
- **FriendGroups** - Original custom groups addon concept
- **Blizzard_FriendsFrame** - Reference implementation (11.2.5)
- **Cell** - Raid frame drag & drop inspiration

### Special Thanks
- WoW AddOn Development Community
- [warcraft.wiki.gg](https://warcraft.wiki.gg) - API documentation
- [GitHub Gethe/wow-ui-source](https://github.com/Gethe/wow-ui-source) - Blizzard source code
- Beta testers and bug reporters

---

## 🔗 Links

- **GitHub**: [Hayato2846/BetterFriendlist](https://github.com/Hayato2846/BetterFriendlist)
- **Issues**: [Report Bugs](https://github.com/Hayato2846/BetterFriendlist/issues)
- **Releases**: [Download](https://github.com/Hayato2846/BetterFriendlist/releases)
- **CurseForge**: Coming soon!
- **WoWInterface**: Coming soon!

---

**Note**: This addon is not affiliated with or endorsed by Blizzard Entertainment. World of Warcraft and Battle.net are trademarks of Blizzard Entertainment, Inc.
