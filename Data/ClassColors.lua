-- Addon-owned fallback palette for cross-client classes missing from the local
-- client. Readable native class colors always take precedence in ClassUtils.
-- Values verified from Retail RAID_CLASS_COLORS on 2026-11-06.
local ADDON_NAME, BFL = ...
BFL.ClassColors = {
	DEATHKNIGHT = { r = 196 / 255, g = 30 / 255, b = 58 / 255, colorStr = "ffc41e3a" },
	MONK = { r = 0, g = 1, b = 152 / 255, colorStr = "ff00ff98" },
	DEMONHUNTER = { r = 163 / 255, g = 48 / 255, b = 201 / 255, colorStr = "ffa330c9" },
	EVOKER = { r = 51 / 255, g = 147 / 255, b = 127 / 255, colorStr = "ff33937f" },
}
