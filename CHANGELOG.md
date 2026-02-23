# Changelog

All notable changes to BetterFriendlist will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [DRAFT]

### Added
- **Who Search Builder: Smart Race/Class Filtering** - The Who Search Builder now prevents impossible race-class combinations (e.g., Dracthyr Death Knight, Human Demon Hunter). When you select a class, only compatible races appear in the race dropdown and vice versa. Each WoW version (Retail, MoP Classic, Cata Classic, Classic Era) has its own accurate compatibility table based on Warcraft Wiki data.

### Changed
- **Who Search Builder: Name Field Character Limit** - The name field in the Who Search Builder is now limited to 12 characters, matching the maximum length of WoW character names.

### Fixed
- **Raid Inset Misaligned** - Fixed the inset (dark grey background) position of raid tab to properly align with quick join in BFL's normal mode.
- **Raid and Quick Join Placeholder Text Misaligned** - Fixed the "Not in Raid" and "No groups available" placeholder texts appearing at different vertical positions. Both are now consistently centered within their respective content areas.
- **Visit House Not Working After Combat** - Fixed the "Visit House" button becoming permanently broken after opening the house list for the first time during combat. The secure proxy frame is now properly deferred and created once combat ends, preventing protected function errors.
- **Who Search Builder: Unsorted Dropdowns** - Fixed race and class dropdowns in the Who Search Builder not being sorted alphabetically, making it difficult to find specific options quickly.
- **Who Search Builder: Level Range Validation** - Fixed level input fields allowing values beyond the maximum player level. Both minimum and maximum level fields now automatically cap entered values to the current expansion's max level and prevent values below 1.
- **Streamer Mode Still Active When Button Hidden** - Fixed Streamer Mode remaining active when the "Show Streamer Mode Button" option was disabled. The addon now automatically deactivates Streamer Mode when the button is hidden, restoring the original header text and removing privacy filtering.
- **Who Search: Stale Player Selection** - Fixed being able to invite or interact with players from previous Who search results after starting a new search. Player selection is now automatically cleared when a new Who search is executed.
- **Who Search Builder: Incomplete Race/Class Data** - Fixed race-class compatibility tables across all WoW versions. In Retail, Dracthyr was missing most of its classes, many races were missing Warlock and other Dragonflight additions, Haranir was not included, and Earthen was incorrectly listed as Death Knight and Druid. In Cata Classic and MoP Classic, Priest was missing Gnome and Tauren, Mage was missing Dwarf, Night Elf, and Orc, and Warlock was missing Dwarf and Troll (all combinations that were added in Cataclysm 4.0). In MoP Classic, Pandaren was incorrectly listed as a Death Knight option (Pandaren DK was not available until Shadowlands).

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

## [2.3.6]       - 2026-02-14
### Added
- **Name Formatting Presets** - Replaced the free-text name format input with a dropdown menu offering preset options (Name (Character), BattleTag (Character), Nickname (Character), Character Only, Name Only). A "Custom..." option is still available for advanced users who want to use wildcards. All wildcards (%name%, %character%, %level%, %zone%, %class%, %game%, %note%, %nickname%, %battletag%, %realm%) are available in both name and info formats. 
- **Friend Info Formatting** - Added a new setting to customize the second line of friend entries (the info line showing level, zone, etc.). Choose from presets like Default, Zone Only, Level Only, Class/Zone, Game Name, or create a custom format using wildcards. Selecting "Disabled" hides the info line entirely and reduces button height to save space.

### Changed
- Character names are now rendered entirely through the formatting system instead of being appended separately, giving full control over their placement and formatting.

### Fixed
- **RAF Overhaul** - Reworked the Recruit-A-Friend tab to closely match Blizzard's official implementation. Recruit list entries are now left-aligned, use version-specific icons and colors, and show the correct status text. Tooltips, reward descriptions, and month counts now display the same text as Blizzard's default UI. Repeatable rewards (e.g. Game Time) now correctly show their claim count. The reward panel now reliably opens to the active RAF season instead of occasionally pulling from an inactive one.
- **RAF Activity Tooltips** - Fixed RAF activity tooltips not matching Blizzard's tooltip style. Now uses the correct tooltip frame for quest reward display and properly shows a loading indicator while quest data is retrieved.
- **RAF Reward Icon** - Fixed the next reward icon always appearing fully saturated. It now properly shows as desaturated when the reward is not yet affordable, matching Blizzard's behavior.
- **RAF Recruitment Link** - Fixed the Recruit-A-Friend recruitment link popup not displaying properly when opened from the BetterFriendlist RAF tab.
- **Search on All Tabs** - The search box now works on the Recent Allies and Recruit-A-Friend tabs in addition to the Friends tab. Each tab shows a fitting placeholder text and switching tabs clears the current search.
- **Accent-Insensitive Search** - Searching for "Hayato" now also finds friends named "Hâyato", "Hàyató", etc. Accented characters are treated as their base letter during search.
- **Friend Search with Real Names** - Friend search now properly skips privacy-protected Real Names (a Blizzard limitation) instead of silently failing. Nicknames are now also included in search results.
- **Who Frame Level Alignment** - Fixed the Level column in the Who search results not aligning with its column header.
- **Blizzard Raid Frame Interaction** - Fixed empty raid member slots retaining stale unit references, which could cause unexpected interactions with Blizzard's default raid frame.
- **Raid Info First-Click Ghost Buttons** - Fixed Blizzard's raid member buttons briefly appearing when clicking the Raid Info button for the first time after a /reload.

### Removed
- **Activity Tracker** - Removed the Activity Tracker feature (last whisper/group/trade timestamps) to fix a critical error caused by addon taint in the chat system on WoW 12.0+. The "Recent Activity" sort option has also been removed.

## [2.3.5]       - 2026-02-13
### Fixed
- **Settings Import Failing** - Fixed settings import always failing with "corrupted string" error, making it impossible to restore exported backups.
- **Settings Import Not Fully Replacing Data** - Fixed settings import not removing groups or settings that were created after the export. Importing a backup now fully restores the exact state from the export.

## [2.3.4]       - 2026-02-12
### Fixed
- **Streamer Mode Real ID Leaks** - Fixed several places where Real IDs could still be visible despite Streamer Mode being active:
  - Friend tooltip in Classic showed Real ID instead of BattleTag.
  - Data Broker tooltip showed Real ID for friends not currently playing WoW.
  - Recruit-A-Friend tab showed Real IDs without respecting Streamer Mode.
  - FriendListColors addon integration received unmasked Real IDs.
  - Copy Name popup could fall back to Real ID.
  - Drag ghost text could show Real ID when dragging a friend.

## [2.3.3]       - 2026-02-11
### Added
- **Note Cleanup Wizard** - Added a new wizard (Settings -> Advanced) to clean up FriendGroups-style note suffixes (#Group1#Group2) from friend notes. Features a searchable table showing Account Name, BattleTag, Original Note and Cleaned Note with inline editing. Supports both BNet and WoW friends. Includes automatic backup before applying changes. Per-row status icons (pending/success/error) with traffic-light colored backgrounds provide real-time visual feedback during the cleanup process. Respects Streamer Mode by masking Real IDs in the Account Name column and search filter.
- **Note Backup Viewer & Restore** - Added a backup viewer (Settings -> Advanced) to inspect all backed-up friend notes side-by-side with current notes. Changed notes are highlighted. The restore process uses sequential per-row status icons (pending/success/error) with traffic-light colored backgrounds, matching the Cleanup Wizard's visual feedback. Includes a Backup button to create new backups directly from the viewer.
- **Group Note Sync** - Added a new setting (Settings -> Advanced) to automatically sync group assignments to friend notes using the FriendGroups format (Note#Group1#Group2). Groups are ordered by their configured group order. Changes to group membership, group order, or external note modifications (e.g., via Note Cleanup Wizard) are automatically detected and corrected. Respects BNet (127 char) and WoW (48 char) note limits. Includes a confirmation dialog when enabling. Shows a live progress indicator ("Syncing notes: x / y") below the checkbox during the initial sync. Supports both BNet and WoW friends.

### Changed
- **Data Broker Tooltip Library** - Migrated the Data Broker tooltip from LibQTip-1.0 to LibQTip-2.0.

### Fixed
- **QuickJoin Secret Values** - Fixed a crash (`attempt to perform boolean test on field 'autoAccept'`) caused by Patch 12.0.0 (Midnight) where certain group finder fields (autoAccept) became secret and caused security violations when used in boolean checks.
- **Non-WoW Game Info Text** - Fixed friend info text for non-WoW games (Overwatch, Diablo, Hearthstone, etc.) showing raw client program codes (e.g., "Pro", "D4", "WTCG") instead of the rich presence text (e.g., "Competitive: In Game", "Greater Rift", "Ranked: In Game") like Blizzard's default UI does.
- **Empty Account Name for BattleTag-Only Friends** - Fixed BNet friends with empty `accountName` (kString) showing a blank display name instead of falling back to the short BattleTag. Now follows Blizzard's `BNet_GetBNetAccountName` pattern: if accountName is nil, empty, or "???", the short BattleTag (before #) is used as fallback.
- **Top Tab State Not Reset on Reopen** - Fixed a bug where closing the friends list while on the Recent Allies or RAF tab and reopening it would show the Friends tab as selected but display the content of the previously viewed tab. The top tab (FriendsTabHeader) state is now properly reset when reopening.
- **QuickJoin Crash During Combat (Issue #44)** - Fixed a crash caused by Patch 12.0.0 Secret Values when `C_LFGList.GetSearchResultInfo()` returns secret field values during combat lockdown (e.g., M+ keys). Implemented a Secret-Passthrough mode that stores and displays secret values directly (group title, leader name, member count, activity name/icon) instead of discarding them. Forbidden operations (comparisons, iteration) are safely skipped.
- **Group Count Font Size** - Fixed the Group Count text (e.g. "(3/10)") not respecting the global Group Header font size setting. Root cause: when the Group Name and Group Count were split into separate FontStrings for independent color support, the Count FontString received a hardcoded 12pt font override that was not properly cleared by subsequent font sync calls.
- **Assist All Checkbox** - Fixed an issue not disabling the 'Assist All' checkbox and its label when the player isn't raid leader.

### Performance
- **QuickJoin Module Optimizations** - Fifth iteration of performance fixes added. If anything feels odd don't hesitate to contact.

## [2.3.2]       - 2026-02-10
### Fixed
- **Midnight API Fix** - Fixed `C_RestrictedActions.IsAddOnRestrictionActive` error caused by missing required `Enum.AddOnRestrictionType` argument (API changed in 12.0.0).
- **Rendering Delay After Login/Reload** - Fixed a noticeable delay where groups appeared empty (with zero counts) before friends populated after `/reload` or login. Root cause was `BNGetNumFriends()` temporarily returning 0 while BNet reconnects, triggering a premature empty render.

---

*Older versions archived. Full history available in git.*
