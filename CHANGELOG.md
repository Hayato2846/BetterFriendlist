# Changelog

All notable changes to BetterFriendlist will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [2.5.3-beta1]  - 2026-03-27

### Added
- **Name Format: BattleTag Only** - New name format preset that shows only the BattleTag without the character name in parentheses.

### Fixed
- **Quick Join: Secret Values** - Fixed an error in the Quick Join tab that could occur repeatedly in the background when viewing listed groups during certain restricted game states.
- **Chat Taint on Midnight** - Fixed hundreds of "secret string value" taint errors per session that could occur on Midnight (12.0.0+) whenever chat messages were received. The addon no longer hooks global tab resize functions that interfere with Blizzard's chat processing.
- **Raid Frame: Combat Restriction** - Ready Check, Convert to Raid, Everyone Assist, and Promote/Demote actions now correctly block during combat instead of showing the cryptic "Interface action failed because of an AddOn" error. The corresponding buttons are visually disabled while in combat.

## [2.5.2]       - 2026-03-24

### Fixed
- **Housing: Combat Restriction** - The "View Houses" context menu entry now shows a clear error message during combat instead of the cryptic "Interface action failed because of an AddOn" error. Visit House buttons in the house list show a gray overlay with a tooltip when combat starts while the list is already open.

## [2.5.1]       - 2026-03-23

### Improved
- **Group Note Sync** - The sync is now fully bidirectional. Existing group tags in friend notes (e.g. from FriendGroups) are automatically imported when enabling the feature. Manually adding a tag like `#MyGroup` to any friend note will create the group and assign the friend automatically.

## [2.5.0]       - 2026-03-22

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
- **Data Broker: Character Column** - Fixed the Character column in the Data Broker tooltip incorrectly showing the account name instead of only the character name.
- **Data Broker: Faction Icons** - Faction icons now also appear in the Name column of the Data Broker tooltip, not just the Character column.

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

---

*Older versions archived. Full history available in git.*
