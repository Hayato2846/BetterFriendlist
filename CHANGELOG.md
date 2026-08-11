# Changelog

All notable changes to BetterFriendlist will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [DRAFT]

### Added
- **EllesmereUI Theme** - Added conditional EllesmereUI styling for Retail Legacy and Modern interface styles through EUI's public skinning API, including live accent and appearance updates when EllesmereUI skinning is enabled.
- **Retail 12.1 Friendlist UI** - Added a new Retail interface based on Blizzard's 12.1 SocialUI, including vertical section tabs, modern friend cards and group headers, a Battle.net bar, compact search/filter/sort controls, and a dedicated Friend Requests view.
- **Interface Style Setting** - Retail can switch between Modern and Legacy without reloading. Modern is the Retail default when Blizzard's SocialUI is enabled; Classic and unsupported Retail states continue to use Legacy.
- **Friend Tab Settings** - Modern Retail users can reorder every side tab, hide individual tabs, and optionally show Friend Requests or Quick Join only while they contain entries. Hidden tabs are removed from the layout without leaving gaps.

### Improved
- **EllesmereUI Visual Parity** - The friendlist now uses EUI's translucent shell, pure accent-colored BFL icons, matched custom side-tab states, aligned header branding, EUI-styled Guild and Who search/dropdown controls, and matching RAF, Raid, Who, and footer actions, while preserving Blizzard's side-tab chrome, group headers, invite buttons, font geometry, and transparent Battle.net bar.
- **Social Entry Points** - Retail SocialUI toggles and tab-opening calls now route to matching BetterFriendlist sections, while the menu option for Blizzard's friendlist opens Blizzard's original SocialUI.
- **Retail 12.1 Contact Views** - Friends, Recent Allies, Friend Requests, Quick Join, Guild, and Who now use section-specific Modern search, filter, divider, list, and action-bar layouts. Recent Allies supports Blizzard's new status and interest filters with an older-client fallback.
- **Retail 12.1 Social Actions** - Recent Allies sends WoW title-friend invitations through Blizzard's confirmation dialog, offline WoW-only Title friends no longer expose an unreachable Whisper action, and Quick Join toasts select and scroll to the matching BetterFriendlist group.
- **Retail 12.1 Parity** - Quick Join uses the new queue icon, shared action layout, text-scale-aware row extents, and Blizzard's friends-restriction state. Quick Join and Friend Requests badges match Blizzard's geometry, Raid recognizes world-boss lockouts, additional roster events, and the new raid-disable game rule, RAF follows Blizzard's active Modern/Legacy owner and full rewards refresh while keeping preview rewards inert, and the status dropdown keeps Blizzard's native template height.
- **Modern Raid Layout** - Raid now combines Blizzard's 12.1 group-card chrome with BFL's compact role summary, a native top-edge layout that keeps the warm SocialUI fade without BFL's extra divider, one shared centerline for Assist All, Raid Help, counters, Ready Check, and Raid Info, native-size group labels, aligned compact footer buttons, expanded group space, transparent member rows, class-colored preview rows, and Blizzard's new raid-assignment atlases with hover tooltips.
- **Consistent Section Layout** - All scrollable Modern sections use the same 18-pixel viewport reserve and final 7-pixel scrollbar gap, placing every visible scrollbar two pixels left of the previous visual adjustment without changing row width; Quick Join and Friend Requests also share one full-height scrollbar rail.
- **Modern Directory Views** - Guild and Who use the same search-field chrome as Friends. Who also uses Modern action buttons, the original Modern 28-pixel table-header surfaces, a full-height scrollbar on an unframed gutter, and a centered full-width Search Builder with complete Dark/Custom controls, theme-colored surfaces, aligned search fields, and localized placeholders.
- **Modern Friend Requests** - Friend Requests now match Blizzard's received-request header, Title/BattleTag/Real ID card surfaces, tertiary accept/decline actions, and full-size privacy warning.
- **Modern Social Detail Views** - Recent Allies places native-size pin and pending-request indicators inline with character data, Friend Requests uses Blizzard's scaled accept and decline-dropdown contract with centered actions, and Recruit a Friend now matches the 12.1 SocialView header, action buttons, 70-pixel cards, activity-chest spacing, and rewards overview.
- **Modern Window Spacing** - Streamer Mode occupies the Battle.net bar's right action edge, Raid Help sits beside Assist All, and Help, Settings, and Ignore windows clear the Modern side-tab rail.
- **Modern Simple Mode** - The Contacts view now hides Quick Filter and Sort in every theme, offers Legacy's optional search setting as a full-width Modern search row, expands the list into freed space when search is disabled, moves filter/sort access into the Contacts menu, and gives Dark/Custom a compact square portrait contained by the main frame.
- **Filter Menus** - Friend filters now use shared Filters and Tags submenus in Modern, Legacy, and Simple Mode. Active filters and selected tag facets appear in a compact, stable first menu level and update immediately after every selection without moving an open submenu; Modern keeps the clean text label, while Legacy uses a centered generic BFL filter icon and vertically centered header selections.
- **Modern Theme Support** - Dark and Custom now use a dedicated, reversible Modern renderer with a transparent Battle.net header, aligned menu and search/filter controls, white BattleTag and copy actions, accent-colored BFL icons, flush side tabs, borderless invite actions in Friends and Recent Allies, compact Raid utilities, border-free Quick Join and Who result content, darkened Modern Who headers, native dark group headers without gold click chrome, and visibly darkened native scrollbar chrome. Blizzard and Legacy keep their existing presentation.
- **ElvUI Theme Support** - ElvUI now skins both Retail interface styles through separate Legacy and Modern pipelines. Modern follows ElvUI's SocialUI treatment for the frame shell, Battle.net controls, side tabs, contact cards, action buttons, directory headers, and scrollbars while preserving BFL's 12.1 geometry; repeated theme and style refreshes no longer duplicate hooks or reapply Legacy layout changes to Modern.
- **Friend Tag Chips** - Friend-row tags now use true circular capsule ends, a crisp black outline, preserved tag colors, and up to three rows of three chips without MaskTextures; they no longer intercept mouse input or show separate tag tooltips.
- **Adaptive Friend Rows** - Friend cards now stack their visible name, info, multi-account, and tag lines from a three-pixel top inset and calculate their height from the content that is actually shown. Long names wrap across as many lines as needed, including names without spaces, instead of being truncated. Rows grow beyond the old fixed Modern sizes and retired height cap when configured fonts or extra lines need more room.
- **WHO Rows** - Alternating row backgrounds now have an adjustable strength control in both settings interfaces.
- **Settings Preview** - Changes from both settings interfaces now refresh every active Preview surface immediately. The fixtures cover mobile-only and multi-game friends, max-level rows, nicknames, dynamic groups, Contact Memory, Guild nicknames, and Broker columns without writing preview data to SavedVariables.

### Fixed
- **Modern Theme Runtime** - Fixed a nil palette access while styling group headers and kept their original darkened texture visible.
- **Legacy UI Restoration** - Switching from Retail's Modern interface to Legacy now reconstructs the v2.7.0 tab rows, whole-pixel window geometry, header dropdowns, Guild scrollbar, Quick Join spacing, Who Search Builder, RAF ownership, and original Who/Raid button templates without changing the Modern presentation. Guild also closes the gap left by unavailable RAF, and Ready Check no longer hides Assist All on Retail Legacy.
- **Recent Allies Invite Button** - The Modern invite action now resets the legacy TravelPass texture crop before applying Blizzard's square SocialCard atlases, preventing the button background from rendering as narrow vertical strips while preserving the original Legacy artwork.
- **Preview Mode** - `/bfl preview` again toggles the complete Retail 12.1 fixture, including Recent Allies and a fully local Recruit a Friend roster that remains available when RAF is disabled on the account or PTR. Its full boot is distributed safely across frames without debug chat spam, then commits the complete mock friend model after all gated fixture work, preventing client stalls and empty custom groups. Preview friends expose deterministic game-specific icons and WoW status, consume current name/info, faction, favorite, font, and layout settings instead of stale cached values, and keep multi-account details above rather than underneath tag chips. Friend Requests cover Title/BattleTag/Real ID and reproduce Blizzard's pending-request counter and tab glow outside the selected Requests view; Quick Join reproduces its counter without an artificial tab glow. RAF exposes Blizzard's complete rewards window through a seven-step local reward track while keeping claim and recruitment services disabled. Raid rows use their class backgrounds, and selected mock friends are released when switching or disabling preview profiles.
- **Preview Who Isolation** - Preview Mode no longer creates, stores, refreshes, or advertises mock Who results; the Who directory remains entirely on Blizzard's live search data.
- **Modern Group Headers** - Retail 12.1 group headers now use static, bounded name/count regions. Labels in other writing systems use Blizzard's preinitialized multilingual system font instead of resolving BFL's runtime-created FontFamily during ScrollBox setup; ASCII and extended Latin labels retain all configurable BFL font settings. Preview diagnostics can compare ASCII, extended Latin, and multilingual regression sets.
- **Raid Member Interaction** - Hovering raid members on Retail 12.1 no longer attempts to anchor a protected proxy to an insecure member slot. Right-click menus continue to use the member button's secure action path.
- **Drag and Hover Handling** - Reordering groups, filters, sorters, and broker columns no longer calls the removed global mouse-over helper. Friend-group drops and themed hover states use the cross-flavor Region API as well.
- **Modern Frame Chrome** - The content background and lower divider now remain inside the resizable frame border, and friend-row tags sit two pixels lower.
- **Friends Frame** - The title now uses the correct centered bounds when Simple Mode hides the portrait, and legacy filter/sort dropdowns stay hidden while the Modern UI is active.
- **Theme Settings** - Theme sliders no longer reskin the full interface for every drag increment, and resetting a theme updates the visible controls immediately.
- **Frame Scale** - Changing the scale in Settings Center now applies it immediately.
- **Friend Tags** - Friend Tags are now a standard feature instead of a Beta feature and can be enabled independently from Private Notes. Their settings are grouped by purpose, tag management lives only in the dedicated editor, and legacy Blizzard-tag handoff is shown only when data is waiting to migrate. Their BFL-owned context menu no longer leaks into Blizzard's menu, the single note action is flat, and the rebuilt editor adds automatic saving, drag-and-drop ordering, a searchable BFL/WoW icon explorer, a true friend-row chip preview, and bare icon-only rendering without pill chrome. Native Blizzard tags remain available in BFL's context menu, friend search, and tag filters when BFL's custom tag feature is disabled.
- **Group Order** - Arrow color controls are hidden when collapse arrows are disabled.
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

## [2.6.4]        - 2026-06-25

### Fixed
- **Classic Friends List** - Fixed class-colored names for WoW friends whose localized class data could miss Classic class ID gaps, including druids on Anniversary realms.
- **Classic UI** - Adjusted the WHO zone dropdown spacing and stabilized copy-name dialogs so their input fields fit on first open.

---

## [2.6.3]        - 2026-06-22

### Added
- **Settings Center Beta** - Added a LibSettingsDesigner-based Settings Center with dashboard, task-based categories, native controls, changelog/help pages, support links, New badges, and BFL Dark/Custom and ElvUI skin support. Enable it through Beta Features; the classic settings window remains the default.
- **Notes & Tags Beta** - Added local private notes for friends and ignored players plus Blizzard-compatible and custom BetterFriendlist tags, with row chips, tooltips, context menu actions, and Settings Center controls.
- **Auto Raid Assist** - Added an opt-in assistant picker for BattleTag friends, nickname matches, manual Character-Realm targets, friends, guild members, and current party or raid characters.

### Improved
- **QuickFilter Builder** - Added friend tag rules for tag text, tag source, tag count, and has-tag matching.
- **Auto Raid Assist** - Improved promotion reliability after party-to-raid conversion, cooldown waits, multiple matching targets, and same-realm character matching.
- **Client Compatibility** - Prepared Recruit A Friend, Quick Join, Battle.net friend metadata, censored Group Finder entries, and guild rank refreshes for Retail 12.1.

### Fixed
- **Classic Guild Window** - Kept Classic clients on Blizzard's separate Guild window so the Guild keybind no longer opens the Friends list.

### Removed
- **Settings Statistics** - Removed the retired settings statistics page from the modern and legacy settings flows.

---

## [2.6.2]        - 2026-06-17

### Improved
- **Broker Tooltip Theming** - Added settings for the shared Friends/Guild Broker separator color and per-theme Broker tooltip background color and opacity. Find the separator color under Settings > Data Broker > Broker Tooltip Appearance, and the background/opacity controls under Settings > Theme > Broker Tooltips.
- **Party Invites** - Improved the invite buttons in the WHO list and Recent Allies so they keep working reliably on Retail and Classic, including upcoming Retail updates.

### Fixed
- **Quick Join** - Restored the card-style group display with activity images.
- **Broker Separators** - Made Friends and Guild Broker header, group, empty-state, and footer separator lines use the same configured color and pixel-consistent thickness.
- **Guild Broker Groups** - Made expand and collapse indicators match Friends Broker formatting and use the same color as their group headers.
- **Menu Bridge** - Matched the companion AddOn category metadata to BetterFriendlist.
- **Predefined Groups** - Fixed Favorites, In-Game, and Recently Added groups sometimes expanding without their matching friends.

### Known Issues
- **Battle.net Favorites** - World of Warcraft currently reports no Battle.net Favorites for some accounts even when Favorites are set in the Battle.net Desktop App. This Blizzard API issue has been reported; BetterFriendlist cannot restore Favorite data while the client APIs return none.

---

---

*Older versions archived. Full history available in git.*
