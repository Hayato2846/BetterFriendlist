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
- **Guild Tab** - New dedicated Guild tab with a full guild roster view directly inside BetterFriendlist. Features searchable member list, column sorting (name, rank, level, zone), online/offline/all filter buttons, guild name, member count, and Message of the Day display. Includes buttons to open Blizzard's guild management and to refresh the roster. Disabled by default; enable in Settings > General > Behavior. Works on all WoW versions.
- **Advanced: Taint-Free Whisper** - New optional setting under Advanced that uses an inline message bar at the bottom of the friend list for whispering friends instead of opening the default Blizzard chat. This prevents BetterFriendlist from interfering with the chat system, which can cause Lua errors when other addons or Blizzard code processes messages. After sending, the bar closes automatically. Press Shift+Enter to reopen it with the same whisper target for follow-up messages. Disabled by default.
- **Broker: Filtered Friend Count** - The broker text and tooltip now reflect the active Quick Filter (e.g., "WoW only" or "Online only") instead of always showing the total online count.
- **Broker: Name Colors** - Friend names in the broker tooltip now use the font color configured in Settings > Fonts, matching the main friend list appearance.
- **Broker: Show Tooltip Hints** - New toggle in Settings > Broker to hide the clickable action hints at the bottom of the broker tooltip for a cleaner look.
- **Broker: Nickname Column** - New optional "Nickname" column for the broker tooltip. Enable it in Settings > Broker > Tooltip Columns. Shows the assigned nickname for each friend, colored with the configured name font color.
- **Broker: ElvUI Tooltip Skin** - When the ElvUI skin is enabled, the broker tooltip now uses the ElvUI backdrop style for a consistent look.
- **Broker: Guild Plugin** - New Data Broker plugin that displays guild members in a rich tooltip, similar to the existing friends broker. Shows name, level, class, rank, zone, notes, officer notes, and last online time with 8 toggleable columns. Supports grouping by rank or class with collapsible headers, online/all filter cycling, rank management (promote, demote, remove), and full click interactions (whisper, invite, context menu). Works on all WoW versions. Disabled by default, enable in Settings > Broker > Guild Plugin.

### Fixed
- **Tab Navigation** - Fixed the window getting stuck on the Who or Quick Join tab after using /who or clicking a group join link. Closing and reopening the window now correctly returns to the Friends tab.

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

## [2.5.1]       - 2026-03-23

### Improved
- **Group Note Sync** - The sync is now fully bidirectional. Existing group tags in friend notes (e.g. from FriendGroups) are automatically imported when enabling the feature. Manually adding a tag like `#MyGroup` to any friend note will create the group and assign the friend automatically.

## [2.5.0]       - 2026-03-22

### Changed
- **Library Isolation** - BetterFriendlist no longer loads shared global libraries (LibStub, CallbackHandler, LibQTip, LibDataBroker, LibSharedMedia). This prevents the addon from being falsely blamed for taint errors caused by other addons that share the same libraries. Font and media features now gracefully fall back to defaults if no media library is available.
- **Arcana** - Updated all references from ChocolateBar to Arcana to reflect the addon's new name.

### Improved
- **Font Dropdowns** - Font selection dropdowns in Settings now use lazy loading, so fonts are only loaded as they scroll into view instead of all at once. This eliminates a brief freeze when opening a font dropdown for the first time.

### Fixed
- **Taint Errors** - Eliminated thousands of "Action was blocked" taint errors that could occur when opening the friend list during or shortly after combat. Tooltips and the friend list window now use addon-owned frames that cannot interfere with Blizzard's protected UI.
- **Frame Position** - Fixed the friend list window sometimes resetting to the center of the screen instead of restoring the saved position. This could happen when opening it via the Data Broker, after a game crash, or when other UI addons moved the window.
- **Midnight Compatibility** - Fixed a crash in the chat system that could occur on WoW 12.0 (Midnight) when a system message arrived while the Global Sync was adding friends. Also hardened all internal display code against the new privacy-protected account names.
- **Standalone Installation** - Fixed a crash on startup when BetterFriendlist was the only addon installed and no shared library provider was available.
- **Classic: Send Message** - Fixed clicking the "Send Message" button on Classic crashing with an error instead of opening a whisper to the selected friend.
- **Non-Roman Alphabets** - Fixed Korean, Chinese, and Russian text not displaying correctly when no font library addon (e.g. SharedMedia) was installed. All text now uses the correct locale-appropriate font as a fallback.
- **Whisper in Instances and Combat** - Fixed clicking to whisper not working while inside instances, Delves, Mythic+, PvP matches, or during combat. This affected both the Data Broker tooltip and the "Send Message" button in the friend list.
- **Data Broker: Built-in Groups** - Fixed the "In-Game", "Favorites", and "Recently Added" groups not appearing in the Data Broker tooltip. Only custom groups were shown previously.
- **Data Broker: Class-Colored Character Names** - Fixed the %character% token in name format not being class-colored in the Data Broker tooltip. Character names now respect the class color setting, matching the main friend list behavior.
- **Data Broker: Character Column** - Fixed the Character column in the Data Broker tooltip incorrectly showing the account name instead of only the character name.
- **Data Broker: Faction Icons** - Faction icons now also appear in the Name column of the Data Broker tooltip, not just the Character column.

### Removed
- **Keybind Override** - Removed a redundant keybinding entry from the Key Bindings UI. The O-key (Social) redirect was already handled internally and the extra entry served no purpose.

---

## [2.4.4]       - 2026-03-09

### Fixed
- **Global Sync** - Fixed several issues that could cause "Player not found." spam and repeated failed sync attempts. The sync now works correctly across connected realms and respects the friend list limit.
- **Raid Shortcuts** - Fixed raid shortcuts (Assist, Raid Lead, Main Tank, Main Assist, and the right-click context menu) not working on Classic. Also fixed these shortcuts silently failing on Retail when "Cast on Key Down" was enabled in the game settings.

---

## [2.4.3]       - 2026-03-02

### Changed
- **Data Broker Right-Click** - Also opens the friend list if it was closed.
- **Friend Tooltip** - Now uses Blizzard's native tooltip instead of a custom replica.
- **Tooltip: Max Game Accounts** - Setting removed. Always shows up to 5 accounts (Blizzard default).

### Fixed
- **Data Broker Tooltip** - No longer stays open for ~5 seconds after moving the mouse away (Arcana, Bazooka, etc.).
- **Data Broker Right-Click** - Fixed an error when right-clicking the icon to open settings.
- **Beta Features Toggle** - Fixed an error when disabling Beta Features while on a Beta settings tab.

---

## [2.4.2]       - 2026-02-26

### Added
- **Raid Tools** - New "Tools" button on the Raid tab that opens a dedicated Raid Tools panel. Features include:
  - **Sort by Role** - Arranges raid members by role with two sort modes: Tanks > Melee > Ranged > Healers, or Tanks > Healers > Melee > Ranged. Uses spec inspection to accurately distinguish melee and ranged DPS.
  - **Split Raid** - Splits the raid into two balanced halves or into odd/even groups, distributing roles, classes, Battle Rez, and Bloodlust evenly across both sides.
  - **Balance DPS** - Optional checkbox that uses damage meter data (Details! or Blizzard's built-in Damage Meter) to evenly distribute DPS output across both sides when splitting.
  - **Promote Tanks** - Gives raid assistant to all players with the Tank role.
  - **Preserve Groups** - Excludes any combination of groups 1-8 from being modified during sort or split operations.
  - **Auto-resume after combat** - Automatically continues an interrupted sort or split after leaving combat.
  - Shows live progress during sort and split operations (e.g., "Sorting... (5/12)").
- **Quick Filter: In A Game** - New Quick Filter option that shows only friends who are currently playing any game (WoW, Overwatch, Diablo, etc.), hiding offline, app-only, and mobile-only friends.

### Fixed
- **Assist All Checkbox** - Fixed the "Assist All" checkbox and its label not disabling when the player isn't raid leader. Also fixed the state not updating when converting between Raid and Party or when raid lead is given or taken. The checkbox tooltip now matches Blizzard's default behavior.
- **Raid Tab Non-Roman Character Names** - Fixed raid member names in non-roman alphabets (Korean, Chinese, Russian) not rendering correctly even when the selected font supports them. The font fallback system was not being applied in the Raid tab, unlike the Friends list where it already worked.

### Changed
- **Raid Tab Controls Always Visible** - The "Assist All" checkbox, role counts, and member count on the Raid tab are now always visible, even when not in a raid group.

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
