-- The PowerShell runner supplies the fixture, width and optional nickname hint state.
-- Load through wow-sim --exec-lua only. This file is excluded from the addon package.
assert(A_Admin and A_Admin.SetManualClock and A_Admin.AdvanceTime, "WoW UI Simulator is required")
local slash = assert(SlashCmdList.BETTERFRIENDLIST, "BetterFriendlist did not register /bfl")
local preview = assert(BFL:GetModule("PreviewMode"))
local settings = assert(BFL:GetModule("FrameSettings"))
local frame = assert(BetterFriendsFrame)
local profileID, profileDefinition = preview:GetProfileDefinition(profile)
assert(profileDefinition, "Unknown BFL preview profile: " .. profile)

A_Admin.SetManualClock(GetTime())
if hintStyle then
	local friendsUI = assert(BFL:GetModule("FriendsUI"))
	assert(friendsUI:SetStyle(hintStyle) and friendsUI:GetAppliedStyle() == hintStyle,
		"Could not switch the simulator friends window to " .. hintStyle)
end
local layout = settings:GetLayoutKey()
local defaultWidth, height = settings:GetDefaultSize(layout)
-- Let the production size handler clamp the narrow variant to its supported minimum.
settings:ApplySize(narrow and 1 or defaultWidth, height)
slash("preview " .. profile)
for _ = 1, 160 do
	if not preview.activationInProgress then
		break
	end
	A_Admin.AdvanceTime(0.016)
end
assert(preview.activeProfile == profileID and not preview.activationInProgress and not preview.activationTrace,
	"BFL preview did not finish: " .. profile)
assert(frame:IsVisible(), "BFL friends frame is hidden")
assert(not narrow or frame:GetWidth() < defaultWidth, "Narrow capture did not shrink the frame")
if profileDefinition.section then
	assert(preview.activeSection == profileDefinition.section, "BFL preview did not open " .. profileDefinition.section)
end

frame:ClearAllPoints()
frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 40, -32)
for _ = 1, 8 do
	A_Admin.AdvanceTime(0.016)
end

local function restoreCardAlignment(parent)
	if not parent:IsVisible() then
		return
	end
	-- These fields together identify the visible friend cards. Their star anchors stay as rendered.
	if parent.Name and parent.Info and parent.favoriteIcon then
		for _, key in ipairs(leftAlignedFields) do
			local text = parent[key]
			if text:GetJustifyH() == "CENTER" then
				text:SetJustifyH("LEFT")
			end
		end
	end
	for _, child in ipairs({ parent:GetChildren() }) do
		restoreCardAlignment(child)
	end
end

if layout == "RetailModern" and #leftAlignedFields > 0 then
	restoreCardAlignment(frame)
end

if hintStyle then
	assert(BFL:GetModule("NicknameHints")):ShowPreview()
	local hints = assert(BFL:GetModule("FeatureHints"))
	local badge = assert(hints.frame)
	if hintExpanded then badge.more:Click() end
	for _ = 1, 8 do A_Admin.AdvanceTime(0.016) end

	assert(badge:IsVisible() and badge.modern == (hintStyle == "modern"), "Incorrect nickname hint style")
	assert(badge.details:IsVisible() == hintExpanded and not badge.pager:IsVisible(), "Incorrect nickname hint state")
	local scale = badge:GetEffectiveScale()
	local function Edge(region, method)
		return region[method](region) * region:GetEffectiveScale() / scale
	end
	local bounds = hints:GetDockBounds()
	assert(math.abs(badge:GetTop() - Edge(frame, "GetTop")) < 1, "The nickname hint title is misaligned")
	assert(math.abs(badge:GetLeft() - Edge(frame, "GetRight")) < 1, "The nickname hint is no longer docked")
	if hintExpanded and hintStyle == "modern" then
		assert(bounds.tabRight and bounds.tabTop, "The Modern scene has no visible side tabs")
		assert(Edge(badge.details, "GetLeft") >= bounds.tabRight, "The detail area overlaps the side tabs")
		local _, shelf, inner = unpack(badge.nativeBorderClips)
		local gap = Edge(shelf, "GetBottom") - bounds.tabTop
		local transparentGutter = BFL.IsForever and 5 or 2
		assert(gap >= -0.5 and Edge(inner, "GetLeft") >= bounds.tabRight - transparentGutter - 0.5,
			"The native frame overlaps visible side-tab art")
		assert(not inner:IsMouseEnabled(), "The decorative frame intercepts side-tab clicks")
		local shelfMarker = CreateFrame("Frame", "BFLUISimNicknameShelf", frame)
		shelfMarker:SetSize(1, 1)
		shelfMarker:SetPoint("BOTTOMLEFT", shelf, "BOTTOMLEFT")
		shelfMarker:Hide()
	elseif hintExpanded then
		assert(math.abs(Edge(badge.details, "GetLeft") - badge:GetLeft()) < 1, "Legacy details do not align with the card")
	end
	if hintExpanded then
		assert(math.abs(Edge(badge.details, "GetRight") - badge:GetRight()) < 1, "The hint's right edge splits on expansion")
	end
	if hintFade then
		badge.elapsed = badge.displaySeconds
		A_Admin.AdvanceTime(0.5)
		assert(badge:IsVisible() and math.abs(badge:GetAlpha() - 0.5) < 0.05, "The hint is not midway through its fade")
	end
end

-- The screenshot command can exit zero after a Lua error. Its frame dump must include this marker.
local marker = CreateFrame("Frame", "BFLUISimCaptureComplete", frame)
marker:SetSize(1, 1)
marker:SetPoint("TOPLEFT")
marker:Hide()
