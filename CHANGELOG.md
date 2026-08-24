# Changelog

All notable changes to BetterFriendlist will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [2.8.7]        - 2026-08-24

### Fixed
- **Large Friend Lists** - BetterFriendlist has received further optimizations for larger friend lists and is now less likely to run into errors when loading them.

---

## [2.8.6]        - 2026-08-24

### Improved
- **Background Performance** - BetterFriendlist now avoids more work while the Friendlist, guild list, raid tools, and Broker tooltips are closed.
- **Large Friend Lists** - Friend and tag updates are now smoother, especially for players with many Battle.net friends.
- **Taint-Free Whisper** - On Retail, the optional whisper box now opens where you normally type chat messages.
- **Ready Check** - Party leaders can now start a Ready Check from the Raid tab without converting the group to a raid.

### Fixed
- **Guild Message of the Day** - Fixed a Retail chat error that could occur when the guild message of the day was displayed.
- **Raid Tab** - Long raid information now stays inside the window, and the Legacy controls no longer overlap.
- **Interface Switching** - Raid Roster Help and Streamer Mode now reappear immediately after switching from Modern to Legacy.
- **Modern Ready Check** - Removed a small visual artifact from the Ready Check button.

---

## [2.8.5]        - 2026-08-22

### Added
- **Friend Tag Actions** - Friend right-click menus can now select or clear all built-in and custom tags at once.
- **Icon-Only Tags** - Tags that only show an icon can optionally keep their colored chip background.
- **Dynamic Tag Groups** - A new option hides all tag chips inside dynamic tag groups. The existing option to hide only the group's own tag remains available.

### Improved
- **Friend Tag Layout** - Friend rows can now show up to 20 tags and use the available row width before wrapping.
- **Friend Tag Settings** - The visibility options now explain where each tag is shown: friend rows, tooltips, or Data Broker.

### Fixed
- **Friend Tag Editor** - Reordering, resetting, or deleting tags now updates friend rows immediately. After deleting a tag, another valid tag stays selected.
- **Friend Tag Names** - Custom tags can no longer use the name of a built-in tag.
- **Compact Friend Rows** - Status, game, and Invite icons now stay aligned when rows have different heights. Status markers remain readable and Invite artwork stays inside its button.
- **Icon-Only Tags** - Icons now stay centered inside colored chips, including the default Tank, Healer, and DPS icons.
- **Battle.net Levels** - Invalid level 0 values from Battle.net are no longer shown as a real character level. Available zone or game information is shown instead.
- **Custom Names** - Friends with digits in their BattleTag no longer trigger repeated rename messages after logging in or reloading the UI.

---

## [2.8.4]        - 2026-08-22

### Improved
- **Raid Tab** - When you are not in a raid, the Raid tab now shows Blizzard's helpful explanation instead of a short placeholder.
- **Recruit A Friend** - The recruit list now adjusts correctly after changing the game's text size, even if the tab was closed at the time.

### Fixed
- **Friend Requests** - Accepting or declining a Battle.net friend request no longer causes the game to freeze.
- **ElvUI BattleTag** - Your BattleTag now stays visible and keeps the same colors when switching between Legacy and Modern or using the copy button.
- **Changelog Notice** - The “NEW” glow around the BFL avatar now follows round and square avatar styles in every theme.
- **ElvUI Simple Mode** - The avatar now stays hidden when switching between Legacy and Modern while Simple Mode is active.
- **ElvUI Guild Tab** - The Legacy guild member list now uses a background that matches the ElvUI theme.
- **Modern Raid Tab** - Raid member right-click menus, shortcuts, selections, and drag-and-drop now stay connected to the correct player.

---

## [2.8.3]        - 2026-08-18

### Added
- **Friend Tag Layout** - Choose how many tags can appear in total and on each line. Tags can also use separate full-width lines. When friends are grouped by a tag, that tag can be hidden from their rows.
- **Tag Appearance** - Pick the font, size, style, and icon size used by friend tags. Each tag can also have its own text color to match its background.

### Improved
- **Friend Tag Editor** - Typing a label now switches to Custom Label automatically. Pressing Enter or Escape finishes text entry, and icon or label changes show up right away.
- **Cleaner Settings** - Options that only work with Modern or Legacy are now shown when that interface is active, while shared options remain available in both.

### Fixed
- **Tag Icons and Labels** - Icon Only now works on the first click. Custom icon paths stay selected, switching between icon types no longer brings back an older icon, and reordering tags keeps their chosen icon zoom.
- **Tag Rows** - Tag lines wrap more reliably with the chosen limits and sizes. Full-width tag rows no longer overlap the game icon or Invite button.
- **Legacy Settings** - Sliders update the friend list without rebuilding the page while dragging. Dropdown widths, menu-count alignment, scrollbars, and right-click color resets have also been tidied up.
- **Friend Search** - Clearing the search box once again restores its hint text and hides the clear button on Retail and Classic.
- **Favorite Icons** - BFL and Blizzard favorite icons now leave a more even gap between the character name and the following friend info.

---

## [2.8.2]        - 2026-08-15

### Fixed
- **EllesmereUI Theme** - Faction-colored friend backgrounds in the Modern interface are now softer and easier to read.

---

## [2.8.1]        - 2026-08-14

### Fixed
- **Raid Info** - The Raid Info button is visible again in Dark and Custom themes, and its window now opens at the correct distance in both Modern and Legacy layouts.
- **Compact Mode** - Friend cards once again fit their visible content without leaving unnecessary empty space.

---

## [2.8.0]        - 2026-08-12

BetterFriendlist 2.8.0 is one of the biggest updates the addon has received so far. With a change this broad, a few rough edges or bugs may still show up. We will keep polishing and adjusting the new experience over the next few days. Feedback on GitHub or CurseForge is always welcome.

### Added
- **New Modern UI** - Retail players can now use a completely new Friendlist built for Blizzard's 12.1 social experience. It keeps BetterFriendlist's groups and social tools while adding side navigation, cleaner friend cards, a dedicated Friend Requests view, and tailored layouts for Friends, Recent Allies, Quick Join, Recruit a Friend, Raid, Guild, and Who.
- **EllesmereUI Theme** - BetterFriendlist now offers an EllesmereUI theme for both Legacy and Modern. It uses EUI's own skinning API and follows live accent and appearance changes whenever EllesmereUI skinning is available and enabled.
- **Friend Tag System** - BetterFriendlist's friend tags now work alongside Blizzard's native tags and extend them with custom tags, colors, icons, row chips, search, filters, and a dedicated editor. Blizzard tags remain usable even when custom BFL tags are turned off.
- **Interface Style Setting** - Retail 12.1 uses Modern by default and can switch between Modern and Legacy without reloading. Classic continues to use Legacy.
- **Friend Tab Settings for Modern UI** - Modern users can reorder every side tab, hide individual tabs, and optionally show Friend Requests or Quick Join only while they contain entries. Hidden tabs close up cleanly without leaving gaps.
- **Onboarding System** - A new step-by-step setup helps Retail users choose Modern or Legacy, preview every available theme, and configure Simple and Compact Mode before starting. The choices remain available in Settings at any time.
- **Filter Menus with Native Tag Support** - Friend filters now use shared Filters and Tags submenus in Modern, Legacy, and Simple Mode. Blizzard tags and custom BFL tags can be selected directly, while active filters and tag choices stay visible and update immediately.
- **Updated Themes for the New Modern UI** - Dark, Custom, and ElvUI have all been adapted to the new Modern interface, including its frame surfaces, navigation, friend cards, controls, headers, and actions.

### Improved
- **Modern UI Availability** - Retail now uses BetterFriendlist's Modern UI whenever the client provides the 12.1 SocialUI API, even while Blizzard temporarily disables its own new Friendlist frame. BetterFriendlist remains the entry point for every Social UI route in both Modern and Legacy, including Broadcast, Ignore List, and Raid Info windows.
- **Recent Allies Availability** - BetterFriendlist now reacts immediately to `RECENT_ALLIES_SYSTEM_STATUS_UPDATED`, refreshing Modern navigation, Legacy tabs, and visible Recent Allies content when Blizzard changes the feature state.
- **Recent Allies Groups** - Converted Legacy friends, pinned allies, and other recent allies now appear in separate groups in the same order as Blizzard's 12.1 Social UI.
- **Queue Filters** - Retail's friend filters now include In Queue and Available for Queue when Blizzard's native Battle.net search is available. Restricted or unavailable search results safely leave the list usable.
- **Classic Era 1.15.9 Compatibility** - BetterFriendlist and its Menu Bridge now declare support for the latest Classic Era client.
- **Retail 12.1 Social Actions** - Recent Allies sends WoW title-friend invitations through Blizzard's confirmation dialog, offline WoW-only Title friends no longer expose an unreachable Whisper action, and Quick Join toasts select and scroll to the matching BetterFriendlist group.
- **Adaptive Friend Rows** - Friend cards now stack their visible name, info, multi-account, and tag lines from a three-pixel top inset and calculate their height from the content that is actually shown. Long names wrap across as many lines as needed, including names without spaces, instead of being truncated. Rows grow beyond the old fixed Modern sizes and retired height cap when configured fonts or extra lines need more room.
- **WHO Rows** - Alternating row backgrounds now have an adjustable strength control in both settings interfaces.

### Fixed
- **Modern Avatar Interaction** - The visible BFL avatar now owns its changelog click and tooltip area in every Modern theme, including ElvUI and EllesmereUI, instead of relying on a differently positioned invisible Legacy button.
- **Recruit a Friend Layout** - Long recruit lists now stop above the Modern Recruitment button, and the Blizzard theme once again shows the button's complete native artwork.
- **Social Side Windows** - Recruit a Friend reward tabs now remain interactive in forced Modern mode, the rewards and Broadcast windows dock beside BetterFriendlist, and the Ignore List is skinned consistently by Dark, Custom, ElvUI, and EllesmereUI.
- **Social UI Scaling and Dialogs** - Modern friend requests and Recruit a Friend layouts rebuild after Blizzard text-scale changes, while the Friends of Friends window now docks beside BetterFriendlist and follows the active theme.
- **Event Compatibility** - Client-specific or removed events no longer stop addon initialization when Blizzard changes the event registry between game flavors or builds.
- **Drag and Hover Handling** - Reordering groups, filters, sorters, and broker columns no longer calls the removed global mouse-over helper. Friend-group drops and themed hover states use the cross-flavor Region API as well.
- **Friends Frame** - The title now uses the correct centered bounds when Simple Mode hides the portrait, and legacy filter/sort dropdowns stay hidden while the Modern UI is active.
- **Theme Settings** - Theme sliders no longer reskin the full interface for every drag increment, and resetting a theme updates the visible controls immediately.
- **Frame Scale** - Changing the scale in Settings Center now applies it immediately.
- **Tooltips** - BetterFriendlist friend tooltips now use `TOOLTIP` strata with a deliberate frame-level lead, keeping them above Modern cards, tabs, and other SocialUI child frames.
- **WHO Double-Click** - WHO actions now expose only the supported Whisper and Invite options; stale unsupported Inspect selections fall back safely to Whisper.

---

## [2.7.0]        - 2026-07-29

### Fixed
- **Legacy Font Dropdowns** - Font lists in the legacy settings now stay on-screen and scroll through all available fonts. Dark and Custom themes no longer show an overlapping second dropdown.

---

## [2.6.9]        - 2026-07-22

### Fixed
- **Who Searches** - Broad Who searches no longer leave an invisible Blizzard window that blocks Escape and disrupts other window positions.

---

---

*Older versions archived. Full history available in git.*
