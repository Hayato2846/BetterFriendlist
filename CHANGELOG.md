# Changelog

All notable changes to BetterFriendlist will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.0] - 2025-11-09

**🎉 Initial Stable Release - Feature Complete!**

This is the first stable release of BetterFriendlist, representing complete feature parity with Blizzard's Friends frame plus extensive enhancements.

### Added

#### Core Features
- **Custom Friend Groups** - Organize friends into named groups with full CRUD operations
- **Drag & Drop** - Move friends between groups with visual feedback
- **Search & Filter** - Search by name/note, Quick Filters (Online, All, WoW, App, Recent, Favorites)
- **Context Menus** - Right-click menus for all actions (invite, whisper, notes, groups)
- **FriendGroups Migration** - Seamless import from FriendGroups addon with BNet note cleanup

#### Major Features
- **Raid Frame** (Phase 8)
  - 40-man raid display with 8 groups × 5 slots
  - Drag & drop members between groups (leader/assistant only)
  - Combat-aware overlay system (drag disabled in combat)
  - Ready Check system with visual indicators
  - Role icons (Tank/Healer/DPS) and rank icons (Leader/Assistant)
  - Control Panel (Ready Check, Everyone Assist, Convert to Raid/Party)
  - Raid Info button (integrates Blizzard's RaidInfoFrame)
  - Class colors, status indicators (online/offline/dead)
  - Context menus for raid management

- **Quick Join** (Phase 9)
  - Social Queue integration (C_SocialQueue API)
  - Browse available groups from friends
  - Role selection dialog (Tank/Healer/Damage with spec detection)
  - Mock system for testing (`/bflqj mock`)
  - Update throttling (1s) and caching (2s TTL)
  - Request tracking ("Request Sent" status)
  - Combat and group status checks

- **WHO Frame**
  - Enhanced player search with filters
  - Level range filters (min/max)
  - Zone/Guild/Race dropdowns (auto-populated)
  - Quick actions (add friend, whisper, invite)
  - Real-time results update

- **Ignore List**
  - Block players and invites
  - SQUELCH_TYPE_IGNORE and SQUELCH_TYPE_BLOCK_INVITE support
  - Quick unignore buttons

- **Recent Allies**
  - Auto-tracking of grouped players
  - Character info display (race, class, level, zone)
  - Quick party invite for online allies
  - Note management

- **Recruit-A-Friend**
  - Full RAF integration
  - Reward claiming panel
  - Recruit list with online/offline status
  - Activity tracking and claiming
  - Recruitment link generation

#### Technical Features
- **Modular Architecture** - 14 independent modules (~11,000 lines total)
  - Database, Groups, FriendsList, Settings, RaidFrame, QuickJoin
  - RAF, WhoFrame, RecentAllies, IgnoreList, ButtonPool
  - QuickFilters, Dialogs, MenuSystem
- **Performance Optimized**
  - Button recycling system (ButtonPool)
  - Update throttling (1s intervals)
  - Caching with 2s TTL
  - Event-driven updates (no polling)
  - Lazy loading
  - Memory management with automatic cleanup
- **Event System** - Modular event callback system
- **Utils** - FontManager, ColorManager, AnimationHelpers, PerformanceMonitor
- **Debug Tools** - Debug print toggle (`/bfl debug print`), Performance monitor (`/bflperf`)

#### UI/UX
- **Keybind Override System** - O key auto-opens BetterFriendlist (SetOverrideBinding approach)
- **4 Main Tabs** - Friends, WHO, Ignore, RAF
- **4 Bottom Tabs** - Recent Allies, Quick Join, Raid, Settings
- **Settings Panel** - General and Advanced tabs
- **Visual Polish** - Class colors, status icons, game icons, faction icons
- **Tooltips** - Informative tooltips throughout
- **Animations** - Smooth transitions and feedback

### Performance Benchmarks
- Friends List: <20ms @ 200 friends ✅
- Quick Join: <40ms @ 50 groups ✅
- Raid Frame: <30ms @ 40 members ✅
- Memory: ~2-3 MB baseline ✅

### Documentation
- Complete README.md with installation, usage, commands, FAQ
- FRIENDGROUPS_MIGRATION.md for migration guide
- PHASE_10.5_COMPLETE.md documenting technical limitations
- v1.0-finalization-plan.md tracking development phases
- TESTING_CHECKLIST.md with 14 identified and fixed bugs

### Commands
- `/bfl` - Toggle frame
- `/bfl settings` - Open settings
- `/bfl help` - Show help
- `/bfl debug print` - Toggle debug output
- `/bflqj mock` - Create mock Quick Join groups
- `/bflqj clear` - Remove mock groups
- `/bflperf enable` - Enable performance monitoring
- `/bflperf report` - Show performance stats

### Known Limitations
- **Main Tank/Assist menu options** - Cannot be implemented due to WoW API Protected Function restrictions (`SetPartyAssignment()` requires `issecure() == true`)
- **Classic Support** - Not planned (uses Retail-only APIs like C_SocialQueue, C_RecruitAFriend)

### Technical Stack
- **WoW Version**: 11.2.5 (Retail/Mainline)
- **APIs**: C_FriendList, C_BattleNet, C_SocialQueue, C_RecruitAFriend
- **UI System**: Modern WoW templates (ScrollBox, ButtonTemplate, etc.)
- **Architecture**: Modular event-driven system with ~11,000 lines across 14 modules

---

## [0.15.0] - 2025-11-08

### Added
- Phase 10.5: Misc Changes & Bug Fixes
  - Raid UI dynamic visibility (only shows in raids, not parties)
  - GROUP_ROSTER_UPDATE event for automatic show/hide

### Fixed
- 14 critical bugs identified and fixed in comprehensive testing session
  - Raid Frame drag & drop tooltip issue
  - WHO Frame whisper command (server extraction)
  - Custom Groups color format
  - Settings migration bnetAccountID lookup
  - Debug Database string filter
  - Recent Allies tooltips
  - Ignore List UI opening

### Changed
- Removed all debug print statements for production
- Updated MenuSystem.lua to remove attempted Main Tank/Assist menu hooks

### Documentation
- Created PHASE_10.5_COMPLETE.md documenting technical limitations

---

## [0.14.0] - 2025-11-06

### Added
- Phase 9: Quick Join Implementation (COMPLETE)
  - Modules/QuickJoin.lua (550+ lines)
  - Role selection dialog with spec detection
  - Mock system for testing (`/bflqj` commands)
  - ScrollBox UI with group list
  - Update throttling and caching

### Changed
- Version bump: 0.13 → 0.14

---

## [0.13.0] - 2025-11-05

### Added
- Phase 8: Raid Frame Implementation (COMPLETE)
  - Modules/RaidFrame.lua (1029 lines)
  - 40-man raid display
  - Drag & drop system
  - Combat overlay
  - Ready Check integration
  - Control Panel features
  - Raid Info button

### Changed
- BetterFriendlist.lua: 2430 → 1515 lines (-37.7% reduction)
- Version bump: 0.12 → 0.13

---

## [0.12.0] - 2025-11-03

### Added
- Phase 5: UI Initialization Cleanup
  - UI/FrameInitializer.lua (313 lines)
  - WHO Frame mixins integration

### Changed
- BetterFriendlist.lua: 3200 → 2943 lines (-8% reduction)
- Version bump: 0.11 → 0.12

### Fixed
- Tab switching logic (all frames properly show/hide)

---

## [0.11.0] - 2025-11-02

### Added
- Phase 4: Event System Reorganization
  - Event callback system in Core.lua
  - Module-based event handlers

### Changed
- BetterFriendlist.lua: 3202 → 3200 lines
- Version bump: 0.10 → 0.11

### Fixed
- Button pool tab switching bugs
- Pulse animation issues

---

## [0.10.0] - 2025-11-01

### Added
- Phase 3: Button Pool Management Module
  - Modules/ButtonPool.lua (378 lines)
  - Button recycling system
  - Drag & drop support

### Changed
- BetterFriendlist.lua: 3448 → 3202 lines (-7.1% reduction)
- Version bump: 0.9 → 0.10

---

## [0.9.0] - 2025-10-31

### Added
- Phase 1-2: Core Modularization
  - 11 core modules created
  - Utils modules (FontManager, ColorManager, AnimationHelpers)
  - Database, Groups, FriendsList, WhoFrame, IgnoreList
  - RecentAllies, MenuSystem, QuickFilters, Settings, Dialogs, RAF

### Changed
- BetterFriendlist.lua: 4500+ → 3448 lines (-23% reduction)

---

## [1.1.0] - 2025-11-09

**Feature Release: Export/Import System**

### Added
- **Export/Import Settings** - Share groups and assignments between characters/accounts
  - Export all custom groups, colors, friend assignments, and group order
  - Import with validation and error handling
  - Hex-encoded format (BFL1: prefix) for easy copy/paste
  - Export Dialog with scrollable text and "Select All" button
  - Import Dialog with validation and confirmation
  - Perfect for multi-account players sharing Battle.net friends
  - UI integrated in Settings → Advanced tab

### Fixed
- **Create Group Dialog Bug** - Fixed `BetterFriendsList_CreateGroup` nil error
  - Changed from non-existent global functions to Module API calls
  - Both `BETTER_FRIENDLIST_CREATE_GROUP` and `BETTER_FRIENDLIST_CREATE_GROUP_AND_ADD_FRIEND` dialogs fixed
  - Now properly calls `BFL:GetModule("Groups"):Create(groupName)`

### Technical
- Added 4 new functions in `Modules/Settings.lua`:
  - `ExportSettings()` - Serializes all settings to hex string
  - `ImportSettings()` - Deserializes and validates import string
  - `SerializeTable()` / `DeserializeTable()` - Table <-> String conversion
  - `EncodeString()` / `DecodeString()` - Hex encoding/decoding
- Added 2 UI frames:
  - `BetterFriendlistExportFrame` - 500×400 draggable dialog
  - `BetterFriendlistImportFrame` - 500×400 draggable dialog with validation
- Updated `BetterFriendlist_Settings.xml` with Export/Import section
- Updated `BetterFriendlist_Settings.lua` with callback functions

---

## [Unreleased]

### Planned for v1.2+
- Enhanced filtering (level, zone, class filters)
- Color coding for custom groups
- Notification system
- Statistics/activity tracking
- Profile system
- Compact mode

---

## Version History Summary

| Version | Date | Description | Lines (Main File) |
|---------|------|-------------|-------------------|
| 1.1.0 | 2025-11-09 | Export/Import + Bugfixes | 1655 |
| 1.0.0 | 2025-11-09 | Initial Stable Release | 1655 |
| 0.15.0 | 2025-11-08 | Phase 10.5 Bug Fixes | ~2600 |
| 0.14.0 | 2025-11-06 | Quick Join | ~2600 |
| 0.13.0 | 2025-11-05 | Raid Frame | 1515 |
| 0.12.0 | 2025-11-03 | UI Cleanup | 2943 |
| 0.11.0 | 2025-11-02 | Event System | 3200 |
| 0.10.0 | 2025-11-01 | Button Pool | 3202 |
| 0.9.0 | 2025-10-31 | Core Modules | 3448 |

---

**Note**: Pre-0.9.0 versions were development builds and are not documented here.
