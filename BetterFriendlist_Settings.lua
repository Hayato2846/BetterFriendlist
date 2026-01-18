--[[Perfy has instrumented this file]] local Perfy_GetTime, Perfy_Trace, Perfy_Trace_Passthrough = Perfy_GetTime, Perfy_Trace, Perfy_Trace_Passthrough; Perfy_Trace(Perfy_GetTime(), "Enter", "(main chunk) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\BetterFriendlist_Settings.lua"); -- BetterFriendlist_Settings.lua
-- Settings window management (Delegates to Settings module)

local ADDON_NAME, BFL = ...

-- Helper to get Settings module
local function GetSettings() Perfy_Trace(Perfy_GetTime(), "Enter", "GetSettings file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\BetterFriendlist_Settings.lua:7:6");
return Perfy_Trace_Passthrough("Leave", "GetSettings file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\BetterFriendlist_Settings.lua:7:6", BFL and BFL:GetModule("Settings"))
end

--------------------------------------------------------------------------
-- GLOBAL FUNCTIONS (Delegating to Settings Module)
--------------------------------------------------------------------------

-- Initialize the settings frame
function BetterFriendlistSettings_OnLoad(frame) Perfy_Trace(Perfy_GetTime(), "Enter", "BetterFriendlistSettings_OnLoad file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\BetterFriendlist_Settings.lua:16:0");
local Settings = GetSettings()
if Settings then
Settings:OnLoad(frame)
end
Perfy_Trace(Perfy_GetTime(), "Leave", "BetterFriendlistSettings_OnLoad file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\BetterFriendlist_Settings.lua:16:0"); end

-- Show the settings window
function BetterFriendlistSettings_Show() Perfy_Trace(Perfy_GetTime(), "Enter", "BetterFriendlistSettings_Show file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\BetterFriendlist_Settings.lua:24:0");
local Settings = GetSettings()
if Settings then
Settings:Show()
end
Perfy_Trace(Perfy_GetTime(), "Leave", "BetterFriendlistSettings_Show file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\BetterFriendlist_Settings.lua:24:0"); end

-- Hide the settings window
function BetterFriendlistSettings_Hide() Perfy_Trace(Perfy_GetTime(), "Enter", "BetterFriendlistSettings_Hide file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\BetterFriendlist_Settings.lua:32:0");
local Settings = GetSettings()
if Settings then
Settings:Hide()
end
Perfy_Trace(Perfy_GetTime(), "Leave", "BetterFriendlistSettings_Hide file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\BetterFriendlist_Settings.lua:32:0"); end

-- Switch between tabs
function BetterFriendlistSettings_ShowTab(tabID) Perfy_Trace(Perfy_GetTime(), "Enter", "BetterFriendlistSettings_ShowTab file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\BetterFriendlist_Settings.lua:40:0");
local Settings = GetSettings()
if Settings then
Settings:ShowTab(tabID)
end
Perfy_Trace(Perfy_GetTime(), "Leave", "BetterFriendlistSettings_ShowTab file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\BetterFriendlist_Settings.lua:40:0"); end

-- Load settings from database into UI
function BetterFriendlistSettings_LoadSettings() Perfy_Trace(Perfy_GetTime(), "Enter", "BetterFriendlistSettings_LoadSettings file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\BetterFriendlist_Settings.lua:48:0");
local Settings = GetSettings()
if Settings then
Settings:LoadSettings()
end
Perfy_Trace(Perfy_GetTime(), "Leave", "BetterFriendlistSettings_LoadSettings file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\BetterFriendlist_Settings.lua:48:0"); end

-- Initialize font size dropdown
function BetterFriendlistSettings_InitFontSizeDropdown() Perfy_Trace(Perfy_GetTime(), "Enter", "BetterFriendlistSettings_InitFontSizeDropdown file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\BetterFriendlist_Settings.lua:56:0");
local Settings = GetSettings()
if Settings then
Settings:InitFontSizeDropdown()
end
Perfy_Trace(Perfy_GetTime(), "Leave", "BetterFriendlistSettings_InitFontSizeDropdown file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\BetterFriendlist_Settings.lua:56:0"); end

-- Set font size
function BetterFriendlistSettings_SetFontSize(size) Perfy_Trace(Perfy_GetTime(), "Enter", "BetterFriendlistSettings_SetFontSize file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\BetterFriendlist_Settings.lua:64:0");
local Settings = GetSettings()
if Settings then
Settings:SetFontSize(size)
end
Perfy_Trace(Perfy_GetTime(), "Leave", "BetterFriendlistSettings_SetFontSize file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\BetterFriendlist_Settings.lua:64:0"); end

-- Reset to defaults
function BetterFriendlistSettings_ResetToDefaults() Perfy_Trace(Perfy_GetTime(), "Enter", "BetterFriendlistSettings_ResetToDefaults file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\BetterFriendlist_Settings.lua:72:0");
local Settings = GetSettings()
if Settings then
Settings:ResetToDefaults()
end
Perfy_Trace(Perfy_GetTime(), "Leave", "BetterFriendlistSettings_ResetToDefaults file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\BetterFriendlist_Settings.lua:72:0"); end

-- Perform the actual reset
function BetterFriendlistSettings_DoReset() Perfy_Trace(Perfy_GetTime(), "Enter", "BetterFriendlistSettings_DoReset file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\BetterFriendlist_Settings.lua:80:0");
local Settings = GetSettings()
if Settings then
Settings:DoReset()
end
Perfy_Trace(Perfy_GetTime(), "Leave", "BetterFriendlistSettings_DoReset file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\BetterFriendlist_Settings.lua:80:0"); end

-- Refresh the group list in the Groups tab
function BetterFriendlistSettings_RefreshGroupList() Perfy_Trace(Perfy_GetTime(), "Enter", "BetterFriendlistSettings_RefreshGroupList file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\BetterFriendlist_Settings.lua:88:0");
local Settings = GetSettings()
if Settings then
Settings:RefreshGroupList()
end
Perfy_Trace(Perfy_GetTime(), "Leave", "BetterFriendlistSettings_RefreshGroupList file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\BetterFriendlist_Settings.lua:88:0"); end

-- Save group order after drag/drop
function BetterFriendlistSettings_SaveGroupOrder() Perfy_Trace(Perfy_GetTime(), "Enter", "BetterFriendlistSettings_SaveGroupOrder file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\BetterFriendlist_Settings.lua:96:0");
local Settings = GetSettings()
if Settings then
Settings:SaveGroupOrder()
end
Perfy_Trace(Perfy_GetTime(), "Leave", "BetterFriendlistSettings_SaveGroupOrder file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\BetterFriendlist_Settings.lua:96:0"); end

-- Refresh tab visibility (Beta features toggle)
function BetterFriendlistSettings_RefreshTabs() Perfy_Trace(Perfy_GetTime(), "Enter", "BetterFriendlistSettings_RefreshTabs file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\BetterFriendlist_Settings.lua:104:0");
	local Settings = GetSettings()
	if Settings then
		Settings:RefreshTabs()
	end
Perfy_Trace(Perfy_GetTime(), "Leave", "BetterFriendlistSettings_RefreshTabs file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\BetterFriendlist_Settings.lua:104:0"); end

-- Show color picker for a group
function BetterFriendlistSettings_ShowColorPicker(groupId, groupName, colorSwatch) Perfy_Trace(Perfy_GetTime(), "Enter", "BetterFriendlistSettings_ShowColorPicker file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\BetterFriendlist_Settings.lua:112:0");
local Settings = GetSettings()
if Settings then
Settings:ShowColorPicker(groupId, groupName, colorSwatch)
end
Perfy_Trace(Perfy_GetTime(), "Leave", "BetterFriendlistSettings_ShowColorPicker file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\BetterFriendlist_Settings.lua:112:0"); end

-- Delete a custom group
function BetterFriendlistSettings_DeleteGroup(groupId, groupName) Perfy_Trace(Perfy_GetTime(), "Enter", "BetterFriendlistSettings_DeleteGroup file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\BetterFriendlist_Settings.lua:120:0");
local Settings = GetSettings()
if Settings then
Settings:DeleteGroup(groupId, groupName)
end
Perfy_Trace(Perfy_GetTime(), "Leave", "BetterFriendlistSettings_DeleteGroup file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\BetterFriendlist_Settings.lua:120:0"); end

-- Migrate from FriendGroups addon
function BetterFriendlistSettings_MigrateFriendGroups(cleanupNotes, force) Perfy_Trace(Perfy_GetTime(), "Enter", "BetterFriendlistSettings_MigrateFriendGroups file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\BetterFriendlist_Settings.lua:128:0");
local Settings = GetSettings()
if Settings then
Settings:MigrateFriendGroups(cleanupNotes, force)
end
Perfy_Trace(Perfy_GetTime(), "Leave", "BetterFriendlistSettings_MigrateFriendGroups file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\BetterFriendlist_Settings.lua:128:0"); end

-- Show migration dialog
function BetterFriendlistSettings_ShowMigrationDialog() Perfy_Trace(Perfy_GetTime(), "Enter", "BetterFriendlistSettings_ShowMigrationDialog file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\BetterFriendlist_Settings.lua:136:0");
local Settings = GetSettings()
if Settings then
Settings:ShowMigrationDialog()
end
Perfy_Trace(Perfy_GetTime(), "Leave", "BetterFriendlistSettings_ShowMigrationDialog file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\BetterFriendlist_Settings.lua:136:0"); end

-- Debug: Print database contents
function BetterFriendlistSettings_DebugDatabase() Perfy_Trace(Perfy_GetTime(), "Enter", "BetterFriendlistSettings_DebugDatabase file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\BetterFriendlist_Settings.lua:144:0");
local Settings = GetSettings()
if Settings then
Settings:DebugDatabase()
end
Perfy_Trace(Perfy_GetTime(), "Leave", "BetterFriendlistSettings_DebugDatabase file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\BetterFriendlist_Settings.lua:144:0"); end

-- Show export dialog
function BetterFriendlistSettings_ShowExportDialog() Perfy_Trace(Perfy_GetTime(), "Enter", "BetterFriendlistSettings_ShowExportDialog file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\BetterFriendlist_Settings.lua:152:0");
local Settings = GetSettings()
if Settings then
Settings:ShowExportDialog()
end
Perfy_Trace(Perfy_GetTime(), "Leave", "BetterFriendlistSettings_ShowExportDialog file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\BetterFriendlist_Settings.lua:152:0"); end

-- Show import dialog
function BetterFriendlistSettings_ShowImportDialog() Perfy_Trace(Perfy_GetTime(), "Enter", "BetterFriendlistSettings_ShowImportDialog file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\BetterFriendlist_Settings.lua:160:0");
local Settings = GetSettings()
if Settings then
Settings:ShowImportDialog()
end
Perfy_Trace(Perfy_GetTime(), "Leave", "BetterFriendlistSettings_ShowImportDialog file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\BetterFriendlist_Settings.lua:160:0"); end

-- Refresh statistics display
function BetterFriendlistSettings_RefreshStatistics() Perfy_Trace(Perfy_GetTime(), "Enter", "BetterFriendlistSettings_RefreshStatistics file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\BetterFriendlist_Settings.lua:168:0");
local Settings = GetSettings()
if Settings then
Settings:RefreshStatistics()
end
Perfy_Trace(Perfy_GetTime(), "Leave", "BetterFriendlistSettings_RefreshStatistics file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\BetterFriendlist_Settings.lua:168:0"); end

-- Compact mode changed
function BetterFriendlistSettings_OnCompactModeChanged(checked) Perfy_Trace(Perfy_GetTime(), "Enter", "BetterFriendlistSettings_OnCompactModeChanged file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\BetterFriendlist_Settings.lua:176:0");
local Settings = GetSettings()
if Settings then
Settings:OnCompactModeChanged(checked)
end
Perfy_Trace(Perfy_GetTime(), "Leave", "BetterFriendlistSettings_OnCompactModeChanged file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\BetterFriendlist_Settings.lua:176:0"); end

-- Show Blizzard option changed
function BetterFriendlistSettings_OnShowBlizzardOptionChanged(checked) Perfy_Trace(Perfy_GetTime(), "Enter", "BetterFriendlistSettings_OnShowBlizzardOptionChanged file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\BetterFriendlist_Settings.lua:184:0");
local Settings = GetSettings()
if Settings then
Settings:OnShowBlizzardOptionChanged(checked)
end
Perfy_Trace(Perfy_GetTime(), "Leave", "BetterFriendlistSettings_OnShowBlizzardOptionChanged file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\BetterFriendlist_Settings.lua:184:0"); end

-- Color class names changed
function BetterFriendlistSettings_OnColorClassNamesChanged(checked) Perfy_Trace(Perfy_GetTime(), "Enter", "BetterFriendlistSettings_OnColorClassNamesChanged file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\BetterFriendlist_Settings.lua:192:0");
local Settings = GetSettings()
if Settings then
Settings:OnColorClassNamesChanged(checked)
end
Perfy_Trace(Perfy_GetTime(), "Leave", "BetterFriendlistSettings_OnColorClassNamesChanged file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\BetterFriendlist_Settings.lua:192:0"); end

-- Hide empty groups changed
function BetterFriendlistSettings_OnHideEmptyGroupsChanged(checked) Perfy_Trace(Perfy_GetTime(), "Enter", "BetterFriendlistSettings_OnHideEmptyGroupsChanged file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\BetterFriendlist_Settings.lua:200:0");
local Settings = GetSettings()
if Settings then
Settings:OnHideEmptyGroupsChanged(checked)
end
Perfy_Trace(Perfy_GetTime(), "Leave", "BetterFriendlistSettings_OnHideEmptyGroupsChanged file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\BetterFriendlist_Settings.lua:200:0"); end

-- Show Faction Icons toggle
function BetterFriendlistSettings_OnShowFactionIconsChanged(checked) Perfy_Trace(Perfy_GetTime(), "Enter", "BetterFriendlistSettings_OnShowFactionIconsChanged file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\BetterFriendlist_Settings.lua:208:0");
local Settings = GetSettings()
if Settings then
Settings:OnShowFactionIconsChanged(checked)
end
Perfy_Trace(Perfy_GetTime(), "Leave", "BetterFriendlistSettings_OnShowFactionIconsChanged file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\BetterFriendlist_Settings.lua:208:0"); end

-- Show Realm Name toggle
function BetterFriendlistSettings_OnShowRealmNameChanged(checked) Perfy_Trace(Perfy_GetTime(), "Enter", "BetterFriendlistSettings_OnShowRealmNameChanged file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\BetterFriendlist_Settings.lua:216:0");
local Settings = GetSettings()
if Settings then
Settings:OnShowRealmNameChanged(checked)
end
Perfy_Trace(Perfy_GetTime(), "Leave", "BetterFriendlistSettings_OnShowRealmNameChanged file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\BetterFriendlist_Settings.lua:216:0"); end

-- Show Favorites Group toggle
function BetterFriendlistSettings_OnShowFavoritesGroupChanged(checked) Perfy_Trace(Perfy_GetTime(), "Enter", "BetterFriendlistSettings_OnShowFavoritesGroupChanged file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\BetterFriendlist_Settings.lua:224:0");
local Settings = GetSettings()
if Settings then
Settings:OnShowFavoritesGroupChanged(checked)
end
Perfy_Trace(Perfy_GetTime(), "Leave", "BetterFriendlistSettings_OnShowFavoritesGroupChanged file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\BetterFriendlist_Settings.lua:224:0"); end

-- Gray Other Faction toggle
function BetterFriendlistSettings_OnGrayOtherFactionChanged(checked) Perfy_Trace(Perfy_GetTime(), "Enter", "BetterFriendlistSettings_OnGrayOtherFactionChanged file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\BetterFriendlist_Settings.lua:232:0");
local Settings = GetSettings()
if Settings then
Settings:OnGrayOtherFactionChanged(checked)
end
Perfy_Trace(Perfy_GetTime(), "Leave", "BetterFriendlistSettings_OnGrayOtherFactionChanged file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\BetterFriendlist_Settings.lua:232:0"); end

-- Show Mobile as AFK toggle
function BetterFriendlistSettings_OnShowMobileAsAFKChanged(checked) Perfy_Trace(Perfy_GetTime(), "Enter", "BetterFriendlistSettings_OnShowMobileAsAFKChanged file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\BetterFriendlist_Settings.lua:240:0");
local Settings = GetSettings()
if Settings then
Settings:OnShowMobileAsAFKChanged(checked)
end
Perfy_Trace(Perfy_GetTime(), "Leave", "BetterFriendlistSettings_OnShowMobileAsAFKChanged file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\BetterFriendlist_Settings.lua:240:0"); end

-- Hide Max Level toggle
function BetterFriendlistSettings_OnHideMaxLevelChanged(checked) Perfy_Trace(Perfy_GetTime(), "Enter", "BetterFriendlistSettings_OnHideMaxLevelChanged file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\BetterFriendlist_Settings.lua:248:0");
local Settings = GetSettings()
if Settings then
Settings:OnHideMaxLevelChanged(checked)
end
Perfy_Trace(Perfy_GetTime(), "Leave", "BetterFriendlistSettings_OnHideMaxLevelChanged file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\BetterFriendlist_Settings.lua:248:0"); end

-- Accordion Groups toggle
function BetterFriendlistSettings_OnAccordionGroupsChanged(checked) Perfy_Trace(Perfy_GetTime(), "Enter", "BetterFriendlistSettings_OnAccordionGroupsChanged file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\BetterFriendlist_Settings.lua:256:0");
local Settings = GetSettings()
if Settings then
Settings:OnAccordionGroupsChanged(checked)
end
Perfy_Trace(Perfy_GetTime(), "Leave", "BetterFriendlistSettings_OnAccordionGroupsChanged file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\BetterFriendlist_Settings.lua:256:0"); end

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
OnAccept = function() Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\BetterFriendlist_Settings.lua:278:11");
BetterFriendlistSettings_DoReset()
Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\BetterFriendlist_Settings.lua:278:11"); end,
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

Perfy_Trace(Perfy_GetTime(), "Leave", "(main chunk) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\BetterFriendlist_Settings.lua");