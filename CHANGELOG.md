# Changelog

All notable changes to BetterFriendlist will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [2.5.6-beta4]  - 2026-05-02

### Fixed
- **Broker: Game Display** - Updated the friends broker game column to use the same Blizzard client icons and rich presence/mobile/app labels as the main BetterFriendlist window instead of the outdated static icon table.
- **Broker: Friend Context Menu** - Restored right-click context menus for friends in the broker tooltip.
- **Guild Broker: Member Detail Tooltip** - Fixed member detail tooltips lingering after the cursor leaves a guild member row.
- **Broker Display Compatibility** - Improved tooltip cleanup compatibility with broker display addons such as Arcana and Bazooka by avoiding a no-op leave handler on BetterFriendlist broker plugins.
- **Guild Broker: Professions Column** - Fixed the Professions setting not adding a separate tooltip column when an older saved guild broker column order was present.
- **Guild Broker: Profession Icons** - Hid unhelpful default profession rank values so the professions column stays focused on the icons unless a meaningful rank is available.
- **Broker: LDB Count Refresh** - Fixed the broker display getting stuck at 0 or stale online counts until a broker setting was toggled. Broker updates now listen for Battle.net/friend events even when Beta Features are disabled and refresh again after roster data settles.
- **Broker: All Filter Count** - Fixed the broker display so the "All" quick filter counts all visible friends, matching the main window, while the "Online" filter still counts online friends only.
- **Social Keybind** - Pressing the Social key now opens BetterFriendlist directly without also opening Blizzard's friend list in the background.
- **Combat Window Toggle** - Improved opening and closing BetterFriendlist during combat when Respect UI Hierarchy is enabled.
- **Taint Hardening** - On secret-value clients, BFL now opens its own friend context menus instead of patching Blizzard UnitPopup menus; legacy UnitPopup customizations are limited to non-secret clients.
- **Context Menus** - Expanded the secret-value fallback menus to cover Blizzard's Friend, Battle.net Friend, and Recent Ally actions, including notes, friends-of-friends, favorite toggle, RAF summon, invite/request invite, houses, ignore/block, remove, report, PvP AFK report, community message delete, recent ally pinning, and copy name. Target actions were intentionally omitted because `TargetUnit()` is protected for addon menu callbacks.
- **Context Menus** - Added BetterFriendlist group/nickname controls to additional Blizzard UnitPopup menus when the clicked player is already a friend.
- **Taint Hardening** - Disabled automatic hidden FriendsFrame initialization on secret-value clients and stopped replacing `C_FriendList.RemoveFriendByIndex` on those clients.
- **Whisper Actions** - Quick Join whisper links now use the secure SetItemRef wrapper, and the Send Message button now accepts both BNet account ID field names.

### Added
- **Broker: Class Icons and Column Colors** - Friends broker tooltip now has an option to show class icons next to friend names plus color pickers for Nickname, Character, Zone, Realm, and Notes columns.
- **Guild Broker: Profession Icons** - New optional Professions column shows guild members' primary profession icons and ranks when guild community data is available.

## [2.5.6-beta3]  - 2026-04-19

### Added
- **Guild Broker: Class Icons** - New option to display class icons next to character names in the guild broker tooltip. Enable in Settings > Broker > Guild Plugin.
- **Guild Broker: Sort Mode** - The guild broker tooltip can now be sorted by name, rank, level, class, zone, or nickname. Configure in Settings > Broker > Guild Plugin.
- **Guild Broker: Exclude Yourself** - New option to hide your own character from the guild broker list and subtract from the online member count.
- **Guild Broker: Custom Nickname Color** - Nickname colors in the guild broker tooltip can now be customized with a color picker. A checkbox lets you toggle between class colors and a custom color.
- **Guild Broker: Column Colors** - New color pickers for Rank, Zone, Note, and Officer Note columns in the guild broker tooltip. Customize each column's text color individually in Settings > Broker > Guild Plugin.
- **Guild Broker: Status Indicators** - AFK and DND status icons are now shown next to member names in the guild broker tooltip, matching the Blizzard guild interface style. Online members no longer show a green circle.

### Fixed
- **Broker: Online Count** - Fixed the broker display always showing the total number of friends instead of the actual online count.
- **Guild Broker: Tooltip Error** - Fixed a Lua error that could occur when hovering over guild members in the broker tooltip, caused by a frame anchoring conflict.

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

*Older versions archived. Full history available in git.*
