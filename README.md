# BetterFriendlist

[![WoW Version](https://img.shields.io/badge/Retail-11.x_%7C_12.x-blue)](https://worldofwarcraft.com)
[![Classic Version](https://img.shields.io/badge/Classic-Era_%7C_Cata_%7C_MoP-orange)](https://worldofwarcraft.com)
[![Discord](https://img.shields.io/badge/Discord-Join_Us-7289da?logo=discord&logoColor=white)](https://discord.gg/dpaV8vh3w3)
[![Ko-fi](https://img.shields.io/badge/Ko--fi-Support_me-ff5e5b?logo=ko-fi&logoColor=white)](https://ko-fi.com/hayato2846)

A complete replacement for WoW's default Friends frame. Groups, nicknames, raid management, a proper WHO list, Quick Join, and a lot more - all in one addon that works on Retail and Classic.

## Features

### Friend Management

*   **Custom Groups** - Create as many groups as you want, give them names and colors, and drag friends between them. Reorder groups by dragging their headers.
*   **Favorites and In-Game** - A pinned Favorites group and a dynamic "In-Game" group that automatically collects friends playing the same game.
*   **Nicknames** - Assign a personal nickname to any friend, independent of their note. Nicknames show up everywhere: the list, tooltips, context menus.
*   **Multi-Select** - Hold Shift to select multiple friends at once for bulk group assignment.
*   **Global Sync** - Your group assignments carry over between characters and connected realms automatically.

### Sorting and Filtering

*   **Dual Sort** - Primary and secondary sort by Status, Name, Level, Zone, Game, Faction, Guild, Class, or Realm.
*   **Quick Filters** - One-click buttons to show only Online, Offline, WoW friends, Battle.net friends, and more.
*   **Search** - Real-time search across names, character names, notes, and nicknames.

### Name and Info Formatting

BetterFriendlist gives you full control over how friends are displayed. Two independent format strings - **Friend Name** and **Friend Info** - each come with several presets and a fully custom mode using tokens:

**Friend Name** controls the primary line. Presets include "Name (Character)", "BattleTag (Character)", "Nickname (Character)", "Character Only", "Name Only", or "Custom". In custom mode you can combine tokens like `%name%`, `%battletag%`, `%nickname%`, `%character%`, `%note%`, `%realm%`, `%level%`, `%zone%`, `%class%`, `%game%`.

**Friend Info** controls the secondary line below the name. Presets include "Level, Zone", "Zone Only", "Level Only", "Class, Zone", "Level Class, Zone", "Game Name", "Disabled", or "Custom" with the same token set.

Character names can be class-colored automatically, and faction icons (Alliance/Horde) can be shown next to character names.

### Streamer Mode

A privacy toggle that replaces Real IDs with BattleTags (or nicknames, or notes) everywhere in the addon - the friend list, tooltips, and context menus. Useful for streaming or recording without leaking personal information.

### Raid Frame

A full 40-man raid roster built into BetterFriendlist. Members are shown in their raid groups with class colors, class icons and role icons.

*   **Drag and Drop** - Move members between groups by dragging them.
*   **Configurable Shortcuts** - Assign modifier+click combinations to common actions: Main Tank, Main Assist, Promote to Assistant, or Promote to Leader. Each shortcut can be individually enabled or disabled.
*   **Ready Check Display** - Visual ready check status on each member button.

### Quick Join

Browse groups that your friends are currently forming or queued for, and request to join with a single click. Shows which friends are in each group and what roles the group still needs. Available on Retail.

### WHO Frame

A rebuilt WHO list with a cleaner layout and more functionality than the default.

*   **Search Builder** - A flyout panel with dedicated fields for Name, Guild, Zone, Race, and Class instead of remembering Blizzard's cryptic `/who` syntax. Fill in what you want and hit Search.
*   **Responsive Columns** - Name, Level, Class, and a variable column (Zone, Guild, or Race) that adapts to the frame width. Click any column header to sort by it.
*   **Ctrl+Click Filtering** - Ctrl+Click a value in the Zone, Guild, or Race column to instantly search for that value.
*   **Double-Click Actions** - Configurable to either Whisper or Invite the selected player.
*   **Class-Colored Names** - Player names and class columns use class colors. Levels are colored by quest difficulty.

### Customization

*   **ElvUI Skin** - Native ElvUI skinning when ElvUI is detected.
*   **Data Broker** - LDB data object for use with TitanPanel, Bazooka, ChocolateBar, and similar addons. Shows online friend count and a rich tooltip listing all friends with status, game, and character info.

## Language Support

Fully localized in 11 languages:
English, German, French, Spanish (EU/LA), Italian, Portuguese (BR), Russian, Korean, Chinese (Simplified/Traditional).

## Installation

Download from **CurseForge**, **Wago**, or **WoWInterface** and extract to your `Interface\AddOns` folder.

## Support

*   **Discord** - [Join the community](https://discord.gg/dpaV8vh3w3) for support, feedback, and discussion.
*   **GitHub** - [Report bugs or request features](https://github.com/Hayato2846/BetterFriendlist/issues).
*   **Ko-fi** - [Support development](https://ko-fi.com/hayato2846).