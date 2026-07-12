# Changelog

All notable changes to BetterFriendlist will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

## [2.6.1]        - 2026-05-31

### Added
- **Guild Tab Beta** - Added a default-off Retail-only beta Guild tab with BetterFriendlist-owned roster search, online/offline filtering, sorting, guild counts, member details, notes, class and status indicators, and safe member actions where permissions and Blizzard APIs allow them. Enable Beta Features under Settings > Advanced > Beta Features, then turn on the Guild roster tab under Settings > Guild. Classic support for this beta feature will follow in a later version.
- **External AddOn Menu Bridge Beta** - Added a default-off beta bridge and official companion AddOn for showing compatible AddOn actions in supported BetterFriendlist context menus. Enable it under Settings > Advanced > Beta Features.
- **Theme Customization** - Added Retail-only beta theme customization with a Custom theme based on Dark, expanded Dark and Custom settings for colors, opacity, hover and selection states, borders, scrollbars, icons, and BFL Avatar visibility. Enable Beta Features under Settings > Advanced > Beta Features, then configure themes under Settings > Theme. Classic support for these beta theme features will follow in a later version.
- **Raid Tab** - Added an optional compact Ready Check button next to Raid Info. Enable it under Settings > Raid.

### Improved
- **Guild Broker Tooltips** - Added a subtle separator between Friends Broker groups and Guild Broker rank groups.

### Changed
- **Client Compatibility** - Prepared friend invites and raid controls for upcoming Retail client changes while preserving current Retail and Classic support.
- **Raid Tools** - Improved handling for temporarily uncached raid roster names.
- **Font Rendering** - Made custom font handling more defensive on newer clients.

### Fixed
- **Friend Menus** - Restored Blizzard's invite versus request-to-join labels and actions for Battle.net friends.
- **Recruit A Friend** - Shortened the search placeholder and kept it on one line in the header search field.
- **Tabs** - Fixed truncated top and bottom tab labels showing duplicate hover tooltips.

### Performance
- **Top Tabs** - Reduced hitches when switching between Friends, Recent Allies, Recruit A Friend, and Guild tabs.
- **Guild Roster** - Reduced memory churn when reopening or switching to the Guild roster tab.
- **Quick Join** - Reduced repeated row-height work while showing available groups.

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
- **Friend Tooltips** - Restored the "Also in group" details and Blizzard-matching restrictions on Battle.net request-to-join buttons.
- **ElvUI Skin** - Fixed startup, availability, and settings-toggle issues when ElvUI was selected, unavailable, or managed outside the Retail beta Theme tab.
- **Menu Compatibility** - Fixed protected Retail unit menu handling and restored Total RP 3 profile actions in BetterFriendlist friend menus.
- **Raid Tools** - Fixed a Lua error after moving players between raid groups with drag and drop.
- **Recruit A Friend** - Fixed reward-viewing tab issues, protected Copy Link errors, and a tooltip stack overflow.

### Performance
- **Friend List Sorting** - Reduced CPU time and memory churn when changing QuickFilters and Sorter selections.
- **Quick Join** - Reduced repeated group-priority and friend-relationship lookups while sorting available groups.

### Outlook
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

---

*Older versions archived. Full history available in git.*
