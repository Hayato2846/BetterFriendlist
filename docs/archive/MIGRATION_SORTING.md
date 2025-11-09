# FriendGroups Migration - Alphabetical Sorting

## Overview
The migration from FriendGroups to BetterFriendlist now preserves the alphabetical group ordering that FriendGroups users are familiar with.

## How It Works

### Migration Phases
The migration happens in 4 distinct phases:

1. **Phase 1: Collection**
   - Scans all BattleNet and WoW friends
   - Extracts group names from notes (format: `Note#Group1#Group2`)
   - Stores friend assignments for later processing
   - Collects all unique group names

2. **Phase 2: Group Creation (Alphabetical)**
   - Converts collected group names to a sorted array
   - Sorts alphabetically using Lua's `table.sort()`
   - Creates groups with sequential order values:
     - Favorites: order = 1 (built-in, always first)
     - Migrated groups: order = 2, 3, 4, 5, ... (alphabetically)
     - No Group: order = 999 (built-in, always last)
   - Uses `Groups:CreateWithOrder(name, order)` to set explicit ordering

3. **Phase 3: Friend Assignment**
   - Iterates through stored friend assignments
   - Assigns each friend to their respective groups using UIDs
   - Tracks total assignment count

4. **Phase 4: Note Cleanup (Optional)**
   - If "Migrate & Clean Notes" was selected:
     - Removes group tags from notes
     - Preserves the actual note text
     - Cleans both BNet and WoW friend notes

## Example

### Original FriendGroups Data
```
Friend 1: "Great player#ZonK#M+ Team"
Friend 2: "Alt account#Boosting#Simply The Best"
Friend 3: "Guild mate#Friends#Drifted"
```

### Groups After Migration (Alphabetically Sorted)
```
1. Favorites (built-in)
2. Boosting
3. Drifted
4. Friends
5. M+ Team
6. Simply The Best
7. ZonK
999. No Group (built-in)
```

### Why Alphabetical Order?
- **Consistency**: Matches FriendGroups' sorting behavior
- **Predictability**: Users know where to find their groups
- **Organization**: Large group lists are easier to navigate
- **Migration Fidelity**: Feels familiar to FriendGroups users

## Technical Details

### CreateWithOrder Function
Located in `Modules/Groups.lua`:
```lua
function Groups:CreateWithOrder(groupName, orderValue)
    -- Creates a group with a specific order value
    -- Used exclusively during migration
    -- Returns: (success, groupId)
end
```

### Order Value System
- **1**: Reserved for Favorites (built-in)
- **2-998**: Custom groups (migration uses 2, 3, 4, ...)
- **999**: Reserved for No Group (built-in)

### Sorting Algorithm
Uses Lua's built-in `table.sort()` with default lexicographic comparison:
- Case-sensitive alphabetical order
- Special characters sorted by ASCII value
- Example: "Boosting" < "Friends" < "M+ Team" < "ZonK"

## Benefits

1. **No Manual Reordering**: Groups appear in the expected order immediately
2. **Muscle Memory**: Users can find groups in the same position as before
3. **Professional Feel**: Organized presentation of migrated data
4. **Scalability**: Works equally well with 5 or 50 groups

## Future Enhancements

Potential improvements:
- Option to preserve FriendGroups' custom ordering (if stored somewhere)
- Case-insensitive sorting option
- Locale-aware sorting for international characters
- Custom sort order selection during migration

## Testing

To verify correct ordering after migration:
1. `/bfl debug` - Check group order values in console
2. Open Friends list - Visually confirm alphabetical order
3. Check between Favorites (top) and No Group (bottom)

## Related Files
- `BetterFriendlist_Settings.lua`: Migration function (Phase 2)
- `Modules/Groups.lua`: CreateWithOrder implementation
- `FRIENDGROUPS_MIGRATION.md`: General migration guide
