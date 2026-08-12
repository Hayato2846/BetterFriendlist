-- BFL_Tooltip: Addon-owned tooltip to avoid tainting the global GameTooltip
-- Must be loaded early (after Core.lua + ClassicCompat.lua, before Modules)
local ADDON_NAME, BFL = ...

-- Create an addon-owned GameTooltip using Blizzard's template
-- This is the same pattern used by WeakAuras, Details, etc.
local tooltip = CreateFrame("GameTooltip", "BFL_Tooltip", UIParent, "GameTooltipTemplate")
tooltip:SetOwner(UIParent, "ANCHOR_NONE")

-- Keep friend tooltips above every SocialUI child frame. Native FriendsTooltip
-- uses GameTooltip as its stable reference; BFL_Tooltip may additionally sit
-- above FriendsTooltip. Keeping that relationship one-way prevents their frame
-- levels from increasing every time the user moves between live and mock rows.
local function RaiseFriendTooltipLayer(targetTooltip)
	targetTooltip = targetTooltip or tooltip
	if not targetTooltip or not targetTooltip.SetFrameStrata then
		return
	end

	targetTooltip:SetFrameStrata("TOOLTIP")
	local highestLevel = 0
	local referenceTooltips = { _G.GameTooltip }
	if targetTooltip == tooltip then
		referenceTooltips[#referenceTooltips + 1] = _G.FriendsTooltip
	end
	for _, blizzardTooltip in ipairs(referenceTooltips) do
		if blizzardTooltip and blizzardTooltip.GetFrameLevel then
			highestLevel = math.max(highestLevel, blizzardTooltip:GetFrameLevel() or 0)
		end
	end
	targetTooltip:SetFrameLevel(highestLevel + 10)
	if targetTooltip.SetToplevel then
		targetTooltip:SetToplevel(true)
	end
end

tooltip:SetClampedToScreen(true)
RaiseFriendTooltipLayer(tooltip)

-- Store on namespace for programmatic access
BFL.Tooltip = tooltip
BFL.RaiseFriendTooltipLayer = RaiseFriendTooltipLayer

local tooltipName = tooltip:GetName()

local function ApplyDefaultSlugToTooltipFontString(fontString)
	if BFL.FontManager and BFL.FontManager.ApplyDefaultSlugToFontString then
		BFL.FontManager:ApplyDefaultSlugToFontString(fontString)
	end
end

local function ApplyDefaultSlugToTooltipLines()
	if not tooltipName or not tooltip.NumLines then
		return
	end

	local lineCount = tooltip:NumLines() or 0
	for lineIndex = 1, lineCount do
		ApplyDefaultSlugToTooltipFontString(_G[tooltipName .. "TextLeft" .. lineIndex])
		ApplyDefaultSlugToTooltipFontString(_G[tooltipName .. "TextRight" .. lineIndex])
	end
end

tooltip.ApplyDefaultSlugFontFlags = ApplyDefaultSlugToTooltipLines
BFL.ApplyDefaultSlugToTooltip = ApplyDefaultSlugToTooltipLines

local function HookTooltipMethod(methodName)
	if not hooksecurefunc then
		return
	end
	pcall(hooksecurefunc, tooltip, methodName, ApplyDefaultSlugToTooltipLines)
end

HookTooltipMethod("SetText")
HookTooltipMethod("AddLine")
HookTooltipMethod("AddDoubleLine")
HookTooltipMethod("Show")

tooltip:HookScript("OnShow", ApplyDefaultSlugToTooltipLines)
tooltip:HookScript("OnShow", RaiseFriendTooltipLayer)

-- Wrapper function for use as OnLeave script reference (replaces GameTooltip_Hide)
function BFL_Tooltip_Hide()
	BFL_Tooltip:Hide()
end
