-- Locales/Locales.lua
-- Main Localization System for BetterFriendlist

local ADDON_NAME, BFL = ...

-- Initialize locale table
BFL_LOCALE = {}

-- Get current WoW locale
local locale = GetLocale()

-- Localization accessor with fallback to key if translation not found
local L = setmetatable({}, {
	__index = function(t, key)
		return BFL_LOCALE[key] or key
	end
})

-- Make accessible globally for all addon modules
_G["BFL_L"] = L
BFL.L = L

-- Debug function to check missing translations (can be removed in production)
function BFL_GetMissingTranslations()
	local missing = {}
	for key, value in pairs(BFL_LOCALE) do
		if value == key then
			table.insert(missing, key)
		end
	end
	return missing
end
