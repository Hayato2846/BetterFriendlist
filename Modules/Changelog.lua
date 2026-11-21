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

## [3.1.6]        - 2026-11-21

### WoW Retail & WoW Forever

#### Fixed
- **Battle.net Party Invites** - The invite button works when WoW provides realm information without a numeric realm ID.

---

## [3.1.5]        - 2026-11-21

### All WoW Versions

#### Fixed
- **Remove Friend** - Character friends can be removed from the right-click menu using Blizzard's confirmation dialog.
- **Friend Notes** - Editing a character friend's note no longer shows an erroneous player-not-found message.
- **Friends List** - Newly added character friends and accepted friend requests appear sooner once the game delivers their details.

### WoW Retail & WoW Forever

#### Fixed
- **Modern Raid Tab** - Online raid and party members have class-colored row backgrounds again.

---

## [3.1.4]        - 2026-11-17

### All WoW Versions

#### Improved
- **Blizzard Friendlist Access** - Moved the option to Advanced under Diagnostics and disabled it once for the 3.1.4 update. Re-enabling requires confirmation that this is for diagnostics only; BetterFriendlist fully replaces Blizzard's friends list and does not support running both lists in parallel.

### WoW Retail & WoW Forever

#### Fixed
- **Who Searches** - A /who command rejected during the search cooldown no longer overwrites the text in the Who search box.

### WoW Forever

#### Improved
- **Who Searches** - Blizzard's wait messages appear in the Who tab in your game client's language. Searches with no result or recognized wait message still show the timeout notice.

### WoW Classic

#### Fixed
- **Who Sorting** - The Name, Level, and Class sort order is kept when Who results refresh or the Who tab is reopened.

---

## [3.1.3]        - 2026-11-15

### All WoW Versions

#### Fixed
- **Settings Menu** - The Settings entry in the contacts menu keeps its normal size when marked New.

---

## [3.1.2]        - 2026-11-14

### All WoW Versions

#### Added
- **Favorite Icon** - Choose the Modern Blizzard favorite star where available, alongside the existing BFL and Blizzard styles.
- **Settings Window** - Everyone now uses the redesigned Settings. Resize the window and keep your preferred size; narrow windows use a separate preview and help window that docks on the free side and remembers its width, height and collapsed state. Open or close it from the Settings edge, use setting tooltips while it is closed, or widen Settings to bring the panel back inside.
- **New Settings** - New options and their categories carry the same New badge as unread changelog entries. Click an individual setting to mark it read; category badges clear when all their new options have been read. Read status is saved per profile.
- **Settings Scrolling** - Enable smooth mouse-wheel scrolling in Settings independently of the friends list. Disabled by default.
- **Window Fonts** - Set fonts and sizes for window titles and main action buttons separately, with previews and a reset to their original fonts.
- **Input Dialogs** - Create groups, tags, and sections, rename groups, or copy links and names in windows that match your BFL theme. You can choose native input dialogs under Theme.
- **BFL Avatar** - Dark, Custom, ElvUI and EllesmereUI hide the avatar by default. Turn off Hide BFL Avatar under Theme to show it again.

#### Improved
- **Side Windows** - Dialogs and hints use the free space beside the friends list and switch sides when needed. In the Modern layout, they prefer the selected tab side.
- **Scrollbars** - Modern scrollbars retain their Blizzard appearance and use the accent color of Dark, Custom, ElvUI or EllesmereUI themes. Disabled scroll arrows stay gray.
- **Friend Tag Editor** - A redesigned editor matches Settings, with tag search, clearer sections, drag-and-drop feedback and direct list actions. Edit icons or custom paths, text, colors and visibility with live previews and pinnable help; per-tag drafts are kept until you apply or discard them, including when switching tags or resizing.
- **Name Formatting** - Browse format fields in a list under Setting details, collapsed by default. Click a field to select its token for copying.
- **QuickFilters & Sorters** - Manage filters and sorters in a simpler list, with descriptions for built-in filters and clearer game and status icons. Matching Blizzard icons are used where available; the remaining icons will be updated in a future release.
- **Groups** - Create a group from a group header, Group Management, or Group Order.

#### Fixed
- **Display Changes** - Button text and group counters refresh after switching display modes or changing UI scale.
- **Themes** - Raid Roster Help and the Assist All checkbox use the selected theme throughout, and button hover effects no longer reveal their original artwork. Footer backgrounds no longer extend into the friends list or leave an extra panel beside Add New Friend.
- **Known Characters** - The tooltip no longer repeats the character already shown above. Other known characters remain available, including when a friend is offline.
- **Tag Sections** - Hiding or showing a section updates its tags and dynamic tag groups immediately. Each tag keeps its previous visibility choices.
- **Settings Performance** - Reduced pauses when changing pages, toggling QuickFilters or changing Simple Mode with the Dark or Custom theme.
- **Theme Settings** - Selecting Dark or Custom immediately shows its customization controls. Broker tooltip appearance options are shown only for themes that support them.
- **Settings Controls** - Disabled controls, including EllesmereUI dropdowns, look inactive throughout Settings; their rows still offer hover explanations.
- **Recently Added Group** - Duration Value accepts only numbers.
- **Settings Preview** - Empty-group notices identify the groups actually hidden in the preview.
- **Dynamic Tag Groups** - Friends in a tag group leave No Group, including when it has been renamed. Group invitation counts and actions use the members shown in that group.
- **Group Names** - Create and Rename accept letters after a popup slot was used for numeric input.
- **Friend Invites** - Right-click menus preserve Blizzard's invitation action and offer a character picker when multiple accounts are available.
- **Window Position and Scaling** - The friends list restores its saved position after switching display modes or reopening near a screen corner. Settings stays within the available screen space when the friends list scale changes.
- **Raid Tab** - Party members whose names WoW temporarily hides show as Unknown. Raid members appear as soon as WoW provides their name, even if the raid roster is still loading.

### WoW Retail & WoW Forever

#### Added
- **Friend Tabs** - Place Modern tabs on the left or right of the friends list, with the right side as the default. The window keeps the selected tab rail on screen when you change sides.

#### Improved
- **Quick Join** - Group tooltips show when a listing welcomes new players.

#### Fixed
- **Search Field** - With ElvUI loaded and the Blizzard theme selected, the native search field no longer draws an extra background over BFL's search box.

### WoW Forever

#### Improved
- **Quick Join** - Group tooltips show when a listing uses Discord voice chat.

#### Fixed
- **Title Friends** - Whisper is available for Title Friends who appear offline. WoW looks up the character to whisper.

---

## [3.1.1]        - 2026-11-10

### All WoW Versions

#### Fixed
- **New Settings Hint** - The hint appears next to the friends list when you open it.

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
- **Title Friends** - Title Friends keep their groups and friend notes when they go offline, switch characters, or you log back in.

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

---

*Older versions archived. Full history available in git.*
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
	return BFL:GetModule("Dialogs"):ShowCopy(url, title, 350)
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

function Changelog:GetNewBadge()
	-- Text-only compatibility for retired Settings Center integrations.
	return NEW_CAPS or L.SETTINGS_CENTER_NEW
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

	local badge = BFL:GetModule("NewFeatureBadge"):Create(header)
	badge:SetPoint("RIGHT", dateLabel, "LEFT", -8, 0)
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
