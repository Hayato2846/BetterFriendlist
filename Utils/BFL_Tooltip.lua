-- BFL_Tooltip: Addon-owned tooltip to avoid tainting the global GameTooltip
-- Must be loaded early (after Core.lua + ClassicCompat.lua, before Modules)
local ADDON_NAME, BFL = ...

-- Create an addon-owned GameTooltip using Blizzard's template
-- This is the same pattern used by WeakAuras, Details, etc.
local tooltip = CreateFrame("GameTooltip", "BFL_Tooltip", UIParent, "GameTooltipTemplate")
tooltip:SetOwner(UIParent, "ANCHOR_NONE")

-- Store on namespace for programmatic access
BFL.Tooltip = tooltip

-- Wrapper function for use as OnLeave script reference (replaces GameTooltip_Hide)
function BFL_Tooltip_Hide()
	BFL_Tooltip:Hide()
end
