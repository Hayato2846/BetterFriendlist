# FriendGroups - World of Warcraft AddOn

A modern, refactored World of Warcraft addon for organizing friends into custom groups with enhanced functionality and improved user experience. Now includes **complete Recruit A Friend (RAF) integration** matching Blizzard's 11.2.5 implementation.

## Features

### Core Functionality
- **Custom Friend Groups**: Organize your WoW and Battle.net friends into custom named groups
- **Recent Allies**: Complete implementation of the Recent Allies system with character tracking
- **Recruit A Friend (RAF)**: Full RAF system integration with recruit management, rewards, and activities
- **Cross-Platform Support**: Supports both WoW friends and Battle.net friends
- **Smart Filtering**: Advanced filtering options including online status, game type, and custom groups
- **Intelligent Sorting**: Multiple sorting options (alphabetical, status, last online, etc.)
- **Note Management**: Enhanced note parsing and management for friends
- **Collapsible Groups**: Collapse/expand groups in the friends list for better organization

### Modern Features (11.2.5)
- **4-Tab Interface**: Friends, Recent Allies, Recruit A Friend, Sort Options
- **Recent Allies System**: Track players you've recently grouped with
- **RAF Reward Tracking**: View your RAF rewards and month count
- **RAF Recruit List**: See all your recruited friends with online status
- **RAF Activity System**: Track and claim recruit activity rewards
- **Modern WoW API**: Updated to use current WoW API calls (C_BattleNet, C_FriendList, C_RecruitAFriend, etc.)
- **Event-Driven Architecture**: Efficient event handling for real-time updates
- **Namespace Protection**: Modern addon namespace pattern to prevent conflicts
- **Database Management**: Robust saved variables system with profile support
- **Context Menus**: Right-click context menus for easy group management
- **Slash Commands**: Comprehensive slash command interface

### User Interface
- **Enhanced Friends List**: Improved friends list with group dividers and member counts
- **RAF Integration**: Complete Recruit A Friend tab with reward claiming panel and recruit list
- **Recent Allies Tab**: ScrollBox-based list with character information and party invite buttons
- **Modern UI Elements**: Updated UI templates using current WoW design patterns
- **Tooltips**: Informative tooltips throughout the interface
- **Visual Indicators**: Clear visual indicators for group membership and status
- **Responsive Design**: UI adapts to different screen sizes and resolutions

## Installation

1. Download or clone this repository
2. Extract to your World of Warcraft AddOns directory:
   - `World of Warcraft\_retail_\Interface\AddOns\BetterFriendlist\`
3. Restart World of Warcraft or reload your UI (`/reload`)
4. The addon will automatically integrate with your existing Friends frame

### Migrating from FriendGroups
If you're upgrading from the FriendGroups addon:
1. Install BetterFriendlist (keep FriendGroups enabled for now)
2. Open Settings (ESC → Interface → AddOns → BetterFriendlist)
3. Go to the **Advanced** tab
4. Click **"Migrate from FriendGroups"**
5. Choose whether to clean up your BattleNet notes
6. After successful migration, you can disable FriendGroups

📖 **Detailed Migration Guide**: See [FRIENDGROUPS_MIGRATION.md](FRIENDGROUPS_MIGRATION.md) for complete instructions.

## Usage

### Tab Navigation (11.2.5)
The addon features 4 main tabs:
1. **Friends Tab**: Your WoW and Battle.net friends list
2. **Recent Allies Tab**: Players you've recently grouped with
3. **Recruit A Friend Tab**: RAF system with recruits, rewards, and activities
4. **Sort Tab**: Choose your preferred friend list sorting method

### Recruit A Friend Features
- **Reward Claiming Panel**: View your lifetime months and next claimable reward
- **Recruit List**: See all your recruited friends with online status
- **Activity Tracking**: Track and claim activity rewards from recruits
- **Recruitment Button**: Generate and share recruitment links
- **Context Menus**: Right-click recruits for RAF-specific actions

### Recent Allies Features
- **Character Tracking**: View race, class, level, and location
- **Online Status**: See which allies are currently online
- **Party Invites**: Quick party invite button for online allies
- **Pin System**: Pin important allies (when available)
- **Auto-Refresh**: Updates automatically when cache changes

### Basic Commands
- `/friendgroups` or `/fg` - Main command interface
- `/fg help` - Show all available commands
- `/fg create <group_name>` - Create a new group
- `/fg delete <group_name>` - Delete a group
- `/fg add <friend_name> <group_name>` - Add friend to group
- `/fg remove <friend_name> <group_name>` - Remove friend from group
- `/fg list` - List all groups and members

### Interface Usage
- **Right-click** group headers to rename or delete groups
- **Right-click** friends to add/remove from groups
- **Left-click** group collapse buttons to expand/collapse groups
- **Shift-click** friends to send /who queries
- Use the context menus for quick group management

### Filtering and Sorting
- Access filtering options through the main friends frame
- Sort by: Name, Status, Last Online, Group, Game Type
- Filter by: Online Status, Game Type, Group Membership
- Search functionality for quick friend finding

## Configuration

The addon saves settings per character in the SavedVariables. Configuration options include:

- **Groups**: Custom friend groups and their members
- **Collapsed Groups**: Which groups are currently collapsed
- **Sort Settings**: Current sorting preferences
- **Filter Settings**: Active filter configurations
- **UI Preferences**: Interface customization options

### Saved Variables
- `FriendGroupsDB` - Main database containing all addon data
- Automatic backup and recovery system
- Profile-based settings (per character)

## API Reference

### Core Functions
```lua
-- Group Management
FriendGroups:CreateGroup(groupName)
FriendGroups:DeleteGroup(groupName)
FriendGroups:RenameGroup(oldName, newName)

-- Member Management
FriendGroups:AddFriendToGroup(friendType, friendID, bnetIDAccount, groupName)
FriendGroups:RemoveFriendFromGroup(friendType, friendID, bnetIDAccount, groupName)
FriendGroups:GetFriendGroups(friendType, friendID, bnetIDAccount)

-- Utility Functions
FriendGroups:GetGroupMemberCount(groupName)
FriendGroups:IsMemberOnline(memberKey)
FriendGroups:GenerateFriendKey(friendType, identifier)
```

### Events
The addon responds to the following WoW events:
- `ADDON_LOADED` - Initialize addon data
- `FRIENDLIST_UPDATE` - Update friend information
- `BN_FRIEND_LIST_SIZE_CHANGED` - Battle.net friends list changes
- `BN_FRIEND_INFO_CHANGED` - Battle.net friend status changes
- `PLAYER_LOGIN` - Complete initialization

## Compatibility

### World of Warcraft Versions
- **Retail (Live)**: Fully supported ✅
- **Classic**: May require minor adjustments ⚠️
- **Burning Crusade Classic**: May require minor adjustments ⚠️

### API Dependencies
- Uses modern WoW API calls (10.0+)
- Battle.net integration requires retail client
- Classic versions may need API compatibility layer

### AddOn Compatibility
- Compatible with most UI replacement addons
- Works with ElvUI, Bartender, and other major UI mods
- May require positioning adjustments with custom friends frame replacements

## Development

### Project Structure
```
FriendGroups/
├── FriendGroups.toc    # Addon metadata and load order
├── FriendGroups.lua    # Core logic and functionality
├── FriendGroups.xml    # UI templates and definitions
└── README.md           # This documentation
```

### Contributing
1. Fork the repository
2. Create a feature branch
3. Make your changes following WoW addon best practices
4. Test thoroughly in-game
5. Submit a pull request with detailed description

### Code Style
- Follow standard Lua conventions
- Use meaningful variable and function names
- Comment complex logic sections
- Maintain backward compatibility where possible
- Use modern WoW API patterns

## Migration from Legacy Versions

### Automatic Migration
The addon automatically detects and migrates data from older versions:
- Legacy saved variables are converted to new format
- Group memberships are preserved
- UI preferences are updated to modern equivalents

### Manual Migration Steps
If automatic migration fails:
1. Export your current groups using `/fg export`
2. Backup your SavedVariables file
3. Install the new version
4. Use `/fg import` to restore your groups

## Troubleshooting

### Common Issues
1. **Groups not showing**: Ensure addon is enabled and UI is reloaded
2. **Friends not grouped**: Check friend names for special characters
3. **UI conflicts**: Disable other friends frame addons temporarily
4. **Data loss**: Check SavedVariables backup in WTF folder

### Debug Commands
- `/fg debug` - Enable debug output
- `/fg reset` - Reset all data (use with caution!)
- `/fg reload` - Reload addon without restarting game

### Support
- Check the Issues section on GitHub
- Provide debug output and error messages
- Include WoW version and other addon information

## Changelog

### Version 3.0.0 (Current - 11.2.5)
- **MAJOR**: Complete Recruit A Friend (RAF) tab implementation
  - Reward Claiming Panel with month count and next reward display
  - Recruit List with online/offline dividers and activity tracking
  - Activity System with chest icons and claim functionality
  - Recruitment Button with link generation support
  - RAF-specific context menus and tooltips
  - Complete 1:1 replication of Blizzard's RecruitAFriendFrame
- **MAJOR**: Complete Recent Allies implementation (14 functions, 450 lines)
  - ScrollBox-based list with character information
  - Loading spinner using SpinnerTemplate
  - Party invite buttons and pin system
  - Auto-refresh on RECENT_ALLIES_CACHE_UPDATE
- **COMPLETE**: Ignore List implementation (9 functions)
  - ElementFactory pattern for headers and buttons
  - Auto-selection using FindElementDataByPredicate
  - SQUELCH_TYPE_IGNORE and SQUELCH_TYPE_BLOCK_INVITE support
- **RESTORED**: Sort Tab as 4th tab
- **UI**: 4-tab interface (Friends, Recent Allies, RAF, Sort)
- **PERFORMANCE**: Enhanced event handling and caching
- **API**: Updated to 11.2.5 API standards

### Version 2.0.0
- Complete rewrite using modern WoW API
- Enhanced UI with improved templates
- Better performance and memory usage
- Comprehensive context menu system
- Improved note management
- Modern event handling

### Previous Versions
- Legacy versions (1.x) are no longer supported
- Automatic migration provided for upgrade path

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Credits

### Original Authors
- Original FriendGroups concept and implementation

### Contributors
- Community feedback and feature requests
- Beta testers and bug reporters
- Modern API documentation contributors

### Special Thanks
- Blizzard Entertainment for the World of Warcraft API
- WoW addon development community
- All users who provided feedback and suggestions

---

**Note**: This addon is not affiliated with or endorsed by Blizzard Entertainment. World of Warcraft is a trademark of Blizzard Entertainment, Inc.
