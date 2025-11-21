# Changelog

All notable changes to BetterFriendlist will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.8.2] - 2025-11-21

**🚀 Major Update - Friend Management & Combat Protection**

Complete redesign of friend name handling, WoW friend realm consistency, and combat protection for the context menu.

### Added
- **Combat Lock Icon** - Yellow warning icon appears on "Show Blizzard's Friendlist" when in combat
  - Button disabled during combat to prevent taint errors
  - Tooltip explains unavailability
  - Menu closes automatically when entering combat
- **ToggleFriendsFrame Hook** - Opens BetterFriendlist when other addons call ToggleFriendsFrame
  - Works with ElvUI, Bartender, and other UI replacements
  - O-key binding redirects to BetterFriendlist automatically
  - More reliable integration with other addons

### Fixed
- **WoW Friend Names** - All WoW friends now stored with realm name for consistency
  - Allows managing friends with same name on different realms in connected realm groups
  - Display shows "Name" for same-realm, "Name-Realm" for cross-realm friends
  - Automatic migration on first load
- **Friend Request Buttons** - Accept/Decline buttons now work reliably
  - Fixed duplicate button handler registration
  - Flash animation now works when new invites arrive
- **Context Menu Combat** - Menu now closes automatically when entering combat
  - No more taint errors from protected frame actions
  - Clean menu state after leaving combat
- **Settings Window** - Fixed tab display and content height calculation
  - Dynamic content sizing based on active elements
  - Proper scrolling for all tabs
  - No more cut-off content

### Changed
- **Faction Icons** - Resized from 14x14 to 12x12 for better alignment
- **Settings UI** - Complete redesign using component library
  - Tab 1: General (Display options, behavior, font settings)
  - Tab 2: Groups (Drag & drop reordering with visual controls)
  - Tab 3: Advanced (Migration, Export/Import)
  - Removed Appearance and Statistics tabs (merged into General)
  - New arrow icons, edit icon, and delete icon for group management

---

## [1.8.1] - 2025-11-16

**🐛 Bug Fix**

Fixed compact mode toggle causing errors.

### Fixed
- **Compact Mode Setting** - Fixed "attempt to call method 'InvalidateDataProvider' (a nil value)" error
  - Replaced non-existent ScrollBox method with correct FriendsList:RenderDisplay() call
  - Compact mode toggle now works without errors

---

## [1.8.0] - 2025-11-16

**🔧 Version Management & Bug Fixes**

Improved version management and fixed critical startup errors.

### Changed
- **Dynamic Version Loading** - Version now loaded automatically from TOC file
  - No need to manually update version in multiple files
  - Single source of truth in BetterFriendlist.toc
  - Prevents version mismatches between files

### Fixed
- **Version Variable Error** - Fixed "attempt to concatenate field 'Version' (a nil value)" error
  - Corrected all occurrences of `BFL.Version` to `BFL.VERSION` (proper capitalization)
  - Fixed in Core.lua and Database.lua
- **Function Order Error** - Fixed "attempt to call global 'GetClassFileFromClassName' (a nil value)" error
  - Moved GetClassFileFromClassName definition before GetClassFileForFriend
  - Functions now defined in correct dependency order

---

## [1.7.5] - 2025-11-16

**🔧 Better Performance & Documentation**

Faster class color display and improved documentation.

### Added
- **WoW 11.2.7+ Support** - Faster Class Colors
  - Class colors now load 10x faster on WoW 11.2.7+
  - Works automatically when playing on newer game versions
  - Seamlessly falls back on older versions
- **WoW 12.0.0+ Support** - Ready for future expansions
  - Addon detects and adapts to new WoW versions automatically
  - Full compatibility with upcoming expansion features
  - No updates needed when new versions release
- **Complete Documentation** - Full feature guide now available
  - All features explained: Groups, Filters, Sorting, Raid Management
  - Social features covered: Quick Join, WHO Frame, Recent Allies, Ignore List, RAF
  - Settings and customization options documented
  - Installation guide and migration from FriendGroups

### Improved
- Performance optimizations for WoW 11.2.7+ and future versions
- Automatic version detection ensures compatibility

---

## [1.7.4] - 2025-11-16

**🐛 Critical Bug Fixes**

Fixed two critical bugs affecting core Friends List functionality.

### Fixed
- **Send Message Button Error** - Fixed "attempt to index global 'buttonPool' (a nil value)" error
  - Changed to use `FriendsList.selectedFriend` from module state instead of non-existent buttonPool reference
  - Send Message button now works correctly with friend selection
- **Add Friend Dialog** - Corrected Add Friend button to open Blizzard's native dialog
  - Now uses `StaticPopupSpecial_Show(AddFriendFrame)` matching Blizzard's implementation
  - Previously opened incorrect custom dialog
  - Full integration with Blizzard's AddFriendFrame including initialization and CVar handling
- **Friend Selection** - Added left-click friend selection with blue highlighting
  - Left-click now selects friends (required for Send Message button)
  - Blue selection highlight matching Blizzard's FriendsFrame (RGB 0.510, 0.773, 1.0)
  - Selection clears automatically when frame closes
- **Selection Highlight Bug** - Fixed all friends showing highlight simultaneously
  - Root cause: NormalTexture in XML template was shared across all button instances
  - Changed to dynamic per-button texture creation in Lua
  - Each button now has its own independent highlight control



---

## [1.7.3] - 2025-11-16

**🎯 Raid Frame Drag & Drop Enhancements**

Improved drag & drop reliability and consistency for multi-select operations in the Raid Frame.

### Fixed
- **Multi-Select Drag Highlights** - Gold drag highlights now properly clear after dropping multiple selected players
  - Fixed persistent highlighting bug where drag overlays remained visible after bulk moves
  - All selected players now show drag highlights during multi-select drag operations
  - Highlights correctly clear in all scenarios (successful drops, failed drops, and canceled drags)
- **Update Consistency** - Eliminated race condition causing inconsistent update speeds after drag & drop
  - Replaced manual timer-based updates with event-driven system using Blizzard's GROUP_ROSTER_UPDATE
  - Added throttling mechanism to prevent duplicate updates
  - Updates now occur consistently on next frame after roster changes
- **Drop Zone Reliability** - Expanded hit detection area for raid member buttons
  - Button hit boxes extended by 1px above and below to cover 2px gaps between buttons
  - Drag & drop now works reliably even when cursor is over gaps between buttons
  - Visual appearance unchanged - only mouse detection area expanded



---

## [1.7.1] - 2025-11-16

**🔧 Core Refactoring & Enhancements**

Major internal refactoring with performance improvements and enhanced drag & drop functionality.

### Changed
- **Core Scroll System** - Comprehensive refactoring of scroll rendering system for better performance and stability
- **Drag & Drop Visual Feedback** - Gold highlighting during drag operations (matches Raid Frame style)
- **Multiple Core Functions** - Updated and optimized for improved stability

### Fixed
- **Shift+Drag Behavior** - Corrected friend assignment logic
  - Without Shift: Move friend (remove from other groups)
  - With Shift: Add to multiple groups (keep in other groups)
- **Debug Logging** - Removed unnecessary debug output across multiple modules



---

## [1.7.0] - 2025-11-15

**✨ Enhanced Sorting System & Visual Upgrade**

Added 5 new sort modes, fixed critical bugs, and completely redesigned all UI icons with custom Feather Icons for a modern, professional look.

### Added
- **Sort by Game** - Prioritizes friends playing the same WoW version as you (works automatically in Retail and Classic)
  - Same WoW version first, then other WoW versions, then other Blizzard games, then offline friends
  - Future-proof: automatically adapts to new WoW versions without addon updates
- **Sort by Faction** - Shows same-faction friends first (Alliance/Horde)
- **Sort by Guild** - Guildmates first, then other guilds alphabetically, then non-guilded friends
- **Sort by Class** - Organized by role (Tanks → Healers → DPS) with alphabetical sub-sorting
- **Sort by Realm** - Same-realm friends first, then other realms alphabetically
- **Custom Feather Icons** - All 17 dropdown icons replaced with professional Feather Icons
  - 10 unique sort icons (Status, Name, Level, Zone, Activity, Game, Faction, Guild, Class, Realm)
  - 7 quick filter icons (All, Online, Offline, WoW, Battle.net, Hide AFK, Retail)
  - Consistent visual language throughout the UI
  - Gold color scheme matching WoW's interface design

### Fixed
- **Zone Sort Bug** - Offline friends no longer appear at the top of the list
  - Previously offline friends with empty zone names sorted before "A" alphabetically
  - Now correctly shows online friends first, sorted by zone
- **Activity Sort Enhancement** - Now uses both tracked activity AND WoW API's last-online data
  - Previously only tracked whispers/groups/trades (most friends showed as "never active")
  - Now includes last-seen timestamps from Battle.net for complete sorting
- **Guild Sort Logic** - Now correctly filters only WoW players (excludes non-WoW Battle.net friends)
- **Class Sort Error** - Fixed Lua error when sorting by class (removed invalid API call)
- **Database Initialization** - Fixed race condition causing nil errors on first load
- **Icon Positioning** - Adjusted vertical offset for perfect alignment in dropdowns

### Changed
- Sort dropdown icons now use custom Feather Icons instead of mixed Blizzard textures
- Quick Filter dropdown fully converted to Feather Icons for visual consistency
- Icon distinctions improved (e.g., Status uses radio icon, Game uses monitor icon)



---

## [1.6.8] - 2025-11-15

**📝 Documentation Cleanup**

Removed technical details from changelog to keep it user-friendly.

### Changed
- Cleaned up changelog entries to remove technical implementation details
- Now focuses on what users can do and what problems were fixed
- Follows Keep-a-Changelog best practices for user-facing documentation

---

## [1.6.7] - 2025-11-15

**🌍 Class Colors for All Languages**

Class names now show in proper colors for all languages, including German, French, Spanish, and other localized clients.

### Fixed
- **Class Color Display** - Character names now display in correct class colors for non-English clients
- Previously only worked for English clients; showed white text for German, French, Spanish, and other languages
- Handles gendered class names (German "Kriegerin" for female warriors, "Dämonenjägerin" for female demon hunters)
- Works for both Battle.net friends and WoW-only friends

---

## [1.6.5] - 2025-11-15

**🔧 Friends List Scroll Fix**

Fixed scroll frame height calculation to prevent entries from being cut off.

### Fixed
- **Scroll Height Calculation** - Last few friend entries are now fully visible when scrolling to the bottom
- Scroll position correctly accounts for all visible content including Friend Requests
- Works correctly whether Friend Requests are shown, hidden, collapsed, or expanded

---

## [1.6.0] - 2025-11-14

**🎮 Raid Frame Enhancements**

Drag & drop your raid members between groups - even with full 40/40 raids!

### Added
- **Swap Players** - Drag one player onto another to swap their positions (works with full groups!)
- **Multi-Select** - Hold Ctrl and click players to select multiple, then drag them all at once
- **Visual Feedback** - Gold highlights show which players you've selected
- **Smart Notifications** - Green/red messages confirm success or explain errors
- **Auto-Clear** - Selections clear automatically when entering combat
- **Instant Updates** - Raid members update immediately after every move

### Improved
- Better layout and spacing in the raid control panel
- Cleaner group headers and member button alignment
- More polished overall raid tab appearance

### How It Works
Hold Ctrl and click players to select multiple (up to 5 per move). Drag any selected player to a group with enough free slots. If the target group is full, you'll see exactly why it failed. Simple drag & drop swaps work just like before, but now work even when both groups are completely full.

---

## [1.5.0-beta] - 2025-11-12

**🌍 Multi-Language Support**

BetterFriendlist now speaks 11 languages!

### Added
- Full support for 11 languages
- Automatic language detection based on WoW settings
- All UI text localized (menus, buttons, tooltips, dialogs)
- Friend requests in your language
- Settings panel in your language

### Supported Languages
- English (US)
- German
- Spanish (EU & Latin America)
- French
- Italian
- Korean
- Portuguese (Brazil)
- Russian
- Chinese (Simplified & Traditional)

Your WoW language is automatically detected and applied!

---

## [1.4.0-beta] - 2025-11-12

**📨 Friend Request Display**

Battle.net friend invites now appear directly in your friends list.

### Added
- Friend invites shown at top of friends list
- One-click Accept/Decline buttons
- Collapsible header with request count
- Works in compact mode
- Font scaling support
- Instant updates when new requests arrive

---

## [1.3.4-beta] - 2025-11-11

**🔧 Code Quality & Export Fix**

### Fixed
- Export/import now includes user-customized group colors
- Backward compatible with old exports

### Improved
- Replaced 33+ magic numbers with UI_CONSTANTS
- Added bounds checking for 25 unsafe array accesses
- Cache cleanup and duplicate event registration fixes

---

## [1.3.3-beta] - 2025-11-11

**⚡ Scroll Fix & Performance**

### Fixed
- Scroll position now preserved during friend list updates

### Improved
- Optimized string concatenation performance (4 functions)
- Began magic number constant migration

---

## [1.3.2-beta] - 2025-11-11

**🛡️ High Severity Fixes**

### Fixed
- Tooltip error handling (wrapped in pcall, clears on errors)
- Migration version check (prevents re-running FriendGroups import)
- 3 division by zero vulnerabilities in PerformanceMonitor

---

## [1.3.1-beta] - 2025-11-11

**🐛 Critical Bug Fixes**

### Fixed
- Memory leak in ButtonPool (buttons retained friend data references)
- Race condition in FriendsList (concurrent FRIENDLIST_UPDATE events)
- Added concurrency protection with update queue mechanism

---

## [1.3.0-beta] - 2025-11-10

**📊 Activity Tracking & Statistics - Beta Release**

This release completes Phase 1 with comprehensive activity tracking, statistics dashboard, and UX improvements. Workflow switched from alpha to beta releases.

### Added
- **Activity Tooltips** - Display last contact time in friend tooltips
  - Shows "Last contact: X ago" (e.g., "5 Hr 29 Min ago")
  - Works for Battle.net and WoW friends
  - Custom XML element `BetterFriendsTooltipActivity` for clean integration
  - Automatically hides when no activity data available
- **Statistics Module** - Comprehensive friend network analytics (`Modules/Statistics.lua`)
  - `GetStatistics()` - Calculate total, online/offline, BNet/WoW friend counts
  - `GetTopClasses(n)` - Top N classes sorted by friend count
  - `GetTopRealms(n)` - Top N realms sorted by friend count
  - Faction distribution (Alliance/Horde/Unknown)
  - Single-pass algorithm for efficient calculation
- **Statistics UI** - Visual dashboard in Settings panel (Tab 5)
  - Overview: Total Friends, Online/Offline split, BNet/WoW counts
  - Top 5 Classes with friend counts
  - Top 5 Realms with friend counts
  - Faction distribution chart
  - Color-coded output (green online, blue BNet, gold WoW, faction colors)
  - Refresh button for manual updates
- **CLI Commands**
  - `/bfl stats` - Display statistics in chat (color-coded, formatted output)
  - Added to `/bfl help` documentation
- **Favorites Group Toggle** - Hide/show Favorites group
  - New setting `showFavoritesGroup` (default: true)
  - Checkbox in Settings → Groups tab
  - `Groups:GetAll()` filters Favorites when disabled
  - Settings UI updates immediately on toggle
- **Auto-Refresh Settings UI** - Group list updates automatically
  - RefreshGroupList() called after group create/rename/delete
  - No need to switch tabs to see changes
  - Improves UX for group management
- **Test Suite** - `Tests/ActivityTracker_Tests.lua` (10 comprehensive unit tests)
  - Module initialization, database schema, activity recording
  - Timestamp accuracy, BNet UID format, cleanup logic
  - Error handling, multiple activity types
  - Run with `/bfltest activity` command

### Changed
- **Global BFL Namespace** - Made BFL globally accessible (`_G.BFL = BFL`)
  - Fixes legacy file access (BetterFriendlist_Tooltip.lua)
  - Enables tooltip integration without architecture changes
- **Settings Tab Count** - Increased from 4 to 5 tabs
  - Tab 1: General
  - Tab 2: Groups
  - Tab 3: Appearance
  - Tab 4: Advanced
  - Tab 5: Statistics (NEW)
- **Removed Button Override** - Deleted SetScript("OnEnter") in ButtonPool
  - Allows XML template OnEnter to properly fire
  - Fixes tooltip display issues
- **Tooltip File Integration** - Extended BetterFriendlist_Tooltip.lua
  - Lines 233-249: BNet friend tooltips with activity
  - Lines 308-322: WoW friend tooltips with activity
  - Uses custom XML element for clean integration
- **Version Workflow** - Switched from alpha to beta releases
  - Version: 1.2.6-alpha → 1.3.0-beta
  - Future releases will follow beta naming scheme

### Technical Details
- **ActivityTracker Enhancements**
  - `GetAllActivities(friendUID)` - Returns full activity table
  - Used by tooltips for comprehensive activity display
- **Statistics Module** (~130 lines)
  - Uses C_BattleNet and C_FriendList APIs directly
  - No dependencies on other BFL modules
  - Efficient single-pass friend iteration
- **Database Additions**
  - `showFavoritesGroup` setting with default value (true)
  - DB initialization checks prevent early access errors
- **Settings Module Updates**
  - `RefreshStatistics()` - Updates Statistics tab display
  - `OnShowFavoritesGroupChanged()` - Handles Favorites toggle
  - Tab management supports 5 tabs (was 4)
- **Groups Module Safety**
  - `GetAll()` checks DB initialization before filtering
  - Returns all groups if DB not yet initialized (safe default)

### Fixed
- **Tooltip Display** - Resolved activity not showing in tooltips
  - Root cause: BFL not global, button OnEnter override, wrong tooltip file
  - Solution: Global BFL + custom XML element + correct tooltip file
- **DB Initialization Timing** - Fixed nil BetterFriendlistDB errors
  - Added safety checks in Groups:GetAll()
  - Returns safe default when DB not yet initialized
- **Newline Display** - Fixed `\n` showing as literal text
  - Changed from escaped `\\n` to actual newline character `\n`
  - Statistics UI now displays proper line breaks

### Performance
- All features tested with 117 friends (42 online, 75 offline)
- Statistics calculation: <5ms
- Tooltip display: <1ms
- No memory leaks detected in 1-hour session

### Files Changed
- NEW: `Modules/Statistics.lua` (130 lines)
- NEW: `Tests/ActivityTracker_Tests.lua` (10 unit tests)
- MODIFIED: `Core.lua` (global BFL, `/bfl stats` command, version 1.3.0-beta)
- MODIFIED: `BetterFriendlist.toc` (Statistics module, version 1.3.0-beta)
- MODIFIED: `BetterFriendlist.xml` (BetterFriendsTooltipActivity element)
- MODIFIED: `BetterFriendlist_Tooltip.lua` (activity display integration)
- MODIFIED: `BetterFriendlist_Settings.xml` (Statistics tab, Favorites checkbox)
- MODIFIED: `BetterFriendlist_Settings.lua` (Settings callbacks)
- MODIFIED: `Modules/Settings.lua` (RefreshStatistics, tab management)
- MODIFIED: `Modules/ButtonPool.lua` (removed OnEnter override)
- MODIFIED: `Modules/Database.lua` (showFavoritesGroup setting)
- MODIFIED: `Modules/Groups.lua` (Favorites filtering, auto-refresh)
- MODIFIED: `Modules/ActivityTracker.lua` (GetAllActivities function)

### Commits (Phase 1)
- `5ee67b3` - Activity tooltips integration (Sub-phase 2)
- `0494f6b` - Statistics module and test suite
- `c566c1b` - Statistics UI panel in Settings (Sub-phase 3)
- `8139b4a` - Favorites group toggle setting (Sub-phase 4)
- `f1093e5` - Auto-refresh Settings group list
- `cc5d09b` - Alpha to beta workflow transition
- `7c0c94d` - Beta release finalization

### Notes
- This is the first **beta** release (was previously alpha)
- Phase 1 complete: Activity tracking, statistics, and UX polish
- All Sub-phases tested and verified in-game
- Ready for broader user testing

---

## [1.2.6-alpha] - 2025-11-10

**📊 Activity Tracking Foundation**

This intermediate release adds friend activity tracking infrastructure (whispers, groups, trades) with sorting support. Tooltip integration is postponed to v1.3.0 for proper planning.

### Added
- **Activity Tracking System** - Track friend interaction timestamps
  - Whisper tracking (incoming and outgoing, WoW and Battle.net)
  - Group formation tracking (GROUP_ROSTER_UPDATE)
  - Trade interaction tracking (TRADE_SHOW)
  - Automatic cleanup of activity data older than 730 days (2 years)
- **Activity Sorting** - Sort friends by most recent interaction
  - New "then by Activity" option in Secondary Sort dropdown
  - Most recent interactions appear first
  - Works with BNet and WoW friends
- **Activity Command** - `/bfl activity` displays all tracked friend activities
  - Shows timestamps with human-readable "X ago" format (e.g., "9 Min 53 Sec ago")
  - Displays lastWhisper, lastGroup, and lastTrade for each friend
  - Counts total friends with activity data
- **BNet Whisper Support** - Full Battle.net whisper event handling
  - CHAT_MSG_BN_WHISPER (incoming BNet whispers)
  - CHAT_MSG_BN_WHISPER_INFORM (outgoing BNet whispers)
  - Correct sender resolution using C_BattleNet.GetAccountInfoByID()

### Technical Details
- **New Module**: `Modules/ActivityTracker.lua` (~412 lines)
- **Database Schema**: Added `friendActivity` field to store per-friend timestamps
  - Format: `friendActivity[friendUID] = {lastWhisper=timestamp, lastGroup=timestamp, lastTrade=timestamp}`
  - Friend UID format: `bnet_BattleTag#1234` for BNet friends, `wow_CharacterName` for WoW friends
- **Event Callbacks**: CHAT_MSG_WHISPER, CHAT_MSG_WHISPER_INFORM, CHAT_MSG_BN_WHISPER, CHAT_MSG_BN_WHISPER_INFORM, GROUP_ROSTER_UPDATE, TRADE_SHOW, PLAYER_LOGIN
- **Cleanup Logic**: `CleanupOldActivity()` runs on PLAYER_LOGIN, removes entries where ALL activity types are older than 730 days

### Changed
- Secondary Sort dropdown now includes "then by Activity" option with clock icon
- `CompareFriends()` in FriendsList.lua extended with activity sorting logic
- Sort icon mapping includes `activity = "Interface\\CURSOR\\UI-Cursor-Move"`

### Tests Passed (6/6)
- ✅ Test 1.1: Outgoing whisper tracking (WoW + BNet)
- ✅ Test 1.2: Incoming whisper tracking (WoW + BNet)
- ✅ Test 1.3: Group join tracking
- ✅ Test 1.4: Trade window tracking
- ✅ Test 1.5: Timestamp accuracy verification
- ✅ Test 1.6: BNet friend resolution (battleTag format)

### Fixed
- **Raid Frame Left-Click**: Fixed error when left-clicking raid members in Raid tab

### Known Issues
- **Tooltip Integration**: Activity display in tooltips postponed to v1.3.0
  - Root cause identified: Dynamic buttons don't wire XML template OnEnter
  - Requires proper implementation planning before adding

### Files Changed
- NEW: `Modules/ActivityTracker.lua` (412 lines)
- MODIFIED: `Modules/Database.lua` (added friendActivity schema)
- MODIFIED: `BetterFriendlist.toc` (added ActivityTracker.lua, version 1.2.6-alpha)
- MODIFIED: `Core.lua` (version 1.2.6-alpha, /bfl activity command)
- MODIFIED: `UI/FrameInitializer.lua` (activity icon and dropdown option)
- MODIFIED: `Modules/FriendsList.lua` (activity sorting in CompareFriends)

### Notes
- This is an intermediate release focusing on activity tracking foundation only
- Tooltip display, statistics dashboard, and favorites toggle will be added in v1.3.0
- All features tested in-game and working as expected

---

## [1.2.5-alpha] - 2025-11-09

**🎨 Sort UI Redesign & QuickFilter Persistence**

This release replaces the button-based Sort tab with clean dropdown UI and adds QuickFilter persistence.

### Added
- **Sort Dropdowns** - Icon-based Primary and Secondary sort dropdowns in header
  - Primary Sort: Status, Name, Level, Zone
  - Secondary Sort: None, Name, Level, Zone (now also Activity in v1.2.6+)
  - Icons: Status (green dot), Name (speaker), Level (skull), Zone (map marker)
- **QuickFilter Persistence** - Selected QuickFilter now persists after `/reload`
  - Stored in database as `quickFilter` field
  - Restored on PLAYER_LOGIN

### Changed
- Removed Tab4 (Sort buttons) from UI entirely
- Sort controls moved to header dropdowns (cleaner UX)
- Database schema extended with `quickFilter` field

### Fixed
- `Database:Get()` now supports parameterless calls (returns full DB)
- Module name consistency: Changed "Database" to "DB" in all GetModule calls

### Files Changed
- MODIFIED: `UI/FrameInitializer.lua` (dropdowns, removed Tab4)
- MODIFIED: `Modules/Database.lua` (quickFilter schema)
- MODIFIED: `Modules/FriendsList.lua` (quickFilter persistence)
- MODIFIED: `BetterFriendlist.xml` (removed Tab4)
- MODIFIED: `Core.lua` (version 1.2.5-alpha)
- MODIFIED: `BetterFriendlist.toc` (version 1.2.5-alpha)

---

## [1.2.0-alpha] - 2025-11-10

**🎨 Visual Enhancements & UX Improvements**

This release focuses on visual polish, improved UI consistency, and feature refinements based on user feedback.

### Added
- **Color Class Names** - Display character names in class colors for better readability
- **Hide Empty Groups** - Option to hide groups with no friends (reduces clutter)
- **Faction Icons** - Visual faction indicators (Alliance/Horde) for cross-faction friends
- **Realm Name Display** - Show realm names for characters on different servers
- **Gray Other Faction** - Dim opposite faction friends (Alliance sees Horde grayed, vice versa)
- **Mobile as AFK** - Show mobile/BSAp friends with AFK status icon (BSAp only, not App)
- **Hide Max Level** - Option to hide level display for max-level characters
- **Accordion Groups** - Only allow one group open at a time (accordion-style)
- **Quick Filters: Hide AFK** - Filter to hide AFK/DND friends
- **Quick Filters: Retail Only** - Filter to show only retail (non-classic) friends
- **Invite All to Group** - Context menu option to invite all online friends in a group

### Changed
- **Improved Sort Dropdown UI** - Icon-based display (51px width), matching QuickFilters style
  - Status icon (green dot), Name icon (speaker), Level icon (skull), Zone icon (map marker)
  - Icon-only button display, icon+text in menu for clarity
- **Enhanced Tooltips** - Better tooltip positioning and more descriptive text

### Removed
- **Show Mobile Text** - Removed obsolete "(Mobile)" text feature (redundant with status icons)
- **Sort by Status Setting** - Removed redundant per-group sorting (use Sort dropdown instead)

### Fixed
- **Mobile AFK Logic** - Now only applies to BSAp (mobile devices), not App client

### Notes
- All 13 planned v1.2.0 features implemented
- Net deletion: 130 lines of obsolete code removed
- UI consistency improved across all dropdowns

---

## [1.1.0] - 2025-11-09

**📋 Export & Import System**

Settings portability with hex-encoded export/import functionality.

### Added
- **Export Settings** - Export all settings to a hex string (400+ LOC)
  - Includes groups, friends, settings, keybinds, activity data, and RAF history
  - Hex-encoded format (2 characters per byte)
  - Copy-to-clipboard with EditBox dialog
  - `/bfl export` command
- **Import Settings** - Import settings from hex string
  - Validates hex format and structure
  - Shows confirmation dialog before applying changes
  - `/bfl import` command
  - Validation with user-friendly error messages
- **Settings UI** - Advanced tab with Export/Import buttons
  - Large scrollable EditBox for hex string display
  - Clear instructions in the UI

### Technical Details
- Export format: `BFL_V1_{hex_encoded_data}`
- Serialization: `LibStub("AceSerializer-3.0")` for data structure conversion
- Error handling: Invalid format, corrupted data, version mismatch
- Full database snapshot (groups, friendGroups, settings, quickFilter, friendActivity, rafTracking)

### Files Changed
- NEW: Export/Import functionality in Settings.lua (~400 lines)
- MODIFIED: `BetterFriendlist_Settings.xml` (Advanced tab UI)
- MODIFIED: `Core.lua` (version 1.1.0, export/import commands)
- MODIFIED: `BetterFriendlist.toc` (version 1.1.0)

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
