local _, BFL = ...
local Dock = BFL:RegisterModule("SettingsPreviewDock", {})

local MIN_WIDTH, MAX_WIDTH, DEFAULT_WIDTH = 280, 560, 380
local MIN_HEIGHT, MAX_HEIGHT, DEFAULT_HEIGHT = 300, 1200, 600
local HEADER_HEIGHT, GAP = 32, 8

function Dock:GetState()
	local db = BFL:GetModule("DB")
	local width = tonumber(db:Get("settingsPreviewWidth")) or DEFAULT_WIDTH
	if width ~= width then width = DEFAULT_WIDTH end
	local height = tonumber(db:Get("settingsPreviewHeight")) or DEFAULT_HEIGHT
	if height ~= height then height = DEFAULT_HEIGHT end
	return math.max(MIN_WIDTH, math.min(MAX_WIDTH, width)), db:Get("settingsPreviewCollapsed") == true,
		math.max(MIN_HEIGHT, math.min(MAX_HEIGHT, height))
end

function Dock:SetCollapsed(collapsed)
	if self.resizing then self:StopResize() end
	BFL:GetModule("DB"):Set("settingsPreviewCollapsed", collapsed == true)
	if self.review and self.review.active then self.review:Layout() end
end

function Dock:StopResize()
	if not self.resizing then return end
	self.resizing = nil
	self.window:StopMovingOrSizing()
	BFL:GetModule("DB"):Set("settingsPreviewWidth", math.floor(self.window:GetWidth() + .5))
	BFL:GetModule("DB"):Set("settingsPreviewHeight", math.floor(self.window:GetHeight() + .5))
	self.previewDirty = nil
	self.geometry = nil
	if not self.applying and self.review.active and self.review.frame:IsVisible() then
		self:Anchor()
		self.review:LayoutPreview()
	end
end

function Dock:ResizeContent()
	if self.resizing and not self.applying and self.review.active then
		self.previewDirty = true
		self.review:LayoutPreview(true)
	end
end

function Dock:RefreshToggleIcon()
	local button = self.toggle
	if not button then return end
	local direction = (self.side == "left") == self.collapsed and "left" or "right"
	local path = "Interface\\AddOns\\BetterFriendlist\\Icons\\chevron-" .. direction .. ".blp"
	button.Icon:SetTexture(path)
	button.Icon:ClearAllPoints()
	button.Icon:SetPoint("CENTER", button, "CENTER", 0, 0)
	if BFL:GetEffectiveTheme() == "blizzard" then
		button.Icon:SetVertexColor(1, 1, 0)
	else
		button.Icon:SetVertexColor(BFL:GetThemeAccentColor())
	end
	button.Icon:Show()
end

function Dock:CreateToggle(owner)
	-- Use the same template selection and full button skins as Settings actions.
	-- The arrow is content; hover/pressed feedback belongs to that shared button.
	local button = BFL.SettingsComponents:CreateButton(owner, "")
	button:SetSize(30, 22)
	button.Icon = button:CreateTexture(nil, "OVERLAY")
	button.Icon:SetSize(14, 14)
	button.Icon:SetPoint("CENTER")
	return button
end

function Dock:RefreshAppearance()
	local frame = self.window
	if not frame then return end
	local style = BFL:GetModule("LegacySettingsStyle")
	style:SkinAuxiliaryWindow(frame, frame.Inset)
	style:SkinActions({ self.toggle })
	local theme, modern, palette = style:GetWindowStyle()
	style:RefreshWindowBackground(frame, theme, modern, palette)
	for _, key in ipairs({ "NineSlice", "Bg" }) do
		local region = frame.Inset[key]
		if region then region:SetShown(theme == "blizzard" and not modern) end
	end
	frame.title:SetText(BFL.L.SETTINGS_PREVIEW_WINDOW_TITLE)
	self:RefreshToggleIcon()
	frame.CloseButton:Hide()
	if BFL.FontManager then BFL.FontManager:RefreshWindowFonts() end
end

function Dock:Ensure(review)
	if self.window then return self.window end
	self.review = review
	local frame = CreateFrame("Frame", "BetterFriendlistSettingsPreviewFrame", review.frame, "ButtonFrameTemplate")
	self.window = frame
	frame:Hide()
	frame.BFL_DarkManagedSubtree = true
	frame:SetSize(DEFAULT_WIDTH, 520)
	frame:SetToplevel(true)
	frame:SetClampedToScreen(true)
	frame:EnableMouse(true)
	if ButtonFrameTemplate_HidePortrait then ButtonFrameTemplate_HidePortrait(frame) end
	if ButtonFrameTemplate_HideAttic then ButtonFrameTemplate_HideAttic(frame) end
	frame.CloseButton:Hide()
	frame.title = frame.TitleContainer and frame.TitleContainer.TitleText or frame.TitleText
	if BFL.FontManager then BFL.FontManager:RegisterWindowFont(frame.title, "WindowTitle") end
	frame.Inset:ClearAllPoints()
	frame.Inset:SetPoint("TOPLEFT", 8, -HEADER_HEIGHT)
	frame.Inset:SetPoint("BOTTOMRIGHT", -8, 8)
	frame.content = CreateFrame("Frame", nil, frame.Inset)
	frame.content:SetPoint("TOPLEFT", 4, -4)
	frame.content:SetPoint("BOTTOMRIGHT", -4, 4)
	frame.content:SetClipsChildren(true)
	-- Place the control inside the Settings title bar, including when the
	-- detached preview is hidden. No extra tab projects beyond its border.
	local toggle = self:CreateToggle(review.frame)
	self.toggle = toggle
	toggle:SetScript("OnClick", function()
		if not self.spaceLimited then self:SetCollapsed(not self.collapsed) end
	end)
	toggle:SetScript("OnEnter", function(button)
		BFL_Tooltip:SetOwner(button, self.side == "left" and "ANCHOR_LEFT" or "ANCHOR_RIGHT")
		BFL_Tooltip:SetText(BFL.L[self.spaceLimited and "SETTINGS_PREVIEW_NO_SPACE" or self.collapsed and "SETTINGS_PREVIEW_EXPAND" or "SETTINGS_PREVIEW_COLLAPSE"])
		BFL_Tooltip:Show()
	end)
	toggle:SetScript("OnLeave", function(button)
		if BFL_Tooltip:GetOwner() == button then BFL_Tooltip:Hide() end
	end)
	if frame.SetResizable and frame.SetResizeBounds and frame.StartSizing then
		frame:SetResizable(true)
		local grip = CreateFrame("Button", nil, frame)
		frame.grip = grip
		grip:SetSize(20, 20)
		grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
		grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
		grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
		grip.BFL_DarkManagedSubtree = true
		grip:SetScript("OnMouseDown", function(_, button)
			if button ~= "LeftButton" or self.collapsed then return end
			self.resizing = true
			frame:StartSizing(self.side == "left" and "BOTTOMLEFT" or "BOTTOMRIGHT")
		end)
		grip:SetScript("OnMouseUp", function() self:StopResize() end)
	end
	frame:SetScript("OnSizeChanged", function()
		-- Only move the viewport while dragging. Rebuilding sample friends,
		-- comparisons and skins on each mouse tick stalls the game.
		self:ResizeContent()
	end)
	frame:SetScript("OnHide", function() self:StopResize() end)
	toggle:SetScript("OnUpdate", function()
		-- Geometry follows the same frame as the owner; only changed bounds or
		-- anchors are applied. Sample rendering stays outside this moving path.
		if not self.resizing then self:FollowOwner() end
	end)
	self:RefreshAppearance()
	return frame
end

function Dock:GetDockSpace()
	local ratio = BFL.WindowGeometry:GetRatio(self.window)
	local left, bottom, width, height = BFL.WindowGeometry:GetRect(self.review.frame)
	local spaceLeft, spaceRight = left - 4, UIParent:GetWidth() - left - width - 4
	local friends = _G.BetterFriendsFrame
	if friends and friends:IsVisible() then
		local fx, fy, fw, fh = BFL.WindowGeometry:GetRect(friends)
		local friendsUI = BFL:GetModule("FriendsUI")
		if fx and friendsUI and friendsUI.GetAuxiliaryWindowOffset then
			local friendRatio = BFL.WindowGeometry:GetRatio(friends)
			local leftRail, rightRail = friendsUI:GetAuxiliaryWindowOffset(nil, "left"), friendsUI:GetAuxiliaryWindowOffset(nil, "right")
			leftRail, rightRail = leftRail > 5 and leftRail * friendRatio or 0, rightRail > 5 and rightRail * friendRatio or 0
			fx, fw = fx - leftRail, fw + leftRail + rightRail
		end
		local top = math.min(UIParent:GetHeight() - 4, math.max(bottom + height, self.window:GetHeight() * ratio + 4))
		if fx and fy < top and fy + fh > top - self.window:GetHeight() * ratio then
			-- The friends window is occupied space, even if Settings has just
			-- switched sides. Never dock the preview on top of it.
			if fx < left then spaceLeft = math.min(spaceLeft, left - fx - fw) end
			if fx + fw > left + width then spaceRight = math.min(spaceRight, fx - left - width) end
		end
	end
	return math.max(0, spaceLeft / ratio - GAP), math.max(0, spaceRight / ratio - GAP)
end

function Dock:GetMaximumWidth()
	local left, right = self:GetDockSpace()
	local side = self.side
	-- Keep a usable side while moving instead of jumping across Settings each
	-- time the preferred width stops fitting. Fit temporarily without saving it.
	if not side or (side == "left" and left or right) < MIN_WIDTH then
		side = right >= left and "right" or "left"
	end
	local available = side == "left" and left or right
	self.nextSide, self.spaceLimited = side, available < 160
	return math.max(160, math.min(MAX_WIDTH, available))
end

function Dock:FollowOwner()
	if not self.detached or not self.review.active then return end
	local changed = self:FitSize()
	local _, savedCollapsed = self:GetState()
	if self.collapsed ~= (savedCollapsed or self.spaceLimited) then
		self.review:Layout()
		return
	end
	self:Anchor()
	if changed then
		self.previewDirty = true
		if not self.collapsed then self.review:LayoutPreview(true) end
	elseif self.previewDirty and not self.collapsed then
		self.previewDirty = nil
		self.review:LayoutPreview()
	end
end

function Dock:FitSize()
	local frame = self.window
	local width, _, height = self:GetState()
	local maxWidth = self:GetMaximumWidth()
	local maxHeight = math.min(MAX_HEIGHT, (UIParent:GetHeight() - 16) / BFL.WindowGeometry:GetRatio(frame))
	width, height = math.min(width, maxWidth), math.min(height, maxHeight)
	local changed = math.abs(frame:GetWidth() - width) > .1 or math.abs(frame:GetHeight() - height) > .1
	self.applying = true
	if changed then frame:SetSize(width, height) end
	local minWidth, minHeight = math.min(MIN_WIDTH, maxWidth), math.min(MIN_HEIGHT, maxHeight)
	local bounds = self.bounds
	if frame.SetResizeBounds and (not bounds or bounds[1] ~= minWidth or bounds[2] ~= minHeight or bounds[3] ~= maxWidth or bounds[4] ~= maxHeight) then
		frame:SetResizeBounds(minWidth, minHeight, maxWidth, maxHeight)
		self.bounds = { minWidth, minHeight, maxWidth, maxHeight }
	end
	self.applying = nil
	return changed
end

function Dock:Anchor()
	local frame, owner = self.window, self.review.frame
	local geometry = BFL.WindowGeometry
	local x, y, w, h = geometry:GetRect(owner)
	if not x then return end
	local ratio = geometry:GetRatio(frame)
	-- EUI's public Shell primitive paints a 25px title strip from the top edge.
	local theme = BFL:GetEffectiveTheme()
	local eui = theme == "ellesmereui"
	local toggleHeight, toggleTop = eui and 25 or 22, eui and 0 or -3
	local toggleWidth, leftInset, rightInset, iconSize, artworkInset = 30, 12, -34, 14, 0
	local close = theme == "blizzard" and owner.CloseButton
	local closeX, closeY, closeW, closeH
	if close then closeX, closeY, closeW, closeH = geometry:GetRect(close) end
	if closeX then
		-- Native title controls fill the frame edge. Match the close button's
		-- actual dimensions and top edge, including client/UI-scale differences.
		local ownerRatio = geometry:GetRatio(owner)
		toggleWidth, toggleHeight = closeW / ownerRatio + 6, closeH / ownerRatio
		toggleTop = (closeY + closeH - y - h) / ownerRatio
		leftInset = (x + w - closeX - closeW) / ownerRatio
		rightInset = (closeX - x - w) / ownerRatio - 2
		iconSize = math.floor(math.min(toggleWidth, toggleHeight) * 2 / 3 + .5)
		if self.toggle.atlasName == "128-RedButton" then
			-- The shared red kit's visible top border sits below the close kit's.
			-- Extend upwards only; keep the aligned bottom and glyph center fixed.
			artworkInset = toggleHeight / 16
			toggleHeight, toggleTop = toggleHeight + artworkInset, toggleTop + artworkInset
		end
	end
	local values = { x, y, w, h, ratio, frame:GetWidth(), frame:GetHeight(), UIParent:GetWidth(), UIParent:GetHeight(), toggleHeight, toggleWidth, toggleTop, leftInset, rightInset }
	local previous, changed = self.geometry, not self.geometry or self.side ~= self.nextSide
	for index, value in ipairs(values) do
		if previous and (not previous[index] or math.abs(value - previous[index]) > .01) then changed = true end
	end
	if not changed then return end
	self.geometry = values
	local _, side = geometry:Dock(frame, owner, GAP * ratio, 0, GAP * ratio, self.nextSide)
	self.side = side
	local toggle = self.toggle
	toggle:ClearAllPoints()
	toggle:SetSize(toggleWidth, toggleHeight)
	toggle.Icon:SetSize(iconSize, iconSize)
	toggle:SetPoint(side == "left" and "TOPLEFT" or "TOPRIGHT", owner, side == "left" and "TOPLEFT" or "TOPRIGHT", side == "left" and leftInset or rightInset, toggleTop)
	self:RefreshToggleIcon()
	if frame.grip then
		frame.grip:ClearAllPoints()
		frame.grip:SetPoint(side == "left" and "BOTTOMLEFT" or "BOTTOMRIGHT", side == "left" and 3 or -3, 3)
		for _, texture in ipairs({ frame.grip:GetNormalTexture(), frame.grip:GetHighlightTexture(), frame.grip:GetPushedTexture() }) do
			texture:SetTexCoord(side == "left" and 1 or 0, side == "left" and 0 or 1, 0, 1)
		end
	end
end

function Dock:RefreshSkinLevels()
	-- Reparenting changes native child levels, including cached skin backings.
	-- Reestablish the backing below each of our known preview widgets.
	local function Adjust(owner)
		local level = owner and math.max(0, owner:GetFrameLevel() - 1)
		for _, backing in pairs({ owner and owner.BFL_DarkBackdrop, owner and owner.backdrop }) do
			if backing.GetFrameLevel and backing:GetFrameLevel() ~= level then backing:SetFrameLevel(level) end
		end
	end
	local function Row(row)
		Adjust(row)
		Adjust(row and row.travelPassButton)
	end
	Adjust(self.window)
	Adjust(self.window and self.window.Inset)
	Adjust(self.toggle)
	local review = self.review
	if not review then return end
	Adjust(review.previewShell)
	for _, row in pairs(review.sampleWidgets or {}) do Row(row) end
	for _, lane in ipairs(review.comparisonLanes or {}) do
		for _, row in ipairs(lane.widgets or {}) do Row(row) end
	end
end

function Dock:Update(review, detached)
	self.review = review
	self.detached = detached
	local frame = detached and self:Ensure(review) or self.window
	if frame then
		local strata, level = review.frame:GetFrameStrata(), review.frame:GetFrameLevel() + 5
		if frame:GetFrameStrata() ~= strata then frame:SetFrameStrata(strata) end
		if frame:GetFrameLevel() ~= level then frame:SetFrameLevel(level) end
		-- Native panel chrome uses explicit levels (500/510), independent of
		-- the window's own level. The toggle must sit above that title artwork.
		local toggleLevel = level + 1
		for _, chrome in pairs({ review.frame.NineSlice, review.frame.TitleContainer }) do
			toggleLevel = math.max(toggleLevel, chrome:GetFrameLevel() + 1)
		end
		if self.toggle:GetFrameLevel() ~= toggleLevel then self.toggle:SetFrameLevel(toggleLevel) end
	end
	local parent = detached and frame.content or review.frame.MainInset
	for _, child in ipairs({ review.preview, review.hoverHelp }) do
		if child:GetParent() ~= parent then
			child:SetParent(parent)
			child:SetFrameLevel(parent:GetFrameLevel() + 2)
		end
	end
	if review.previewShell then review.previewShell:SetFrameLevel(review.preview:GetFrameLevel() - 1) end
	self:RefreshSkinLevels()
	if not detached then
		self.applying = true
		if frame then frame:Hide() end
		if self.toggle then self.toggle:Hide() end
		self.applying = nil
		return
	end
	self.applying = true
	if not self.resizing then self:FitSize() end
	local _, savedCollapsed = self:GetState()
	local collapsed = savedCollapsed or self.spaceLimited
	self.collapsed = collapsed
	self.applying = nil
	frame:SetShown(not collapsed)
	self.toggle:Show()
	self.geometry = nil
	if not self.resizing then self:Anchor() end
	return frame.content, not collapsed
end

function Dock:Hide()
	if self.window then self.window:Hide() end
	if self.toggle then self.toggle:Hide() end
end
