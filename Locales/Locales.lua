-- Locales/Locales.lua
-- Main Localization System for BetterFriendlist

local ADDON_NAME, BFL = ...

-- Initialize locale table
BFL_LOCALE = {}

-- Get current WoW locale
local locale = GetLocale()

-- Localization accessor with fallback to key if translation not found
-- Also tracks missing keys for developer reporting
BFL.MissingKeys = {}

local L = setmetatable({}, {
	__index = function(t, key)
		local translation = BFL_LOCALE[key]
		if not translation then
			-- Track missing key if not already tracked
			if not BFL.MissingKeys[key] then
				BFL.MissingKeys[key] = true
			end
			return key -- Fallback to key name
		end
		return translation
	end
})

-- Make accessible globally for all addon modules
_G["BFL_L"] = L
BFL.L = L

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
	local info = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
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
