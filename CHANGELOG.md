# Changelog

All notable changes to BetterFriendlist will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [DRAFT]

### Added
- **Theme Settings** - Added a Theme settings section with Blizzard, Dark, and ElvUI theme choices.
- **Dark Theme** - Added a BFL-owned dark skinning engine covering BetterFriendlist windows, rows, dialogs, and broker tooltips.

### Changed
- **ElvUI Skin Setting** - Moved the ElvUI skin option from General to Theme and migrated existing profiles automatically.
- **Dark Theme Visuals** - Refined the Dark theme with translucent black Aurora-style surfaces, clearer control hairlines, Material-like navigation states, and cleaner list dividers.

### Fixed
- **ElvUI Top Tabs** - Centered the Friends, Recent Allies, and Recruit A Friend tab labels in the ElvUI skin.
- **Dark Theme Coverage** - Improved Dark theme coverage for frame borders, tabs, scroll bars, dropdown menus, sliders, close buttons, and standard Blizzard button templates that could still show Blizzard styling.
- **Dark Theme Controls** - Replaced text-based close and dropdown indicators with BFL icons, removed extra borders from header icon buttons, and preserved TravelPass invite textures.
- **Dark Theme Tabs** - Centered tab labels, matched bottom-tab opacity to the main frame, and added accent borders for selected top and bottom tabs.
- **Dark Theme Main List** - Widened and aligned the main scrollbar, lined up the footer buttons with the list edges, and made disabled buttons visually distinct without dimming selected tabs.
- **Dark Theme Performance** - Reduced Friendlist rerender work and stopped row skinning from interfering with configured group header colors.
- **Dark Theme Frame Chrome** - Prevented Blizzard ButtonFrame portrait/corner artwork from reappearing over the Dark theme after portrait visibility updates.
- **Dark Theme Polish** - Aligned header and title icon buttons, changed borderless button hover to icon-only glow, and tightened the main scrollbar alignment and stepper state layout.

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
