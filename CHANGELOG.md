# Changelog

All notable changes to BetterFriendlist will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [3.0.1]        - 2026-11-06

BetterFriendlist 3.0.1 improves group note sync and backups, adds ruleset checks for invites in WoW Forever, and makes smooth scrolling optional.

### All WoW Versions

#### Added
- **Full Backups** - Exports now include private contact notes and saved note backups. Both backup windows explain that the exported data can contain private information and friend names.
- **Global Sync Database** - Use Delete All to clear saved Global Sync entries and their notes for this client after confirmation, without removing anyone from your Blizzard friends list.

#### Improved
- **Group Note Sync** - Large syncs send queued updates without waiting for each note to appear or repeatedly sending changes already awaiting confirmation. Progress shows what is queued and what is waiting, with fewer repeated friend-list reads and window refreshes.
- **Note Cleanup** - The wizard keeps its recovery copy across retries, waits for delayed note changes, and lets you stop cleanup while keeping the backup. Title friend backups can be restored during the same game session.
- **Backup Text Fields** - Large pastes in the import and export windows are buffered to reduce pauses. Selections and text after the insertion point are preserved.

#### Fixed
- **Group Assignments** - Existing note tags are read before syncing starts, and assignments stay intact when groups are renamed or changed during a sync. Group names containing # are supported, though other FriendGroups addons may display their escaped form.
- **Settings Imports** - Backups are checked before replacing your data, and the previous settings are restored if applying an import fails. Nested filters and older group colors are preserved.
- **Global Sync Backups** - Saved friends and Global Sync options are restored only into the same WoW client type, keeping Retail, Forever, and Classic separate. Imports from another client or older backups without this information keep your existing Global Sync data.
- **Game Icons** - Friends playing WoW Forever show Blizzard's matching game icon in the friends list, tooltips, account menus, and the Data Broker.
- **Friend Tags** - Removed patch-number references from the Blizzard handoff heading and description.

### Retail Midnight & WoW Forever

#### Improved
- **Scrolling** - Immediate scrolling is the default again, matching the behavior before 3.0.0. Enable Smooth Scrolling in General settings to animate scrolling in either the Modern or Legacy layout.

### WoW Forever

#### Added
- **Ruleset Display** - Friend details show Normal, PvP, RP, or RP-PvP instead of internal realm names. The default info line includes the ruleset, and custom name and info formats can use %ruleset%.
- **Ruleset Invites** - Invite and Request to Join now check rulesets as well as faction. The party button is disabled for a different ruleset and explains why on hover; friends with several online characters can still use a compatible character.

#### Fixed
- **Class Colors** - Retail friends keep their Monk, Death Knight, Demon Hunter, and Evoker colors when viewed in Forever, including in tooltips, account menus, and the Data Broker.
- **Character Names** - Auto Raid Assist keeps complete first and last names when finding, saving, and promoting Title friends. Raid, guild, and Quick Join displays also preserve surnames.
- **Who Searches** - Who searches open in BetterFriendlist instead of Blizzard's Who or Looking For Group window, including searches from /who and character links. Looking For Group remains available for its normal group activities.
- **Global Sync** - Saved entries can be removed from the sync database without removing Blizzard friends. The invite list opens horizontally centered over the friends list.

### WoW Classic

#### Fixed
- **Backups and Notes** - Fixed missing characters at the end of some backup strings. Non-English group names can use the full note length supported by the client.

---

## [3.0.0]        - 2026-11-03

BetterFriendlist 3.0.0 adds saved Who searches, an option to show friends' alts in tooltips, and smoother scrolling on Retail and Forever.

### All WoW Versions

#### Added
- **Known Characters** - You can now link alts to a friend and show them in their tooltip. You can add characters yourself or let BFL remember characters it sees your Battle.net friends play. Both options are off by default, and the list stays hidden in Streamer Mode.
- **Who Searches** - Use the star next to the search box to save up to 12 searches or pick a recent one. You can edit it before hitting Search, and you can clear or turn off your search history.
- **Friend Tooltips** - Tooltips now show whether someone is a WoW, BattleTag, or Real ID friend when that info is available.

#### Improved
- **Themes** - Dark and Custom now draw many of their flat borders the same way, including in Settings and the Friend Tag Editor. Each theme keeps its own colors.
- **Changelog** - Drag the bottom-right corner to make the window wider or taller. It remembers your size the next time you open it.
- **Settings Center** - Clicking a search result highlights the setting it takes you to. Pages with tabs no longer repeat the tab name above the settings, and the Note Cleanup descriptions have room to wrap without covering the buttons.

#### Fixed
- **Recently Added** - Long-time friends no longer show up as newly added while your friends list is still loading or after a reconnect.
- **Faction Icons** - Faction icons now show up with name-only and BattleTag-only layouts when enabled.
- **Settings and Setup** - Support links copy in full, window size fields have room for the whole number, and filters stay inside the list while you drag them. Checkbox borders in Dark and Custom and the borders on the setup summary are more even.
- **Group Actions** - Fixed errors when promoting someone or changing the group type in combat, and when blocking Battle.net friends while Blizzard restricts the action.
- **Who and Friend Tooltips** - Saved searches keep their wording when you open them in the Search Builder. Friend details no longer stick around when the game reuses a tooltip.

### Retail Midnight & WoW Forever

#### Added
- **Smooth Scrolling** - The friends list now scrolls smoothly by default in both the Modern and Legacy layouts.
- **Recent Allies** - Click a player to see what you did together and how long ago. You can also see their latest activities in the tooltip.

#### Improved
- **Changelog** - The changelog window now uses backgrounds from the Modern friends list when that layout is active.

#### Fixed
- **Recent Allies** - Fixed errors when details about another player are hidden, including in the pin tooltip. Preview entries can no longer trigger real player actions.
- **Modern Friends Window** - Side tab icons and the Who scrollbar stay lined up when you switch tabs. In Dark and Custom, disabled buttons are easier to spot, and the Streamer Mode header and Raid help text are less bright. The Guild filter only shows its selection once.
- **Streamer Mode** - If a Title friend has no BattleTag, the friends list and right-click menu show their character name.
- **Who Search** - Class and race filters work again on clients where those searches could fail.
- **Raid Tab** - The Raid tab follows the game's availability rules, and promotion buttons respect who can promote group members.
- **Guild Roster** - You can still open the guild list when the game temporarily hides extra details like professions.

### WoW Forever

#### Fixed
- **Quick Join** - Quick Join unlocks with Group Finder at level 10. If it isn't available yet, the setting shows why.
- **Global Friend Sync** - Saved names keep their surnames, and BFL skips your own character. If you have saved friends left to invite, use the globe next to Add New Friend. Add All opens Blizzard's confirmations one at a time.

### WoW 12.1.7 PTR

#### Compatibility
- **PTR Support** - Updated BetterFriendlist and the Menu Bridge for the 12.1.7 PTR.

---

## [2.9.2]        - 2026-10-11

BetterFriendlist 2.9.2 adds a WoW Forever filter and fixes greyed-out group invites, along with a few smaller fixes.

### All WoW Versions

#### Fixed
- **Group Invites** - Fixed cases where Invite was greyed out in a Battle.net friend's right-click menu, including friends on other realms in WoW Forever. The character picker also handles friends with multiple WoW accounts.
- **Remove Friend** - The confirmation now uses the correct wording for WoW, BattleTag, and Real ID friends.
- **Changelog** - The current version's draft notes now appear in both in-game changelog views.
- **Invite Tooltip** - Offline friends now show a red offline message. Fixed incorrect faction warnings and added available group activity details when requesting to join.
- **Context Menu** - Empty Interact headings are no longer shown when no actions are available, including offline Title friends.
- **Friend List** - Fixed missing updates when reopening the friends list after changes while it was closed.
- **Who Class Filters** - Fixed missing class options on some clients, including Druids on Classic.
- **Settings and Skins** - Fixed errors that could occur when Settings, Who, or an addon skin accessed UI details restricted by Blizzard.

### Retail Midnight & WoW Forever

#### Fixed
- **Battle.net Blocking** - Block actions are now hidden for Title friends or when the required account details are missing. Friend requests are checked again before an account is blocked.
- **Title Friend Colors** - Online Title friends also use class colors in name-only layouts when enabled. Offline names stay gray.

### WoW Forever

#### Added
- **WoW Forever Filter** - A new quick filter shows friends playing WoW Forever in the friends list and Data Broker.

#### Fixed
- **Character Names** - Friends' character menus, Copy Character Name, and Quick Join no longer add unnecessary realm names. Forever surnames are kept in player links.
- **Add Friend** - BFL now opens Blizzard's Add Friend window in Forever, including its handling of Title friend requests.
- **Title Friend Names** - Title friends show the character name once in the default layout and friend tooltip. Custom names are still shown in the list if they differ from the character name.
- **Friend List** - Fixed an empty friend list after login or reloading when a title friend appeared first.

---

## [2.9.1]        - 2026-09-27

BetterFriendlist 2.9.1 adds new Guild tools, updates the Settings Center, and fixes several Who and Group Finder problems.

### All WoW Versions

#### Added
- **Raid PvP Icons** - Raid and party rows can now show PvP faction or prestige icons when available.

#### Improved
- **Private Notes** - Private Notes are no longer a Beta feature. They remain disabled until you turn them on.
- **Settings Center** - Updated the Settings Center library. It now uses direct links to features, two-column pages, and grouped option rows.
- **Themes** - Dark and Custom themes now update faster when you change their colors.
- **Auto Raid Assist** - Search results now show Battle.net friends first, followed by WoW and Title friends, and then guild members. Battle.net results and targets use Battle.net blue, while WoW, Title, and Guild entries use class colors.
- **External AddOn Menu Bridge** - The bridge is no longer a Beta feature and is switched on once when upgrading to v2.9.1. You can turn it off again at any time. If the companion addon is disabled, the option is greyed out and explains why.

#### Fixed
- **Blocked Actions** - Fixed errors caused when BFL or an addon skin tried to recolor a UI element locked by Blizzard.
- **Search and Sorting** - Search and sorting now skip names or text hidden by Blizzard.

### Retail Midnight & WoW Forever

#### Added
- **Guild Roster** - Profession filters now sit inside the main Guild filter and work together with Online, All, and Offline. Message of the Day, Guild News, and Guild Information share one larger area. Guild News is always available when supported and includes filters, a scrollable history, and links for achievements and items.
- **Guild Member Menu** - Right-click a guild member to add them as a friend, ignore them, or view their house when available. The unused Who option has been removed.
- **Quick Join** - Tooltips can now show the group leader's level.

### WoW Forever

#### Added
- **BattleTag Friend Requests** - Title friends can now be added as Battle.net friends from their right-click menu.

#### Improved
- **Character Names** - Forever surnames are now kept in Who searches, right-click menus, and Recent Allies notes.
- **Context Menus** - Block and remove actions are now shown in red.

#### Fixed
- **Group Finder** - Fixed blocked-action errors that could appear after using BFL's Who tab.
- **Who During Combat** - Typing or pressing Escape in the Who tab during combat no longer causes blocked-action errors.
- **Blocking** - Battle.net blocking works again, and Title friends no longer show an unusable Block Invites option.
- **Restricted Chat** - Whisper actions are disabled and show Blizzard's reason when the account is not allowed to chat.

---

## [2.9.0]        - 2026-09-18

BetterFriendlist 2.9.0 adds support for WoW Forever to BetterFriendlist and the Menu Bridge without changing the existing Retail Midnight and Classic experiences.

### All WoW Versions

#### Improved
- **Changelog Notice** - The BFL avatar now uses the same pulsing glow animation as the Friend Requests tab when a new changelog is available.
- **Who Search Builder** - Opening the Search Builder now imports the current Who query, including name, guild, zone, class, race, and level filters. Additional free-form search terms are preserved.
- **Who Search Feedback** - Who searches now show the same loading spinner used by Recent Allies while waiting for the server. “No players found” appears only after a completed empty response, while a timeout keeps its separate retry message.

### WoW Forever

#### Added
- **WoW Forever Support** - BetterFriendlist and the Menu Bridge now recognize Forever as a modern Mainline client despite its `1.60.1` version. Available social views and features—including Forever's Recent Allies categories—follow the APIs and live game rules provided by the client, while unsupported Midnight-only features remain hidden. Retail Midnight and every supported Classic flavor retain their existing behavior.

#### Fixed
- **Forever Who Routing** - `/who` now opens BetterFriendlist directly on its Who tab and performs the search there without also opening Forever's separate LFG Who window. The native Group Finder remains available through its own UI.
- **Forever Keybindings** - The Social shortcut is now migrated only after Forever has loaded a writable binding profile, preventing a Lua error during login.

### Retail Midnight

#### Fixed
- **Raid Member Right-Click** - Hovering raid members no longer causes a protected-frame anchor error. The normal Blizzard menu, including protected actions, still opens through the secure proxy in both Retail layouts.

---

## [2.8.8]        - 2026-09-13

### Retail Live & Classic

#### Added
- **Master Looter** - Classic raid and party lists now show who is Master Looter. The icon also works with both Retail raid layouts if the client provides that flag.

#### Improved
- **Addon Window Spacing** - EnhanceQoL, GlobalIgnoreList, and NorthernSkyRaidTools now leave room for the Modern side tabs. Their Legacy positions stay as they were.

#### Fixed
- **Story Mode Raid Tab** - The Raid tab is now disabled during a Story raid and shows Blizzard's reason when hovered.
- **ElvUI Broker Tooltips** - Friends and Guild Broker tooltips use the selected ElvUI tooltip style again.
- **Broker Tooltip Scrolling** - Friend updates no longer jump a scrolled Friends Broker tooltip back to the top.
- **Raid Member Right-Click** - The Raid Player menu works again in both Retail layouts. Regular clicks, shortcuts, selection, and drag-and-drop keep working on the same row.
- **Raid Counts** - Member and role counts update after returning to a Raid tab that changed while it was hidden.

### WoW 12.1.5 PTR

#### Added
- **Friend Search and Sorting** - On 12.1.5, BFL can use Blizzard's new locale-aware text APIs for local friends, tags, groups, realms, and Recent Allies. Other clients keep the existing search behavior.

#### Compatibility
- **New Client APIs** - Added checks for the new internationalization, LFG, and timer APIs so they are only used when the client provides them.
- **Raid Updates** - Repeated raid and LFG events now share one pending refresh on 12.1.5. Older clients keep the existing timer path.
- **Matchmade Raid Markers** - Main Tank and Main Assist markers are hidden when 12.1.5 reports a matchmade raid without manual role requirements.

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

---

*Older versions archived. Full history available in git.*
