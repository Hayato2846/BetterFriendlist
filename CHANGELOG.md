# Changelog

All notable changes to BetterFriendlist will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [3.1.9]        - 2026-11-24

Add a third sort criterion, customize friend colors, or move Settings independently of the friends list. This update also reduces background work while the friends list is closed.

### All WoW Versions

#### Added
- **Tertiary Sort** - Use Enable Tertiary Sort under Groups & Filters to add a third criterion to the friends list and detailed broker tooltip. The third slot offers the unused options from Secondary Sort, so you can sort by Ruleset, then Faction, then Nickname in WoW Forever.
- **Settings Window** - Use the anchor button in the title bar to detach Settings from the friends list. Drag the title bar to move the window, and its position is saved between sessions. Press Escape to close the detached window.
- **Friend Formatting** - Set or reset individual field colors when Name Formatting or Friend Info Formatting uses Custom. Parentheses and brackets around a single field take on its custom color.
- **Friend Status** - Use `%statusonline%` in a custom info line to show AFK and DND only. The existing `%status%` field also shows Online for available friends.
- **Friend Local Time** - Turn on Show Friend Local Time in Display Options to set a friend's time difference from their right-click menu and see their local time in the tooltip. The option starts off and keeps saved time differences when disabled.

#### Improved
- **Name and Info Formatting** - Each custom format field appears when you select its own Custom preset. Switching presets keeps your saved format.
- **Group Management** - The third sort criterion, In-Game group mode, and Recently Added duration settings appear under their respective options when enabled. Their saved values are kept when you turn an option off.
- **Recently Added** - When the friends list is closed, incoming friend changes are processed together. Changes received in combat can catch up when combat ends.
- **Settings Title Bar** - Blizzard and EllesmereUI use compact title-bar icons for the anchor and preview controls. EllesmereUI gives both controls the same size, and hovering brightens the icon.
- **Beta Features** - Experimental settings pages appear in the sidebar and search when Beta Features is enabled.

#### Fixed
- **Friends List** - Closing the window during a refresh stops work on the unfinished list. The next open refreshes the list again.
- **Group Note Sync** - Pending group and note changes sync when the friends list is open and you're out of combat. Updates for an individual Battle.net friend check that friend's note directly.
- **Drag and Drop** - Drag friends between groups with single-click whispering enabled. The drag preview uses the name shown in the friends list and matches the current theme.
- **Raid Tab** - Group changes and combat transitions no longer update the raid controls while the Raid tab or friends window is closed. Auto Raid Assist continues to work in the background.
- **Guild News** - News updates wait until the Guild News panel is visible.
- **Who** - The search countdown updates only while its buttons are visible and picks up at the correct time when reopened.
- **Friends Broker** - The label and tooltip show the same count when a QuickFilter or tag filter is active.
- **Dynamic Tag Groups** - Collapse All Groups and Expand All Groups now apply to tag groups and are available from their right-click menus.
- **Guild Broker** - Online guild members' levels use difficulty colors relative to your character's level.
- **Forever Friend Locations** - When the friends list or broker gets a Forever friend's zone from their Battle.net status, it no longer mistakes text after a dash for the friend's realm.
- **Settings Window** - Controls stay aligned when reading New badges, changing checkboxes, or resizing the window.
- **Friend Tags** - Tag icons keep their editor colors in older right-click menus. The tag hint also accounts for the active dynamic tag group filter.
- **Friend Tag Editor** - Fixed a Lua error when opening certain older tags with custom icons.
- **Custom Theme** - Friend Tag Editor action icons and the welcome message use the configured theme colors.
- **Nickname Hint** - The extra nickname hint stays hidden when the friend's name already shows their nickname.

### WoW Retail & WoW Forever

#### Fixed
- **Social Window** - Opening BetterFriendlist from Blizzard's Social controls respects your window preference and works during combat.
- **Friends Search** - EllesmereUI's Blizzard window skin no longer covers the BetterFriendlist search field with a second background or border.
- **Recent Allies** - Closing the friends window stops a pending search from rebuilding the hidden list.
- **Modern Group Headers** - Korean, Chinese, and Cyrillic group names use fonts that support their characters.
- **Battle.net Friend Tooltips** - Under Other Game Accounts, the Blizzard marker reflects whether a character is on a different realm or belongs to the other faction.
- **Quick Filters** - Removed In Queue and Available for Queue because WoW can block these filters. Existing selections switch back to All Friends.
- **Quick Join** - Group listing changes refresh when you reopen the friends list, reducing background work while it is closed.

### WoW Forever

#### Fixed
- **Escape** - Escape closes BetterFriendlist alongside Blizzard windows when Respect UI Hierarchy is enabled. In combat, Escape also closes the friends list when WoW allows the window to be hidden.
- **Gray Out Other Rulesets** - The setting also dims Retail friends and applies the same gray color to nicknames in custom names and the broker.
- **Title Friend Notes** - BetterFriendlist does less work in the background while your friends list is closed or you're in combat.

---

## [3.1.8]        - 2026-11-23

### All WoW Versions

#### Added
- **Nickname Sorting** - Sort by nickname first or use it to break ties in the friends list and detailed broker tooltip.
- **Broker Friend Tags** - The detailed tooltip can show a Tags column and the same tag groups as your friends list. Use the filter menu to pick or search for tags. Right-click a friend to manage their tags or a tag group to edit it.
- **Dynamic Tag Groups** - You can limit tag groups to online friends playing your version of WoW or using only the Battle.net app. Your other friends keep their tags and still appear in the friends list.

#### Fixed
- **Nicknames** - Editing a nickname stays with the friend you picked, even if two friends have the same display name. Changes made in CustomNames show up in the friends list and broker tooltip, including for BattleTags with no linked characters.
- **Drag and Drop** - Letting go over a friend row no longer moves the friend you were dragging.
- **Friends List** - Fixed cases where a list update could make you whisper, invite, favorite, or remove the wrong friend.

### WoW Retail & WoW Forever

#### Fixed
- **CustomNames** - The CustomNames option shows up in the right-click menu for Battle.net friends when Menu Bridge is enabled.

### WoW Forever

#### Added
- **Gray Out Other Rulesets** - Dim online friends playing on a different Forever ruleset in the friends list and detailed broker tooltip.
- **Ruleset Sorting** - Sort by Forever ruleset first or use it to break ties in the friends list and detailed broker tooltip.

#### Fixed
- **Title Friend Groups** - Fixed a bug that could leave you stuck with the "link isn't ready" message when trying to put a Title Friend in a group.
- **Title Friend Notes** - You can edit short notes you already had on Title Friends without reloading.

---

## [3.1.7]        - 2026-11-22

### All WoW Versions

#### Improved
- **Ruleset Search** - Find Forever friends by ruleset using names such as RP, Roleplay, RP-PvP, or Roleplay PvP. Searching for PvP also finds friends on RP-PvP.
- **Quick Filters** - WoW Forever Only is now called Forever Only.

#### Fixed
- **Forever Ruleset Display** - Battle.net friends show Normal, PvP, RP, or RP-PvP when their game status identifies the ruleset, including when realm information is unavailable. The ruleset also appears for additional game accounts. Unfamiliar ruleset labels are shown as supplied by Battle.net.

### WoW Forever

#### Added
- **My Ruleset Only** - This quick filter shows online friends playing on your own Forever ruleset.

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

*Older versions archived. Full history available in git.*
