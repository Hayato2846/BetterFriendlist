# Changelog

All notable changes to BetterFriendlist will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [DRAFT]

### Added
- **QuickFilter & Sorter Builder** - Added a beta-gated settings tab for controlling visible QuickFilters and Sorters, creating custom filter rules and sorter chains, and choosing BFL or Blizzard icons.
- **Theme Settings** - Added a Theme settings section with Blizzard, Dark, and ElvUI theme choices.
- **Dark Theme** - Added a BFL-owned dark skinning engine covering BetterFriendlist windows, rows, dialogs, and broker tooltips.
- **Font Rendering** - Added per-font rendering flag settings and enabled Slug rendering across BetterFriendlist UI text on compatible clients.
- **WoW Online Filter** - Added a quick filter for showing only online friends who are currently in WoW.

### Changed
- **QuickFilter & Sorter Builder** - Creation and editing now happen in a docked editor panel, rule fields use dropdowns, and Preview temporarily applies the selected filter or sorter to the friends list.
- **Filter/Sort Registry** - QuickFilter menus, sort dropdowns, and Broker cycling now read from a shared registry; hidden active selections fall back to Filter `all`, Primary Sort `game`, and Secondary Sort `status`.
- **ElvUI Skin Setting** - Moved the ElvUI skin option from General to Theme and migrated existing profiles automatically.
- **Theme Settings** - Theme choices are now beta-gated and automatically switch back to Blizzard when Beta Features are disabled.
- **Dark Theme Visuals** - Refined the Dark theme with translucent black Aurora-style surfaces, clearer control hairlines, Material-like navigation states, and cleaner list dividers.

### Fixed
- **QuickFilter & Sorter Builder** - Updated the docked editor to use the same modern frame styling as the Settings and Raid Help windows.
- **QuickFilter & Sorter Builder** - Cleaned up the docked editor layout so preview, metadata, filter rules, and sorter steps no longer overlap.
- **QuickFilter & Sorter Builder** - Added the missing delete action for nested filter groups.
- **Retail Unit Menus** - Avoided adding BetterFriendlist group options to protected Blizzard unit menus.
- **Total RP 3 Compatibility** - Restored the Total RP 3 profile action in BetterFriendlist friend context menus without using Blizzard menu callbacks.
- **Raid Drag Tooltips** - Fixed a Lua error that could occur after moving players between raid groups with drag and drop.
- **Dark Theme Coverage** - Improved Dark theme coverage for frame borders, tabs, scroll bars, dropdown menus, sliders, close buttons, and standard Blizzard button templates that could still show Blizzard styling.
- **Dark Theme Controls** - Replaced text-based close and dropdown indicators with BFL icons and removed extra borders from header icon buttons.
- **Dark Theme Tabs** - Centered tab labels, matched bottom-tab opacity to the main frame, and added accent borders for selected top and bottom tabs.
- **Dark Theme Main List** - Widened and aligned the main scrollbar, lined up the footer buttons with the list edges, removed the duplicate outer list frame, and made disabled buttons visually distinct without dimming selected tabs.
- **Dark Theme Performance** - Reduced Friendlist rerender work and stopped row skinning from interfering with configured group header colors.
- **Dark Theme Frame Chrome** - Prevented Blizzard ButtonFrame portrait/corner artwork from reappearing over the Dark theme after portrait visibility updates.
- **Dark Theme Polish** - Aligned header and title icon buttons, changed borderless button hover to icon-only glow, and tightened the main scrollbar alignment and stepper state layout.
- **Dark Theme Scrolling** - Fixed scrollbar stepper icon alignment and initial visibility, removed group header highlighting, improved scrollbar thumb highlighting while dragging, and unified Dark theme scrollbar styling across BFL windows.
- **Theme Isolation** - Prevented Dark theme skin state from leaking into the Blizzard theme after switching themes, including top/bottom tab layout, selected tab text, icon coloring, checkboxes, edit boxes, and scrollbar thumbs.
- **Dark Theme Texture Buttons** - Preserved native invite and RAF reward textures while cleaning up Dark theme borders, RAF list separators, and tooltip behavior.
- **Dark Theme Overlay Buttons** - Prevented invisible Friends row game-account overlays from receiving visible button chrome.
- **Dark Theme Tab Lists** - Applied the Friends tab list chrome rules to Recent Allies and Recruit A Friend so list insets and scrollbars align consistently.
- **Dark Theme Who Tab** - Fitted WHO column headers inside the list inset, aligned them as table columns, extended the scrollbar through the header gutter, and kept search utility buttons borderless.
- **Dark Theme Search Builder and Raid Tab** - Removed redundant inner frames, aligned Search Builder dropdowns with inputs, cleaned up raid controls, and stopped the builder from capturing unrelated keys.
- **Dark Theme Raid Tab** - Aligned and cleaned up the Assist All checkbox styling.
- **Dark Theme Quick Join Tab** - Removed the extra outer inset frame, added breathing room below the title buttons, and aligned the scrollbar and request button with the Contacts tab layout.
- **Dark Theme Raid Help** - Cleaned up Raid Roster Help inset chrome and aligned its scrollbar with other tab lists.
- **Dark Theme Settings** - Fixed settings scrollbar stepper icons after tab switches and aligned Font Settings dropdowns, sliders, and color controls.
- **Dark Theme Advanced Dialogs** - Skinned the FriendGroups migration dialog, Note Cleanup Wizard, and Note Backup Viewer consistently with the Dark theme.
- **Theme Settings** - Fixed an error when disabling Beta Features from the settings window.
- **Recruit A Friend Rewards** - Prevented viewing rewards from breaking reward tabs or causing a protected Copy Link error in the recruitment dialog.

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
