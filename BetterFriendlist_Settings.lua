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
		Settings:SelectCategory(tabID)
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

-- Refresh tab visibility (Beta features toggle)
function BetterFriendlistSettings_RefreshTabs()
	local Settings = GetSettings()
	if Settings then
		Settings:RefreshCategories()
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
function BetterFriendlistSettings_MigrateFriendGroups(cleanupNotes, force)
local Settings = GetSettings()
if Settings then
Settings:MigrateFriendGroups(cleanupNotes, force)
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

-- Show export dialog
function BetterFriendlistSettings_ShowExportDialog()
local Settings = GetSettings()
if Settings then
Settings:ShowExportDialog()
end
end

-- Show import dialog
function BetterFriendlistSettings_ShowImportDialog()
local Settings = GetSettings()
if Settings then
Settings:ShowImportDialog()
end
end

-- Refresh statistics display
function BetterFriendlistSettings_RefreshStatistics()
local Settings = GetSettings()
if Settings then
Settings:RefreshStatistics()
end
end

-- Compact mode changed
function BetterFriendlistSettings_OnCompactModeChanged(checked)
local Settings = GetSettings()
if Settings then
Settings:OnCompactModeChanged(checked)
end
end

-- Show Blizzard option changed
function BetterFriendlistSettings_OnShowBlizzardOptionChanged(checked)
local Settings = GetSettings()
if Settings then
Settings:OnShowBlizzardOptionChanged(checked)
end
end

-- Color class names changed
function BetterFriendlistSettings_OnColorClassNamesChanged(checked)
local Settings = GetSettings()
if Settings then
Settings:OnColorClassNamesChanged(checked)
end
end

-- Hide empty groups changed
function BetterFriendlistSettings_OnHideEmptyGroupsChanged(checked)
local Settings = GetSettings()
if Settings then
Settings:OnHideEmptyGroupsChanged(checked)
end
end

-- Show Faction Icons toggle
function BetterFriendlistSettings_OnShowFactionIconsChanged(checked)
local Settings = GetSettings()
if Settings then
Settings:OnShowFactionIconsChanged(checked)
end
end

-- Show Realm Name toggle
function BetterFriendlistSettings_OnShowRealmNameChanged(checked)
local Settings = GetSettings()
if Settings then
Settings:OnShowRealmNameChanged(checked)
end
end

-- Show Favorites Group toggle
function BetterFriendlistSettings_OnShowFavoritesGroupChanged(checked)
local Settings = GetSettings()
if Settings then
Settings:OnShowFavoritesGroupChanged(checked)
end
end

-- Gray Other Faction toggle
function BetterFriendlistSettings_OnGrayOtherFactionChanged(checked)
local Settings = GetSettings()
if Settings then
Settings:OnGrayOtherFactionChanged(checked)
end
end

-- Show Mobile as AFK toggle
function BetterFriendlistSettings_OnShowMobileAsAFKChanged(checked)
local Settings = GetSettings()
if Settings then
Settings:OnShowMobileAsAFKChanged(checked)
end
end

-- Hide Max Level toggle
function BetterFriendlistSettings_OnHideMaxLevelChanged(checked)
local Settings = GetSettings()
if Settings then
Settings:OnHideMaxLevelChanged(checked)
end
end

-- Accordion Groups toggle
function BetterFriendlistSettings_OnAccordionGroupsChanged(checked)
local Settings = GetSettings()
if Settings then
Settings:OnAccordionGroupsChanged(checked)
end
end

--------------------------------------------------------------------------
-- TAB VISIBILITY SYSTEM (Beta Features)
--------------------------------------------------------------------------



--------------------------------------------------------------------------
-- STATIC POPUP DIALOGS
--------------------------------------------------------------------------

-- Reset settings confirmation
StaticPopupDialogs["BETTER_FRIENDLIST_RESET_SETTINGS"] = {
text = BFL.L.DIALOG_RESET_SETTINGS_TEXT,
button1 = BFL.L.DIALOG_RESET_BTN1,
button2 = BFL.L.DIALOG_RESET_BTN2,
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
