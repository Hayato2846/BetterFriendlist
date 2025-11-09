[SIZE=6][B]BetterFriendlist - World of Warcraft AddOn[/B][/SIZE]

[B]Version 1.0[/B] - A complete replacement for WoW's default Friends frame with custom groups, Raid management, and Quick Join support.

[COLOR="RoyalBlue"]WoW 11.2.5 | Stable | MIT License[/COLOR]

[HR][/HR]

[SIZE=5][B]✨ Features[/B][/SIZE]

[SIZE=4][B]🎯 Core Features[/B][/SIZE]
[LIST]
[*][B]Custom Friend Groups[/B] - Organize friends into custom named groups with drag & drop
[*][B]Raid Frame[/B] - Complete 40-man raid management with drag & drop, ready checks, and role assignments
[*][B]Quick Join[/B] - Social Queue system for joining friends' groups with role selection
[*][B]WHO Frame[/B] - Enhanced player search with filters and quick actions
[*][B]Ignore List[/B] - Manage blocked players and invites
[*][B]Recent Allies[/B] - Track players you've recently grouped with
[*][B]Recruit-A-Friend[/B] - Full RAF system with rewards and recruit management
[/LIST]

[SIZE=4][B]🚀 Advanced Features[/B][/SIZE]
[LIST]
[*][B]FriendGroups Migration[/B] - Seamlessly import groups from FriendGroups addon
[*][B]Smart Filtering[/B] - Quick filters (Online, All, WoW, App, Recent, Favorites)
[*][B]Collapsible Groups[/B] - Expand/collapse custom groups
[*][B]Search & Notes[/B] - Search friends by name and manage notes
[*][B]Context Menus[/B] - Right-click menus for all actions
[*][B]Performance Optimized[/B] - Smooth performance with 200+ friends
[/LIST]

[SIZE=4][B]🎨 User Interface[/B][/SIZE]
[LIST]
[*][B]Modern Design[/B] - Clean, Blizzard-style UI matching 11.2.5 aesthetics
[*][B]4-Tab Layout[/B] - Friends, WHO, Ignore, RAF
[*][B]4 Bottom Tabs[/B] - Recent Allies, Quick Join, Raid, Settings
[*][B]Drag & Drop[/B] - Move friends between groups and raid members between groups
[*][B]Visual Indicators[/B] - Status icons, class colors, game icons, faction icons
[*][B]Responsive[/B] - Adapts to different screen sizes
[/LIST]

[HR][/HR]

[SIZE=5][B]📥 Installation[/B][/SIZE]

[SIZE=4][B]Manual Installation[/B][/SIZE]
[LIST=1]
[*]Download the latest release from [URL="https://github.com/Hayato2846/BetterFriendlist/releases"]GitHub[/URL]
[*]Extract to your World of Warcraft AddOns directory:
[CODE]World of Warcraft\_retail_\Interface\AddOns\BetterFriendlist\[/CODE]
[*]Restart WoW or reload UI ([COLOR="Gray"]/reload[/COLOR])
[*]Press [B]O[/B] key or use [COLOR="Gray"]/bfl[/COLOR] to open
[/LIST]

[SIZE=4][B]⚙️ Migrating from FriendGroups[/B][/SIZE]
If you're upgrading from the FriendGroups addon:
[LIST=1]
[*]Keep FriendGroups enabled during migration
[*]Open BetterFriendlist Settings ([COLOR="Gray"]/bfl settings[/COLOR])
[*]Go to [B]Advanced[/B] tab → Click [B]"Migrate from FriendGroups"[/B]
[*]Choose whether to clean up BattleNet notes
[*]After successful migration, disable FriendGroups
[/LIST]

[HR][/HR]

[SIZE=5][B]🚀 Quick Start[/B][/SIZE]

[SIZE=4][B]Opening the Frame[/B][/SIZE]
[LIST]
[*][B]Keyboard:[/B] Press [B]O[/B] key (auto-replaces default Friends frame)
[*][B]Slash Command:[/B] [COLOR="Gray"]/bfl[/COLOR] or [COLOR="Gray"]/betterfriendlist[/COLOR]
[*][B]Blizzard Menu:[/B] Social button still works
[/LIST]

[SIZE=4][B]Creating Your First Group[/B][/SIZE]
[LIST=1]
[*]Click [B]"Create Group"[/B] button at the top
[*]Enter a group name (e.g., "Guild", "Raid Team", "Arena")
[*]Drag & drop friends from the list into your new group
[*]Right-click groups for more options (rename, delete, etc.)
[/LIST]

[SIZE=4][B]Raid Management[/B][/SIZE]
[LIST=1]
[*]Click [B]"Raid"[/B] bottom tab (only visible when in raid)
[*]Drag & drop members between raid groups (requires leader/assistant)
[*]Use Control Panel for ready checks, role polls, difficulty
[*]Click [B]"Raid Info"[/B] to view saved instances
[/LIST]

[SIZE=4][B]Quick Join[/B][/SIZE]
[LIST=1]
[*]Click [B]"Quick Join"[/B] bottom tab
[*]Browse available groups from friends
[*]Click [B]"Join"[/B] → Select your role → Request to join
[*][B]Mock System[/B] for testing: [COLOR="Gray"]/bflqj mock[/COLOR] (creates 3 test groups)
[/LIST]

[HR][/HR]

[SIZE=5][B]📖 Commands[/B][/SIZE]

[SIZE=4][B]Main Commands[/B][/SIZE]
[TABLE="width: 100%"]
[TR]
[TD][B]Command[/B][/TD]
[TD][B]Description[/B][/TD]
[/TR]
[TR]
[TD][COLOR="Gray"]/bfl[/COLOR][/TD]
[TD]Toggle BetterFriendlist frame[/TD]
[/TR]
[TR]
[TD][COLOR="Gray"]/bfl settings[/COLOR][/TD]
[TD]Open settings panel[/TD]
[/TR]
[TR]
[TD][COLOR="Gray"]/bfl help[/COLOR][/TD]
[TD]Show all available commands[/TD]
[/TR]
[TR]
[TD][COLOR="Gray"]/bfl debug print[/COLOR][/TD]
[TD]Toggle debug output (for bug reports)[/TD]
[/TR]
[/TABLE]

[SIZE=4][B]Quick Join Commands (Testing)[/B][/SIZE]
[TABLE="width: 100%"]
[TR]
[TD][B]Command[/B][/TD]
[TD][B]Description[/B][/TD]
[/TR]
[TR]
[TD][COLOR="Gray"]/bflqj mock[/COLOR][/TD]
[TD]Create 3 mock groups for testing[/TD]
[/TR]
[TR]
[TD][COLOR="Gray"]/bflqj clear[/COLOR][/TD]
[TD]Remove all mock groups[/TD]
[/TR]
[TR]
[TD][COLOR="Gray"]/bflqj list[/COLOR][/TD]
[TD]List all mock groups[/TD]
[/TR]
[TR]
[TD][COLOR="Gray"]/bflqj disable[/COLOR][/TD]
[TD]Disable mock mode (use real data)[/TD]
[/TR]
[/TABLE]

[SIZE=4][B]Performance Monitoring (Advanced)[/B][/SIZE]
[TABLE="width: 100%"]
[TR]
[TD][B]Command[/B][/TD]
[TD][B]Description[/B][/TD]
[/TR]
[TR]
[TD][COLOR="Gray"]/bflperf enable[/COLOR][/TD]
[TD]Enable performance monitoring[/TD]
[/TR]
[TR]
[TD][COLOR="Gray"]/bflperf report[/COLOR][/TD]
[TD]Show performance statistics[/TD]
[/TR]
[TR]
[TD][COLOR="Gray"]/bflperf reset[/COLOR][/TD]
[TD]Reset statistics[/TD]
[/TR]
[TR]
[TD][COLOR="Gray"]/bflperf memory[/COLOR][/TD]
[TD]Show memory usage[/TD]
[/TR]
[/TABLE]

[HR][/HR]

[SIZE=5][B]📚 Usage Guide[/B][/SIZE]

[SIZE=4][B]Friends List Tab[/B][/SIZE]
[B]Main Features:[/B]
[LIST]
[*][B]Custom Groups[/B] - Organize friends into named groups
[*][B]Drag & Drop[/B] - Move friends between groups
[*][B]Search[/B] - Find friends by name or note
[*][B]Quick Filters[/B] - Filter by Online, All, WoW, App, Recent, Favorites
[*][B]Sort Options[/B] - Sort by name, status, or last online
[*][B]Context Menus[/B] - Right-click for quick actions (invite, whisper, notes, etc.)
[/LIST]

[B]Tips:[/B]
[LIST]
[*]Right-click group headers to rename or delete
[*]Collapse groups to save space (click arrow icon)
[*]Use Search box (top right) to quickly find friends
[*]Notes are synced with Blizzard's system
[/LIST]

[SIZE=4][B]WHO Frame Tab[/B][/SIZE]
[B]Main Features:[/B]
[LIST]
[*][B]Player Search[/B] - Search for players by name, guild, zone, or race
[*][B]Level Filters[/B] - Min/Max level range
[*][B]Advanced Options[/B] - Guild, race, zone dropdowns
[*][B]Quick Actions[/B] - Right-click to add friend, whisper, invite
[/LIST]

[SIZE=4][B]Raid Frame Bottom Tab[/B][/SIZE]
[B]Main Features:[/B]
[LIST]
[*][B]40-Man Display[/B] - View all 40 raid slots across 8 groups
[*][B]Drag & Drop[/B] - Move members between groups (leader/assistant only)
[*][B]Combat Protection[/B] - Drag disabled during combat (shows overlay)
[*][B]Ready Check[/B] - Initiate ready checks from Control Panel
[*][B]Role Summary[/B] - See tank/healer/DPS count
[*][B]Difficulty[/B] - Change raid difficulty
[*][B]Raid Info[/B] - View saved instances (pop-out window)
[/LIST]

[B]Tips:[/B]
[LIST]
[*]Only visible when in a raid (6+ players)
[*]Drag & drop requires Raid Leader or Raid Assistant
[*]Right-click members for standard raid menu
[*]Raid Info button shows Blizzard's saved instance UI
[/LIST]

[SIZE=4][B]Quick Join Bottom Tab[/B][/SIZE]
[B]Main Features:[/B]
[LIST]
[*][B]Browse Groups[/B] - See available groups from friends
[*][B]Role Selection[/B] - Pick your role (Tank/Healer/Damage) before joining
[*][B]Request to Join[/B] - Send join request with one click
[*][B]Status Tracking[/B] - Shows "Request Sent" when pending
[/LIST]

[B]Mock System (Testing):[/B]
[LIST]
[*][COLOR="Gray"]/bflqj mock[/COLOR] - Create 3 test groups
[*][COLOR="Gray"]/bflqj clear[/COLOR] - Remove test groups
[*][COLOR="Gray"]/bflqj disable[/COLOR] - Switch back to real data
[/LIST]

[HR][/HR]

[SIZE=5][B]🔧 Technical Details[/B][/SIZE]

[SIZE=4][B]Modular Architecture[/B][/SIZE]
BetterFriendlist uses a fully modular architecture with [B]14 independent modules[/B]:

[B]Core Modules:[/B]
[LIST]
[*][B]Database.lua[/B] (151 lines) - SavedVariables management
[*][B]Groups.lua[/B] (398 lines) - Group management logic
[*][B]FriendsList.lua[/B] (1307 lines) - Friends list rendering & display
[*][B]Settings.lua[/B] (955 lines) - Settings UI & migration
[/LIST]

[B]Feature Modules:[/B]
[LIST]
[*][B]RaidFrame.lua[/B] (1029 lines) - Raid management system
[*][B]QuickJoin.lua[/B] (1337 lines) - Social Queue integration
[*][B]RAF.lua[/B] (878 lines) - Recruit-A-Friend system
[*][B]WhoFrame.lua[/B] (507 lines) - WHO search system
[*][B]RecentAllies.lua[/B] (324 lines) - Recent allies tracking
[*][B]IgnoreList.lua[/B] (172 lines) - Ignore list management
[/LIST]

[B]Support Modules:[/B]
[LIST]
[*][B]ButtonPool.lua[/B] (381 lines) - UI button recycling & drag-drop
[*][B]QuickFilters.lua[/B] (130 lines) - Filter logic
[*][B]Dialogs.lua[/B] (178 lines) - StaticPopup dialogs
[*][B]MenuSystem.lua[/B] (83 lines) - Context menus
[/LIST]

[SIZE=4][B]Performance[/B][/SIZE]
[LIST]
[*][B]Button Recycling[/B] - Reuses UI elements for efficiency
[*][B]Update Throttling[/B] - Limits update frequency (1s interval)
[*][B]Caching[/B] - 2-second TTL cache for Quick Join data
[*][B]Event-Driven[/B] - No polling, only event-based updates
[*][B]Lazy Loading[/B] - Only loads visible data
[/LIST]

[B]Benchmarks:[/B]
[LIST]
[*]Friends List: [COLOR="Green"]<20ms[/COLOR] @ 200 friends
[*]Quick Join: [COLOR="Green"]<40ms[/COLOR] @ 50 groups
[*]Raid Frame: [COLOR="Green"]<30ms[/COLOR] @ 40 members
[*]Memory: [COLOR="Green"]~2-3 MB[/COLOR] baseline
[/LIST]

[SIZE=4][B]API Compatibility[/B][/SIZE]
[LIST]
[*][B]WoW Version:[/B] 11.2.5 (Retail/Mainline)
[*][B]APIs Used:[/B] C_FriendList, C_BattleNet, C_SocialQueue, C_RecruitAFriend
[*][B]Protected Functions:[/B] Handled via secure templates & menus
[*][B]Classic Support:[/B] Not planned (uses Retail-only APIs)
[/LIST]

[HR][/HR]

[SIZE=5][B]🤝 Compatibility[/B][/SIZE]

[SIZE=4][B]WoW Versions[/B][/SIZE]
[LIST]
[*]✅ [B]Retail 11.2.5[/B] - Fully supported
[*]❌ [B]Classic[/B] - Not supported (uses Retail-only APIs)
[*]❌ [B]Wrath/Cata[/B] - Not supported
[/LIST]

[SIZE=4][B]AddOn Compatibility[/B][/SIZE]
[LIST]
[*]✅ [B]ElvUI[/B] - Fully compatible
[*]✅ [B]Bartender[/B] - Fully compatible
[*]✅ [B]Shadowed Unit Frames[/B] - Fully compatible
[*]✅ [B]WeakAuras[/B] - Fully compatible
[*]⚠️ [B]Other Friends Frame Replacements[/B] - May conflict (disable one)
[/LIST]

[HR][/HR]

[SIZE=5][B]❓ FAQ[/B][/SIZE]

[B]Q: Why isn't the O key opening BetterFriendlist?[/B]
A: The O key should automatically open BetterFriendlist. If not:
[LIST=1]
[*]Check [COLOR="Gray"]/bfl debug print[/COLOR] - you should see keybind override messages
[*]Try [COLOR="Gray"]/reload[/COLOR] to reinitialize the keybind system
[*]Manually rebind in Keybindings → AddOns → BetterFriendlist
[/LIST]

[B]Q: Can I use this with ElvUI?[/B]
A: Yes! BetterFriendlist is fully compatible with ElvUI and other UI replacements.

[B]Q: Will this work in Classic?[/B]
A: No. BetterFriendlist uses Retail-only APIs (C_SocialQueue, C_RecruitAFriend, etc.) that don't exist in Classic.

[B]Q: How do I migrate from FriendGroups?[/B]
A: See the Installation section above for step-by-step migration instructions.

[B]Q: Does this replace Blizzard's Friends frame?[/B]
A: Yes. When you press O or use social keybinds, BetterFriendlist opens instead of Blizzard's frame.

[B]Q: Why can't I drag raid members during combat?[/B]
A: This is a WoW API restriction. Protected functions like SwapRaidSubgroup() are disabled during combat to prevent exploits.

[B]Q: Quick Join shows "No groups available" - is it broken?[/B]
A: No. Quick Join only shows groups when:
[LIST=1]
[*]Friends have created LFG groups
[*]You're not already in a group
[*]The group is joinable
[/LIST]
Use [COLOR="Gray"]/bflqj mock[/COLOR] to test the UI with fake groups.

[HR][/HR]

[SIZE=5][B]🐛 Troubleshooting[/B][/SIZE]

[SIZE=4][B]Common Issues[/B][/SIZE]

[B]Problem:[/B] O key doesn't open BetterFriendlist
[B]Solution:[/B] [COLOR="Gray"]/reload[/COLOR] or check Keybindings → AddOns → BetterFriendlist

[B]Problem:[/B] Lua errors on login
[B]Solution:[/B]
[LIST=1]
[*]Update to latest version
[*]Enable [COLOR="Gray"]/bfl debug print[/COLOR] and report the error
[*]Check for addon conflicts (disable others temporarily)
[/LIST]

[B]Problem:[/B] Groups not showing after migration
[B]Solution:[/B]
[LIST=1]
[*]Settings → Advanced → Debug Database
[*]Check that groups exist in the output
[*]Try [COLOR="Gray"]/reload[/COLOR]
[/LIST]

[B]Problem:[/B] Raid frame not appearing
[B]Solution:[/B]
[LIST=1]
[*]Must be in a raid (6+ players), not a party
[*]Click "Raid" bottom tab
[*]If still hidden, try [COLOR="Gray"]/reload[/COLOR]
[/LIST]

[B]Problem:[/B] Can't drag raid members
[B]Solution:[/B]
[LIST=1]
[*]Must be Raid Leader or Raid Assistant
[*]Cannot drag during combat (Protected Function restriction)
[*]Combat overlay will appear when in combat
[/LIST]

[SIZE=4][B]Getting Support[/B][/SIZE]

[B]When Reporting:[/B]
[LIST=1]
[*]Post on [URL="https://github.com/Hayato2846/BetterFriendlist/issues"]GitHub Issues[/URL]
[*]Include:
[LIST]
[*]WoW version (e.g., 11.2.5)
[*]Addon version (from .toc or [COLOR="Gray"]/bfl[/COLOR] title bar)
[*]Full error message (from BugSack)
[*]Debug logs (if debug print enabled)
[*]Steps to reproduce
[/LIST]
[/LIST]

[HR][/HR]

[SIZE=5][B]📜 Changelog[/B][/SIZE]

[SIZE=4][B]v1.0 (Current - November 2025)[/B][/SIZE]
[B]🎉 Initial Stable Release - Feature Complete![/B]

[LIST]
[*]✅ [B]Modularization Complete:[/B] 14 modules, ~11,000 lines of code
[*]✅ [B]Friends List:[/B] Custom groups, drag & drop, search, filters
[*]✅ [B]Raid Frame:[/B] 40-man display, drag & drop, ready checks, control panel
[*]✅ [B]Quick Join:[/B] Social Queue integration with mock system
[*]✅ [B]WHO Frame:[/B] Enhanced player search
[*]✅ [B]Ignore List:[/B] Block management
[*]✅ [B]Recent Allies:[/B] Auto-tracking system
[*]✅ [B]RAF:[/B] Recruit-A-Friend integration
[*]✅ [B]Settings:[/B] FriendGroups migration, advanced options
[*]✅ [B]Performance:[/B] Optimized for 200+ friends (<20ms updates)
[*]✅ [B]Keybind System:[/B] Auto-replaces O key binding
[*]✅ [B]Debug Tools:[/B] Debug print toggle, performance monitor
[/LIST]

[HR][/HR]

[SIZE=5][B]🙏 Credits[/B][/SIZE]

[SIZE=4][B]Development[/B][/SIZE]
[LIST]
[*][B]Lead Developer:[/B] Hayato2846
[*][B]AI Assistant:[/B] GitHub Copilot (Claude Sonnet 4.5)
[/LIST]

[SIZE=4][B]Inspiration & Reference[/B][/SIZE]
[LIST]
[*][B]FriendGroups[/B] - Original custom groups addon concept
[*][B]Blizzard_FriendsFrame[/B] - Reference implementation (11.2.5)
[*][B]Cell[/B] - Raid frame drag & drop inspiration
[/LIST]

[SIZE=4][B]Special Thanks[/B][/SIZE]
[LIST]
[*]WoW AddOn Development Community
[*][URL="https://warcraft.wiki.gg"]warcraft.wiki.gg[/URL] - API documentation
[*][URL="https://github.com/Gethe/wow-ui-source"]GitHub Gethe/wow-ui-source[/URL] - Blizzard source code
[*]Beta testers and bug reporters
[/LIST]

[HR][/HR]

[SIZE=5][B]🔗 Links[/B][/SIZE]

[LIST]
[*][B]GitHub:[/B] [URL="https://github.com/Hayato2846/BetterFriendlist"]Hayato2846/BetterFriendlist[/URL]
[*][B]Issues:[/B] [URL="https://github.com/Hayato2846/BetterFriendlist/issues"]Report Bugs[/URL]
[*][B]Releases:[/B] [URL="https://github.com/Hayato2846/BetterFriendlist/releases"]Download[/URL]
[/LIST]

[HR][/HR]

[SIZE=2][COLOR="Gray"][B]Note:[/B] This addon is not affiliated with or endorsed by Blizzard Entertainment. World of Warcraft and Battle.net are trademarks of Blizzard Entertainment, Inc.[/COLOR][/SIZE]
