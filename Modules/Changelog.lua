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

local SUPPORT_LINKS = {
	{ id = "discord", key = "DiscordButton", labelKey = "CHANGELOG_DISCORD",
		popupKey = "CHANGELOG_POPUP_DISCORD", url = "https://discord.gg/dpaV8vh3w3" },
	{ id = "github", key = "GitHubButton", labelKey = "CHANGELOG_GITHUB",
		popupKey = "CHANGELOG_POPUP_GITHUB", url = "https://github.com/Hayato2846/BetterFriendlist/issues" },
	{ id = "kofi", key = "KoFiButton", labelKey = "CHANGELOG_SUPPORT",
		popupKey = "CHANGELOG_POPUP_SUPPORT", url = "https://ko-fi.com/hayato2846" },
}
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

## [3.1.0]        - 2026-11-10

### All WoW Versions

#### Added
- **New Settings** - Open Settings from the friends list or type /bfl settings to browse by category or search for an option. Search puts matching pages and results you often choose near the top. Hover over a setting to see what it does, or click its row to keep it highlighted and pin the help and any comparison. The main preview shows your saved setup.
- **Friend Tags** - Use Icon Color to tint any tag icon, including Blizzard icons and custom paths. In Icon Only mode, you can show the tinted icon on its own.
- **Tag Sections** - Choose a section for each tag, including Blizzard tags, or create your own. Drag sections and the tags inside them to set their order in the editor and friend menu. You can hide sections or delete them with or without their tags.
- **Dynamic Tag Groups** - Show each friend in their highest matching tag group. Choose a standard header, a colored title, or Tag Chip to tint the header and show the tag icon beside the title.
- **Blizzard Tags** - Remove built-in tags from BetterFriendlist and bring them back with Restore Tags. Their assignments are kept.

#### Improved
- **Global Friend Sync** - Global Sync is available on flavors that still use WoW's old friends list. Its settings and invite shortcuts are hidden on flavors that use Title Friends.

#### Fixed
- **Nickname Dialog** - Canceling the new group window no longer leaves red text or a group-name error in the nickname box.
- **World Map Tooltips** - Quest tooltips from the world map no longer pop up through the friends list.
- **Friend Requests** - Fixed missing pop-ups for Battle.net and Title Friend requests. The pop-ups still follow your WoW notification settings.
- **Raid Tab** - Raid members listed as Unknown now show their name as soon as WoW has it. You can right-click them once the name appears.
- **Window Scale** - The friends list keeps its scale when you switch between fullscreen and windowed mode. Settings and Friend Tags follow the friends list scale and fit on smaller screens.
- **Friend Tags** - Creating a tag keeps the editor where you placed it. Confirm or cancel the color picker before applying changes to a tag. Custom tags in the friend menu follow the order you set in the editor.
- **Settings** - The active category stays highlighted when you adjust Control Opacity.

### Retail Midnight & WoW Forever

#### Improved
- **Friend Search** - Find Title Friends even when they're offline, or search by Battle.net account name, including Real ID names.
- **Copy BattleTag** - In the Modern friends list, the icon next to your BattleTag now copies it straight to your clipboard when WoW supports it.

#### Fixed
- **Who Search Builder** - The Who results scrollbar no longer overlaps the search builder's close button in the Modern layout.
- **Title Friends** - Character names appear once in the friends list and Friends Broker, with class colors and icons.

### Retail Midnight

#### Fixed
- **Friend Invites** - The invite button now works for Battle.net friends with one character you can invite, even when WoW leaves out some character details.
- **Recent Allies** - The tab shows the last known list right away and updates it in the background.

### WoW Forever

#### Fixed
- **Who Searches** - Shift-left-clicking a character name in chat runs the lookup without opening BetterFriendlist's Who tab by default. You can turn automatic opening on under Who settings.
- **Title Friends** - Title Friends keep their groups and friend notes when they go offline, switch characters, or you log back in. BFL stores the note text in the addon and uses a short ID in the Blizzard note. To move the text back to Blizzard, type `/bfl titlefriendnotes off`.

---

## [3.0.3]        - 2026-11-09

### All WoW Versions

#### Fixed
- **Friend Menus** - Fixed cases where right-clicking a friend failed to open their menu.
- **Whispers** - Click to Whisper and the Whisper menu option now open the chat box in cases where they previously failed.
- **Who Searches** - Who no longer skips searches that previously left the results list unchanged.

---

## [3.0.2]        - 2026-11-07

BetterFriendlist 3.0.2 brings back Blizzard's friend menu, fixes chat taint when you start a whisper, and makes friend tags easier to edit.

### All WoW Versions

#### Added
- **Hints** - BFL can now show a hint when a nickname, friend tag, private note, new group, or favorite is hidden. You can open the options from the hint.

#### Improved
- **Friend Menus** - Blizzard's friend menu is back in both layouts when you right-click a friend in the list or Friends Broker. BFL's group, nickname, and tag options are there too, along with actions from compatible addons.
- **Raid Tab** - Right-click a raid member to open Blizzard's raid menu.
- **Friend Tag Editor** - Preview changes for each tag and use Save All to save your drafts when closing the editor. Reset previews the default look, and the delete prompt shows how many friends have the tag.
- **Tag Appearance** - Open the icon picker in one click, enter a custom path, or remove the icon. Icon Only keeps your custom text for later, and hiding a tag keeps your choices for where it appears.

#### Fixed
- **Chat Taint** - Whisper from a right-click menu, single- and double-click whispers, and the Legacy Send Message button now use Blizzard's own whisper action to fix chat taint. Who, Recent Allies, the guild tab, and both brokers use it too, so the separate Taint-Free Whisper window and setting are gone.
- **Friend Tag Editor** - Fixed a bug that could reset a custom tag's name, icon, text, or colors when you switched tags or made a new one.
- **Settings** - Guild filters, sorting, and row options now take effect right away in both settings windows. The same goes for Streamer Mode and broker display options.

### Retail Midnight

#### Improved
- **Forever Friends** - See a Forever friend's realm ruleset in the friends list and tooltips, or add it to a custom format with `%ruleset%`. The display updates when they switch between Forever and Retail.

#### Fixed
- **Blizzard Friend Tags** - Removing a friend's last Blizzard tag updates the list right away. You can edit another friend's tags while the first change is still pending.

### Retail Midnight & WoW Forever

#### Improved
- **Legacy Settings** - When you use the Modern friends list, Legacy Settings uses the same backgrounds, dividers, and scrollbar.

### WoW Forever

#### Improved
- **Friend Invites** - Invite and Request to Join in Blizzard's friend menu check realm rulesets, even if your friend has more than one character online.

#### Fixed
- **Who Searches** - The friends list stays put when another addon runs a Who search in the background.

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
]]

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

local function GetChangelogActions()
	local links = {}
	for index, link in ipairs(SUPPORT_LINKS) do
		links[index] = {
			id = link.id,
			key = link.key,
			icon = link.id,
			url = link.url,
			label = L[link.labelKey],
			popup = L[link.popupKey],
		}
	end
	return links
end

function Changelog:GetSupportLinks()
	local links = {}
	for index, link in ipairs(SUPPORT_LINKS) do
		links[index] = {
			id = link.id,
			url = link.url,
			label = L[link.popupKey],
			shortLabel = (L[link.labelKey]:gsub("^%s+", "")),
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
			bflChangelogVersion = entryData.version,
			entries = content,
		}
	end
	return entries
end

function Changelog:ShowDiscordPopup()
	ShowCopyDialog("https://discord.gg/dpaV8vh3w3", L.CHANGELOG_POPUP_DISCORD)
end

local function GetReadState(entries)
	local DB = BFL:GetModule("DB")
	local state = DB:Get("changelogReadState")
	if type(state) == "table" and type(state.through) == "string" and state.through ~= "" and type(state.versions) == "table" then
		return state
	end
	local through = DB:Get("lastChangelogVersion", "0.0.0")
	if through == "0.0.0" and entries[2] then
		through = entries[2].version
	end
	state = { through = through, versions = {} }
	DB:Set("changelogReadState", state)
	return state
end

local function IsNewerVersion(version, through)
	if version == through then return false end
	local versionParts = { version:match("^v?(%d+)%.(%d+)%.(%d+)(.*)$") }
	local throughParts = { through:match("^v?(%d+)%.(%d+)%.(%d+)(.*)$") }
	if #versionParts == 0 or #throughParts == 0 then return true end
	for index = 1, 3 do
		local current, read = tonumber(versionParts[index]), tonumber(throughParts[index])
		if current ~= read then return current > read end
	end
	return throughParts[4] ~= ""
end

function Changelog:GetUnreadVersions(entries)
	entries = entries or self:GetEntries()
	local state = GetReadState(entries)
	local unread = {}
	local throughIndex
	for index, entry in ipairs(entries) do
		if entry.version == state.through then
			throughIndex = index
			break
		end
	end
	for index, entry in ipairs(entries) do
		local version = entry.version
		local newer = throughIndex and index < throughIndex
		if not throughIndex then newer = IsNewerVersion(version, state.through) end
		if newer and not state.versions[version] then
			unread[version] = true
		end
	end
	return unread
end

function Changelog:HasUnreadVersions()
	return next(self:GetUnreadVersions()) ~= nil
end

function Changelog:MarkVersionRead(version)
	local entries = self:GetEntries()
	if not self:GetUnreadVersions(entries)[version] then return end
	local state = GetReadState(entries)
	state.versions[version] = true
	BFL:GetModule("DB"):Set("changelogReadState", state)
end

function Changelog:ResetReadState()
	local previous = self:GetEntries()[2]
	BFL:GetModule("DB"):Set("changelogReadState", { through = previous and previous.version or "0.0.0", versions = {} })
	local review = BFL:GetModule("LegacySettingsReview")
	if review and review.home then self:RefreshReleaseBadges(review.home.entries) end
end

function Changelog:GetNewBadge(inVersionRow)
	local atlas, height, width
	if BFL.IsClassic then
		atlas, height, width = "communities-icon-invitemail", inVersionRow and 20 or 48, inVersionRow and 27 or 64
	else
		-- The inline atlas renders smaller in the release header than in the menu.
		atlas, height, width = "NewCharacter-Alliance", inVersionRow and 35 or 29, inVersionRow and 68 or 56
	end
	local badge = BFL.GetAtlasOrTextureMarkup(atlas, "", height, width)
	if badge ~= "" then return badge end
	return "|cffffa640" .. L.SETTINGS_CENTER_NEW .. "|r"
end

function Changelog:Initialize()
	self:GetUnreadVersions()
	-- Setup PortraitButton for Classic - create entirely in Lua for full control
	if BFL.IsClassic and BetterFriendsFrame then
		self:SetupClassicPortraitButton()
	end
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

	-- Keep the portrait on a separate surface for the Classic layout and skins.
	local button = CreateFrame("Button", "BFL_ClassicPortraitButton", frame)
	button:EnableMouse(false)
	button:SetSize(60, 60)

	-- Ensure it sits above the frame background
	button:SetFrameLevel(frame:GetFrameLevel() + 5)

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

	-- Position relative to main frame
	button:ClearAllPoints()
	button:SetPoint("TOPLEFT", -5, 7)

	-- Store reference
	frame.PortraitButton = button
	frame.PortraitIcon = icon
end

local function CreateSupportButton(frame, parent, link, modern)
	local template = modern and "SharedButtonTemplate" or "UIPanelButtonTemplate"
	local button = CreateFrame("Button", nil, parent, template)
	button.BFL_DarkManagedSubtree = true
	button:SetText(link.label)
	local label = button:GetFontString()
	ApplyChangelogFont(label)
	if label then
		label:ClearAllPoints()
		label:SetPoint("LEFT", 25, 0)
		label:SetPoint("RIGHT", -7, 0)
		label:SetJustifyH("CENTER")
	end
	if modern then
		for _, event in ipairs({ "OnShow", "OnEnter", "OnLeave", "OnEnable", "OnDisable" }) do
			button:HookScript(event, function(owner)
				ApplyChangelogFont(owner:GetFontString())
			end)
		end
	end

	local icon = button:CreateTexture(nil, "ARTWORK")
	icon:SetSize(14, 14)
	icon:SetPoint("LEFT", 10, 0)
	button.BFL_SupportIcon = icon
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

function Changelog:CreateSupportButtons(surface, parent, modern)
	local buttons = {}
	for index, link in ipairs(GetChangelogActions()) do
		buttons[index] = CreateSupportButton(surface, parent, link, modern)
	end
	self:ApplySurfaceAccent(surface)
	return buttons
end

function Changelog:RefreshAccentColors()
	local review = BFL:GetModule("LegacySettingsReview")
	if review and review.home and review.home.entries then
		self:ApplySurfaceAccent(review.home)
		self:RefreshReleaseBadges(review.home.entries)
	end
	if review and review.support then self:ApplySurfaceAccent(review.support) end
end

function Changelog:ApplySurfaceAccent(frame)
	local accentR, accentG, accentB = GetAccentColor(1, 0.82, 0, 1)
	local secondaryAccentR, secondaryAccentG, secondaryAccentB = GetSecondaryAccentColor()
	if frame.BFL_AccentTextures then
		for _, texture in ipairs(frame.BFL_AccentTextures) do
			if texture and texture.SetColorTexture then
				texture:SetColorTexture(accentR, accentG, accentB, 1)
			elseif texture and texture.SetVertexColor then
				texture:SetVertexColor(accentR, accentG, accentB, 1)
			end
		end
	end
	if frame.BFL_AccentFontStrings then
		for _, fontString in ipairs(frame.BFL_AccentFontStrings) do
			if fontString and fontString.SetTextColor then
				fontString:SetTextColor(accentR, accentG, accentB)
			end
		end
	end
	if frame.BFL_SecondaryAccentFontStrings then
		for _, fontString in ipairs(frame.BFL_SecondaryAccentFontStrings) do
			if fontString and fontString.SetTextColor then
				fontString:SetTextColor(secondaryAccentR, secondaryAccentG, secondaryAccentB)
			end
		end
	end
end

function Changelog:RefreshReleaseBadges(entryFrames)
	local unread = self:GetUnreadVersions()
	for _, entry in ipairs(entryFrames) do
		entry:RefreshHeader(unread[entry.Version] == true)
	end
end

local RELEASE_HEADER_HEIGHT = 24

local function CreateReleaseHeader(parent, entryData, modern)
	local template = modern and "BFLModernGroupHeaderTemplate" or "BetterFriendsGroupHeaderTemplate"
	local header = CreateFrame("Button", nil, parent, template)
	header.BFL_SettingsReleaseHeader = true
	header.BFL_DarkManagedSubtree = true
	header:SetHeight(RELEASE_HEADER_HEIGHT)
	header:SetPoint("TOPLEFT")
	header:SetPoint("TOPRIGHT")

	local title = header.HeaderText or header:GetFontString()
	ApplyChangelogFont(title)
	title:ClearAllPoints()
	title:SetPoint("LEFT", 25, 0)
	title:SetJustifyH("LEFT")
	title:SetWordWrap(false)
	title:SetText(FormatVersionTitle(entryData.version))

	if header.CountText then header.CountText:Hide() end
	if header.CollapseButton then
		header.CollapseButton:ClearAllPoints()
		header.CollapseButton:SetPoint("LEFT", 6, 0)
		header.CollapseButton:EnableMouse(false)
		title:SetPoint("LEFT", header.CollapseButton, "RIGHT", 4, 0)
		header.elementData = {}
	else
		BFL.SetTextureOrAtlas(header.RightArrow, "friendslist-categorybutton-arrow-left", "Interface\\AddOns\\BetterFriendlist\\Icons\\chevron-right")
		BFL.SetTextureOrAtlas(header.DownArrow, "friendslist-categorybutton-arrow-down", "Interface\\AddOns\\BetterFriendlist\\Icons\\chevron-down")
	end

	local dateLabel = CreateChangelogText(header, "BetterFriendlistFontNormal")
	dateLabel:SetWidth(85)
	dateLabel:SetJustifyH("LEFT")
	dateLabel:SetPoint("RIGHT", -8, 0)
	dateLabel:SetText(entryData.date)

	local badge = CreateChangelogText(header, "BetterFriendlistFontHighlightSmall")
	badge:SetPoint("RIGHT", dateLabel, "LEFT", -8, 0)
	badge:SetText(Changelog:GetNewBadge(true))
	title:SetPoint("RIGHT", badge, "LEFT", -8, 0)
	header.NewBadge = badge
	return header
end

function Changelog:CreateReleaseEntries(content, frame, onHeightChanged, limit)
	local entries = self:GetEntries()
	local unread = self:GetUnreadVersions(entries)
	local entryFrames = {}
	local reflowEntries = {}
	local previousFrame = nil

	local function UpdateHeight()
		RecalculateHeight(content, entryFrames)
		if onHeightChanged then
			onHeightChanged(content:GetHeight())
		end
	end

	for i, entryData in ipairs(entries) do
		if limit and i > limit then
			break
		end
		local entryFrame = CreateFrame("Frame", nil, content)

		if previousFrame then
			entryFrame:SetPoint("TOPLEFT", previousFrame, "BOTTOMLEFT", 0, -5)
		else
			entryFrame:SetPoint("TOPLEFT", 0, -5)
		end
		entryFrame:SetPoint("RIGHT", content, "RIGHT", -8, 0)

		entryFrame.Version = entryData.version

		-- Content
		local entryContent = CreateFrame("Frame", nil, entryFrame)
		entryContent:SetPoint("TOPLEFT", entryFrame, "TOPLEFT", 0, -RELEASE_HEADER_HEIGHT - 5)
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
			entryFrame:SetHeight(RELEASE_HEADER_HEIGHT + 5 - y)
		end

		-- Toggle Logic
		local isExpanded = false

		local function UpdateState()
			if isExpanded then
				LayoutEntry(content:GetWidth() - 8)
				entryContent:Show()
			else
				entryContent:Hide()
				entryFrame:SetHeight(RELEASE_HEADER_HEIGHT)
			end
		end

		local headers = {}
		local function Toggle()
			isExpanded = not isExpanded
			if isExpanded then
				self:MarkVersionRead(entryData.version)
			end
			UpdateState()
			entryFrame:RefreshHeader(false)
			UpdateHeight()
		end

		function entryFrame:RefreshHeader(isUnread)
			local ui = BFL:GetModule("FriendsUI")
			local modern = ui and ui:IsModernActive() == true or false
			local header = headers[modern]
			if not header then
				header = CreateReleaseHeader(self, entryData, modern)
				header:SetScript("OnClick", Toggle)
				headers[modern] = header
			end
			if self.Header and self.Header ~= header then self.Header:Hide() end
			self.Header, self.NewBadge = header, header.NewBadge
			header:Show()
			header.NewBadge:SetShown(isUnread)
			if modern then
				header.elementData.collapsed = not isExpanded
				ui:StyleGroupHeader(header)
			else
				header.RightArrow:SetShown(not isExpanded)
				header.DownArrow:SetShown(isExpanded)
			end
			local style = BFL:GetModule("LegacySettingsStyle")
			if style then style:SkinReleaseHeader(header, modern) end
		end

		reflowEntries[i] = function(width)
			if isExpanded then
				LayoutEntry(width)
			end
		end
		UpdateState()
		entryFrame:RefreshHeader(unread[entryData.version] == true)

		table.insert(entryFrames, entryFrame)
		previousFrame = entryFrame
	end


	local lastWidth
	local function Reflow(_, width)
		if width <= 8 or width == lastWidth then
			return
		end
		lastWidth = width
		for _, reflow in ipairs(reflowEntries) do
			reflow(width - 8)
		end
		UpdateHeight()
	end
	content:HookScript("OnSizeChanged", Reflow)
	UpdateHeight()
	Reflow(content, content:GetWidth())
	return entryFrames
end
