# Changelog

All notable changes to BetterFriendlist will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [DRAFT]

### Improved
- **Broker Tooltips** - Added the subtle broker separator between Friends Broker groups and Guild Broker rank groups.

## [2.6.0]        - 2026-05-25

### Added
- **QuickFilter & Sorter Builder** - Added a dedicated settings tab for choosing visible QuickFilters and Sorters, building custom filter rules and sorter chains, previewing changes, and choosing BFL or Blizzard icons. Enable Beta Features under Advanced > Beta Features to show the tab.
- **Theme Settings and Dark Theme** - Added a dedicated Retail Theme tab with Blizzard, Dark, and ElvUI choices, plus a BFL-owned Dark theme for BetterFriendlist windows, rows, dialogs, settings, and broker tooltips. Enable Beta Features under Advanced > Beta Features to show the tab. Classic support will follow as soon as possible in one of the next releases.
- **Font Rendering** - Added per-font rendering flag settings and Slug rendering support on compatible clients.
- **WoW Online Filter** - Added a quick filter for showing only online friends who are currently in WoW.

### Changed
- **QuickFilter and Sorter Menus** - QuickFilter menus, sort dropdowns, and Broker cycling now respect custom visibility and order, with safe fallbacks for hidden active selections.
- **Theme Safety** - Theme choices now fall back safely when Beta Features are disabled, on non-Retail clients, or when ElvUI is unavailable.

### Fixed
- **ElvUI Skin** - Fixed startup, availability, and settings-toggle issues when ElvUI was selected, unavailable, or managed outside the Retail beta Theme tab.
- **Menu Compatibility** - Fixed protected Retail unit menu handling and restored Total RP 3 profile actions in BetterFriendlist friend menus.
- **Raid Tools** - Fixed a Lua error after moving players between raid groups with drag and drop.
- **Recruit A Friend** - Fixed reward-viewing tab issues, protected Copy Link errors, and a tooltip stack overflow.

### Performance
- **Friend List Sorting** - Reduced CPU time and memory churn when changing QuickFilters and Sorter selections.
- **Quick Join** - Reduced repeated group-priority and friend-relationship lookups while sorting available groups.

### Outlook
- **Custom Theme & Theme Settings** - A future Custom theme will inherit from the Dark theme and add full controls for colors, transparency, and related visual details. Dark theme settings will also expand in upcoming releases.
- **Guild Tab** - A Retail and Classic Guild tab is planned for upcoming releases, with a BetterFriendlist-owned roster view for searching guild members, filtering online/offline members, sorting by rank, name, level, class, zone, status, and last online time, and showing guild counts, notes, status, and class information through the shared safe roster provider.

## [2.5.9]        - 2026-05-17

### Fixed
- **ElvUI Top Tabs** - Centered the Friends, Recent Allies, and Recruit A Friend tab labels in the ElvUI skin.

## [2.5.8]        - 2026-05-16

### Added
- **Broker Tooltip Fonts** - Added an optional setting for using selected broker tooltip fonts on non-latin alphabets, with a warning about unsupported glyphs.
- **Guild Broker MOTD** - Added the guild message of the day to the Guild Broker tooltip with guarded cross-version handling.

### Fixed
- **Guild Broker Click Action** - Fixed the configured left-click action not opening the guild frame or broker settings.
- **Recruit A Friend Taint** - Reduced RAF list taint by keeping addon display data separate from Blizzard recruit records.

## [2.5.7]        - 2026-05-16

### Fixed
- **Classic Loading** - Fixed a load error after the latest update.

### Changed
- **Client Compatibility** - Added TOC support for newer Retail and Classic client builds.

## [2.5.6]        - 2026-05-15

### Added
- **Advanced: Taint-Free Whisper** - Added an optional inline whisper bar under Advanced that lets you message friends without opening Blizzard chat.
- **Friend List Whisper Click** - Added an optional Behavior setting to start whispers from friend rows with a double left-click or single left-click.
- **Broker Tooltip Fonts** - Added global font and font size settings for Friends and Guild broker tooltips.
- **Friends Broker: Filter-Aware Display** - Broker text and tooltip counts now follow the active quick filter, including Online, All, WoW only, and In A Game.
- **Friends Broker: Columns** - Added optional Nickname and Status columns, class icons in the Character column, and configurable group name alignment.
- **Broker Hover Details** - Friend and guild broker rows now show overlay detail tooltips on hover.
- **Friends Broker: Styling** - Added per-column colors, main-list name color syncing, ElvUI tooltip styling, Blizzard client icons, rich presence/mobile/app labels, and a toggle for footer hints.
- **Guild Broker Plugin** - Added an optional Data Broker plugin for guild rosters with online/all filtering, collapsible rank/class groups, configurable columns, member actions, rank management, and all-version support. Enable it in Settings > Broker > Guild Plugin.
- **Guild Broker: Roster Options** - Added nickname, professions, class icon, applicant count, hide-max-level, and exclude-yourself options, with drag-and-drop column ordering.
- **Guild Broker: Sorting and Status** - Added sort modes for name, rank, level, class, zone, and nickname plus AFK/DND status indicators.
- **Guild Broker: Colors** - Added custom nickname colors and configurable Rank, Zone, Note, and Officer Note colors.
- **Guild Broker: Compatibility** - Added support for Retail secret-value clients, migration-friendly saved column layouts, clean member tooltip cleanup, and streamlined profession rank display.

### Improved
- **Broker Refreshing** - Data Broker plugins now refresh reliably after Battle.net and friend roster updates, including when Beta Features are disabled.
- **Broker Display Compatibility** - Improved tooltip cleanup for broker display addons such as Arcana and Bazooka.
- **Secret-Value Context Menus** - Modern clients now use BetterFriendlist-owned friend menus for Friend, Battle.net Friend, and Recent Ally actions instead of patching protected Blizzard menus.
- **Friend Tooltips** - Battle.net friend hover tooltips now use sanitized data on secret-value clients and class colors when class-colored names are enabled.
- **Social Keybind** - The Social key now opens BetterFriendlist directly and migrates or restores cleanly without reload prompts or Guild/Communities taint.
- **Quick Join** - Group Finder listings opened from Quick Join now use Blizzard's native sign-up dialog.
- **Combat Window Toggle** - Opening and closing BetterFriendlist during combat is more reliable when Respect UI Hierarchy is enabled.

### Fixed
- **Blizzard Friends Frame Replacement** - Blizzard and addon calls that open the default Friends frame now route to BetterFriendlist more consistently, preventing both windows from opening or closing out of sync.
- **Escape Key Handling** - Pressing Escape now closes BetterFriendlist more reliably, including when the frame is opened outside the normal UI panel path.
- **Taint-Free Whisper Focus** - Closing the inline whisper bar with Escape no longer blocks normal keybinds while BetterFriendlist stays open.
- **Broker Hover Details** - Friend and guild broker detail tooltips now stay above the main broker tooltip and no longer trigger QTip release errors while closing.
- **Tab Navigation** - Fixed the window getting stuck on the Who or Quick Join tab after using /who or clicking a group join link.
- **Broker Counts** - Fixed stale, zero, total-friend, and filtered-count display problems across Friends broker quick filters.
- **Broker Group Headers** - Collapse and expand markers now render as `+` and `-` without extra parentheses.
- **Retail Chat Taint** - Reduced chat history taint by using secret-safe friend menu extension handling on modern clients.
- **Guild and Communities Taint** - On secret-value clients, BetterFriendlist now avoids Guild/Communities roster hooks and native guild menu extensions while Blizzard's Guild panel opens.
- **Recruit A Friend Taint** - Reduced RAF list taint noise on secret-value clients by keeping raw Battle.net account payloads out of RAF list rows.
- **Quick Join Messages** - Whisper links and Send Message actions from Quick Join now open the correct Battle.net conversation more reliably.

## [2.5.5]        - 2026-04-05

### Fixed
- **Retail: Quick Join** - Fixed a Lua error caused by protected values during combat restrictions.

## [2.5.4]        - 2026-04-03

### Fixed
- **Classic: Sort Dropdown** - Fixed an error when selecting a sort option (e.g., "Game") in Classic clients.

### Improved
- **Quick Join: Known Players** - Quick Join entries now also show guild members and community members next to the group leader, not just friends. Community members additionally display the community name they belong to.

## [2.5.3]        - 2026-04-02

### Added
- **Name Format: BattleTag Only** - New preset that shows only the BattleTag without the character name.

### Improved
- **Performance** - Faster sorting, group toggling, and list updates across Friends List, Quick Join, Raid Frame, and WHO tab. Reduced memory usage overall.
- **Tooltip: External Addon Support** - Friend tooltips now work with RaiderIO and ArchonTooltip (Warcraft Logs).

### Fixed
- **Friends List: Zone Display** - Fixed zone names with hyphens (e.g., French "Silvermoon City") being split incorrectly.
- **Retail: Secret Values** - Fixed crashes when encountering protected values in tooltips, display names, Quick Join, and debug commands.
- **Retail: Chat & Whisper Taint** - Fixed mass taint errors when receiving chat messages or whispering in popout mode.
- **Raid Frame: Combat Restriction** - Raid actions (Convert, Assist, Promote) now block properly during combat instead of showing a cryptic error. Buttons are visually disabled in combat.

## [2.5.2]       - 2026-03-24

### Fixed
- **Housing: Combat Restriction** - The "View Houses" context menu entry now shows a clear error message during combat instead of the cryptic "Interface action failed because of an AddOn" error. Visit House buttons in the house list show a gray overlay with a tooltip when combat starts while the list is already open.

---

*Older versions archived. Full history available in git.*
