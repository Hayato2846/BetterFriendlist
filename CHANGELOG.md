# Changelog

All notable changes to BetterFriendlist will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [2.3.2]       - 2026-02-10
### Fixed
- **Midnight API Fix** - Fixed `C_RestrictedActions.IsAddOnRestrictionActive` error caused by missing required `Enum.AddOnRestrictionType` argument (API changed in 12.0.0).

## [2.3.1]       - 2026-02-10
### Special Thanks
- Huge shoutout to **R41z0r** again for another round of testing my addon <3
### Added
- **Context Menu Integration** - Added BFL options (Set Nickname, Groups, etc.) to friend right-click menus even when not opened from BFL (e.g. from chat links), provided the player is a recognized friend.
- **Favorite Icon Style** - Added a setting to choose between BFL and Blizzard favorite icons (with icon previews) in Retail.

### Changed
- **Font Dropdown UX** - Font dropdowns now use single-check checkbox menus so the current selection stays visible without reopening. Font dropdowns now preview the font.
- **Settings Layout** - Moved "Show Welcome Message" above Favorite Icon controls.
- **Favorite Icon Spacing** - Adjusted favorite icon sizing/padding in compact mode to keep names aligned.

### Fixed
- **UI Taint / Action Forbidden** - Fixed critical errors ("Action Forbidden") that could break the ESC key or Chat functionality during combat. Removed a conflict with Blizzard's window management system.
- **Localization** - Fixed capitalization in context menu headers ("BetterFriendList" -> "BetterFriendlist") for consistency.
- **Group Rename Display** - Fixed an issue where renaming groups (including built-in groups like "Favorites" or "No Group") would not visually update until a full UI reload.
- **Built-in Group Renames** - Fixed inconsistent behavior when renaming built-in groups like "In-Game" so changes are reflected correctly.
- **Settings Frame Viewport** - Fixed an issue where the Settings frame could be dragged outside the visible screen area. Frame is now clamped to screen boundaries.
- **Invite Group (Party Check)** - Fixed "Invite All to Party" to skip friends who are already in your party/raid or playing a different WoW version (e.g., Classic friends when you're on Retail).
- **Invite Group (Empty Groups)** - Fixed "Invite All to Party" context menu option to only appear when the group has invitable friends (online, same WoW version, not in party). The button shows the invitable count.
- **Story Mode Raid Tab** - Fixed the Raid tab to be properly disabled when in Story Mode instances (like Blizzard's FriendsFrame). Uses official `DifficultyUtil.InStoryRaid()` API. Disabled tab shows tooltip explaining why.
- **Dynamic Row Height** - Fixed friend list rows to dynamically adjust height based on font size settings, preventing text overlap at larger font sizes.
- **Group Color Picker Alpha** - Added alpha (transparency) support to all group color pickers (main color, count color, arrow color) allowing semi-transparent group colors.
- **Show Faction Icons** - Fixed the setting so faction icons display correctly when enabled.
- **Show Collapse Arrow** - Fixed the setting so collapse/expand arrows show when enabled.
- **Raid Right-Click MT/MA** - Fixed raid context menu options for Main Tank/Main Assist not working.
- **ElvUI Skin (Context Menus)** - Removed redundant context menu skinning code since ElvUI already handles this globally.
- **ElvUI Skin (Missing Hooks)** - Added ElvUI skinning for Checkbox+Dropdown rows (e.g. Favorite Icon), Input fields (e.g. Streamer Mode custom text), and Button rows that were previously unskinned.
- **Favorite Icon Cache** - Fixed favorite star icons incorrectly appearing on offline WoW friends due to a ScrollBox button recycling issue.
- **Assist All** - Fixed Assist All not showing assistant crown for raid players.
- **Tabs Resizing** - Improved Tabs resizing when using big font sizes.

## [2.3.0]       - 2026-02-07
### Special Thanks
- Huge shoutout to **R41z0r** for testing the shit out of my addon. He's awesome and so is his addon EQOL <3

### Added
- **Raid Tab** - Added Convert To Raid / Convert To Party button to raid tab.
- **Login Message Setting** - Added new setting to enable/disable BFL's login message.
- **Raid Shortcuts** - Added two new Raid Shortcuts for setting Raid Leader and Assistant
- **Raid Settings** - Added new Raid Tab in Settings. You can enable/disable and change the actual shortcut used for the four actions BFL supports.
- **Raid Help Frame** - Added descriptions for both new shortcuts. The text reflects what you have setup in Raid Settings.
- **Copy Dialogs** - Added auto-close function when Ctrl+C is pressed.
- **Translations** - Added new translations, fixed some awkward translations.
- **Groups Scrollbar** - Added Scrollbar for right-click menu for friends -> groups so that a massive list of created groups doesn't grow out of the screen.
- **Frame Clamped** - Added ClampedToScreen protection so that the friendlist window can't move out of screen.
- **Position Reset Command** - For any edge-case scenarios the command `/bfl reset` was added. It resets frame position, width, height and scale.

### Changed
- **Changelog** - Improved the "NEW" indicator on the changelog menu button to use a cleaner, native-style tag with less padding (Retail).
- **RAF Visibility** - Added RAF visibility check.
- **Copy Character Name** - Replaced all 'Copy Character Name' right-click menu options with BFL-native options. Please be aware that copying natively to clipboard is protected and a copy dialog variant is the only way to achieve it for addons.
- **Create/Rename Group** - Dialog for creating/renaming a group now checks if the given name is already used.
- **Groups Setting Fixes** - Added outline to groups color elements in settings, removed highlight hover effect, fixed inherit functions, standardized padding between elements, fixed missing translation key for renaming groups
- **Font Settings** - Removed options Font Outline and Font Shadow for now. Will be added again in a later update.
- **Group Header Counts** - Changed possible values to Filtered / Total, Online / Total, Filtered / Online / Total
- **Sorter** - Selected primary sorter can't be used as secondary sorter anymore, e.g. sorting by Name & Name doesn't make sense.
- **Empty Groups** - Changed default behaviour of empty groups so these will be shown when 'Hide Empty Groups' setting is disabled.
- **Simple Mode** - Removed empty spaces around the SearchBar.
- **Settings Visibility** - Data Broker and Global Sync options are now hidden when the features aren't enabled.
- **Send Message Button** - Send Message Button is disabled when you select a offline WoW friend.
- **Group Order Drag and Drop** - Changed group ordering in settings to use drag and drop instead of up and down buttons.
- **Data Broker Column Drag and Drop** - Changed data broker column ordering in settings to use drag and drop instead of up and down buttons.
- **Drag and Drop Ghosting** - Added a ghosting effect when you use drag so that you know what/who you're dragging!

### Fixed
- **Tab Width Calculation** - Fixed dynamic tab width calculation when toggling Streamer Mode.
- **Layouting** - Fixed and standardized layout of UI elements.
- **RAF Label** - Removed redundant friend label.
- **Changelog** - Fixed date alignment.
- **SearchBar Visibility** - Fixed SearchBar visibility in Normal Mode when swapping tabs.
- **Recent Allies Information** - Changed display of Recent Allies information to a approach closer to Blizzard's view of Recent Allies.
- **Recent Allies Rendering** - Fixed flickering of some Recent Allies elements.
- **Recent Allies Positioning** - Changed element positioning to better align character information and pipes.
- **Beta Fixes** - Added some new API Calls so that deprecated API isn't used anymore in WoW Midnight Beta, e.g. BNSetAFK().
- **Ignore List Label** - Fixed visibility of ignored label showing when you no entries in ignore list.
- **Groups Setting Layout** - Fixed Groups Setting layout cropping UI elements.
- **Streamer Mode Tooltip** - Fixed Streamer Mode tooltip enabled/disable state not updating properly after toggling the mode by pressing the button.
- **ColorPicker** - Fixed some lua errors and added proper color reset.
- **Global Sync** - Fixed a bug not saving note changes in Global Sync tab for friends.
- **Who List** - Fixed selection in who list, fixed sorting, fixed caching.
- **Performance** - Fourth iteration of performance fixes added. If anything feels odd don't hesitate to contact.
- **Streamer Mode (Classic)** - Fixed Streamer Mode in Classic not showing settings and button.
- **Friend Width Calculation (Classic)** - Fixed friend font string width calculation not properly updating in classic after changing the width of the friendlist.

## [2.2.9]       - 2026-02-03
### Fixed
- **Friend Button Layout** - Fixed an issue where Friend Name and Friend Info would not resize properly after adjusting Width via Settings.
- **Database Initialization** - Fixed a database initialization error.
- **QuickFilters** - Fixed a QuickFilter database issue causing filters to not update properly.

## [2.2.8]       - 2026-02-02
### Added
- **Streamer Mode** - Added Streamer Mode! When enabled you can toggle streamer mode to hide friend informations like Real IDs or your own battletag for privacy reasons. Real IDs will be hidden for following UI elements: Friend Name, Friend Tooltip, QuickJoin. You can change your own BattleTag with custom text in settings.
- **Favorite Icons** - Added an option to toggle the star icon for favorites directly on the friend button (Settings -> General). While enabled, favorite friends will be sorted above other friends in the same sorting subgroup.
- **Faction Backgrounds** - Added an option to show faction-colored backgrounds (Blue/Red) for friends in the list (Settings -> General).
- **Friend List Colors Support** - Automatically disables Name Format settings when "FriendListColors" addon is detected. When Friend List Colors is enabled all the name formatting actions will be led by the addon (Streamer Mode excluded).
- **Settings Layout** - Updated settings layout to better support future categories.
- **More Font Settings** - Added Font Settings for Tab Texts and Raid Player Name.
- **Window Lock Option** - Added option to lock the window to prevent moving it accidentally.

### Changed
- **Global Sync** - Global Sync is now flagged as stable feature and can be used without enabling beta features in BFL.

### Removed
- **Edit Mode** - Abandoned BFL's Edit Mode Support for now. Settings for width, height and scale can be found in settings instead. If the position, width, height or scale is different after the update please adjust it again - I wasn't able to restore all variants of Edit Mode Profiles to my settings. Sorry for the inconvenience!
- **Notification System** - Removed Notification Beta System for now. Might be added again in the future

### Fixed
- **Broker Tooltip** - Resolved an issue where the tooltip would not display correctly with display addons like ChocolateBar.
- **ElvUI Skin** - Fixed a Lua error ("index field 'BFLCheckmark'") that could occur when other addons (like ToyBoxEnhanced) create menus that BetterFriendlist tries to skin.
- **Groups Cache** - Fixed an issue with groups caching sometimes not updating properly when changing groups of a friend.

## [2.2.7]       - 2026-01-31
### Fixed
- **Library** - Fixed potential issues with LibQTip library integration.

## [2.2.6]       - 2026-01-31
### Added
- **Copy Character Name** - Added a new option to the context menu to copy character names (Name-Realm) for better inviting/messaging
- **Simple Mode** - Added Simple Mode in Settings -> General. Simple Mode hides specific elements (Search, Filter, Sort, BFL Avatar) and moves corresponding functions in the menu button
- **ElvUI Skin Tabs** - Improved alignment of tab text and overall layout of all tabs of BFL in ElvUI Skin

### Fixed
- **Friend Groups Migration** - Fixed an issue with FriendGroups Migration for WoW friends. Added more debug logs to better help with issues.
- **ElvUI Skin Retail** - Fixed an error with ElvUI Retail Skinning
- **ElvUI Skin Classic** - Fixed and enabled ElvUI Classic Skin
- **QuickJoin Informations** - Fixed an issue with shown QuickJoin informations lacking details of queued content type
- **Broker Integration** - Fixed an issue that disabled the Broker BFL Plugin
- **Performance** - Third iteration of performance added. If anything feels odd don't hesitate to contact
- **RAF** - Fixed an issue blocking the usage of copy link button in RAF Frame
- **Global Sync** - Fixed an error occuring while having own characters in sync added

## [2.2.5]       - 2026-01-25
### Fixed
- **Combat Blocking Fix** - Fixed a critical issue where the Friends List window could not be opened during combat, even when UI Panel settings were disabled. This resolves the "ADDON_ACTION_BLOCKED" error caused by unnecessary secure templates.
- **Localization** - Fixed encoding issues in English localization (enUS) where bullets and arrows were displayed as corrupted characters.

## [2.2.4]       - 2026-01-25
### Fixed
- **Mojibake Fix** - Fixed an issue where localized text (German, French, etc.) could display incorrect characters. (Core.lua)
- **QuickJoin** - Fixed quick join tooltips.
- **Edit Mode** - Fixed visibility issues when entering Edit Mode.

## [2.2.3]       - 2026-01-25
### Added
- **Typography Settings** - Added detailed font customization for Friend Names, Friend Info, and Group Headers. (Shadow settings coming soon).
- **Ignore List Enhancements** - Added support for "Global Ignore List" addon in our improved Ignore List frame, including a quick-toggle button.
- **Settings Overhaul** - Started restructuring the Settings panel for better organization. More improvements to come!
- **Group Visuals** - Added color customization for Group Collapse Arrows and Group Member Counts.
- **Classic Visuals** - Improved the visual design of collapse and expand arrows for group headers in Classic versions.

### Fixed
- **Edit Mode Stability** - Fixed an issue where opening Edit Mode immediately on startup (by other addons) would show BFL in an invalid state if no friend data was present.
- **Classic Localization** - Fixed missing localization keys for the Ignore List in Classic versions.
- **Visual Consistency** - Fixed the default friend name color to perfectly match Blizzard's standard UI color.
- **Quick Join Tooltips** - Fixed the "Request to Join" tooltip on travel pass buttons to show the correct group information.
- **Migration Notifications** - Fixed a bug where the "Migration Successful" message would appear after every UI reload.
- **Performance** - Implemented the second iteration of performance fixes for smoother scrolling and updates.
- **Housing System** - Fixed an issue preventing players from visiting friends' houses.
- **Startup Stability** - Fixed an issue where BetterFriendlist would remain open if other addons forcibly entered and exited Edit Mode during startup.
- **Combat Protection** - Added combat protection for UI Panel attributes.
- **Activity Tracker** - Added secret value protection in ActivityTracker for Midnight.

---

*Older versions archived. Full history available in git.*
