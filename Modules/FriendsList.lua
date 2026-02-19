-- Friends List Core Logic Module

local ADDON_NAME, BFL = ...
local FriendsList = BFL:RegisterModule("FriendsList", {})
local L = BFL.L -- Localization table
local LSM = LibStub("LibSharedMedia-3.0")

-- ========================================
-- Module Dependencies
-- ========================================
local function GetDB()
	return BFL:GetModule("DB")
end
local function GetGroups()
	return BFL:GetModule("Groups")
end
local function GetColorManager()
	return BFL.ColorManager
end
local function GetFontManager()
	return BFL.FontManager
end

local function GetFriendsListModule()
	return BFL:GetModule("FriendsList")
end

-- ========================================
-- Constants
-- ========================================
local BUTTON_TYPE_FRIEND = 1
local BUTTON_TYPE_GROUP_HEADER = 2
local BUTTON_TYPE_INVITE_HEADER = 3
local BUTTON_TYPE_INVITE = 4
local BUTTON_TYPE_DIVIDER = 5
local BUTTON_TYPE_SEARCH = 6
local MAX_MULTI_ACCOUNT_ROW_ENTRIES = 2 -- Info Line Formatting (Phase 22)

-- Forward declarations for helpers referenced before their definitions
local ShouldShowMultiAccountRow

-- Reference to Groups (Upvalue shared by all functions)
local friendGroups = {}

-- Race condition protection
local isUpdatingFriendsList = false
local hasPendingUpdate = false

-- ========================================
-- PERFY OPTIMIZATION (Phase 2A): Named Event Callbacks
-- Pre-define event handlers to eliminate closure allocation overhead
-- These are called 1000s of times per session, closures are expensive!
-- ========================================

local function EventCallback_FriendListUpdate(...)
	BFL.FriendsList:OnFriendListUpdate(...)
end

local function EventCallback_BNetFriendListSizeChanged(...)
	BFL.FriendsList:OnFriendListUpdate(...)
end

local function EventCallback_BNetAccountOnline(...)
	BFL.FriendsList:OnFriendListUpdate(...)
end

local function EventCallback_BNetAccountOffline(...)
	BFL.FriendsList:OnFriendListUpdate(...)
end

local function EventCallback_BNetFriendInfoChanged(...)
	BFL.FriendsList:OnFriendListUpdate(...)
end

local function EventCallback_BNetConnected(...)
	BFL.FriendsList:OnFriendListUpdate(...)
end

local function EventCallback_BNetDisconnected(...)
	BFL.FriendsList:OnFriendListUpdate(...)
end

-- GROUP_ROSTER_UPDATE affects invite button availability - refresh friendlist
local function EventCallback_GroupRosterUpdate(...)
	BFL.FriendsList:OnFriendListUpdate(...)
end

local function EventCallback_BNetInviteListInitialized()
	BFL.FriendsList:OnFriendListUpdate(true) -- Force immediate update
end

local function EventCallback_BNetInviteAdded()
	-- Play sound immediately (Phase 1)
	PlaySound(SOUNDKIT.UI_BNET_TOAST)

	local collapsed = GetCVarBool("friendInvitesCollapsed")
	if collapsed then
		BFL.FriendsList:FlashInviteHeader()
	end
	BFL.FriendsList:OnFriendListUpdate(true) -- Force immediate update (Phase 2)
end

local function EventCallback_BNetInviteRemoved()
	BFL.FriendsList:OnFriendListUpdate(true) -- Force immediate update (Phase 2)
end

local function HookScript_OnFrameShow()
	local self = BFL.FriendsList
	-- CRITICAL FIX: Update layout immediately when shown
	-- This ensures SearchBox appears instantly in Simple Mode,
	-- instead of waiting for the threaded UpdateFriendsList -> RenderDisplay cycle
	self:UpdateScrollBoxExtent()

	if needsRenderOnShow then
		-- BFL:DebugPrint("|cff00ffffFriendsList:|r Frame shown, dirty flag set - triggering refresh")
		self:UpdateFriendsList()
	end
end

local function HookScript_OnScrollFrameShow()
	local self = BFL.FriendsList
	-- Force layout here too, as switching tabs shows ScrollFrame
	self:UpdateScrollBoxExtent()
end

-- Bound method for UpdateSearchBoxWidth timer
local function Timer_UpdateSearchBoxWidth()
	if BFL.FriendsList and BFL.FriendsList.UpdateSearchBoxWidth then
		BFL.FriendsList:UpdateSearchBoxWidth()
	end
	-- Also ensure extent is correct if frame wasn't ready
	if BFL.FriendsList and BFL.FriendsList.UpdateScrollBoxExtent then
		BFL.FriendsList:UpdateScrollBoxExtent()
	end
end

-- Bound method for UpdateFriendsList throttle timer
local function Timer_UpdateFriendsList()
	if BFL.FriendsList then
		BFL.FriendsList.updateTimer = nil
		BFL.FriendsList:UpdateFriendsList()
	end
end

-- PERFY OPTIMIZATION (Phase 2A): Pre-defined SetScript Handlers
local function FriendButton_OnSizeChanged(self, width, height)
	local padding = self.textRightPadding or 80
	local nameWidth = width - 44 - padding
	if nameWidth < 10 then
		nameWidth = 10
	end
	if self.Name then
		self.Name:SetWidth(nameWidth)
	end
	if self.Info then
		self.Info:SetWidth(nameWidth)
	end
	if self.multiAccountRow then
		self.multiAccountRow:SetWidth(nameWidth)
	end
end

-- Performance Caches (Phase 9.7)
local uidCache = {} -- Interned strings for UIDs (bnet_Tag123)
local displayFormatBlueprint = nil -- Parsed structure for fast string building

-- Dirty flag: Set when data changes while frame is hidden
-- When true, next time frame is shown, we need to re-render
local needsRenderOnShow = true -- Default to true to force initial render

-- Selected friend for "Send Message" button (matching Blizzard's FriendsFrame)
FriendsList.selectedFriend = nil
FriendsList.selectedFriendUID = nil
FriendsList.selectedButton = nil -- Reference to the selected button for highlight management

-- Invite restriction constants (matching Blizzard's)
local INVITE_RESTRICTION_NONE = 0
local INVITE_RESTRICTION_LEADER = 1
local INVITE_RESTRICTION_FACTION = 2
local INVITE_RESTRICTION_REALM = 3
local INVITE_RESTRICTION_INFO = 4
local INVITE_RESTRICTION_CLIENT = 5
local INVITE_RESTRICTION_WOW_PROJECT_ID = 6

-- Forward Declarations for Drag Handlers (Phase 9.2 / Phase 5)
local Button_OnDragStart, Button_OnDragStop, Button_OnDragUpdate
local INVITE_RESTRICTION_WOW_PROJECT_MAINLINE = 7
local INVITE_RESTRICTION_WOW_PROJECT_CLASSIC = 8
local INVITE_RESTRICTION_MOBILE = 9
local INVITE_RESTRICTION_REGION = 10
local INVITE_RESTRICTION_QUEST_SESSION = 11
local INVITE_RESTRICTION_NO_GAME_ACCOUNTS = 12

-- ========================================
-- Helper Functions
-- ========================================

-- Fix #35/#40: Calculate dynamic friend row height based on font size
-- Base height is designed for 12px fonts, scales proportionally for larger sizes
local BASE_FONT_SIZE = 12
local BASE_ROW_HEIGHT = 34
local BASE_COMPACT_ROW_HEIGHT = 24
local MIN_ROW_HEIGHT = 24 -- Minimum height even for tiny fonts
local MAX_ROW_HEIGHT = 72 -- Maximum to prevent overly large rows (allows extra detail rows)

-- Fix #35: Calculate row height based on combined font heights
local function CalculateFriendRowHeight(isCompactMode, nameSize, infoSize, infoDisabled, hasMultiAccountRow)
	local nameFontSize = nameSize or BASE_FONT_SIZE
	local infoFontSize = infoSize or BASE_FONT_SIZE

	-- Calculate line height for each font (font size + 2px breathing room)
	local nameLineHeight = nameFontSize + 2
	local infoLineHeight = infoFontSize + 2

	local calculatedHeight
	if isCompactMode then
		-- Compact Mode: name can wrap to 2 lines (maxLines=2), info hidden
		-- 2 * nameLineHeight + padding (4px top + 4px bottom)
		calculatedHeight = (nameLineHeight * 2) + 8
	elseif infoDisabled then
		-- Info Disabled: single name line only, no info line
		-- nameLineHeight + padding (4px top + 4px bottom)
		calculatedHeight = nameLineHeight + 8
	else
		-- Normal: name + info stacked (each 1 line max), add padding (4px top + 2px gap + 4px bottom)
		calculatedHeight = nameLineHeight + infoLineHeight + 10
		if hasMultiAccountRow then
			-- Extra multi-account row sits below the info line; reuse info line height with a small gap
			calculatedHeight = calculatedHeight + infoLineHeight + 2
		end
	end

	-- Clamp to reasonable bounds
	return math.max(MIN_ROW_HEIGHT, math.min(MAX_ROW_HEIGHT, math.floor(calculatedHeight)))
end

local function CalculateCompactRowHeight(self, nameSize, nameText, nameWidth)
	local nameFontSize = nameSize or BASE_FONT_SIZE
	local nameLineHeight = nameFontSize + 2
	local fallbackHeight = (nameLineHeight * 2) + 8

	if not nameText or nameText == "" or not nameWidth or nameWidth <= 0 then
		return math.max(MIN_ROW_HEIGHT, math.min(MAX_ROW_HEIGHT, math.floor(fallbackHeight)))
	end

	if self and not self.nameMeasure then
		local parent = BetterFriendsFrame or UIParent
		if parent then
			self.nameMeasure = parent:CreateFontString(nil, "ARTWORK")
			self.nameMeasure:Hide()
			self.nameMeasure:SetJustifyH("LEFT")
			self.nameMeasure:SetWordWrap(true)
		end
	end

	if not (self and self.nameMeasure) then
		return math.max(MIN_ROW_HEIGHT, math.min(MAX_ROW_HEIGHT, math.floor(fallbackHeight)))
	end

	local measure = self.nameMeasure
	if self.fontCache and self.fontCache.namePath then
		local outline = self.fontCache.nameOutline
		if outline == "NONE" then
			outline = ""
		end
		measure:SetFont(self.fontCache.namePath, nameFontSize, outline)
	else
		local _, _, flags = measure:GetFont()
		measure:SetFont("Fonts\\FRIZQT__.TTF", nameFontSize, flags)
	end

	measure:SetWidth(nameWidth)
	if measure.SetMaxLines then
		measure:SetMaxLines(2)
	end
	measure:SetText(nameText)

	local measuredHeight = measure:GetStringHeight() or 0
	if measuredHeight <= 0 then
		return math.max(MIN_ROW_HEIGHT, math.min(MAX_ROW_HEIGHT, math.floor(fallbackHeight)))
	end

	local calculatedHeight = measuredHeight + 8
	return math.max(MIN_ROW_HEIGHT, math.min(MAX_ROW_HEIGHT, math.floor(calculatedHeight)))
end

local function FormatColorCode(r, g, b, a)
	local alpha = a
	if alpha == nil then
		alpha = 1
	end
	return string.format(
		"|c%02x%02x%02x%02x",
		math.floor(alpha * 255),
		math.floor((r or 1) * 255),
		math.floor((g or 1) * 255),
		math.floor((b or 1) * 255)
	)
end

local GROUP_HEADER_TEXT_GAP = 4

local EnsureGroupHeaderFont

local function EnsureGroupHeaderCountText(button)
	if button.CountText then
		return button.CountText
	end

	local countText = button:CreateFontString(nil, "OVERLAY")
	countText:SetJustifyH("LEFT")
	local baseFont = button.GetFontString and button:GetFontString()
	local baseFontObj = baseFont and baseFont:GetFontObject()
	if baseFontObj then
		countText:SetFontObject(baseFontObj)
	elseif _G.GameFontNormal then
		countText:SetFontObject(_G.GameFontNormal)
	else
		-- Only hardcode fallback if no FontObject is available at all
		countText:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
	end
	EnsureGroupHeaderFont(countText)
	button.CountText = countText
	return countText
end

EnsureGroupHeaderFont = function(fs)
	if not fs then
		return
	end
	if fs:GetFontObject() then
		return
	end
	if fs:GetFont() then
		return
	end

	local fallback = _G.GameFontNormal
	if fallback then
		fs:SetFontObject(fallback)
		return
	end

	if fallback and fallback.GetFont then
		local fontPath, fontSize, fontFlags = fallback:GetFont()
		if fontPath then
			fs:SetFont(fontPath, fontSize or 12, fontFlags)
			return
		end
	end

	fs:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
end

local function SyncGroupHeaderFont(fs, countFs)
	if not (fs and countFs) then
		return
	end

	local fontObj = fs:GetFontObject()
	if fontObj then
		countFs:SetFontObject(fontObj)
		-- Also apply SetFont to clear any per-instance font override
		-- that may persist from EnsureGroupHeaderCountText or previous renders
		local fontPath, fontSize, fontFlags = fs:GetFont()
		if fontPath then
			countFs:SetFont(fontPath, fontSize, fontFlags or "")
		end
		return
	end

	local fontPath, fontSize, fontFlags = fs:GetFont()
	if fontPath then
		countFs:SetFont(fontPath, fontSize, fontFlags)
	end
end

local function IsFontReady(fs)
	if not fs then
		return false
	end
	return (fs.GetFontObject and fs:GetFontObject()) or (fs.GetFont and fs:GetFont())
end

-- General-purpose font guard: ensures a FontString has a font before SetText
-- Prevents "FontString:SetText(): Font not set" errors and ScrollBox taint
local function EnsureFontSet(fs)
	if not fs then
		return
	end
	-- Fast path: font is already set
	if fs.GetFont and fs:GetFont() then
		return
	end
	-- Try FontObject fallback
	if fs.GetFontObject and fs:GetFontObject() then
		local obj = fs:GetFontObject()
		if obj and obj.GetFont and obj:GetFont() then
			return
		end
	end
	-- Font is NOT set: apply hardcoded fallback
	local fallback = _G.GameFontNormal
	if fallback then
		fs:SetFontObject(fallback)
		if fs:GetFont() then
			return
		end
	end
	fs:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
end

local function SafeSetText(fs, text)
	EnsureGroupHeaderFont(fs)
	if not IsFontReady(fs) then
		fs:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
	end
	if IsFontReady(fs) then
		local ok = pcall(fs.SetText, fs, text or "")
		return ok
	end
	return false
end

local function EnsureHeaderFontFromButton(button, fs, countFs)
	if not (button and button.GetNormalFontObject and fs) then
		return false
	end
	local fontObj = button:GetNormalFontObject()
	if not fontObj then
		return false
	end
	fs:SetFontObject(fontObj)
	if countFs then
		countFs:SetFontObject(fontObj)
	end
	return true
end

local function ApplyGroupHeaderText(button, nameText, countText, nameColor, countColor, align)
	local fs = button:GetFontString()
	if not fs then
		return
	end

	local countFs = EnsureGroupHeaderCountText(button)
	fs:Show()
	countFs:Show()

	EnsureHeaderFontFromButton(button, fs, countFs)
	if not IsFontReady(fs) or not IsFontReady(countFs) then
		if not button._deferredHeaderUpdate then
			button._deferredHeaderUpdate = true
			C_Timer.After(0, function()
				button._deferredHeaderUpdate = false
				ApplyGroupHeaderText(button, nameText, countText, nameColor, countColor, align)
			end)
		end
		return
	end

	EnsureGroupHeaderFont(fs)
	EnsureGroupHeaderFont(countFs)
	SyncGroupHeaderFont(fs, countFs)

	local okName = SafeSetText(fs, nameText or "")
	local okCount = true
	if countText and countText ~= "" then
		okCount = SafeSetText(countFs, "(" .. countText .. ")")
	else
		okCount = SafeSetText(countFs, "")
	end
	if not okName or not okCount then
		if not button._deferredHeaderUpdate then
			button._deferredHeaderUpdate = true
			C_Timer.After(0, function()
				button._deferredHeaderUpdate = false
				ApplyGroupHeaderText(button, nameText, countText, nameColor, countColor, align)
			end)
		end
		return
	end

	if nameColor then
		fs:SetTextColor(nameColor.r, nameColor.g, nameColor.b, nameColor.a or 1)
	end
	if countColor then
		countFs:SetTextColor(countColor.r, countColor.g, countColor.b, countColor.a or 1)
	end

	local shadowX, shadowY = fs:GetShadowOffset()
	local shadowR, shadowG, shadowB, shadowA = fs:GetShadowColor()
	countFs:SetShadowOffset(shadowX, shadowY)
	countFs:SetShadowColor(shadowR, shadowG, shadowB, shadowA)

	fs:ClearAllPoints()
	countFs:ClearAllPoints()

	if align == "RIGHT" then
		countFs:SetPoint("RIGHT", button, "RIGHT", -22, 0)
		fs:SetPoint("RIGHT", countFs, "LEFT", -GROUP_HEADER_TEXT_GAP, 0)
		fs:SetJustifyH("RIGHT")
		countFs:SetJustifyH("RIGHT")
	elseif align == "CENTER" then
		local nameWidth = fs:GetStringWidth() or 0
		local countWidth = countFs:GetStringWidth() or 0
		local totalWidth = nameWidth + GROUP_HEADER_TEXT_GAP + countWidth
		if totalWidth <= 0 then
			fs:SetPoint("LEFT", button, "LEFT", 22, 0)
			countFs:SetPoint("LEFT", fs, "RIGHT", GROUP_HEADER_TEXT_GAP, 0)
		else
			fs:SetPoint("LEFT", button, "CENTER", -totalWidth / 2, 0)
			countFs:SetPoint("LEFT", fs, "RIGHT", GROUP_HEADER_TEXT_GAP, 0)
		end
		fs:SetJustifyH("LEFT")
		countFs:SetJustifyH("LEFT")
	else
		fs:SetPoint("LEFT", button, "LEFT", 22, 0)
		countFs:SetPoint("LEFT", fs, "RIGHT", GROUP_HEADER_TEXT_GAP, 0)
		fs:SetJustifyH("LEFT")
		countFs:SetJustifyH("LEFT")
	end
end

local function ApplyGroupHeaderSingleText(button, text, align)
	local fs = button:GetFontString()
	if not fs then
		return
	end

	EnsureHeaderFontFromButton(button, fs)
	if not IsFontReady(fs) then
		if not button._deferredHeaderUpdate then
			button._deferredHeaderUpdate = true
			C_Timer.After(0, function()
				button._deferredHeaderUpdate = false
				ApplyGroupHeaderSingleText(button, text, align)
			end)
		end
		return
	end

	EnsureGroupHeaderFont(fs)
	fs:Show()
	if not SafeSetText(fs, text or "") then
		if not button._deferredHeaderUpdate then
			button._deferredHeaderUpdate = true
			C_Timer.After(0, function()
				button._deferredHeaderUpdate = false
				ApplyGroupHeaderSingleText(button, text, align)
			end)
		end
		return
	end

	if button.CountText then
		button.CountText:Hide()
	end

	fs:ClearAllPoints()
	if align == "CENTER" then
		fs:SetPoint("CENTER", button, "CENTER", 0, 0)
		fs:SetJustifyH("CENTER")
	elseif align == "RIGHT" then
		fs:SetPoint("RIGHT", button, "RIGHT", -22, 0)
		fs:SetJustifyH("RIGHT")
	else
		fs:SetPoint("LEFT", button, "LEFT", 22, 0)
		fs:SetJustifyH("LEFT")
	end
end

-- Get height of a display list item based on its type
-- CRITICAL: These heights MUST match XML template heights and ButtonPool SetHeight() calls
-- Otherwise buttons will drift out of position!
local function GetItemHeight(item, isCompactMode, nameSize, infoSize, self, infoDisabled)
	if not item then
		return 0
	end

	-- Support both .type (Retail) and .buttonType (Classic)
	local itemType = item.type or item.buttonType

	if itemType == BUTTON_TYPE_GROUP_HEADER then
		return 22
	elseif itemType == BUTTON_TYPE_INVITE_HEADER then
		return 22 -- Invite header height (BFL_FriendInviteHeaderTemplate y="22")
	elseif itemType == BUTTON_TYPE_INVITE then
		return 34 -- Invite button height (BFL_FriendInviteButtonTemplate y="34")
	elseif itemType == BUTTON_TYPE_DIVIDER then
		return 8 -- Divider height (BetterFriendsDividerTemplate y="8") - FIXED from 16!
	elseif itemType == BUTTON_TYPE_SEARCH then
		return 30
	elseif itemType == BUTTON_TYPE_FRIEND then
		-- Fix #35/#40: Use dynamic height for friend rows
		if isCompactMode and self then
			local friend = item.friend
			local line1Text = friend and friend._cache_text_line1
			if friend and not line1Text and self.GetFormattedButtonText then
				line1Text = self:GetFormattedButtonText(friend)
			end
			local line1BaseText = friend and friend._cache_text_line1_base or line1Text or ""
			local line1SuffixText = friend and friend._cache_text_line1_suffix or ""
			local showFavIcon = friend
				and (friend.type == "bnet")
				and friend.isFavorite
				and self.settingsCache
				and self.settingsCache.enableFavoriteIcon

			local displayLine1 = line1Text or ""
			if line1SuffixText ~= "" and showFavIcon then
				local spacer = "  "
				if (self.settingsCache and self.settingsCache.favoriteIconStyle) == "blizzard" then
					spacer = "     "
				end
				displayLine1 = line1BaseText .. spacer .. line1SuffixText
			end

			local buttonWidth = self:GetButtonWidth()
			local padding = 25
			local showGameIcon = self.settingsCache and self.settingsCache.showGameIcon
			if showGameIcon == nil then
				showGameIcon = true
			end
			local hasGameIcon = false
			if showGameIcon and friend and friend.connected then
				if friend.type == "bnet" and friend.gameAccountInfo and friend.gameAccountInfo.clientProgram then
					hasGameIcon = true
				end
			end
			if hasGameIcon then
				padding = 80
			elseif friend and friend.type == "bnet" and friend.connected then
				padding = 45
			end

			if showFavIcon and (self.settingsCache and self.settingsCache.favoriteIconStyle) == "blizzard" then
				padding = padding + 8
			end

			local nameWidth = buttonWidth - 44 - padding
			if nameWidth < 10 then
				nameWidth = 10
			end

			return CalculateCompactRowHeight(self, nameSize, displayLine1, nameWidth)
		end

		local hasMultiAccountRow = self and ShouldShowMultiAccountRow(self, item.friend)
		return CalculateFriendRowHeight(isCompactMode, nameSize, infoSize, infoDisabled, hasMultiAccountRow)
	else
		return 34 -- Default fallback
	end
end

-- ========================================
-- ScrollBox/DataProvider Functions (NEW - Phase 1)
-- ========================================

-- Build DataProvider for ScrollBox system (replaces BuildDisplayList logic)
-- Returns a DataProvider object with elementData for each button
-- Build Display List (Optimization: Returns simplified table instead of DataProvider)
-- This allows for diffing before committing to ScrollBox
local function BuildDisplayList(self)
	-- PERFY OPTIMIZATION (Phase 2B): Input Version Tracking
	-- Skip expensive rebuild if inputs unchanged (600+ friends = 600+ operations!)
	local numInvitesForSignature
	if BFL.MockFriendInvites and BFL.MockFriendInvites.enabled then
		numInvitesForSignature = #BFL.MockFriendInvites.invites
	else
		numInvitesForSignature = (BNGetNumFriendInvites and BNGetNumFriendInvites()) or 0
	end

	local invitesCollapsed = GetCVarBool("friendInvitesCollapsed") and 1 or 0
	local currentSignature = table.concat({
		BFL.FriendsListVersion or 0,
		BFL.SettingsVersion or 0, -- Fix: Track settings/groups changes
		self.filterMode or "all",
		self.searchText or "",
		numInvitesForSignature,
		invitesCollapsed,
	}, "|")

	if self.lastBuildSignature == currentSignature and self.cachedDisplayList then
		-- BFL:DebugPrint("|cff00ff00BuildDisplayList:|r Cache HIT (inputs unchanged)")
		self.groupedFriends = self.cachedGroupedFriends or self.groupedFriends or {}
		return self.cachedDisplayList -- INSTANT return, no rebuild!
	end

	-- BFL:DebugPrint("|cffff8800BuildDisplayList:|r Cache MISS (rebuilding)")
	local displayList = {}

	-- Optimization: SyncGroups removed (Called by UpdateFriendsList before Render)
	-- self:SyncGroups()

	-- Get DB
	local DB = GetDB()
	if not DB then
		return displayList -- Return empty list if DB missing
	end

	-- Get friendGroups from Groups module
	local Groups = GetGroups()
	local friendGroups = Groups and Groups:GetAll() or friendGroups -- Fallback to upvalue if nil

	-- Feature: Embedded Search Box (Simple Mode)
	-- REFACTORED (Phase 21): Use Persistent SearchBox instead of ScrollBox row
	-- Logic moved to UpdateLayout / UpdateScrollBoxExtent
	-- local simpleMode = DB:Get("simpleMode", false)
	-- local showSearch = DB:Get("simpleModeShowSearch", true)

	-- if simpleMode and showSearch then
	-- 	table.insert(displayList, {
	-- 		buttonType = BUTTON_TYPE_SEARCH,
	-- 		searchText = self.searchText or ""
	-- 	})
	-- end

	-- Add friend invites at top (real or mock)
	local numInvites = numInvitesForSignature

	if numInvites and numInvites > 0 then
		table.insert(displayList, {
			buttonType = BUTTON_TYPE_INVITE_HEADER,
			count = numInvites,
		})

		if not GetCVarBool("friendInvitesCollapsed") then
			for i = 1, numInvites do
				table.insert(displayList, {
					buttonType = BUTTON_TYPE_INVITE,
					inviteIndex = i,
				})
			end

			-- Add divider if there are friends below
			if #self.friendsList > 0 then
				table.insert(displayList, {
					buttonType = BUTTON_TYPE_DIVIDER,
				})
			end
		end
	end

	-- Separate friends into groups
	local groupedFriends = {
		favorites = {},
		nogroup = {},
		ingame = {}, -- Feature: In-Game Group
	}
	local totalGroupCounts = {
		favorites = 0,
		nogroup = 0,
		ingame = 0,
	}
	local onlineGroupCounts = {
		favorites = 0,
		nogroup = 0,
		ingame = 0,
	}

	-- Initialize custom group tables
	for groupId, groupData in pairs(friendGroups) do
		if not groupData.builtin or groupId == "favorites" or groupId == "nogroup" or groupId == "ingame" then
			groupedFriends[groupId] = groupedFriends[groupId] or {}
			totalGroupCounts[groupId] = 0
			onlineGroupCounts[groupId] = 0
		end
	end

	-- Get DB
	local DB = GetDB()
	if not DB then
		return displayList -- Return empty list if DB missing
	end

	-- PERFY OPTIMIZATION: Direct cache access (no DB:Get fallback)
	-- Cache is auto-refreshed at entry point, safe to use directly
	local enableInGameGroup = self.settingsCache.enableInGameGroup or false
	local inGameGroupMode = self.settingsCache.inGameGroupMode or "same_game"
	local BNET_CLIENT_WOW = BNET_CLIENT_WOW or "WoW"

	-- Group friends
	for _, friend in ipairs(self.friendsList) do
		local friendUID = GetFriendUID(friend)
		local isFavorite = (friend.type == "bnet" and friend.isFavorite)
		local customGroups = (
			BetterFriendlistDB
			and BetterFriendlistDB.friendGroups
			and BetterFriendlistDB.friendGroups[friendUID]
		) or {}

		-- Determine groups for this friend
		local friendGroupIds = {}
		local isInAnyGroup = false

		-- FIX: Only mark as "in group" if the Favorites group is actually Enabled/Visible
		-- If Favorites group is hidden (showFavoritesGroup=false), BNet favorites should fall through to 'nogroup'
		-- unless they are in another custom group.
		-- CRITICAL: Must check friendGroups (from Groups:GetAll(), respects visibility settings)
		-- NOT groupedFriends (which always pre-initializes favorites={} and is always truthy)
		if isFavorite then
			if friendGroups["favorites"] then
				table.insert(friendGroupIds, "favorites")
				isInAnyGroup = true
			end
		end

		-- Feature: In-Game Group (Dynamic)
		-- Only if enabled in settings
		if enableInGameGroup then
			local mode = inGameGroupMode
			local isInGame = false

			if mode == "any_game" then
				-- Any Game: WoW friends (always online in game) OR BNet friends online in ANY game
				if friend.type == "wow" and friend.connected then
					isInGame = true
				elseif
					friend.type == "bnet"
					and friend.connected
					and friend.gameAccountInfo
					and friend.gameAccountInfo.isOnline
				then
					-- Check if actually in a game (clientProgram is set)
					local client = friend.gameAccountInfo.clientProgram
					if client and client ~= "" and client ~= "App" and client ~= "BSAp" then
						isInGame = true
					end
				end
			else
				-- Same Game (Default): WoW friends OR BNet friends in SAME WoW version
				if friend.type == "wow" and friend.connected then
					isInGame = true
				elseif
					friend.type == "bnet"
					and friend.connected
					and friend.gameAccountInfo
					and friend.gameAccountInfo.clientProgram == BNET_CLIENT_WOW
				then
					-- Check Project ID (Retail vs Classic vs Classic Era)
					if friend.gameAccountInfo.wowProjectID == WOW_PROJECT_ID then
						isInGame = true
					end
				end
			end

			if isInGame then
				table.insert(friendGroupIds, "ingame")
				isInAnyGroup = true
			end
		end

		local assignedGroups = {} -- Deduplication set

		for _, groupId in ipairs(customGroups) do
			if type(groupId) == "string" and groupedFriends[groupId] and not assignedGroups[groupId] then
				table.insert(friendGroupIds, groupId)
				assignedGroups[groupId] = true -- Mark as assigned
				isInAnyGroup = true
			end
		end

		if not isInAnyGroup then
			table.insert(friendGroupIds, "nogroup")
		end

		-- Update counts and lists
		for _, groupId in ipairs(friendGroupIds) do
			-- Increment total count
			totalGroupCounts[groupId] = (totalGroupCounts[groupId] or 0) + 1

			-- Increment online count
			if friend.connected then
				onlineGroupCounts[groupId] = (onlineGroupCounts[groupId] or 0) + 1
			end

			-- Add to display list if passes filters
			if self:PassesFilters(friend) then
				table.insert(groupedFriends[groupId], friend)
			end
		end
	end

	-- Build display list in group order
	local orderedGroups = {}
	for _, groupData in pairs(friendGroups) do
		-- Safety check for groupData structure
		if type(groupData) == "table" then
			table.insert(orderedGroups, groupData)
		end
	end

	-- ROBUSTNESS FIX: Ensure nogroup is always present in orderedGroups
	-- If Groups module returns a list without nogroup (e.g. glitch or filter), friends in 'nogroup' would be invisible.
	local hasNoGroup = false
	for _, g in ipairs(orderedGroups) do
		if g.id == "nogroup" then
			hasNoGroup = true
			break
		end
	end

	if not hasNoGroup then
		-- Fallback 'No Group' definition
		table.insert(orderedGroups, {
			id = "nogroup",
			name = (BFL.L and BFL.L.GROUP_NO_GROUP) or "No Group",
			builtin = true,
			order = 999,
			collapsed = (
				BetterFriendlistDB
				and BetterFriendlistDB.groupStates
				and BetterFriendlistDB.groupStates["nogroup"]
			) or false,
			color = { r = 0.5, g = 0.5, b = 0.5 },
		})
	end

	table.sort(orderedGroups, function(a, b)
		return (a.order or 999) < (b.order or 999)
	end)

	-- PERFY OPTIMIZATION: Direct cache access
	local hideEmptyGroups = self.settingsCache.hideEmptyGroups or false

	for _, groupData in ipairs(orderedGroups) do
		local groupFriends = groupedFriends[groupData.id]

		-- Only process if group has friends table (might be nil if not initialized)
		if groupFriends then
			-- Check if we should skip empty groups
			local shouldSkip = false
			-- Fix Phase 22: Only hide empty results if a filter is active (Search or Filter Mode != All)
			-- Otherwise, show empty groups so users can populate them (prevents "disappearing groups" issue)
			local hasActiveFilter = (self.filterMode and self.filterMode ~= "all")
				or (self.searchText and self.searchText ~= "")

			if hideEmptyGroups then
				-- Count online friends only (for display purpose)
				local onlineCount = 0
				for _, friend in ipairs(groupFriends) do
					if friend.connected then
						onlineCount = onlineCount + 1
					end
				end
				shouldSkip = (onlineCount == 0)
			elseif #groupFriends == 0 then
				-- Only skip if filtering is active (e.g. "Online" or Search)
				shouldSkip = hasActiveFilter
			end

			if not shouldSkip then
				-- Add group header
				table.insert(displayList, {
					buttonType = BUTTON_TYPE_GROUP_HEADER,
					groupId = groupData.id,
					name = groupData.name,
					count = #groupFriends,
					totalCount = totalGroupCounts[groupData.id] or 0,
					onlineCount = onlineGroupCounts[groupData.id] or 0,
					collapsed = groupData.collapsed,
				})

				-- Add friends if not collapsed
				if not groupData.collapsed then
					for _, friend in ipairs(groupFriends) do
						table.insert(displayList, {
							buttonType = BUTTON_TYPE_FRIEND,
							friend = friend,
							groupId = groupData.id,
							_hasMultiAccountRow = ShouldShowMultiAccountRow(self, friend),
						})
					end
				end
			end
		end
	end

	-- PERFY OPTIMIZATION (Phase 2B): Cache built display list
	self.lastBuildSignature = currentSignature
	self.cachedDisplayList = displayList
	self.groupedFriends = groupedFriends
	self.cachedGroupedFriends = groupedFriends

	return displayList
end

-- Create element factory for ScrollBox button creation
-- Returns a factory function that creates buttons based on elementData.buttonType
local function CreateElementFactory(friendsList) -- Capture friendsList reference in closure
	local self = friendsList

	-- Pre-define initializers to avoid closure allocation per row (Phase 9.3 Optimization)
	local function InitInviteHeader(button, data)
		self:UpdateInviteHeaderButton(button, data)
	end

	local function InitInviteButton(button, data)
		self:UpdateInviteButton(button, data)
	end

	local function InitGroupHeader(button, data)
		self:UpdateGroupHeaderButton(button, data)
	end

	-- REFACTORED (Phase 21): Removed InitSearchBox - using Persistent Frame
	-- local function InitSearchBox(frame, data) ... end

	local function InitFriendButton(button, data)
		-- One-time setup for recycled buttons (Phase 5 Optimization)
		if not button.initialized then
			-- Create drag overlay
			if not button.dragOverlay then
				local dragOverlay = button:CreateTexture(nil, "OVERLAY")
				dragOverlay:SetAllPoints()
				dragOverlay:SetColorTexture(1.0, 0.843, 0.0, 0.5) -- Gold with 50% alpha
				dragOverlay:SetBlendMode("ADD")
				dragOverlay:Hide()
				button.dragOverlay = dragOverlay
			end

			-- Create selection highlight
			if not button.selectionHighlight then
				local selectionHighlight = button:CreateTexture(nil, "BACKGROUND")
				selectionHighlight:SetTexture("Interface\\QuestFrame\\UI-QuestLogTitleHighlight")
				selectionHighlight:SetBlendMode("ADD")
				selectionHighlight:SetAllPoints()
				selectionHighlight:SetVertexColor(0.510, 0.773, 1.0, 0.5)
				selectionHighlight:Hide()
				button.selectionHighlight = selectionHighlight
			end

			-- Create favorite icon (Phase 5 Optimization: Static Init)
			if not button.favoriteIcon then
				button.favoriteIcon = button:CreateTexture(nil, "OVERLAY")
				button.favoriteIcon:SetTexture("Interface\\AddOns\\BetterFriendlist\\Icons\\star")
				button.favoriteIcon:Hide()
			end

			-- Create multi-game-account badge (Phase: Multi-Game-Account Support)
			if not button.gameAccountBadge then
				local badge = CreateFrame("Frame", nil, button)
				badge:SetSize(16, 16)
				badge:Hide()
				button.gameAccountBadge = badge

				local badgeBg = badge:CreateTexture(nil, "OVERLAY", nil, 1)
				badgeBg:SetAllPoints(badge)
				badgeBg:SetColorTexture(0.1, 0.1, 0.1, 0.9)
				local badgeMask = badge:CreateMaskTexture(nil, "OVERLAY")
				badgeMask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask")
				badgeMask:SetAllPoints(badge)
				badgeBg:AddMaskTexture(badgeMask)
				badge.gameAccountBadgeBg = badgeBg
				button.gameAccountBadgeBg = badgeBg

				local badgeText = badge:CreateFontString(nil, "OVERLAY", nil, 2)
				badgeText:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
				badgeText:SetPoint("CENTER", badge, "CENTER", 0, 0)
				badgeText:SetTextColor(1, 0.82, 0, 1) -- Gold
				badgeText:SetJustifyH("CENTER")
				badge.gameAccountBadgeText = badgeText
				button.gameAccountBadgeText = badgeText
			end

			-- Mini stack of class dots for first few game accounts
			if not button.gameAccountDotsFrame then
				local dotsFrame = CreateFrame("Frame", nil, button)
				dotsFrame:SetSize(32, 12)
				dotsFrame:Hide()
				button.gameAccountDotsFrame = dotsFrame
				button.gameAccountDots = {}

				for i = 1, 3 do
					local dot = dotsFrame:CreateTexture(nil, "OVERLAY", nil, 3 + i)
					dot:SetColorTexture(1, 1, 1, 1)
					dot:Hide()
					button.gameAccountDots[i] = dot
				end
			end

			-- Dedicated multi-account row (icons + names)
			if not button.multiAccountRow then
				local row = CreateFrame("Frame", nil, button)
				row:SetHeight(14)
				row:Hide()
				row.entries = {}

				for i = 1, MAX_MULTI_ACCOUNT_ROW_ENTRIES do
					local entry = CreateFrame("Frame", nil, row)
					entry:SetHeight(14)
					entry.icon = entry:CreateTexture(nil, "ARTWORK")
					entry.icon:SetSize(12, 12)
					entry.icon:SetPoint("LEFT", entry, "LEFT", 0, 0)
					entry.text = entry:CreateFontString(nil, "ARTWORK", "BetterFriendlistFriendsFontSmall")
					entry.text:SetJustifyH("LEFT")
					entry.text:SetWordWrap(false)
					entry.text:SetPoint("LEFT", entry.icon, "RIGHT", 4, 0)
					row.entries[i] = entry
				end

				row.remainderText = row:CreateFontString(nil, "ARTWORK", "BetterFriendlistFriendsFontSmall")
				row.remainderText:SetJustifyH("LEFT")

				button.multiAccountRow = row
			end

			-- Clickable overlay on game icon for switching preferred game account
			if not button.gameIconOverlay then
				local overlay = CreateFrame("Button", nil, button)
				overlay:SetSize(28, 28)
				overlay:Hide()
				overlay:SetScript("OnClick", function(self)
					local FL = BFL:GetModule("FriendsList")
					if FL and self.friendData then
						FL:ShowGameAccountPicker(self, self.friendData)
					end
				end)
				overlay:SetScript("OnEnter", function(self)
					if self.friendData and self.friendData.gameAccounts and #self.friendData.gameAccounts > 1 then
						GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
						GameTooltip:SetText((L and L.MENU_SWITCH_GAME_ACCOUNT) or "Switch Game Account", 1, 1, 1)
						GameTooltip:Show()
					end
				end)
				overlay:SetScript("OnLeave", function()
					GameTooltip:Hide()
				end)
				button.gameIconOverlay = overlay
			end

			-- Enable drag
			button:RegisterForDrag("LeftButton")
			button:SetScript("OnDragStart", Button_OnDragStart)
			button:SetScript("OnDragStop", Button_OnDragStop)

			-- PERFY OPTIMIZATION (Phase 2A): Use pre-defined handler
			-- FIX: Responsive Layout (Phase 28)
			-- Ensure text width updates when button width changes (e.g. resizing frame)
			if not button.resizeHooked then
				button:SetScript("OnSizeChanged", FriendButton_OnSizeChanged)
				button.resizeHooked = true
			end

			button.initialized = true
		end

		self:UpdateFriendButton(button, data)
	end

	return function(factory, elementData)
		local buttonType = elementData.buttonType

		if buttonType == BUTTON_TYPE_DIVIDER then
			factory("BetterFriendsDividerTemplate")
		elseif buttonType == BUTTON_TYPE_INVITE_HEADER then
			factory("BFL_FriendInviteHeaderTemplate", InitInviteHeader)
		elseif buttonType == BUTTON_TYPE_INVITE then
			factory("BFL_FriendInviteButtonTemplate", InitInviteButton)
		elseif buttonType == BUTTON_TYPE_GROUP_HEADER then
			factory("BetterFriendsGroupHeaderTemplate", InitGroupHeader)

		-- elseif buttonType == BUTTON_TYPE_SEARCH then
		-- 	factory("BetterFriendsSearchBoxTemplate", InitSearchBox)
		else -- BUTTON_TYPE_FRIEND
			factory("BetterFriendsListButtonTemplate", InitFriendButton)
		end
	end
end

-- Create extent calculator for dynamic button heights
-- Returns a function that calculates height based on elementData.buttonType
local function CreateExtentCalculator(self)
	-- PERFY OPTIMIZATION: Direct cache access (no DB dependency in closure)
	return function(dataIndex, elementData)
		local isCompactMode = self.settingsCache.compactMode or false
		-- Fix #35/#40: Get font sizes from settings cache for dynamic row height
		local nameSize = self.settingsCache.fontSizeFriendName or 12
		local infoSize = self.settingsCache.fontSizeFriendInfo or 10

		if elementData.buttonType == BUTTON_TYPE_GROUP_HEADER then
			return 22
		elseif elementData.buttonType == BUTTON_TYPE_INVITE_HEADER then
			return 22
		elseif elementData.buttonType == BUTTON_TYPE_INVITE then
			return 34
		elseif elementData.buttonType == BUTTON_TYPE_DIVIDER then
			return 8
		elseif elementData.buttonType == BUTTON_TYPE_SEARCH then
			return 30
		elseif elementData.buttonType == BUTTON_TYPE_FRIEND then
			-- Fix #35/#40: Use dynamic height based on font size
			return GetItemHeight(
				elementData,
				isCompactMode,
				nameSize,
				infoSize,
				self,
				self.settingsCache and self.settingsCache.infoDisabled
			)
		else
			return 34
		end
	end
end

-- ========================================
-- Responsive ScrollBox Functions (Phase 3)
-- ========================================

-- Update SearchBox visibility and anchors (Phase 22 Fix)
function FriendsList:UpdateSearchBoxState()
	local frame = BetterFriendsFrame
	if not frame or not frame.ScrollFrame then
		return
	end

	-- CRITICAL: Refresh cache before reading simpleMode to prevent stale state
	-- when called from OnSimpleModeChanged before ForceRefreshFriendsList has run
	self:UpdateSettingsCache()

	-- PERFY OPTIMIZATION: Direct cache access
	local simpleMode = self.settingsCache.simpleMode or false
	local showSearch = self.settingsCache.simpleModeShowSearch
	if showSearch == nil then
		showSearch = true
	end
	local searchBox = frame.FriendsTabHeader and frame.FriendsTabHeader.SearchBox
	local scrollFrame = frame.ScrollFrame

	-- Check if we are on the Contacts bottom tab (which hosts Friends, Recent Allies, RAF)
	local isContactsTab = (PanelTemplates_GetSelectedTab(frame) or 1) == 1

	-- Relaxed check: If the scroll frame is shown, we are definitely on the contacts tab
	-- This fixes Scenario 3 where toggling simpleMode hides variable elements
	if scrollFrame and scrollFrame:IsShown() then
		isContactsTab = true
	end

	-- Check which top tab is active (1=Friends, 2=Recent Allies, 3=RAF)
	local activeTopTab = 1
	if frame.FriendsTabHeader then
		activeTopTab = PanelTemplates_GetSelectedTab(frame.FriendsTabHeader) or 1
	end
	local isFriendsTopTab = (activeTopTab == 1)

	if simpleMode then
		if showSearch and searchBox then
			-- Persistent SearchBox Mode (Simple Mode - SHOW)
			-- We reparent to the main frame to keep it visible even when TabHeader is hidden
			searchBox:SetParent(frame)
			searchBox:ClearAllPoints()

			-- Shifted 2px to the right to correct centering (Left: 8, Right: -4)
			-- Adjusted (Phase 29): Reduced top padding (-5 -> -2) to reduce "air" above
			-- Adjusted (Phase 30): Optimized Simple Mode spacing based on user feedback
			searchBox:SetPoint("TOPLEFT", frame.Inset, "TOPLEFT", 8, -1)
			-- Adjusted (Phase 31): Extended width to right edge (was -4)
			searchBox:SetPoint("TOPRIGHT", frame.Inset, "TOPRIGHT", -1, -1)

			searchBox:SetWidth(0) -- Let anchors decide width
			-- Adjusted (Phase 30): Reduced height (28 -> 22) for tighter layout
			-- Note: SearchBoxTemplate textures might clip if too small, but 22 is usually safe for standard fonts.
			searchBox:SetHeight(22)
			searchBox:SetFrameLevel(frame:GetFrameLevel() + 20)

			-- Show SearchBox on any Contacts sub-tab (Friends, Recent Allies, RAF)
			if isContactsTab then
				searchBox:Show()
			else
				searchBox:Hide()
			end

			-- Push ScrollFrame down only on Friends top tab (scrollFrame is Friends-specific)
			if isFriendsTopTab then
				-- Adjusted (Phase 30): Maximum tightness (-25 -> -22)
				scrollFrame:ClearAllPoints()
				scrollFrame:SetPoint("TOPLEFT", frame.Inset, "TOPLEFT", 4, -22)
				scrollFrame:SetPoint("BOTTOMRIGHT", frame.Inset, "BOTTOMRIGHT", -22, 2)
			end

			-- Push content frames for tabs 2/3 down to make room for SearchBox
			if frame.RecentAlliesFrame then
				frame.RecentAlliesFrame:ClearAllPoints()
				frame.RecentAlliesFrame:SetPoint("TOPLEFT", frame.Inset, "TOPLEFT", 3, -22)
				frame.RecentAlliesFrame:SetPoint("BOTTOMRIGHT", frame.Inset, "BOTTOMRIGHT", -3, 2)
			end
			if frame.RecruitAFriendFrame then
				frame.RecruitAFriendFrame:ClearAllPoints()
				frame.RecruitAFriendFrame:SetPoint("TOPLEFT", frame.Inset, "TOPLEFT", 0, -22)
				frame.RecruitAFriendFrame:SetPoint("BOTTOMRIGHT", frame.Inset, "BOTTOMRIGHT", 0, 0)
			end
		elseif searchBox then
			-- Persistent SearchBox Mode (Simple Mode - HIDE)
			searchBox:Hide()

			-- Reset ScrollFrame to top
			scrollFrame:ClearAllPoints()
			scrollFrame:SetPoint("TOPLEFT", frame.Inset, "TOPLEFT", 4, -4)
			scrollFrame:SetPoint("BOTTOMRIGHT", frame.Inset, "BOTTOMRIGHT", -22, 2)

			-- Reset content frames for tabs 2/3 (no SearchBox = no offset)
			if frame.RecentAlliesFrame then
				frame.RecentAlliesFrame:ClearAllPoints()
				frame.RecentAlliesFrame:SetPoint("TOPLEFT", frame.Inset, "TOPLEFT", 3, -4)
				frame.RecentAlliesFrame:SetPoint("BOTTOMRIGHT", frame.Inset, "BOTTOMRIGHT", -3, 2)
			end
			if frame.RecruitAFriendFrame then
				frame.RecruitAFriendFrame:ClearAllPoints()
				frame.RecruitAFriendFrame:SetPoint("TOPLEFT", frame.Inset, "TOPLEFT", 0, -4)
				frame.RecruitAFriendFrame:SetPoint("BOTTOMRIGHT", frame.Inset, "BOTTOMRIGHT", 0, 0)
			end
		end
	else
		-- Normal Mode
		if searchBox and frame.FriendsTabHeader then
			searchBox:SetParent(frame.FriendsTabHeader)
			searchBox:ClearAllPoints()

			-- Reset FrameLevel (Simple Mode elevates it by +20 for overlay)
			searchBox:SetFrameLevel(frame.FriendsTabHeader:GetFrameLevel() + 2)

			-- Invalidate width cache: Simple Mode sets SetWidth(0), but BFL_LastWidth
			-- retains the previous Normal Mode value. Without clearing this,
			-- UpdateSearchBoxWidth() skips the SetWidth call (cache hit) and the
			-- SearchBox stays at width 0.
			searchBox.BFL_LastWidth = nil

			if BFL.IsClassic then
				-- Classic Normal Mode: Restore XML Defaults
				-- XML: <Anchor point="TOPLEFT" relativeKey="$parent.$parent.Inset" x="10" y="50"/>
				-- Adjusted (Phase 29): Shifted 0.5px left for pixel-perfect alignment
				searchBox:SetPoint("TOPLEFT", frame.Inset, "TOPLEFT", 9.5, 50)
				searchBox:SetPoint("TOPRIGHT", frame.Inset, "TOPRIGHT", -10, 50)
				searchBox:SetWidth(0) -- Let anchors decide width
			else
				-- Restore XML exact layout (Retail)
				-- <Anchor point="TOPLEFT" relativeKey="$parent.$parent.Inset" x="10" y="60"/>
				-- Adjusted (Phase 29): Shifted 0.5px left for pixel-perfect alignment
				searchBox:SetPoint("TOPLEFT", frame.Inset, "TOPLEFT", 9.5, 60)

				-- Fixed: Do not hardcode width (220), use responsive width calculation (Phase 28)
				if self.UpdateSearchBoxWidth then
					self:UpdateSearchBoxWidth()
				else
					searchBox:SetWidth(220) -- Fallback
				end
			end

			searchBox:SetHeight(28)

			-- Re-anchor dropdowns after reparenting
			-- XML anchors ($parent.SearchBox) may be invalidated when SearchBox
			-- was reparented to BetterFriendsFrame during Simple Mode
			local header = frame.FriendsTabHeader
			if BFL.IsClassic then
				local isClassicElvUISkinActive = _G.ElvUI
					and BetterFriendlistDB
					and BetterFriendlistDB.enableElvUISkin ~= false
				local classicSortSpacing = isClassicElvUISkinActive and 8 or -10
				local classicSecondarySpacing = isClassicElvUISkinActive and 8 or -15

				-- Classic: UIDropDownMenuTemplate frames are ~180px wide.
				-- Place all 3 dropdowns in a separate row ABOVE the SearchBox
				-- (instead of Retail-style to the right, which overflows the frame).
				-- UIDropDownMenuTemplate has ~16px built-in left margin, ~8px top margin.
				if header.QuickFilterDropdown then
					header.QuickFilterDropdown:ClearAllPoints()
					header.QuickFilterDropdown:SetPoint("TOPLEFT", searchBox, "TOPLEFT", -16, 32)
					header.QuickFilterDropdown:SetHeight(24)
				end
				if header.PrimarySortDropdown and header.QuickFilterDropdown then
					header.PrimarySortDropdown:ClearAllPoints()
					header.PrimarySortDropdown:SetPoint(
						"LEFT",
						header.QuickFilterDropdown,
						"RIGHT",
						classicSortSpacing,
						0
					)
					header.PrimarySortDropdown:SetHeight(24)
				end
				if header.SecondarySortDropdown and header.PrimarySortDropdown then
					header.SecondarySortDropdown:ClearAllPoints()
					header.SecondarySortDropdown:SetPoint(
						"LEFT",
						header.PrimarySortDropdown,
						"RIGHT",
						classicSecondarySpacing,
						0
					)
					header.SecondarySortDropdown:SetHeight(24)
				end
			else
				-- Retail: WowStyle1DropdownTemplate buttons are small (51px),
				-- so place them to the right of the SearchBox on the same row
				if header.QuickFilterDropdown then
					header.QuickFilterDropdown:ClearAllPoints()
					header.QuickFilterDropdown:SetPoint("LEFT", searchBox, "RIGHT", 5, 0)
				end
				if header.PrimarySortDropdown and header.QuickFilterDropdown then
					header.PrimarySortDropdown:ClearAllPoints()
					header.PrimarySortDropdown:SetPoint("LEFT", header.QuickFilterDropdown, "RIGHT", 5, 0)
				end
				if header.SecondarySortDropdown and header.PrimarySortDropdown then
					header.SecondarySortDropdown:ClearAllPoints()
					header.SecondarySortDropdown:SetPoint("LEFT", header.PrimarySortDropdown, "RIGHT", 5, 0)
				end
			end

			-- CRITICAL FIX: Ensure SearchBox is visible in Normal Mode
			if not searchBox:IsShown() then
				searchBox:Show()
			end

			-- ALSO Ensure TabHeader is visible if on Friends Tab
			if isContactsTab and not frame.FriendsTabHeader:IsShown() then
				frame.FriendsTabHeader:Show()
			end
		end

		-- Restore ScrollFrame (Normal Mode usually has header space if not Simple)
		scrollFrame:ClearAllPoints()
		scrollFrame:SetPoint("TOPLEFT", frame.Inset, "TOPLEFT", 4, -4)
		scrollFrame:SetPoint("BOTTOMRIGHT", frame.Inset, "BOTTOMRIGHT", -22, 2)
	end
end

-- Update ScrollBox/ScrollFrame height when frame is resized (called from MainFrameEditMode)
function FriendsList:UpdateScrollBoxExtent()
	local frame = BetterFriendsFrame
	if not frame or not frame.ScrollFrame then
		return
	end

	-- Update SearchBox state and anchors
	self:UpdateSearchBoxState()

	-- Retail: ScrollBox updates automatically with anchor changes
	-- We do NOT trigger FullUpdate here as it causes lag/delay (Regression Phase 21)
	-- Pass
end

-- Get button width based on current frame size (Phase 3)
function FriendsList:GetButtonWidth()
	local frame = BetterFriendsFrame
	if not frame then
		return 398 -- Default width from XML
	end

	-- Frame width minus padding, scrollbar, and inset borders
	-- Frame width - left padding (8px) - right padding (6px) - scrollbar (22px) - inset borders (8px)
	local frameWidth = frame:GetWidth()
	local buttonWidth = frameWidth - 44

	-- Ensure minimum width
	if buttonWidth < 300 then
		buttonWidth = 300
	end

	return buttonWidth
end

-- ========================================
-- ScrollBox Initialization (NEW - Phase 1)
-- ========================================

-- Initialize scroll system (called once in Initialize())
-- Retail: Modern ScrollBox/DataProvider system
-- Classic: FauxScrollFrame with button pool
function FriendsList:InitializeScrollBox()
	local scrollFrame = BetterFriendsFrame.ScrollFrame
	if not scrollFrame then
		return
	end

	-- Classic: Use FauxScrollFrame approach
	if BFL.IsClassic or not BFL.HasModernScrollBox then
		-- BFL:DebugPrint("|cff00ffffFriendsList:|r Using Classic FauxScrollFrame mode")
		self:InitializeClassicScrollFrame(scrollFrame)
		return
	end

	-- Retail: Use modern ScrollBox system
	-- BFL:DebugPrint("|cff00ffffFriendsList:|r Using Retail ScrollBox mode")

	-- Create ScrollBox if it doesn't exist
	if not scrollFrame.ScrollBox then
		-- Create ScrollBox container (replaces FauxScrollFrame)
		local scrollBox = CreateFrame("Frame", nil, scrollFrame, "WowScrollBoxList")
		scrollBox:SetPoint("TOPLEFT", scrollFrame, "TOPLEFT", 0, 0)
		scrollBox:SetPoint("BOTTOMRIGHT", scrollFrame, "BOTTOMRIGHT", 0, 0)
		scrollFrame.ScrollBox = scrollBox
	end

	-- Use existing MinimalScrollBar (already defined in XML)
	local scrollBar = BetterFriendsFrame.MinimalScrollBar
	if not scrollBar then
		return
	end

	-- Create view with factory and extent calculator
	local view = CreateScrollBoxListLinearView()
	view:SetElementFactory(CreateElementFactory(self))
	view:SetElementExtentCalculator(CreateExtentCalculator(self))

	-- Initialize ScrollBox with view and scrollbar
	ScrollUtil.InitScrollBoxListWithScrollBar(scrollFrame.ScrollBox, scrollBar, view)

	-- Store reference for later use
	self.scrollBox = scrollFrame.ScrollBox
	self.scrollBar = scrollBar
end

-- ========================================
-- Classic FauxScrollFrame Implementation
-- ========================================

-- Classic button pool configuration
local CLASSIC_BUTTON_HEIGHT = 34
local CLASSIC_COMPACT_BUTTON_HEIGHT = 24
local CLASSIC_MAX_BUTTONS = 50 -- Max visible buttons (Increased for safety)

-- Initialize Classic FauxScrollFrame with button pool
function FriendsList:InitializeClassicScrollFrame(scrollFrame) -- Store reference to scrollFrame for Classic mode
	-- Safety: Destroy orphaned buttons from previous initialization to prevent duplicate rendering
	if self.classicButtonPool then
		for _, button in ipairs(self.classicButtonPool) do
			button:Hide()
			button:SetParent(nil)
		end
	end
	if self.classicHeaderPool then
		for _, header in ipairs(self.classicHeaderPool) do
			header:Hide()
			header:SetParent(nil)
		end
	end
	if self.classicInviteHeaderPool then
		for _, b in ipairs(self.classicInviteHeaderPool) do
			b:Hide()
			b:SetParent(nil)
		end
	end
	if self.classicInviteButtonPool then
		for _, b in ipairs(self.classicInviteButtonPool) do
			b:Hide()
			b:SetParent(nil)
		end
	end
	if self.classicDividerPool then
		for _, b in ipairs(self.classicDividerPool) do
			b:Hide()
			b:SetParent(nil)
		end
	end

	self.classicScrollFrame = scrollFrame
	self.classicButtonPool = {}
	self.classicDisplayList = {}

	-- Create FauxScrollFrame if needed
	if not scrollFrame.FauxScrollFrame then
		-- Create the scroll frame
		local fauxScroll =
			CreateFrame("ScrollFrame", "BetterFriendsClassicScrollFrame", scrollFrame, "FauxScrollFrameTemplate")
		fauxScroll:SetPoint("TOPLEFT", scrollFrame, "TOPLEFT", 0, 0)
		-- Fix Phase 27: Remove double padding (ScrollFrame is already -22, so we don't need another -22 here)
		fauxScroll:SetPoint("BOTTOMRIGHT", scrollFrame, "BOTTOMRIGHT", 0, 0)
		scrollFrame.FauxScrollFrame = fauxScroll

		-- Z-Order Fix: Ensure ScrollBar (child of fauxScroll) is above content
		fauxScroll:SetFrameLevel(scrollFrame:GetFrameLevel() + 10)

		-- Fix ScrollBar Anchor: Re-anchor to be outside the list (in the reserved 22px space)
		-- Note: We removed SetClipsChildren(true) from the XML to allow this
		local scrollBar = _G[fauxScroll:GetName() .. "ScrollBar"] or _G["BetterFriendsClassicScrollFrameScrollBar"]
		if scrollBar then
			scrollBar:ClearAllPoints()
			scrollBar:SetPoint("TOPLEFT", fauxScroll, "TOPRIGHT", 0, -16)
			scrollBar:SetPoint("BOTTOMLEFT", fauxScroll, "BOTTOMRIGHT", 0, 16)
		end

		-- Explicitly disable clipping on the container to ensure ScrollBar (outside) is visible
		scrollFrame:SetClipsChildren(false)

		-- Set OnVerticalScroll handler
		fauxScroll:SetScript("OnVerticalScroll", function(self, offset)
			FauxScrollFrame_OnVerticalScroll(self, offset, CLASSIC_BUTTON_HEIGHT, function()
				BFL.FriendsList:RenderClassicButtons()
			end)
		end)
	end

	-- Create content frame for buttons (same size as FauxScrollFrame)
	if not scrollFrame.ContentFrame then
		local content = CreateFrame("Frame", nil, scrollFrame)
		content:SetPoint("TOPLEFT", scrollFrame.FauxScrollFrame, "TOPLEFT", 0, 0)
		content:SetPoint("BOTTOMRIGHT", scrollFrame.FauxScrollFrame, "BOTTOMRIGHT", 0, 0)
		scrollFrame.ContentFrame = content

		-- Ensure content frame clips its children (buttons) so they don't overflow the viewport
		-- This prevents the "too long" list overlapping bottom buttons
		content:SetClipsChildren(true)

		-- Z-Order Fix: Ensure content is below ScrollBar
		content:SetFrameLevel(scrollFrame:GetFrameLevel() + 1)
	end

	-- Calculate how many buttons we need
	local frameHeight = scrollFrame:GetHeight() or 400
	local numButtons = math.ceil(frameHeight / CLASSIC_COMPACT_BUTTON_HEIGHT) + 5 -- +5 extra for variable heights (headers are smaller)
	numButtons = math.min(numButtons, CLASSIC_MAX_BUTTONS)

	-- Create button pool using friend button template
	for i = 1, numButtons do
		local button = CreateFrame(
			"Button",
			"BetterFriendsListButton" .. i,
			scrollFrame.ContentFrame,
			"BetterFriendsListButtonTemplate"
		)
		button:SetPoint("TOPLEFT", scrollFrame.ContentFrame, "TOPLEFT", 2, -((i - 1) * CLASSIC_BUTTON_HEIGHT)) -- 2px left padding
		button:SetPoint("RIGHT", scrollFrame.ContentFrame, "RIGHT", 5, 0) -- 12px - 2px right padding = 10px
		button:SetHeight(CLASSIC_BUTTON_HEIGHT)
		button.classicIndex = i
		button:Hide()

		-- Create selection highlight (Fix for Classic missing selection state)
		if not button.selectionHighlight then
			local selectionHighlight = button:CreateTexture(nil, "BACKGROUND")
			selectionHighlight:SetTexture("Interface\\QuestFrame\\UI-QuestLogTitleHighlight")
			selectionHighlight:SetBlendMode("ADD")
			selectionHighlight:SetAllPoints()
			selectionHighlight:SetVertexColor(0.510, 0.773, 1.0, 0.5)
			selectionHighlight:Hide()
			button.selectionHighlight = selectionHighlight
		end

		-- Create drag overlay (Fix for Classic missing drag visual)
		if not button.dragOverlay then
			local dragOverlay = button:CreateTexture(nil, "OVERLAY")
			dragOverlay:SetAllPoints()
			dragOverlay:SetColorTexture(1.0, 0.843, 0.0, 0.5) -- Gold with 50% alpha
			dragOverlay:SetBlendMode("ADD")
			dragOverlay:Hide()
			button.dragOverlay = dragOverlay
		end

		-- Create favorite icon (Fix for Classic)
		if not button.favoriteIcon then
			button.favoriteIcon = button:CreateTexture(nil, "OVERLAY")
			button.favoriteIcon:SetTexture("Interface\\AddOns\\BetterFriendlist\\Icons\\star")
			button.favoriteIcon:Hide()
		end

		-- Enable drag handlers
		button:RegisterForDrag("LeftButton")
		button:SetScript("OnDragStart", Button_OnDragStart)
		button:SetScript("OnDragStop", Button_OnDragStop)

		-- FIX: Responsive Layout (Phase 28) - Classic Implementation
		-- Ensure text width updates when button width changes (e.g. resizing frame)
		if not button.resizeHooked then
			button:SetScript("OnSizeChanged", function(self, width, height)
				local padding = self.textRightPadding or 80 -- Default fallback
				local nameWidth = width - 44 - padding
				if nameWidth < 10 then
					nameWidth = 10
				end
				if self.Name then
					self.Name:SetWidth(nameWidth)
				end
				if self.Info then
					self.Info:SetWidth(nameWidth)
				end
			end)
			button.resizeHooked = true
		end

		self.classicButtonPool[i] = button
	end

	-- Also create group header buttons
	self.classicHeaderPool = {}
	for i = 1, numButtons do -- Dynamic pool size matching friend buttons (Fix for >10 groups)
		local header = CreateFrame(
			"Button",
			"BetterFriendsGroupHeader" .. i,
			scrollFrame.ContentFrame,
			"BetterFriendsGroupHeaderTemplate"
		)
		header:SetPoint("LEFT", scrollFrame.ContentFrame, "LEFT", 2, 0) -- 2px left padding
		header:SetPoint("RIGHT", scrollFrame.ContentFrame, "RIGHT", 3, 0) -- Match friend buttons
		header:SetHeight(22)
		header:Hide()
		self.classicHeaderPool[i] = header
	end

	-- Create invite header buttons (Phase 6 Fix)
	self.classicInviteHeaderPool = {}
	for i = 1, 5 do -- Max 5 invite headers (usually only 1)
		local header = CreateFrame(
			"Button",
			"BetterFriendsInviteHeader" .. i,
			scrollFrame.ContentFrame,
			"BFL_FriendInviteHeaderTemplate"
		)
		header:SetPoint("LEFT", scrollFrame.ContentFrame, "LEFT", 2, 0)
		header:SetPoint("RIGHT", scrollFrame.ContentFrame, "RIGHT", 3, 0)
		header:SetHeight(22)
		header:Hide()
		self.classicInviteHeaderPool[i] = header
	end

	-- Create invite buttons (Phase 6 Fix)
	self.classicInviteButtonPool = {}
	for i = 1, numButtons do -- Dynamic pool size (Fix for >10 invites)
		local button = CreateFrame(
			"Button",
			"BetterFriendsInviteButton" .. i,
			scrollFrame.ContentFrame,
			"BFL_FriendInviteButtonTemplate"
		)
		button:SetPoint("LEFT", scrollFrame.ContentFrame, "LEFT", 2, 0)
		button:SetPoint("RIGHT", scrollFrame.ContentFrame, "RIGHT", 3, 0)
		button:SetHeight(34)
		button:Hide()
		self.classicInviteButtonPool[i] = button
	end

	-- Create divider buttons (Phase 6 Fix)
	self.classicDividerPool = {}
	for i = 1, 5 do -- Max 5 dividers
		local divider =
			CreateFrame("Frame", "BetterFriendsDivider" .. i, scrollFrame.ContentFrame, "BetterFriendsDividerTemplate")
		divider:SetPoint("LEFT", scrollFrame.ContentFrame, "LEFT", 2, 0)
		divider:SetPoint("RIGHT", scrollFrame.ContentFrame, "RIGHT", 3, 0)
		divider:SetHeight(8)
		divider:Hide()
		self.classicDividerPool[i] = divider
	end

	-- BFL:DebugPrint(string.format("|cff00ffffFriendsList:|r Created Classic button pool with %d buttons", numButtons))
end

-- Render buttons in Classic FauxScrollFrame mode
function FriendsList:RenderClassicButtons()
	if not self.classicScrollFrame or not self.classicButtonPool then
		return
	end

	local displayList = self.classicDisplayList or {}
	local numItems = #displayList
	local offset = FauxScrollFrame_GetOffset(self.classicScrollFrame.FauxScrollFrame) or 0
	local numButtons = #self.classicButtonPool

	-- PERFY OPTIMIZATION: Direct cache access
	-- Get compact mode setting
	local isCompactMode = self.settingsCache.compactMode or false
	local nameSize = self.fontCache and self.fontCache.nameSize or BASE_FONT_SIZE
	local infoSize = self.fontCache and self.fontCache.infoSize or BASE_FONT_SIZE

	-- Calculate total content height for accurate scrolling with variable item heights
	local totalHeight = 0
	for _, elementData in ipairs(displayList) do
		totalHeight = totalHeight
			+ GetItemHeight(
				elementData,
				isCompactMode,
				nameSize,
				infoSize,
				nil,
				self.settingsCache and self.settingsCache.infoDisabled
			)
	end

	-- FIX: Do NOT set ContentFrame height to totalHeight for FauxScrollFrame.
	-- This causes the frame to expand downwards and overlap other UI elements.
	-- ContentFrame should remain anchored to the viewport (set in InitializeClassicScrollFrame).
	-- self.classicScrollFrame.ContentFrame:SetHeight(math.max(totalHeight, self.classicScrollFrame:GetHeight() or 400))

	-- Calculate number of VISIBLE buttons (not pool size!)
	local scrollHeight = isCompactMode and CLASSIC_COMPACT_BUTTON_HEIGHT or CLASSIC_BUTTON_HEIGHT
	local frameHeight = self.classicScrollFrame:GetHeight() or 400
	local numVisibleButtons = math.floor(frameHeight / scrollHeight)

	FauxScrollFrame_Update(self.classicScrollFrame.FauxScrollFrame, numItems, numVisibleButtons, scrollHeight)

	-- Track current Y position for variable height items
	local yOffset = 0
	local buttonIndex = 1
	local headerIndex = 1
	local inviteHeaderIndex = 1
	local inviteButtonIndex = 1
	local dividerIndex = 1

	-- Hide all buttons and headers first
	for _, button in ipairs(self.classicButtonPool) do
		button:Hide()
	end
	for _, header in ipairs(self.classicHeaderPool) do
		header:Hide()
	end
	if self.classicInviteHeaderPool then
		for _, b in ipairs(self.classicInviteHeaderPool) do
			b:Hide()
		end
	end
	if self.classicInviteButtonPool then
		for _, b in ipairs(self.classicInviteButtonPool) do
			b:Hide()
		end
	end
	if self.classicDividerPool then
		for _, b in ipairs(self.classicDividerPool) do
			b:Hide()
		end
	end

	-- Render visible items
	for i = 1, numButtons do
		local dataIndex = offset + i
		if dataIndex <= numItems then
			local elementData = displayList[dataIndex]

			-- Use appropriate button type
			local button
			if elementData.buttonType == BUTTON_TYPE_GROUP_HEADER then
				-- Use header from header pool
				button = self.classicHeaderPool[headerIndex]
				headerIndex = headerIndex + 1
			elseif elementData.buttonType == BUTTON_TYPE_INVITE_HEADER then
				-- Use invite header from pool
				if self.classicInviteHeaderPool then
					button = self.classicInviteHeaderPool[inviteHeaderIndex]
					inviteHeaderIndex = inviteHeaderIndex + 1
				end
			elseif elementData.buttonType == BUTTON_TYPE_INVITE then
				-- Use invite button from pool
				if self.classicInviteButtonPool then
					button = self.classicInviteButtonPool[inviteButtonIndex]
					inviteButtonIndex = inviteButtonIndex + 1
				end
			elseif elementData.buttonType == BUTTON_TYPE_DIVIDER then
				-- Use divider from pool
				if self.classicDividerPool then
					button = self.classicDividerPool[dividerIndex]
					dividerIndex = dividerIndex + 1
				end
			else
				-- Use friend button from button pool
				button = self.classicButtonPool[buttonIndex]
				buttonIndex = buttonIndex + 1
			end

			if button and elementData then
				-- Position button (set BOTH TOPLEFT and RIGHT for full width)
				-- Right point set to -2 (small padding) because ScrollFrame is already -22 from edge
				button:ClearAllPoints()
				button:SetPoint("TOPLEFT", self.classicScrollFrame.ContentFrame, "TOPLEFT", 2, -yOffset) -- 2px left padding
				button:SetPoint("RIGHT", self.classicScrollFrame.ContentFrame, "RIGHT", -2, 0)

				-- Get height for this item type (using font sizes for dynamic friend row height)
				local itemHeight = GetItemHeight(
					elementData,
					isCompactMode,
					nameSize,
					infoSize,
					self,
					self.settingsCache and self.settingsCache.infoDisabled
				)
				button:SetHeight(itemHeight)

				-- Update button based on type
				if elementData.buttonType == BUTTON_TYPE_FRIEND then
					self:UpdateFriendButton(button, elementData)
				elseif elementData.buttonType == BUTTON_TYPE_GROUP_HEADER then
					self:UpdateGroupHeaderButton(button, elementData)
				elseif elementData.buttonType == BUTTON_TYPE_INVITE_HEADER then
					self:UpdateInviteHeaderButton(button, elementData)
				elseif elementData.buttonType == BUTTON_TYPE_INVITE then
					self:UpdateInviteButton(button, elementData)
				end

				button:Show()
				yOffset = yOffset + itemHeight
			end
			-- Continue iterating to process other items in the logic (offset calculation)
		end
	end
end

-- ========================================
-- Legacy Helper Functions
-- ========================================

-- Convert localized class name to English class filename for RAID_CLASS_COLORS
-- This fixes class coloring in non-English clients (deDE, frFR, esES, etc.)
-- CRITICAL: gameAccountInfo.className and friendInfo.className are LOCALIZED
-- German client: "Krieger", French client: "Guerrier", English client: "Warrior"
-- We must convert localized → English classFile (e.g., "Krieger" → "WARRIOR")
--
-- IMPORTANT: German (and other languages) use GENDERED class names:
-- - Masculine: "Krieger", "Dämonenjäger" (from GetClassInfo)
-- - Feminine: "Kriegerin", "Dämonenjägerin" (from gameAccountInfo.className)
-- We need to strip gender suffixes before matching
--
-- ⚠️ DEPRECATED: Logic moved to BFL.ClassUtils
local function GetClassFileFromClassName(className)
	return BFL.ClassUtils:GetClassFileFromClassName(className)
end

-- Get class file for friend (optimized for 11.2.7+)
local function GetClassFileForFriend(friend)
	return BFL.ClassUtils:GetClassFileForFriend(friend)
end

local function GetAccountClassFile(account)
	if not account then
		return nil
	end

	if account.classID and account.classID > 0 and C_CreatureInfo and C_CreatureInfo.GetClassInfo then
		local info = C_CreatureInfo.GetClassInfo(account.classID)
		if info and info.classFile then
			return info.classFile
		end
	end

	if account.className and BFL.ClassUtils then
		return BFL.ClassUtils:GetClassFileFromClassName(account.className)
	end

	return nil
end

-- Build display data for a single game account (shared by menus/tooltips)
function FriendsList:BuildAccountDisplay(gameAccountInfo)
	if not gameAccountInfo then
		return {
			text = "Unknown",
			isInvitable = false,
		}
	end

	local charName = gameAccountInfo.characterName or "Unknown"
	local realmName = gameAccountInfo.realmName or ""

	-- Resolve class file via classID (11.2.7+) or localized class name
	local classFile
	if gameAccountInfo.classID and gameAccountInfo.classID > 0 then
		if C_CreatureInfo and C_CreatureInfo.GetClassInfo then
			local info = C_CreatureInfo.GetClassInfo(gameAccountInfo.classID)
			if info and info.classFile then
				classFile = info.classFile
			end
		end
	end

	if not classFile and gameAccountInfo.className and BFL.ClassUtils then
		classFile = GetClassFileFromClassName(gameAccountInfo.className)
	end

	local coloredName = charName
	if classFile and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile] then
		coloredName = RAID_CLASS_COLORS[classFile]:WrapTextInColorCode(charName)
	end

	local text
	if realmName ~= "" then
		text = coloredName .. " - " .. realmName
	else
		text = coloredName
	end

	local restriction = gameAccountInfo.bflRestriction or gameAccountInfo.inviteRestriction
	local restrictionNone = INVITE_RESTRICTION_NONE
	local isInvitable

	if gameAccountInfo.bflIsInvitable ~= nil then
		isInvitable = gameAccountInfo.bflIsInvitable
	elseif restrictionNone then
		isInvitable = restriction == restrictionNone
	else
		isInvitable = restriction == nil
	end

	return {
		text = text,
		coloredName = coloredName,
		realmName = realmName,
		classFile = classFile,
		isInvitable = isInvitable and true or false,
		restriction = restriction,
		gameAccountID = gameAccountInfo.gameAccountID,
		playerGuid = gameAccountInfo.playerGuid,
		factionName = gameAccountInfo.factionName,
		projectID = gameAccountInfo.wowProjectID,
		gameMode = gameAccountInfo.classID,
		raw = gameAccountInfo,
	}
end

local function GetInviteRestrictionTextSafe(restriction)
	if BFL and BFL.GetInviteRestrictionText then
		return BFL.GetInviteRestrictionText(restriction)
	end
	return nil
end

-- ========================================
-- Module State
-- ========================================
FriendsList.friendsList = {} -- Raw friends data from API
FriendsList.searchText = "" -- Current search filter
FriendsList.filterMode = "all" -- Current filter mode: all, online, offline, wow, bnet
FriendsList.sortMode = "status" -- Current sort mode: status, name, level, zone

-- Reference to Groups
-- local friendGroups = {} -- MOVED TO TOP OF FILE

-- ========================================
-- Private Helper Functions
-- ========================================

-- Count table entries (replacement for tsize)
local function CountTableEntries(t)
	local count = 0
	for _ in pairs(t) do
		count = count + 1
	end
	return count
end

-- Get last online time text (from Blizzard's FriendsFrame)
local function GetLastOnlineTime(timeDifference)
	if not timeDifference then
		timeDifference = 0
	end

	timeDifference = time() - timeDifference

	if timeDifference < 60 then
		return LASTONLINE_SECS
	elseif timeDifference >= 60 and timeDifference < 3600 then
		return string.format(LASTONLINE_MINUTES, math.floor(timeDifference / 60))
	elseif timeDifference >= 3600 and timeDifference < 86400 then
		return string.format(LASTONLINE_HOURS, math.floor(timeDifference / 3600))
	elseif timeDifference >= 86400 and timeDifference < 2592000 then
		return string.format(LASTONLINE_DAYS, math.floor(timeDifference / 86400))
	elseif timeDifference >= 2592000 and timeDifference < 31536000 then
		return string.format(LASTONLINE_MONTHS, math.floor(timeDifference / 2592000))
	else
		return string.format(LASTONLINE_YEARS, math.floor(timeDifference / 31536000))
	end
end

local function GetLastOnlineText(accountInfo)
	if not accountInfo or not accountInfo.lastOnlineTime or accountInfo.lastOnlineTime == 0 then
		return FRIENDS_LIST_OFFLINE
	else
		return string.format(BNET_LAST_ONLINE_TIME, GetLastOnlineTime(accountInfo.lastOnlineTime))
	end
end

-- Get friend unique ID (matching BetterFriendlist.lua format)
local function GetFriendUID(friend)
	if not friend then
		return nil
	end
	if friend.type == "bnet" then
		-- Use battleTag as persistent identifier (bnetAccountID is temporary per session)
		-- CRITICAL: Check for non-empty string, not just truthy value
		if friend.battleTag and friend.battleTag ~= "" then
			-- Phase 9.7: UID Interning to reduce string garbage
			local tag = friend.battleTag
			local cached = uidCache[tag]
			if not cached then
				cached = "bnet_" .. tag
				uidCache[tag] = cached
			end
			return cached
		else
			-- Fallback to bnetAccountID only if battleTag is unavailable (should never happen)
			return "bnet_" .. tostring(friend.bnetAccountID or "unknown")
		end
	else
		-- WoW friends: Always use Name-Realm format for consistency
		local normalizedName = BFL:NormalizeWoWFriendName(friend.name)
		return normalizedName and ("wow_" .. normalizedName) or nil
	end
end

-- Resolve current BNet friend index by stable identifiers (index is not persistent)
function FriendsList:ResolveBNetFriendIndex(bnetAccountID, battleTag)
	local numBNet = BNGetNumFriends and select(1, BNGetNumFriends()) or 0
	if numBNet == 0 then
		return nil
	end

	local Compat = BFL and BFL.Compat
	local getInfo = Compat and Compat.GetBNetFriendInfo or (C_BattleNet and C_BattleNet.GetFriendAccountInfo)
	if not getInfo then
		return nil
	end

	for i = 1, numBNet do
		local accountInfo = getInfo(i)
		if accountInfo then
			if bnetAccountID and accountInfo.bnetAccountID == bnetAccountID then
				return i
			end
			if (not bnetAccountID) and battleTag and accountInfo.battleTag == battleTag then
				return i
			end
		end
	end

	return nil
end

-- Resolve current WoW friend index by name (index is not persistent)
function FriendsList:ResolveWoWFriendIndex(name)
	if not name then
		return nil
	end

	local numFriends = C_FriendList and C_FriendList.GetNumFriends and C_FriendList.GetNumFriends() or 0
	if numFriends == 0 then
		return nil
	end

	local targetName = BFL:NormalizeWoWFriendName(name)
	if not targetName then
		return nil
	end

	for i = 1, numFriends do
		local info = C_FriendList.GetFriendInfoByIndex(i)
		if info and info.name then
			local normalizedInfo = BFL:NormalizeWoWFriendName(info.name)
			if normalizedInfo == targetName then
				return i
			end
		end
	end

	return nil
end

-- Resolve current friend data by stable UID
function FriendsList:ResolveFriendByUID(uid)
	if not uid or not self.friendsList then
		return nil
	end

	for _, friend in ipairs(self.friendsList) do
		local friendUID = friend.uid or GetFriendUID(friend)
		if friendUID == uid then
			return friend
		end
	end

	return nil
end

-- Resolve the currently selected friend from UID (safe across list refreshes)
function FriendsList:ResolveSelectedFriend()
	return self:ResolveFriendByUID(self.selectedFriendUID)
end

-- Replace token case-insensitively in format string
local function ReplaceTokenCaseInsensitive(str, token, value)
	-- Create pattern that matches token case-insensitively
	local pattern = "%%"
	for i = 1, #token do
		local c = token:sub(i, i)
		if c:match("%a") then
			pattern = pattern .. "[" .. c:upper() .. c:lower() .. "]"
		else
			pattern = pattern .. c
		end
	end
	pattern = pattern .. "%%"

	-- Escape value for replacement
	local safeValue = value:gsub("%%", "%%%%")
	return str:gsub(pattern, safeValue)
end

-- Check if token exists case-insensitively
local function HasTokenCaseInsensitive(str, token)
	local pattern = "%%"
	for i = 1, #token do
		local c = token:sub(i, i)
		if c:match("%a") then
			pattern = pattern .. "[" .. c:upper() .. c:lower() .. "]"
		else
			pattern = pattern .. c
		end
	end
	pattern = pattern .. "%%"
	return str:find(pattern) ~= nil
end

-- ========================================
-- Info Line Formatting (Phase 22)
-- ========================================
local function CollectAdditionalGameAccounts(friend)
	if not friend then
		return nil
	end

	local accounts = friend.gameAccounts
	if not accounts or #accounts == 0 then
		return nil
	end

	local primaryGameAccountID = friend.gameAccountInfo and friend.gameAccountInfo.gameAccountID
	local primaryPlayerGuid = friend.gameAccountInfo and friend.gameAccountInfo.playerGuid

	local additional = {}
	for _, ga in ipairs(accounts) do
		local gaId = ga.gameAccountID
		local gaGuid = ga.playerGuid
		local isPrimary = (gaId and primaryGameAccountID and gaId == primaryGameAccountID)
			or (gaGuid and primaryPlayerGuid and gaGuid == primaryPlayerGuid)
			or ga == friend.gameAccountInfo

		if not isPrimary then
			additional[#additional + 1] = ga
		end
	end

	return additional
end

function ShouldShowMultiAccountRow(self, friend)
	if not self or not self.settingsCache then
		return false
	end

	if self.settingsCache.compactMode or self.settingsCache.infoDisabled then
		return false
	end

	if not self.settingsCache.showMultiAccountInfo then
		return false
	end

	if not friend or friend.type ~= "bnet" or not friend.connected then
		return false
	end

	local accounts = friend.gameAccounts
	local totalAccounts = friend.numGameAccounts or (accounts and #accounts) or 0
	if not accounts or #accounts == 0 then
		return false
	end

	return totalAccounts > 1
end

-- Helper: Get colored level text (used by info format system)
local function GetColoredLevelText(level)
	if not level or level == 0 then
		return ""
	end

	local color = GetQuestDifficultyColor and GetQuestDifficultyColor(level)
	if color then
		return string.format("|cff%02x%02x%02x%d|r", color.r * 255, color.g * 255, color.b * 255, level)
	end
	return tostring(level)
end

-- Build a short summary of online game accounts for the info line (BNet only)
local function BuildMultiAccountInfoLine(self, friend)
	if not self or not friend or friend.type ~= "bnet" then
		return nil
	end

	if not self.settingsCache or not self.settingsCache.showMultiAccountInfo then
		return nil
	end

	if not friend.connected then
		return nil
	end

	local accounts = friend.gameAccounts
	local totalAccounts = friend.numGameAccounts or (accounts and #accounts) or 0
	if not accounts or #accounts == 0 or totalAccounts <= 1 then
		return nil
	end

	local additionalAccounts = CollectAdditionalGameAccounts(friend)
	local additionalCount = totalAccounts - 1 -- exclude focus account from total
	if additionalCount <= 0 or not additionalAccounts or #additionalAccounts == 0 then
		return nil
	end

	local names = {}
	local maxNames = 2
	for _, ga in ipairs(additionalAccounts) do
		local display = self.BuildAccountDisplay and self:BuildAccountDisplay(ga)
		local nameText = display and (display.coloredName or display.text)
		if not nameText or nameText == "" then
			nameText = ga.characterName or ga.richPresence or ga.gameAccountName or ga.name
		end
		if nameText and nameText ~= "" then
			names[#names + 1] = nameText
		end
		if #names >= maxNames then
			break
		end
	end

	local infoText = "+" .. tostring(additionalCount)
	if #names > 0 then
		infoText = infoText .. " (" .. table.concat(names, ", ") .. ")"
	end

	local extraCount = additionalCount - #names
	if extraCount > 0 then
		local remainderFmt = (L and L.INFO_MULTI_ACCOUNT_REMAINDER) or " (+%d)"
		infoText = infoText .. string.format(remainderFmt, extraCount)
	end

	return infoText
end

local function BuildMultiAccountRowData(self, friend)
	if not ShouldShowMultiAccountRow(self, friend) then
		return nil
	end

	local accounts = CollectAdditionalGameAccounts(friend)
	local totalAccounts = friend.numGameAccounts or (friend.gameAccounts and #friend.gameAccounts) or 0
	local additionalCount = totalAccounts - 1
	if not accounts or #accounts == 0 or additionalCount <= 0 then
		return nil
	end

	local entries = {}
	for _, ga in ipairs(accounts) do
		local isWoW = ga.clientProgram == (BNET_CLIENT_WOW or "WoW")
		local nameText
		local display
		if isWoW then
			display = self.BuildAccountDisplay and self:BuildAccountDisplay(ga)
			nameText = display and (display.coloredName or display.text)
			if not nameText or nameText == "" then
				nameText = ga.characterName or "Unknown"
			end
		else
			-- Non-WoW: no character name, just richPresence
			nameText = ga.richPresence or ""
		end
		if nameText and nameText ~= "" then
			entries[#entries + 1] = {
				name = nameText,
				clientProgram = ga.clientProgram,
				classFile = display and display.classFile,
				level = ga.characterLevel,
				zone = ga.areaName or "",
				className = ga.className or "",
				raceName = ga.raceName or "",
				richPresence = ga.richPresence or "",
				wowProjectID = ga.wowProjectID,
				realmName = ga.realmName or "",
				gameAccountID = ga.gameAccountID,
			}
		end
		if #entries >= MAX_MULTI_ACCOUNT_ROW_ENTRIES then
			break
		end
	end

	local remainder = additionalCount - #entries
	if remainder < 0 then
		remainder = 0
	end

	return {
		entries = entries,
		remainder = remainder,
	}
end

-- Format the info line (line 2) using the info format system
-- Returns formatted string, or nil if info is disabled
function FriendsList:FormatInfoLine(friend)
	local infoPreset = self.settingsCache.infoFormatPreset or "default"

	local function AppendMultiAccountInfo(baseText)
		-- Skip info-line summary when the dedicated multi-account row is shown
		if ShouldShowMultiAccountRow(self, friend) then
			return baseText
		end
		local extra = BuildMultiAccountInfoLine(self, friend)
		if extra and extra ~= "" then
			if baseText and baseText ~= "" then
				return baseText .. " | " .. extra
			end
			return extra
		end
		return baseText
	end

	-- Disabled: No info line at all
	if infoPreset == "disabled" then
		return nil
	end

	local hideMaxLevel = self.settingsCache.hideMaxLevel
	local maxLevel = BFL.GetMaxLevel and BFL.GetMaxLevel() or 60

	-- Determine raw data values
	local isBNet = (friend.type == "bnet")
	local level = friend.level
	local zone = isBNet and friend.areaName or friend.area or ""
	local className = friend.className or ""
	local gameName = friend.gameName or ""
	local realmName = friend.realmName or ""
	local note = friend.note or friend.notes or ""
	local statusText = ""

	-- Status text (AFK/DND)
	if friend.isAFK or friend.afk then
		statusText = CHAT_FLAG_AFK or "AFK"
	elseif friend.isDND or friend.dnd then
		statusText = CHAT_FLAG_DND or "DND"
	elseif friend.connected then
		statusText = L.ONLINE_STATUS or "Online"
	else
		statusText = L.OFFLINE_STATUS or "Offline"
	end

	-- Last online text
	local lastOnlineText = ""
	if not friend.connected and friend.lastOnlineTime then
		lastOnlineText = GetLastOnlineText(friend) or ""
	end

	-- Level text (respects hideMaxLevel and colorLevelByDifficulty)
	local levelText = ""
	if level and level > 0 then
		if hideMaxLevel and level == maxLevel then
			levelText = ""
		else
			local colorByDifficulty = self.settingsCache.colorLevelByDifficulty
			if colorByDifficulty == nil then
				colorByDifficulty = true
			end
			if colorByDifficulty and friend.connected then
				levelText = GetColoredLevelText(level) or tostring(level)
			else
				levelText = tostring(level)
			end
		end
	end

	-- "default" preset: Use the original hardcoded logic
	if infoPreset == "default" then
		if friend.connected then
			if isBNet then
				-- BNet friend
				if level and zone and zone ~= "" then
					if hideMaxLevel and level == maxLevel then
						return AppendMultiAccountInfo(zone)
					else
						return AppendMultiAccountInfo(string.format(L.LEVEL_FORMAT, level) .. ", " .. zone)
					end
				elseif level then
					if hideMaxLevel and level == maxLevel then
						return AppendMultiAccountInfo(L.FRIEND_MAX_LEVEL or "")
					else
						return AppendMultiAccountInfo(string.format(L.LEVEL_FORMAT, level))
					end
				elseif zone and zone ~= "" then
					return AppendMultiAccountInfo(zone)
				elseif gameName and gameName ~= "" then
					return AppendMultiAccountInfo(gameName)
				else
					return AppendMultiAccountInfo(L.ONLINE_STATUS or "Online")
				end
			else
				-- WoW friend
				if level and zone and zone ~= "" then
					if hideMaxLevel and level == maxLevel then
						return zone
					else
						return string.format(L.LEVEL_FORMAT, level) .. ", " .. zone
					end
				elseif level then
					if hideMaxLevel and level == maxLevel then
						return L.FRIEND_MAX_LEVEL or ""
					else
						return string.format(L.LEVEL_FORMAT, level)
					end
				elseif zone and zone ~= "" then
					return zone
				else
					return L.ONLINE_STATUS or "Online"
				end
			end
		else
			-- Offline
			if isBNet then
				if friend.lastOnlineTime then
					return GetLastOnlineText(friend) or L.OFFLINE_STATUS or "Offline"
				else
					return L.OFFLINE_STATUS or "Offline"
				end
			else
				return L.OFFLINE_STATUS or "Offline"
			end
		end
	end

	-- Custom or preset format: Replace tokens
	local formatString
	if infoPreset == "custom" then
		formatString = self.settingsCache.infoFormatString or "%level%, %zone%"
	else
		local DB = GetDB()
		formatString = DB and DB:GetInfoFormatString() or "%level%, %zone%"
	end

	-- For offline friends with custom format, show last online or offline status
	if not friend.connected then
		if HasTokenCaseInsensitive(formatString, "lastonline") and lastOnlineText ~= "" then
			local result = ReplaceTokenCaseInsensitive(formatString, "lastonline", lastOnlineText)
			-- Clear other tokens that don't apply to offline friends
			result = ReplaceTokenCaseInsensitive(result, "level", "")
			result = ReplaceTokenCaseInsensitive(result, "zone", "")
			result = ReplaceTokenCaseInsensitive(result, "class", "")
			result = ReplaceTokenCaseInsensitive(result, "game", "")
			result = ReplaceTokenCaseInsensitive(result, "realm", "")
			result = ReplaceTokenCaseInsensitive(result, "note", note)
			result = ReplaceTokenCaseInsensitive(result, "status", statusText)
			-- Phase 22b: Unified tokens - name tokens in info format
			result = ReplaceTokenCaseInsensitive(
				result,
				"name",
				isBNet and (friend.accountName or "Unknown") or (friend.name or "Unknown")
			)
			result = ReplaceTokenCaseInsensitive(
				result,
				"battletag",
				friend.battleTag and (friend.battleTag:match("([^#]+)") or friend.battleTag) or ""
			)
			local DB = GetDB()
			local uid = friend.uid or GetFriendUID(friend)
			result = ReplaceTokenCaseInsensitive(result, "nickname", DB and DB:GetNickname(uid) or "")
			result = ReplaceTokenCaseInsensitive(result, "character", friend.characterName or "")
			-- Multi-Game-Account tokens (empty for offline)
			result = ReplaceTokenCaseInsensitive(result, "accounts", "")
			result = ReplaceTokenCaseInsensitive(result, "games", "")
			-- Cleanup empty delimiters
			result = result:gsub("%(%)", "")
			result = result:gsub("%[%]", "")
			result = result:gsub(",%s*,", ",")
			result = result:gsub("^%s*,%s*", "")
			result = result:gsub("%s*,%s*$", "")
			result = result:match("^%s*(.-)%s*$")
			if result == "" then
				return lastOnlineText ~= "" and lastOnlineText or (L.OFFLINE_STATUS or "Offline")
			end
			return result
		else
			return lastOnlineText ~= "" and lastOnlineText or (L.OFFLINE_STATUS or "Offline")
		end
	end

	-- Replace tokens for online friends
	local result = formatString
	result = ReplaceTokenCaseInsensitive(result, "level", levelText)
	result = ReplaceTokenCaseInsensitive(result, "zone", zone)
	result = ReplaceTokenCaseInsensitive(result, "class", className)
	result = ReplaceTokenCaseInsensitive(result, "game", gameName)
	result = ReplaceTokenCaseInsensitive(result, "realm", realmName)
	result = ReplaceTokenCaseInsensitive(result, "note", note)
	result = ReplaceTokenCaseInsensitive(result, "status", statusText)
	result = ReplaceTokenCaseInsensitive(result, "lastonline", "")
	-- Phase 22b: Unified tokens - name tokens in info format
	local nameValue = isBNet and (friend.accountName or "Unknown") or (friend.name or "Unknown")
	result = ReplaceTokenCaseInsensitive(result, "name", nameValue)
	local battletag = friend.battleTag and (friend.battleTag:match("([^#]+)") or friend.battleTag) or ""
	result = ReplaceTokenCaseInsensitive(result, "battletag", battletag)
	local DB = GetDB()
	local uid = friend.uid or GetFriendUID(friend)
	result = ReplaceTokenCaseInsensitive(result, "nickname", DB and DB:GetNickname(uid) or "")
	result = ReplaceTokenCaseInsensitive(result, "character", friend.characterName or friend.name or "")

	-- Multi-Game-Account tokens
	local accountCount = friend.numGameAccounts or (isBNet and 1 or 1)
	result = ReplaceTokenCaseInsensitive(result, "accounts", tostring(accountCount))

	local gamesText = ""
	if friend.gameAccounts and #friend.gameAccounts > 0 then
		local seen = {}
		local gameList = {}
		for _, ga in ipairs(friend.gameAccounts) do
			local gn = ga.richPresence or ga.clientProgram or ""
			if gn ~= "" and not seen[gn] then
				seen[gn] = true
				gameList[#gameList + 1] = gn
			end
		end
		gamesText = table.concat(gameList, ", ")
	elseif gameName ~= "" then
		gamesText = gameName
	end
	result = ReplaceTokenCaseInsensitive(result, "games", gamesText)

	-- Append multi-account summary only when no dedicated row is shown
	if not ShouldShowMultiAccountRow(self, friend) then
		local multiAccountInfo = BuildMultiAccountInfoLine(self, friend)
		if multiAccountInfo and multiAccountInfo ~= "" then
			if result ~= "" then
				result = result .. " | " .. multiAccountInfo
			else
				result = multiAccountInfo
			end
		end
	end

	-- Cleanup empty delimiters and extra commas/spaces
	result = result:gsub("%(%)", "")
	result = result:gsub("%[%]", "")
	result = result:gsub(",%s*,", ",")
	result = result:gsub("^%s*,%s*", "")
	result = result:gsub("%s*,%s*$", "")
	result = result:match("^%s*(.-)%s*$")

	if result == "" then
		return L.ONLINE_STATUS or "Online"
	end

	return result
end

-- Get display name based on format setting
-- @param forSorting (boolean) If true, use BattleTag instead of AccountName for BNet friends (prevents sorting issues with protected strings)
function FriendsList:GetDisplayName(friend, forSorting) -- PHASE 9.7: Display Name Caching (Persistent)
	-- PERFY OPTIMIZATION: Direct cache access
	-- [STREAMER MODE] Determine if active (used below to override %name%)
	local isStreamerMode = BFL.StreamerMode and BFL.StreamerMode:IsActive()
	local streamerNameFormat = isStreamerMode and (self.settingsCache.streamerModeNameFormat or "battletag") or nil

	if not self.displayNameCache then
		self.displayNameCache = {}
	end

	-- PERFY OPTIMIZATION: Direct cache access (Phase 22: Use preset system)
	local format = self.settingsCache.nameFormatString or "%name%"
	local uid = friend.uid or GetFriendUID(friend)
	local note = (friend.note or friend.notes or "")
	local showRealmName = self.settingsCache.showRealmName or false
	local colorClassNames = self.settingsCache.colorClassNames
	if colorClassNames == nil then
		colorClassNames = true
	end
	local showFactionIcons = self.settingsCache.showFactionIcons or false
	local nicknameVersion = BFL.NicknameCacheVersion or 0 -- Phase 6: Version Check

	-- Inputs for validation
	local rawName = friend.name
	local rawBattleTag = friend.battleTag
	local rawAccountName = friend.accountName

	-- CACHE CHECK (Persistent with Validation)
	if not self.displayNameCache[uid] then
		self.displayNameCache[uid] = {}
	end
	local modeKey = forSorting and 2 or 1
	local cacheEntry = self.displayNameCache[uid][modeKey]

	-- Check if cache is valid (inputs haven't changed)
	if
		cacheEntry
		and cacheEntry.format == format
		and cacheEntry.showRealmName == showRealmName
		and cacheEntry.colorClassNames == colorClassNames
		and cacheEntry.showFactionIcons == showFactionIcons
		and cacheEntry.isStreamerMode == isStreamerMode
		and cacheEntry.streamerNameFormat == streamerNameFormat
		and cacheEntry.note == note
		and cacheEntry.rawName == rawName
		and cacheEntry.rawAccountName == rawAccountName
		and cacheEntry.rawBattleTag == rawBattleTag
		and cacheEntry.nicknameVersion == nicknameVersion
		and cacheEntry.characterName == friend.characterName
	then -- Phase 6: Check version instead of value
		return cacheEntry.result
	end

	-- 1. Prepare Data (Only on Cache Miss)
	-- Fetch nickname now if we haven't already (lazy load)
	local DB = GetDB()
	local nickname = DB and DB:GetNickname(uid) or ""

	local name = "Unknown"
	local battletag = rawBattleTag or ""

	-- Process battletag to be short version (before #)
	if battletag ~= "" then
		local hashIndex = string.find(battletag, "#")
		if hashIndex then
			battletag = string.sub(battletag, 1, hashIndex - 1)
		end
	end

	if friend.type == "bnet" then
		if forSorting then
			-- SORTING MODE: Use BattleTag (Short) first
			if rawBattleTag and rawBattleTag ~= "" then
				local hashIndex = string.find(rawBattleTag, "#")
				if hashIndex then
					name = string.sub(rawBattleTag, 1, hashIndex - 1)
				else
					name = rawBattleTag
				end
			else
				name = rawAccountName or "Unknown"
			end
		elseif isStreamerMode then
			-- [STREAMER MODE] %name% must NEVER resolve to Real ID (accountName)
			-- Use safe alternatives based on streamer mode name format setting
			local streamerNameMode = self.settingsCache.streamerModeNameFormat or "battletag"
			if streamerNameMode == "nickname" then
				local nick = DB and DB:GetNickname(uid) or ""
				if nick ~= "" then
					name = nick
				else
					-- Fallback to BattleTag if no nickname set
					name = battletag ~= "" and battletag or "Unknown"
				end
			elseif streamerNameMode == "note" then
				if note ~= "" then
					name = note
				else
					name = battletag ~= "" and battletag or "Unknown"
				end
			else
				-- Default: BattleTag (short, already processed above)
				name = battletag ~= "" and battletag or "Unknown"
			end
		else
			-- DISPLAY MODE: Follow Blizzard's BNet_GetBNetAccountName pattern
			-- accountName is a kString. If nil/empty, fall back to short BattleTag.
			if rawAccountName then
				name = rawAccountName
			else
				-- Fallback: use short BattleTag (before #) like Blizzard does
				if rawBattleTag and rawBattleTag ~= "" then
					local hashIndex = string.find(rawBattleTag, "#")
					if hashIndex then
						name = string.sub(rawBattleTag, 1, hashIndex - 1)
					else
						name = rawBattleTag
					end
				else
					name = "Unknown"
				end
			end
		end
	else
		-- WoW: Name is Character Name
		local fullName = rawName or "Unknown"

		if showRealmName then
			name = fullName
		else
			local n, r = strsplit("-", fullName)
			local playerRealm = GetNormalizedRealmName()

			if r and r ~= playerRealm then
				name = n .. "*" -- Indicate cross-realm
			else
				name = n
			end
		end
	end

	-- 2. Replace Tokens (case-insensitive)
	local result = format

	-- Smart Fallback Logic:
	if
		nickname == ""
		and HasTokenCaseInsensitive(result, "nickname")
		and not HasTokenCaseInsensitive(result, "name")
	then
		nickname = name
	end
	if
		battletag == ""
		and HasTokenCaseInsensitive(result, "battletag")
		and not HasTokenCaseInsensitive(result, "name")
	then
		battletag = name
	end

	-- Replace tokens case-insensitively
	result = ReplaceTokenCaseInsensitive(result, "name", name)
	result = ReplaceTokenCaseInsensitive(result, "note", note)
	result = ReplaceTokenCaseInsensitive(result, "nickname", nickname)
	result = ReplaceTokenCaseInsensitive(result, "battletag", battletag)

	-- Phase 22b: Unified token system - all tokens available in name format
	local character = friend.characterName or ""
	local realm = friend.realmName or ""

	-- Apply class coloring, faction icon, timerunning, and realm to %character% token
	if character ~= "" and HasTokenCaseInsensitive(result, "character") and not forSorting then
		local decoratedChar = character

		-- Timerunning icon
		if friend.timerunningSeasonID and TimerunningUtil and TimerunningUtil.AddSmallIcon then
			decoratedChar = TimerunningUtil.AddSmallIcon(decoratedChar)
		end

		-- Faction icon
		local showFactionIcons = self.settingsCache.showFactionIcons
		if showFactionIcons and friend.factionName then
			if friend.factionName == "Horde" then
				decoratedChar = "|TInterface\\FriendsFrame\\PlusManz-Horde:12:12:0:0|t" .. decoratedChar
			elseif friend.factionName == "Alliance" then
				decoratedChar = "|TInterface\\FriendsFrame\\PlusManz-Alliance:12:12:0:0|t" .. decoratedChar
			end
		end

		-- Realm name
		if showRealmName and friend.realmName and friend.realmName ~= "" then
			local playerRealm = GetRealmName()
			if friend.realmName ~= playerRealm then
				decoratedChar = decoratedChar .. " - " .. friend.realmName
			end
		end

		-- Class coloring
		local useClassColor = self.settingsCache.colorClassNames
		if useClassColor == nil then
			useClassColor = true
		end
		local colorStr = nil
		if useClassColor and friend.className then
			local classFile = GetClassFileForFriend(friend)
			local classColor = classFile and RAID_CLASS_COLORS[classFile]
			if classColor then
				colorStr = classColor.colorStr or "ffffffff"
			end
		end

		-- Check if %character% is wrapped in parentheses: (%character%) → include parens in class coloring
		local wrappedPattern = "%(%%[Cc][Hh][Aa][Rr][Aa][Cc][Tt][Ee][Rr]%%%)"
		local wrapStart, wrapEnd = result:find(wrappedPattern)
		if wrapStart then
			-- Replace (%character%) with class-colored (CharName) - parens inside color
			local wrappedReplacement
			if colorStr then
				wrappedReplacement = "|c" .. colorStr .. "(" .. decoratedChar .. ")|r"
			else
				wrappedReplacement = "(" .. decoratedChar .. ")"
			end
			-- Use find+sub instead of gsub to avoid replacement string interpretation issues
			result = result:sub(1, wrapStart - 1) .. wrappedReplacement .. result:sub(wrapEnd + 1)
			-- Also replace any remaining standalone %character% tokens (unlikely but safe)
			if HasTokenCaseInsensitive(result, "character") then
				local standaloneReplacement = colorStr and ("|c" .. colorStr .. decoratedChar .. "|r") or decoratedChar
				result = ReplaceTokenCaseInsensitive(result, "character", standaloneReplacement)
			end
		else
			-- Standard replacement: class color without parens
			local replacement = colorStr and ("|c" .. colorStr .. decoratedChar .. "|r") or decoratedChar
			result = ReplaceTokenCaseInsensitive(result, "character", replacement)
		end
	else
		-- Empty character or forSorting: remove wrapping parens for empty character, then replace
		if character == "" then
			local wrappedPattern = "%(%%[Cc][Hh][Aa][Rr][Aa][Cc][Tt][Ee][Rr]%%%)"
			result = result:gsub(wrappedPattern, "")
		end
		result = ReplaceTokenCaseInsensitive(result, "character", character)
	end
	result = ReplaceTokenCaseInsensitive(result, "realm", realm)

	-- Info tokens available in name format (Phase 22b: Unified tokens)
	if not forSorting then
		local level = friend.level or 0
		local levelText = ""
		if level > 0 then
			local colorLevelByDifficulty = self.settingsCache.colorLevelByDifficulty
			if colorLevelByDifficulty == nil then
				colorLevelByDifficulty = true
			end
			if colorLevelByDifficulty then
				levelText = GetColoredLevelText(level)
			else
				levelText = tostring(level)
			end
		end
		local zone = friend.areaName or friend.area or ""
		local className = friend.className or ""
		local gameName = ""
		if friend.gameAccountInfo and friend.gameAccountInfo.richPresence then
			gameName = friend.gameAccountInfo.richPresence
		elseif friend.clientProgram then
			gameName = friend.clientProgram
		end

		result = ReplaceTokenCaseInsensitive(result, "level", levelText)
		result = ReplaceTokenCaseInsensitive(result, "zone", zone)
		result = ReplaceTokenCaseInsensitive(result, "class", className)
		result = ReplaceTokenCaseInsensitive(result, "game", gameName)
		result = ReplaceTokenCaseInsensitive(result, "status", "")
		result = ReplaceTokenCaseInsensitive(result, "lastonline", "")
	else
		result = ReplaceTokenCaseInsensitive(result, "level", "")
		result = ReplaceTokenCaseInsensitive(result, "zone", "")
		result = ReplaceTokenCaseInsensitive(result, "class", "")
		result = ReplaceTokenCaseInsensitive(result, "game", "")
		result = ReplaceTokenCaseInsensitive(result, "status", "")
		result = ReplaceTokenCaseInsensitive(result, "lastonline", "")
	end

	-- 3. Cleanup
	result = result:gsub("%(%)", "")
	result = result:gsub("%[%]", "")
	result = result:gsub(",%s*,", ",")
	result = result:gsub("^%s*,%s*", "")
	result = result:gsub("%s*,%s*$", "")
	result = result:match("^%s*(.-)%s*$")

	-- 4. Fallback
	if result == "" then
		result = name
	end

	-- Update Cache
	self.displayNameCache[uid][modeKey] = {
		result = result,
		format = format,
		showRealmName = showRealmName,
		colorClassNames = colorClassNames,
		showFactionIcons = showFactionIcons,
		isStreamerMode = isStreamerMode,
		streamerNameFormat = streamerNameFormat,
		note = note,
		nicknameVersion = nicknameVersion, -- Phase 6: Store version
		rawName = rawName,
		rawBattleTag = rawBattleTag,
		rawAccountName = rawAccountName,
		characterName = friend.characterName, -- Phase 22b: Cache invalidation for character changes
	}

	return result
end

-- Update "Send Message" button state based on selection
function FriendsList:UpdateSendMessageButton()
	local frame = BetterFriendsFrame
	if not frame or not frame.SendMessageButton then
		return
	end

	local button = frame.SendMessageButton
	local friend = self:ResolveSelectedFriend()

	if not friend then
		button:Disable()
		return
	end

	if friend.type == "wow" then
		if friend.connected then
			button:Enable()
		else
			button:Disable()
		end
	elseif friend.type == "bnet" then
		-- BNet friends can receive messages via app even if appearing offline/away
		-- Blizzard enables it for all BNet friends
		button:Enable()
	end
end

-- ========================================
-- Public API
-- ========================================

-- Initialize the module
function FriendsList:Initialize() -- Initialize sort modes and filter from database
	-- Guard against double initialization (Core.lua and BetterFriendlist.lua both call Initialize)
	-- Double init in Classic creates orphaned button frames that cause duplicate rendering
	if self.initialized then
		return
	end
	self.initialized = true

	local DB = BFL:GetModule("DB")
	local db = DB and DB:Get() or {}
	self.sortMode = db.primarySort or "status"
	self.secondarySort = db.secondarySort or "name"

	-- Compatibility: Prevent invalid state where Primary == Secondary
	if self.sortMode == self.secondarySort then
		self.secondarySort = "none"
		if DB then
			DB:Set("secondarySort", "none")
		end
		if BFL.FrameInitializer and BFL.FrameInitializer.SetSecondarySortMode_UI then
			BFL.FrameInitializer:SetSecondarySortMode_UI("none") -- Update UI if needed, though this runs early
		end
	end

	-- CRITICAL: Load filterMode from DB to ensure consistency
	self.filterMode = db.quickFilter or "all"

	-- Initialize settings cache
	self:UpdateSettingsCache()

	-- Sync groups from Groups module
	self:SyncGroups()

	-- Initialize ScrollBox system (NEW - Phase 1)
	self:InitializeScrollBox()

	-- Force Initial Layout (Fix for delayed SearchBox in Simple Mode)
	self:UpdateScrollBoxExtent()

	-- NOTE: We do NOT call UpdateFriendsList(true) here anymore.
	-- At ADDON_LOADED time, BNet data is often incomplete (missing battleTags),
	-- causing friends to appear under "No Group" until FRIENDLIST_UPDATE fires
	-- with complete data. The needsRenderOnShow flag (default: true) ensures
	-- the list renders correctly when the frame is first opened.

	-- PERFY OPTIMIZATION (Phase 2A): Use named function for timer
	-- Initialize responsive SearchBox width
	C_Timer.After(0.1, Timer_UpdateSearchBoxWidth)

	-- PERFY OPTIMIZATION (Phase 2A): Use pre-defined named event callbacks
	-- Register event callbacks for friend list updates
	BFL:RegisterEventCallback("FRIENDLIST_UPDATE", EventCallback_FriendListUpdate, 10)
	BFL:RegisterEventCallback("BN_FRIEND_LIST_SIZE_CHANGED", EventCallback_BNetFriendListSizeChanged, 10)
	BFL:RegisterEventCallback("BN_FRIEND_ACCOUNT_ONLINE", EventCallback_BNetAccountOnline, 10)
	BFL:RegisterEventCallback("BN_FRIEND_ACCOUNT_OFFLINE", EventCallback_BNetAccountOffline, 10)
	BFL:RegisterEventCallback("BN_FRIEND_INFO_CHANGED", EventCallback_BNetFriendInfoChanged, 10)

	-- Additional events from Blizzard's FriendsFrame
	BFL:RegisterEventCallback("BN_CONNECTED", EventCallback_BNetConnected, 10)
	BFL:RegisterEventCallback("BN_DISCONNECTED", EventCallback_BNetDisconnected, 10)
	BFL:RegisterEventCallback("GROUP_ROSTER_UPDATE", EventCallback_GroupRosterUpdate, 10)

	-- Register friend invite events
	BFL:RegisterEventCallback("BN_FRIEND_INVITE_LIST_INITIALIZED", EventCallback_BNetInviteListInitialized, 10)
	BFL:RegisterEventCallback("BN_FRIEND_INVITE_ADDED", EventCallback_BNetInviteAdded, 10)
	BFL:RegisterEventCallback("BN_FRIEND_INVITE_REMOVED", EventCallback_BNetInviteRemoved, 10)

	-- PERFY OPTIMIZATION (Phase 2A): Use named functions for HookScript
	-- Hook OnShow to re-render if data changed while hidden
	if BetterFriendsFrame then
		BetterFriendsFrame:HookScript("OnShow", HookScript_OnFrameShow)

		-- Also hook ScrollFrame OnShow for tab switching
		if BetterFriendsFrame.ScrollFrame then
			BetterFriendsFrame.ScrollFrame:HookScript("OnShow", HookScript_OnScrollFrameShow)
		end
	end

	-- Initialize font cache (Performance Optimization)
	self:UpdateFontCache()
end

-- Update cached font paths and colors to avoid lookups in render loop
function FriendsList:UpdateFontCache()
	if not self.fontCache then
		self.fontCache = {}
	end
	self.fontCacheVersion = (self.fontCacheVersion or 0) + 1

	local DB = GetDB()
	if not DB then
		return
	end

	-- Fix #35/#40: Track if font sizes changed to force layout rebuild
	local oldNameSize = self.fontCache.nameSize
	local oldInfoSize = self.fontCache.infoSize

	-- Function to safely get color table
	local function GetColor(key)
		local c = DB:Get(key)
		if c and c.r and c.g and c.b then
			return c.r, c.g, c.b, c.a or 1
		end
		-- Default fallbacks if DB is missing or corrupt
		if key == "fontColorFriendName" then
			return 1, 0.82, 0, 1
		end -- Gold/Yellow
		if key == "fontColorFriendInfo" then
			return 0.5, 0.5, 0.5, 1
		end -- Gray
		return 1, 1, 1, 1
	end

	-- Name Font
	local nameFontName = DB:Get("fontFriendName", "Friz Quadrata TT")
	self.fontCache.namePath = LSM:Fetch("font", nameFontName)
	self.fontCache.nameSize = DB:Get("fontSizeFriendName", 12)
	self.fontCache.nameOutline = DB:Get("fontOutlineFriendName", "NONE")
	self.fontCache.nameShadow = DB:Get("fontShadowFriendName", false)
	self.fontCache.nameR, self.fontCache.nameG, self.fontCache.nameB, self.fontCache.nameA =
		GetColor("fontColorFriendName")

	-- Info Font
	local infoFontName = DB:Get("fontFriendInfo", "Friz Quadrata TT")
	self.fontCache.infoPath = LSM:Fetch("font", infoFontName)
	self.fontCache.infoSize = DB:Get("fontSizeFriendInfo", 10)
	self.fontCache.infoOutline = DB:Get("fontOutlineFriendInfo", "NONE")
	self.fontCache.infoShadow = DB:Get("fontShadowFriendInfo", false)
	self.fontCache.infoR, self.fontCache.infoG, self.fontCache.infoB, self.fontCache.infoA =
		GetColor("fontColorFriendInfo")

	-- Fix #35/#40: Force layout rebuild if font sizes changed (affects row heights)
	if oldNameSize ~= self.fontCache.nameSize or oldInfoSize ~= self.fontCache.infoSize then
		self.forceLayoutRebuild = true
	end
end

-- Invalidate settings cache (called by DB:Set to ensure immediate UI response)
function FriendsList:InvalidateSettingsCache()
	self.settingsCacheVersion = nil
end

-- Update cached settings to avoid DB lookups in render loop
-- PERFY FIX: Version-based lazy loading - only rebuild if settings changed
function FriendsList:UpdateSettingsCache()
	local DB = GetDB()
	if not DB then
		return
	end

	-- Check if cache is already up-to-date
	local currentVersion = BFL.SettingsVersion or 1
	if self.settingsCacheVersion == currentVersion then
		return -- Cache still valid
	end

	-- Rebuild cache with new settings
	self.settingsCacheVersion = currentVersion
	self.settingsCache = self.settingsCache or {}

	-- Track layout-affecting settings for forceLayoutRebuild
	local oldInfoDisabled = self.settingsCache.infoDisabled
	local oldCompactMode = self.settingsCache.compactMode

	-- Core Display Settings (Phase 22: Preset system)
	self.settingsCache.nameDisplayFormat = DB:Get("nameDisplayFormat", "%name%") -- Legacy compat
	self.settingsCache.nameFormatString = DB:GetNameFormatString()
	self.settingsCache.infoFormatPreset = DB:Get("infoFormatPreset", "default")
	self.settingsCache.infoFormatString = DB:GetInfoFormatString()
	self.settingsCache.infoDisabled = DB:IsInfoDisabled()
	self.settingsCache.showRealmName = DB:Get("showRealmName", false)
	self.settingsCache.compactMode = DB:Get("compactMode", false)

	-- Force layout rebuild if row height-affecting settings changed
	if oldInfoDisabled ~= self.settingsCache.infoDisabled or oldCompactMode ~= self.settingsCache.compactMode then
		self.forceLayoutRebuild = true
	end

	-- Group Settings
	self.settingsCache.enableInGameGroup = DB:Get("enableInGameGroup", false)
	self.settingsCache.inGameGroupMode = DB:Get("inGameGroupMode", "same_game")
	self.settingsCache.hideEmptyGroups = DB:Get("hideEmptyGroups", false)
	self.settingsCache.accordionGroups = DB:Get("accordionGroups", false)

	-- Visual Settings
	self.settingsCache.grayOtherFaction = DB:Get("grayOtherFaction", false)
	self.settingsCache.showFactionIcons = DB:Get("showFactionIcons", false)
	self.settingsCache.colorClassNames = DB:Get("colorClassNames", true)
	self.settingsCache.hideMaxLevel = DB:Get("hideMaxLevel", false)
	self.settingsCache.colorLevelByDifficulty = DB:Get("colorLevelByDifficulty", true)
	self.settingsCache.showGameIcon = DB:Get("showGameIcon", true)
	self.settingsCache.showMobileAsAFK = DB:Get("showMobileAsAFK", false)
	self.settingsCache.treatMobileAsOffline = DB:Get("treatMobileAsOffline", false)
	self.settingsCache.enableFavoriteIcon = DB:Get("enableFavoriteIcon", true)
	self.settingsCache.favoriteIconStyle = DB:Get("favoriteIconStyle", "bfl")
	self.settingsCache.showFactionBg = DB:Get("showFactionBg", false)
	self.settingsCache.showMultiAccountBadge = DB:Get("showMultiAccountBadge", true)
	self.settingsCache.showMultiAccountInfo = DB:Get("showMultiAccountInfo", true)
	self.settingsCache.fontColorFriendInfo = DB:Get("fontColorFriendInfo") or { r = 0.5, g = 0.5, b = 0.5, a = 1 }

	-- Fix #35/#40: Font Size Settings for Dynamic Row Height
	self.settingsCache.fontSizeFriendName = DB:Get("fontSizeFriendName", 12)
	self.settingsCache.fontSizeFriendInfo = DB:Get("fontSizeFriendInfo", 10)

	-- Group Header Settings (Hot Path in UpdateGroupHeaderButton)
	self.settingsCache.headerCountFormat = DB:Get("headerCountFormat", "visible")
	self.settingsCache.groupHeaderAlign = DB:Get("groupHeaderAlign", "LEFT")
	self.settingsCache.showGroupArrow = DB:Get("showGroupArrow", true)
	self.settingsCache.groupArrowAlign = DB:Get("groupArrowAlign", "LEFT")

	-- Simple Mode Settings
	self.settingsCache.simpleMode = DB:Get("simpleMode", false)
	self.settingsCache.simpleModeShowSearch = DB:Get("simpleModeShowSearch", true)

	-- Streamer Mode Settings
	self.settingsCache.streamerModeNameFormat = DB:Get("streamerModeNameFormat", "battletag")

	-- Cache player faction for background rendering (Optimized Phase 4.1)
	self.playerFaction = UnitFactionGroup("player")
end

-- Handle friend list update events
function FriendsList:OnFriendListUpdate(forceImmediate) -- Event Coalescing (Micro-Throttling)
	-- Instead of updating immediately for every event, we schedule an update for the next frame.
	-- This handles "event bursts" (e.g. 50 friends coming online at once) by updating only once.

	-- Phase 2: Allow bypassing throttle for critical UI interactions (Invites)
	-- Also bypass until BNet data is fully ready (battleTags loaded) for instant population
	if forceImmediate or not self.bnetDataReady then
		if self.updateTimer then
			self.updateTimer:Cancel()
			self.updateTimer = nil
		end
		self:UpdateFriendsList()
		return
	end

	-- Phase 9.5 Strict Throttling:
	-- If frame is hidden, DO NOT allocate a timer or closure.
	-- Just mark as dirty (needsRenderOnShow) and return.
	-- This saves valid memory/CPU cycles during gameplay when frame is closed.
	if not BetterFriendsFrame or not BetterFriendsFrame:IsShown() then
		needsRenderOnShow = true
		return
	end

	if self.updateTimer then
		-- Timer already running, update will happen next frame
		return
	end

	-- PERFY OPTIMIZATION (Phase 2A): Use bound method instead of closure
	-- Schedule update with a small delay (0.1s) to batch multiple events
	-- This significantly reduces CPU usage during login or mass status changes
	self.updateTimer = C_Timer.After(0.1, Timer_UpdateFriendsList)
end

-- Sync groups from Groups module
function FriendsList:SyncGroups()
	local Groups = GetGroups()
	if Groups then
		friendGroups = Groups:GetAll()
	else
		-- Fallback: Use built-in groups
		friendGroups = {
			favorites = {
				id = "favorites",
				name = BFL.L.GROUP_FAVORITES,
				collapsed = false,
				builtin = true,
				order = 1,
				color = { r = 1.0, g = 0.82, b = 0.0 },
				icon = "Interface\\FriendsFrame\\Battlenet-Battleneticon",
			},
			nogroup = {
				id = "nogroup",
				name = BFL.L.GROUP_NO_GROUP,
				collapsed = false,
				builtin = true,
				order = 999,
				color = { r = 0.5, g = 0.5, b = 0.5 },
				icon = "Interface\\FriendsFrame\\UI-Toast-FriendOnlineIcon",
			},
		}
	end

	-- Feature: In-Game Group (Dynamic)
	-- Now handled by Groups module (Groups:GetAll filters it based on settings)
end

-- ========================================
-- Sorting Priority Calculation Helpers (Optimized)
-- ========================================

local function CalculateStatusPriority(friend)
	if not ((friend.type == "bnet" and friend.connected) or (friend.type == "wow" and friend.connected)) then
		return 3 -- Offline lowest priority
	end

	-- Check DND first (Priority 1)
	local isDND = false
	if friend.type == "bnet" then
		isDND = friend.isDND
			or (friend.gameAccountInfo and (friend.gameAccountInfo.isDND or friend.gameAccountInfo.isGameBusy))
	elseif friend.type == "wow" then
		isDND = friend.dnd
	end
	if isDND then
		return 1
	end

	-- Check AFK second (Priority 2)
	local isAFK = false
	if friend.type == "bnet" then
		isAFK = friend.isAFK
			or (friend.gameAccountInfo and (friend.gameAccountInfo.isAFK or friend.gameAccountInfo.isGameAFK))
		if friend.gameAccountInfo and friend.gameAccountInfo.clientProgram == "BSAp" then
			isAFK = true
		end
	elseif friend.type == "wow" then
		isAFK = friend.afk
	end
	if isAFK then
		return 2
	end

	return 0 -- Online (Priority 0)
end

local function CalculateGamePriority(friend)
	-- Offline = lowest priority
	if not ((friend.type == "bnet" and friend.connected) or (friend.type == "wow" and friend.connected)) then
		return 999
	end

	-- WoW-only friends: Check if same project as player
	if friend.type == "wow" then
		return 0 -- Always highest (same game by definition)
	end

	-- BNet friends: check clientProgram and wowProjectID
	if friend.type == "bnet" and friend.gameAccountInfo then
		local clientProgram = friend.gameAccountInfo.clientProgram
		local friendProjectID = friend.gameAccountInfo.wowProjectID

		-- WoW games: Use DYNAMIC wowProjectID prioritization
		if clientProgram == "WoW" and friendProjectID then
			-- Priority 0: Same WoW version as player
			if friendProjectID == WOW_PROJECT_ID then
				return 0 -- HIGHEST: Same version
			end

			-- Priority 1-99: Other WoW versions (sorted by projectID)
			return friendProjectID -- Natural priority based on projectID
		end

		-- Non-WoW Blizzard games: Lower priority
		if clientProgram == "ANBS" then
			return 100
		end -- Diablo IV
		if clientProgram == "WTCG" then
			return 101
		end -- Hearthstone
		if clientProgram == "DIMAR" then
			return 102
		end -- Diablo Immortal
		if clientProgram == "Pro" then
			return 103
		end -- Overwatch 2
		if clientProgram == "S2" then
			return 104
		end -- StarCraft II
		if clientProgram == "D3" then
			return 105
		end -- Diablo III
		if clientProgram == "Hero" then
			return 106
		end -- Heroes of the Storm
		if clientProgram == "BSAp" or clientProgram == "App" then
			return 200
		end -- Lowest priority (mobile/app)
		return 150 -- Unknown/Other games
	end

	return 999 -- Fallback (offline)
end

local function CalculateFactionPriority(friend)
	local playerFaction = UnitFactionGroup("player")

	-- Offline or non-WoW = lowest priority
	if not ((friend.type == "bnet" and friend.connected) or (friend.type == "wow" and friend.connected)) then
		return 3
	end

	local friendFaction = nil

	-- WoW-only friends
	if friend.type == "wow" and friend.factionName then
		friendFaction = friend.factionName
	end

	-- BNet friends playing WoW
	if friend.type == "bnet" and friend.gameAccountInfo then
		if friend.gameAccountInfo.clientProgram == "WoW" and friend.gameAccountInfo.factionName then
			friendFaction = friend.gameAccountInfo.factionName
		end
	end

	-- Priority logic
	if not friendFaction then
		return 3 -- No faction data
	elseif friendFaction == playerFaction then
		return 0 -- Same faction (highest priority)
	else
		return 1 -- Other faction
	end
end

local function CalculateGuildPriority(friend)
	local playerGuild = GetGuildInfo("player")
	local friendGuild = nil
	local isPlayingWoW = false

	-- WoW-only friends
	if friend.type == "wow" and friend.connected then
		isPlayingWoW = true
		friendGuild = GetGuildInfo(friend.name)
	end

	-- BNet friends playing WoW
	if friend.type == "bnet" and friend.gameAccountInfo then
		if friend.gameAccountInfo.clientProgram == "WoW" then
			isPlayingWoW = true
			friendGuild = friend.gameAccountInfo.guildName
		end
	end

	-- Not playing WoW = lowest priority
	if not isPlayingWoW then
		return 3, ""
	end

	-- Priority logic for WoW players
	if not friendGuild then
		return 2, "" -- No guild
	elseif playerGuild and friendGuild == playerGuild then
		return 0, friendGuild -- Same guild (highest)
	else
		return 1, friendGuild -- Other guild
	end
end

local TANK_CLASSES = { WARRIOR = 1, PALADIN = 1, DEATHKNIGHT = 1, DRUID = 1, MONK = 1, DEMONHUNTER = 1 }
local HEALER_CLASSES = { PRIEST = 1, PALADIN = 1, SHAMAN = 1, DRUID = 1, MONK = 1, EVOKER = 1 }

local function CalculateClassPriority(friend)
	-- Check if friend is actually playing WoW
	local isPlayingWoW = false
	if friend.type == "wow" and friend.connected then
		isPlayingWoW = true
	elseif friend.type == "bnet" and friend.gameAccountInfo and friend.gameAccountInfo.clientProgram == "WoW" then
		isPlayingWoW = true
	end

	-- Not playing WoW = lowest priority (below all DPS)
	if not isPlayingWoW then
		return 10, ""
	end

	-- friend.class already contains the English class file (WARRIOR, MAGE, etc.)
	local classFile = friend.class

	if not classFile or classFile == "" or classFile == "Unknown" then
		return 9, "" -- Playing WoW but no class
	end

	if TANK_CLASSES[classFile] and HEALER_CLASSES[classFile] then
		return 0, classFile -- Hybrid (tank priority)
	elseif TANK_CLASSES[classFile] then
		return 0, classFile -- Pure tank
	elseif HEALER_CLASSES[classFile] then
		return 1, classFile -- Pure healer
	else
		return 2, classFile -- DPS
	end
end

local function CalculateRealmPriority(friend)
	local playerRealm = GetRealmName()
	local friendRealm = nil

	-- WoW-only friends
	if friend.type == "wow" and friend.name then
		friendRealm = friend.name:match("-(.+)$") or playerRealm
	end

	-- BNet friends playing WoW
	if friend.type == "bnet" and friend.gameAccountInfo then
		if friend.gameAccountInfo.clientProgram == "WoW" then
			friendRealm = friend.gameAccountInfo.realmName or friend.realmName
		end
	end

	if not friendRealm then
		return 2, "" -- No realm (offline/non-WoW)
	elseif friendRealm == playerRealm then
		return 0, friendRealm -- Same realm
	else
		return 1, friendRealm -- Other realm
	end
end

-- Update the friends list from WoW API
function FriendsList:UpdateFriendsList(ignoreVisibility) -- Visibility Optimization:
	-- If the frame is hidden, we don't need to fetch data or rebuild the list.
	-- Just mark it as dirty so it updates when shown.
	if (not BetterFriendsFrame or not BetterFriendsFrame:IsShown()) and not ignoreVisibility then
		needsRenderOnShow = true
		isUpdatingFriendsList = false -- Ensure lock is released if it was somehow set
		return
	end

	-- Prevent concurrent updates
	if isUpdatingFriendsList then
		hasPendingUpdate = true
		return
	end

	isUpdatingFriendsList = true

	-- Update settings cache before processing
	self:UpdateSettingsCache()

	-- PHASE 9.6: Object Pooling Optimization
	-- Instead of wipe(self.friendsList), we overwrite existing entries to reduce garbage
	local listIndex = 0

	-- Helper to get next recycled object
	local function GetNextFriendObject()
		listIndex = listIndex + 1
		local f = self.friendsList[listIndex]
		if not f then
			f = {}
			self.friendsList[listIndex] = f
		else
			wipe(f)
		end
		return f
	end

	-- Sync groups first
	self:SyncGroups()

	-- Get Battle.net friends (Classic: May not be available)
	local bnetFriends = C_BattleNet.GetFriendNumGameAccounts and C_BattleNet.GetFriendAccountInfo or nil
	-- Classic safeguard: BNGetNumFriends may not exist
	if bnetFriends and BNGetNumFriends then
		local numBNetTotal, numBNetOnline = BNGetNumFriends()

		-- BNet data completeness check: After login/reload, the first API responses
		-- may lack battleTags (returns nil/empty). Without battleTags, friend UIDs
		-- won't match DB group assignments, causing all friends to show under "No Group".
		-- Skip this render and wait for the next FRIENDLIST_UPDATE with complete data.
		if not self.bnetDataReady then
			if numBNetTotal == 0 then
				-- After login/reload, BNGetNumFriends() may temporarily return 0
				-- even when the user has BNet friends (server data still loading).
				-- Don't trust zero immediately - schedule a fallback timer.
				-- If still 0 after 1s, user truly has no BNet friends.
				if not self.bnetZeroFallbackTimer then
					self.bnetZeroFallbackTimer = C_Timer.NewTimer(1.0, function()
						self.bnetZeroFallbackTimer = nil
						if not self.bnetDataReady then
							self.bnetDataReady = true
							self:UpdateFriendsList()
						end
					end)
				end
				-- Defer render until BNet data actually loads or fallback fires
				isUpdatingFriendsList = false
				return
			else
				local firstInfo = C_BattleNet.GetFriendAccountInfo(1)
				if firstInfo and firstInfo.battleTag and firstInfo.battleTag ~= "" then
					self.bnetDataReady = true
					-- Cancel zero fallback timer if it was pending from a previous call
					if self.bnetZeroFallbackTimer then
						self.bnetZeroFallbackTimer:Cancel()
						self.bnetZeroFallbackTimer = nil
					end
				else
					-- Data not ready yet - defer render
					needsRenderOnShow = true
					isUpdatingFriendsList = false
					return
				end
			end
		end

		for i = 1, numBNetTotal do
			local accountInfo = C_BattleNet.GetFriendAccountInfo(i)
			if accountInfo then
				local friend = GetNextFriendObject()

				friend.type = "bnet"
				friend.index = i
				friend.bnetAccountID = accountInfo.bnetAccountID
				-- Follow Blizzard's BNet_GetBNetAccountName pattern:
				-- accountName is a kString (|Kq..|k). Store nil if empty or "???" so display fallback triggers.
				local accName = accountInfo.accountName
				if accName == nil or accName == "" or accName == "???" then
					friend.accountName = nil
				else
					friend.accountName = accName
				end
				friend.battleTag = accountInfo.battleTag

				-- PHASE 9.6: Cache UID (Hot Path)
				-- CRITICAL: Check for non-empty string, not just truthy value
				if friend.battleTag and friend.battleTag ~= "" then
					friend.uid = "bnet_" .. friend.battleTag
				else
					friend.uid = "bnet_" .. (accountInfo.bnetAccountID or "unknown")
				end

				friend.connected = accountInfo.gameAccountInfo and accountInfo.gameAccountInfo.isOnline or false
				friend.note = accountInfo.note
				friend.isFavorite = accountInfo.isFavorite
				friend.gameAccountInfo = accountInfo.gameAccountInfo
				friend.lastOnlineTime = accountInfo.lastOnlineTime
				friend.isAFK = accountInfo.isAFK
				friend.isDND = accountInfo.isDND

				-- If they're playing WoW, get game info (EXACT COPY OF OLD LOGIC)
				if accountInfo.gameAccountInfo and accountInfo.gameAccountInfo.isOnline then
					local gameInfo = accountInfo.gameAccountInfo
					if gameInfo.clientProgram == "WoW" then
						-- DEBUG: Log raw data for analysis
						if BFL.DebugPrint then
							-- BFL:DebugPrint(string.format("BNet Friend: %s (Prog: %s, Proj: %s, Class: %s, Area: %s, Rich: %s)",
							-- 	tostring(gameInfo.characterName),
							-- 	tostring(gameInfo.clientProgram),
							-- 	tostring(gameInfo.wowProjectID),
							-- 	tostring(gameInfo.className),
							-- 	tostring(gameInfo.areaName),
							-- 	tostring(gameInfo.richPresence)
							-- ))
						end

						friend.characterName = gameInfo.characterName
						friend.className = gameInfo.className
						friend.classID = gameInfo.classID -- 11.2.7+: Store classID for optimized class color lookup
						friend.areaName = gameInfo.areaName
						-- friend.richPresence = gameInfo.richPresence -- REVERTED: Caused issues with zone display
						friend.level = gameInfo.characterLevel
						friend.realmName = gameInfo.realmName
						friend.factionName = gameInfo.factionName
						friend.timerunningSeasonID = gameInfo.timerunningSeasonID

						-- Classic Fix: Parse richPresence if areaName is missing (e.g. "Zone - Realm")
						if (not friend.areaName or friend.areaName == "") and gameInfo.richPresence then
							local richZone, richRealm = strsplit("-", gameInfo.richPresence)
							if richZone then
								friend.areaName = strtrim(richZone)
							end
							if richRealm and (not friend.realmName or friend.realmName == "") then
								friend.realmName = strtrim(richRealm)
							end
						end

						if gameInfo.timerunningSeasonID then
							friend.timerunningSeasonID = gameInfo.timerunningSeasonID
						end
					elseif gameInfo.clientProgram == "BSAp" then
						friend.gameName = BFL.L.STATUS_MOBILE
						-- Feature: Treat Mobile as Offline (Phase Feature Request)
						local treatMobileAsOffline = self.settingsCache.treatMobileAsOffline
						if treatMobileAsOffline then
							friend.connected = false -- Treat as offline for sorting/display
							friend.isMobileButTreatedOffline = true -- Flag for special display
						end
					elseif gameInfo.clientProgram == "App" then
						friend.gameName = BFL.L.STATUS_IN_APP
					else
						-- Non-WoW games (Overwatch, Diablo, Hearthstone, etc.): Use richPresence
						-- for info text, matching Blizzard's behavior (e.g., "Competitive: In Game")
						local richPresence = gameInfo.richPresence
						if richPresence and richPresence ~= "" then
							friend.gameName = richPresence
						else
							friend.gameName = gameInfo.clientProgram or BFL.L.UNKNOWN_GAME
						end
					end
				end

				-- PHASE 4 OPTIMIZATION: Pre-calculate Invite Status
				-- Moves O(N^2) complexity from Render Loop to Data Update
				-- Multi-Game-Account Support: Also stores all game accounts for richer display
				friend.canInvite = false
				friend.inviteAtlas = nil

				if friend.connected then
					local restriction = nil
					local numGameAccounts = C_BattleNet.GetFriendNumGameAccounts(i)

					-- Multi-Game-Account: Store count and collect all game account data
					friend.numGameAccounts = numGameAccounts

					local gameAccounts
					local invitableAccounts
					if numGameAccounts > 1 then
						gameAccounts = {}
						invitableAccounts = {}
					end

					local playerFactionGroup = UnitFactionGroup("player")

					for k = 1, numGameAccounts do
						local gameAccountInfo = C_BattleNet.GetFriendGameAccountInfo(i, k)
						if gameAccountInfo then
							-- Multi-Game-Account: Store account info (filter out App/CLNT/BSAp)
							if
								gameAccounts
								and gameAccountInfo.clientProgram ~= BNET_CLIENT_APP
								and gameAccountInfo.clientProgram ~= "CLNT"
								and gameAccountInfo.clientProgram ~= "BSAp"
							then
								gameAccounts[#gameAccounts + 1] = gameAccountInfo
							end

							-- Invite restriction check (original logic)
							if gameAccountInfo.clientProgram == BNET_CLIENT_WOW then
								local accountRestriction = nil
								if gameAccountInfo.wowProjectID and WOW_PROJECT_ID then
									if
										gameAccountInfo.wowProjectID == WOW_PROJECT_CLASSIC
										and WOW_PROJECT_ID ~= WOW_PROJECT_CLASSIC
									then
										accountRestriction = INVITE_RESTRICTION_WOW_PROJECT_CLASSIC
									elseif
										gameAccountInfo.wowProjectID == WOW_PROJECT_MAINLINE
										and WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE
									then
										accountRestriction = INVITE_RESTRICTION_WOW_PROJECT_MAINLINE
									elseif gameAccountInfo.wowProjectID ~= WOW_PROJECT_ID then
										accountRestriction = INVITE_RESTRICTION_WOW_PROJECT_ID
									elseif gameAccountInfo.realmID == 0 then
										accountRestriction = INVITE_RESTRICTION_INFO
									elseif not gameAccountInfo.isInCurrentRegion then
										accountRestriction = INVITE_RESTRICTION_REGION
									else
										-- Check faction restriction
										if gameAccountInfo.factionName ~= playerFactionGroup then
											if C_QuestSession and C_QuestSession.Exists() then
												accountRestriction = INVITE_RESTRICTION_QUEST_SESSION
											elseif
												C_PartyInfo
												and C_PartyInfo.CanFormCrossFactionParties
												and not C_PartyInfo.CanFormCrossFactionParties()
											then
												accountRestriction = INVITE_RESTRICTION_FACTION
											end
										end
										-- Check game mode restriction (Retail only)
										if not accountRestriction and not BFL.IsClassic then
											if CanInviteByGameMode and not CanInviteByGameMode(gameAccountInfo) then
												accountRestriction = INVITE_RESTRICTION_GAME_MODE
											end
										end
										-- If no sub-restriction found, this account is invitable
										if not accountRestriction then
											accountRestriction = INVITE_RESTRICTION_NONE
											if invitableAccounts then
												invitableAccounts[#invitableAccounts + 1] = gameAccountInfo
											end
										end
									end
								elseif gameAccountInfo.realmID == 0 then
									accountRestriction = INVITE_RESTRICTION_INFO
								elseif not gameAccountInfo.isInCurrentRegion then
									accountRestriction = INVITE_RESTRICTION_REGION
								elseif gameAccountInfo.realmID and gameAccountInfo.realmID ~= 0 then
									accountRestriction = INVITE_RESTRICTION_NONE
									if invitableAccounts then
										invitableAccounts[#invitableAccounts + 1] = gameAccountInfo
									end
								end

								-- Track best restriction across all accounts
								-- Store per-account restriction metadata for downstream display logic
								local restrictionValue = accountRestriction
								if not restrictionValue and INVITE_RESTRICTION_NO_GAME_ACCOUNTS then
									restrictionValue = INVITE_RESTRICTION_NO_GAME_ACCOUNTS
								end

								gameAccountInfo.bflRestriction = restrictionValue
								local restrictionNone = INVITE_RESTRICTION_NONE
								if restrictionNone then
									gameAccountInfo.bflIsInvitable = accountRestriction == restrictionNone
								else
									gameAccountInfo.bflIsInvitable = accountRestriction == nil
								end

								if accountRestriction then
									if not restriction or accountRestriction > (restriction or 0) then
										restriction = accountRestriction
									end
									if accountRestriction == INVITE_RESTRICTION_NONE and not invitableAccounts then
										-- Single-account shortcut: break early
										break
									end
								end
							else
								if not restriction then
									restriction = INVITE_RESTRICTION_CLIENT
								end
							end
						end
					end

					-- Store multi-account data on friend object
					friend.gameAccounts = gameAccounts
					friend.invitableAccounts = invitableAccounts
					friend.numInvitableAccounts = invitableAccounts and #invitableAccounts or 0

					-- Update numGameAccounts to filtered count (excludes App/CLNT/BSAp)
					if gameAccounts then
						friend.numGameAccounts = #gameAccounts
					end

					if not restriction then
						restriction = INVITE_RESTRICTION_NO_GAME_ACCOUNTS
					end

					-- Fix: If at least one account is invitable, the friend-level restriction
					-- must be NONE regardless of worse restrictions from other accounts
					-- (e.g. non-WoW App accounts or cross-faction accounts during quest sessions).
					-- The max-tracking can incorrectly override NONE (0) with a higher value.
					if restriction ~= INVITE_RESTRICTION_NONE and invitableAccounts and #invitableAccounts > 0 then
						restriction = INVITE_RESTRICTION_NONE
					end

					if restriction == INVITE_RESTRICTION_NONE then
						friend.canInvite = true

						-- Calculate Cross-Faction Atlas
						if not BFL.IsClassic then
							local isCrossFaction = accountInfo.gameAccountInfo
								and accountInfo.gameAccountInfo.factionName
								and accountInfo.gameAccountInfo.factionName ~= playerFactionGroup

							if isCrossFaction then
								if accountInfo.gameAccountInfo.factionName == "Horde" then
									friend.inviteAtlas = "horde"
								elseif accountInfo.gameAccountInfo.factionName == "Alliance" then
									friend.inviteAtlas = "alliance"
								end
							else
								friend.inviteAtlas = "default"
							end
						end
					end
				else
					friend.numGameAccounts = 0
				end

				-- Preferred Game Account Override:
				-- If the user has selected a preferred account for this friend,
				-- swap out the focused gameAccountInfo and re-derive character fields.
				if friend.connected and friend.gameAccounts and #friend.gameAccounts > 1 then
					local prefID = self:GetPreferredGameAccountID(friend.uid)
					if prefID then
						local prefAccount
						for _, ga in ipairs(friend.gameAccounts) do
							if ga.gameAccountID == prefID then
								prefAccount = ga
								break
							end
						end
						if prefAccount then
							-- Store original focused account for reference
							friend.originalGameAccountInfo = friend.gameAccountInfo
							friend.gameAccountInfo = prefAccount
							friend.hasPreferredAccountOverride = true

							-- Re-derive character fields from preferred account
							if prefAccount.clientProgram == "WoW" then
								friend.characterName = prefAccount.characterName
								friend.className = prefAccount.className
								friend.classID = prefAccount.classID
								friend.areaName = prefAccount.areaName
								friend.level = prefAccount.characterLevel
								friend.realmName = prefAccount.realmName
								friend.factionName = prefAccount.factionName
								friend.timerunningSeasonID = prefAccount.timerunningSeasonID
								friend.gameName = nil
								-- Classic richPresence fallback
								if (not friend.areaName or friend.areaName == "") and prefAccount.richPresence then
									local richZone, richRealm = strsplit("-", prefAccount.richPresence)
									if richZone then
										friend.areaName = strtrim(richZone)
									end
									if richRealm and (not friend.realmName or friend.realmName == "") then
										friend.realmName = strtrim(richRealm)
									end
								end
							elseif prefAccount.clientProgram == "BSAp" then
								friend.characterName = nil
								friend.className = nil
								friend.classID = nil
								friend.areaName = nil
								friend.level = nil
								friend.realmName = nil
								friend.gameName = BFL.L.STATUS_MOBILE
							else
								friend.characterName = nil
								friend.className = nil
								friend.classID = nil
								friend.areaName = nil
								friend.level = nil
								friend.realmName = nil
								local rp = prefAccount.richPresence
								friend.gameName = (rp and rp ~= "") and rp
									or (prefAccount.clientProgram or BFL.L.UNKNOWN_GAME)
							end

							-- Recalculate cross-faction atlas for preferred account
							if not BFL.IsClassic and friend.canInvite then
								local prefFactionGroup = UnitFactionGroup("player")
								local isCrossFaction = prefAccount.factionName
									and prefAccount.factionName ~= prefFactionGroup
								if isCrossFaction then
									if prefAccount.factionName == "Horde" then
										friend.inviteAtlas = "horde"
									elseif prefAccount.factionName == "Alliance" then
										friend.inviteAtlas = "alliance"
									end
								else
									friend.inviteAtlas = "default"
								end
							end
						else
							-- Preferred account no longer online/available, clear it silently
							-- (Do NOT call ClearPreferredGameAccount here as it triggers ForceRefresh recursion)
							local DB = BFL:GetModule("DB")
							if DB then
								DB:ClearPreferredGameAccount(friend.uid)
							end
						end
					end
				end
			end
		end
	end

	-- Classic fallback: If BNet APIs don't exist, mark data as ready immediately
	if not self.bnetDataReady then
		self.bnetDataReady = true
	end

	-- Get WoW friends
	local numWoWFriends = C_FriendList.GetNumFriends() or 0
	-- Optimization: Cache player realm to avoid repeated API calls in loop
	local playerRealm = GetNormalizedRealmName()

	for i = 1, numWoWFriends do
		local friendInfo = C_FriendList.GetFriendInfoByIndex(i)
		if friendInfo then
			-- Normalize name to always include realm for consistent identification
			local normalizedName = BFL:NormalizeWoWFriendName(friendInfo.name, playerRealm)

			if normalizedName then
				-- Extract realm name from normalized name (Name-Realm)
				local _, realmName = strsplit("-", normalizedName)

				-- Classic Fallback: Ensure area is populated
				-- C_FriendList might return nil area in some Classic versions
				local area = friendInfo.area
				if (not area or area == "") and BFL.IsClassic and GetFriendInfo then
					local _, _, _, classicArea = GetFriendInfo(i)
					area = classicArea
				end

				local friend = GetNextFriendObject()

				friend.type = "wow"
				friend.index = i
				friend.name = normalizedName -- Always includes realm: "Name-Realm"

				-- PHASE 9.6: Cache UID
				friend.uid = "wow_" .. normalizedName

				friend.realmName = realmName -- Explicitly store realm name for display
				friend.connected = friendInfo.connected
				friend.level = friendInfo.level
				friend.className = friendInfo.className
				friend.area = area
				friend.notes = friendInfo.notes
				friend.afk = friendInfo.afk
				friend.dnd = friendInfo.dnd
			end
		end
	end

	-- Clean up excess recycled objects
	for i = #self.friendsList, listIndex + 1, -1 do
		self.friendsList[i] = nil
	end

	-- PERFY OPTIMIZATION: Pre-calculate sort keys for ALL friends
	-- This prevents recalculation during the N*log(N) sort process (1000s of calls)
	-- We always calculate ALL keys because primary/secondary sort can switch instantly

	-- OPTIMIZATION (Phase 9.8): Selective Sort Key Calculation
	-- Only calculate expensive keys if they are actually used for sorting
	local primarySort = self.sortMode or "status"
	local secondarySort = self.secondarySort or "name"

	local needGame = (primarySort == "game" or secondarySort == "game")
	local needFaction = (primarySort == "faction" or secondarySort == "faction")
	local needGuild = (primarySort == "guild" or secondarySort == "guild")
	local needClass = (primarySort == "class" or secondarySort == "class")
	local needRealm = (primarySort == "realm" or secondarySort == "realm")
	local needZone = (primarySort == "zone" or secondarySort == "zone")

	for _, friend in ipairs(self.friendsList) do
		-- Status Priority (Always used)
		friend._sort_status = CalculateStatusPriority(friend)

		-- PERFY FIX: Calculate display name once to avoid duplicate GetDisplayName calls
		local displayName = self:GetDisplayName(friend, false) or "Unknown"
		friend.displayName = displayName

		-- Reuse for sorting (forSorting=true uses BattleTag short form for BNet)
		local nameForSort = (friend.type == "bnet" and friend.battleTag) and friend.battleTag:match("([^#]+)")
			or displayName
		friend._sort_name = nameForSort:lower()
		friend._sort_level = friend.level or 0
		friend._sort_accountCount = friend.numGameAccounts or 0

		-- Game Priority (For game sort)
		if needGame then
			friend._sort_game = CalculateGamePriority(friend)
		else
			friend._sort_game = nil
		end

		-- Faction Priority (For faction sort)
		if needFaction then
			friend._sort_faction = CalculateFactionPriority(friend)
		else
			friend._sort_faction = nil
		end

		-- Guild Priority (For guild sort)
		if needGuild then
			local gp, gName = CalculateGuildPriority(friend)
			friend._sort_guildPriority = gp
			friend._sort_guildName = gName and gName:lower() or ""
		else
			friend._sort_guildPriority = nil
			friend._sort_guildName = nil
		end

		-- Class Priority
		if needClass then
			local cp, cName = CalculateClassPriority(friend)
			friend._sort_classPriority = cp
			friend._sort_className = cName -- Already file string (WARRIOR etc)
		else
			friend._sort_classPriority = nil
			friend._sort_className = nil
		end

		-- Realm Priority
		if needRealm then
			local rp, rName = CalculateRealmPriority(friend)
			friend._sort_realmPriority = rp
			friend._sort_realmName = rName and rName:lower() or ""
		else
			friend._sort_realmPriority = nil
			friend._sort_realmName = nil
		end

		-- Zone Priority (Complex: Online+Zone > Online > Offline)
		local isOnline = ((friend.type == "bnet" and friend.connected) or (friend.type == "wow" and friend.connected))
		-- Needed for status checks anyway
		friend._sort_isOnline = isOnline

		if needZone then
			local zoneName = (friend.areaName or friend.area or "")
			local hasZone = isOnline and zoneName ~= ""
			friend._sort_hasZone = hasZone
			friend._sort_zoneName = zoneName:lower()
		else
			friend._sort_hasZone = nil
			friend._sort_zoneName = nil
		end

		-- Activity sort key (uses last online time from API)
		friend._sort_activity = friend.lastOnlineTime or 0
	end

	-- Apply filters and sort
	self:ApplyFilters()
	self:ApplySort()

	-- PERFY OPTIMIZATION (Phase 2B): Increment version AFTER data collection to prevent premature cache invalidation
	-- This ensures BuildDisplayList cache is only invalidated when data actually changed
	BFL.FriendsListVersion = (BFL.FriendsListVersion or 0) + 1

	-- CRITICAL FIX: Render the display after building list
	-- Without this, UI never updates after friend offline/online events
	self:RenderDisplay(ignoreVisibility)

	-- Update Send Message button state based on current selection status
	self:UpdateSendMessageButton()

	-- Release lock after update complete
	isUpdatingFriendsList = false

	-- PERFY FIX (Phase 23): Handle pending updates that were blocked during execution
	if hasPendingUpdate then
		hasPendingUpdate = false
		-- Re-run update immediately to show latest state
		self:UpdateFriendsList(ignoreVisibility)
	end
end

-- Clear pending update flag (used by ForceRefreshFriendsList to prevent race conditions)
function FriendsList:ClearPendingUpdate()
	hasPendingUpdate = false
end

-- Apply search and filter to friends list
function FriendsList:ApplyFilters() -- Filter is applied in RenderDisplay / BuildDataProvider
end

local compareByMode = {
	status = function(a, b)
		if a._sort_isOnline ~= b._sort_isOnline then
			return a._sort_isOnline
		end
		local aP = a._sort_status or 3
		local bP = b._sort_status or 3
		if aP ~= bP then
			return aP < bP
		end
		return nil
	end,
	name = function(a, b)
		local aName = a._sort_name or ""
		local bName = b._sort_name or ""
		if aName ~= bName then
			return aName < bName
		end
		return nil
	end,
	level = function(a, b)
		local aLevel = a._sort_level or 0
		local bLevel = b._sort_level or 0
		if aLevel ~= bLevel then
			return aLevel > bLevel
		end
		return nil
	end,
	zone = function(a, b)
		if a._sort_hasZone ~= b._sort_hasZone then
			return a._sort_hasZone
		end
		if a._sort_hasZone then
			if a._sort_zoneName ~= b._sort_zoneName then
				return a._sort_zoneName < b._sort_zoneName
			end
			return nil
		end
		if a._sort_isOnline ~= b._sort_isOnline then
			return a._sort_isOnline
		end
		return nil
	end,
	activity = function(a, b)
		local aTime = a._sort_activity or 0
		local bTime = b._sort_activity or 0
		if aTime ~= bTime then
			return aTime > bTime
		end
		return nil
	end,
	game = function(a, b)
		local aP = a._sort_game or 999
		local bP = b._sort_game or 999
		if aP ~= bP then
			return aP < bP
		end
		return nil
	end,
	faction = function(a, b)
		local aP = a._sort_faction or 3
		local bP = b._sort_faction or 3
		if aP ~= bP then
			return aP < bP
		end
		return nil
	end,
	guild = function(a, b)
		local aP = a._sort_guildPriority or 3
		local bP = b._sort_guildPriority or 3
		if aP ~= bP then
			return aP < bP
		end
		if aP == 1 then
			if a._sort_guildName ~= b._sort_guildName then
				return a._sort_guildName < b._sort_guildName
			end
		end
		return nil
	end,
	class = function(a, b)
		local aP = a._sort_classPriority or 10
		local bP = b._sort_classPriority or 10
		if aP ~= bP then
			return aP < bP
		end
		if a._sort_className ~= b._sort_className then
			return a._sort_className < b._sort_className
		end
		return nil
	end,
	realm = function(a, b)
		local aP = a._sort_realmPriority or 2
		local bP = b._sort_realmPriority or 2
		if aP ~= bP then
			return aP < bP
		end
		if a._sort_realmName ~= b._sort_realmName then
			return a._sort_realmName < b._sort_realmName
		end
		return nil
	end,
}

local currentPrimaryComparator = nil
local currentSecondaryComparator = nil
local currentNameComparator = nil

-- Optimized comparator to avoid closure allocation
local function SortComparator(a, b)
	if currentPrimaryComparator then
		local primaryResult = currentPrimaryComparator(a, b)
		if primaryResult ~= nil then
			return primaryResult
		end
	end

	-- Primary sort is equal (Same Group): Prioritize Favorites
	if a.isFavorite ~= b.isFavorite then
		return a.isFavorite
	end

	-- If primary sort is equal, use secondary sort
	if currentSecondaryComparator and currentSecondaryComparator ~= currentPrimaryComparator then
		local secondaryResult = currentSecondaryComparator(a, b)
		if secondaryResult ~= nil then
			return secondaryResult
		end
	end

	-- FALLBACK FOR OFFLINE FRIENDS: Sort by Last Online Time
	local aOffline = not a._sort_isOnline
	local bOffline = not b._sort_isOnline
	if aOffline and bOffline then
		local aTime = a.lastOnlineTime or 0
		local bTime = b.lastOnlineTime or 0
		if aTime ~= bTime then
			return aTime > bTime
		end
	end

	-- Fallback: sort by name
	if currentNameComparator then
		local fallbackResult = currentNameComparator(a, b)
		if fallbackResult ~= nil then
			return fallbackResult
		end
	end

	-- Ultimate fallback: stable sort by ID/Index
	return (a.index or 0) < (b.index or 0)
end

-- Apply sort order to friends list (with primary and secondary sort)
function FriendsList:ApplySort() -- Store sort modes for the static comparator
	self.currentPrimarySort = self.sortMode
	self.currentSecondarySort = self.secondarySort or "name"
	self.currentPrimaryComparator = compareByMode[self.currentPrimarySort]
	self.currentSecondaryComparator = compareByMode[self.currentSecondarySort]
	self.currentNameComparator = compareByMode.name
	currentPrimaryComparator = self.currentPrimaryComparator
	currentSecondaryComparator = self.currentSecondaryComparator
	currentNameComparator = self.currentNameComparator

	-- Use static comparator to avoid closure allocation (Phase 9.4 Optimization)
	table.sort(self.friendsList, SortComparator)
end

-- Compare two friends by a specific sort mode (returns true, false, or nil if equal)
-- Compare two friends by a specific sort mode (Optimized)
function FriendsList:CompareFriends(a, b, sortMode)
	local comparator = compareByMode[sortMode]
	if comparator then
		return comparator(a, b)
	end
	return nil
end

-- Check if friend passes current filters
function FriendsList:PassesFilters(friend) -- Search text filter
	if self.searchText and self.searchText ~= "" then
		local searchNormalized = BFL:StripAccents(self.searchText)
		local found = false

		-- Helper function to check if a field contains the search text (accent-insensitive)
		local function contains(text)
			if text and text ~= "" and text ~= "???" then
				-- Fix #50: Skip kStrings (|K...|k) - these are Blizzard privacy-protected
				-- strings (Real Names) that cannot be searched programmatically.
				-- Calling lower() on them mangles the escape code |K -> |k.
				if text:sub(1, 2) == "|K" then
					return false
				end
				return BFL:StripAccents(text):find(searchNormalized, 1, true) ~= nil
			end
			return false
		end

		-- Search in multiple fields depending on friend type
		if friend.type == "bnet" then
			-- BNet friends: search in accountName, battleTag, characterName, realmName, note, nickname
			-- Note: accountName is a kString (Real Name) and will be skipped by contains()
			-- This is a Blizzard privacy limitation - Real Names cannot be searched
			local DB = GetDB()
			local uid = friend.uid or GetFriendUID(friend)
			local nickname = DB and DB:GetNickname(uid) or nil
			found = contains(friend.accountName)
				or contains(friend.battleTag)
				or contains(friend.characterName)
				or contains(friend.realmName)
				or contains(friend.note)
				or contains(nickname)
		else
			-- WoW friends: search in name, note
			found = contains(friend.name) or contains(friend.note)
		end

		-- If no match found in any field, filter out this friend
		if not found then
			return false
		end
	end

	-- Filter mode (use 'connected' field for both BNet and WoW friends)
	if self.filterMode == "online" then
		if not friend.connected then
			return false
		end
	elseif self.filterMode == "offline" then
		if friend.connected then
			return false
		end
	elseif self.filterMode == "wow" then
		if friend.type == "bnet" then
			-- BNet friend must be in WoW
			if not friend.connected or not friend.gameAccountInfo then
				return false
			end
			if friend.gameAccountInfo.clientProgram ~= BNET_CLIENT_WOW then
				return false
			end
		end
		-- WoW friends always pass
	elseif self.filterMode == "bnet" then
		if friend.type ~= "bnet" then
			return false
		end
	elseif self.filterMode == "hideafk" then
		-- Hide AFK/DND friends (show all friends, but hide those who are AFK or DND)
		if friend.type == "bnet" then
			-- CRITICAL: isAFK/isDND are on friend object directly, not in gameAccountInfo
			if friend.isAFK or friend.isDND then
				return false
			end
		elseif friend.type == "wow" then
			-- WoW friends have afk/dnd status fields (set during data collection)
			if friend.afk or friend.dnd then
				return false
			end
		end
	elseif self.filterMode == "retail" then
		-- Show only Retail/Mainline WoW friends
		if friend.type == "bnet" then
			-- BNet friend must be in WoW Retail
			if not friend.connected or not friend.gameAccountInfo then
				return false
			end
			if friend.gameAccountInfo.clientProgram ~= BNET_CLIENT_WOW then
				return false
			end
			-- Check if it's Retail (Mainline)
			if friend.gameAccountInfo.wowProjectID and friend.gameAccountInfo.wowProjectID ~= WOW_PROJECT_MAINLINE then
				return false
			end
		end
		-- WoW friends are assumed to be on same version as player
	end

	return true
end

-- Get friend UID (public helper)
function FriendsList:GetFriendUID(friend)
	return GetFriendUID(friend)
end

function FriendsList:GetLastInvitedAccountID(friendUID)
	local DB = BFL:GetModule("DB")
	if not DB then
		return nil
	end

	return DB:GetLastInvitedAccount(friendUID)
end

function FriendsList:SetLastInvitedAccountID(friendUID, gameAccountID)
	local DB = BFL:GetModule("DB")
	if not DB then
		return
	end

	DB:SetLastInvitedAccount(friendUID, gameAccountID)
end

-- Preferred Game Account: user-selected account override for display
function FriendsList:GetPreferredGameAccountID(friendUID)
	local DB = BFL:GetModule("DB")
	if not DB then
		return nil
	end
	return DB:GetPreferredGameAccount(friendUID)
end

function FriendsList:SetPreferredGameAccount(friendUID, gameAccountID)
	local DB = BFL:GetModule("DB")
	if not DB then
		return
	end
	DB:SetPreferredGameAccount(friendUID, gameAccountID)
	BFL:ForceRefreshFriendsList()
end

function FriendsList:ClearPreferredGameAccount(friendUID)
	local DB = BFL:GetModule("DB")
	if not DB then
		return
	end
	DB:ClearPreferredGameAccount(friendUID)
	BFL:ForceRefreshFriendsList()
end

-- Show account picker dropdown on the game icon for switching preferred game account
function FriendsList:ShowGameAccountPicker(anchorFrame, friend)
	if not friend or not friend.gameAccounts or #friend.gameAccounts <= 1 then
		return
	end

	local friendUID = friend.uid or GetFriendUID(friend)
	if not friendUID then
		return
	end

	local currentPrefID = self:GetPreferredGameAccountID(friendUID)

	-- Retail: Use MenuUtil
	if MenuUtil and MenuUtil.CreateContextMenu then
		MenuUtil.CreateContextMenu(anchorFrame, function(ownerRegion, rootDescription)
			-- Header: Friend display name (respects name formatting & Streamer Mode)
			rootDescription:CreateTitle(self:GetDisplayName(friend))

			local function IsSelected(gaID)
				if gaID == "default" then
					return currentPrefID == nil
				end
				return currentPrefID == gaID
			end

			local function SetSelected(gaID)
				if gaID == "default" then
					self:ClearPreferredGameAccount(friendUID)
				else
					self:SetPreferredGameAccount(friendUID, gaID)
				end
			end

			-- "Default (Server)" option
			local defaultText = (L and L.MENU_DEFAULT_FOCUS) or "Default (Server)"
			rootDescription:CreateRadio(defaultText, IsSelected, SetSelected, "default")

			rootDescription:CreateDivider()

			-- List all game accounts (excluding App/CLNT/BSAp)
			for _, ga in ipairs(friend.gameAccounts) do
				if ga.clientProgram ~= "App" and ga.clientProgram ~= "CLNT" and ga.clientProgram ~= "BSAp" then
					local isWoW = ga.clientProgram == (BNET_CLIENT_WOW or "WoW")
					local label
					if isWoW then
						local display = self:BuildAccountDisplay(ga)
						label = display and (display.coloredName or display.text) or ga.characterName or "Unknown"
						if ga.areaName and ga.areaName ~= "" then
							label = label .. " - " .. ga.areaName
						end
					else
						-- Non-WoW: just richPresence, no character name
						label = ga.richPresence or ga.clientProgram or "Unknown"
					end

					-- Prepend game icon
					label = BFL:GetClientEmbeddedIcon(ga.clientProgram, 16) .. label

					rootDescription:CreateRadio(label, IsSelected, SetSelected, ga.gameAccountID)
				end
			end
		end)
		return
	end

	-- Classic: Use UIDropDownMenu
	if UIDropDownMenu_Initialize and ToggleDropDownMenu then
		if not BFL.GameAccountPickerDropdown then
			BFL.GameAccountPickerDropdown =
				CreateFrame("Frame", "BFL_GameAccountPickerDropdown", UIParent, "UIDropDownMenuTemplate")
		end

		UIDropDownMenu_Initialize(BFL.GameAccountPickerDropdown, function(self, level)
			-- Header: Friend display name (respects name formatting & Streamer Mode)
			local titleInfo = UIDropDownMenu_CreateInfo()
			titleInfo.text = FriendsList:GetDisplayName(friend)
			titleInfo.isTitle = true
			titleInfo.notCheckable = true
			UIDropDownMenu_AddButton(titleInfo, level)

			-- Default option
			local defaultInfo = UIDropDownMenu_CreateInfo()
			defaultInfo.text = (L and L.MENU_DEFAULT_FOCUS) or "Default (Server)"
			defaultInfo.checked = (currentPrefID == nil)
			defaultInfo.func = function()
				FriendsList:ClearPreferredGameAccount(friendUID)
				CloseDropDownMenus()
			end
			UIDropDownMenu_AddButton(defaultInfo, level)

			-- Game accounts
			for _, ga in ipairs(friend.gameAccounts) do
				if ga.clientProgram ~= "App" and ga.clientProgram ~= "CLNT" and ga.clientProgram ~= "BSAp" then
					local isWoW = ga.clientProgram == (BNET_CLIENT_WOW or "WoW")
					local label
					if isWoW then
						local display = FriendsList:BuildAccountDisplay(ga)
						label = display and (display.coloredName or display.text) or ga.characterName or "Unknown"
						if ga.areaName and ga.areaName ~= "" then
							label = label .. " - " .. ga.areaName
						end
					else
						-- Non-WoW: just richPresence, no character name
						label = ga.richPresence or ga.clientProgram or "Unknown"
					end

					-- Prepend game icon
					label = BFL:GetClientEmbeddedIcon(ga.clientProgram, 16) .. label

					local info = UIDropDownMenu_CreateInfo()
					info.text = label
					info.checked = (currentPrefID ~= nil and ga.gameAccountID == currentPrefID)
					local gaID = ga.gameAccountID
					info.func = function()
						FriendsList:SetPreferredGameAccount(friendUID, gaID)
						CloseDropDownMenus()
					end
					UIDropDownMenu_AddButton(info, level)
				end
			end
		end, "MENU")

		ToggleDropDownMenu(1, nil, BFL.GameAccountPickerDropdown, anchorFrame, 0, 0)
	end
end

-- Set search text
function FriendsList:SetSearchText(text)
	local newText = text or ""
	if self.searchText == newText then
		return
	end
	self.searchText = newText
	BFL:ForceRefreshFriendsList()
end

-- Set filter mode
function FriendsList:SetFilterMode(mode)
	local newMode = mode or "all"
	if self.filterMode == newMode then
		return
	end
	self.filterMode = newMode

	-- Save to database
	local DB = BFL:GetModule("DB")
	if DB then
		local db = DB:Get()
		db.quickFilter = self.filterMode
	end

	BFL:ForceRefreshFriendsList()
end

-- Set sort mode
function FriendsList:SetSortMode(mode)
	local newMode = mode or "status"
	if self.sortMode == newMode then
		return
	end
	self.sortMode = newMode

	-- Compatibility: If new Primary matches Secondary, reset Secondary to 'none'
	-- This prevents parallel sorting on the same criteria
	if self.secondarySort == newMode then
		self:SetSecondarySortMode("none")
	end

	-- Save to database
	local DB = BFL:GetModule("DB")
	if DB then
		local db = DB:Get()
		db.primarySort = self.sortMode
	end

	self:ApplySort()
	BFL:ForceRefreshFriendsList()
end

-- Set secondary sort mode (for multi-criteria sorting)
function FriendsList:SetSecondarySortMode(mode)
	if self.secondarySort == mode then
		return
	end

	-- Prevent parallel sorting: Cannot set Secondary to same as Primary
	if mode == self.sortMode and mode ~= "none" then
		return
	end

	self.secondarySort = mode

	-- Save to database
	local DB = BFL:GetModule("DB")
	if DB then
		local db = DB:Get()
		db.secondarySort = self.secondarySort
	end

	self:ApplySort()
	BFL:ForceRefreshFriendsList()
end

-- Helper to populate the Sort menu for the Contacts menu
function FriendsList:PopulateSortMenu(rootDescription, sortType)
	local L = BFL.L
	local FrameInitializer = BFL.FrameInitializer
	local UI = BFL.UI

	-- Sort Icons (mirrored from FrameInitializer)
	local SORT_ICONS = {
		status = "Interface\\AddOns\\BetterFriendlist\\Icons\\status",
		name = "Interface\\AddOns\\BetterFriendlist\\Icons\\name",
		level = "Interface\\AddOns\\BetterFriendlist\\Icons\\level",
		zone = "Interface\\AddOns\\BetterFriendlist\\Icons\\zone",
		game = "Interface\\AddOns\\BetterFriendlist\\Icons\\game",
		faction = "Interface\\AddOns\\BetterFriendlist\\Icons\\faction",
		guild = "Interface\\AddOns\\BetterFriendlist\\Icons\\guild",
		class = "Interface\\AddOns\\BetterFriendlist\\Icons\\class",
		realm = "Interface\\AddOns\\BetterFriendlist\\Icons\\realm",
		none = "Interface\\BUTTONS\\UI-GroupLoot-Pass-Up",
	}

	local function FormatIconText(iconData, text)
		return string.format("\124T%s:16:16:0:0\124t %s", iconData, text)
	end

	if sortType == "primary" then
		local function IsPrimarySelected(mode)
			return self.sortMode == mode
		end

		local function SetPrimarySelected(mode)
			self:SetSortMode(mode)
		end

		local function CreatePrimaryRadio(root, text, mode)
			root:CreateRadio(text, IsPrimarySelected, SetPrimarySelected, mode)
		end

		CreatePrimaryRadio(rootDescription, FormatIconText(SORT_ICONS.status, L.SORT_STATUS), "status")
		CreatePrimaryRadio(rootDescription, FormatIconText(SORT_ICONS.name, L.SORT_NAME), "name")
		CreatePrimaryRadio(rootDescription, FormatIconText(SORT_ICONS.level, L.SORT_LEVEL), "level")
		CreatePrimaryRadio(rootDescription, FormatIconText(SORT_ICONS.zone, L.SORT_ZONE), "zone")
		CreatePrimaryRadio(rootDescription, FormatIconText(SORT_ICONS.game, L.SORT_GAME), "game")
		CreatePrimaryRadio(rootDescription, FormatIconText(SORT_ICONS.faction, L.SORT_FACTION), "faction")
		CreatePrimaryRadio(rootDescription, FormatIconText(SORT_ICONS.guild, L.SORT_GUILD), "guild")
		CreatePrimaryRadio(rootDescription, FormatIconText(SORT_ICONS.class, L.SORT_CLASS), "class")
		CreatePrimaryRadio(rootDescription, FormatIconText(SORT_ICONS.realm, L.SORT_REALM), "realm")
	elseif sortType == "secondary" then
		local function IsSecondarySelected(mode)
			return self.secondarySort == mode
		end

		local function SetSecondarySelected(mode)
			self:SetSecondarySortMode(mode)
		end

		local function CreateSecondaryRadio(root, text, mode)
			-- Prevent selecting same sort as Primary (except None)
			if mode ~= "none" and mode == self.sortMode then
				return
			end
			root:CreateRadio(text, IsSecondarySelected, SetSecondarySelected, mode)
		end

		CreateSecondaryRadio(rootDescription, FormatIconText(SORT_ICONS.none, L.SORT_NONE), "none")
		CreateSecondaryRadio(rootDescription, FormatIconText(SORT_ICONS.status, L.SORT_STATUS), "status")
		CreateSecondaryRadio(rootDescription, FormatIconText(SORT_ICONS.name, L.SORT_NAME), "name")
		CreateSecondaryRadio(rootDescription, FormatIconText(SORT_ICONS.level, L.SORT_LEVEL), "level")
		CreateSecondaryRadio(rootDescription, FormatIconText(SORT_ICONS.zone, L.SORT_ZONE), "zone")
		CreateSecondaryRadio(rootDescription, FormatIconText(SORT_ICONS.game, L.SORT_GAME), "game")
		CreateSecondaryRadio(rootDescription, FormatIconText(SORT_ICONS.faction, L.SORT_FACTION), "faction")
		CreateSecondaryRadio(rootDescription, FormatIconText(SORT_ICONS.guild, L.SORT_GUILD), "guild")
		CreateSecondaryRadio(rootDescription, FormatIconText(SORT_ICONS.class, L.SORT_CLASS), "class")
		CreateSecondaryRadio(rootDescription, FormatIconText(SORT_ICONS.realm, L.SORT_REALM), "realm")
	end
end

-- ========================================
-- Group Management API
-- ========================================

-- Helper: Get friends in a specific group (optimized for single group access)
function FriendsList:GetFriendsForGroup(targetGroupId)
	local groupFriends = {}
	local grouped = self.groupedFriends or self.cachedGroupedFriends
	if grouped and grouped[targetGroupId] then
		return grouped[targetGroupId]
	end

	local DB = GetDB()
	if not DB then
		return groupFriends
	end
	local enableInGameGroup = DB:Get("enableInGameGroup", false)
	local inGameGroupMode = DB:Get("inGameGroupMode", "same_game")
	local friendGroups = (BetterFriendlistDB and BetterFriendlistDB.friendGroups) or {}

	-- Get visible groups to check if favorites/ingame are actually enabled
	local Groups = GetGroups()
	local visibleGroups = Groups and Groups:GetAll() or {}
	local favoritesVisible = visibleGroups["favorites"] == true

	for _, friend in ipairs(self.friendsList) do
		-- Apply filters first
		if self:PassesFilters(friend) then
			local friendUID = GetFriendUID(friend)
			local isFavorite = (friend.type == "bnet" and friend.isFavorite)
			local isInTargetGroup = false
			local isInAnyGroup = false

			-- Check Favorites (only if Favorites group is visible/enabled)
			if isFavorite and favoritesVisible then
				if targetGroupId == "favorites" then
					isInTargetGroup = true
				end
				isInAnyGroup = true
			end

			-- Check In-Game Group
			if enableInGameGroup then
				local mode = inGameGroupMode
				local isInGame = false

				if mode == "any_game" then
					if friend.type == "wow" and friend.connected then
						isInGame = true
					elseif
						friend.type == "bnet"
						and friend.connected
						and friend.gameAccountInfo
						and friend.gameAccountInfo.isOnline
					then
						local client = friend.gameAccountInfo.clientProgram
						if client and client ~= "" and client ~= "App" and client ~= "BSAp" then
							isInGame = true
						end
					end
				else
					if friend.type == "wow" and friend.connected then
						isInGame = true
					elseif
						friend.type == "bnet"
						and friend.connected
						and friend.gameAccountInfo
						and friend.gameAccountInfo.clientProgram == BNET_CLIENT_WOW
					then
						if friend.gameAccountInfo.wowProjectID == WOW_PROJECT_ID then
							isInGame = true
						end
					end
				end

				if isInGame then
					if targetGroupId == "ingame" then
						isInTargetGroup = true
					end
					isInAnyGroup = true
				end
			end

			-- Check Custom Groups (only count groups that actually exist)
			local customGroups = friendGroups[friendUID] or {}
			for _, groupId in ipairs(customGroups) do
				if type(groupId) == "string" and visibleGroups[groupId] then
					if groupId == targetGroupId then
						isInTargetGroup = true
					end
					isInAnyGroup = true
				end
			end

			-- Check "No Group"
			if not isInAnyGroup and targetGroupId == "nogroup" then
				isInTargetGroup = true
			end

			if isInTargetGroup then
				table.insert(groupFriends, friend)
			end
		end
	end

	return groupFriends
end

-- Attempt optimized group toggle without full list rebuild
function FriendsList:OptimizedGroupToggle(groupId, expanding) -- Only possible on Retail (ScrollBox)
	if not self.scrollBox then
		return false
	end

	local dataProvider = self.scrollBox:GetDataProvider()
	if not dataProvider then
		return false
	end

	local headerData = nil
	local friendsToRemove = {}
	local foundHeader = false

	-- Scan provider to find header and children
	for _, data in dataProvider:Enumerate() do
		if not foundHeader then
			if data.buttonType == BUTTON_TYPE_GROUP_HEADER and data.groupId == groupId then
				headerData = data
				foundHeader = true

				-- If expanding, we just need the header, so we can stop scanning
				if expanding then
					break
				end
			end
		else
			-- We are in the group (Collapsing logic)
			if data.buttonType == BUTTON_TYPE_FRIEND and data.groupId == groupId then
				table.insert(friendsToRemove, data) -- Collect data to remove
			else
				-- Hit something else (another header or filtered out), stop
				break
			end
		end
	end

	if not headerData then
		return false
	end

	-- Update header state
	headerData.collapsed = not expanding

	if not expanding then
		-- COLLAPSING: Remove friends
		-- Depending on DataProvider implementation, Remove(data) is usually available
		if dataProvider.Remove then
			for _, data in ipairs(friendsToRemove) do
				dataProvider:Remove(data)
			end
		else
			-- Fallback if Remove(data) missing (unlikely on Retail)
			return false
		end
	else
		-- EXPANDING: Insert friends
		local friends = self:GetFriendsForGroup(groupId)

		-- Find insertion index
		local insertIndex = nil
		if dataProvider.FindIndex then
			insertIndex = dataProvider:FindIndex(headerData)
		end

		-- Fallback scan if needed
		if not insertIndex then
			local idx = 0
			for _, data in dataProvider:Enumerate() do
				idx = idx + 1
				if data == headerData then
					insertIndex = idx
					break
				end
			end
		end

		if insertIndex then
			insertIndex = insertIndex + 1 -- Start inserting AFTER header
			for _, friend in ipairs(friends) do
				dataProvider:InsertAtIndex({
					buttonType = BUTTON_TYPE_FRIEND,
					friend = friend,
					groupId = groupId,
					_hasMultiAccountRow = ShouldShowMultiAccountRow(self, friend),
				}, insertIndex)
				insertIndex = insertIndex + 1
			end
		else
			return false -- Should not happen header was found earlier
		end
	end

	-- Manually update header visual to reflect new state
	self.scrollBox:ForEachFrame(function(frame, elementData)
		if elementData == headerData then
			self:UpdateGroupHeaderButton(frame, elementData)
		end
	end)

	-- PERFY OPTIMIZATION (Phase 2B): Invalidate BuildDisplayList cache
	-- OptimizedGroupToggle bypasses BuildDisplayList, so cache is now stale
	self.lastBuildSignature = nil

	return true
end

-- Toggle group collapsed state (Optimized)
function FriendsList:ToggleGroup(groupId)
	local Groups = GetGroups()
	if not Groups then
		return
	end

	-- PERFY OPTIMIZATION: Direct cache access
	-- Handle Accordion Mode
	-- Note: We do this before the main toggle to clear others
	local accordionMode = self.settingsCache.accordionGroups or false
	local needsFullRefresh = false

	if accordionMode then
		local group = Groups:Get(groupId)
		-- If we are expanding a closed group
		if group and group.collapsed then
			for gid, gData in pairs(Groups.groups) do
				if gid ~= groupId and not gData.collapsed then
					-- Force collapse, suppress update
					Groups:SetCollapsed(gid, true, true)
					needsFullRefresh = true -- Multiple changes, safer to full refresh
				end
			end
		end
	end

	-- Toggle the target group, suppress native update
	if Groups:Toggle(groupId, true) then
		if needsFullRefresh then
			BFL:ForceRefreshFriendsList()
			return
		end

		-- Try optimized update first
		local group = Groups:Get(groupId)
		local expanding = not group.collapsed

		if self:OptimizedGroupToggle(groupId, expanding) then
			-- Optimization successful!
			return
		end

		-- Fallback to full refresh
		BFL:ForceRefreshFriendsList()
	elseif needsFullRefresh then
		-- Target group didn't change but others did (Accordion)
		BFL:ForceRefreshFriendsList()
	end
end

-- Create a new custom group
function FriendsList:CreateGroup(groupName)
	local Groups = GetGroups()
	if not Groups then
		return false, "Groups module not available"
	end

	local success, err = Groups:Create(groupName)
	if success then
		self:SyncGroups()
		BFL:ForceRefreshFriendsList()
	end

	return success, err
end

-- Rename a group
function FriendsList:RenameGroup(groupId, newName)
	local Groups = GetGroups()
	if not Groups then
		return false, "Groups module not available"
	end

	local success, err = Groups:Rename(groupId, newName)
	if success then
		self:SyncGroups()
		BFL:ForceRefreshFriendsList()
	end

	return success, err
end

-- Open color picker for a group
function FriendsList:OpenColorPicker(groupId)
	local Groups = GetGroups()
	if not Groups then
		return
	end

	local group = Groups:Get(groupId)
	if not group then
		return
	end

	local r, g, b, a = 1, 1, 1, 1
	if group.color then
		r = group.color.r or 1
		g = group.color.g or 1
		b = group.color.b or 1
		a = group.color.a or 1 -- Fix #34: Alpha support
	end

	local info = {
		swatchFunc = function()
			local newR, newG, newB = ColorPickerFrame:GetColorRGB()
			local newA = ColorPickerFrame:GetColorAlpha() or 1 -- Fix #34
			Groups:SetColor(groupId, newR, newG, newB, newA)
			BFL:ForceRefreshFriendsList()
		end,
		opacityFunc = function() -- Fix #34: Update on alpha slider change
			local newR, newG, newB = ColorPickerFrame:GetColorRGB()
			local newA = ColorPickerFrame:GetColorAlpha() or 1
			Groups:SetColor(groupId, newR, newG, newB, newA)
			BFL:ForceRefreshFriendsList()
		end,
		cancelFunc = function(previousValues)
			if previousValues then
				local prevA = previousValues.a or 1 -- Fix #34
				Groups:SetColor(groupId, previousValues.r, previousValues.g, previousValues.b, prevA)
				BFL:ForceRefreshFriendsList()
			end
		end,
		r = r,
		g = g,
		b = b,
		opacity = a, -- Fix #34
		hasOpacity = true, -- Fix #34: Enable alpha slider
	}

	ColorPickerFrame:SetupColorPickerAndShow(info)
end

-- Delete a group
function FriendsList:DeleteGroup(groupId)
	local Groups = GetGroups()
	if not Groups then
		return false, "Groups module not available"
	end

	local success, err = Groups:Delete(groupId)
	if success then
		self:SyncGroups()
		BFL:ForceRefreshFriendsList()
	end

	return success, err
end

-- Fix #33: Helper to count invitable friends in a group (same WoW version, not in party)
function FriendsList:GetInvitableCount(groupId)
	local DB = GetDB()
	if not DB then
		return 0
	end

	-- Helper to check if already in party/raid
	local function IsAlreadyInGroup(characterName)
		if not characterName then
			return false
		end
		local numMembers = GetNumGroupMembers()
		if numMembers == 0 then
			return false
		end
		for i = 1, numMembers do
			local unit = IsInRaid() and ("raid" .. i) or ("party" .. i)
			local name = UnitName(unit)
			if name and (name == characterName or characterName:find(name)) then
				return true
			end
		end
		return false
	end

	local count = 0

	for _, friend in ipairs(self.friendsList) do
		if friend.connected then
			local friendUID = GetFriendUID(friend)
			local isInGroup = false

			-- Check group membership (same logic as InviteGroupToParty)
			if groupId == "favorites" and friend.type == "bnet" and friend.isFavorite then
				isInGroup = true
			elseif groupId ~= "favorites" and groupId ~= "nogroup" then
				if
					BetterFriendlistDB
					and BetterFriendlistDB.friendGroups
					and BetterFriendlistDB.friendGroups[friendUID]
				then
					local groups = BetterFriendlistDB.friendGroups[friendUID]
					for _, gid in ipairs(groups) do
						if gid == groupId then
							isInGroup = true
							break
						end
					end
				end
			elseif groupId == "nogroup" then
				local hasGroup = false
				if friend.type == "bnet" and friend.isFavorite then
					hasGroup = true
				elseif
					BetterFriendlistDB
					and BetterFriendlistDB.friendGroups
					and BetterFriendlistDB.friendGroups[friendUID]
				then
					local groups = BetterFriendlistDB.friendGroups[friendUID]
					if #groups > 0 then
						hasGroup = true
					end
				end
				isInGroup = not hasGroup
			end

			if isInGroup then
				-- Validate: Must be WoW, same version, not already in party
				local isValid = false
				local characterName = nil

				if friend.type == "bnet" then
					if
						friend.gameAccountInfo
						and friend.gameAccountInfo.clientProgram == BNET_CLIENT_WOW
						and friend.gameAccountInfo.gameAccountID
					then
						local friendProjectID = friend.gameAccountInfo.wowProjectID
						if friendProjectID and WOW_PROJECT_ID and friendProjectID == WOW_PROJECT_ID then
							isValid = true
							characterName = friend.gameAccountInfo.characterName
						end
					end
				elseif friend.type == "wow" then
					isValid = true
					characterName = friend.name
				end

				if isValid and not IsAlreadyInGroup(characterName) then
					count = count + 1
				end
			end
		end
	end

	return count
end

-- Invite all online friends in a group to party
function FriendsList:InviteGroupToParty(groupId)
	local DB = GetDB()
	if not DB then
		return
	end

	-- Fix #33: Helper to check if a character name is already in our party/raid
	local function IsAlreadyInGroup(characterName)
		if not characterName then
			return false
		end
		local numMembers = GetNumGroupMembers()
		if numMembers == 0 then
			return false
		end

		for i = 1, numMembers do
			local unit = IsInRaid() and ("raid" .. i) or ("party" .. i)
			local name = UnitName(unit)
			if name and (name == characterName or characterName:find(name)) then
				return true
			end
		end
		return false
	end

	local inviteCandidates = {}

	-- 1. Collect all candidates
	for _, friend in ipairs(self.friendsList) do
		if friend.connected then
			local friendUID = GetFriendUID(friend)
			local isInGroup = false

			-- Check if favorite
			if groupId == "favorites" and friend.type == "bnet" and friend.isFavorite then
				isInGroup = true
			-- Check if in custom group
			elseif groupId ~= "favorites" and groupId ~= "nogroup" then
				if
					BetterFriendlistDB
					and BetterFriendlistDB.friendGroups
					and BetterFriendlistDB.friendGroups[friendUID]
				then
					local groups = BetterFriendlistDB.friendGroups[friendUID]
					for _, gid in ipairs(groups) do
						if gid == groupId then
							isInGroup = true
							break
						end
					end
				end
			-- Check if in no group
			elseif groupId == "nogroup" then
				local hasGroup = false
				if friend.type == "bnet" and friend.isFavorite then
					hasGroup = true
				elseif
					BetterFriendlistDB
					and BetterFriendlistDB.friendGroups
					and BetterFriendlistDB.friendGroups[friendUID]
				then
					local groups = BetterFriendlistDB.friendGroups[friendUID]
					if #groups > 0 then
						hasGroup = true
					end
				end
				isInGroup = not hasGroup
			end

			-- Add to candidates if found
			if isInGroup then
				-- Validate invitable status (BNet WoW or WoW friend)
				local isValid = false
				local characterName = nil

				if friend.type == "bnet" then
					if
						friend.gameAccountInfo
						and friend.gameAccountInfo.clientProgram == BNET_CLIENT_WOW
						and friend.gameAccountInfo.gameAccountID
					then
						-- Fix #33: Also check WoW project ID (Retail vs Classic)
						local friendProjectID = friend.gameAccountInfo.wowProjectID
						if friendProjectID and WOW_PROJECT_ID and friendProjectID == WOW_PROJECT_ID then
							isValid = true
							characterName = friend.gameAccountInfo.characterName
						end
					end
				elseif friend.type == "wow" then
					-- WoW friends are always on same project
					isValid = true
					characterName = friend.name
				end

				-- Fix #33: Skip friends already in our party/raid
				if isValid and IsAlreadyInGroup(characterName) then
					isValid = false
				end

				if isValid then
					table.insert(inviteCandidates, friend)
				end
			end
		end
	end

	if #inviteCandidates == 0 then
		print(BFL.L.MSG_NO_FRIENDS_AVAILABLE)
		return
	end

	-- 2. Check Group Status & Raid Conversion
	local numGroupMembers = GetNumGroupMembers()
	if numGroupMembers == 0 then
		numGroupMembers = 1
	end -- Self count is 1 if solo

	local totalSize = numGroupMembers + #inviteCandidates

	if not IsInRaid() and totalSize > 5 then
		-- Need to convert to raid
		print(BFL.L.MSG_INVITE_CONVERT_RAID)
		if BFL.ConvertToRaid then
			BFL.ConvertToRaid()
		end
	end

	-- 3. Check Raid Cap (40)
	local raidCap = 40
	local inviteLimit = #inviteCandidates

	if totalSize > raidCap then
		print(string.format(BFL.L.MSG_INVITE_RAID_FULL, raidCap))
		inviteLimit = raidCap - numGroupMembers
		if inviteLimit < 0 then
			inviteLimit = 0
		end
	end

	-- 4. Execute Invites
	local inviteCount = 0
	for i = 1, inviteLimit do
		local friend = inviteCandidates[i]
		if friend.type == "bnet" then
			BFL.BNInviteFriend(friend.gameAccountInfo.gameAccountID)
			inviteCount = inviteCount + 1
		elseif friend.type == "wow" then
			BFL.InviteUnit(friend.name)
			inviteCount = inviteCount + 1
		end
	end

	if inviteCount > 0 then
		print(string.format(BFL.L.MSG_INVITE_COUNT, inviteCount))
	end
end

-- Toggle friend in group
function FriendsList:ToggleFriendInGroup(friendUID, groupId)
	local DB = GetDB()
	if not DB then
		return
	end

	local friendGroupsData = DB:Get("friendGroups", {})
	friendGroupsData[friendUID] = friendGroupsData[friendUID] or {}

	local isInGroup = false
	for i, gid in ipairs(friendGroupsData[friendUID]) do
		if gid == groupId then
			table.remove(friendGroupsData[friendUID], i)
			isInGroup = true
			break
		end
	end

	if not isInGroup then
		table.insert(friendGroupsData[friendUID], groupId)
	end

	-- Clean up if no groups
	if #friendGroupsData[friendUID] == 0 then
		friendGroupsData[friendUID] = nil
	end

	DB:Set("friendGroups", friendGroupsData)
	self:RenderDisplay()

	return not isInGroup -- Return new state (true = added)
end

-- Check if friend is in group
function FriendsList:IsFriendInGroup(friendUID, groupId)
	local DB = GetDB()
	if not DB then
		return false
	end

	local friendGroupsData = DB:Get("friendGroups", {})
	if not friendGroupsData[friendUID] then
		return false
	end

	for _, gid in ipairs(friendGroupsData[friendUID]) do
		if gid == groupId then
			return true
		end
	end

	return false
end

-- Remove friend from group
function FriendsList:RemoveFriendFromGroup(friendUID, groupId)
	local DB = GetDB()
	if not DB then
		return
	end

	local friendGroupsData = DB:Get("friendGroups", {})
	if not friendGroupsData[friendUID] then
		return
	end

	for i, gid in ipairs(friendGroupsData[friendUID]) do
		if gid == groupId then
			table.remove(friendGroupsData[friendUID], i)
			break
		end
	end

	-- Clean up if no groups
	if #friendGroupsData[friendUID] == 0 then
		friendGroupsData[friendUID] = nil
	end

	DB:Set("friendGroups", friendGroupsData)
	self:RenderDisplay()
end

-- ========================================
-- Friends Display Rendering
-- ========================================

-- Helper to compare element data for structural equivalence
local function CompareElementData(a, b)
	if not a or not b then
		return false
	end
	if a.buttonType ~= b.buttonType then
		return false
	end

	if a.buttonType == BUTTON_TYPE_FRIEND then
		-- FIX (Fehlerklasse 4): Use UID comparison instead of reference comparison
		-- Object Pooling recycles friend tables, so reference equality is unreliable
		-- (same table can hold different friend data after wipe+refill)
		if a.friend and b.friend then
			return a.friend.uid == b.friend.uid and a.groupId == b.groupId
		end
		return false
	elseif a.buttonType == BUTTON_TYPE_GROUP_HEADER then
		-- For headers, we check ID and if collapsed state matches
		-- Counts might change, but that's a property update, not a structure update
		return a.groupId == b.groupId and a.collapsed == b.collapsed
	elseif a.buttonType == BUTTON_TYPE_INVITE then
		return a.inviteIndex == b.inviteIndex
	elseif a.buttonType == BUTTON_TYPE_SEARCH then
		return true -- Always matches, content updated dynamically
	end
end

-- Friends Display Rendering
function FriendsList:RenderDisplay(ignoreVisibility)
	-- REFACTORED (Phase 21): Ensure layout (SearchBox) matches current settings
	-- MOVED UP: Must happen even if frame is hidden to avoid SearchBox pop-in delay on show
	self:UpdateScrollBoxExtent()

	-- Skip update if Friends list elements are hidden (means we're on another tab)
	if BetterFriendsFrame.ScrollFrame and not BetterFriendsFrame.ScrollFrame:IsShown() and not ignoreVisibility then
		needsRenderOnShow = true
		return
	end

	-- Skip update if we're not on the Friends tab (tab 1)
	if BetterFriendsFrame.FriendsTabHeader then
		local selectedTab = PanelTemplates_GetSelectedTab(BetterFriendsFrame.FriendsTabHeader)
		if selectedTab and selectedTab ~= 1 then
			needsRenderOnShow = true
			return
		end
	end

	-- Clear dirty flag since we're rendering now
	needsRenderOnShow = false

	-- Build Display List (Returns simple table now)
	local newDisplayList = BuildDisplayList(self)

	-- Classic: Use FauxScrollFrame rendering
	if BFL.IsClassic or not BFL.HasModernScrollBox then
		-- Convert DataProvider to display list for Classic
		self.classicDisplayList = newDisplayList
		-- Render with Classic button pool
		self:RenderClassicButtons()
		return
	end

	-- Retail: Optimized ScrollBox Rendering using Diffing
	if self.scrollBox then
		local currentProvider = self.scrollBox:GetDataProvider()
		local structureChanged = true

		-- Check if structure has changed
		if currentProvider then
			local currentSize = (currentProvider.GetSize and currentProvider:GetSize())
				or (currentProvider.Count and currentProvider:Count())
				or 0

			if currentSize == #newDisplayList then
				structureChanged = false
				local index = 1
				-- Enumerate is linear, so this compares in order
				for _, oldData in currentProvider:Enumerate() do
					local newData = newDisplayList[index]
					if not CompareElementData(oldData, newData) then
						structureChanged = true
						break
					end
					index = index + 1
				end
			end
		end

		-- Fix #35/#40: Force full rebuild if font sizes changed (affects row heights)
		if self.forceLayoutRebuild then
			structureChanged = true
			self.forceLayoutRebuild = false
		end

		-- Force full rebuild if any friend's multi-account row status changed
		-- (height changes require ScrollBox layout recalculation)
		if not structureChanged and currentProvider then
			local index = 1
			for _, oldData in currentProvider:Enumerate() do
				local newData = newDisplayList[index]
				if oldData.buttonType == BUTTON_TYPE_FRIEND and oldData.friend then
					local oldHasRow = oldData._hasMultiAccountRow or false
					local newHasRow = ShouldShowMultiAccountRow(self, newData.friend)
					if oldHasRow ~= newHasRow then
						structureChanged = true
						break
					end
				end
				index = index + 1
			end
		end

		if not structureChanged then
			-- SMART UPDATE: Structure is identical, so we just update properties
			-- This avoids a full ScrollBox layout/rebuild!

			local index = 1
			for _, oldData in currentProvider:Enumerate() do
				local newData = newDisplayList[index]

				-- Copy value properties from new data to old data (in place)
				-- This ensures the existing elementData has the latest counts/states
				if newData.buttonType == BUTTON_TYPE_GROUP_HEADER then
					oldData.count = newData.count
					oldData.totalCount = newData.totalCount
					oldData.onlineCount = newData.onlineCount
					oldData.name = newData.name -- Fix #31/#32/#37: Copy renamed group name
				elseif newData.buttonType == BUTTON_TYPE_FRIEND then
					-- friend reference is same, so data inside friend object is already new
					-- Copy multi-account row status for height change tracking
					oldData._hasMultiAccountRow = newData._hasMultiAccountRow
				end

				index = index + 1
			end

			-- Force visible frames to refresh their visual state
			-- Loop only visible frames (SUPER FAST)
			self.scrollBox:ForEachFrame(function(frame, elementData)
				if elementData.buttonType == BUTTON_TYPE_FRIEND then
					self:UpdateFriendButton(frame, elementData)
				elseif elementData.buttonType == BUTTON_TYPE_GROUP_HEADER then
					self:UpdateGroupHeaderButton(frame, elementData)
				elseif elementData.buttonType == BUTTON_TYPE_INVITE then
					self:UpdateInviteButton(frame, elementData)
				elseif elementData.buttonType == BUTTON_TYPE_INVITE_HEADER then
					self:UpdateInviteHeaderButton(frame, elementData)
				end
			end)

			-- Debugging
			-- if BFL.DebugPrint then BFL:DebugPrint("Smart Render: Skipped Layout") end
			return
		end

		-- Structure Changed: Full Rebuild
		-- if BFL.DebugPrint then BFL:DebugPrint("Full Render: Rebuilding DataProvider") end

		local dataProvider = CreateDataProvider()
		-- Bulk insert is usually faster if available, but Insert loop is fine
		for _, data in ipairs(newDisplayList) do
			dataProvider:Insert(data)
		end
		self.scrollBox:SetDataProvider(dataProvider, true) -- retainScrollPosition = true
	end
end

-- Check if render is needed (called when frame is shown)
function FriendsList:NeedsRenderOnShow()
	return needsRenderOnShow
end

-- ========================================
-- Button Update Functions (called by ScrollBox Factory)
-- ========================================

-- Update group header button (NEW - Phase 1)
function FriendsList:UpdateGroupHeaderButton(button, elementData)
	local groupId = elementData.groupId
	local name = elementData.name
	local count = elementData.count
	local collapsed = elementData.collapsed

	local Groups = GetGroups()

	-- Store group data on button
	button.groupId = groupId
	button.elementData = elementData

	-- Create drop target highlight if it doesn't exist
	if not button.dropHighlight then
		local dropHighlight = button:CreateTexture(nil, "BACKGROUND")
		dropHighlight:SetAllPoints()
		dropHighlight:SetColorTexture(0, 1, 0, 0.2)
		dropHighlight:Hide()
		button.dropHighlight = dropHighlight
	end

	-- Get group color (Default name color)
	local r, g, b, a = 1, 1, 1, 1 -- Default white
	local colorCode = FormatColorCode(1, 1, 1, 1)

	-- Count and Arrow Colors (Default to Group Color)
	local countR, countG, countB, countA = 1, 1, 1, 1
	local arrowR, arrowG, arrowB, arrowA = 1, 1, 1, 1

	if Groups then
		local group = Groups:Get(groupId)
		if group and group.color then
			r = group.color.r or group.color[1] or 1
			g = group.color.g or group.color[2] or 1
			b = group.color.b or group.color[3] or 1
			a = group.color.a or group.color[4] or 1
			colorCode = FormatColorCode(r, g, b, a)
		end

		-- Default to White (No Inheritance)
		countR, countG, countB = 1, 1, 1
		arrowR, arrowG, arrowB = 1, 1, 1

		-- Override if specific colors are set
		if group and group.countColor then
			countR, countG, countB = group.countColor.r, group.countColor.g, group.countColor.b
			countA = group.countColor.a or 1
		end
		if group and group.arrowColor then
			arrowR, arrowG, arrowB = group.arrowColor.r, group.arrowColor.g, group.arrowColor.b
			arrowA = group.arrowColor.a or 1
		end
	end

	local DB = GetDB()
	-- Count Color Code
	local countColorCode = FormatColorCode(countR, countG, countB, countA)

	-- PERFY OPTIMIZATION: Direct cache access
	-- Set header text with color
	local format = self.settingsCache.headerCountFormat or "visible"
	local countText = ""

	if format == "online" then
		-- Show "Online / Total" (e.g. "3/10")
		countText = string.format("%d/%d", elementData.onlineCount or 0, elementData.totalCount or 0)
	elseif format == "both" then
		-- Show "Filtered / Online / Total" (e.g. "1/3/10")
		countText = string.format("%d / %d / %d", count, elementData.onlineCount or 0, elementData.totalCount or 0)
	else -- "visible" (Default)
		-- Show "Filtered / Total" (e.g. "3/10" or just "3" if same)
		countText = count
		if elementData.totalCount and elementData.totalCount > count then
			countText = string.format("%d/%d", count, elementData.totalCount)
		end
	end

	-- PERFY OPTIMIZATION: Direct cache access
	-- Apply Text Alignment and Font Settings (Feature Request)
	local align = self.settingsCache.groupHeaderAlign or "LEFT"

	local fs = button:GetFontString()
	if fs then
		-- Font Settings
		local appliedFont = false
		local fontSize = 12
		local fontOutline = ""
		local fontShadow = false
		if DB then
			local fontName = DB:Get("fontGroupHeader", "Friz Quadrata TT")
			fontSize = DB:Get("fontSizeGroupHeader", 12)
			fontOutline = DB:Get("fontOutlineGroupHeader", "NONE")
			fontShadow = DB:Get("fontShadowGroupHeader", false)

			local fontPath = LSM:Fetch("font", fontName)
			-- Use FontManager to apply font with Alphabet support
			if fontPath and BFL.FontManager and BFL.FontManager.GetOrCreateFontFamily then
				-- For Group Headers (Buttons), we must set the Normal/Highlight FontObject
				-- instead of just setting the FontString, otherwise interaction resets it
				local familyObj = BFL.FontManager:GetOrCreateFontFamily(fontPath, fontSize, fontOutline, fontShadow)
				if familyObj then
					button:SetNormalFontObject(familyObj)
					button:SetHighlightFontObject(familyObj)
					-- Also set current fs immediately to ensure visual update
					fs:SetFontObject(familyObj)
					appliedFont = true
				end
			elseif fontPath then
				fs:SetFont(fontPath, fontSize, fontOutline)
				appliedFont = true

				if fontShadow then
					fs:SetShadowColor(0, 0, 0, 1)
					fs:SetShadowOffset(1, -1)
				else
					fs:SetShadowColor(0, 0, 0, 0)
					fs:SetShadowOffset(0, 0)
				end
			end
		end

		if not appliedFont then
			local outline = fontOutline
			if outline == "NONE" then
				outline = ""
			end
			fs:SetFont("Fonts\\FRIZQT__.TTF", fontSize, outline)
			if fontShadow then
				fs:SetShadowColor(0, 0, 0, 1)
				fs:SetShadowOffset(1, -1)
			else
				fs:SetShadowColor(0, 0, 0, 0)
				fs:SetShadowOffset(0, 0)
			end
		end

		ApplyGroupHeaderText(
			button,
			name,
			countText,
			{ r = r, g = g, b = b, a = a },
			{ r = countR, g = countG, b = countB, a = countA },
			align
		)
	end

	-- PERFY OPTIMIZATION: Direct cache access
	-- Show/hide and align collapse arrows (Feature Request)
	local showArrow = self.settingsCache.showGroupArrow
	if showArrow == nil then
		showArrow = true
	end
	local arrowAlign = self.settingsCache.groupArrowAlign or "LEFT"

	-- Reset visibility first
	if button.DownArrow then
		button.DownArrow:Hide()
	end
	if button.RightArrow then
		button.RightArrow:Hide()
	end

	if showArrow then
		local targetArrow = collapsed and button.RightArrow or button.DownArrow
		if targetArrow then
			targetArrow:Show()
			targetArrow:SetDesaturated(true)
			targetArrow:SetVertexColor(arrowR, arrowG, arrowB, arrowA)
			targetArrow:ClearAllPoints()

			-- Restore normal textures first (resetting any overrides)
			if BFL.IsClassic then
				if targetArrow == button.RightArrow then
					targetArrow:SetTexture("Interface\\AddOns\\BetterFriendlist\\Icons\\chevron-right")
				else
					targetArrow:SetTexture("Interface\\AddOns\\BetterFriendlist\\Icons\\chevron-down")
				end
			else
				if targetArrow == button.RightArrow then
					targetArrow:SetAtlas("friendslist-categorybutton-arrow-left")
					targetArrow:SetRotation(0)
				else
					targetArrow:SetAtlas("friendslist-categorybutton-arrow-down")
					targetArrow:SetRotation(0)
				end
			end

			-- Base coordinates for unpressed state
			local point, x, y
			if arrowAlign == "RIGHT" then
				point = "RIGHT"

				-- Override texture for Right Arrow (Collapsed state) to point Left
				if targetArrow == button.RightArrow then
					if not BFL.IsClassic then
						targetArrow:SetAtlas("friendslist-categorybutton-arrow-left")
						targetArrow:SetRotation(math.pi)
					else
						targetArrow:SetTexture("Interface\\AddOns\\BetterFriendlist\\Icons\\chevron-left")
					end
				end

				x = (targetArrow == button.DownArrow) and -8 or -6
				y = (targetArrow == button.DownArrow) and -2 or 0
			elseif arrowAlign == "CENTER" then
				point = "CENTER"

				if align == "CENTER" then
					-- If text is also centered, offset arrow to the left of text
					local textWidth = 0
					local headerFs = button:GetFontString()
					if headerFs then
						textWidth = headerFs:GetStringWidth() or 0
					end
					if button.CountText and button.CountText:IsShown() then
						textWidth = textWidth + GROUP_HEADER_TEXT_GAP + (button.CountText:GetStringWidth() or 0)
					end
					local offset = (textWidth / 2) + 12
					x = -offset
				else
					x = (targetArrow == button.DownArrow) and 0 or 2
				end

				y = (targetArrow == button.DownArrow) and -2 or 0
			else -- LEFT (Default)
				point = "LEFT"
				x = (targetArrow == button.DownArrow) and 6 or 8
				y = (targetArrow == button.DownArrow) and -2 or 0
			end

			targetArrow:SetPoint(point, x, y)

			-- Override mouse scripts to support alignment (only once per button)
			if not button.isArrowScriptHooked then
				button:SetScript("OnMouseDown", function(self)
					if self.DownArrow and self.DownArrow:IsShown() then
						local p, relativeTo, relativePoint, x, y = self.DownArrow:GetPoint()
						if p then
							self.DownArrow:SetPoint(p, relativeTo, relativePoint, x + 1, y - 1)
						end
					end
					if self.RightArrow and self.RightArrow:IsShown() then
						local p, relativeTo, relativePoint, x, y = self.RightArrow:GetPoint()
						if p then
							self.RightArrow:SetPoint(p, relativeTo, relativePoint, x + 1, y - 1)
						end
					end
				end)

				button:SetScript(
					"OnMouseUp",
					function(self) -- Trigger update to reset positions based on current settings
						if FriendsList and FriendsList.UpdateGroupHeaderButton and self.elementData then
							FriendsList:UpdateGroupHeaderButton(self, self.elementData)
						end
					end
				)
				button.isArrowScriptHooked = true
			end
		end
	end

	-- Apply font scaling
	local FontManager = GetFontManager()
	local headerFs = button:GetFontString()
	if FontManager and headerFs then
		EnsureGroupHeaderFont(headerFs)
		if IsFontReady(headerFs) then
			pcall(FontManager.ApplyFontSize, FontManager, headerFs)
		end
	end

	-- Tooltips for group headers
	button:SetScript("OnEnter", function(self) -- Check if we're currently dragging a friend
		local isDragging = BetterFriendsList_DraggedFriend ~= nil

		local Groups = GetGroups()
		local friendGroups = Groups and Groups:GetAll() or {}

		if isDragging and self.groupId and friendGroups[self.groupId] and not friendGroups[self.groupId].builtin then
			-- Show drop target tooltip
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText(L.TOOLTIP_DROP_TO_ADD, 1, 1, 1)
			GameTooltip:AddLine(L.TOOLTIP_HOLD_SHIFT, 0.7, 0.7, 0.7, true)
			GameTooltip:Show()
		else
			-- Show group info tooltip
			if self.groupId and friendGroups[self.groupId] then
				local groupData = friendGroups[self.groupId]

				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				GameTooltip:SetText(groupData.name, 1, 1, 1)
				GameTooltip:AddLine(BFL.L.HINT_RIGHT_CLICK_OPTIONS, 0.7, 0.7, 0.7, true)
				if not groupData.builtin then
					GameTooltip:AddLine(L.TOOLTIP_DRAG_HERE, 0.5, 0.8, 1.0, true)
				end
				GameTooltip:Show()
			end
		end
	end)

	button:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	-- Add right-click menu functionality
	if Groups then
		local group = Groups:Get(groupId)
		if group and not group.builtin then
			-- Custom groups: Full context menu with Rename/Delete
			button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			button:SetScript("OnClick", function(self, buttonName)
				if buttonName == "RightButton" then
					-- Open context menu for custom group header
					MenuUtil.CreateContextMenu(self, function(owner, rootDescription)
						local groupData = Groups:Get(self.groupId)
						if not groupData then
							return
						end

						rootDescription:CreateTitle(groupData.name)

						rootDescription:CreateButton(BFL.L.MENU_RENAME_GROUP, function()
							StaticPopup_Show("BETTER_FRIENDLIST_RENAME_GROUP", nil, nil, self.groupId)
						end)

						rootDescription:CreateButton(BFL.L.MENU_CHANGE_COLOR, function()
							FriendsList:OpenColorPicker(self.groupId)
						end)

						rootDescription:CreateButton(BFL.L.MENU_DELETE_GROUP, function()
							StaticPopup_Show("BETTER_FRIENDLIST_DELETE_GROUP", nil, nil, self.groupId)
						end)

						-- Fix #30/#33: Only show Invite button if there are invitable friends (same WoW version, not in party)
						local invitableCount = FriendsList:GetInvitableCount(self.groupId)
						if invitableCount > 0 then
							rootDescription:CreateDivider()

							rootDescription:CreateButton(
								BFL.L.MENU_INVITE_GROUP .. " (" .. invitableCount .. ")",
								function()
									FriendsList:InviteGroupToParty(self.groupId)
								end
							)
						end

						rootDescription:CreateDivider()

						-- Group-wide action buttons
						rootDescription:CreateButton(BFL.L.MENU_COLLAPSE_ALL, function()
							for gid in pairs(Groups.groups) do
								Groups:SetCollapsed(gid, true, true) -- true = force collapse
							end
							BFL:ForceRefreshFriendsList()
						end)

						rootDescription:CreateButton(BFL.L.MENU_EXPAND_ALL, function()
							for gid in pairs(Groups.groups) do
								Groups:SetCollapsed(gid, false, true) -- false = force expand
							end
							BFL:ForceRefreshFriendsList()
						end)
					end)
				else
					-- Left click: toggle collapse
					FriendsList:ToggleGroup(self.groupId)
				end
			end)
		else
			-- Built-in groups: Right-click for Collapse/Expand All + Invite
			button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			button:SetScript("OnClick", function(self, buttonName)
				if buttonName == "RightButton" then
					-- Open context menu for built-in group header
					MenuUtil.CreateContextMenu(self, function(owner, rootDescription)
						local groupData = Groups:Get(self.groupId)
						if not groupData then
							return
						end

						rootDescription:CreateTitle(groupData.name)

						rootDescription:CreateButton(BFL.L.MENU_RENAME_GROUP, function()
							StaticPopup_Show("BETTER_FRIENDLIST_RENAME_GROUP", nil, nil, self.groupId)
						end)

						rootDescription:CreateButton(BFL.L.MENU_CHANGE_COLOR, function()
							FriendsList:OpenColorPicker(self.groupId)
						end)

						-- Fix #30/#33: Only show Invite button if there are invitable friends (same WoW version, not in party)
						local invitableCount = FriendsList:GetInvitableCount(self.groupId)
						if invitableCount > 0 then
							rootDescription:CreateButton(
								BFL.L.MENU_INVITE_GROUP .. " (" .. invitableCount .. ")",
								function()
									FriendsList:InviteGroupToParty(self.groupId)
								end
							)
						end

						rootDescription:CreateDivider()

						rootDescription:CreateButton(BFL.L.MENU_COLLAPSE_ALL, function()
							if Groups then
								for gid in pairs(Groups.groups) do
									Groups:SetCollapsed(gid, true, true) -- true = force collapse
								end
								BFL:ForceRefreshFriendsList()
							end
						end)

						rootDescription:CreateButton(BFL.L.MENU_EXPAND_ALL, function()
							if Groups then
								for gid in pairs(Groups.groups) do
									Groups:SetCollapsed(gid, false, true) -- false = force expand
								end
								BFL:ForceRefreshFriendsList()
							end
						end)
					end)
				else
					-- Left click: toggle collapse
					FriendsList:ToggleGroup(self.groupId)
				end
			end)
		end
	end

	-- Ensure button is visible
	button:Show()
end

-- ========================================
-- Friend Button Update (ScrollBox Factory Callback)
-- ========================================

-- ========================================
-- Drag & Drop Handlers (Hoisted - Phase 9.2)
-- ========================================

-- Drag OnUpdate Handler
Button_OnDragUpdate = function(self)
	-- Get cursor position (used for Ghost positioning mainly)
	local cursorX, cursorY = GetCursorPosition()
	local scale = UIParent:GetEffectiveScale()
	cursorX = cursorX / scale
	cursorY = cursorY / scale

	-- Move Ghost
	local ghost = BFL:GetDragGhost()
	if ghost and ghost:IsShown() then
		ghost:SetPoint("CENTER", UIParent, "BOTTOMLEFT", cursorX, cursorY)
	end

	-- Get all visible group header buttons from ScrollBox
	local Groups = GetGroups()
	local friendGroups = Groups and Groups:GetAll() or {}

	-- Universal Frame Iteration (Retail + Classic)
	local framesToCheck
	if BFL.IsClassic or FriendsList.classicHeaderPool then
		framesToCheck = FriendsList.classicHeaderPool
	else
		-- Robust ScrollBox Retrieval
		local scrollBox = FriendsList.scrollBox -- Use module reference
		if not scrollBox and self.GetParent then
			-- Fallback: Traverse parents (Button -> ScrollTarget -> ScrollBox)
			local parent = self:GetParent()
			if parent then
				scrollBox = parent:GetParent()
			end
		end

		if scrollBox and scrollBox.GetFrames then
			framesToCheck = scrollBox:GetFrames()
		end
	end

	-- Add Broker Tooltip Headers if available (Broker Drag & Drop)
	-- Helper to append tables without overhead
	local Broker = BFL:GetModule("Broker")
	local brokerTargets = Broker and Broker.GetDropTargets and Broker:GetDropTargets()

	-- DEBUG: Throttle print to check if we see broker targets
	if brokerTargets and #brokerTargets > 0 then
		-- Optional: print once
		if not self.hasPrintedBrokerFetch then
			BFL:DebugPrint(string.format("DragUpdate: Found %d broker targets", #brokerTargets))
			self.hasPrintedBrokerFetch = true
		end
	elseif Broker and not brokerTargets then
		if not self.hasPrintedBrokerFetch then
			BFL:DebugPrint("DragUpdate: No broker targets found - GetDropTargets returned nil")
			self.hasPrintedBrokerFetch = true
		end
	end

	if framesToCheck then
		-- Iterate frames (Universal)
		for _, frame in pairs(framesToCheck) do
			-- Check IsShown() for Classic pooling safety
			if frame:IsShown() and frame.groupId and frame.dropHighlight then
				local groupData = friendGroups[frame.groupId]
				if groupData and not groupData.builtin then
					-- Check if cursor is over this header using MouseIsOver for robustness
					local isOver = MouseIsOver(frame)

					if isOver and BetterFriendsList_DraggedFriend then
						-- Show highlight and update text
						frame.dropHighlight:Show()
						local headerText =
							string.format(BFL.L.HEADER_ADD_FRIEND, BetterFriendsList_DraggedFriend, groupData.name)
						local align = (
							FriendsList
							and FriendsList.settingsCache
							and FriendsList.settingsCache.groupHeaderAlign
						) or "LEFT"
						ApplyGroupHeaderSingleText(frame, headerText, align)
					else
						-- Hide highlight and restore original text
						frame.dropHighlight:Hide()
						-- Optimization: Use cached count from elementData if available
						local memberCount = 0

						-- Universal access to data (Classic property vs Retail method)
						local elementData = frame.elementData
						if not elementData and frame.GetElementData then
							elementData = frame:GetElementData()
						end

						if elementData and elementData.count then
							memberCount = elementData.count
						else
							-- Fallback (should not happen with ScrollBox)
							if BetterFriendlistDB.friendGroups then
								for _, groups in pairs(BetterFriendlistDB.friendGroups) do
									for _, gid in ipairs(groups) do
										if gid == frame.groupId then
											memberCount = memberCount + 1
											break
										end
									end
								end
							end
						end

						if FriendsList and FriendsList.UpdateGroupHeaderButton and frame.elementData then
							FriendsList:UpdateGroupHeaderButton(frame, frame.elementData)
						else
							local headerText = string.format("%s (%d)", groupData.name, memberCount)
							local align = (
								FriendsList
								and FriendsList.settingsCache
								and FriendsList.settingsCache.groupHeaderAlign
							) or "LEFT"
							ApplyGroupHeaderSingleText(frame, headerText, align)
						end
					end
				end
			end
		end
	end

	-- Check Broker Targets
	if brokerTargets then
		for _, frame in pairs(brokerTargets) do
			if frame:IsShown() and frame.groupId and frame.dropHighlight then
				local groupData = friendGroups[frame.groupId]
				if groupData and not groupData.builtin then
					local isOver = MouseIsOver(frame)
					if isOver and BetterFriendsList_DraggedFriend then
						frame.dropHighlight:Show()
						-- Note: LibQTip lines use custom cell setting, so SetText might not work directly/cleanly
						-- We'll assume the Broker module sets up a compatible SetText or we just trust the highlight
						if frame.SetText then
							local headerText =
								string.format(BFL.L.HEADER_ADD_FRIEND, BetterFriendsList_DraggedFriend, groupData.name)
							frame:SetText("  " .. headerText) -- Indent for Broker style
						end
					else
						frame.dropHighlight:Hide()
						-- Restore original text is complex for Broker lines.
						-- Better to let Broker module handle restore?
						-- Or simpler: Just rely on highlight for Broker, don't change text to avoid "flicker" complexity or state loss
						-- Ideally we replicate the logic.
						if frame.SetText and frame.originalText then
							frame:SetText(frame.originalText)
						end
					end
				end
			end
		end
	end
end

-- Drag OnStart Handler
Button_OnDragStart = function(self)
	if self.friendData then
		-- Store friend name for header text updates
		-- [STREAMER MODE CHECK] Never expose Real ID in drag ghost text
		local dragName
		if BFL.StreamerMode and BFL.StreamerMode:IsActive() and self.friendData.type == "bnet" then
			dragName = FriendsList:GetDisplayName(self.friendData)
		else
			dragName = self.friendData.name or self.friendData.accountName or self.friendData.battleTag or "Unknown"
		end
		BetterFriendsList_DraggedFriend = dragName
		-- Store UID for validation (Fix for Phantom DragStop events during list refresh)
		BetterFriendsList_DraggedUID = FriendsList:GetFriendUID(self.friendData)

		-- Init Ghost with Visuals
		local ghost = BFL:GetDragGhost()
		if ghost then
			-- Format text nicely (including class color if available)
			local text = BetterFriendsList_DraggedFriend
			local colorR, colorG, colorB = 1, 0.82, 0 -- Default Gold

			-- Reset base text color to Gold to prevent tinting issues from previous drags
			ghost.text:SetTextColor(1, 0.82, 0)

			if self.friendData.className then
				local classFile = GetClassFileFromClassName(self.friendData.className)
				if not classFile and self.friendData.type == "bnet" then
					-- For BNet, we might need to look it up differently if classFile isn't direct
					classFile = GetClassFileForFriend(self.friendData)
				end

				local classColor = classFile and RAID_CLASS_COLORS[classFile]
				if classColor then
					text = "|c" .. (classColor.colorStr or "ffffffff") .. text .. "|r"
					colorR, colorG, colorB = classColor.r, classColor.g, classColor.b
				end
			end

			ghost.text:SetText(text)
			ghost.stripe:SetColorTexture(colorR, colorG, colorB)

			-- Calculate width based on text length + padding
			local width = ghost.text:GetStringWidth() + 30
			ghost:SetSize(width, 24)

			ghost:Show()
			local cursorX, cursorY = GetCursorPosition()
			local scale = UIParent:GetEffectiveScale()
			ghost:SetPoint("CENTER", UIParent, "BOTTOMLEFT", cursorX / scale, cursorY / scale)
		end

		-- Show drag overlay
		self.dragOverlay:Show()
		self:SetAlpha(0.5)

		-- Hide tooltip
		GameTooltip:Hide()

		-- Enable OnUpdate
		self.hasPrintedBrokerFetch = nil -- Reset debug flag for new drag session
		self:SetScript("OnUpdate", Button_OnDragUpdate)
	end
end

-- Drag OnStop Handler
Button_OnDragStop = function(self)
	-- Disable OnUpdate
	self:SetScript("OnUpdate", nil)

	-- Hide Ghost
	local ghost = BFL:GetDragGhost()
	if ghost then
		ghost:Hide()
		ghost:ClearAllPoints()
	end

	-- Hide drag overlay
	if self.dragOverlay then
		self.dragOverlay:Hide()
	end
	self:SetAlpha(1.0)

	-- Guard Phase
	local currentUID = FriendsList:GetFriendUID(self.friendData)
	if not BetterFriendsList_DraggedUID or BetterFriendsList_DraggedUID ~= currentUID then
		BFL:DebugPrint("DragStop ignored: UID mismatch (Phantom Event)")
		return
	end

	-- Get Groups and reset all header highlights and texts
	local Groups = GetGroups()
	local friendGroups = Groups and Groups:GetAll() or {}

	-- Universal Frame Iteration (Retail + Classic)
	local framesToCheck
	if BFL.IsClassic or FriendsList.classicHeaderPool then
		framesToCheck = FriendsList.classicHeaderPool
	else
		-- Robust ScrollBox Retrieval
		local scrollBox = FriendsList.scrollBox -- Use module reference
		if not scrollBox and self.GetParent then
			-- Fallback: Traverse parents (Button -> ScrollTarget -> ScrollBox)
			local parent = self:GetParent()
			if parent then
				scrollBox = parent:GetParent()
			end
		end

		if scrollBox and scrollBox.GetFrames then
			framesToCheck = scrollBox:GetFrames()
		end
	end

	-- Reset Highlights
	if framesToCheck then
		for _, frame in pairs(framesToCheck) do
			if frame:IsShown() and frame.groupId and frame.dropHighlight then
				frame.dropHighlight:Hide()
				local groupData = friendGroups[frame.groupId]
				if groupData then
					local memberCount = 0

					-- Universal access to data
					local elementData = frame.elementData
					if not elementData and frame.GetElementData then
						elementData = frame:GetElementData()
					end

					if elementData and elementData.count then
						memberCount = elementData.count
					else
						-- Fallback for counting members
						if BetterFriendlistDB.friendGroups then
							for _, groups in pairs(BetterFriendlistDB.friendGroups) do
								for _, gid in ipairs(groups) do
									if gid == frame.groupId then
										memberCount = memberCount + 1
										break
									end
								end
							end
						end
					end

					if FriendsList and FriendsList.UpdateGroupHeaderButton and elementData then
						FriendsList:UpdateGroupHeaderButton(frame, elementData)
					else
						local headerText = string.format("%s (%d)", groupData.name, memberCount)
						local align = (
							FriendsList
							and FriendsList.settingsCache
							and FriendsList.settingsCache.groupHeaderAlign
						) or "LEFT"
						ApplyGroupHeaderSingleText(frame, headerText, align)
					end
				end
			end
		end
	end

	-- Detect Drop Target using MouseIsOver for robustness
	local droppedOnGroup = nil
	if framesToCheck then
		for _, frame in pairs(framesToCheck) do
			if frame:IsShown() and frame.groupId then
				if MouseIsOver(frame) then
					droppedOnGroup = frame.groupId
					break
				end
			end
		end
	end

	-- Check Broker Targets (Broker Drag & Drop)
	if not droppedOnGroup then
		local Broker = BFL:GetModule("Broker")
		local brokerTargets = Broker and Broker.GetDropTargets and Broker:GetDropTargets()
		if brokerTargets then
			for _, frame in pairs(brokerTargets) do
				if frame:IsShown() and frame.groupId then
					if MouseIsOver(frame) then
						droppedOnGroup = frame.groupId
						break
					end
				end
			end
		end
	end

	-- If dropped on a group, add friend to that group
	-- Pcall protection for logic
	local success, err = pcall(function()
		-- DEBUG: Trace DragStop
		if droppedOnGroup then
			BFL:DebugPrint(string.format("DragStop detected on group: %s", tostring(droppedOnGroup)))
		else
			-- Optional: BFL:DebugPrint("DragStop: No group detected")
		end

		if droppedOnGroup and self.friendData then
			local friendUID = FriendsList:GetFriendUID(self.friendData)
			BFL:DebugPrint(
				string.format("Dropped friend: %s (UID: %s)", tostring(self.friendData.name), tostring(friendUID))
			)

			if friendUID then
				-- Without Shift: Remove from all other custom groups (move)
				-- With Shift: Keep in other groups (add to multiple groups)
				if not IsShiftKeyDown() then
					BFL:DebugPrint("Shift NOT down - attempting MOVE (Remove from old groups)")
					if BetterFriendlistDB.friendGroups and BetterFriendlistDB.friendGroups[friendUID] then
						for i = #BetterFriendlistDB.friendGroups[friendUID], 1, -1 do
							if BetterFriendlistDB.friendGroups[friendUID][i] then
								local groupId = BetterFriendlistDB.friendGroups[friendUID][i]
								-- Check if valid group and NOT builtin (can't remove from builtin like favorites)
								if friendGroups[groupId] and not friendGroups[groupId].builtin then
									BFL:DebugPrint(string.format("Removing from old group: %s", tostring(groupId)))
									table.remove(BetterFriendlistDB.friendGroups[friendUID], i)
								else
									BFL:DebugPrint(
										string.format(
											"Skipping removal from builtin/invalid group: %s",
											tostring(groupId)
										)
									)
								end
							end
						end
					else
						BFL:DebugPrint("No existing groups found for friend")
					end
				else
					BFL:DebugPrint("Shift IS down - attempting ADD (Keep in old groups)")
				end

				-- Add to target group
				local DB = GetDB()
				if DB then
					BFL:DebugPrint(string.format("Adding to target group: %s", tostring(droppedOnGroup)))
					-- Robustness: Force add (DB handles duplicates)
					DB:AddFriendToGroup(friendUID, droppedOnGroup)
				else
					BFL:DebugPrint("Error: DB module not found")
				end
				BFL:ForceRefreshFriendsList()
			end
		end
	end)

	if not success then
		BFL:DebugPrint("Error in DragStop: " .. tostring(err))
	end

	-- Clear dragged friend name
	BetterFriendsList_DraggedFriend = ""
	BetterFriendsList_DraggedUID = nil
end

-- Wrapper for use by other modules (e.g. Broker)
function FriendsList:OnDragStart(button)
	Button_OnDragStart(button)
end

function FriendsList:OnDragStop(button)
	Button_OnDragStop(button)
end

-- ========================================
-- Friend Text Optimization (Phase 21)
-- ========================================

-- Helper: Get formatted text for friend button (Cached)
-- This moves expensive string concatenation out of the render loop
function FriendsList:GetFormattedButtonText(friend)
	local DB = GetDB()

	-- [STREAMER MODE LOGIC INTEGRATED]
	-- We removed the early return here to allow formatted names (e.g. Nicknames)
	-- AND show friend info (Character Name, Zone, etc.) which is desired by the user.
	-- GetDisplayName (called below) handles the primary name masking.

	-- PERFY OPTIMIZATION: Direct cache access
	local isCompactMode = self.settingsCache.compactMode or false
	local currentSettingsVersion = BFL.SettingsVersion or 1

	-- Check cache (Fastest Path)
	if
		friend._cache_text_version == currentSettingsVersion
		and friend._cache_text_compact == isCompactMode
		and friend._cache_text_line1
	then
		return friend._cache_text_line1, friend._cache_text_line2
	end

	-- Cache Miss - Calculate text (Slow Path - Happens once per friend/setting change)
	local line1Text = ""
	local line1BaseText = ""
	local line1SuffixText = ""
	local line2Text = ""

	local displayName = friend.displayName or self:GetDisplayName(friend)

	-- External Formatter Support (FriendListColors)
	-- If FriendListColors is loaded, use it to format the name text (Line 1)
	local usedExternalFormatter = false
	-- Safety check: Ensure Format function exists
	-- Only supporting the official public API (FriendListColorsAPI)
	local formatFunc = nil
	if _G.FriendListColorsAPI and type(_G.FriendListColorsAPI.Format) == "function" then
		formatFunc = _G.FriendListColorsAPI.Format
	end

	if formatFunc then
		local flcData = {}
		flcData.isBNet = (friend.type == "bnet")

		-- Match Native FLC Logic: Only treat as "Online" for coloring if playing WoW
		-- FLC's internal package logic only merges game data (including isOnline) if client is WoW
		if friend.type == "bnet" then
			local isWoW = (friend.gameAccountInfo and friend.gameAccountInfo.clientProgram == "WoW")
			flcData.isOnline = isWoW and friend.connected
			flcData.connected = isWoW and friend.connected
		else
			flcData.isOnline = friend.connected
			flcData.connected = friend.connected
		end

		flcData.notes = friend.note or friend.notes

		if friend.type == "bnet" then
			-- [STREAMER MODE CHECK] Mask accountName for external addon
			if BFL.StreamerMode and BFL.StreamerMode:IsActive() then
				local safeName = displayName or self:GetDisplayName(friend)
				flcData.accountName = safeName
				flcData.name = friend.characterName or safeName
			else
				flcData.accountName = friend.accountName
				flcData.name = friend.characterName or friend.accountName
			end
			flcData.battleTag = friend.battleTag
			flcData.characterName = friend.characterName
			flcData.level = friend.level
			flcData.className = friend.className
			flcData.areaName = friend.areaName
			flcData.factionName = friend.factionName
			flcData.timerunningSeasonID = friend.timerunningSeasonID
			flcData.gameAccountInfo = friend.gameAccountInfo
		else
			flcData.name = friend.name
			flcData.level = friend.level
			flcData.className = friend.className
			flcData.area = friend.area
		end

		-- Use pcall for safety against external errors
		local success, flcText = pcall(formatFunc, flcData)
		if success and flcText and flcText ~= "" then
			line1Text = flcText
			usedExternalFormatter = true
		end
	end

	if friend.type == "bnet" then
		-- Battle.net Friend (PERFY OPTIMIZATION: Direct cache access)
		local playerFactionGroup = UnitFactionGroup("player")
		local grayOtherFaction = self.settingsCache.grayOtherFaction or false

		if friend.connected then
			if not usedExternalFormatter then
				local isOppositeFaction = friend.factionName
					and friend.factionName ~= playerFactionGroup
					and friend.factionName ~= ""
				local shouldGray = grayOtherFaction and isOppositeFaction

				if shouldGray then
					-- Strip inner color codes so gray applies uniformly (Phase 22b)
					local stripped = displayName:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
					line1Text = "|cff808080" .. stripped .. "|r"
				else
					line1Text = displayName
				end
			end
		else
			-- Offline
			if not usedExternalFormatter then
				line1Text = "|cff7f7f7f" .. displayName .. "|r"
			end
		end

		-- Compact Mode Append (BNet)
		local infoDisabled = self.settingsCache.infoDisabled or false
		if isCompactMode or infoDisabled then
			if not usedExternalFormatter then
				line1BaseText = line1Text
				-- Phase 22: Use FormatInfoLine for compact suffix
				local infoLine = not infoDisabled and self:FormatInfoLine(friend)
				if infoLine and infoLine ~= "" then
					local infoColor = self.settingsCache.fontColorFriendInfo or { r = 0.5, g = 0.5, b = 0.5, a = 1 }
					local infoHex = FormatColorCode(infoColor.r, infoColor.g, infoColor.b, infoColor.a)
					if friend.connected then
						line1SuffixText = infoHex .. " - " .. infoLine .. "|r"
					else
						line1SuffixText = " " .. infoHex .. "- " .. infoLine .. "|r"
					end
					line1Text = line1Text .. line1SuffixText
				end
			end
		else
			-- Normal Mode Line 2 (Phase 22: Use FormatInfoLine)
			line2Text = self:FormatInfoLine(friend) or ""
		end
	else
		-- WoW Friend
		local playerFactionGroup = UnitFactionGroup("player")
		local grayOtherFaction = self.settingsCache.grayOtherFaction
		local showFactionIcons = self.settingsCache.showFactionIcons
		local showRealmName = self.settingsCache.showRealmName

		if friend.connected then
			if not usedExternalFormatter then
				local isOppositeFaction = friend.factionName
					and friend.factionName ~= playerFactionGroup
					and friend.factionName ~= ""
				local shouldGray = grayOtherFaction and isOppositeFaction

				local characterName = displayName

				if showFactionIcons and friend.factionName then
					if friend.factionName == "Horde" then
						characterName = "|TInterface\\FriendsFrame\\PlusManz-Horde:12:12:0:0|t" .. characterName
					elseif friend.factionName == "Alliance" then
						characterName = "|TInterface\\FriendsFrame\\PlusManz-Alliance:12:12:0:0|t" .. characterName
					end
				end

				local useClassColor = self.settingsCache.colorClassNames
				if useClassColor == nil then
					useClassColor = true
				end

				if useClassColor and not shouldGray then
					local classFile = GetClassFileFromClassName(friend.className)
					local classColor = classFile and RAID_CLASS_COLORS[classFile]
					if classColor then
						line1Text = "|c" .. (classColor.colorStr or "ffffffff") .. characterName .. "|r"
					else
						line1Text = characterName
					end
				else
					if shouldGray then
						line1Text = "|cff808080" .. characterName .. "|r"
					else
						line1Text = characterName
					end
				end
			end
		else
			if not usedExternalFormatter then
				line1Text = "|cff7f7f7f" .. displayName .. "|r"
			end
		end

		-- Compact Mode Append (WoW)
		local infoDisabledWow = self.settingsCache.infoDisabled or false
		if isCompactMode or infoDisabledWow then
			if not usedExternalFormatter then
				line1BaseText = line1Text
				-- Phase 22: Use FormatInfoLine for compact suffix
				local infoLine = not infoDisabledWow and self:FormatInfoLine(friend)
				if infoLine and infoLine ~= "" and friend.connected then
					local infoColor = self.settingsCache.fontColorFriendInfo or { r = 0.5, g = 0.5, b = 0.5, a = 1 }
					local infoHex = FormatColorCode(infoColor.r, infoColor.g, infoColor.b, infoColor.a)
					line1SuffixText = infoHex .. " - " .. infoLine .. "|r"
					line1Text = line1Text .. line1SuffixText
				end
			end
		else
			-- Normal Mode Line 2 (Phase 22: Use FormatInfoLine)
			line2Text = self:FormatInfoLine(friend) or ""
		end
	end

	if line1BaseText == "" then
		line1BaseText = line1Text
	end

	-- Store in cache
	friend._cache_text_version = currentSettingsVersion
	friend._cache_text_compact = isCompactMode
	friend._cache_text_line1 = line1Text
	friend._cache_text_line1_base = line1BaseText
	friend._cache_text_line1_suffix = line1SuffixText
	friend._cache_text_line2 = line2Text

	return line1Text, line2Text
end

local function ApplyClientIcon(texture, clientProgram, iconSize)
	if not texture then
		return
	end

	texture:SetTexCoord(0, 1, 0, 1)

	local applied = false

	-- Use C_Texture.SetTitleIconTexture (same API the primary game icon uses)
	if
		not applied
		and clientProgram
		and C_Texture
		and C_Texture.SetTitleIconTexture
		and Enum
		and Enum.TitleIconVersion
	then
		local ok = pcall(C_Texture.SetTitleIconTexture, texture, clientProgram, Enum.TitleIconVersion.Small)
		if ok then
			applied = true
		end
	end

	-- Classic fallback: BNet_GetClientTexture returns a file path
	if not applied and clientProgram and BNet_GetClientTexture then
		local texturePath = BNet_GetClientTexture(clientProgram)
		if texturePath then
			texture:SetTexture(texturePath)
			applied = true
		end
	end

	if not applied then
		texture:SetTexture("Interface\\FriendsFrame\\Battlenet-Battleneticon")
	end

	if iconSize then
		texture:SetSize(iconSize, iconSize)
	end
end

-- Returns an embedded texture string (|T...|t) for a game client icon, for use in text/menu labels
function BFL:GetClientEmbeddedIcon(clientProgram, size)
	if not clientProgram then
		return ""
	end
	size = size or 16

	-- Retail: Use C_Texture API for proper high-res icon
	if
		C_Texture
		and C_Texture.GetTitleIconTexture
		and C_Texture.IsTitleIconTextureReady
		and Enum
		and Enum.TitleIconVersion
		and C_Texture.IsTitleIconTextureReady(clientProgram, Enum.TitleIconVersion.Small)
	then
		local iconStr = ""
		C_Texture.GetTitleIconTexture(clientProgram, Enum.TitleIconVersion.Small, function(success, texture)
			if success and BNet_GetClientEmbeddedTexture then
				iconStr = BNet_GetClientEmbeddedTexture(texture, size, size, 0) .. " "
			end
		end)
		if iconStr ~= "" then
			return iconStr
		end
	end

	-- Classic fallback: BNet_GetClientTexture
	if BNet_GetClientTexture then
		local texturePath = BNet_GetClientTexture(clientProgram)
		if texturePath then
			if BNet_GetClientEmbeddedTexture then
				return BNet_GetClientEmbeddedTexture(texturePath, size, size, 0) .. " "
			else
				return "|T" .. texturePath .. ":" .. size .. ":" .. size .. ":0:0|t "
			end
		end
	end

	return ""
end

function FriendsList:UpdateMultiAccountRow(button, friend, availableWidth)
	local row = button and button.multiAccountRow
	if not row then
		return
	end

	local data = BuildMultiAccountRowData(self, friend)
	if not data or not data.entries or #data.entries == 0 then
		row:Hide()
		if button then
			button.lastHasMultiAccountRow = false
		end
		return
	end

	button.lastHasMultiAccountRow = true
	local infoFontPath = self.fontCache and self.fontCache.infoPath
	local infoFontSize = self.fontCache and self.fontCache.infoSize or BASE_FONT_SIZE
	local infoFontOutline = self.fontCache and self.fontCache.infoOutline or "NONE"
	if infoFontOutline == "NONE" then
		infoFontOutline = ""
	end
	local infoShadow = self.fontCache and self.fontCache.infoShadow
	local infoR = (self.fontCache and self.fontCache.infoR) or 0.5
	local infoG = (self.fontCache and self.fontCache.infoG) or 0.5
	local infoB = (self.fontCache and self.fontCache.infoB) or 0.5
	local infoA = (self.fontCache and self.fontCache.infoA) or 1

	local rowWidth = availableWidth or row:GetWidth() or (button and button.Name and button.Name:GetWidth()) or 0
	if not rowWidth or rowWidth <= 0 then
		rowWidth = (self.GetButtonWidth and self:GetButtonWidth()) or 200
	end
	rowWidth = math.max(rowWidth, 120) -- Ensure usable width for text/icon layout
	local iconSize = math.max(12, math.floor(infoFontSize * 1.2))
	local rowHeight = math.max(iconSize, infoFontSize + 2)
	row:SetHeight(rowHeight)
	row:SetWidth(rowWidth)

	row:ClearAllPoints()
	row:SetPoint("TOPLEFT", button.Info, "BOTTOMLEFT", 0, -2)
	row:SetPoint("TOPRIGHT", button.Info, "BOTTOMRIGHT", 0, -2)

	for _, entry in ipairs(row.entries) do
		entry:Hide()
	end
	if row.remainderText then
		row.remainderText:Hide()
	end

	local cursorX = 0
	for idx, entryData in ipairs(data.entries or {}) do
		local entryFrame = row.entries[idx]
		if not entryFrame then
			break
		end

		entryFrame:ClearAllPoints()
		entryFrame:SetPoint("LEFT", row, "LEFT", cursorX, 0)
		entryFrame:SetSize(rowWidth - cursorX, rowHeight)

		ApplyClientIcon(entryFrame.icon, entryData.clientProgram, iconSize)
		entryFrame.icon:SetSize(iconSize, iconSize)
		entryFrame.icon:Show()

		if infoFontPath then
			entryFrame.text:SetFont(infoFontPath, infoFontSize, infoFontOutline)
		end
		if infoShadow then
			entryFrame.text:SetShadowOffset(1, -1)
		else
			entryFrame.text:SetShadowOffset(0, 0)
		end
		entryFrame.text:SetTextColor(infoR, infoG, infoB, infoA)
		entryFrame.text:SetWidth(math.max(0, rowWidth - cursorX - iconSize - 4))

		-- Build display text: name + info (level, zone or richPresence)
		local displayText = entryData.name or ""
		local isWoW = entryData.clientProgram == (BNET_CLIENT_WOW or "WoW")
		if isWoW then
			local infoParts = {}
			local level = entryData.level
			local zone = entryData.zone
			local hideMaxLevel = self.settingsCache.hideMaxLevel
			local maxLevel = BFL.GetMaxLevel and BFL.GetMaxLevel() or 80
			if level and level > 0 then
				if not (hideMaxLevel and level == maxLevel) then
					infoParts[#infoParts + 1] = string.format((L and L.LEVEL_FORMAT) or "Lvl %d", level)
				end
			end
			if zone and zone ~= "" then
				infoParts[#infoParts + 1] = zone
			end
			if #infoParts > 0 then
				displayText = displayText .. " - " .. table.concat(infoParts, ", ")
			end
		else
			-- Non-WoW game: name IS the richPresence already (set in BuildMultiAccountRowData)
			-- No additional info to append
		end

		entryFrame.text:SetText(displayText)

		local textWidth = entryFrame.text:GetStringWidth() or 0
		cursorX = cursorX + iconSize + textWidth + 8

		entryFrame:Show()
	end

	if data.remainder and data.remainder > 0 and row.remainderText then
		if infoFontPath then
			row.remainderText:SetFont(infoFontPath, infoFontSize, infoFontOutline)
		end
		if infoShadow then
			row.remainderText:SetShadowOffset(1, -1)
		else
			row.remainderText:SetShadowOffset(0, 0)
		end
		row.remainderText:SetTextColor(infoR, infoG, infoB, infoA)
		row.remainderText:ClearAllPoints()
		row.remainderText:SetPoint("LEFT", row, "LEFT", cursorX, 0)
		row.remainderText:SetWidth(math.max(0, rowWidth - cursorX))
		row.remainderText:SetText(string.format((L and L.INFO_MULTI_ACCOUNT_REMAINDER) or " (+%d)", data.remainder))
		row.remainderText:Show()
	end

	row:Show()
end

-- Update friend button (called by ScrollBox factory for each visible friend)
function FriendsList:UpdateFriendButton(button, elementData)
	local friend = elementData.friend
	local groupId = elementData.groupId

	-- Store friend data on button for tooltip and context menu
	button.friendIndex = friend.index
	button.friendData = friend
	button.groupId = groupId

	-- Sync selection highlight state to correct data
	if button.selectionHighlight then
		if self.selectedFriend == friend then
			button.selectionHighlight:Show()
			self.selectedButton = button
		else
			button.selectionHighlight:Hide()
		end
	end

	-- [Phase 5 Optimized] Static setup moved to InitFriendButton (friendInfo removed, using friendData)

	-- PERFY OPTIMIZATION: Direct cache access (auto-refreshed at entry)
	local isCompactMode = self.settingsCache.compactMode or false
	local showGameIcon = self.settingsCache.showGameIcon
	if showGameIcon == nil then
		showGameIcon = true
	end

	local hasMultiAccountRow = ShouldShowMultiAccountRow(self, friend)

	-- Hide arrows if they exist
	if button.RightArrow then
		button.RightArrow:Hide()
	end
	if button.DownArrow then
		button.DownArrow:Hide()
	end

	-- Reset drag overlay (Fix for recycled buttons showing "multiple drags")
	if button.dragOverlay then
		button.dragOverlay:Hide()
	end

	-- Calculate dynamic row height for icon positioning (needed for layout updates)
	local nameSize = self.fontCache and self.fontCache.nameSize or BASE_FONT_SIZE
	local infoSize = self.fontCache and self.fontCache.infoSize or BASE_FONT_SIZE
	local rowHeight = button:GetHeight()
		or CalculateFriendRowHeight(
			isCompactMode,
			nameSize,
			infoSize,
			self.settingsCache.infoDisabled,
			hasMultiAccountRow
		)
	local iconBaseRowHeight =
		CalculateFriendRowHeight(isCompactMode, nameSize, infoSize, self.settingsCache.infoDisabled, false)

	-- Compact mode: actual row height may be smaller than the 2-line fallback used by
	-- CalculateFriendRowHeight. Clamp icon base so icons never exceed the real row.
	if iconBaseRowHeight > rowHeight then
		iconBaseRowHeight = rowHeight
	end

	-- OPTIMIZATION: Layout Caching (Phase 9.9)
	-- Update layout if CompactMode changed OR font version changed OR row height changed
	local infoDisabled = self.settingsCache.infoDisabled or false
	local layoutChanged = button.lastCompactMode ~= isCompactMode
		or button.lastLayoutFontVersion ~= self.fontCacheVersion
		or button.lastRowHeight ~= rowHeight
		or button.lastInfoDisabled ~= infoDisabled
		or button.lastHasMultiAccountRow ~= hasMultiAccountRow
	if layoutChanged then
		button.lastCompactMode = isCompactMode
		button.lastLayoutFontVersion = self.fontCacheVersion
		button.lastRowHeight = rowHeight
		button.lastInfoDisabled = infoDisabled
		button.lastHasMultiAccountRow = hasMultiAccountRow

		-- Reset name position based on compact mode and info disabled state
		if isCompactMode or infoDisabled then
			button.Name:SetPoint("LEFT", 44, 0) -- Centered vertically for single line
		else
			button.Name:SetPoint("LEFT", 44, 7) -- Upper position for two lines
		end

		-- Show/hide friend elements based on compact mode and info disabled state
		if isCompactMode then
			button.Info:Hide() -- Hide second line in compact mode
			-- Allow name to wrap to 2 lines since info is hidden
			if button.Name.SetMaxLines then
				button.Name:SetMaxLines(2)
			end
			if button.Info.SetMaxLines then
				button.Info:SetMaxLines(2)
			end
		elseif infoDisabled then
			button.Info:Hide() -- Hide second line when info is disabled
			-- Single line only (row height is slim, no space for wrapping)
			if button.Name.SetMaxLines then
				button.Name:SetMaxLines(1)
			end
		else
			button.Info:Show()
			-- Normal mode: no wrapping, truncate with ellipsis
			if button.Name.SetMaxLines then
				button.Name:SetMaxLines(1)
			end
			if button.Info.SetMaxLines then
				button.Info:SetMaxLines(1)
			end
		end

		-- Invalidate favorite icon cache to force repositioning
		button.lastIsFavorite = nil
		-- CRITICAL: Also hide the icon immediately to prevent stale display on recycled buttons
		-- Without this, setting lastIsFavorite=nil when the new friend also has showFavIcon=nil
		-- causes nil~=nil -> false, skipping the hide logic entirely
		if button.favoriteIcon then
			button.favoriteIcon:Hide()
		end

		-- All icons scale proportionally to row height (no artificial min/max limits)
		-- Status icon: 16px at 34px row height = 47%
		local statusSize = math.floor(iconBaseRowHeight * 0.47)
		local statusYOffset = -math.floor((rowHeight - statusSize) / 2)
		button.status:SetSize(statusSize, statusSize)
		button.status:ClearAllPoints()
		button.status:SetPoint("TOPLEFT", 4, statusYOffset)

		-- Game icon: 28px at 34px row height = 82%
		local gameIconSize = math.floor(iconBaseRowHeight * 0.82)
		local gameIconYOffset = -math.floor((rowHeight - gameIconSize) / 2)
		button.gameIcon:SetSize(gameIconSize, gameIconSize)
		button.gameIcon:ClearAllPoints()
		button.gameIcon:SetPoint("TOPRIGHT", -30, gameIconYOffset)

		-- TravelPass button: 32px height at 34px row height = 94%, aspect ratio 3:4
		if button.travelPassButton then
			local tpHeight = math.floor(iconBaseRowHeight * 0.94)
			local tpWidth = math.floor(tpHeight * 0.75)
			local tpYOffset = -math.floor((rowHeight - tpHeight) / 2)
			button.travelPassButton:SetSize(tpWidth, tpHeight)
			button.travelPassButton:ClearAllPoints()
			button.travelPassButton:SetPoint("TOPRIGHT", 0, tpYOffset)

			-- Scale textures
			button.travelPassButton.NormalTexture:SetSize(tpWidth, tpHeight)
			button.travelPassButton.PushedTexture:SetSize(tpWidth, tpHeight)
			button.travelPassButton.DisabledTexture:SetSize(tpWidth, tpHeight)
			button.travelPassButton.HighlightTexture:SetSize(tpWidth, tpHeight)
		end
	end

	-- OPTIMIZATION: Font Caching (Phase 9.9)
	-- Only apply font if settings changed (version check)
	local fontChanged = false
	if self.fontCache and button.lastFontVersion ~= self.fontCacheVersion then
		button.lastFontVersion = self.fontCacheVersion
		fontChanged = true

		-- Apply Friend Name Font Settings
		if self.fontCache.namePath then
			local outline = self.fontCache.nameOutline
			if outline == "NONE" then
				outline = ""
			end

			-- Use FontManager to apply font with Alphabet support
			if BFL.FontManager and BFL.FontManager.ApplyFont then
				BFL.FontManager:ApplyFont(
					button.Name,
					self.fontCache.namePath,
					self.fontCache.nameSize,
					outline,
					self.fontCache.nameShadow
				)
			else
				button.Name:SetFont(self.fontCache.namePath, self.fontCache.nameSize, outline)
				if self.fontCache.nameShadow then
					button.Name:SetShadowColor(0, 0, 0, 1)
					button.Name:SetShadowOffset(1, -1)
				else
					button.Name:SetShadowColor(0, 0, 0, 0)
					button.Name:SetShadowOffset(0, 0)
				end
			end

			button.Name:SetTextColor(
				self.fontCache.nameR,
				self.fontCache.nameG,
				self.fontCache.nameB,
				self.fontCache.nameA
			)
		end

		-- Apply Friend Info Font Settings
		if not isCompactMode and self.fontCache.infoPath then
			local outline = self.fontCache.infoOutline
			if outline == "NONE" then
				outline = ""
			end

			-- Use FontManager to apply font with Alphabet support
			if BFL.FontManager and BFL.FontManager.ApplyFont then
				BFL.FontManager:ApplyFont(
					button.Info,
					self.fontCache.infoPath,
					self.fontCache.infoSize,
					outline,
					self.fontCache.infoShadow
				)
			else
				button.Info:SetFont(self.fontCache.infoPath, self.fontCache.infoSize, outline)

				if self.fontCache.infoShadow then
					button.Info:SetShadowColor(0, 0, 0, 1)
					button.Info:SetShadowOffset(1, -1)
				else
					button.Info:SetShadowColor(0, 0, 0, 0)
					button.Info:SetShadowOffset(0, 0)
				end
			end

			button.Info:SetTextColor(
				self.fontCache.infoR,
				self.fontCache.infoG,
				self.fontCache.infoB,
				self.fontCache.infoA
			)
		end
	end

	-- Ensure status is shown (needed if button was recycled or hidden elsewhere)
	button.status:Show()

	if friend.type == "bnet" then
		-- Battle.net friend
		-- Feature: Flexible Name Format (Phase 15)
		local displayName = friend.displayName or self:GetDisplayName(friend)

		-- Set background color (Optimized Phase 4: State Check)
		local bgR, bgG, bgB, bgA
		if friend.connected then
			bgR, bgG, bgB, bgA =
				FRIENDS_BNET_BACKGROUND_COLOR.r,
				FRIENDS_BNET_BACKGROUND_COLOR.g,
				FRIENDS_BNET_BACKGROUND_COLOR.b,
				FRIENDS_BNET_BACKGROUND_COLOR.a

			-- Phase 4.1: Faction Background
			if self.settingsCache.showFactionBg then
				local faction = friend.factionName
				if not faction and friend.gameAccountInfo then
					faction = friend.gameAccountInfo.factionName
				end

				-- English Faction (Alliance/Horde)
				local playerFaction = self.playerFaction

				-- Expanded Logic: Check for English, German, and Player Faction match
				-- Note: We check for "Alliance" (English) and "Allianz" (German) explicitly as requested
				if faction == "Alliance" or faction == "Allianz" then
					bgR, bgG, bgB, bgA = 0.0, 0.44, 0.87, 0.2 -- Alliance Blue
				elseif faction == "Horde" then
					bgR, bgG, bgB, bgA = 0.80, 0.16, 0.16, 0.2 -- Horde Red
				elseif playerFaction and faction == playerFaction then
					-- Fallback: If localized string matches player faction return
					if playerFaction == "Alliance" then
						bgR, bgG, bgB, bgA = 0.0, 0.44, 0.87, 0.2
					elseif playerFaction == "Horde" then
						bgR, bgG, bgB, bgA = 0.80, 0.16, 0.16, 0.2
					end
				else
				end
			end
		else
			bgR, bgG, bgB, bgA =
				FRIENDS_OFFLINE_BACKGROUND_COLOR.r,
				FRIENDS_OFFLINE_BACKGROUND_COLOR.g,
				FRIENDS_OFFLINE_BACKGROUND_COLOR.b,
				FRIENDS_OFFLINE_BACKGROUND_COLOR.a
		end

		-- Explicit check for ANY change including Alpha
		if button.lastBgR ~= bgR or button.lastBgG ~= bgG or button.lastBgB ~= bgB or button.lastBgA ~= bgA then
			button.background:SetColorTexture(bgR, bgG, bgB, bgA)
			button.lastBgR, button.lastBgG, button.lastBgB, button.lastBgA = bgR, bgG, bgB, bgA
		end

		-- Set status icon (BSAp shows as AFK if setting enabled)
		-- PERFY OPTIMIZATION: Direct cache access
		local showMobileAsAFK = self.settingsCache.showMobileAsAFK or false
		local statusTexture

		if friend.connected then
			local isMobile = friend.gameAccountInfo and friend.gameAccountInfo.clientProgram == "BSAp"
			-- Check both account status (App) and game status (WoW /afk)
			local isAFK = friend.isAFK
				or (friend.gameAccountInfo and (friend.gameAccountInfo.isAFK or friend.gameAccountInfo.isGameAFK))
			local isDND = friend.isDND
				or (friend.gameAccountInfo and (friend.gameAccountInfo.isDND or friend.gameAccountInfo.isGameBusy))

			if isDND then
				statusTexture = "Interface\\FriendsFrame\\StatusIcon-DnD"
			elseif isAFK or (showMobileAsAFK and isMobile) then
				statusTexture = "Interface\\FriendsFrame\\StatusIcon-Away"
			else
				statusTexture = "Interface\\FriendsFrame\\StatusIcon-Online"
			end
		else
			statusTexture = "Interface\\FriendsFrame\\StatusIcon-Offline"
		end

		if button.lastStatusTexture ~= statusTexture then
			button.status:SetTexture(statusTexture)
			button.lastStatusTexture = statusTexture
		end

		-- Set game icon using Blizzard's modern API
		if friend.gameAccountInfo and friend.gameAccountInfo.clientProgram and friend.connected then
			local clientProgram = friend.gameAccountInfo.clientProgram

			local canSetTitleIcon = false
			if C_Texture and C_Texture.SetTitleIconTexture then
				if Enum and Enum.TitleIconVersion then
					canSetTitleIcon = true
				end
			end
			if canSetTitleIcon then
				-- Use Blizzard's modern texture API (11.0+) for ALL client programs including Battle.net App
				-- Optimized Phase 4: Avoid C-Call if unnecessary (though SetTitleIconTexture is fast, avoiding it is faster)
				if button.lastClientProgram ~= clientProgram then
					C_Texture.SetTitleIconTexture(button.gameIcon, clientProgram, Enum.TitleIconVersion.Medium)
					button.lastClientProgram = clientProgram
				end

				-- Fade icon for WoW friends on different project versions
				local fadeIcon = (clientProgram == BNET_CLIENT_WOW)
					and (friend.gameAccountInfo.wowProjectID ~= WOW_PROJECT_ID)
				local targetAlpha = fadeIcon and 0.6 or 1

				if button.lastGameIconAlpha ~= targetAlpha then
					button.gameIcon:SetAlpha(targetAlpha)
					button.lastGameIconAlpha = targetAlpha
				end

				button.gameIcon:Show()
			else
				button.gameIcon:Hide()
				button.lastClientProgram = nil
			end
		else
			button.gameIcon:Hide()
			button.lastClientProgram = nil -- Reset state
		end

		-- Game icon overlay: clickable for BNet friends with multiple game accounts
		if button.gameIconOverlay then
			local showOverlay = friend.type == "bnet"
				and friend.connected
				and friend.gameAccounts
				and #friend.gameAccounts > 1
				and button.gameIcon:IsShown()
			if showOverlay then
				button.gameIconOverlay.friendData = friend
				button.gameIconOverlay:ClearAllPoints()
				button.gameIconOverlay:SetAllPoints(button.gameIcon)
				button.gameIconOverlay:SetFrameLevel(button:GetFrameLevel() + 10)
				button.gameIconOverlay:Show()
			else
				button.gameIconOverlay.friendData = nil
				button.gameIconOverlay:Hide()
			end
		end

		-- Multi-Game-Account Badge: Show count when friend has multiple game accounts online
		if button.gameAccountBadge then
			local showBadge = self.settingsCache.showMultiAccountBadge
				and friend.connected
				and friend.numGameAccounts
				and friend.numGameAccounts > 1
			if showBadge then
				local countStr = tostring(friend.numGameAccounts)
				if button.lastBadgeCount ~= countStr then
					button.gameAccountBadgeText:SetText(countStr)
					button.lastBadgeCount = countStr
				end

				local iconSize = button.gameIcon and button.gameIcon:GetWidth() or 28
				local badgeSize = math.max(14, math.floor(iconSize * 0.54))
				button.gameAccountBadge:SetSize(badgeSize, badgeSize)
				if button.gameAccountBadgeText and button.gameAccountBadgeText.SetFont then
					local fontHeight = math.max(10, math.floor(badgeSize * 0.55))
					button.gameAccountBadgeText:SetFont(STANDARD_TEXT_FONT, fontHeight, "OUTLINE")
				end

				button.gameAccountBadge:ClearAllPoints()
				button.gameAccountBadge:SetPoint("BOTTOMRIGHT", button.gameIcon, "BOTTOMRIGHT", 4, -4)
				button.gameAccountBadge:Show()
				button.gameAccountBadgeBg:Show()
				button.gameAccountBadgeText:Show()

				if button.gameAccountDotsFrame and button.gameAccountDots then
					button.gameAccountDotsFrame:Hide()
					for i = 1, 3 do
						if button.gameAccountDots[i] then
							button.gameAccountDots[i]:Hide()
						end
					end
				end
			else
				button.gameAccountBadge:Hide()
				button.gameAccountBadgeBg:Hide()
				button.gameAccountBadgeText:Hide()
				button.lastBadgeCount = nil

				if button.gameAccountDotsFrame and button.gameAccountDots then
					button.gameAccountDotsFrame:Hide()
					for i = 1, 3 do
						if button.gameAccountDots[i] then
							button.gameAccountDots[i]:Hide()
						end
					end
				end
			end
		end

		-- Handle TravelPass button for Battle.net friends
		-- Optimized Phase 4: Use Pre-Calculated Data (O(1) complexity)
		if button.travelPassButton then
			if friend.connected then
				-- Store friend index for click handler
				button.travelPassButton.friendIndex = friend.index
				button.travelPassButton.friendData = friend

				-- Enable/disable button based on restriction (Pre-calculated)
				if friend.canInvite then
					button.travelPassButton:Enable()
				else
					button.travelPassButton:Disable()
				end

				-- Set atlas based on faction for cross-faction invites
				if not BFL.IsClassic then
					local targetAtlas = friend.inviteAtlas or "default"
					if button.lastInviteAtlas ~= targetAtlas then
						button.lastInviteAtlas = targetAtlas

						if targetAtlas == "horde" then
							button.travelPassButton.NormalTexture:SetAtlas("friendslist-invitebutton-horde-normal")
							button.travelPassButton.PushedTexture:SetAtlas("friendslist-invitebutton-horde-pressed")
							button.travelPassButton.DisabledTexture:SetAtlas("friendslist-invitebutton-horde-disabled")
						elseif targetAtlas == "alliance" then
							button.travelPassButton.NormalTexture:SetAtlas("friendslist-invitebutton-alliance-normal")
							button.travelPassButton.PushedTexture:SetAtlas("friendslist-invitebutton-alliance-pressed")
							button.travelPassButton.DisabledTexture:SetAtlas(
								"friendslist-invitebutton-alliance-disabled"
							)
						else -- default (also covers BNet-only friends with no inviteAtlas)
							button.travelPassButton.NormalTexture:SetAtlas("friendslist-invitebutton-default-normal")
							button.travelPassButton.PushedTexture:SetAtlas("friendslist-invitebutton-default-pressed")
							button.travelPassButton.DisabledTexture:SetAtlas(
								"friendslist-invitebutton-default-disabled"
							)
						end
					end
				end
				-- Classic: Uses file-based textures from XML (Interface\FriendsFrame\TravelPass-Invite)

				button.travelPassButton:Show()
			else
				button.lastInviteAtlas = nil -- Reset state
				button.travelPassButton:Hide()
			end
		end

		-- Text handled by optimized shared cache (Phase 21)
	else
		-- WoW friend
		-- Set background color (Optimized Phase 4: State Check)
		local bgR, bgG, bgB, bgA
		if friend.connected then
			bgR, bgG, bgB, bgA =
				FRIENDS_WOW_BACKGROUND_COLOR.r,
				FRIENDS_WOW_BACKGROUND_COLOR.g,
				FRIENDS_WOW_BACKGROUND_COLOR.b,
				FRIENDS_WOW_BACKGROUND_COLOR.a

			-- Phase 4.1: Faction Background
			if self.settingsCache.showFactionBg then
				-- WoW friends are typically same faction as player
				local playerFaction = self.playerFaction

				if playerFaction == "Alliance" then
					bgR, bgG, bgB, bgA = 0.0, 0.44, 0.87, 0.2 -- Alliance Blue
				elseif playerFaction == "Horde" then
					bgR, bgG, bgB, bgA = 0.80, 0.16, 0.16, 0.2 -- Horde Red
				end
			end
		else
			bgR, bgG, bgB, bgA =
				FRIENDS_OFFLINE_BACKGROUND_COLOR.r,
				FRIENDS_OFFLINE_BACKGROUND_COLOR.g,
				FRIENDS_OFFLINE_BACKGROUND_COLOR.b,
				FRIENDS_OFFLINE_BACKGROUND_COLOR.a
		end

		if button.lastBgR ~= bgR or button.lastBgG ~= bgG or button.lastBgB ~= bgB or button.lastBgA ~= bgA then
			button.background:SetColorTexture(bgR, bgG, bgB, bgA)
			button.lastBgR, button.lastBgG, button.lastBgB, button.lastBgA = bgR, bgG, bgB, bgA
		end

		-- Set status icon
		local statusTexture
		if friend.connected then
			if friend.dnd then
				statusTexture = "Interface\\FriendsFrame\\StatusIcon-DnD"
			elseif friend.afk then
				statusTexture = "Interface\\FriendsFrame\\StatusIcon-Away"
			else
				statusTexture = "Interface\\FriendsFrame\\StatusIcon-Online"
			end
		else
			statusTexture = "Interface\\FriendsFrame\\StatusIcon-Offline"
		end

		if button.lastStatusTexture ~= statusTexture then
			button.status:SetTexture(statusTexture)
			button.lastStatusTexture = statusTexture
		end

		button.gameIcon:Hide()
		button.lastClientProgram = nil -- Reset state

		-- Hide badge for WoW friends (only BNet friends have multi-account)
		if button.gameAccountBadge then
			button.gameAccountBadge:Hide()
			button.gameAccountBadgeBg:Hide()
			button.gameAccountBadgeText:Hide()
			button.lastBadgeCount = nil
			if button.gameAccountDotsFrame and button.gameAccountDots then
				button.gameAccountDotsFrame:Hide()
				for i = 1, 3 do
					if button.gameAccountDots[i] then
						button.gameAccountDots[i]:Hide()
					end
				end
			end
		end

		-- Hide TravelPass button for WoW friends (they don't have it)
		if button.travelPassButton then
			button.travelPassButton:Hide()
		end

		-- Text handled by optimized shared cache (Phase 21)
	end -- end of if friend.type == "bnet"

	-- OPTIMIZED: Use cached text generation (Phase 21)
	local line1Text, line2Text = self:GetFormattedButtonText(friend)
	local line1BaseText = friend._cache_text_line1_base or line1Text
	local line1SuffixText = friend._cache_text_line1_suffix or ""

	-- Favorites Icon (Feature: Display Favorites)
	-- CRITICAL: GetStringWidth/Height are EXPENSIVE WoW API calls - only call when state changes!
	-- Guard: Only BNet friends can have favorites (WoW friends never have isFavorite)
	local isFavorite = (friend.type == "bnet") and friend.isFavorite
	local showFavIcon = isFavorite and self.settingsCache.enableFavoriteIcon

	-- Optimized Phase 4: State Check for Text
	local textChanged = false
	local displayLine1 = line1Text
	if isCompactMode and line1SuffixText ~= "" and showFavIcon then
		local spacer = "  "
		if (self.settingsCache and self.settingsCache.favoriteIconStyle) == "blizzard" then
			spacer = "     "
		end
		displayLine1 = line1BaseText .. spacer .. line1SuffixText
	end
	if button.lastLine1Text ~= displayLine1 then
		EnsureFontSet(button.Name)
		button.Name:SetText(displayLine1)
		button.lastLine1Text = displayLine1
		textChanged = true
	end

	-- We check if favorite state changed OR if the text changed (which means width changed)
	-- Also check if font changed, as that affects text width
	if button.lastIsFavorite ~= showFavIcon or (showFavIcon and (textChanged or fontChanged)) then
		button.lastIsFavorite = showFavIcon

		if showFavIcon then
			-- Ensure icon exists (Safety fallback)
			if not button.favoriteIcon then
				button.favoriteIcon = button:CreateTexture(nil, "OVERLAY")
				button.favoriteIcon:SetTexture("Interface\\AddOns\\BetterFriendlist\\Icons\\star")
			end

			local iconStyle = self.settingsCache and self.settingsCache.favoriteIconStyle or "bfl"
			if button.lastFavoriteIconStyle ~= iconStyle then
				if iconStyle == "blizzard" then
					local applied = false
					if
						C_Texture
						and C_Texture.GetAtlasInfo
						and C_Texture.GetAtlasInfo("friendslist-favorite")
						and button.favoriteIcon.SetAtlas
					then
						button.favoriteIcon:SetAtlas("friendslist-favorite", true)
						applied = true
					elseif button.favoriteIcon.SetAtlas then
						button.favoriteIcon:SetAtlas("friendslist-favorite", true)
						applied = true
					end
					if not applied then
						button.favoriteIcon:SetTexture("Interface\\AddOns\\BetterFriendlist\\Icons\\star")
					end
				else
					button.favoriteIcon:SetTexture("Interface\\AddOns\\BetterFriendlist\\Icons\\star")
				end
				button.lastFavoriteIconStyle = iconStyle
			end

			-- Position Update Logic (Hoisted for reuse)
			local function UpdateFavoriteIconPosition()
				if not button or not button.Name or not button.favoriteIcon then
					return
				end

				local _, fontSize = button.Name:GetFont()
				local nameHeight = fontSize or 12
				local iconScale = 0.70
				if (self.settingsCache and self.settingsCache.favoriteIconStyle) == "blizzard" then
					iconScale = 1.2
				end
				local iconSize = math.floor(nameHeight * iconScale)
				button.favoriteIcon:SetSize(iconSize, iconSize)
				local iconYOffset = 0
				local iconPadding = 2
				if (self.settingsCache and self.settingsCache.favoriteIconStyle) == "blizzard" then
					-- Adjust X/Y offset to align Blizzard icon with BFL icon position
					local bflIconSize = math.floor(nameHeight * 0.70)
					iconYOffset = math.floor((iconSize - bflIconSize) / 2)
					iconPadding = 2 - math.floor((iconSize - bflIconSize) / 2)
				end

				-- Re-measure width (crucial for delayed updates)
				local currentWidth = button.Name:GetStringWidth() or 0
				local baseText = (line1BaseText ~= "" and line1BaseText) or line1Text
				local nameWidth = button.Name:GetWidth() or 0
				if baseText ~= "" and nameWidth > 0 then
					if not button.favoriteMeasure then
						button.favoriteMeasure = button:CreateFontString(nil, "ARTWORK")
						button.favoriteMeasure:Hide()
						button.favoriteMeasure:SetJustifyH("LEFT")
						button.favoriteMeasure:SetWordWrap(true)
					end

					if button.favoriteMeasureFontVersion ~= button.lastFontVersion then
						local fontPath, fontSize, fontFlags = button.Name:GetFont()
						if fontPath then
							button.favoriteMeasure:SetFont(fontPath, fontSize, fontFlags)
							button.favoriteMeasureFontVersion = button.lastFontVersion
						end
					end

					button.favoriteMeasure:SetWidth(nameWidth)
					if button.favoriteMeasure.SetMaxLines then
						button.favoriteMeasure:SetMaxLines(isCompactMode and 2 or 1)
					end
					EnsureFontSet(button.favoriteMeasure)
					button.favoriteMeasure:SetText(baseText)
					local baseWidth = button.favoriteMeasure:GetStringWidth() or 0
					if baseWidth > 0 then
						currentWidth = baseWidth
					end
				end

				button.favoriteIcon:ClearAllPoints()
				-- Offset relative to text start + text width
				button.favoriteIcon:SetPoint("TOPLEFT", button.Name, "TOPLEFT", currentWidth + iconPadding, iconYOffset)
				button.favoriteIcon:Show()
			end

			-- Apply immediately
			UpdateFavoriteIconPosition()

			-- CRITICAL FIX: Re-apply on next frame if font changed or on reload.
			-- After /reload or SetFont, GetStringWidth() often returns 0 or incorrect values.
			local targetFriend = friend
			if fontChanged or textChanged or needsRenderOnShow then -- Apply delay if any layout factor changed
				C_Timer.After(0, function()
					-- Only update if the button still belongs to the same friend
					if button and button.friendData == targetFriend then
						UpdateFavoriteIconPosition()
					end
				end)
			end
		else
			if button.favoriteIcon then
				button.favoriteIcon:Hide()
			end
		end
	end

	if not isCompactMode then
		if button.lastLine2Text ~= line2Text then
			EnsureFontSet(button.Info)
			button.Info:SetText(line2Text)
			button.lastLine2Text = line2Text
		end
	end

	-- Auto-Resize Text: Calculate dynamic padding based on visible right-side elements
	local padding = 25 -- Base padding (safe margin from right edge)

	-- GameIcon (Status/Client) is at -38, width 28 -> Left edge at -66
	if button.gameIcon and button.gameIcon:IsShown() then
		padding = 80 -- Clear -66px with margin
	-- TravelPass (Invite) is at -8, width 24 -> Left edge at -32
	elseif button.travelPassButton and button.travelPassButton:IsShown() then
		padding = 45 -- Clear -32px with margin
	end

	if button.textRightPadding ~= padding then
		button.textRightPadding = padding
		-- Force update immediately if padding changed
		if button:GetScript("OnSizeChanged") then
			button:GetScript("OnSizeChanged")(button, button:GetWidth(), button:GetHeight())
		end
	end

	local nameWidth = (button.Name and button.Name:GetWidth()) or (self:GetButtonWidth() - 44 - padding)
	if nameWidth and nameWidth > 0 then
		self:UpdateMultiAccountRow(button, friend, nameWidth)
	else
		self:UpdateMultiAccountRow(button, friend)
	end

	-- Ensure button is visible
	button:Show()
end

-- ========================================
-- Friend Invite Functions
-- ========================================

function FriendsList:UpdateInviteHeaderButton(button, data)
	EnsureFontSet(button.Text)
	button.Text:SetFormattedText(L.INVITE_HEADER, data.count)
	local collapsed = GetCVarBool("friendInvitesCollapsed")

	-- Store data on button for callbacks (important for OnMouseUp refresh)
	button.elementData = data

	-- PERFY OPTIMIZATION: Direct cache access
	-- APPLY TEXT ALIGNMENT (Feature Request)
	local align = self.settingsCache.groupHeaderAlign or "LEFT"
	if button.Text then
		button.Text:ClearAllPoints()
		if align == "CENTER" then
			button.Text:SetPoint("CENTER", button, "CENTER", 0, 0)
			button.Text:SetJustifyH("CENTER")
		elseif align == "RIGHT" then
			button.Text:SetPoint("RIGHT", button, "RIGHT", -22, 0)
			button.Text:SetJustifyH("RIGHT")
		else -- "LEFT" (Default)
			button.Text:SetPoint("LEFT", button, "LEFT", 22, 0)
			button.Text:SetJustifyH("LEFT")
		end
	end

	-- PERFY OPTIMIZATION: Direct cache access
	-- ARROW ALIGNMENT & VISIBILITY
	local showArrow = self.settingsCache.showGroupArrow
	if showArrow == nil then
		showArrow = true
	end
	local arrowAlign = self.settingsCache.groupArrowAlign or "LEFT"

	-- Reset visibility
	if button.DownArrow then
		button.DownArrow:Hide()
	end
	if button.RightArrow then
		button.RightArrow:Hide()
	end

	if showArrow then
		local targetArrow = collapsed and button.RightArrow or button.DownArrow
		if targetArrow then
			targetArrow:Show()
			targetArrow:ClearAllPoints()

			-- Restore normal textures (resetting overrides)
			if BFL.IsClassic then
				if targetArrow == button.RightArrow then
					targetArrow:SetTexture("Interface\\AddOns\\BetterFriendlist\\Icons\\chevron-right")
				else
					targetArrow:SetTexture("Interface\\AddOns\\BetterFriendlist\\Icons\\chevron-down")
				end
			else
				if targetArrow == button.RightArrow then
					targetArrow:SetAtlas("friendslist-categorybutton-arrow-left")
					targetArrow:SetRotation(0)
				else
					targetArrow:SetAtlas("friendslist-categorybutton-arrow-down")
					targetArrow:SetRotation(0)
				end
			end

			-- Position Calculation
			local point, x, y
			if arrowAlign == "RIGHT" then
				point = "RIGHT"
				-- Flip right arrow to point left if aligned right
				if targetArrow == button.RightArrow then
					if not BFL.IsClassic then
						targetArrow:SetAtlas("friendslist-categorybutton-arrow-left")
						targetArrow:SetRotation(math.pi)
					else
						targetArrow:SetTexture("Interface\\AddOns\\BetterFriendlist\\Icons\\chevron-left")
					end
				end
				x = (targetArrow == button.DownArrow) and -8 or -6
				y = (targetArrow == button.DownArrow) and -2 or 0
			elseif arrowAlign == "CENTER" then
				point = "CENTER"
				if align == "CENTER" then
					local textWidth = button.Text and button.Text:GetStringWidth() or 0
					local offset = (textWidth / 2) + 12
					x = -offset
				else
					x = (targetArrow == button.DownArrow) and 0 or 2
				end
				y = (targetArrow == button.DownArrow) and -2 or 0
			else -- LEFT (Default)
				point = "LEFT"
				x = (targetArrow == button.DownArrow) and 6 or 8
				y = (targetArrow == button.DownArrow) and -2 or 0
			end

			targetArrow:SetPoint(point, x, y)

			-- Mouse Scripts for Arrow depression
			if not button.isArrowScriptHooked then
				button:SetScript("OnMouseDown", function(self)
					if self.DownArrow and self.DownArrow:IsShown() then
						local p, relativeTo, relativePoint, x, y = self.DownArrow:GetPoint()
						if p then
							self.DownArrow:SetPoint(p, relativeTo, relativePoint, x + 1, y - 1)
						end
					end
					if self.RightArrow and self.RightArrow:IsShown() then
						local p, relativeTo, relativePoint, x, y = self.RightArrow:GetPoint()
						if p then
							self.RightArrow:SetPoint(p, relativeTo, relativePoint, x + 1, y - 1)
						end
					end
				end)

				button:SetScript(
					"OnMouseUp",
					function(self) -- Trigger update via element factory if possible, or just re-run this function
						if FriendsList and FriendsList.UpdateInviteHeaderButton and self.elementData then
							FriendsList:UpdateInviteHeaderButton(self, self.elementData)
						end
					end
				)
				button.isArrowScriptHooked = true
			end
		end
	end

	-- Apply font scaling to header text
	local FontManager = BFL.FontManager
	if FontManager and button.Text then
		FontManager:ApplyFontSize(button.Text)
	end

	-- Setup OnClick handler for collapse/expand (only once)
	if not button.handlerRegistered then
		button:SetScript("OnClick", function(self)
			local collapsed = GetCVarBool("friendInvitesCollapsed")
			SetCVar("friendInvitesCollapsed", collapsed and "0" or "1")

			-- Force full rebuild of display list
			BFL:ForceRefreshFriendsList()
		end)
		button.handlerRegistered = true
	end

	-- Ensure button is visible
	button:Show()
end

-- Update invite button
function FriendsList:UpdateInviteButton(button, data)
	local inviteID, accountName

	-- Get invite info from mock or real API
	if BFL.MockFriendInvites.enabled then
		local mockInvite = BFL.MockFriendInvites.invites[data.inviteIndex]
		if mockInvite then
			inviteID = mockInvite.inviteID
			accountName = mockInvite.accountName
		end
	else
		inviteID, accountName = BNGetFriendInviteInfo(data.inviteIndex)
	end

	if not inviteID then
		return
	end

	-- Get current button height to determine if compact mode
	local height = button:GetHeight()
	local isCompact = height < 25

	-- Set name with cyan color (BNet style)
	EnsureFontSet(button.Name)
	button.Name:SetText((FRIENDS_BNET_NAME_COLOR_CODE or "|cff82c5ff") .. accountName .. "|r")

	-- Set Info text ALWAYS
	EnsureFontSet(button.Info)
	button.Info:SetText(L.INVITE_TAP_TEXT)

	-- Adjust positioning based on compact mode
	button.Name:ClearAllPoints()

	if isCompact then
		-- Compact mode: single line, vertically centered
		button.Name:SetPoint("LEFT", 10, 0)
		button.Info:Hide()
	else
		-- Normal mode: two-line layout (Info uses XML relative positioning)
		button.Name:SetPoint("TOPLEFT", 10, -6)
		button.Info:Show()
	end

	-- Apply font scaling (must be called after text is set)
	local FontManager = BFL.FontManager
	if FontManager then
		FontManager:ApplyFontSize(button.Name)
		if not isCompact then
			FontManager:ApplyFontSize(button.Info)
		end
		-- Apply to button text if exists
		if button.AcceptButton and button.AcceptButton:GetFontString() then
			FontManager:ApplyFontSize(button.AcceptButton:GetFontString())
		end
		if button.DeclineButton and button.DeclineButton:GetFontString() then
			FontManager:ApplyFontSize(button.DeclineButton:GetFontString())
		end
	end

	-- Store invite data
	button.inviteID = inviteID
	button.inviteIndex = data.inviteIndex

	-- Setup Accept button OnClick handler
	if button.AcceptButton and not button.AcceptButton.handlerRegistered then
		button.AcceptButton:SetScript("OnClick", function(self)
			local parent = self:GetParent()
			if parent.inviteID then
				if BFL.MockFriendInvites.enabled then
					-- Mock: Remove from list and refresh
					for i, invite in ipairs(BFL.MockFriendInvites.invites) do
						if invite.inviteID == parent.inviteID then
							table.remove(BFL.MockFriendInvites.invites, i)
							BFL:DebugPrint(
								"|cff00ff00BetterFriendlist:|r "
									.. string.format(BFL.L.MOCK_INVITE_ACCEPTED, invite.accountName)
							)
							break
						end
					end
					BFL:ForceRefreshFriendsList()
				else
					-- Real API call
					BNAcceptFriendInvite(parent.inviteID)
				end
			end
		end)
		button.AcceptButton.handlerRegistered = true
	end

	-- Setup Decline button OnClick handler
	if button.DeclineButton and not button.DeclineButton.handlerRegistered then
		button.DeclineButton:SetScript("OnClick", function(self)
			local parent = self:GetParent()
			if not parent.inviteID or not parent.inviteIndex then
				return
			end

			local inviteID, accountName

			-- Get invite info from mock or real API
			if BFL.MockFriendInvites.enabled then
				local mockInvite = BFL.MockFriendInvites.invites[parent.inviteIndex]
				if mockInvite then
					inviteID = mockInvite.inviteID
					accountName = mockInvite.accountName
				end
			else
				inviteID, accountName = BNGetFriendInviteInfo(parent.inviteIndex)
			end

			if not inviteID then
				return
			end

			MenuUtil.CreateContextMenu(self, function(owner, rootDescription)
				rootDescription:CreateButton("Decline", function()
					if BFL.MockFriendInvites.enabled then
						-- Mock: Remove from list and refresh
						for i, invite in ipairs(BFL.MockFriendInvites.invites) do
							if invite.inviteID == inviteID then
								table.remove(BFL.MockFriendInvites.invites, i)
								BFL:DebugPrint(
									"|cffff0000BetterFriendlist:|r "
										.. string.format(BFL.L.MOCK_INVITE_DECLINED, invite.accountName)
								)
								break
							end
						end
						BFL:ForceRefreshFriendsList()
					else
						-- Real API call
						BNDeclineFriendInvite(inviteID)
					end
				end)

				if not BFL.MockFriendInvites.enabled then
					rootDescription:CreateButton("Report Player", function()
						if C_ReportSystem and C_ReportSystem.OpenReportPlayerDialog then
							C_ReportSystem.OpenReportPlayerDialog(
								C_ReportSystem.ReportType.InappropriateBattleNetName,
								accountName
							)
						end
					end)
					rootDescription:CreateButton("Block Invites", function()
						BNSetBlocked(inviteID, true)
					end)
				end
			end)
		end)
		button.DeclineButton.handlerRegistered = true
	end

	-- Ensure button is visible
	button:Show()
end

-- Flash invite header when new invite arrives while collapsed
function FriendsList:FlashInviteHeader()
	if not self.scrollBox then
		return
	end

	-- Get all currently visible frames from ScrollBox
	local frames = self.scrollBox:GetFrames()
	if not frames then
		return
	end

	-- Find the invite header button and flash it
	for _, frame in pairs(frames) do
		-- Check if this is an invite header button by verifying its unique children
		if frame:GetObjectType() == "Button" and frame.Text and frame.DownArrow and frame.RightArrow then
			-- Flash animation (simple alpha pulse)
			UIFrameFlash(frame, 0.5, 0.5, 2, false, 0, 0)
			break
		end
	end
end

-- ========================================
-- Event Hooks (for future Raid/QuickJoin integration)
-- ========================================
function FriendsList:FireEvent(eventName, ...) -- TODO: Implement event system for module communication
	-- This will allow Raid/QuickJoin modules to hook into friend list updates
end

-- ========================================
-- Responsive UI Functions
-- ========================================

-- Update SearchBox width dynamically based on available space
function FriendsList:UpdateSearchBoxWidth()
	local frame = BetterFriendsFrame
	-- Fix: Simple Mode and Classic checks
	local DB = GetDB()
	local simpleMode = DB and DB:Get("simpleMode", false)

	if simpleMode then
		return
	end
	if BFL.IsClassic then
		return
	end

	if not frame then
		-- BFL:DebugPrint("|cffff0000UpdateSearchBoxWidth: No frame|r")
		return
	end

	if not frame.FriendsTabHeader then
		-- BFL:DebugPrint("|cffff0000UpdateSearchBoxWidth: No FriendsTabHeader|r")
		return
	end

	local header = frame.FriendsTabHeader
	if not header.SearchBox then
		-- BFL:DebugPrint("|cffff0000UpdateSearchBoxWidth: No SearchBox|r")
		return
	end

	local frameWidth = frame:GetWidth()
	if not frameWidth or frameWidth <= 0 then
		return
	end

	-- Classic Mode: Fixed width to fit dropdowns
	if BFL.IsClassic then
		-- Let XML anchors handle width (Full Width)
		return
	end

	-- Fixed elements on the right side of the header:
	-- - QuickFilter dropdown (~125px)
	-- - Sort dropdown (~80px)
	-- Total reserved space: ~205px (with padding)
	local fixedElementsWidth = 205
	local availableWidth = frameWidth - fixedElementsWidth

	-- Clamp SearchBox to functional minimum (175px)
	-- NO MAXIMUM: Scale up to max frame width (800px - 205px = 595px)
	-- This allows SearchBox to grow with frame width for better UX
	local minSearchBoxWidth = 175

	if availableWidth < minSearchBoxWidth then
		availableWidth = minSearchBoxWidth
	end

	local lastWidth = header.SearchBox.BFL_LastWidth
	if lastWidth and math.abs(lastWidth - availableWidth) < 0.5 then
		return
	end

	-- Apply new width
	header.SearchBox:SetWidth(availableWidth)
	header.SearchBox.BFL_LastWidth = availableWidth

	-- BFL:DebugPrint(string.format("|cff00ffffFriendsList:|r SearchBox width updated: %.1fpx (frame width: %.1fpx)",
	-- 	availableWidth, frameWidth))
end

-- Expose Drag Handlers for other modules (Broker)
FriendsList.OnDragStart = Button_OnDragStart
FriendsList.OnDragStop = Button_OnDragStop
FriendsList.OnDragUpdate = Button_OnDragUpdate

-- Export module to BFL namespace (required for BFL.FriendsList access)
BFL.FriendsList = FriendsList

return FriendsList
