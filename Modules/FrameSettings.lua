local ADDON_NAME, BFL = ...
local FrameSettings = BFL:RegisterModule("FrameSettings", {})

-- Constants for Limits
local MIN_WIDTH = 380
local MAX_WIDTH = 800
local MIN_HEIGHT = 400
local MAX_HEIGHT = 1200
local MIN_SCALE = 0.5
local MAX_SCALE = 2.0

local LEGACY_LAYOUT_KEY = "Default"
local MODERN_LAYOUT_KEY = "RetailModern"
local SHARED_POSITION_KEY = "Shared"

function FrameSettings:GetLayoutKey()
	local FriendsUI = BFL.FriendsUI or BFL:GetModule("FriendsUI")
	if FriendsUI and FriendsUI.GetLayoutKey then
		return FriendsUI:GetLayoutKey()
	end
	return LEGACY_LAYOUT_KEY
end

function FrameSettings:GetDefaultSize(layoutKey)
	if layoutKey == MODERN_LAYOUT_KEY then
		return 410, 675
	end
	return self.db.defaultFrameWidth or 415, self.db.defaultFrameHeight or 570
end

function FrameSettings:EnsureLayout(layoutKey)
	if not self.db.mainFrameSize[layoutKey] then
		local width, height = self:GetDefaultSize(layoutKey)
		self.db.mainFrameSize[layoutKey] = { width = width, height = height }
	end

	-- WoW can report scaled frame dimensions with small floating-point tails
	-- (for example 549.99987792969). Legacy size controls have always operated
	-- on whole pixels, so normalize only the Legacy bucket when it is read.
	-- Retail Modern keeps its independent geometry completely untouched.
	if layoutKey == LEGACY_LAYOUT_KEY then
		local size = self.db.mainFrameSize[layoutKey]
		if type(size) == "table" then
			if type(size.width) == "number" then
				size.width = math.floor(size.width + 0.5)
			end
			if type(size.height) == "number" then
				size.height = math.floor(size.height + 0.5)
			end
		end
	end
end

function FrameSettings:MigrateSharedPosition()
	local positions = self.db.mainFramePosition
	if not positions[SHARED_POSITION_KEY] then
		local activeLayoutKey = self:GetLayoutKey()
		positions[SHARED_POSITION_KEY] = positions[activeLayoutKey]
			or positions[LEGACY_LAYOUT_KEY]
			or positions[MODERN_LAYOUT_KEY]
	end
	positions[LEGACY_LAYOUT_KEY] = nil
	positions[MODERN_LAYOUT_KEY] = nil
end

function FrameSettings:GetPositionKey()
	return SHARED_POSITION_KEY
end

function FrameSettings:Initialize()
	self.db = BetterFriendlistDB

	-- Ensure DB structures exist
	if not self.db.mainFrameSize then
		self.db.mainFrameSize = {}
	end
	if not self.db.mainFramePosition then
		self.db.mainFramePosition = {}
	end
	if not self.db.windowScale then
		self.db.windowScale = 1.0
	end
	if self.db.lockWindow == nil then
		self.db.lockWindow = false
	end

	-- Keep Legacy and Retail Modern sizes independent, but use one shared
	-- position so a style switch never moves the window to a stale location.
	self:EnsureLayout(LEGACY_LAYOUT_KEY)
	if BFL.IsRetail then
		self:EnsureLayout(MODERN_LAYOUT_KEY)
	end
	self:MigrateSharedPosition()

	-- Hook MainFrame movement to save position
	-- Fix: Ensure BFL.MainFrame is set
	if not BFL.MainFrame and _G.BetterFriendsFrame then
		BFL.MainFrame = _G.BetterFriendsFrame
	end

	if BFL.MainFrame then
		local frame = BFL.MainFrame

		-- Apply initial settings
		self:ApplySettings()

		-- Hook for saving position after drag
		frame:HookScript("OnDragStop", function()
			self:ApplyClamping()
			self:SavePosition()
		end)

		-- Also hook OnMouseUp as a backup if OnDragStop isn't reliably firing for custom frames
		frame:HookScript("OnMouseUp", function()
			if frame.isMoving then
				self:SavePosition()
			end
		end)

		-- Save position when frame is hidden (crash protection: ensures position is
		-- persisted in SavedVariables before logout/reload writes them to disk)
		frame:HookScript("OnHide", function()
			self:SavePosition()
		end)

		-- Re-apply saved position when frame is shown (protection against external
		-- addons like ElvUI/MoveAnything overriding SetPoint outside of our control)
		frame:HookScript("OnShow", function()
			if not (self.db.useUIPanelSystem and not InCombatLockdown()) then
				self:ApplyPosition()
			end
			self:ApplyClamping()
			BFL.FontManager:RefreshWindowFonts()
		end)
	end
end

function FrameSettings:OnPlayerLogin()
	local function RefreshScale()
		self:QueueScaleRefresh(false, true)
	end

	BFL:RegisterEventCallback("DISPLAY_SIZE_CHANGED", RefreshScale)
	BFL:RegisterEventCallback("UI_SCALE_CHANGED", RefreshScale)
	BFL:RegisterEventCallback("CVAR_UPDATE", function(name)
		if type(name) ~= "string" or BFL:IsSecret(name) then return end
		name = name:lower()
		if name == "uiscale" or name == "useuiscale" then
			self:QueueScaleRefresh(true, true)
		elseif name == "gxmaximize" then
			self:QueueScaleRefresh(false, true)
		end
	end)
	BFL:RegisterEventCallback("PLAYER_REGEN_ENABLED", function()
		if self.scaleRefreshAfterCombat or self.displayTextRefreshAfterCombat then self:QueueScaleRefresh(false, true) end
		if self.positionAfterCombat then self:ApplyPosition() end
		self:ApplyClamping()
	end)
	self:QueueScaleRefresh(true)
end

function FrameSettings:QueueScaleRefresh(resetReference, refreshText)
	self.resetScaleReference = self.resetScaleReference or resetReference
	self.refreshDisplayText = self.refreshDisplayText or refreshText
	if self.scaleRefreshPending then return end

	self.scaleRefreshPending = true
	C_Timer.After(0, function()
		self.scaleRefreshPending = nil
		if self.resetScaleReference then
			self.referenceUIScale = UIParent:GetEffectiveScale()
			self.resetScaleReference = nil
		end
		self:ApplyScale()
		if not self.scaleRefreshAfterCombat and not self.db.useUIPanelSystem then
			self:ApplyPosition()
		end
		self:ApplyClamping()
		if self.refreshDisplayText then
			self.refreshDisplayText = nil
			self:QueueDisplayTextRefresh()
		end
	end)
end

function FrameSettings:QueueDisplayTextRefresh()
	self.displayTextRefreshGeneration = (self.displayTextRefreshGeneration or 0) + 1
	local generation = self.displayTextRefreshGeneration
	-- A mode switch can emit several scale/CVar events while native font metrics
	-- are settling. Only the last request refreshes BFL's own text regions.
	C_Timer.After(0.15, function()
		if generation ~= self.displayTextRefreshGeneration then return end
		if InCombatLockdown() then
			self.displayTextRefreshAfterCombat = true
			return
		end
		self.displayTextRefreshAfterCombat = nil
		if BFL.FontManager and BFL.FontManager.RefreshDisplayFonts then
			BFL.FontManager:RefreshDisplayFonts()
		end
		-- Measure group counters on the next frame, after button/font rebinding.
		C_Timer.After(0, function()
			if generation ~= self.displayTextRefreshGeneration then return end
			if InCombatLockdown() then self.displayTextRefreshAfterCombat = true; return end
			local list = BFL:GetModule("FriendsList")
			if list and list.RefreshGroupHeadersAfterDisplayChange then list:RefreshGroupHeadersAfterDisplayChange() end
		end)
	end)
end

function FrameSettings:ApplySettings()
	if not BFL.MainFrame then
		return
	end

	self:ApplySize()
	self:ApplyScale()
	self:ApplyPosition()
	self:ApplyLock()
	self:ApplyClamping()
end

function FrameSettings:ApplyClamping()
	local frame = BFL.MainFrame
	if not frame then
		return
	end

	if InCombatLockdown() and frame:IsProtected() then return end
	frame:SetClampedToScreen(true)
	if not (frame.SetClampRectInsets and frame.GetRect and BFL.WindowGeometry) then return end
	local geometry = BFL.WindowGeometry
	local left, bottom, width, height = geometry:GetRect(frame)
	if not left then return end
	local minLeft, minBottom, maxRight, maxTop = left, bottom, left + width, bottom + height
	local function Include(tab)
		if not (tab and tab:IsShown()) then return end
		if tab.GetAlpha and tab:GetAlpha() <= 0 then return end
		local x, y, w, h = geometry:GetRect(tab)
		if not x then return end
		minLeft, minBottom = math.min(minLeft, x), math.min(minBottom, y)
		maxRight, maxTop = math.max(maxRight, x + w), math.max(maxTop, y + h)
	end
	local friendsUI = BFL:GetModule("FriendsUI")
	if friendsUI and friendsUI.IsModernActive and friendsUI:IsModernActive() then
		for _, tab in ipairs(friendsUI.sideTabs or {}) do
			if tab:IsShown() and tab:GetAlpha() > 0 then
				Include(tab)
				for _, key in ipairs({ "Background", "SelectedTexture", "HighlightTexture", "TabGlow", "ThemeGlow" }) do
					Include(tab[key])
				end
			end
		end
	end
	for index = 1, 5 do Include(frame["BottomTab" .. index]) end
	local ratio = geometry:GetRatio(frame)
	frame:SetClampRectInsets((minLeft - left) / ratio, (maxRight - left - width) / ratio,
		(maxTop - bottom - height) / ratio, (minBottom - bottom) / ratio)
	-- Updating the insets alone need not move an already positioned frame.
	-- Re-read after native clamping so clients which apply it immediately do not move twice.
	local currentLeft, currentBottom = geometry:GetRect(frame)
	if not currentLeft then return end
	local unionLeft = currentLeft + minLeft - left
	local unionTop = currentBottom + maxTop - bottom
	local fitLeft, fitTop = geometry:Fit(unionLeft, unionTop, maxRight - minLeft, maxTop - minBottom)
	local dx, dy = fitLeft - unionLeft, fitTop - unionTop
	if math.abs(dx) > .001 or math.abs(dy) > .001 then
		if frame.AdjustPointsOffset then
			-- Retain existing anchors, including Blizzard's UIPanel positioning.
			frame:AdjustPointsOffset(dx / ratio, dy / ratio)
		else
			geometry:SetTopLeft(frame, currentLeft + dx, currentBottom + height + dy)
		end
	end
end

function FrameSettings:ApplyLock(locked)
	local frame = BFL.MainFrame
	if not frame then
		return
	end

	local isLocked = locked
	if isLocked == nil then
		isLocked = self.db.lockWindow
	end

	-- Save if explicitly changed
	if locked ~= nil then
		self.db.lockWindow = locked
	end

	frame:SetMovable(not isLocked)
	if isLocked then
		frame:RegisterForDrag() -- Unregister drag events
	else
		frame:RegisterForDrag("LeftButton")
	end
end

function FrameSettings:ApplySize(bgWidth, bgHeight)
	local frame = BFL.MainFrame
	if not frame then
		return
	end

	local layoutKey = self:GetLayoutKey()
	self:EnsureLayout(layoutKey)
	local currentSize = self.db.mainFrameSize[layoutKey]
	local width = bgWidth or currentSize.width
	local height = bgHeight or currentSize.height
	if layoutKey == LEGACY_LAYOUT_KEY then
		width = math.floor(width + 0.5)
		height = math.floor(height + 0.5)
	end

	-- Clamp values
	width = math.max(MIN_WIDTH, math.min(MAX_WIDTH, width))
	height = math.max(MIN_HEIGHT, math.min(MAX_HEIGHT, height))

	-- Persist normalized Legacy dimensions as well as explicit setting changes.
	-- This removes stale fractional values from SavedVariables permanently.
	if bgWidth or bgHeight or layoutKey == LEGACY_LAYOUT_KEY then
		currentSize.width = width
		currentSize.height = height
	end

	frame:SetSize(width, height)
	if bgWidth and BFL.ApplyTabFonts then
		C_Timer.After(0, function()
			BFL:ApplyTabFonts()
		end)
	end
	-- BFL:DebugPrint("FrameSettings: Applied size " .. width .. "x" .. height)
end

function FrameSettings:ApplyScale(scale)
	local frame = BFL.MainFrame
	if not frame then
		return
	end

	local newScale = scale or self.db.windowScale
	-- Clamp values
	newScale = math.max(MIN_SCALE, math.min(MAX_SCALE, newScale))

	-- Save if explicitly changed
	if scale then
		self.db.windowScale = newScale
	end

	local uiScale = UIParent:GetEffectiveScale()
	local relativeScale = newScale * (self.referenceUIScale or uiScale) / uiScale
	if frame:GetScale() ~= relativeScale then
		if InCombatLockdown() and frame:IsProtected() then
			self.scaleRefreshAfterCombat = true
			return
		end
		frame:SetScale(relativeScale)
	end
	self.scaleRefreshAfterCombat = nil

	local settings = BFL:GetModule("SettingsDesigner")
	self:ApplyAuxiliaryScale(settings and settings.GetFrame and settings:GetFrame())
	local tagEditor = BFL:GetModule("FriendTagEditor")
	if tagEditor and tagEditor.frame then
		tagEditor:FitWindow()
		self:ApplyAuxiliaryScale(tagEditor.frame)
	end
	local review = BFL:GetModule("LegacySettingsReview")
	if review and review.active then
		self:FitSettingsWindow(review.frame)
		BFL:GetModule("Settings"):RefreshVisibleWindowAnchor()
	end
end

function FrameSettings:ApplyAuxiliaryScale(window)
	if not (window and BFL.MainFrame) then return end

	-- Legacy Settings already inherits the main frame's scale. Keep the
	-- independent windows in step while allowing them to fit smaller screens.
	local fit = math.min(
		UIParent:GetWidth() / math.max(1, window:GetWidth()),
		UIParent:GetHeight() / math.max(1, window:GetHeight())
	)
	window:SetScale(math.min(BFL.MainFrame:GetScale(), fit))
end

function FrameSettings:FitSettingsWindow(frame)
	local parentRatio = frame:GetParent():GetEffectiveScale() / UIParent:GetEffectiveScale()
	frame:SetScale(math.min(1, (UIParent:GetWidth() - 24) / (640 * parentRatio),
		(UIParent:GetHeight() - 42) / (520 * parentRatio)))
	local ratio = BFL.WindowGeometry:GetRatio(frame)
	local maxWidth = (UIParent:GetWidth() - 24) / ratio
	local maxHeight = (UIParent:GetHeight() - 42) / ratio
	local saved = self.db.settingsWindowSize or {}
	local width = math.min(maxWidth, math.max(math.min(640, maxWidth), tonumber(saved.width) or 1170))
	local height = math.min(maxHeight, math.max(math.min(520, maxHeight), tonumber(saved.height) or 800))
	frame:SetResizeBounds(math.min(640, maxWidth), math.min(520, maxHeight), maxWidth, maxHeight)
	frame:SetSize(width, height)
	frame.CategoryList:SetWidth(width < 800 and 156 or 174)
end

function FrameSettings:InitializeSettingsWindow(frame)
	if frame.BFL_ResizeGrip then return end
	frame:SetResizable(true)
	local grip = CreateFrame("Button", nil, frame)
	grip:SetSize(20, 20)
	grip:SetPoint("BOTTOMRIGHT", -3, 3)
	grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
	grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
	grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
	grip.BFL_DarkManagedSubtree = true
	grip:SetScript("OnMouseDown", function(_, button)
		if button ~= "LeftButton" then return end
		frame.BFL_Resizing = true
		frame:StartSizing("BOTTOMRIGHT")
	end)
	local function StopSizing()
		if not frame.BFL_Resizing then return end
		frame.BFL_Resizing = nil
		frame:StopMovingOrSizing()
		local db = BFL:GetModule("DB")
		db:Set("settingsWindowSize", { width = math.floor(frame:GetWidth() + 0.5), height = math.floor(frame:GetHeight() + 0.5) })
		local settings = BFL:GetModule("Settings")
		if settings then settings:RefreshVisibleWindowAnchor() end
	end
	grip:SetScript("OnMouseUp", StopSizing)
	frame.BFL_StopResize = StopSizing
	frame:HookScript("OnHide", StopSizing)
	frame:HookScript("OnSizeChanged", function()
		frame.CategoryList:SetWidth(frame:GetWidth() < 800 and 156 or 174)
	end)
	frame.BFL_ResizeGrip = grip
end

function FrameSettings:ResetSettingsWindowSize()
	BFL:GetModule("DB"):Set("settingsWindowSize", {})
	local review = BFL:GetModule("LegacySettingsReview")
	if review and review.active then
		self:FitSettingsWindow(review.frame)
		BFL:GetModule("Settings"):RefreshVisibleWindowAnchor()
	end
end

function FrameSettings:ApplyPosition()
	local frame = BFL.MainFrame
	if not frame then
		return
	end
	if self.db.useUIPanelSystem then return end
	if InCombatLockdown() and frame:IsProtected() then
		self.positionAfterCombat = true
		return
	end
	self.positionAfterCombat = nil

	local pos = self.db.mainFramePosition[self:GetPositionKey()]
	if pos and pos.point then
		frame:ClearAllPoints()
		local x = tonumber(pos.x) or 0
		local y = tonumber(pos.y) or 0
		if x ~= x or math.abs(x) == math.huge then x = 0 end
		if y ~= y or math.abs(y) == math.huge then y = 0 end
		-- Valid offsets can exceed 5000 on wide screens or at a small UI scale.
		if BFL.WindowGeometry and frame.GetEffectiveScale and UIParent.GetWidth then
			local ratio = BFL.WindowGeometry:GetRatio(frame)
			local limitX = UIParent:GetWidth() / ratio + frame:GetWidth()
			local limitY = UIParent:GetHeight() / ratio + frame:GetHeight()
			x = math.max(-limitX, math.min(limitX, x))
			y = math.max(-limitY, math.min(limitY, y))
		end
		frame:SetPoint(pos.point, UIParent, pos.relativePoint or pos.point, x, y)
	else
		-- Default position if nothing saved
		frame:ClearAllPoints()
		frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	end
end

function FrameSettings:SavePosition()
	local frame = BFL.MainFrame
	if not frame then
		return
	end

	-- UIPanel positions belong to Blizzard, not the user's floating-window layout.
	if self.db.useUIPanelSystem then return end
	local point, _, relativePoint, x, y = frame:GetPoint()
	if frame.GetRect and BFL.WindowGeometry then
		local geometry = BFL.WindowGeometry
		local left, bottom, _, height = geometry:GetRect(frame)
		if left then
			local ratio = geometry:GetRatio(frame)
			point, relativePoint = "TOPLEFT", "TOPLEFT"
			x, y = left / ratio, (bottom + height - UIParent:GetHeight()) / ratio
		end
	end

	if point then
		self.db.mainFramePosition[self:GetPositionKey()] = {
			point = point,
			relativePoint = relativePoint,
			x = x,
			y = y,
		}
		-- BFL:DebugPrint("FrameSettings: Position saved")
	end
end

function FrameSettings:ResetDefaults()
	-- Reset to defaults defined in Database.lua indirectly
	self.db.windowScale = 1.0
	local layoutKey = self:GetLayoutKey()
	local width, height = self:GetDefaultSize(layoutKey)
	self.db.mainFrameSize[layoutKey] = { width = width, height = height }

	-- Reset position to center
	self.db.mainFramePosition[self:GetPositionKey()] = {
		point = "CENTER",
		relativePoint = "CENTER",
		x = 0,
		y = 0,
	}

	self:ApplySettings()
	print("|cff00ff00BetterFriendlist:|r Frame settings reset to defaults.")
end
