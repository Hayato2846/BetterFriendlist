-- Modules/HelpFrame.lua
-- Creates the modern Help Frame with ScrollUtil

local _, BFL = ...
local HelpFrame = {}
BFL.HelpFrame = HelpFrame

local helpFrame = nil

local function GetFormattedShortcut(action)
	local db = BetterFriendlistDB
	local shortcuts = db and db.raidShortcuts or {}
	local setting = shortcuts[action]
	local L = BFL.L
	
	if not setting then return "Unknown" end
	
	local mod = setting.modifier or "NONE"
	local btn = setting.button or "LeftButton"
	
	local modText = ""
	
	if mod == "NONE" then
		modText = ""
	else
		-- Handle composite modifiers like "CTRL-ALT" by splitting and translating parts
		local parts = {}
		-- Check for hyphenated modifiers
		if string.find(mod, "-") then
			for part in string.gmatch(mod, "[^-]+") do
				local localized = L["SETTINGS_RAID_MODIFIER_" .. part] or part
				table.insert(parts, localized)
			end
			modText = table.concat(parts, " + ")
		else
			-- Single modifier
			modText = L["SETTINGS_RAID_MODIFIER_" .. mod] or mod
		end
	end

	local btnText = ""
	
	if btn == "LeftButton" then btnText = L.SETTINGS_RAID_MOUSE_LEFT or "Left Click"
	elseif btn == "RightButton" then btnText = L.SETTINGS_RAID_MOUSE_RIGHT or "Right Click"
	elseif btn == "MiddleButton" then btnText = L.SETTINGS_RAID_MOUSE_MIDDLE or "Middle Click"
	else btnText = btn end
	
	if modText == "" then
		return btnText
	else
		return modText .. " + " .. btnText
	end
end

function HelpFrame:UpdateText(frame)
	if not frame or not frame.textElements then return end
	local L = BFL.L or {}
	
	-- Update dynamic sections
	if frame.textElements.section2Text then
		frame.textElements.section2Text:SetText(string.format(L.RAID_HELP_MAINTANK_TEXT, GetFormattedShortcut("mainTank")))
	end
	
	if frame.textElements.section3Text then
		frame.textElements.section3Text:SetText(string.format(L.RAID_HELP_MAINASSIST_TEXT, GetFormattedShortcut("mainAssist")))
	end
	
	if frame.textElements.sectionLeadText then
		frame.textElements.sectionLeadText:SetText(string.format(L.RAID_HELP_LEAD_TEXT, GetFormattedShortcut("lead")))
	end
	
	if frame.textElements.sectionPromoteText then
		frame.textElements.sectionPromoteText:SetText(string.format(L.RAID_HELP_PROMOTE_TEXT, GetFormattedShortcut("promote")))
	end
	
	-- Re-calculate layout if needed (height might change with text length)
	if frame.LayoutContent then
		frame:LayoutContent()
	end
end

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
	
	-- Logic to store updateable text elements
	frame.textElements = {}
	
	local L = BFL.L or {}
	
	-- Title
	local title = content:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontNormalLarge")
	title:SetPoint("TOPLEFT", 10, -10)
	title:SetPoint("TOPRIGHT", -10, -10)
	title:SetJustifyH("LEFT")
	title:SetText(L.RAID_HELP_TITLE)
	title:SetTextColor(1.0, 0.82, 0)
	
	-- Section 1: Multi-Selection
	local section1Title = content:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontNormal")
	section1Title:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -15)
	section1Title:SetPoint("TOPRIGHT", title, "BOTTOMRIGHT", 0, -15)
	section1Title:SetJustifyH("LEFT")
	section1Title:SetText(L.RAID_HELP_MULTISELECT_TITLE)
	section1Title:SetTextColor(1.0, 0.82, 0)
	
	local section1Text = content:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontHighlight")
	section1Text:SetPoint("TOPLEFT", section1Title, "BOTTOMLEFT", 5, -5)
	section1Text:SetPoint("TOPRIGHT", section1Title, "BOTTOMRIGHT", -5, -5)
	section1Text:SetJustifyH("LEFT")
	section1Text:SetJustifyV("TOP")
	section1Text:SetText(L.RAID_HELP_MULTISELECT_TEXT)
	
	-- Section 2: Main Tank
	local section2Title = content:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontNormal")
	section2Title:SetPoint("TOPLEFT", section1Text, "BOTTOMLEFT", -5, -15)
	section2Title:SetPoint("TOPRIGHT", section1Text, "BOTTOMRIGHT", 5, -15)
	section2Title:SetJustifyH("LEFT")
	section2Title:SetText(L.RAID_HELP_MAINTANK_TITLE)
	section2Title:SetTextColor(1.0, 0.82, 0)
	
	local section2Text = content:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontHighlight")
	section2Text:SetPoint("TOPLEFT", section2Title, "BOTTOMLEFT", 5, -5)
	section2Text:SetPoint("TOPRIGHT", section2Title, "BOTTOMRIGHT", -5, -5)
	section2Text:SetJustifyH("LEFT")
	section2Text:SetJustifyV("TOP")
	section2Text:SetText(string.format(L.RAID_HELP_MAINTANK_TEXT, GetFormattedShortcut("mainTank")))
	frame.textElements.section2Text = section2Text
	
	-- Section 3: Main Assist
	local section3Title = content:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontNormal")
	section3Title:SetPoint("TOPLEFT", section2Text, "BOTTOMLEFT", -5, -15)
	section3Title:SetPoint("TOPRIGHT", section2Text, "BOTTOMRIGHT", 5, -15)
	section3Title:SetJustifyH("LEFT")
	section3Title:SetText(L.RAID_HELP_MAINASSIST_TITLE)
	section3Title:SetTextColor(1.0, 0.82, 0)
	
	local section3Text = content:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontHighlight")
	section3Text:SetPoint("TOPLEFT", section3Title, "BOTTOMLEFT", 5, -5)
	section3Text:SetPoint("TOPRIGHT", section3Title, "BOTTOMRIGHT", -5, -5)
	section3Text:SetJustifyH("LEFT")
	section3Text:SetJustifyV("TOP")
	section3Text:SetText(string.format(L.RAID_HELP_MAINASSIST_TEXT, GetFormattedShortcut("mainAssist")))
	frame.textElements.section3Text = section3Text
	
	-- Section 4: Raid Leader
	local sectionLeadTitle = content:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontNormal")
	sectionLeadTitle:SetPoint("TOPLEFT", section3Text, "BOTTOMLEFT", -5, -15)
	sectionLeadTitle:SetPoint("TOPRIGHT", section3Text, "BOTTOMRIGHT", 5, -15)
	sectionLeadTitle:SetJustifyH("LEFT")
	sectionLeadTitle:SetText(L.RAID_HELP_LEAD_TITLE)
	sectionLeadTitle:SetTextColor(1.0, 0.82, 0)
	
	local sectionLeadText = content:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontHighlight")
	sectionLeadText:SetPoint("TOPLEFT", sectionLeadTitle, "BOTTOMLEFT", 5, -5)
	sectionLeadText:SetPoint("TOPRIGHT", sectionLeadTitle, "BOTTOMRIGHT", -5, -5)
	sectionLeadText:SetJustifyH("LEFT")
	sectionLeadText:SetJustifyV("TOP")
	sectionLeadText:SetText(string.format(L.RAID_HELP_LEAD_TEXT, GetFormattedShortcut("lead")))
	frame.textElements.sectionLeadText = sectionLeadText
	
	-- Section 5: Promote Assistant
	local sectionPromoteTitle = content:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontNormal")
	sectionPromoteTitle:SetPoint("TOPLEFT", sectionLeadText, "BOTTOMLEFT", -5, -15)
	sectionPromoteTitle:SetPoint("TOPRIGHT", sectionLeadText, "BOTTOMRIGHT", 5, -15)
	sectionPromoteTitle:SetJustifyH("LEFT")
	sectionPromoteTitle:SetText(L.RAID_HELP_PROMOTE_TITLE)
	sectionPromoteTitle:SetTextColor(1.0, 0.82, 0)
	
	local sectionPromoteText = content:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontHighlight")
	sectionPromoteText:SetPoint("TOPLEFT", sectionPromoteTitle, "BOTTOMLEFT", 5, -5)
	sectionPromoteText:SetPoint("TOPRIGHT", sectionPromoteTitle, "BOTTOMRIGHT", -5, -5)
	sectionPromoteText:SetJustifyH("LEFT")
	sectionPromoteText:SetJustifyV("TOP")
	sectionPromoteText:SetText(string.format(L.RAID_HELP_PROMOTE_TEXT, GetFormattedShortcut("promote")))
	frame.textElements.sectionPromoteText = sectionPromoteText

	-- Section 6: Drag & Drop
	local section4Title = content:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontNormal")
	section4Title:SetPoint("TOPLEFT", sectionPromoteText, "BOTTOMLEFT", -5, -15)
	section4Title:SetPoint("TOPRIGHT", sectionPromoteText, "BOTTOMRIGHT", 5, -15)
	section4Title:SetJustifyH("LEFT")
	section4Title:SetText(L.RAID_HELP_DRAGDROP_TITLE)
	section4Title:SetTextColor(1.0, 0.82, 0)
	
	local section4Text = content:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontHighlight")
	section4Text:SetPoint("TOPLEFT", section4Title, "BOTTOMLEFT", 5, -5)
	section4Text:SetPoint("TOPRIGHT", section4Title, "BOTTOMRIGHT", -5, -5)
	section4Text:SetJustifyH("LEFT")
	section4Text:SetJustifyV("TOP")
	section4Text:SetText(L.RAID_HELP_DRAGDROP_TEXT)
	
	-- Section 5: Combat Lock
	local section5Title = content:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontNormal")
	section5Title:SetPoint("TOPLEFT", section4Text, "BOTTOMLEFT", -5, -15)
	section5Title:SetPoint("TOPRIGHT", section4Text, "BOTTOMRIGHT", 5, -15)
	section5Title:SetJustifyH("LEFT")
	section5Title:SetText(L.RAID_HELP_COMBAT_TITLE)
	section5Title:SetTextColor(1.0, 0.82, 0)
	
	local section5Text = content:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontHighlight")
	section5Text:SetPoint("TOPLEFT", section5Title, "BOTTOMLEFT", 5, -5)
	section5Text:SetPoint("TOPRIGHT", section5Title, "BOTTOMRIGHT", -5, -5)
	section5Text:SetJustifyH("LEFT")
	section5Text:SetJustifyV("TOP")
	section5Text:SetText(L.RAID_HELP_COMBAT_TEXT)
	
	-- Calculate actual content height dynamically
	local sections = {
		title,
		section1Title, section1Text,
		section2Title, section2Text,
		section3Title, section3Text,
		sectionLeadTitle, sectionLeadText,
		sectionPromoteTitle, sectionPromoteText,
		section4Title, section4Text,
		section5Title, section5Text
	}
	
	frame.LayoutContent = function()
		local total = 10
		for _, fs in ipairs(sections) do
			total = total + fs:GetStringHeight() + 5
		end
		content:SetHeight(total + 20)
	end
	frame:LayoutContent() -- Initial layout
	
	-- Sound effects
	frame:SetScript("OnShow", function()
		HelpFrame:UpdateText(frame) -- Update text on show
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
