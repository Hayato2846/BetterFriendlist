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

## [DRAFT]

### Added
- **Retail 12.1 Friendlist UI** - Added a new Retail interface based on Blizzard's 12.1 SocialUI, including vertical section tabs, modern friend cards and group headers, a Battle.net bar, compact search/filter/sort controls, and a dedicated Friend Requests view.
- **Interface Style Setting** - Retail can switch between Modern and Legacy without reloading. Modern is the Retail default when Blizzard's SocialUI is enabled; Classic and unsupported Retail states continue to use Legacy.
- **Friend Tab Settings** - Modern Retail users can reorder every side tab, hide individual tabs, and optionally show Friend Requests or Quick Join only while they contain entries. Hidden tabs are removed from the layout without leaving gaps.

### Improved
- **Social Entry Points** - Retail SocialUI toggles and tab-opening calls now route to matching BetterFriendlist sections, while the menu option for Blizzard's friendlist opens Blizzard's original SocialUI.
- **Retail 12.1 Contact Views** - Friends, Recent Allies, Friend Requests, Quick Join, Guild, and Who now use section-specific Modern search, filter, divider, list, and action-bar layouts. Recent Allies supports Blizzard's new status and interest filters with an older-client fallback.
- **Retail 12.1 Social Actions** - Recent Allies sends WoW title-friend invitations through Blizzard's confirmation dialog, offline WoW-only Title friends no longer expose an unreachable Whisper action, and Quick Join toasts select and scroll to the matching BetterFriendlist group.
- **Retail 12.1 Parity** - Quick Join uses the new queue icon, shared action layout, text-scale-aware row extents, and Blizzard's friends-restriction state. Quick Join and Friend Requests badges match Blizzard's geometry, Raid recognizes world-boss lockouts, additional roster events, and the new raid-disable game rule, RAF follows Blizzard's active Modern/Legacy owner and full rewards refresh while keeping preview rewards inert, and the status dropdown keeps Blizzard's native template height.
- **Modern Raid Layout** - Raid now combines Blizzard's 12.1 group-card chrome with BFL's compact role summary, a native top-edge layout that keeps the warm SocialUI fade without BFL's extra divider, one shared centerline for Assist All, Raid Help, counters, Ready Check, and Raid Info, native-size group labels, aligned compact footer buttons, expanded group space, transparent member rows, class-colored preview rows, and Blizzard's new raid-assignment atlases with hover tooltips.
- **Consistent Section Layout** - All scrollable Modern sections use the same 18-pixel viewport reserve and final 7-pixel scrollbar gap, placing every visible scrollbar two pixels left of the previous visual adjustment without changing row width; Quick Join and Friend Requests also share one full-height scrollbar rail.
- **Modern Directory Views** - Guild and Who use the same search-field chrome as Friends. Who also uses Modern action buttons, the original Modern 28-pixel table-header surfaces, a full-height scrollbar on an unframed gutter, and a centered full-width Search Builder with complete Dark/Custom controls, theme-colored surfaces, aligned search fields, and localized placeholders.
- **Modern Friend Requests** - Friend Requests now match Blizzard's received-request header, Title/BattleTag/Real ID card surfaces, tertiary accept/decline actions, and full-size privacy warning.
- **Modern Social Detail Views** - Recent Allies places native-size pin and pending-request indicators inline with character data, Friend Requests uses Blizzard's scaled accept and decline-dropdown contract with centered actions, and Recruit a Friend now matches the 12.1 SocialView header, action buttons, 70-pixel cards, activity-chest spacing, and rewards overview.
- **Modern Window Spacing** - Streamer Mode occupies the Battle.net bar's right action edge, Raid Help sits beside Assist All, and Help, Settings, and Ignore windows clear the Modern side-tab rail.
- **Modern Simple Mode** - The Contacts view now hides Quick Filter and Sort in every theme, offers Legacy's optional search setting as a full-width Modern search row, expands the list into freed space when search is disabled, moves filter/sort access into the Contacts menu, and gives Dark/Custom a compact square portrait contained by the main frame.
- **Filter Menus** - Friend filters now use shared Filters and Tags submenus in Modern, Legacy, and Simple Mode. Active filters and selected tag facets appear in a compact, stable first menu level and update immediately after every selection without moving an open submenu; Modern keeps the clean text label, while Legacy uses a centered generic BFL filter icon and vertically centered header selections.
- **Modern Theme Support** - Dark and Custom now use a dedicated, reversible Modern renderer with a transparent Battle.net header, aligned menu and search/filter controls, white BattleTag and copy actions, accent-colored BFL icons, flush side tabs, borderless invite actions in Friends and Recent Allies, compact Raid utilities, border-free Quick Join and Who result content, darkened Modern Who headers, native dark group headers without gold click chrome, and visibly darkened native scrollbar chrome. Blizzard and Legacy keep their existing presentation.
- **Friend Tag Chips** - Friend-row tags now use true circular capsule ends, a crisp black outline, preserved tag colors, and up to three rows of three chips without MaskTextures; they no longer intercept mouse input or show separate tag tooltips.
- **Adaptive Friend Rows** - Friend cards now stack their visible name, info, multi-account, and tag lines from a three-pixel top inset and calculate their height from the content that is actually shown. Long names wrap across as many lines as needed, including names without spaces, instead of being truncated. Rows grow beyond the old fixed Modern sizes and retired height cap when configured fonts or extra lines need more room.
- **WHO Rows** - Alternating row backgrounds now have an adjustable strength control in both settings interfaces.
- **Settings Preview** - Changes from both settings interfaces now refresh every active Preview surface immediately. The fixtures cover mobile-only and multi-game friends, max-level rows, nicknames, dynamic groups, Contact Memory, Guild nicknames, and Broker columns without writing preview data to SavedVariables.

### Fixed
- **Modern Theme Runtime** - Fixed a nil palette access while styling group headers and kept their original darkened texture visible.
- **Legacy UI Restoration** - Switching from Retail's Modern interface to Legacy now reconstructs the v2.7.0 tab rows, whole-pixel window geometry, header dropdowns, Guild scrollbar, Quick Join spacing, Who Search Builder, RAF ownership, and original Who/Raid button templates without changing the Modern presentation. Guild also closes the gap left by unavailable RAF, and Ready Check no longer hides Assist All on Retail Legacy.
- **Recent Allies Invite Button** - The Modern invite action now resets the legacy TravelPass texture crop before applying Blizzard's square SocialCard atlases, preventing the button background from rendering as narrow vertical strips while preserving the original Legacy artwork.
- **Preview Mode** - `/bfl preview` again toggles the complete Retail 12.1 fixture, including Recent Allies and a fully local Recruit a Friend roster that remains available when RAF is disabled on the account or PTR. Its full boot is distributed safely across frames without debug chat spam, then commits the complete mock friend model after all gated fixture work, preventing client stalls and empty custom groups. Preview friends expose deterministic game-specific icons and WoW status, consume current name/info, faction, favorite, font, and layout settings instead of stale cached values, and keep multi-account details above rather than underneath tag chips. Friend Requests cover Title/BattleTag/Real ID and reproduce Blizzard's pending-request counter and tab glow outside the selected Requests view; Quick Join reproduces its counter without an artificial tab glow. RAF exposes Blizzard's complete rewards window through a seven-step local reward track while keeping claim and recruitment services disabled. Raid rows use their class backgrounds, and selected mock friends are released when switching or disabling preview profiles.
- **Preview Who Isolation** - Preview Mode no longer creates, stores, refreshes, or advertises mock Who results; the Who directory remains entirely on Blizzard's live search data.
- **Modern Group Headers** - Retail 12.1 group headers now use static, bounded name/count regions. Labels in other writing systems use Blizzard's preinitialized multilingual system font instead of resolving BFL's runtime-created FontFamily during ScrollBox setup; ASCII and extended Latin labels retain all configurable BFL font settings. Preview diagnostics can compare ASCII, extended Latin, and multilingual regression sets.
- **Raid Member Interaction** - Hovering raid members on Retail 12.1 no longer attempts to anchor a protected proxy to an insecure member slot. Right-click menus continue to use the member button's secure action path.
- **Drag and Hover Handling** - Reordering groups, filters, sorters, and broker columns no longer calls the removed global mouse-over helper. Friend-group drops and themed hover states use the cross-flavor Region API as well.
- **Modern Frame Chrome** - The content background and lower divider now remain inside the resizable frame border, and friend-row tags sit two pixels lower.
- **Friends Frame** - The title now uses the correct centered bounds when Simple Mode hides the portrait, and legacy filter/sort dropdowns stay hidden while the Modern UI is active.
- **Theme Settings** - Theme sliders no longer reskin the full interface for every drag increment, and resetting a theme updates the visible controls immediately.
- **Frame Scale** - Changing the scale in Settings Center now applies it immediately.
- **Friend Tags** - Friend Tags are now a standard feature instead of a Beta feature and can be enabled independently from Private Notes. Their settings are grouped by purpose, tag management lives only in the dedicated editor, and legacy Blizzard-tag handoff is shown only when data is waiting to migrate. Their BFL-owned context menu no longer leaks into Blizzard's menu, the single note action is flat, and the rebuilt editor adds automatic saving, drag-and-drop ordering, a searchable BFL/WoW icon explorer, a true friend-row chip preview, and bare icon-only rendering without pill chrome. Native Blizzard tags remain available in BFL's context menu, friend search, and tag filters when BFL's custom tag feature is disabled.
- **Group Order** - Arrow color controls are hidden when collapse arrows are disabled.
- **Tooltips** - BetterFriendlist friend tooltips now use `TOOLTIP` strata with a deliberate frame-level lead, keeping them above Modern cards, tabs, and other SocialUI child frames.
- **WHO Double-Click** - WHO actions now expose only the supported Whisper and Invite options; stale unsupported Inspect selections fall back safely to Whisper.

---

## [2.7.0]        - 2026-07-29

### Fixed
- **Legacy Font Dropdowns** - Font lists in the legacy settings now stay on-screen and scroll through all available fonts. Dark and Custom themes no longer show an overlapping second dropdown.

---

## [2.6.9]        - 2026-07-22

### Fixed
- **Who Searches** - Broad Who searches no longer leave an invisible Blizzard window that blocks Escape and disrupts other window positions.

---

## [2.6.8]        - 2026-07-14

### Improved
- **Translations** - Many translations across all supported languages have been updated, corrected, and expanded.
- **Classic Anniversary** - BetterFriendlist now loads normally with the Classic Anniversary 2.5.6 client update.

### Fixed
- **Friend Search** - Search now checks a friend's displayed WoW contact name plus every visible character and realm linked to their Battle.net account.
- **Multi-Account Filters** - The WoW, WoW Online, Retail, and In Game filters, along with matching custom rules, now check every visible game account instead of only the focused one.
- **Mobile-Only Status** - Treat Mobile as Offline now only marks friends offline when the Battle.net mobile app is their only active session. They stay online while playing another Blizzard game.
- **Friend List Refreshes** - Rapid friend-status changes no longer cause duplicate refreshes, and BetterFriendlist keeps the last complete list visible while Battle.net data is still loading.

---

## [2.6.7]        - 2026-07-12

### Added
- **WoW Contact Custom Names (Retail 12.1)** - Once Blizzard enables the new WoW-only Battle.net contacts and their custom names, BetterFriendlist displays those names in the friends list and Broker tooltip. They can also be edited from the right-click menu.
- **Appear Offline (Retail 12.1)** - Once Blizzard enables the new Battle.net presence option, BetterFriendlist's existing status menu includes Appear Offline alongside Online, Away, and Busy.

### Improved
- **Retail 12.1 Compatibility** - BetterFriendlist now adapts when Blizzard enables the new friends system or disables older character-friend features. Friend counts, notes, adding or removing friends, and related friend actions continue to work through the transition.
- **Retail 12.1 Social Updates** - Once Blizzard enables the new social features, changes to your Battle.net status, WoW contact names, and available friend functions are reflected in BetterFriendlist immediately.
- **Localization** - Completed and corrected all supported locale files, including recently added settings and social features, while removing stale keys, duplicate assignments, English fallback text, and encoding damage.

### Fixed
- **Static Friend Groups** - Assigning a friend to a custom group now removes them from "No Group" as expected. Dropping a friend onto "No Group" removes their custom-group assignments cleanly.

---

## [2.6.6]        - 2026-06-30

### Fixed
- **Raid Tab Menus** - Right-clicking raid members on Retail should open the normal Blizzard menu again, including options like Set Focus.
- **Auto Raid Assist** - Your chosen assistants are picked up more reliably after raid changes, zoning, difficulty changes, or when WoW is slow to finish loading the roster.
- **Auto Raid Assist** - If you take assistant away from someone yourself, they stay that way until they leave the raid.
- **Classic Login** - Classic Era and Season of Discovery should no longer show a protected action warning when you log in with BetterFriendlist enabled.

---

## [2.6.5]        - 2026-06-28

### Added
- **NSRT Compatibility** - You can now dock Northern Sky Raid Tools' Missing Raid Buffs panel into the BetterFriendlist Raid tab. This currently requires an NSRT alpha version.
- **Theme Customization** - Dark and Custom themes are no longer beta and now work on Retail and Classic. Find them in the old settings under Settings > Theme, or in the Settings Center under Appearance > Theme. ElvUI users can pick the ElvUI skin from that same Theme page.

### Fixed
- **Classic Themes** - The Friends window should look cleaner in Dark and Custom themes now: search box, bottom tabs, selected tab highlight, scroll buttons, WHO headers, and Raid role icons line up better.
- **Classic Simple Mode** - The missing top-left Blizzard frame corner is back when the avatar is hidden in Blizzard theme.
- **Quick Join** - Retail group tooltips now show better member info when available, including classes, roles, and leader markers.

### Improved
- **Classic Dropdowns** - Friends header, WHO, settings, and builder dropdowns now have cleaner icon placement and more reliable click areas in Dark/Custom themes and ElvUI.
- **Classic Simple Mode** - Turning Simple Mode on or off updates the frame right away, no reload needed.
- **Classic UI** - More Classic menus use the newer menu style where the client supports it, and shared icon art is safer on Classic.

---

## [2.6.4]        - 2026-06-25

### Fixed
- **Classic Friends List** - Fixed class-colored names for WoW friends whose localized class data could miss Classic class ID gaps, including druids on Anniversary realms.
- **Classic UI** - Adjusted the WHO zone dropdown spacing and stabilized copy-name dialogs so their input fields fit on first open.

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
	local editBoxWidth = 350
	StaticPopupDialogs["BETTERFRIENDLIST_COPY_URL"] = {
		text = title or "Copy URL",
		button1 = "Close",
		hasEditBox = true,
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
				if BFL.SetTextureOrAtlas then
					BFL.SetTextureOrAtlas(button.NewLabel, "communities-icon-invitemail", "Interface\\AddOns\\BetterFriendlist\\Icons\\mail")
				else
					button.NewLabel:SetTexture("Interface\\AddOns\\BetterFriendlist\\Icons\\mail")
				end
				button.NewLabel:SetSize(64, 48)
			else
				if BFL.SetTextureOrAtlas then
					BFL.SetTextureOrAtlas(button.NewLabel, "CharacterCreate-NewLabel", "Interface\\AddOns\\BetterFriendlist\\Icons\\star")
				else
					button.NewLabel:SetTexture("Interface\\AddOns\\BetterFriendlist\\Icons\\star")
				end
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
