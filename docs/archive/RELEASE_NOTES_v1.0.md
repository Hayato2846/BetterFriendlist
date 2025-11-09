# BetterFriendlist v1.0 - Release Notes

**Release Date**: November 9, 2025  
**Type**: Major Release - Initial Stable Version  
**Status**: Feature Complete

---

## 🎉 What's New

BetterFriendlist v1.0 is the first stable release, representing **complete feature parity** with Blizzard's Friends frame plus extensive enhancements. This release includes over **11,000 lines of code** across **14 modular components**.

---

## ✨ Major Features

### 🎯 Custom Friend Groups
- Create, rename, and delete custom groups
- Drag & drop friends between groups
- Collapsible groups with member counts
- Visual group dividers in friends list
- Context menus for quick group management

### 🛡️ Raid Frame (40-Man)
- Complete raid management system
- 8 groups × 5 slots = 40 members display
- **Drag & drop** members between groups (leader/assistant only)
- **Combat-aware overlay** - drag disabled during combat
- **Ready Check** system with visual indicators
- **Control Panel**: Ready Check, Everyone Assist, Convert to Raid/Party
- **Raid Info** button - integrates Blizzard's saved instance UI
- Role icons (Tank/Healer/DPS) and rank icons (Leader/Assistant)
- Class colors and status indicators (online/offline/dead)

### 🤝 Quick Join (Social Queue)
- Browse available groups from friends
- **Role selection dialog** (Tank/Healer/Damage)
- Automatic spec detection for role pre-selection
- Request tracking ("Request Sent" status)
- **Mock system** for testing (`/bflqj mock`)
- Combat and group status checks
- Update throttling (1s) and caching (2s TTL)

### 🔍 WHO Frame
- Enhanced player search with filters
- Level range filters (min/max)
- Zone/Guild/Race dropdowns (auto-populated)
- Quick actions: Add friend, whisper, invite
- Real-time results update

### Additional Features
- **Ignore List** - Block players and invites
- **Recent Allies** - Auto-tracking of grouped players
- **Recruit-A-Friend** - Full RAF system integration
- **Search & Filter** - Quick filters (Online, All, WoW, App, Recent, Favorites)
- **Settings Panel** - FriendGroups migration, debug tools

---

## 🚀 Performance

BetterFriendlist is optimized for large friend lists and raid groups:

- **Friends List**: <20ms @ 200 friends ✅
- **Quick Join**: <40ms @ 50 groups ✅
- **Raid Frame**: <30ms @ 40 members ✅
- **Memory Usage**: ~2-3 MB baseline ✅

**Optimization Techniques:**
- Button recycling (ButtonPool system)
- Update throttling (1s intervals)
- Caching with 2s TTL
- Event-driven updates (no polling)
- Lazy loading

---

## 🏗️ Architecture

### Modular Design
14 independent modules totaling ~11,000 lines:

**Core Modules:**
- Database (151 lines) - SavedVariables management
- Groups (398 lines) - Group management
- FriendsList (1307 lines) - Friends list rendering
- Settings (955 lines) - Settings UI & migration

**Feature Modules:**
- RaidFrame (1029 lines) - Raid management
- QuickJoin (1337 lines) - Social Queue
- RAF (878 lines) - Recruit-A-Friend
- WhoFrame (507 lines) - WHO system
- RecentAllies (324 lines) - Recent allies
- IgnoreList (172 lines) - Ignore list

**Support Modules:**
- ButtonPool (381 lines) - UI button recycling
- QuickFilters (130 lines) - Filter logic
- Dialogs (178 lines) - StaticPopup dialogs
- MenuSystem (83 lines) - Context menus

**Utilities:**
- FontManager, ColorManager, AnimationHelpers
- PerformanceMonitor - Performance tracking tool

---

## 📖 Commands

### Main Commands
- `/bfl` - Toggle BetterFriendlist frame
- `/bfl settings` - Open settings panel
- `/bfl help` - Show all commands
- `/bfl debug print` - Toggle debug output

### Quick Join Commands (Testing)
- `/bflqj mock` - Create 3 test groups
- `/bflqj clear` - Remove test groups
- `/bflqj list` - List all mock groups
- `/bflqj disable` - Use real Social Queue data

### Performance Monitoring
- `/bflperf enable` - Enable performance tracking
- `/bflperf report` - Show performance statistics
- `/bflperf reset` - Reset statistics
- `/bflperf memory` - Show memory usage

---

## 🔧 Technical Details

### WoW API Integration
- **Version**: 11.2.5 (Retail/Mainline)
- **APIs Used**: 
  - C_FriendList - Friends management
  - C_BattleNet - Battle.net integration
  - C_SocialQueue - Quick Join system
  - C_RecruitAFriend - RAF integration
- **Protected Functions**: Handled via secure templates & menus
- **Event System**: Modular event callback architecture

### Keybind Override
- **O key** automatically opens BetterFriendlist
- Uses `SetOverrideBinding()` approach (BetterBags-style)
- No ESC conflicts or taint issues
- Manual rebinding still available in Keybindings menu

---

## ⚠️ Known Limitations

### Main Tank/Assist Menu Options (NOT IMPLEMENTED)
**Status**: Cannot be implemented due to WoW API restrictions

**Technical Reason:**
- `SetPartyAssignment()` and `ClearPartyAssignment()` are **Protected Functions**
- These functions require `issecure() == true`
- Addon code always runs in non-secure context
- WoW API restriction, not an addon bug

**Workarounds:**
- Use Blizzard's standard Raid frames for Main Tank/Assist
- Use slash commands: `/maintank <name>` and `/mainassist <name>`
- All other raid-frame addons have the same limitation

### Classic Support
- **Not planned** - uses Retail-only APIs (C_SocialQueue, C_RecruitAFriend)
- Would require complete API rewrite for Classic compatibility

---

## 🔄 Migration from FriendGroups

If you're upgrading from FriendGroups:

1. Keep FriendGroups enabled during migration
2. Open BetterFriendlist Settings (`/bfl settings`)
3. Go to **Advanced** tab
4. Click **"Migrate from FriendGroups"**
5. Choose whether to clean up BattleNet notes
6. After successful migration, disable FriendGroups

📖 **Detailed Guide**: See [FRIENDGROUPS_MIGRATION.md](FRIENDGROUPS_MIGRATION.md)

---

## 🐛 Bug Fixes

### Phase 10.4 Testing (14 Bugs Fixed)
- Raid Frame drag & drop tooltip issue
- WHO Frame whisper command (server extraction)
- Custom Groups color format parsing
- Settings migration bnetAccountID lookup
- Debug Database string filter
- Recent Allies tooltips
- Ignore List UI opening
- Various nil-check and edge case fixes

### Phase 10.5 Polish
- Removed all debug print statements
- Cleaned up MenuSystem.lua
- Fixed Raid UI visibility (only shows in raids, not parties)

---

## 📚 Documentation

### User Documentation
- **README.md** - Complete user guide (450+ lines)
  - Installation instructions
  - Quick start guide
  - Feature documentation
  - Commands reference
  - FAQ (8 questions)
  - Troubleshooting section
- **CHANGELOG.md** - Full version history
- **FRIENDGROUPS_MIGRATION.md** - Migration guide

### Technical Documentation
- **PHASE_10.5_COMPLETE.md** - Technical limitations explained
- **TESTING_CHECKLIST.md** - 14 bugs documented
- **v1.0-finalization-plan.md** - Development roadmap
- **MASTER_ROADMAP.md** - Overall project plan

---

## 🙏 Credits

### Development
- **Lead Developer**: Hayato2846
- **AI Assistant**: GitHub Copilot (Claude Sonnet 4.5)

### Inspiration & Reference
- **FriendGroups** - Original custom groups addon
- **Blizzard_FriendsFrame** - Reference implementation (11.2.5)
- **Cell** - Raid frame drag & drop inspiration

### Special Thanks
- WoW AddOn Development Community
- [warcraft.wiki.gg](https://warcraft.wiki.gg) - API documentation
- [GitHub Gethe/wow-ui-source](https://github.com/Gethe/wow-ui-source) - Blizzard source
- Beta testers and bug reporters

---

## 🔗 Links

- **GitHub**: [Hayato2846/BetterFriendlist](https://github.com/Hayato2846/BetterFriendlist)
- **Issues**: [Report Bugs](https://github.com/Hayato2846/BetterFriendlist/issues)
- **Releases**: [Download](https://github.com/Hayato2846/BetterFriendlist/releases)

---

## 🎯 What's Next?

### Planned for v1.1+ (Optional)
- Enhanced filtering (level, zone, class)
- Color coding for custom groups
- Notification system
- Statistics/activity tracking
- Profile system
- Import/Export groups

**v1.0 is feature complete!** Future releases will focus on quality-of-life improvements and user requests.

---

## 💬 Feedback

We'd love to hear your feedback!

- **Bug Reports**: [GitHub Issues](https://github.com/Hayato2846/BetterFriendlist/issues)
- **Feature Requests**: [GitHub Discussions](https://github.com/Hayato2846/BetterFriendlist/discussions)
- **Questions**: Check [README.md](README.md) FAQ section first

---

**Thank you for using BetterFriendlist!** 🎉

---

*This addon is not affiliated with or endorsed by Blizzard Entertainment. World of Warcraft and Battle.net are trademarks of Blizzard Entertainment, Inc.*
