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

	-- Register for combat start to hide proxy and show overlays on all buttons
	BFL:RegisterEventCallback("PLAYER_REGEN_DISABLED", function()
		self:HideProxy()
		self:ShowAllCombatOverlays()
	end)

	-- Register for combat end to hide overlays and process pending actions
	BFL:RegisterEventCallback("PLAYER_REGEN_ENABLED", function()
		self:HideAllCombatOverlays()
		self:ProcessPendingShow()
		-- If proxy creation was deferred due to combat, create it now
		if self.deferredProxyCreation then
			self.deferredProxyCreation = false
			self:CreateGlobalProxy()
			-- If callback setup was deferred, complete it now
			if self.deferredCallbackSetup then
				self.deferredCallbackSetup = false
				self:SetupScrollBoxCallback()
			end
		end
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

	-- CRITICAL: Secure frames cannot be created during combat
	-- Defer creation until combat ends
	if BFL:IsActionRestricted() then
		self.deferredProxyCreation = true
		return nil
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

	-- Try to create proxy (will defer if in combat)
	self:CreateGlobalProxy()

	-- If proxy creation was deferred, defer callback setup too
	if self.deferredProxyCreation then
		self.deferredCallbackSetup = true
		return
	end

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

	-- Show combat overlay whenever the button becomes visible during combat
	button:HookScript("OnShow", function(btn)
		if BFL:IsActionRestricted() and btn.bflCombatOverlay then
			btn.bflCombatOverlay:Show()
		end
	end)

	-- Create combat overlay for this button
	self:CreateButtonCombatOverlay(button)

	-- Track the button
	if not self.hookedButtons then
		self.hookedButtons = {}
	end
	self.hookedButtons[button] = true

	-- If currently in combat, show overlay immediately
	if BFL:IsActionRestricted() and button.bflCombatOverlay then
		button.bflCombatOverlay:Show()
	end

	button.bflHooked = true
end

-- ========================================
-- Combat Overlay (per-button)
-- ========================================

function HouseListProxy:CreateButtonCombatOverlay(button)
	if button.bflCombatOverlay then
		return button.bflCombatOverlay
	end

	-- Use UIPanelButtonTemplate so the overlay has the same rounded shape as the VisitHouseButton
	local overlay = CreateFrame("Button", nil, button, "UIPanelButtonTemplate")
	overlay:SetAllPoints(button)
	overlay:SetFrameLevel(button:GetFrameLevel() + 5)
	overlay:SetMotionScriptsWhileDisabled(true)
	overlay:Disable()
	overlay:Hide()

	-- Tint the disabled texture darker for a clear visual distinction
	local disabledTex = overlay:GetDisabledTexture()
	if disabledTex then
		disabledTex:SetVertexColor(0.4, 0.4, 0.4, 1.0)
	end

	-- Show localized combat text on the button
	overlay:SetDisabledFontObject(GameFontDisable)
	local L = BFL.L
	if L and L.HOUSING_COMBAT_RESTRICTED then
		overlay:SetText(L.HOUSING_COMBAT_RESTRICTED)
	end

	-- Tooltip on hover explaining the restriction
	overlay:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		local L = BFL.L
		if L and L.HOUSING_COMBAT_RESTRICTED then
			GameTooltip:SetText(L.HOUSING_COMBAT_RESTRICTED, 1.0, 0.1, 0.1, 1.0, true)
		end
		GameTooltip:Show()
	end)

	overlay:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	button.bflCombatOverlay = overlay
	return overlay
end

function HouseListProxy:ShowAllCombatOverlays()
	if not self.hookedButtons then
		return
	end
	for button in pairs(self.hookedButtons) do
		if button:IsVisible() and button.bflCombatOverlay then
			button.bflCombatOverlay:Show()
		end
	end
end

function HouseListProxy:HideAllCombatOverlays()
	if not self.hookedButtons then
		return
	end
	for button in pairs(self.hookedButtons) do
		if button.bflCombatOverlay then
			button.bflCombatOverlay:Hide()
		end
	end
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

	-- If in combat or restricted, queue the action for later (overlay is already visible)
	if BFL:IsActionRestricted() then
		self.pendingShow = {
			button = button,
			houseInfo = houseInfo,
		}
		return
	end

	-- If proxy doesn't exist yet (e.g., deferred creation), can't show it
	local proxy = self.secureProxy
	if not proxy then
		return
	end

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
