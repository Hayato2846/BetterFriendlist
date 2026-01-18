--[[Perfy has instrumented this file]] local Perfy_GetTime, Perfy_Trace, Perfy_Trace_Passthrough = Perfy_GetTime, Perfy_Trace, Perfy_Trace_Passthrough; Perfy_Trace(Perfy_GetTime(), "Enter", "(main chunk) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Compat_GlobalIgnoreList.lua"); local ADDON_NAME, BFL = ...
local Compat = BFL:RegisterModule("Compat_GlobalIgnoreList", {})

-- Global Ignore List Compatibility Module
-- Supports opening GIL alongside BetterFriendlist and smart anchoring

function Compat:Initialize() Perfy_Trace(Perfy_GetTime(), "Enter", "Compat:Initialize file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Compat_GlobalIgnoreList.lua:7:0");
	-- Check if GlobalIgnoreList is loaded or wait for it
	if C_AddOns.IsAddOnLoaded("GlobalIgnoreList") then
		self:Setup()
	else
		local frame = CreateFrame("Frame")
		frame:RegisterEvent("ADDON_LOADED")
		frame:SetScript("OnEvent", function(f, event, addonName) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Compat_GlobalIgnoreList.lua:14:29");
			if addonName == "GlobalIgnoreList" then
				self:Setup()
				f:UnregisterEvent("ADDON_LOADED")
				f:SetScript("OnEvent", nil)
			end
		Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Compat_GlobalIgnoreList.lua:14:29"); end)
	end
Perfy_Trace(Perfy_GetTime(), "Leave", "Compat:Initialize file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Compat_GlobalIgnoreList.lua:7:0"); end

function Compat:Setup() Perfy_Trace(Perfy_GetTime(), "Enter", "Compat:Setup file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Compat_GlobalIgnoreList.lua:24:0");
	-- Hook Main Frame
	if BetterFriendsFrame then
		BetterFriendsFrame:HookScript("OnShow", function() Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Compat_GlobalIgnoreList.lua:27:42"); self:OnFriendsShow() Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Compat_GlobalIgnoreList.lua:27:42"); end)
		BetterFriendsFrame:HookScript("OnHide", function() Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Compat_GlobalIgnoreList.lua:28:42"); self:OnFriendsHide() Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Compat_GlobalIgnoreList.lua:28:42"); end)
	end
	
	-- Hook Settings Module
	local Settings = BFL:GetModule("Settings")
	if Settings then
		-- Hook Show to capture frame creation and initial display
		hooksecurefunc(Settings, "Show", function() Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Compat_GlobalIgnoreList.lua:35:35"); 
			self:HookSettingsFrame()
			self:UpdateAnchor() 
		Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Compat_GlobalIgnoreList.lua:35:35"); end)
		-- Hook Hide just in case it's called programmatically
		hooksecurefunc(Settings, "Hide", function() Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Compat_GlobalIgnoreList.lua:40:35"); self:UpdateAnchor() Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Compat_GlobalIgnoreList.lua:40:35"); end)
	end
	
	-- Hook HelpFrame Module
    -- HelpFrame does not use RegisterModule, so it is located at BFL.HelpFrame
	local HelpFrame = BFL.HelpFrame
	if HelpFrame then
		-- Hook Show/Toggle to capture frame creation
		if HelpFrame.Show then
			hooksecurefunc(HelpFrame, "Show", function() Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Compat_GlobalIgnoreList.lua:49:37"); 
				self:HookHelpFrame()
				self:UpdateAnchor() 
			Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Compat_GlobalIgnoreList.lua:49:37"); end)
		end
		if HelpFrame.Toggle then
			hooksecurefunc(HelpFrame, "Toggle", function() Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Compat_GlobalIgnoreList.lua:55:39"); 
				self:HookHelpFrame()
				self:UpdateAnchor() 
			Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Compat_GlobalIgnoreList.lua:55:39"); end)
		end
		
		if HelpFrame.Hide then
			hooksecurefunc(HelpFrame, "Hide", function() Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Compat_GlobalIgnoreList.lua:62:37"); self:UpdateAnchor() Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Compat_GlobalIgnoreList.lua:62:37"); end)
		end
	end
	
	-- Hook RaidFrame Module's RaidInfo Button
	-- RaidInfoFrame is loaded lazily via BetterRaidFrame_RaidInfoButton_OnClick global
	if _G.BetterRaidFrame_RaidInfoButton_OnClick then
		hooksecurefunc("BetterRaidFrame_RaidInfoButton_OnClick", function() Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Compat_GlobalIgnoreList.lua:69:59"); 
			self:HookRaidInfoFrame()
			self:UpdateAnchor() 
		Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Compat_GlobalIgnoreList.lua:69:59"); end)
	end
Perfy_Trace(Perfy_GetTime(), "Leave", "Compat:Setup file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Compat_GlobalIgnoreList.lua:24:0"); end

function Compat:HookSettingsFrame() Perfy_Trace(Perfy_GetTime(), "Enter", "Compat:HookSettingsFrame file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Compat_GlobalIgnoreList.lua:76:0");
	if self.settingsFrameHooked then Perfy_Trace(Perfy_GetTime(), "Leave", "Compat:HookSettingsFrame file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Compat_GlobalIgnoreList.lua:76:0"); return end
	
	local frame = _G["BetterFriendlistSettingsFrame"]
	if frame then
		-- Hook OnShow/OnHide script handlers to catch UI interactions (like 'X' button)
		frame:HookScript("OnShow", function() Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Compat_GlobalIgnoreList.lua:82:29"); self:UpdateAnchor() Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Compat_GlobalIgnoreList.lua:82:29"); end)
		frame:HookScript("OnHide", function() Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Compat_GlobalIgnoreList.lua:83:29"); self:UpdateAnchor() Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Compat_GlobalIgnoreList.lua:83:29"); end)
		self.settingsFrameHooked = true
	end
Perfy_Trace(Perfy_GetTime(), "Leave", "Compat:HookSettingsFrame file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Compat_GlobalIgnoreList.lua:76:0"); end

function Compat:HookHelpFrame() Perfy_Trace(Perfy_GetTime(), "Enter", "Compat:HookHelpFrame file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Compat_GlobalIgnoreList.lua:88:0");
	if self.helpFrameHooked then Perfy_Trace(Perfy_GetTime(), "Leave", "Compat:HookHelpFrame file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Compat_GlobalIgnoreList.lua:88:0"); return end
	
	local frame = _G["BetterFriendlistHelpFrame"]
	if frame then
		frame:HookScript("OnShow", function() Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Compat_GlobalIgnoreList.lua:93:29"); self:UpdateAnchor() Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Compat_GlobalIgnoreList.lua:93:29"); end)
		frame:HookScript("OnHide", function() Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Compat_GlobalIgnoreList.lua:94:29"); self:UpdateAnchor() Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Compat_GlobalIgnoreList.lua:94:29"); end)
		self.helpFrameHooked = true
	end
Perfy_Trace(Perfy_GetTime(), "Leave", "Compat:HookHelpFrame file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Compat_GlobalIgnoreList.lua:88:0"); end

function Compat:HookRaidInfoFrame() Perfy_Trace(Perfy_GetTime(), "Enter", "Compat:HookRaidInfoFrame file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Compat_GlobalIgnoreList.lua:99:0");
	if self.raidInfoFrameHooked then Perfy_Trace(Perfy_GetTime(), "Leave", "Compat:HookRaidInfoFrame file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Compat_GlobalIgnoreList.lua:99:0"); return end
	
	local frame = _G["RaidInfoFrame"]
	if frame then
		-- Hook OnShow/OnHide
		frame:HookScript("OnShow", function() Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Compat_GlobalIgnoreList.lua:105:29"); self:UpdateAnchor() Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Compat_GlobalIgnoreList.lua:105:29"); end)
		frame:HookScript("OnHide", function() Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Compat_GlobalIgnoreList.lua:106:29"); self:UpdateAnchor() Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Compat_GlobalIgnoreList.lua:106:29"); end)
		self.raidInfoFrameHooked = true
	end
Perfy_Trace(Perfy_GetTime(), "Leave", "Compat:HookRaidInfoFrame file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Compat_GlobalIgnoreList.lua:99:0"); end

function Compat:UpdateAnchor() Perfy_Trace(Perfy_GetTime(), "Enter", "Compat:UpdateAnchor file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Compat_GlobalIgnoreList.lua:111:0");
	-- Check if GIL frame exists and is shown
	local gilFrame = _G["GIL"]
	if not gilFrame or not gilFrame:IsShown() then Perfy_Trace(Perfy_GetTime(), "Leave", "Compat:UpdateAnchor file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Compat_GlobalIgnoreList.lua:111:0"); return end
	
	-- Check if BFL frame is shown
	local anchor = BetterFriendsFrame
	if not anchor or not anchor:IsShown() then Perfy_Trace(Perfy_GetTime(), "Leave", "Compat:UpdateAnchor file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Compat_GlobalIgnoreList.lua:111:0"); return end
	
	-- Check for active side panels
	-- Settings Frame
	local settingsFrame = _G["BetterFriendlistSettingsFrame"]
	if settingsFrame and settingsFrame:IsShown() then
		anchor = settingsFrame
	end
	
	-- Help Frame (takes precedence if both are somehow shown, or typically exclusive)
	local helpFrame = _G["BetterFriendlistHelpFrame"]
	if helpFrame and helpFrame:IsShown() then
		anchor = helpFrame
	end
	
	-- Raid Info Frame (highest priority)
	-- Only if it is docked to BetterFriendsFrame
	local raidInfoFrame = _G["RaidInfoFrame"]
	if raidInfoFrame and raidInfoFrame:IsShown() and raidInfoFrame:GetParent() == BetterFriendsFrame then
		anchor = raidInfoFrame
	end
	
	-- Apply Anchor
	gilFrame:ClearAllPoints()
	gilFrame:SetPoint("TOPLEFT", anchor, "TOPRIGHT", 12, -10)
Perfy_Trace(Perfy_GetTime(), "Leave", "Compat:UpdateAnchor file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Compat_GlobalIgnoreList.lua:111:0"); end

function Compat:OnFriendsShow() Perfy_Trace(Perfy_GetTime(), "Enter", "Compat:OnFriendsShow file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Compat_GlobalIgnoreList.lua:145:0");
	-- Check user preference in GIL DB
	if GlobalIgnoreDB and GlobalIgnoreDB.openWithFriends then
		-- Ensure GIL is shown (creates frame if needed)
		if SlashCmdList["GIGNORE"] then
			SlashCmdList["GIGNORE"]("ui")
		end
		
		-- Update position
		self:UpdateAnchor()
	end
Perfy_Trace(Perfy_GetTime(), "Leave", "Compat:OnFriendsShow file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Compat_GlobalIgnoreList.lua:145:0"); end

function Compat:OnFriendsHide() Perfy_Trace(Perfy_GetTime(), "Enter", "Compat:OnFriendsHide file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Compat_GlobalIgnoreList.lua:158:0");
	if GlobalIgnoreDB and GlobalIgnoreDB.openWithFriends then
		local gilFrame = _G["GIL"]
		if gilFrame and gilFrame:IsShown() then
			gilFrame:Hide()
		end
	end
Perfy_Trace(Perfy_GetTime(), "Leave", "Compat:OnFriendsHide file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Compat_GlobalIgnoreList.lua:158:0"); end

Perfy_Trace(Perfy_GetTime(), "Leave", "(main chunk) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/Compat_GlobalIgnoreList.lua");