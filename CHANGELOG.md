# Changelog

All notable changes to BetterFriendlist will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [3.1.6]        - 2026-11-21

### WoW Retail & WoW Forever

#### Fixed
- **Battle.net Party Invites** - The invite button works when WoW provides realm information without a numeric realm ID.

---

## [3.1.5]        - 2026-11-21

### All WoW Versions

#### Fixed
- **Remove Friend** - Character friends can be removed from the right-click menu using Blizzard's confirmation dialog.
- **Friend Notes** - Editing a character friend's note no longer shows an erroneous player-not-found message.
- **Friends List** - Newly added character friends and accepted friend requests appear sooner once the game delivers their details.

### WoW Retail & WoW Forever

#### Fixed
- **Modern Raid Tab** - Online raid and party members have class-colored row backgrounds again.

---

## [3.1.4]        - 2026-11-17

### All WoW Versions

#### Improved
- **Blizzard Friendlist Access** - Moved the option to Advanced under Diagnostics and disabled it once for the 3.1.4 update. Re-enabling requires confirmation that this is for diagnostics only; BetterFriendlist fully replaces Blizzard's friends list and does not support running both lists in parallel.

### WoW Retail & WoW Forever

#### Fixed
- **Who Searches** - A /who command rejected during the search cooldown no longer overwrites the text in the Who search box.

### WoW Forever

#### Improved
- **Who Searches** - Blizzard's wait messages appear in the Who tab in your game client's language. Searches with no result or recognized wait message still show the timeout notice.

### WoW Classic

#### Fixed
- **Who Sorting** - The Name, Level, and Class sort order is kept when Who results refresh or the Who tab is reopened.

---

## [3.1.3]        - 2026-11-15

### All WoW Versions

#### Fixed
- **Settings Menu** - The Settings entry in the contacts menu keeps its normal size when marked New.

---

## [3.1.2]        - 2026-11-14

### All WoW Versions

#### Added
- **Favorite Icon** - Choose the Modern Blizzard favorite star where available, alongside the existing BFL and Blizzard styles.
- **Settings Window** - Everyone now uses the redesigned Settings. Resize the window and keep your preferred size; narrow windows use a separate preview and help window that docks on the free side and remembers its width, height and collapsed state. Open or close it from the Settings edge, use setting tooltips while it is closed, or widen Settings to bring the panel back inside.
- **New Settings** - New options and their categories carry the same New badge as unread changelog entries. Click an individual setting to mark it read; category badges clear when all their new options have been read. Read status is saved per profile.
- **Settings Scrolling** - Enable smooth mouse-wheel scrolling in Settings independently of the friends list. Disabled by default.
- **Window Fonts** - Set fonts and sizes for window titles and main action buttons separately, with previews and a reset to their original fonts.
- **Input Dialogs** - Create groups, tags, and sections, rename groups, or copy links and names in windows that match your BFL theme. You can choose native input dialogs under Theme.
- **BFL Avatar** - Dark, Custom, ElvUI and EllesmereUI hide the avatar by default. Turn off Hide BFL Avatar under Theme to show it again.

#### Improved
- **Side Windows** - Dialogs and hints use the free space beside the friends list and switch sides when needed. In the Modern layout, they prefer the selected tab side.
- **Scrollbars** - Modern scrollbars retain their Blizzard appearance and use the accent color of Dark, Custom, ElvUI or EllesmereUI themes. Disabled scroll arrows stay gray.
- **Friend Tag Editor** - A redesigned editor matches Settings, with tag search, clearer sections, drag-and-drop feedback and direct list actions. Edit icons or custom paths, text, colors and visibility with live previews and pinnable help; per-tag drafts are kept until you apply or discard them, including when switching tags or resizing.
- **Name Formatting** - Browse format fields in a list under Setting details, collapsed by default. Click a field to select its token for copying.
- **QuickFilters & Sorters** - Manage filters and sorters in a simpler list, with descriptions for built-in filters and clearer game and status icons. Matching Blizzard icons are used where available; the remaining icons will be updated in a future release.
- **Groups** - Create a group from a group header, Group Management, or Group Order.

#### Fixed
- **Display Changes** - Button text and group counters refresh after switching display modes or changing UI scale.
- **Themes** - Raid Roster Help and the Assist All checkbox use the selected theme throughout, and button hover effects no longer reveal their original artwork. Footer backgrounds no longer extend into the friends list or leave an extra panel beside Add New Friend.
- **Known Characters** - The tooltip no longer repeats the character already shown above. Other known characters remain available, including when a friend is offline.
- **Tag Sections** - Hiding or showing a section updates its tags and dynamic tag groups immediately. Each tag keeps its previous visibility choices.
- **Settings Performance** - Reduced pauses when changing pages, toggling QuickFilters or changing Simple Mode with the Dark or Custom theme.
- **Theme Settings** - Selecting Dark or Custom immediately shows its customization controls. Broker tooltip appearance options are shown only for themes that support them.
- **Settings Controls** - Disabled controls, including EllesmereUI dropdowns, look inactive throughout Settings; their rows still offer hover explanations.
- **Recently Added Group** - Duration Value accepts only numbers.
- **Settings Preview** - Empty-group notices identify the groups actually hidden in the preview.
- **Dynamic Tag Groups** - Friends in a tag group leave No Group, including when it has been renamed. Group invitation counts and actions use the members shown in that group.
- **Group Names** - Create and Rename accept letters after a popup slot was used for numeric input.
- **Friend Invites** - Right-click menus preserve Blizzard's invitation action and offer a character picker when multiple accounts are available.
- **Window Position and Scaling** - The friends list restores its saved position after switching display modes or reopening near a screen corner. Settings stays within the available screen space when the friends list scale changes.
- **Raid Tab** - Party members whose names WoW temporarily hides show as Unknown. Raid members appear as soon as WoW provides their name, even if the raid roster is still loading.

### WoW Retail & WoW Forever

#### Added
- **Friend Tabs** - Place Modern tabs on the left or right of the friends list, with the right side as the default. The window keeps the selected tab rail on screen when you change sides.

#### Improved
- **Quick Join** - Group tooltips show when a listing welcomes new players.

#### Fixed
- **Search Field** - With ElvUI loaded and the Blizzard theme selected, the native search field no longer draws an extra background over BFL's search box.

### WoW Forever

#### Improved
- **Quick Join** - Group tooltips show when a listing uses Discord voice chat.

#### Fixed
- **Title Friends** - Whisper is available for Title Friends who appear offline. WoW looks up the character to whisper.

---

## [3.1.1]        - 2026-11-10

### All WoW Versions

#### Fixed
- **New Settings Hint** - The hint appears next to the friends list when you open it.

---

## [3.1.0]        - 2026-11-10

### All WoW Versions

#### Added
- **New Settings** - Open Settings from the friends list or type /bfl settings to browse by category or search for an option. Search puts matching pages and results you often choose near the top. Hover over a setting to see what it does, or click its row to keep it highlighted and pin the help and any comparison. The main preview shows your saved setup.
- **Friend Tags** - Use Icon Color to tint any tag icon, including Blizzard icons and custom paths. In Icon Only mode, you can show the tinted icon on its own.
- **Tag Sections** - Choose a section for each tag, including Blizzard tags, or create your own. Drag sections and the tags inside them to set their order in the editor and friend menu. You can hide sections or delete them with or without their tags.
- **Dynamic Tag Groups** - Show each friend in their highest matching tag group. Choose a standard header, a colored title, or Tag Chip to tint the header and show the tag icon beside the title.
- **Blizzard Tags** - Remove built-in tags from BetterFriendlist and bring them back with Restore Tags. Their assignments are kept.

#### Improved
- **Global Friend Sync** - Global Sync is available on flavors that still use WoW's old friends list. Its settings and invite shortcuts are hidden on flavors that use Title Friends.

#### Fixed
- **Nickname Dialog** - Canceling the new group window no longer leaves red text or a group-name error in the nickname box.
- **World Map Tooltips** - Quest tooltips from the world map no longer pop up through the friends list.
- **Friend Requests** - Fixed missing pop-ups for Battle.net and Title Friend requests. The pop-ups still follow your WoW notification settings.
- **Raid Tab** - Raid members listed as Unknown now show their name as soon as WoW has it. You can right-click them once the name appears.
- **Window Scale** - The friends list keeps its scale when you switch between fullscreen and windowed mode. Settings and Friend Tags follow the friends list scale and fit on smaller screens.
- **Friend Tags** - Creating a tag keeps the editor where you placed it. Confirm or cancel the color picker before applying changes to a tag. Custom tags in the friend menu follow the order you set in the editor.
- **Settings** - The active category stays highlighted when you adjust Control Opacity.

### Retail Midnight & WoW Forever

#### Improved
- **Friend Search** - Find Title Friends even when they're offline, or search by Battle.net account name, including Real ID names.
- **Copy BattleTag** - In the Modern friends list, the icon next to your BattleTag now copies it straight to your clipboard when WoW supports it.

#### Fixed
- **Who Search Builder** - The Who results scrollbar no longer overlaps the search builder's close button in the Modern layout.
- **Title Friends** - Character names appear once in the friends list and Friends Broker, with class colors and icons.

### Retail Midnight

#### Fixed
- **Friend Invites** - The invite button now works for Battle.net friends with one character you can invite, even when WoW leaves out some character details.
- **Recent Allies** - The tab shows the last known list right away and updates it in the background.

### WoW Forever

#### Fixed
- **Who Searches** - Shift-left-clicking a character name in chat runs the lookup without opening BetterFriendlist's Who tab by default. You can turn automatic opening on under Who settings.
- **Title Friends** - Title Friends keep their groups and friend notes when they go offline, switch characters, or you log back in.

---

## [3.0.3]        - 2026-11-09

### All WoW Versions

#### Fixed
- **Friend Menus** - Fixed cases where right-clicking a friend failed to open their menu.
- **Whispers** - Click to Whisper and the Whisper menu option now open the chat box in cases where they previously failed.
- **Who Searches** - Who no longer skips searches that previously left the results list unchanged.

---

## [3.0.2]        - 2026-11-07

BetterFriendlist 3.0.2 brings back Blizzard's friend menu, fixes chat taint when you start a whisper, and makes friend tags easier to edit.

### All WoW Versions

#### Added
- **Hints** - BFL can now show a hint when a nickname, friend tag, private note, new group, or favorite is hidden. You can open the options from the hint.

#### Improved
- **Friend Menus** - Blizzard's friend menu is back in both layouts when you right-click a friend in the list or Friends Broker. BFL's group, nickname, and tag options are there too, along with actions from compatible addons.
- **Raid Tab** - Right-click a raid member to open Blizzard's raid menu.
- **Friend Tag Editor** - Preview changes for each tag and use Save All to save your drafts when closing the editor. Reset previews the default look, and the delete prompt shows how many friends have the tag.
- **Tag Appearance** - Open the icon picker in one click, enter a custom path, or remove the icon. Icon Only keeps your custom text for later, and hiding a tag keeps your choices for where it appears.

#### Fixed
- **Chat Taint** - Whisper from a right-click menu, single- and double-click whispers, and the Legacy Send Message button now use Blizzard's own whisper action to fix chat taint. Who, Recent Allies, the guild tab, and both brokers use it too, so the separate Taint-Free Whisper window and setting are gone.
- **Friend Tag Editor** - Fixed a bug that could reset a custom tag's name, icon, text, or colors when you switched tags or made a new one.
- **Settings** - Guild filters, sorting, and row options now take effect right away in both settings windows. The same goes for Streamer Mode and broker display options.

### Retail Midnight

#### Improved
- **Forever Friends** - See a Forever friend's realm ruleset in the friends list and tooltips, or add it to a custom format with `%ruleset%`. The display updates when they switch between Forever and Retail.

#### Fixed
- **Blizzard Friend Tags** - Removing a friend's last Blizzard tag updates the list right away. You can edit another friend's tags while the first change is still pending.

### Retail Midnight & WoW Forever

#### Improved
- **Legacy Settings** - When you use the Modern friends list, Legacy Settings uses the same backgrounds, dividers, and scrollbar.

### WoW Forever

#### Improved
- **Friend Invites** - Invite and Request to Join in Blizzard's friend menu check realm rulesets, even if your friend has more than one character online.

#### Fixed
- **Who Searches** - The friends list stays put when another addon runs a Who search in the background.

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

---

*Older versions archived. Full history available in git.*
