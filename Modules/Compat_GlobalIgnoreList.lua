local ADDON_NAME, BFL = ...
local Compat = BFL:RegisterModule("Compat_GlobalIgnoreList", {})

-- Global Ignore List Compatibility Module
-- Supports opening GIL alongside BetterFriendlist and smart anchoring

function Compat:Initialize()
	-- Check if GlobalIgnoreList is loaded or wait for it
	if C_AddOns.IsAddOnLoaded("GlobalIgnoreList") then
		self:Setup()
	else
		local frame = CreateFrame("Frame")
		frame:RegisterEvent("ADDON_LOADED")
		frame:SetScript("OnEvent", function(f, event, addonName)
			if addonName == "GlobalIgnoreList" then
				self:Setup()
				f:UnregisterEvent("ADDON_LOADED")
				f:SetScript("OnEvent", nil)
			end
		end)
	end
end

function Compat:Setup()
	-- Hook Main Frame
	if BetterFriendsFrame then
		BetterFriendsFrame:HookScript("OnShow", function() self:OnFriendsShow() end)
		BetterFriendsFrame:HookScript("OnHide", function() self:OnFriendsHide() end)
	end
	
	-- Hook Settings Module
	local Settings = BFL:GetModule("Settings")
	if Settings then
		-- Hook Show to capture frame creation and initial display
		hooksecurefunc(Settings, "Show", function() 
			self:HookSettingsFrame()
			self:UpdateAnchor() 
		end)
		-- Hook Hide just in case it's called programmatically
		hooksecurefunc(Settings, "Hide", function() self:UpdateAnchor() end)
	end
	
	-- Hook HelpFrame Module
    -- HelpFrame does not use RegisterModule, so it is located at BFL.HelpFrame
	local HelpFrame = BFL.HelpFrame
	if HelpFrame then
		-- Hook Show/Toggle to capture frame creation
		if HelpFrame.Show then
			hooksecurefunc(HelpFrame, "Show", function() 
				self:HookHelpFrame()
				self:UpdateAnchor() 
			end)
		end
		if HelpFrame.Toggle then
			hooksecurefunc(HelpFrame, "Toggle", function() 
				self:HookHelpFrame()
				self:UpdateAnchor() 
			end)
		end
		
		if HelpFrame.Hide then
			hooksecurefunc(HelpFrame, "Hide", function() self:UpdateAnchor() end)
		end
	end
	
	-- Hook RaidFrame Module's RaidInfo Button
	-- RaidInfoFrame is loaded lazily via BetterRaidFrame_RaidInfoButton_OnClick global
	if _G.BetterRaidFrame_RaidInfoButton_OnClick then
		hooksecurefunc("BetterRaidFrame_RaidInfoButton_OnClick", function() 
			self:HookRaidInfoFrame()
			self:UpdateAnchor() 
		end)
	end
	
	-- Hook IgnoreList Module
	self:HookIgnoreListFrame()
end

function Compat:HookSettingsFrame()
	if self.settingsFrameHooked then return end
	
	local frame = _G["BetterFriendlistSettingsFrame"]
	if frame then
		-- Hook OnShow/OnHide script handlers to catch UI interactions (like 'X' button)
		frame:HookScript("OnShow", function() self:UpdateAnchor() end)
		frame:HookScript("OnHide", function() self:UpdateAnchor() end)
		self.settingsFrameHooked = true
	end
end

function Compat:HookHelpFrame()
	if self.helpFrameHooked then return end
	
	local frame = _G["BetterFriendlistHelpFrame"]
	if frame then
		frame:HookScript("OnShow", function() self:UpdateAnchor() end)
		frame:HookScript("OnHide", function() self:UpdateAnchor() end)
		self.helpFrameHooked = true
	end
end

function Compat:HookRaidInfoFrame()
	if self.raidInfoFrameHooked then return end
	
	local frame = _G["RaidInfoFrame"]
	if frame then
		-- Hook OnShow/OnHide
		frame:HookScript("OnShow", function() self:UpdateAnchor() end)
		frame:HookScript("OnHide", function() self:UpdateAnchor() end)
		self.raidInfoFrameHooked = true
	end
end

function Compat:HookIgnoreListFrame()
	if self.ignoreListFrameHooked then return end
	
	if BetterFriendsFrame and BetterFriendsFrame.IgnoreListWindow then
		BetterFriendsFrame.IgnoreListWindow:HookScript("OnShow", function() self:UpdateAnchor() end)
		BetterFriendsFrame.IgnoreListWindow:HookScript("OnHide", function() self:UpdateAnchor() end)
		self.ignoreListFrameHooked = true
	end
end

function Compat:UpdateAnchor()
	-- Check if GIL frame exists and is shown
	local gilFrame = _G["GIL"]
	if not gilFrame or not gilFrame:IsShown() then return end
	
	-- Check if BFL frame is shown
	local anchor = BetterFriendsFrame
	if not anchor or not anchor:IsShown() then return end
	
	-- Check for active side panels
	-- Settings Frame
	local settingsFrame = _G["BetterFriendlistSettingsFrame"]
	if settingsFrame and settingsFrame:IsShown() then
		anchor = settingsFrame
	end
	
	-- Ignore List Frame
	if BetterFriendsFrame and BetterFriendsFrame.IgnoreListWindow and BetterFriendsFrame.IgnoreListWindow:IsShown() then
		anchor = BetterFriendsFrame.IgnoreListWindow
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
end

function Compat:OnFriendsShow()
	-- Ensure hooks are ready (esp. for IgnoreList which might load late)
	self:HookIgnoreListFrame()
	
	-- Check user preference in GIL DB
	if GlobalIgnoreDB and GlobalIgnoreDB.openWithFriends then
		-- Ensure GIL is shown (creates frame if needed)
		if SlashCmdList["GIGNORE"] then
			SlashCmdList["GIGNORE"]("ui")
		end
		
		-- Update position
		self:UpdateAnchor()
	end
end

function Compat:OnFriendsHide()
	if GlobalIgnoreDB and GlobalIgnoreDB.openWithFriends then
		local gilFrame = _G["GIL"]
		if gilFrame and gilFrame:IsShown() then
			gilFrame:Hide()
		end
	end
end
