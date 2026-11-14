local _, BFL = ...

-- All calculations use UIParent coordinates, including windows with a different scale.
local Geometry = {}
BFL.WindowGeometry = Geometry

function Geometry:GetRatio(frame)
	return frame:GetEffectiveScale() / UIParent:GetEffectiveScale()
end

function Geometry:GetRect(frame)
	local left, bottom, width, height = frame:GetRect()
	if not left then return end
	local ratio = self:GetRatio(frame)
	return left * ratio, bottom * ratio, width * ratio, height * ratio
end

function Geometry:Fit(left, top, width, height, margin)
	margin = margin or 0
	local screenWidth, screenHeight = UIParent:GetSize()
	left = math.max(margin, math.min(left, screenWidth - width - margin))
	top = math.min(screenHeight - margin, math.max(top, height + margin))
	return left, top
end

function Geometry:SetTopLeft(frame, left, top)
	local ratio = self:GetRatio(frame)
	frame:ClearAllPoints()
	frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left / ratio, top / ratio)
end

function Geometry:Dock(window, owner, gap, topOffset, leftGap, preferredSide)
	local left, bottom, width, height = self:GetRect(owner)
	if not left then return false end
	local ratio = self:GetRatio(window)
	local windowWidth, windowHeight = window:GetWidth() * ratio, window:GetHeight() * ratio
	local screenWidth = UIParent:GetWidth()
	local right = left + width + gap
	local otherSide = left - (leftGap or gap) - windowWidth
	local side = preferredSide == "left" and "left" or "right"
	if side == "left" and otherSide < 0 and right + windowWidth <= screenWidth then
		side = "right"
	elseif side == "right" and right + windowWidth > screenWidth and otherSide >= 0 then
		side = "left"
	end
	local x = side == "left" and otherSide or right
	local top = bottom + height + topOffset
	x, top = self:Fit(x, top, windowWidth, windowHeight, 4)
	-- Keep the owner relationship after fitting. The window follows its owner
	-- immediately while dragging; the docking refresh only has to reconsider sides.
	window:ClearAllPoints()
	if side == "left" then
		window:SetPoint("TOPRIGHT", owner, "TOPLEFT", (x + windowWidth - left) / ratio, (top - bottom - height) / ratio)
	else
		window:SetPoint("TOPLEFT", owner, "TOPRIGHT", (x - left - width) / ratio, (top - bottom - height) / ratio)
	end
	return true, side
end
