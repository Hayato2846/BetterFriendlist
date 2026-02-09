-- Modules/Changelog.lua
-- Displays the changelog in a scrollable window

local ADDON_NAME, BFL = ...
local L = BFL.L
local Changelog = BFL:RegisterModule("Changelog", {})

local changelogFrame = nil

-- Changelog content
local CHANGELOG_TEXT = [[# Changelog

All notable changes to BetterFriendlist will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [DRAFT]
### Added
- **Context Menu Integration** - Added BFL options (Set Nickname, Groups, etc.) to friend right-click menus even when not opened from BFL (e.g. from chat links), provided the player is a recognized friend.
- **Favorite Icon Style** - Added a setting to choose between BFL and Blizzard favorite icons (with icon previews).

### Changed
- **Tab Font Size** - Reduced maximum tab font size from 24 to 18 to prevent tab overlap issues.
- **Font Dropdown UX** - Font dropdowns now use single-check checkbox menus so the current selection stays visible without reopening.
- **Settings Layout** - Moved "Show Welcome Message" above Favorite Icon controls.
- **Favorite Icon Spacing** - Adjusted favorite icon sizing/padding in compact mode to keep names aligned.

### Fixed
- **Context Menu** - Prevented BetterFriendlist options from appearing in context menus of non-friend players. Added comprehensive restriction protection (combat and secure execution) to avoid "Action Forbidden" errors during checks.
- **UI Taint / Action Forbidden** - Fixed critical errors ("Action Forbidden") that could break the ESC key or Chat functionality during combat. Removed a conflict with Blizzard's window management system.
- **Localization** - Fixed capitalization in context menu headers ("BetterFriendList" -> "BetterFriendlist") for consistency.
- **Group Rename Display** - Fixed an issue where renaming groups (including built-in groups like "Favorites" or "No Group") would not visually update until a full UI reload.
- **Built-in Group Renames** - Fixed inconsistent behavior when renaming built-in groups like "In-Game" so changes are reflected correctly.
- **Settings Frame Viewport** - Fixed an issue where the Settings frame could be dragged outside the visible screen area. Frame is now clamped to screen boundaries.
- **Invite Group (Party Check)** - Fixed "Invite All to Party" to skip friends who are already in your party/raid or playing a different WoW version (e.g., Classic friends when you're on Retail).
- **Invite Group (Empty Groups)** - Fixed "Invite All to Party" context menu option to only appear when the group has invitable friends (online, same WoW version, not in party). The button shows the invitable count.
- **Story Mode Raid Tab** - Fixed the Raid tab to be properly disabled when in Story Mode instances (like Blizzard's FriendsFrame). Uses official `DifficultyUtil.InStoryRaid()` API. Disabled tab shows tooltip explaining why.
- **Dynamic Row Height** - Fixed friend list rows to dynamically adjust height based on font size settings, preventing text overlap at larger font sizes.
- **Group Color Picker Alpha** - Added alpha (transparency) support to all group color pickers (main color, count color, arrow color) allowing semi-transparent group colors.
- **Show Faction Icons** - Fixed the setting so faction icons display correctly when enabled.
- **Show Collapse Arrow** - Fixed the setting so collapse/expand arrows show when enabled.
- **Raid Right-Click MT/MA** - Fixed raid context menu options for Main Tank/Main Assist not working.

## [2.3.0]       - 2026-02-07
### Special Thanks
- Huge shoutout to **R41z0r** for testing the shit out of my addon. He's awesome and so is his addon EQOL <3

### Added
- **Raid Tab** - Added Convert To Raid / Convert To Party button to raid tab.
- **Login Message Setting** - Added new setting to enable/disable BFL's login message.
- **Raid Shortcuts** - Added two new Raid Shortcuts for setting Raid Leader and Assistant
- **Raid Settings** - Added new Raid Tab in Settings. You can enable/disable and change the actual shortcut used for the four actions BFL supports.
- **Raid Help Frame** - Added descriptions for both new shortcuts. The text reflects what you have setup in Raid Settings.
- **Copy Dialogs** - Added auto-close function when Ctrl+C is pressed.
- **Translations** - Added new translations, fixed some awkward translations.
- **Groups Scrollbar** - Added Scrollbar for right-click menu for friends -> groups so that a massive list of created groups doesn't grow out of the screen.
- **Frame Clamped** - Added ClampedToScreen protection so that the friendlist window can't move out of screen.
- **Position Reset Command** - For any edge-case scenarios the command `/bfl reset` was added. It resets frame position, width, height and scale.

### Changed
- **Changelog** - Improved the "NEW" indicator on the changelog menu button to use a cleaner, native-style tag with less padding (Retail).
- **RAF Visibility** - Added RAF visibility check.
- **Copy Character Name** - Replaced all 'Copy Character Name' right-click menu options with BFL-native options. Please be aware that copying natively to clipboard is protected and a copy dialog variant is the only way to achieve it for addons.
- **Create/Rename Group** - Dialog for creating/renaming a group now checks if the given name is already used.
- **Groups Setting Fixes** - Added outline to groups color elements in settings, removed highlight hover effect, fixed inherit functions, standardized padding between elements, fixed missing translation key for renaming groups
- **Font Settings** - Removed options Font Outline and Font Shadow for now. Will be added again in a later update.
- **Group Header Counts** - Changed possible values to Filtered / Total, Online / Total, Filtered / Online / Total
- **Sorter** - Selected primary sorter can't be used as secondary sorter anymore, e.g. sorting by Name & Name doesn't make sense.
- **Empty Groups** - Changed default behaviour of empty groups so these will be shown when 'Hide Empty Groups' setting is disabled.
- **Simple Mode** - Removed empty spaces around the SearchBar.
- **Settings Visibility** - Data Broker and Global Sync options are now hidden when the features aren't enabled.
- **Send Message Button** - Send Message Button is disabled when you select a offline WoW friend.
- **Group Order Drag and Drop** - Changed group ordering in settings to use drag and drop instead of up and down buttons.
- **Data Broker Column Drag and Drop** - Changed data broker column ordering in settings to use drag and drop instead of up and down buttons.
- **Drag and Drop Ghosting** - Added a ghosting effect when you use drag so that you know what/who you're dragging!

### Fixed
- **Tab Width Calculation** - Fixed dynamic tab width calculation when toggling Streamer Mode.
- **Layouting** - Fixed and standardized layout of UI elements.
- **RAF Label** - Removed redundant friend label.
- **Changelog** - Fixed date alignment.
- **SearchBar Visibility** - Fixed SearchBar visibility in Normal Mode when swapping tabs.
- **Recent Allies Information** - Changed display of Recent Allies information to a approach closer to Blizzard's view of Recent Allies.
- **Recent Allies Rendering** - Fixed flickering of some Recent Allies elements.
- **Recent Allies Positioning** - Changed element positioning to better align character information and pipes.
- **Beta Fixes** - Added some new API Calls so that deprecated API isn't used anymore in WoW Midnight Beta, e.g. BNSetAFK().
- **Ignore List Label** - Fixed visibility of ignored label showing when you no entries in ignore list.
- **Groups Setting Layout** - Fixed Groups Setting layout cropping UI elements.
- **Streamer Mode Tooltip** - Fixed Streamer Mode tooltip enabled/disable state not updating properly after toggling the mode by pressing the button.
- **ColorPicker** - Fixed some lua errors and added proper color reset.
- **Global Sync** - Fixed a bug not saving note changes in Global Sync tab for friends.
- **Who List** - Fixed selection in who list, fixed sorting, fixed caching.
- **Performance** - Fourth iteration of performance fixes added. If anything feels odd don't hesitate to contact.
- **Streamer Mode (Classic)** - Fixed Streamer Mode in Classic not showing settings and button.
- **Friend Width Calculation (Classic)** - Fixed friend font string width calculation not properly updating in classic after changing the width of the friendlist.

## [2.2.9]       - 2026-02-03
### Fixed
- **Friend Button Layout** - Fixed an issue where Friend Name and Friend Info would not resize properly after adjusting Width via Settings.
- **Database Initialization** - Fixed a database initialization error.
- **QuickFilters** - Fixed a QuickFilter database issue causing filters to not update properly.

## [2.2.8]       - 2026-02-02
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

## [2.2.7]       - 2026-01-31
### Fixed
- **Library** - Fixed potential issues with LibQTip library integration.

## [2.2.6]       - 2026-01-31
### Added
- **Copy Character Name** - Added a new option to the context menu to copy character names (Name-Realm) for better inviting/messaging
- **Simple Mode** - Added Simple Mode in Settings -> General. Simple Mode hides specific elements (Search, Filter, Sort, BFL Avatar) and moves corresponding functions in the menu button
- **ElvUI Skin Tabs** - Improved alignment of tab text and overall layout of all tabs of BFL in ElvUI Skin

### Fixed
- **Friend Groups Migration** - Fixed an issue with FriendGroups Migration for WoW friends. Added more debug logs to better help with issues.
- **ElvUI Skin Retail** - Fixed an error with ElvUI Retail Skinning
- **ElvUI Skin Classic** - Fixed and enabled ElvUI Classic Skin
- **QuickJoin Informations** - Fixed an issue with shown QuickJoin informations lacking details of queued content type
- **Broker Integration** - Fixed an issue that disabled the Broker BFL Plugin
- **Performance** - Third iteration of performance added. If anything feels odd don't hesitate to contact
- **RAF** - Fixed an issue blocking the usage of copy link button in RAF Frame
- **Global Sync** - Fixed an error occuring while having own characters in sync added

## [2.2.5]       - 2026-01-25
### Fixed
- **Combat Blocking Fix** - Fixed a critical issue where the Friends List window could not be opened during combat, even when UI Panel settings were disabled. This resolves the "ADDON_ACTION_BLOCKED" error caused by unnecessary secure templates.
- **Localization** - Fixed encoding issues in English localization (enUS) where bullets and arrows were displayed as corrupted characters.

## [2.2.4]       - 2026-01-25
### Fixed
- **Mojibake Fix** - Fixed an issue where localized text (German, French, etc.) could display incorrect characters. (Core.lua)
- **QuickJoin** - Fixed quick join tooltips.
- **Edit Mode** - Fixed visibility issues when entering Edit Mode.

## [2.2.3]       - 2026-01-25
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

## [2.2.2]       - 2026-01-18
### Fixed
- **Font Support** - Reverted the friend name font to `GameFontNormal`. This restores support for the 4 standard fonts (including Asian/Cyrillic characters).
- **ElvUI Interaction** - **Note:** ElvUI Font Size settings now apply to the Friend Name again.
- **Workaround** - This is a temporary workaround. Proper independent font settings will be added in the next version.

---

*Older versions archived. Full history available in git.*
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
        -- Match version and date with flexible whitespace handling
        local version, date = line:match("^## %[(.-)%]%s*-%s*(.+)")
        
        -- Fallback for entries with just version (like DRAFT or future unreleased)
        -- Although the previous code required date, sometimes [Unreleased] has no date
        if not version then
             version = line:match("^## %[(.-)%]%s*$")
             date = ""
        end

        if version and date ~= "" then -- Maintain previous behavior of requiring date mostly, or strictly adhering to "Header has date"
            -- Actually, let's stick closer to original logic but allow extra spaces
            -- Trim date just in case
            date = date:match("^%s*(.-)%s*$")
            
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
            self.EditBox:SetScript("OnKeyUp", function(editBox, key)
                if IsControlKeyDown() and key == "C" then
                    editBox:GetParent():Hide()
                end
            end)
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

function Changelog:IsNewVersion()
    local DB = BFL:GetModule("DB")
    local lastVersion = DB:Get("lastChangelogVersion", "0.0.0")
    local currentVersion = BFL.VERSION
    return lastVersion ~= currentVersion
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
        dateLabel:SetWidth(85) -- Fixed width for alignment (fits YYYY-MM-DD)
        dateLabel:SetJustifyH("LEFT") -- Left align for clean column start
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
