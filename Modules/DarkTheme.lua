-- Modules/DarkTheme.lua
-- Aurora-inspired dark theme coverage for BFL-owned UI

local ADDON_NAME, BFL = ...
local DarkTheme = BFL:RegisterModule("DarkTheme", {})

local WHO_COLUMN_HEADER_HEIGHT = 28
local WHO_COLUMN_HEADER_OVERLAP = -1
local WHO_LIST_INSET_PADDING = 4
local WHO_SCROLLBAR_RESERVE = 24
local WHO_SCROLLBAR_OFFSET_X = 1

local function GetEngine()
	return BFL:GetModule("SkinEngine")
end

local function SafeCall(fn, ...)
	if not fn then
		return
	end
	pcall(fn, ...)
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

local function SkinCompactCheckButtonField(engine, parent, key)
	if parent and parent[key] then
		parent[key].BFL_DarkNoCheckChrome = nil
		parent[key].BFL_DarkCompactCheckButton = true
		engine:SkinCheckButton(parent[key])
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
	engine:Deactivate()
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
	if not BFL:IsThemeActive("dark") then
		return
	end

	if C_Timer and C_Timer.After then
		C_Timer.After(0, function()
			self:SkinMainTabs()
		end)
	else
		self:SkinMainTabs()
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

	engine:SkinFrame(frame, "main", { stripTextures = true, textureAlpha = 0.10 })
	engine:SkinTree(frame, 6)
	engine:StripButtonFrameArtwork(frame)

	self:LayoutMainListChrome(engine, frame)
	HideFieldChrome(engine, frame, "Inset")
	SkinField(engine, frame, "ScrollFrame", "inset")
	SkinScrollBarField(engine, frame, "MinimalScrollBar")
	SkinButtonField(engine, frame, "AddFriendButton")
	SkinButtonField(engine, frame, "SendMessageButton")
	SkinButtonField(engine, frame, "RecruitmentButton")
	SkinButtonField(engine, frame, "PortraitButton")
	SkinIconButtonField(engine, frame, "StreamerModeButton", { texture = frame.StreamerModeButton and frame.StreamerModeButton.Icon, size = 18 })
	SkinIconButtonField(engine, frame, "HelpButton", { texture = frame.HelpButton and frame.HelpButton.Icon, size = 18 })
	self:LayoutMainTitleButtons(engine, frame)
	self:SkinMainTabs(engine)

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
		self:LayoutHeaderButtons(engine, header)
	end

	self:SkinFriendsListRows(engine)
	self:SkinRecentAlliesFrame(engine)
	self:SkinRAFFrame(engine)
	self:SkinWhoFrame(engine)
	self:SkinRaidFrame(engine)
	self:SkinQuickJoin(engine)
	self:SkinIgnoreList(engine)
	self:SkinGuildFrame(engine)
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

	local pools = {
		FriendsList.classicButtonPool,
		FriendsList.classicHeaderPool,
		FriendsList.classicInviteHeaderPool,
		FriendsList.classicInviteButtonPool,
		FriendsList.classicDividerPool,
	}
	for _, pool in ipairs(pools) do
		if pool then
			for _, row in ipairs(pool) do
				engine:SkinRow(row)
			end
		end
	end
end

function DarkTheme:SkinRecentAlliesFrame(engine)
	local frame = _G.BetterFriendsFrame
	local recent = frame and frame.RecentAlliesFrame
	if not recent then
		return
	end

	SkinTabListSurface(engine, recent, recent.ScrollBox, recent.ScrollBar)
	engine:SkinTree(recent, 5)
end

function DarkTheme:SkinRAFFrame(engine)
	local frame = _G.BetterFriendsFrame
	local raf = frame and frame.RecruitAFriendFrame
	if not raf then
		return
	end

	HideFrameChrome(engine, raf)

	local reward = raf.RewardClaiming
	if reward then
		engine:SkinFrame(reward, "panel", { stripTextures = true, textureAlpha = 0 })
		SkinNativeTextureButtonField(engine, reward, "NextRewardInfoButton")
		SkinNativeTextureButtonField(engine, reward, "NextRewardButton")
		SkinButtonField(engine, reward, "ClaimOrViewRewardButton")
		engine:SkinTree(reward, 4)
	end

	local recruitList = raf.RecruitList
	if recruitList then
		HideFieldChrome(engine, recruitList, "Header")
		SkinTabListSurface(engine, recruitList, recruitList.ScrollBox, recruitList.ScrollBar)
		SkinTabListScrollBar(engine, recruitList.ScrollBox, recruitList.ClassicScrollBar)
		engine:SkinTree(recruitList, 5)
	end

	local splash = raf.SplashFrame
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

	local WhoFrame = BFL:GetModule("WhoFrame")
	if WhoFrame then
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

		local builderContainer = WhoFrame.builderDockedContainer or WhoFrame.builderContainer or _G.BetterFriendlistSearchBuilderFrame
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
		if WhoFrame.classicWhoButtonPool then
			for _, row in ipairs(WhoFrame.classicWhoButtonPool) do
				engine:SkinRow(row)
			end
		end
	end

	local searchBuilderFrame = _G.BetterFriendlistSearchBuilderFrame
	if searchBuilderFrame then
		engine:SkinFrame(searchBuilderFrame, "popup", { stripTextures = true, textureAlpha = 0 })
	end
end

function DarkTheme:SkinRaidFrame(engine)
	local frame = _G.BetterFriendsFrame
	local raid = frame and frame.RaidFrame
	if not raid then
		return
	end

	HideFrameChrome(engine, raid)
	HideFieldChrome(engine, raid, "ControlPanel")
	SkinCompactCheckButtonField(engine, raid.ControlPanel, "EveryoneAssistCheckbox")
	SkinButtonField(engine, raid.ControlPanel, "RaidInfoButton")
	SkinField(engine, raid, "GroupsInset", "inset")
	SkinButtonField(engine, raid, "ConvertToRaidButton")
	SkinButtonField(engine, raid, "RaidToolsButton")
	SkinButtonField(engine, raid, "CombatIcon")
	engine:SkinTree(raid, 5)
	HideFrameChrome(engine, raid)
	HideFieldChrome(engine, raid, "ControlPanel")
	SkinField(engine, raid, "GroupsInset", "inset")
end

function DarkTheme:SkinQuickJoin(engine)
	local frame = _G.BetterFriendsFrame
	local quickJoin = frame and frame.QuickJoinFrame
	if not quickJoin then
		return
	end

	engine:SkinFrame(quickJoin, "panel")
	SkinField(engine, quickJoin, "ContentInset", "inset")
	if quickJoin.ContentInset then
		SkinField(engine, quickJoin.ContentInset, "ScrollBoxContainer", "inset")
		SkinField(engine, quickJoin.ContentInset, "ScrollBox", "inset")
		SkinScrollBarField(engine, quickJoin.ContentInset, "ScrollBar")
		SkinScrollBarField(engine, quickJoin.ContentInset, "ClassicScrollBar")
		SkinButtonField(engine, quickJoin.ContentInset, "JoinQueueButton")
	end
	engine:SkinTree(quickJoin, 5)
end

function DarkTheme:SkinIgnoreList(engine)
	local frame = _G.BetterFriendsFrame
	local ignore = frame and frame.IgnoreListWindow
	if not ignore then
		return
	end

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
	if frame.ContentScrollFrame then
		local scrollBar = frame.ContentScrollFrame.ScrollBar or _G[GetFrameName(frame.ContentScrollFrame) .. "ScrollBar"]
		if scrollBar then
			scrollBar.BFL_DarkWideScrollbar = true
			engine:SkinScrollBar(scrollBar)
		end
	end
	engine:SkinTree(frame, 7)
	SkinSettingsNavigation(engine, frame)
end

function DarkTheme:SkinAuxiliaryFrames(engine)
	for _, frameInfo in ipairs({
		{ "BetterFriendlistChangelogFrame", "popup" },
		{ "BetterFriendlistHelpFrame", "popup" },
		{ "BetterFriendlistExportFrame", "popup" },
		{ "BetterFriendlistImportFrame", "popup" },
		{ "BetterFriendlistFilterSortEditorFrame", "popup" },
		{ "BetterFriendlistNoteCleanupWizard", "popup" },
		{ "BetterFriendlistNoteBackupViewer", "popup" },
		{ "BetterFriendlistRaidToolsFrame", "popup" },
		{ "BetterSavedInstancesFrame", "popup" },
		{ "BFL_GuildMemberInfoPanel", "popup" },
	}) do
		SkinFrameByName(engine, frameInfo[1], frameInfo[2])
	end
end

function DarkTheme:SkinCreatedFrame(frame)
	local engine = GetEngine()
	if not engine or not engine:IsActive() or not frame then
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
		C_Timer.After(0, function()
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
		if BFL:IsThemeActive("dark") then
			SafeCall(after, moduleSelf, r1, r2, r3, r4, ...)
		end
		return r1, r2, r3, r4
	end
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
		self:InstallGlobalTabHooks()
		return
	end
	self.hooksInstalled = true

	self:InstallSettingsComponentHooks()
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
		local engine = GetEngine()
		if engine then
			engine:SkinRow(button)
		end
	end)
	self:WrapModuleMethod("FriendsList", "UpdateGroupHeaderButton", function(_, _, _, _, _, button)
		local engine = GetEngine()
		if engine then
			engine:SkinRow(button)
		end
	end)
	self:WrapModuleMethod("FriendsList", "UpdateInviteHeaderButton", function(_, _, _, _, _, button)
		local engine = GetEngine()
		if engine then
			engine:SkinRow(button)
		end
	end)
	self:WrapModuleMethod("FriendsList", "UpdateInviteButton", function(_, _, _, _, _, button)
		local engine = GetEngine()
		if engine then
			engine:SkinRow(button)
		end
	end)
	self:WrapModuleMethod("FriendsList", "RenderDisplay", function()
		local engine = GetEngine()
		if engine then
			self:SkinFriendsListRows(engine)
		end
	end)
	self:WrapModuleMethod("FriendsList", "RenderClassicButtons", function()
		local engine = GetEngine()
		if engine then
			self:SkinFriendsListRows(engine)
		end
	end)

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
				DarkTheme:SkinCreatedFrame(frame or _G.BetterFriendlistHelpFrame)
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
		hooksecurefunc("BetterFriendsFrame_ShowBottomTab", function()
			DarkTheme:SkinMainTabsDeferred()
		end)
	end

	if not self.topTabHooked and type(_G.BetterFriendsFrame_ShowTab) == "function" then
		self.topTabHooked = true
		hooksecurefunc("BetterFriendsFrame_ShowTab", function()
			DarkTheme:SkinMainTabsDeferred()
		end)
	end

	if not self.applyTabFontsHooked and type(BFL.ApplyTabFonts) == "function" then
		self.applyTabFontsHooked = true
		hooksecurefunc(BFL, "ApplyTabFonts", function()
			DarkTheme:SkinMainTabsDeferred()
		end)
	end
end

return DarkTheme
