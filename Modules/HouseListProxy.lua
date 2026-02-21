-- Modules/HouseListProxy.lua
-- Secure Proxy for 12.0.0+ HouseListFrame "Visit House" button
-- Strategy: ScrollBox Callback (Clean Event-Based Native API)
-- hi osirisnz - you shouldn't do that

local ADDON_NAME, BFL = ...
local HouseListProxy = BFL:RegisterModule("HouseListProxy", {})

-- ========================================
-- Constants
-- ========================================

local TARGET_ADDON = "Blizzard_HouseList"

-- ========================================
-- Initialization
-- ========================================

function HouseListProxy:Initialize()
	-- Only needed on Retail 12.0.0+ (Midnight) where C_Housing is secure
	if not BFL.IsRetail then
		return
	end

	-- Register for ADDON_LOADED to setup when ready
	BFL:RegisterEventCallback("ADDON_LOADED", function(addonName)
		if addonName == TARGET_ADDON then
			self:SetupScrollBoxCallback()
		end
	end)

	-- Register for combat start to hide proxy
	BFL:RegisterEventCallback("PLAYER_REGEN_DISABLED", function()
		self:HideProxy()
	end)

	-- Register for combat end to process pending actions
	BFL:RegisterEventCallback("PLAYER_REGEN_ENABLED", function()
		self:ProcessPendingShow()
	end)

	-- Check if already loaded
	if C_AddOns and C_AddOns.IsAddOnLoaded(TARGET_ADDON) then
		self:SetupScrollBoxCallback()
	end
end

-- ========================================
-- Secure Proxy Creation
-- ========================================

function HouseListProxy:CreateGlobalProxy()
	if self.secureProxy then
		return self.secureProxy
	end

	local proxy = CreateFrame("Button", "BFL_HouseList_SecureProxy", UIParent, "InsecureActionButtonTemplate")

	proxy:SetFrameStrata("DIALOG")
	proxy:SetFrameLevel(9999)
	proxy:Hide()
	proxy:RegisterForClicks("AnyUp", "AnyDown")
	proxy:SetAttribute("type", "visithouse")

	proxy:SetScript("OnEnter", function(self)
		if self.visualButton and self.visualButton:GetScript("OnEnter") then
			pcall(self.visualButton:GetScript("OnEnter"), self.visualButton)
			self.visualButton:LockHighlight()
		end
	end)

	proxy:SetScript("OnLeave", function(self)
		if self.visualButton then
			if self.visualButton:GetScript("OnLeave") then
				pcall(self.visualButton:GetScript("OnLeave"), self.visualButton)
			end
			self.visualButton:UnlockHighlight()
		end
		self:Hide()
		self:ClearAllPoints()
		self.visualButton = nil
	end)

	proxy:SetScript("OnMouseDown", function(self)
		if self.visualButton then
			self.visualButton:SetButtonState("PUSHED")
		end
	end)

	proxy:SetScript("OnMouseUp", function(self)
		if self.visualButton then
			self.visualButton:SetButtonState("NORMAL")
		end
	end)

	self.secureProxy = proxy
	return proxy
end

-- ========================================
-- ScrollBox Callback Logic
-- ========================================

function HouseListProxy:SetupScrollBoxCallback()
	if self.callbackSetup then
		return
	end

	local hostFrame = _G.HouseListFrame
	if not hostFrame or not hostFrame.ScrollBox then
		return
	end

	self:CreateGlobalProxy()

	-- The "Clean" way: Register for the OnInitializedFrame event
	-- This tells us when a frame is created or reused
	if hostFrame.ScrollBox.RegisterCallback then
		hostFrame.ScrollBox:RegisterCallback("OnInitializedFrame", function(o, frame, elementData)
			self:SetupButtonInteraction(frame)
		end, self)
	end

	self.callbackSetup = true
end

function HouseListProxy:SetupButtonInteraction(rowFrame)
	local button = rowFrame.VisitHouseButton
	if not button then
		return
	end

	if button.bflHooked then
		return
	end

	button:HookScript("OnEnter", function(btn)
		local parentRow = btn:GetParent()
		local houseInfo = parentRow and parentRow.houseInfo

		if houseInfo then
			self:ShowProxy(btn, houseInfo)
		end
	end)

	button.bflHooked = true
end

-- ========================================
-- Interaction Logic
-- ========================================

function HouseListProxy:HideProxy()
	if self.secureProxy and self.secureProxy:IsShown() then
		self.secureProxy:Hide()
		self.secureProxy:ClearAllPoints()
		self.secureProxy.visualButton = nil
	end
	-- Clear any pending show
	self.pendingShow = nil
end

function HouseListProxy:ProcessPendingShow()
	if not self.pendingShow then
		return
	end

	local pending = self.pendingShow
	self.pendingShow = nil

	-- Only execute if button still exists, is visible, and mouse is still over it
	if pending.button and pending.button:IsVisible() and pending.button:IsMouseOver() then
		self:ShowProxy(pending.button, pending.houseInfo)
	end
end

function HouseListProxy:ShowProxy(button, houseInfo)
	-- Validate required house data first
	if not houseInfo then
		return
	end

	-- Validate required house data fields exist and are valid
	if not houseInfo.neighborhoodGUID or not houseInfo.houseGUID or not houseInfo.plotID then
		return
	end

	-- Validate GUIDs are non-empty strings
	if houseInfo.neighborhoodGUID == "" or houseInfo.houseGUID == "" then
		return
	end

	-- If in combat or restricted, queue the action for later
	if BFL:IsActionRestricted() then
		self.pendingShow = {
			button = button,
			houseInfo = houseInfo,
		}
		return
	end

	local proxy = self.secureProxy

	if proxy:IsShown() and proxy.visualButton == button then
		return
	end

	proxy:ClearAllPoints()
	proxy:SetAllPoints(button)

	proxy:SetAttribute("house-neighborhood-guid", houseInfo.neighborhoodGUID)
	proxy:SetAttribute("house-guid", houseInfo.houseGUID)
	proxy:SetAttribute("house-plot-id", houseInfo.plotID)

	proxy.visualButton = button
	proxy:Show()

	if proxy:GetScript("OnEnter") then
		proxy:GetScript("OnEnter")(proxy)
	end
end
