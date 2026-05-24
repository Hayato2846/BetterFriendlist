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
- **QuickFilter & Sorter Builder** - Added a beta-gated settings tab for controlling visible QuickFilters and Sorters, creating custom filter rules and sorter chains, and choosing BFL or Blizzard icons.
- **Theme Settings** - Added a Theme settings section with Blizzard, Dark, and ElvUI theme choices.
- **Dark Theme** - Added a BFL-owned dark skinning engine covering BetterFriendlist windows, rows, dialogs, and broker tooltips.
- **Font Rendering** - Added per-font rendering flag settings and enabled Slug rendering across BetterFriendlist UI text on compatible clients.
- **WoW Online Filter** - Added a quick filter for showing only online friends who are currently in WoW.

### Changed
- **QuickFilter & Sorter Builder** - Creation and editing now happen in a docked editor panel, rule fields use dropdowns, and Preview temporarily applies the selected filter or sorter to the friends list.
- **Filter/Sort Registry** - QuickFilter menus, sort dropdowns, and Broker cycling now read from a shared registry; hidden active selections fall back to Filter `all`, Primary Sort `game`, and Secondary Sort `status`.
- **ElvUI Skin Setting** - Moved the ElvUI skin option from General to Theme and migrated existing profiles automatically.
- **Theme Settings** - Theme choices are now beta-gated and automatically switch back to Blizzard when Beta Features are disabled.
- **Dark Theme Visuals** - Refined the Dark theme with translucent black Aurora-style surfaces, clearer control hairlines, Material-like navigation states, and cleaner list dividers.

### Fixed
- **QuickFilter & Sorter Builder** - Updated the docked editor to use the same modern frame styling as the Settings and Raid Help windows.
- **QuickFilter & Sorter Builder** - Cleaned up the docked editor layout so preview, metadata, filter rules, and sorter steps no longer overlap.
- **QuickFilter & Sorter Builder** - Added the missing delete action for nested filter groups.
- **Retail Unit Menus** - Avoided adding BetterFriendlist group options to protected Blizzard unit menus.
- **Total RP 3 Compatibility** - Restored the Total RP 3 profile action in BetterFriendlist friend context menus without using Blizzard menu callbacks.
- **Raid Drag Tooltips** - Fixed a Lua error that could occur after moving players between raid groups with drag and drop.
- **Dark Theme Coverage** - Improved Dark theme coverage for frame borders, tabs, scroll bars, dropdown menus, sliders, close buttons, and standard Blizzard button templates that could still show Blizzard styling.
- **Dark Theme Controls** - Replaced text-based close and dropdown indicators with BFL icons and removed extra borders from header icon buttons.
- **Dark Theme Tabs** - Centered tab labels, matched bottom-tab opacity to the main frame, and added accent borders for selected top and bottom tabs.
- **Dark Theme Main List** - Widened and aligned the main scrollbar, lined up the footer buttons with the list edges, removed the duplicate outer list frame, and made disabled buttons visually distinct without dimming selected tabs.
- **Dark Theme Performance** - Reduced Friendlist rerender work and stopped row skinning from interfering with configured group header colors.
- **Dark Theme Frame Chrome** - Prevented Blizzard ButtonFrame portrait/corner artwork from reappearing over the Dark theme after portrait visibility updates.
- **Dark Theme Polish** - Aligned header and title icon buttons, changed borderless button hover to icon-only glow, and tightened the main scrollbar alignment and stepper state layout.
- **Dark Theme Scrolling** - Fixed scrollbar stepper icon alignment and initial visibility, removed group header highlighting, improved scrollbar thumb highlighting while dragging, and unified Dark theme scrollbar styling across BFL windows.
- **Theme Isolation** - Prevented Dark theme skin state from leaking into the Blizzard theme after switching themes, including top/bottom tab layout, selected tab text, icon coloring, checkboxes, edit boxes, and scrollbar thumbs.
- **Dark Theme Texture Buttons** - Preserved native invite and RAF reward textures while cleaning up Dark theme borders, RAF list separators, and tooltip behavior.
- **Dark Theme Overlay Buttons** - Prevented invisible Friends row game-account overlays from receiving visible button chrome.
- **Dark Theme Tab Lists** - Applied the Friends tab list chrome rules to Recent Allies and Recruit A Friend so list insets and scrollbars align consistently.
- **Dark Theme Who Tab** - Fitted WHO column headers inside the list inset, aligned them as table columns, extended the scrollbar through the header gutter, and kept search utility buttons borderless.
- **Dark Theme Search Builder and Raid Tab** - Removed redundant inner frames, aligned Search Builder dropdowns with inputs, cleaned up raid controls, and stopped the builder from capturing unrelated keys.
- **Dark Theme Raid Tab** - Aligned and cleaned up the Assist All checkbox styling.
- **Dark Theme Quick Join Tab** - Removed the extra outer inset frame, added breathing room below the title buttons, and aligned the scrollbar and request button with the Contacts tab layout.
- **Dark Theme Raid Help** - Cleaned up Raid Roster Help inset chrome and aligned its scrollbar with other tab lists.
- **Dark Theme Settings** - Fixed settings scrollbar stepper icons after tab switches and aligned Font Settings dropdowns, sliders, and color controls.
- **Dark Theme Advanced Dialogs** - Skinned the FriendGroups migration dialog, Note Cleanup Wizard, and Note Backup Viewer consistently with the Dark theme.
- **Theme Settings** - Fixed an error when disabling Beta Features from the settings window.
- **ElvUI Skin** - Prevented startup errors when the ElvUI theme was still selected but ElvUI was disabled.
- **Recruit A Friend Rewards** - Prevented viewing rewards from breaking reward tabs or causing a protected Copy Link error in the recruitment dialog.

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

## [2.5.4]        - 2026-04-03

### Fixed
- **Classic: Sort Dropdown** - Fixed an error when selecting a sort option (e.g., "Game") in Classic clients.

### Improved
- **Quick Join: Known Players** - Quick Join entries now also show guild members and community members next to the group leader, not just friends. Community members additionally display the community name they belong to.

## [2.5.3]        - 2026-04-02

### Added
- **Name Format: BattleTag Only** - New preset that shows only the BattleTag without the character name.

### Improved
- **Performance** - Faster sorting, group toggling, and list updates across Friends List, Quick Join, Raid Frame, and WHO tab. Reduced memory usage overall.
- **Tooltip: External Addon Support** - Friend tooltips now work with RaiderIO and ArchonTooltip (Warcraft Logs).

### Fixed
- **Friends List: Zone Display** - Fixed zone names with hyphens (e.g., French "Silvermoon City") being split incorrectly.
- **Retail: Secret Values** - Fixed crashes when encountering protected values in tooltips, display names, Quick Join, and debug commands.
- **Retail: Chat & Whisper Taint** - Fixed mass taint errors when receiving chat messages or whispering in popout mode.
- **Raid Frame: Combat Restriction** - Raid actions (Convert, Assist, Promote) now block properly during combat instead of showing a cryptic error. Buttons are visually disabled in combat.

## [2.5.2]       - 2026-03-24

### Fixed
- **Housing: Combat Restriction** - The "View Houses" context menu entry now shows a clear error message during combat instead of the cryptic "Interface action failed because of an AddOn" error. Visit House buttons in the house list show a gray overlay with a tooltip when combat starts while the list is already open.

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
	BFL_Tooltip:SetOwner(button, "ANCHOR_RIGHT")
	BFL_Tooltip:SetText("BetterFriendlist " .. (BFL.VERSION or ""), 1, 0.82, 0)

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
