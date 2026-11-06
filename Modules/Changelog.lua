-- Modules/Changelog.lua
-- Displays the changelog in a scrollable window

local ADDON_NAME, BFL = ...
local L = BFL.L
local Changelog = BFL:RegisterModule("Changelog", {})

local FONT_FLAGS = "SLUG"

local function ApplyChangelogFont(fontString)
	if not fontString or not BFL.FontManager then
		return
	end
	local font, size, flags = fontString:GetFont()
	if flags ~= BFL.FontManager:GetFontFlags(FONT_FLAGS) then
		BFL.FontManager:SafeSetFont(fontString, font, size, FONT_FLAGS)
	end
end

local function CreateChangelogText(parent, template)
	local fontString = parent:CreateFontString(nil, "OVERLAY", template)
	ApplyChangelogFont(fontString)
	return fontString
end

-- The Settings Center creates fresh text when an entry is expanded.
function Changelog:ApplyContentFonts(frame)
	for _, region in ipairs({ frame:GetRegions() }) do
		if region:IsObjectType("FontString") then
			ApplyChangelogFont(region)
		end
	end
	for _, child in ipairs({ frame:GetChildren() }) do
		self:ApplyContentFonts(child)
	end
end

local changelogFrame = nil
local SUPPORT_LINKS = {
	{ id = "discord", url = "https://discord.gg/dpaV8vh3w3" },
	{ id = "github", url = "https://github.com/Hayato2846/BetterFriendlist/issues" },
	{ id = "kofi", url = "https://ko-fi.com/hayato2846" },
}
local PORTRAIT_NOTICE_MIN_ALPHA = 0.35
local PORTRAIT_NOTICE_MAX_ALPHA = 1
local PORTRAIT_NOTICE_FADE_DURATION = 1.2
local PORTRAIT_NOTICE_WIDTH = 64
local PORTRAIT_NOTICE_HEIGHT = 48

local function ApplyPortraitNoticeTexture(texture)
	if not texture then
		return
	end

	local atlas = BFL.IsClassic and "communities-icon-invitemail" or "CharacterCreate-NewLabel"
	local fallback = BFL.IsClassic and "Interface\\AddOns\\BetterFriendlist\\Icons\\mail"
		or "Interface\\AddOns\\BetterFriendlist\\Icons\\star"
	if BFL.SetTextureOrAtlas then
		BFL.SetTextureOrAtlas(texture, atlas, fallback)
	else
		texture:SetTexture(fallback)
	end
end

local function GetAccentColor(fallbackR, fallbackG, fallbackB, fallbackA)
	if BFL.GetThemeAccentColor then
		return BFL:GetThemeAccentColor(fallbackR or 1, fallbackG or 0.82, fallbackB or 0, fallbackA or 1)
	end
	return fallbackR or 1, fallbackG or 0.82, fallbackB or 0, fallbackA or 1
end

local function GetSecondaryAccentColor()
	local accentR, accentG, accentB, accentA = GetAccentColor(1, 0.82, 0, 1)
	local tint = 0.32
	return accentR + (1 - accentR) * tint,
		accentG + (1 - accentG) * tint,
		accentB + (1 - accentB) * tint,
		accentA
end

local function FormatSecondaryHeading(content)
	local r, g, b = GetSecondaryAccentColor()
	return string.format("|cff%02x%02x%02x%s|r", math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5), content)
end

-- Changelog content
local CHANGELOG_TEXT = [[# Changelog

All notable changes to BetterFriendlist will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [3.0.1]        - 2026-11-06

BetterFriendlist 3.0.1 improves group note sync and backups, adds ruleset checks for invites in WoW Forever, and makes smooth scrolling optional.

### All WoW Versions

#### Added
- **Full Backups** - Exports now include private contact notes and saved note backups. Both backup windows explain that the exported data can contain private information and friend names.
- **Global Sync Database** - Use Delete All to clear saved Global Sync entries and their notes for this client after confirmation, without removing anyone from your Blizzard friends list.

#### Improved
- **Group Note Sync** - Large syncs send queued updates without waiting for each note to appear or repeatedly sending changes already awaiting confirmation. Progress shows what is queued and what is waiting, with fewer repeated friend-list reads and window refreshes.
- **Note Cleanup** - The wizard keeps its recovery copy across retries, waits for delayed note changes, and lets you stop cleanup while keeping the backup. Title friend backups can be restored during the same game session.
- **Backup Text Fields** - Large pastes in the import and export windows are buffered to reduce pauses. Selections and text after the insertion point are preserved.

#### Fixed
- **Group Assignments** - Existing note tags are read before syncing starts, and assignments stay intact when groups are renamed or changed during a sync. Group names containing # are supported, though other FriendGroups addons may display their escaped form.
- **Settings Imports** - Backups are checked before replacing your data, and the previous settings are restored if applying an import fails. Nested filters and older group colors are preserved.
- **Global Sync Backups** - Saved friends and Global Sync options are restored only into the same WoW client type, keeping Retail, Forever, and Classic separate. Imports from another client or older backups without this information keep your existing Global Sync data.
- **Game Icons** - Friends playing WoW Forever show Blizzard's matching game icon in the friends list, tooltips, account menus, and the Data Broker.
- **Friend Tags** - Removed patch-number references from the Blizzard handoff heading and description.

### Retail Midnight & WoW Forever

#### Improved
- **Scrolling** - Immediate scrolling is the default again, matching the behavior before 3.0.0. Enable Smooth Scrolling in General settings to animate scrolling in either the Modern or Legacy layout.

### WoW Forever

#### Added
- **Ruleset Display** - Friend details show Normal, PvP, RP, or RP-PvP instead of internal realm names. The default info line includes the ruleset, and custom name and info formats can use %ruleset%.
- **Ruleset Invites** - Invite and Request to Join now check rulesets as well as faction. The party button is disabled for a different ruleset and explains why on hover; friends with several online characters can still use a compatible character.

#### Fixed
- **Class Colors** - Retail friends keep their Monk, Death Knight, Demon Hunter, and Evoker colors when viewed in Forever, including in tooltips, account menus, and the Data Broker.
- **Character Names** - Auto Raid Assist keeps complete first and last names when finding, saving, and promoting Title friends. Raid, guild, and Quick Join displays also preserve surnames.
- **Who Searches** - Who searches open in BetterFriendlist instead of Blizzard's Who or Looking For Group window, including searches from /who and character links. Looking For Group remains available for its normal group activities.
- **Global Sync** - Saved entries can be removed from the sync database without removing Blizzard friends. The invite list opens horizontally centered over the friends list.

### WoW Classic

#### Fixed
- **Backups and Notes** - Fixed missing characters at the end of some backup strings. Non-English group names can use the full note length supported by the client.

---

## [3.0.0]        - 2026-11-03

BetterFriendlist 3.0.0 adds saved Who searches, an option to show friends' alts in tooltips, and smoother scrolling on Retail and Forever.

### All WoW Versions

#### Added
- **Known Characters** - You can now link alts to a friend and show them in their tooltip. You can add characters yourself or let BFL remember characters it sees your Battle.net friends play. Both options are off by default, and the list stays hidden in Streamer Mode.
- **Who Searches** - Use the star next to the search box to save up to 12 searches or pick a recent one. You can edit it before hitting Search, and you can clear or turn off your search history.
- **Friend Tooltips** - Tooltips now show whether someone is a WoW, BattleTag, or Real ID friend when that info is available.

#### Improved
- **Themes** - Dark and Custom now draw many of their flat borders the same way, including in Settings and the Friend Tag Editor. Each theme keeps its own colors.
- **Changelog** - Drag the bottom-right corner to make the window wider or taller. It remembers your size the next time you open it.
- **Settings Center** - Clicking a search result highlights the setting it takes you to. Pages with tabs no longer repeat the tab name above the settings, and the Note Cleanup descriptions have room to wrap without covering the buttons.

#### Fixed
- **Recently Added** - Long-time friends no longer show up as newly added while your friends list is still loading or after a reconnect.
- **Faction Icons** - Faction icons now show up with name-only and BattleTag-only layouts when enabled.
- **Settings and Setup** - Support links copy in full, window size fields have room for the whole number, and filters stay inside the list while you drag them. Checkbox borders in Dark and Custom and the borders on the setup summary are more even.
- **Group Actions** - Fixed errors when promoting someone or changing the group type in combat, and when blocking Battle.net friends while Blizzard restricts the action.
- **Who and Friend Tooltips** - Saved searches keep their wording when you open them in the Search Builder. Friend details no longer stick around when the game reuses a tooltip.

### Retail Midnight & WoW Forever

#### Added
- **Smooth Scrolling** - The friends list now scrolls smoothly by default in both the Modern and Legacy layouts.
- **Recent Allies** - Click a player to see what you did together and how long ago. You can also see their latest activities in the tooltip.

#### Improved
- **Changelog** - The changelog window now uses backgrounds from the Modern friends list when that layout is active.

#### Fixed
- **Recent Allies** - Fixed errors when details about another player are hidden, including in the pin tooltip. Preview entries can no longer trigger real player actions.
- **Modern Friends Window** - Side tab icons and the Who scrollbar stay lined up when you switch tabs. In Dark and Custom, disabled buttons are easier to spot, and the Streamer Mode header and Raid help text are less bright. The Guild filter only shows its selection once.
- **Streamer Mode** - If a Title friend has no BattleTag, the friends list and right-click menu show their character name.
- **Who Search** - Class and race filters work again on clients where those searches could fail.
- **Raid Tab** - The Raid tab follows the game's availability rules, and promotion buttons respect who can promote group members.
- **Guild Roster** - You can still open the guild list when the game temporarily hides extra details like professions.

### WoW Forever

#### Fixed
- **Quick Join** - Quick Join unlocks with Group Finder at level 10. If it isn't available yet, the setting shows why.
- **Global Friend Sync** - Saved names keep their surnames, and BFL skips your own character. If you have saved friends left to invite, use the globe next to Add New Friend. Add All opens Blizzard's confirmations one at a time.

### WoW 12.1.7 PTR

#### Compatibility
- **PTR Support** - Updated BetterFriendlist and the Menu Bridge for the 12.1.7 PTR.

---

## [2.9.2]        - 2026-10-11

BetterFriendlist 2.9.2 adds a WoW Forever filter and fixes greyed-out group invites, along with a few smaller fixes.

### All WoW Versions

#### Fixed
- **Group Invites** - Fixed cases where Invite was greyed out in a Battle.net friend's right-click menu, including friends on other realms in WoW Forever. The character picker also handles friends with multiple WoW accounts.
- **Remove Friend** - The confirmation now uses the correct wording for WoW, BattleTag, and Real ID friends.
- **Changelog** - The current version's draft notes now appear in both in-game changelog views.
- **Invite Tooltip** - Offline friends now show a red offline message. Fixed incorrect faction warnings and added available group activity details when requesting to join.
- **Context Menu** - Empty Interact headings are no longer shown when no actions are available, including offline Title friends.
- **Friend List** - Fixed missing updates when reopening the friends list after changes while it was closed.
- **Who Class Filters** - Fixed missing class options on some clients, including Druids on Classic.
- **Settings and Skins** - Fixed errors that could occur when Settings, Who, or an addon skin accessed UI details restricted by Blizzard.

### Retail Midnight & WoW Forever

#### Fixed
- **Battle.net Blocking** - Block actions are now hidden for Title friends or when the required account details are missing. Friend requests are checked again before an account is blocked.
- **Title Friend Colors** - Online Title friends also use class colors in name-only layouts when enabled. Offline names stay gray.

### WoW Forever

#### Added
- **WoW Forever Filter** - A new quick filter shows friends playing WoW Forever in the friends list and Data Broker.

#### Fixed
- **Character Names** - Friends' character menus, Copy Character Name, and Quick Join no longer add unnecessary realm names. Forever surnames are kept in player links.
- **Add Friend** - BFL now opens Blizzard's Add Friend window in Forever, including its handling of Title friend requests.
- **Title Friend Names** - Title friends show the character name once in the default layout and friend tooltip. Custom names are still shown in the list if they differ from the character name.
- **Friend List** - Fixed an empty friend list after login or reloading when a title friend appeared first.

---

## [2.9.1]        - 2026-09-27

BetterFriendlist 2.9.1 adds new Guild tools, updates the Settings Center, and fixes several Who and Group Finder problems.

### All WoW Versions

#### Added
- **Raid PvP Icons** - Raid and party rows can now show PvP faction or prestige icons when available.

#### Improved
- **Private Notes** - Private Notes are no longer a Beta feature. They remain disabled until you turn them on.
- **Settings Center** - Updated the Settings Center library. It now uses direct links to features, two-column pages, and grouped option rows.
- **Themes** - Dark and Custom themes now update faster when you change their colors.
- **Auto Raid Assist** - Search results now show Battle.net friends first, followed by WoW and Title friends, and then guild members. Battle.net results and targets use Battle.net blue, while WoW, Title, and Guild entries use class colors.
- **External AddOn Menu Bridge** - The bridge is no longer a Beta feature and is switched on once when upgrading to v2.9.1. You can turn it off again at any time. If the companion addon is disabled, the option is greyed out and explains why.

#### Fixed
- **Blocked Actions** - Fixed errors caused when BFL or an addon skin tried to recolor a UI element locked by Blizzard.
- **Search and Sorting** - Search and sorting now skip names or text hidden by Blizzard.

### Retail Midnight & WoW Forever

#### Added
- **Guild Roster** - Profession filters now sit inside the main Guild filter and work together with Online, All, and Offline. Message of the Day, Guild News, and Guild Information share one larger area. Guild News is always available when supported and includes filters, a scrollable history, and links for achievements and items.
- **Guild Member Menu** - Right-click a guild member to add them as a friend, ignore them, or view their house when available. The unused Who option has been removed.
- **Quick Join** - Tooltips can now show the group leader's level.

### WoW Forever

#### Added
- **BattleTag Friend Requests** - Title friends can now be added as Battle.net friends from their right-click menu.

#### Improved
- **Character Names** - Forever surnames are now kept in Who searches, right-click menus, and Recent Allies notes.
- **Context Menus** - Block and remove actions are now shown in red.

#### Fixed
- **Group Finder** - Fixed blocked-action errors that could appear after using BFL's Who tab.
- **Who During Combat** - Typing or pressing Escape in the Who tab during combat no longer causes blocked-action errors.
- **Blocking** - Battle.net blocking works again, and Title friends no longer show an unusable Block Invites option.
- **Restricted Chat** - Whisper actions are disabled and show Blizzard's reason when the account is not allowed to chat.

---

## [2.9.0]        - 2026-09-18

BetterFriendlist 2.9.0 adds support for WoW Forever to BetterFriendlist and the Menu Bridge without changing the existing Retail Midnight and Classic experiences.

### All WoW Versions

#### Improved
- **Changelog Notice** - The BFL avatar now uses the same pulsing glow animation as the Friend Requests tab when a new changelog is available.
- **Who Search Builder** - Opening the Search Builder now imports the current Who query, including name, guild, zone, class, race, and level filters. Additional free-form search terms are preserved.
- **Who Search Feedback** - Who searches now show the same loading spinner used by Recent Allies while waiting for the server. “No players found” appears only after a completed empty response, while a timeout keeps its separate retry message.

### WoW Forever

#### Added
- **WoW Forever Support** - BetterFriendlist and the Menu Bridge now recognize Forever as a modern Mainline client despite its `1.60.1` version. Available social views and features—including Forever's Recent Allies categories—follow the APIs and live game rules provided by the client, while unsupported Midnight-only features remain hidden. Retail Midnight and every supported Classic flavor retain their existing behavior.

#### Fixed
- **Forever Who Routing** - `/who` now opens BetterFriendlist directly on its Who tab and performs the search there without also opening Forever's separate LFG Who window. The native Group Finder remains available through its own UI.
- **Forever Keybindings** - The Social shortcut is now migrated only after Forever has loaded a writable binding profile, preventing a Lua error during login.

### Retail Midnight

#### Fixed
- **Raid Member Right-Click** - Hovering raid members no longer causes a protected-frame anchor error. The normal Blizzard menu, including protected actions, still opens through the secure proxy in both Retail layouts.

---

## [2.8.8]        - 2026-09-13

### Retail Live & Classic

#### Added
- **Master Looter** - Classic raid and party lists now show who is Master Looter. The icon also works with both Retail raid layouts if the client provides that flag.

#### Improved
- **Addon Window Spacing** - EnhanceQoL, GlobalIgnoreList, and NorthernSkyRaidTools now leave room for the Modern side tabs. Their Legacy positions stay as they were.

#### Fixed
- **Story Mode Raid Tab** - The Raid tab is now disabled during a Story raid and shows Blizzard's reason when hovered.
- **ElvUI Broker Tooltips** - Friends and Guild Broker tooltips use the selected ElvUI tooltip style again.
- **Broker Tooltip Scrolling** - Friend updates no longer jump a scrolled Friends Broker tooltip back to the top.
- **Raid Member Right-Click** - The Raid Player menu works again in both Retail layouts. Regular clicks, shortcuts, selection, and drag-and-drop keep working on the same row.
- **Raid Counts** - Member and role counts update after returning to a Raid tab that changed while it was hidden.

### WoW 12.1.5 PTR

#### Added
- **Friend Search and Sorting** - On 12.1.5, BFL can use Blizzard's new locale-aware text APIs for local friends, tags, groups, realms, and Recent Allies. Other clients keep the existing search behavior.

#### Compatibility
- **New Client APIs** - Added checks for the new internationalization, LFG, and timer APIs so they are only used when the client provides them.
- **Raid Updates** - Repeated raid and LFG events now share one pending refresh on 12.1.5. Older clients keep the existing timer path.
- **Matchmade Raid Markers** - Main Tank and Main Assist markers are hidden when 12.1.5 reports a matchmade raid without manual role requirements.

---

## [2.8.7]        - 2026-08-24

### Fixed
- **Large Friend Lists** - BetterFriendlist has received further optimizations for larger friend lists and is now less likely to run into errors when loading them.

---

## [2.8.6]        - 2026-08-24

### Improved
- **Background Performance** - BetterFriendlist now avoids more work while the Friendlist, guild list, raid tools, and Broker tooltips are closed.
- **Large Friend Lists** - Friend and tag updates are now smoother, especially for players with many Battle.net friends.
- **Taint-Free Whisper** - On Retail, the optional whisper box now opens where you normally type chat messages.
- **Ready Check** - Party leaders can now start a Ready Check from the Raid tab without converting the group to a raid.

### Fixed
- **Guild Message of the Day** - Fixed a Retail chat error that could occur when the guild message of the day was displayed.
- **Raid Tab** - Long raid information now stays inside the window, and the Legacy controls no longer overlap.
- **Interface Switching** - Raid Roster Help and Streamer Mode now reappear immediately after switching from Modern to Legacy.
- **Modern Ready Check** - Removed a small visual artifact from the Ready Check button.

---

## [2.8.5]        - 2026-08-22

### Added
- **Friend Tag Actions** - Friend right-click menus can now select or clear all built-in and custom tags at once.
- **Icon-Only Tags** - Tags that only show an icon can optionally keep their colored chip background.
- **Dynamic Tag Groups** - A new option hides all tag chips inside dynamic tag groups. The existing option to hide only the group's own tag remains available.

### Improved
- **Friend Tag Layout** - Friend rows can now show up to 20 tags and use the available row width before wrapping.
- **Friend Tag Settings** - The visibility options now explain where each tag is shown: friend rows, tooltips, or Data Broker.

### Fixed
- **Friend Tag Editor** - Reordering, resetting, or deleting tags now updates friend rows immediately. After deleting a tag, another valid tag stays selected.
- **Friend Tag Names** - Custom tags can no longer use the name of a built-in tag.
- **Compact Friend Rows** - Status, game, and Invite icons now stay aligned when rows have different heights. Status markers remain readable and Invite artwork stays inside its button.
- **Icon-Only Tags** - Icons now stay centered inside colored chips, including the default Tank, Healer, and DPS icons.
- **Battle.net Levels** - Invalid level 0 values from Battle.net are no longer shown as a real character level. Available zone or game information is shown instead.
- **Custom Names** - Friends with digits in their BattleTag no longer trigger repeated rename messages after logging in or reloading the UI.

---

## [2.8.4]        - 2026-08-22

### Improved
- **Raid Tab** - When you are not in a raid, the Raid tab now shows Blizzard's helpful explanation instead of a short placeholder.
- **Recruit A Friend** - The recruit list now adjusts correctly after changing the game's text size, even if the tab was closed at the time.

### Fixed
- **Friend Requests** - Accepting or declining a Battle.net friend request no longer causes the game to freeze.
- **ElvUI BattleTag** - Your BattleTag now stays visible and keeps the same colors when switching between Legacy and Modern or using the copy button.
- **Changelog Notice** - The “NEW” glow around the BFL avatar now follows round and square avatar styles in every theme.
- **ElvUI Simple Mode** - The avatar now stays hidden when switching between Legacy and Modern while Simple Mode is active.
- **ElvUI Guild Tab** - The Legacy guild member list now uses a background that matches the ElvUI theme.
- **Modern Raid Tab** - Raid member right-click menus, shortcuts, selections, and drag-and-drop now stay connected to the correct player.

---

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

local function ParseChangelog(text, currentVersion)
	local entries = {}
	local currentEntry = nil

	for line in text:gmatch("[^\r\n]+") do
		-- Match version and date with flexible whitespace handling
		local version, date = line:match("^## %[(.-)%]%s*-%s*(.+)")

		-- Fallback for entries with just version (like future unreleased notes)
		-- Although the previous code required date, sometimes [Unreleased] has no date
		if not version then
			version = line:match("^## %[(.-)%]%s*$")
			date = ""
		end

		if version then
			date = date:match("^%s*(.-)%s*$")
			local isDraft = date == ""
			if (version == "DRAFT" or version == "Unreleased") and currentVersion then
				version = currentVersion
			end
			if date == "" then
				date = L.SETTINGS_CENTER_CHANGELOG_DRAFT or "Draft"
			end

			if currentEntry then
				table.insert(entries, currentEntry)
			end
			currentEntry = {
				version = version,
				date = date,
				isDraft = isDraft,
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

local function NormalizeEntryID(value)
	value = tostring(value or ""):lower():gsub("[^%w]+", "-"):gsub("^-+", ""):gsub("-+$", "")
	if value == "" then
		value = "entry"
	end
	return value
end

local function FormatVersionTitle(version)
	local template = L.CHANGELOG_HEADER_VERSION or "Version %s"
	local ok, title = pcall(string.format, template, tostring(version or ""))
	if ok and title and title ~= "" then
		return title
	end
	return "Version " .. tostring(version or "")
end

local function ConvertBlockToInfoEntry(block)
	if type(block) ~= "table" then
		return nil
	end
	if block.type == "separator" then
		return { type = "spacer", height = 8 }
	end
	local content = block.content or ""
	if content == "" then
		return nil
	end
	if block.type == "h3" then
		return { type = "text", text = "|cffffd100" .. content .. "|r" }
	elseif block.type == "h4" then
		return { type = "text", text = FormatSecondaryHeading(content) }
	elseif block.type == "list_item" then
		return { type = "text", text = "- " .. content }
	end
	return { type = "text", text = content }
end

local function RecalculateHeight(contentFrame, entryFrames)
	local totalHeight = 10
	for _, frame in ipairs(entryFrames) do
		totalHeight = totalHeight + frame:GetHeight() + 5
	end
	contentFrame:SetHeight(totalHeight)
end

local function ShowCopyDialog(url, title)
	local editBoxWidth = 350
	StaticPopupDialogs["BETTERFRIENDLIST_COPY_URL"] = {
		text = title or "Copy URL",
		button1 = "Close",
		hasEditBox = true,
		maxLetters = 0,
		editBoxWidth = editBoxWidth,
		OnShow = function(self)
			self.EditBox:SetText(url)
			self.EditBox:SetFocus()
			self.EditBox:HighlightText()
			self.EditBox:SetScript("OnKeyUp", function(editBox, key)
				if IsControlKeyDown() and key == "C" then
					editBox:GetParent():Hide()
				end
			end)
			if BFL.BrokerUtils and BFL.BrokerUtils.FixCopyStaticPopupLayout then
				BFL.BrokerUtils.FixCopyStaticPopupLayout(self, editBoxWidth)
			end
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
	local dialog = StaticPopup_Show("BETTERFRIENDLIST_COPY_URL")
	if dialog and BFL.BrokerUtils and BFL.BrokerUtils.FixCopyStaticPopupLayout then
		BFL.BrokerUtils.FixCopyStaticPopupLayout(dialog, editBoxWidth)
	end
end

function Changelog:ShowCopyDialog(url, title)
	ShowCopyDialog(url, title)
end

function Changelog:GetSupportLinks()
	local labels = {
		discord = L.CHANGELOG_POPUP_DISCORD or "Discord",
		github = L.CHANGELOG_POPUP_GITHUB or "GitHub Issues",
		kofi = L.CHANGELOG_POPUP_SUPPORT or "Ko-fi",
	}
	local links = {}
	for index, link in ipairs(SUPPORT_LINKS) do
		links[index] = {
			id = link.id,
			url = link.url,
			label = labels[link.id] or link.id,
		}
	end
	return links
end

function Changelog:GetEntries()
	-- Both views show the same draft/release list. Drafts retain their badge and
	-- use the installed version rather than hiding behind a literal DRAFT title.
	return ParseChangelog(CHANGELOG_TEXT, BFL.VERSION)
end

function Changelog:GetSettingsCenterEntries(limit)
	local entries = {}
	for index, entryData in ipairs(self:GetEntries()) do
		if limit and #entries >= limit then
			break
		end
		local content = {}
		for _, block in ipairs(entryData.blocks or {}) do
			local infoEntry = ConvertBlockToInfoEntry(block)
			if infoEntry then
				content[#content + 1] = infoEntry
			end
		end
		if #content == 0 then
			content[#content + 1] = {
				type = "text",
				text = L.SETTINGS_CENTER_CHANGELOG_EMPTY or "No release notes available.",
			}
		end
		entries[#entries + 1] = {
			type = "expandable",
			id = "bfl-changelog-" .. NormalizeEntryID(entryData.version or index),
			title = FormatVersionTitle(entryData.version),
			rightText = entryData.date,
			defaultExpanded = #entries == 0,
			entries = content,
		}
	end
	return entries
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
	self:RegisterTests()

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
		BFL_Tooltip:Hide()
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

function Changelog:GetPortraitButton()
	local FriendsUI = BFL.FriendsUI or BFL:GetModule("FriendsUI")
	if FriendsUI and FriendsUI.IsModernActive and FriendsUI:IsModernActive() then
		local modernPortrait = FriendsUI.root
			and FriendsUI.root.PortraitOverlay
			and FriendsUI.root.PortraitOverlay.HitButton
		if modernPortrait then
			return modernPortrait
		end
	end
	return BetterFriendsFrame and BetterFriendsFrame.PortraitButton
end

function Changelog:HidePortraitFrameGlow(button)
	local glow = button and button.Glow
	if not glow then
		return
	end

	glow:SetAlpha(0)
	glow:Hide()
end

function Changelog:EnsurePortraitNoticeAnimation(button)
	local notice = button and button.NewLabel
	if not notice then
		return nil
	end
	if button.ChangelogNoticeAnimation then
		return button.ChangelogNoticeAnimation
	end

	local animation = notice:CreateAnimationGroup()
	animation:SetLooping("REPEAT")
	if animation.SetToFinalAlpha then
		animation:SetToFinalAlpha(true)
	end

	local fadeIn = animation:CreateAnimation("Alpha")
	fadeIn:SetDuration(PORTRAIT_NOTICE_FADE_DURATION)
	fadeIn:SetOrder(1)
	fadeIn:SetFromAlpha(PORTRAIT_NOTICE_MIN_ALPHA)
	fadeIn:SetToAlpha(PORTRAIT_NOTICE_MAX_ALPHA)

	local fadeOut = animation:CreateAnimation("Alpha")
	fadeOut:SetDuration(PORTRAIT_NOTICE_FADE_DURATION)
	fadeOut:SetOrder(2)
	fadeOut:SetFromAlpha(PORTRAIT_NOTICE_MAX_ALPHA)
	fadeOut:SetToAlpha(PORTRAIT_NOTICE_MIN_ALPHA)

	animation.FadeIn = fadeIn
	animation.FadeOut = fadeOut
	button.ChangelogNoticeAnimation = animation
	return animation
end

function Changelog:SetPortraitNoticeAnimationPlaying(button, playing)
	local notice = button and button.NewLabel
	local animation = self:EnsurePortraitNoticeAnimation(button)
	if not (notice and animation) then
		return
	end

	if playing then
		notice:SetAlpha(PORTRAIT_NOTICE_MIN_ALPHA)
		notice:Show()
		if not animation:IsPlaying() then
			animation:Play()
		end
	else
		animation:Stop()
		notice:SetAlpha(0)
		notice:Hide()
	end
end

function Changelog:ShowGlow(show)
	local button = self:GetPortraitButton()
	if button then
		local accentR, accentG, accentB, accentA = GetAccentColor(1, 0.82, 0, 1)
		self:HidePortraitFrameGlow(button)

		-- Create NewLabel texture if it doesn't exist
		if not button.NewLabel then
			button.NewLabel = button:CreateTexture(nil, "OVERLAY")
			button.NewLabel:SetDrawLayer("OVERLAY", 2)
			button.NewLabel:SetPoint("CENTER", button, "CENTER", 0, 0)
			ApplyPortraitNoticeTexture(button.NewLabel)
			button.NewLabel:SetSize(PORTRAIT_NOTICE_WIDTH, PORTRAIT_NOTICE_HEIGHT)
			-- Desaturate to remove the native color, then color it with the active accent.
			button.NewLabel:SetDesaturated(true)
		end
		if button.NewLabel then
			button.NewLabel:SetVertexColor(accentR, accentG, accentB, accentA)
		end

		if show then
			self:SetPortraitNoticeAnimationPlaying(button, true)
		else
			self:SetPortraitNoticeAnimationPlaying(button, false)
		end
	end
end

function Changelog:RefreshPortraitIndicator()
	self:ShowGlow(self:IsNewVersion())
end

function Changelog:ToggleChangelog()
	if not changelogFrame then
		self:CreateChangelogWindow()
	end

	if changelogFrame:IsShown() then
		changelogFrame:Hide()
	else
		self:RefreshAccentColors()
		changelogFrame:Show()
		-- Update version in DB
		local DB = BFL:GetModule("DB")
		DB:Set("lastChangelogVersion", BFL.VERSION)
		self:ShowGlow(false)
	end
end

function Changelog:OnPortraitEnter(button)
	BFL_Tooltip:SetOwner(button, "ANCHOR_RIGHT")
	BFL_Tooltip:SetText("BetterFriendlist " .. (BFL.VERSION or ""), GetAccentColor(1, 0.82, 0, 1))

	local DB = BFL:GetModule("DB")
	local lastVersion = DB:Get("lastChangelogVersion", "0.0.0")

	if lastVersion ~= BFL.VERSION then
		BFL_Tooltip:AddLine(L.CHANGELOG_TOOLTIP_UPDATE, 0, 1, 0)
		BFL_Tooltip:AddLine(L.CHANGELOG_TOOLTIP_CLICK, 1, 1, 1)
	else
		BFL_Tooltip:AddLine(L.CHANGELOG_TOOLTIP_CLICK, 1, 1, 1)
	end

	BFL_Tooltip:Show()
end

function Changelog:Show()
	self:ToggleChangelog()
end

local function CreateSupportButton(frame, parent, link, modern)
	local template = modern and "SharedButtonTemplate" or "UIPanelButtonTemplate"
	local button = CreateFrame("Button", nil, parent, template)
	button:SetText(link.label)
	local label = button:GetFontString()
	ApplyChangelogFont(label)
	if modern and label then
		label:ClearAllPoints()
		label:SetPoint("LEFT", 25, 0)
		label:SetPoint("RIGHT", -7, 0)
		label:SetJustifyH("CENTER")
		for _, event in ipairs({ "OnShow", "OnEnter", "OnLeave", "OnEnable", "OnDisable" }) do
			button:HookScript(event, function(owner)
				ApplyChangelogFont(owner:GetFontString())
			end)
		end
	end

	local icon = button:CreateTexture(nil, "ARTWORK")
	icon:SetSize(14, 14)
	icon:SetPoint("LEFT", 10, 0)
	table.insert(frame.BFL_AccentTextures, icon)

	local mask = button:CreateMaskTexture()
	mask:SetSize(14, 14)
	mask:SetPoint("LEFT", 10, 0)
	mask:SetTexture("Interface\\AddOns\\BetterFriendlist\\Icons\\" .. link.icon .. ".blp")
	icon:AddMaskTexture(mask)

	button:SetScript("OnClick", function()
		ShowCopyDialog(link.url, link.popup)
	end)
	return button
end

local function RefreshSupportButtons(frame, modern)
	for _, link in ipairs(frame.BFL_SupportLinks) do
		if modern and not link.modernButton then
			link.modernButton = CreateSupportButton(frame, link.button:GetParent(), link, true)
			link.modernButton:SetPoint("CENTER", link.button)
			link.modernButton:SetSize(link.button:GetWidth(), 30)
		end
		link.button:SetShown(not modern)
		if link.modernButton then
			link.modernButton:SetShown(modern)
		end
	end
end

local function RefreshChangelogBackgrounds(frame)
	local FriendsUI = BFL.IsMainline and BFL:GetModule("FriendsUI")
	local theme = BFL.GetEffectiveTheme and BFL:GetEffectiveTheme() or "blizzard"
	local modern = FriendsUI and FriendsUI:IsModernActive()
		and (theme == "blizzard" or theme == "dark" or theme == "custom")
	modern = not not modern
	if not modern and frame.BFL_ModernChangelog == nil then
		return
	end
	RefreshSupportButtons(frame, modern and theme == "blizzard")
	local inset = frame.MainInset
	if frame.BFL_ModernChangelog ~= modern then
		frame.BFL_ModernChangelog = modern
		inset:ClearAllPoints()
		inset:SetPoint("TOPLEFT", frame, "TOPLEFT", modern and 4 or 10, -25)
		inset:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -4, 5)
		frame.BFL_HeaderBackground:SetShown(not modern)
		frame.BFL_HeaderLine:SetShown(not modern)
	end
	if theme == "blizzard" then
		-- The outer window supplies the edge. A second rim splits the Modern surface.
		inset:SetBackdropBorderColor(0.4, 0.4, 0.4, modern and 0 or 0.8)
	end
	local backgrounds = frame.BFL_ModernBackgrounds
	if modern and not backgrounds then
		local body = inset:CreateTexture(nil, "BACKGROUND", nil, 1)
		body:SetAllPoints()

		local topFade = inset:CreateTexture(nil, "BACKGROUND", nil, 2)
		topFade:SetPoint("TOPLEFT", body, "TOPLEFT")
		topFade:SetPoint("TOPRIGHT", body, "TOPRIGHT")
		local bottomFade = inset:CreateTexture(nil, "BACKGROUND", nil, 2)
		bottomFade:SetPoint("BOTTOMLEFT", body, "BOTTOMLEFT")
		bottomFade:SetPoint("BOTTOMRIGHT", body, "BOTTOMRIGHT")

		local header = frame.BFL_HeaderLine:GetParent()
		local divider = header:CreateTexture(nil, "ARTWORK")
		divider:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 5, -1)
		divider:SetPoint("TOPRIGHT", header, "BOTTOMRIGHT", -5, -1)
		divider:SetTexelSnappingBias(0)
		divider:SetSnapToPixelGrid(false)
		if BFL.HasAtlas("perks-divider-short") and BFL.SetTextureOrAtlas(divider, "perks-divider-short") then
			divider:SetHeight(3)
		else
			divider:SetColorTexture(1, 1, 1, 0.28)
			divider:SetHeight(1)
		end

		local function LoadFade(texture, atlas)
			local loaded = BFL.HasAtlas(atlas) and BFL.SetTextureOrAtlas(texture, atlas, nil, true)
			if loaded then
				texture:SetHeight(math.min(texture:GetHeight(), 140))
			end
			return loaded
		end

		backgrounds = {
			body = body,
			divider = divider,
			topFade = topFade,
			bottomFade = bottomFade,
			hasTopFade = LoadFade(topFade, "friends-frame-toptexbg"),
			hasBottomFade = LoadFade(bottomFade, "friends-frame-bottomtexbg"),
		}
		frame.BFL_ModernBackgrounds = backgrounds
	end
	if not backgrounds then
		return
	end

	local useAtlas = modern and theme == "blizzard"
	backgrounds.body:SetShown(modern)
	backgrounds.divider:SetShown(modern)
	backgrounds.topFade:SetShown(useAtlas and backgrounds.hasTopFade or false)
	backgrounds.bottomFade:SetShown(useAtlas and backgrounds.hasBottomFade or false)
	if modern then
		local palette = FriendsUI:GetModernThemeColors(theme)
		backgrounds.body:SetColorTexture(unpack(palette.background))
		backgrounds.divider:SetVertexColor(unpack(palette.border))
	end
end

function Changelog:RefreshAccentColors()
	self:RefreshPortraitIndicator()

	if not changelogFrame then
		return
	end
	RefreshChangelogBackgrounds(changelogFrame)

	local accentR, accentG, accentB = GetAccentColor(1, 0.82, 0, 1)
	local secondaryAccentR, secondaryAccentG, secondaryAccentB = GetSecondaryAccentColor()
	if changelogFrame.BFL_AccentTextures then
		for _, texture in ipairs(changelogFrame.BFL_AccentTextures) do
			if texture and texture.SetColorTexture then
				texture:SetColorTexture(accentR, accentG, accentB, 1)
			elseif texture and texture.SetVertexColor then
				texture:SetVertexColor(accentR, accentG, accentB, 1)
			end
		end
	end
	if changelogFrame.BFL_AccentFontStrings then
		for _, fontString in ipairs(changelogFrame.BFL_AccentFontStrings) do
			if fontString and fontString.SetTextColor then
				fontString:SetTextColor(accentR, accentG, accentB)
			end
		end
	end
	if changelogFrame.BFL_SecondaryAccentFontStrings then
		for _, fontString in ipairs(changelogFrame.BFL_SecondaryAccentFontStrings) do
			if fontString and fontString.SetTextColor then
				fontString:SetTextColor(secondaryAccentR, secondaryAccentG, secondaryAccentB)
			end
		end
	end
end

function Changelog:RegisterTests()
	if self.testsRegistered then
		return
	end
	local TestSuite = BFL:GetModule("TestSuite")
	if not (TestSuite and TestSuite.RegisterTest) then
		return
	end
	self.testsRegistered = true

	TestSuite:RegisterTest("ui", "Changelog_PortraitNoticeAnimation", {
		condition = function()
			return CreateFrame ~= nil and UIParent ~= nil
		end,
		action = function(V)
			local owner = CreateFrame("Frame", nil, UIParent)
			owner.NewLabel = owner:CreateTexture(nil, "OVERLAY")
			local animation = self:EnsurePortraitNoticeAnimation(owner)
			V:Assert(animation ~= nil, "Changelog creates an avatar notice animation")
			V:AssertEqual(animation:GetLooping(), "REPEAT", "Changelog notice repeats like the Friend Requests glow")
			V:AssertEqual(animation.FadeIn:GetDuration(), PORTRAIT_NOTICE_FADE_DURATION, "Changelog notice uses the Friend Requests fade-in duration")
			V:AssertEqual(animation.FadeOut:GetDuration(), PORTRAIT_NOTICE_FADE_DURATION, "Changelog notice uses the Friend Requests fade-out duration")

			self:SetPortraitNoticeAnimationPlaying(owner, true)
			V:Assert(animation:IsPlaying(), "Changelog notice starts when a changelog is unread")
			self:SetPortraitNoticeAnimationPlaying(owner, false)
			V:Assert(not animation:IsPlaying(), "Changelog notice stops after the changelog is read")
			V:Assert(not owner.NewLabel:IsShown(), "Changelog notice is hidden after the changelog is read")
			owner:Hide()
		end,
	})
end

local function EnableChangelogResize(frame)
	local minWidth, minHeight = 600, 500
	local function UpdateBounds()
		local maxWidth = math.max(minWidth, UIParent:GetWidth())
		local maxHeight = math.max(minHeight, UIParent:GetHeight())
		if frame.SetResizeBounds then
			frame:SetResizeBounds(minWidth, minHeight, maxWidth, maxHeight)
		else
			frame:SetMinResize(minWidth, minHeight)
			frame:SetMaxResize(maxWidth, maxHeight)
		end
		return maxWidth, maxHeight
	end

	frame:SetResizable(true)
	frame:SetClampedToScreen(true)
	local maxWidth, maxHeight = UpdateBounds()
	local DB = BFL:GetModule("DB")
	local size = DB and DB:Get("changelogWindowSize")
	if type(size) ~= "table" then
		size = {}
	end
	frame:SetSize(
		math.max(minWidth, math.min(maxWidth, tonumber(size.width) or minWidth)),
		math.max(minHeight, math.min(maxHeight, tonumber(size.height) or minHeight))
	)
	frame:ClearAllPoints()
	frame:SetPoint("CENTER", UIParent, "CENTER", tonumber(size.x) or 0, tonumber(size.y) or 0)

	local grip = CreateFrame("Button", nil, frame)
	grip:SetSize(16, 16)
	grip:SetPoint("BOTTOMRIGHT", -3, 3)
	grip:SetFrameLevel(frame:GetFrameLevel() + 10)
	grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
	grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight", "ADD")
	grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")

	local dragMode
	local function StopDrag()
		if not dragMode then
			return
		end
		dragMode = nil
		frame:StopMovingOrSizing()
		frame:SetUserPlaced(false)
		if DB then
			local x, y = frame:GetCenter()
			local screenX, screenY = UIParent:GetCenter()
			DB:Set("changelogWindowSize", {
				width = frame:GetWidth(),
				height = frame:GetHeight(),
				x = x and screenX and x - screenX or size.x,
				y = y and screenY and y - screenY or size.y,
			})
		end
	end
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", function()
		frame:StartMoving()
		dragMode = "move"
	end)
	frame:SetScript("OnDragStop", StopDrag)
	grip:SetScript("OnMouseDown", function(_, button)
		if button == "LeftButton" then
			UpdateBounds()
			frame:StartSizing("BOTTOMRIGHT")
			dragMode = "resize"
		end
	end)
	grip:SetScript("OnMouseUp", function()
		if dragMode == "resize" then
			StopDrag()
		end
	end)
	frame:HookScript("OnHide", StopDrag)
end

function Changelog:CreateChangelogWindow()
	-- Use ButtonFrameTemplate to match Settings window
	local frame = CreateFrame("Frame", "BetterFriendlistChangelogFrame", UIParent, "ButtonFrameTemplate")
	frame.BFL_AccentTextures = {}
	frame.BFL_AccentFontStrings = {}
	frame.BFL_SecondaryAccentFontStrings = {}
	frame:SetFrameStrata("DIALOG")
	frame:EnableMouse(true)
	frame:SetMovable(true)
	EnableChangelogResize(frame)

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
	ApplyChangelogFont(frame.TitleText or (frame.TitleContainer and frame.TitleContainer.TitleText))

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
	frame.BFL_HeaderBackground = headerBg
	headerBg:SetAllPoints()
	headerBg:SetColorTexture(0.1, 0.1, 0.1, 0.5)

	-- Separator line
	local headerLine = headerFrame:CreateTexture(nil, "ARTWORK")
	frame.BFL_HeaderLine = headerLine
	headerLine:SetHeight(1)
	headerLine:SetPoint("BOTTOMLEFT", 0, 0)
	headerLine:SetPoint("BOTTOMRIGHT", 0, 0)
	headerLine:SetColorTexture(0.4, 0.4, 0.4, 0.8)

	local headerGroup = CreateFrame("Frame", nil, headerFrame)
	headerGroup:SetPoint("CENTER")
	local buttonWidth, buttonGap = 130, 10
	local headerText = CreateChangelogText(headerGroup, "BetterFriendlistFontNormal")
	headerText:SetPoint("LEFT")
	headerText:SetJustifyH("LEFT")
	headerText:SetText(L.CHANGELOG_HEADER_COMMUNITY)
	local labelWidth = math.min(math.ceil(headerText:GetStringWidth()), 150)
	headerText:SetWidth(labelWidth)
	headerGroup:SetSize(labelWidth + 3 * (buttonWidth + buttonGap), 24)

	frame.BFL_SupportLinks = {
		{ key = "DiscordButton", icon = "discord", label = L.CHANGELOG_DISCORD,
			url = "https://discord.gg/dpaV8vh3w3", popup = L.CHANGELOG_POPUP_DISCORD },
		{ key = "GitHubButton", icon = "github", label = L.CHANGELOG_GITHUB,
			url = "https://github.com/Hayato2846/BetterFriendlist/issues", popup = L.CHANGELOG_POPUP_GITHUB },
		{ key = "KoFiButton", icon = "kofi", label = L.CHANGELOG_SUPPORT,
			url = "https://ko-fi.com/hayato2846", popup = L.CHANGELOG_POPUP_SUPPORT },
	}
	local previousButton
	for _, link in ipairs(frame.BFL_SupportLinks) do
		local button = CreateSupportButton(frame, headerGroup, link, false)
		button:SetSize(buttonWidth, 24)
		if previousButton then
			button:SetPoint("RIGHT", previousButton, "LEFT", -buttonGap, 0)
		else
			button:SetPoint("RIGHT")
		end
		link.button = button
		frame[link.key] = button
		previousButton = button
	end

	-- ScrollFrame
	local scrollFrame

	if BFL.HasModernScrollBox and ScrollUtil and ScrollUtil.InitScrollFrameWithScrollBar then
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
	content:SetSize(math.max(1, frame:GetWidth() - 47), 1)
	scrollFrame:SetScrollChild(content)

	local entries = self:GetEntries()
	local entryFrames = {}
	local reflowEntries = {}
	local previousFrame = nil

	for i, entryData in ipairs(entries) do
		local entryFrame = CreateFrame("Frame", nil, content)

		if previousFrame then
			entryFrame:SetPoint("TOPLEFT", previousFrame, "BOTTOMLEFT", 0, -5)
		else
			entryFrame:SetPoint("TOPLEFT", 0, -5)
		end
		entryFrame:SetPoint("RIGHT", content, "RIGHT", -8, 0)

		-- Header
		local header = CreateFrame("Button", nil, entryFrame)
		header:SetHeight(20)
		header:SetPoint("TOPLEFT")
		header:SetPoint("RIGHT", entryFrame)

		-- Icon
		local icon = header:CreateTexture(nil, "ARTWORK")
		icon:SetSize(16, 16)
		icon:SetPoint("LEFT", 5, 0)
		icon:SetTexture("Interface\\AddOns\\BetterFriendlist\\Icons\\chevron-right.blp")

		-- Title
		local title = CreateChangelogText(header, "BetterFriendlistFontNormal")
		title:SetPoint("LEFT", icon, "RIGHT", 5, 0)
		title:SetText(string.format(L.CHANGELOG_HEADER_VERSION, entryData.version))

		-- Date
		local dateLabel = CreateChangelogText(header, "BetterFriendlistFontNormal")
		dateLabel:SetWidth(85) -- Fixed width for alignment (fits YYYY-MM-DD)
		dateLabel:SetJustifyH("LEFT") -- Left align for clean column start
		dateLabel:SetPoint("RIGHT", header, "RIGHT", -5, 0)
		dateLabel:SetText(entryData.date)

		-- Content
		local entryContent = CreateFrame("Frame", nil, entryFrame)
		entryContent:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -5)
		entryContent:SetPoint("RIGHT", entryFrame)

		local rows = {}
		for _, block in ipairs(entryData.blocks) do
			local region, bullet
			if block.type == "separator" then
				region = entryContent:CreateTexture(nil, "ARTWORK")
				region:SetTexture("Interface\\Common\\UI-TooltipDivider-Transparent")
				region:SetHeight(8)
			else
				local template = "BetterFriendlistFontHighlight"
				if block.type == "h1" then
					template = "BetterFriendlistFontLarge"
				elseif block.type == "h3" or block.type == "h4" then
					template = "BetterFriendlistFontNormal"
				end
				region = CreateChangelogText(entryContent, template)
				region:SetJustifyH("LEFT")
				region:SetText(block.content)
				if block.type == "h3" then
					region:SetTextColor(GetAccentColor(1, 0.82, 0, 1))
					table.insert(frame.BFL_AccentFontStrings, region)
				elseif block.type == "h4" then
					region:SetTextColor(GetSecondaryAccentColor())
					table.insert(frame.BFL_SecondaryAccentFontStrings, region)
				elseif block.type == "list_item" then
					bullet = CreateChangelogText(entryContent, "BetterFriendlistFontHighlight")
					bullet:SetText("•")
				end
			end
			rows[#rows + 1] = { region = region, bullet = bullet, kind = block.type }
		end

		local function LayoutEntry(width)
			local y = -5
			for _, row in ipairs(rows) do
				local left = row.bullet and 30 or 10
				local region = row.region
				region:ClearAllPoints()
				region:SetPoint("TOPLEFT", left, y)
				region:SetWidth(math.max(1, width - left - 10))
				local height = row.kind == "separator" and 8 or region:GetStringHeight()
				if row.bullet then
					row.bullet:ClearAllPoints()
					row.bullet:SetPoint("TOPLEFT", 15, y)
					height = math.max(height, row.bullet:GetStringHeight())
				end
				local gap = row.kind == "h1" and 10 or (row.kind == "separator" and 7 or 5)
				y = y - height - gap
			end
			entryContent:SetHeight(-y)
			entryFrame:SetHeight(25 - y)
		end

		-- Toggle Logic
		local isExpanded = (i == 1)

		local function UpdateState()
			if isExpanded then
				LayoutEntry(content:GetWidth() - 8)
				entryContent:Show()
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

		reflowEntries[i] = function(width)
			if isExpanded then
				LayoutEntry(width)
			end
		end
		UpdateState()

		table.insert(entryFrames, entryFrame)
		previousFrame = entryFrame
	end

	RecalculateHeight(content, entryFrames)
	scrollFrame:HookScript("OnSizeChanged", function(_, width)
		if width <= 8 or width == content:GetWidth() then
			return
		end
		content:SetWidth(width)
		for _, reflow in ipairs(reflowEntries) do
			reflow(width - 8)
		end
		RecalculateHeight(content, entryFrames)
	end)

	changelogFrame = frame
	self:RefreshAccentColors()
	frame:Hide()
end
