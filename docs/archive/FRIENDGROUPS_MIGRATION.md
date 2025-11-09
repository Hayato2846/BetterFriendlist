# FriendGroups to BetterFriendlist Migration Guide

## Overview
BetterFriendlist includes a built-in migration tool to seamlessly transfer your friend groups from the FriendGroups addon.

## What Gets Migrated?

### ✅ Groups
- All custom groups stored in BattleNet notes
- Group names and assignments

### ✅ Friend Assignments
- BattleNet friends and their group memberships
- WoW friends and their group memberships

### ❌ Not Migrated
- FriendGroups settings (filters, display options, etc.)
- Special groups: `[Favorites]` and `[No Group]` (use BFL's native versions instead)
- Collapsed/expanded state of groups

## Migration Process

### Step 1: Backup Your Data
Before migrating, it's recommended to:
1. Take a screenshot of your FriendGroups list
2. Export your WTF folder (contains saved variables)
3. Make sure both addons are up to date

### Step 2: Access Migration Tool
1. Open BetterFriendlist Settings (ESC → Interface → AddOns → BetterFriendlist)
2. Navigate to the **Advanced** tab
3. Find the **FriendGroups Migration** section

### Step 3: Choose Migration Options
Click the **"Migrate from FriendGroups"** button. You'll see a confirmation dialog with three options:

**Option 1: Migrate & Clean Notes**
- ✅ Creates groups in BetterFriendlist
- ✅ Assigns friends to groups
- ✅ **Removes group data from BattleNet notes**
- ✅ Preserves actual note text (if any)

**Option 2: Migrate Only**
- ✅ Creates groups in BetterFriendlist
- ✅ Assigns friends to groups
- ❌ Keeps group data in BattleNet notes (FriendGroups format remains)

**Option 3: Cancel**
- ❌ No changes made

### Step 4: Verify Migration
After migration completes:
1. Check the chat message for summary:
   ```
   BetterFriendlist: Successfully migrated 42 friends into 8 groups (156 total assignments). 
   Notes have been cleaned up.
   ```
   - **Friends**: Number of friends with group data migrated
   - **Groups**: Number of unique groups created
   - **Assignments**: Total friend-to-group relationships (one friend can be in multiple groups)
2. Review your groups in the **Groups** tab
3. Verify friend assignments in the main friend list
4. Check a few BattleNet notes to confirm cleanup (if selected)

## Technical Details

### FriendGroups Note Format
FriendGroups stores group information in BattleNet notes using this format:
```
ActualNoteText#GroupName1#GroupName2#GroupName3
```

For example:
```
Best healer!#Raid Team#Guild Members
```

### Migration Process
1. **Parse Notes**: Splits note text by `#` delimiter
2. **Extract Groups**: Identifies group names (everything after first `#`)
3. **Create Groups**: Creates matching groups in BetterFriendlist (if they don't exist)
4. **Generate UIDs**: Creates proper BetterFriendlist UIDs (`bnet_<ID>` or `wow_<name>`)
5. **Assign Friends**: Links each friend to their respective groups via Database module
6. **Clean Notes** (optional): Removes group data, keeps actual note text

### Friend UID Format
BetterFriendlist uses unique identifiers for friends:
- **BattleNet Friends**: `bnet_<bnetAccountID>` (e.g., `bnet_12345678`)
- **WoW Friends**: `wow_<characterName>` (e.g., `wow_Thrall`)

These UIDs ensure proper friend-to-group assignments across sessions.

### Special Cases
- **Empty Notes**: Skipped (nothing to migrate)
- **Special Groups**: `[Favorites]` and `[No Group]` are ignored (use BFL's native versions)
- **Duplicate Groups**: If a group already exists in BFL, friends are added to that group
- **WoW Friends**: Both BattleNet and WoW-only friends are processed

## After Migration

### Recommended Actions
1. **Test Everything**: 
   - Open/collapse groups
   - Check friend assignments
   - Verify notes are preserved
   
2. **Disable FriendGroups** (if you cleaned notes):
   - Go to ESC → Interface → AddOns
   - Uncheck FriendGroups
   - Reload UI (/reload)

3. **Customize BetterFriendlist**:
   - Reorder groups (drag & drop in Groups tab)
   - Assign custom colors
   - Configure display settings (Appearance tab)

### Can I Undo Migration?
⚠️ **Migration cannot be undone automatically.**

If you need to revert:
1. **Without Note Cleanup**: Your FriendGroups data is still in notes, just disable BFL
2. **With Note Cleanup**: You'll need to restore from a backup (WTF folder)

## Troubleshooting

### Migration Button Not Working
- Ensure BetterFriendlist is fully loaded (/reload)
- Check for Lua errors (install BugSack addon)
- Verify you have friends with FriendGroups notes

### Some Friends Not Migrated
- Check if those friends have group data in their notes (must contain `#` delimiter)
- Special groups `[Favorites]` and `[No Group]` are intentionally skipped

### Groups Created But Friends Not Assigned
- Check chat for error messages
- Verify friend names/IDs haven't changed
- Try /reload and check again

### Notes Not Cleaned Up
- Verify you selected "Migrate & Clean Notes" option
- Check if you have permission to edit notes (online friends only)
- Some notes may require manual cleanup if they have unusual formatting

## Support

If you encounter issues:
1. Check Lua errors (BugSack addon recommended)
2. Review chat messages for migration results
3. Report issues on GitHub: https://github.com/Hayato2846/BetterFriendlist

---

*Last Updated: 2025-10-28*
