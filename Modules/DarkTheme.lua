-- Modules/DarkTheme.lua
-- Aurora-inspired dark theme coverage for BFL-owned UI

local ADDON_NAME, BFL = ...
local DarkTheme = BFL:RegisterModule("DarkTheme", {})

local WHO_COLUMN_HEADER_HEIGHT = 28
local WHO_COLUMN_HEADER_OVERLAP = -1
local WHO_LIST_INSET_PADDING = 4
local WHO_SCROLLBAR_RESERVE = 24
local WHO_SCROLLBAR_OFFSET_X = 1
local QUICK_JOIN_CONTENT_OFFSET_Y = -6
local QUICK_JOIN_REQUEST_BUTTON_OFFSET_X = 1
local QUICK_JOIN_REQUEST_BUTTON_OFFSET_Y = 1
local SETTINGS_SCROLLBAR_RESERVE = 30
local SETTINGS_SCROLLBAR_RIGHT_OFFSET_X = -3
local SETTINGS_SCROLLBAR_TRACK_TOP_OFFSET_Y = -22
local SETTINGS_SCROLLBAR_TRACK_BOTTOM_OFFSET_Y = 22
local SETTINGS_SCROLLBAR_BUTTON_TOP_OFFSET_Y = -4
local SETTINGS_SCROLLBAR_BUTTON_BOTTOM_OFFSET_Y = 4
local HELP_SCROLLBAR_TOP_OFFSET_Y = 3
local HELP_SCROLLBAR_BOTTOM_OFFSET_Y = 1

local function GetEngine()
	return BFL:GetModule("SkinEngine")
end

local function SafeCall(fn, ...)
	if not fn then
		return
	end
	pcall(fn, ...)
end

local function IsShown(frame)
	if not frame then
		return false
	end
	if frame.IsShown then
		return frame:IsShown() == true
	end
	return true
end

local function GetSelectedPanelTab(frame)
	if not frame then
		return nil
	end
	return (PanelTemplates_GetSelectedTab and PanelTemplates_GetSelectedTab(frame)) or frame.selectedTab
end

local function BuildSkinKey(...)
	local key = ""
	for i = 1, select("#", ...) do
		key = key .. ":" .. tostring(select(i, ...))
	end
	return key
end

local function SkinFrameByName(engine, name, variant)
	local frame = _G[name]
	if frame then
		engine:SkinFrame(frame, variant or "panel", { stripTextures = true, textureAlpha = 0.08 })
		engine:SkinTree(frame, 6)
	end
end

local function GetFrameName(frame)
	return (frame and frame.GetName and frame:GetName()) or ""
end

local function GetScrollFrameScrollBar(scrollFrame)
	if not scrollFrame then
		return nil
	end
	if scrollFrame.ScrollBar then
		return scrollFrame.ScrollBar
	end

	local frameName = GetFrameName(scrollFrame)
	if frameName ~= "" then
		return _G[frameName .. "ScrollBar"]
	end
end

local function FindScrollBarForFrame(scrollFrame)
	local scrollBar = GetScrollFrameScrollBar(scrollFrame)
	if scrollBar then
		return scrollBar
	end

	if not scrollFrame or not scrollFrame.GetChildren then
		return nil
	end

	for _, child in ipairs({ scrollFrame:GetChildren() }) do
		local childName = GetFrameName(child)
		local lowerName = childName ~= "" and string.lower(childName) or ""
		if lowerName:find("scrollbar") or child.ScrollUpButton or child.ScrollDownButton or (child.Back and child.Forward) then
			return child
		end
	end

	return nil
end

local function SkinBorderOnlyInset(engine, frame)
	if not engine or not frame then
		return
	end

	engine:SkinFrame(frame, "inset", { stripTextures = true, textureAlpha = 0 })
	if engine.colors and frame.BFL_DarkBackdrop then
		engine:StyleBackdrop(frame, engine.colors.borderNone, engine.colors.borderSoft)
	end
end

local function SkinField(engine, parent, key, variant)
	if parent and parent[key] then
		engine:SkinFrame(parent[key], variant or "panel", { stripTextures = true, textureAlpha = 0.10 })
		engine:SkinTree(parent[key], 5)
	end
end

local HideFrameChrome

local function HideFieldChrome(engine, parent, key)
	local frame = parent and parent[key]
	if not frame then
		return
	end

	HideFrameChrome(engine, frame, 2)
end

HideFrameChrome = function(engine, frame, textureDepth)
	if not engine or not frame then
		return
	end

	engine:DampenFrameTextures(frame, 0, textureDepth or 0)
	engine:DampenKnownArtwork(frame, 0)
	engine:DampenNineSlice(frame, 0)
	if frame.BFL_DarkBackdrop then
		frame.BFL_DarkBackdrop:Hide()
	end
end

local function SkinTabListScrollBar(engine, scrollBox, scrollBar, opts)
	if not engine or not scrollBox or not scrollBar then
		return
	end

	opts = opts or {}
	scrollBar.BFL_DarkWideScrollbar = true
	engine:SetFramePoints(scrollBar, {
		{ "TOPLEFT", scrollBox, "TOPRIGHT", opts.scrollTopX or 0, opts.scrollTopY or 0 },
		{ "BOTTOMLEFT", scrollBox, "BOTTOMRIGHT", opts.scrollBottomX or 0, opts.scrollBottomY or 0 },
	})
	engine:SkinScrollBar(scrollBar)
end

local function RefreshScrollBarSteppers(engine, scrollBar)
	if not engine or not scrollBar then
		return
	end

	engine:RefreshScrollBarSteppers(scrollBar)
	if C_Timer and C_Timer.After then
		C_Timer.After(0, function()
			local delayedEngine = GetEngine()
			if delayedEngine and delayedEngine:IsActive() then
				delayedEngine:RefreshScrollBarSteppers(scrollBar)
			end
		end)
		C_Timer.After(0.05, function()
			local delayedEngine = GetEngine()
			if delayedEngine and delayedEngine:IsActive() then
				delayedEngine:RefreshScrollBarSteppers(scrollBar)
			end
		end)
	end
end

local function SkinWhoListScrollBar(engine, who, scrollBar, opts)
	if not engine or not who or not who.ScrollBox or not scrollBar then
		return
	end

	opts = opts or {}
	local topFrame = who.ClassHeader or who.ScrollBox
	scrollBar.BFL_DarkWideScrollbar = true
	engine:SetFramePoints(scrollBar, {
		{ "TOPLEFT", topFrame, "TOPRIGHT", opts.scrollTopX or WHO_SCROLLBAR_OFFSET_X, opts.scrollTopY or 0 },
		{ "BOTTOMLEFT", who.ScrollBox, "BOTTOMRIGHT", opts.scrollBottomX or WHO_SCROLLBAR_OFFSET_X, opts.scrollBottomY or 0 },
	})
	engine:SkinScrollBar(scrollBar)
end

local function SkinTabListSurface(engine, container, scrollBox, scrollBar, opts)
	if not engine or not container or not scrollBox then
		return
	end

	HideFrameChrome(engine, container)
	engine:SkinFrame(scrollBox, "inset", { stripTextures = true, textureAlpha = 0 })
	SkinTabListScrollBar(engine, scrollBox, scrollBar, opts)
end

local function SkinButtonField(engine, parent, key)
	if parent and parent[key] then
		engine:SkinButton(parent[key])
	end
end

local function SkinColumnHeaderField(engine, parent, key)
	if parent and parent[key] then
		engine:SkinButton(parent[key], { insets = { left = 0, right = 0, top = 0, bottom = 0 }, keepFontColor = true })
	end
end

local function SkinNativeTextureButtonField(engine, parent, key)
	if parent and parent[key] and engine.SkinNativeTextureButton then
		engine:SkinNativeTextureButton(parent[key])
	end
end

local function SkinRaidAssistCheckButtonField(engine, parent, key)
	if parent and parent[key] then
		local checkButton = parent[key]
		checkButton.BFL_DarkNoCheckChrome = nil
		checkButton.BFL_DarkCompactCheckButton = nil
		checkButton.BFL_DarkCheckButtonInsets = { left = 1, right = 1, top = -1, bottom = -1 }
		checkButton.BFL_DarkCheckButtonNormalAlpha = 0
		checkButton.BFL_DarkCheckButtonPushedAlpha = 0
		checkButton.BFL_DarkCheckButtonDisabledAlpha = 0
		checkButton.BFL_DarkCheckButtonHighlightAlpha = 0.10
		engine:SetFrameSize(checkButton, 24, 24)
		engine:SkinCheckButton(checkButton)
	end
end

local function SkinTabField(engine, parent, key)
	if parent and parent[key] then
		engine:SkinTab(parent[key])
	end
end

local function SkinIconButtonField(engine, parent, key, opts)
	if parent and parent[key] then
		engine:SkinIconButton(parent[key], nil, opts)
	end
end

local function SetObjectShown(engine, owner, object, shown)
	if not object then
		return
	end
	if engine and engine.SetObjectShown then
		engine:SetObjectShown(owner, object, shown)
	elseif object.SetShown then
		object:SetShown(shown == true)
	elseif shown and object.Show then
		object:Show()
	elseif not shown and object.Hide then
		object:Hide()
	end
end

local function IsSimpleModeEnabled()
	local DB = BFL and BFL.GetModule and BFL:GetModule("DB")
	if DB and DB.Get then
		return DB:Get("simpleMode", false) == true
	end
	return BetterFriendlistDB and BetterFriendlistDB.simpleMode == true
end

local function RestorePortraitArtwork(engine, frame)
	if not frame then
		return
	end

	local portraitButton = frame.PortraitButton
	local showPortrait = not IsSimpleModeEnabled()
	if portraitButton then
		portraitButton.BFL_DarkInvisibleOverlayButton = true
		if engine then
			engine:RestoreFrame(portraitButton)
		end

		if showPortrait then
			if portraitButton.SetFrameLevel and frame.GetFrameLevel then
				portraitButton:SetFrameLevel((frame:GetFrameLevel() or 0) + 5)
			end
			SetObjectShown(engine, portraitButton, portraitButton, true)

			local icon = portraitButton.BFL_DarkPortraitIcon
			if not icon and portraitButton.CreateTexture then
				icon = portraitButton:CreateTexture(nil, "ARTWORK")
				portraitButton.BFL_DarkPortraitIcon = icon
				if engine and engine.RegisterOverlay then
					engine:RegisterOverlay(portraitButton, icon)
				end
			end

			if icon then
				icon:ClearAllPoints()
				icon:SetPoint("CENTER", portraitButton, "CENTER", 0, 0)
				icon:SetSize(60, 60)
				if icon.SetTexture then
					icon:SetTexture("Interface\\AddOns\\BetterFriendlist\\Textures\\PortraitIcon.blp")
				end
				if icon.SetTexCoord then
					icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
				end
				if icon.SetVertexColor then
					icon:SetVertexColor(1, 1, 1, 1)
				end
				if icon.SetAlpha then
					icon:SetAlpha(1)
				end
				if icon.SetDrawLayer then
					icon:SetDrawLayer("ARTWORK", 0)
				end

				local mask = portraitButton.BFL_DarkPortraitMask
				if not mask and portraitButton.CreateMaskTexture then
					mask = portraitButton:CreateMaskTexture()
					portraitButton.BFL_DarkPortraitMask = mask
					if engine and engine.RegisterOverlay then
						engine:RegisterOverlay(portraitButton, mask)
					end
				end
				if mask then
					mask:ClearAllPoints()
					mask:SetPoint("CENTER", portraitButton, "CENTER", 0, 0)
					mask:SetSize(60, 60)
					if mask.SetTexture then
						mask:SetTexture(
							"Interface\\CharacterFrame\\TempPortraitAlphaMask",
							"CLAMPTOBLACKADDITIVE",
							"CLAMPTOBLACKADDITIVE"
						)
					end
					if not portraitButton.BFL_DarkPortraitMaskApplied and icon.AddMaskTexture then
						icon:AddMaskTexture(mask)
						portraitButton.BFL_DarkPortraitMaskApplied = true
					end
					if mask.Show then
						mask:Show()
					end
				end
				icon:Show()
			end
		else
			if portraitButton.BFL_DarkPortraitIcon then
				portraitButton.BFL_DarkPortraitIcon:Hide()
			end
			if portraitButton.BFL_DarkPortraitMask then
				portraitButton.BFL_DarkPortraitMask:Hide()
			end
			SetObjectShown(engine, portraitButton, portraitButton, false)
		end
	end

	if frame.PortraitIcon then
		if portraitButton and frame.PortraitIcon ~= portraitButton.BFL_DarkPortraitIcon then
			SetObjectShown(engine, frame, frame.PortraitIcon, false)
		elseif showPortrait and engine then
			engine:SetTextureAlpha(frame, frame.PortraitIcon, 1)
		elseif showPortrait then
			frame.PortraitIcon:SetAlpha(1)
		else
			SetObjectShown(engine, frame, frame.PortraitIcon, false)
		end
	end
	if frame.PortraitMask and frame.PortraitMask.Show then
		if portraitButton and frame.PortraitMask ~= portraitButton.BFL_DarkPortraitMask then
			SetObjectShown(engine, frame, frame.PortraitMask, false)
		elseif showPortrait then
			if frame.PortraitMask.SetAlpha then
				frame.PortraitMask:SetAlpha(1)
			end
			frame.PortraitMask:Show()
		else
			SetObjectShown(engine, frame, frame.PortraitMask, false)
		end
	end
end

local function SkinDropdownField(engine, parent, key)
	if parent and parent[key] then
		engine:SkinDropdown(parent[key])
	end
end

local function SkinEditBoxField(engine, parent, key)
	if parent and parent[key] then
		engine:SkinEditBox(parent[key])
	end
end

local function SkinScrollBarField(engine, parent, key)
	if parent and parent[key] then
		parent[key].BFL_DarkWideScrollbar = true
		engine:SkinScrollBar(parent[key])
	end
end

local function RefreshFriendListRow(row)
	local engine = DarkTheme.refreshFriendsListRowsEngine
	if not engine or not row then
		return
	end
	engine:RefreshRow(row)
end

local function SkinSettingsNavigation(engine, frame)
	local list = frame and frame.CategoryList
	if not list or not list.GetChildren then
		return
	end

	for _, child in ipairs({ list:GetChildren() }) do
		if child and (child.selectedTex or child.id) then
			engine:SkinNavigationButton(child)
		end
	end
end

local function SkinFontString(engine, owner, fontString, r, g, b, a)
	if engine and fontString then
		engine:SetFontColor(owner or fontString, fontString, r, g, b, a or 1)
	end
end

local function SkinFontStringFields(engine, owner, fields, r, g, b, a)
	if not owner or not fields then
		return
	end

	for _, key in ipairs(fields) do
		SkinFontString(engine, owner, owner[key], r, g, b, a)
	end
end

local function SkinNoteCleanupRows(engine, rows)
	if not engine or type(rows) ~= "table" then
		return
	end

	for _, row in ipairs(rows) do
		if row then
			SkinFontStringFields(engine, row, {
				"accountName",
				"battleTag",
				"noteText",
				"backedUpNote",
				"currentNote",
			}, 0.92, 0.92, 0.92, 1)
			if row.cleanedInput then
				engine:SkinEditBox(row.cleanedInput)
			end
		end
	end
end

function DarkTheme:Initialize()
	if BFL:IsThemeActive("dark") then
		self:InstallHooks()
	end
end

function DarkTheme:OnPlayerLogin()
	if BFL:IsThemeActive("dark") then
		self:Apply("player-login")
	end
end

function DarkTheme:Apply(reason)
	local engine = GetEngine()
	if not engine then
		return
	end

	engine:Activate()
	self.applied = true
	self:InstallHooks()
	self:SkinKnownFrames(reason)
end

function DarkTheme:Remove(reason)
	local engine = GetEngine()
	if not engine then
		self.applied = nil
		return
	end

	if not self.applied and engine.active ~= true and not next(engine.registry or {}) then
		return
	end

	self.applied = nil
	self.mainTabsSkinPending = nil
	self.visibleMainContentRefreshPending = nil
	self.visibleMainContentRefreshBottomTab = nil
	self.visibleMainContentRefreshTopTab = nil
	engine:Deactivate()
	self:ClearMainFrameSkinKeys()
end

function DarkTheme:SkinKnownFrames(reason)
	local engine = GetEngine()
	if not engine or not engine:IsActive() then
		return
	end

	self:SkinMainFrame(engine)
	self:SkinSettingsFrame(engine)
	self:SkinAuxiliaryFrames(engine)

	if _G.BFL_Tooltip then
		engine:SkinTooltip(_G.BFL_Tooltip)
	end
end

function DarkTheme:SkinMainTabs(engine)
	engine = engine or GetEngine()
	if not engine or not engine:IsActive() then
		return
	end

	local frame = _G.BetterFriendsFrame
	if not frame then
		return
	end

	for i = 1, 4 do
		SkinTabField(engine, frame, "BottomTab" .. i)
	end

	local header = frame.FriendsTabHeader
	if header then
		for i = 1, 4 do
			SkinTabField(engine, header, "Tab" .. i)
		end
	end
end

function DarkTheme:SkinMainTabsDeferred()
	local engine = GetEngine()
	if not engine or not engine:IsActive() then
		self.mainTabsSkinPending = nil
		return
	end

	if self.mainTabsSkinPending then
		return
	end
	self.mainTabsSkinPending = true

	local function FlushMainTabs()
		self.mainTabsSkinPending = nil
		local delayedEngine = GetEngine()
		if delayedEngine and delayedEngine:IsActive() then
			self:SkinMainTabs(delayedEngine)
		end
	end

	if C_Timer and C_Timer.After then
		C_Timer.After(0, FlushMainTabs)
	else
		FlushMainTabs()
	end
end

local function GetMainFrameStaticSkinKey(frame)
	local header = frame and frame.FriendsTabHeader
	local bnetFrame = header and header.BattlenetFrame
	local broadcast = header and header.BroadcastFrame
	return BuildSkinKey(
		frame,
		frame and frame.Inset,
		frame and frame.ScrollFrame,
		frame and frame.MinimalScrollBar,
		frame and frame.AddFriendButton,
		frame and frame.SendMessageButton,
		frame and frame.RecruitmentButton,
		frame and frame.PortraitButton,
		frame and frame.StreamerModeButton,
		frame and frame.HelpButton,
		header,
		bnetFrame,
		broadcast,
		broadcast and broadcast.EditBox,
		broadcast and broadcast.UpdateButton,
		broadcast and broadcast.CancelButton,
		header and header.StatusDropdown,
		header and header.SearchBox,
		header and header.QuickFilterDropdown,
		header and header.PrimarySortDropdown,
		header and header.SecondarySortDropdown,
		bnetFrame and bnetFrame.ContactsMenuButton,
		bnetFrame and bnetFrame.SettingsButton
	)
end

function DarkTheme:ClearMainFrameSkinKeys()
	local frame = _G.BetterFriendsFrame
	if not frame then
		return
	end

	frame.BFL_DarkMainFrameStaticSkinKey = nil
	local who = frame.WhoFrame
	if who then
		who.BFL_DarkWhoStaticSkinKey = nil
		who.BFL_DarkWhoBuilderSkinKey = nil
	end
	if frame.QuickJoinFrame then
		frame.QuickJoinFrame.BFL_DarkQuickJoinSkinKey = nil
	end
	if frame.RecentAlliesFrame then
		frame.RecentAlliesFrame.BFL_DarkRecentAlliesSkinKey = nil
	end
	if frame.RecruitAFriendFrame then
		frame.RecruitAFriendFrame.BFL_DarkRAFSkinKey = nil
	end
	if frame.RaidFrame then
		frame.RaidFrame.BFL_DarkRaidSkinKey = nil
	end
	if frame.IgnoreListWindow then
		frame.IgnoreListWindow.BFL_DarkIgnoreListSkinKey = nil
	end
	if frame.GuildFrame then
		frame.GuildFrame.BFL_DarkGuildSkinKey = nil
	end
end

function DarkTheme:RefreshMainFrameControls(engine, frame)
	if not engine or not frame then
		return
	end

	self:LayoutMainListChrome(engine, frame)
	self:LayoutMainTitleButtons(engine, frame)
	self:SkinMainTabs(engine)

	for _, key in ipairs({
		"AddFriendButton",
		"SendMessageButton",
		"RecruitmentButton",
	}) do
		if frame[key] then
			engine:ApplyButtonState(frame[key])
		end
	end

	local header = frame.FriendsTabHeader
	if header then
		self:LayoutHeaderButtons(engine, header)
		local bnetFrame = header.BattlenetFrame
		if bnetFrame then
			if bnetFrame.ContactsMenuButton then
				engine:ApplyButtonState(bnetFrame.ContactsMenuButton)
			end
			if bnetFrame.SettingsButton then
				engine:ApplyButtonState(bnetFrame.SettingsButton)
			end
		end
	end
end

function DarkTheme:SkinVisibleMainContent(engine, frame)
	frame = frame or _G.BetterFriendsFrame
	if not engine or not engine:IsActive() or not frame then
		return
	end

	if IsShown(frame.ScrollFrame) or IsShown(frame.MinimalScrollBar) then
		self:SkinFriendsListRows(engine)
	end
	if IsShown(frame.RecentAlliesFrame) then
		self:SkinRecentAlliesFrame(engine)
	end
	if IsShown(frame.RecruitAFriendFrame) then
		self:SkinRAFFrame(engine)
	end
	if IsShown(frame.WhoFrame) then
		self:SkinWhoFrame(engine)
	end
	if IsShown(frame.RaidFrame) then
		self:SkinRaidFrame(engine)
	end
	if IsShown(frame.QuickJoinFrame) then
		self:SkinQuickJoin(engine)
	end
	if IsShown(frame.IgnoreListWindow) then
		self:SkinIgnoreList(engine)
	end
	if IsShown(frame.GuildFrame) then
		self:SkinGuildFrame(engine)
	end
end

function DarkTheme:SkinMainContentForTabs(engine, frame, bottomTabIndex, topTabIndex)
	frame = frame or _G.BetterFriendsFrame
	if not engine or not engine:IsActive() or not frame then
		return
	end

	bottomTabIndex = bottomTabIndex or GetSelectedPanelTab(frame) or 1

	if bottomTabIndex == 1 then
		topTabIndex = topTabIndex or GetSelectedPanelTab(frame.FriendsTabHeader) or 1
		if BFL.IsClassic and topTabIndex == 2 then
			self:SkinWhoFrame(engine)
		elseif BFL.IsClassic and topTabIndex == 4 then
			self:SkinRaidFrame(engine)
		elseif BFL.IsClassic or topTabIndex == 1 then
			self:SkinFriendsListRows(engine)
		elseif topTabIndex == 2 then
			self:SkinRecentAlliesFrame(engine)
		elseif topTabIndex == 3 then
			self:SkinRAFFrame(engine)
		elseif topTabIndex == 4 then
			self:SkinGuildFrame(engine)
		else
			self:SkinVisibleMainContent(engine, frame)
		end
	elseif bottomTabIndex == 2 then
		self:SkinWhoFrame(engine)
	elseif bottomTabIndex == 3 then
		if BFL.IsClassic then
			self:SkinGuildFrame(engine)
		else
			self:SkinRaidFrame(engine)
		end
	elseif bottomTabIndex == 4 then
		if BFL.IsClassic then
			self:SkinRaidFrame(engine)
		else
			self:SkinQuickJoin(engine)
		end
	else
		self:SkinVisibleMainContent(engine, frame)
	end
end

function DarkTheme:RefreshVisibleMainContentDeferred(bottomTabIndex, topTabIndex)
	local engine = GetEngine()
	if not engine or not engine:IsActive() then
		self.visibleMainContentRefreshPending = nil
		self.visibleMainContentRefreshBottomTab = nil
		self.visibleMainContentRefreshTopTab = nil
		return
	end

	if bottomTabIndex then
		self.visibleMainContentRefreshBottomTab = bottomTabIndex
	end
	if topTabIndex then
		self.visibleMainContentRefreshTopTab = topTabIndex
	end

	if self.visibleMainContentRefreshPending then
		return
	end
	self.visibleMainContentRefreshPending = true

	local function FlushVisibleMainContent()
		self.visibleMainContentRefreshPending = nil
		local pendingBottomTab = self.visibleMainContentRefreshBottomTab
		local pendingTopTab = self.visibleMainContentRefreshTopTab
		self.visibleMainContentRefreshBottomTab = nil
		self.visibleMainContentRefreshTopTab = nil
		local delayedEngine = GetEngine()
		local frame = _G.BetterFriendsFrame
		if delayedEngine and delayedEngine:IsActive() and frame then
			self:SkinMainContentForTabs(delayedEngine, frame, pendingBottomTab, pendingTopTab)
		end
	end

	if C_Timer and C_Timer.After then
		C_Timer.After(0, FlushVisibleMainContent)
	else
		FlushVisibleMainContent()
	end
end

function DarkTheme:LayoutMainListChrome(engine, frame)
	if not engine or not frame or not frame.ScrollFrame then
		return
	end

	local scrollBar = frame.MinimalScrollBar
	if scrollBar then
		scrollBar.BFL_DarkWideScrollbar = true
		engine:SetFrameSize(scrollBar, 22)
		engine:SetFramePoints(scrollBar, {
			{ "TOPLEFT", frame.ScrollFrame, "TOPRIGHT", 0, 2 },
			{ "BOTTOMLEFT", frame.ScrollFrame, "BOTTOMRIGHT", 0, 2 },
		})
	end

	if frame.AddFriendButton then
		engine:SetFramePoints(frame.AddFriendButton, {
			{ "TOPLEFT", frame.ScrollFrame, "BOTTOMLEFT", 0, 0 },
		})
	end

	if frame.SendMessageButton then
		engine:SetFramePoints(frame.SendMessageButton, {
			{ "TOPRIGHT", frame.ScrollFrame, "BOTTOMRIGHT", 0, 0 },
		})
	end
end

function DarkTheme:LayoutWhoListChrome(engine, who)
	if not engine or not who then
		return
	end

	HideFrameChrome(engine, who)
	HideFrameChrome(engine, who.ScrollBox)

	if who.ScrollBox and who.NameHeader and who.ListInset and who.ListInset.Totals then
		engine:SetFramePoints(who.ScrollBox, {
			{ "TOPLEFT", who.NameHeader, "BOTTOMLEFT", 0, -1 },
			{ "BOTTOMRIGHT", who.ListInset.Totals, "TOPRIGHT", -WHO_SCROLLBAR_RESERVE, 2 },
		})
	end

	SkinWhoListScrollBar(engine, who, who.ScrollBar)
	SkinWhoListScrollBar(engine, who, who.ClassicScrollBar, {
		scrollTopY = -18,
		scrollBottomY = 18,
	})
end

function DarkTheme:LayoutQuickJoinListChrome(engine, quickJoin)
	if not engine or not quickJoin or not quickJoin.ContentInset then
		return
	end

	local content = quickJoin.ContentInset
	local listSurface = content.ScrollBoxContainer or content.ScrollBox

	HideFrameChrome(engine, quickJoin)
	HideFrameChrome(engine, content)
	engine:SetFramePoints(content, {
		{ "TOPLEFT", quickJoin, "TOPLEFT", 0, 80 + QUICK_JOIN_CONTENT_OFFSET_Y },
		{ "BOTTOMRIGHT", quickJoin, "BOTTOMRIGHT", 0, QUICK_JOIN_CONTENT_OFFSET_Y },
	})
	if content.JoinQueueButton then
		local buttonAnchor = listSurface or content
		engine:SetFramePoints(content.JoinQueueButton, {
			{ "TOPRIGHT", buttonAnchor, "BOTTOMRIGHT", QUICK_JOIN_REQUEST_BUTTON_OFFSET_X, QUICK_JOIN_REQUEST_BUTTON_OFFSET_Y },
		})
	end

	if listSurface then
		engine:SkinFrame(listSurface, "inset", { stripTextures = true, textureAlpha = 0 })
	end
	HideFrameChrome(engine, content.ScrollBox)

	SkinTabListScrollBar(engine, listSurface or content, content.ScrollBar, {
		scrollTopY = 2,
		scrollBottomY = 2,
	})
	SkinTabListScrollBar(engine, listSurface or content, content.ClassicScrollBar, {
		scrollTopY = 2,
		scrollBottomY = 2,
	})
end

function DarkTheme:LayoutSettingsContentChrome(engine, frame)
	if not engine or not frame or not frame.MainInset or not frame.ContentScrollFrame then
		return
	end

	local scrollFrame = frame.ContentScrollFrame
	local scrollBar = GetScrollFrameScrollBar(scrollFrame)
	engine:SetFramePoints(scrollFrame, {
		{ "TOPLEFT", frame.MainInset, "TOPLEFT", 8, -5 },
		{ "BOTTOMRIGHT", frame.MainInset, "BOTTOMRIGHT", -SETTINGS_SCROLLBAR_RESERVE, 1 },
	})

	if scrollBar then
		scrollBar.BFL_DarkWideScrollbar = true
		engine:SetFramePoints(scrollBar, {
			{
				"TOPRIGHT",
				frame.MainInset,
				"TOPRIGHT",
				SETTINGS_SCROLLBAR_RIGHT_OFFSET_X,
				SETTINGS_SCROLLBAR_TRACK_TOP_OFFSET_Y,
			},
			{
				"BOTTOMRIGHT",
				frame.MainInset,
				"BOTTOMRIGHT",
				SETTINGS_SCROLLBAR_RIGHT_OFFSET_X,
				SETTINGS_SCROLLBAR_TRACK_BOTTOM_OFFSET_Y,
			},
		})
		engine:SkinScrollBar(scrollBar)
		engine:SetFramePoints(scrollBar, {
			{
				"TOPRIGHT",
				frame.MainInset,
				"TOPRIGHT",
				SETTINGS_SCROLLBAR_RIGHT_OFFSET_X,
				SETTINGS_SCROLLBAR_TRACK_TOP_OFFSET_Y,
			},
			{
				"BOTTOMRIGHT",
				frame.MainInset,
				"BOTTOMRIGHT",
				SETTINGS_SCROLLBAR_RIGHT_OFFSET_X,
				SETTINGS_SCROLLBAR_TRACK_BOTTOM_OFFSET_Y,
			},
		})
		local topButton = scrollBar.ScrollUpButton or scrollBar.Back
		local bottomButton = scrollBar.ScrollDownButton or scrollBar.Forward
		if topButton then
			engine:SetFramePoints(topButton, {
				{
					"TOPRIGHT",
					frame.MainInset,
					"TOPRIGHT",
					SETTINGS_SCROLLBAR_RIGHT_OFFSET_X,
					SETTINGS_SCROLLBAR_BUTTON_TOP_OFFSET_Y,
				},
			})
		end
		if bottomButton then
			engine:SetFramePoints(bottomButton, {
				{
					"BOTTOMRIGHT",
					frame.MainInset,
					"BOTTOMRIGHT",
					SETTINGS_SCROLLBAR_RIGHT_OFFSET_X,
					SETTINGS_SCROLLBAR_BUTTON_BOTTOM_OFFSET_Y,
				},
			})
		end
		RefreshScrollBarSteppers(engine, scrollBar)
	end
end

function DarkTheme:SkinHelpFrame(engine)
	local frame = _G.BetterFriendlistHelpFrame
	if not frame then
		return
	end

	engine:SkinFrame(frame, "popup", { stripTextures = true, textureAlpha = 0.08 })
	HideFieldChrome(engine, frame, "Inset")
	if frame.ScrollFrame then
		SkinBorderOnlyInset(engine, frame.ScrollFrame)
		local scrollBar = frame.ScrollBar or GetScrollFrameScrollBar(frame.ScrollFrame)
		if scrollBar then
			SkinTabListScrollBar(engine, frame.ScrollFrame, scrollBar, {
				scrollTopY = HELP_SCROLLBAR_TOP_OFFSET_Y,
				scrollBottomY = HELP_SCROLLBAR_BOTTOM_OFFSET_Y,
			})
			RefreshScrollBarSteppers(engine, scrollBar)
		end
	end
	engine:SkinTree(frame, 6)
	HideFieldChrome(engine, frame, "Inset")
	if frame.ScrollFrame then
		SkinBorderOnlyInset(engine, frame.ScrollFrame)
	end
end

function DarkTheme:LayoutWhoColumnHeaders(engine, who)
	if not engine or not who then
		return
	end

	if who.NameHeader and who.ListInset then
		engine:SetFrameSize(who.NameHeader, nil, WHO_COLUMN_HEADER_HEIGHT)
		engine:SetFramePoints(who.NameHeader, {
			{ "TOPLEFT", who.ListInset, "TOPLEFT", WHO_LIST_INSET_PADDING, -WHO_LIST_INSET_PADDING },
		})
	end

	if who.ColumnDropdown and who.NameHeader then
		engine:SetFrameSize(who.ColumnDropdown, nil, WHO_COLUMN_HEADER_HEIGHT)
		engine:SetFramePoints(who.ColumnDropdown, {
			{ "TOPLEFT", who.NameHeader, "TOPRIGHT", WHO_COLUMN_HEADER_OVERLAP, 0 },
		})
	end

	if who.LevelHeader and who.ColumnDropdown then
		engine:SetFrameSize(who.LevelHeader, nil, WHO_COLUMN_HEADER_HEIGHT)
		engine:SetFramePoints(who.LevelHeader, {
			{ "TOPLEFT", who.ColumnDropdown, "TOPRIGHT", WHO_COLUMN_HEADER_OVERLAP, 0 },
		})
	end

	if who.ClassHeader and who.LevelHeader then
		engine:SetFrameSize(who.ClassHeader, nil, WHO_COLUMN_HEADER_HEIGHT)
		engine:SetFramePoints(who.ClassHeader, {
			{ "TOPLEFT", who.LevelHeader, "TOPRIGHT", WHO_COLUMN_HEADER_OVERLAP, 0 },
		})
	end
end

function DarkTheme:LayoutMainTitleButtons(engine, frame)
	if not engine or not frame then
		return
	end

	local closeButton = frame.CloseButton
	local frameName = frame.GetName and frame:GetName()
	if not closeButton and frameName then
		closeButton = _G[frameName .. "CloseButton"]
	end

	local streamerButton = frame.StreamerModeButton
	if closeButton then
		engine:SetFrameSize(closeButton, 24, 24)
		engine:SetFramePoints(closeButton, {
			{ "TOPRIGHT", frame, "TOPRIGHT", -3, -2 },
		})
	end
	if streamerButton then
		engine:SetFrameSize(streamerButton, 24, 24)
		if closeButton then
			engine:SetFramePoints(streamerButton, {
				{ "RIGHT", closeButton, "LEFT", 0, 0 },
			})
		end
	end
end

function DarkTheme:LayoutHeaderButtons(engine, header)
	local bnetFrame = header and header.BattlenetFrame
	if not engine or not bnetFrame then
		return
	end

	local contactsButton = bnetFrame.ContactsMenuButton
	if contactsButton then
		engine:SetFrameSize(contactsButton, 28, 28)
		engine:SetFramePoints(contactsButton, {
			{ "LEFT", bnetFrame, "RIGHT", 4, 0 },
		})
	end

	local settingsButton = bnetFrame.SettingsButton
	if settingsButton then
		engine:SetFrameSize(settingsButton, 28, 28)
		if contactsButton then
			engine:SetFramePoints(settingsButton, {
				{ "LEFT", contactsButton, "RIGHT", 4, 0 },
			})
		end
	end
end

function DarkTheme:SkinMainFrame(engine)
	local frame = _G.BetterFriendsFrame
	if not frame then
		return
	end

	local staticSkinKey = GetMainFrameStaticSkinKey(frame)
	if frame.BFL_DarkMainFrameStaticSkinKey ~= staticSkinKey or not frame.BFL_DarkBackdrop then
		frame.BFL_DarkMainFrameStaticSkinKey = staticSkinKey
		RestorePortraitArtwork(engine, frame)
		engine:SkinFrame(frame, "main", { stripTextures = true, textureAlpha = 0.10 })
		engine:SkinTree(frame, 6)
		engine:StripButtonFrameArtwork(frame)
		RestorePortraitArtwork(engine, frame)

		HideFieldChrome(engine, frame, "Inset")
		SkinField(engine, frame, "ScrollFrame", "inset")
		SkinScrollBarField(engine, frame, "MinimalScrollBar")
		SkinButtonField(engine, frame, "AddFriendButton")
		SkinButtonField(engine, frame, "SendMessageButton")
		SkinButtonField(engine, frame, "RecruitmentButton")
		local streamerActive = BFL.StreamerMode and BFL.StreamerMode.IsActive and BFL.StreamerMode:IsActive()
		SkinIconButtonField(engine, frame, "StreamerModeButton", {
			texture = frame.StreamerModeButton and frame.StreamerModeButton.Icon,
			size = 18,
			color = streamerActive and { 0.64, 0.33, 1.0, 1 } or { 0.62, 0.62, 0.64, 0.82 },
			hoverColor = streamerActive and { 0.78, 0.52, 1.0, 1 } or { 0.86, 0.86, 0.88, 1 },
			downColor = streamerActive and { 0.54, 0.24, 0.88, 1 } or { 0.48, 0.48, 0.50, 1 },
		})
		SkinIconButtonField(engine, frame, "HelpButton", { texture = frame.HelpButton and frame.HelpButton.Icon, size = 18 })

		local header = frame.FriendsTabHeader
		if header then
			engine:SkinFrame(header, "panel")
			SkinField(engine, header, "BattlenetFrame", "panel")
			SkinField(engine, header, "BroadcastFrame", "popup")
			if header.BroadcastFrame then
				SkinEditBoxField(engine, header.BroadcastFrame, "EditBox")
				SkinButtonField(engine, header.BroadcastFrame, "UpdateButton")
				SkinButtonField(engine, header.BroadcastFrame, "CancelButton")
			end
			SkinDropdownField(engine, header, "StatusDropdown")
			SkinEditBoxField(engine, header, "SearchBox")
			SkinDropdownField(engine, header, "QuickFilterDropdown")
			SkinDropdownField(engine, header, "PrimarySortDropdown")
			SkinDropdownField(engine, header, "SecondarySortDropdown")
			SkinButtonField(engine, header.BattlenetFrame, "ContactsMenuButton")
			SkinButtonField(engine, header.BattlenetFrame, "SettingsButton")
		end
	end

	RestorePortraitArtwork(engine, frame)
	self:RefreshMainFrameControls(engine, frame)
	self:SkinVisibleMainContent(engine, frame)
end

function DarkTheme:SkinFriendsListRows(engine)
	local FriendsList = BFL:GetModule("FriendsList")
	if not FriendsList then
		return
	end

	if FriendsList.scrollBox and FriendsList.scrollBox.ForEachFrame then
		FriendsList.scrollBox:ForEachFrame(function(row)
			engine:SkinRow(row)
		end)
	end

	local pool = FriendsList.classicButtonPool
	if pool then
		for _, row in ipairs(pool) do
			engine:SkinRow(row)
		end
	end
	pool = FriendsList.classicHeaderPool
	if pool then
		for _, row in ipairs(pool) do
			engine:SkinRow(row)
		end
	end
	pool = FriendsList.classicInviteHeaderPool
	if pool then
		for _, row in ipairs(pool) do
			engine:SkinRow(row)
		end
	end
	pool = FriendsList.classicInviteButtonPool
	if pool then
		for _, row in ipairs(pool) do
			engine:SkinRow(row)
		end
	end
	pool = FriendsList.classicDividerPool
	if pool then
		for _, row in ipairs(pool) do
			engine:SkinRow(row)
		end
	end
end

function DarkTheme:RefreshFriendsListRows(engine)
	local FriendsList = BFL:GetModule("FriendsList")
	if not FriendsList then
		return
	end

	self.refreshFriendsListRowsEngine = engine
	if FriendsList.scrollBox and FriendsList.scrollBox.ForEachFrame then
		FriendsList.scrollBox:ForEachFrame(RefreshFriendListRow)
	end

	local pool = FriendsList.classicButtonPool
	if pool then
		for _, row in ipairs(pool) do
			RefreshFriendListRow(row)
		end
	end
	pool = FriendsList.classicHeaderPool
	if pool then
		for _, row in ipairs(pool) do
			RefreshFriendListRow(row)
		end
	end
	pool = FriendsList.classicInviteHeaderPool
	if pool then
		for _, row in ipairs(pool) do
			RefreshFriendListRow(row)
		end
	end
	pool = FriendsList.classicInviteButtonPool
	if pool then
		for _, row in ipairs(pool) do
			RefreshFriendListRow(row)
		end
	end
	pool = FriendsList.classicDividerPool
	if pool then
		for _, row in ipairs(pool) do
			RefreshFriendListRow(row)
		end
	end
	self.refreshFriendsListRowsEngine = nil
end

function DarkTheme:SkinRecentAlliesFrame(engine)
	local frame = _G.BetterFriendsFrame
	local recent = frame and frame.RecentAlliesFrame
	if not recent then
		return
	end

	local staticSkinKey = BuildSkinKey(recent, recent.ScrollBox, recent.ScrollBar, recent.ClassicScrollBar)
	if recent.BFL_DarkRecentAlliesSkinKey == staticSkinKey then
		return
	end
	recent.BFL_DarkRecentAlliesSkinKey = staticSkinKey

	SkinTabListSurface(engine, recent, recent.ScrollBox, recent.ScrollBar)
	engine:SkinTree(recent, 5)
end

function DarkTheme:SkinRAFFrame(engine)
	local frame = _G.BetterFriendsFrame
	local raf = frame and frame.RecruitAFriendFrame
	if not raf then
		return
	end

	local reward = raf.RewardClaiming
	local recruitList = raf.RecruitList
	local splash = raf.SplashFrame
	local staticSkinKey = BuildSkinKey(
		raf,
		reward,
		reward and reward.NextRewardInfoButton,
		reward and reward.NextRewardButton,
		reward and reward.ClaimOrViewRewardButton,
		recruitList,
		recruitList and recruitList.Header,
		recruitList and recruitList.ScrollBox,
		recruitList and recruitList.ScrollBar,
		recruitList and recruitList.ClassicScrollBar,
		splash,
		splash and splash.OKButton
	)
	if raf.BFL_DarkRAFSkinKey == staticSkinKey then
		if reward and reward.ClaimOrViewRewardButton then
			engine:ApplyButtonState(reward.ClaimOrViewRewardButton)
		end
		if splash and splash.OKButton then
			engine:ApplyButtonState(splash.OKButton)
		end
		return
	end
	raf.BFL_DarkRAFSkinKey = staticSkinKey

	HideFrameChrome(engine, raf)

	if reward then
		engine:SkinFrame(reward, "panel", { stripTextures = true, textureAlpha = 0 })
		SkinNativeTextureButtonField(engine, reward, "NextRewardInfoButton")
		SkinNativeTextureButtonField(engine, reward, "NextRewardButton")
		SkinButtonField(engine, reward, "ClaimOrViewRewardButton")
		engine:SkinTree(reward, 4)
	end

	if recruitList then
		HideFieldChrome(engine, recruitList, "Header")
		SkinTabListSurface(engine, recruitList, recruitList.ScrollBox, recruitList.ScrollBar)
		SkinTabListScrollBar(engine, recruitList.ScrollBox, recruitList.ClassicScrollBar)
		engine:SkinTree(recruitList, 5)
	end

	if splash then
		engine:SkinFrame(splash, "popup", { stripTextures = true, textureAlpha = 0 })
		SkinButtonField(engine, splash, "OKButton")
		engine:SkinTree(splash, 4)
	end
end

function DarkTheme:SkinWhoFrame(engine)
	local frame = _G.BetterFriendsFrame
	local who = frame and frame.WhoFrame
	if not who then
		return
	end

	local staticSkinKey = tostring(who.ScrollBox)
		.. ":"
		.. tostring(who.ScrollBar)
		.. ":"
		.. tostring(who.ClassicScrollBar)
		.. ":"
		.. tostring(who.ListInset)
		.. ":"
		.. tostring(who.EditBox)
		.. ":"
		.. tostring(who.ColumnDropdown)
		.. ":"
		.. tostring(who.NameHeader)
		.. ":"
		.. tostring(who.LevelHeader)
		.. ":"
		.. tostring(who.ClassHeader)
		.. ":"
		.. tostring(who.WhoButton)
		.. ":"
		.. tostring(who.AddFriendButton)
		.. ":"
		.. tostring(who.GroupInviteButton)
	if who.BFL_DarkWhoStaticSkinKey ~= staticSkinKey then
		who.BFL_DarkWhoStaticSkinKey = staticSkinKey
		self:LayoutWhoColumnHeaders(engine, who)
		self:LayoutWhoListChrome(engine, who)
		SkinField(engine, who, "ListInset", "inset")
		SkinEditBoxField(engine, who, "EditBox")
		SkinDropdownField(engine, who, "ColumnDropdown")
		SkinColumnHeaderField(engine, who, "NameHeader")
		SkinColumnHeaderField(engine, who, "LevelHeader")
		SkinColumnHeaderField(engine, who, "ClassHeader")
		SkinButtonField(engine, who, "WhoButton")
		SkinButtonField(engine, who, "AddFriendButton")
		SkinButtonField(engine, who, "GroupInviteButton")
	else
		if who.WhoButton then
			engine:ApplyButtonState(who.WhoButton)
		end
		if who.AddFriendButton then
			engine:ApplyButtonState(who.AddFriendButton)
		end
		if who.GroupInviteButton then
			engine:ApplyButtonState(who.GroupInviteButton)
		end
	end

	local WhoFrame = BFL:GetModule("WhoFrame")
	if WhoFrame then
		local builderContainer = WhoFrame.builderDockedContainer or WhoFrame.builderContainer or _G.BetterFriendlistSearchBuilderFrame
		local builderSkinKey = tostring(WhoFrame.builderToggle)
			.. ":"
			.. tostring(WhoFrame.builderDockBtn)
			.. ":"
			.. tostring(WhoFrame.builderFlyout)
			.. ":"
			.. tostring(WhoFrame.builderDocked)
			.. ":"
			.. tostring(builderContainer)
			.. ":"
			.. tostring(WhoFrame.builderCloseBtn)
			.. ":"
			.. tostring(_G.BetterFriendlistSearchBuilderFrame)
		if who.BFL_DarkWhoBuilderSkinKey ~= builderSkinKey then
			who.BFL_DarkWhoBuilderSkinKey = builderSkinKey
			if WhoFrame.builderToggle then
				WhoFrame.builderToggle.BFL_DarkNoButtonChrome = true
				engine:RestoreFrame(WhoFrame.builderToggle)
			end
			if WhoFrame.builderDockBtn then
				WhoFrame.builderDockBtn.BFL_DarkNoButtonChrome = true
				engine:RestoreFrame(WhoFrame.builderDockBtn)
			end
			if WhoFrame.builderFlyout then
				if WhoFrame.builderDocked then
					HideFrameChrome(engine, WhoFrame.builderFlyout)
				else
					engine:SkinFrame(WhoFrame.builderFlyout, "popup", { stripTextures = true, textureAlpha = 0 })
				end
				engine:SkinTree(WhoFrame.builderFlyout, 6)
				if WhoFrame.builderCloseBtn then
					WhoFrame.builderCloseBtn.BFL_DarkNoButtonChrome = nil
					engine:SkinCloseButton(WhoFrame.builderCloseBtn)
				end
			end

			if builderContainer then
				engine:SkinFrame(builderContainer, "popup", { stripTextures = true, textureAlpha = 0 })
				HideFieldChrome(engine, builderContainer, "Inset")
				HideFieldChrome(engine, builderContainer, "InsetRight")
				engine:SkinTree(builderContainer, 6)
				if builderContainer.CloseButton then
					builderContainer.CloseButton.BFL_DarkNoButtonChrome = true
					engine:RestoreFrame(builderContainer.CloseButton)
				end
			end
			if WhoFrame.builderDocked and WhoFrame.builderFlyout then
				HideFrameChrome(engine, WhoFrame.builderFlyout)
			end

			local searchBuilderFrame = _G.BetterFriendlistSearchBuilderFrame
			if searchBuilderFrame then
				engine:SkinFrame(searchBuilderFrame, "popup", { stripTextures = true, textureAlpha = 0 })
			end
		end

		if WhoFrame.classicWhoButtonPool then
			for _, row in ipairs(WhoFrame.classicWhoButtonPool) do
				engine:SkinRow(row)
			end
		end
	end
end

function DarkTheme:SkinRaidFrame(engine)
	local frame = _G.BetterFriendsFrame
	local raid = frame and frame.RaidFrame
	if not raid then
		return
	end

	local control = raid.ControlPanel
	local staticSkinKey = BuildSkinKey(
		raid,
		control,
		control and control.RaidInfoButton,
		control and control.EveryoneAssistCheckbox,
		raid.GroupsInset,
		raid.ConvertToRaidButton,
		raid.RaidToolsButton,
		raid.CombatIcon
	)
	if raid.BFL_DarkRaidSkinKey == staticSkinKey then
		for _, button in ipairs({
			control and control.RaidInfoButton,
			raid.ConvertToRaidButton,
			raid.RaidToolsButton,
			raid.CombatIcon,
		}) do
			if button then
				engine:ApplyButtonState(button)
			end
		end
		return
	end
	raid.BFL_DarkRaidSkinKey = staticSkinKey

	HideFrameChrome(engine, raid)
	HideFieldChrome(engine, raid, "ControlPanel")
	SkinButtonField(engine, raid.ControlPanel, "RaidInfoButton")
	SkinField(engine, raid, "GroupsInset", "inset")
	SkinButtonField(engine, raid, "ConvertToRaidButton")
	SkinButtonField(engine, raid, "RaidToolsButton")
	SkinButtonField(engine, raid, "CombatIcon")
	engine:SkinTree(raid, 5)
	HideFrameChrome(engine, raid)
	HideFieldChrome(engine, raid, "ControlPanel")
	SkinField(engine, raid, "GroupsInset", "inset")
	SkinRaidAssistCheckButtonField(engine, raid.ControlPanel, "EveryoneAssistCheckbox")
end

function DarkTheme:SkinQuickJoin(engine)
	local frame = _G.BetterFriendsFrame
	local quickJoin = frame and frame.QuickJoinFrame
	if not quickJoin then
		return
	end

	local content = quickJoin.ContentInset
	if content then
		local listSurface = content.ScrollBoxContainer or content.ScrollBox
		local skinKey = tostring(content)
			.. ":"
			.. tostring(listSurface)
			.. ":"
			.. tostring(content.ScrollBar)
			.. ":"
			.. tostring(content.ClassicScrollBar)
			.. ":"
			.. tostring(content.JoinQueueButton)
		if quickJoin.BFL_DarkQuickJoinSkinKey ~= skinKey then
			quickJoin.BFL_DarkQuickJoinSkinKey = skinKey
			HideFrameChrome(engine, quickJoin)
			self:LayoutQuickJoinListChrome(engine, quickJoin)
			SkinButtonField(engine, content, "JoinQueueButton")
		elseif content.JoinQueueButton then
			engine:ApplyButtonState(content.JoinQueueButton)
		end
	else
		HideFrameChrome(engine, quickJoin)
	end
end

function DarkTheme:SkinIgnoreList(engine)
	local frame = _G.BetterFriendsFrame
	local ignore = frame and frame.IgnoreListWindow
	if not ignore then
		return
	end

	local staticSkinKey = BuildSkinKey(
		ignore,
		ignore.UnignorePlayerButton,
		ignore.GlobalIgnoreListButton,
		ignore.EnhanceQoLIgnoreButton,
		ignore.ScrollBox,
		ignore.ScrollBar,
		ignore.ClassicScrollBar,
		ignore.Inset and ignore.Inset.ClassicScrollBar
	)
	if ignore.BFL_DarkIgnoreListSkinKey == staticSkinKey then
		for _, button in ipairs({
			ignore.UnignorePlayerButton,
			ignore.GlobalIgnoreListButton,
			ignore.EnhanceQoLIgnoreButton,
		}) do
			if button then
				engine:ApplyButtonState(button)
			end
		end
		return
	end
	ignore.BFL_DarkIgnoreListSkinKey = staticSkinKey

	engine:SkinFrame(ignore, "popup", { stripTextures = true, textureAlpha = 0.08 })
	SkinButtonField(engine, ignore, "UnignorePlayerButton")
	SkinButtonField(engine, ignore, "GlobalIgnoreListButton")
	SkinButtonField(engine, ignore, "EnhanceQoLIgnoreButton")
	SkinField(engine, ignore, "ScrollBox", "inset")
	SkinScrollBarField(engine, ignore, "ScrollBar")
	SkinScrollBarField(engine, ignore, "ClassicScrollBar")
	SkinScrollBarField(engine, ignore.Inset, "ClassicScrollBar")
	engine:SkinTree(ignore, 5)
end

function DarkTheme:SkinGuildFrame(engine)
	local frame = _G.BetterFriendsFrame
	local guild = frame and frame.GuildFrame
	if not guild then
		return
	end

	local staticSkinKey = BuildSkinKey(
		guild,
		guild.SearchBox,
		guild.ListInset,
		guild.ScrollBox,
		guild.ScrollBar,
		guild.NameHeader,
		guild.RankHeader,
		guild.LevelHeader,
		guild.ZoneHeader,
		guild.ILvlHeader,
		guild.FilterAll,
		guild.FilterOnline,
		guild.FilterOffline,
		guild.OpenBlizzardGuildButton,
		guild.RefreshButton,
		guild.InvitePlayerButton
	)
	if guild.BFL_DarkGuildSkinKey == staticSkinKey then
		for _, key in ipairs({
			"NameHeader",
			"RankHeader",
			"LevelHeader",
			"ZoneHeader",
			"ILvlHeader",
			"FilterAll",
			"FilterOnline",
			"FilterOffline",
			"OpenBlizzardGuildButton",
			"RefreshButton",
			"InvitePlayerButton",
		}) do
			if guild[key] then
				engine:ApplyButtonState(guild[key])
			end
		end
		return
	end
	guild.BFL_DarkGuildSkinKey = staticSkinKey

	engine:SkinFrame(guild, "panel")
	SkinEditBoxField(engine, guild, "SearchBox")
	SkinField(engine, guild, "ListInset", "inset")
	SkinField(engine, guild, "ScrollBox", "inset")
	SkinScrollBarField(engine, guild, "ScrollBar")
	for _, key in ipairs({
		"NameHeader",
		"RankHeader",
		"LevelHeader",
		"ZoneHeader",
		"ILvlHeader",
		"FilterAll",
		"FilterOnline",
		"FilterOffline",
		"OpenBlizzardGuildButton",
		"RefreshButton",
		"InvitePlayerButton",
	}) do
		SkinButtonField(engine, guild, key)
	end
	engine:SkinTree(guild, 5)

	SkinFrameByName(engine, "BFL_GuildMemberInfoPanel", "popup")
end

function DarkTheme:SkinSettingsFrame(engine)
	local frame = _G.BetterFriendlistSettingsFrame
	if not frame then
		return
	end

	engine:SkinFrame(frame, "main", { stripTextures = true, textureAlpha = 0.08 })
	SkinField(engine, frame, "MainInset", "inset")
	SkinField(engine, frame, "CategoryList", "panel")
	SkinField(engine, frame, "ButtonSeparator", "panel")
	self:LayoutSettingsContentChrome(engine, frame)
	engine:SkinTree(frame, 7)
	self:LayoutSettingsContentChrome(engine, frame)
	SkinSettingsNavigation(engine, frame)
end

function DarkTheme:SkinNoteCleanupFrame(engine, frame)
	if not engine or not engine:IsActive() or not frame then
		return
	end

	local colors = engine.colors or {}

	engine:SkinFrame(frame, "popup", { stripTextures = true, textureAlpha = 0.04 })
	engine:StripButtonFrameArtwork(frame)
	HideFieldChrome(engine, frame, "Inset")

	SkinFontString(engine, frame, frame.descText, 0.92, 0.92, 0.92, 1)
	SkinFontString(engine, frame, frame.countLabel, 0.92, 0.92, 0.92, 1)

	if frame.searchBox then
		engine:SkinEditBox(frame.searchBox)
		SkinFontString(engine, frame.searchBox, frame.searchBox.Instructions, 0.52, 0.52, 0.54, 1)
	end

	for _, key in ipairs({
		"applyButton",
		"viewBackupButton",
		"backupButton",
		"restoreButton",
	}) do
		SkinButtonField(engine, frame, key)
	end

	if frame.headerBar then
		engine:SkinFrame(frame.headerBar, "panel", {
			insets = { left = 0, right = 0, top = 0, bottom = 0 },
		})
		if frame.headerBar.bg then
			engine:SetTextureAlpha(frame.headerBar, frame.headerBar.bg, 0)
		end
		if colors.controlDown and colors.borderNone then
			engine:StyleBackdrop(frame.headerBar, colors.controlDown, colors.borderNone)
		end
	end

	if frame.headerLabels then
		for _, label in ipairs(frame.headerLabels) do
			SkinFontString(engine, frame.headerBar or frame, label, 1, 0.82, 0, 1)
		end
	end

	if frame.scrollFrame then
		SkinBorderOnlyInset(engine, frame.scrollFrame)
		local scrollBar = FindScrollBarForFrame(frame.scrollFrame)
		if scrollBar then
			scrollBar.BFL_DarkWideScrollbar = true
			SkinTabListScrollBar(engine, frame.scrollFrame, scrollBar, {
				scrollTopX = 1,
				scrollBottomX = 1,
			})
			RefreshScrollBarSteppers(engine, scrollBar)
		end
	end

	engine:SkinTree(frame, 7)
	HideFieldChrome(engine, frame, "Inset")
	SkinNoteCleanupRows(engine, frame.rowFrames)

	for _, key in ipairs({
		"applyButton",
		"viewBackupButton",
		"backupButton",
		"restoreButton",
	}) do
		SkinButtonField(engine, frame, key)
	end
end

function DarkTheme:SkinAuxiliaryFrames(engine)
	for _, frameInfo in ipairs({
		{ "BetterFriendlistChangelogFrame", "popup" },
		{ "BetterFriendlistExportFrame", "popup" },
		{ "BetterFriendlistImportFrame", "popup" },
		{ "BetterFriendlistFilterSortEditorFrame", "popup" },
		{ "BetterFriendlistRaidToolsFrame", "popup" },
		{ "BetterSavedInstancesFrame", "popup" },
		{ "BFL_GuildMemberInfoPanel", "popup" },
	}) do
		SkinFrameByName(engine, frameInfo[1], frameInfo[2])
	end
	self:SkinNoteCleanupFrame(engine, _G.BetterFriendlistNoteCleanupWizard)
	self:SkinNoteCleanupFrame(engine, _G.BetterFriendlistNoteBackupViewer)
	self:SkinHelpFrame(engine)
end

function DarkTheme:SkinCreatedFrame(frame)
	local engine = GetEngine()
	if not engine or not engine:IsActive() or not frame then
		return
	end

	local frameName = GetFrameName(frame)
	if frameName == "BetterFriendlistNoteCleanupWizard" or frameName == "BetterFriendlistNoteBackupViewer" then
		self:SkinNoteCleanupFrame(engine, frame)
		return
	end

	engine:SkinFrame(frame, "popup", { stripTextures = true, textureAlpha = 0.08 })
	engine:SkinTree(frame, 7)
end

function DarkTheme:SkinSettingsFrameDeferred()
	local engine = GetEngine()
	if engine and engine:IsActive() then
		self:SkinSettingsFrame(engine)
	end

	if C_Timer and C_Timer.After then
		if self.settingsSkinPending then
			return
		end
		self.settingsSkinPending = true
		C_Timer.After(0, function()
			self.settingsSkinPending = nil
			local delayedEngine = GetEngine()
			if delayedEngine and delayedEngine:IsActive() then
				self:SkinSettingsFrame(delayedEngine)
			end
		end)
	end
end

function DarkTheme:WrapModuleMethod(moduleName, methodName, after)
	local module = BFL:GetModule(moduleName)
	if not module or type(module[methodName]) ~= "function" then
		return
	end

	local hookKey = "BFL_DarkHook_" .. methodName
	if module[hookKey] then
		return
	end
	module[hookKey] = true

	local original = module[methodName]
	module[methodName] = function(moduleSelf, ...)
		local r1, r2, r3, r4 = original(moduleSelf, ...)
		local engine = GetEngine()
		if engine and engine:IsActive() then
			after(moduleSelf, r1, r2, r3, r4, ...)
		end
		return r1, r2, r3, r4
	end
end

function DarkTheme:RefreshUpdatedFriendRow(button)
	local engine = GetEngine()
	if engine then
		self.friendListRowUpdateCounter = (self.friendListRowUpdateCounter or 0) + 1
		engine:RefreshRow(button)
	end
end

function DarkTheme:WrapFriendsListRenderMethod(methodName)
	local module = BFL:GetModule("FriendsList")
	if not module or type(module[methodName]) ~= "function" then
		return
	end

	local hookKey = "BFL_DarkHook_" .. methodName
	if module[hookKey] then
		return
	end
	module[hookKey] = true

	local original = module[methodName]
	module[methodName] = function(moduleSelf, ...)
		local rowUpdateCounter = self.friendListRowUpdateCounter or 0
		local r1, r2, r3, r4 = original(moduleSelf, ...)
		local engine = GetEngine()
		if engine and engine:IsActive() and (self.friendListRowUpdateCounter or 0) == rowUpdateCounter then
			self:RefreshFriendsListRows(engine)
		end
		return r1, r2, r3, r4
	end
end

function DarkTheme:InstallNoteCleanupWizardHooks()
	local wizard = BFL.NoteCleanupWizard
	if not wizard or wizard.BFL_DarkHooksInstalled then
		return
	end

	wizard.BFL_DarkHooksInstalled = true

	local function Wrap(methodName, after)
		local original = wizard[methodName]
		if type(original) ~= "function" then
			return
		end

		wizard[methodName] = function(wizardSelf, ...)
			local r1, r2, r3, r4 = original(wizardSelf, ...)
			if BFL:IsThemeActive("dark") then
				SafeCall(after, r1, r2, r3, r4)
			end
			return r1, r2, r3, r4
		end
	end

	Wrap("CreateWizardFrame", function(frame)
		local engine = GetEngine()
		self:SkinNoteCleanupFrame(engine, frame or _G.BetterFriendlistNoteCleanupWizard)
	end)
	Wrap("CreateBackupViewerFrame", function(frame)
		local engine = GetEngine()
		self:SkinNoteCleanupFrame(engine, frame or _G.BetterFriendlistNoteBackupViewer)
	end)
	Wrap("RefreshRows", function()
		local engine = GetEngine()
		local frame = _G.BetterFriendlistNoteCleanupWizard
		if engine and engine:IsActive() and frame then
			SkinNoteCleanupRows(engine, frame.rowFrames)
		end
	end)
	Wrap("RefreshBackupRows", function()
		local engine = GetEngine()
		local frame = _G.BetterFriendlistNoteBackupViewer
		if engine and engine:IsActive() and frame then
			SkinNoteCleanupRows(engine, frame.rowFrames)
		end
	end)
	Wrap("Show", function()
		local engine = GetEngine()
		self:SkinNoteCleanupFrame(engine, _G.BetterFriendlistNoteCleanupWizard)
	end)
	Wrap("ShowBackupViewer", function()
		local engine = GetEngine()
		self:SkinNoteCleanupFrame(engine, _G.BetterFriendlistNoteBackupViewer)
	end)
end

function DarkTheme:InstallSettingsComponentHooks()
	local Components = BFL.SettingsComponents
	if not Components or Components.BFL_DarkComponentsHooked then
		return
	end

	Components.BFL_DarkComponentsHooked = true
	local engineGetter = GetEngine

	local function Wrap(methodName)
		local original = Components[methodName]
		if type(original) ~= "function" then
			return
		end
		Components[methodName] = function(componentSelf, ...)
			local holder = original(componentSelf, ...)
			local engine = engineGetter()
			if engine and engine:IsActive() then
				engine:SkinControl(holder)
				if C_Timer and C_Timer.After then
					C_Timer.After(0, function()
						local delayedEngine = engineGetter()
						if delayedEngine and delayedEngine:IsActive() then
							delayedEngine:SkinControl(holder)
						end
					end)
				end
			end
			return holder
		end
	end

	Wrap("CreateHeader")
	Wrap("CreateCheckbox")
	Wrap("CreateDoubleCheckbox")
	Wrap("CreateCheckboxDropdown")
	Wrap("CreateDropdown")
	Wrap("CreateColorPicker")
	Wrap("CreateSlider")
	Wrap("CreateSliderWithColorPicker")
	Wrap("CreateInput")
	Wrap("CreateButton")
	Wrap("CreateButtonRow")
	Wrap("CreateListItem")
end

function DarkTheme:InstallHooks()
	if self.hooksInstalled then
		self:InstallSettingsComponentHooks()
		self:InstallNoteCleanupWizardHooks()
		self:InstallGlobalTabHooks()
		return
	end
	self.hooksInstalled = true

	self:InstallSettingsComponentHooks()
	self:InstallNoteCleanupWizardHooks()
	self:InstallGlobalTabHooks()

	if not self.portraitVisibilityHooked and hooksecurefunc and type(BFL.UpdatePortraitVisibility) == "function" then
		self.portraitVisibilityHooked = true
		hooksecurefunc(BFL, "UpdatePortraitVisibility", function()
			local engine = GetEngine()
			local frame = _G.BetterFriendsFrame
			if engine and frame and engine:IsActive() then
				engine:StripButtonFrameArtwork(frame)
			end
		end)
	end

	self:WrapModuleMethod("FriendsList", "UpdateFriendButton", function(_, _, _, _, _, button)
		self:RefreshUpdatedFriendRow(button)
	end)
	self:WrapModuleMethod("FriendsList", "UpdateGroupHeaderButton", function(_, _, _, _, _, button)
		self:RefreshUpdatedFriendRow(button)
	end)
	self:WrapModuleMethod("FriendsList", "UpdateInviteHeaderButton", function(_, _, _, _, _, button)
		self:RefreshUpdatedFriendRow(button)
	end)
	self:WrapModuleMethod("FriendsList", "UpdateInviteButton", function(_, _, _, _, _, button)
		self:RefreshUpdatedFriendRow(button)
	end)
	self:WrapFriendsListRenderMethod("RenderDisplay")
	self:WrapFriendsListRenderMethod("RenderClassicButtons")

	self:WrapModuleMethod("RecentAllies", "OnLoad", function()
		local engine = GetEngine()
		if engine then
			self:SkinRecentAlliesFrame(engine)
		end
	end)
	self:WrapModuleMethod("RecentAllies", "Refresh", function()
		local engine = GetEngine()
		if engine then
			self:SkinRecentAlliesFrame(engine)
		end
	end)
	self:WrapModuleMethod("RecentAllies", "InitializeEntry", function(_, _, _, _, _, button)
		local engine = GetEngine()
		if engine then
			engine:SkinRow(button)
			engine:SkinTree(button, 2)
		end
	end)

	self:WrapModuleMethod("RAF", "OnLoad", function()
		local engine = GetEngine()
		if engine then
			self:SkinRAFFrame(engine)
		end
	end)
	self:WrapModuleMethod("RAF", "UpdateRecruitList", function()
		local engine = GetEngine()
		if engine then
			self:SkinRAFFrame(engine)
		end
	end)
	self:WrapModuleMethod("RAF", "RenderClassicRAFButtons", function()
		local engine = GetEngine()
		if engine then
			self:SkinRAFFrame(engine)
		end
	end)
	self:WrapModuleMethod("RAF", "RecruitListButton_Init", function(_, _, _, _, _, button)
		local engine = GetEngine()
		if engine then
			engine:SkinRow(button)
			engine:SkinTree(button, 2)
		end
	end)

	self:WrapModuleMethod("WhoFrame", "Update", function()
		local engine = GetEngine()
		if engine then
			self:SkinWhoFrame(engine)
		end
	end)
	self:WrapModuleMethod("WhoFrame", "CreateSearchBuilder", function()
		local engine = GetEngine()
		if engine then
			self:SkinWhoFrame(engine)
		end
	end)
	self:WrapModuleMethod("WhoFrame", "ToggleSearchBuilder", function()
		local engine = GetEngine()
		if engine then
			self:SkinWhoFrame(engine)
		end
	end)
	self:WrapModuleMethod("WhoFrame", "SetBuilderDocked", function()
		local engine = GetEngine()
		if engine then
			self:SkinWhoFrame(engine)
		end
	end)

	for _, methodName in ipairs({
		"Initialize",
		"InitializeClassicQuickJoin",
		"Update",
	}) do
		self:WrapModuleMethod("QuickJoin", methodName, function()
			local engine = GetEngine()
			if engine then
				self:SkinQuickJoin(engine)
			end
		end)
	end

	for _, methodName in ipairs({
		"RefreshThemeTab",
		"RefreshGeneralTab",
		"RefreshFontsTab",
		"RefreshGroupsTab",
		"RefreshAdvancedTab",
		"RefreshStatisticsTab",
		"RefreshBrokerTab",
		"RefreshFilterSortTab",
		"RefreshGlobalSyncTab",
		"RefreshStreamerTab",
		"RefreshRaidTab",
		"RefreshWhoTab",
		"RefreshCategories",
		"SelectCategory",
	}) do
		self:WrapModuleMethod("Settings", methodName, function()
			self:SkinSettingsFrameDeferred()
		end)
	end
	self:WrapModuleMethod("Settings", "CreateExportFrame", function(_, frame)
		self:SkinCreatedFrame(frame or _G.BetterFriendlistExportFrame)
	end)
	self:WrapModuleMethod("Settings", "CreateImportFrame", function(_, frame)
		self:SkinCreatedFrame(frame or _G.BetterFriendlistImportFrame)
	end)
	self:WrapModuleMethod("Settings", "EnsureFilterSortEditorPanel", function(_, frame)
		self:SkinCreatedFrame(frame or _G.BetterFriendlistFilterSortEditorFrame)
	end)

	self:WrapModuleMethod("Changelog", "CreateChangelogWindow", function(_, frame)
		self:SkinCreatedFrame(frame or _G.BetterFriendlistChangelogFrame)
	end)
	self:WrapModuleMethod("RaidTools", "CreateFrame", function(_, frame)
		self:SkinCreatedFrame(frame or _G.BetterFriendlistRaidToolsFrame)
	end)
	self:WrapModuleMethod("NoteCleanupWizard", "CreateWizardFrame", function(_, frame)
		self:SkinCreatedFrame(frame or _G.BetterFriendlistNoteCleanupWizard)
	end)
	self:WrapModuleMethod("NoteCleanupWizard", "CreateBackupViewerFrame", function(_, frame)
		self:SkinCreatedFrame(frame or _G.BetterFriendlistNoteBackupViewer)
	end)
	self:WrapModuleMethod("GuildFrame", "CreateMemberInfoPanel", function(_, frame)
		self:SkinCreatedFrame(frame or _G.BFL_GuildMemberInfoPanel)
	end)

	if BFL.HelpFrame and type(BFL.HelpFrame.CreateFrame) == "function" and not BFL.HelpFrame.BFL_DarkHook_CreateFrame then
		BFL.HelpFrame.BFL_DarkHook_CreateFrame = true
		local original = BFL.HelpFrame.CreateFrame
		BFL.HelpFrame.CreateFrame = function(helpSelf, ...)
			local frame = original(helpSelf, ...)
			if BFL:IsThemeActive("dark") then
				local engine = GetEngine()
				if engine then
					DarkTheme:SkinHelpFrame(engine)
				end
			end
			return frame
		end
	end
end

function DarkTheme:InstallGlobalTabHooks()
	if not hooksecurefunc then
		return
	end

	if not self.bottomTabHooked and type(_G.BetterFriendsFrame_ShowBottomTab) == "function" then
		self.bottomTabHooked = true
		hooksecurefunc("BetterFriendsFrame_ShowBottomTab", function(tabIndex)
			DarkTheme:RefreshVisibleMainContentDeferred(tabIndex)
		end)
	end

	if not self.topTabHooked and type(_G.BetterFriendsFrame_ShowTab) == "function" then
		self.topTabHooked = true
		hooksecurefunc("BetterFriendsFrame_ShowTab", function(tabIndex)
			DarkTheme:RefreshVisibleMainContentDeferred(1, tabIndex)
		end)
	end

	if not self.applyTabFontsHooked and type(BFL.ApplyTabFonts) == "function" then
		self.applyTabFontsHooked = true
		hooksecurefunc(BFL, "ApplyTabFonts", function()
			local cache = BFL._tabFontCache
			if cache and cache.appliedThisCall == false then
				return
			end
			DarkTheme:SkinMainTabsDeferred()
		end)
	end

	if not self.applyTabVisualStateHooked and type(BFL.ApplyTabVisualState) == "function" then
		self.applyTabVisualStateHooked = true
		hooksecurefunc(BFL, "ApplyTabVisualState", function(_, tab)
			local engine = GetEngine()
			if engine and engine:IsActive() and tab then
				engine:CenterTabText(tab)
			end
		end)
	end
end

return DarkTheme
