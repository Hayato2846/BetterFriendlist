--[[Perfy has instrumented this file]] local Perfy_GetTime, Perfy_Trace, Perfy_Trace_Passthrough = Perfy_GetTime, Perfy_Trace, Perfy_Trace_Passthrough; Perfy_Trace(Perfy_GetTime(), "Enter", "(main chunk) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Locales/Locales.lua"); -- Locales/Locales.lua
-- Main Localization System for BetterFriendlist

local ADDON_NAME, BFL = ...

-- Initialize locale tables
BFL_LOCALE = {}          -- Current locale
BFL_LOCALE_ENUS = {}     -- English fallback

-- Get current WoW locale
local locale = GetLocale()

-- Localization accessor with 3-tier fallback:
-- 1. Current locale (e.g. deDE, frFR)
-- 2. English (enUS) - FALLBACK
-- 3. Key name - LAST RESORT (means enUS is also missing the key)
BFL.MissingKeys = {}

local L = setmetatable({}, {
	__index = function(t, key) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Locales/Locales.lua:20:11");
		-- Try current locale first
		local translation = BFL_LOCALE[key]
		if translation then
			Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Locales/Locales.lua:20:11"); return translation
		end
		
		-- Fallback to enUS
		local englishFallback = BFL_LOCALE_ENUS[key]
		if englishFallback then
			-- Track missing translation (but don't spam for enUS locale)
			if locale ~= "enUS" and not BFL.MissingKeys[key] then
				BFL.MissingKeys[key] = true
			end
			Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Locales/Locales.lua:20:11"); return englishFallback
		end
		
		-- Last resort: return key name (means even enUS doesn't have it!)
		if not BFL.MissingKeys[key] then
			BFL.MissingKeys[key] = true
		end
		Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Locales/Locales.lua:20:11"); return key
	end
})

-- Make accessible globally for all addon modules
_G["BFL_L"] = L
BFL.L = L

-- Developer Tool: Show Missing Translations Frame
function BFL:ShowMissingLocalesFrame() Perfy_Trace(Perfy_GetTime(), "Enter", "BFL:ShowMissingLocalesFrame file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Locales/Locales.lua:50:0");
	if self.MissingLocalesFrame then
		self.MissingLocalesFrame:Show()
		self:UpdateMissingLocalesText()
		Perfy_Trace(Perfy_GetTime(), "Leave", "BFL:ShowMissingLocalesFrame file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Locales/Locales.lua:50:0"); return
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
	btn:SetScript("OnClick", function() Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Locales/Locales.lua:98:26"); BFL:UpdateMissingLocalesText() Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Locales/Locales.lua:98:26"); end)

	self.MissingLocalesFrame = f
	self:UpdateMissingLocalesText()
Perfy_Trace(Perfy_GetTime(), "Leave", "BFL:ShowMissingLocalesFrame file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Locales/Locales.lua:50:0"); end

function BFL:UpdateMissingLocalesText() Perfy_Trace(Perfy_GetTime(), "Enter", "BFL:UpdateMissingLocalesText file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Locales/Locales.lua:104:0");
	if not self.MissingLocalesFrame then Perfy_Trace(Perfy_GetTime(), "Leave", "BFL:UpdateMissingLocalesText file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Locales/Locales.lua:104:0"); return end
	
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
Perfy_Trace(Perfy_GetTime(), "Leave", "BFL:UpdateMissingLocalesText file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Locales/Locales.lua:104:0"); end

Perfy_Trace(Perfy_GetTime(), "Leave", "(main chunk) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Locales/Locales.lua");