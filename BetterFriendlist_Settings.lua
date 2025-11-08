-- BetterFriendlist_Settings.lua
-- Settings window management (Delegates to Settings module)

local ADDON_NAME, BFL = ...

-- Helper to get Settings module
local function GetSettings()
return BFL and BFL:GetModule("Settings")
end

--------------------------------------------------------------------------
-- GLOBAL FUNCTIONS (Delegating to Settings Module)
--------------------------------------------------------------------------

-- Initialize the settings frame
function BetterFriendlistSettings_OnLoad(frame)
local Settings = GetSettings()
if Settings then
Settings:OnLoad(frame)
end
end

-- Show the settings window
function BetterFriendlistSettings_Show()
local Settings = GetSettings()
if Settings then
Settings:Show()
end
end

-- Hide the settings window
function BetterFriendlistSettings_Hide()
local Settings = GetSettings()
if Settings then
Settings:Hide()
end
end

-- Switch between tabs
function BetterFriendlistSettings_ShowTab(tabID)
local Settings = GetSettings()
if Settings then
Settings:ShowTab(tabID)
end
end

-- Load settings from database into UI
function BetterFriendlistSettings_LoadSettings()
local Settings = GetSettings()
if Settings then
Settings:LoadSettings()
end
end

-- Initialize font size dropdown
function BetterFriendlistSettings_InitFontSizeDropdown()
local Settings = GetSettings()
if Settings then
Settings:InitFontSizeDropdown()
end
end

-- Set font size
function BetterFriendlistSettings_SetFontSize(size)
local Settings = GetSettings()
if Settings then
Settings:SetFontSize(size)
end
end

-- Reset to defaults
function BetterFriendlistSettings_ResetToDefaults()
local Settings = GetSettings()
if Settings then
Settings:ResetToDefaults()
end
end

-- Perform the actual reset
function BetterFriendlistSettings_DoReset()
local Settings = GetSettings()
if Settings then
Settings:DoReset()
end
end

-- Refresh the group list in the Groups tab
function BetterFriendlistSettings_RefreshGroupList()
local Settings = GetSettings()
if Settings then
Settings:RefreshGroupList()
end
end

-- Save group order after drag/drop
function BetterFriendlistSettings_SaveGroupOrder()
local Settings = GetSettings()
if Settings then
Settings:SaveGroupOrder()
end
end

-- Show color picker for a group
function BetterFriendlistSettings_ShowColorPicker(groupId, groupName, colorSwatch)
local Settings = GetSettings()
if Settings then
Settings:ShowColorPicker(groupId, groupName, colorSwatch)
end
end

-- Delete a custom group
function BetterFriendlistSettings_DeleteGroup(groupId, groupName)
local Settings = GetSettings()
if Settings then
Settings:DeleteGroup(groupId, groupName)
end
end

-- Migrate from FriendGroups addon
function BetterFriendlistSettings_MigrateFriendGroups(cleanupNotes)
local Settings = GetSettings()
if Settings then
Settings:MigrateFriendGroups(cleanupNotes)
end
end

-- Show migration dialog
function BetterFriendlistSettings_ShowMigrationDialog()
local Settings = GetSettings()
if Settings then
Settings:ShowMigrationDialog()
end
end

-- Debug: Print database contents
function BetterFriendlistSettings_DebugDatabase()
local Settings = GetSettings()
if Settings then
Settings:DebugDatabase()
end
end

--------------------------------------------------------------------------
-- STATIC POPUP DIALOGS
--------------------------------------------------------------------------

-- Reset settings confirmation
StaticPopupDialogs["BETTER_FRIENDLIST_RESET_SETTINGS"] = {
text = "Reset all BetterFriendlist settings to defaults?",
button1 = "Reset",
button2 = "Cancel",
OnAccept = function()
BetterFriendlistSettings_DoReset()
end,
timeout = 0,
whileDead = true,
hideOnEscape = true,
preferredIndex = 3,
}

--------------------------------------------------------------------------
-- INITIALIZATION
--------------------------------------------------------------------------

-- Initialize when frame loads
if BetterFriendlistSettingsFrame then
BetterFriendlistSettings_OnLoad(BetterFriendlistSettingsFrame)
end
