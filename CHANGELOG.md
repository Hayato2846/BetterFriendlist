# Changelog

All notable changes to BetterFriendlist will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [2.5.6-beta2]  - 2026-04-17

### Added
- **Guild Broker: Nickname Column** - New optional "Nickname" column for the guild broker tooltip. Assign custom nicknames to guild members via right-click context menu. Nicknames sync with the CustomNames library so other addons can see them too. Enable in Settings > Broker > Guild Plugin.
- **Guild Broker: Hide Level at Max** - New toggle to hide the level column for characters at maximum level, reducing visual clutter. Enable in Settings > Broker > Guild Plugin.
- **Guild Broker: Column Ordering** - Guild broker tooltip columns can now be reordered via drag and drop in Settings, just like the friends broker.

### Fixed
- **Broker: In A Game Filter** - Fixed the "In A Game" quick filter showing no friends in the broker tooltip even when friends were actively playing.
- **Broker: Filtered Count** - The broker display now correctly shows the total number of friends when the "All" quick filter is active, matching the main window. Previously it always showed the online count regardless of the active filter.

## [2.5.6-beta1]  - 2026-04-15

### Added
- **Advanced: Taint-Free Whisper** - New optional setting under Advanced that uses an inline message bar at the bottom of the friend list for whispering friends instead of opening the default Blizzard chat. This prevents BetterFriendlist from interfering with the chat system, which can cause Lua errors when other addons or Blizzard code processes messages. After sending, the bar closes automatically. Press Shift+Enter to reopen it with the same whisper target for follow-up messages. Disabled by default.
- **Broker: Filtered Friend Count** - The broker text and tooltip now reflect the active Quick Filter (e.g., "WoW only" or "Online only") instead of always showing the total online count.
- **Broker: Name Colors** - Friend names in the broker tooltip now use the font color configured in Settings > Fonts, matching the main friend list appearance.
- **Broker: Show Tooltip Hints** - New toggle in Settings > Broker to hide the clickable action hints at the bottom of the broker tooltip for a cleaner look.
- **Broker: Nickname Column** - New optional "Nickname" column for the broker tooltip. Enable it in Settings > Broker > Tooltip Columns. Shows the assigned nickname for each friend, colored with the configured name font color.
- **Broker: ElvUI Tooltip Skin** - When the ElvUI skin is enabled, the broker tooltip now uses the ElvUI backdrop style for a consistent look.
- **Broker: Guild Plugin** - New Data Broker plugin that displays guild members in a rich tooltip, similar to the existing friends broker. Shows name, level, class, rank, zone, notes, officer notes, and last online time with 8 toggleable columns. Supports grouping by rank or class with collapsible headers, online/all filter cycling, rank management (promote, demote, remove), and full click interactions (whisper, invite, context menu). Works on all WoW versions. Disabled by default, enable in Settings > Broker > Guild Plugin.

### Fixed
- **Tab Navigation** - Fixed the window getting stuck on the Who or Quick Join tab after using /who or clicking a group join link. Closing and reopening the window now correctly returns to the Friends tab.

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

---

*Older versions archived. Full history available in git.*
