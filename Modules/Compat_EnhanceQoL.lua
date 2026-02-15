local ADDON_NAME, BFL = ...
local Compat = BFL:RegisterModule("Compat_EnhanceQoL", {})

-- EnhanceQoL Ignore List Compatibility Module
-- Supports opening EQOL Ignore List alongside BetterFriendlist and smart anchoring
-- Mirrors the Global Ignore List compat pattern

function Compat:Initialize()
	-- Check if EnhanceQoL is loaded or wait for it
	if C_AddOns.IsAddOnLoaded("EnhanceQoL") then
		self:Setup()
	else
		local frame = CreateFrame("Frame")
		frame:RegisterEvent("ADDON_LOADED")
		frame:SetScript("OnEvent", function(f, event, addonName)
			if addonName == "EnhanceQoL" then
				self:Setup()
				f:UnregisterEvent("ADDON_LOADED")
				f:SetScript("OnEvent", nil)
			end
		end)
	end
end

--- Check if the EQOL Ignore feature is enabled (master toggle)
---@return boolean
function Compat:IsIgnoreEnabled()
	local eqol = _G["EnhanceQoL"]
	if not eqol or not eqol.db then
		return false
	end
	return eqol.db.enableIgnore
end

--- Check if EQOL should auto-open/close with BetterFriendsFrame
---@return boolean
function Compat:ShouldAttach()
	if not self:IsIgnoreEnabled() then
		return false
	end
	local eqol = _G["EnhanceQoL"]
	return eqol.db.ignoreAttachFriendsFrame
end

--- Check if EQOL should anchor to our frames
---@return boolean
function Compat:ShouldAnchor()
	if not self:IsIgnoreEnabled() then
		return false
	end
	local eqol = _G["EnhanceQoL"]
	return eqol.db.ignoreAnchorFriendsFrame
end

function Compat:Setup()
	-- Verify EQOL Ignore feature is actually enabled
	local eqol = _G["EnhanceQoL"]
	if not eqol then
		return
	end

	-- Hook Main Frame
	if BetterFriendsFrame then
		BetterFriendsFrame:HookScript("OnShow", function()
			self:OnFriendsShow()
		end)
		BetterFriendsFrame:HookScript("OnHide", function()
			self:OnFriendsHide()
		end)
	end

	-- Hook Settings Module
	local Settings = BFL:GetModule("Settings")
	if Settings then
		hooksecurefunc(Settings, "Show", function()
			self:HookSettingsFrame()
			self:UpdateAnchor()
		end)
		hooksecurefunc(Settings, "Hide", function()
			self:UpdateAnchor()
		end)
	end

	-- Hook HelpFrame Module
	-- HelpFrame does not use RegisterModule, so it is located at BFL.HelpFrame
	local HelpFrame = BFL.HelpFrame
	if HelpFrame then
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
			hooksecurefunc(HelpFrame, "Hide", function()
				self:UpdateAnchor()
			end)
		end
	end

	-- Hook RaidFrame Module's RaidInfo Button
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
	if self.settingsFrameHooked then
		return
	end

	local frame = _G["BetterFriendlistSettingsFrame"]
	if frame then
		frame:HookScript("OnShow", function()
			self:UpdateAnchor()
		end)
		frame:HookScript("OnHide", function()
			self:UpdateAnchor()
		end)
		self.settingsFrameHooked = true
	end
end

function Compat:HookHelpFrame()
	if self.helpFrameHooked then
		return
	end

	local frame = _G["BetterFriendlistHelpFrame"]
	if frame then
		frame:HookScript("OnShow", function()
			self:UpdateAnchor()
		end)
		frame:HookScript("OnHide", function()
			self:UpdateAnchor()
		end)
		self.helpFrameHooked = true
	end
end

function Compat:HookRaidInfoFrame()
	if self.raidInfoFrameHooked then
		return
	end

	local frame = _G["RaidInfoFrame"]
	if frame then
		frame:HookScript("OnShow", function()
			self:UpdateAnchor()
		end)
		frame:HookScript("OnHide", function()
			self:UpdateAnchor()
		end)
		self.raidInfoFrameHooked = true
	end
end

function Compat:HookIgnoreListFrame()
	if self.ignoreListFrameHooked then
		return
	end

	if BetterFriendsFrame and BetterFriendsFrame.IgnoreListWindow then
		BetterFriendsFrame.IgnoreListWindow:HookScript("OnShow", function()
			self:UpdateAnchor()
		end)
		BetterFriendsFrame.IgnoreListWindow:HookScript("OnHide", function()
			self:UpdateAnchor()
		end)
		self.ignoreListFrameHooked = true
	end
end

function Compat:UpdateAnchor()
	if not self:ShouldAnchor() then
		return
	end

	local eqolFrame = _G["EQOLIgnoreFrame"]
	if not eqolFrame or not eqolFrame:IsShown() then
		return
	end

	-- Check if BFL frame is shown
	local anchor = BetterFriendsFrame
	if not anchor or not anchor:IsShown() then
		return
	end

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

	-- Help Frame
	local helpFrame = _G["BetterFriendlistHelpFrame"]
	if helpFrame and helpFrame:IsShown() then
		anchor = helpFrame
	end

	-- Raid Info Frame (highest priority, only if docked to BetterFriendsFrame)
	local raidInfoFrame = _G["RaidInfoFrame"]
	if raidInfoFrame and raidInfoFrame:IsShown() and raidInfoFrame:GetParent() == BetterFriendsFrame then
		anchor = raidInfoFrame
	end

	-- Apply Anchor
	eqolFrame:ClearAllPoints()
	eqolFrame:SetPoint("TOPLEFT", anchor, "TOPRIGHT", 12, -10)
end

function Compat:OnFriendsShow()
	-- Ensure hooks are ready (esp. for IgnoreList which might load late)
	self:HookIgnoreListFrame()

	if not self:ShouldAttach() then
		return
	end

	local eqolFrame = _G["EQOLIgnoreFrame"]
	if eqolFrame then
		eqolFrame:Show()
		self:UpdateAnchor()
	end
end

function Compat:OnFriendsHide()
	if not self:ShouldAttach() then
		return
	end

	local eqolFrame = _G["EQOLIgnoreFrame"]
	if eqolFrame and eqolFrame:IsShown() then
		eqolFrame:Hide()
	end
end
