local ADDON_NAME, BFL = ...
local Compat = BFL:RegisterModule("Compat_NorthernSkyRaidTools", {})

local NSRT_ADDON_NAME = "NorthernSkyRaidTools"
local HOST_ADDON_NAME = "BetterFriendlist"

local PANEL_FRAME_X_OFFSET = 4
local PANEL_TOP_OFFSET = -2
local PANEL_BOTTOM_INSET = 3

local function GetRaidBuffAPI()
	local api = _G.NSAPI
	if type(api) ~= "table" or type(api.RegisterRaidBuffPanelHost) ~= "function" then
		return nil
	end
	return api
end

local function GetRaidBuffPanel()
	local nsrtInternal = _G.NSI
	return _G.NSIRaidBuffFrame or (nsrtInternal and nsrtInternal.RaidBuffCheck)
end

local function GetPanelHeight(parent)
	local frame = _G.BetterFriendsFrame
	if not (frame and parent) then
		return nil
	end

	local frameTop = frame:GetTop()
	local frameBottom = frame:GetBottom()
	if frameTop and frameBottom then
		local height = frameTop + PANEL_TOP_OFFSET - frameBottom - PANEL_BOTTOM_INSET
		if height > 0 then
			return height
		end
	end

	return parent:GetHeight()
end

function Compat:IsRaidTabVisible()
	local frame = _G.BetterFriendsFrame
	local raidFrame = frame and frame.RaidFrame
	if not (frame and raidFrame and PanelTemplates_GetSelectedTab) then
		return false
	end

	return frame:IsShown() and raidFrame:IsShown() and PanelTemplates_GetSelectedTab(frame) == 3
end

function Compat:GetRaidPanelParent()
	local frame = _G.BetterFriendsFrame
	return frame and frame.RaidFrame
end

function Compat:ApplyPanelLayout()
	if not self:IsRaidTabVisible() then
		return
	end

	local parent = self:GetRaidPanelParent()
	local panel = GetRaidBuffPanel()
	if not (parent and panel and panel:IsShown()) then
		return
	end

	panel:ClearAllPoints()
	panel:SetPoint("TOPLEFT", _G.BetterFriendsFrame, "TOPRIGHT", PANEL_FRAME_X_OFFSET, PANEL_TOP_OFFSET)

	local height = GetPanelHeight(parent)
	if height and height > 0 then
		panel:SetHeight(height)
	end
end

function Compat:RefreshPanel()
	local api = _G.NSAPI
	local updatePanel = api and api.UpdateRaidBuffPanel
	if type(updatePanel) ~= "function" then
		return
	end

	pcall(updatePanel, api)
	self:ApplyPanelLayout()
end

function Compat:InstallHooks()
	local frame = _G.BetterFriendsFrame
	if not frame then
		return
	end

	if not self.mainFrameHooksInstalled then
		frame:HookScript("OnShow", function()
			Compat:RefreshPanel()
		end)
		frame:HookScript("OnHide", function()
			Compat:RefreshPanel()
		end)
		self.mainFrameHooksInstalled = true
	end

	local raidFrame = frame.RaidFrame
	if raidFrame and not self.raidFrameHooksInstalled then
		raidFrame:HookScript("OnShow", function()
			Compat:RefreshPanel()
		end)
		raidFrame:HookScript("OnHide", function()
			Compat:RefreshPanel()
		end)
		self.raidFrameHooksInstalled = true
	end

	if hooksecurefunc and _G.BetterFriendsFrame_ShowBottomTab and not self.bottomTabHookInstalled then
		hooksecurefunc("BetterFriendsFrame_ShowBottomTab", function()
			Compat:RefreshPanel()
		end)
		self.bottomTabHookInstalled = true
	end

	local nsrtInternal = _G.NSI
	if
		hooksecurefunc
		and nsrtInternal
		and type(nsrtInternal.UpdateRaidBuffFrame) == "function"
		and not self.nsrtUpdateHookInstalled
	then
		hooksecurefunc(nsrtInternal, "UpdateRaidBuffFrame", function()
			Compat:ApplyPanelLayout()
		end)
		self.nsrtUpdateHookInstalled = true
	end
end

function Compat:RegisterHost()
	local api = GetRaidBuffAPI()
	if not api then
		return false
	end

	if not self.hostRegistered then
		local provider = {
			isVisible = function()
				return Compat:IsRaidTabVisible()
			end,
			getParent = function()
				return Compat:GetRaidPanelParent()
			end,
			getHeight = function(parent)
				return GetPanelHeight(parent)
			end,
		}

		local ok = pcall(api.RegisterRaidBuffPanelHost, api, HOST_ADDON_NAME, provider)
		if not ok then
			return false
		end

		self.hostRegistered = true
		self.provider = provider
	end

	self:InstallHooks()
	self:RefreshPanel()
	return true
end

function Compat:Initialize()
	if not BFL.IsRetail then
		return
	end

	self:RegisterHost()

	BFL:RegisterEventCallback("ADDON_LOADED", function(addonName)
		if addonName == NSRT_ADDON_NAME then
			Compat:RegisterHost()
		end
	end, 100)

	BFL:RegisterEventCallback("PLAYER_LOGIN", function()
		Compat:RegisterHost()
	end, 100)
end
