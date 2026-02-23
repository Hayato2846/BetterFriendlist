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
- **Who Search Builder: Smart Race/Class Filtering** - The Who Search Builder now prevents impossible race-class combinations (e.g., Dracthyr Death Knight, Human Demon Hunter). When you select a class, only compatible races appear in the race dropdown and vice versa. Each WoW version (Retail, MoP Classic, Cata Classic, Classic Era) has its own accurate compatibility table based on Warcraft Wiki data.

### Changed
- **Who Search Builder: Name Field Character Limit** - The name field in the Who Search Builder is now limited to 12 characters, matching the maximum length of WoW character names.

### Fixed
- **Visit House Not Working After Combat** - Fixed the "Visit House" button becoming permanently broken after opening the house list for the first time during combat. The secure proxy frame is now properly deferred and created once combat ends, preventing protected function errors.
- **Who Search Builder: Unsorted Dropdowns** - Fixed race and class dropdowns in the Who Search Builder not being sorted alphabetically, making it difficult to find specific options quickly.
- **Who Search Builder: Level Range Validation** - Fixed level input fields allowing values beyond the maximum player level. Both minimum and maximum level fields now automatically cap entered values to the current expansion's max level and prevent values below 1.
- **Streamer Mode Still Active When Button Hidden** - Fixed Streamer Mode remaining active when the "Show Streamer Mode Button" option was disabled. The addon now automatically deactivates Streamer Mode when the button is hidden, restoring the original header text and removing privacy filtering.
- **Who Search: Stale Player Selection** - Fixed being able to invite or interact with players from previous Who search results after starting a new search. Player selection is now automatically cleared when a new Who search is executed.
- **Who Search Builder: Incomplete Race/Class Data** - Fixed race-class compatibility tables across all WoW versions. In Retail, Dracthyr was missing most of its classes, many races were missing Warlock and other Dragonflight additions, Haranir was not included, and Earthen was incorrectly listed as Death Knight and Druid. In Cata Classic and MoP Classic, Priest was missing Gnome and Tauren, Mage was missing Dwarf, Night Elf, and Orc, and Warlock was missing Dwarf and Troll (all combinations that were added in Cataclysm 4.0). In MoP Classic, Pandaren was incorrectly listed as a Death Knight option (Pandaren DK was not available until Shadowlands).

## [2.4.0]       - 2026-02-21

### Fixed
- **Streamer Mode Whisper Broken** - Fixed whispering via the right-click context menu not working when Streamer Mode was active. The whisper target was incorrectly set to the formatted display name (including character name and color codes) instead of the account name.

## [2.3.9]       - 2026-02-19
### Added
- **Who Frame Visual Overhaul** - The Who search results now feature class icons, class-colored names, level difficulty coloring, alternating row backgrounds, and taller rows for improved readability. Hovering a result shows a detailed tooltip with name, level, race, class, guild, and zone. Double-clicking a player whispers them (configurable to invite instead). Ctrl+Click searches by the value in the current variable column (zone, guild, or race).
- **Who Settings Tab** - A new "Who" tab in Settings lets you toggle class icons, class colors, level colors, zebra striping, and choose the double-click action.
- **Who Search Builder** - A new filter icon next to the Who search box opens an interactive query builder. Fill in name, guild, zone, class, race, or level range fields and the addon composes the correct /who syntax for you. A live preview shows the generated query before searching.

### Fixed
- **Top Tab Text Truncation** - Fixed the Friends, Recent Allies, and Recruit A Friend tabs cutting off text too early, especially noticeable on the RAF tab. Also fixed the tab text position shifting downward when increasing font size.
- **Classic ElvUI Contacts/Who Layout** - Fixed multiple Classic ElvUI layout issues where filter and sort dropdowns could overlap, bottom tabs were spaced incorrectly, the Raid tab styling could be inconsistent, and WHO/Search Builder dropdown click areas did not match their visible boxes.
- **Retail ElvUI Top Tab Text Position** - Fixed the Friends/Recent Allies/RAF tab text appearing too low when reopening the frame with ElvUI active.

## [2.3.8]       - 2026-02-17
### Added
- **Multi-Game-Account Support** - Friends logged into multiple game accounts now show a badge on their game icon with the number of active accounts. Right-clicking offers an "Invite Character..." submenu to pick which character to invite. On Classic, the invite button now also shows a selection dropdown instead of always inviting only the first account.
- **New Info Line Tokens** - Added %accounts% (number of game accounts online) and %games% (list of games being played) for use in custom info line formats.
- **Configurable Tooltip Account Limit** - The number of additional game accounts shown in a friend's tooltip can now be changed (default: 5). Accessible via the new "Tooltip: Max Game Accounts" setting.
- **Multi-Account Detail Line** - Friends on multiple characters now show an extra line with icons and compact names for the other online accounts, leaving the main info line focused on status/zone.
- **Preferred Game Account** - You can now choose which game account is displayed as the primary one for friends with multiple accounts. Click the game icon or use the "Switch Game Account" right-click submenu. The picker shows your friend's name as header, game icons per entry, and a radio selection to indicate the current choice. Non-WoW games (Hearthstone, Diablo, etc.) are fully supported. Respects Streamer Mode and your name format settings.

### Fixed
- **Copy Character Name Not Showing** - Fixed "Copy Character Name" sometimes not appearing in the friend right-click menu. The option now also supports multiple characters across different game accounts via a submenu.
- **White Hover Highlight on Friends** - Fixed the mouse-over highlight on friend entries appearing white instead of the standard light blue used by Blizzard's default Friends list. Also removed a duplicate highlight definition in the Retail button template.
- **Compact Mode Icon Sizing** - Fixed game icons and invite buttons appearing oversized in Compact Mode when a friend's name fits on a single line. Icons now scale to match the actual row height.
- **Chat System Taint (MONSTER_YELL crash)** - Fixed a crash ("attempt to perform string conversion on a secret string value") that could occur when NPCs yelled in-game. The root cause was BetterFriendlist's custom tab sizing tainting Blizzard's chat system, which also uses tabs internally. This has been properly fixed with a non-tainting approach.
- **Classic Dropdown Positioning** - Fixed the QuickFilter, Primary Sort, and Secondary Sort dropdowns appearing outside the frame in Classic Normal Mode.

## [2.3.7]       - 2026-02-15
### Added
- **EnhanceQoL Ignore List Support** - When EnhanceQoL's Ignore List feature is active and set to open with the Friends frame, BetterFriendlist now automatically shows and positions it alongside its own window, just like Global Ignore List. A toggle button also appears in the Ignore List panel.

### Fixed
- **Streamer Mode Header Reset After Note Changes** - Fixed the custom header text (BattleTag replacement) being overwritten by the real BattleTag after using the Note Cleanup Wizard or importing a settings backup. The Streamer Mode button still appeared active but the header showed the real BattleTag.
- **Streamer Mode Name Format Not Live-Updating** - Fixed changing the name formatting dropdown in Streamer Mode settings not immediately updating the friends list. A /reload was previously required.
- **Custom Header Text Shown With Streamer Mode Off** - Fixed the custom header text (e.g. "Streamer Mode") remaining visible after disabling Streamer Mode in certain conditions, such as when the addon loaded with Streamer Mode already active.
- **ElvUI Skin (Advanced Settings Dialogs)** - Added ElvUI skinning for the Export, Import, Note Cleanup Wizard, and Backup Viewer windows (Settings -> Advanced). Buttons, scrollbars, and frames are now properly styled to match the ElvUI theme.
- **Missing "Status" Secondary Sort Option** - Fixed the "Status" sort option not appearing as a secondary sort choice. The sort logic already supported it but the option was missing from the dropdown and context menus.

## [2.3.6]       - 2026-02-14
### Added
- **Name Formatting Presets** - Replaced the free-text name format input with a dropdown menu offering preset options (Name (Character), BattleTag (Character), Nickname (Character), Character Only, Name Only). A "Custom..." option is still available for advanced users who want to use wildcards. All wildcards (%name%, %character%, %level%, %zone%, %class%, %game%, %note%, %nickname%, %battletag%, %realm%) are available in both name and info formats. 
- **Friend Info Formatting** - Added a new setting to customize the second line of friend entries (the info line showing level, zone, etc.). Choose from presets like Default, Zone Only, Level Only, Class/Zone, Game Name, or create a custom format using wildcards. Selecting "Disabled" hides the info line entirely and reduces button height to save space.

### Changed
- Character names are now rendered entirely through the formatting system instead of being appended separately, giving full control over their placement and formatting.

### Fixed
- **RAF Overhaul** - Reworked the Recruit-A-Friend tab to closely match Blizzard's official implementation. Recruit list entries are now left-aligned, use version-specific icons and colors, and show the correct status text. Tooltips, reward descriptions, and month counts now display the same text as Blizzard's default UI. Repeatable rewards (e.g. Game Time) now correctly show their claim count. The reward panel now reliably opens to the active RAF season instead of occasionally pulling from an inactive one.
- **RAF Activity Tooltips** - Fixed RAF activity tooltips not matching Blizzard's tooltip style. Now uses the correct tooltip frame for quest reward display and properly shows a loading indicator while quest data is retrieved.
- **RAF Reward Icon** - Fixed the next reward icon always appearing fully saturated. It now properly shows as desaturated when the reward is not yet affordable, matching Blizzard's behavior.
- **RAF Recruitment Link** - Fixed the Recruit-A-Friend recruitment link popup not displaying properly when opened from the BetterFriendlist RAF tab.
- **Search on All Tabs** - The search box now works on the Recent Allies and Recruit-A-Friend tabs in addition to the Friends tab. Each tab shows a fitting placeholder text and switching tabs clears the current search.
- **Accent-Insensitive Search** - Searching for "Hayato" now also finds friends named "Hâyato", "Hàyató", etc. Accented characters are treated as their base letter during search.
- **Friend Search with Real Names** - Friend search now properly skips privacy-protected Real Names (a Blizzard limitation) instead of silently failing. Nicknames are now also included in search results.
- **Who Frame Level Alignment** - Fixed the Level column in the Who search results not aligning with its column header.
- **Blizzard Raid Frame Interaction** - Fixed empty raid member slots retaining stale unit references, which could cause unexpected interactions with Blizzard's default raid frame.
- **Raid Info First-Click Ghost Buttons** - Fixed Blizzard's raid member buttons briefly appearing when clicking the Raid Info button for the first time after a /reload.

### Removed
- **Activity Tracker** - Removed the Activity Tracker feature (last whisper/group/trade timestamps) to fix a critical error caused by addon taint in the chat system on WoW 12.0+. The "Recent Activity" sort option has also been removed.

## [2.3.5]       - 2026-02-13
### Fixed
- **Settings Import Failing** - Fixed settings import always failing with "corrupted string" error, making it impossible to restore exported backups.
- **Settings Import Not Fully Replacing Data** - Fixed settings import not removing groups or settings that were created after the export. Importing a backup now fully restores the exact state from the export.

## [2.3.4]       - 2026-02-12
### Fixed
- **Streamer Mode Real ID Leaks** - Fixed several places where Real IDs could still be visible despite Streamer Mode being active:
  - Friend tooltip in Classic showed Real ID instead of BattleTag.
  - Data Broker tooltip showed Real ID for friends not currently playing WoW.
  - Recruit-A-Friend tab showed Real IDs without respecting Streamer Mode.
  - FriendListColors addon integration received unmasked Real IDs.
  - Copy Name popup could fall back to Real ID.
  - Drag ghost text could show Real ID when dragging a friend.

## [2.3.3]       - 2026-02-11
### Added
- **Note Cleanup Wizard** - Added a new wizard (Settings -> Advanced) to clean up FriendGroups-style note suffixes (#Group1#Group2) from friend notes. Features a searchable table showing Account Name, BattleTag, Original Note and Cleaned Note with inline editing. Supports both BNet and WoW friends. Includes automatic backup before applying changes. Per-row status icons (pending/success/error) with traffic-light colored backgrounds provide real-time visual feedback during the cleanup process. Respects Streamer Mode by masking Real IDs in the Account Name column and search filter.
- **Note Backup Viewer & Restore** - Added a backup viewer (Settings -> Advanced) to inspect all backed-up friend notes side-by-side with current notes. Changed notes are highlighted. The restore process uses sequential per-row status icons (pending/success/error) with traffic-light colored backgrounds, matching the Cleanup Wizard's visual feedback. Includes a Backup button to create new backups directly from the viewer.
- **Group Note Sync** - Added a new setting (Settings -> Advanced) to automatically sync group assignments to friend notes using the FriendGroups format (Note#Group1#Group2). Groups are ordered by their configured group order. Changes to group membership, group order, or external note modifications (e.g., via Note Cleanup Wizard) are automatically detected and corrected. Respects BNet (127 char) and WoW (48 char) note limits. Includes a confirmation dialog when enabling. Shows a live progress indicator ("Syncing notes: x / y") below the checkbox during the initial sync. Supports both BNet and WoW friends.

### Changed
- **Data Broker Tooltip Library** - Migrated the Data Broker tooltip from LibQTip-1.0 to LibQTip-2.0.

### Fixed
- **QuickJoin Secret Values** - Fixed a crash (`attempt to perform boolean test on field 'autoAccept'`) caused by Patch 12.0.0 (Midnight) where certain group finder fields (autoAccept) became secret and caused security violations when used in boolean checks.
- **Non-WoW Game Info Text** - Fixed friend info text for non-WoW games (Overwatch, Diablo, Hearthstone, etc.) showing raw client program codes (e.g., "Pro", "D4", "WTCG") instead of the rich presence text (e.g., "Competitive: In Game", "Greater Rift", "Ranked: In Game") like Blizzard's default UI does.
- **Empty Account Name for BattleTag-Only Friends** - Fixed BNet friends with empty `accountName` (kString) showing a blank display name instead of falling back to the short BattleTag. Now follows Blizzard's `BNet_GetBNetAccountName` pattern: if accountName is nil, empty, or "???", the short BattleTag (before #) is used as fallback.
- **Top Tab State Not Reset on Reopen** - Fixed a bug where closing the friends list while on the Recent Allies or RAF tab and reopening it would show the Friends tab as selected but display the content of the previously viewed tab. The top tab (FriendsTabHeader) state is now properly reset when reopening.
- **QuickJoin Crash During Combat (Issue #44)** - Fixed a crash caused by Patch 12.0.0 Secret Values when `C_LFGList.GetSearchResultInfo()` returns secret field values during combat lockdown (e.g., M+ keys). Implemented a Secret-Passthrough mode that stores and displays secret values directly (group title, leader name, member count, activity name/icon) instead of discarding them. Forbidden operations (comparisons, iteration) are safely skipped.
- **Group Count Font Size** - Fixed the Group Count text (e.g. "(3/10)") not respecting the global Group Header font size setting. Root cause: when the Group Name and Group Count were split into separate FontStrings for independent color support, the Count FontString received a hardcoded 12pt font override that was not properly cleared by subsequent font sync calls.
- **Assist All Checkbox** - Fixed an issue not disabling the 'Assist All' checkbox and its label when the player isn't raid leader.

### Performance
- **QuickJoin Module Optimizations** - Fifth iteration of performance fixes added. If anything feels odd don't hesitate to contact.

## [2.3.2]       - 2026-02-10
### Fixed
- **Midnight API Fix** - Fixed `C_RestrictedActions.IsAddOnRestrictionActive` error caused by missing required `Enum.AddOnRestrictionType` argument (API changed in 12.0.0).
- **Rendering Delay After Login/Reload** - Fixed a noticeable delay where groups appeared empty (with zero counts) before friends populated after `/reload` or login. Root cause was `BNGetNumFriends()` temporarily returning 0 while BNet reconnects, triggering a premature empty render.

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
		"🚀",
		"⚡",
		"🔗",
		"🔌",
		"🎯",
		"🔔",
		"🐛",
		"🔧",
		"✨",
		"📝",
		"🌍",
		"🎮",
		"📨",
		"🛡️",
		"📊",
		"🎉",
		"🎨",
		"📋",
		"✅",
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
				blocks = {},
			}
		elseif currentEntry then
			local cleanLine = CleanLine(line)
			if cleanLine ~= "" then
				-- Determine block type
				if cleanLine:match("^# ") then
					table.insert(currentEntry.blocks, {
						type = "h1",
						content = FormatInline(cleanLine:gsub("^# ", "")),
					})
				elseif cleanLine:match("^#### ") then
					table.insert(currentEntry.blocks, {
						type = "h4",
						content = FormatInline(cleanLine:gsub("^#### ", "")),
					})
				elseif cleanLine:match("^### ") then
					table.insert(currentEntry.blocks, {
						type = "h3",
						content = FormatInline(cleanLine:gsub("^### ", "")),
					})
				elseif cleanLine:match("^%- ") then
					table.insert(currentEntry.blocks, {
						type = "list_item",
						content = FormatInline(cleanLine:gsub("^%- ", "")),
					})
				elseif cleanLine:match("^%-%-%-") or cleanLine:match("^%*%*%*") or cleanLine:match("^___") then
					table.insert(currentEntry.blocks, {
						type = "separator",
					})
				else
					table.insert(currentEntry.blocks, {
						type = "text",
						content = FormatInline(cleanLine),
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
	hitRect:SetVertexColor(0, 0, 0, 0) -- Fully transparent

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
	glow:SetVertexColor(1.0, 1.0, 1.0, 1.0) -- White like Retail
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
			if button.Glow then
				button.Glow:Show()
			end
			if button.NewLabel then
				button.NewLabel:Show()
			end
		else
			if button.Glow then
				button.Glow:Hide()
			end
			if button.NewLabel then
				button.NewLabel:Hide()
			end
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
	if frame.portrait then
		frame.portrait:Hide()
	end
	if frame.PortraitContainer then
		frame.PortraitContainer:Hide()
	end

	if ButtonFrameTemplate_HidePortrait then
		ButtonFrameTemplate_HidePortrait(frame)
	end
	if ButtonFrameTemplate_HideAttic then
		ButtonFrameTemplate_HideAttic(frame)
	end

	-- Hide default Inset
	if frame.Inset then
		frame.Inset:Hide()
	end

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
		insets = { left = 1, right = 1, top = 1, bottom = 1 },
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
