# Quick Join InsetFrameTemplate Fix

## Issue
After implementing InsetFrameTemplate for the Quick Join UI (to add proper dark background with gray border), three UI elements were broken:
1. Button had no text
2. List was not visible
3. Placeholder text "No groups available" was not showing

## Root Cause
The XML structure was reorganized with ContentInset wrapper, but Lua code still referenced elements directly from `self.*` instead of `self.ContentInset.*`.

## XML Structure (Correct)
```
QuickJoinFrame
└── ContentInset (InsetFrameTemplate)
    ├── Layers
    │   └── ARTWORK
    │       └── NoGroupsText
    └── Frames
        ├── ScrollBoxContainer
        │   └── ScrollBox
        ├── ScrollBar
        └── JoinQueueButton
```

## Files Modified

### 1. BetterFriendlist.lua
**BetterQuickJoinFrame_OnLoad (lines 2400-2490)**
- Already correctly updated to use `contentInset.JoinQueueButton`, `contentInset.ScrollBoxContainer`, etc.
- Caches `self.ScrollBox = scrollBox` for later use

**BetterQuickJoinFrame_Update (lines 2540-2560)**
- Fixed: `self.NoGroupsText` → `self.ContentInset.NoGroupsText`
- NoGroupsText is now accessed through ContentInset parent

### 2. Modules/QuickJoin.lua
**QuickJoin:UpdateJoinButtonState (line 1278)**
- Fixed: `frame.JoinQueueButton` → `frame.ContentInset.JoinQueueButton`
- Added nil-check for `frame.ContentInset`

## Testing Checklist
- [ ] `/reload` - Reload addon without errors
- [ ] `/bflqj mock` - Create 3 test groups
- [ ] Verify button shows text "JOIN_QUEUE"
- [ ] Verify list displays mock groups
- [ ] Clear mock groups and verify "No groups available" text appears
- [ ] Test with real friends in groups
- [ ] Click button and verify Blizzard role selection dialog appears
- [ ] Verify dark background area is properly sized

## Result
All UI elements now correctly reference their paths through ContentInset:
- ✅ Button text appears
- ✅ List is visible
- ✅ Placeholder text works
- ✅ Dark background displays properly (InsetFrameTemplate)
- ✅ Gray border matches Raid Frame style
