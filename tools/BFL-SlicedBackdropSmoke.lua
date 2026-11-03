-- Lua 5.4: lua tools/BFL-SlicedBackdropSmoke.lua <repo>
local BFL = {}
assert(loadfile(assert(arg[1]) .. "/Utils/SlicedBackdrop.lua"))("BetterFriendlist", BFL)

function CopyTable(source)
	local copy = {}
	for key, value in pairs(source) do
		copy[key] = type(value) == "table" and CopyTable(value) or value
	end
	return copy
end

local function NewTexture()
	local texture = { points = {} }
	function texture:Hide() self.shown = false end
	function texture:Show() self.shown = true end
	function texture:SetTexture(path, _, _, filterMode)
		assert(filterMode == "NEAREST", "slice border must use nearest-neighbor filtering")
		local asset = assert(io.open(arg[1] .. "/" .. path:match("(Textures.*)"):gsub("\\", "/"), "rb"))
		assert(#asset:read("*a") > 18)
		asset:close()
		return true
	end
	function texture:SetAllPoints() end
	function texture:SetTextureSliceMargins(left, top, right, bottom)
		assert(left == 1 and top == 1 and right == 1 and bottom == 1)
	end
	function texture:SetColorTexture() end
	function texture:ClearAllPoints() self.points = {} end
	function texture:SetPoint(_, _, _, x, y) self.points[#self.points + 1] = { x, y } end
	function texture:SetVertexColor(...) self.color = { ... } end
	function texture:GetVertexColor() return table.unpack(self.color) end
	return texture
end

local function NewFrame(hasSlices)
	local frame = { textures = {} }
	function frame:CreateTexture()
		local texture = NewTexture()
		if not hasSlices then
			texture.SetTextureSliceMargins = nil
		end
		self.textures[#self.textures + 1] = texture
		return texture
	end
	function frame:ClearBackdrop() self.native = nil end
	function frame:SetBackdrop(definition)
		if definition == nil then
			self:ClearBackdrop()
			return
		end
		self.native = definition
		self:SetBackdropColor(1, 1, 1, 1)
		self:SetBackdropBorderColor(1, 1, 1, 1)
	end
	function frame:GetBackdrop() return self.native end
	function frame:SetBackdropColor(...) self.nativeFill = { ... } end
	function frame:GetBackdropColor() return table.unpack(self.nativeFill) end
	function frame:SetBackdropBorderColor(...) self.nativeEdge = { ... } end
	function frame:GetBackdropBorderColor() return table.unpack(self.nativeEdge) end
	return frame
end

local white = "Interface\\Buttons\\WHITE8X8"
local flat = { bgFile = white, edgeFile = white, edgeSize = 1, insets = { left = 1, bottom = 2 } }
local artwork = { edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 12 }
local frame = NewFrame(true)
BFL.SetOwnedBackdrop(frame, artwork)
assert(frame.native == artwork and #frame.textures == 0)
BFL.SetOwnedBackdrop(frame, flat)
local edge, fill = table.unpack(frame.textures)
assert(edge.shown and fill.shown and frame.native == nil)
assert(fill.points[1][1] == 1 and fill.points[2][2] == 2)
frame:SetBackdropColor(0.2, 0.3, 0.4)
frame:SetBackdropBorderColor(0.6, 0.7, 0.8, 0.9)
BFL.SetOwnedBackdrop(frame, flat)
assert(select(4, frame:GetBackdropColor()) == 1 and frame:GetBackdropColor() == 0.2)
assert(select(4, frame:GetBackdropBorderColor()) == 0.9)
frame:GetBackdrop().insets.left = 10
assert(frame:GetBackdrop().insets.left == 1)
frame:SetBackdrop(artwork)
assert(frame:GetBackdrop() == artwork and not fill.shown and not edge.shown)
frame:SetBackdropBorderColor(0.1, 0.2, 0.3, 0.4)
assert(frame:GetBackdropBorderColor() == 0.1)
frame:SetBackdrop(flat)
assert(frame:GetBackdropColor() == 1 and #frame.textures == 2)
frame:ClearBackdrop()
assert(not edge.shown and not fill.shown and frame:GetBackdrop() == nil)
frame:SetBackdrop(flat)
frame:SetBackdrop(nil)
assert(not edge.shown and not fill.shown and frame:GetBackdrop() == nil)

local scaled = CopyTable(flat)
scaled.edgeSize = 1.33
local fallback = NewFrame(true)
BFL.SetOwnedBackdrop(fallback, scaled)
assert(fallback.native == scaled and #fallback.textures == 0)
InCombatLockdown = function() return true end
BFL.SetOwnedBackdrop(fallback, flat)
assert(fallback.native == flat and #fallback.textures == 0)
InCombatLockdown = nil
BFL.SetOwnedBackdrop(fallback, flat)
assert(fallback.native == nil and #fallback.textures == 2)
local older = NewFrame(false)
BFL.SetOwnedBackdrop(older, flat)
assert(older.native == flat and not older.textures[1].shown)
local another = NewFrame(false)
BFL.SetOwnedBackdrop(another, flat)
assert(another.native == flat and #another.textures == 0)
io.write("[OK] Sliced backdrop smoke passed\n")
