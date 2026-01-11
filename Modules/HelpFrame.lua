-- Modules/HelpFrame.lua
-- Creates the modern Help Frame with ScrollUtil

local _, BFL = ...
local HelpFrame = {}
BFL.HelpFrame = HelpFrame

local helpFrame = nil

function HelpFrame:CreateFrame()
	if helpFrame then
		return helpFrame
	end
	
	-- Use ButtonFrameTemplate to match Settings window
	local frame = CreateFrame("Frame", "BetterFriendlistHelpFrame", BetterFriendsFrame, "ButtonFrameTemplate")
	frame:SetSize(380, 500)
	frame:SetPoint("TOPLEFT", BetterFriendsFrame, "TOPRIGHT", 5, 0)
	frame:SetFrameStrata("HIGH")
	frame:EnableMouse(true)
	frame:SetMovable(false)
	frame:Hide()
	
	-- Setup ButtonFrameTemplate features
	if frame.portrait then frame.portrait:Hide() end
	if frame.PortraitContainer then frame.PortraitContainer:Hide() end
	
	if ButtonFrameTemplate_HidePortrait then
		ButtonFrameTemplate_HidePortrait(frame)
	end
	if ButtonFrameTemplate_HideAttic then
		ButtonFrameTemplate_HideAttic(frame)
	end
	
	-- Set title
	if frame.TitleContainer and frame.TitleContainer.TitleText then
		frame.TitleContainer.TitleText:SetText(BFL.L.RAID_HELP_TITLE or "Raid Roster Help")
	end
	
	-- ScrollFrame with modern ScrollUtil
	local scrollFrame
	
	if not BFL.IsClassic and ScrollUtil and ScrollUtil.InitScrollFrameWithScrollBar then
		-- Retail: Modern ScrollUtil
		scrollFrame = CreateFrame("ScrollFrame", nil, frame)
		frame.ScrollFrame = scrollFrame
		scrollFrame:SetPoint("TOPLEFT", 12, -30)
		scrollFrame:SetPoint("BOTTOMRIGHT", -30, 30)
		
		-- Mixin CallbackRegistry (Required for ScrollUtil)
		if not scrollFrame.RegisterCallback then
			Mixin(scrollFrame, CallbackRegistryMixin)
			scrollFrame:OnLoad()
		end
		
		-- Create ScrollBar (EventFrame inheriting MinimalScrollBar)
		local scrollBar = CreateFrame("EventFrame", nil, frame, "MinimalScrollBar")
		frame.ScrollBar = scrollBar
		scrollBar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", 6, 0)
		scrollBar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", 6, 0)
		
		ScrollUtil.InitScrollFrameWithScrollBar(scrollFrame, scrollBar)
	else
		-- Classic: Legacy UIPanelScrollFrameTemplate
		scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
		frame.ScrollFrame = scrollFrame
		scrollFrame:SetPoint("TOPLEFT", 12, -30)
		scrollFrame:SetPoint("BOTTOMRIGHT", -32, 30)
	end
	
	-- Content
	local content = CreateFrame("Frame", nil, scrollFrame)
	content:SetSize(330, 1) -- Height will be adjusted
	scrollFrame:SetScrollChild(content)
	
	local L = BFL.L or {}
	
	-- Title
	local title = content:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 10, -10)
	title:SetPoint("TOPRIGHT", -10, -10)
	title:SetJustifyH("LEFT")
	title:SetText(L.RAID_HELP_TITLE or "Raid Roster Help")
	title:SetTextColor(1.0, 0.82, 0)
	
	-- Section 1: Multi-Selection
	local section1Title = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	section1Title:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -15)
	section1Title:SetPoint("TOPRIGHT", title, "BOTTOMRIGHT", 0, -15)
	section1Title:SetJustifyH("LEFT")
	section1Title:SetText(L.RAID_HELP_MULTISELECT_TITLE or "Multi-Selection")
	section1Title:SetTextColor(1.0, 0.82, 0)
	
	local section1Text = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	section1Text:SetPoint("TOPLEFT", section1Title, "BOTTOMLEFT", 5, -5)
	section1Text:SetPoint("TOPRIGHT", section1Title, "BOTTOMRIGHT", -5, -5)
	section1Text:SetJustifyH("LEFT")
	section1Text:SetJustifyV("TOP")
	section1Text:SetText(L.RAID_HELP_MULTISELECT_TEXT or "Hold Ctrl and left-click to select multiple players.\nOnce selected, drag and drop them into any group to move them all at once.")
	
	-- Section 2: Main Tank
	local section2Title = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	section2Title:SetPoint("TOPLEFT", section1Text, "BOTTOMLEFT", -5, -15)
	section2Title:SetPoint("TOPRIGHT", section1Text, "BOTTOMRIGHT", 5, -15)
	section2Title:SetJustifyH("LEFT")
	section2Title:SetText(L.RAID_HELP_MAINTANK_TITLE or "Main Tank")
	section2Title:SetTextColor(1.0, 0.82, 0)
	
	local section2Text = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	section2Text:SetPoint("TOPLEFT", section2Title, "BOTTOMLEFT", 5, -5)
	section2Text:SetPoint("TOPRIGHT", section2Title, "BOTTOMRIGHT", -5, -5)
	section2Text:SetJustifyH("LEFT")
	section2Text:SetJustifyV("TOP")
	section2Text:SetText(L.RAID_HELP_MAINTANK_TEXT or "Shift + Right-Click on a player to set them as Main Tank.\nA tank icon will appear next to their name.")
	
	-- Section 3: Main Assist
	local section3Title = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	section3Title:SetPoint("TOPLEFT", section2Text, "BOTTOMLEFT", -5, -15)
	section3Title:SetPoint("TOPRIGHT", section2Text, "BOTTOMRIGHT", 5, -15)
	section3Title:SetJustifyH("LEFT")
	section3Title:SetText(L.RAID_HELP_MAINASSIST_TITLE or "Main Assist")
	section3Title:SetTextColor(1.0, 0.82, 0)
	
	local section3Text = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	section3Text:SetPoint("TOPLEFT", section3Title, "BOTTOMLEFT", 5, -5)
	section3Text:SetPoint("TOPRIGHT", section3Title, "BOTTOMRIGHT", -5, -5)
	section3Text:SetJustifyH("LEFT")
	section3Text:SetJustifyV("TOP")
	section3Text:SetText(L.RAID_HELP_MAINASSIST_TEXT or "Ctrl + Right-Click on a player to set them as Main Assist.\nAn assist icon will appear next to their name.")
	
	-- Section 4: Drag & Drop
	local section4Title = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	section4Title:SetPoint("TOPLEFT", section3Text, "BOTTOMLEFT", -5, -15)
	section4Title:SetPoint("TOPRIGHT", section3Text, "BOTTOMRIGHT", 5, -15)
	section4Title:SetJustifyH("LEFT")
	section4Title:SetText(L.RAID_HELP_DRAGDROP_TITLE or "Drag & Drop")
	section4Title:SetTextColor(1.0, 0.82, 0)
	
	local section4Text = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	section4Text:SetPoint("TOPLEFT", section4Title, "BOTTOMLEFT", 5, -5)
	section4Text:SetPoint("TOPRIGHT", section4Title, "BOTTOMRIGHT", -5, -5)
	section4Text:SetJustifyH("LEFT")
	section4Text:SetJustifyV("TOP")
	section4Text:SetText(L.RAID_HELP_DRAGDROP_TEXT or "Drag any player to move them between groups.\nYou can also drag multiple selected players at once.\nEmpty slots can be used to swap positions.")
	
	-- Section 5: Combat Lock
	local section5Title = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	section5Title:SetPoint("TOPLEFT", section4Text, "BOTTOMLEFT", -5, -15)
	section5Title:SetPoint("TOPRIGHT", section4Text, "BOTTOMRIGHT", 5, -15)
	section5Title:SetJustifyH("LEFT")
	section5Title:SetText(L.RAID_HELP_COMBAT_TITLE or "Combat Lock")
	section5Title:SetTextColor(1.0, 0.82, 0)
	
	local section5Text = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	section5Text:SetPoint("TOPLEFT", section5Title, "BOTTOMLEFT", 5, -5)
	section5Text:SetPoint("TOPRIGHT", section5Title, "BOTTOMRIGHT", -5, -5)
	section5Text:SetJustifyH("LEFT")
	section5Text:SetJustifyV("TOP")
	section5Text:SetText(L.RAID_HELP_COMBAT_TEXT or "Players cannot be moved during combat.\nThis is a Blizzard restriction to prevent errors.")
	
	-- Calculate actual content height dynamically
	local totalHeight = 10 -- Starting offset
	local sections = {
		title,
		section1Title, section1Text,
		section2Title, section2Text,
		section3Title, section3Text,
		section4Title, section4Text,
		section5Title, section5Text
	}
	
	for _, fs in ipairs(sections) do
		totalHeight = totalHeight + fs:GetStringHeight() + 5
	end
	
	content:SetHeight(totalHeight + 20) -- Add bottom padding
	
	-- Sound effects
	frame:SetScript("OnShow", function()
		PlaySound(SOUNDKIT.IG_MAINMENU_OPEN)
	end)
	
	frame:SetScript("OnHide", function()
		PlaySound(SOUNDKIT.IG_MAINMENU_CLOSE)
	end)
	
	helpFrame = frame
	return frame
end

function HelpFrame:Toggle()
	local frame = self:CreateFrame()
	
	if frame:IsShown() then
		frame:Hide()
	else
		frame:Show()
	end
end

function HelpFrame:Show()
	local frame = self:CreateFrame()
	frame:Show()
end

function HelpFrame:Hide()
	if helpFrame then
		helpFrame:Hide()
	end
end
