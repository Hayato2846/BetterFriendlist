-- Locales/Locales.lua
-- Main Localization System for BetterFriendlist

local ADDON_NAME, BFL = ...

-- Initialize locale tables
BFL_LOCALE = {}          -- Current locale
BFL_LOCALE_ENUS = {}     -- English fallback
BFL.Locales = {}         -- Registry for locale functions

-- Get initial WoW locale
local initialLocale = GetLocale()
BFL.ConfiguredLocale = initialLocale

-- Localization accessor with 3-tier fallback:
-- 1. Current locale (e.g. deDE, frFR)
-- 2. English (enUS) - FALLBACK
-- 3. Key name - LAST RESORT (means enUS is also missing the key)
BFL.MissingKeys = {}

local L = setmetatable({}, {
	__index = function(t, key)
		-- Try current locale first
		local translation = BFL_LOCALE[key]
		if translation then
			return translation
		end
		
		-- Fallback to enUS
		local englishFallback = BFL_LOCALE_ENUS[key]
		if englishFallback then
			-- Track missing translation (but don't spam for enUS locale)
			-- Use ConfiguredLocale instead of GetLocale()
			if BFL.ConfiguredLocale ~= "enUS" and not BFL.MissingKeys[key] then
				BFL.MissingKeys[key] = true
			end
			return englishFallback
		end
		
		-- Last resort: return key name (means even enUS doesn't have it!)
		if not BFL.MissingKeys[key] then
			BFL.MissingKeys[key] = true
		end
		return key
	end
})

-- Make accessible globally for all addon modules
_G["BFL_L"] = L
BFL.L = L

-- Register a locale function
function BFL:RegisterLocale(localeName, loadFunc)
	self.Locales[localeName] = loadFunc
	
	-- Immediately load if this matches our initial locale
	if localeName == self.ConfiguredLocale then
		loadFunc()
	end
end

-- Switch locale at runtime (for testing)
function BFL:SetLocale(newLocale)
	-- Normalize input to handle case-insensitivity (e.g. "frfr" -> "frFR")
	local targetKey = newLocale
	
	-- If exact match not found, try case-insensitive search
	if not self.Locales[targetKey] then
		local lowerTarget = newLocale:lower()
		for key, _ in pairs(self.Locales) do
			if key:lower() == lowerTarget then
				targetKey = key
				break
			end
		end
	end

	if not self.Locales[targetKey] and targetKey ~= "enUS" then 
		print("|cffff0000BFL:|r Locale " .. newLocale .. " not found!")
		return 
	end

	self.ConfiguredLocale = targetKey
	
	-- Safety: If BFL_LOCALE points to BFL_LOCALE_ENUS (reference equality), 
	-- do NOT wipe it, instead point to a new table.
	if BFL_LOCALE == BFL_LOCALE_ENUS then
		BFL_LOCALE = {}
	else
		wipe(BFL_LOCALE)
	end
	
	-- Run the registered function for the new locale
	if self.Locales[targetKey] then
		self.Locales[targetKey]()
	else
		-- Fallback if we switch to a locale with no file but it is valid? 
		-- Should not happen with our setup.
	end
	
	print("|cff00ff00BFL:|r Leveled up! Switched locale to " .. targetKey)
end

-- Developer Tool: Show Missing Translations Frame
function BFL:ShowMissingLocalesFrame()
	if self.MissingLocalesFrame then
		self.MissingLocalesFrame:Show()
		self:UpdateMissingLocalesText()
		return
	end

	-- Create Frame
	local f = CreateFrame("Frame", "BFLMissingLocalesFrame", UIParent, "BasicFrameTemplateWithInset")
	f:SetSize(600, 500)
	f:SetPoint("CENTER")
	f:SetMovable(true)
	f:EnableMouse(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", f.StartMoving)
	f:SetScript("OnDragStop", f.StopMovingOrSizing)
	f:SetFrameStrata("DIALOG")
	
	-- Title
	f.TitleBg:SetHeight(30)
	f.TitleText:SetText("BetterFriendlist - Missing Translations")
	f.TitleText:SetPoint("TOP", 0, -5)

	-- Instructions
	local info = f:CreateFontString(nil, "OVERLAY", "BetterFriendlistFontNormal")
	info:SetPoint("TOPLEFT", 15, -35)
	info:SetPoint("TOPRIGHT", -15, -35)
	info:SetJustifyH("LEFT")
	info:SetText("The following keys were accessed but not found in the current locale (" .. GetLocale() .. ").\nCopy and add them to your locale file.")

	-- ScrollFrame
	local sf = CreateFrame("ScrollFrame", "BFLMissingLocalesScroll", f, "UIPanelScrollFrameTemplate")
	sf:SetPoint("TOPLEFT", 15, -70)
	sf:SetPoint("BOTTOMRIGHT", -35, 40)

	-- EditBox
	local eb = CreateFrame("EditBox", nil, sf)
	eb:SetMultiLine(true)
	eb:SetFontObject("ChatFontNormal")
	eb:SetWidth(530)
	sf:SetScrollChild(eb)
	f.EditBox = eb

	-- Refresh Button
	local btn = CreateFrame("Button", nil, f, "GameMenuButtonTemplate")
	btn:SetPoint("BOTTOM", 0, 10)
	btn:SetSize(120, 24)
	btn:SetText("Refresh")
	btn:SetScript("OnClick", function() BFL:UpdateMissingLocalesText() end)

	self.MissingLocalesFrame = f
	self:UpdateMissingLocalesText()
end

function BFL:UpdateMissingLocalesText()
	if not self.MissingLocalesFrame then return end
	
	local keys = {}
	for k, _ in pairs(BFL.MissingKeys) do
		table.insert(keys, k)
	end
	table.sort(keys)
	
	local text = "-- Detected Missing Keys for usage in: " .. GetLocale() .. "\n"
	text = text .. "-- Generated on " .. date() .. "\n\n"
	
	if #keys == 0 then
		text = text .. "-- No missing keys detected in this session!"
	else
		for _, key in ipairs(keys) do
			text = text .. string.format('L.%s = "%s"\n', key, key)
		end
	end
	
	self.MissingLocalesFrame.EditBox:SetText(text)
	self.MissingLocalesFrame.EditBox:SetFocus()
	self.MissingLocalesFrame.EditBox:HighlightText()
end
