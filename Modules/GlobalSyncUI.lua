local _, BFL = ...
local GlobalSync = BFL.GlobalSync
local ROW_HEIGHT = 26
local ICON = "Interface\\AddOns\\BetterFriendlist\\Icons\\globe.blp"

local function AnchorMenu(panel, button)
	local frame = BetterFriendsFrame
	local bottom, top = frame:GetBottom(), button:GetTop()
	panel:ClearAllPoints()
	if bottom and top then
		-- Keep the existing height above the footer, with the horizontal center
		-- tied to the friend list. Modern footer controls may use another scale.
		local offsetY = top * button:GetEffectiveScale() / frame:GetEffectiveScale() - bottom + 6
		panel:SetPoint("BOTTOM", frame, "BOTTOM", 0, offsetY)
	else
		panel:SetPoint("BOTTOMRIGHT", button, "TOPRIGHT", 0, 6)
	end
end

local function CreateMenu(self)
	local panel = CreateFrame("Frame", nil, BetterFriendsFrame, "BackdropTemplate")
	panel:SetFrameStrata("DIALOG")
	panel:SetSize(320, 224)
	panel:EnableMouse(true)
	panel:SetClampedToScreen(true)
	panel:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8X8",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 12,
		insets = { left = 3, right = 3, top = 3, bottom = 3 },
	})
	panel:SetBackdropColor(0.055, 0.045, 0.035, 0.98)
	panel:SetBackdropBorderColor(0.55, 0.43, 0.27, 1)

	local close = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", -2, -2)
	close:SetScript("OnClick", function() panel:Hide() end)

	local addAll = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
	addAll:SetSize(140, 24)
	addAll:SetPoint("TOPLEFT", 10, -8)
	addAll:SetText(BFL.L.SETTINGS_GLOBAL_SYNC_ADD_ALL)
	addAll:SetScript("OnClick", function()
		self:StartTitleInvites(self:GetPendingTitleFriends())
		self:RefreshTitleFriendUI()
	end)
	panel.AddAll = addAll

	local scroll = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
	scroll:SetPoint("TOPLEFT", addAll, "BOTTOMLEFT", 0, -6)
	scroll:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -29, 9)
	local content = CreateFrame("Frame", nil, scroll)
	content:SetSize(281, 1)
	scroll:SetScrollChild(content)
	panel.Scroll, panel.Content, panel.Rows = scroll, content, {}
	panel:SetScript("OnHide", function()
		self.titleInviteBatch = nil
	end)
	panel:Hide()
	return panel
end

local function UpdateMenu(self, panel, names)
	local busy = self.titleInviteBatch ~= nil or self.activeTitlePrompt ~= nil
	panel.AddAll:SetEnabled(not busy)
	for index, name in ipairs(names) do
		local row = panel.Rows[index]
		if not row then
			row = CreateFrame("Frame", nil, panel.Content)
			local y = -(index - 1) * ROW_HEIGHT
			row:SetPoint("TOPLEFT", 0, y)
			row:SetPoint("TOPRIGHT", 0, y)
			row:SetHeight(ROW_HEIGHT)
			row.Add = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
			row.Add:SetSize(75, 22)
			row.Add:SetPoint("RIGHT", -2, 0)
			row.Add:SetText(BFL.L.AUTO_RAID_ASSIST_ADD)
			row.Add:SetScript("OnClick", function()
				self:StartTitleInvites({ row.characterName })
				self:RefreshTitleFriendUI()
			end)
			row.Label = row:CreateFontString(nil, "OVERLAY", "BetterFriendlistFontHighlight")
			row.Label:SetPoint("LEFT", 4, 0)
			row.Label:SetPoint("RIGHT", row.Add, "LEFT", -8, 0)
			row.Label:SetJustifyH("LEFT")
			row.Label:SetWordWrap(false)
			panel.Rows[index] = row
		end
		row.characterName = name
		row.Label:SetText(name)
		row.Add:SetEnabled(not busy)
		row:Show()
	end
	for index = #names + 1, #panel.Rows do
		panel.Rows[index]:Hide()
	end
	panel.Content:SetHeight(math.max(1, #names * ROW_HEIGHT))
end

local function GetButton(self, anchor, modern)
	if anchor.BFL_TitleSyncButton then
		return anchor.BFL_TitleSyncButton
	end
	local button = CreateFrame("Button", nil, anchor:GetParent(), modern and "SharedButtonTemplate" or "UIPanelButtonTemplate")
	button:SetSize(28, 24)
	button:SetPoint("LEFT", anchor, "RIGHT", 5, 0)
	local icon = button:CreateTexture(nil, "ARTWORK")
	icon:SetSize(15, 15)
	icon:SetPoint("CENTER")
	icon:SetTexture(ICON)
	button:SetScript("OnEnter", function(owner)
		BFL_Tooltip:SetOwner(owner, "ANCHOR_TOP")
		BFL_Tooltip:SetText(BFL.L.SETTINGS_TAB_GLOBAL_SYNC)
		BFL_Tooltip:Show()
	end)
	button:SetScript("OnLeave", function() BFL_Tooltip:Hide() end)
	button:SetScript("OnClick", function()
		local panel = self.titleFriendMenu or CreateMenu(self)
		self.titleFriendMenu = panel
		if panel:IsShown() then
			panel:Hide()
			return
		end
		AnchorMenu(panel, button)
		panel.Scroll:SetVerticalScroll(0)
		panel:Show()
		self:RefreshTitleFriendUI()
	end)
	anchor.BFL_TitleSyncButton = button
	return button
end

function GlobalSync:RefreshTitleFriendUI()
	local frame = BetterFriendsFrame
	if not BFL.IsMainline or not frame or InCombatLockdown() then
		return
	end
	local FriendsUI = BFL:GetModule("FriendsUI")
	local modern = FriendsUI and FriendsUI:IsModernActive()
	local actionBar = FriendsUI and FriendsUI.root and FriendsUI.root.BottomActionBar
	local modernAnchor = actionBar and actionBar.AddFriendButton
	local legacyAnchor = frame.AddFriendButton
	for _, candidate in pairs({ modernAnchor, legacyAnchor }) do
		if not candidate.BFL_TitleSyncHooked then
			candidate.BFL_TitleSyncHooked = true
			candidate:HookScript("OnShow", function() self:RefreshTitleFriendUI() end)
			candidate:HookScript("OnHide", function() self:RefreshTitleFriendUI() end)
		end
	end
	local anchor = legacyAnchor
	if modern then
		anchor = modernAnchor
	end
	local onFriends = not modern or FriendsUI:GetSelectedSection() == "friends"
	local names = frame:IsShown() and onFriends and anchor and anchor:IsVisible() and anchor:IsEnabled()
		and self:GetPendingTitleFriends() or {}
	local hasEntries = #names > 0
	local modernButton = modernAnchor and modernAnchor.BFL_TitleSyncButton
	local legacyButton = legacyAnchor and legacyAnchor.BFL_TitleSyncButton
	if modernButton then modernButton:SetShown(false) end
	if legacyButton then legacyButton:SetShown(false) end
	if hasEntries then
		GetButton(self, anchor, modern):Show()
	end

	local panel = self.titleFriendMenu
	if panel and panel:IsShown() then
		if hasEntries then
			UpdateMenu(self, panel, names)
		else
			panel:Hide()
		end
	end
end
