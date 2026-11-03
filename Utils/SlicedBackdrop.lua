local _, BFL = ...

local EDGE_TEXTURE = "Interface\\AddOns\\BetterFriendlist\\Textures\\Skinning\\flat-border-1.tga"
local WHITE_TEXTURE = "interface\\buttons\\white8x8"
local sliceAvailable

local function IsWhiteTexture(path)
	return type(path) == "string" and path:lower() == WHITE_TEXTURE
end

local function CanSlice(definition)
	return type(definition) == "table" and IsWhiteTexture(definition.bgFile) and IsWhiteTexture(definition.edgeFile)
		and definition.edgeSize == 1
end

local function IsAccessible(frame)
	if frame.IsForbidden and frame:IsForbidden() then
		return false
	end
	if frame.CanBeAccessedInContext then
		local ok, accessible = pcall(frame.CanBeAccessedInContext, frame)
		return ok and accessible == true
	end
	return true
end

local function ClearDefinition(frame)
	local surface = frame.BFL_SlicedBackdrop
	if surface.definition then
		surface.definition = nil
		surface.fill:Hide()
		surface.edge:Hide()
	end
	surface.nativeClearBackdrop(frame)
end

local function SetDefinition(frame, definition)
	local surface = frame.BFL_SlicedBackdrop
	if not CanSlice(definition) then
		if surface.definition then
			ClearDefinition(frame)
		end
		surface.nativeSetBackdrop(frame, definition)
		return
	end
	if surface.definition == definition then
		return
	end

	if not surface.definition then
		surface.nativeSetBackdrop(frame, nil)
		surface.fill:Show()
		surface.edge:Show()
	end
	surface.fill:SetVertexColor(1, 1, 1, 1)
	surface.edge:SetVertexColor(1, 1, 1, 1)
	surface.definition = definition

	-- The native backdrop's fill is inset from the outer edge independently of the border.
	local insets = definition.insets
	local left, right = insets and insets.left or 0, insets and insets.right or 0
	local top, bottom = insets and insets.top or 0, insets and insets.bottom or 0
	if left ~= surface.left or right ~= surface.right or top ~= surface.top or bottom ~= surface.bottom then
		surface.fill:ClearAllPoints()
		surface.fill:SetPoint("TOPLEFT", frame, "TOPLEFT", left, -top)
		surface.fill:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -right, bottom)
		surface.left, surface.right, surface.top, surface.bottom = left, right, top, bottom
	end
end

local function GetDefinition(frame)
	local surface = frame.BFL_SlicedBackdrop
	if not surface.definition then
		return surface.nativeGetBackdrop(frame)
	end
	local definition = CopyTable(surface.definition)
	definition.tile = definition.tile or false
	definition.tileSize = definition.tileSize or 0
	if definition.tileEdge == nil then
		definition.tileEdge = true
	end
	definition.insets = {
		left = surface.left,
		right = surface.right,
		top = surface.top,
		bottom = surface.bottom,
	}
	return definition
end

local function SetFillColor(frame, r, g, b, a)
	local surface = frame.BFL_SlicedBackdrop
	if surface.definition then
		surface.fill:SetVertexColor(r, g, b, a or 1)
	else
		surface.nativeSetBackdropColor(frame, r, g, b, a)
	end
end

local function GetFillColor(frame)
	local surface = frame.BFL_SlicedBackdrop
	if surface.definition then
		return surface.fill:GetVertexColor()
	end
	return surface.nativeGetBackdropColor(frame)
end

local function SetEdgeColor(frame, r, g, b, a)
	local surface = frame.BFL_SlicedBackdrop
	if surface.definition then
		surface.edge:SetVertexColor(r, g, b, a or 1)
	else
		surface.nativeSetBackdropBorderColor(frame, r, g, b, a)
	end
end

local function GetEdgeColor(frame)
	local surface = frame.BFL_SlicedBackdrop
	if surface.definition then
		return surface.edge:GetVertexColor()
	end
	return surface.nativeGetBackdropBorderColor(frame)
end

local function Install(frame)
	local edge = frame:CreateTexture(nil, "BORDER", nil, -8)
	edge:Hide()
	if not edge.SetTextureSliceMargins then
		sliceAvailable = false
		return
	end
	-- Linear filtering would bleed the opaque edge into the stretched transparent center.
	local ok, loaded = pcall(edge.SetTexture, edge, EDGE_TEXTURE, nil, nil, "NEAREST")
	if not ok or loaded == false or not pcall(edge.SetTextureSliceMargins, edge, 1, 1, 1, 1) then
		return
	end
	edge:SetAllPoints(frame)
	local fill = frame:CreateTexture(nil, "BACKGROUND", nil, -8)
	fill:SetColorTexture(1, 1, 1, 1)
	fill:Hide()

	-- Preserve the per-frame color and restore contract. Native templates and
	-- other addons retain their own methods, including when a theme uses artwork.
	frame.BFL_SlicedBackdrop = {
		fill = fill,
		edge = edge,
		nativeSetBackdrop = frame.SetBackdrop,
		nativeClearBackdrop = frame.ClearBackdrop,
		nativeGetBackdrop = frame.GetBackdrop,
		nativeSetBackdropColor = frame.SetBackdropColor,
		nativeGetBackdropColor = frame.GetBackdropColor,
		nativeSetBackdropBorderColor = frame.SetBackdropBorderColor,
		nativeGetBackdropBorderColor = frame.GetBackdropBorderColor,
	}
	frame.SetBackdrop = SetDefinition
	frame.ClearBackdrop = ClearDefinition
	frame.GetBackdrop = GetDefinition
	frame.SetBackdropColor = SetFillColor
	frame.GetBackdropColor = GetFillColor
	frame.SetBackdropBorderColor = SetEdgeColor
	frame.GetBackdropBorderColor = GetEdgeColor
end

-- Opt in only at BFL-owned surface creation sites, before applying the flat style.
function BFL.SetOwnedBackdrop(frame, definition)
	if not frame.BFL_SlicedBackdrop and sliceAvailable ~= false and CanSlice(definition)
		and frame.CreateTexture and frame.ClearBackdrop and frame.GetBackdrop
		and frame.GetBackdropColor and frame.GetBackdropBorderColor
		and (not InCombatLockdown or not InCombatLockdown()) and IsAccessible(frame)
	then
		Install(frame)
	end
	frame:SetBackdrop(definition)
end
