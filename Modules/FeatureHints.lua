-- Shared, non-modal guidance cards. Feature modules supply their own conditions and localized content.
local ADDON_NAME, BFL = ...
local FeatureHints = BFL:RegisterModule("FeatureHints", {})

local DISPLAY_SECONDS = 18
local FADE_SECONDS = 1

local ICON_ROOT = "Interface\\AddOns\\BetterFriendlist\\Icons\\"
local BADGE_WIDTH = 280
local PADDING = 12
local SUMMARY_PADDING = 10
local FOOTER_GAP = 4
local FOOTER_PADDING = 10
local DETAIL_TOP_PADDING = 6
local SCREEN_MARGIN = 8
local TAB_GAP = 8
local DETAIL_TAB_GAP = 2
local SHELF_TAB_CLEARANCE = 4
local SHELF_CLIP_CLEARANCE = 1
local MIN_DETAIL_WIDTH = 188
local MIN_DETAIL_HEIGHT = 96
local PAGER_HEIGHT = 24
local FLAT_BACKDROP = {
	bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8",
	edgeSize = 1, insets = { left = 1, right = 1, top = 1, bottom = 1 },
}

local function Color(source, fallback)
	source = source or fallback
	return { source[1] or source.r, source[2] or source.g, source[3] or source.b, source[4] or source.a or 1 }
end

function FeatureHints:GetPalette()
	local palette = {
		background = { 0.045, 0.040, 0.033, 0.97 }, border = { 0.30, 0.27, 0.21, 1 },
		text = { 0.94, 0.93, 0.90, 1 }, muted = { 0.63, 0.61, 0.56, 1 },
		accent = { BFL:GetThemeAccentColor(1, 0.82, 0, 1) },
	}
	local engine = BFL:GetModule("SkinEngine")
	local colors = engine and engine.IsActive and engine:IsActive() and engine.colors
	local FriendsUI = BFL:GetModule("FriendsUI")
	if colors then
		palette.background = Color(colors.popup or colors.panel, palette.background)
		palette.border = Color(colors.borderSoft, palette.border)
		palette.text = Color(colors.text, palette.text)
		palette.muted = Color(colors.disabledText, palette.muted)
	elseif FriendsUI and FriendsUI.GetModernThemeColors then
		local modern, themed = FriendsUI:GetModernThemeColors()
		if modern then
			palette.background = Color(modern.background, palette.background)
			if themed then
				palette.border = Color(modern.border, palette.border)
				palette.text = Color(modern.text, palette.text)
				palette.muted = Color(modern.disabledText, palette.muted)
			end
		end
	end
	local theme = BFL.GetEffectiveTheme and BFL:GetEffectiveTheme()
	if theme == "elvui" and BFL.GetElvUIEngine then
		local E = BFL:GetElvUIEngine(false)
		if E and E.media then
			palette.background = Color(E.media.backdropcolor, palette.background)
			palette.border = Color(E.media.bordercolor, palette.border)
		end
	end
	-- A small floating notice needs its own readable surface over the game world.
	palette.background[4] = math.max(palette.background[4], 0.94)
	return palette
end

local function HasAction(entry)
	return entry.onClick ~= nil or entry.page ~= nil or entry.category ~= nil
end

function FeatureHints:OpenEntry(entry)
	entry = entry or self.entries[1]
	if not HasAction(entry) then return end
	self.frame:Hide()
	if entry.onClick then entry.onClick(); return end
	local Settings = BFL:GetModule("Settings")
	if not Settings then return end
	if Settings:IsSettingsCenterEnabled() and Settings:ShowSettingsCenter(entry.page, entry.control) then return end
	Settings:ShowLegacy(entry.category, entry.legacySection)
end

local function NewText(owner, font)
	local text = owner:CreateFontString(nil, "OVERLAY", font)
	text:SetJustifyH("LEFT")
	text:SetJustifyV("TOP")
	text:SetWordWrap(true)
	text:SetNonSpaceWrap(true)
	text:SetMaxLines(0)
	return text
end

local function Measure(text, width)
	-- Explicit dimensions avoid measuring unresolved anchors and clipping later paragraphs.
	text:SetWidth(width)
	text:SetHeight(0)
	local height = math.ceil(text:GetStringHeight())
	text:SetHeight(height)
	return height
end

local function LayoutAction(button, text, width)
	button.label:SetText(text)
	button.label:SetWidth(0)
	button.label:SetHeight(0)
	local buttonWidth = math.min(width, math.ceil(button.label:GetStringWidth()))
	button:SetSize(buttonWidth, math.max(20, Measure(button.label, buttonWidth)))
end

function FeatureHints:IsModernStyle()
	local FriendsUI = BFL:GetModule("FriendsUI")
	return FriendsUI and FriendsUI.IsModernActive and FriendsUI:IsModernActive() == true or false
end

function FeatureHints:GetDockBounds()
	local frame, parent = self.frame, self.anchor
	local scale = frame:GetEffectiveScale()
	local function Edge(region, method)
		local value = region[method](region)
		return value and value * region:GetEffectiveScale() / scale
	end
	local bounds = {
		left = Edge(UIParent, "GetLeft"), right = Edge(UIParent, "GetRight"),
		top = Edge(UIParent, "GetTop"), bottom = Edge(UIParent, "GetBottom"),
		parentTop = Edge(parent, "GetTop"), parentRight = Edge(parent, "GetRight"), scale = scale,
	}
	local friendsUI = BFL:GetModule("FriendsUI")
	if parent == _G.BetterFriendsFrame and friendsUI and friendsUI.sideTabs then
		for _, tab in ipairs(friendsUI.sideTabs) do
			if tab:IsVisible() then
				local left, right, top = Edge(tab, "GetLeft"), Edge(tab, "GetRight"), Edge(tab, "GetTop")
				if left and right and top then
					bounds.tabLeft = math.min(bounds.tabLeft or left, left)
					bounds.tabRight = math.max(bounds.tabRight or right, right)
					bounds.tabTop = math.max(bounds.tabTop or top, top)
				end
			end
		end
	end
	return bounds
end

function FeatureHints:GetDockPlan(bounds, minimumHeight)
	local width = math.min(BADGE_WIDTH, bounds.right - bounds.left - SCREEN_MARGIN * 2)
	local left = self.anchor == UIParent and bounds.right - width - 24 or bounds.parentRight
	left = math.max(bounds.left + SCREEN_MARGIN, math.min(left, bounds.right - width - SCREEN_MARGIN))
	local top = self.anchor == UIParent and bounds.top - 120 or bounds.parentTop
	top = math.min(bounds.top, top)
	local bottom = bounds.bottom + SCREEN_MARGIN
	local overTabs = bounds.tabRight and left < bounds.tabRight + TAB_GAP and left + width > bounds.tabLeft - TAB_GAP
	if overTabs then
		local tabLimit = bounds.tabTop + TAB_GAP
		local needsSide = minimumHeight and top - tabLimit < minimumHeight
		if needsSide and bounds.tabLeft - TAB_GAP - width >= bounds.left + SCREEN_MARGIN then
			-- Large text can make even the compact badge too tall for the gap.
			-- Keep its title line and put the whole card clear of the tab rail.
			left = bounds.tabLeft - TAB_GAP - width
		elseif needsSide and bounds.tabRight + TAB_GAP + width <= bounds.right - SCREEN_MARGIN then
			left = bounds.tabRight + TAB_GAP
		else
			bottom = math.max(bottom, tabLimit)
		end
	end
	return { left = left, top = top, width = width, maxHeight = math.max(1, top - bottom) }
end

local BORDER_PIECES = {
	"TopLeftCorner", "TopRightCorner", "TopEdge", "BottomLeftCorner",
	"BottomRightCorner", "BottomEdge", "LeftEdge", "RightEdge", "Center",
}
local OUTER_BORDER = { TopEdge = true, TopRightCorner = true, RightEdge = true, BottomRightCorner = true }
local LEFT_HEADER_BORDER = { TopLeftCorner = true }
local UPPER_BORDER = { LeftEdge = true, BottomLeftCorner = true, BottomEdge = true }
local LOWER_BORDER = { LeftEdge = true, BottomLeftCorner = true, BottomEdge = true }
local HEADER_BORDER = { TopLeftCorner = true, TopRightCorner = true, TopEdge = true }
local NATIVE_FRAME_GUTTER = 16
local NATIVE_LEDGE_OVERLAP = 6
local NATIVE_INNER_RISE = 4

local function ShowBorderPieces(skin, shown)
	for _, name in ipairs(BORDER_PIECES) do
		local piece = skin[name]
		if piece then piece:SetShown(not shown or shown[name] == true) end
	end
end

local function CreateBorderClip(parent)
	local clip = CreateFrame("Frame", nil, parent)
	clip:EnableMouse(false)
	clip:SetClipsChildren(true)
	clip.skin = CreateFrame("Frame", nil, clip)
	return clip
end

local function LayoutNativeBorder(frame, borderLevel, upperLeftTrim)
	local border, details = frame.NineSlice, frame.details
	local indent, stepDrop = details.indent, details.stepDrop
	local sideTrim = 0
	if indent > 0 then
		-- On Mainline, HidePortrait applies this border without updating
		-- the inherited layout type, which still points to the portrait art.
		local layout = BFL.IsMainline and "ButtonFrameTemplateNoPortrait"
			or (border.GetFrameLayoutType and border:GetFrameLayoutType())
		if not (layout and NineSliceUtil and NineSliceUtil.ApplyLayoutByName and NineSliceUtil.GetLayout(layout)) then
			return false
		end
		if not frame.nativeBorderClips then
			if not frame.SetClipsChildren then return false end
			frame.nativeBorderClips = { CreateBorderClip(frame), CreateBorderClip(frame), CreateBorderClip(frame) }
		end
		local header, upper, lower = unpack(frame.nativeBorderClips)
		local kit = border.GetFrameLayoutTextureKit and border:GetFrameLayoutTextureKit()
		local newLayout = frame.connectedLayout ~= layout or frame.connectedTextureKit ~= kit
		for _, clip in ipairs(frame.nativeBorderClips) do
			if newLayout then
				clip.skin.layoutType = layout
				NineSliceUtil.ApplyLayoutByName(clip.skin, layout, kit)
			end
			clip:SetFrameLevel(borderLevel)
			-- The inner vertical edge covers the end of the shelf.
			clip.skin:SetFrameLevel(borderLevel + (clip == lower and 2 or 1))
			clip:ClearAllPoints()
		end
		if newLayout then
			frame.connectedLayout, frame.connectedTextureKit = layout, kit
		end
		-- Blizzard's tab atlases reserve transparent space to the right.
		-- Use it for the painted border only, keeping the detail hit area clear.
		sideTrim = BFL.IsForever and 6 or 3
		-- Leave Blizzard's atlas sizes and edge anchors intact on each rectangle.
		-- The top-left artwork also contains part of the horizontal title bar,
		-- so it must span the full card independently of the clipped shelf.
		header:SetPoint("TOPLEFT", frame, "TOPLEFT", -NATIVE_FRAME_GUTTER, NATIVE_FRAME_GUTTER)
		header:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", NATIVE_FRAME_GUTTER, -stepDrop)
		header.skin:ClearAllPoints()
		header.skin:SetPoint("TOPLEFT", frame, "TOPLEFT", -upperLeftTrim, 0)
		header.skin:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT")
		ShowBorderPieces(header.skin, LEFT_HEADER_BORDER)
		upper:SetPoint("TOPLEFT", frame, "TOPLEFT", -NATIVE_FRAME_GUTTER, NATIVE_FRAME_GUTTER)
		upper:SetPoint("BOTTOMRIGHT", details, "TOPLEFT", NATIVE_LEDGE_OVERLAP - sideTrim, -details.shelfClipDepth - stepDrop)
		upper.skin:ClearAllPoints()
		upper.skin:SetPoint("TOPLEFT", frame, "TOPLEFT", -upperLeftTrim, 0)
		upper.skin:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, -stepDrop)
		ShowBorderPieces(upper.skin, UPPER_BORDER)
		-- Clip the upright at the top of the gold ledge. The horizontal art
		-- needs more overlap to reach it through the atlas's side gutter.
		lower:SetPoint("TOPLEFT", details, "TOPLEFT", 1 - DETAIL_TAB_GAP - sideTrim, NATIVE_INNER_RISE - stepDrop)
		lower:SetPoint("BOTTOMRIGHT", details, "BOTTOMRIGHT", NATIVE_FRAME_GUTTER, -NATIVE_FRAME_GUTTER)
		lower.skin:ClearAllPoints()
		lower.skin:SetPoint("TOPLEFT", frame, "TOPLEFT", indent - sideTrim, NATIVE_FRAME_GUTTER * 2)
		lower.skin:SetPoint("BOTTOMRIGHT", details, "BOTTOMRIGHT")
		ShowBorderPieces(lower.skin, LOWER_BORDER)
		for _, clip in ipairs(frame.nativeBorderClips) do clip:Show() end
	end
	ShowBorderPieces(border, indent > 0 and OUTER_BORDER or nil)
	return true, sideTrim
end

local function LayoutConnectedOutline(frame, nativeHeader)
	local outline, width, summary = frame.outline, frame.layoutWidth, frame:GetHeight()
	local indent, upper = frame.details.indent, summary + frame.details.stepDrop
	local top = nativeHeader and 22 or 0
	local bottom = summary + frame.details:GetHeight()
	local color = frame.palette.border
	if nativeHeader then
		color = BFL.IsForever and { .50, .39, .23, 1 } or { .36, .33, .28, 1 }
	end
	-- The contour uses frame coordinates. Native edge textures include artwork
	-- and transparent gutters whose widths are unrelated to the cutout.
	local function Line(index, x, y, w, h, shown)
		local line = outline.lines[index]
		line:ClearAllPoints()
		line:SetPoint("TOPLEFT", frame, "TOPLEFT", x, -y)
		line:SetSize(w, h)
		line:SetColorTexture(unpack(color))
		line:SetShown(shown ~= false)
	end
	Line(1, 0, 0, width, 1, not nativeHeader)
	Line(2, 0, top, 1, (indent > 0 and upper or bottom) - top)
	Line(3, width - 1, top, 1, bottom - top)
	Line(4, indent, bottom - 1, width - indent, 1)
	Line(5, 0, upper - 1, math.max(1, indent), 1, indent > 0)
	Line(6, indent, upper - 1, 1, bottom - upper + 1, indent > 0)
end

function FeatureHints:RefreshSurface()
	local frame = self.frame
	local connected = frame.details:IsShown()
	local borderLevel = frame.NineSlice and frame.NineSlice:GetFrameLevel() or frame:GetFrameLevel()
	local contentLevel = math.max(frame:GetFrameLevel(), borderLevel) + 3
	frame.content:SetFrameLevel(contentLevel)
	frame.details:SetFrameLevel(contentLevel)
	if frame.TitleContainer then frame.TitleContainer:SetFrameLevel(contentLevel + 1) end
	if frame.CloseButton then frame.CloseButton:SetFrameLevel(contentLevel + 1) end
	local theme = BFL.GetEffectiveTheme and BFL:GetEffectiveTheme() or "blizzard"
	local native = theme == "blizzard"
	local modern = frame.modern
	local nineSlice = frame.NineSlice
	local nativeHeader = native and nineSlice and nineSlice.TopEdge
	-- Align the painted bevels beside the Modern friends window. Their atlas
	-- offsets differ between Forever and Retail.
	local upperLeftTrim = nativeHeader and modern and (BFL.IsForever and 1 or 2) or 0
	if frame.nativeBorderClips then
		for _, clip in ipairs(frame.nativeBorderClips) do clip:Hide() end
	end
	local useNativeBorder, nativeSideTrim
	if connected and nativeHeader then
		useNativeBorder, nativeSideTrim = LayoutNativeBorder(frame, borderLevel, upperLeftTrim)
		if not useNativeBorder then upperLeftTrim = 0 end
	end
	frame.outline:SetFrameLevel(borderLevel)
	frame.outline:SetShown(connected and not useNativeBorder)
	if connected and not useNativeBorder then LayoutConnectedOutline(frame, nativeHeader) end
	if nineSlice then
		nineSlice:SetShown(native and (not connected or nativeHeader ~= nil))
		nineSlice:ClearAllPoints()
		if useNativeBorder or upperLeftTrim > 0 then
			nineSlice:SetPoint("TOPLEFT", frame, "TOPLEFT", -upperLeftTrim, 0)
			nineSlice:SetPoint("BOTTOMRIGHT", useNativeBorder and frame.details or frame, "BOTTOMRIGHT")
		else
			nineSlice:SetAllPoints(frame)
		end
		if not useNativeBorder then
			ShowBorderPieces(nineSlice, connected and HEADER_BORDER or nil)
		end
	end
	-- These are the same native shell and inset used by BetterFriendsFrame.
	for _, region in ipairs(frame.nativeRegions) do region:SetShown(native) end
	if frame.Bg then frame.Bg:SetShown(native and not modern and not connected) end
	if frame.Inset then frame.Inset:SetShown(native and not modern and not connected) end
	if frame.CloseButton then frame.CloseButton:SetShown(native) end
	frame.close:SetShown(not native)
	if native or connected then frame:ClearBackdrop()
	else BFL.SetOwnedBackdrop(frame, FLAT_BACKDROP) end
	frame.bodySurface:ClearAllPoints()
	if connected then
		local backingInset = useNativeBorder and 2 or 1
		if useNativeBorder and frame.Bg then
			frame.bodySurface:SetPoint("TOPLEFT", frame.Bg, "TOPLEFT", -upperLeftTrim, 0)
		else
			frame.bodySurface:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, nativeHeader and -22 or -1)
		end
		frame.bodySurface:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -backingInset, -frame.details.stepDrop)
		frame.details.bodySurface:ClearAllPoints()
		local detailLeftInset = nativeSideTrim and nativeSideTrim > 0 and (4 - nativeSideTrim) or backingInset
		-- Meet the summary at the shelf. Overlapping opaque fills darken this band during the fade.
		frame.details.bodySurface:SetPoint("TOPLEFT", frame.details, "TOPLEFT", detailLeftInset, -frame.details.stepDrop)
		frame.details.bodySurface:SetPoint("BOTTOMRIGHT", frame.details, "BOTTOMRIGHT", -backingInset, backingInset)
		frame.details.bottomFade:SetHeight(math.min(72, frame.details:GetHeight() / 2))
	elseif upperLeftTrim > 0 and frame.Bg then
		frame.bodySurface:SetPoint("TOPLEFT", frame.Bg, "TOPLEFT", -upperLeftTrim, 0)
		frame.bodySurface:SetPoint("BOTTOMRIGHT", frame.Bg, "BOTTOMRIGHT")
	else
		frame.bodySurface:SetAllPoints(frame.Bg)
	end
	frame.bodySurface:SetShown((native and modern) or connected)
	frame.details.bodySurface:SetShown(connected)
	frame.topFade:SetShown(native and modern and frame.hasTopFade)
	frame.bottomFade:SetShown(native and modern and not connected and frame.hasBottomFade)
	frame.details.bottomFade:SetShown(native and modern and connected and frame.details.hasBottomFade)
	frame.modernDivider:SetShown(frame.hasFooter and modern and frame.hasModernDivider)
	frame.divider:SetShown(frame.hasFooter and not (modern and frame.hasModernDivider))
	local bodyHeight = math.max(24, frame:GetHeight() - 30)
	frame.topFade:SetHeight(math.min(96, bodyHeight / 2))
	frame.bottomFade:SetHeight(math.min(72, bodyHeight / 2))
	frame.progress:SetShown(not connected)
	frame.details.progress:SetShown(connected)
	frame.activeProgress = connected and frame.details.progress or frame.progress
	frame.progressWidth = (connected and frame.details:GetWidth() or frame.layoutWidth) - PADDING * 2
	frame.activeProgress:SetWidth(math.max(1, frame.progressWidth * (1 - math.min(1, (frame.elapsed or 0) / frame.displaySeconds))))
	return native
end

function FeatureHints:ApplyAppearance()
	local frame = self.frame
	if not frame then return end
	local palette = self:GetPalette()
	frame.palette = palette
	local native = self:RefreshSurface()
	if not native and not frame.details:IsShown() then
		frame:SetBackdropColor(unpack(palette.background))
		frame:SetBackdropBorderColor(unpack(palette.border))
	end
	local legacyDetails = native and not frame.modern and frame.details:IsShown()
	for _, surface in ipairs({ frame.bodySurface, frame.details.bodySurface }) do
		if legacyDetails then
			surface:SetTexture("Interface\\FrameGeneral\\UI-Background-Marble")
		else
			surface:SetColorTexture(palette.background[1], palette.background[2], palette.background[3], 1)
		end
		surface:SetHorizTile(legacyDetails)
		surface:SetVertTile(legacyDetails)
	end
	frame.title:SetTextColor(unpack(palette.accent))
	frame.icon:SetVertexColor(unpack(palette.accent))
	frame.close.icon:SetVertexColor(unpack(palette.muted))
	frame.open.label:SetTextColor(unpack(palette.accent))
	frame.more.label:SetTextColor(unpack(palette.muted))
	frame.pageNumber:SetTextColor(unpack(palette.muted))
	frame.previous.label:SetTextColor(unpack(palette.accent))
	frame.next.label:SetTextColor(unpack(palette.accent))
	frame.divider:SetColorTexture(palette.border[1], palette.border[2], palette.border[3], 0.6)
	if native then frame.modernDivider:SetVertexColor(1, 1, 1, 1)
	else frame.modernDivider:SetVertexColor(unpack(palette.border)) end
	frame.activeProgress:SetColorTexture(palette.accent[1], palette.accent[2], palette.accent[3], 0.45)
	for _, panel in ipairs({ frame, frame.details }) do
		panel.scrollbar.track:SetColorTexture(palette.border[1], palette.border[2], palette.border[3], 0.55)
		panel.scrollbar:GetThumbTexture():SetVertexColor(unpack(palette.muted))
	end
	for _, row in ipairs(frame.rows) do
		row.heading:SetTextColor(unpack(palette.accent))
		row.description:SetTextColor(unpack(palette.text))
		row.path:SetTextColor(unpack(palette.muted))
	end
end

function FeatureHints:LayoutRows(panel, width, first, last, showHeadings)
	local y = 0
	local rowPadding = showHeadings and 4 or 2
	local pathGap = showHeadings and 5 or 3
	for index = first, last do
		local entry, row = self.entries[index], self.frame.rows[index]
		if row:GetParent() ~= panel.scrollContent then row:SetParent(panel.scrollContent) end
		row:ClearAllPoints()
		row:SetPoint("TOPLEFT", panel.scrollContent, "TOPLEFT", 0, -y)
		row:SetWidth(width)
		row.heading:SetText(entry.label)
		local showHeading = showHeadings and entry.label ~= nil and entry.label ~= ""
		row.heading:SetShown(showHeading)
		local headingHeight = showHeading and Measure(row.heading, width) or 0
		local headingGap = showHeading and 4 or 0
		row.description:SetText(entry.text)
		row.description:ClearAllPoints()
		row.description:SetPoint("TOPLEFT", 0, -rowPadding - headingHeight - headingGap)
		local descriptionHeight = Measure(row.description, width)
		row.path:SetText(entry.path or "")
		row.path:ClearAllPoints()
		row.path:SetPoint("TOPLEFT", 0, -rowPadding - headingHeight - headingGap - descriptionHeight - pathGap)
		local pathHeight = entry.path and Measure(row.path, width) or 0
		row:SetHeight(rowPadding * 2 + headingHeight + headingGap + descriptionHeight + pathHeight + (entry.path and pathGap or 0))
		row:Show()
		y = y + row:GetHeight() + (index < last and 8 or 0)
	end
	return math.max(1, y)
end

function FeatureHints:LayoutViewport(panel, width, maxHeight, top, first, last, showHeadings, scrollOffset)
	local bodyHeight = self:LayoutRows(panel, width, first, last, showHeadings)
	local scrolling = bodyHeight > maxHeight
	local bodyWidth = width - (scrolling and 12 or 0)
	if scrolling then bodyHeight = self:LayoutRows(panel, bodyWidth, first, last, showHeadings) end
	local viewportHeight = math.min(bodyHeight, maxHeight)
	local viewport = panel.viewport
	viewport:ClearAllPoints()
	viewport:SetPoint("TOPLEFT", panel.content or panel, "TOPLEFT", panel == self.frame and SUMMARY_PADDING or PADDING, -top)
	viewport:SetSize(bodyWidth, viewportHeight)
	panel.scrollContent:SetSize(bodyWidth, bodyHeight)
	viewport:UpdateScrollChildRect()
	panel.scrollRange = math.max(0, bodyHeight - viewportHeight)
	local offset = math.min(scrollOffset or viewport:GetVerticalScroll(), panel.scrollRange)
	local bar = panel.scrollbar
	bar:SetMinMaxValues(0, panel.scrollRange)
	bar:SetValue(offset)
	bar:SetShown(scrolling)
	bar:GetThumbTexture():SetHeight(math.min(viewportHeight, math.max(12, viewportHeight * viewportHeight / bodyHeight)))
	viewport:SetVerticalScroll(offset)
	return viewportHeight
end

function FeatureHints:LayoutDetails(plan, bounds, badgeHeight)
	local frame, details = self.frame, self.frame.details
	local left = plan.left
	if bounds.tabRight and left < bounds.tabRight + DETAIL_TAB_GAP and left + plan.width > bounds.tabLeft - DETAIL_TAB_GAP then
		left = bounds.tabRight + DETAIL_TAB_GAP
	end
	local indent = left - plan.left
	local width = plan.width - indent
	local height = plan.top - badgeHeight - bounds.bottom - SCREEN_MARGIN
	if width < MIN_DETAIL_WIDTH or height < MIN_DETAIL_HEIGHT then
		return false
	end
	details:ClearAllPoints()
	details:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", indent, 0)
	details.indent = indent
	-- Fill the unused band above the rail with the shoulder and start the detail text below it.
	details.stepDrop, details.shelfClipDepth = 0, TAB_GAP
	if indent > 0 then
		local gap = plan.top - badgeHeight - bounds.tabTop
		details.stepDrop = math.max(0, math.min(gap - SHELF_TAB_CLEARANCE, height - MIN_DETAIL_HEIGHT))
		details.shelfClipDepth = math.min(TAB_GAP, gap - details.stepDrop - SHELF_CLIP_CLEARANCE)
	end
	local top = details.stepDrop + DETAIL_TOP_PADDING
	local bodyHeight = self:LayoutViewport(details, width - PADDING * 2, height - PADDING * 2 - top, top, 2, #self.entries, true)
	details:SetSize(width, bodyHeight + PADDING * 2 + top)
	details:Show()
	return true
end

function FeatureHints:LayoutBadge()
	local frame = self.frame
	if frame.layoutInProgress then return end
	frame.layoutInProgress = true
	local bounds = self:GetDockBounds()
	local plan = self:GetDockPlan(bounds)
	-- Native GetWidth can round differently from SetWidth. Use the planned width for
	-- this entire pass; never retry layout until a native measurement matches exactly.
	frame.layoutWidth = plan.width
	frame:SetWidth(plan.width)
	frame.modern = self:IsModernStyle()
	local width = plan.width - SUMMARY_PADDING * 2
	frame.title:SetText(self.options.title)
	frame.title:ClearAllPoints()
	frame.title:SetJustifyH("CENTER")
	frame.title:SetPoint("TOPLEFT", frame, "TOPLEFT", 34, -6)
	frame.icon:SetShown(frame.modern)
	local titleHeight = Measure(frame.title, plan.width - 68)
	local bodyTop = math.max(25, titleHeight + 12)
	local defaultAction = self.options.actionText or BFL.L.FEATURE_HINT_OPEN_SETTINGS
	local openWidth, openHeight = 0, 0
	for _, entry in ipairs(self.entries) do
		if HasAction(entry) then
			LayoutAction(frame.open, (entry.actionText or defaultAction) .. "  >", width)
			openWidth = math.max(openWidth, frame.open:GetWidth())
			openHeight = math.max(openHeight, frame.open:GetHeight())
		end
	end
	-- Reserve the same footer space for either toggle label.
	local moreText = string.format(BFL.L.FEATURE_HINT_MORE, #self.entries - 1)
	LayoutAction(frame.more, self.expanded and moreText or BFL.L.FEATURE_HINT_LESS, width)
	local moreWidth, moreHeight = frame.more:GetWidth(), frame.more:GetHeight()
	LayoutAction(frame.more, self.expanded and BFL.L.FEATURE_HINT_LESS or moreText, width)
	moreWidth = math.max(moreWidth, frame.more:GetWidth())
	moreHeight = #self.entries > 1 and math.max(moreHeight, frame.more:GetHeight()) or 0
	frame.more:SetShown(#self.entries > 1)
	local stacked = moreHeight > 0 and openHeight > 0 and openWidth + moreWidth + 20 > width
	local footerHeight = stacked and moreHeight + 4 + openHeight or math.max(openHeight, moreHeight)
	frame.hasFooter = footerHeight > 0
	local fixedHeight = bodyTop + (frame.hasFooter and FOOTER_GAP or 0) + footerHeight + FOOTER_PADDING
	plan = self:GetDockPlan(bounds, fixedHeight + PAGER_HEIGHT + 16)
	local maxBodyHeight = plan.maxHeight - fixedHeight
	if maxBodyHeight < 1 then
		frame.layoutInProgress = nil
		frame:Hide()
		return false
	end
	local wasPaged = frame.pager:IsShown()
	local pageOffset = wasPaged and frame.viewport:GetVerticalScroll() or 0
	local viewportHeight = self:LayoutViewport(frame, width, maxBodyHeight, bodyTop, 1, 1, false, wasPaged and 0 or nil)
	local badgeHeight = fixedHeight + viewportHeight
	local showDetails = self.expanded and self:LayoutDetails(plan, bounds, badgeHeight)
	frame.details:SetShown(showDetails == true)
	local paged = self.expanded and not showDetails
	frame.pager:SetShown(paged)
	local index = 1
	if paged then
		index = self.page
		frame.pageNumber:SetText(string.format("%d/%d", index - 1, #self.entries - 1))
		local canGoBack, canGoForward = index > 2, index < #self.entries
		frame.previous:SetEnabled(canGoBack)
		frame.previous:SetAlpha(canGoBack and 1 or 0.45)
		frame.next:SetEnabled(canGoForward)
		frame.next:SetAlpha(canGoForward and 1 or 0.45)
		-- Use the same space above the tabs and scroll long individual entries.
		local pagerHeight = math.min(PAGER_HEIGHT, math.max(1, maxBodyHeight - 16))
		frame.pager:ClearAllPoints()
		frame.pager:SetPoint("TOP", frame.content, "TOP", 0, -bodyTop)
		frame.pager:SetHeight(pagerHeight)
		bodyTop = bodyTop + pagerHeight
		local pageHeight = math.min(maxBodyHeight - pagerHeight, math.max(50, viewportHeight - pagerHeight))
		viewportHeight = self:LayoutViewport(frame, width, math.max(1, pageHeight), bodyTop, index, index, true, pageOffset)
		badgeHeight = fixedHeight + pagerHeight + viewportHeight
	end
	for rowIndex, row in ipairs(frame.rows) do
		if (paged and rowIndex ~= index) or (not self.expanded and rowIndex > 1) then row:Hide() end
	end
	local entry = self.entries[index]
	frame.open:SetShown(HasAction(entry))
	if HasAction(entry) then LayoutAction(frame.open, (entry.actionText or defaultAction) .. "  >", width) end
	local y = bodyTop + viewportHeight
	frame.divider:ClearAllPoints()
	frame.divider:SetPoint("TOPLEFT", frame.content, "TOPLEFT", SUMMARY_PADDING, -y)
	frame.divider:SetWidth(width)
	frame.modernDivider:ClearAllPoints()
	frame.modernDivider:SetPoint("TOPLEFT", frame.content, "TOPLEFT", SUMMARY_PADDING, -y)
	frame.modernDivider:SetWidth(width)
	frame.more:ClearAllPoints()
	frame.more:SetPoint("TOPLEFT", frame.content, "TOPLEFT", SUMMARY_PADDING, -y - FOOTER_GAP)
	frame.open:ClearAllPoints()
	frame.open:SetPoint("TOPRIGHT", frame.content, "TOPRIGHT", -SUMMARY_PADDING, -y - FOOTER_GAP - (stacked and frame.more:GetHeight() + 4 or 0))
	frame:SetHeight(badgeHeight)
	plan.bottom = plan.top - badgeHeight
	frame.dockPlan = plan
	frame:ClearAllPoints()
	frame:SetPoint("TOPLEFT", self.anchor, "TOPRIGHT", plan.left - bounds.parentRight, plan.top - bounds.parentTop)
	frame.layoutBounds = bounds
	self:ApplyAppearance()
	frame.layoutInProgress = nil
	return true
end

function FeatureHints:RefreshAppearance()
	if self.frame and self.entries then self:LayoutBadge() end
end

local function CreateViewport(panel, parent, name)
	local viewport = CreateFrame("ScrollFrame", name, parent)
	local bar = CreateFrame("Slider", nil, parent)
	panel.viewport, panel.scrollbar = viewport, bar
	panel.scrollContent = CreateFrame("Frame", nil, viewport)
	viewport:SetScrollChild(panel.scrollContent)
	viewport:EnableMouse(true)
	viewport:EnableMouseWheel(true)
	bar:SetOrientation("VERTICAL")
	bar:SetWidth(8)
	bar:SetPoint("TOPLEFT", viewport, "TOPRIGHT", 4, 0)
	bar:SetPoint("BOTTOMLEFT", viewport, "BOTTOMRIGHT", 4, 0)
	bar:SetThumbTexture("Interface\\Buttons\\WHITE8X8")
	bar:GetThumbTexture():SetWidth(4)
	bar.track = bar:CreateTexture(nil, "BACKGROUND")
	bar.track:SetPoint("TOP", bar, "TOP")
	bar.track:SetPoint("BOTTOM", bar, "BOTTOM")
	bar.track:SetWidth(1)
	bar:EnableMouse(true)
	bar:EnableMouseWheel(true)
	bar:SetScript("OnValueChanged", function(_, value) viewport:SetVerticalScroll(value) end)
	local function ScrollWheel(_, delta)
		bar:SetValue(viewport:GetVerticalScroll() - delta * 20)
	end
	viewport:SetScript("OnMouseWheel", ScrollWheel)
	bar:SetScript("OnMouseWheel", ScrollWheel)
	bar:Hide()
end

function FeatureHints:CreateBadge(parent)
	local frame = CreateFrame("Frame", "BFLFeatureHintFrame", parent, "ButtonFrameTemplate,BackdropTemplate")
	if ButtonFrameTemplate_HidePortrait then ButtonFrameTemplate_HidePortrait(frame) end
	if ButtonFrameTemplate_HideAttic then ButtonFrameTemplate_HideAttic(frame) end
	if frame.PortraitContainer then frame.PortraitContainer:Hide() end
	frame.nativeRegions = {}
	for _, region in ipairs({ frame:GetRegions() }) do
		if region:GetObjectType() == "Texture" and region:IsShown() then frame.nativeRegions[#frame.nativeRegions + 1] = region end
	end
	if frame.Inset then
		frame.Inset:ClearAllPoints()
		frame.Inset:SetPoint("TOPLEFT", 4, -28)
		frame.Inset:SetPoint("BOTTOMRIGHT", -4, 5)
	end
	frame:SetClampedToScreen(true)
	frame:EnableMouse(true)
	-- Native NineSlice art is a child frame, so root-layer text can render underneath it.
	-- Put the content above the shell and keep the actual native title in its title bar.
	frame.content = CreateFrame("Frame", nil, frame)
	frame.content:SetAllPoints(frame)
	frame.content:EnableMouse(false)
	CreateViewport(frame, frame.content, "BFLFeatureHintScrollFrame")
	local function Atlas(texture, atlas)
		return BFL.HasAtlas and BFL.HasAtlas(atlas) and BFL.SetTextureOrAtlas(texture, atlas, nil, false) == true or false
	end
	local function Progress(panel)
		local texture = panel:CreateTexture(nil, "OVERLAY")
		texture:SetHeight(2)
		texture:SetPoint("BOTTOMLEFT", PADDING, 8)
		return texture
	end
	-- The native background excludes the border artwork's transparent gutters.
	-- Follow those bounds in both styles; the full frame rectangle paints outside the visible shell.
	frame.bodySurface = frame:CreateTexture(nil, "BACKGROUND", nil, -7)
	frame.bodySurface:SetAllPoints(frame.Bg)
	frame.topFade = frame:CreateTexture(nil, "BACKGROUND", nil, 2)
	frame.topFade:SetPoint("TOPLEFT", frame.bodySurface, "TOPLEFT")
	frame.topFade:SetPoint("TOPRIGHT", frame.bodySurface, "TOPRIGHT")
	frame.hasTopFade = Atlas(frame.topFade, "friends-frame-toptexbg")
	frame.bottomFade = frame:CreateTexture(nil, "BACKGROUND", nil, 2)
	frame.bottomFade:SetPoint("BOTTOMLEFT", frame.bodySurface, "BOTTOMLEFT")
	frame.bottomFade:SetPoint("BOTTOMRIGHT", frame.bodySurface, "BOTTOMRIGHT")
	frame.hasBottomFade = Atlas(frame.bottomFade, "friends-frame-bottomtexbg")
	frame.details = CreateFrame("Frame", nil, frame)
	frame.details:EnableMouse(true)
	-- Paint both parts below the native border, including its inner highlights.
	frame.details.bodySurface = frame:CreateTexture(nil, "BACKGROUND", nil, -7)
	frame.details.bottomFade = frame:CreateTexture(nil, "BACKGROUND", nil, 2)
	frame.details.bottomFade:SetPoint("BOTTOMLEFT", frame.details.bodySurface, "BOTTOMLEFT")
	frame.details.bottomFade:SetPoint("BOTTOMRIGHT", frame.details.bodySurface, "BOTTOMRIGHT")
	frame.details.hasBottomFade = Atlas(frame.details.bottomFade, "friends-frame-bottomtexbg")
	frame.details.progress = Progress(frame.details)
	CreateViewport(frame.details, frame.details, "BFLFeatureHintDetailsScrollFrame")
	frame.details:Hide()
	frame.outline = CreateFrame("Frame", nil, frame)
	frame.outline:SetAllPoints(frame)
	frame.outline:EnableMouse(false)
	frame.outline.lines = {}
	for index = 1, 6 do frame.outline.lines[index] = frame.outline:CreateTexture(nil, "OVERLAY") end
	frame.modernDivider = frame.content:CreateTexture(nil, "ARTWORK")
	frame.modernDivider:SetHeight(3)
	frame.hasModernDivider = Atlas(frame.modernDivider, "perks-divider-short")
	frame.rows = {}
	frame.icon = frame.content:CreateTexture(nil, "ARTWORK")
	frame.icon:SetSize(14, 14)
	frame.icon:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -6)
	frame.icon:SetTexture(ICON_ROOT .. "info.blp")
	frame.title = (frame.TitleContainer and frame.TitleContainer.TitleText) or frame.TitleText
		or NewText(frame.content, "BetterFriendlistFontNormal")
	frame.title:SetFontObject("BetterFriendlistFontNormal")
	frame.title:SetWordWrap(true)
	frame.title:SetMaxLines(0)
	frame.title:Show()
	if frame.TitleContainer then frame.TitleContainer:Show() end
	frame.divider = frame.content:CreateTexture(nil, "ARTWORK")
	frame.divider:SetHeight(1)
	frame.progress = Progress(frame.content)
	local function Hover(button)
		button.BFL_DarkNoButtonChrome = true
		button:HookScript("OnEnter", function()
			frame.hovered = true
			frame.elapsed = math.min(frame.elapsed, math.max(0, frame.displaySeconds - 3))
			frame:SetAlpha(1)
			if button.label then button.label:SetTextColor(unpack(frame.palette.text)) end
			if button == frame.close then button.icon:SetVertexColor(unpack(frame.palette.text)) end
		end)
		button:HookScript("OnLeave", function()
			frame.hovered = false
			if button.label then
				button.label:SetTextColor(unpack(button == frame.more and frame.palette.muted or frame.palette.accent))
			end
			if button == frame.close then button.icon:SetVertexColor(unpack(frame.palette.muted)) end
		end)
	end
	Hover(frame)
	Hover(frame.viewport)
	Hover(frame.scrollbar)
	Hover(frame.details)
	Hover(frame.details.viewport)
	Hover(frame.details.scrollbar)
	frame.close = CreateFrame("Button", nil, frame.content)
	frame.close:SetSize(24, 24)
	frame.close:SetPoint("TOPRIGHT", -3, -1)
	frame.close.icon = frame.close:CreateTexture(nil, "ARTWORK")
	frame.close.icon:SetSize(12, 12)
	frame.close.icon:SetPoint("CENTER")
	frame.close.icon:SetTexture(ICON_ROOT .. "x.blp")
	frame.close:SetScript("OnClick", function() frame:Hide() end)
	Hover(frame.close)
	if frame.CloseButton then
		frame.CloseButton:SetScript("OnClick", function() frame:Hide() end)
		Hover(frame.CloseButton)
	end
	frame.open = CreateFrame("Button", nil, frame.content)
	frame.open.label = NewText(frame.open, "BetterFriendlistFontHighlightSmall")
	frame.open.label:SetPoint("LEFT")
	frame.open:SetScript("OnClick", function()
		self:OpenEntry(self.entries[frame.pager:IsShown() and self.page or 1])
	end)
	Hover(frame.open)
	frame.more = CreateFrame("Button", nil, frame.content)
	frame.more.label = NewText(frame.more, "BetterFriendlistFontHighlightSmall")
	frame.more.label:SetPoint("LEFT")
	frame.more:SetScript("OnClick", function()
		self.expanded = not self.expanded
		self.page = 2
		frame.elapsed = 0
		frame.viewport:SetVerticalScroll(0)
		frame.details.viewport:SetVerticalScroll(0)
		self:LayoutBadge()
	end)
	Hover(frame.more)
	frame.pager = CreateFrame("Frame", nil, frame.content)
	frame.pager:SetWidth(108)
	frame.pageNumber = NewText(frame.pager, "BetterFriendlistFontHighlightSmall")
	frame.pageNumber:SetPoint("CENTER")
	local function PageButton(label, direction, point)
		local button = CreateFrame("Button", nil, frame.pager)
		button:SetWidth(28)
		button:SetPoint("TOP" .. point)
		button:SetPoint("BOTTOM" .. point)
		button.label = NewText(button, "BetterFriendlistFontNormal")
		button.label:SetPoint("CENTER")
		button.label:SetText(label)
		button:SetScript("OnClick", function()
			self.page = math.max(2, math.min(#self.entries, self.page + direction))
			frame.elapsed = 0
			frame.viewport:SetVerticalScroll(0)
			self:LayoutBadge()
		end)
		Hover(button)
		return button
	end
	frame.previous, frame.next = PageButton("‹", -1, "LEFT"), PageButton("›", 1, "RIGHT")
	frame.pager:Hide()
	frame:SetScript("OnUpdate", function(owner, elapsed)
		owner.layoutElapsed = (owner.layoutElapsed or 0) + elapsed
		if owner.layoutElapsed >= 0.25 then
			owner.layoutElapsed = 0
			local bounds = self:GetDockBounds()
			for _, key in ipairs({ "left", "right", "top", "bottom", "parentTop", "parentRight", "scale", "tabLeft", "tabRight", "tabTop" }) do
				local previous, current = owner.layoutBounds and owner.layoutBounds[key], bounds[key]
				if previous ~= current and (not previous or not current or math.abs(previous - current) > 0.001) then
					self:LayoutBadge()
					break
				end
			end
		end
		if owner.hovered then return end
		owner.elapsed = owner.elapsed + elapsed
		owner.activeProgress:SetWidth(math.max(1, owner.progressWidth * (1 - math.min(1, owner.elapsed / owner.displaySeconds))))
		if owner.elapsed >= owner.displaySeconds + FADE_SECONDS then owner:Hide()
		elseif owner.elapsed > owner.displaySeconds then owner:SetAlpha(1 - (owner.elapsed - owner.displaySeconds) / FADE_SECONDS) end
	end)
	self.frame = frame
	return frame, Hover
end

function FeatureHints:CreateEntry(index)
	local frame = self.frame
	local row = CreateFrame("Button", nil, frame.scrollContent)
	row.BFL_DarkInvisibleOverlayButton = true
	row.heading = NewText(row, "BetterFriendlistFontHighlightSmall")
	row.heading:SetPoint("TOPLEFT", 0, -4)
	row.description = NewText(row, "BetterFriendlistFontHighlightSmall")
	row.path = NewText(row, "BetterFriendlistFontHighlightSmall")
	row:SetScript("OnClick", function() self:OpenEntry(self.entries[index]) end)
	self.hover(row)
	frame.rows[index] = row
	return row
end

-- Show{ id, title, entries, icon?, duration?, anchor?, actionText?, oncePerSession?, replace? }.
-- Entries contain localized label/text/path and page/control/category or an onClick callback.
-- Stable IDs isolate session limits per feature. Defaults: once per session, 18 seconds,
-- info icon, docked to the visible friends window (otherwise UIParent).
-- The first entry supplies the footer action; further entries are expandable and clickable.
-- Entries without a destination are informational. Settings links resolve the active settings UI on click.
-- A busy card is left alone unless replace=true; previews use oncePerSession=false.
function FeatureHints:Show(options)
	if type(options) ~= "table" or type(options.id) ~= "string" or options.id == ""
		or type(options.title) ~= "string" or type(options.entries) ~= "table" or #options.entries == 0 then return false end
	local once = options.oncePerSession ~= false
	if once and self.shown and self.shown[options.id] then return false end
	if self:IsShown() and not options.replace then return false end
	for _, entry in ipairs(options.entries) do
		if type(entry) ~= "table" or type(entry.text) ~= "string"
			or (entry.actionText ~= nil and type(entry.actionText) ~= "string")
			or (entry.onClick ~= nil and type(entry.onClick) ~= "function") then return false end
	end
	local friendsFrame = _G.BetterFriendsFrame
	local parent = options.anchor or (friendsFrame and friendsFrame:IsShown() and friendsFrame) or _G.UIParent
	if not parent or not parent:IsShown() then return false end
	local entries = options.entries
	if not self.frame then self.frame, self.hover = self:CreateBadge(parent) end
	local frame = self.frame
	frame.elapsed, frame.hovered = 0, false
	frame.displaySeconds = math.max(1, tonumber(options.duration) or DISPLAY_SECONDS)
	self.options, self.id = options, options.id
	self.anchor, self.entries, self.expanded, self.page = parent, entries, false, 2
	frame:SetParent(parent)
	frame.viewport:SetVerticalScroll(0)
	frame.details.viewport:SetVerticalScroll(0)
	frame.icon:SetTexture(options.icon or (ICON_ROOT .. "info.blp"))
	self.hookedAnchors = self.hookedAnchors or {}
	if parent ~= UIParent and not self.hookedAnchors[parent] then
		self.hookedAnchors[parent] = true
		parent:HookScript("OnHide", function() if self.anchor == parent then frame:Hide() end end)
	end
	frame:SetFrameLevel(parent:GetFrameLevel() + 10)
	for index in ipairs(entries) do if not frame.rows[index] then self:CreateEntry(index) end end
	for index = #entries + 1, #frame.rows do frame.rows[index]:Hide() end
	if not self:LayoutBadge() then return false end
	frame.activeProgress:SetWidth(frame.progressWidth)
	frame:SetAlpha(1)
	frame:Show()
	if once then
		self.shown = self.shown or {}
		self.shown[options.id] = true
	end
	return true
end

function FeatureHints:IsShown(id)
	return self.frame ~= nil and self.frame:IsShown() and (id == nil or self.id == id)
end

function FeatureHints:Hide(id)
	if self:IsShown(id) then self.frame:Hide() end
end
