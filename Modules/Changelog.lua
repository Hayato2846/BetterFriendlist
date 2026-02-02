-- Modules/Changelog.lua
-- Displays the changelog in a scrollable window

local ADDON_NAME, BFL = ...
local L = BFL.L
local Changelog = BFL:RegisterModule("Changelog", {})

local changelogFrame = nil

-- Changelog content
local CHANGELOG_TEXT = [[
# Changelog

All notable changes to BetterFriendlist will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [2.2.8] - 2026-02-02
### Added
- **Streamer Mode** - Added Streamer Mode! When enabled you can toggle streamer mode to hide friend informations like Real IDs or your own battletag for privacy reasons. Real IDs will be hidden for following UI elements: Friend Name, Friend Tooltip, QuickJoin. You can change your own BattleTag with custom text in settings.
- **Favorite Icons** - Added an option to toggle the star icon for favorites directly on the friend button (Settings -> General). While enabled, favorite friends will be sorted above other friends in the same sorting subgroup.
- **Faction Backgrounds** - Added an option to show faction-colored backgrounds (Blue/Red) for friends in the list (Settings -> General).
- **Friend List Colors Support** - Automatically disables Name Format settings when "FriendListColors" addon is detected. When Friend List Colors is enabled all the name formatting actions will be led by the addon (Streamer Mode excluded).
- **Settings Layout** - Updated settings layout to better support future categories.
- **More Font Settings** - Added Font Settings for Tab Texts and Raid Player Name.
- **Window Lock Option** - Added option to lock the window to prevent moving it accidentally.

### Changed
- **Global Sync** - Global Sync is now flagged as stable feature and can be used without enabling beta features in BFL.

### Removed
- **Edit Mode** - Abandoned BFL's Edit Mode Support for now. Settings for width, height and scale can be found in settings instead. If the position, width, height or scale is different after the update please adjust it again - I wasn't able to restore all variants of Edit Mode Profiles to my settings. Sorry for the inconvenience!
- **Notification System** - Removed Notification Beta System for now. Might be added again in the future

### Fixed
- **Broker Tooltip** - Resolved an issue where the tooltip would not display correctly with display addons like ChocolateBar.
- **ElvUI Skin** - Fixed a Lua error ("index field 'BFLCheckmark'") that could occur when other addons (like ToyBoxEnhanced) create menus that BetterFriendlist tries to skin.
- **Groups Cache** - Fixed an issue with groups caching sometimes not updating properly when changing groups of a friend.

## [2.2.7] - 2026-01-31
### Fixed
- **Library** - Fixed potential issues with LibQTip library integration.

## [2.2.6] - 2026-01-31
### Added
- **Simple Mode** - Added Simple Mode in Settings -> General. Simple Mode hides specific elements (Search, Filter, Sort, BFL Avatar) and moves corresponding functions in the menu button
- **ElvUI Skin Tabs** - Improved alignment of tab text and overall layout of all tabs of BFL in ElvUI Skin
- **Copy Character Name** - Added an option to copy the character name and realm from the friends list context menu.

### Fixed
- **Friend Groups Migration** - Fixed an issue with FriendGroups Migration for WoW friends. Added more debug logs to better help with issues.
- **ElvUI Skin Retail** - Fixed an error with ElvUI Retail Skinning
- **ElvUI Skin Classic** - Fixed and enabled ElvUI Classic Skin
- **QuickJoin Informations** - Fixed an issue with shown QuickJoin informations lacking details of queued content type
- **Broker Integration** - Fixed an issue that disabled the Broker BFL Plugin
- **Performance** - Third iteration of performance added. If anything feels odd don't hesitate to contact
- **RAF** - Fixed an issue blocking the usage of copy link button in RAF Frame
- **Global Sync** - Fixed an error occuring while having own characters in sync added

## [2.2.5] - 2026-01-25
### Fixed
- **Combat Blocking Fix** - Fixed a critical issue where the Friends List window could not be opened during combat, even when UI Panel settings were disabled. This resolves the "ADDON_ACTION_BLOCKED" error caused by unnecessary secure templates.
- **Localization** - Fixed encoding issues in English localization (enUS) where bullets and arrows were displayed as corrupted characters.

## [2.2.4] - 2026-01-25
### Fixed
- **Mojibake Fix** - Fixed an issue where localized text (German, French, etc.) could display incorrect characters. (Core.lua)
- **QuickJoin** - Fixed quick join tooltips.
- **Edit Mode** - Fixed visibility issues when entering Edit Mode.

## [2.2.3] - 2026-01-25
### Added
- **Typography Settings** - Added detailed font customization for Friend Names, Friend Info, and Group Headers. (Shadow settings coming soon).
- **Ignore List Enhancements** - Added support for "Global Ignore List" addon in our improved Ignore List frame, including a quick-toggle button.
- **Settings Overhaul** - Started restructuring the Settings panel for better organization. More improvements to come!
- **Group Visuals** - Added color customization for Group Collapse Arrows and Group Member Counts.
- **Classic Visuals** - Improved the visual design of collapse and expand arrows for group headers in Classic versions.

### Fixed
- **Edit Mode Stability** - Fixed an issue where opening Edit Mode immediately on startup (by other addons) would show BFL in an invalid state if no friend data was present.
- **Classic Localization** - Fixed missing localization keys for the Ignore List in Classic versions.
- **Visual Consistency** - Fixed the default friend name color to perfectly match Blizzard's standard UI color.
- **Quick Join Tooltips** - Fixed the "Request to Join" tooltip on travel pass buttons to show the correct group information.
- **Migration Notifications** - Fixed a bug where the "Migration Successful" message would appear after every UI reload.
- **Performance** - Implemented the second iteration of performance fixes for smoother scrolling and updates.
- **Housing System** - Fixed an issue preventing players from visiting friends' houses.
- **Startup Stability** - Fixed an issue where BetterFriendlist would remain open if other addons forcibly entered and exited Edit Mode during startup.
- **Combat Protection** - Added combat protection for UI Panel attributes.
- **Activity Tracker** - Added secret value protection in ActivityTracker for Midnight.

## [2.2.2] - 2026-01-18
### Fixed
- **Font Support** - Reverted the friend name font to `GameFontNormal`. This restores support for the 4 standard fonts (including Asian/Cyrillic characters).
- **ElvUI Interaction** - **Note:** ElvUI Font Size settings now apply to the Friend Name again.
- **Workaround** - This is a temporary workaround. Proper independent font settings will be added in the next version.

## [2.2.1] - 2026-01-18
### Fixed
- **Slash Commands** - Cleanup of slash commands.
- **Performance** - Fixed performance issues. (Reported by Drakblackz)
- **Menu System** - Fixed issue where menus would not close properly, likely due to mouse cursor changes. (Reported by Atom)

## [2.2.0] - 2026-01-17
### Added
- **Group Name Alignment** - Added a new option to align group headers (Left, Center, Right). Left alignment is now the default. (Reported by Drakblackz)
- **Collapse/Expand Arrow** - Added options to hide the collapse/expand arrow and change its alignment (Left, Center, Right). Left is default. (Reported by Drakblackz)
- **Settings Button** - Added a dedicated cogwheel button to the main frame for easier access to settings, making it more discoverable for new users. (Reported by Atom)

### Fixed
- **Class Coloring** - Fixed an issue with class coloring not working correctly for some languages. (Reported by Drakblackz)
- **Performance** - Investigated and fixed small freezes that could occur when collapsing/expanding groups. (Reported by Drakblackz)
- **ElvUI Skin** - Fixed a Lua error related to the ElvUI skin integration. (Reported by Seiryoku)
- **ElvUI Skin** - Fixed skinning issues where ElvUI styles were not properly applied to some newer UI elements.
- **Send Message Button** - Fixed the "Send Message" button not working correctly in some scenarios. (Reported by Kylani)
- **Settings UI** - Fixed an issue where some dropdowns in general settings would not display their selected value.
- **Font Scaling** - Fixed visual issues with dropdowns and tab texts when global font size is overridden by other addons (e.g., ElvUI). (Reported by Drakblackz)
- **Sorting** - Fixed the Alphabetical Name sorter not working properly. (Reported by Drakblackz)

## [2.1.9] - 2026-01-16
### Added
- **Global Ignore List Support** - Added a compatibility module for the "Global Ignore List" addon. The GIL window now correctly anchors to the BetterFriendlist frame (Main, Settings, Help, or Raid Info) and opens/closes automatically. (reported by Kiley01)

## [2.1.8] - 2026-01-15
### Fixed
- **Critical Crash Fix** - Fixed "attempt to index global 'L' (a nil value)" error that prevented the Friends List from opening after the 2.1.7 update. Added missing localization table reference in FriendsList.lua.

## [2.1.7] - 2026-01-14
### Fixed
- **Tab Switching Bug** - Fixed an issue where switching from "Who" or "Raid" back to "Contacts" would incorrectly display the Friends list even when "Recent Allies" or "Recruit A Friend" tabs were active.
- **Localization Fallback** - Improved fallback logic for missing translations. The addon now automatically uses English text when a translation is missing instead of displaying variable names.
- **Localization (All Languages)** - Significantly improved translations across all 11 supported languages. The German localization has been completely reworked to be less formal and more natural.

## [2.1.6] - 2026-01-12
### Fixed
- **Quick Filters (Classic)** - Fixed a Lua error ("attempt to call method 'SetFilter' a nil value") when selecting a filter in the Classic version (reported by Loro).

## [2.1.5] - 2026-01-11
### Added
- **Localization Update** - Significantly improved translation coverage across all 11 supported languages, especially for Raid Frame and Help features.
- **Asian Language Support** - Fixed issues with missing localization keys in Korean (koKR), Simplified Chinese (zhCN), and Traditional Chinese (zhTW).
- **Classic Guild Support** - Added better support for guilds in Classic. The addon now automatically disables the 'Classic Guild UI' setting as it requires the modern Guild UI.
- **Classic Guild Tab** - Added a Guild Tab in Classic which opens the modern guild window on click.
- **Classic Settings** - Added two new settings in Classic: 'Hide Guild Tab' and 'Close BetterFriendlist when opening Guild'.
- **UI Hierarchy** - Added a new setting for Retail and Classic: 'Respect UI Hierarchy'. This integrates BetterFriendlist into Blizzard's UI Panel System so it no longer overlaps other UI windows. (Requested by Surfingnet)
- **Raid Frame Help** - Added a Help Button to the Raid Tab explaining unique features like Multi-Selection, Drag & Drop, and Main Tank/Assist assignments.

## [2.1.4] - 2026-01-07
### Fixed
- **Ignore List (Classic)** - Fixed visual layout issues in the Ignore List window:
  - Removed top gap ensuring the empty list starts at the correct position.
  - Replaced legacy scrollbar with standard UIPanelScrollBar for better visibility and usability.
  - Fixed "Unignore Player" button text displaying as a variable name instead of localized text.

## [2.1.3] - 2026-01-06

### Fixed
- **Classic Portrait Button** - Fixed the PortraitButton frame strata and frame level. It now sits correctly above the frame but below dialogs (reported by Twoti).
- **Classic Invites** - Fixed a Lua error when viewing friend invites in Classic versions (missing text element) (reported by Twoti).

## [2.1.2] - 2026-01-05

### Fixed
- **QuickFilter Persistence** - Fixed a bug where QuickFilter dropdown changes were not persistently saved, causing updates to apply previously cached values (reported by Loro).
- **QuickFilter UI** - Removed the separator line between QuickFilter dropdown options.
- **Hide AFK/DND** - Fixed "Hide AFK/DND" QuickFilter logic to correctly hide AFK/DND friends as expected.

## [2.1.1] - 2026-01-03

### Fixed
- **FriendGroups Migration** - Fixed an issue where the migration could not be re-run if it had already been completed.

## [2.1.0] - 2026-01-03

### Added
- **CustomNames Support** - Added support for the `CustomNames` library to sync nicknames (Thanks Jods!).

### Fixed
- **Group Cache** - Fixed an issue where newly created groups were not immediately available in the cache (reported by m33shoq).

## [2.0.9] - 2026-01-03

### Added
- **ElvUI Skin** - Added full skinning support for the Changelog window and the Portrait/Changelog button.
- **ElvUI Stability** - Added comprehensive debug logging and error handling for the skinning process.

### Improved
- **Debug Logs** - Cleaned up global debug logs to reduce chat spam.

## [2.0.8] - 2026-01-03

### Fixed
- **Data Broker Conflict** - Fixed a conflict with other Data Broker addons (like Broker Everything) where tooltips could become empty or stuck.
- **Tooltip Stability** - Improved robustness of tooltip cleanup and auto-hide logic to prevent resource leaks and ensure correct closing behavior.

## [2.0.7] - 2026-01-01

### Fixed
- **Classic Dropdowns** - Fixed missing tooltips and incorrect width for QuickFilter and Sort dropdowns in Classic versions.
- **UI Insets** - Adjusted frame insets for better visual alignment.

## [2.0.6] - 2026-01-01

### Fixed
- **Battle.net Context Menu** - Fixed missing options in the right-click menu for Battle.net friends. Restored correct parameter passing to match Blizzard's expected format (regression from v2.0.5).

## [2.0.5] - 2026-01-01

### Fixed
- **Crash Fix** - Fixed a crash ("script ran too long") caused by infinite recursion in group migration.
- **Performance** - Optimized event handling to prevent freezing during large friend list updates.
- **Who Frame** - Improved UI positioning for buttons in the Who tab (centering).
- **Quick Join** - Minor UI adjustments in the Quick Join tab.

## [2.0.4] - 2026-01-01

### Fixed
- **Crash Fix** - Fixed a Lua error that could occur when logging in if the friend list was not yet fully initialized (`'for' limit must be a number`).

## [2.0.3] - 2026-01-01

### Added
- **Global Friend Sync** (Beta) - Automatically syncs your WoW friends across all your characters. Includes support for Connected Realms (e.g. syncing friends between "Burning Blade" and "Draenor"). Configurable via Settings -> Advanced -> Beta Features.

### Changed
- **Data Broker Module** - Promoted from Beta to Standard feature. Now available to all users without enabling Beta Features.

### Fixed
- **Group Creation** - Fixed an issue when creating groups via right-click on WoW Friends.
]]

-- Helper to set title safely across versions
local function SetTitle(frame, title)
    if frame.TitleText and frame.TitleText.SetText then
        frame.TitleText:SetText(title)
    elseif frame.TitleContainer and frame.TitleContainer.TitleText then
        frame.TitleContainer.TitleText:SetText(title)
    end
end

local function StripEmojis(text)
    -- 1. Replace specific symbols
    text = text:gsub("→", ">")
    
    -- 2. Remove known emojis
    local emojis = {
        "🚀", "⚡", "🔗", "🔌", "🎯", "🔔", "🐛", "🔧", "✨", "📝", 
        "🌍", "🎮", "📨", "🛡️", "📊", "🎉", "🎨", "📋", "✅"
    }
    for _, emoji in ipairs(emojis) do
        text = text:gsub(emoji, "")
    end

    -- 3. Catch-all for 4-byte characters (Generic Emoji range)
    text = text:gsub("[\240-\247][\128-\191][\128-\191][\128-\191]", "")
    
    return text
end

local function CleanLine(line)
    -- Remove comments
    line = line:gsub("/%*.-%*/", "")
    -- Remove emojis
    line = StripEmojis(line)
    -- Remove backticks
    line = line:gsub("`", "")
    -- Trim whitespace
    return line:gsub("^%s+", "")
end

local function FormatInline(text)
    -- Bold **text**
    text = text:gsub("%*%*(.-)%*%*", "|cffffffff%1|r")
    -- Links
    text = text:gsub("%[(.-)%]%((.-)%)", "|cff66bbff%1|r")
    return text
end

local function ParseChangelog(text)
    local entries = {}
    local currentEntry = nil
    
    for line in text:gmatch("[^\r\n]+") do
        local version, date = line:match("^## %[(.-)%] %- (.+)")
        if version then
            if currentEntry then
                table.insert(entries, currentEntry)
            end
            currentEntry = {
                version = version,
                date = date,
                blocks = {}
            }
        elseif currentEntry then
            local cleanLine = CleanLine(line)
            if cleanLine ~= "" then
                -- Determine block type
                if cleanLine:match("^# ") then
                    table.insert(currentEntry.blocks, {
                        type = "h1",
                        content = FormatInline(cleanLine:gsub("^# ", ""))
                    })
                elseif cleanLine:match("^#### ") then
                    table.insert(currentEntry.blocks, {
                        type = "h4",
                        content = FormatInline(cleanLine:gsub("^#### ", ""))
                    })
                elseif cleanLine:match("^### ") then
                    table.insert(currentEntry.blocks, {
                        type = "h3",
                        content = FormatInline(cleanLine:gsub("^### ", ""))
                    })
                elseif cleanLine:match("^%- ") then
                    table.insert(currentEntry.blocks, {
                        type = "list_item",
                        content = FormatInline(cleanLine:gsub("^%- ", ""))
                    })
                elseif cleanLine:match("^%-%-%-") or cleanLine:match("^%*%*%*") or cleanLine:match("^___") then
                    table.insert(currentEntry.blocks, {
                        type = "separator"
                    })
                else
                    table.insert(currentEntry.blocks, {
                        type = "text",
                        content = FormatInline(cleanLine)
                    })
                end
            end
        end
    end
    
    if currentEntry then
        table.insert(entries, currentEntry)
    end
    
    return entries
end

local function RecalculateHeight(contentFrame, entryFrames)
    local totalHeight = 10
    for _, frame in ipairs(entryFrames) do
        totalHeight = totalHeight + frame:GetHeight() + 5
    end
    contentFrame:SetHeight(totalHeight)
end

local function ShowCopyDialog(url, title)
    StaticPopupDialogs["BETTERFRIENDLIST_COPY_URL"] = {
        text = title or "Copy URL",
        button1 = "Close",
        hasEditBox = true,
        editBoxWidth = 350,
        OnShow = function(self)
            self.EditBox:SetText(url)
            self.EditBox:SetFocus()
            self.EditBox:HighlightText()
        end,
        EditBoxOnEnterPressed = function(self)
            self:GetParent():Hide()
        end,
        EditBoxOnEscapePressed = function(self)
            self:GetParent():Hide()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
    StaticPopup_Show("BETTERFRIENDLIST_COPY_URL")
end

function Changelog:ShowDiscordPopup()
    ShowCopyDialog("https://discord.gg/dpaV8vh3w3", L.CHANGELOG_POPUP_DISCORD)
end

function Changelog:Initialize()
    -- Setup PortraitButton for Classic - create entirely in Lua for full control
    if BFL.IsClassic and BetterFriendsFrame then
        self:SetupClassicPortraitButton()
    end
    
    -- Check version and show glow if needed
    self:CheckVersion()
end

function Changelog:SetupClassicPortraitButton()
    local frame = BetterFriendsFrame
    if not frame then 
        return 
    end
    
    -- Hide the default portrait from ButtonFrameTemplate
    if frame.portrait then 
        frame.portrait:Hide() 
    end
    
    -- Create clickable button as child of the frame (ensures correct Z-ordering with other windows)
    -- This fixes the issue where it covers other UI frames like CharacterInfo
    local button = CreateFrame("Button", "BFL_ClassicPortraitButton", frame)
    button:SetSize(60, 60)
    
    -- Ensure it sits above the frame background
    button:SetFrameLevel(frame:GetFrameLevel() + 5)
    
    button:EnableMouse(true)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    
    -- Invisible hit rect (needed for click detection)
    local hitRect = button:CreateTexture(nil, "BACKGROUND")
    hitRect:SetAllPoints()
    hitRect:SetTexture("Interface\\BUTTONS\\WHITE8X8")
    hitRect:SetVertexColor(0, 0, 0, 0)  -- Fully transparent
    
    -- Portrait Icon 
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetTexture("Interface\\AddOns\\BetterFriendlist\\Textures\\PortraitIcon")
    icon:SetSize(60, 60)
    icon:SetPoint("CENTER")
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    button.Icon = icon
    
    -- Apply circular mask to the icon
    local mask = button:CreateMaskTexture()
    mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    mask:SetSize(60, 60)
    mask:SetPoint("CENTER")
    icon:AddMaskTexture(mask)
    
    -- Glow texture for new version notification (hidden by default)
    -- Using CurrentPlayer-Glow from tournamentorganizer (exists in Classic)
    -- Positioned like Retail: TOPLEFT x=-18 y=12, BOTTOMRIGHT x=64 y=-64 relative to 60x60 button
    local glow = button:CreateTexture(nil, "OVERLAY", nil, 7)
    glow:SetTexture("Interface\\PVPFrame\\TournamentOrganizer")
    glow:SetTexCoord(0.3173828125, 0.4423828125, 0.0341796875, 0.1591796875)
    glow:SetBlendMode("ADD")
    glow:ClearAllPoints()
    glow:SetPoint("TOPLEFT", button, "TOPLEFT", -18, 16)
    glow:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 64, -64)
    glow:SetVertexColor(1.0, 1.0, 1.0, 1.0)  -- White like Retail
    glow:Hide()
    button.Glow = glow
    
    -- Position relative to main frame
    button:ClearAllPoints()
    button:SetPoint("TOPLEFT", -5, 7)
    
    -- Click handler
    button:SetScript("OnClick", function(self, btn)
        local Changelog = BFL:GetModule("Changelog")
        if Changelog then
            Changelog:ToggleChangelog()
        end
    end)
    
    -- Hover handlers
    button:SetScript("OnEnter", function(self)
        local Changelog = BFL:GetModule("Changelog")
        if Changelog then
            Changelog:OnPortraitEnter(self)
        end
    end)
    
    button:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
    
    -- No need to manual sync visibility if it's a child, but let's be safe if it gets parented elsewhere in future
    -- Actually, child frame automatically hides when parent hides. 
    -- But we keep the reference logic.
    
    -- Store reference
    frame.PortraitButton = button
    frame.PortraitIcon = icon
    
    -- BFL:DebugPrint("Changelog", "Classic PortraitButton created")
end

function Changelog:CheckVersion()
    local DB = BFL:GetModule("DB")
    local lastVersion = DB:Get("lastChangelogVersion", "0.0.0")
    local currentVersion = BFL.VERSION
    
    if lastVersion ~= currentVersion then
        self:ShowGlow(true)
    else
        self:ShowGlow(false)
    end
end

function Changelog:ShowGlow(show)
    if BetterFriendsFrame and BetterFriendsFrame.PortraitButton then
        local button = BetterFriendsFrame.PortraitButton
        
        -- Create NewLabel texture if it doesn't exist
        if not button.NewLabel then
            button.NewLabel = button:CreateTexture(nil, "OVERLAY")
            button.NewLabel:SetPoint("CENTER", button, "CENTER", 0, 0)
            if BFL.IsClassic then
                -- Use NewCharacter-Horde texture from CharacterCreate (exists in Classic)
                --button.NewLabel:SetTexture("interface\\encounterjournal\\adventureguide")
                --button.NewLabel:SetTexCoord(0.677734375, 0.75, 0.099609375, 0.171875)
                --button.NewLabel:SetSize(37, 37)  -- Scaled down from 112x58
                button.NewLabel:SetAtlas("communities-icon-invitemail")
                button.NewLabel:SetSize(64, 48)
            else
                button.NewLabel:SetAtlas("CharacterCreate-NewLabel")
                button.NewLabel:SetSize(64, 48)
            end
            -- Desaturate to remove the native color, then color it gold
            button.NewLabel:SetDesaturated(true)
            button.NewLabel:SetVertexColor(1, 0.82, 0, 1)
        end

        if show then
            if button.Glow then button.Glow:Show() end
            if button.NewLabel then button.NewLabel:Show() end
        else
            if button.Glow then button.Glow:Hide() end
            if button.NewLabel then button.NewLabel:Hide() end
        end
    end
end

function Changelog:ToggleChangelog()
    if not changelogFrame then
        self:CreateChangelogWindow()
    end
    
    if changelogFrame:IsShown() then
        changelogFrame:Hide()
    else
        changelogFrame:Show()
        -- Update version in DB
        local DB = BFL:GetModule("DB")
        DB:Set("lastChangelogVersion", BFL.VERSION)
        self:ShowGlow(false)
    end
end

function Changelog:OnPortraitEnter(button)
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    GameTooltip:SetText("BetterFriendlist " .. (BFL.VERSION or ""), 1, 0.82, 0)
    
    local DB = BFL:GetModule("DB")
    local lastVersion = DB:Get("lastChangelogVersion", "0.0.0")
    
    if lastVersion ~= BFL.VERSION then
        GameTooltip:AddLine(L.CHANGELOG_TOOLTIP_UPDATE, 0, 1, 0)
        GameTooltip:AddLine(L.CHANGELOG_TOOLTIP_CLICK, 1, 1, 1)
    else
        GameTooltip:AddLine(L.CHANGELOG_TOOLTIP_CLICK, 1, 1, 1)
    end
    
    GameTooltip:Show()
end

function Changelog:Show()
    self:ToggleChangelog()
end

function Changelog:CreateChangelogWindow()
    -- Use ButtonFrameTemplate to match Settings window
    local frame = CreateFrame("Frame", "BetterFriendlistChangelogFrame", UIParent, "ButtonFrameTemplate")
    frame:SetSize(600, 500)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    
    -- Setup ButtonFrameTemplate features
    if frame.portrait then frame.portrait:Hide() end
    if frame.PortraitContainer then frame.PortraitContainer:Hide() end
    
    if ButtonFrameTemplate_HidePortrait then
        ButtonFrameTemplate_HidePortrait(frame)
    end
    if ButtonFrameTemplate_HideAttic then
        ButtonFrameTemplate_HideAttic(frame)
    end
    
    -- Hide default Inset
    if frame.Inset then frame.Inset:Hide() end
    
    SetTitle(frame, L.CHANGELOG_TITLE)
    
    -- Create MainInset to match Settings style
    local mainInset = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    frame.MainInset = mainInset
    mainInset:SetPoint("TOPLEFT", 10, -25) -- Adjusted y since we don't have tabs
    mainInset:SetPoint("BOTTOMRIGHT", -4, 5) -- Adjusted y since we don't have bottom buttons
    
    mainInset:SetBackdrop({
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 6,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    mainInset:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.8)

    -- Header Frame (Links)
    local headerFrame = CreateFrame("Frame", nil, mainInset)
    headerFrame:SetPoint("TOPLEFT", 1, -1)
    headerFrame:SetPoint("TOPRIGHT", -1, -1)
    headerFrame:SetHeight(40)
    
    -- Background for header
    local headerBg = headerFrame:CreateTexture(nil, "BACKGROUND")
    headerBg:SetAllPoints()
    headerBg:SetColorTexture(0.1, 0.1, 0.1, 0.5)

    -- Separator line
    local headerLine = headerFrame:CreateTexture(nil, "ARTWORK")
    headerLine:SetHeight(1)
    headerLine:SetPoint("BOTTOMLEFT", 0, 0)
    headerLine:SetPoint("BOTTOMRIGHT", 0, 0)
    headerLine:SetColorTexture(0.4, 0.4, 0.4, 0.8)

    -- Intro Text
    local headerText = headerFrame:CreateFontString(nil, "OVERLAY", "BetterFriendlistFontNormal")
    headerText:SetPoint("LEFT", 10, 0)
    headerText:SetText(L.CHANGELOG_HEADER_COMMUNITY)

    -- Discord Button (Rightmost)
    local discordBtn = CreateFrame("Button", nil, headerFrame, "UIPanelButtonTemplate")
    frame.DiscordButton = discordBtn
    discordBtn:SetSize(130, 24)
    discordBtn:SetPoint("RIGHT", -10, 0)
    discordBtn:SetText(L.CHANGELOG_DISCORD)
    
    local dcIcon = discordBtn:CreateTexture(nil, "ARTWORK")
    dcIcon:SetSize(14, 14)
    dcIcon:SetPoint("LEFT", 10, 0)
    dcIcon:SetColorTexture(1, 0.82, 0) -- Gold
    
    local dcMask = discordBtn:CreateMaskTexture()
    dcMask:SetSize(14, 14)
    dcMask:SetPoint("LEFT", 10, 0)
    dcMask:SetTexture("Interface\\AddOns\\BetterFriendlist\\Icons\\discord.blp")
    dcIcon:AddMaskTexture(dcMask)
    
    discordBtn:SetScript("OnClick", function()
        ShowCopyDialog("https://discord.gg/dpaV8vh3w3", L.CHANGELOG_POPUP_DISCORD)
    end)

    -- GitHub Button (Left of Discord)
    local githubBtn = CreateFrame("Button", nil, headerFrame, "UIPanelButtonTemplate")
    frame.GitHubButton = githubBtn
    githubBtn:SetSize(130, 24)
    githubBtn:SetPoint("RIGHT", discordBtn, "LEFT", -10, 0)
    githubBtn:SetText(L.CHANGELOG_GITHUB)
    
    local ghIcon = githubBtn:CreateTexture(nil, "ARTWORK")
    ghIcon:SetSize(14, 14)
    ghIcon:SetPoint("LEFT", 10, 0)
    ghIcon:SetColorTexture(1, 0.82, 0) -- Gold
    
    local ghMask = githubBtn:CreateMaskTexture()
    ghMask:SetSize(14, 14)
    ghMask:SetPoint("LEFT", 10, 0)
    ghMask:SetTexture("Interface\\AddOns\\BetterFriendlist\\Icons\\github.blp")
    ghIcon:AddMaskTexture(ghMask)
    
    githubBtn:SetScript("OnClick", function()
        ShowCopyDialog("https://github.com/Hayato2846/BetterFriendlist/issues", L.CHANGELOG_POPUP_GITHUB)
    end)

    -- Ko-fi Button (Left of GitHub)
    local kofiBtn = CreateFrame("Button", nil, headerFrame, "UIPanelButtonTemplate")
    frame.KoFiButton = kofiBtn
    kofiBtn:SetSize(130, 24)
    kofiBtn:SetPoint("RIGHT", githubBtn, "LEFT", -10, 0)
    kofiBtn:SetText(L.CHANGELOG_SUPPORT)
    
    local kofiIcon = kofiBtn:CreateTexture(nil, "ARTWORK")
    kofiIcon:SetSize(14, 14)
    kofiIcon:SetPoint("LEFT", 10, 0)
    kofiIcon:SetColorTexture(1, 0.82, 0) -- Gold
    
    local kofiMask = kofiBtn:CreateMaskTexture()
    kofiMask:SetSize(14, 14)
    kofiMask:SetPoint("LEFT", 10, 0)
    kofiMask:SetTexture("Interface\\AddOns\\BetterFriendlist\\Icons\\kofi.blp")
    kofiIcon:AddMaskTexture(kofiMask)
    
    kofiBtn:SetScript("OnClick", function()
        ShowCopyDialog("https://ko-fi.com/hayato2846", L.CHANGELOG_POPUP_SUPPORT)
    end)

    -- ScrollFrame
    local scrollFrame
    
    if not BFL.IsClassic and ScrollUtil and ScrollUtil.InitScrollFrameWithScrollBar then
        -- Retail: Modern ScrollUtil
        scrollFrame = CreateFrame("ScrollFrame", nil, frame)
        frame.ScrollFrame = scrollFrame
        scrollFrame:SetPoint("TOPLEFT", mainInset, "TOPLEFT", 8, -45) -- Adjusted for header
        scrollFrame:SetPoint("BOTTOMRIGHT", mainInset, "BOTTOMRIGHT", -25, 5)
        
        -- Mixin CallbackRegistry (Required for ScrollUtil)
        if not scrollFrame.RegisterCallback then
            Mixin(scrollFrame, CallbackRegistryMixin)
            scrollFrame:OnLoad()
        end
        
        -- Create ScrollBar (EventFrame inheriting MinimalScrollBar)
        local scrollBar = CreateFrame("EventFrame", nil, frame, "MinimalScrollBar")
        frame.ScrollBar = scrollBar
        scrollBar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", 6, 0)
        scrollBar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", 6, 0)
        
        ScrollUtil.InitScrollFrameWithScrollBar(scrollFrame, scrollBar)
    else
        -- Classic: Legacy UIPanelScrollFrameTemplate
        scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
        frame.ScrollFrame = scrollFrame
        scrollFrame:SetPoint("TOPLEFT", mainInset, "TOPLEFT", 8, -45) -- Adjusted for header
        scrollFrame:SetPoint("BOTTOMRIGHT", mainInset, "BOTTOMRIGHT", -25, 5)
    end
    
    -- Content
    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(560, 1000) -- Height will be adjusted
    scrollFrame:SetScrollChild(content)
    
    local entries = ParseChangelog(CHANGELOG_TEXT)
    local entryFrames = {}
    local previousFrame = nil
    
    for i, entryData in ipairs(entries) do
        local entryFrame = CreateFrame("Frame", nil, content)
        entryFrame:SetWidth(530)
        
        if previousFrame then
            entryFrame:SetPoint("TOPLEFT", previousFrame, "BOTTOMLEFT", 0, -5)
        else
            entryFrame:SetPoint("TOPLEFT", 0, -5)
        end
        
        -- Header
        local header = CreateFrame("Button", nil, entryFrame)
        header:SetSize(530, 20)
        header:SetPoint("TOPLEFT")
        
        -- Icon
        local icon = header:CreateTexture(nil, "ARTWORK")
        icon:SetSize(16, 16)
        icon:SetPoint("LEFT", 5, 0)
        icon:SetTexture("Interface\\AddOns\\BetterFriendlist\\Icons\\chevron-right.blp")
        
        -- Title
        local title = header:CreateFontString(nil, "OVERLAY", "BetterFriendlistFontNormal")
        title:SetPoint("LEFT", icon, "RIGHT", 5, 0)
        title:SetText(string.format(L.CHANGELOG_HEADER_VERSION, entryData.version))

        -- Date
        local dateLabel = header:CreateFontString(nil, "OVERLAY", "BetterFriendlistFontNormal")
        dateLabel:SetPoint("RIGHT", header, "RIGHT", -5, 0)
        dateLabel:SetText(entryData.date)
        
        -- Content
        local entryContent = CreateFrame("Frame", nil, entryFrame)
        entryContent:SetWidth(530)
        entryContent:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -5)
        
        local currentY = -5
        for _, block in ipairs(entryData.blocks) do
            if block.type == "h1" then
                local fs = entryContent:CreateFontString(nil, "OVERLAY", "BetterFriendlistFontLarge")
                fs:SetPoint("TOPLEFT", 10, currentY)
                fs:SetWidth(510)
                fs:SetJustifyH("LEFT")
                fs:SetText(block.content)
                currentY = currentY - fs:GetStringHeight() - 10
            elseif block.type == "h3" then
                local fs = entryContent:CreateFontString(nil, "OVERLAY", "BetterFriendlistFontNormal")
                fs:SetPoint("TOPLEFT", 10, currentY)
                fs:SetWidth(510)
                fs:SetJustifyH("LEFT")
                fs:SetText(block.content)
                fs:SetTextColor(1, 0.82, 0) -- Gold
                currentY = currentY - fs:GetStringHeight() - 5
            elseif block.type == "h4" then
                local fs = entryContent:CreateFontString(nil, "OVERLAY", "BetterFriendlistFontNormal")
                fs:SetPoint("TOPLEFT", 10, currentY)
                fs:SetWidth(510)
                fs:SetJustifyH("LEFT")
                fs:SetText(block.content)
                fs:SetTextColor(0.8, 0.8, 0.8) -- Light Gray
                currentY = currentY - fs:GetStringHeight() - 5
            elseif block.type == "separator" then
                local tex = entryContent:CreateTexture(nil, "ARTWORK")
                tex:SetTexture("Interface\\Common\\UI-TooltipDivider-Transparent")
                tex:SetPoint("TOPLEFT", 10, currentY)
                tex:SetSize(510, 8)
                currentY = currentY - 15
            elseif block.type == "list_item" then
                -- Bullet
                local bullet = entryContent:CreateFontString(nil, "OVERLAY", "BetterFriendlistFontHighlight")
                bullet:SetPoint("TOPLEFT", 15, currentY)
                bullet:SetText("•")
                
                -- Text
                local fs = entryContent:CreateFontString(nil, "OVERLAY", "BetterFriendlistFontHighlight")
                fs:SetPoint("TOPLEFT", 30, currentY)
                fs:SetWidth(490)
                fs:SetJustifyH("LEFT")
                fs:SetText(block.content)
                
                currentY = currentY - math.max(fs:GetStringHeight(), bullet:GetStringHeight()) - 5
            else -- text
                local fs = entryContent:CreateFontString(nil, "OVERLAY", "BetterFriendlistFontHighlight")
                fs:SetPoint("TOPLEFT", 10, currentY)
                fs:SetWidth(510)
                fs:SetJustifyH("LEFT")
                fs:SetText(block.content)
                currentY = currentY - fs:GetStringHeight() - 5
            end
        end
        
        local contentHeight = math.abs(currentY)
        entryContent:SetHeight(contentHeight)
        
        -- Toggle Logic
        local isExpanded = (i == 1)
        
        local function UpdateState()
            if isExpanded then
                entryContent:Show()
                entryFrame:SetHeight(20 + 5 + contentHeight)
                icon:SetTexture("Interface\\AddOns\\BetterFriendlist\\Icons\\chevron-down.blp")
            else
                entryContent:Hide()
                entryFrame:SetHeight(20)
                icon:SetTexture("Interface\\AddOns\\BetterFriendlist\\Icons\\chevron-right.blp")
            end
        end
        
        header:SetScript("OnClick", function()
            isExpanded = not isExpanded
            UpdateState()
            RecalculateHeight(content, entryFrames)
        end)
        
        UpdateState()
        
        table.insert(entryFrames, entryFrame)
        previousFrame = entryFrame
    end
    
    RecalculateHeight(content, entryFrames)
    
    changelogFrame = frame
    frame:Hide()
end
