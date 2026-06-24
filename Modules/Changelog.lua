-- Modules/Changelog.lua
-- Displays the changelog in a scrollable window

local ADDON_NAME, BFL = ...
local L = BFL.L
local Changelog = BFL:RegisterModule("Changelog", {})

local changelogFrame = nil
local SUPPORT_LINKS = {
	{ id = "discord", url = "https://discord.gg/dpaV8vh3w3" },
	{ id = "github", url = "https://github.com/Hayato2846/BetterFriendlist/issues" },
	{ id = "kofi", url = "https://ko-fi.com/hayato2846" },
}

local function GetAccentColor(fallbackR, fallbackG, fallbackB, fallbackA)
	if BFL.GetThemeAccentColor then
		return BFL:GetThemeAccentColor(fallbackR or 1, fallbackG or 0.82, fallbackB or 0, fallbackA or 1)
	end
	return fallbackR or 1, fallbackG or 0.82, fallbackB or 0, fallbackA or 1
end

-- Changelog content
local CHANGELOG_TEXT = [[# Changelog

All notable changes to BetterFriendlist will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [2.6.3]        - 2026-06-22

### Added
- **Settings Center Beta** - Added a LibSettingsDesigner-based Settings Center with dashboard, task-based categories, native controls, changelog/help pages, support links, New badges, and BFL Dark/Custom and ElvUI skin support. Enable it through Beta Features; the classic settings window remains the default.
- **Notes & Tags Beta** - Added local private notes for friends and ignored players plus Blizzard-compatible and custom BetterFriendlist tags, with row chips, tooltips, context menu actions, and Settings Center controls.
- **Auto Raid Assist** - Added an opt-in assistant picker for BattleTag friends, nickname matches, manual Character-Realm targets, friends, guild members, and current party or raid characters.

### Improved
- **QuickFilter Builder** - Added friend tag rules for tag text, tag source, tag count, and has-tag matching.
- **Auto Raid Assist** - Improved promotion reliability after party-to-raid conversion, cooldown waits, multiple matching targets, and same-realm character matching.
- **Client Compatibility** - Prepared Recruit A Friend, Quick Join, Battle.net friend metadata, censored Group Finder entries, and guild rank refreshes for Retail 12.1.

### Fixed
- **Classic Guild Window** - Kept Classic clients on Blizzard's separate Guild window so the Guild keybind no longer opens the Friends list.

### Removed
- **Settings Statistics** - Removed the retired settings statistics page from the modern and legacy settings flows.

---

## [2.6.2]        - 2026-06-17

### Improved
- **Broker Tooltip Theming** - Added settings for the shared Friends/Guild Broker separator color and per-theme Broker tooltip background color and opacity. Find the separator color under Settings > Data Broker > Broker Tooltip Appearance, and the background/opacity controls under Settings > Theme > Broker Tooltips.
- **Party Invites** - Improved the invite buttons in the WHO list and Recent Allies so they keep working reliably on Retail and Classic, including upcoming Retail updates.

### Fixed
- **Quick Join** - Restored the card-style group display with activity images.
- **Broker Separators** - Made Friends and Guild Broker header, group, empty-state, and footer separator lines use the same configured color and pixel-consistent thickness.
- **Guild Broker Groups** - Made expand and collapse indicators match Friends Broker formatting and use the same color as their group headers.
- **Menu Bridge** - Matched the companion AddOn category metadata to BetterFriendlist.
- **Predefined Groups** - Fixed Favorites, In-Game, and Recently Added groups sometimes expanding without their matching friends.

### Known Issues
- **Battle.net Favorites** - World of Warcraft currently reports no Battle.net Favorites for some accounts even when Favorites are set in the Battle.net Desktop App. This Blizzard API issue has been reported; BetterFriendlist cannot restore Favorite data while the client APIs return none.

---

## [2.6.1]        - 2026-05-31

### Added
- **Guild Tab Beta** - Added a default-off Retail-only beta Guild tab with BetterFriendlist-owned roster search, online/offline filtering, sorting, guild counts, member details, notes, class and status indicators, and safe member actions where permissions and Blizzard APIs allow them. Enable Beta Features under Settings > Advanced > Beta Features, then turn on the Guild roster tab under Settings > Guild. Classic support for this beta feature will follow in a later version.
- **External AddOn Menu Bridge Beta** - Added a default-off beta bridge and official companion AddOn for showing compatible AddOn actions in supported BetterFriendlist context menus. Enable it under Settings > Advanced > Beta Features.
- **Theme Customization** - Added Retail-only beta theme customization with a Custom theme based on Dark, expanded Dark and Custom settings for colors, opacity, hover and selection states, borders, scrollbars, icons, and BFL Avatar visibility. Enable Beta Features under Settings > Advanced > Beta Features, then configure themes under Settings > Theme. Classic support for these beta theme features will follow in a later version.
- **Raid Tab** - Added an optional compact Ready Check button next to Raid Info. Enable it under Settings > Raid.

### Improved
- **Guild Broker Tooltips** - Added a subtle separator between Friends Broker groups and Guild Broker rank groups.

### Changed
- **Client Compatibility** - Prepared friend invites and raid controls for upcoming Retail client changes while preserving current Retail and Classic support.
- **Raid Tools** - Improved handling for temporarily uncached raid roster names.
- **Font Rendering** - Made custom font handling more defensive on newer clients.

### Fixed
- **Friend Menus** - Restored Blizzard's invite versus request-to-join labels and actions for Battle.net friends.
- **Recruit A Friend** - Shortened the search placeholder and kept it on one line in the header search field.
- **Tabs** - Fixed truncated top and bottom tab labels showing duplicate hover tooltips.

### Performance
- **Top Tabs** - Reduced hitches when switching between Friends, Recent Allies, Recruit A Friend, and Guild tabs.
- **Guild Roster** - Reduced memory churn when reopening or switching to the Guild roster tab.
- **Quick Join** - Reduced repeated row-height work while showing available groups.

## [2.6.0]        - 2026-05-25

### Added
- **QuickFilter & Sorter Builder** - Added a dedicated settings tab for choosing visible QuickFilters and Sorters, building custom filter rules and sorter chains, previewing changes, and choosing BFL or Blizzard icons. Enable Beta Features under Advanced > Beta Features to show the tab.
- **Theme Settings and Dark Theme** - Added a dedicated Retail Theme tab with Blizzard, Dark, and ElvUI choices, plus a BFL-owned Dark theme for BetterFriendlist windows, rows, dialogs, settings, and broker tooltips. Enable Beta Features under Advanced > Beta Features to show the tab. Classic support will follow as soon as possible in one of the next releases.
- **Font Rendering** - Added per-font rendering flag settings and Slug rendering support on compatible clients.
- **WoW Online Filter** - Added a quick filter for showing only online friends who are currently in WoW.

### Changed
- **QuickFilter and Sorter Menus** - QuickFilter menus, sort dropdowns, and Broker cycling now respect custom visibility and order, with safe fallbacks for hidden active selections.
- **Theme Safety** - Theme choices now fall back safely when Beta Features are disabled, on non-Retail clients, or when ElvUI is unavailable.

### Fixed
- **Friend Tooltips** - Restored the "Also in group" details and Blizzard-matching restrictions on Battle.net request-to-join buttons.
- **ElvUI Skin** - Fixed startup, availability, and settings-toggle issues when ElvUI was selected, unavailable, or managed outside the Retail beta Theme tab.
- **Menu Compatibility** - Fixed protected Retail unit menu handling and restored Total RP 3 profile actions in BetterFriendlist friend menus.
- **Raid Tools** - Fixed a Lua error after moving players between raid groups with drag and drop.
- **Recruit A Friend** - Fixed reward-viewing tab issues, protected Copy Link errors, and a tooltip stack overflow.

### Performance
- **Friend List Sorting** - Reduced CPU time and memory churn when changing QuickFilters and Sorter selections.
- **Quick Join** - Reduced repeated group-priority and friend-relationship lookups while sorting available groups.

### Outlook
- **Guild Tab** - A Retail and Classic Guild tab is planned for upcoming releases, with a BetterFriendlist-owned roster view for searching guild members, filtering online/offline members, sorting by rank, name, level, class, zone, status, and last online time, and showing guild counts, notes, status, and class information through the shared safe roster provider.

## [2.5.9]        - 2026-05-17

### Fixed
- **ElvUI Top Tabs** - Centered the Friends, Recent Allies, and Recruit A Friend tab labels in the ElvUI skin.

## [2.5.8]        - 2026-05-16

### Added
- **Broker Tooltip Fonts** - Added an optional setting for using selected broker tooltip fonts on non-latin alphabets, with a warning about unsupported glyphs.
- **Guild Broker MOTD** - Added the guild message of the day to the Guild Broker tooltip with guarded cross-version handling.

### Fixed
- **Guild Broker Click Action** - Fixed the configured left-click action not opening the guild frame or broker settings.
- **Recruit A Friend Taint** - Reduced RAF list taint by keeping addon display data separate from Blizzard recruit records.

## [2.5.7]        - 2026-05-16

### Fixed
- **Classic Loading** - Fixed a load error after the latest update.

### Changed
- **Client Compatibility** - Added TOC support for newer Retail and Classic client builds.

## [2.5.6]        - 2026-05-15

### Added
- **Advanced: Taint-Free Whisper** - Added an optional inline whisper bar under Advanced that lets you message friends without opening Blizzard chat.
- **Friend List Whisper Click** - Added an optional Behavior setting to start whispers from friend rows with a double left-click or single left-click.
- **Broker Tooltip Fonts** - Added global font and font size settings for Friends and Guild broker tooltips.
- **Friends Broker: Filter-Aware Display** - Broker text and tooltip counts now follow the active quick filter, including Online, All, WoW only, and In A Game.
- **Friends Broker: Columns** - Added optional Nickname and Status columns, class icons in the Character column, and configurable group name alignment.
- **Broker Hover Details** - Friend and guild broker rows now show overlay detail tooltips on hover.
- **Friends Broker: Styling** - Added per-column colors, main-list name color syncing, ElvUI tooltip styling, Blizzard client icons, rich presence/mobile/app labels, and a toggle for footer hints.
- **Guild Broker Plugin** - Added an optional Data Broker plugin for guild rosters with online/all filtering, collapsible rank/class groups, configurable columns, member actions, rank management, and all-version support. Enable it in Settings > Broker > Guild Plugin.
- **Guild Broker: Roster Options** - Added nickname, professions, class icon, applicant count, hide-max-level, and exclude-yourself options, with drag-and-drop column ordering.
- **Guild Broker: Sorting and Status** - Added sort modes for name, rank, level, class, zone, and nickname plus AFK/DND status indicators.
- **Guild Broker: Colors** - Added custom nickname colors and configurable Rank, Zone, Note, and Officer Note colors.
- **Guild Broker: Compatibility** - Added support for Retail secret-value clients, migration-friendly saved column layouts, clean member tooltip cleanup, and streamlined profession rank display.

### Improved
- **Broker Refreshing** - Data Broker plugins now refresh reliably after Battle.net and friend roster updates, including when Beta Features are disabled.
- **Broker Display Compatibility** - Improved tooltip cleanup for broker display addons such as Arcana and Bazooka.
- **Secret-Value Context Menus** - Modern clients now use BetterFriendlist-owned friend menus for Friend, Battle.net Friend, and Recent Ally actions instead of patching protected Blizzard menus.
- **Friend Tooltips** - Battle.net friend hover tooltips now use sanitized data on secret-value clients and class colors when class-colored names are enabled.
- **Social Keybind** - The Social key now opens BetterFriendlist directly and migrates or restores cleanly without reload prompts or Guild/Communities taint.
- **Quick Join** - Group Finder listings opened from Quick Join now use Blizzard's native sign-up dialog.
- **Combat Window Toggle** - Opening and closing BetterFriendlist during combat is more reliable when Respect UI Hierarchy is enabled.

### Fixed
- **Blizzard Friends Frame Replacement** - Blizzard and addon calls that open the default Friends frame now route to BetterFriendlist more consistently, preventing both windows from opening or closing out of sync.
- **Escape Key Handling** - Pressing Escape now closes BetterFriendlist more reliably, including when the frame is opened outside the normal UI panel path.
- **Taint-Free Whisper Focus** - Closing the inline whisper bar with Escape no longer blocks normal keybinds while BetterFriendlist stays open.
- **Broker Hover Details** - Friend and guild broker detail tooltips now stay above the main broker tooltip and no longer trigger QTip release errors while closing.
- **Tab Navigation** - Fixed the window getting stuck on the Who or Quick Join tab after using /who or clicking a group join link.
- **Broker Counts** - Fixed stale, zero, total-friend, and filtered-count display problems across Friends broker quick filters.
- **Broker Group Headers** - Collapse and expand markers now render as `+` and `-` without extra parentheses.
- **Retail Chat Taint** - Reduced chat history taint by using secret-safe friend menu extension handling on modern clients.
- **Guild and Communities Taint** - On secret-value clients, BetterFriendlist now avoids Guild/Communities roster hooks and native guild menu extensions while Blizzard's Guild panel opens.
- **Recruit A Friend Taint** - Reduced RAF list taint noise on secret-value clients by keeping raw Battle.net account payloads out of RAF list rows.
- **Quick Join Messages** - Whisper links and Send Message actions from Quick Join now open the correct Battle.net conversation more reliably.

## [2.5.5]        - 2026-04-05

### Fixed
- **Retail: Quick Join** - Fixed a Lua error caused by protected values during combat restrictions.

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

local function ParseChangelog(text, includeUndated)
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

		if version and (date ~= "" or includeUndated == true) then -- Maintain legacy behavior unless callers opt into draft/undated entries.
			-- Actually, let's stick closer to original logic but allow extra spaces
			-- Trim date just in case
			date = date:match("^%s*(.-)%s*$")
			if date == "" then
				date = L.SETTINGS_CENTER_CHANGELOG_DRAFT or "Draft"
			end

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
		return { type = "text", text = "|cffcccccc" .. content .. "|r" }
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

function Changelog:GetSettingsCenterEntries(limit)
	local entries = {}
	for index, entryData in ipairs(ParseChangelog(CHANGELOG_TEXT, true)) do
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

function Changelog:ShowGlow(show)
	if BetterFriendsFrame and BetterFriendsFrame.PortraitButton then
		local button = BetterFriendsFrame.PortraitButton
		local accentR, accentG, accentB, accentA = GetAccentColor(1, 0.82, 0, 1)

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
			-- Desaturate to remove the native color, then color it with the active accent.
			button.NewLabel:SetDesaturated(true)
		end
		if button.NewLabel then
			button.NewLabel:SetVertexColor(accentR, accentG, accentB, accentA)
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

function Changelog:RefreshAccentColors()
	if not changelogFrame then
		return
	end

	local accentR, accentG, accentB = GetAccentColor(1, 0.82, 0, 1)
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
end

function Changelog:CreateChangelogWindow()
	-- Use ButtonFrameTemplate to match Settings window
	local frame = CreateFrame("Frame", "BetterFriendlistChangelogFrame", UIParent, "ButtonFrameTemplate")
	frame.BFL_AccentTextures = {}
	frame.BFL_AccentFontStrings = {}
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
	dcIcon:SetColorTexture(GetAccentColor(1, 0.82, 0, 1))
	table.insert(frame.BFL_AccentTextures, dcIcon)

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
	ghIcon:SetColorTexture(GetAccentColor(1, 0.82, 0, 1))
	table.insert(frame.BFL_AccentTextures, ghIcon)

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
	kofiIcon:SetColorTexture(GetAccentColor(1, 0.82, 0, 1))
	table.insert(frame.BFL_AccentTextures, kofiIcon)

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
				fs:SetTextColor(GetAccentColor(1, 0.82, 0, 1))
				table.insert(frame.BFL_AccentFontStrings, fs)
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
	self:RefreshAccentColors()
	frame:Hide()
end
