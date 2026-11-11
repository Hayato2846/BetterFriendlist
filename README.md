<h1 align="center">BetterFriendlist</h1>

<p align="center"><strong>The social window I always wanted World of Warcraft to have.</strong></p>

<p align="center">
  <a href="https://www.curseforge.com/wow/addons/betterfriendlist"><img src="https://img.shields.io/badge/CurseForge-Download-f16436?logo=curseforge&logoColor=white" alt="Download on CurseForge"></a>
  <a href="https://addons.wago.io/addons/betterfriendlist"><img src="https://img.shields.io/badge/Wago-Download-c1272d" alt="Download on Wago"></a>
  <a href="https://www.wowinterface.com/downloads/info26984-BetterFriendlist.html"><img src="https://img.shields.io/badge/WoWInterface-Download-2e8bce" alt="Download on WoWInterface"></a>
  <a href="https://discord.gg/dpaV8vh3w3"><img src="https://img.shields.io/badge/Discord-Community-5865f2?logo=discord&logoColor=white" alt="Join the Discord community"></a>
</p>

WoW's default Friends frame is fine when your list is short. Once it fills up with Battle.net contacts, alts, guildmates, raid regulars, and people you met once three expansions ago, finding the right person becomes a small project of its own.

BetterFriendlist started with a simple idea: the Friends frame should help you remember **who people are and what you play together**. From there it grew one everyday annoyance at a time: groups, tags, nicknames, better search and sorting, guild and raid tools, Quick Join, a proper Who list, and plenty of ways to make the window feel like your own.

It is meant to feel familiar on the first login. You can keep the Blizzard look and use the defaults, or tune almost every part of the experience if that is your thing.

## What BetterFriendlist does

### Organize the people you actually play with

- **Custom groups** — Create as many groups as you need, give them names and colors, assign friends to more than one group, and reorder everything with drag and drop.
- **Useful automatic groups** — Favorites, In-Game, Recently Added, and No Group keep important contacts visible without extra upkeep. Their visibility, order, names, and colors can be adjusted.
- **Friend tags** — Use Blizzard-compatible interests and roles or create your own tags. Tags can have custom labels, icons, colors, and visibility rules, appear as compact chips, participate in search, or form dynamic groups without changing friend notes.
- **Nicknames** — Give WoW and Battle.net friends a name that means something to you. Nicknames are used consistently in the list, tooltips, menus, and supported guild and Broker views.
- **Bulk actions** — Select several friends at once to update group or tag assignments together.
- **Import, export, and migration tools** — Move group data between installations, import an existing FriendGroups setup, and clean old FriendGroups markers from notes with backup and restore support.

### Find the right person quickly

- **Live search** checks real names, BattleTags, character names, nicknames, notes, realms, and enabled friend tags.
- **QuickFilters** cover everyday views such as Online, Offline, WoW, Battle.net, In-Game, Hide AFK, and supported queue states.
- **Primary and secondary sorting** can combine status, name, level, zone, game, faction, guild, class, or realm.
- **Custom QuickFilters and sorters** can be built from detailed rules when the optional beta editor is enabled.
- **Custom name and info formats** let you decide exactly what each friend row says. Presets handle the common layouts, while tokens such as `%nickname%`, `%character%`, `%realm%`, `%level%`, `%zone%`, `%class%`, and `%game%` cover the rest.

### Choose how the window should feel

On supported Retail clients, players can switch between two complete interfaces:

- **Modern** follows Blizzard's current Social UI with friend cards and a configurable side navigation. Tabs can be reordered, hidden, or shown only when they contain something useful.
- **Legacy** keeps the familiar BetterFriendlist layout and is also the standard interface on Classic clients.

Both styles share the same friends, groups, tags, and settings. Switching does not require starting over.

There is also a **Simple Mode** for a quieter frame, a **Compact Mode** for denser lists, and detailed controls for window size, scale, position, fonts, colors, row contents, group headers, icons, and click behavior.

Five visual themes are available:

- Blizzard
- Dark
- Custom, with its own color palette and opacity controls
- ElvUI, when ElvUI is installed
- EllesmereUI, when EllesmereUI skinning is available

### Keep the rest of WoW's social tools close

BetterFriendlist is more than a reskinned list. Depending on the game client and the APIs Blizzard provides, the same window can also bring together:

| Area | What it adds |
| --- | --- |
| **Friend Requests** | Review incoming requests in the same interface as the rest of your friends. |
| **Recent Allies** | Find players you recently grouped with, including pinned and converted legacy contacts on supported Retail clients. |
| **Quick Join** | Browse groups your friends are forming, see who is involved, and request an invite. Available on Retail. |
| **Recruit A Friend** | Keep Blizzard's recruit list, rewards, and recruitment actions connected to the main social window. Available on Retail. |
| **Guild** | An optional guild roster with search, online filters, sorting, nicknames, member details, and supported guild-management actions. Currently a beta feature. |
| **Who** | A rebuilt `/who` view with responsive columns, class and level coloring, search history, configurable double-click actions, and a search builder for names, levels, guilds, zones, races, and classes. |
| **Ignore & Broadcast** | Blizzard's related social windows remain reachable and are positioned and themed alongside BetterFriendlist where supported. |

Features tied to a specific Blizzard system are only shown on clients that provide that system. The rest of the addon continues to work normally.

## Raid tools

The built-in raid roster shows all eight raid groups at once, with class colors, class and role icons, leader and assistant ranks, Main Tank and Main Assist markers, Master Looter, ready-check results, and live role counts.

Raid leaders and assistants can:

- Drag individual players between groups or use multi-selection for bulk moves.
- Assign configurable modifier-click shortcuts for Main Tank, Main Assist, Raid Leader, and Assistant.
- Sort the roster by role, split it into balanced halves or odd/even groups, preserve selected groups, and optionally balance DPS.
- Resume an interrupted roster operation after combat.
- Promote tanks together or let **Auto Raid Assist** promote selected friends and characters when they join.
- Start a ready check and open saved raid information directly from the roster.

WoW's combat and permission restrictions still apply; BetterFriendlist will pause or disable actions when the game does not allow them.

## Broker displays

BetterFriendlist provides separate **Friends** and **Guild** LibDataBroker objects for display addons such as Titan Panel, Bazooka, Arcana, ChocolateBar, and similar tools.

The Broker tooltips can show grouped and sortable contact lists, online totals, friend tags, status and game details, guild ranks, zones, notes, last-online information, and configurable columns. Click actions and tooltip appearance can be tailored independently from the main frame.

## Privacy and syncing

- **Streamer Mode** replaces Real IDs with BattleTags, nicknames, or notes throughout BetterFriendlist so a stream or recording does not reveal personal names.
- **Private Notes** can store your own context for friends and ignored players without writing it into Blizzard's public friend-note field. This feature is opt-in.
- **Global Friend Sync** can keep WoW friends available across characters and realms on the same account. Deletion syncing is a separate opt-in setting.
- **FriendGroups note sync** is available for people who still share group assignments through the established FriendGroups note format.

Personal groups, custom tags, private notes, nicknames, and settings are stored in BetterFriendlist's local SavedVariables. Optional integrations such as CustomNames may share the relevant data through their own local libraries.

## Addon compatibility

BetterFriendlist includes dedicated support for several popular UI and social addons, including:

- ElvUI, EllesmereUI, AddOnSkins, and LibSharedMedia
- CustomNames and FriendListColors
- Global Ignore List and EnhanceQoL's Ignore List
- Total RP 3
- Northern Sky Raid Tools
- LibDataBroker display addons

The optional **BetterFriendlist Menu Bridge** can expose supported actions from compatible addons inside BetterFriendlist context menus. Because modern WoW protects some social data and actions, this integration is deliberately opt-in and only appears where it can operate safely.

## Retail and Classic support

BetterFriendlist is maintained from one shared codebase for Retail and the supported Classic families. That currently includes Retail 11.x and 12.x clients, Classic Era/Anniversary, and supported Classic progression clients.

The addon checks for capabilities instead of assuming every client has the same APIs. Retail-only features such as Quick Join, Recent Allies, Recruit A Friend, and the Modern Social UI stay out of the way on Classic, while groups, search, sorting, Who, guild tools, raid tools, themes, and the Legacy interface adapt to the client where supported.

For the exact game versions attached to the latest release, see the file list on [CurseForge](https://www.curseforge.com/wow/addons/betterfriendlist/files), [Wago](https://addons.wago.io/addons/betterfriendlist), or [WoWInterface](https://www.wowinterface.com/downloads/info26984-BetterFriendlist.html).

## Localization

BetterFriendlist is fully localized in 11 languages:

- English
- German
- French
- Spanish (Europe and Latin America)
- Italian
- Portuguese (Brazil)
- Russian
- Korean
- Chinese (Simplified and Traditional)

## Installation and first steps

The easiest option is to install BetterFriendlist through [CurseForge](https://www.curseforge.com/wow/addons/betterfriendlist), [Wago](https://addons.wago.io/addons/betterfriendlist), or [WoWInterface](https://www.wowinterface.com/downloads/info26984-BetterFriendlist.html).

For a manual installation:

1. Download the latest release and extract it.
2. Place the `BetterFriendlist` folder in `World of Warcraft\_retail_\Interface\AddOns` or the matching folder for your Classic client.
3. Enable BetterFriendlist on the character-selection screen and log in.

Open the social window normally or type `/bfl`. Use `/bfl settings` to jump straight to the options. On supported Retail clients, the first-run setup helps you choose an interface style and theme; every choice can be changed later.

## Feedback and support

BetterFriendlist has grown through real use, bug reports, and the little annoyances people notice only after opening the Friends frame for the thousandth time. If something feels awkward, does not work on your WoW client, or would save you a few clicks every day, I would genuinely like to hear about it.

- [Join the Discord community](https://discord.gg/dpaV8vh3w3) for help, feedback, and discussion.
- [Open a GitHub issue](https://github.com/Hayato2846/BetterFriendlist/issues) for reproducible bugs and feature requests.
- [Support development on Ko-fi](https://ko-fi.com/hayato2846) if BetterFriendlist has made your time in WoW a little easier.
- Read the [changelog](CHANGELOG.md) for recent additions and fixes.

BetterFriendlist is maintained by [Hayato2846](https://github.com/Hayato2846) and distributed under the terms in the [license](LICENSE).
