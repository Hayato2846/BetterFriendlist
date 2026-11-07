-- Modern FriendsFrame surfaces for the legacy XML settings window only.
local ADDON_NAME, BFL = ...
local LegacySettingsStyle = BFL:RegisterModule("LegacySettingsStyle", {})

function LegacySettingsStyle:OnSectionsLaidOut(frames)
	local frame = _G.BetterFriendlistSettingsFrame
	local content = frame and frame.ContentScrollFrame and frame.ContentScrollFrame.Content
	local page = frames[1] and frames[1]:GetParent()
	if not content or not page or page:GetParent() ~= content then return end
	-- Keep only the current layout per page; rebuilt controls hide their predecessors.
	self.sectionGroups = self.sectionGroups or {}
	self.sectionGroups[page] = frames
	self:Refresh()
end

function LegacySettingsStyle:RefreshSections(modern, palette)
	local frame = _G.BetterFriendlistSettingsFrame
	local content = frame and frame.ContentScrollFrame and frame.ContentScrollFrame.Content
	for page, frames in pairs(self.sectionGroups or {}) do
		local inLegacyWindow = page:GetParent() == content
		local first = true
		for _, header in ipairs(frames) do
			if header.BFL_SettingsSectionHeader and header:IsShown() then
				local shown = modern and inLegacyWindow and not first
				local divider = header.BFL_SectionDivider
				if shown and not divider then
					divider = header:CreateTexture(nil, "ARTWORK")
					divider:SetPoint("TOPLEFT", header, "TOPLEFT", 0, 7)
					divider:SetPoint("TOPRIGHT", header, "TOPRIGHT", 0, 7)
					divider:SetTexelSnappingBias(0)
					divider:SetSnapToPixelGrid(false)
					if BFL.HasAtlas("perks-divider-short") and BFL.SetTextureOrAtlas(divider, "perks-divider-short") then
						divider:SetHeight(3)
					else
						divider:SetColorTexture(1, 1, 1, 0.28)
						divider:SetHeight(1)
					end
					header.BFL_SectionDivider = divider
				end
				if divider then
					divider:SetShown(shown)
					if shown then
						divider:SetAlpha(1)
						divider:SetVertexColor(unpack(palette.border))
					end
				end
				first = false
			end
		end
		if not inLegacyWindow then self.sectionGroups[page] = nil end
	end
end

function LegacySettingsStyle:RefreshScrollbar(frame, modern, theme)
	local scrollFrame = frame.ContentScrollFrame
	if not scrollFrame or not scrollFrame.ScrollBar then return end
	local state = scrollFrame.BFL_SettingsScrollbars
	if modern and not state and BFL.HasModernScrollBox and ScrollUtil and ScrollUtil.InitScrollFrameWithScrollBar then
		local bar = CreateFrame("EventFrame", nil, frame, "MinimalScrollBar")
		state = { active = false, legacy = scrollFrame.ScrollBar, modern = bar, legacyScripts = {}, modernScripts = {} }
		scrollFrame.BFL_SettingsScrollbars = state
		frame.BFL_ModernSettingsScrollBar = bar
		bar:SetHideIfUnscrollable(true)
		local events = { "OnVerticalScroll", "OnScrollRangeChanged", "OnMouseWheel" }
		for _, event in ipairs(events) do state.legacyScripts[event] = scrollFrame:GetScript(event) end
		ScrollUtil.InitScrollFrameWithScrollBar(scrollFrame, bar)
		for _, event in ipairs(events) do
			local eventName = event
			state.modernScripts[eventName] = scrollFrame:GetScript(eventName)
			-- Keep existing HookScript observers and the legacy Slider reference intact.
			scrollFrame:SetScript(eventName, function(owner, ...)
				local scripts = state.active and state.modernScripts or state.legacyScripts
				if scripts[eventName] then scripts[eventName](owner, ...) end
			end)
		end
		state.RefreshVisibility = function()
			local scrollable = scrollFrame:GetVerticalScrollRange() > 0.5
			state.legacy:SetShown(not state.active and scrollable)
			state.modern:SetShown(state.active and scrollable)
		end
		state.legacy:HookScript("OnShow", function()
			if state.active then state.legacy:Hide() end
		end)
		scrollFrame:HookScript("OnScrollRangeChanged", state.RefreshVisibility)
		scrollFrame:EnableMouseWheel(true)
	end
	if not state then return end
	state.active = modern
	if modern then
		local engine = BFL:GetModule("SkinEngine")
		if engine and engine:IsActive() then engine:SkinScrollBar(state.modern) end
		if theme == "blizzard" then state.modern:SetWidth(8) end
		state.modern:ClearAllPoints()
		state.modern:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", 6, 0)
		state.modern:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", 6, 0)
	end
	local scripts = modern and state.modernScripts or state.legacyScripts
	local range = scrollFrame:GetVerticalScrollRange()
	local offset = scrollFrame:GetVerticalScroll()
	if scripts.OnScrollRangeChanged then scripts.OnScrollRangeChanged(scrollFrame, 0, range) end
	-- Rebinding a stale legacy Slider can clamp its old value and move the viewport.
	scrollFrame:SetVerticalScroll(math.min(offset, range))
	if scripts.OnVerticalScroll then scripts.OnVerticalScroll(scrollFrame, scrollFrame:GetVerticalScroll()) end
	state.RefreshVisibility()
end

function LegacySettingsStyle:Refresh()
	local frame = _G.BetterFriendlistSettingsFrame
	if not (frame and frame.Bg and frame.MainInset) then return end
	local FriendsUI = BFL.IsMainline and BFL:GetModule("FriendsUI")
	local theme = BFL.GetEffectiveTheme and BFL:GetEffectiveTheme() or "blizzard"
	local supportedTheme = theme == "blizzard" or theme == "dark" or theme == "custom"
	local modern = not not (FriendsUI and FriendsUI:IsModernActive() and supportedTheme)
	self:RefreshScrollbar(frame, modern, theme)
	if not modern and not frame.BFL_ModernSettingsBackgrounds then return end

	local backgrounds = frame.BFL_ModernSettingsBackgrounds
	if modern and not backgrounds then
		local body = frame:CreateTexture(nil, "BACKGROUND", nil, 1)
		-- The native background accounts for transparent gutters in the outer border.
		body:SetAllPoints(frame.Bg)
		local topFade = frame:CreateTexture(nil, "BACKGROUND", nil, 2)
		topFade:SetPoint("TOPLEFT", body, "TOPLEFT")
		topFade:SetPoint("TOPRIGHT", body, "TOPRIGHT")
		local bottomFade = frame:CreateTexture(nil, "BACKGROUND", nil, 2)
		bottomFade:SetPoint("BOTTOMLEFT", body, "BOTTOMLEFT")
		bottomFade:SetPoint("BOTTOMRIGHT", body, "BOTTOMRIGHT")
		local navigationDivider
		if frame.CategoryList then
			navigationDivider = frame:CreateTexture(nil, "ARTWORK")
			navigationDivider:SetWidth(1)
			navigationDivider:SetTexelSnappingBias(0)
			navigationDivider:SetSnapToPixelGrid(false)
			navigationDivider:SetPoint("TOPLEFT", frame.CategoryList, "TOPRIGHT", 5, 0)
			navigationDivider:SetPoint("BOTTOMLEFT", frame.CategoryList, "BOTTOMRIGHT", 5, 0)
		end
		local function LoadFade(texture, atlas)
			local loaded = BFL.HasAtlas(atlas) and BFL.SetTextureOrAtlas(texture, atlas, nil, true)
			if loaded then texture:SetHeight(math.min(texture:GetHeight(), 140)) end
			return loaded
		end
		backgrounds = {
			body = body, topFade = topFade, bottomFade = bottomFade,
			navigationDivider = navigationDivider,
			hasTopFade = LoadFade(topFade, "friends-frame-toptexbg"),
			hasBottomFade = LoadFade(bottomFade, "friends-frame-bottomtexbg"),
		}
		frame.BFL_ModernSettingsBackgrounds = backgrounds
	end

	-- The outer window supplies the native border, as in the Modern changelog.
	if theme == "blizzard" then
		frame.Bg:SetShown(not modern)
		frame.MainInset:SetBackdropBorderColor(0.4, 0.4, 0.4, modern and 0 or 0.8)
	end
	if frame.ButtonSeparator and supportedTheme then frame.ButtonSeparator:SetShown(not modern) end
	backgrounds.body:SetShown(modern)
	local useAtlas = modern and theme == "blizzard"
	backgrounds.topFade:SetShown(useAtlas and backgrounds.hasTopFade or false)
	backgrounds.bottomFade:SetShown(useAtlas and backgrounds.hasBottomFade or false)
	local palette = modern and FriendsUI:GetModernThemeColors(theme)
	self:RefreshSections(modern, palette)
	if backgrounds.navigationDivider then
		backgrounds.navigationDivider:SetShown(modern)
		if modern then
			local border = palette.border
			backgrounds.navigationDivider:SetColorTexture(border[1], border[2], border[3], theme == "blizzard" and 0.25 or border[4])
			backgrounds.navigationDivider:SetAlpha(1)
		end
	end
	if modern then
		backgrounds.body:SetColorTexture(unpack(palette.background))
		-- A theme refresh can have dimmed existing artwork before this owner pass.
		backgrounds.body:SetAlpha(1)
		backgrounds.topFade:SetAlpha(1)
		backgrounds.bottomFade:SetAlpha(1)
	end
end

function LegacySettingsStyle:Initialize()
	if self.initialized then return end
	self.initialized = true
	local Components = BFL.SettingsComponents
	if Components then
		hooksecurefunc(Components, "AnchorChain", function(_, frames) self:OnSectionsLaidOut(frames) end)
	end
	local frame = _G.BetterFriendlistSettingsFrame
	if frame then frame:HookScript("OnShow", function() self:Refresh() end) end
	-- All targets are addon-owned methods. Reapply after theme restoration and
	-- deferred legacy-control skinning, without touching the Settings Center.
	local ThemeManager = BFL:GetModule("ThemeManager")
	if ThemeManager and ThemeManager.ApplyCurrentTheme then
		hooksecurefunc(ThemeManager, "ApplyCurrentTheme", function() self:Refresh() end)
	end
	local DarkTheme = BFL:GetModule("DarkTheme")
	if DarkTheme and DarkTheme.SkinSettingsFrame then
		hooksecurefunc(DarkTheme, "SkinSettingsFrame", function() self:Refresh() end)
	end
	self:Refresh()
end
