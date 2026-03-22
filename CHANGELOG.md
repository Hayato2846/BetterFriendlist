# Changelog

All notable changes to BetterFriendlist will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [2.5.0-beta2]       - 2026-03-22

### Changed
- **Library Isolation** - BetterFriendlist no longer loads shared global libraries (LibStub, CallbackHandler, LibQTip, LibDataBroker, LibSharedMedia). This prevents the addon from being falsely blamed for taint errors caused by other addons that share the same libraries. Font and media features now gracefully fall back to defaults if no media library is available.
- **Arcana** - Updated all references from ChocolateBar to Arcana to reflect the addon's new name.

### Improved
- **Font Dropdowns** - Font selection dropdowns in Settings now use lazy loading, so fonts are only loaded as they scroll into view instead of all at once. This eliminates a brief freeze when opening a font dropdown for the first time.

### Fixed
- **Taint Errors** - Eliminated thousands of "Action was blocked" taint errors that could occur when opening the friend list during or shortly after combat. Tooltips and the friend list window now use addon-owned frames that cannot interfere with Blizzard's protected UI.
- **Frame Position** - Fixed the friend list window sometimes resetting to the center of the screen instead of restoring the saved position. This could happen when opening it via the Data Broker, after a game crash, or when other UI addons moved the window.
- **Midnight Compatibility** - Fixed a crash in the chat system that could occur on WoW 12.0 (Midnight) when a system message arrived while the Global Sync was adding friends. Also hardened all internal display code against the new privacy-protected account names.
- **Standalone Installation** - Fixed a crash on startup when BetterFriendlist was the only addon installed and no shared library provider was available.
- **Classic: Send Message** - Fixed clicking the "Send Message" button on Classic crashing with an error instead of opening a whisper to the selected friend.
- **Non-Roman Alphabets** - Fixed Korean, Chinese, and Russian text not displaying correctly when no font library addon (e.g. SharedMedia) was installed. All text now uses the correct locale-appropriate font as a fallback.
- **Whisper in Instances and Combat** - Fixed clicking to whisper not working while inside instances, Delves, Mythic+, PvP matches, or during combat. This affected both the Data Broker tooltip and the "Send Message" button in the friend list.
- **Data Broker: Built-in Groups** - Fixed the "In-Game", "Favorites", and "Recently Added" groups not appearing in the Data Broker tooltip. Only custom groups were shown previously.
- **Data Broker: Class-Colored Character Names** - Fixed the %character% token in name format not being class-colored in the Data Broker tooltip. Character names now respect the class color setting, matching the main friend list behavior.

### Removed
- **Keybind Override** - Removed a redundant keybinding entry from the Key Bindings UI. The O-key (Social) redirect was already handled internally and the extra entry served no purpose.

---

## [2.4.4]       - 2026-03-09

### Fixed
- **Global Sync** - Fixed several issues that could cause "Player not found." spam and repeated failed sync attempts. The sync now works correctly across connected realms and respects the friend list limit.
- **Raid Shortcuts** - Fixed raid shortcuts (Assist, Raid Lead, Main Tank, Main Assist, and the right-click context menu) not working on Classic. Also fixed these shortcuts silently failing on Retail when "Cast on Key Down" was enabled in the game settings.

---

## [2.4.3]       - 2026-03-02

### Changed
- **Data Broker Right-Click** - Also opens the friend list if it was closed.
- **Friend Tooltip** - Now uses Blizzard's native tooltip instead of a custom replica.
- **Tooltip: Max Game Accounts** - Setting removed. Always shows up to 5 accounts (Blizzard default).

### Fixed
- **Data Broker Tooltip** - No longer stays open for ~5 seconds after moving the mouse away (Arcana, Bazooka, etc.).
- **Data Broker Right-Click** - Fixed an error when right-clicking the icon to open settings.
- **Beta Features Toggle** - Fixed an error when disabling Beta Features while on a Beta settings tab.

---

## [2.4.2]       - 2026-02-26

### Added
- **Raid Tools** - New "Tools" button on the Raid tab that opens a dedicated Raid Tools panel. Features include:
  - **Sort by Role** - Arranges raid members by role with two sort modes: Tanks > Melee > Ranged > Healers, or Tanks > Healers > Melee > Ranged. Uses spec inspection to accurately distinguish melee and ranged DPS.
  - **Split Raid** - Splits the raid into two balanced halves or into odd/even groups, distributing roles, classes, Battle Rez, and Bloodlust evenly across both sides.
  - **Balance DPS** - Optional checkbox that uses damage meter data (Details! or Blizzard's built-in Damage Meter) to evenly distribute DPS output across both sides when splitting.
  - **Promote Tanks** - Gives raid assistant to all players with the Tank role.
  - **Preserve Groups** - Excludes any combination of groups 1-8 from being modified during sort or split operations.
  - **Auto-resume after combat** - Automatically continues an interrupted sort or split after leaving combat.
  - Shows live progress during sort and split operations (e.g., "Sorting... (5/12)").
- **Quick Filter: In A Game** - New Quick Filter option that shows only friends who are currently playing any game (WoW, Overwatch, Diablo, etc.), hiding offline, app-only, and mobile-only friends.

### Fixed
- **Assist All Checkbox** - Fixed the "Assist All" checkbox and its label not disabling when the player isn't raid leader. Also fixed the state not updating when converting between Raid and Party or when raid lead is given or taken. The checkbox tooltip now matches Blizzard's default behavior.
- **Raid Tab Non-Roman Character Names** - Fixed raid member names in non-roman alphabets (Korean, Chinese, Russian) not rendering correctly even when the selected font supports them. The font fallback system was not being applied in the Raid tab, unlike the Friends list where it already worked.

### Changed
- **Raid Tab Controls Always Visible** - The "Assist All" checkbox, role counts, and member count on the Raid tab are now always visible, even when not in a raid group.

## [2.4.1]       - 2026-02-23

### Added
- **Who Search Builder: Smart Race/Class Filtering** - The Who Search Builder now prevents impossible race-class combinations (e.g., Dracthyr Death Knight, Human Demon Hunter). When you select a class, only compatible races appear in the race dropdown and vice versa.
- **Who Search: Throttle Protection** - The Refresh button now shows a 5-second cooldown countdown after each search, preventing queries from being silently dropped by the server. A "Searching..." indicator appears while waiting for results, and a timeout message is shown if no results are received.
- **Recently Added Group** - New optional builtin group that automatically tracks newly added friends. Friends appear in the group for a configurable duration (default: 7 days) and can be bulk-added to custom groups or cleared individually. Enable it in Settings under General -> Group Management.
- **Who Search Builder: Docked Mode** - The Who Search Builder can now be docked as a standalone panel next to the main window. Click the new dock button in the builder's title bar to switch between overlay and docked mode. In docked mode, the search box updates live as you type, the builder stays open after searching, and ESC no longer closes it. Your preference is saved across sessions.
- **Who Results: Alt+Click to Search Builder** - Alt+Click on a Who result now adds the hovered column's value (Name, Zone, Guild, Race, Level, or Class) directly into the Search Builder fields. The Search Builder opens automatically if it is not already visible.

### Changed
- **Who Search Builder: Name Field Character Limit** - The name field in the Who Search Builder is now limited to 12 characters, matching the maximum length of WoW character names.
- **Who Results: Smarter Ctrl+Click Search** - Ctrl+Click on a Who result now searches based on the column you are hovering over (Name, Zone/Guild/Race, Level, or Class) instead of always using the dropdown column. The tooltip also shows which column will be searched.

### Fixed
- **Raid Info Overlap Layering** - Fixed visual overlap where parts of BetterFriendlist could render on top of the Blizzard Raid Information window when both frames were on top of each other.
- **Raid Inset Misaligned** - Fixed the inset (dark grey background) position of raid tab to properly align with quick join in BFL's normal mode.
- **Raid and Quick Join Placeholder Text Misaligned** - Fixed the "Not in Raid" and "No groups available" placeholder texts appearing at different vertical positions. Both are now consistently centered within their respective content areas.
- **Visit House Not Working After Combat** - Fixed the "Visit House" button becoming permanently broken after opening the house list for the first time during combat.
- **Who Search Builder: Unsorted Dropdowns** - Fixed race and class dropdowns in the Who Search Builder not being sorted alphabetically, making it difficult to find specific options quickly.
- **Who Search Builder: Level Range Validation** - Fixed level input fields allowing values beyond the maximum player level. Both minimum and maximum level fields now automatically cap entered values to the current expansion's max level and prevent values below 1.
- **Streamer Mode Still Active When Button Hidden** - Fixed Streamer Mode remaining active when the "Show Streamer Mode Button" option was disabled. The addon now automatically deactivates Streamer Mode when the button is hidden, restoring the original header text and removing privacy filtering.
- **Who Search: Stale Player Selection** - Fixed being able to invite or interact with players from previous Who search results after starting a new search. Player selection is now automatically cleared when a new Who search is executed.

## [2.4.0]       - 2026-02-21

### Fixed
- **Streamer Mode Whisper Broken** - Fixed whispering via the right-click context menu not working when Streamer Mode was active. The whisper target was incorrectly set to the formatted display name (including character name and color codes) instead of the account name.

## [2.3.9]       - 2026-02-19
### Added
- **Who Frame Visual Overhaul** - The Who search results now feature class icons, class-colored names, level difficulty coloring, alternating row backgrounds, and taller rows for improved readability. Hovering a result shows a detailed tooltip with name, level, race, class, guild, and zone. Double-clicking a player whispers them (configurable to invite instead). Ctrl+Click searches by the value in the current variable column (zone, guild, or race).
- **Who Settings Tab** - A new "Who" tab in Settings lets you toggle class icons, class colors, level colors, zebra striping, and choose the double-click action.
- **Who Search Builder** - A new filter icon next to the Who search box opens an interactive query builder. Fill in name, guild, zone, class, race, or level range fields and the addon composes the correct /who syntax for you. A live preview shows the generated query before searching.

### Fixed
- **Top Tab Text Truncation** - Fixed the Friends, Recent Allies, and Recruit A Friend tabs cutting off text too early, especially noticeable on the RAF tab. Also fixed the tab text position shifting downward when increasing font size.
- **Classic ElvUI Contacts/Who Layout** - Fixed multiple Classic ElvUI layout issues where filter and sort dropdowns could overlap, bottom tabs were spaced incorrectly, the Raid tab styling could be inconsistent, and WHO/Search Builder dropdown click areas did not match their visible boxes.
- **Retail ElvUI Top Tab Text Position** - Fixed the Friends/Recent Allies/RAF tab text appearing too low when reopening the frame with ElvUI active.

## [2.3.8]       - 2026-02-17
### Added
- **Multi-Game-Account Support** - Friends logged into multiple game accounts now show a badge on their game icon with the number of active accounts. Right-clicking offers an "Invite Character..." submenu to pick which character to invite. On Classic, the invite button now also shows a selection dropdown instead of always inviting only the first account.
- **New Info Line Tokens** - Added %accounts% (number of game accounts online) and %games% (list of games being played) for use in custom info line formats.
- **Configurable Tooltip Account Limit** - The number of additional game accounts shown in a friend's tooltip can now be changed (default: 5). Accessible via the new "Tooltip: Max Game Accounts" setting.
- **Multi-Account Detail Line** - Friends on multiple characters now show an extra line with icons and compact names for the other online accounts, leaving the main info line focused on status/zone.
- **Preferred Game Account** - You can now choose which game account is displayed as the primary one for friends with multiple accounts. Click the game icon or use the "Switch Game Account" right-click submenu. The picker shows your friend's name as header, game icons per entry, and a radio selection to indicate the current choice. Non-WoW games (Hearthstone, Diablo, etc.) are fully supported. Respects Streamer Mode and your name format settings.

### Fixed
- **Copy Character Name Not Showing** - Fixed "Copy Character Name" sometimes not appearing in the friend right-click menu. The option now also supports multiple characters across different game accounts via a submenu.
- **White Hover Highlight on Friends** - Fixed the mouse-over highlight on friend entries appearing white instead of the standard light blue used by Blizzard's default Friends list. Also removed a duplicate highlight definition in the Retail button template.
- **Compact Mode Icon Sizing** - Fixed game icons and invite buttons appearing oversized in Compact Mode when a friend's name fits on a single line. Icons now scale to match the actual row height.
- **Chat System Taint (MONSTER_YELL crash)** - Fixed a crash ("attempt to perform string conversion on a secret string value") that could occur when NPCs yelled in-game. The root cause was BetterFriendlist's custom tab sizing tainting Blizzard's chat system, which also uses tabs internally. This has been properly fixed with a non-tainting approach.
- **Classic Dropdown Positioning** - Fixed the QuickFilter, Primary Sort, and Secondary Sort dropdowns appearing outside the frame in Classic Normal Mode.

## [2.3.7]       - 2026-02-15
### Added
- **EnhanceQoL Ignore List Support** - When EnhanceQoL's Ignore List feature is active and set to open with the Friends frame, BetterFriendlist now automatically shows and positions it alongside its own window, just like Global Ignore List. A toggle button also appears in the Ignore List panel.

### Fixed
- **Streamer Mode Header Reset After Note Changes** - Fixed the custom header text (BattleTag replacement) being overwritten by the real BattleTag after using the Note Cleanup Wizard or importing a settings backup. The Streamer Mode button still appeared active but the header showed the real BattleTag.
- **Streamer Mode Name Format Not Live-Updating** - Fixed changing the name formatting dropdown in Streamer Mode settings not immediately updating the friends list. A /reload was previously required.
- **Custom Header Text Shown With Streamer Mode Off** - Fixed the custom header text (e.g. "Streamer Mode") remaining visible after disabling Streamer Mode in certain conditions, such as when the addon loaded with Streamer Mode already active.
- **ElvUI Skin (Advanced Settings Dialogs)** - Added ElvUI skinning for the Export, Import, Note Cleanup Wizard, and Backup Viewer windows (Settings -> Advanced). Buttons, scrollbars, and frames are now properly styled to match the ElvUI theme.
- **Missing "Status" Secondary Sort Option** - Fixed the "Status" sort option not appearing as a secondary sort choice. The sort logic already supported it but the option was missing from the dropdown and context menus.

---

*Older versions archived. Full history available in git.*
