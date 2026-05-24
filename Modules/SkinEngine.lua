-- Modules/SkinEngine.lua
-- Reversible BFL skinning primitives used by the Dark theme

local ADDON_NAME, BFL = ...
local SkinEngine = BFL:RegisterModule("SkinEngine", {})

local BACKDROP = {
	bgFile = "Interface\\Buttons\\WHITE8X8",
	edgeFile = "Interface\\Buttons\\WHITE8X8",
	tile = false,
	edgeSize = 1,
	insets = { left = 1, right = 1, top = 1, bottom = 1 },
}

local DARK_SCROLLBAR_WIDTH = 22
local DARK_SCROLLBAR_STEPPER_HEIGHT = 16
local DARK_SCROLLBAR_STEPPER_TOP_OFFSET_Y = -2
local DARK_SCROLLBAR_STEPPER_BOTTOM_OFFSET_Y = 2
local ZERO_INSETS = { left = 0, right = 0, top = 0, bottom = 0 }
local BUTTON_INSETS = { left = 1, right = 1, top = -1, bottom = -1 }
local SCROLLBAR_TRACK_INSETS = { left = 1, right = 1, top = 0, bottom = 0 }
local ARROW_BUTTON_INSETS = { left = 3, right = 3, top = -3, bottom = 3 }
local SLIDER_STEPPER_INSETS = { left = 2, right = 2, top = 0, bottom = 0 }
local TAB_BUTTON_OPTS = { variant = "tab", insets = ZERO_INSETS }
local NAV_BUTTON_OPTS = { variant = "nav", keepFontColor = true, insets = ZERO_INSETS }

local function ApplyDefaultSlugToFontString(fontString)
	if BFL.FontManager and BFL.FontManager.ApplyDefaultSlugToFontString then
		BFL.FontManager:ApplyDefaultSlugToFontString(fontString)
	end
end

local COLORS = {
	panel = { 0.000, 0.000, 0.000, 0.68 },
	popup = { 0.000, 0.000, 0.000, 0.78 },
	panelSoft = { 0.030, 0.030, 0.034, 0.42 },
	tab = { 0.000, 0.000, 0.000, 0.68 },
	tabHover = { 0.000, 0.000, 0.000, 0.74 },
	control = { 0.055, 0.055, 0.060, 0.42 },
	controlHover = { 0.135, 0.135, 0.145, 0.50 },
	controlDown = { 0.000, 0.000, 0.000, 0.62 },
	controlDisabled = { 0.020, 0.020, 0.024, 0.30 },
	inset = { 0.000, 0.000, 0.000, 0.42 },
	scrollTrack = { 0.000, 0.000, 0.000, 0.50 },
	sliderTrack = { 0.000, 0.000, 0.000, 0.46 },
	sliderThumb = { 1.0, 0.82, 0.0, 0.92 },
	scrollThumb = { 0.42, 0.42, 0.44, 0.78 },
	scrollThumbHover = { 0.62, 0.62, 0.64, 0.90 },
	scrollThumbDown = { 1.0, 0.82, 0.0, 0.86 },
	row = { 0.000, 0.000, 0.000, 0.00 },
	rowHover = { 1.0, 0.82, 0.0, 0.10 },
	rowDown = { 1.0, 0.82, 0.0, 0.14 },
	border = { 0.34, 0.34, 0.36, 0.82 },
	borderSoft = { 0.22, 0.22, 0.24, 0.58 },
	borderMuted = { 0.13, 0.13, 0.14, 0.38 },
	controlBorder = { 0.32, 0.32, 0.34, 0.80 },
	controlBorderHover = { 1.0, 0.82, 0.0, 0.52 },
	controlBorderDisabled = { 0.10, 0.10, 0.11, 0.32 },
	divider = { 0.24, 0.24, 0.26, 0.40 },
	topLine = { 1.0, 1.0, 1.0, 0.055 },
	controlTopLine = { 1.0, 1.0, 1.0, 0.075 },
	bottomShadow = { 0, 0, 0, 0.55 },
	borderNone = { 0, 0, 0, 0 },
	icon = { 1.0, 0.82, 0.0, 0.90 },
	iconHover = { 1.0, 1.0, 0.72, 1 },
	iconDown = { 1.0, 0.68, 0.0, 1 },
	close = { 0.95, 0.22, 0.18, 1 },
	closeHover = { 1.0, 0.38, 0.32, 1 },
	closeDown = { 0.78, 0.12, 0.10, 1 },
	accent = { 1.0, 0.82, 0.0, 0.62 },
	accentSoft = { 1.0, 0.82, 0.0, 0.22 },
	accentState = { 1.0, 0.82, 0.0, 0.14 },
	gold = { 1.0, 0.82, 0.0, 0.9 },
	disabledText = { 0.45, 0.45, 0.46, 0.85 },
}

local ICONS = {
	close = "Interface\\AddOns\\BetterFriendlist\\Icons\\x.blp",
	down = "Interface\\AddOns\\BetterFriendlist\\Icons\\chevron-down.blp",
	up = "Interface\\AddOns\\BetterFriendlist\\Icons\\chevron-up.blp",
	left = "Interface\\AddOns\\BetterFriendlist\\Icons\\chevron-left.blp",
	right = "Interface\\AddOns\\BetterFriendlist\\Icons\\chevron-right.blp",
}

local DECOR_KEYS = {
	"NineSlice",
	"Border",
	"BorderFrame",
	"Bg",
	"BG",
	"bgLeft",
	"bgRight",
	"Background",
	"Backdrop",
	"DividerTexture",
	"HeaderDivider",
	"TopTileStreaks",
	"ArtOverlayFrame",
	"FilligreeOverlay",
	"PortraitOverlay",
	"PortraitContainer",
	"Portrait",
	"portrait",
	"PortraitIcon",
	"PortraitMask",
	"ScrollFrameBorder",
	"TopLeftCorner",
	"TopRightCorner",
	"BottomLeftCorner",
	"BottomRightCorner",
	"TopBorder",
	"BottomBorder",
	"LeftBorder",
	"RightBorder",
	"TopEdge",
	"BottomEdge",
	"LeftEdge",
	"RightEdge",
	"Center",
	"Left",
	"Middle",
	"Right",
	"Top",
	"Bottom",
	"Bracket_TopLeft",
	"Bracket_TopRight",
	"Bracket_BottomLeft",
	"Bracket_BottomRight",
	"PictureFrame",
	"Watermark",
}

local BUTTON_TEXTURE_KEYS = {
	"Left",
	"Middle",
	"Right",
	"LeftDisabled",
	"MiddleDisabled",
	"RightDisabled",
	"TopLeft",
	"TopMiddle",
	"TopRight",
	"MiddleLeft",
	"MiddleMiddle",
	"MiddleRight",
	"BottomLeft",
	"BottomMiddle",
	"BottomRight",
	"NormalTexture",
	"PushedTexture",
	"DisabledTexture",
	"HighlightTexture",
	"Flash",
	"Border",
	"BorderFrame",
	"NineSlice",
}

local NINE_SLICE_KEYS = {
	"TopLeftCorner",
	"TopRightCorner",
	"BottomLeftCorner",
	"BottomRightCorner",
	"TopEdge",
	"BottomEdge",
	"LeftEdge",
	"RightEdge",
	"Center",
}

SkinEngine.colors = COLORS
SkinEngine.registry = {}

local function IsForbidden(frame)
	return frame and frame.IsForbidden and frame:IsForbidden()
end

local function GetObjectType(frame)
	if not frame or not frame.GetObjectType then
		return nil
	end
	return frame:GetObjectType()
end

local function IsObjectType(frame, objectType)
	return frame and frame.IsObjectType and frame:IsObjectType(objectType)
end

local function GetName(frame)
	return (frame and frame.GetName and frame:GetName()) or ""
end

local function LowerName(frame)
	return string.lower(GetName(frame) or "")
end

local function TextureMatches(texture, pattern)
	if not texture then
		return false
	end

	local atlas = texture.GetAtlas and texture:GetAtlas()
	if type(atlas) == "string" and atlas:lower():find(pattern) then
		return true
	end

	local file = texture.GetTexture and texture:GetTexture()
	if type(file) == "string" and file:lower():find(pattern) then
		return true
	end

	return false
end

local function IsTravelPassButton(button)
	if not button or not IsObjectType(button, "Button") then
		return false
	end

	local parent = button.GetParent and button:GetParent()
	if parent and (parent.travelPassButton == button or parent.PartyButton == button) then
		return true
	end

	local lowerName = LowerName(button)
	if lowerName:find("travelpass") then
		return true
	end

	local normal = button.NormalTexture or (button.GetNormalTexture and button:GetNormalTexture())
	return TextureMatches(normal, "friendslist%-invitebutton") or TextureMatches(normal, "travelpass%-invite")
end

local function IsRAFNativeRewardButton(button)
	if not button or not IsObjectType(button, "Button") then
		return false
	end

	local parent = button.GetParent and button:GetParent()
	return parent and (parent.NextRewardInfoButton == button or parent.NextRewardButton == button)
end

local function IsRAFActivityButton(button)
	if not button or not IsObjectType(button, "Button") then
		return false
	end

	local parent = button.GetParent and button:GetParent()
	local activities = parent and parent.Activities
	if not activities then
		return false
	end

	for i = 1, #activities do
		if activities[i] == button then
			return true
		end
	end

	return false
end

local function IsRAFNativeTextureButton(button)
	return IsRAFNativeRewardButton(button) or IsRAFActivityButton(button)
end

local function IsButtonChromeSuppressed(button)
	if not button or not IsObjectType(button, "Button") then
		return false
	end

	if button.BFL_DarkNoButtonChrome or button.BFL_DarkInvisibleOverlayButton then
		return true
	end

	local parent = button.GetParent and button:GetParent()
	return parent
		and (
			parent.gameIconOverlay == button
			or (IsObjectType(parent, "EditBox") and (parent.clearButton == button or parent.ClearButton == button))
		)
end

local function UnpackColor(color)
	return color[1], color[2], color[3], color[4]
end

local function SameColor(left, right)
	if left == right then
		return true
	end
	return left
		and right
		and left[1] == right[1]
		and left[2] == right[2]
		and left[3] == right[3]
		and left[4] == right[4]
end

local function SetBackdropStoredColors(backdrop, bgColor, borderColor)
	if not backdrop then
		return
	end
	backdrop.BFL_DarkBaseColor = bgColor
	backdrop.BFL_DarkBorderColor = borderColor
end

local function NormalizeFramePoint(point)
	if not point or not point[1] then
		return nil
	end

	local relativeTo = point[2]
	if not relativeTo then
		return point[1], nil, nil, point[4] or 0, point[5] or 0
	end

	return point[1], relativeTo, point[3], point[4] or 0, point[5] or 0
end

local function FramePointsMatch(frame, points)
	if not frame or not frame.GetNumPoints or not frame.GetPoint then
		return false
	end

	points = points or {}
	if frame:GetNumPoints() ~= #points then
		return false
	end

	for i, point in ipairs(points) do
		local targetPoint, targetRelativeTo, targetRelativePoint, targetX, targetY = NormalizeFramePoint(point)
		if not targetPoint then
			return false
		end
		local currentPoint, currentRelativeTo, currentRelativePoint, currentX, currentY = frame:GetPoint(i)
		if
			currentPoint ~= targetPoint
			or currentRelativeTo ~= targetRelativeTo
			or currentRelativePoint ~= targetRelativePoint
			or (currentX or 0) ~= targetX
			or (currentY or 0) ~= targetY
		then
			return false
		end
	end

	return true
end

local function IsControlEnabled(frame)
	if not frame then
		return true
	end

	if frame.IsEnabled then
		local enabled = frame:IsEnabled()
		if enabled == false or enabled == nil or enabled == 0 then
			return false
		end
	end

	return true
end

local function GetCachedTextureRegions(frame)
	if not frame or not frame.GetRegions then
		return nil
	end

	local regionCount = frame.GetNumRegions and frame:GetNumRegions() or nil
	local cached = frame.BFL_DarkTextureRegions
	if cached and (not regionCount or frame.BFL_DarkTextureRegionCount == regionCount) then
		return cached
	end

	local regions = { frame:GetRegions() }
	local textures = {}
	for _, region in ipairs(regions) do
		if region and region.SetAlpha and GetObjectType(region) == "Texture" then
			textures[#textures + 1] = region
		end
	end

	frame.BFL_DarkTextureRegions = textures
	frame.BFL_DarkTextureRegionCount = regionCount or #regions
	return textures
end

local function GetCachedChildFrames(frame)
	if not frame or not frame.GetChildren then
		return nil
	end

	local childCount = frame.GetNumChildren and frame:GetNumChildren() or nil
	local cached = frame.BFL_DarkChildFrames
	if cached and (not childCount or frame.BFL_DarkChildFrameCount == childCount) then
		return cached
	end

	local children = { frame:GetChildren() }
	frame.BFL_DarkChildFrames = children
	frame.BFL_DarkChildFrameCount = childCount or #children
	return children
end

local function IsScrollBarFrame(frame)
	if not frame or IsForbidden(frame) then
		return false
	end

	local lowerName = LowerName(frame)
	if lowerName:find("scrollbar") then
		return true
	end

	if frame.Back and frame.Forward and frame.Track then
		return true
	end
	if frame.ScrollUpButton or frame.ScrollDownButton then
		return true
	end

	local parent = frame.GetParent and frame:GetParent()
	return parent
		and (parent.ScrollBar == frame or parent.ClassicScrollBar == frame or parent.MinimalScrollBar == frame)
end

local function SetOverlayAlpha(owner, overlay, alpha)
	if overlay and overlay.SetAlpha then
		SkinEngine:SetTextureAlpha(owner, overlay, alpha)
	end
end

local function SetButtonOverlayAlpha(button, alpha)
	if not button then
		return
	end

	SetOverlayAlpha(button, button.BFL_DarkArrowIcon, alpha)
	SetOverlayAlpha(button, button.BFL_DarkIcon, alpha)
	SetOverlayAlpha(button, button.Icon, alpha)
	SetOverlayAlpha(button, button.icon, alpha)
	local dropdown = button.BFL_DarkDropdownIndicator
	if dropdown then
		SetOverlayAlpha(button, dropdown.Icon, alpha)
	end
end

local function SetOverlayColor(owner, overlay, color)
	if overlay and overlay.SetVertexColor then
		SkinEngine:SetTextureVertexColor(owner, overlay, UnpackColor(color))
	end
end

local function SetButtonIconColor(button, color)
	if not button or not color then
		return
	end

	SetOverlayColor(button, button.BFL_DarkArrowIcon, color)
	SetOverlayColor(button, button.BFL_DarkIcon, color)
	SetOverlayColor(button, button.Icon, color)
	SetOverlayColor(button, button.icon, color)
end

local function SetOverlayBlendMode(owner, overlay, blendMode)
	if overlay and overlay.SetBlendMode then
		SkinEngine:SetTextureBlendMode(owner, overlay, blendMode or "BLEND")
	end
end

local function SetButtonIconBlendMode(button, blendMode)
	if not button then
		return
	end

	SetOverlayBlendMode(button, button.BFL_DarkArrowIcon, blendMode)
	SetOverlayBlendMode(button, button.BFL_DarkIcon, blendMode)
	SetOverlayBlendMode(button, button.Icon, blendMode)
	SetOverlayBlendMode(button, button.icon, blendMode)
end

local function SetButtonHoverIcon(button, alpha, color)
	local hoverIcon = button and button.BFL_DarkHoverIcon
	if not hoverIcon then
		return
	end

	if color and hoverIcon.SetVertexColor then
		SkinEngine:SetTextureVertexColor(button, hoverIcon, UnpackColor(color))
	end
	if hoverIcon.SetAlpha then
		SkinEngine:SetTextureAlpha(button, hoverIcon, alpha or 0)
	end
	if alpha and alpha > 0 then
		hoverIcon:Show()
	else
		hoverIcon:Hide()
	end
end

local function SetBackdropColors(backdrop, bgColor, borderColor)
	if not backdrop or not backdrop.SetBackdropColor then
		return
	end

	borderColor = borderColor or COLORS.borderNone
	if SameColor(backdrop.BFL_DarkAppliedBgColor, bgColor) and SameColor(backdrop.BFL_DarkAppliedBorderColor, borderColor) then
		SetBackdropStoredColors(backdrop, bgColor, borderColor)
		return
	end

	backdrop:SetBackdropColor(UnpackColor(bgColor))
	backdrop:SetBackdropBorderColor(UnpackColor(borderColor))
	backdrop.BFL_DarkAppliedBgColor = bgColor
	backdrop.BFL_DarkAppliedBorderColor = borderColor
	SetBackdropStoredColors(backdrop, bgColor, borderColor)
end

local function ConfigureBackdropLine(backdrop, key, point, color)
	if not backdrop or not backdrop.CreateTexture then
		return
	end

	local line = backdrop[key]
	if not color or (color[4] or 0) <= 0 then
		if line then
			line:Hide()
		end
		return
	end

	if not line then
		line = backdrop:CreateTexture(nil, "BORDER")
		backdrop[key] = line
	end

	line:ClearAllPoints()
	if point == "TOP" then
		line:SetPoint("TOPLEFT", backdrop, "TOPLEFT", 1, -1)
		line:SetPoint("TOPRIGHT", backdrop, "TOPRIGHT", -1, -1)
	else
		line:SetPoint("BOTTOMLEFT", backdrop, "BOTTOMLEFT", 1, 1)
		line:SetPoint("BOTTOMRIGHT", backdrop, "BOTTOMRIGHT", -1, 1)
	end
	line:SetHeight(1)
	line:SetColorTexture(UnpackColor(color))
	line:Show()
end

local function ApplyBackdropLines(backdrop, variant)
	local topColor
	local bottomColor

	if variant == "main" or variant == "popup" then
		topColor = COLORS.topLine
		bottomColor = COLORS.bottomShadow
	elseif
		variant == "control"
		or variant == "button"
		or variant == "dropdown"
		or variant == "editbox"
		or variant == "nav"
		or variant == "tab"
	then
		topColor = COLORS.controlTopLine
		bottomColor = COLORS.bottomShadow
	elseif variant == "inset" or variant == "slider" then
		topColor = COLORS.topLine
	elseif variant == "row" then
		bottomColor = COLORS.divider
	elseif variant == "thumb" then
		topColor = COLORS.topLine
	end

	ConfigureBackdropLine(backdrop, "BFL_DarkTopLine", "TOP", topColor)
	ConfigureBackdropLine(backdrop, "BFL_DarkBottomLine", "BOTTOM", bottomColor)
end

function SkinEngine:IsActive()
	return self.active == true and self.activeTheme == "dark"
end

function SkinEngine:Activate()
	self.active = true
	self.activeTheme = "dark"
end

function SkinEngine:Deactivate()
	if self.active ~= true and not next(self.registry) then
		self.activeTheme = nil
		return
	end

	self.active = false
	self.activeTheme = nil
	self:RestoreAll()
end

function SkinEngine:GetState(frame)
	if not frame then
		return nil
	end
	local state = frame.BFL_DarkSkin
	if not state then
		state = {
			textureAlpha = {},
			textureVertexColors = {},
			textureBlendModes = {},
			fontColors = {},
			fontJustify = {},
			regionPoints = {},
			regionSizes = {},
			shown = {},
			backdrops = {},
			overlays = {},
		}
		frame.BFL_DarkSkin = state
	else
		state.textureAlpha = state.textureAlpha or {}
		state.textureVertexColors = state.textureVertexColors or {}
		state.textureBlendModes = state.textureBlendModes or {}
		state.fontColors = state.fontColors or {}
		state.fontJustify = state.fontJustify or {}
		state.regionPoints = state.regionPoints or {}
		state.regionSizes = state.regionSizes or {}
		state.shown = state.shown or {}
		state.backdrops = state.backdrops or {}
		state.overlays = state.overlays or {}
	end
	self.registry[frame] = true
	return state
end

local function ApplyStoredPoint(frame, point)
	if not frame or not point or not point[1] then
		return
	end

	if point[2] then
		frame:SetPoint(point[1], point[2], point[3], point[4] or 0, point[5] or 0)
	elseif point[4] ~= nil or point[5] ~= nil then
		frame:SetPoint(point[1], point[4] or 0, point[5] or 0)
	else
		frame:SetPoint(point[1])
	end
end

function SkinEngine:RememberFramePoints(frame)
	if not frame or IsForbidden(frame) or not frame.GetNumPoints or not frame.GetPoint then
		return
	end

	local state = self:GetState(frame)
	if not state or state.points then
		return
	end

	state.points = {}
	for i = 1, frame:GetNumPoints() do
		state.points[i] = { frame:GetPoint(i) }
	end
end

function SkinEngine:SetFramePoints(frame, points)
	if not self:IsActive() or not frame or IsForbidden(frame) or not frame.ClearAllPoints or not frame.SetPoint then
		return
	end

	if FramePointsMatch(frame, points) then
		return
	end

	self:RememberFramePoints(frame)
	frame:ClearAllPoints()
	for _, point in ipairs(points or {}) do
		ApplyStoredPoint(frame, point)
	end
end

function SkinEngine:RememberFrameSize(frame)
	if not frame or IsForbidden(frame) or not frame.GetSize then
		return
	end

	local state = self:GetState(frame)
	if not state or state.size then
		return
	end

	local width, height = frame:GetSize()
	state.size = { width, height }
end

function SkinEngine:SetFrameSize(frame, width, height)
	if not self:IsActive() or not frame or IsForbidden(frame) then
		return
	end

	if width and height and frame.GetSize then
		local currentWidth, currentHeight = frame:GetSize()
		if currentWidth == width and currentHeight == height then
			return
		end
	elseif width and frame.GetWidth and frame:GetWidth() == width then
		return
	elseif height and frame.GetHeight and frame:GetHeight() == height then
		return
	end

	self:RememberFrameSize(frame)
	if width and height and frame.SetSize then
		frame:SetSize(width, height)
	elseif width and frame.SetWidth then
		frame:SetWidth(width)
	elseif height and frame.SetHeight then
		frame:SetHeight(height)
	end
end

function SkinEngine:RememberTextureAlpha(frame, texture)
	if not texture or not texture.SetAlpha then
		return
	end

	local state = self:GetState(frame)
	if state and state.textureAlpha[texture] == nil then
		state.textureAlpha[texture] = texture.GetAlpha and texture:GetAlpha() or 1
	end
end

function SkinEngine:SetTextureAlpha(frame, texture, alpha)
	if not texture or not texture.SetAlpha then
		return
	end
	if texture.GetAlpha and texture:GetAlpha() == alpha then
		return
	end
	self:RememberTextureAlpha(frame, texture)
	texture:SetAlpha(alpha)
end

function SkinEngine:RememberTextureVertexColor(frame, texture)
	if not texture or not texture.SetVertexColor then
		return
	end

	local state = self:GetState(frame)
	if state and not state.textureVertexColors[texture] then
		local r, g, b, a = 1, 1, 1, 1
		if texture.GetVertexColor then
			r, g, b, a = texture:GetVertexColor()
		end
		state.textureVertexColors[texture] = { r or 1, g or 1, b or 1, a or 1 }
	end
end

function SkinEngine:SetTextureVertexColor(frame, texture, r, g, b, a)
	if not texture or not texture.SetVertexColor then
		return
	end

	if texture.GetVertexColor then
		local currentR, currentG, currentB, currentA = texture:GetVertexColor()
		if currentR == (r or 1) and currentG == (g or 1) and currentB == (b or 1) and currentA == (a or 1) then
			return
		end
	end
	self:RememberTextureVertexColor(frame, texture)
	texture:SetVertexColor(r or 1, g or 1, b or 1, a or 1)
end

function SkinEngine:RememberTextureBlendMode(frame, texture)
	if not texture or not texture.SetBlendMode then
		return
	end

	local state = self:GetState(frame)
	if state and not state.textureBlendModes[texture] then
		local blendMode = "BLEND"
		if texture.GetBlendMode then
			blendMode = texture:GetBlendMode() or blendMode
		end
		state.textureBlendModes[texture] = blendMode
	end
end

function SkinEngine:SetTextureBlendMode(frame, texture, blendMode)
	if not texture or not texture.SetBlendMode then
		return
	end

	blendMode = blendMode or "BLEND"
	if texture.GetBlendMode and texture:GetBlendMode() == blendMode then
		return
	end
	self:RememberTextureBlendMode(frame, texture)
	texture:SetBlendMode(blendMode)
end

function SkinEngine:RememberRegionPoints(frame, region)
	if not region or not region.GetNumPoints or not region.GetPoint then
		return
	end

	local state = self:GetState(frame)
	if not state or state.regionPoints[region] then
		return
	end

	state.regionPoints[region] = {}
	for i = 1, region:GetNumPoints() do
		state.regionPoints[region][i] = { region:GetPoint(i) }
	end
end

function SkinEngine:SetRegionPoints(frame, region, points)
	if not region or not region.ClearAllPoints or not region.SetPoint then
		return
	end

	self:RememberRegionPoints(frame, region)
	region:ClearAllPoints()
	for _, point in ipairs(points or {}) do
		ApplyStoredPoint(region, point)
	end
end

function SkinEngine:RememberRegionSize(frame, region)
	if not region or not region.GetSize then
		return
	end

	local state = self:GetState(frame)
	if state and not state.regionSizes[region] then
		local width, height = region:GetSize()
		state.regionSizes[region] = { width, height }
	end
end

function SkinEngine:SetRegionSize(frame, region, width, height)
	if not region then
		return
	end

	if width and height and region.GetSize then
		local currentWidth, currentHeight = region:GetSize()
		if currentWidth == width and currentHeight == height then
			return
		end
	elseif width and region.GetWidth and region:GetWidth() == width then
		return
	elseif height and region.GetHeight and region:GetHeight() == height then
		return
	end

	self:RememberRegionSize(frame, region)
	if width and height and region.SetSize then
		region:SetSize(width, height)
	elseif width and region.SetWidth then
		region:SetWidth(width)
	elseif height and region.SetHeight then
		region:SetHeight(height)
	end
end

function SkinEngine:RememberShown(frame, object)
	if not object or not object.IsShown then
		return
	end

	local state = self:GetState(frame)
	if state and state.shown[object] == nil then
		state.shown[object] = object:IsShown() == true
	end
end

function SkinEngine:SetObjectShown(frame, object, shown)
	if not object then
		return
	end

	self:RememberShown(frame, object)
	if object.SetShown then
		object:SetShown(shown == true)
	elseif shown and object.Show then
		object:Show()
	elseif not shown and object.Hide then
		object:Hide()
	end
end

function SkinEngine:ClearTextureObject(owner, texture, alpha)
	if not texture then
		return
	end

	local objectType = GetObjectType(texture)
	if objectType == "Texture" or objectType == "MaskTexture" then
		self:SetTextureAlpha(owner, texture, alpha or 0)
	elseif texture.GetRegions or texture.GetChildren then
		self:DampenFrameTextures(texture, alpha or 0, 2)
	elseif texture.SetAlpha then
		self:SetTextureAlpha(owner, texture, alpha or 0)
	end
end

function SkinEngine:RegisterOverlay(frame, overlay)
	if not frame or not overlay then
		return
	end

	local state = self:GetState(frame)
	if state then
		state.overlays[overlay] = true
	end
end

function SkinEngine:RememberFontColor(frame, fontString)
	if not fontString or not fontString.GetTextColor or not fontString.SetTextColor then
		return
	end

	local state = self:GetState(frame)
	if state and not state.fontColors[fontString] then
		local r, g, b, a = fontString:GetTextColor()
		state.fontColors[fontString] = { r, g, b, a }
	end
end

function SkinEngine:SetFontColor(frame, fontString, r, g, b, a)
	if not fontString or not fontString.SetTextColor then
		return
	end
	if fontString.GetTextColor then
		local currentR, currentG, currentB, currentA = fontString:GetTextColor()
		if currentR == r and currentG == g and currentB == b and currentA == (a or 1) then
			return
		end
	end
	self:RememberFontColor(frame, fontString)
	fontString:SetTextColor(r, g, b, a or 1)
end

function SkinEngine:RememberFontJustify(frame, fontString)
	if not fontString or (not fontString.GetJustifyH and not fontString.GetJustifyV) then
		return
	end

	local state = self:GetState(frame)
	if state and not state.fontJustify[fontString] then
		state.fontJustify[fontString] = {
			fontString.GetJustifyH and fontString:GetJustifyH() or nil,
			fontString.GetJustifyV and fontString:GetJustifyV() or nil,
		}
	end
end

function SkinEngine:SetFontJustify(frame, fontString, justifyH, justifyV)
	if not fontString then
		return
	end

	self:RememberFontJustify(frame, fontString)
	if justifyH and fontString.SetJustifyH then
		fontString:SetJustifyH(justifyH)
	end
	if justifyV and fontString.SetJustifyV then
		fontString:SetJustifyV(justifyV)
	end
end

local function ResolveBackdropColors(variant)
	local bg = COLORS.panelSoft
	local border = COLORS.borderMuted
	if variant == "main" then
		bg = COLORS.panel
		border = COLORS.border
	elseif variant == "popup" then
		bg = COLORS.popup
		border = COLORS.border
	elseif variant == "inset" then
		bg = COLORS.inset
		border = COLORS.borderSoft
	elseif variant == "slider" then
		bg = COLORS.sliderTrack
		border = COLORS.borderMuted
	elseif variant == "scrollbar" then
		bg = COLORS.scrollTrack
		border = COLORS.borderMuted
	elseif variant == "tab" then
		bg = COLORS.tab
		border = COLORS.borderMuted
	elseif variant == "control" or variant == "button" or variant == "dropdown" or variant == "editbox" or variant == "nav" then
		bg = COLORS.control
		border = COLORS.controlBorder
	elseif variant == "nativeButton" then
		bg = COLORS.borderNone
		border = COLORS.borderSoft
	elseif variant == "icon" then
		bg = COLORS.borderNone
		border = COLORS.borderNone
	elseif variant == "thumb" then
		bg = COLORS.scrollThumb
		border = COLORS.borderNone
	elseif variant == "row" then
		bg = COLORS.row
		border = COLORS.borderNone
	end

	return bg, border
end

function SkinEngine:CreateBackdrop(frame, variant, insets)
	if not frame or IsForbidden(frame) or not CreateFrame then
		return nil
	end

	variant = variant or "panel"
	insets = insets or ZERO_INSETS
	local state = self:GetState(frame)
	local backdrop = frame.BFL_DarkBackdrop
	if not backdrop then
		local template = BackdropTemplateMixin and "BackdropTemplate" or nil
		backdrop = CreateFrame("Frame", nil, frame, template)
		backdrop:SetFrameLevel(math.max((frame:GetFrameLevel() or 1) - 1, 0))
		if backdrop.SetBackdrop then
			backdrop:SetBackdrop(BACKDROP)
		else
			backdrop.bg = backdrop:CreateTexture(nil, "BACKGROUND")
			backdrop.bg:SetAllPoints()
		end
		frame.BFL_DarkBackdrop = backdrop
		state.backdrops[backdrop] = true
	end

	local left = insets.left or 0
	local right = insets.right or 0
	local top = insets.top or 0
	local bottom = insets.bottom or 0
	if
		backdrop.BFL_DarkInsetLeft ~= left
		or backdrop.BFL_DarkInsetRight ~= right
		or backdrop.BFL_DarkInsetTop ~= top
		or backdrop.BFL_DarkInsetBottom ~= bottom
	then
		backdrop.BFL_DarkInsetLeft = left
		backdrop.BFL_DarkInsetRight = right
		backdrop.BFL_DarkInsetTop = top
		backdrop.BFL_DarkInsetBottom = bottom
		backdrop:ClearAllPoints()
		backdrop:SetPoint("TOPLEFT", frame, "TOPLEFT", left, top)
		backdrop:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -right, -bottom)
	end

	local bg, border = ResolveBackdropColors(variant)

	if backdrop.SetBackdropColor then
		SetBackdropColors(backdrop, bg, border)
	elseif backdrop.bg then
		if not SameColor(backdrop.BFL_DarkAppliedBgColor, bg) then
			backdrop.bg:SetColorTexture(UnpackColor(bg))
			backdrop.BFL_DarkAppliedBgColor = bg
		end
		SetBackdropStoredColors(backdrop, bg, border)
	end
	if backdrop.BFL_DarkVariant ~= variant then
		backdrop.BFL_DarkVariant = variant
		ApplyBackdropLines(backdrop, variant)
	end
	if not backdrop.IsShown or not backdrop:IsShown() then
		backdrop:Show()
	end

	return backdrop
end

function SkinEngine:DampenRegions(frame, alpha)
	if not frame or IsForbidden(frame) or not frame.GetRegions then
		return
	end

	local regions = GetCachedTextureRegions(frame)
	for _, region in ipairs(regions or {}) do
		self:SetTextureAlpha(frame, region, alpha or 0)
	end
end

function SkinEngine:DampenFrameTextures(frame, alpha, maxDepth, currentDepth)
	if not frame or IsForbidden(frame) then
		return
	end

	self:DampenRegions(frame, alpha or 0)

	currentDepth = currentDepth or 0
	maxDepth = maxDepth or 1
	if currentDepth >= maxDepth or not frame.GetChildren then
		return
	end

	for _, child in ipairs(GetCachedChildFrames(frame) or {}) do
		self:DampenFrameTextures(child, alpha, maxDepth, currentDepth + 1)
	end
end

function SkinEngine:DampenNamedTextures(frame, alpha, names)
	if not frame or not names then
		return
	end

	for _, key in ipairs(names) do
		local region = frame[key]
		if region and region.SetAlpha then
			self:SetTextureAlpha(frame, region, alpha or 0)
		end
	end
end

function SkinEngine:DampenKnownArtwork(frame, alpha)
	if not frame or IsForbidden(frame) then
		return
	end

	local frameName = GetName(frame)
	for _, key in ipairs(DECOR_KEYS) do
		local object = frame[key] or (frameName ~= "" and _G[frameName .. key])
		if object then
			self:ClearTextureObject(frame, object, alpha or 0)
		end
	end
end

function SkinEngine:DampenNineSlice(frame, alpha)
	if not frame or IsForbidden(frame) then
		return
	end

	local nineSlice = frame.NineSlice
	if not nineSlice then
		return
	end

	self:ClearTextureObject(frame, nineSlice, alpha or 0)
	for _, key in ipairs(NINE_SLICE_KEYS) do
		self:ClearTextureObject(frame, nineSlice[key], alpha or 0)
	end
end

function SkinEngine:StripButtonFrameArtwork(frame, alpha)
	if not self:IsActive() or not frame or IsForbidden(frame) then
		return
	end

	alpha = alpha or 0
	self:DampenKnownArtwork(frame, alpha)
	self:DampenNineSlice(frame, alpha)

	local frameName = GetName(frame)
	for _, key in ipairs({
		"Bg",
		"TopTileStreaks",
		"PortraitContainer",
		"Portrait",
		"portrait",
		"PortraitIcon",
		"PortraitMask",
	}) do
		self:ClearTextureObject(frame, frame[key], alpha)
		if frameName ~= "" then
			self:ClearTextureObject(frame, _G[frameName .. key], alpha)
		end
	end
end

function SkinEngine:SkinButtonTextures(button, alpha)
	if not button or IsForbidden(button) then
		return
	end

	local name = GetName(button)
	local textures = button.BFL_DarkButtonTextureObjects
	if not textures or button.BFL_DarkButtonTextureObjectsName ~= name then
		textures = {}
		for _, key in ipairs(BUTTON_TEXTURE_KEYS) do
			local texture = button[key]
			if texture then
				textures[#textures + 1] = texture
			end
		end
		if name ~= "" then
			for _, key in ipairs(BUTTON_TEXTURE_KEYS) do
				local texture = _G[name .. key]
				if texture then
					textures[#textures + 1] = texture
				end
			end
		end
		button.BFL_DarkButtonTextureObjects = textures
		button.BFL_DarkButtonTextureObjectsName = name
	end

	for _, texture in ipairs(textures) do
		self:ClearTextureObject(button, texture, alpha or 0)
	end
	button.BFL_DarkButtonTexturesAlpha = alpha or 0
end

function SkinEngine:ClearButtonTextureCache(button)
	if not button then
		return
	end
	button.BFL_DarkButtonTextureObjects = nil
	button.BFL_DarkButtonTextureObjectsName = nil
end

function SkinEngine:IsBFLFrame(frame)
	local current = frame
	for _ = 1, 12 do
		if not current then
			return false
		end

		local name = GetName(current)
		if name ~= "" then
			if name:find("^BFL")
				or name:find("^BetterFriendlist")
				or name:find("^BetterFriends")
				or name:find("^BetterSavedInstances")
			then
				return true
			end
		end

		current = current.GetParent and current:GetParent()
	end

	return false
end

function SkinEngine:IsDropdownControl(frame)
	if not frame or IsForbidden(frame) then
		return false
	end

	if frame.BFL_DarkDropdownData then
		return true
	end

	local lowerName = LowerName(frame)
	if lowerName:find("dropdown") then
		return true
	end
	if frame.SetupMenu and (frame.Text or frame.Button or frame.MenuArrowButton or frame.ArrowButton) then
		return true
	end

	local name = GetName(frame)
	if name ~= "" and name:lower():find("dropdown") and _G[name .. "Text"] and (_G[name .. "Button"] or _G[name .. "Middle"]) then
		return true
	end

	return false
end

function SkinEngine:SkinFrame(frame, variant, opts)
	if not self:IsActive() or not frame or IsForbidden(frame) then
		return
	end

	variant = variant or "panel"
	self:CreateBackdrop(frame, variant, opts and opts.insets)

	local stripTextures = opts and opts.stripTextures == true
	local textureAlpha = (opts and opts.textureAlpha) or 0
	local decorAlpha = (opts and opts.decorAlpha) or 0
	if
		stripTextures
		and (
			frame.BFL_DarkFrameStripTextures ~= true
			or frame.BFL_DarkFrameTextureAlpha ~= textureAlpha
			or frame.BFL_DarkFrameDecorAlpha ~= decorAlpha
		)
	then
		frame.BFL_DarkFrameStripTextures = true
		frame.BFL_DarkFrameTextureAlpha = textureAlpha
		frame.BFL_DarkFrameDecorAlpha = decorAlpha
		self:DampenRegions(frame, textureAlpha)
		self:DampenKnownArtwork(frame, decorAlpha)
	end

	if frame.TitleContainer and frame.TitleContainer.TitleText then
		self:SetFontColor(frame, frame.TitleContainer.TitleText, 1, 0.82, 0, 1)
	end

	local closeButton = frame.CloseButton
	local frameName = GetName(frame)
	if not closeButton and frameName ~= "" then
		closeButton = _G[frameName .. "CloseButton"]
	end
	if closeButton then
		self:SkinCloseButton(closeButton)
	end
end

function SkinEngine:StyleBackdrop(frame, bgColor, borderColor)
	local backdrop = frame and frame.BFL_DarkBackdrop
	if not backdrop or not backdrop.SetBackdropColor then
		return
	end

	bgColor = bgColor or backdrop.BFL_DarkBaseColor or COLORS.control
	borderColor = borderColor or backdrop.BFL_DarkBorderColor or COLORS.borderSoft
	SetBackdropColors(backdrop, bgColor, borderColor)
end

function SkinEngine:ApplyButtonState(button, interactionState)
	if not self:IsActive() or not button or IsForbidden(button) then
		return
	end
	if IsButtonChromeSuppressed(button) then
		if button.BFL_DarkBackdrop then
			button.BFL_DarkBackdrop:Hide()
		end
		return
	end

	local selectedTab = button.BFL_DarkTabButton and self:IsTabSelected(button)
	if button.BFL_DarkTabButton then
		button.BFL_DarkTabSelected = selectedTab
	end

	local enabled = IsControlEnabled(button)
	if button.BFL_DarkTabButton then
		enabled = selectedTab or button.isDisabled ~= true
	end

	local stateKind = button.BFL_DarkBorderlessIconButton and "icon"
		or button.BFL_DarkTravelPassButton and "travel"
		or button.BFL_DarkArrowButton and "arrow"
		or button.BFL_DarkTabButton and "tab"
		or "button"
	local stateKey = stateKind
		.. ":"
		.. (interactionState or "")
		.. ":"
		.. (enabled and "1" or "0")
		.. ":"
		.. (selectedTab and "1" or "0")
		.. ":"
		.. (button.BFL_DarkScrollStepper and "scroll" or "")
	local arrowNeedsRefresh = button.BFL_DarkArrowButton and not button.BFL_DarkArrowTexturesHidden
	if not arrowNeedsRefresh and button.BFL_DarkButtonStateKey == stateKey then
		return
	end
	button.BFL_DarkButtonStateKey = stateKey

	if button.BFL_DarkBorderlessIconButton then
		self:StyleBackdrop(button, COLORS.borderNone, COLORS.borderNone)
		local iconColor = button.BFL_DarkIconColor or COLORS.icon
		if enabled then
			if interactionState == "down" then
				iconColor = button.BFL_DarkIconDownColor or COLORS.iconDown
			elseif interactionState == "hover" then
				iconColor = button.BFL_DarkIconHoverColor or COLORS.iconHover
			end
		end
		SetButtonIconColor(button, iconColor)
		SetButtonIconBlendMode(button, enabled and interactionState == "hover" and "ADD" or "BLEND")
		SetButtonHoverIcon(button, enabled and interactionState == "hover" and 0.85 or 0, iconColor)
		SetButtonOverlayAlpha(button, enabled and 1 or 0.35)
		return
	end
	if button.BFL_DarkTravelPassButton then
		local border = COLORS.borderSoft
		if not enabled then
			border = COLORS.controlBorderDisabled
		elseif interactionState == "down" then
			border = COLORS.accent
		elseif interactionState == "hover" then
			border = COLORS.controlBorderHover
		end

		self:StyleBackdrop(button, COLORS.borderNone, border)
		return
	end
	if button.BFL_DarkArrowButton then
		self:RefreshArrowButton(button)
	end

	local bg
	local border
	if not enabled then
		bg = COLORS.controlDisabled
		border = COLORS.controlBorderDisabled
	elseif button.BFL_DarkTabButton then
		if interactionState == "down" then
			bg = COLORS.controlDown
			border = COLORS.accent
		elseif interactionState == "hover" then
			bg = COLORS.tabHover
			border = selectedTab and COLORS.accent or COLORS.controlBorderHover
		else
			bg = selectedTab and COLORS.tabHover or COLORS.tab
			border = selectedTab and COLORS.accent or COLORS.borderMuted
		end
	elseif interactionState == "down" then
		bg = COLORS.controlDown
		border = COLORS.accent
	elseif interactionState == "hover" then
		bg = COLORS.controlHover
		border = COLORS.controlBorderHover
	end

	self:StyleBackdrop(button, bg, border)

	local fs = button.GetFontString and button:GetFontString()
	if fs and (not button.BFL_DarkKeepFontColor or not enabled) then
		if enabled then
			local color = button.BFL_DarkTabButton and selectedTab and 1 or 0.92
			self:SetFontColor(button, fs, color, color, color, 1)
		else
			self:SetFontColor(button, fs, UnpackColor(COLORS.disabledText))
		end
	end
	local overlayAlpha = enabled and 1 or 0.35
	if button.BFL_DarkScrollStepper then
		overlayAlpha = enabled and 1 or 0.82
	end
	SetButtonOverlayAlpha(button, overlayAlpha)
end

function SkinEngine:InstallButtonHooks(button)
	if not button or button.BFL_DarkButtonHooked or not button.HookScript then
		return
	end

	button.BFL_DarkButtonHooked = true
	button:HookScript("OnEnter", function(self)
		if SkinEngine:IsActive() then
			SkinEngine:ApplyButtonState(self, "hover")
		end
	end)
	button:HookScript("OnLeave", function(self)
		if SkinEngine:IsActive() then
			SkinEngine:ApplyButtonState(self)
		end
	end)
	button:HookScript("OnMouseDown", function(self)
		if SkinEngine:IsActive() then
			SkinEngine:ApplyButtonState(self, "down")
		end
	end)
	button:HookScript("OnMouseUp", function(self)
		if SkinEngine:IsActive() then
			if self.BFL_DarkBorderlessIconButton then
				local isMouseOver = MouseIsOver and MouseIsOver(self)
				SkinEngine:ApplyButtonState(self, isMouseOver and "hover" or nil)
			elseif self.BFL_DarkTabButton then
				SkinEngine:RefreshRelatedTabs(self)
			else
				local isMouseOver = MouseIsOver and MouseIsOver(self)
				SkinEngine:ApplyButtonState(self, isMouseOver and "hover" or nil)
			end
		end
	end)
	button:HookScript("OnEnable", function(self)
		if SkinEngine:IsActive() then
			SkinEngine:ApplyButtonState(self)
		end
	end)
	button:HookScript("OnDisable", function(self)
		if SkinEngine:IsActive() then
			SkinEngine:ApplyButtonState(self)
		end
	end)
end

function SkinEngine:InstallIconButtonHooks(button)
	if not button or button.BFL_DarkIconButtonHooked or not button.HookScript then
		return
	end

	button.BFL_DarkIconButtonHooked = true
	button:HookScript("OnEnter", function(self)
		if SkinEngine:IsActive() and self.BFL_DarkBorderlessIconButton then
			SkinEngine:ApplyButtonState(self, "hover")
		end
	end)
	button:HookScript("OnLeave", function(self)
		if SkinEngine:IsActive() and self.BFL_DarkBorderlessIconButton then
			SkinEngine:ApplyButtonState(self)
		end
	end)
	button:HookScript("OnMouseDown", function(self)
		if SkinEngine:IsActive() and self.BFL_DarkBorderlessIconButton then
			SkinEngine:ApplyButtonState(self, "down")
		end
	end)
	button:HookScript("OnMouseUp", function(self)
		if SkinEngine:IsActive() and self.BFL_DarkBorderlessIconButton then
			local isMouseOver = MouseIsOver and MouseIsOver(self)
			SkinEngine:ApplyButtonState(self, isMouseOver and "hover" or nil)
		end
	end)
end

function SkinEngine:SkinButton(button, opts)
	if not self:IsActive() or not button or IsForbidden(button) then
		return
	end
	if IsButtonChromeSuppressed(button) then
		self:RestoreFrame(button)
		return
	end
	if IsRAFNativeTextureButton(button) then
		self:SkinNativeTextureButton(button)
		return
	end
	if IsTravelPassButton(button) then
		self:SkinTravelPassButton(button)
		return
	end

	if button.BFL_DarkDropdownIndicator then
		button.BFL_DarkDropdownIndicator:Hide()
	end

	local variant = (opts and opts.variant) or "button"
	local insets = (opts and opts.insets) or BUTTON_INSETS
	local keepFontColor = opts and opts.keepFontColor == true
	local keepNormalTexture = opts and opts.keepNormalTexture == true
	local textureAlpha = (opts and opts.textureAlpha) or 0
	local deferState = opts and opts.deferState == true
	button.BFL_DarkKeepFontColor = keepFontColor

	local left = insets.left or 0
	local right = insets.right or 0
	local top = insets.top or 0
	local bottom = insets.bottom or 0
	if
		button.BFL_DarkButtonSkinned
		and button.BFL_DarkButtonVariant == variant
		and button.BFL_DarkButtonInsetLeft == left
		and button.BFL_DarkButtonInsetRight == right
		and button.BFL_DarkButtonInsetTop == top
		and button.BFL_DarkButtonInsetBottom == bottom
		and button.BFL_DarkButtonKeepNormalTexture == keepNormalTexture
		and button.BFL_DarkButtonTextureAlpha == textureAlpha
	then
		if not deferState then
			self:ApplyButtonState(button)
		end
		return
	end

	button.BFL_DarkButtonSkinned = true
	button.BFL_DarkButtonStateKey = nil
	button.BFL_DarkButtonVariant = variant
	button.BFL_DarkButtonInsetLeft = left
	button.BFL_DarkButtonInsetRight = right
	button.BFL_DarkButtonInsetTop = top
	button.BFL_DarkButtonInsetBottom = bottom
	button.BFL_DarkButtonKeepNormalTexture = keepNormalTexture
	button.BFL_DarkButtonTextureAlpha = textureAlpha
	self:CreateBackdrop(button, variant, insets)

	if button.GetNormalTexture then
		self:SetTextureAlpha(button, button:GetNormalTexture(), keepNormalTexture and 0.35 or 0)
	end
	if button.GetPushedTexture then
		self:SetTextureAlpha(button, button:GetPushedTexture(), 0)
	end
	if button.GetDisabledTexture then
		self:SetTextureAlpha(button, button:GetDisabledTexture(), 0.18)
	end
	if button.GetHighlightTexture then
		self:SetTextureAlpha(button, button:GetHighlightTexture(), 0.18)
	end
	self:SkinButtonTextures(button, textureAlpha)

	local fs = button.GetFontString and button:GetFontString()
	if fs and not keepFontColor then
		self:SetFontColor(button, fs, 0.92, 0.92, 0.92, 1)
	end

	self:InstallButtonHooks(button)
	if not deferState then
		self:ApplyButtonState(button)
	end
end

function SkinEngine:SkinIconButton(button, iconPath, opts)
	if not self:IsActive() or not button or IsForbidden(button) then
		return
	end

	local insets = (opts and opts.insets) or ZERO_INSETS
	local textureAlpha = (opts and opts.textureAlpha) or 0
	local stripRegions = opts and opts.stripRegions == true
	local iconSize = (opts and opts.size) or 14
	local iconX = (opts and opts.x) or 0
	local iconY = (opts and opts.y) or 0
	local iconAlpha = (opts and opts.alpha) or 1
	local explicitTexture = opts and opts.texture

	button.BFL_DarkBorderlessIconButton = true
	button.BFL_DarkIconColor = (opts and opts.color) or COLORS.icon
	button.BFL_DarkIconHoverColor = (opts and opts.hoverColor) or COLORS.iconHover
	button.BFL_DarkIconDownColor = (opts and opts.downColor) or COLORS.iconDown

	local needsSetup = not button.BFL_DarkIconButtonSkinned
		or button.BFL_DarkIconButtonTextureAlpha ~= textureAlpha
		or button.BFL_DarkIconButtonStripRegions ~= stripRegions
		or button.BFL_DarkIconButtonSize ~= iconSize
		or button.BFL_DarkIconButtonX ~= iconX
		or button.BFL_DarkIconButtonY ~= iconY
		or button.BFL_DarkIconButtonExplicitTexture ~= explicitTexture
		or button.BFL_DarkIconButtonIconPath ~= iconPath

	if needsSetup then
		button.BFL_DarkIconButtonSkinned = true
		button.BFL_DarkButtonStateKey = nil
		button.BFL_DarkIconButtonTextureAlpha = textureAlpha
		button.BFL_DarkIconButtonStripRegions = stripRegions
		button.BFL_DarkIconButtonSize = iconSize
		button.BFL_DarkIconButtonX = iconX
		button.BFL_DarkIconButtonY = iconY
		button.BFL_DarkIconButtonExplicitTexture = explicitTexture
		button.BFL_DarkIconButtonIconPath = iconPath

		self:CreateBackdrop(button, "icon", insets)
		self:SkinButtonTextures(button, textureAlpha)
		if button.GetNormalTexture then
			self:SetTextureAlpha(button, button:GetNormalTexture(), 0)
		end
		if button.GetPushedTexture then
			self:SetTextureAlpha(button, button:GetPushedTexture(), 0)
		end
		if button.GetDisabledTexture then
			self:SetTextureAlpha(button, button:GetDisabledTexture(), 0)
		end
		if button.GetHighlightTexture then
			self:SetTextureAlpha(button, button:GetHighlightTexture(), 0)
		end
		if stripRegions then
			self:DampenRegions(button, 0)
		end
	end
	self:StyleBackdrop(button, COLORS.borderNone, COLORS.borderNone)

	if button.BFL_DarkCloseText then
		self:SetObjectShown(button, button.BFL_DarkCloseText, false)
	end
	if button.BFL_DarkArrowText then
		self:SetObjectShown(button, button.BFL_DarkArrowText, false)
	end

	local icon = explicitTexture or button.BFL_DarkIcon
	if not icon and button.CreateTexture then
		icon = button:CreateTexture(nil, "OVERLAY")
		button.BFL_DarkIcon = icon
		self:RegisterOverlay(button, icon)
	end
	if not icon then
		return
	end

	if iconPath and icon.SetTexture then
		icon:SetTexture(iconPath)
	end
	if needsSetup and icon.ClearAllPoints then
		self:SetRegionPoints(button, icon, {
			{ "CENTER", button, "CENTER", iconX, iconY },
		})
	end
	if icon.SetSize then
		self:SetRegionSize(button, icon, iconSize, iconSize)
	end
	if icon.SetVertexColor then
		self:SetTextureVertexColor(button, icon, UnpackColor(button.BFL_DarkIconColor))
	end
	self:SetTextureAlpha(button, icon, iconAlpha)
	icon:Show()
	button.BFL_DarkIcon = icon

	local hoverIcon = button.BFL_DarkHoverIcon
	if not hoverIcon and button.CreateTexture then
		hoverIcon = button:CreateTexture(nil, "OVERLAY", nil, 1)
		button.BFL_DarkHoverIcon = hoverIcon
		self:RegisterOverlay(button, hoverIcon)
	end
	if hoverIcon then
		if iconPath and hoverIcon.SetTexture then
			hoverIcon:SetTexture(iconPath)
		elseif icon.GetAtlas and hoverIcon.SetAtlas then
			local atlas = icon:GetAtlas()
			if atlas then
				hoverIcon:SetAtlas(atlas, true)
			elseif icon.GetTexture and hoverIcon.SetTexture then
				hoverIcon:SetTexture(icon:GetTexture())
			end
		elseif icon.GetTexture and hoverIcon.SetTexture then
			hoverIcon:SetTexture(icon:GetTexture())
		end
		if needsSetup and hoverIcon.ClearAllPoints then
			self:SetRegionPoints(button, hoverIcon, {
				{ "CENTER", icon, "CENTER", 0, 0 },
			})
		end
		if hoverIcon.SetSize and icon.GetSize then
			self:SetRegionSize(button, hoverIcon, icon:GetSize())
		end
		if hoverIcon.SetTexCoord and icon.GetTexCoord then
			hoverIcon:SetTexCoord(icon:GetTexCoord())
		end
		if hoverIcon.SetBlendMode then
			self:SetTextureBlendMode(button, hoverIcon, "ADD")
		end
		if hoverIcon.SetAlpha then
			self:SetTextureAlpha(button, hoverIcon, 0)
		end
		hoverIcon:Hide()
	end

	self:InstallButtonHooks(button)
	self:InstallIconButtonHooks(button)
	self:ApplyButtonState(button)
end

function SkinEngine:SkinNativeTextureButton(button)
	if not self:IsActive() or not button or IsForbidden(button) then
		return
	end

	button.BFL_DarkNativeTextureButton = true
	button.BFL_DarkBorderlessIconButton = nil
	button.BFL_DarkTravelPassButton = nil
	button.BFL_DarkButtonStateKey = nil

	if button.BFL_DarkBackdrop then
		button.BFL_DarkBackdrop:Hide()
	end
	if button.BFL_DarkDropdownIndicator then
		button.BFL_DarkDropdownIndicator:Hide()
	end
	if button.BFL_DarkTravelPassIcon then
		self:SetTextureAlpha(button, button.BFL_DarkTravelPassIcon, 0)
		button.BFL_DarkTravelPassIcon:Hide()
	end
	if button.BFL_DarkIcon == button.BFL_DarkTravelPassIcon then
		button.BFL_DarkIcon = nil
	end

	self:SetTextureAlpha(button, button.NormalTexture, 1)
	self:SetTextureAlpha(button, button.PushedTexture, 1)
	self:SetTextureAlpha(button, button.DisabledTexture, 1)
	self:SetTextureAlpha(button, button.HighlightTexture, 1)
	if button.GetNormalTexture then
		self:SetTextureAlpha(button, button:GetNormalTexture(), 1)
	end
	if button.GetPushedTexture then
		self:SetTextureAlpha(button, button:GetPushedTexture(), 1)
	end
	if button.GetDisabledTexture then
		self:SetTextureAlpha(button, button:GetDisabledTexture(), 1)
	end
	if button.GetHighlightTexture then
		self:SetTextureAlpha(button, button:GetHighlightTexture(), 1)
	end
	self:SetTextureAlpha(button, button.Icon, 1)
	self:SetTextureAlpha(button, button.IconBorder, 1)
	self:SetTextureAlpha(button, button.LetterI, 1)
end

function SkinEngine:SkinTravelPassButton(button)
	if not self:IsActive() or not button or IsForbidden(button) then
		return
	end

	button.BFL_DarkTravelPassButton = true
	if not button.BFL_DarkTravelPassSkinned then
		button.BFL_DarkTravelPassSkinned = true
		button.BFL_DarkButtonStateKey = nil
		self:CreateBackdrop(button, "nativeButton", ZERO_INSETS)
		if button.BFL_DarkBackdrop and button.GetFrameLevel then
			button.BFL_DarkBackdrop:SetFrameLevel((button:GetFrameLevel() or 1) + 1)
		end

		if button.BFL_DarkDropdownIndicator then
			button.BFL_DarkDropdownIndicator:Hide()
		end

		self:SetTextureAlpha(button, button.NormalTexture, 1)
		self:SetTextureAlpha(button, button.PushedTexture, 1)
		self:SetTextureAlpha(button, button.DisabledTexture, 1)
		self:SetTextureAlpha(button, button.HighlightTexture, 1)
		if button.GetNormalTexture then
			self:SetTextureAlpha(button, button:GetNormalTexture(), 1)
		end
		if button.GetPushedTexture then
			self:SetTextureAlpha(button, button:GetPushedTexture(), 1)
		end
		if button.GetDisabledTexture then
			self:SetTextureAlpha(button, button:GetDisabledTexture(), 1)
		end
		if button.GetHighlightTexture then
			self:SetTextureAlpha(button, button:GetHighlightTexture(), 1)
		end

		if button.BFL_DarkTravelPassIcon then
			self:SetTextureAlpha(button, button.BFL_DarkTravelPassIcon, 0)
			button.BFL_DarkTravelPassIcon:Hide()
		end
		if button.BFL_DarkIcon == button.BFL_DarkTravelPassIcon then
			button.BFL_DarkIcon = nil
		end

		self:InstallButtonHooks(button)
	end

	self:ApplyButtonState(button)
end

function SkinEngine:RefreshTravelPassButton(button)
	if not self:IsActive() or not button or IsForbidden(button) then
		return
	end

	if button.BFL_DarkTravelPassSkinned then
		self:ApplyButtonState(button)
	else
		self:SkinTravelPassButton(button)
	end
end

function SkinEngine:SkinNavigationButton(button)
	if not self:IsActive() or not button or IsForbidden(button) then
		return
	end

	self:SkinButton(button, NAV_BUTTON_OPTS)

	local selected = button.selectedTex and button.selectedTex.IsShown and button.selectedTex:IsShown()
	local bg = selected and COLORS.controlHover or COLORS.panelSoft
	local border = selected and COLORS.controlBorderHover or COLORS.borderMuted
	self:StyleBackdrop(button, bg, border)

	if button.selectedTex and button.selectedTex.SetAlpha then
		self:SetTextureAlpha(button, button.selectedTex, 0)
	end

	local indicator = button.BFL_DarkNavIndicator
	if not indicator and button.CreateTexture then
		indicator = button:CreateTexture(nil, "ARTWORK")
		indicator:SetPoint("TOPLEFT", button, "TOPLEFT", 0, -5)
		indicator:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 0, 5)
		indicator:SetWidth(3)
		button.BFL_DarkNavIndicator = indicator
		self:RegisterOverlay(button, indicator)
	end
	if indicator then
		indicator:SetColorTexture(UnpackColor(COLORS.accent))
		indicator:SetShown(selected)
	end
end

function SkinEngine:IsTabSelected(tab)
	if not tab then
		return false
	end

	local owner = tab.GetParent and tab:GetParent()
	if LowerName(tab):find("bottomtab") then
		owner = _G.BetterFriendsFrame
	end

	local selectedTab
	if owner then
		selectedTab = PanelTemplates_GetSelectedTab and PanelTemplates_GetSelectedTab(owner) or owner.selectedTab
	end
	local tabId = tab.GetID and tab:GetID()
	return selectedTab and tabId and selectedTab == tabId
end

function SkinEngine:CenterTabText(tab)
	local fs = tab and (tab.Text or (tab.GetFontString and tab:GetFontString()))
	if not fs then
		return
	end
	if tab.BFL_DarkTextCentered and fs.BFL_DarkCenteredForTab == tab then
		local point, relativeTo, relativePoint, xOffset, yOffset = fs:GetPoint(1)
		if point == "CENTER" and relativeTo == tab and relativePoint == "CENTER" and (xOffset or 0) == 0 and (yOffset or 0) == 0 then
			return
		end
	end

	if not tab.BFL_DarkOriginalTextPoints then
		if tab.BFL_OriginalTextPoints and tab.BFL_OriginalTextPoints[1] then
			tab.BFL_DarkOriginalTextPoints = { unpack(tab.BFL_OriginalTextPoints) }
		else
			tab.BFL_DarkOriginalTextPoints = { fs:GetPoint(1) }
		end
	end

	local state = self:GetState(tab)
	if state and not state.tabUseTextCenterStored then
		state.tabUseTextCenterStored = true
		state.tabUseTextCenter = tab.BFL_UseTextCenter
	end
	if state and not state.regionPoints[fs] then
		if tab.BFL_OriginalTextPoints and tab.BFL_OriginalTextPoints[1] then
			state.regionPoints[fs] = { { unpack(tab.BFL_OriginalTextPoints) } }
		else
			self:RememberRegionPoints(tab, fs)
		end
	end

	tab.BFL_UseTextCenter = true
	self:SetRegionPoints(tab, fs, {
		{ "CENTER", tab, "CENTER", 0, 0 },
	})
	self:SetFontJustify(tab, fs, "CENTER", "MIDDLE")
	tab.BFL_DarkTextCentered = true
	fs.BFL_DarkCenteredForTab = tab
end

function SkinEngine:RefreshRelatedTabs(tab)
	if not self:IsActive() or self.BFL_DarkRefreshingTabs then
		return
	end

	self.BFL_DarkRefreshingTabs = true
	if LowerName(tab):find("bottomtab") then
		for i = 1, 4 do
			self:SkinTab(_G["BetterFriendsFrameBottomTab" .. i])
		end
	else
		for i = 1, 4 do
			self:SkinTab(_G["BetterFriendsFrameTab" .. i])
		end
	end
	self.BFL_DarkRefreshingTabs = nil
end

function SkinEngine:InstallTabHooks(tab)
	if not tab or tab.BFL_DarkTabHooked or not tab.HookScript then
		return
	end

	tab.BFL_DarkTabHooked = true
	tab:HookScript("OnClick", function(self)
		SkinEngine:RefreshRelatedTabs(self)
	end)
	tab:HookScript("OnShow", function(self)
		if SkinEngine:IsActive() then
			SkinEngine:SkinTab(self)
		end
	end)
	tab:HookScript("OnSizeChanged", function(self)
		if SkinEngine:IsActive() then
			SkinEngine:CenterTabText(self)
		end
	end)
end

function SkinEngine:SkinTab(tab)
	if not self:IsActive() or not tab or IsForbidden(tab) then
		return
	end

	if tab.BFL_DarkTabButton and tab.BFL_DarkTabSkinned and tab.BFL_DarkButtonSkinned then
		self:ApplyButtonState(tab)
		local fs = tab.Text or (tab.GetFontString and tab:GetFontString())
		if fs and (not tab.BFL_DarkTextCentered or fs.BFL_DarkCenteredForTab ~= tab) then
			self:CenterTabText(tab)
		end
		return
	end

	tab.BFL_DarkTabButton = true
	self:SkinButton(tab, TAB_BUTTON_OPTS)
	if not tab.BFL_DarkTabSkinned then
		tab.BFL_DarkTabSkinned = true
		self:DampenRegions(tab, 0)
		self:InstallTabHooks(tab)
	end

	local fs = tab.Text or (tab.GetFontString and tab:GetFontString())
	if fs and (not tab.BFL_DarkTextCentered or fs.BFL_DarkCenteredForTab ~= tab) then
		self:CenterTabText(tab)
	end
end

function SkinEngine:SkinCloseButton(button)
	if not self:IsActive() or not button or IsForbidden(button) then
		return
	end

	self:SkinIconButton(button, ICONS.close, {
		color = COLORS.close,
		hoverColor = COLORS.closeHover,
		downColor = COLORS.closeDown,
		size = 15,
		stripRegions = true,
	})
end

function SkinEngine:HideArrowButtonTextures(button, force)
	if not button or IsForbidden(button) then
		return
	end
	if not force and button.BFL_DarkArrowTexturesHidden then
		return
	end

	self:DampenRegions(button, 0)
	self:SkinButtonTextures(button, 0)
	if button.Texture then
		self:SetTextureAlpha(button, button.Texture, 0)
	end
	if button.BFL_DarkArrowIcon then
		self:SetTextureAlpha(button, button.BFL_DarkArrowIcon, 1)
	end
	button.BFL_DarkArrowTexturesHidden = true
end

function SkinEngine:PositionArrowButtonIcon(button, direction)
	if not button or IsForbidden(button) then
		return
	end

	local icon = button.BFL_DarkArrowIcon
	if not icon then
		return
	end

	local anchor = button
	if button.BFL_DarkScrollStepper and button.BFL_DarkBackdrop then
		anchor = button.BFL_DarkBackdrop
	end
	direction = direction or button.BFL_DarkArrowDirection or "down"
	if icon.BFL_DarkArrowIconAnchor == anchor and icon.BFL_DarkArrowIconDirection == direction then
		if icon.Show and (not icon.IsShown or not icon:IsShown()) then
			icon:Show()
		end
		return
	end

	icon:ClearAllPoints()
	icon:SetPoint("CENTER", anchor, "CENTER", 0, 0)

	if icon.SetDrawLayer then
		icon:SetDrawLayer("OVERLAY", 7)
	end
	icon:Show()
	icon.BFL_DarkArrowIconAnchor = anchor
	icon.BFL_DarkArrowIconDirection = direction
end

function SkinEngine:RefreshArrowButton(button, force)
	if not self:IsActive() or not button or IsForbidden(button) then
		return
	end

	self:HideArrowButtonTextures(button, force)
	if button.BFL_DarkArrowIcon then
		self:SetTextureAlpha(button, button.BFL_DarkArrowIcon, 1)
	end
	self:PositionArrowButtonIcon(button)
end

function SkinEngine:InstallArrowButtonHooks(button)
	if not button or button.BFL_DarkArrowButtonHooked then
		return
	end

	button.BFL_DarkArrowButtonHooked = true
	local function refresh(target)
		if SkinEngine:IsActive() and target and target.BFL_DarkArrowButton then
			SkinEngine:RefreshArrowButton(target, true)
		end
	end

	if button.HookScript then
		button:HookScript("OnShow", refresh)
		button:HookScript("OnEnter", refresh)
		button:HookScript("OnLeave", refresh)
		button:HookScript("OnMouseDown", refresh)
		button:HookScript("OnMouseUp", refresh)
		button:HookScript("OnEnable", refresh)
		button:HookScript("OnDisable", refresh)
		button:HookScript("OnSizeChanged", refresh)
	end
	if hooksecurefunc and type(button.OnButtonStateChanged) == "function" then
		hooksecurefunc(button, "OnButtonStateChanged", refresh)
	end
end

function SkinEngine:SkinArrowButton(button, direction)
	if not self:IsActive() or not button or IsForbidden(button) then
		return
	end

	direction = direction or "down"
	button.BFL_DarkArrowButton = true
	button.BFL_DarkArrowDirection = direction
	local insets = button.BFL_DarkScrollStepper and ZERO_INSETS
		or button.BFL_DarkSliderStepper and SLIDER_STEPPER_INSETS
		or ARROW_BUTTON_INSETS
	local left = insets.left or 0
	local right = insets.right or 0
	local top = insets.top or 0
	local bottom = insets.bottom or 0
	local needsSetup = not button.BFL_DarkArrowSkinned
		or button.BFL_DarkArrowSetupDirection ~= direction
		or button.BFL_DarkArrowInsetLeft ~= left
		or button.BFL_DarkArrowInsetRight ~= right
		or button.BFL_DarkArrowInsetTop ~= top
		or button.BFL_DarkArrowInsetBottom ~= bottom
	if needsSetup then
		button.BFL_DarkArrowSkinned = true
		button.BFL_DarkArrowSetupDirection = direction
		button.BFL_DarkArrowInsetLeft = left
		button.BFL_DarkArrowInsetRight = right
		button.BFL_DarkArrowInsetTop = top
		button.BFL_DarkArrowInsetBottom = bottom
		button.BFL_DarkButtonStateKey = nil
		button.BFL_DarkArrowTexturesHidden = nil
	end
	self:SkinButton(button, { insets = insets, keepFontColor = true, deferState = true })
	self:HideArrowButtonTextures(button, needsSetup)

	if button.BFL_DarkArrowText then
		self:SetObjectShown(button, button.BFL_DarkArrowText, false)
	end

	local icon = button.BFL_DarkArrowIcon
	if not icon and button.CreateTexture then
		icon = button:CreateTexture(nil, "OVERLAY")
		button.BFL_DarkArrowIcon = icon
		self:RegisterOverlay(button, icon)
	end

	if icon then
		local iconPath = ICONS[button.BFL_DarkArrowDirection] or ICONS.down
		if needsSetup and icon.SetTexture then
			icon:SetTexture(iconPath)
		end
		self:SetRegionSize(button, icon, 10, 10)
		self:SetTextureVertexColor(button, icon, UnpackColor(COLORS.gold))
		self:SetTextureAlpha(button, icon, 1)
		self:PositionArrowButtonIcon(button, direction)
	end
	self:InstallArrowButtonHooks(button)
	self:ApplyButtonState(button)
end

function SkinEngine:SkinCompactCheckButton(checkButton)
	if not self:IsActive() or not checkButton or IsForbidden(checkButton) then
		return
	end

	if checkButton.BFL_DarkBackdrop then
		checkButton.BFL_DarkBackdrop:Hide()
	end

	local marker = checkButton.BFL_DarkCheckMarker
	if not marker and CreateFrame then
		local template = BackdropTemplateMixin and "BackdropTemplate" or nil
		marker = CreateFrame("Frame", nil, checkButton, template)
		marker:EnableMouse(false)
		if marker.SetBackdrop then
			marker:SetBackdrop(BACKDROP)
		end
		checkButton.BFL_DarkCheckMarker = marker
		self:RegisterOverlay(checkButton, marker)
	end

	if marker then
		marker:ClearAllPoints()
		marker:SetPoint("CENTER", checkButton, "CENTER", -1, 0)
		marker:SetSize(14, 14)
		marker:SetFrameLevel(math.max((checkButton:GetFrameLevel() or 1) - 1, 0))
		SetBackdropColors(marker, COLORS.controlDown, COLORS.controlBorder)
		marker:Show()
	end

	if checkButton.GetNormalTexture then
		self:SetTextureAlpha(checkButton, checkButton:GetNormalTexture(), 0)
	end
	if checkButton.GetPushedTexture then
		self:SetTextureAlpha(checkButton, checkButton:GetPushedTexture(), 0)
	end
	if checkButton.GetDisabledTexture then
		self:SetTextureAlpha(checkButton, checkButton:GetDisabledTexture(), 0)
	end
	if checkButton.GetHighlightTexture then
		self:SetTextureAlpha(checkButton, checkButton:GetHighlightTexture(), 0.10)
	end

	local checkedTexture = checkButton.GetCheckedTexture and checkButton:GetCheckedTexture()
	if checkedTexture then
		self:SetRegionPoints(checkButton, checkedTexture, {
			{ "CENTER", marker or checkButton, "CENTER", 0, 0 },
		})
		self:SetRegionSize(checkButton, checkedTexture, 16, 16)
		self:SetTextureVertexColor(checkButton, checkedTexture, UnpackColor(COLORS.gold))
		self:SetTextureAlpha(checkButton, checkedTexture, 1)
	end

	local disabledCheckedTexture = checkButton.GetDisabledCheckedTexture and checkButton:GetDisabledCheckedTexture()
	if disabledCheckedTexture then
		self:SetRegionPoints(checkButton, disabledCheckedTexture, {
			{ "CENTER", marker or checkButton, "CENTER", 0, 0 },
		})
		self:SetRegionSize(checkButton, disabledCheckedTexture, 16, 16)
		self:SetTextureVertexColor(checkButton, disabledCheckedTexture, UnpackColor(COLORS.disabledText))
		self:SetTextureAlpha(checkButton, disabledCheckedTexture, 0.85)
	end

	local text = checkButton.Text or _G[GetName(checkButton) .. "Text"]
	if text then
		self:SetFontColor(checkButton, text, 0.88, 0.88, 0.88, 1)
	end
end

function SkinEngine:SkinCheckButton(checkButton)
	if not self:IsActive() or not checkButton or IsForbidden(checkButton) then
		return
	end

	if checkButton.BFL_DarkCompactCheckButton then
		self:SkinCompactCheckButton(checkButton)
		return
	end

	if checkButton.BFL_DarkNoCheckChrome or checkButton.BFL_DarkNoButtonChrome then
		self:RestoreFrame(checkButton)
		return
	end

	self:CreateBackdrop(
		checkButton,
		"control",
		checkButton.BFL_DarkCheckButtonInsets or { left = 4, right = 4, top = -4, bottom = -4 }
	)

	if checkButton.GetNormalTexture then
		local normalAlpha = checkButton.BFL_DarkCheckButtonNormalAlpha
		if normalAlpha == nil then
			normalAlpha = 0.25
		end
		self:SetTextureAlpha(checkButton, checkButton:GetNormalTexture(), normalAlpha)
	end
	if checkButton.GetPushedTexture and checkButton.BFL_DarkCheckButtonPushedAlpha ~= nil then
		self:SetTextureAlpha(checkButton, checkButton:GetPushedTexture(), checkButton.BFL_DarkCheckButtonPushedAlpha)
	end
	if checkButton.GetDisabledTexture and checkButton.BFL_DarkCheckButtonDisabledAlpha ~= nil then
		self:SetTextureAlpha(checkButton, checkButton:GetDisabledTexture(), checkButton.BFL_DarkCheckButtonDisabledAlpha)
	end
	if checkButton.GetHighlightTexture then
		local highlightAlpha = checkButton.BFL_DarkCheckButtonHighlightAlpha
		if highlightAlpha == nil then
			highlightAlpha = 0.18
		end
		self:SetTextureAlpha(checkButton, checkButton:GetHighlightTexture(), highlightAlpha)
	end

	local text = checkButton.Text or _G[GetName(checkButton) .. "Text"]
	if text then
		self:SetFontColor(checkButton, text, 0.88, 0.88, 0.88, 1)
	end
end

function SkinEngine:SkinEditBox(editBox)
	if not self:IsActive() or not editBox or IsForbidden(editBox) then
		return
	end

	self:CreateBackdrop(editBox, "editbox", ZERO_INSETS)
	self:DampenNamedTextures(editBox, 0, {
		"Left",
		"Middle",
		"Right",
		"LeftTexture",
		"MiddleTexture",
		"RightTexture",
		"TopLeftBorder",
		"TopRightBorder",
		"TopBorder",
		"BottomLeftBorder",
		"BottomRightBorder",
		"BottomBorder",
		"LeftBorder",
		"RightBorder",
		"MiddleBorder",
		"Backdrop",
	})

	self:SetFontColor(editBox, editBox, 0.92, 0.92, 0.92, 1)

	local clearButton = editBox.clearButton or editBox.ClearButton
	if clearButton then
		clearButton.BFL_DarkNoButtonChrome = true
		self:RestoreFrame(clearButton)
	end

end

function SkinEngine:SkinDropdownIndicator(dropdown)
	if not dropdown or IsForbidden(dropdown) or not CreateFrame then
		return
	end

	local indicator = dropdown.BFL_DarkDropdownIndicator
	if not indicator then
		local template = BackdropTemplateMixin and "BackdropTemplate" or nil
		indicator = CreateFrame("Frame", nil, dropdown, template)
		indicator:SetSize(24, 20)
		indicator:SetPoint("TOPRIGHT", dropdown, "TOPRIGHT", -1, -2)
		indicator:SetPoint("BOTTOMRIGHT", dropdown, "BOTTOMRIGHT", -1, 2)
		indicator:EnableMouse(false)
		dropdown.BFL_DarkDropdownIndicator = indicator
		self:RegisterOverlay(dropdown, indicator)
	end

	indicator:Show()
	if indicator.SetFrameLevel then
		indicator:SetFrameLevel((dropdown:GetFrameLevel() or 1) + 1)
	end
	if indicator.SetBackdrop then
		indicator:SetBackdrop(BACKDROP)
		indicator:SetBackdropColor(UnpackColor(COLORS.controlDown))
		indicator:SetBackdropBorderColor(UnpackColor(COLORS.borderSoft))
	end

	if indicator.Text then
		indicator.Text:Hide()
	end
	if not indicator.Icon and indicator.CreateTexture then
		local icon = indicator:CreateTexture(nil, "OVERLAY")
		indicator.Icon = icon
	end
	if indicator.Icon then
		indicator.Icon:SetTexture(ICONS.down)
		indicator.Icon:ClearAllPoints()
		indicator.Icon:SetPoint("CENTER", indicator, "CENTER", 0, 0)
		indicator.Icon:SetSize(10, 10)
		indicator.Icon:SetVertexColor(UnpackColor(COLORS.gold))
		indicator.Icon:SetAlpha(1)
		indicator.Icon:Show()
	end
end

function SkinEngine:GetDropdownMenu(dropdown)
	if not dropdown or not dropdown.BFL_DarkDropdownData or IsForbidden(dropdown) then
		return nil
	end

	local menu = dropdown.BFL_DarkCustomMenu
	if not menu and CreateFrame then
		local template = BackdropTemplateMixin and "BackdropTemplate" or nil
		menu = CreateFrame("Frame", nil, UIParent, template)
		menu:SetFrameStrata("DIALOG")
		menu:SetClampedToScreen(true)
		menu:EnableMouse(true)
		menu:Hide()
		menu.Rows = {}
		menu.offset = 1
		menu.ownerDropdown = dropdown
		menu:SetScript("OnMouseWheel", function(self, delta)
			local data = self.ownerDropdown and self.ownerDropdown.BFL_DarkDropdownData
			if not data then
				return
			end
			local maxVisible = self.maxVisible or 10
			local maxOffset = math.max(1, (#data.labels or 0) - maxVisible + 1)
			self.offset = math.max(1, math.min(maxOffset, (self.offset or 1) - delta))
			SkinEngine:RenderCustomDropdown(self.ownerDropdown)
		end)
		menu:SetScript("OnLeave", function(self)
			if MouseIsOver and (MouseIsOver(self) or MouseIsOver(self.ownerDropdown)) then
				return
			end
			self:Hide()
		end)
		dropdown.BFL_DarkCustomMenu = menu
		self:RegisterOverlay(dropdown, menu)
	end

	return menu
end

function SkinEngine:RenderCustomDropdown(dropdown)
	local data = dropdown and dropdown.BFL_DarkDropdownData
	local menu = dropdown and dropdown.BFL_DarkCustomMenu
	if not data or not menu then
		return
	end

	local labels = data.labels or {}
	local values = data.values or {}
	local rowHeight = 22
	local maxVisible = math.min(#labels, data.maxVisible or 10)
	if maxVisible < 1 then
		menu:Hide()
		return
	end

	local dropdownWidth = dropdown.GetWidth and dropdown:GetWidth() or 170
	local menuWidth = math.max(dropdownWidth, data.width or 170)
	local maxOffset = math.max(1, #labels - maxVisible + 1)
	menu.offset = math.max(1, math.min(maxOffset, menu.offset or 1))
	menu.maxVisible = maxVisible
	menu:SetSize(menuWidth, (rowHeight * maxVisible) + 6)
	menu:ClearAllPoints()
	menu:SetPoint("TOPLEFT", dropdown, "BOTTOMLEFT", 0, -2)

	if menu.SetBackdrop then
		menu:SetBackdrop(BACKDROP)
		menu:SetBackdropColor(UnpackColor(COLORS.panel))
		menu:SetBackdropBorderColor(UnpackColor(COLORS.borderSoft))
	end

	for rowIndex = 1, maxVisible do
		local button = menu.Rows[rowIndex]
		if not button then
			local template = BackdropTemplateMixin and "BackdropTemplate" or nil
			button = CreateFrame("Button", nil, menu, template)
			button:SetHeight(rowHeight)
			button.Check = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
			ApplyDefaultSlugToFontString(button.Check)
			button.Check:SetPoint("LEFT", button, "LEFT", 6, 0)
			button.Check:SetWidth(16)
			button.Check:SetJustifyH("CENTER")
			button.Text = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
			ApplyDefaultSlugToFontString(button.Text)
			button.Text:SetPoint("LEFT", button.Check, "RIGHT", 4, 0)
			button.Text:SetPoint("RIGHT", button, "RIGHT", -6, 0)
			button.Text:SetJustifyH("LEFT")
			menu.Rows[rowIndex] = button
		end

		local itemIndex = menu.offset + rowIndex - 1
		local label = labels[itemIndex]
		local value = values[itemIndex]
		button.ownerDropdown = dropdown
		button.itemValue = value
		button:ClearAllPoints()
		button:SetPoint("TOPLEFT", menu, "TOPLEFT", 3, -3 - ((rowIndex - 1) * rowHeight))
		button:SetPoint("TOPRIGHT", menu, "TOPRIGHT", -3, -3 - ((rowIndex - 1) * rowHeight))
		button:Show()
		button.Text:SetText(label or "")
		button.Text:SetTextColor(0.92, 0.92, 0.92, 1)
		if data.getFontObject then
			local fontObject = data.getFontObject(itemIndex)
			if fontObject then
				button.Text:SetFontObject(fontObject)
			end
		end
		local selected = data.isSelected and data.isSelected(value)
		button.Check:SetText(selected and (data.useCheckboxes and "x" or "o") or "")
		button.Check:SetTextColor(1, 0.82, 0, 1)
		if button.SetBackdrop then
			button:SetBackdrop(BACKDROP)
			button:SetBackdropColor(UnpackColor(selected and COLORS.controlHover or COLORS.panelSoft))
			button:SetBackdropBorderColor(0, 0, 0, 0)
		end
		button:SetScript("OnEnter", function(self)
			if self.SetBackdrop then
				self:SetBackdropColor(UnpackColor(COLORS.controlHover))
				self:SetBackdropBorderColor(UnpackColor(COLORS.controlBorderHover))
			end
		end)
		button:SetScript("OnLeave", function(self)
			local ownerData = self.ownerDropdown and self.ownerDropdown.BFL_DarkDropdownData
			local isSelected = ownerData and ownerData.isSelected and ownerData.isSelected(self.itemValue)
			if self.SetBackdrop then
				self:SetBackdropColor(UnpackColor(isSelected and COLORS.controlHover or COLORS.panelSoft))
				self:SetBackdropBorderColor(0, 0, 0, 0)
			end
		end)
		button:SetScript("OnClick", function(self)
			local owner = self.ownerDropdown
			local ownerData = owner and owner.BFL_DarkDropdownData
			if not ownerData then
				return
			end
			if ownerData.onSelect then
				ownerData.onSelect(self.itemValue)
			end
			if ownerData.setText then
				ownerData.setText(self.itemValue)
			end
			if ownerData.applyFont then
				ownerData.applyFont(self.itemValue)
			end
			if not ownerData.useCheckboxes and owner.BFL_DarkCustomMenu then
				owner.BFL_DarkCustomMenu:Hide()
			else
				SkinEngine:RenderCustomDropdown(owner)
			end
		end)
	end

	for rowIndex = maxVisible + 1, #menu.Rows do
		menu.Rows[rowIndex]:Hide()
	end
end

function SkinEngine:ToggleCustomDropdown(dropdown)
	if not self:IsActive() or not dropdown or not dropdown.BFL_DarkDropdownData then
		return false
	end

	local menu = self:GetDropdownMenu(dropdown)
	if not menu then
		return false
	end
	if menu:IsShown() then
		menu:Hide()
		return true
	end

	if self.openCustomDropdownMenu and self.openCustomDropdownMenu ~= menu then
		self.openCustomDropdownMenu:Hide()
	end
	self.openCustomDropdownMenu = menu
	menu.offset = 1
	self:RenderCustomDropdown(dropdown)
	menu:Show()
	return true
end

function SkinEngine:InstallCustomDropdown(dropdown)
	if not dropdown or dropdown.BFL_DarkCustomDropdownInstalled or not dropdown.BFL_DarkDropdownData then
		return
	end

	dropdown.BFL_DarkCustomDropdownInstalled = true
	dropdown.BFL_DarkOriginalOnMouseDown = dropdown.GetScript and dropdown:GetScript("OnMouseDown")
	dropdown.BFL_DarkOriginalOnMouseDownSet = true
	if dropdown.SetScript then
		dropdown:SetScript("OnMouseDown", function(self, button)
			if SkinEngine:ToggleCustomDropdown(self) then
				return
			end
			if self.BFL_DarkOriginalOnMouseDown then
				self.BFL_DarkOriginalOnMouseDown(self, button)
			end
		end)
	end
	if dropdown.HookScript then
		dropdown:HookScript("OnHide", function(self)
			if self.BFL_DarkCustomMenu then
				self.BFL_DarkCustomMenu:Hide()
			end
		end)
	end

	local name = GetName(dropdown)
	local classicButton = name ~= "" and _G[name .. "Button"] or nil
	if classicButton and classicButton.SetScript then
		dropdown.BFL_DarkCustomButton = classicButton
		dropdown.BFL_DarkOriginalButtonOnClick = classicButton.GetScript and classicButton:GetScript("OnClick")
		dropdown.BFL_DarkOriginalButtonOnClickSet = true
		classicButton:SetScript("OnClick", function(self, button)
			local owner = self:GetParent()
			if owner and SkinEngine:ToggleCustomDropdown(owner) then
				return
			end
			if owner and owner.BFL_DarkOriginalButtonOnClick then
				owner.BFL_DarkOriginalButtonOnClick(self, button)
			end
		end)
	end
end

function SkinEngine:SkinDropdown(dropdown)
	if not self:IsActive() or not dropdown or IsForbidden(dropdown) then
		return
	end
	if not self:IsDropdownControl(dropdown) then
		self:SkinButton(dropdown)
		return
	end

	self:CreateBackdrop(dropdown, "dropdown", ZERO_INSETS)
	self:DampenRegions(dropdown, 0)
	self:DampenKnownArtwork(dropdown, 0)
	self:SkinButtonTextures(dropdown, 0)
	self:InstallCustomDropdown(dropdown)

	local name = GetName(dropdown)
	local namedButton
	if name ~= "" then
		namedButton = _G[name .. "Button"]
		local pieces = {
			_G[name .. "Left"],
			_G[name .. "Middle"],
			_G[name .. "Right"],
			namedButton,
			_G[name .. "ButtonNormalTexture"],
			_G[name .. "ButtonPushedTexture"],
			_G[name .. "ButtonDisabledTexture"],
		}
		for _, piece in ipairs(pieces) do
			if piece and piece.SetAlpha then
				if piece == namedButton then
					self:SkinArrowButton(piece, "down")
				else
					self:SetTextureAlpha(dropdown, piece, 0)
				end
			end
		end
		local text = _G[name .. "Text"]
		if text then
			self:SetFontColor(dropdown, text, 0.92, 0.92, 0.92, 1)
		end
	end

	local arrowButton = dropdown.Button or dropdown.MenuArrowButton or dropdown.ArrowButton
	if arrowButton then
		self:SkinArrowButton(arrowButton, "down")
	end
	if not arrowButton and not namedButton then
		self:SkinDropdownIndicator(dropdown)
	elseif dropdown.BFL_DarkDropdownIndicator then
		dropdown.BFL_DarkDropdownIndicator:Hide()
	end

	if dropdown.Text then
		self:SetFontColor(dropdown, dropdown.Text, 0.92, 0.92, 0.92, 1)
	end

end

function SkinEngine:SkinScrollThumb(thumb)
	if not self:IsActive() or not thumb or IsForbidden(thumb) then
		return
	end

	if thumb.BFL_DarkScrollThumbSkinned then
		return
	end
	thumb.BFL_DarkScrollThumbSkinned = true

	if thumb.CreateTexture or thumb.SetBackdrop then
		self:CreateBackdrop(thumb, "thumb", ZERO_INSETS)
	end
	self:DampenRegions(thumb, 0)
end

function SkinEngine:SkinScrollTextureThumb(scrollBar, thumb)
	if not self:IsActive() or not scrollBar or not thumb or IsForbidden(scrollBar) then
		return
	end

	self:SetTextureAlpha(scrollBar, thumb, 0)

	local marker = scrollBar.BFL_DarkScrollThumb
	if not marker and CreateFrame then
		local template = BackdropTemplateMixin and "BackdropTemplate" or nil
		marker = CreateFrame("Frame", nil, scrollBar, template)
		marker:EnableMouse(false)
		scrollBar.BFL_DarkScrollThumb = marker
		self:RegisterOverlay(scrollBar, marker)
	end

	if marker then
		marker:ClearAllPoints()
		local inset = scrollBar.BFL_DarkWideScrollbar and 4 or 2
		marker:SetPoint("TOP", thumb, "TOP", 0, -1)
		marker:SetPoint("BOTTOM", thumb, "BOTTOM", 0, 1)
		marker:SetPoint("LEFT", scrollBar, "LEFT", inset, 0)
		marker:SetPoint("RIGHT", scrollBar, "RIGHT", -inset, 0)
		if marker.SetFrameLevel then
			marker:SetFrameLevel((scrollBar:GetFrameLevel() or 1) + 2)
		end
		if marker.SetBackdrop then
			marker:SetBackdrop(BACKDROP)
			SetBackdropColors(marker, COLORS.scrollThumb, COLORS.borderNone)
		end
		marker:Show()
	end
end

function SkinEngine:ApplyScrollThumbState(scrollBar, thumb, interactionState)
	if not self:IsActive() or not scrollBar or IsForbidden(scrollBar) then
		return
	end

	if scrollBar.BFL_DarkScrollThumbDragging then
		interactionState = "down"
	elseif not interactionState and scrollBar.BFL_DarkScrollThumbOver then
		interactionState = "hover"
	end

	local color = COLORS.scrollThumb
	if interactionState == "down" then
		color = COLORS.scrollThumbDown
	elseif interactionState == "hover" then
		color = COLORS.scrollThumbHover
	end

	if scrollBar.BFL_DarkScrollThumb then
		SetBackdropColors(scrollBar.BFL_DarkScrollThumb, color, COLORS.borderNone)
	elseif thumb and thumb.BFL_DarkBackdrop then
		SetBackdropColors(thumb.BFL_DarkBackdrop, color, COLORS.borderNone)
	end
end

function SkinEngine:InstallScrollThumbHooks(scrollBar, thumb)
	if not scrollBar or scrollBar.BFL_DarkScrollThumbHooked then
		return
	end

	scrollBar.BFL_DarkScrollThumbHooked = true
	local owner = scrollBar
	local target = thumb

	local function refresh(interactionState)
		if SkinEngine:IsActive() then
			SkinEngine:ApplyScrollThumbState(owner, target, interactionState)
		end
	end

	if target and target.HookScript then
		target:HookScript("OnEnter", function()
			owner.BFL_DarkScrollThumbOver = true
			refresh("hover")
		end)
		target:HookScript("OnLeave", function()
			owner.BFL_DarkScrollThumbOver = nil
			refresh()
		end)
		target:HookScript("OnMouseDown", function(_, buttonName)
			if buttonName == "LeftButton" then
				owner.BFL_DarkScrollThumbDragging = true
				refresh("down")
			end
		end)
		target:HookScript("OnMouseUp", function(_, buttonName)
			if buttonName == "LeftButton" then
				owner.BFL_DarkScrollThumbDragging = nil
				owner.BFL_DarkScrollThumbOver = MouseIsOver and MouseIsOver(target)
				refresh(owner.BFL_DarkScrollThumbOver and "hover" or nil)
			end
		end)
		target:HookScript("OnHide", function()
			owner.BFL_DarkScrollThumbDragging = nil
			owner.BFL_DarkScrollThumbOver = nil
			refresh()
		end)
	elseif owner.HookScript then
		owner:HookScript("OnEnter", function(self)
			self.BFL_DarkScrollThumbOver = true
			refresh("hover")
		end)
		owner:HookScript("OnLeave", function(self)
			self.BFL_DarkScrollThumbOver = nil
			refresh()
		end)
		owner:HookScript("OnMouseDown", function(self, buttonName)
			if buttonName == "LeftButton" then
				self.BFL_DarkScrollThumbDragging = true
				refresh("down")
			end
		end)
		owner:HookScript("OnMouseUp", function(self, buttonName)
			if buttonName == "LeftButton" then
				self.BFL_DarkScrollThumbDragging = nil
				self.BFL_DarkScrollThumbOver = MouseIsOver and MouseIsOver(self)
				refresh(self.BFL_DarkScrollThumbOver and "hover" or nil)
			end
		end)
	end

	if owner.HookScript then
		owner:HookScript("OnHide", function(self)
			self.BFL_DarkScrollThumbDragging = nil
			self.BFL_DarkScrollThumbOver = nil
			refresh()
		end)
	end
end

function SkinEngine:RefreshScrollBarSteppers(scrollBar)
	if not self:IsActive() or not scrollBar or IsForbidden(scrollBar) then
		return
	end

	local button = scrollBar.ScrollUpButton
	if button and button.BFL_DarkArrowButton then
		self:RefreshArrowButton(button)
		self:ApplyButtonState(button)
	end
	button = scrollBar.ScrollDownButton
	if button and button.BFL_DarkArrowButton then
		self:RefreshArrowButton(button)
		self:ApplyButtonState(button)
	end
	button = scrollBar.Back
	if button and button.BFL_DarkArrowButton then
		self:RefreshArrowButton(button)
		self:ApplyButtonState(button)
	end
	button = scrollBar.Forward
	if button and button.BFL_DarkArrowButton then
		self:RefreshArrowButton(button)
		self:ApplyButtonState(button)
	end
end

function SkinEngine:InstallScrollBarStepperHooks(scrollBar)
	if not scrollBar or scrollBar.BFL_DarkStepperHooksInstalled then
		return
	end

	scrollBar.BFL_DarkStepperHooksInstalled = true
	local function refresh()
		if SkinEngine:IsActive() then
			SkinEngine:RefreshScrollBarSteppers(scrollBar)
		end
	end
	local function refreshSoon()
		refresh()
		if C_Timer and C_Timer.After then
			C_Timer.After(0, refresh)
		end
	end
	local function hookScript(frame, scriptName)
		if not frame or not frame.HookScript then
			return
		end
		if frame.HasScript then
			local ok, hasScript = pcall(frame.HasScript, frame, scriptName)
			if ok and not hasScript then
				return
			end
		end
		pcall(frame.HookScript, frame, scriptName, refreshSoon)
	end

	hookScript(scrollBar, "OnShow")
	if IsObjectType(scrollBar, "Slider") then
		hookScript(scrollBar, "OnValueChanged")
	end

	local parent = scrollBar.GetParent and scrollBar:GetParent()
	hookScript(parent, "OnShow")
	hookScript(parent, "OnScrollRangeChanged")
	hookScript(parent, "OnVerticalScroll")

	if C_Timer and C_Timer.After then
		C_Timer.After(0, refresh)
	end
end

function SkinEngine:SkinScrollBar(scrollBar)
	if not self:IsActive() or not scrollBar or IsForbidden(scrollBar) then
		return
	end

	if scrollBar.BFL_DarkWideScrollbar == nil and self:IsBFLFrame(scrollBar) then
		scrollBar.BFL_DarkWideScrollbar = true
	end
	if scrollBar.BFL_DarkWideScrollbar then
		self:SetFrameSize(scrollBar, DARK_SCROLLBAR_WIDTH)
	end
	local setupKey = (scrollBar.BFL_DarkWideScrollbar and "wide" or "normal")
		.. ":"
		.. tostring(scrollBar.ScrollUpButton)
		.. ":"
		.. tostring(scrollBar.ScrollDownButton)
		.. ":"
		.. tostring(scrollBar.Back)
		.. ":"
		.. tostring(scrollBar.Forward)
		.. ":"
		.. tostring(scrollBar.Track)
		.. ":"
		.. tostring(scrollBar.GetThumbTexture and scrollBar:GetThumbTexture() or nil)
	if scrollBar.BFL_DarkScrollBarSkinned and scrollBar.BFL_DarkScrollBarSetupKey == setupKey then
		self:ApplyScrollThumbState(scrollBar, scrollBar.BFL_DarkScrollThumbFrame)
		return
	end
	scrollBar.BFL_DarkScrollBarSkinned = true
	scrollBar.BFL_DarkScrollBarSetupKey = setupKey

	local trackInsets = scrollBar.BFL_DarkWideScrollbar and ZERO_INSETS or SCROLLBAR_TRACK_INSETS
	self:CreateBackdrop(scrollBar, "scrollbar", trackInsets)
	self:DampenRegions(scrollBar, 0)
	self:DampenNamedTextures(scrollBar, 0, {
		"Top",
		"Bottom",
		"Middle",
		"Background",
		"ScrollBarTop",
		"ScrollBarBottom",
		"ScrollBarMiddle",
	})

	local thumb = scrollBar.GetThumbTexture and scrollBar:GetThumbTexture()
	if thumb then
		self:SkinScrollTextureThumb(scrollBar, thumb)
	end

	local thumbFrame = thumb
	if scrollBar.Track then
		self:DampenRegions(scrollBar.Track, 0)
		if scrollBar.BFL_DarkWideScrollbar then
			self:SetFrameSize(scrollBar.Track, 14)
			local topStepper = scrollBar.Back or scrollBar.ScrollUpButton
			local bottomStepper = scrollBar.Forward or scrollBar.ScrollDownButton
			if topStepper and bottomStepper then
				self:SetFramePoints(scrollBar.Track, {
					{ "TOP", topStepper, "BOTTOM", 0, -2 },
					{ "BOTTOM", bottomStepper, "TOP", 0, 2 },
				})
			else
				self:SetFramePoints(scrollBar.Track, {
					{ "TOP", scrollBar, "TOP", 0, -18 },
					{ "BOTTOM", scrollBar, "BOTTOM", 0, 18 },
				})
			end
		end
		if scrollBar.BFL_DarkWideScrollbar and scrollBar.Track.Thumb then
			self:SetFrameSize(scrollBar.Track.Thumb, 12)
		end
		thumbFrame = scrollBar.Track.Thumb
		self:SkinScrollThumb(thumbFrame)
	end
	scrollBar.BFL_DarkScrollThumbFrame = thumbFrame
	self:InstallScrollThumbHooks(scrollBar, thumbFrame)
	self:ApplyScrollThumbState(scrollBar, thumbFrame)
	local useInternalStepperLayout = scrollBar.BFL_DarkWideScrollbar and scrollBar.Track
	if scrollBar.ScrollUpButton then
		scrollBar.ScrollUpButton.BFL_DarkScrollStepper = true
		self:SkinArrowButton(scrollBar.ScrollUpButton, "up")
		if scrollBar.BFL_DarkWideScrollbar then
			self:SetFrameSize(scrollBar.ScrollUpButton, DARK_SCROLLBAR_WIDTH, DARK_SCROLLBAR_STEPPER_HEIGHT)
			self:SetFramePoints(scrollBar.ScrollUpButton, {
				{ "TOP", scrollBar, "TOP", 0, DARK_SCROLLBAR_STEPPER_TOP_OFFSET_Y },
			})
		end
		self:RefreshArrowButton(scrollBar.ScrollUpButton)
	end
	if scrollBar.ScrollDownButton then
		scrollBar.ScrollDownButton.BFL_DarkScrollStepper = true
		self:SkinArrowButton(scrollBar.ScrollDownButton, "down")
		if scrollBar.BFL_DarkWideScrollbar then
			self:SetFrameSize(scrollBar.ScrollDownButton, DARK_SCROLLBAR_WIDTH, DARK_SCROLLBAR_STEPPER_HEIGHT)
			self:SetFramePoints(scrollBar.ScrollDownButton, {
				{ "BOTTOM", scrollBar, "BOTTOM", 0, DARK_SCROLLBAR_STEPPER_BOTTOM_OFFSET_Y },
			})
		end
		self:RefreshArrowButton(scrollBar.ScrollDownButton)
	end
	if scrollBar.Back then
		scrollBar.Back.BFL_DarkScrollStepper = true
		self:SkinArrowButton(scrollBar.Back, "up")
		if scrollBar.BFL_DarkWideScrollbar then
			self:SetFrameSize(scrollBar.Back, DARK_SCROLLBAR_WIDTH, DARK_SCROLLBAR_STEPPER_HEIGHT)
			self:SetFramePoints(scrollBar.Back, {
				{ "TOP", scrollBar, "TOP", 0, DARK_SCROLLBAR_STEPPER_TOP_OFFSET_Y },
			})
		end
		self:RefreshArrowButton(scrollBar.Back)
	end
	if scrollBar.Forward then
		scrollBar.Forward.BFL_DarkScrollStepper = true
		self:SkinArrowButton(scrollBar.Forward, "down")
		if scrollBar.BFL_DarkWideScrollbar then
			self:SetFrameSize(scrollBar.Forward, DARK_SCROLLBAR_WIDTH, DARK_SCROLLBAR_STEPPER_HEIGHT)
			self:SetFramePoints(scrollBar.Forward, {
				{ "BOTTOM", scrollBar, "BOTTOM", 0, DARK_SCROLLBAR_STEPPER_BOTTOM_OFFSET_Y },
			})
		end
		self:RefreshArrowButton(scrollBar.Forward)
	end
	self:InstallScrollBarStepperHooks(scrollBar)
	self:RefreshScrollBarSteppers(scrollBar)
end

function SkinEngine:SkinSliderThumb(slider, thumb)
	if not slider or not thumb then
		return
	end

	if thumb.SetAlpha then
		self:SetTextureAlpha(slider, thumb, 0)
	end

	local marker = slider.BFL_DarkSliderThumb
	if not marker and CreateFrame then
		local template = BackdropTemplateMixin and "BackdropTemplate" or nil
		marker = CreateFrame("Frame", nil, slider, template)
		marker:SetSize(10, 10)
		marker:EnableMouse(false)
		slider.BFL_DarkSliderThumb = marker
		self:RegisterOverlay(slider, marker)
	end

	if marker then
		marker:ClearAllPoints()
		marker:SetPoint("CENTER", thumb, "CENTER", 0, 0)
		if marker.SetFrameLevel then
			marker:SetFrameLevel((slider:GetFrameLevel() or 1) + 2)
		end
		if marker.SetBackdrop then
			marker:SetBackdrop(BACKDROP)
			marker:SetBackdropColor(UnpackColor(COLORS.sliderThumb))
			marker:SetBackdropBorderColor(UnpackColor(COLORS.borderNone))
		end
		marker:Show()
	end
end

function SkinEngine:SkinSlider(slider)
	if not self:IsActive() or not slider or IsForbidden(slider) then
		return
	end

	if slider.Slider and slider.Slider ~= slider then
		self:SkinSlider(slider.Slider)
		if slider.Back then
			self:SkinArrowButton(slider.Back, "left")
		end
		if slider.Forward then
			self:SkinArrowButton(slider.Forward, "right")
		end
		for _, label in ipairs({
			slider.LeftText,
			slider.RightText,
			slider.TopText,
			slider.MinText,
			slider.MaxText,
		}) do
			if label then
				self:SetFontColor(slider, label, 1, 0.82, 0, 1)
			end
		end
		return
	end

	self:CreateBackdrop(slider, "slider", slider.BFL_DarkSliderTrackInsets or { left = 0, right = 0, top = 6, bottom = 6 })
	self:DampenNamedTextures(slider, 0, {
		"Left",
		"Middle",
		"Right",
		"Background",
		"Border",
	})
	self:DampenRegions(slider, 0)

	local thumb = slider.Thumb or (slider.GetThumbTexture and slider:GetThumbTexture())
	self:SkinSliderThumb(slider, thumb)
end

function SkinEngine:SkinColorSwatch(button)
	if not self:IsActive() or not button or IsForbidden(button) then
		return
	end

	button.BFL_DarkColorSwatchButton = true
	self:CreateBackdrop(button, "control", ZERO_INSETS)
end

local function IsGroupHeaderRow(row)
	return row
		and row.groupId
		and not row.friendData
		and (row.elementData or row.CountText or row.DownArrow or row.RightArrow)
end

function SkinEngine:SkinRow(row)
	if not self:IsActive() or not row or IsForbidden(row) then
		return
	end

	if not row.BFL_DarkRowSkinned then
		row.BFL_DarkRowSkinned = true
		self:CreateBackdrop(row, "row", ZERO_INSETS)
		self:InstallRowHooks(row)
		if row.BFL_DarkRowOver == nil and MouseIsOver then
			row.BFL_DarkRowOver = MouseIsOver(row) or nil
		end
	end
	if row.background and row.BFL_DarkRowBackground ~= row.background then
		row.BFL_DarkRowBackground = row.background
		self:SetTextureAlpha(row, row.background, 0)
	end
	if row.BG and row.BFL_DarkRowBG ~= row.BG then
		row.BFL_DarkRowBG = row.BG
		self:SetTextureAlpha(row, row.BG, 0)
	end
	local highlight = row.HighlightTexture or (row.GetHighlightTexture and row:GetHighlightTexture())
	if row.BFL_DarkRowHighlightTexture ~= highlight then
		row.BFL_DarkRowHighlightTexture = highlight
		if highlight then
			self:SetTextureAlpha(row, highlight, 0)
		end
	end

	local noRowHighlight = IsGroupHeaderRow(row) == true
	if row.BFL_DarkNoRowHighlight ~= noRowHighlight then
		row.BFL_DarkNoRowHighlight = noRowHighlight
		row.BFL_DarkRowStateKey = nil
	end
	if noRowHighlight then
		row.BFL_DarkRowMouseDown = nil
		if row.UnlockHighlight then
			row:UnlockHighlight()
		end
	end

	self:ApplyRowState(row, row.BFL_DarkRowOver and "hover" or nil)

	if row.travelPassButton then
		self:RefreshTravelPassButton(row.travelPassButton)
	end
	if row.PartyButton then
		self:RefreshTravelPassButton(row.PartyButton)
	end
end

function SkinEngine:RefreshRow(row)
	if not self:IsActive() or not row or IsForbidden(row) then
		return
	end

	if not row.BFL_DarkRowSkinned then
		self:SkinRow(row)
		return
	end

	local noRowHighlight = IsGroupHeaderRow(row) == true
	if row.BFL_DarkNoRowHighlight ~= noRowHighlight then
		row.BFL_DarkNoRowHighlight = noRowHighlight
		row.BFL_DarkRowStateKey = nil
	end

	local highlight = row.HighlightTexture or (row.GetHighlightTexture and row:GetHighlightTexture())
	if
		(row.background and row.BFL_DarkRowBackground ~= row.background)
		or (row.BG and row.BFL_DarkRowBG ~= row.BG)
		or row.BFL_DarkRowHighlightTexture ~= highlight
	then
		self:SkinRow(row)
		return
	end

	self:ApplyRowState(row, row.BFL_DarkRowOver and "hover" or nil)

	if row.travelPassButton then
		self:RefreshTravelPassButton(row.travelPassButton)
	end
	if row.PartyButton then
		self:RefreshTravelPassButton(row.PartyButton)
	end
end

function SkinEngine:ApplyRowState(row, interactionState)
	if not self:IsActive() or not row or IsForbidden(row) then
		return
	end

	local noRowHighlight = row.BFL_DarkNoRowHighlight
	if noRowHighlight == nil then
		noRowHighlight = IsGroupHeaderRow(row) == true
		row.BFL_DarkNoRowHighlight = noRowHighlight
	end
	local stateKey = (noRowHighlight and "noHighlight" or (interactionState or "normal"))
		.. ":"
		.. (row.BFL_DarkRowMouseDown and "down" or "")
	if row.BFL_DarkRowStateKey == stateKey then
		return
	end
	row.BFL_DarkRowStateKey = stateKey

	if noRowHighlight then
		row.BFL_DarkNoRowHighlight = true
		row.BFL_DarkRowMouseDown = nil
		if row.UnlockHighlight then
			row:UnlockHighlight()
		end
		local highlight = row.HighlightTexture or (row.GetHighlightTexture and row:GetHighlightTexture())
		self:SetTextureAlpha(row, highlight, 0)
		self:StyleBackdrop(row, COLORS.row, COLORS.borderNone)
		return
	end

	local bg = COLORS.row
	if row.BFL_DarkRowMouseDown then
		bg = COLORS.rowDown
	elseif interactionState == "hover" then
		bg = COLORS.rowHover
	end

	self:StyleBackdrop(row, bg, COLORS.borderNone)
end

function SkinEngine:InstallRowHooks(row)
	if not row or row.BFL_DarkRowHooked or not row.HookScript then
		return
	end

	row.BFL_DarkRowHooked = true
	row:HookScript("OnEnter", function(self)
		self.BFL_DarkRowOver = true
		if SkinEngine:IsActive() then
			SkinEngine:ApplyRowState(self, "hover")
		end
	end)
	row:HookScript("OnLeave", function(self)
		self.BFL_DarkRowOver = nil
		if SkinEngine:IsActive() then
			SkinEngine:ApplyRowState(self)
		end
	end)
	row:HookScript("OnMouseDown", function(self, buttonName)
		if SkinEngine:IsActive() and buttonName == "LeftButton" then
			self.BFL_DarkRowMouseDown = true
			SkinEngine:ApplyRowState(self, "down")
		end
	end)
	row:HookScript("OnMouseUp", function(self, buttonName)
		if SkinEngine:IsActive() and buttonName == "LeftButton" then
			self.BFL_DarkRowMouseDown = nil
			local isOver = self.BFL_DarkRowOver or (MouseIsOver and MouseIsOver(self))
			SkinEngine:ApplyRowState(self, isOver and "hover" or nil)
		end
	end)
	row:HookScript("OnHide", function(self)
		self.BFL_DarkRowMouseDown = nil
		if SkinEngine:IsActive() then
			SkinEngine:ApplyRowState(self)
		end
	end)
end

function SkinEngine:SkinTooltip(tooltip)
	if not self:IsActive() or not tooltip or IsForbidden(tooltip) then
		return
	end

	if tooltip.NineSlice then
		self:SetTextureAlpha(tooltip, tooltip.NineSlice, 0)
	end

	self:SkinFrame(tooltip, "popup")
	tooltip.bflDarkSkinned = true
end

function SkinEngine:SkinControl(control)
	if not self:IsActive() or not control then
		return
	end

	local objectType = GetObjectType(control)
	if self:IsDropdownControl(control) then
		self:SkinDropdown(control)
	elseif objectType == "Button" then
		self:SkinButton(control)
	elseif objectType == "CheckButton" then
		self:SkinCheckButton(control)
	elseif objectType == "EditBox" then
		self:SkinEditBox(control)
	elseif objectType == "Slider" then
		self:SkinSlider(control)
	elseif objectType == "FontString" then
		local parent = control.GetParent and control:GetParent()
		self:SetFontColor(parent or control, control, 0.88, 0.88, 0.88, 1)
	end

	if control.DropDown then
		self:SkinDropdown(control.DropDown)
	end
	if control.RightDropdown then
		self:SkinDropdown(control.RightDropdown)
	end
	if control.Input then
		self:SkinEditBox(control.Input)
	end
	if control.Slider then
		self:SkinSlider(control.Slider)
	end
	if control.checkBox then
		self:SkinCheckButton(control.checkBox)
	end
	if control.LeftCheckbox then
		self:SkinCheckButton(control.LeftCheckbox)
	end
	if control.colorButton then
		self:SkinColorSwatch(control.colorButton)
	end
	if control.LeftButton then
		self:SkinButton(control.LeftButton)
	end
	if control.RightButton then
		self:SkinButton(control.RightButton)
	end
	if control.Label then
		self:SetFontColor(control, control.Label, 0.88, 0.88, 0.88, 1)
	end
	if control.ValueLabel then
		self:SetFontColor(control, control.ValueLabel, 1, 0.82, 0, 1)
	end
	if control.text then
		self:SetFontColor(control, control.text, 1, 0.82, 0, 1)
	end

	self:SkinTree(control, 2)
end

function SkinEngine:SkinTree(root, maxDepth, currentDepth)
	if not self:IsActive() or not root or IsForbidden(root) or not root.GetChildren then
		return
	end

	currentDepth = currentDepth or 0
	maxDepth = maxDepth or 4
	if currentDepth > maxDepth then
		return
	end

	for _, child in ipairs(GetCachedChildFrames(root) or {}) do
		if child and not IsForbidden(child) then
			local objectType = GetObjectType(child)
			local lowerName = LowerName(child)

			if IsScrollBarFrame(child) then
				self:SkinScrollBar(child)
			elseif self:IsDropdownControl(child) then
				self:SkinDropdown(child)
			elseif IsObjectType(child, "EditBox") then
				self:SkinEditBox(child)
			elseif IsObjectType(child, "CheckButton") then
				self:SkinCheckButton(child)
			elseif IsObjectType(child, "Slider") then
				self:SkinSlider(child)
			elseif IsObjectType(child, "Button") then
				if IsButtonChromeSuppressed(child) then
					self:RestoreFrame(child)
				elseif IsRAFNativeTextureButton(child) then
					self:SkinNativeTextureButton(child)
				elseif child.BFL_DarkColorSwatchButton then
					self:SkinColorSwatch(child)
				elseif lowerName:find("tab") then
					self:SkinTab(child)
				elseif lowerName:find("close") then
					self:SkinCloseButton(child)
				elseif lowerName:find("header") or lowerName:find("row") or lowerName:find("button%d") then
					self:SkinRow(child)
				else
					self:SkinButton(child)
				end
			elseif lowerName:find("dropdown") then
				self:SkinDropdown(child)
			elseif lowerName:find("nineslice") or lowerName:find("border") then
				self:DampenFrameTextures(child, 0, 2)
			elseif lowerName:find("scrollbar") or lowerName:find("scrollbar") or lowerName:find("scroll") then
				if objectType == "EventFrame" or objectType == "Slider" then
					self:SkinScrollBar(child)
				end
			elseif lowerName:find("inset") or lowerName:find("panel") or lowerName:find("frame") then
				self:SkinFrame(child, lowerName:find("inset") and "inset" or "panel")
			end

			self:SkinTree(child, maxDepth, currentDepth + 1)
		end
	end
end

function SkinEngine:RestoreFrame(frame)
	local state = frame and frame.BFL_DarkSkin
	if not state then
		return
	end
	state.textureAlpha = state.textureAlpha or {}
	state.textureVertexColors = state.textureVertexColors or {}
	state.textureBlendModes = state.textureBlendModes or {}
	state.fontColors = state.fontColors or {}
	state.fontJustify = state.fontJustify or {}
	state.regionPoints = state.regionPoints or {}
	state.regionSizes = state.regionSizes or {}
	state.shown = state.shown or {}
	state.overlays = state.overlays or {}

	if frame.SetScript and frame.BFL_DarkOriginalOnMouseDownSet then
		frame:SetScript("OnMouseDown", frame.BFL_DarkOriginalOnMouseDown)
		frame.BFL_DarkOriginalOnMouseDown = nil
		frame.BFL_DarkOriginalOnMouseDownSet = nil
		frame.BFL_DarkCustomDropdownInstalled = nil
	end
	if frame.BFL_DarkCustomButton and frame.BFL_DarkCustomButton.SetScript then
		frame.BFL_DarkCustomButton:SetScript("OnClick", frame.BFL_DarkOriginalButtonOnClick)
		frame.BFL_DarkCustomButton = nil
		frame.BFL_DarkOriginalButtonOnClick = nil
		frame.BFL_DarkOriginalButtonOnClickSet = nil
	end

	if frame.BFL_DarkBackdrop then
		frame.BFL_DarkBackdrop:Hide()
	end

	if state.points and frame.ClearAllPoints and frame.SetPoint then
		frame:ClearAllPoints()
		for _, point in ipairs(state.points) do
			ApplyStoredPoint(frame, point)
		end
		state.points = nil
	end

	if state.size and frame.SetSize then
		frame:SetSize(state.size[1], state.size[2])
		state.size = nil
	end

	local restoredRegionPoints = {}
	for region, points in pairs(state.regionPoints) do
		if region and region.ClearAllPoints and region.SetPoint then
			region:ClearAllPoints()
			for _, point in ipairs(points) do
				ApplyStoredPoint(region, point)
			end
			restoredRegionPoints[region] = true
		end
	end
	wipe(state.regionPoints)

	for region, size in pairs(state.regionSizes) do
		if region and region.SetSize and size[1] and size[2] then
			region:SetSize(size[1], size[2])
		end
	end
	wipe(state.regionSizes)

	if frame.BFL_DarkTabButton then
		local fs = frame.Text or (frame.GetFontString and frame:GetFontString())
		local originalPoints = frame.BFL_DarkOriginalTextPoints
		if fs and originalPoints and originalPoints[1] and not restoredRegionPoints[fs] then
			fs:ClearAllPoints()
			fs:SetPoint(unpack(originalPoints))
		end
		frame.BFL_DarkTabButton = nil
		frame.BFL_DarkTabSelected = nil
		frame.BFL_DarkTabSkinned = nil
		frame.BFL_DarkTextCentered = nil
		frame.BFL_DarkOriginalTextPoints = nil
		if fs then
			fs.BFL_DarkCenteredForTab = nil
		end
		if state.tabUseTextCenterStored then
			frame.BFL_UseTextCenter = state.tabUseTextCenter
			state.tabUseTextCenterStored = nil
			state.tabUseTextCenter = nil
		else
			frame.BFL_UseTextCenter = false
		end
	end

	if state.overlays then
		for overlay, _ in pairs(state.overlays) do
			if overlay and overlay.Hide then
				overlay:Hide()
			end
		end
	end

	for texture, alpha in pairs(state.textureAlpha) do
		if texture and texture.SetAlpha then
			texture:SetAlpha(alpha)
		end
	end
	wipe(state.textureAlpha)

	for texture, color in pairs(state.textureVertexColors) do
		if texture and texture.SetVertexColor then
			texture:SetVertexColor(color[1], color[2], color[3], color[4] or 1)
		end
	end
	wipe(state.textureVertexColors)

	for texture, blendMode in pairs(state.textureBlendModes) do
		if texture and texture.SetBlendMode then
			texture:SetBlendMode(blendMode or "BLEND")
		end
	end
	wipe(state.textureBlendModes)

	if state.shown then
		for object, shown in pairs(state.shown) do
			if object then
				if object.SetShown then
					object:SetShown(shown == true)
				elseif shown and object.Show then
					object:Show()
				elseif not shown and object.Hide then
					object:Hide()
				end
			end
		end
		wipe(state.shown)
	end

	for fontString, color in pairs(state.fontColors) do
		if fontString and fontString.SetTextColor then
			fontString:SetTextColor(color[1], color[2], color[3], color[4] or 1)
		end
	end
	wipe(state.fontColors)

	for fontString, justify in pairs(state.fontJustify) do
		if fontString then
			if justify[1] and fontString.SetJustifyH then
				fontString:SetJustifyH(justify[1])
			end
			if justify[2] and fontString.SetJustifyV then
				fontString:SetJustifyV(justify[2])
			end
		end
	end
	wipe(state.fontJustify)

	if frame.bflDarkSkinned ~= nil then
		frame.bflDarkSkinned = nil
	end
	frame.BFL_DarkFrameStripTextures = nil
	frame.BFL_DarkFrameTextureAlpha = nil
	frame.BFL_DarkFrameDecorAlpha = nil
	frame.BFL_DarkRowSkinned = nil
	frame.BFL_DarkRowOver = nil
	frame.BFL_DarkRowBackground = nil
	frame.BFL_DarkRowBG = nil
	frame.BFL_DarkRowHighlightTexture = nil
	frame.BFL_DarkNoRowHighlight = nil
	frame.BFL_DarkRowMouseDown = nil
	frame.BFL_DarkRowStateKey = nil
	frame.BFL_DarkKeepFontColor = nil
	frame.BFL_DarkButtonSkinned = nil
	frame.BFL_DarkButtonStateKey = nil
	frame.BFL_DarkButtonVariant = nil
	frame.BFL_DarkButtonInsetLeft = nil
	frame.BFL_DarkButtonInsetRight = nil
	frame.BFL_DarkButtonInsetTop = nil
	frame.BFL_DarkButtonInsetBottom = nil
	frame.BFL_DarkButtonKeepNormalTexture = nil
	frame.BFL_DarkButtonTextureAlpha = nil
	frame.BFL_DarkButtonTexturesAlpha = nil
	frame.BFL_DarkButtonTextureObjects = nil
	frame.BFL_DarkButtonTextureObjectsName = nil
	frame.BFL_DarkBorderlessIconButton = nil
	frame.BFL_DarkIconButtonSkinned = nil
	frame.BFL_DarkIconButtonTextureAlpha = nil
	frame.BFL_DarkIconButtonStripRegions = nil
	frame.BFL_DarkIconButtonSize = nil
	frame.BFL_DarkIconButtonX = nil
	frame.BFL_DarkIconButtonY = nil
	frame.BFL_DarkIconButtonExplicitTexture = nil
	frame.BFL_DarkIconButtonIconPath = nil
	frame.BFL_DarkIconColor = nil
	frame.BFL_DarkIconHoverColor = nil
	frame.BFL_DarkIconDownColor = nil
	frame.BFL_DarkArrowButton = nil
	frame.BFL_DarkArrowDirection = nil
	frame.BFL_DarkArrowSkinned = nil
	frame.BFL_DarkArrowSetupDirection = nil
	frame.BFL_DarkArrowInsetLeft = nil
	frame.BFL_DarkArrowInsetRight = nil
	frame.BFL_DarkArrowInsetTop = nil
	frame.BFL_DarkArrowInsetBottom = nil
	frame.BFL_DarkArrowTexturesHidden = nil
	if frame.BFL_DarkArrowIcon then
		frame.BFL_DarkArrowIcon.BFL_DarkArrowIconAnchor = nil
		frame.BFL_DarkArrowIcon.BFL_DarkArrowIconDirection = nil
	end
	frame.BFL_DarkTravelPassButton = nil
	frame.BFL_DarkTravelPassSkinned = nil
	frame.BFL_DarkNativeTextureButton = nil
	frame.BFL_DarkColorSwatchButton = nil
	frame.BFL_DarkScrollStepper = nil
	frame.BFL_DarkSliderStepper = nil
	frame.BFL_DarkSliderTrackInsets = nil
	frame.BFL_DarkScrollThumbDragging = nil
	frame.BFL_DarkScrollThumbOver = nil
	frame.BFL_DarkWideScrollbar = nil
	frame.BFL_DarkScrollBarSkinned = nil
	frame.BFL_DarkScrollBarSetupKey = nil
	frame.BFL_DarkScrollThumbFrame = nil
	frame.BFL_DarkScrollThumbSkinned = nil
	frame.BFL_DarkCompactCheckButton = nil
	frame.BFL_DarkNoCheckChrome = nil
	frame.BFL_DarkCheckButtonInsets = nil
	frame.BFL_DarkCheckButtonNormalAlpha = nil
	frame.BFL_DarkCheckButtonPushedAlpha = nil
	frame.BFL_DarkCheckButtonDisabledAlpha = nil
	frame.BFL_DarkCheckButtonHighlightAlpha = nil
end

function SkinEngine:RestoreAll()
	for frame, _ in pairs(self.registry) do
		self:RestoreFrame(frame)
	end
	wipe(self.registry)
end

return SkinEngine
