-- BFL_Tooltip: Addon-owned tooltip to avoid tainting the global GameTooltip
-- Must be loaded early (after Core.lua + ClassicCompat.lua, before Modules)
local ADDON_NAME, BFL = ...

-- Create an addon-owned GameTooltip using Blizzard's template
-- This is the same pattern used by WeakAuras, Details, etc.
local tooltip = CreateFrame("GameTooltip", "BFL_Tooltip", UIParent, "GameTooltipTemplate")
tooltip:SetOwner(UIParent, "ANCHOR_NONE")

-- Store on namespace for programmatic access
BFL.Tooltip = tooltip

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

-- Wrapper function for use as OnLeave script reference (replaces GameTooltip_Hide)
function BFL_Tooltip_Hide()
	BFL_Tooltip:Hide()
end
