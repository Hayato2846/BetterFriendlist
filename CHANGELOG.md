# Changelog

All notable changes to BetterFriendlist will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

## [2.6.8]        - 2026-07-14

### Improved
- **Translations** - Many translations across all supported languages have been updated, corrected, and expanded.
- **Classic Anniversary** - BetterFriendlist now loads normally with the Classic Anniversary 2.5.6 client update.

### Fixed
- **Friend Search** - Search now checks a friend's displayed WoW contact name plus every visible character and realm linked to their Battle.net account.
- **Multi-Account Filters** - The WoW, WoW Online, Retail, and In Game filters, along with matching custom rules, now check every visible game account instead of only the focused one.
- **Mobile-Only Status** - Treat Mobile as Offline now only marks friends offline when the Battle.net mobile app is their only active session. They stay online while playing another Blizzard game.
- **Friend List Refreshes** - Rapid friend-status changes no longer cause duplicate refreshes, and BetterFriendlist keeps the last complete list visible while Battle.net data is still loading.

---

## [2.6.7]        - 2026-07-12

### Added
- **WoW Contact Custom Names (Retail 12.1)** - Once Blizzard enables the new WoW-only Battle.net contacts and their custom names, BetterFriendlist displays those names in the friends list and Broker tooltip. They can also be edited from the right-click menu.
- **Appear Offline (Retail 12.1)** - Once Blizzard enables the new Battle.net presence option, BetterFriendlist's existing status menu includes Appear Offline alongside Online, Away, and Busy.

### Improved
- **Retail 12.1 Compatibility** - BetterFriendlist now adapts when Blizzard enables the new friends system or disables older character-friend features. Friend counts, notes, adding or removing friends, and related friend actions continue to work through the transition.
- **Retail 12.1 Social Updates** - Once Blizzard enables the new social features, changes to your Battle.net status, WoW contact names, and available friend functions are reflected in BetterFriendlist immediately.
- **Localization** - Completed and corrected all supported locale files, including recently added settings and social features, while removing stale keys, duplicate assignments, English fallback text, and encoding damage.

### Fixed
- **Static Friend Groups** - Assigning a friend to a custom group now removes them from "No Group" as expected. Dropping a friend onto "No Group" removes their custom-group assignments cleanly.

---

## [2.6.6]        - 2026-06-30

### Fixed
- **Raid Tab Menus** - Right-clicking raid members on Retail should open the normal Blizzard menu again, including options like Set Focus.
- **Auto Raid Assist** - Your chosen assistants are picked up more reliably after raid changes, zoning, difficulty changes, or when WoW is slow to finish loading the roster.
- **Auto Raid Assist** - If you take assistant away from someone yourself, they stay that way until they leave the raid.
- **Classic Login** - Classic Era and Season of Discovery should no longer show a protected action warning when you log in with BetterFriendlist enabled.

---

## [2.6.5]        - 2026-06-28

### Added
- **NSRT Compatibility** - You can now dock Northern Sky Raid Tools' Missing Raid Buffs panel into the BetterFriendlist Raid tab. This currently requires an NSRT alpha version.
- **Theme Customization** - Dark and Custom themes are no longer beta and now work on Retail and Classic. Find them in the old settings under Settings > Theme, or in the Settings Center under Appearance > Theme. ElvUI users can pick the ElvUI skin from that same Theme page.

### Fixed
- **Classic Themes** - The Friends window should look cleaner in Dark and Custom themes now: search box, bottom tabs, selected tab highlight, scroll buttons, WHO headers, and Raid role icons line up better.
- **Classic Simple Mode** - The missing top-left Blizzard frame corner is back when the avatar is hidden in Blizzard theme.
- **Quick Join** - Retail group tooltips now show better member info when available, including classes, roles, and leader markers.

### Improved
- **Classic Dropdowns** - Friends header, WHO, settings, and builder dropdowns now have cleaner icon placement and more reliable click areas in Dark/Custom themes and ElvUI.
- **Classic Simple Mode** - Turning Simple Mode on or off updates the frame right away, no reload needed.
- **Classic UI** - More Classic menus use the newer menu style where the client supports it, and shared icon art is safer on Classic.

---

---

*Older versions archived. Full history available in git.*
