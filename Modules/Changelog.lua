-- Modules/Changelog.lua
-- Displays the changelog in a scrollable window

local ADDON_NAME, BFL = ...
local L = BFL.L
local Changelog = BFL:RegisterModule("Changelog", {})

local changelogFrame = nil

-- Changelog content
local CHANGELOG_TEXT = [[
﻿# Changelog

All notable changes to BetterFriendlist will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [DRAFT]
### Fixed
- **Recent Allies & Recruit A Friend** - Fixed scrollbar positioning and length to match the Friends List standard.

## [2.2.9]       - 2026-02-03
### Fixed
- **Friend Button Layout** - Fixed an issue where Friend Name and Friend Info would not resize properly after adjusting Width via Settings.
- **Database Initialization** - Fixed a database initialization error.
- **QuickFilters** - Fixed a QuickFilter database issue causing filters to not update properly.

## [2.2.8]       - 2026-02-02
### Added
- **Streamer Mode** - Added Streamer Mode! When enabled you can toggle streamer mode to hide friend informations like Real IDs or your own battletag for privacy reasons. Real IDs will be hidden for following UI elements: Friend Name, Friend Tooltip, QuickJoin. You can change your own BattleTag with custom text in settings.
- **Favorite Icons** - Added an option to toggle the star icon for favorites directly on the friend button (Settings -> General). While enabled, favorite friends will be sorted above other friends in the same sorting subgroup.
- **Faction Backgrounds** - Added an option to show faction-colored backgrounds (Blue/Red) for friends in the list (Settings -> General).
- **Friend List Colors Support** - Automatically disables Name Format settings when "FriendListColors" addon is detected. When Friend List Colors is enabled all the name formatting actions will be led by the addon (Streamer Mode excluded).
- **Settings Layout** - Updated settings layout to better support future categories.
- **More Font Settings** - Added Font Settings for Tab Texts and Raid Player Name.
- **Window Lock Option** - Added option to lock the window to prevent moving it accidentally.

### Changed
- **Global Sync** - Global Sync is now flagged as stable feature and can be used without enabling beta features in BFL.

### Removed
- **Edit Mode** - Abandoned BFL's Edit Mode Support for now. Settings for width, height and scale can be found in settings instead. If the position, width, height or scale is different after the update please adjust it again - I wasn't able to restore all variants of Edit Mode Profiles to my settings. Sorry for the inconvenience!
- **Notification System** - Removed Notification Beta System for now. Might be added again in the future

### Fixed
- **Broker Tooltip** - Resolved an issue where the tooltip would not display correctly with display addons like ChocolateBar.
- **ElvUI Skin** - Fixed a Lua error ("index field 'BFLCheckmark'") that could occur when other addons (like ToyBoxEnhanced) create menus that BetterFriendlist tries to skin.
- **Groups Cache** - Fixed an issue with groups caching sometimes not updating properly when changing groups of a friend.

## [2.2.7]       - 2026-01-31
### Fixed
- **Library** - Fixed potential issues with LibQTip library integration.

## [2.2.6]       - 2026-01-31
### Added
- **Copy Character Name** - Added a new option to the context menu to copy character names (Name-Realm) for better inviting/messaging
- **Simple Mode** - Added Simple Mode in Settings -> General. Simple Mode hides specific elements (Search, Filter, Sort, BFL Avatar) and moves corresponding functions in the menu button
- **ElvUI Skin Tabs** - Improved alignment of tab text and overall layout of all tabs of BFL in ElvUI Skin

### Fixed
- **Friend Groups Migration** - Fixed an issue with FriendGroups Migration for WoW friends. Added more debug logs to better help with issues.
- **ElvUI Skin Retail** - Fixed an error with ElvUI Retail Skinning
- **ElvUI Skin Classic** - Fixed and enabled ElvUI Classic Skin
- **QuickJoin Informations** - Fixed an issue with shown QuickJoin informations lacking details of queued content type
- **Broker Integration** - Fixed an issue that disabled the Broker BFL Plugin
- **Performance** - Third iteration of performance added. If anything feels odd don't hesitate to contact
- **RAF** - Fixed an issue blocking the usage of copy link button in RAF Frame
- **Global Sync** - Fixed an error occuring while having own characters in sync added

## [2.2.5]       - 2026-01-25
### Fixed
- **Combat Blocking Fix** - Fixed a critical issue where the Friends List window could not be opened during combat, even when UI Panel settings were disabled. This resolves the "ADDON_ACTION_BLOCKED" error caused by unnecessary secure templates.
- **Localization** - Fixed encoding issues in English localization (enUS) where bullets and arrows were displayed as corrupted characters.

## [2.2.4]       - 2026-01-25
### Fixed
- **Mojibake Fix** - Fixed an issue where localized text (German, French, etc.) could display incorrect characters. (Core.lua)
- **QuickJoin** - Fixed quick join tooltips.
- **Edit Mode** - Fixed visibility issues when entering Edit Mode.

## [2.2.3]       - 2026-01-25
### Added
- **Typography Settings** - Added detailed font customization for Friend Names, Friend Info, and Group Headers. (Shadow settings coming soon).
- **Ignore List Enhancements** - Added support for "Global Ignore List" addon in our improved Ignore List frame, including a quick-toggle button.
- **Settings Overhaul** - Started restructuring the Settings panel for better organization. More improvements to come!
- **Group Visuals** - Added color customization for Group Collapse Arrows and Group Member Counts.
- **Classic Visuals** - Improved the visual design of collapse and expand arrows for group headers in Classic versions.

### Fixed
- **Edit Mode Stability** - Fixed an issue where opening Edit Mode immediately on startup (by other addons) would show BFL in an invalid state if no friend data was present.
- **Classic Localization** - Fixed missing localization keys for the Ignore List in Classic versions.
- **Visual Consistency** - Fixed the default friend name color to perfectly match Blizzard's standard UI color.
- **Quick Join Tooltips** - Fixed the "Request to Join" tooltip on travel pass buttons to show the correct group information.
- **Migration Notifications** - Fixed a bug where the "Migration Successful" message would appear after every UI reload.
- **Performance** - Implemented the second iteration of performance fixes for smoother scrolling and updates.
- **Housing System** - Fixed an issue preventing players from visiting friends' houses.
- **Startup Stability** - Fixed an issue where BetterFriendlist would remain open if other addons forcibly entered and exited Edit Mode during startup.
- **Combat Protection** - Added combat protection for UI Panel attributes.
- **Activity Tracker** - Added secret value protection in ActivityTracker for Midnight.

## [2.2.2]       - 2026-01-18
### Fixed
- **Font Support** - Reverted the friend name font to `GameFontNormal`. This restores support for the 4 standard fonts (including Asian/Cyrillic characters).
- **ElvUI Interaction** - **Note:** ElvUI Font Size settings now apply to the Friend Name again.
- **Workaround** - This is a temporary workaround. Proper independent font settings will be added in the next version.

## [2.2.1]       - 2026-01-18
### Fixed
- **Slash Commands** - Cleanup of slash commands.
- **Performance** - Fixed performance issues. (Reported by Drakblackz)
- **Menu System** - Fixed issue where menus would not close properly, likely due to mouse cursor changes. (Reported by Atom)

## [2.2.0]       - 2026-01-17
### Added
- **Group Name Alignment** - Added a new option to align group headers (Left, Center, Right). Left alignment is now the default. (Reported by Drakblackz)
- **Collapse/Expand Arrow** - Added options to hide the collapse/expand arrow and change its alignment (Left, Center, Right). Left is default. (Reported by Drakblackz)
- **Settings Button** - Added a dedicated cogwheel button to the main frame for easier access to settings, making it more discoverable for new users. (Reported by Atom)

### Fixed
- **Class Coloring** - Fixed an issue with class coloring not working correctly for some languages. (Reported by Drakblackz)
- **Performance** - Investigated and fixed small freezes that could occur when collapsing/expanding groups. (Reported by Drakblackz)
- **ElvUI Skin** - Fixed a Lua error related to the ElvUI skin integration. (Reported by Seiryoku)
- **ElvUI Skin** - Fixed skinning issues where ElvUI styles were not properly applied to some newer UI elements.
- **Send Message Button** - Fixed the "Send Message" button not working correctly in some scenarios. (Reported by Kylani)
- **Settings UI** - Fixed an issue where some dropdowns in general settings would not display their selected value.
- **Font Scaling** - Fixed visual issues with dropdowns and tab texts when global font size is overridden by other addons (e.g., ElvUI). (Reported by Drakblackz)
- **Sorting** - Fixed the Alphabetical Name sorter not working properly. (Reported by Drakblackz)

## [2.1.9]       - 2026-01-16
### Added
- **Global Ignore List Support** - Added a compatibility module for the "Global Ignore List" addon. The GIL window now correctly anchors to the BetterFriendlist frame (Main, Settings, Help, or Raid Info) and opens/closes automatically. (reported by Kiley01)

## [2.1.8]       - 2026-01-15
### Fixed
- **Critical Crash Fix** - Fixed "attempt to index global 'L' (a nil value)" error that prevented the Friends List from opening after the 2.1.7 update. Added missing localization table reference in FriendsList.lua.

## [2.1.7]       - 2026-01-14
### Fixed
- **Tab Switching Bug** - Fixed an issue where switching from "Who" or "Raid" back to "Contacts" would incorrectly display the Friends list even when "Recent Allies" or "Recruit A Friend" tabs were active.
- **Localization Fallback** - Improved fallback logic for missing translations. The addon now automatically uses English text when a translation is missing instead of displaying variable names.
- **Localization (All Languages)** - Significantly improved translations across all 11 supported languages. The German localization has been completely reworked to be less formal and more natural.

## [2.1.6]       - 2026-01-12
### Fixed
- **Quick Filters (Classic)** - Fixed a Lua error ("attempt to call method 'SetFilter' a nil value") when selecting a filter in the Classic version (reported by Loro).

## [2.1.5]       - 2026-01-11
### Added
- **Localization Update** - Significantly improved translation coverage across all 11 supported languages, especially for Raid Frame and Help features.
- **Asian Language Support** - Fixed issues with missing localization keys in Korean (koKR), Simplified Chinese (zhCN), and Traditional Chinese (zhTW).
- **Classic Guild Support** - Added better support for guilds in Classic. The addon now automatically disables the 'Classic Guild UI' setting as it requires the modern Guild UI.
- **Classic Guild Tab** - Added a Guild Tab in Classic which opens the modern guild window on click.
- **Classic Settings** - Added two new settings in Classic: 'Hide Guild Tab' and 'Close BetterFriendlist when opening Guild'.
- **UI Hierarchy** - Added a new setting for Retail and Classic: 'Respect UI Hierarchy'. This integrates BetterFriendlist into Blizzard's UI Panel System so it no longer overlaps other UI windows. (Requested by Surfingnet)
- **Raid Frame Help** - Added a Help Button to the Raid Tab explaining unique features like Multi-Selection, Drag & Drop, and Main Tank/Assist assignments.

## [2.1.4]       - 2026-01-07
### Fixed
- **Ignore List (Classic)** - Fixed visual layout issues in the Ignore List window:
  - Removed top gap ensuring the empty list starts at the correct position.
  - Replaced legacy scrollbar with standard UIPanelScrollBar for better visibility and usability.
  - Fixed "Unignore Player" button text displaying as a variable name instead of localized text.

## [2.1.3]       - 2026-01-06
### Fixed
- **Classic Portrait Button** - Fixed the PortraitButton frame strata and frame level. It now sits correctly above the frame but below dialogs (reported by Twoti).
- **Classic Invites** - Fixed a Lua error when viewing friend invites in Classic versions (missing text element) (reported by Twoti).

## [2.1.2]       - 2026-01-05
### Fixed
- **QuickFilter Persistence** - Fixed a bug where QuickFilter dropdown changes were not persistently saved, causing updates to apply previously cached values (reported by Loro).
- **QuickFilter UI** - Removed the separator line between QuickFilter dropdown options.
- **Hide AFK/DND** - Fixed "Hide AFK/DND" QuickFilter logic to correctly hide AFK/DND friends as expected.

## [2.1.1]       - 2026-01-03
### Fixed
- **FriendGroups Migration** - Fixed an issue where the migration tool could not be re-run if it had been run previously (or if the flag was set). You can now force a re-migration via the Settings dialog.

## [2.1.0]       - 2026-01-03
### Added
- **CustomNames Support** - Added support for the `CustomNames` library to sync nicknames (Thanks Jods!).

### Fixed
- **Group Cache** - Fixed an issue where newly created groups were not immediately available in the cache (reported by m33shoq).

## [2.0.9]       - 2026-01-03
### Added
- **ElvUI Skin** - Added full skinning support for the Changelog window and the Portrait/Changelog button.
- **ElvUI Stability** - Added comprehensive debug logging and error handling for the skinning process.

### Improved
- **Debug Logs** - Cleaned up global debug logs to reduce chat spam.

## [2.0.8]       - 2026-01-03
### Fixed
- **Data Broker Conflict** - Fixed a conflict with other Data Broker addons (like Broker Everything) where tooltips could become empty or stuck.
- **Tooltip Stability** - Improved robustness of tooltip cleanup and auto-hide logic to prevent resource leaks and ensure correct closing behavior.

## [2.0.7]       - 2026-01-01

### Fixed
- **Classic Dropdowns** - Fixed missing tooltips and incorrect width for QuickFilter and Sort dropdowns in Classic versions.
- **UI Insets** - Adjusted frame insets for better visual alignment.
- **Who Frame Layout** - Fixed ScrollFrame clipping into the SearchBox and adjusted ScrollBar height in Classic.

## [2.0.6]       - 2026-01-01

### Fixed
- **Battle.net Context Menu** - Fixed missing options in the right-click menu for Battle.net friends. Restored correct parameter passing to match Blizzard's expected format (regression from v2.0.5).

## [2.0.5]       - 2026-01-01

### Fixed
- **Crash Fix** - Fixed a crash ("script ran too long") caused by infinite recursion in group migration.
- **Performance** - Optimized event handling to prevent freezing during large friend list updates.
- **Who Frame** - Improved UI positioning for buttons in the Who tab (centering).
- **Quick Join** - Minor UI adjustments in the Quick Join tab.

## [2.0.4]       - 2026-01-01

### Fixed
- **Crash Fix** - Fixed a Lua error that could occur when logging in if the friend list was not yet fully initialized (`'for' limit must be a number`).

## [2.0.3]       - 2026-01-01

### Added
- **Global Friend Sync** (Beta) - Automatically syncs your WoW friends across all your characters. Includes support for Connected Realms (e.g. syncing friends between "Burning Blade" and "Draenor"). Configurable via Settings -> Advanced -> Beta Features.

### Changed
- **Data Broker Module** - Promoted from Beta to Standard feature. Now available to all users without enabling Beta Features.

### Fixed
- **Group Creation** - Fixed an issue when creating groups via right-click on WoW Friends.

## [2.0.2]       - 2025-12-31

### Fixed
- **WoW Friend Context Menu** - Fixed an issue where right-clicking WoW friends would not open the context menu.
- **Localization** - Fixed missing translations for dialogs and settings (e.g., Create Group dialog).
- **Raid Frame** - Fixed an issue where new raid members were not immediately visible upon joining.

## [2.0.1]       - 2025-12-29

### Added
- **Full Classic Support** - Added support for Classic Era, TBC Classic, Wrath Classic, Cataclysm Classic, and Mists of Pandaria Classic.
- **New Changelog System** - Introduced a new, user-friendly changelog system that keeps you informed about updates.

### Fixed
- **AFK/DND Status Display** - Fixed an issue where AFK and DND statuses were not correctly displayed in the Friendlist and DataBroker. (Thanks to Toxicator from CF!)

## [2.0.0]       - 2025-12-14

### 🚀 Major Update - ElvUI Integration, Nicknames & UI Overhaul

This is a comprehensive update bringing native ElvUI skin support, a custom nickname system, enhanced group displays, Quick Join visual redesign, Main Tank/Assist support in Raid, and numerous quality-of-life improvements across all tabs.

### Added

#### ElvUI Integration
- **Native ElvUI Skin** - Full visual integration with ElvUI's styling
  - Toggle on/off in Settings → General → "Enable ElvUI Skin"
  - Skins all frames, tabs, buttons, scrollbars, dropdowns, and checkboxes
  - Proper styling for Settings panel including dynamically created components
  - Context menu checkbox skinning with ElvUI's visual style
  - Requires UI reload when toggling (prompt included)

#### Friends List Enhancements
- **Custom Nicknames** - Assign personal nicknames to friends (separate from notes!)
  - Right-click any friend → "Set Nickname"
  - Use `%nickname%` token in Name Format to display it
  - Perfect for remembering who people are by their real name
  - Example: Display "John" instead of "RandomBattleTag#1234" while keeping notes for gameplay info
- **Flexible Name Formatting** - New token-based name display system
  - Available tokens: `%name%`, `%note%`, `%nickname%`, `%battletag%`
  - Configure in Settings → General → Name Formatting
  - Smart Fallback: If a token is empty (e.g., no nickname), falls back to account name automatically
  - Example formats: `%nickname%`, `%name% (%nickname%)`, `%battletag%`
- **Group Header Count Options** - Choose how friend counts are displayed
  - "Filtered / Total" (default): Shows currently visible vs. total members
  - "Online / Total": Shows online count vs. total members
  - "Filtered (Online) / Total": Shows all three numbers
  - Configure in Settings → General
- **Dynamic "In-Game" Group** - Automatic group for friends currently playing
  - Enable in Settings → General → "Show 'In-Game' Group"
  - Two modes: "WoW Only" (same WoW version) or "Any Game" (any Battle.net game)
  - Friends are automatically grouped when they're playing

#### Raid Frame Improvements
- **Main Tank & Main Assist Icons** - Visual indicators for raid role assignments
  - Shield icon for Main Tanks, flag icon for Main Assists
  - Automatically displays based on raid roster assignments
- **Secure Main Tank/Assist Toggle** - Assign roles directly from BetterFriendlist
  - Shift+Right-Click on raid member: Toggle Main Tank
  - Ctrl+Right-Click on raid member: Toggle Main Assist
  - Uses Blizzard's secure action system (works outside of combat)
- **Realm Name Truncation** - Long realm names no longer cause text wrapping
  - Names display cleanly without the realm suffix in raid buttons
- **Font Scaling Support** - Raid member names and levels now respect your font size setting

#### Quick Join Visual Overhaul
- **Complete Card Redesign** - Modern, informative group cards
  - Activity icon, title, and dungeon/raid name clearly visible
  - Leader name shown in Details line
  - Member count displayed in top-right corner
  - Role icons (Tank/Healer/DPS) showing what's needed
- **Selection Highlight** - Gold highlight when selecting a group
- **Click-to-Select** - Left-click now properly selects groups for joining
- **Improved Layout** - Better spacing, readable text, cleaner visual hierarchy

#### Who Frame Fixes
- **Dynamic Column Updates** - Changing the dropdown (Zone/Guild/Race) now immediately refreshes the list
  - Previously required a new /who query; now updates instantly from cached data
- **Text Alignment** - Name and variable columns now left-aligned for better readability
- **Font Scaling** - All Who frame text now respects your font size setting
- **Column Width Fix** - Long class names like "Death Knight" or "Demon Hunter" no longer overflow into the scrollbar

### Improved

#### Performance & Stability
- **Debug Output Cleanup** - Removed excessive debug prints from Raid Frame layout calculations
- **Font Manager Integration** - Consistent font scaling across all UI elements (Friends, Who, Raid)

#### Data Broker
- **Name Format Support** - Data Broker tooltip now respects your Name Formatting settings
  - Uses the same `%nickname%`, `%battletag%`, `%note%` tokens
  - Smart Fallback ensures names always display something useful
- **Sorting Consistency** - Name sorting in tooltip matches the displayed name format

#### Settings Panel
- **Dropdown Tooltips** - All dropdown settings now have proper tooltip support
- **Component Library Updates** - Improved SettingsComponents for better consistency
- **ElvUI Checkbox Styling** - All checkboxes in settings properly skinned when ElvUI is enabled

### Fixed

- **QuickJoin Selection** - Fixed left-click not selecting groups (button initialization was incomplete)
- **Who Frame Column Refresh** - Fixed columns not updating when changing dropdown selection
- **Raid Frame Text Overflow** - Fixed long names causing layout issues
- **RAF Reward Icon** - Fixed reward icon appearing desaturated when it shouldn't be
- **Settings Panel ElvUI** - Fixed scrollbar, tabs, and input fields not being skinned properly

---

## [1.9.5]       - 2025-12-06

### ⚡ Performance Optimization & Feature Requests

Comprehensive performance refactoring and implementation of user-requested features.

### Added
- **Built-in Group Customization** - You can now rename and recolor "Favorites" and "No Group"
  - Right-click on these group headers to access the new options
  - Custom colors are persisted and synced across characters

### Improved
- **Data Broker Enhancements** - Significant upgrades to the Data Broker module
  - **Advanced Tooltip**: Now uses LibQTip for a rich, multi-column display (Name, Status, Zone, Realm, Notes).
  - **Interactive Group Headers**:
    - **Collapse/Expand**: Left-click group headers in the tooltip to toggle visibility.
    - **Context Menu**: Right-click headers to Rename, Change Color, or Delete groups directly from the tooltip.
    - **Visual Feedback**: Added hover highlights and collapse indicators `(+)`/`(-)`.
  - **Visual Consistency**: Tooltip now respects all Friendlist visual settings:
    - **Notes as Name**: Uses your custom notes if enabled.
    - **Class Colors**: Names are colored by class (respecting "Colorize names" setting).
    - **Faction Icons**: Shows faction icons if enabled.
    - **Grayed Out**: Respects "Gray out other faction" setting.
  - **Text Formatting**: New options to toggle "Friends:" label and Total count (e.g. "5" vs "Friends: 5/10").
  - **Fixed Footer**: Summary information is now pinned to the bottom of the tooltip.
  - **Interactive Actions**:
    - **Left-Click**: Toggle Friends List window.
    - **Right-Click**: Open Settings.
    - **Middle-Click**: Cycle through filters (All, Online, WoW, Battle.net).
  - **Visual Polish**:
    - **Game Icons**: Updated support for all modern Battle.net games (Diablo IV, Overwatch 2, Rumble, etc.).
    - **Status Icons**: Clear indicators for Online, AFK, DND, and Mobile status.
- **Smart Group Counts** - Group headers now show `(Shown/Total)` counts when filters are active (e.g., "Favorites (2/5)" when 3 are offline).
- **Sorting Logic Overhaul** - "What You See Is What You Sort"
  - **Smart Name Sorting**: Now respects "Show Notes as Name" setting. If you see a note, it sorts by that note.
  - **BattleTag Sorting**: Sorts by the visible name only (e.g., "Jonas"), ignoring the hidden Real ID and discriminator (#1234).
  - **Offline Sorting**: Offline friends are now automatically sorted by "Last Online" time (most recent first).
- **Global Visibility Awareness** - The addon now intelligently pauses all processing when the frame is hidden
  - **Friends List**: No longer processes updates in the background while playing
  - **Raid Frame**: Completely dormant until the Raid tab is opened
  - **Who Frame**: Zero CPU usage when not actively searching
  - **Quick Join**: Social Queue updates are paused while the tab is closed
  - **Result**: Massive CPU reduction during gameplay, especially in busy environments (cities, raids)
- **Smart Event Coalescing** - Implemented micro-throttling (1-frame delay) for all list updates
  - Replaces fixed-interval throttling with a smarter, responsive system
  - Eliminates redundant calculations during "event bursts" (e.g., mass logins, zone changes, raid joins)
  - Ensures the UI feels instant while preventing "update storms"
- **Lazy Loading Architecture** - Tabs now only initialize and render when first clicked
  - Reduces initial addon load time
  - Prevents memory allocation for features you aren't currently using

### Changed
- **Sort Menu Cleanup** - Removed redundant "Sort by Note" option (functionality integrated into "Sort by Name")

## [1.9.4]       - 2025-12-05

### 🔗 ElvUI Compatibility & Quick Join Fixes

Full compatibility with ElvUI and other UI replacement addons, plus Quick Join improvements.

### Added
- **Smart Tab Support** - Opening Quick Join, Who, or Raid from other addons now opens the correct tab
  - ElvUI Quick Join Datatext opens BetterFriendlist directly on Quick Join tab
  - Works with any addon using `ToggleFriendsFrame(tabIndex)` or `ToggleQuickJoinPanel()`
  - Intelligent toggle: requesting a different tab switches tabs instead of closing

### Fixed
- **ElvUI Friends Button** - Now correctly opens BetterFriendlist instead of Blizzard's frame
  - Works even when ElvUI caches `ToggleFriendsFrame` at load time
  - Multi-layer hook strategy intercepts FriendsFrame regardless of how it's opened
- **Combat Compatibility** - Fixed "Interface action failed because of an AddOn" errors
  - Removed FriendsFrame from UIPanel system for combat-safe Hide()
  - No more taint issues when closing the frame during combat
- **Quick Join Leader Names** - Now shows the correct character name in tooltips
  - Previously showed the Battle.net account name instead of the character name
  - Now correctly shows the character name with realm (e.g., "Tsveta-ChamberofAspects")

### Improved
- **Hook System** - Completely rewritten for maximum addon compatibility
  - FriendsFrame:OnShow hook catches ALL methods of opening the friends frame
  - Detects requested tab from Blizzard's selection and passes it through
  - "Show Blizzard's Friendlist" menu option works reliably with proper UIPanel handling
- **Quick Join Data Handling** - Better extraction of LFG List group information
  - Stores LFG List ID for fresh data lookup in tooltips
  - Ensures character names are always up-to-date

---

## [1.9.2]       - 2025-01-05

### 🔌 Data Broker Integration (Beta) & New Features

Display your online friends count on any Data Broker display addon, plus new customization options.

### Added
- **Data Broker Integration** (Beta Feature) - Show friends on display bars
  - Works with Bazooka, ChocolateBar, TitanPanel, and other Data Broker displays
  - Rich tooltip with full friends list, grouping, and game icons
  - Click friends to whisper, Alt+Click to invite, Right-Click for context menu
  - Middle-Click on broker icon to cycle through quick filters
  - Configure in Settings → Data Broker tab (requires Beta Features enabled)
- **Window Scale** - Scale your friends list window from 50% to 200%
  - Available in Edit Mode settings (WoW's Edit Mode → select BetterFriendlist)
  - Perfect for high-resolution displays or compact setups
  - Scale is saved per Edit Mode layout
- **Show Notes as Friend Name** - New option in General settings
  - Display your personal notes as the friend's name in the list
  - Great for remembering who people are by their real name or nickname
- **Treat Mobile as Offline** - New option in General settings
  - Friends using the Battle.net Mobile App can be shown in the Offline group
  - Keeps your online friends list focused on people actually in games

### Fixed
- **Edit Mode Overlay** - Search box in Who tab no longer appears above the Edit Mode overlay
  - Previously the search field would cover the Edit Mode selection when repositioning
  - Now correctly stays below the overlay for smooth Edit Mode usage
- **Raid Frame Control Panel** - Buttons now update correctly when resizing the window
  - AllAssist button and member counts stay properly positioned after resize

### Improved
- **Who Tab Columns** - Better column width distribution
  - Name, level, class columns now align perfectly with headers
  - Responsive layout accounts for header overlaps correctly
  - Row content scales smoothly with frame width changes
- **Group Color Changes** - Colors update immediately without needing to scroll
  - Same improvement for compact mode and font size changes

---

## [1.9.1]       - 2025-11-29

**🎯 Edit Mode & RaiderIO Integration**

Resize and position your friends list window freely, plus seamless integration with RaiderIO and other tooltip addons.

### Added
- **Edit Mode Integration** - Full frame positioning and resizing support
  - Drag and position your friends list window anywhere on screen
  - Resize window width (380-800px) and height (400-1200px) to your preference
  - Use WoW's Edit Mode (/editmode) to customize your layout
  - Size and position saved per Edit Mode layout
  - All UI elements scale dynamically with frame size
- **RaiderIO Integration** - Friend tooltips now work with popular addons
  - RaiderIO scores appear automatically below friend information
  - Activity tracking ("Last contact") displays cleanly with divider line
  - Works with any addon that enhances friend tooltips
  - No configuration needed - works out of the box

### Fixed
- **Context Menu** - Friend group menu now appears correctly
  - Group management options show when right-clicking friends
  - Fixed menu appearing for non-friends (WHO list, guilds)
  - Proper menu isolation for different friend types
- **Tooltip Display** - Friend tooltips now appear correctly in all situations
  - Tooltips show when friends list window is closed
  - Activity information positioned perfectly without overlap
  - Consistent appearance with other WoW tooltips
- **QuickJoin Display** - Player names no longer cause errors
  - Fixed crash when friend has no character name
  - Guild and club member lookups now validate names properly

---

## [1.9.0]       - 2025-11-25

**🔔 Beta Feature - Smart Notifications**

Complete notification system with friend status alerts, quiet hours, per-friend rules, and group notification controls.

### Added
- **Friend Status Notifications** - Get notified when friends come online, go offline, or switch characters
  - Three display modes: Toast notifications, chat messages, or disabled
  - Separate toggles for online, offline, and character switch events
  - Optional sound effects (default: Battle.net toast sound)
  - Test button to preview notifications
  - Smart cooldowns: 30s for online/offline, 10s for character switches
- **Quiet Hours System** - Control when notifications appear
  - Manual Do Not Disturb mode (highest priority)
  - Auto-silence during combat encounters
  - Auto-silence in dungeons, raids, and PvP
  - Scheduled quiet hours (default: 22:00-08:00)
  - Time-based scheduling with midnight crossing support
- **Per-Friend Notification Rules** - Customize notifications for specific friends
  - Whitelist: Always notify (bypasses quiet hours and cooldowns)
  - Blacklist: Never notify (complete silence for that friend)
  - Default: Use global notification settings
  - Accessible via right-click menu "Notification Settings"
- **Group Notification Rules** - Control notifications for entire friend groups
  - Set Whitelist/Blacklist/Default for any custom group
  - Right-click on group header to access Notifications menu
  - All members of whitelisted groups bypass quiet hours
  - Works with favorites group too
  - Priority system: Per-friend rules override group rules
- **Notification Positioning** - Drag and drop toast notifications in Edit Mode
  - Enter WoW's Edit Mode to reposition notification toasts
  - Preview toasts appear during Edit Mode
  - Position saves automatically
  - Professional library integration (LibEditMode)
- **All features require Beta Features toggle** - Enable in Settings → Advanced → Beta Features

### Fixed
- **Friend list updates** - Friend list now always stays synchronized, even when window is closed
  - Previously friends could show as online for minutes after logging off
  - Data now updates in background regardless of window visibility
- **Character switch notifications** - Now work correctly with independent cooldowns
  - Character switches have separate 10-second cooldown from online/offline events
  - No longer blocked by online notification cooldowns
- **False game switch alerts** - Eliminated duplicate notifications during character switches
  - System now detects and ignores transient loading states
  - Only shows one notification when switching characters
- **Beta Features styling** - All Beta feature text now uses consistent orange color
  - Changed from gold to orange for better visual distinction
  - "Currently available Beta features:" title properly colored

### Changed
- Orange color scheme for Beta Features section in settings (changed from gold)
- Removed "Bulk Friend Operations" from Beta features list (feature moved to future release)

---

## [1.8.2]       - 2025-11-21

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

## [1.8.1]       - 2025-11-16

**🐛 Bug Fix**

Fixed compact mode toggle causing errors.

### Fixed
- **Compact Mode Setting** - Fixed "attempt to call method 'InvalidateDataProvider' (a nil value)" error
  - Replaced non-existent ScrollBox method with correct FriendsList:RenderDisplay() call
  - Compact mode toggle now works without errors

---

## [1.8.0]       - 2025-11-16

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

## [1.7.5]       - 2025-11-16

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

## [1.7.4]       - 2025-11-16

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

## [1.7.3]       - 2025-11-16

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

## [1.7.1]       - 2025-11-16

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

## [1.7.0]       - 2025-11-15

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

## [1.6.8]       - 2025-11-15

**📝 Documentation Cleanup**

Removed technical details from changelog to keep it user-friendly.

### Changed
- Cleaned up changelog entries to remove technical implementation details
- Now focuses on what users can do and what problems were fixed
- Follows Keep-a-Changelog best practices for user-facing documentation

---

## [1.6.7]       - 2025-11-15

**🌍 Class Colors for All Languages**

Class names now show in proper colors for all languages, including German, French, Spanish, and other localized clients.

### Fixed
- **Class Color Display** - Character names now display in correct class colors for non-English clients
- Previously only worked for English clients; showed white text for German, French, Spanish, and other languages
- Handles gendered class names (German "Kriegerin" for female warriors, "Dämonenjägerin" for female demon hunters)
- Works for both Battle.net friends and WoW-only friends

---

## [1.6.5]       - 2025-11-15

**🔧 Friends List Scroll Fix**

Fixed scroll frame height calculation to prevent entries from being cut off.

### Fixed
- **Scroll Height Calculation** - Last few friend entries are now fully visible when scrolling to the bottom
- Scroll position correctly accounts for all visible content including Friend Requests
- Works correctly whether Friend Requests are shown, hidden, collapsed, or expanded

---

## [1.6.0]       - 2025-11-14

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

## [1.5.0-beta]  - 2025-11-12

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

## [1.4.0-beta]  - 2025-11-12

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

## [1.3.4-beta]  - 2025-11-11

**🔧 Code Quality & Export Fix**

### Fixed
- Export/import now includes user-customized group colors
- Backward compatible with old exports

### Improved
- Replaced 33+ magic numbers with UI_CONSTANTS
- Added bounds checking for 25 unsafe array accesses
- Cache cleanup and duplicate event registration fixes

---

## [1.3.3-beta]  - 2025-11-11

**⚡ Scroll Fix & Performance**

### Fixed
- Scroll position now preserved during friend list updates

### Improved
- Optimized string concatenation performance (4 functions)
- Began magic number constant migration

---

## [1.3.2-beta]  - 2025-11-11

**🛡️ High Severity Fixes**

### Fixed
- Tooltip error handling (wrapped in pcall, clears on errors)
- Migration version check (prevents re-running FriendGroups import)
- 3 division by zero vulnerabilities in PerformanceMonitor

---

## [1.3.1-beta]  - 2025-11-11

**🐛 Critical Bug Fixes**

### Fixed
- Memory leak in ButtonPool (buttons retained friend data references)
- Race condition in FriendsList (concurrent FRIENDLIST_UPDATE events)
- Added concurrency protection with update queue mechanism

---

## [1.3.0-beta]  - 2025-11-10

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

## [1.1.0]       - 2025-11-09

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

## [1.0.0]       - 2025-11-09

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

## [0.15.0]      - 2025-11-08

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

## [0.14.0]      - 2025-11-06

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

## [0.13.0]      - 2025-11-05

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

## [0.12.0]      - 2025-11-03

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

## [0.11.0]      - 2025-11-02

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

## [0.10.0]      - 2025-11-01

### Added
- Phase 3: Button Pool Management Module
  - Modules/ButtonPool.lua (378 lines)
  - Button recycling system
  - Drag & drop support

### Changed
- BetterFriendlist.lua: 3448 → 3202 lines (-7.1% reduction)
- Version bump: 0.9 → 0.10

---

## [0.9.0]       - 2025-10-31

### Added
- Phase 1-2: Core Modularization
  - 11 core modules created
  - Utils modules (FontManager, ColorManager, AnimationHelpers)
  - Database, Groups, FriendsList, WhoFrame, IgnoreList
  - RecentAllies, MenuSystem, QuickFilters, Settings, Dialogs, RAF

### Changed
- BetterFriendlist.lua: 4500+ → 3448 lines (-23% reduction)

---

## [1.1.0]       - 2025-11-09

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
]]

-- Helper to set title safely across versions
local function SetTitle(frame, title)
    if frame.TitleText and frame.TitleText.SetText then
        frame.TitleText:SetText(title)
    elseif frame.TitleContainer and frame.TitleContainer.TitleText then
        frame.TitleContainer.TitleText:SetText(title)
    end
end

local function StripEmojis(text)
    -- 1. Replace specific symbols
    text = text:gsub("→", ">")
    
    -- 2. Remove known emojis
    local emojis = {
        "🚀", "⚡", "🔗", "🔌", "🎯", "🔔", "🐛", "🔧", "✨", "📝", 
        "🌍", "🎮", "📨", "🛡️", "📊", "🎉", "🎨", "📋", "✅"
    }
    for _, emoji in ipairs(emojis) do
        text = text:gsub(emoji, "")
    end

    -- 3. Catch-all for 4-byte characters (Generic Emoji range)
    text = text:gsub("[\240-\247][\128-\191][\128-\191][\128-\191]", "")
    
    return text
end

local function CleanLine(line)
    -- Remove comments
    line = line:gsub("/%*.-%*/", "")
    -- Remove emojis
    line = StripEmojis(line)
    -- Remove backticks
    line = line:gsub("`", "")
    -- Trim whitespace
    return line:gsub("^%s+", "")
end

local function FormatInline(text)
    -- Bold **text**
    text = text:gsub("%*%*(.-)%*%*", "|cffffffff%1|r")
    -- Links
    text = text:gsub("%[(.-)%]%((.-)%)", "|cff66bbff%1|r")
    return text
end

local function ParseChangelog(text)
    local entries = {}
    local currentEntry = nil
    
    for line in text:gmatch("[^\r\n]+") do
        -- Match version and date with flexible whitespace handling
        local version, date = line:match("^## %[(.-)%]%s*-%s*(.+)")
        
        -- Fallback for entries with just version (like DRAFT or future unreleased)
        -- Although the previous code required date, sometimes [Unreleased] has no date
        if not version then
             version = line:match("^## %[(.-)%]%s*$")
             date = ""
        end

        if version and date ~= "" then -- Maintain previous behavior of requiring date mostly, or strictly adhering to "Header has date"
            -- Actually, let's stick closer to original logic but allow extra spaces
            -- Trim date just in case
            date = date:match("^%s*(.-)%s*$")
            
            if currentEntry then
                table.insert(entries, currentEntry)
            end
            currentEntry = {
                version = version,
                date = date,
                blocks = {}
            }
        elseif currentEntry then
            local cleanLine = CleanLine(line)
            if cleanLine ~= "" then
                -- Determine block type
                if cleanLine:match("^# ") then
                    table.insert(currentEntry.blocks, {
                        type = "h1",
                        content = FormatInline(cleanLine:gsub("^# ", ""))
                    })
                elseif cleanLine:match("^#### ") then
                    table.insert(currentEntry.blocks, {
                        type = "h4",
                        content = FormatInline(cleanLine:gsub("^#### ", ""))
                    })
                elseif cleanLine:match("^### ") then
                    table.insert(currentEntry.blocks, {
                        type = "h3",
                        content = FormatInline(cleanLine:gsub("^### ", ""))
                    })
                elseif cleanLine:match("^%- ") then
                    table.insert(currentEntry.blocks, {
                        type = "list_item",
                        content = FormatInline(cleanLine:gsub("^%- ", ""))
                    })
                elseif cleanLine:match("^%-%-%-") or cleanLine:match("^%*%*%*") or cleanLine:match("^___") then
                    table.insert(currentEntry.blocks, {
                        type = "separator"
                    })
                else
                    table.insert(currentEntry.blocks, {
                        type = "text",
                        content = FormatInline(cleanLine)
                    })
                end
            end
        end
    end
    
    if currentEntry then
        table.insert(entries, currentEntry)
    end
    
    return entries
end

local function RecalculateHeight(contentFrame, entryFrames)
    local totalHeight = 10
    for _, frame in ipairs(entryFrames) do
        totalHeight = totalHeight + frame:GetHeight() + 5
    end
    contentFrame:SetHeight(totalHeight)
end

local function ShowCopyDialog(url, title)
    StaticPopupDialogs["BETTERFRIENDLIST_COPY_URL"] = {
        text = title or "Copy URL",
        button1 = "Close",
        hasEditBox = true,
        editBoxWidth = 350,
        OnShow = function(self)
            self.EditBox:SetText(url)
            self.EditBox:SetFocus()
            self.EditBox:HighlightText()
            self.EditBox:SetScript("OnKeyUp", function(editBox, key)
                if IsControlKeyDown() and key == "C" then
                    editBox:GetParent():Hide()
                end
            end)
        end,
        EditBoxOnEnterPressed = function(self)
            self:GetParent():Hide()
        end,
        EditBoxOnEscapePressed = function(self)
            self:GetParent():Hide()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
    StaticPopup_Show("BETTERFRIENDLIST_COPY_URL")
end

function Changelog:ShowDiscordPopup()
    ShowCopyDialog("https://discord.gg/dpaV8vh3w3", L.CHANGELOG_POPUP_DISCORD)
end

function Changelog:IsNewVersion()
    local DB = BFL:GetModule("DB")
    local lastVersion = DB:Get("lastChangelogVersion", "0.0.0")
    local currentVersion = BFL.VERSION
    return lastVersion ~= currentVersion
end

function Changelog:Initialize()
    -- Setup PortraitButton for Classic - create entirely in Lua for full control
    if BFL.IsClassic and BetterFriendsFrame then
        self:SetupClassicPortraitButton()
    end
    
    -- Check version and show glow if needed
    self:CheckVersion()
end

function Changelog:SetupClassicPortraitButton()
    local frame = BetterFriendsFrame
    if not frame then 
        return 
    end
    
    -- Hide the default portrait from ButtonFrameTemplate
    if frame.portrait then 
        frame.portrait:Hide() 
    end
    
    -- Create clickable button as child of the frame (ensures correct Z-ordering with other windows)
    -- This fixes the issue where it covers other UI frames like CharacterInfo
    local button = CreateFrame("Button", "BFL_ClassicPortraitButton", frame)
    button:SetSize(60, 60)
    
    -- Ensure it sits above the frame background
    button:SetFrameLevel(frame:GetFrameLevel() + 5)
    
    button:EnableMouse(true)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    
    -- Invisible hit rect (needed for click detection)
    local hitRect = button:CreateTexture(nil, "BACKGROUND")
    hitRect:SetAllPoints()
    hitRect:SetTexture("Interface\\BUTTONS\\WHITE8X8")
    hitRect:SetVertexColor(0, 0, 0, 0)  -- Fully transparent
    
    -- Portrait Icon 
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetTexture("Interface\\AddOns\\BetterFriendlist\\Textures\\PortraitIcon")
    icon:SetSize(60, 60)
    icon:SetPoint("CENTER")
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    button.Icon = icon
    
    -- Apply circular mask to the icon
    local mask = button:CreateMaskTexture()
    mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    mask:SetSize(60, 60)
    mask:SetPoint("CENTER")
    icon:AddMaskTexture(mask)
    
    -- Glow texture for new version notification (hidden by default)
    -- Using CurrentPlayer-Glow from tournamentorganizer (exists in Classic)
    -- Positioned like Retail: TOPLEFT x=-18 y=12, BOTTOMRIGHT x=64 y=-64 relative to 60x60 button
    local glow = button:CreateTexture(nil, "OVERLAY", nil, 7)
    glow:SetTexture("Interface\\PVPFrame\\TournamentOrganizer")
    glow:SetTexCoord(0.3173828125, 0.4423828125, 0.0341796875, 0.1591796875)
    glow:SetBlendMode("ADD")
    glow:ClearAllPoints()
    glow:SetPoint("TOPLEFT", button, "TOPLEFT", -18, 16)
    glow:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 64, -64)
    glow:SetVertexColor(1.0, 1.0, 1.0, 1.0)  -- White like Retail
    glow:Hide()
    button.Glow = glow
    
    -- Position relative to main frame
    button:ClearAllPoints()
    button:SetPoint("TOPLEFT", -5, 7)
    
    -- Click handler
    button:SetScript("OnClick", function(self, btn)
        local Changelog = BFL:GetModule("Changelog")
        if Changelog then
            Changelog:ToggleChangelog()
        end
    end)
    
    -- Hover handlers
    button:SetScript("OnEnter", function(self)
        local Changelog = BFL:GetModule("Changelog")
        if Changelog then
            Changelog:OnPortraitEnter(self)
        end
    end)
    
    button:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
    
    -- No need to manual sync visibility if it's a child, but let's be safe if it gets parented elsewhere in future
    -- Actually, child frame automatically hides when parent hides. 
    -- But we keep the reference logic.
    
    -- Store reference
    frame.PortraitButton = button
    frame.PortraitIcon = icon
    
    -- BFL:DebugPrint("Changelog", "Classic PortraitButton created")
end

function Changelog:CheckVersion()
    local DB = BFL:GetModule("DB")
    local lastVersion = DB:Get("lastChangelogVersion", "0.0.0")
    local currentVersion = BFL.VERSION
    
    if lastVersion ~= currentVersion then
        self:ShowGlow(true)
    else
        self:ShowGlow(false)
    end
end

function Changelog:ShowGlow(show)
    if BetterFriendsFrame and BetterFriendsFrame.PortraitButton then
        local button = BetterFriendsFrame.PortraitButton
        
        -- Create NewLabel texture if it doesn't exist
        if not button.NewLabel then
            button.NewLabel = button:CreateTexture(nil, "OVERLAY")
            button.NewLabel:SetPoint("CENTER", button, "CENTER", 0, 0)
            if BFL.IsClassic then
                -- Use NewCharacter-Horde texture from CharacterCreate (exists in Classic)
                --button.NewLabel:SetTexture("interface\\encounterjournal\\adventureguide")
                --button.NewLabel:SetTexCoord(0.677734375, 0.75, 0.099609375, 0.171875)
                --button.NewLabel:SetSize(37, 37)  -- Scaled down from 112x58
                button.NewLabel:SetAtlas("communities-icon-invitemail")
                button.NewLabel:SetSize(64, 48)
            else
                button.NewLabel:SetAtlas("CharacterCreate-NewLabel")
                button.NewLabel:SetSize(64, 48)
            end
            -- Desaturate to remove the native color, then color it gold
            button.NewLabel:SetDesaturated(true)
            button.NewLabel:SetVertexColor(1, 0.82, 0, 1)
        end

        if show then
            if button.Glow then button.Glow:Show() end
            if button.NewLabel then button.NewLabel:Show() end
        else
            if button.Glow then button.Glow:Hide() end
            if button.NewLabel then button.NewLabel:Hide() end
        end
    end
end

function Changelog:ToggleChangelog()
    if not changelogFrame then
        self:CreateChangelogWindow()
    end
    
    if changelogFrame:IsShown() then
        changelogFrame:Hide()
    else
        changelogFrame:Show()
        -- Update version in DB
        local DB = BFL:GetModule("DB")
        DB:Set("lastChangelogVersion", BFL.VERSION)
        self:ShowGlow(false)
    end
end

function Changelog:OnPortraitEnter(button)
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    GameTooltip:SetText("BetterFriendlist " .. (BFL.VERSION or ""), 1, 0.82, 0)
    
    local DB = BFL:GetModule("DB")
    local lastVersion = DB:Get("lastChangelogVersion", "0.0.0")
    
    if lastVersion ~= BFL.VERSION then
        GameTooltip:AddLine(L.CHANGELOG_TOOLTIP_UPDATE, 0, 1, 0)
        GameTooltip:AddLine(L.CHANGELOG_TOOLTIP_CLICK, 1, 1, 1)
    else
        GameTooltip:AddLine(L.CHANGELOG_TOOLTIP_CLICK, 1, 1, 1)
    end
    
    GameTooltip:Show()
end

function Changelog:Show()
    self:ToggleChangelog()
end

function Changelog:CreateChangelogWindow()
    -- Use ButtonFrameTemplate to match Settings window
    local frame = CreateFrame("Frame", "BetterFriendlistChangelogFrame", UIParent, "ButtonFrameTemplate")
    frame:SetSize(600, 500)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    
    -- Setup ButtonFrameTemplate features
    if frame.portrait then frame.portrait:Hide() end
    if frame.PortraitContainer then frame.PortraitContainer:Hide() end
    
    if ButtonFrameTemplate_HidePortrait then
        ButtonFrameTemplate_HidePortrait(frame)
    end
    if ButtonFrameTemplate_HideAttic then
        ButtonFrameTemplate_HideAttic(frame)
    end
    
    -- Hide default Inset
    if frame.Inset then frame.Inset:Hide() end
    
    SetTitle(frame, L.CHANGELOG_TITLE)
    
    -- Create MainInset to match Settings style
    local mainInset = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    frame.MainInset = mainInset
    mainInset:SetPoint("TOPLEFT", 10, -25) -- Adjusted y since we don't have tabs
    mainInset:SetPoint("BOTTOMRIGHT", -4, 5) -- Adjusted y since we don't have bottom buttons
    
    mainInset:SetBackdrop({
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 6,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    mainInset:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.8)

    -- Header Frame (Links)
    local headerFrame = CreateFrame("Frame", nil, mainInset)
    headerFrame:SetPoint("TOPLEFT", 1, -1)
    headerFrame:SetPoint("TOPRIGHT", -1, -1)
    headerFrame:SetHeight(40)
    
    -- Background for header
    local headerBg = headerFrame:CreateTexture(nil, "BACKGROUND")
    headerBg:SetAllPoints()
    headerBg:SetColorTexture(0.1, 0.1, 0.1, 0.5)

    -- Separator line
    local headerLine = headerFrame:CreateTexture(nil, "ARTWORK")
    headerLine:SetHeight(1)
    headerLine:SetPoint("BOTTOMLEFT", 0, 0)
    headerLine:SetPoint("BOTTOMRIGHT", 0, 0)
    headerLine:SetColorTexture(0.4, 0.4, 0.4, 0.8)

    -- Intro Text
    local headerText = headerFrame:CreateFontString(nil, "OVERLAY", "BetterFriendlistFontNormal")
    headerText:SetPoint("LEFT", 10, 0)
    headerText:SetText(L.CHANGELOG_HEADER_COMMUNITY)

    -- Discord Button (Rightmost)
    local discordBtn = CreateFrame("Button", nil, headerFrame, "UIPanelButtonTemplate")
    frame.DiscordButton = discordBtn
    discordBtn:SetSize(130, 24)
    discordBtn:SetPoint("RIGHT", -10, 0)
    discordBtn:SetText(L.CHANGELOG_DISCORD)
    
    local dcIcon = discordBtn:CreateTexture(nil, "ARTWORK")
    dcIcon:SetSize(14, 14)
    dcIcon:SetPoint("LEFT", 10, 0)
    dcIcon:SetColorTexture(1, 0.82, 0) -- Gold
    
    local dcMask = discordBtn:CreateMaskTexture()
    dcMask:SetSize(14, 14)
    dcMask:SetPoint("LEFT", 10, 0)
    dcMask:SetTexture("Interface\\AddOns\\BetterFriendlist\\Icons\\discord.blp")
    dcIcon:AddMaskTexture(dcMask)
    
    discordBtn:SetScript("OnClick", function()
        ShowCopyDialog("https://discord.gg/dpaV8vh3w3", L.CHANGELOG_POPUP_DISCORD)
    end)

    -- GitHub Button (Left of Discord)
    local githubBtn = CreateFrame("Button", nil, headerFrame, "UIPanelButtonTemplate")
    frame.GitHubButton = githubBtn
    githubBtn:SetSize(130, 24)
    githubBtn:SetPoint("RIGHT", discordBtn, "LEFT", -10, 0)
    githubBtn:SetText(L.CHANGELOG_GITHUB)
    
    local ghIcon = githubBtn:CreateTexture(nil, "ARTWORK")
    ghIcon:SetSize(14, 14)
    ghIcon:SetPoint("LEFT", 10, 0)
    ghIcon:SetColorTexture(1, 0.82, 0) -- Gold
    
    local ghMask = githubBtn:CreateMaskTexture()
    ghMask:SetSize(14, 14)
    ghMask:SetPoint("LEFT", 10, 0)
    ghMask:SetTexture("Interface\\AddOns\\BetterFriendlist\\Icons\\github.blp")
    ghIcon:AddMaskTexture(ghMask)
    
    githubBtn:SetScript("OnClick", function()
        ShowCopyDialog("https://github.com/Hayato2846/BetterFriendlist/issues", L.CHANGELOG_POPUP_GITHUB)
    end)

    -- Ko-fi Button (Left of GitHub)
    local kofiBtn = CreateFrame("Button", nil, headerFrame, "UIPanelButtonTemplate")
    frame.KoFiButton = kofiBtn
    kofiBtn:SetSize(130, 24)
    kofiBtn:SetPoint("RIGHT", githubBtn, "LEFT", -10, 0)
    kofiBtn:SetText(L.CHANGELOG_SUPPORT)
    
    local kofiIcon = kofiBtn:CreateTexture(nil, "ARTWORK")
    kofiIcon:SetSize(14, 14)
    kofiIcon:SetPoint("LEFT", 10, 0)
    kofiIcon:SetColorTexture(1, 0.82, 0) -- Gold
    
    local kofiMask = kofiBtn:CreateMaskTexture()
    kofiMask:SetSize(14, 14)
    kofiMask:SetPoint("LEFT", 10, 0)
    kofiMask:SetTexture("Interface\\AddOns\\BetterFriendlist\\Icons\\kofi.blp")
    kofiIcon:AddMaskTexture(kofiMask)
    
    kofiBtn:SetScript("OnClick", function()
        ShowCopyDialog("https://ko-fi.com/hayato2846", L.CHANGELOG_POPUP_SUPPORT)
    end)

    -- ScrollFrame
    local scrollFrame
    
    if not BFL.IsClassic and ScrollUtil and ScrollUtil.InitScrollFrameWithScrollBar then
        -- Retail: Modern ScrollUtil
        scrollFrame = CreateFrame("ScrollFrame", nil, frame)
        frame.ScrollFrame = scrollFrame
        scrollFrame:SetPoint("TOPLEFT", mainInset, "TOPLEFT", 8, -45) -- Adjusted for header
        scrollFrame:SetPoint("BOTTOMRIGHT", mainInset, "BOTTOMRIGHT", -25, 5)
        
        -- Mixin CallbackRegistry (Required for ScrollUtil)
        if not scrollFrame.RegisterCallback then
            Mixin(scrollFrame, CallbackRegistryMixin)
            scrollFrame:OnLoad()
        end
        
        -- Create ScrollBar (EventFrame inheriting MinimalScrollBar)
        local scrollBar = CreateFrame("EventFrame", nil, frame, "MinimalScrollBar")
        frame.ScrollBar = scrollBar
        scrollBar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", 6, 0)
        scrollBar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", 6, 0)
        
        ScrollUtil.InitScrollFrameWithScrollBar(scrollFrame, scrollBar)
    else
        -- Classic: Legacy UIPanelScrollFrameTemplate
        scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
        frame.ScrollFrame = scrollFrame
        scrollFrame:SetPoint("TOPLEFT", mainInset, "TOPLEFT", 8, -45) -- Adjusted for header
        scrollFrame:SetPoint("BOTTOMRIGHT", mainInset, "BOTTOMRIGHT", -25, 5)
    end
    
    -- Content
    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(560, 1000) -- Height will be adjusted
    scrollFrame:SetScrollChild(content)
    
    local entries = ParseChangelog(CHANGELOG_TEXT)
    local entryFrames = {}
    local previousFrame = nil
    
    for i, entryData in ipairs(entries) do
        local entryFrame = CreateFrame("Frame", nil, content)
        entryFrame:SetWidth(530)
        
        if previousFrame then
            entryFrame:SetPoint("TOPLEFT", previousFrame, "BOTTOMLEFT", 0, -5)
        else
            entryFrame:SetPoint("TOPLEFT", 0, -5)
        end
        
        -- Header
        local header = CreateFrame("Button", nil, entryFrame)
        header:SetSize(530, 20)
        header:SetPoint("TOPLEFT")
        
        -- Icon
        local icon = header:CreateTexture(nil, "ARTWORK")
        icon:SetSize(16, 16)
        icon:SetPoint("LEFT", 5, 0)
        icon:SetTexture("Interface\\AddOns\\BetterFriendlist\\Icons\\chevron-right.blp")
        
        -- Title
        local title = header:CreateFontString(nil, "OVERLAY", "BetterFriendlistFontNormal")
        title:SetPoint("LEFT", icon, "RIGHT", 5, 0)
        title:SetText(string.format(L.CHANGELOG_HEADER_VERSION, entryData.version))

        -- Date
        local dateLabel = header:CreateFontString(nil, "OVERLAY", "BetterFriendlistFontNormal")
        dateLabel:SetWidth(85) -- Fixed width for alignment (fits YYYY-MM-DD)
        dateLabel:SetJustifyH("LEFT") -- Left align for clean column start
        dateLabel:SetPoint("RIGHT", header, "RIGHT", -5, 0)
        dateLabel:SetText(entryData.date)
        
        -- Content
        local entryContent = CreateFrame("Frame", nil, entryFrame)
        entryContent:SetWidth(530)
        entryContent:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -5)
        
        local currentY = -5
        for _, block in ipairs(entryData.blocks) do
            if block.type == "h1" then
                local fs = entryContent:CreateFontString(nil, "OVERLAY", "BetterFriendlistFontLarge")
                fs:SetPoint("TOPLEFT", 10, currentY)
                fs:SetWidth(510)
                fs:SetJustifyH("LEFT")
                fs:SetText(block.content)
                currentY = currentY - fs:GetStringHeight() - 10
            elseif block.type == "h3" then
                local fs = entryContent:CreateFontString(nil, "OVERLAY", "BetterFriendlistFontNormal")
                fs:SetPoint("TOPLEFT", 10, currentY)
                fs:SetWidth(510)
                fs:SetJustifyH("LEFT")
                fs:SetText(block.content)
                fs:SetTextColor(1, 0.82, 0) -- Gold
                currentY = currentY - fs:GetStringHeight() - 5
            elseif block.type == "h4" then
                local fs = entryContent:CreateFontString(nil, "OVERLAY", "BetterFriendlistFontNormal")
                fs:SetPoint("TOPLEFT", 10, currentY)
                fs:SetWidth(510)
                fs:SetJustifyH("LEFT")
                fs:SetText(block.content)
                fs:SetTextColor(0.8, 0.8, 0.8) -- Light Gray
                currentY = currentY - fs:GetStringHeight() - 5
            elseif block.type == "separator" then
                local tex = entryContent:CreateTexture(nil, "ARTWORK")
                tex:SetTexture("Interface\\Common\\UI-TooltipDivider-Transparent")
                tex:SetPoint("TOPLEFT", 10, currentY)
                tex:SetSize(510, 8)
                currentY = currentY - 15
            elseif block.type == "list_item" then
                -- Bullet
                local bullet = entryContent:CreateFontString(nil, "OVERLAY", "BetterFriendlistFontHighlight")
                bullet:SetPoint("TOPLEFT", 15, currentY)
                bullet:SetText("•")
                
                -- Text
                local fs = entryContent:CreateFontString(nil, "OVERLAY", "BetterFriendlistFontHighlight")
                fs:SetPoint("TOPLEFT", 30, currentY)
                fs:SetWidth(490)
                fs:SetJustifyH("LEFT")
                fs:SetText(block.content)
                
                currentY = currentY - math.max(fs:GetStringHeight(), bullet:GetStringHeight()) - 5
            else -- text
                local fs = entryContent:CreateFontString(nil, "OVERLAY", "BetterFriendlistFontHighlight")
                fs:SetPoint("TOPLEFT", 10, currentY)
                fs:SetWidth(510)
                fs:SetJustifyH("LEFT")
                fs:SetText(block.content)
                currentY = currentY - fs:GetStringHeight() - 5
            end
        end
        
        local contentHeight = math.abs(currentY)
        entryContent:SetHeight(contentHeight)
        
        -- Toggle Logic
        local isExpanded = (i == 1)
        
        local function UpdateState()
            if isExpanded then
                entryContent:Show()
                entryFrame:SetHeight(20 + 5 + contentHeight)
                icon:SetTexture("Interface\\AddOns\\BetterFriendlist\\Icons\\chevron-down.blp")
            else
                entryContent:Hide()
                entryFrame:SetHeight(20)
                icon:SetTexture("Interface\\AddOns\\BetterFriendlist\\Icons\\chevron-right.blp")
            end
        end
        
        header:SetScript("OnClick", function()
            isExpanded = not isExpanded
            UpdateState()
            RecalculateHeight(content, entryFrames)
        end)
        
        UpdateState()
        
        table.insert(entryFrames, entryFrame)
        previousFrame = entryFrame
    end
    
    RecalculateHeight(content, entryFrames)
    
    changelogFrame = frame
    frame:Hide()
end
