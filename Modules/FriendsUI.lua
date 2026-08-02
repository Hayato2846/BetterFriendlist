local ADDON_NAME, BFL = ...

local FriendsUI = BFL:RegisterModule("FriendsUI", {})
BFL.FriendsUI = FriendsUI

local STYLE_MODERN = "modern"
local STYLE_LEGACY = "legacy"
local MODERN_LAYOUT_KEY = "RetailModern"
local LEGACY_LAYOUT_KEY = "Default"
-- Keep one consistent Modern list gutter: content ends 18 px before the shared
-- right edge and the MinimalScrollBar begins 7 px after the content viewport.
-- Moving the gap itself shifts the visible scrollbar without changing row width.
local MODERN_SCROLL_BOX_RIGHT_INSET = 18
local MODERN_SCROLL_BAR_GAP = 7
-- The custom TGAs already carry a gold palette with an average G/R ratio of
-- roughly 0.845. Preserve that luminance and calibrate only the color channels:
-- 0.845 * 0.9704 ~= Blizzard's 0.82 gold ratio. Inactive scales both channels
-- equally, so its hue remains identical without the brown cast from desaturation.
local CUSTOM_TAB_ICON_ACTIVE_COLOR = { 1, 0.9704, 0 }
local CUSTOM_TAB_ICON_INACTIVE_COLOR = { 0.68, 0.659872, 0 }
local LEGACY_HEADER_DROPDOWN_FIELDS = { "QuickFilterDropdown", "PrimarySortDropdown", "SecondarySortDropdown" }
local POPULATED_ONLY_SECTIONS = {
	quick_join = true,
	friend_requests = true,
}

FriendsUI.STYLE_MODERN = STYLE_MODERN
FriendsUI.STYLE_LEGACY = STYLE_LEGACY
FriendsUI.MODERN_LAYOUT_KEY = MODERN_LAYOUT_KEY
FriendsUI.LEGACY_LAYOUT_KEY = LEGACY_LAYOUT_KEY

local SECTION_DEFINITIONS = {
	{
		id = "friends",
		labelKey = "FRIENDS_UI_SECTION_FRIENDS",
		activeAtlas = "friends-icon-tab-friends",
		inactiveAtlas = "friends-icon-tab-friends-inactive",
		fallback = "Interface\\AddOns\\BetterFriendlist\\Icons\\users.blp",
		bottomTab = 1,
		topTab = 1,
	},
	{
		id = "recent_allies",
		labelKey = "FRIENDS_UI_SECTION_RECENT_ALLIES",
		activeAtlas = "friends-icon-tab-recentallies",
		inactiveAtlas = "friends-icon-tab-recentallies-inactive",
		fallback = "Interface\\AddOns\\BetterFriendlist\\Icons\\clock.blp",
		bottomTab = 1,
		topTab = 2,
	},
	{
		id = "quick_join",
		labelKey = "FRIENDS_UI_SECTION_QUICK_JOIN",
		activeAtlas = "friends-icon-tab-quickjoin",
		inactiveAtlas = "friends-icon-tab-quickjoin-inactive",
		fallback = "Interface\\AddOns\\BetterFriendlist\\Icons\\user-plus.blp",
		bottomTab = 4,
	},
	{
		id = "friend_requests",
		labelKey = "FRIENDS_UI_SECTION_REQUESTS",
		activeAtlas = "friends-icon-tab-friendRequest",
		inactiveAtlas = "friends-icon-tab-friendRequest-inactive",
		fallback = "Interface\\AddOns\\BetterFriendlist\\Icons\\git-pull-request.blp",
	},
	{
		id = "recruit_a_friend",
		labelKey = "FRIENDS_UI_SECTION_RECRUIT_A_FRIEND",
		activeAtlas = "friends-icon-tab-recruitFriends",
		inactiveAtlas = "friends-icon-tab-recruitFriends-inactive",
		fallback = "Interface\\AddOns\\BetterFriendlist\\Icons\\user-check.blp",
		bottomTab = 1,
		topTab = 3,
	},
	{
		id = "raid",
		labelKey = "FRIENDS_UI_SECTION_RAID",
		activeAtlas = "friends-icon-tab-raid",
		inactiveAtlas = "friends-icon-tab-raid-inactive",
		fallback = "Interface\\AddOns\\BetterFriendlist\\Icons\\users.blp",
		bottomTab = 3,
	},
	{
		id = "guild",
		labelKey = "FRIENDS_UI_SECTION_GUILD",
		activeAtlas = "friends-icon-tab-guild",
		inactiveAtlas = "friends-icon-tab-guild-inactive",
		customTexture = "Interface\\AddOns\\BetterFriendlist\\Icons\\friends-icon-tab-guild.tga",
		iconOffsetX = -4,
		fallback = "Interface\\AddOns\\BetterFriendlist\\Icons\\guild.blp",
		bottomTab = 1,
		topTab = 4,
	},
	{
		id = "who",
		labelKey = "FRIENDS_UI_SECTION_WHO",
		activeAtlas = "friends-icon-tab-who",
		inactiveAtlas = "friends-icon-tab-who-inactive",
		customTexture = "Interface\\AddOns\\BetterFriendlist\\Icons\\friends-icon-tab-who.tga",
		iconOffsetX = -4,
		fallback = "Interface\\AddOns\\BetterFriendlist\\Icons\\user.blp",
		bottomTab = 2,
	},
}

local SECTION_BY_ID = {}
local DEFAULT_SECTION_ORDER = {}
for _, definition in ipairs(SECTION_DEFINITIONS) do
	SECTION_BY_ID[definition.id] = definition
	DEFAULT_SECTION_ORDER[#DEFAULT_SECTION_ORDER + 1] = definition.id
end

local CONTACT_CHROME = {
	friends = { filterBar = true, friendsFilter = true, sort = true, action = "add_friend" },
	recent_allies = { filterBar = true, recentFilter = true, action = "add_friend" },
	friend_requests = { action = "add_friend" },
	quick_join = { action = "quick_join" },
	guild = { filterBar = true, action = "guild_actions" },
	who = { filterBar = true, action = "who_actions" },
}

local FRIENDS_RESTRICTED_SECTIONS = {
	friends = true,
	recent_allies = true,
	quick_join = true,
	friend_requests = true,
	recruit_a_friend = true,
}

local function GetL()
	return BFL.L or _G.BFL_L or {}
end

local function GetDB()
	local DB = BFL:GetModule("DB")
	return DB and DB:Get() or BetterFriendlistDB
end

local function SetDBValue(key, value)
	local DB = BFL:GetModule("DB")
	if DB and DB.Set then
		DB:Set(key, value)
	elseif BetterFriendlistDB then
		BetterFriendlistDB[key] = value
		if BFL.SettingsVersion then
			BFL.SettingsVersion = BFL.SettingsVersion + 1
		end
	end
end

local function CopyMap(source)
	local copy = {}
	for key, value in pairs(type(source) == "table" and source or {}) do
		copy[key] = value
	end
	return copy
end

local function IsFrame(frame)
	return frame and frame.GetObjectType ~= nil
end

local function SafeShow(frame, shown)
	if not IsFrame(frame) then
		return
	end
	if shown then
		frame:Show()
	else
		frame:Hide()
	end
end

local function SafeSetAtlas(texture, atlas, fallback)
	if not texture then
		return
	end
	if BFL.SetTextureOrAtlas then
		BFL.SetTextureOrAtlas(texture, atlas, fallback, true)
	elseif fallback then
		texture:SetTexture(fallback)
	end
end

local function ApplyModernSearchBoxVisual(searchBox)
	if not searchBox then
		return
	end

	-- Guild and Who historically added a second character-select search atlas
	-- on top of SearchBoxTemplate. Keep only the same chrome Friends uses.
	SafeShow(searchBox.Backdrop, false)
	for _, key in ipairs({ "Left", "Middle", "Right" }) do
		SafeShow(searchBox[key], true)
	end
	if searchBox.searchIcon then
		if BFL.SetTextureOrAtlas then
			-- SearchBoxTemplate explicitly uses useAtlasSize=false. The general
			-- icon helper uses true and would expand this atlas to its native
			-- dimensions instead of the intended 10 x 10 search glyph.
			BFL.SetTextureOrAtlas(
				searchBox.searchIcon,
				"common-search-magnifyingglass",
				"Interface\\AddOns\\BetterFriendlist\\Icons\\search",
				false
			)
		else
			searchBox.searchIcon:SetTexture("Interface\\AddOns\\BetterFriendlist\\Icons\\search")
		end
		searchBox.searchIcon:ClearAllPoints()
		searchBox.searchIcon:SetSize(10, 10)
		searchBox.searchIcon:SetPoint("LEFT", searchBox, "LEFT", 1, -1)
	end

	if searchBox.Instructions then
		searchBox.Instructions:SetFontObject("BetterFriendlistFontDisable")
		searchBox.Instructions:SetJustifyH("LEFT")
		searchBox.Instructions:SetMaxLines(1)
		searchBox.Instructions:ClearAllPoints()
		searchBox.Instructions:SetPoint("LEFT", searchBox, "LEFT", 16, -1)
		searchBox.Instructions:SetPoint("RIGHT", searchBox, "RIGHT", -20, -1)
	end

	-- Reapply the shared BFL edit-box surface after the legacy overlay was
	-- removed. SkinEditBox is a no-op when the dark theme is inactive.
	local SkinEngine = BFL:GetModule("SkinEngine")
	if SkinEngine and SkinEngine.SkinEditBox then
		SkinEngine:SkinEditBox(searchBox)
	end
end

local function ConstrainDropdownText(dropdown, leftInset, rightInset, fontReduction)
	local text = dropdown and (dropdown.Text or dropdown.TextRegion or dropdown.SelectionText)
	if not text then
		return
	end

	text:ClearAllPoints()
	text:SetPoint("LEFT", dropdown, "LEFT", leftInset or 5, 0)
	text:SetPoint("RIGHT", dropdown, "RIGHT", rightInset or -20, 0)
	text:SetJustifyH("CENTER")
	text:SetJustifyV("MIDDLE")
	if text.SetWordWrap then
		text:SetWordWrap(false)
	end
	if text.SetNonSpaceWrap then
		text:SetNonSpaceWrap(true)
	end
	if text.SetMaxLines then
		text:SetMaxLines(1)
	end
	if fontReduction and text.GetFont and text.SetFont then
		if not dropdown.BFLOriginalDropdownFont then
			dropdown.BFLOriginalDropdownFont = { text:GetFont() }
		end
		local fontPath, fontSize, fontFlags = unpack(dropdown.BFLOriginalDropdownFont)
		if fontPath and fontSize then
			text:SetFont(fontPath, math.max(10, fontSize - fontReduction), fontFlags)
		end
	end
end

local function ApplySectionIcon(texture, definition, selected)
	if not texture or not definition then
		return
	end
	if definition.customTexture then
		texture:SetTexture(definition.customTexture)
		texture:SetSize(32, 32)
		texture:SetTexCoord(0, 1, 0, 1)
		-- Keep the artwork's native luminance. Its source palette is already gold;
		-- the calibrated tint below removes blue and corrects green to Blizzard's
		-- effective 1:0.82:0 hue without darkening the icon into brown.
		texture:SetDesaturated(false)
		local color = selected and CUSTOM_TAB_ICON_ACTIVE_COLOR or CUSTOM_TAB_ICON_INACTIVE_COLOR
		texture:SetVertexColor(color[1], color[2], color[3], 1)
		return
	end
	SafeSetAtlas(texture, selected and definition.activeAtlas or definition.inactiveAtlas, definition.fallback)
	texture:SetVertexColor(1, 1, 1, 1)
end

function FriendsUI:ApplyFriendTabIcon(texture, sectionID, selected)
	local definition = SECTION_BY_ID[sectionID]
	if not definition then
		return false
	end
	ApplySectionIcon(texture, definition, selected == true)
	return true
end

function FriendsUI:HideModernLegacyHeaderDropdowns(header)
	if not header then
		return
	end

	for _, field in ipairs(LEGACY_HEADER_DROPDOWN_FIELDS) do
		local dropdown = header[field]
		if dropdown then
			if not dropdown._bflModernVisibilityGuardInstalled and dropdown.HookScript then
				dropdown._bflModernVisibilityGuardInstalled = true
				dropdown:HookScript("OnShow", function(control)
					local ui = BFL.FriendsUI or BFL:GetModule("FriendsUI")
					if ui and ui.IsModernActive and ui:IsModernActive() then
						control:Hide()
					end
				end)
			end
			SafeShow(dropdown, false)
		end
	end
end

local function AreFriendsDisabled()
	if not (C_SocialRestrictions and C_SocialRestrictions.IsFriendsDisabled) then
		return false
	end
	local ok, disabled = pcall(C_SocialRestrictions.IsFriendsDisabled)
	return ok and disabled == true
end

function FriendsUI:AreFriendsDisabled()
	return AreFriendsDisabled()
end

local function GetFriendInviteCount()
	if BFL.MockFriendInvites and BFL.MockFriendInvites.enabled then
		return #BFL.MockFriendInvites.invites
	end
	if BNGetNumFriendInvites then
		local ok, count = pcall(BNGetNumFriendInvites)
		if ok then
			return tonumber(count) or 0
		end
	end
	return 0
end

function FriendsUI:GetDefaultRequestedStyle(isRetail)
	if isRetail == nil then
		isRetail = BFL.IsRetail == true
	end
	return isRetail and STYLE_MODERN or STYLE_LEGACY
end

function FriendsUI:ComputeEffectiveStyle(requestedStyle, isRetail, socialUIEnabled)
	if requestedStyle ~= STYLE_MODERN then
		return STYLE_LEGACY
	end
	if isRetail ~= true or socialUIEnabled ~= true then
		return STYLE_LEGACY
	end
	return STYLE_MODERN
end

function FriendsUI:IsSocialUIEnabled()
	if not (BFL.IsRetail and C_SocialUI and C_SocialUI.IsSystemEnabled) then
		return false
	end
	local ok, enabled = pcall(C_SocialUI.IsSystemEnabled)
	return ok and enabled == true
end

function FriendsUI:GetRequestedStyle()
	local db = GetDB()
	local style = db and db.friendsFrameStyle
	if style ~= STYLE_MODERN and style ~= STYLE_LEGACY then
		return self:GetDefaultRequestedStyle()
	end
	return style
end

function FriendsUI:GetEffectiveStyle()
	return self:ComputeEffectiveStyle(self:GetRequestedStyle(), BFL.IsRetail == true, self:IsSocialUIEnabled())
end

function FriendsUI:GetAppliedStyle()
	return self.appliedStyle or self:GetEffectiveStyle()
end

function FriendsUI:IsModernActive()
	return self:GetAppliedStyle() == STYLE_MODERN
end

function FriendsUI:GetLayoutKeyForStyle(style)
	return style == STYLE_MODERN and MODERN_LAYOUT_KEY or LEGACY_LAYOUT_KEY
end

function FriendsUI:GetLayoutKey()
	return self:GetLayoutKeyForStyle(self:GetAppliedStyle())
end

function FriendsUI:ShouldShowInvitesInline(style)
	return (style or self:GetAppliedStyle()) ~= STYLE_MODERN
end

function FriendsUI:GetSectionDefinitions()
	return SECTION_DEFINITIONS
end

function FriendsUI:NormalizeFriendTabOrder(order)
	local normalized = {}
	local seen = {}
	for _, sectionID in ipairs(type(order) == "table" and order or {}) do
		if SECTION_BY_ID[sectionID] and not seen[sectionID] then
			seen[sectionID] = true
			normalized[#normalized + 1] = sectionID
		end
	end
	for _, sectionID in ipairs(DEFAULT_SECTION_ORDER) do
		if not seen[sectionID] then
			seen[sectionID] = true
			normalized[#normalized + 1] = sectionID
		end
	end
	return normalized
end

function FriendsUI:GetFriendTabOrder()
	local db = GetDB()
	return self:NormalizeFriendTabOrder(db and db.modernFriendTabOrder)
end

function FriendsUI:SetFriendTabOrder(order)
	SetDBValue("modernFriendTabOrder", self:NormalizeFriendTabOrder(order))
	self:RefreshFriendTabSettings()
end

function FriendsUI:MoveFriendTab(fromIndex, toIndex)
	local order = self:GetFriendTabOrder()
	fromIndex = tonumber(fromIndex)
	toIndex = tonumber(toIndex)
	if not (fromIndex and toIndex and order[fromIndex]) then
		return false
	end
	toIndex = math.max(1, math.min(#order, toIndex))
	local sectionID = table.remove(order, fromIndex)
	table.insert(order, toIndex, sectionID)
	self:SetFriendTabOrder(order)
	return true
end

function FriendsUI:IsFriendTabVisible(sectionID)
	if not SECTION_BY_ID[sectionID] then
		return false
	end
	local db = GetDB()
	local visibility = db and db.modernFriendTabVisibility
	return type(visibility) ~= "table" or visibility[sectionID] ~= false
end

function FriendsUI:SetFriendTabVisible(sectionID, visible)
	if not SECTION_BY_ID[sectionID] then
		return false
	end
	local db = GetDB()
	local visibility = CopyMap(db and db.modernFriendTabVisibility)
	visibility[sectionID] = visible == true
	SetDBValue("modernFriendTabVisibility", visibility)
	self:RefreshFriendTabSettings()
	return true
end

function FriendsUI:IsFriendTabPopulatedOnly(sectionID)
	if not POPULATED_ONLY_SECTIONS[sectionID] then
		return false
	end
	local db = GetDB()
	local settings = db and db.modernFriendTabPopulatedOnly
	return type(settings) == "table" and settings[sectionID] == true
end

function FriendsUI:SetFriendTabPopulatedOnly(sectionID, enabled)
	if not POPULATED_ONLY_SECTIONS[sectionID] then
		return false
	end
	local db = GetDB()
	local settings = CopyMap(db and db.modernFriendTabPopulatedOnly)
	settings[sectionID] = enabled == true
	SetDBValue("modernFriendTabPopulatedOnly", settings)
	self:RefreshFriendTabSettings()
	return true
end

function FriendsUI:GetFriendTabSettingsEntries()
	local L = GetL()
	local entries = {}
	for _, sectionID in ipairs(self:GetFriendTabOrder()) do
		local definition = SECTION_BY_ID[sectionID]
		entries[#entries + 1] = {
			id = sectionID,
			key = sectionID,
			label = L[definition.labelKey] or sectionID,
			activeAtlas = definition.activeAtlas,
			inactiveAtlas = definition.inactiveAtlas,
			customTexture = definition.customTexture,
			fallback = definition.fallback,
		}
	end
	return entries
end

function FriendsUI:GetSectionForLegacyTabs(bottomTab, topTab)
	bottomTab = tonumber(bottomTab) or 1
	topTab = tonumber(topTab) or 1
	if bottomTab == 2 then
		return "who"
	elseif bottomTab == 3 then
		return "raid"
	elseif bottomTab == 4 then
		return "quick_join"
	elseif topTab == 2 then
		return "recent_allies"
	elseif topTab == 3 then
		return "recruit_a_friend"
	elseif topTab == 4 then
		return "guild"
	end
	return "friends"
end

function FriendsUI:GetSectionForSocialTab(tabType)
	local tab = _G.SocialUITabType
	if not tab then
		return nil
	end
	local mapping = {
		[tab.Friends] = "friends",
		[tab.RecentAllies] = "recent_allies",
		[tab.QuickJoin] = "quick_join",
		[tab.FriendRequests] = "friend_requests",
		[tab.RecruitAFriend] = "recruit_a_friend",
		[tab.RaidList] = "raid",
	}
	return mapping[tabType]
end

function FriendsUI:GetSocialTabForSection(sectionID)
	local tab = _G.SocialUITabType
	if not tab then
		return nil
	end
	local mapping = {
		friends = tab.Friends,
		recent_allies = tab.RecentAllies,
		quick_join = tab.QuickJoin,
		friend_requests = tab.FriendRequests,
		recruit_a_friend = tab.RecruitAFriend,
		raid = tab.RaidList,
	}
	return mapping[sectionID]
end

function FriendsUI:GetCapabilities()
	local bnetSupported = not BFL.IsBattleNetFriendsListSupported or BFL.IsBattleNetFriendsListSupported()
	local bnetEnabled = not BFL.IsBattleNetFriendsListEnabled or BFL.IsBattleNetFriendsListEnabled()
	local recentEnabled = false
	if BFL.IsRetail and C_RecentAllies then
		if C_RecentAllies.IsSystemEnabled then
			local ok, enabled = pcall(C_RecentAllies.IsSystemEnabled)
			recentEnabled = ok and enabled == true
		elseif C_RecentAllies.IsRecentAlliesEnabled then
			local ok, enabled = pcall(C_RecentAllies.IsRecentAlliesEnabled)
			recentEnabled = ok and enabled == true
		end
	end
	local quickJoinEnabled = BFL.IsSocialQueueSupported and BFL.IsSocialQueueSupported()
	if quickJoinEnabled and BFL.IsSocialQueueEnabled then
		quickJoinEnabled = BFL.IsSocialQueueEnabled()
	end
	local rafEnabled = BFL.IsRAFSystemSupported and BFL.IsRAFSystemSupported()
	if rafEnabled and BFL.IsRAFSystemEnabled then
		rafEnabled = BFL.IsRAFSystemEnabled()
	end
	local rafPreviewEnabled = BFL.IsRAFPreviewActive and BFL:IsRAFPreviewActive()
	return {
		-- The Friends section also contains character friends and must remain
		-- reachable when Battle.net friends are unavailable.
		friends = true,
		recent_allies = recentEnabled,
		quick_join = quickJoinEnabled == true,
		friend_requests = bnetSupported and bnetEnabled,
		recruit_a_friend = rafPreviewEnabled == true or rafEnabled == true,
		raid = BFL.IsRetail == true and not self:AreRaidGroupsDisabled(),
		guild = BFL.IsGuildTabEnabled and BFL:IsGuildTabEnabled() or false,
		who = true,
	}
end

function FriendsUI:AreRaidGroupsDisabled()
	local gameRule = Enum and Enum.GameRule and Enum.GameRule.DisableRaidGroups
	if not (gameRule and C_GameRules and C_GameRules.IsGameRuleActive) then
		return false
	end
	local ok, disabled = pcall(C_GameRules.IsGameRuleActive, gameRule)
	return ok and disabled == true
end

function FriendsUI:ShouldShowSection(sectionID, capabilities, counts)
	capabilities = capabilities or self:GetCapabilities()
	if capabilities[sectionID] ~= true then
		return false
	end
	if not self:IsModernActive() then
		return true
	end
	if not self:IsFriendTabVisible(sectionID) then
		return false
	end
	if self:IsFriendTabPopulatedOnly(sectionID) then
		local count = counts and counts[sectionID]
		if count == nil then
			count = self:GetSectionCount(sectionID)
		end
		return (tonumber(count) or 0) > 0
	end
	return true
end

function FriendsUI:BuildAvailableSectionIDs(capabilities, counts)
	capabilities = capabilities or self:GetCapabilities()
	local result = {}
	local order = self:IsModernActive() and self:GetFriendTabOrder() or DEFAULT_SECTION_ORDER
	for _, sectionID in ipairs(order) do
		if self:ShouldShowSection(sectionID, capabilities, counts) then
			result[#result + 1] = sectionID
		end
	end
	return result
end

function FriendsUI:IsSectionAvailable(sectionID)
	local capabilities = self:GetCapabilities()
	return self:ShouldShowSection(sectionID, capabilities)
end

local function CaptureFrameState(frame)
	if not IsFrame(frame) then
		return nil
	end
	local points = {}
	for index = 1, frame:GetNumPoints() do
		points[index] = { frame:GetPoint(index) }
	end
	return {
		frame = frame,
		parent = frame:GetParent(),
		points = points,
		width = frame:GetWidth(),
		height = frame:GetHeight(),
		shown = frame:IsShown(),
		alpha = frame:GetAlpha(),
		frameLevel = frame:GetFrameLevel(),
	}
end

local function RestoreFrameState(state, restoreShown)
	if not state or not IsFrame(state.frame) then
		return
	end
	local frame = state.frame
	frame:SetParent(state.parent)
	frame:ClearAllPoints()
	for _, point in ipairs(state.points) do
		frame:SetPoint(unpack(point))
	end
	if #state.points <= 1 and state.width and state.height and state.width > 0 and state.height > 0 then
		frame:SetSize(state.width, state.height)
	end
	frame:SetAlpha(state.alpha or 1)
	if state.frameLevel then
		frame:SetFrameLevel(state.frameLevel)
	end
	if restoreShown then
		SafeShow(frame, state.shown)
	end
end

function FriendsUI:CaptureLegacyLayout()
	if self.legacyState or not BetterFriendsFrame then
		return
	end
	local frame = BetterFriendsFrame
	local fields = {
		"Inset",
		"ScrollFrame",
		"MinimalScrollBar",
		"RecentAlliesFrame",
		"RecruitAFriendFrame",
		"QuickJoinFrame",
		"WhoFrame",
		"RaidFrame",
		"GuildFrame",
		"AddFriendButton",
		"SendMessageButton",
		"RecruitmentButton",
		"FriendsTabHeader",
		"BottomTab1",
		"BottomTab2",
		"BottomTab3",
		"BottomTab4",
		"StreamerModeButton",
	}
	local state = { frames = {}, title = frame.TitleText and frame.TitleText:GetText() }
	for _, field in ipairs(fields) do
		state.frames[field] = CaptureFrameState(frame[field])
	end
	local nestedFrames = {
		["recentAllies.scrollBox"] = frame.RecentAlliesFrame and frame.RecentAlliesFrame.ScrollBox,
		["recentAllies.scrollBar"] = frame.RecentAlliesFrame and frame.RecentAlliesFrame.ScrollBar,
		["recruitAFriend.scrollBox"] = frame.RecruitAFriendFrame and frame.RecruitAFriendFrame.RecruitList and frame.RecruitAFriendFrame.RecruitList.ScrollBox,
		["recruitAFriend.scrollBar"] = frame.RecruitAFriendFrame and frame.RecruitAFriendFrame.RecruitList and frame.RecruitAFriendFrame.RecruitList.ScrollBar,
		["quickJoin.scrollBar"] = frame.QuickJoinFrame and frame.QuickJoinFrame.ContentInset and frame.QuickJoinFrame.ContentInset.ScrollBar,
		["who.scrollBox"] = frame.WhoFrame and frame.WhoFrame.ScrollBox,
		["who.scrollBar"] = frame.WhoFrame and frame.WhoFrame.ScrollBar,
		["who.editBox"] = frame.WhoFrame and frame.WhoFrame.EditBox,
		["who.listInset"] = frame.WhoFrame and frame.WhoFrame.ListInset,
		["who.nameHeader"] = frame.WhoFrame and frame.WhoFrame.NameHeader,
		["who.columnDropdown"] = frame.WhoFrame and frame.WhoFrame.ColumnDropdown,
		["who.levelHeader"] = frame.WhoFrame and frame.WhoFrame.LevelHeader,
		["who.classHeader"] = frame.WhoFrame and frame.WhoFrame.ClassHeader,
		["who.refreshButton"] = frame.WhoFrame and frame.WhoFrame.WhoButton,
		["who.addFriendButton"] = frame.WhoFrame and frame.WhoFrame.AddFriendButton,
		["who.groupInviteButton"] = frame.WhoFrame and frame.WhoFrame.GroupInviteButton,
		["guild.scrollBox"] = frame.GuildFrame and frame.GuildFrame.ScrollBox,
		["guild.scrollBar"] = frame.GuildFrame and frame.GuildFrame.ScrollBar,
		["guild.searchBox"] = frame.GuildFrame and frame.GuildFrame.SearchBox,
		["guild.filterDropdown"] = frame.GuildFrame and frame.GuildFrame.FilterDropdown,
		["guild.sortDropdown"] = frame.GuildFrame and frame.GuildFrame.SortDropdown,
		["guild.actionsButton"] = frame.GuildFrame and frame.GuildFrame.ActionsButton,
		["guild.listInset"] = frame.GuildFrame and frame.GuildFrame.ListInset,
	}
	for key, nestedFrame in pairs(nestedFrames) do
		state.frames[key] = CaptureFrameState(nestedFrame)
	end
	local header = frame.FriendsTabHeader
	if header then
		state.searchInstruction = header.SearchBox
			and header.SearchBox.Instructions
			and header.SearchBox.Instructions:GetText()
		for _, field in ipairs({ "StatusDropdown", "BattlenetFrame", "SearchBox", "QuickFilterDropdown", "PrimarySortDropdown", "SecondarySortDropdown" }) do
			state.frames["header." .. field] = CaptureFrameState(header[field])
		end
		local bnetFrame = header.BattlenetFrame
		for _, field in ipairs({ "ContactsMenuButton", "SettingsButton" }) do
			state.frames["bnet." .. field] = CaptureFrameState(bnetFrame and bnetFrame[field])
		end
	end
	if frame.portrait and frame.portrait.GetTexture then
		state.portraitTexture = frame.portrait:GetTexture()
	end
	self.legacyState = state
end

function FriendsUI:CreateModernRoot()
	if self.root or not BetterFriendsFrame or not BFL.IsRetail then
		return self.root
	end
	local root = CreateFrame("Frame", nil, BetterFriendsFrame, "BFLModernFriendsRootTemplate")
	root:SetAllPoints(BetterFriendsFrame)
	root:SetFrameLevel(BetterFriendsFrame:GetFrameLevel() + 1)
	root.PortraitOverlay:SetFrameLevel(root:GetFrameLevel() + 20)
	root:Hide()
	self.root = root

	if root.FilterBar.SortButton.SetupMenu then
		root.FilterBar.SortButton:SetupMenu(function(_, rootDescription)
			self:PopulateSortMenu(rootDescription)
		end)
	else
		root.FilterBar.SortButton:SetScript("OnClick", function(button)
			self:OpenSortMenu(button)
		end)
	end
	root.FilterBar.SortButton:SetScript("OnEnter", function(button)
		GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
		GameTooltip:SetText(GetL().FRIENDS_UI_SORT_TOOLTIP or "Sorting")
		GameTooltip:Show()
	end)
	root.FilterBar.SortButton:SetScript("OnLeave", GameTooltip_Hide)
	self:RefreshSortButtonText()

	local filterDropdown = root.FilterBar.FilterDropdown
	local QuickFilters = BFL:GetModule("QuickFilters")
	if filterDropdown and QuickFilters and QuickFilters.InitDropdown then
		QuickFilters:InitDropdown(filterDropdown)
		filterDropdown._bflModernInitialized = true
	end
	local recentFilterDropdown = root.FilterBar.RecentFilterDropdown
	local RecentAllies = BFL:GetModule("RecentAllies")
	if recentFilterDropdown and RecentAllies and RecentAllies.InitializeFilterDropdown then
		RecentAllies:InitializeFilterDropdown(recentFilterDropdown)
	end

	local menuButton = root.BattleNetBar.MenuButton
	menuButton:SetScript("OnClick", function(button)
		BetterFriendsFrame_ShowContactsMenu(button)
	end)
	menuButton:SetScript("OnEnter", function(button)
		BFL_Tooltip:SetOwner(button, "ANCHOR_RIGHT")
		GameTooltip_SetTitle(BFL_Tooltip, CONTACTS_MENU_NAME or "Menu")
		BFL_Tooltip:Show()
	end)
	menuButton:SetScript("OnLeave", BFL_Tooltip_Hide)
	menuButton:SetScript("OnMouseDown", function(button)
		if button.Icon and button.Icon.AdjustPointsOffset then
			button.Icon:AdjustPointsOffset(1, -1)
		end
	end)
	menuButton:SetScript("OnMouseUp", function(button)
		if button.Icon and button.Icon.AdjustPointsOffset then
			button.Icon:AdjustPointsOffset(-1, 1)
		end
	end)

	local addFriendButton = root.BottomActionBar.AddFriendButton
	addFriendButton:SetText(ADD_NEW_FRIEND or ADD_FRIEND or "Add Friend")
	addFriendButton:SetScript("OnClick", function()
		self:PerformContactAction()
	end)
	addFriendButton:HookScript("OnEnter", function(button)
		local chrome = self:GetContactChrome(self.selectedSection or "friends")
		if not button:IsEnabled() and chrome.action == "add_friend" then
			GameTooltip:SetOwner(button, "ANCHOR_TOPRIGHT", 6, 0)
			GameTooltip_AddErrorLine(GameTooltip, ADDING_FRIENDS_DISABLED or "Adding friends is currently disabled.")
			GameTooltip:Show()
		elseif not button:IsEnabled() and chrome.action == "quick_join" and button.tooltip then
			GameTooltip:SetOwner(button, "ANCHOR_TOPRIGHT", 6, 0)
			GameTooltip_AddErrorLine(GameTooltip, button.tooltip)
			GameTooltip:Show()
		end
	end)
	addFriendButton:HookScript("OnLeave", GameTooltip_Hide)

	local copyBattleTagButton = root.BattleNetBar.CopyBattleTagButton
	copyBattleTagButton:SetScript("OnClick", function()
		self:CopyBattleTag()
	end)
	copyBattleTagButton:SetScript("OnMouseDown", function(button)
		if button.Icon and button.Icon.AdjustPointsOffset then
			button.Icon:AdjustPointsOffset(1, -1)
		end
		if button.HighlightTexture and button.HighlightTexture.AdjustPointsOffset then
			button.HighlightTexture:AdjustPointsOffset(1, -1)
		end
	end)
	copyBattleTagButton:SetScript("OnMouseUp", function(button)
		if button.Icon and button.Icon.AdjustPointsOffset then
			button.Icon:AdjustPointsOffset(-1, 1)
		end
		if button.HighlightTexture and button.HighlightTexture.AdjustPointsOffset then
			button.HighlightTexture:AdjustPointsOffset(-1, 1)
		end
	end)
	copyBattleTagButton:SetScript("OnEnter", function(button)
		GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
		GameTooltip:SetText(GetL().FRIENDS_UI_COPY_BATTLETAG or "Copy BattleTag")
		GameTooltip:Show()
	end)
	copyBattleTagButton:SetScript("OnLeave", GameTooltip_Hide)

	self:CreateNavigationTabs()
	self:InitializeRequestsScrollBox()
	return root
end

function FriendsUI:CreateNavigationTabs()
	if self.sideTabs or not self.root then
		return
	end
	self.sideTabs = {}
	for index, definition in ipairs(SECTION_DEFINITIONS) do
		local tab = CreateFrame("Button", nil, self.root, "BFLModernSideTabTemplate")
		tab.sectionID = definition.id
		tab.activeAtlas = definition.activeAtlas
		tab.inactiveAtlas = definition.inactiveAtlas
		tab.fallbackTexture = definition.fallback
		local onClick = function(button)
			self:SelectSection(button.sectionID)
		end
		if tab.SetCustomOnMouseUpHandler then
			tab:SetCustomOnMouseUpHandler(function(button, mouseButton, upInside)
				if mouseButton == "LeftButton" and upInside then
					onClick(button)
				end
			end)
		else
			tab:SetScript("OnClick", onClick)
		end
		tab:SetScript("OnEnter", function(button)
			GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
			GameTooltip:SetText(button.tooltipText or button.sectionID)
			if button.disabledReason then
				GameTooltip:AddLine(button.disabledReason, 1, 0.82, 0, true)
			end
			GameTooltip:Show()
		end)
		tab:SetScript("OnLeave", GameTooltip_Hide)
		self.sideTabs[index] = tab
		definition.tab = tab
	end
end

function FriendsUI:IsStoryRaidActive()
	if not (DifficultyUtil and DifficultyUtil.InStoryRaid) then
		return false
	end
	local ok, active = pcall(DifficultyUtil.InStoryRaid)
	return ok and active == true
end

function FriendsUI:GetQuickJoinCount()
	local QuickJoin = BFL:GetModule("QuickJoin")
	if QuickJoin and QuickJoin.GetAllGroups then
		local ok, groups = pcall(QuickJoin.GetAllGroups, QuickJoin)
		if ok and type(groups) == "table" then
			return #groups
		end
	end
	if C_SocialQueue and C_SocialQueue.GetAllGroups then
		local ok, groups = pcall(C_SocialQueue.GetAllGroups)
		if ok and type(groups) == "table" then
			return #groups
		end
	end
	return 0
end

function FriendsUI:GetSectionCount(sectionID, inviteCount, quickJoinCount)
	if sectionID == "friend_requests" then
		return inviteCount == nil and GetFriendInviteCount() or inviteCount
	elseif sectionID == "quick_join" then
		return quickJoinCount == nil and self:GetQuickJoinCount() or quickJoinCount
	end
	return 0
end

function FriendsUI:ShouldStartRequestGlow(newInvite, selectedSection)
	return newInvite == true and (selectedSection or self.selectedSection) ~= "friend_requests"
end

function FriendsUI:RefreshNavigation()
	if self:IsModernActive() then
		self:HideLegacyTabs()
	end
	if not self.sideTabs then
		return
	end
	local capabilities = self:GetCapabilities()
	local counts = {
		friend_requests = self:GetSectionCount("friend_requests"),
		quick_join = self:GetSectionCount("quick_join"),
	}
	local availableSections = self:BuildAvailableSectionIDs(capabilities, counts)
	local visibleSections = {}
	for _, sectionID in ipairs(availableSections) do
		visibleSections[sectionID] = true
	end
	local previous
	local L = GetL()
	for _, definition in ipairs(SECTION_DEFINITIONS) do
		local tab = definition.tab
		local available = visibleSections[definition.id] == true
		tab.tooltipText = L[definition.labelKey] or definition.id
		tab.disabledReason = nil
		tab:SetEnabled(available)
		tab:SetShown(available)
		local selected = self.selectedSection == definition.id
		if tab.SelectedTexture then
			tab.SelectedTexture:SetShown(selected)
		end
		local icon = tab.Icon or tab.icon
		ApplySectionIcon(icon, definition, selected)
		if tab.Count then
			local count = counts[definition.id] or 0
			tab.Count:SetShown(count > 0)
			tab.Count:SetText(count > 0 and count or "")
			if tab.Icon then
				tab.Icon:ClearAllPoints()
				tab.Icon:SetPoint("CENTER", tab, "CENTER", definition.iconOffsetX or -2, count > 0 and 5 or 0)
			end
		end
		if definition.id == "raid" and available and self:IsStoryRaidActive() then
			tab:SetEnabled(false)
			tab.disabledReason = L.FRIENDS_UI_RAID_STORY_DISABLED or "Unavailable during a Story raid."
		end
	end
	for _, sectionID in ipairs(availableSections) do
		local tab = SECTION_BY_ID[sectionID].tab
		tab:ClearAllPoints()
		if previous then
			tab:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -3)
		else
			tab:SetPoint("TOPLEFT", BetterFriendsFrame, "TOPRIGHT", 0, -122)
		end
		previous = tab
	end
	if
		self:IsModernActive()
		and self.selectedSection
		and not visibleSections[self.selectedSection]
		and availableSections[1]
		and not self.refreshingFriendTabSelection
	then
		self.refreshingFriendTabSelection = true
		self:SelectSection(availableSections[1])
		self.refreshingFriendTabSelection = false
		return
	end
	self:ApplyTheme(self.currentTheme)
end

function FriendsUI:RefreshFriendTabSettings()
	if not self:IsModernActive() or not self.sideTabs then
		return
	end
	self:RefreshNavigation()
end

function FriendsUI:StartRequestGlow()
	local definition = SECTION_BY_ID.friend_requests
	local tab = definition and definition.tab
	if not tab or self.selectedSection == "friend_requests" then
		return
	end
	if tab.SetTabGlowAnimationPlaying then
		tab:SetTabGlowAnimationPlaying(true)
	elseif tab.TabGlowAnimation and tab.TabGlowAnimation.Play then
		tab.TabGlowAnimation:Play()
	end
end

function FriendsUI:StopRequestGlow()
	local definition = SECTION_BY_ID.friend_requests
	local tab = definition and definition.tab
	if not tab then
		return
	end
	if tab.SetTabGlowAnimationPlaying then
		tab:SetTabGlowAnimationPlaying(false)
	elseif tab.TabGlowAnimation and tab.TabGlowAnimation.Stop then
		tab.TabGlowAnimation:Stop()
	end
end

function FriendsUI:RefreshBattleTag()
	if not (self.root and BetterFriendsFrame and BetterFriendsFrame.FriendsTabHeader) then
		return
	end
	local header = BetterFriendsFrame.FriendsTabHeader
	local bnetFrame = header.BattlenetFrame
	if bnetFrame and bnetFrame.Tag and BNGetInfo then
		local ok, _, battleTag = pcall(BNGetInfo)
		if ok and battleTag then
			self.battleTag = battleTag
			local marker = battleTag:find("#", 1, true)
			local display = marker and (battleTag:sub(1, marker - 1) .. "|cff416380" .. battleTag:sub(marker) .. "|r") or battleTag
			bnetFrame.Tag:SetText(display)
		end
	end
end

function FriendsUI:CopyBattleTag()
	self:RefreshBattleTag()
	local value = self.battleTag
	if not value or value == "" then
		return
	end
	local Changelog = BFL:GetModule("Changelog")
	if Changelog and Changelog.ShowCopyDialog then
		Changelog:ShowCopyDialog(value, GetL().FRIENDS_UI_COPY_BATTLETAG or "Copy BattleTag")
	end
end

function FriendsUI:RefreshSortButtonText()
	local button = self.root and self.root.FilterBar and self.root.FilterBar.SortButton
	if not button then
		return
	end
	local FriendsList = BFL:GetModule("FriendsList")
	local Registry = BFL:GetModule("FilterSortRegistry")
	local text = SORT or (SORT_BY or GetL().RAID_TOOLS_SORT_HEADER or "Sort"):gsub(":%s*$", "")
	if FriendsList and Registry and Registry.GetSorterIcon and Registry.FormatIcon then
		local primary = Registry:FormatIcon(Registry:GetSorterIcon(FriendsList.sortMode), 11)
		text = string.format("%s (%s", text, primary)
		if FriendsList.secondarySort and FriendsList.secondarySort ~= "none" then
			local secondary = Registry:FormatIcon(Registry:GetSorterIcon(FriendsList.secondarySort), 11)
			text = string.format("%s %s", text, secondary)
		end
		text = text .. ")"
	end
	if BFL.SetDropdownText then
		BFL.SetDropdownText(button, text)
	elseif button.SetText then
		button:SetText(text)
	end
	ConstrainDropdownText(button, 5, -20, 1)
end

function FriendsUI:LayoutBattleTagActions()
	local root = self.root
	local frame = BetterFriendsFrame
	local header = frame and frame.FriendsTabHeader
	local bnetFrame = header and header.BattlenetFrame
	local tag = bnetFrame and bnetFrame.Tag
	if not (root and tag) then
		return
	end

	local copyButton = root.BattleNetBar.CopyBattleTagButton
	copyButton:ClearAllPoints()
	copyButton:SetPoint("LEFT", tag, "RIGHT", 8, 0)
	copyButton:SetFrameLevel(root.BattleNetBar:GetFrameLevel() + 4)

	local streamerButton = frame.StreamerModeButton
	if streamerButton then
		streamerButton:SetParent(root.BattleNetBar)
		streamerButton:ClearAllPoints()
		streamerButton:SetPoint("RIGHT", bnetFrame, "RIGHT", -7, 0)
		streamerButton:SetSize(20, 20)
		streamerButton:SetFrameLevel(root.BattleNetBar:GetFrameLevel() + 4)
	end
	if bnetFrame then
		bnetFrame:ClearAllPoints()
		bnetFrame:SetPoint("LEFT", root.BattleNetBar, "LEFT", 65, 4)
		bnetFrame:SetPoint("RIGHT", root.BattleNetBar.MenuButton, "LEFT", -7, 4)
	end
end

function FriendsUI:GetSortMenuItems()
	local FriendsList = BFL:GetModule("FriendsList")
	local Registry = BFL:GetModule("FilterSortRegistry")
	if not FriendsList or not Registry then
		return nil
	end
	local L = GetL()
	local primary = {
		type = "submenu",
		text = L.SORT_PRIMARY_LABEL or "Primary sort",
		items = {},
	}
	local secondary = {
		type = "submenu",
		text = L.SORT_SECONDARY_LABEL or "Secondary sort",
		items = {
			{
				type = "radio",
				text = L.SORT_NONE or NONE or "None",
				value = "none",
				checked = function(value)
					return FriendsList.secondarySort == value
				end,
				func = function(value)
					FriendsList:SetSecondarySortMode(value)
					self:RefreshSortButtonText()
				end,
			},
		},
	}
	for _, sorter in ipairs(Registry:GetVisibleSorters()) do
		local sorterText = sorter.name
		if Registry.FormatIcon and sorter.icon then
			sorterText = Registry:FormatIcon(sorter.icon, 16) .. " " .. sorterText
		end
		primary.items[#primary.items + 1] = {
			type = "radio",
			text = sorterText,
			value = sorter.id,
			checked = function(value)
				return FriendsList.sortMode == value
			end,
			func = function(value)
				FriendsList:SetSortMode(value)
				self:RefreshSortButtonText()
			end,
		}
		if sorter.id ~= FriendsList.sortMode then
			secondary.items[#secondary.items + 1] = {
				type = "radio",
				text = sorterText,
				value = sorter.id,
				checked = function(value)
					return FriendsList.secondarySort == value
				end,
				func = function(value)
					FriendsList:SetSecondarySortMode(value)
					self:RefreshSortButtonText()
				end,
			}
		end
	end
	return { primary, secondary }
end

function FriendsUI:PopulateSortMenu(rootDescription)
	local items = self:GetSortMenuItems()
	if items and BFL.PopulateSimpleMenu then
		return BFL.PopulateSimpleMenu(rootDescription, items)
	end
	return false
end

function FriendsUI:OpenSortMenu(anchor)
	local items = self:GetSortMenuItems()
	if items and BFL.OpenSimpleContextMenu then
		return BFL.OpenSimpleContextMenu(anchor, "BFL_ModernSortMenu", items)
	end
	return false
end

local function GetInviteInfo(index)
	if BFL.MockFriendInvites and BFL.MockFriendInvites.enabled then
		return BFL.MockFriendInvites.invites[index]
	end
	if BFL.GetBNetFriendInviteInfo then
		return BFL.GetBNetFriendInviteInfo(index)
	end
	if BNGetFriendInviteInfo then
		return BNGetFriendInviteInfo(index)
	end
	return nil
end

function FriendsUI:NormalizeInvite(index)
	local raw = GetInviteInfo(index)
	if type(raw) == "table" then
		return {
			inviteIndex = index,
			inviteID = raw.inviteID or raw.id,
			accountName = raw.accountName or raw.name or UNKNOWN,
			friendLevel = raw.friendLevel,
			creationTimestamp = raw.creationTimestamp or raw.createdAt,
		}
	end
	local inviteID, accountName, isBattleTag, creationTimestamp = GetInviteInfo(index)
	if inviteID == nil then
		return nil
	end
	return {
		inviteIndex = index,
		inviteID = inviteID,
		accountName = accountName or UNKNOWN,
		friendLevel = isBattleTag,
		creationTimestamp = creationTimestamp,
	}
end

function FriendsUI:GetFriendLevelLabel(friendLevel)
	local L = GetL()
	local level = Enum and Enum.BattleNetFriendLevel
	if level then
		if friendLevel == level.RealID then
			return L.FRIENDS_UI_REQUEST_REAL_ID or "Real ID"
		elseif friendLevel == level.BattleTag then
			return L.FRIENDS_UI_REQUEST_BATTLETAG or "BattleTag"
		elseif friendLevel == level.Title then
			return L.FRIENDS_UI_REQUEST_TITLE or "World of Warcraft"
		end
	end
	if friendLevel == false or friendLevel == 0 then
		return L.FRIENDS_UI_REQUEST_REAL_ID or "Real ID"
	end
	return L.FRIENDS_UI_REQUEST_BATTLETAG or "BattleTag"
end

function FriendsUI:IsRealIDInvite(friendLevel)
	local level = Enum and Enum.BattleNetFriendLevel
	return level and friendLevel == level.RealID or false
end

function FriendsUI:IsTitleInvite(friendLevel)
	local level = Enum and Enum.BattleNetFriendLevel
	return level and friendLevel == level.Title or false
end

function FriendsUI:InitializeRequestHeader(button, elementData)
	if button and button.ButtonText then
		button.ButtonText:SetText(elementData.headerText or "")
	end
end

function FriendsUI:RemoveMockInvite(inviteID, accepted)
	local mockInvites = BFL.MockFriendInvites
	if not (mockInvites and mockInvites.enabled) then
		return false
	end
	for index, invite in ipairs(mockInvites.invites or {}) do
		if invite.inviteID == inviteID then
			table.remove(mockInvites.invites, index)
			return true
		end
	end
	return false
end

function FriendsUI:OpenRequestDeclineMenu(button)
	if not (button and button.inviteID and BFL.OpenSimpleContextMenu) then
		return
	end
	local inviteID = button.inviteID
	local accountName = button.accountName
	local items = {
		{
			text = BFL.L.DECLINE or DECLINE or "Decline",
			func = function()
				if not self:RemoveMockInvite(inviteID, false) and BNDeclineFriendInvite then
					BNDeclineFriendInvite(inviteID)
				end
				self:RefreshRequests()
			end,
		},
	}
	if not (BFL.MockFriendInvites and BFL.MockFriendInvites.enabled) then
		items[#items + 1] = {
			text = REPORT_PLAYER or "Report Player",
			func = function()
				if C_ReportSystem and C_ReportSystem.OpenReportPlayerDialog then
					C_ReportSystem.OpenReportPlayerDialog(
						C_ReportSystem.ReportType.InappropriateBattleNetName,
						accountName
					)
				end
			end,
		}
		items[#items + 1] = {
			text = BLOCK_INVITES or "Block Invites",
			func = function()
				if BNSetBlocked then
					BNSetBlocked(inviteID, true)
				end
			end,
		}
	end
	BFL.OpenSimpleContextMenu(button, "BFL_ModernFriendRequestDeclineDropdown", items)
end

local function InitializeScaledRequestMenuElement(description)
	if description and description.AddInitializer and SocialUIUtil
		and SocialUIUtil.InitializeUserScaledDropdownButton
	then
		description:AddInitializer(SocialUIUtil.InitializeUserScaledDropdownButton)
	end
end

function FriendsUI:SetupRequestDeclineButton(declineButton)
	if not declineButton or declineButton._bflRequestMenuInitialized then
		return
	end
	declineButton._bflRequestMenuInitialized = true

	if not declineButton.SetupMenu then
		declineButton:SetScript("OnClick", function(button)
			self:OpenRequestDeclineMenu(button)
		end)
		return
	end

	declineButton:SetupMenu(function(dropdown, rootDescription)
		if rootDescription.SetTag then
			rootDescription:SetTag("MENU_FRIEND_REQUESTS_DECLINE")
		end

		local decline = rootDescription:CreateButton(DECLINE or BFL.L.DECLINE or "Decline", function()
			if StaticPopup_Hide then
				StaticPopup_Hide("CONFIRM_BLOCK_INVITES")
			end
			if not self:RemoveMockInvite(dropdown.inviteID, false) and BNDeclineFriendInvite then
				BNDeclineFriendInvite(dropdown.inviteID)
			end
			self:RefreshRequests()
		end)
		InitializeScaledRequestMenuElement(decline)

		if BFL.MockFriendInvites and BFL.MockFriendInvites.enabled then
			return
		end

		local report = rootDescription:CreateButton(REPORT_PLAYER or "Report Player", function()
			local inviteInfo = C_BattleNet
				and C_BattleNet.GetFriendInviteInfo
				and C_BattleNet.GetFriendInviteInfo(dropdown.inviteIndex)
			local bnetIDAccount = inviteInfo and inviteInfo.inviteID or dropdown.inviteID
			local accountName = inviteInfo and inviteInfo.accountName or dropdown.accountName
			if PlayerLocation and ReportInfo and ReportFrame and Enum and Enum.ReportType then
				local playerLocation = PlayerLocation:CreateFromBattleNetID(bnetIDAccount)
				local reportInfo = ReportInfo:CreateReportInfoFromType(Enum.ReportType.Friend)
				ReportFrame:InitiateReport(reportInfo, accountName, playerLocation, bnetIDAccount ~= nil)
			end
		end)
		InitializeScaledRequestMenuElement(report)

		local modeSupportsStaticPopups = not (C_Glue and C_Glue.IsOnGlueScreen and C_Glue.IsOnGlueScreen())
		if modeSupportsStaticPopups then
			local block = rootDescription:CreateButton(BLOCK_INVITES or "Block Invites", function()
				local inviteInfo = C_BattleNet
					and C_BattleNet.GetFriendInviteInfo
					and C_BattleNet.GetFriendInviteInfo(dropdown.inviteIndex)
				local inviteID = inviteInfo and inviteInfo.inviteID or dropdown.inviteID
				local accountName = inviteInfo and inviteInfo.accountName or dropdown.accountName
				if StaticPopup_Show then
					StaticPopup_Show("CONFIRM_BLOCK_INVITES", accountName, nil, inviteID)
				elseif BNSetBlocked then
					BNSetBlocked(inviteID, true)
				end
			end)
			InitializeScaledRequestMenuElement(block)
		end
	end)
end

function FriendsUI:InitializeRequestCard(button, elementData)
	button.inviteIndex = elementData.inviteIndex
	button.inviteID = elementData.inviteID
	button.accountName = elementData.accountName
	button.Name:SetText(elementData.accountName or UNKNOWN)
	button.FriendType:SetText(self:GetFriendLevelLabel(elementData.friendLevel))
	local age
	if elementData.creationTimestamp and SecondsToTime then
		age = SecondsToTime(math.max(0, time() - elementData.creationTimestamp))
	end
	button.RequestTimestamp:SetText(age and string.format(GetL().FRIENDS_UI_REQUEST_RECEIVED or "%s ago", age) or "")
	button.AcceptButton:SetText(ACCEPT or GetL().ACCEPT or "Accept")
	button.AcceptButton:SetScript("OnClick", function()
		if self:RemoveMockInvite(button.inviteID, true) then
			-- The deterministic preview fixture is local and must never call the live API.
		elseif BNAcceptFriendInvite and button.inviteID then
			BNAcceptFriendInvite(button.inviteID)
		end
		self:RefreshRequests()
	end)
	button.DeclineButton.inviteIndex = button.inviteIndex
	button.DeclineButton.inviteID = button.inviteID
	button.DeclineButton.accountName = button.accountName
	self:SetupRequestDeclineButton(button.DeclineButton)
	SafeSetAtlas(button.Background, self:IsTitleInvite(elementData.friendLevel) and "friends-card-default" or "friends-card-battleNet")
	self:StyleRequestCard(button)
end

function FriendsUI:InitializeRequestsScrollBox()
	if self.requestsInitialized or not (self.root and BFL.HasModernScrollBox) then
		return
	end
	local requests = self.root.RequestsFrame
	local view = CreateScrollBoxListLinearView()
	view:SetElementFactory(function(factory, elementData)
		if elementData and elementData.headerText then
			factory("BFLModernFriendRequestHeaderTemplate", function(button, data)
				self:InitializeRequestHeader(button, data)
			end)
		elseif elementData and elementData.isSpacer then
			factory("BFLModernFriendRequestSpacerTemplate")
		else
			factory("BFLModernFriendRequestCardTemplate", function(button, data)
				self:InitializeRequestCard(button, data)
			end)
		end
	end)
	view:SetElementExtentCalculator(function(_, elementData)
		if elementData and elementData.headerText then
			return 24
		elseif elementData and elementData.isSpacer then
			return 2
		end
		return 70
	end)
	BFL.InitScrollBoxListWithScrollBar(requests.ScrollBox, requests.ScrollBar, view)
	self.requestsInitialized = true
	requests.EmptyLabel:SetText(GetL().FRIENDS_UI_REQUESTS_EMPTY or "No pending friend requests")
	requests.RealIDWarning.Text:SetText(
		SOCIAL_UI_FRIEND_REQUESTS_REAL_ID_WARNING
			or GetL().FRIENDS_UI_REAL_ID_WARNING
			or "Real ID requests reveal your real name."
	)
	requests.RealIDWarning.Text:SetTextColor(1, 1, 1, 1)
	requests.RealIDWarning.Text:ClearAllPoints()
	requests.RealIDWarning.Text:SetPoint("TOP", requests.RealIDWarning.PlayerIcon, "BOTTOM", 0, -27)
	requests.RealIDWarning.Text:SetPoint("LEFT", requests.RealIDWarning, "LEFT", 30, 0)
	requests.RealIDWarning.Text:SetPoint("RIGHT", requests.RealIDWarning, "RIGHT", -30, 0)
	requests.RealIDWarning.Text:SetPoint("BOTTOM", requests.RealIDWarning.ContinueButton, "TOP", 0, 20)
	SafeSetAtlas(requests.RealIDWarning.PlayerIcon, "friends-icon-addFriend", "Interface\\AddOns\\BetterFriendlist\\Icons\\user-plus.blp")
	SafeSetAtlas(requests.RealIDWarning.BattleNetIcon, "friends-icon-addFriend-logo-battleNet", "Interface\\AddOns\\BetterFriendlist\\Icons\\star.blp")
	requests.RealIDWarning.ContinueButton:SetText(CONTINUE or GetL().CONTINUE or "Continue")
	requests.RealIDWarning.ContinueButton:SetScript("OnClick", function()
		if SetCVar then
			SetCVar("pendingInviteInfoShown", "1")
		end
		requests.RealIDWarning:Hide()
		self:LayoutRequestsFrame()
	end)
end

function FriendsUI:GetContactChrome(sectionID)
	return CONTACT_CHROME[sectionID] or {}
end

function FriendsUI:PerformContactAction()
	local chrome = self:GetContactChrome(self.selectedSection or "friends")
	if chrome.action == "quick_join" then
		local QuickJoin = BFL:GetModule("QuickJoin")
		if QuickJoin and QuickJoin.JoinQueue then
			QuickJoin:JoinQueue()
		end
	elseif chrome.action == "add_friend" and AddFriendFrame_Show then
		AddFriendFrame_Show()
	elseif chrome.action == "guild_actions" and _G.BFL_GuildFrame_ShowActionsMenu then
		_G.BFL_GuildFrame_ShowActionsMenu(self.root and self.root.BottomActionBar.AddFriendButton)
	end
end

function FriendsUI:ApplyContactChrome(sectionID, header)
	if not self.root then
		return self:GetContactChrome(sectionID)
	end
	local root = self.root
	local chrome = self:GetContactChrome(sectionID)
	local showFilterBar = chrome.filterBar == true
	local showActionBar = chrome.action ~= nil
	local showSharedSearch = sectionID == "friends" or sectionID == "recent_allies"

	root.FilterBar:SetShown(showFilterBar)
	SafeShow(header and header.SearchBox, showFilterBar and showSharedSearch)
	self:HideModernLegacyHeaderDropdowns(header)
	SafeShow(root.FilterBar.FilterDropdown, chrome.friendsFilter == true)
	SafeShow(root.FilterBar.RecentFilterDropdown, chrome.recentFilter == true)
	SafeShow(root.FilterBar.SortButton, chrome.sort == true)

	root.TopDivider:ClearAllPoints()
	if showFilterBar then
		root.TopDivider:SetPoint("TOPLEFT", root.FilterBar, "BOTTOMLEFT", 5, -3)
		root.TopDivider:SetPoint("TOPRIGHT", root.FilterBar, "BOTTOMRIGHT", -5, -3)
	else
		root.TopDivider:SetPoint("TOPLEFT", root.BattleNetBar, "BOTTOMLEFT", 5, -9)
		root.TopDivider:SetPoint("TOPRIGHT", root.BattleNetBar, "BOTTOMRIGHT", -5, -9)
	end

	root.BottomActionBar:SetShown(showActionBar)
	root.BottomDivider:SetShown(showActionBar)
		local actionButton = root.BottomActionBar.AddFriendButton
		if actionButton then
			actionButton:SetShown(chrome.action ~= "who_actions")
			if chrome.action == "quick_join" then
				actionButton:SetText(JOIN_QUEUE or "Join Queue")
				local QuickJoin = BFL:GetModule("QuickJoin")
				if QuickJoin and QuickJoin.UpdateJoinButtonState then
					QuickJoin:UpdateJoinButtonState()
				else
					actionButton:SetEnabled(false)
				end
				if AreFriendsDisabled() then
					actionButton:SetEnabled(false)
				end
		elseif chrome.action == "add_friend" then
			local label = sectionID == "recent_allies" and SOCIAL_UI_RECENT_ALLIES_ADD_FRIEND_BUTTON_LABEL
				or sectionID == "friend_requests" and SOCIAL_UI_FRIEND_REQUESTS_ADD_FRIEND_BUTTON_LABEL
				or SOCIAL_UI_FRIENDS_LIST_ADD_FRIEND_BUTTON_LABEL
			actionButton:SetText(label or ADD_NEW_FRIEND or ADD_FRIEND or "Add Friend")
			actionButton:SetEnabled(not AreFriendsDisabled())
		elseif chrome.action == "guild_actions" then
			actionButton:SetText(GetL().GUILD_ACTIONS_MENU or "Guild Actions")
			local GuildFrame = BFL:GetModule("GuildFrame")
			actionButton:SetEnabled(not GuildFrame or not GuildFrame.IsInGuild or GuildFrame:IsInGuild())
		end
	end
	return chrome
end

function FriendsUI:ApplyFriendsRestrictionState(sectionID)
	if not (self.root and BetterFriendsFrame) then
		return false
	end

	local restricted = FRIENDS_RESTRICTED_SECTIONS[sectionID] == true and AreFriendsDisabled()
	local label = self.root.FriendsDisabledText
	if label then
		if restricted then
			local definition = SECTION_BY_ID[sectionID]
			local tabName = definition and (GetL()[definition.labelKey] or definition.id) or ""
			label:SetText(SOCIAL_TAB_UNAVAILABLE and SOCIAL_TAB_UNAVAILABLE:format(tabName) or tabName)
		end
		label:SetShown(restricted)
	end

	if not restricted then
		return false
	end

	local frame = BetterFriendsFrame
	if sectionID == "friends" then
		SafeShow(frame.ScrollFrame, false)
		SafeShow(frame.MinimalScrollBar, false)
	elseif sectionID == "recent_allies" then
		SafeShow(frame.RecentAlliesFrame, false)
	elseif sectionID == "quick_join" then
		SafeShow(frame.QuickJoinFrame, false)
	elseif sectionID == "friend_requests" then
		SafeShow(self.root.RequestsFrame, false)
	elseif sectionID == "recruit_a_friend" then
		SafeShow(frame.RecruitAFriendFrame, false)
		SafeShow(frame.RecruitmentButton, false)
	end
	return true
end

local function SetModernHeaderHeight(button, height)
	if not button then
		return
	end
	button:SetHeight(height)
	for _, key in ipairs({ "Left", "Middle", "Right" }) do
		local texture = button[key]
		if texture then
			texture:SetHeight(height)
		end
	end
end

local function ApplyModernDirectoryHeaderVisual(button)
	if not button then
		return
	end
	for _, key in ipairs({ "Left", "Middle", "Right", "Background" }) do
		SafeShow(button[key], false)
	end
	if button.NineSlice then
		button.NineSlice:Hide()
	end
	if not button.BFL_ModernHeaderBackground then
		local texture = button:CreateTexture(nil, "BACKGROUND", nil, -1)
		texture:SetAllPoints()
		texture:SetAtlas("common-button-list-collapseExpand")
		button.BFL_ModernHeaderBackground = texture
	end
	button.BFL_ModernHeaderBackground:Show()
end

function FriendsUI:ApplyModernDirectoryGeometry(sectionID)
	local frame = BetterFriendsFrame
	local root = self.root
	if not (frame and root) then
		return
	end

	local guild = frame.GuildFrame
	local guildActive = sectionID == "guild"
	if guild then
		SafeShow(guild.SearchBox, guildActive)
		SafeShow(guild.FilterDropdown, guildActive)
		SafeShow(guild.SortDropdown, guildActive)
		SafeShow(guild.ActionsButton, false)
		if guildActive then
			if guild.SortDropdown then
				guild.SortDropdown:ClearAllPoints()
				guild.SortDropdown:SetPoint("RIGHT", root.FilterBar, "RIGHT", -7, 0)
				guild.SortDropdown:SetSize(92, 29)
				ConstrainDropdownText(guild.SortDropdown, 5, -20, 1)
			end
			if guild.FilterDropdown then
				guild.FilterDropdown:ClearAllPoints()
				guild.FilterDropdown:SetPoint(
					"RIGHT",
					guild.SortDropdown or root.FilterBar,
					guild.SortDropdown and "LEFT" or "RIGHT",
					guild.SortDropdown and -7 or -7,
					0
				)
				guild.FilterDropdown:SetSize(92, 29)
				ConstrainDropdownText(guild.FilterDropdown, 5, -20, 1)
			end
			if guild.SearchBox then
				guild.SearchBox:ClearAllPoints()
				guild.SearchBox:SetPoint("LEFT", root.FilterBar, "LEFT", 15, 0)
				guild.SearchBox:SetPoint(
					"RIGHT",
					guild.FilterDropdown or guild.SortDropdown or root.FilterBar,
					"LEFT",
					-7,
					0
				)
				guild.SearchBox:SetHeight(30)
				ApplyModernSearchBoxVisual(guild.SearchBox)
				if guild.SearchBox.Instructions then
					guild.SearchBox.Instructions:SetText(SOCIAL_UI_SEARCH_BOX_INSTRUCTIONS or SEARCH or "Search")
				end
			end
			if guild.ListInset then
				SafeShow(guild.ListInset.Bg, false)
				SafeShow(guild.ListInset.NineSlice, false)
			end
			SafeShow(guild.HeaderDivider, false)
			local GuildFrame = BFL:GetModule("GuildFrame")
			if GuildFrame and GuildFrame.UpdateLayout then
				GuildFrame:UpdateLayout()
			end
		end
	end

	local who = frame.WhoFrame
	local whoActive = sectionID == "who"
	if who then
		SafeShow(who.EditBox, whoActive)
		SafeShow(who.WhoButton, whoActive)
		SafeShow(who.AddFriendButton, whoActive)
		SafeShow(who.GroupInviteButton, whoActive)
		if whoActive then
			who.WhoButton:ClearAllPoints()
			who.WhoButton:SetPoint("RIGHT", root.FilterBar, "RIGHT", -7, 0)
			who.WhoButton:SetSize(92, 29)
			who.EditBox:ClearAllPoints()
			who.EditBox:SetPoint("LEFT", root.FilterBar, "LEFT", 15, 0)
			who.EditBox:SetPoint("RIGHT", who.WhoButton, "LEFT", -7, 0)
			who.EditBox:SetHeight(30)
			ApplyModernSearchBoxVisual(who.EditBox)
			if who.EditBox.Instructions then
				who.EditBox.Instructions:SetText(SOCIAL_UI_SEARCH_BOX_INSTRUCTIONS or SEARCH or "Search")
			end

			who.ListInset:ClearAllPoints()
			who.ListInset:SetAllPoints(who)
			SafeShow(who.ListInset.Bg, false)
			SafeShow(who.ListInset.NineSlice, false)
			local WhoFrame = BFL:GetModule("WhoFrame")
			if WhoFrame and WhoFrame.ApplyModernSearchBuilderLayout then
				WhoFrame:ApplyModernSearchBuilderLayout()
			end
			local builderOffset = who.BFL_ModernBuilderHeight or 0
			who.NameHeader:ClearAllPoints()
			who.NameHeader:SetPoint("TOPLEFT", who.ListInset, "TOPLEFT", 4, -2 - builderOffset)
			SetModernHeaderHeight(who.NameHeader, 24)
			ApplyModernDirectoryHeaderVisual(who.NameHeader)
			who.ColumnDropdown:ClearAllPoints()
			who.ColumnDropdown:SetPoint("TOPLEFT", who.NameHeader, "TOPRIGHT", -1, 0)
			who.ColumnDropdown:SetHeight(24)
			ApplyModernDirectoryHeaderVisual(who.ColumnDropdown)
			who.LevelHeader:ClearAllPoints()
			who.LevelHeader:SetPoint("TOPLEFT", who.ColumnDropdown, "TOPRIGHT", -1, 0)
			SetModernHeaderHeight(who.LevelHeader, 24)
			ApplyModernDirectoryHeaderVisual(who.LevelHeader)
			who.ClassHeader:ClearAllPoints()
			who.ClassHeader:SetPoint("TOPLEFT", who.LevelHeader, "TOPRIGHT", -1, 0)
			SetModernHeaderHeight(who.ClassHeader, 24)
			ApplyModernDirectoryHeaderVisual(who.ClassHeader)

			who.ListInset.Totals:ClearAllPoints()
			who.ListInset.Totals:SetPoint("BOTTOMLEFT", who.ListInset, "BOTTOMLEFT", 8, 6)
			who.ListInset.Totals:SetPoint("BOTTOMRIGHT", who.ListInset, "BOTTOMRIGHT", -MODERN_SCROLL_BOX_RIGHT_INSET, 6)

			local buttonGap = 7
			who.AddFriendButton:ClearAllPoints()
			who.AddFriendButton:SetPoint("RIGHT", root.BottomActionBar, "CENTER", -buttonGap / 2, 0)
			who.AddFriendButton:SetSize(140, 30)
			who.GroupInviteButton:ClearAllPoints()
			who.GroupInviteButton:SetPoint("LEFT", root.BottomActionBar, "CENTER", buttonGap / 2, 0)
			who.GroupInviteButton:SetSize(140, 30)

			if WhoFrame and WhoFrame.UpdateResponsiveLayout then
				WhoFrame._lastLayoutWidth = nil
				WhoFrame:UpdateResponsiveLayout()
			end
		end
	end
end

local function GetModernRaidTextWidth(region, fallback)
	if region and region.GetStringWidth then
		local width = region:GetStringWidth()
		if width and width > 0 then
			return width
		end
	end
	return fallback or 0
end

local function SizeCompactModernRaidButton(button, minWidth, maxWidth)
	if not button then
		return
	end
	local fontString = button.GetFontString and button:GetFontString()
	local textWidth = GetModernRaidTextWidth(fontString, minWidth - 28)
	local width = math.max(minWidth, math.min(maxWidth, math.ceil(textWidth + 28)))
	button:SetSize(width, 24)
end

function FriendsUI:ApplyModernSectionTopChrome(sectionID)
	if not self.root then
		return
	end
	-- The native fade supplies the warm SocialUI color transition in every
	-- section. Raid only removes BFL's additional contact-list divider.
	SafeShow(self.root.TopFade, true)
	SafeShow(self.root.TopDivider, sectionID ~= "raid")
end

function FriendsUI:ApplyModernRaidGeometry()
	local raid = BetterFriendsFrame and BetterFriendsFrame.RaidFrame
	local control = raid and raid.ControlPanel
	if not control then
		return
	end

	control:ClearAllPoints()
	control:SetPoint("TOPLEFT", raid, "TOPLEFT", 0, 0)
	control:SetPoint("TOPRIGHT", raid, "TOPRIGHT", 0, 0)
	control:SetHeight(32)

	local helpButton = BetterFriendsFrame.HelpButton
	if helpButton then
		helpButton:SetParent(control)
		helpButton:ClearAllPoints()
		helpButton:SetSize(24, 24)
		helpButton:SetFrameLevel(control:GetFrameLevel() + 5)
		if helpButton.Icon then
			helpButton.Icon:SetSize(17, 17)
		end
	end

	local assist = control.EveryoneAssistCheckbox
	if assist then
		assist:ClearAllPoints()
		assist:SetPoint("TOPLEFT", control, "TOPLEFT", 8, -10)
		assist:SetSize(24, 24)
	end
	local assistIcon = control.EveryoneAssistIcon
	if assistIcon then
		SafeSetAtlas(assistIcon, "friends-icon-raidAssist")
		assistIcon:SetSize(17, 15)
		assistIcon:ClearAllPoints()
		assistIcon:SetPoint("LEFT", assist, "RIGHT", 2, 0)
		assistIcon:Show()
	end
	local assistLabel = control.EveryoneAssistLabel
	if assistLabel then
		assistLabel:ClearAllPoints()
		assistLabel:SetPoint("LEFT", assistIcon or assist, "RIGHT", 2, 0)
		assistLabel:SetJustifyH("LEFT")
		assistLabel:SetText(ALL_ASSIST_LABEL_SHORT or ALL or "All")
		if GameFontNormalMed1 then
			assistLabel:SetFontObject(GameFontNormalMed1)
		end
		assistLabel:Show()
	end
	if helpButton then
		helpButton:SetPoint("LEFT", assistLabel or assist, "RIGHT", 4, 0)
	end

	SafeShow(control.TankFrame, false)
	SafeShow(control.HealerFrame, false)
	SafeShow(control.DamagerFrame, false)
	SafeShow(control.RoleSummary, true)

	local raidInfoWidth = 100
	local rightPadding = 4
	local panelWidth = control:GetWidth()
	if not panelWidth or panelWidth <= 0 then
		panelWidth = raid:GetWidth() or 400
	end
	local assistLabelWidth = GetModernRaidTextWidth(assistLabel, 20)
	local leftSectionEnd = 8 + 24 + 2 + 17 + 2 + assistLabelWidth + (helpButton and 28 or 0)
	local utilityVisible = (control.ReadyCheckButton and control.ReadyCheckButton:IsShown())
		or (control.CombatIcon and control.CombatIcon:IsShown())
	local utilityWidth = utilityVisible and 27 or 0
	local rightSectionStart = panelWidth - rightPadding - raidInfoWidth - utilityWidth
	local roleWidth = control.RoleSummary and control.RoleSummary:GetWidth() or 125
	local memberWidth = GetModernRaidTextWidth(control.MemberCount, 45)
	local narrowLayout = panelWidth < 380
	local sectionGap = narrowLayout and 1 or 4
	local centerGap = narrowLayout and 2 or 4
	local centerWidth = roleWidth + centerGap + memberWidth
	local availableCenter = rightSectionStart - leftSectionEnd
	local centerStart = leftSectionEnd + math.max(sectionGap, (availableCenter - centerWidth) / 2)
	centerStart = math.max(
		leftSectionEnd + sectionGap,
		math.min(centerStart, rightSectionStart - centerWidth - sectionGap)
	)

	if control.RoleSummary then
		control.RoleSummary:ClearAllPoints()
		control.RoleSummary:SetPoint("LEFT", control, "LEFT", centerStart, -6)
		control.RoleSummary:Show()
	end
	if control.MemberCount then
		control.MemberCount:ClearAllPoints()
		control.MemberCount:SetPoint("LEFT", control.RoleSummary, "RIGHT", centerGap, 0)
		control.MemberCount:SetJustifyH("LEFT")
		control.MemberCount:Show()
	end

	if control.RaidInfoButton then
		control.RaidInfoButton:ClearAllPoints()
		control.RaidInfoButton:SetPoint("TOPRIGHT", control, "TOPRIGHT", -rightPadding, -6)
		control.RaidInfoButton:SetSize(raidInfoWidth, 32)
	end
	local utilityOffset = -15
	if control.ReadyCheckButton then
		control.ReadyCheckButton:ClearAllPoints()
		control.ReadyCheckButton:SetPoint("CENTER", control.RaidInfoButton, "LEFT", utilityOffset, 0)
	end
	if control.CombatIcon then
		control.CombatIcon:ClearAllPoints()
		control.CombatIcon:SetPoint("CENTER", control.RaidInfoButton, "LEFT", utilityOffset, -1)
	end

	local groupsInset = raid.GroupsInset
	if groupsInset then
		groupsInset:ClearAllPoints()
		groupsInset:SetPoint("TOPLEFT", control, "BOTTOMLEFT", 0, 0)
		groupsInset:SetPoint("BOTTOMRIGHT", raid, "BOTTOMRIGHT", 0, 31)
		SafeShow(groupsInset.Bg, false)
		SafeShow(groupsInset.NineSlice, false)
		SafeShow(groupsInset.backdrop, false)
		SafeShow(groupsInset.BFL_DarkBackdrop, false)
		if groupsInset.SetBackdrop then
			groupsInset:SetBackdrop(nil)
		end
		local container = groupsInset.GroupsContainer
		if container then
			container:ClearAllPoints()
			container:SetPoint("TOPLEFT", groupsInset, "TOPLEFT", 9, -7)
			container:SetPoint("BOTTOMRIGHT", groupsInset, "BOTTOMRIGHT", -9, 0)
		end
	end

	SizeCompactModernRaidButton(raid.RaidToolsButton, 72, 110)
	SizeCompactModernRaidButton(raid.ConvertToRaidButton, 120, 180)
	if raid.RaidToolsButton then
		raid.RaidToolsButton:ClearAllPoints()
		raid.RaidToolsButton:SetPoint("BOTTOMLEFT", raid, "BOTTOMLEFT", 8, 5)
	end
	if raid.ConvertToRaidButton then
		raid.ConvertToRaidButton:ClearAllPoints()
		raid.ConvertToRaidButton:SetPoint("BOTTOMRIGHT", raid, "BOTTOMRIGHT", -8, 5)
	end

	if not raid.BFL_ModernRaidResizeHooked then
		raid:HookScript("OnSizeChanged", function()
			if not FriendsUI:IsModernActive() then
				return
			end
			FriendsUI:ApplyModernRaidGeometry()
			local RaidFrame = BFL:GetModule("RaidFrame")
			if RaidFrame and RaidFrame.UpdateGroupLayout then
				RaidFrame._lastLayoutWidth = nil
				RaidFrame._lastLayoutHeight = nil
				RaidFrame:UpdateGroupLayout()
			end
		end)
		raid.BFL_ModernRaidResizeHooked = true
	end
end

function FriendsUI:RestoreLegacyRaidGeometry()
	local raid = BetterFriendsFrame and BetterFriendsFrame.RaidFrame
	local control = raid and raid.ControlPanel
	if not control then
		return
	end
	control:ClearAllPoints()
	control:SetPoint("TOPLEFT", raid, "TOPLEFT", 14, -8)
	control:SetPoint("TOPRIGHT", raid, "TOPRIGHT", -14, -8)
	control:SetHeight(48)
	local helpButton = BetterFriendsFrame.HelpButton
	if helpButton then
		helpButton:SetParent(BetterFriendsFrame)
		helpButton:SetSize(24, 24)
		if helpButton.Icon then
			helpButton.Icon:SetSize(18, 18)
		end
	end
	local StreamerMode = BFL:GetModule("StreamerMode")
	if StreamerMode and StreamerMode.UpdateAdjacentButtonAnchors then
		StreamerMode:UpdateAdjacentButtonAnchors()
	end
	SafeShow(control.EveryoneAssistIcon, false)
	SafeShow(control.TankFrame, false)
	SafeShow(control.HealerFrame, false)
	SafeShow(control.DamagerFrame, false)
	SafeShow(control.RoleSummary, true)
	if control.RaidInfoButton then
		control.RaidInfoButton:SetSize(90, 22)
	end
	local groupsInset = raid.GroupsInset
	if groupsInset then
		groupsInset:ClearAllPoints()
		groupsInset:SetPoint("TOPLEFT", control, "BOTTOMLEFT", -4, 10)
		groupsInset:SetPoint("BOTTOMRIGHT", raid, "BOTTOMRIGHT", -2, 21)
		SafeShow(groupsInset.Bg, true)
		SafeShow(groupsInset.NineSlice, true)
		local container = groupsInset.GroupsContainer
		if container then
			container:ClearAllPoints()
			container:SetPoint("TOPLEFT", groupsInset, "TOPLEFT", 10, -2)
			container:SetPoint("BOTTOMRIGHT", groupsInset, "BOTTOMRIGHT", -10, 2)
		end
	end
	if raid.ConvertToRaidButton then
		raid.ConvertToRaidButton:ClearAllPoints()
		raid.ConvertToRaidButton:SetPoint("BOTTOMRIGHT", raid, "BOTTOMRIGHT", -2, -1)
		raid.ConvertToRaidButton:SetSize(150, 21)
	end
	if raid.RaidToolsButton then
		raid.RaidToolsButton:ClearAllPoints()
		raid.RaidToolsButton:SetPoint("TOPLEFT", raid.GroupsInset, "BOTTOMLEFT", -2, -1)
		raid.RaidToolsButton:SetSize(150, 21)
	end
end

function FriendsUI:ApplyModernQuickJoinGeometry(sectionID)
	local quickJoinFrame = BetterFriendsFrame and BetterFriendsFrame.QuickJoinFrame
	local contentInset = quickJoinFrame and quickJoinFrame.ContentInset
	if not contentInset then
		return
	end
	local modernQuickJoin = sectionID == "quick_join"
	contentInset:ClearAllPoints()
	contentInset:SetAllPoints(quickJoinFrame)
	contentInset:SetAlpha(1)
	SafeShow(contentInset.Bg, not modernQuickJoin)
	SafeShow(contentInset.NineSlice, not modernQuickJoin)
	local joinButton = contentInset.JoinQueueButton
	if joinButton then
		joinButton:SetShown(not modernQuickJoin)
	end
	if contentInset.ScrollBoxContainer then
		contentInset.ScrollBoxContainer:ClearAllPoints()
		contentInset.ScrollBoxContainer:SetPoint("TOPLEFT", contentInset, "TOPLEFT", 0, 0)
		contentInset.ScrollBoxContainer:SetPoint("BOTTOMRIGHT", contentInset, "BOTTOMRIGHT", -MODERN_SCROLL_BOX_RIGHT_INSET, 0)
	end
end

function FriendsUI:RestoreLegacyQuickJoinGeometry()
	local quickJoinFrame = BetterFriendsFrame and BetterFriendsFrame.QuickJoinFrame
	local contentInset = quickJoinFrame and quickJoinFrame.ContentInset
	if not contentInset then
		return
	end
	contentInset:ClearAllPoints()
	contentInset:SetPoint("TOPLEFT", quickJoinFrame, "TOPLEFT", 0, 80)
	contentInset:SetPoint("BOTTOMRIGHT", quickJoinFrame, "BOTTOMRIGHT", 0, 0)
	contentInset:SetAlpha(1)
	SafeShow(contentInset.Bg, true)
	SafeShow(contentInset.NineSlice, true)
	SafeShow(contentInset.JoinQueueButton, true)
	if contentInset.ScrollBoxContainer then
		contentInset.ScrollBoxContainer:ClearAllPoints()
		contentInset.ScrollBoxContainer:SetPoint("TOPLEFT", contentInset, "TOPLEFT", 4, -4)
		contentInset.ScrollBoxContainer:SetPoint("BOTTOMRIGHT", contentInset, "BOTTOMRIGHT", -24, 4)
	end
end

function FriendsUI:LayoutRequestsFrame()
	if not self.root then
		return
	end
	local requests = self.root.RequestsFrame
	local referenceScrollBar = BetterFriendsFrame and BetterFriendsFrame.MinimalScrollBar
	local referenceWidth = referenceScrollBar and referenceScrollBar:GetWidth()
	requests.ScrollBox:ClearAllPoints()
	requests.ScrollBar:ClearAllPoints()
	if referenceWidth and referenceWidth > 0 then
		requests.ScrollBar:SetWidth(referenceWidth)
	end
	requests.ScrollBox:SetPoint("TOPLEFT", requests, "TOPLEFT", 0, 0)
	requests.ScrollBox:SetPoint("BOTTOMRIGHT", requests, "BOTTOMRIGHT", -MODERN_SCROLL_BOX_RIGHT_INSET, 0)
	requests.ScrollBar:SetPoint("TOPLEFT", requests.ScrollBox, "TOPRIGHT", MODERN_SCROLL_BAR_GAP, 0)
	requests.ScrollBar:SetPoint("BOTTOMLEFT", requests.ScrollBox, "BOTTOMRIGHT", MODERN_SCROLL_BAR_GAP, 0)
end

local function AnchorModernScrollBar(scrollBar, scrollBox, topOffset, bottomOffset, width)
	if not (scrollBar and scrollBox) then
		return
	end
	scrollBar:ClearAllPoints()
	if width and width > 0 then
		scrollBar:SetWidth(width)
	end
	scrollBar:SetPoint("TOPLEFT", scrollBox, "TOPRIGHT", MODERN_SCROLL_BAR_GAP, topOffset or 0)
	scrollBar:SetPoint("BOTTOMLEFT", scrollBox, "BOTTOMRIGHT", MODERN_SCROLL_BAR_GAP, bottomOffset or 0)
end

function FriendsUI:GetModernScrollBarLeftInset()
	return MODERN_SCROLL_BOX_RIGHT_INSET - MODERN_SCROLL_BAR_GAP
end

function FriendsUI:GetModernScrollBoxRightInset()
	return MODERN_SCROLL_BOX_RIGHT_INSET
end

function FriendsUI:GetModernScrollBarGap()
	return MODERN_SCROLL_BAR_GAP
end

function FriendsUI:GetAuxiliaryWindowOffset()
	-- LargeSideTabButtonTemplate protrudes from the main frame's right edge.
	-- Leave the complete tab rail plus a small visual gap unobstructed.
	return self:IsModernActive() and 68 or 5
end

function FriendsUI:AnchorAuxiliaryWindow(window, topOffset)
	if not (window and BetterFriendsFrame) then
		return
	end
	window:ClearAllPoints()
	window:SetPoint(
		"TOPLEFT",
		BetterFriendsFrame,
		"TOPRIGHT",
		self:GetAuxiliaryWindowOffset(),
		topOffset or 0
	)
end

function FriendsUI:ApplyModernScrollBarGeometry()
	local frame = BetterFriendsFrame
	if not (self.root and frame) then
		return
	end

	local referenceWidth = frame.MinimalScrollBar and frame.MinimalScrollBar:GetWidth()
	if not referenceWidth or referenceWidth <= 0 then
		referenceWidth = 8
	end

	AnchorModernScrollBar(frame.MinimalScrollBar, frame.ScrollFrame, nil, nil, referenceWidth)

	local recentAllies = frame.RecentAlliesFrame
	if recentAllies and recentAllies.ScrollBox then
		recentAllies.ScrollBox:ClearAllPoints()
		recentAllies.ScrollBox:SetPoint("TOPLEFT", recentAllies, "TOPLEFT", 4, -2)
		recentAllies.ScrollBox:SetPoint("BOTTOMRIGHT", recentAllies, "BOTTOMRIGHT", -MODERN_SCROLL_BOX_RIGHT_INSET, -2)
		AnchorModernScrollBar(recentAllies.ScrollBar, recentAllies.ScrollBox, nil, nil, referenceWidth)
	end

	local recruitList = frame.RecruitAFriendFrame and frame.RecruitAFriendFrame.RecruitList
	if recruitList and recruitList.ScrollBox then
		recruitList.ScrollBox:ClearAllPoints()
		recruitList.ScrollBox:SetPoint("TOPLEFT", recruitList.Header, "BOTTOMLEFT", 0, -3)
		recruitList.ScrollBox:SetPoint("BOTTOMRIGHT", recruitList, "BOTTOMRIGHT", -MODERN_SCROLL_BOX_RIGHT_INSET, 1)
		AnchorModernScrollBar(recruitList.ScrollBar, recruitList.ScrollBox, nil, nil, referenceWidth)
	end

	local quickJoinInset = frame.QuickJoinFrame and frame.QuickJoinFrame.ContentInset
	if quickJoinInset then
		AnchorModernScrollBar(quickJoinInset.ScrollBar, quickJoinInset.ScrollBoxContainer, nil, nil, referenceWidth)
	end

	local who = frame.WhoFrame
	if who and who.ScrollBox then
		who.ScrollBox:ClearAllPoints()
		who.ScrollBox:SetPoint("TOPLEFT", who.NameHeader, "BOTTOMLEFT", 7, -2)
		who.ScrollBox:SetPoint(
			"BOTTOMRIGHT",
			who.ListInset,
			"BOTTOMRIGHT",
			-MODERN_SCROLL_BOX_RIGHT_INSET,
			24
		)
		-- Include the column-header and totals bands so Who uses the same full
		-- vertical scrollbar rail as the Friends list.
		AnchorModernScrollBar(who.ScrollBar, who.ScrollBox, 26, -24, referenceWidth)
	end

	local guild = frame.GuildFrame
	if guild and guild.ScrollBox then
		guild.ScrollBox:ClearAllPoints()
		guild.ScrollBox:SetPoint("TOPLEFT", guild.ListInset, "TOPLEFT", 4, -4)
		guild.ScrollBox:SetPoint("BOTTOMRIGHT", guild.ListInset, "BOTTOMRIGHT", -MODERN_SCROLL_BOX_RIGHT_INSET, 4)
		AnchorModernScrollBar(guild.ScrollBar, guild.ScrollBox, nil, nil, referenceWidth)
	end

	self:LayoutRequestsFrame()
end

function FriendsUI:RefreshRequests(newInvite)
	local count = GetFriendInviteCount()
	if self.root and self.requestsInitialized then
		local dataProvider = CreateDataProvider()
		local hasRealID = false
		local headerFormat = SOCIAL_UI_FRIEND_REQUESTS_RECEIVED_HEADER or "Friend Requests Received (%d)"
		dataProvider:Insert({ headerText = string.format(headerFormat, count) })
		dataProvider:Insert({ isSpacer = true })
		for index = 1, count do
			local info = self:NormalizeInvite(index)
			if info then
				dataProvider:Insert(info)
				hasRealID = hasRealID or self:IsRealIDInvite(info.friendLevel)
			end
		end
		self.root.RequestsFrame.ScrollBox:SetDataProvider(dataProvider, ScrollBoxConstants.RetainScrollPosition)
		self.root.RequestsFrame.EmptyLabel:SetShown(count == 0)
		local warningSeen = GetCVarBool and GetCVarBool("pendingInviteInfoShown")
		local realIDEnabled = false
		if BNGetInfo then
			local ok, _, _, _, _, _, _, enabled = pcall(BNGetInfo)
			realIDEnabled = ok and enabled == true
		end
		self.root.RequestsFrame.RealIDWarning:SetShown(hasRealID and realIDEnabled and not warningSeen)
		self:LayoutRequestsFrame()
	end
	if count == 0 then
		self:StopRequestGlow()
	elseif self:ShouldStartRequestGlow(newInvite) then
		self:StartRequestGlow()
	end
	self:RefreshNavigation()
end

function FriendsUI:HideAllContentFrames()
	local frame = BetterFriendsFrame
	if not frame then
		return
	end
	for _, field in ipairs({ "ScrollFrame", "MinimalScrollBar", "RecentAlliesFrame", "RecruitAFriendFrame", "QuickJoinFrame", "WhoFrame", "RaidFrame", "GuildFrame", "SortFrame", "AddFriendButton", "SendMessageButton", "RecruitmentButton" }) do
		SafeShow(frame[field], false)
	end
end

function FriendsUI:HideLegacyTabs()
	local frame = BetterFriendsFrame
	if not frame then
		return
	end
	for _, field in ipairs({ "BottomTab1", "BottomTab2", "BottomTab3", "BottomTab4" }) do
		SafeShow(frame[field], false)
	end
	local header = frame.FriendsTabHeader
	if header then
		for _, field in ipairs({ "Tab1", "Tab2", "Tab3", "Tab4" }) do
			SafeShow(header[field], false)
		end
	end
end

function FriendsUI:SynchronizeModernBottomFade()
	if not BFL.IsRetail then
		return false
	end
	local root = self.root
	local frame = BetterFriendsFrame
	local background = frame and (frame.Bg or frame)
	local topFade = root and root.TopFade
	local bottomFade = root and root.BottomFade
	if not (background and topFade and bottomFade) then
		return false
	end

	-- The two SocialUI atlases intentionally have different native widths.  The
	-- visual edge of the bottom atlas must therefore take its width from the
	-- rendered top fade, rather than from its own atlas dimensions.
	local topWidth = topFade:GetWidth() or 0
	if topWidth <= 0 then
		return false
	end

	bottomFade:ClearAllPoints()
	bottomFade:SetPoint("BOTTOM", background, "BOTTOM")
	bottomFade:SetWidth(topWidth)
	return true
end

function FriendsUI:QueueModernBottomFadeSync()
	local root = self.root
	if not (root and C_Timer and C_Timer.After) or root._bottomFadeSyncPending then
		return
	end
	root._bottomFadeSyncPending = true
	C_Timer.After(0, function()
		root._bottomFadeSyncPending = nil
		if self.root == root then
			self:SynchronizeModernBottomFade()
		end
	end)
end

function FriendsUI:ApplyModernRootGeometry()
	if not (self.root and BetterFriendsFrame) then
		return
	end
	local root = self.root
	local frame = BetterFriendsFrame
	local background = frame.Bg or frame

	root.BattleNetBar:ClearAllPoints()
	root.BattleNetBar:SetPoint("TOPLEFT", background, "TOPLEFT", -3, -1)
	root.BattleNetBar:SetPoint("TOPRIGHT", background, "TOPRIGHT", 3, -1)
	root.BattleNetBar.MenuButton:SetSize(34, 34)

	root.ContentBackground:ClearAllPoints()
	root.ContentBackground:SetPoint("TOP", root.BattleNetBar, "BOTTOM", 0, 5)
	root.ContentBackground:SetPoint("LEFT", frame, "LEFT", 4, 0)
	root.ContentBackground:SetPoint("RIGHT", frame, "RIGHT", -4, 0)
	root.ContentBackground:SetPoint("BOTTOM", frame, "BOTTOM", 0, 4)
	root.FadeMask:ClearAllPoints()
	-- Both native fades use this exact mask. This is the actual region clipping
	-- mechanism; SetClipsChildren does not clip textures in a frame's own layer.
	root.FadeMask:SetPoint("TOPLEFT", frame, "TOPLEFT", 4, 0)
	root.FadeMask:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -4, 4)

	-- Keep Blizzard's native top fade centered. Bottom follows its rendered
	-- width, shares its mask, and uses Blizzard's Bg-relative anchor.
	root.TopFade:ClearAllPoints()
	root.TopFade:SetPoint("TOP", root.BattleNetBar, "BOTTOM", 0, 5)
	self:SynchronizeModernBottomFade()
	-- Anchors resolve after the current layout pass. Repeat once so a newly
	-- created root never retains the bottom atlas' wider native width.
	self:QueueModernBottomFadeSync()

	root.FilterBar:ClearAllPoints()
	root.FilterBar:SetPoint("TOPLEFT", root.BattleNetBar, "BOTTOMLEFT", 0, 5)
	root.FilterBar:SetPoint("TOPRIGHT", root.BattleNetBar, "BOTTOMRIGHT", 0, 5)
	root.FilterBar.SortButton:ClearAllPoints()
	root.FilterBar.SortButton:SetPoint("RIGHT", root.FilterBar, "RIGHT", -7, 0)
	root.FilterBar.SortButton:SetSize(92, 29)
	root.FilterBar.FilterDropdown:ClearAllPoints()
	root.FilterBar.FilterDropdown:SetPoint("RIGHT", root.FilterBar.SortButton, "LEFT", -7, 0)
	root.FilterBar.FilterDropdown:SetSize(92, 29)
	-- The dropdown arrow is baked into the native background atlas, so the
	-- one-pixel shorter control reduces it together with the text and icon.
	ConstrainDropdownText(root.FilterBar.FilterDropdown, 5, -20, 1)
	root.FilterBar.RecentFilterDropdown:ClearAllPoints()
	root.FilterBar.RecentFilterDropdown:SetPoint("RIGHT", root.FilterBar, "RIGHT", -7, 0)
	root.FilterBar.RecentFilterDropdown:SetSize(92, 29)
	ConstrainDropdownText(root.FilterBar.RecentFilterDropdown, 5, -20, 1)
	self:RefreshSortButtonText()

	root.BottomActionBar:ClearAllPoints()
	root.BottomActionBar:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
	root.BottomActionBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
	root.TopDivider:ClearAllPoints()
	root.TopDivider:SetSize(400, 3)
	root.TopDivider:SetPoint("TOPLEFT", root.FilterBar, "BOTTOMLEFT", 5, -3)
	root.TopDivider:SetPoint("TOPRIGHT", root.FilterBar, "BOTTOMRIGHT", -5, -3)
	root.BottomDivider:ClearAllPoints()
	root.BottomDivider:SetHeight(3)
	root.BottomDivider:SetPoint("BOTTOMLEFT", root.BottomActionBar, "TOPLEFT", 5, -6)
	root.BottomDivider:SetPoint("BOTTOMRIGHT", root.BottomActionBar, "TOPRIGHT", -5, -6)

	root.RequestsFrame:ClearAllPoints()
	root.RequestsFrame:SetPoint("TOPLEFT", root.BattleNetBar, "BOTTOMLEFT", 8, -3)
	root.RequestsFrame:SetPoint("BOTTOMRIGHT", background, "BOTTOMRIGHT", -8, 8)
end

function FriendsUI:ApplyModernPortrait()
	local frame = BetterFriendsFrame
	if not frame then
		return
	end
	local db = GetDB()
	local simpleMode = db and db.simpleMode == true
	if frame._bflModernPortraitChromeShown ~= (not simpleMode) then
		frame._bflModernPortraitChromeShown = not simpleMode
		if frame.SetPortraitShown then
			frame:SetPortraitShown(not simpleMode)
		end

		-- ButtonFrameTemplate_HidePortrait also moves Bg, Inset and
		-- TitleContainer. Modern Simple Mode only hides the portrait, so keep
		-- the frame geometry untouched and exchange the integrated portrait
		-- corner artwork directly.
		local topLeftCorner = frame.NineSlice and frame.NineSlice.TopLeftCorner
		if topLeftCorner and topLeftCorner.SetAtlas then
			pcall(
				topLeftCorner.SetAtlas,
				topLeftCorner,
				simpleMode and "UI-Frame-Metal-CornerTopLeft" or "UI-Frame-PortraitMetal-CornerTopLeft",
				true
			)
		end
	end

	-- The native portrait TitleContainer is intentionally asymmetric. Anchor
	-- only its text to the actual frame so the title remains centered at every
	-- width and in both Simple Mode states without moving Battle.net chrome.
	local titleText = (frame.TitleContainer and frame.TitleContainer.TitleText) or frame.TitleText
	if titleText then
		titleText:ClearAllPoints()
		titleText:SetPoint("TOPLEFT", frame, "TOPLEFT", 72, -5)
		titleText:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -72, -5)
		titleText:SetJustifyH("CENTER")
	end

	-- Parent-layer portrait regions render below child frames and would be cut
	-- by the Battle.net bar. Modern therefore owns a child-frame portrait layer.
	SafeShow(frame.portrait, false)
	SafeShow(frame.PortraitIcon, false)
	SafeShow(frame.PortraitMask, false)
	SafeShow(self.root and self.root.PortraitOverlay, not simpleMode)
end

function FriendsUI:ApplyModernContentLayout(sectionID, skipNavigationRefresh)
	if not (self.root and BetterFriendsFrame) then
		return
	end
	local frame = BetterFriendsFrame
	local header = frame.FriendsTabHeader
	self:ApplyModernRootGeometry()
	self:HideLegacyTabs()
	if header then
		if header.StatusDropdown then
			header.StatusDropdown:SetParent(self.root.BattleNetBar)
			header.StatusDropdown:ClearAllPoints()
			header.StatusDropdown:SetPoint("LEFT", self.root.BattleNetBar, "LEFT", 65, 4)
			header.StatusDropdown:SetWidth(54)
			ConstrainDropdownText(header.StatusDropdown, 4, -20)
		end
		local bnetFrame = header.BattlenetFrame
		if bnetFrame then
			bnetFrame:SetParent(self.root.BattleNetBar)
			bnetFrame:ClearAllPoints()
			bnetFrame:SetPoint("LEFT", self.root.BattleNetBar, "LEFT", 65, 4)
			bnetFrame:SetPoint("RIGHT", self.root.BattleNetBar.MenuButton, "LEFT", -7, 4)
			bnetFrame:Show()
			SafeShow(bnetFrame.Background, true)
			SafeShow(bnetFrame.ContactsMenuButton, false)
			SafeShow(self.root.BattleNetBar.MenuButton, true)
			SafeShow(bnetFrame.SettingsButton, false)
		end
		if header.StatusDropdown and bnetFrame then
			header.StatusDropdown:SetFrameLevel(bnetFrame:GetFrameLevel() + 1)
		end
		self:LayoutBattleTagActions()
		self:HideModernLegacyHeaderDropdowns(header)
		local filterDropdown = self.root.FilterBar.FilterDropdown
		local QuickFilters = BFL:GetModule("QuickFilters")
		if filterDropdown and not filterDropdown._bflModernInitialized and QuickFilters and QuickFilters.InitDropdown then
			QuickFilters:InitDropdown(filterDropdown)
			filterDropdown._bflModernInitialized = true
		end
		if header.SearchBox and (sectionID == "friends" or sectionID == "recent_allies") then
			local searchRightControl = sectionID == "recent_allies" and self.root.FilterBar.RecentFilterDropdown or filterDropdown
			header.SearchBox:SetParent(self.root.FilterBar)
			header.SearchBox:ClearAllPoints()
			header.SearchBox:SetPoint("LEFT", self.root.FilterBar, "LEFT", 15, 0)
			header.SearchBox:SetPoint("RIGHT", searchRightControl, "LEFT", -7, 0)
			header.SearchBox:SetHeight(30)
			ApplyModernSearchBoxVisual(header.SearchBox)
			if header.SearchBox.Instructions then
				header.SearchBox.Instructions:SetText(SOCIAL_UI_SEARCH_BOX_INSTRUCTIONS or SEARCH or "Search")
			end
		end
	end
	local chrome = self:ApplyContactChrome(sectionID, header)
	local showFilter = chrome.filterBar == true
	local showAction = chrome.action ~= nil
	local raidLayout = sectionID == "raid"
	self:ApplyModernSectionTopChrome(sectionID)
	SafeShow(frame.AddFriendButton, false)
	SafeShow(frame.SendMessageButton, false)
	SafeShow(frame.RecruitmentButton, sectionID == "recruit_a_friend")

	if frame.Inset then
		frame.Inset:ClearAllPoints()
		if raidLayout then
			-- Match SocialUI's native raid content frame: it begins directly below
			-- the Battle.net bar and extends to the background's bottom edge.
			frame.Inset:SetPoint("TOPLEFT", self.root.BattleNetBar, "BOTTOMLEFT", 0, 5)
			frame.Inset:SetPoint("BOTTOMRIGHT", frame.Bg or frame, "BOTTOMRIGHT", 0, 0)
		elseif showFilter then
			frame.Inset:SetPoint("TOPLEFT", self.root.FilterBar, "BOTTOMLEFT", 8, -10)
			if showAction then
				frame.Inset:SetPoint("BOTTOMRIGHT", self.root.BottomActionBar, "TOPRIGHT", -8, 1)
			else
				frame.Inset:SetPoint("BOTTOMRIGHT", frame.Bg or frame, "BOTTOMRIGHT", -8, 8)
			end
		else
			local background = frame.Bg or frame
			frame.Inset:SetPoint("TOPLEFT", self.root.TopDivider, "BOTTOMLEFT", 3, -7)
			if showAction then
				frame.Inset:SetPoint("BOTTOMRIGHT", self.root.BottomActionBar, "TOPRIGHT", -8, 1)
			else
				frame.Inset:SetPoint("BOTTOMRIGHT", background, "BOTTOMRIGHT", -8, 8)
			end
		end
		frame.Inset:SetAlpha(0)
		frame.Inset:Show()
	end
	if frame.ScrollFrame then
		frame.ScrollFrame:ClearAllPoints()
		frame.ScrollFrame:SetPoint("TOPLEFT", frame.Inset, "TOPLEFT", 4, -2)
		frame.ScrollFrame:SetPoint("BOTTOMRIGHT", frame.Inset, "BOTTOMRIGHT", -MODERN_SCROLL_BOX_RIGHT_INSET, -2)
	end
	for _, field in ipairs({ "RecentAlliesFrame", "RecruitAFriendFrame", "QuickJoinFrame", "WhoFrame", "RaidFrame", "GuildFrame" }) do
		local child = frame[field]
		if child then
			child:SetFrameLevel(self.root:GetFrameLevel() + 2)
			child:ClearAllPoints()
			child:SetPoint("TOPLEFT", frame.Inset, "TOPLEFT")
			child:SetPoint("BOTTOMRIGHT", frame.Inset, "BOTTOMRIGHT")
		end
	end
	self:ApplyModernDirectoryGeometry(sectionID)
	self:ApplyModernQuickJoinGeometry(sectionID)
	if frame.ScrollFrame then
		frame.ScrollFrame:SetFrameLevel(self.root:GetFrameLevel() + 2)
	end
	if frame.MinimalScrollBar then
		frame.MinimalScrollBar:SetFrameLevel(self.root:GetFrameLevel() + 3)
	end
	self.root.RequestsFrame:ClearAllPoints()
	self.root.RequestsFrame:SetPoint("TOPLEFT", frame.Inset, "TOPLEFT")
	self.root.RequestsFrame:SetPoint("BOTTOMRIGHT", frame.Inset, "BOTTOMRIGHT")
	self.root.RequestsFrame:SetShown(sectionID == "friend_requests")
	self:AnchorAuxiliaryWindow(frame.IgnoreListWindow, 0)
	self:ApplyModernRaidGeometry()
	if sectionID == "raid" then
		local RaidFrame = BFL:GetModule("RaidFrame")
		if RaidFrame and RaidFrame.UpdateGroupLayout then
			RaidFrame._lastLayoutWidth = nil
			RaidFrame._lastLayoutHeight = nil
			RaidFrame:UpdateGroupLayout()
		end
	end
		self:ApplyModernScrollBarGeometry()
		self:ApplyFriendsRestrictionState(sectionID)
		if frame.TitleText then
		local definition = SECTION_BY_ID[sectionID]
		frame.TitleText:SetText(definition and (GetL()[definition.labelKey] or definition.id) or "BetterFriendlist")
	end
	if not skipNavigationRefresh then
		self:RefreshNavigation()
	end
end

function FriendsUI:ApplyModernLayout()
	local root = self:CreateModernRoot()
	if not root or not BetterFriendsFrame then
		return
	end
	self:CaptureLegacyLayout()
	root:Show()
	local frame = BetterFriendsFrame
	local header = frame.FriendsTabHeader
	if BFL.FrameInitializer and BFL.FrameInitializer.InitializeStatusDropdown then
		BFL.FrameInitializer:InitializeStatusDropdown(frame)
	end
	self:ApplyModernRootGeometry()
	self:HideLegacyTabs()
	if header then
		for _, field in ipairs({ "Tab1", "Tab2", "Tab3", "Tab4", "PrimarySortDropdown", "SecondarySortDropdown", "SettingsButton" }) do
			SafeShow(header[field], false)
		end
		if header.StatusDropdown then
			header.StatusDropdown:SetParent(root.BattleNetBar)
			header.StatusDropdown:ClearAllPoints()
			header.StatusDropdown:SetPoint("LEFT", root.BattleNetBar, "LEFT", 65, 4)
			header.StatusDropdown:SetWidth(54)
			ConstrainDropdownText(header.StatusDropdown, 4, -20)
			header.StatusDropdown:Show()
		end
		if header.BattlenetFrame then
			local bnetFrame = header.BattlenetFrame
			bnetFrame:SetParent(root.BattleNetBar)
			bnetFrame:ClearAllPoints()
			bnetFrame:SetPoint("LEFT", root.BattleNetBar, "LEFT", 65, 4)
			bnetFrame:SetPoint("RIGHT", root.BattleNetBar.MenuButton, "LEFT", -7, 4)
			bnetFrame:Show()
			SafeShow(bnetFrame.Background, true)
			SafeShow(bnetFrame.ContactsMenuButton, false)
			SafeShow(root.BattleNetBar.MenuButton, true)
			SafeShow(bnetFrame.SettingsButton, false)
		end
		if header.StatusDropdown and header.BattlenetFrame then
			header.StatusDropdown:SetFrameLevel(header.BattlenetFrame:GetFrameLevel() + 1)
		end
		self:LayoutBattleTagActions()
		self:HideModernLegacyHeaderDropdowns(header)
		local filterDropdown = root.FilterBar.FilterDropdown
		local QuickFilters = BFL:GetModule("QuickFilters")
		if filterDropdown and not filterDropdown._bflModernInitialized and QuickFilters and QuickFilters.InitDropdown then
			QuickFilters:InitDropdown(filterDropdown)
			filterDropdown._bflModernInitialized = true
		end
		if header.SearchBox then
			header.SearchBox:SetParent(root.FilterBar)
			header.SearchBox:ClearAllPoints()
			header.SearchBox:SetPoint("LEFT", root.FilterBar, "LEFT", 15, 0)
			header.SearchBox:SetPoint("RIGHT", filterDropdown, "LEFT", -7, 0)
			header.SearchBox:SetHeight(30)
			ApplyModernSearchBoxVisual(header.SearchBox)
			if header.SearchBox.Instructions then
				header.SearchBox.Instructions:SetText(SOCIAL_UI_SEARCH_BOX_INSTRUCTIONS or SEARCH or "Search")
			end
		end
	end
	self:ApplyModernPortrait()
	self:RefreshBattleTag()
	self:ApplyModernContentLayout(self.selectedSection or "friends")
	self:RefreshRequests(false)
end

function FriendsUI:RestoreLegacyLayout()
	if not BetterFriendsFrame then
		return
	end
	SafeShow(self.root, false)
	self:RestoreLegacyQuickJoinGeometry()
	if self.legacyState then
		for _, state in pairs(self.legacyState.frames) do
			RestoreFrameState(state, true)
		end
		if BetterFriendsFrame.portrait and self.legacyState.portraitTexture then
			BetterFriendsFrame.portrait:SetTexture(self.legacyState.portraitTexture)
		end
		if BetterFriendsFrame.TitleText then
			BetterFriendsFrame.TitleText:SetText(self.legacyState.title or "BetterFriendlist")
		end
		local header = BetterFriendsFrame.FriendsTabHeader
		if header and header.SearchBox and header.SearchBox.Instructions and self.legacyState.searchInstruction then
			header.SearchBox.Instructions:SetText(self.legacyState.searchInstruction)
		end
	end
	local who = BetterFriendsFrame.WhoFrame
	if who then
		for _, headerButton in ipairs({ who.NameHeader, who.ColumnDropdown, who.LevelHeader, who.ClassHeader }) do
			if headerButton then
				for _, key in ipairs({ "Left", "Middle", "Right" }) do
					if headerButton[key] then
						headerButton[key]:SetHeight(35)
						headerButton[key]:Show()
					end
				end
				SafeShow(headerButton.Background, true)
				SafeShow(headerButton.NineSlice, true)
				SafeShow(headerButton.BFL_ModernHeaderBackground, false)
			end
		end
		SafeShow(who.ListInset and who.ListInset.Bg, true)
		SafeShow(who.ListInset and who.ListInset.NineSlice, true)
		SafeShow(who.EditBox and who.EditBox.Backdrop, true)
	end
	local guild = BetterFriendsFrame.GuildFrame
	if guild then
		SafeShow(guild.ListInset and guild.ListInset.Bg, true)
		SafeShow(guild.ListInset and guild.ListInset.NineSlice, true)
		SafeShow(guild.HeaderDivider, true)
	end
	self:RestoreLegacyRaidGeometry()
	local RaidFrame = BFL:GetModule("RaidFrame")
	if RaidFrame and RaidFrame.UpdateGroupLayout then
		RaidFrame._lastLayoutWidth = nil
		RaidFrame._lastLayoutHeight = nil
		RaidFrame._lastLayoutModern = nil
		RaidFrame:UpdateGroupLayout()
		RaidFrame:UpdateControlPanel()
	end
	if BFL.UpdatePortraitVisibility then
		BFL:UpdatePortraitVisibility()
	end
	if BFL.FrameInitializer and BFL.FrameInitializer.InitializeStatusDropdown then
		BFL.FrameInitializer:InitializeStatusDropdown(BetterFriendsFrame)
	end
end

function FriendsUI:GetSelectedSection()
	if self.selectedSection then
		return self.selectedSection
	end
	if BetterFriendsFrame then
		local bottom = PanelTemplates_GetSelectedTab and PanelTemplates_GetSelectedTab(BetterFriendsFrame) or 1
		local header = BetterFriendsFrame.FriendsTabHeader
		local top = header and PanelTemplates_GetSelectedTab and PanelTemplates_GetSelectedTab(header) or 1
		return self:GetSectionForLegacyTabs(bottom, top)
	end
	return "friends"
end

function FriendsUI:SelectSection(sectionID)
	if not SECTION_BY_ID[sectionID] then
		sectionID = "friends"
	end
	if not self:IsSectionAvailable(sectionID) or (sectionID == "raid" and self:IsStoryRaidActive()) then
		sectionID = self:BuildAvailableSectionIDs()[1] or "friends"
	end
	if not self:IsModernActive() and sectionID == "friend_requests" then
		sectionID = "friends"
	end
	self.selectedSection = sectionID
	self.selectingSection = true
	if self:IsModernActive() and sectionID == "friend_requests" then
		self:HideAllContentFrames()
		self:StopRequestGlow()
		self:RefreshRequests(false)
	else
		local definition = SECTION_BY_ID[sectionID]
		if definition and definition.bottomTab and BetterFriendsFrame_ShowBottomTab then
			BetterFriendsFrame_ShowBottomTab(definition.bottomTab)
		end
		if definition and definition.topTab and BetterFriendsFrame_ShowTab then
			BetterFriendsFrame_ShowTab(definition.topTab)
		end
	end
	self.selectingSection = false
	if self:IsModernActive() then
		self:ApplyModernContentLayout(sectionID)
	end
	return sectionID
end

function FriendsUI:ToggleSection(sectionID)
	if not BetterFriendsFrame then
		return
	end
	if BetterFriendsFrame:IsShown() and self:GetSelectedSection() == sectionID then
		BetterFriendsFrame:Hide()
		return
	end
	if not BetterFriendsFrame:IsShown() then
		if ShowUIPanel then
			ShowUIPanel(BetterFriendsFrame)
		else
			BetterFriendsFrame:Show()
		end
	end
	self:SelectSection(sectionID)
end

function FriendsUI:SetStyle(style)
	if style ~= STYLE_MODERN and style ~= STYLE_LEGACY then
		return false
	end
	local FrameSettings = BFL:GetModule("FrameSettings")
	if FrameSettings and FrameSettings.SavePosition then
		FrameSettings:SavePosition()
	end
	local DB = BFL:GetModule("DB")
	if DB then
		DB:Set("friendsFrameStyle", style)
	elseif BetterFriendlistDB then
		BetterFriendlistDB.friendsFrameStyle = style
	end
	self:ApplyEffectiveStyle("setting")
	return true
end

function FriendsUI:ApplyEffectiveStyle(reason)
	local effective = self:GetEffectiveStyle()
	if InCombatLockdown and InCombatLockdown() then
		self.pendingStyle = effective
		return false
	end
	local selected = self:GetSelectedSection()
	if self.appliedStyle and self.appliedStyle ~= effective then
		local previousFrameSettings = BFL:GetModule("FrameSettings")
		if previousFrameSettings and previousFrameSettings.SavePosition then
			previousFrameSettings:SavePosition()
		end
	end
	self.appliedStyle = effective
	self.pendingStyle = nil
	local RAF = BFL:GetModule("RAF")
	local rafFrame = BetterFriendsFrame and BetterFriendsFrame.RecruitAFriendFrame
	if RAF and RAF.ApplyFrameStyle and rafFrame then
		RAF:ApplyFrameStyle(rafFrame)
	end
	if effective == STYLE_MODERN then
		self:ApplyModernLayout()
	else
		self:RestoreLegacyLayout()
	end
	local FrameSettings = BFL:GetModule("FrameSettings")
	if FrameSettings and FrameSettings.ApplySettings then
		FrameSettings:ApplySettings()
	end
	local FriendsList = BFL:GetModule("FriendsList")
	if FriendsList and FriendsList.OnFriendsUIStyleChanged then
		FriendsList:OnFriendsUIStyleChanged(effective, reason)
	end
	local ThemeManager = BFL:GetModule("ThemeManager")
	if ThemeManager and ThemeManager.ApplyCurrentTheme then
		ThemeManager:ApplyCurrentTheme()
	end
	self:SelectSection(selected)
	return true
end

function FriendsUI:OnLegacyTabSelected()
	if self.selectingSection then
		return
	end
	local bottom = PanelTemplates_GetSelectedTab and PanelTemplates_GetSelectedTab(BetterFriendsFrame) or 1
	local header = BetterFriendsFrame and BetterFriendsFrame.FriendsTabHeader
	local top = header and PanelTemplates_GetSelectedTab and PanelTemplates_GetSelectedTab(header) or 1
	self.selectedSection = self:GetSectionForLegacyTabs(bottom, top)
	if self:IsModernActive() then
		self:ApplyModernContentLayout(self.selectedSection)
	end
end

function FriendsUI:InstallTabHooks()
	if self.tabHooksInstalled or not hooksecurefunc then
		return
	end
	if BetterFriendsFrame_ShowTab then
		hooksecurefunc("BetterFriendsFrame_ShowTab", function()
			self:OnLegacyTabSelected()
		end)
	end
	if BetterFriendsFrame_ShowBottomTab then
		hooksecurefunc("BetterFriendsFrame_ShowBottomTab", function()
			self:OnLegacyTabSelected()
		end)
	end
	self.tabHooksInstalled = true
end

function FriendsUI:InstallSocialUIRedirects()
	if self.redirectsInstalled or not BFL.IsRetail then
		return
	end
	if not _G.SocialUIControl then
		return
	end
	self.redirectsInstalled = true
	self.originalToggleSocialUI = _G.ToggleSocialUI
	self.originalSocialUIControl = {}
	if SocialUIControl then
		for _, key in ipairs({ "Toggle", "OpenToTab", "ToggleToTab" }) do
			self.originalSocialUIControl[key] = SocialUIControl[key]
		end
	end
	_G.ToggleSocialUI = function()
		self:ToggleSection(self:GetSelectedSection())
	end
	if SocialUIControl then
		SocialUIControl.Toggle = function()
			self:ToggleSection(self:GetSelectedSection())
		end
		SocialUIControl.OpenToTab = function(tabType)
			local section = self:GetSectionForSocialTab(tabType) or "friends"
			if not BetterFriendsFrame:IsShown() then
				ShowUIPanel(BetterFriendsFrame)
			end
			self:SelectSection(section)
		end
		SocialUIControl.ToggleToTab = function(tabType)
			self:ToggleSection(self:GetSectionForSocialTab(tabType) or "friends")
		end
	end
end

function FriendsUI:EnsureSocialUIRedirects()
	if not (BFL.IsRetail and self:IsSocialUIEnabled()) then
		return
	end
	if not _G.SocialUIControl and C_AddOns and C_AddOns.LoadAddOn then
		pcall(C_AddOns.LoadAddOn, "Blizzard_SocialUIShared")
	end
	self:InstallSocialUIRedirects()
end

function FriendsUI:GetBlizzardSocialTab(sectionID)
	local tab = _G.SocialUITabType
	if not tab then
		return nil
	end
	return self:GetSocialTabForSection(sectionID) or tab.Friends
end

function FriendsUI:OpenLoadedBlizzardSocialUI(frame, tabType)
	if not frame then
		return false
	end
	if frame:IsShown() then
		if tabType and frame.SelectTab then
			frame:SelectTab(tabType)
		end
		return true
	end
	if tabType and frame.SetDeferredOpenTab then
		frame:SetDeferredOpenTab(tabType)
	end
	local originalControl = self.originalSocialUIControl
	if originalControl and originalControl.Toggle then
		originalControl.Toggle()
		return true
	end
	if ShowUIPanel then
		ShowUIPanel(frame)
	elseif frame.Show then
		frame:Show()
	end
	return true
end

function FriendsUI:OpenBlizzardSocialUI(sectionID)
	if not _G.SocialUIFrame and C_AddOns and C_AddOns.LoadAddOn then
		pcall(C_AddOns.LoadAddOn, "Blizzard_SocialUI")
	end
	local tabType = self:GetBlizzardSocialTab(sectionID or self:GetSelectedSection())
	return self:OpenLoadedBlizzardSocialUI(_G.SocialUIFrame, tabType)
end

function FriendsUI:ApplyTheme(theme)
	if not self.root then
		return
	end
	self.currentTheme = theme or self.currentTheme
	local isBlizzard = self.currentTheme == nil or self.currentTheme == "blizzard"
	local r, g, b = 0.04, 0.04, 0.04
	if self.currentTheme == "dark" then
		r, g, b = 0.025, 0.025, 0.025
	elseif self.currentTheme == "custom" then
		local ThemePalette = BFL:GetModule("ThemePalette")
		local color = ThemePalette and ThemePalette.GetResolvedCustomColor
			and ThemePalette:GetResolvedCustomColor("backgroundColor", { r, g, b, 1 })
		if type(color) == "table" then
			r, g, b = color.r or color[1] or r, color.g or color[2] or g, color.b or color[3] or b
		end
	elseif self.currentTheme == "elvui" then
		r, g, b = 0.055, 0.055, 0.055
	end
	self.root.ContentBackground:SetVertexColor(r, g, b, isBlizzard and 1 or 0.96)
	self.root.FilterBar.Background:SetVertexColor(r, g, b, 0.9)
	if self.root.BattleNetBar.Background then
		self.root.BattleNetBar.Background:SetVertexColor(isBlizzard and 1 or r * 3, isBlizzard and 1 or g * 3, isBlizzard and 1 or b * 3)
	end
	for _, definition in ipairs(SECTION_DEFINITIONS) do
		local tab = definition.tab
		if tab then
			local selected = self.selectedSection == definition.id
			ApplySectionIcon(tab.Icon or tab.icon, definition, selected)
		end
	end
	if self:IsModernActive() and BetterFriendsFrame then
		self:ApplyModernPortrait()
		self:ApplyModernContentLayout(self.selectedSection or "friends", true)
	end
end

function FriendsUI:StyleFriendCard(button)
	if not self:IsModernActive() or not button then
		return
	end
	local friend = button.friendData
	local db = GetDB()
	local faction = friend and (friend.factionName or (friend.gameAccountInfo and friend.gameAccountInfo.factionName))
	local factionTint
	if friend and friend.connected and db and db.showFactionBg then
		if faction == "Alliance" or faction == "Allianz" then
			factionTint = { 0.03, 0.30, 0.85 }
		elseif faction == "Horde" then
			factionTint = { 0.85, 0.03, 0.03 }
		end
	end
	local atlas = "friends-card-default"
	if friend and friend.connected == false then
		atlas = "friends-card-disabled"
	elseif friend and friend.type == "bnet" then
		local titleLevel = Enum and Enum.BattleNetFriendLevel and Enum.BattleNetFriendLevel.Title
		atlas = titleLevel and friend.friendLevel == titleLevel and "friends-card-default" or "friends-card-battleNet"
	end
	if button.CardBackground then
		SafeSetAtlas(button.CardBackground, atlas)
		local shade = (self.currentTheme == "dark" or self.currentTheme == "custom" or self.currentTheme == "elvui") and 0.72 or 1
		if button.CardBackground.SetDesaturated then
			button.CardBackground:SetDesaturated(false)
		end
		button.CardBackground:SetVertexColor(shade, shade, shade, 1)
		-- Keep the faction color behind Blizzard's card surface. The surface
		-- remains dominant and therefore preserves contrast for ARTWORK text.
		button.CardBackground:SetAlpha(factionTint and 0.76 or 1)
	end
	if button.FactionTintMask then
		SafeSetAtlas(button.FactionTintMask, atlas)
	end
	if button.FactionTint then
		if factionTint then
			if button.FactionTint.SetBlendMode then
				button.FactionTint:SetBlendMode("BLEND")
			end
			button.FactionTint:SetColorTexture(factionTint[1], factionTint[2], factionTint[3], 1)
			button.FactionTint:SetAlpha(1)
			button.FactionTint:Show()
		else
			button.FactionTint:Hide()
		end
	end
	if button.background then
		-- Modern faction color is clipped into the native card silhouette above.
		-- Never cover it with the legacy flat-color compatibility region.
		button.background:SetColorTexture(0, 0, 0, 0)
	end
	local actionButton = button.travelPassButton
	if actionButton then
		actionButton.friendData = friend
		actionButton.friendIndex = friend and friend.index or nil
		actionButton:SetSize(34, 34)
		actionButton:ClearAllPoints()
		actionButton:SetPoint("RIGHT", button, "RIGHT", -4, 0)
		SafeSetAtlas(actionButton.NormalTexture, "common-button-tertiary-square-normal")
		SafeSetAtlas(actionButton.PushedTexture, "common-button-tertiary-square-pressed")
		SafeSetAtlas(actionButton.DisabledTexture, "common-button-tertiary-square-normal")
		SafeSetAtlas(actionButton.HighlightTexture, "common-button-tertiary-square-normal")

		local isInGroup = false
		local playerGUID = friend and (friend.guid or (friend.gameAccountInfo and friend.gameAccountInfo.playerGuid))
		if playerGUID and C_SocialQueue and C_SocialQueue.IsSystemSupported and C_SocialQueue.GetGroupForPlayer then
			local supported = C_SocialQueue.IsSystemSupported()
			if supported then
				local ok, group = pcall(C_SocialQueue.GetGroupForPlayer, playerGUID)
				isInGroup = ok and group ~= nil
			end
		end
		local enabled = friend and friend.connected == true and (friend.type ~= "bnet" or friend.canInvite == true)
		actionButton:SetEnabled(enabled == true)
		if actionButton.ActionIcon then
			local atlas = isInGroup and "friends-icon-friendsInGroup" or "friends-icon-friendsAvailable"
			if not enabled then
				atlas = atlas .. "-dis"
			end
			SafeSetAtlas(actionButton.ActionIcon, atlas)
		end
		actionButton:Show()
		if button.gameIcon then
			button.gameIcon:SetSize(20, 20)
			button.gameIcon:ClearAllPoints()
			button.gameIcon:SetPoint("RIGHT", actionButton, "LEFT", -6, 1)
		end
	end
	-- FriendsList owns row height and the top-down text stack. Modern styling
	-- must not replace that calculated extent with the old 70/46px presets.
end

function FriendsUI:StyleGroupHeader(button)
	if not self:IsModernActive() or not button then
		return
	end
	button:SetHeight(24)
	local collapsed = button.elementData and button.elementData.collapsed == true
	SafeShow(button.RightArrow, false)
	SafeShow(button.DownArrow, false)
	if button.CollapseButton then
		SafeShow(button.CollapseButton, button._bflCollapseButtonShown ~= false)
		if
			button.CollapseButton.UpdateCollapsedState
			and button._bflCollapseButtonState ~= collapsed
		then
			button.CollapseButton:UpdateCollapsedState(collapsed)
		end
	end
	-- Text geometry is resolved once by FriendsList. Re-anchoring CountText to
	-- both HeaderText and CollapseButton here would recreate the constrained
	-- FontFamily layout that can hang Retail 12.1 with many group headers.
	local normal = button:GetNormalTexture()
	if normal then
		normal:SetVertexColor(1, 1, 1, 1)
	end
end

function FriendsUI:StyleRequestCard(button)
	if not button or not button.Background then
		return
	end
	local shade = (self.currentTheme == "dark" or self.currentTheme == "custom" or self.currentTheme == "elvui") and 0.72 or 1
	button.Background:SetVertexColor(shade, shade, shade, 1)
end

function FriendsUI:RegisterTests()
	if self.testsRegistered then
		return
	end
	local TestSuite = BFL:GetModule("TestSuite")
	if not TestSuite or not TestSuite.RegisterTest then
		return
	end
	self.testsRegistered = true
	TestSuite:RegisterTest("ui", "FriendsUI_Defaults", {
		action = function(V)
			V:AssertEqual(self:GetDefaultRequestedStyle(true), STYLE_MODERN, "Retail defaults to Modern")
			V:AssertEqual(self:GetDefaultRequestedStyle(false), STYLE_LEGACY, "Classic defaults to Legacy")
		end,
	})
	TestSuite:RegisterTest("ui", "FriendsUI_CapabilityFallback", {
		action = function(V)
			V:AssertEqual(self:ComputeEffectiveStyle(STYLE_MODERN, true, true), STYLE_MODERN, "Modern requires Retail SocialUI")
			V:AssertEqual(self:ComputeEffectiveStyle(STYLE_MODERN, true, false), STYLE_LEGACY, "Disabled SocialUI falls back")
			V:AssertEqual(self:ComputeEffectiveStyle(STYLE_MODERN, false, true), STYLE_LEGACY, "Classic remains Legacy")
		end,
	})
	TestSuite:RegisterTest("ui", "FriendsUI_SectionOrder", {
		action = function(V)
			V:AssertEqual(
				table.concat(self:NormalizeFriendTabOrder({}), ","),
				"friends,recent_allies,quick_join,friend_requests,recruit_a_friend,raid,guild,who",
				"Default section order must match SocialUI"
			)
		end,
	})
	TestSuite:RegisterTest("ui", "FriendsUI_FriendTabPreferences", {
		action = function(V)
			local db = GetDB()
			if not db then
				V:Skip("Database is unavailable")
				return
			end
			local originalOrder = db.modernFriendTabOrder
			local originalVisibility = db.modernFriendTabVisibility
			local originalPopulatedOnly = db.modernFriendTabPopulatedOnly
			local originalStyle = self.appliedStyle
			local ok, err = pcall(function()
				self.appliedStyle = STYLE_MODERN
				db.modernFriendTabOrder = { "who", "friends", "who", "unknown" }
				db.modernFriendTabVisibility = { raid = false }
				db.modernFriendTabPopulatedOnly = { friend_requests = true, quick_join = true }
				local all = {}
				for _, definition in ipairs(SECTION_DEFINITIONS) do
					all[definition.id] = true
				end
				local sections = self:BuildAvailableSectionIDs(all, {
					friend_requests = 0,
					quick_join = 2,
				})
				V:AssertEqual(
					table.concat(sections, ","),
					"who,friends,recent_allies,quick_join,recruit_a_friend,guild",
					"Order, general visibility, and populated-only visibility compose without layout gaps"
				)
				V:AssertEqual(
					table.concat(self:NormalizeFriendTabOrder({ "raid", "raid", "invalid" }), ","),
					"raid,friends,recent_allies,quick_join,friend_requests,recruit_a_friend,guild,who",
					"Saved tab order is deduplicated and completed with new tabs"
				)
			end)
			db.modernFriendTabOrder = originalOrder
			db.modernFriendTabVisibility = originalVisibility
			db.modernFriendTabPopulatedOnly = originalPopulatedOnly
			self.appliedStyle = originalStyle
			if not ok then
				error(err)
			end
		end,
	})
	TestSuite:RegisterTest("ui", "FriendsUI_LegacyTabMapping", {
		action = function(V)
			V:AssertEqual(self:GetSectionForLegacyTabs(1, 2), "recent_allies", "Top tab 2 maps to Recent Allies")
			V:AssertEqual(self:GetSectionForLegacyTabs(4, 1), "quick_join", "Bottom tab 4 maps to Quick Join")
			V:AssertEqual(self:GetSectionForLegacyTabs(2, 1), "who", "Bottom tab 2 maps to Who")
		end,
	})
	TestSuite:RegisterTest("ui", "FriendsUI_SeparateInviteProvider", {
		action = function(V)
			V:Assert(self:ShouldShowInvitesInline(STYLE_LEGACY), "Legacy keeps invites inline")
			V:Assert(not self:ShouldShowInvitesInline(STYLE_MODERN), "Modern uses the request provider")
		end,
	})
	TestSuite:RegisterTest("ui", "FriendsUI_SeparateFrameGeometry", {
		action = function(V)
			V:AssertEqual(self:GetLayoutKeyForStyle(STYLE_LEGACY), LEGACY_LAYOUT_KEY, "Legacy uses the Default geometry")
			V:AssertEqual(self:GetLayoutKeyForStyle(STYLE_MODERN), MODERN_LAYOUT_KEY, "Modern uses separate Retail geometry")
		end,
	})
	TestSuite:RegisterTest("ui", "FriendsUI_ModernScrollBarGrid", {
		action = function(V)
			V:AssertEqual(self:GetModernScrollBoxRightInset(), 18, "Modern section content leaves an 18 px scrollbar gutter")
			V:AssertEqual(self:GetModernScrollBarGap(), 7, "Modern scrollbars sit 7 px beyond their content viewport")
			V:AssertEqual(self:GetModernScrollBarLeftInset(), 11, "Every Modern scrollbar shares the Friends X position")
			if self:IsModernActive() and BetterFriendsFrame and BetterFriendsFrame.RecentAlliesFrame then
				self:ApplyModernScrollBarGeometry()
				local friends = BetterFriendsFrame.ScrollFrame
				local recent = BetterFriendsFrame.RecentAlliesFrame.ScrollBox
				local anchoredScrollBars = {
					{ BetterFriendsFrame.MinimalScrollBar, friends, "Friends" },
					{ BetterFriendsFrame.RecentAlliesFrame.ScrollBar, recent, "Recent Allies" },
				}
				local recruitList = BetterFriendsFrame.RecruitAFriendFrame
					and BetterFriendsFrame.RecruitAFriendFrame.RecruitList
				if recruitList then
					anchoredScrollBars[#anchoredScrollBars + 1] = {
						recruitList.ScrollBar,
						recruitList.ScrollBox,
						"Recruit A Friend",
					}
				end
				local quickJoinInset = BetterFriendsFrame.QuickJoinFrame
					and BetterFriendsFrame.QuickJoinFrame.ContentInset
				if quickJoinInset then
					anchoredScrollBars[#anchoredScrollBars + 1] = {
						quickJoinInset.ScrollBar,
						quickJoinInset.ScrollBoxContainer,
						"Quick Join",
					}
				end
				if BetterFriendsFrame.WhoFrame then
					anchoredScrollBars[#anchoredScrollBars + 1] = {
						BetterFriendsFrame.WhoFrame.ScrollBar,
						BetterFriendsFrame.WhoFrame.ScrollBox,
						"Who",
					}
				end
				if BetterFriendsFrame.GuildFrame then
					anchoredScrollBars[#anchoredScrollBars + 1] = {
						BetterFriendsFrame.GuildFrame.ScrollBar,
						BetterFriendsFrame.GuildFrame.ScrollBox,
						"Guild",
					}
				end
				if self.root and self.root.RequestsFrame then
					anchoredScrollBars[#anchoredScrollBars + 1] = {
						self.root.RequestsFrame.ScrollBar,
						self.root.RequestsFrame.ScrollBox,
						"Friend Requests",
					}
				end
				for _, entry in ipairs(anchoredScrollBars) do
					local scrollBar, scrollBox, label = entry[1], entry[2], entry[3]
					if scrollBar and scrollBox then
						V:AssertEqual(
							scrollBar:GetWidth(),
							BetterFriendsFrame.MinimalScrollBar:GetWidth(),
							label .. " scrollbar uses the Friends rail width"
						)
						local topLeftAnchor
						for pointIndex = 1, scrollBar:GetNumPoints() do
							local point, relativeTo, relativePoint, xOffset = scrollBar:GetPoint(pointIndex)
							if point == "TOPLEFT" then
								topLeftAnchor = { relativeTo, relativePoint, xOffset }
								break
							end
						end
						V:Assert(topLeftAnchor ~= nil, label .. " scrollbar has a top-left anchor")
						if topLeftAnchor then
							V:Assert(
								topLeftAnchor[1] == scrollBox,
								label .. " scrollbar anchors to its content viewport"
							)
							V:AssertEqual(
								topLeftAnchor[2],
								"TOPRIGHT",
								label .. " scrollbar follows the viewport's right edge"
							)
							V:AssertEqual(
								topLeftAnchor[3],
								7,
								label .. " scrollbar is visibly shifted 7 px beyond the viewport"
							)
						end
					end
				end
				V:Assert(
					friends and recent and math.abs(friends:GetHeight() - recent:GetHeight()) < 0.5,
					"Friends and Recent Allies scroll viewports use the same height"
				)
				if quickJoinInset and self.root and self.root.RequestsFrame then
					local requests = self.root.RequestsFrame
					self:ApplyModernQuickJoinGeometry("quick_join")
					self:LayoutRequestsFrame()
					V:Assert(
						math.abs(quickJoinInset.ScrollBoxContainer:GetHeight() - requests.ScrollBox:GetHeight()) < 0.5,
						"Quick Join and Friend Requests use the same full-height scroll viewport"
					)
					self:ApplyModernQuickJoinGeometry(self.selectedSection)
				end
			end
		end,
	})
	TestSuite:RegisterTest("ui", "FriendsUI_ModernRequestLevels", {
		action = function(V)
			local levels = Enum and Enum.BattleNetFriendLevel
			if not levels then
				V:Skip("BattleNet friend levels are unavailable")
				return
			end
			V:AssertEqual(self:GetFriendLevelLabel(levels.BattleTag), GetL().FRIENDS_UI_REQUEST_BATTLETAG or "BattleTag", "BattleTag request label")
			V:AssertEqual(self:GetFriendLevelLabel(levels.RealID), GetL().FRIENDS_UI_REQUEST_REAL_ID or "Real ID", "Real ID request label")
			V:AssertEqual(self:GetFriendLevelLabel(levels.Title), GetL().FRIENDS_UI_REQUEST_TITLE or "World of Warcraft", "Title request label")
			V:Assert(self:IsTitleInvite(levels.Title), "Title requests use the WoW card surface")
		end,
	})
	TestSuite:RegisterTest("ui", "FriendsUI_ModernAuxiliarySpacing", {
		action = function(V)
			if self:IsModernActive() then
				V:AssertEqual(self:GetAuxiliaryWindowOffset(), 68, "Modern auxiliary windows clear the side-tab rail")
			else
				V:AssertEqual(self:GetAuxiliaryWindowOffset(), 5, "Legacy auxiliary windows retain their original gap")
			end
		end,
	})
	TestSuite:RegisterTest("ui", "FriendsUI_ModernRaidChrome", {
		condition = function()
			local raid = BetterFriendsFrame and BetterFriendsFrame.RaidFrame
			return self:IsModernActive() and raid and raid.ControlPanel and raid.GroupsInset
		end,
		action = function(V)
			local raid = BetterFriendsFrame.RaidFrame
			local control = raid.ControlPanel
			self:ApplyModernRaidGeometry()
			V:Assert(control.EveryoneAssistIcon:IsShown(), "Modern Raid shows Blizzard's separate assist icon")
			V:Assert(control.RoleSummary:IsShown(), "Modern Raid uses BFL's compact combined role summary")
			V:Assert(not control.TankFrame:IsShown() and not control.HealerFrame:IsShown() and not control.DamagerFrame:IsShown(), "Modern Raid hides the expanded role counters")
			V:AssertEqual(control:GetHeight(), 32, "Modern Raid uses the compact control row")
			V:AssertEqual(control.RaidInfoButton:GetWidth(), 100, "Modern Raid Info uses Blizzard's button width")
			V:AssertEqual(control.RaidInfoButton:GetHeight(), 32, "Modern Raid Info uses Blizzard's button height")
			local helpPoint, helpRelativeTo, helpRelativePoint = BetterFriendsFrame.HelpButton:GetPoint(1)
			V:AssertEqual(helpPoint, "LEFT", "Modern Raid help follows Assist All horizontally")
			V:AssertEqual(helpRelativeTo, control.EveryoneAssistLabel, "Modern Raid help sits directly after the Assist All label")
			V:AssertEqual(helpRelativePoint, "RIGHT", "Modern Raid help uses the Assist All label's right edge")
			V:Assert(not raid.GroupsInset.Bg or not raid.GroupsInset.Bg:IsShown(), "Modern Raid has no shared group inset background")
			V:AssertEqual(raid.RaidToolsButton:GetHeight(), raid.ConvertToRaidButton:GetHeight(), "Modern Raid footer buttons share one baseline and height")
			V:Assert(math.abs(raid.RaidToolsButton:GetBottom() - raid.ConvertToRaidButton:GetBottom()) < 0.5, "Modern Raid footer buttons share one baseline")
			local RaidFrame = BFL:GetModule("RaidFrame")
			RaidFrame._lastLayoutWidth = nil
			RaidFrame._lastLayoutHeight = nil
			RaidFrame:UpdateGroupLayout()
			local firstGroup = raid.GroupsInset.GroupsContainer.Group1
			local firstSlot = firstGroup.Slot1
			local lastSlot = firstGroup.Slot5
			RaidFrame:InitializeMemberButtons()
			V:Assert(firstSlot._bflRankTooltip ~= nil, "Raid rank icon owns a Blizzard-style hover tooltip hitbox")
			V:Assert(firstSlot._bflMainTankTooltip ~= nil, "Main Tank icon owns a Blizzard-style hover tooltip hitbox")
			V:Assert(firstSlot._bflMainAssistTooltip ~= nil, "Main Assist icon owns a Blizzard-style hover tooltip hitbox")
			V:Assert(not firstSlot.Background:IsShown(), "Modern Raid member rows do not restore the legacy black background")
			if firstSlot.memberData and firstSlot.memberData._isMock then
				V:Assert(firstSlot.ClassColorTint:IsShown(), "Raid preview rows expose their class-color background tint")
				if firstSlot.memberData.rank == 2 and firstSlot.RankIcon.GetAtlas then
					V:AssertEqual(firstSlot.RankIcon:GetAtlas(), "friends-icon-raidLead", "Raid leader uses the 12.1 SocialUI atlas")
				elseif firstSlot.memberData.rank == 1 and firstSlot.RankIcon.GetAtlas then
					V:AssertEqual(firstSlot.RankIcon:GetAtlas(), "friends-icon-raidAssist", "Raid assistant uses the 12.1 SocialUI atlas")
				end
			else
				V:Assert(not firstSlot.ClassColorTint:IsShown(), "Live Modern Raid rows use the group card background")
			end
			local _, groupLabelSize = firstGroup.GroupTitle:GetFont()
			local _, nativeLabelSize = GameFontHighlight:GetFont()
			V:Assert(groupLabelSize and nativeLabelSize and math.abs(groupLabelSize - nativeLabelSize) < 0.01, "Modern Raid group labels use the native GameFontHighlight size")
			local groupBottom = firstGroup:GetBottom()
			local slotBottom = lastSlot:GetBottom()
			V:Assert(groupBottom and slotBottom and slotBottom >= groupBottom + 3, "Modern Raid keeps the fifth member slot inside the group card")
			local groupTop = firstGroup:GetTop()
			local firstSlotTop = firstSlot:GetTop()
			V:Assert(
				groupTop and firstSlotTop and math.abs((groupTop - firstSlotTop) - 20) < 0.5,
				"Modern Raid starts members 20 px below the group top"
			)
			local previousSection = self.selectedSection or "friends"
			self:ApplyModernSectionTopChrome("raid")
			V:Assert(self.root.TopFade:IsShown() and not self.root.TopDivider:IsShown(), "Modern Raid keeps the shared top fade without BFL's divider")
			self:ApplyModernSectionTopChrome(previousSection)
		end,
	})
	TestSuite:RegisterTest("ui", "FriendsUI_CustomTabIconColors", {
		condition = function()
			return self:IsModernActive() and SECTION_BY_ID.guild.tab and SECTION_BY_ID.who.tab
		end,
		action = function(V)
			for _, sectionID in ipairs({ "guild", "who" }) do
				local definition = SECTION_BY_ID[sectionID]
				local icon = definition.tab.Icon or definition.tab.icon
				ApplySectionIcon(icon, definition, true)
				local activeR, activeG, activeB = icon:GetVertexColor()
				V:Assert(not icon:IsDesaturated(), sectionID .. " icon preserves its source luminance")
				V:Assert(math.abs(activeR - CUSTOM_TAB_ICON_ACTIVE_COLOR[1]) < 0.01
					and math.abs(activeG - CUSTOM_TAB_ICON_ACTIVE_COLOR[2]) < 0.01
					and math.abs(activeB - CUSTOM_TAB_ICON_ACTIVE_COLOR[3]) < 0.01, sectionID .. " selected icon calibrates its source palette to Blizzard gold")
				ApplySectionIcon(icon, definition, false)
				local inactiveR, inactiveG, inactiveB = icon:GetVertexColor()
				V:Assert(math.abs(inactiveR - CUSTOM_TAB_ICON_INACTIVE_COLOR[1]) < 0.01
					and math.abs(inactiveG - CUSTOM_TAB_ICON_INACTIVE_COLOR[2]) < 0.01
					and math.abs(inactiveB - CUSTOM_TAB_ICON_INACTIVE_COLOR[3]) < 0.01, sectionID .. " inactive icon uses Blizzard's muted gold")
			end
			self:RefreshNavigation()
		end,
	})
	TestSuite:RegisterTest("ui", "FriendsUI_ModernLegacyDropdownGuard", {
		condition = function()
			return self:IsModernActive() and BetterFriendsFrame and BetterFriendsFrame.FriendsTabHeader
		end,
		action = function(V)
			local header = BetterFriendsFrame.FriendsTabHeader
			self:HideModernLegacyHeaderDropdowns(header)
			for _, field in ipairs(LEGACY_HEADER_DROPDOWN_FIELDS) do
				local dropdown = header[field]
				if dropdown then
					dropdown:Show()
					V:Assert(not dropdown:IsShown(), "Modern guard keeps legacy " .. field .. " hidden")
				end
			end
		end,
	})
	TestSuite:RegisterTest("ui", "FriendsUI_ContactChrome", {
		action = function(V)
			local friends = self:GetContactChrome("friends")
			local recent = self:GetContactChrome("recent_allies")
			local requests = self:GetContactChrome("friend_requests")
			local quickJoin = self:GetContactChrome("quick_join")
			V:Assert(friends.filterBar and friends.friendsFilter and friends.sort, "Friends keeps search, quick filters, and sorting")
			V:Assert(recent.filterBar and recent.recentFilter and not recent.sort, "Recent Allies gets its 12.1 search filters")
			V:AssertEqual(requests.action, "add_friend", "Friend Requests keeps the Add Friend action")
			V:AssertEqual(quickJoin.action, "quick_join", "Quick Join owns the shared action button")
			V:AssertEqual(self:GetContactChrome("guild").action, "guild_actions", "Guild uses the shared Modern action bar")
			V:AssertEqual(self:GetContactChrome("who").action, "who_actions", "Who uses the shared Modern action bar")
			V:Assert(self:GetContactChrome("raid").action == nil, "Raid does not inherit orphaned contact chrome")
		end,
	})
	TestSuite:RegisterTest("ui", "FriendsUI_ModernDirectoryChrome", {
		condition = function()
			return self:IsModernActive()
				and BetterFriendsFrame
				and BetterFriendsFrame.GuildFrame
				and BetterFriendsFrame.WhoFrame
		end,
		action = function(V)
			local previousSection = self.selectedSection or "friends"
			self:ApplyModernContentLayout("guild", true)
			local guild = BetterFriendsFrame.GuildFrame
			V:Assert(guild.SearchBox:IsShown(), "Guild exposes search in the shared 12.1 header row")
			V:AssertEqual(guild.SearchBox.searchIcon:GetWidth(), 10, "Guild keeps Blizzard's 10 px search glyph")
			V:AssertEqual(guild.SearchBox.searchIcon:GetHeight(), 10, "Guild search glyph keeps its aspect ratio")
			V:Assert(
				not guild.SearchBox.Backdrop or not guild.SearchBox.Backdrop:IsShown(),
				"Guild removes its legacy character-select search overlay"
			)
			V:Assert(guild.FilterDropdown:IsShown() and guild.SortDropdown:IsShown(), "Guild exposes Modern filter and sort controls")
			V:Assert(not guild.ActionsButton:IsShown(), "Guild replaces the embedded Legacy action button")
			V:Assert(not guild.ListInset.Bg or not guild.ListInset.Bg:IsShown(), "Guild removes the Legacy list inset background")

			self:ApplyModernContentLayout("who", true)
			local who = BetterFriendsFrame.WhoFrame
			V:Assert(who.EditBox:IsShown() and who.WhoButton:IsShown(), "Who moves search and refresh into the shared header row")
			V:AssertEqual(who.EditBox.searchIcon:GetWidth(), 10, "Who keeps Blizzard's 10 px search glyph")
			V:AssertEqual(who.EditBox.searchIcon:GetHeight(), 10, "Who search glyph keeps its aspect ratio")
			V:Assert(
				not who.EditBox.Backdrop or not who.EditBox.Backdrop:IsShown(),
				"Who removes its legacy character-select search overlay"
			)
			V:AssertEqual(who.NameHeader:GetHeight(), 24, "Who uses Blizzard's compact column-header height")
			V:Assert(not who.ListInset.Bg or not who.ListInset.Bg:IsShown(), "Who removes the Legacy list inset background")
			V:AssertEqual(who.AddFriendButton:GetHeight(), 30, "Who uses the shared action-row button height")
			local WhoFrame = BFL:GetModule("WhoFrame")
			local flyout = WhoFrame and WhoFrame.builderFlyout
			if flyout and who.ListInset then
				local leftMargin = flyout:GetLeft() - who.ListInset:GetLeft()
				local rightMargin = who.ListInset:GetRight() - flyout:GetRight()
				V:Assert(
					math.abs(leftMargin - rightMargin) < 0.5,
					"Who Search Builder is centered across the full list width"
				)
				V:Assert(
					not flyout.BFL_ModernLeftLine:IsShown() and not flyout.BFL_ModernRightLine:IsShown(),
					"Embedded Who Search Builder does not draw a popup border"
				)
				V:Assert(
					WhoFrame.builder.nameInput.searchIcon ~= nil
						and WhoFrame.builder.nameInput.Instructions:GetText()
							== (GetL().WHO_BUILDER_NAME_PLACEHOLDER or "Search for character name"),
					"Who Search Builder uses localized search fields"
				)
				local inputLeft = WhoFrame.builder.nameInput:GetLeft()
				local inputRight = WhoFrame.builder.nameInput:GetRight()
				local dropdownLeft = WhoFrame.builder.classDropdown:GetLeft()
				local dropdownRight = WhoFrame.builder.classDropdown:GetRight()
				V:Assert(
					inputLeft
						and dropdownLeft
						and math.abs((inputLeft - dropdownLeft) - 8) < 0.5
						and inputRight
						and dropdownRight
						and math.abs(inputRight - dropdownRight) < 0.5,
					"Who dropdown chrome compensates for SearchBoxTemplate's 8 px visual inset"
				)
			end
			self:ApplyModernContentLayout(previousSection, true)
		end,
	})
	TestSuite:RegisterTest("ui", "FriendsUI_RecentAlliesSearchContract", {
		condition = function()
			local RecentAllies = BFL:GetModule("RecentAllies")
			return RecentAllies and RecentAllies.BuildSearchInfo ~= nil
		end,
		action = function(V)
			local RecentAllies = BFL:GetModule("RecentAllies")
			local originalFilters = RecentAllies.selectedFilters
			local originalSearch = RecentAllies.searchText
			local ok, err = pcall(function()
				RecentAllies.selectedFilters = { online = true, roleplaying = true }
				RecentAllies.searchText = "ally"
				local info = RecentAllies:BuildSearchInfo()
				V:AssertEqual(info.searchText, "ally", "Recent Allies forwards the search text")
				V:Assert(info.isOnline and not info.isAFK and not info.isDND and not info.isOffline, "Recent Allies supplies every required status field")
				local rolePlaying = Enum and Enum.RecentAlliesFriendTag and Enum.RecentAlliesFriendTag.RolePlaying
				V:AssertEqual(#info.interests, rolePlaying ~= nil and 1 or 0, "Missing PTR enum values are not forwarded")
				if rolePlaying == nil then
					for _, option in ipairs(RecentAllies:GetAvailableInterestOptions()) do
						V:Assert(option.id ~= "roleplaying", "Missing PTR enum values are not offered in the menu")
					end
				end
			end)
			RecentAllies.selectedFilters = originalFilters
			RecentAllies.searchText = originalSearch
			if not ok then
				error(err)
			end
		end,
	})
	TestSuite:RegisterTest("ui", "FriendsUI_CapabilityGates", {
		action = function(V)
			local originalStyle = self.appliedStyle
			self.appliedStyle = STYLE_LEGACY
			local sections = self:BuildAvailableSectionIDs({
				friends = true,
				friend_requests = true,
				raid = true,
				who = true,
			})
			self.appliedStyle = originalStyle
			V:AssertEqual(table.concat(sections, ","), "friends,friend_requests,raid,who", "Unavailable systems must be omitted without changing order")
			V:AssertEqual(
				self:GetCapabilities().raid,
				BFL.IsRetail == true and not self:AreRaidGroupsDisabled(),
				"Raid availability follows the Retail DisableRaidGroups game rule"
			)
		end,
	})
	TestSuite:RegisterTest("ui", "FriendsUI_SocialTabMapping", {
		condition = function()
			return _G.SocialUITabType ~= nil
		end,
		action = function(V)
			V:AssertEqual(self:GetSectionForSocialTab(SocialUITabType.Friends), "friends", "Social Friends maps to BFL Friends")
			V:AssertEqual(self:GetSectionForSocialTab(SocialUITabType.FriendRequests), "friend_requests", "Social requests map to BFL requests")
			V:AssertEqual(self:GetSectionForSocialTab(SocialUITabType.RaidList), "raid", "Social Raid maps to BFL Raid")
		end,
	})
	TestSuite:RegisterTest("ui", "FriendsUI_BlizzardSocialTabFallback", {
		condition = function()
			return _G.SocialUITabType ~= nil
		end,
		action = function(V)
			V:AssertEqual(self:GetBlizzardSocialTab("quick_join"), SocialUITabType.QuickJoin, "Mapped sections retain their Blizzard tab")
			V:AssertEqual(self:GetBlizzardSocialTab("guild"), SocialUITabType.Friends, "Guild falls back to Blizzard Friends")
			V:AssertEqual(self:GetBlizzardSocialTab("who"), SocialUITabType.Friends, "Who falls back to Blizzard Friends")
		end,
	})
	TestSuite:RegisterTest("ui", "FriendsUI_BlizzardSocialUIBypass", {
		action = function(V)
			local originalControl = self.originalSocialUIControl
			local toggleCalls = 0
			local deferredTab
			local selectedTab
			self.originalSocialUIControl = {
				Toggle = function()
					toggleCalls = toggleCalls + 1
				end,
				OpenToTab = function()
					error("The redirected OpenToTab path must not be used")
				end,
			}
			local hiddenFrame = {
				IsShown = function()
					return false
				end,
				SetDeferredOpenTab = function(_, tabType)
					deferredTab = tabType
				end,
			}
			local visibleFrame = {
				IsShown = function()
					return true
				end,
				SelectTab = function(_, tabType)
					selectedTab = tabType
				end,
			}
			local ok, err = pcall(function()
				V:Assert(self:OpenLoadedBlizzardSocialUI(hiddenFrame, 101), "Hidden Blizzard SocialUI opens")
				V:AssertEqual(deferredTab, 101, "Hidden Blizzard SocialUI receives the deferred tab")
				V:AssertEqual(toggleCalls, 1, "Hidden Blizzard SocialUI uses Blizzard's original Toggle")
				V:Assert(self:OpenLoadedBlizzardSocialUI(visibleFrame, 202), "Visible Blizzard SocialUI updates in place")
				V:AssertEqual(selectedTab, 202, "Visible Blizzard SocialUI selects the requested tab")
				V:AssertEqual(toggleCalls, 1, "Visible Blizzard SocialUI is not toggled closed")
			end)
			self.originalSocialUIControl = originalControl
			if not ok then
				error(err)
			end
		end,
	})
	TestSuite:RegisterTest("ui", "FriendsUI_CountersAndGlow", {
		action = function(V)
			V:AssertEqual(self:GetSectionCount("friend_requests", 4, 7), 4, "Requests use the invite counter")
			V:AssertEqual(self:GetSectionCount("quick_join", 4, 7), 7, "Quick Join uses the group counter")
			V:AssertEqual(self:GetSectionCount("friends", 4, 7), 0, "Uncounted sections stay empty")
			V:Assert(self:ShouldStartRequestGlow(true, "friends"), "A new request glows outside the requests section")
			V:Assert(not self:ShouldStartRequestGlow(true, "friend_requests"), "The selected requests section does not glow")
			V:Assert(not self:ShouldStartRequestGlow(false, "friends"), "Refreshes without a new request do not start a glow")
			V:Assert(FRIENDS_RESTRICTED_SECTIONS.quick_join, "Quick Join follows the native friends restriction")
			V:Assert(FRIENDS_RESTRICTED_SECTIONS.friend_requests, "Friend Requests follow the native friends restriction")
			for _, sectionID in ipairs({ "quick_join", "friend_requests" }) do
				local tab = SECTION_BY_ID[sectionID] and SECTION_BY_ID[sectionID].tab
				if tab and tab.Count then
					local drawLayer = tab.Count:GetDrawLayer()
					V:AssertEqual(drawLayer, "ARTWORK", sectionID .. " badge matches Blizzard's draw layer")
					V:AssertEqual(tab.Count:GetWidth(), 32, sectionID .. " badge matches Blizzard's width")
					V:AssertEqual(tab.Count:GetHeight(), 18, sectionID .. " badge matches Blizzard's height")
				end
			end
		end,
	})
	TestSuite:RegisterTest("ui", "FriendsUI_LiveStyleSwitch", {
		condition = function()
			return BetterFriendsFrame ~= nil
				and self:IsSocialUIEnabled()
				and not (InCombatLockdown and InCombatLockdown())
		end,
		setup = function()
			self.testOriginalStyle = self:GetRequestedStyle()
			self.testOriginalSection = self:GetSelectedSection()
			self.testOriginalPositions = {}
			local db = GetDB()
			for _, key in ipairs({ LEGACY_LAYOUT_KEY, MODERN_LAYOUT_KEY }) do
				local position = db and db.mainFramePosition and db.mainFramePosition[key]
				self.testOriginalPositions[key] = position and {
					point = position.point,
					relativePoint = position.relativePoint,
					x = position.x,
					y = position.y,
				} or false
			end
		end,
		action = function(V)
			V:Assert(self:SetStyle(STYLE_LEGACY), "Legacy style switch should succeed")
			V:AssertEqual(self:GetAppliedStyle(), STYLE_LEGACY, "Legacy applies without reload")
			V:Assert(self:SetStyle(STYLE_MODERN), "Modern style switch should succeed")
			V:AssertEqual(self:GetAppliedStyle(), STYLE_MODERN, "Modern applies without reload")
		end,
		teardown = function()
			self:SetStyle(self.testOriginalStyle or self:GetDefaultRequestedStyle())
			self:SelectSection(self.testOriginalSection or "friends")
			local db = GetDB()
			if db and db.mainFramePosition then
				for key, position in pairs(self.testOriginalPositions or {}) do
					db.mainFramePosition[key] = position or nil
				end
			end
			self.testOriginalStyle = nil
			self.testOriginalSection = nil
			self.testOriginalPositions = nil
		end,
	})
	TestSuite:RegisterTest("ui", "FriendsUI_SocialRedirects", {
		condition = function()
			return self.redirectsInstalled and _G.SocialUIControl ~= nil
		end,
		action = function(V)
			V:Assert(_G.ToggleSocialUI ~= self.originalToggleSocialUI, "ToggleSocialUI is redirected")
			V:Assert(SocialUIControl.Toggle ~= self.originalSocialUIControl.Toggle, "SocialUI Toggle is redirected")
			V:Assert(SocialUIControl.OpenToTab ~= self.originalSocialUIControl.OpenToTab, "SocialUI OpenToTab is redirected")
			V:Assert(SocialUIControl.ToggleToTab ~= self.originalSocialUIControl.ToggleToTab, "SocialUI ToggleToTab is redirected")
		end,
	})
end

function FriendsUI:Initialize()
	if not BFL.IsRetail then
		self.appliedStyle = STYLE_LEGACY
		return
	end
	pcall(function()
		BFL:RegisterEventCallback("SOCIAL_UI_SYSTEM_STATUS_UPDATED", function()
			self:EnsureSocialUIRedirects()
			self:ApplyEffectiveStyle("social-ui-status")
		end, 10)
	end)
	BFL:RegisterEventCallback("PLAYER_REGEN_ENABLED", function()
		if self.pendingStyle then
			self:ApplyEffectiveStyle("combat-ended")
		end
	end, 10)
	BFL:RegisterEventCallback("BN_FRIEND_INVITE_LIST_INITIALIZED", function()
		self:RefreshRequests(false)
	end, 20)
	BFL:RegisterEventCallback("BN_FRIEND_INVITE_ADDED", function()
		self:RefreshRequests(true)
	end, 20)
	BFL:RegisterEventCallback("BN_FRIEND_INVITE_REMOVED", function()
		self:RefreshRequests(false)
	end, 20)
	BFL:RegisterEventCallback("BN_INFO_CHANGED", function()
		self:RefreshBattleTag()
	end, 20)
	BFL:RegisterEventCallback("GROUP_ROSTER_UPDATE", function()
		self:RefreshNavigation()
	end, 80)
	BFL:RegisterEventCallback("ADDON_LOADED", function(loadedAddOn)
		if loadedAddOn == "Blizzard_SocialUI" or loadedAddOn == "Blizzard_SocialUIShared" then
			self:InstallSocialUIRedirects()
		end
	end, 80)
	C_Timer.After(0, function()
		self:InstallTabHooks()
		self:EnsureSocialUIRedirects()
		if BetterFriendsFrame then
			BetterFriendsFrame:HookScript("OnShow", function()
				self:ApplyEffectiveStyle("show")
			end)
		end
		self:ApplyEffectiveStyle("initialize")
	end)
end

function FriendsUI:OnPlayerLogin()
	if BFL.IsRetail then
		self:ApplyEffectiveStyle("player-login")
		self:RegisterTests()
	end
end
