-- Utils/BrokerUtils.lua
-- Shared utilities for Data Broker plugins (Friends Broker + Guild Broker)
-- Extracted from Modules/Broker.lua to avoid duplication

local ADDON_NAME, BFL = ...

BFL.BrokerUtils = {}
local BU = BFL.BrokerUtils

-- ========================================
-- Color Wrapper
-- ========================================
local COLOR_TABLE = {
	dkyellow = "ffcc00",
	ltyellow = "ffff99",
	ltblue = "6699ff",
	ltgray = "b0b0b0",
	gray = "808080",
	white = "ffffff",
	green = "00ff00",
	red = "ff0000",
	gold = "ffd700",
}

function BU.C(color, text)
	if not text then
		return ""
	end

	-- Check if it's a class color (try direct match first, then convert from localized name)
	local classColor = RAID_CLASS_COLORS[color]
	if not classColor then
		local classFile = BFL.ClassUtils and BFL.ClassUtils:GetClassFileFromClassName(color)
		if classFile then
			classColor = RAID_CLASS_COLORS[classFile]
		end
	end

	if classColor then
		return string.format("|cff%02x%02x%02x%s|r", classColor.r * 255, classColor.g * 255, classColor.b * 255, text)
	end

	-- Otherwise use predefined or custom hex
	local hex = COLOR_TABLE[color] or color
	return "|cff" .. hex .. text .. "|r"
end

-- ========================================
-- Status Icon Helper (AFK/DND/Online)
-- ========================================
function BU.GetStatusIcon(isAFK, isDND, isMobile)
	local showMobileAsAFK = BetterFriendlistDB and BetterFriendlistDB.showMobileAsAFK

	if isAFK or (isMobile and showMobileAsAFK) then
		return "|TInterface\\FriendsFrame\\StatusIcon-Away:12:12:0:0:32:32:5:27:5:27|t"
	elseif isDND then
		return "|TInterface\\FriendsFrame\\StatusIcon-DnD:12:12:0:0:32:32:5:27:5:27|t"
	else
		return "|TInterface\\FriendsFrame\\StatusIcon-Online:12:12:0:0:32:32:5:27:5:27|t"
	end
end

-- ========================================
-- Faction Icon Helper
-- ========================================
function BU.GetFactionIcon(factionName)
	if not factionName then
		return ""
	end

	if factionName == "Alliance" then
		return "|TInterface\\FriendsFrame\\PlusManz-Alliance:16:16|t"
	elseif factionName == "Horde" then
		return "|TInterface\\FriendsFrame\\PlusManz-Horde:16:16|t"
	else
		return "" -- Neutral or unknown
	end
end

-- ========================================
-- Class Color Text (from classFile or friend table)
-- ========================================

-- Color text by class file name (e.g., "WARRIOR", "PALADIN")
function BU.ClassColorTextByFile(classFile, text)
	if not text then
		return ""
	end
	local classColor = classFile and RAID_CLASS_COLORS[classFile]
	if classColor then
		return string.format("|cff%02x%02x%02x%s|r", classColor.r * 255, classColor.g * 255, classColor.b * 255, text)
	end
	return text
end

-- Color text by friend data table (uses ClassUtils for classID/className resolution)
function BU.ClassColorText(friend, text)
	if not text then
		return ""
	end
	local classColor = BFL.ClassUtils and BFL.ClassUtils:GetClassColorForFriend(friend)
	if classColor then
		return string.format("|cff%02x%02x%02x%s|r", classColor.r * 255, classColor.g * 255, classColor.b * 255, text)
	end
	return text
end

-- ========================================
-- Menu Open Detection
-- ========================================
function BU.IsMenuOpen()
	if UIDROPDOWNMENU_OPEN_MENU and UIDROPDOWNMENU_OPEN_MENU:IsShown() then
		return true
	end
	if _G.Lib_UIDROPDOWNMENU_OPEN_MENU and _G.Lib_UIDROPDOWNMENU_OPEN_MENU:IsShown() then
		return true
	end

	if Menu and Menu.GetManager then
		local manager = Menu.GetManager()
		if manager and manager.GetOpenMenu then
			local openMenu = manager:GetOpenMenu()
			if openMenu and openMenu.IsShown and openMenu:IsShown() then
				return true
			end
		end
	end

	return false
end

-- ========================================
-- Active Broker Tooltip Tracking
-- ========================================
-- Prevents overlapping tooltips when hovering between Friends and Guild plugins.
-- Each plugin registers its tooltip on creation and dismisses the previous one.

local activeBrokerEntry = nil -- { tooltip, detailTooltipRef, LQT }

function BU.DismissActiveBrokerTooltip()
	if not activeBrokerEntry then
		return
	end
	local entry = activeBrokerEntry
	activeBrokerEntry = nil -- clear first to prevent re-entry

	-- Release detail tooltip if present
	local dt = entry.detailTooltipRef and entry.detailTooltipRef()
	if dt and entry.LQT then
		pcall(entry.LQT.ReleaseTooltip, entry.LQT, dt)
	end

	-- Release main tooltip
	if entry.tooltip and entry.LQT then
		pcall(entry.LQT.ReleaseTooltip, entry.LQT, entry.tooltip)
	end
end

function BU.SetActiveBrokerTooltip(tt, LQT, detailTooltipRef)
	activeBrokerEntry = { tooltip = tt, LQT = LQT, detailTooltipRef = detailTooltipRef }
end

function BU.ClearActiveBrokerTooltip()
	activeBrokerEntry = nil
end

-- ========================================
-- ElvUI Tooltip Skin Helpers
-- ========================================

--- Get the ElvUI engine object (cached check)
function BU.GetElvUIEngine()
	if not _G.ElvUI then return nil end
	local ok, E = pcall(function() return select(1, unpack(_G.ElvUI)) end)
	if ok and E and E.initialized then return E end
	return nil
end

--- Apply ElvUI skin to a LibQTip tooltip (mirrors ElvUI TT:SetStyle)
function BU.ApplyElvUISkin(tt)
	if not tt then return end
	local E = BU.GetElvUIEngine()
	if not E then return end

	local wantSkin = BetterFriendlistDB and BetterFriendlistDB.enableElvUISkin
	if not wantSkin then return end

	-- Hide default NineSlice backdrop (same as ElvUI TT:SetStyle)
	if tt.NineSlice then tt.NineSlice:SetAlpha(0) end

	-- Apply ElvUI template directly on the tooltip frame
	if tt.SetTemplate then
		tt:SetTemplate("Transparent")
	end

	tt.bflElvUISkinned = true
end

--- Remove ElvUI skin from a LibQTip tooltip (restore default appearance)
function BU.RemoveElvUISkin(tt)
	if not tt or not tt.bflElvUISkinned then return end

	-- Restore NineSlice visibility
	if tt.NineSlice then
		tt.NineSlice:SetAlpha(1)
		NineSlicePanelMixin.OnLoad(tt.NineSlice)
		if GameTooltip.layoutType then
			tt.NineSlice:SetCenterColor(GameTooltip.NineSlice:GetCenterColor())
			tt.NineSlice:SetBorderColor(GameTooltip.NineSlice:GetBorderColor())
		end
	end

	-- Remove ElvUI's flat backdrop
	if tt.SetBackdrop then
		tt:SetBackdrop(nil)
	end

	-- Hide ElvUI inner/outer border frames
	if tt.iborder then tt.iborder:Hide() end
	if tt.oborder then tt.oborder:Hide() end

	-- Hide old CreateBackdrop child frame
	if tt.backdrop then tt.backdrop:Hide() end

	-- Remove from ElvUI's frame update tracking
	local E = BU.GetElvUIEngine()
	if E and E.frames then
		E.frames[tt] = nil
	end

	tt.bflElvUISkinned = nil
end

-- ========================================
-- Tooltip Auto-Hide (Custom timer with menu detection)
-- ========================================
-- detailTooltipRef: optional function that returns the detail tooltip to check for mouse-over
function BU.SetupTooltipAutoHide(tt, anchorFrame, LQT, detailTooltipRef)
	tt:SetAutoHideDelay(nil) -- Disable LibQTip's built-in auto-hide

	if not tt.bflTimer then
		tt.bflTimer = CreateFrame("Frame", nil, tt)
	end

	local timer = tt.bflTimer
	timer.hideTimer = 0
	timer.checkTimer = 0
	timer.menuOpenTimer = 0

	timer:SetScript("OnUpdate", function(self, elapsed)
		self.checkTimer = self.checkTimer + elapsed
		if self.checkTimer < 0.1 then
			return
		end

		local checkInterval = self.checkTimer
		self.checkTimer = 0

		local isOver = (tt.IsMouseOver and tt:IsMouseOver())

		if not isOver and anchorFrame and anchorFrame.IsMouseOver and anchorFrame:IsMouseOver() then
			isOver = true
		end

		-- Check detail tooltip if provided
		local dt = detailTooltipRef and detailTooltipRef()
		if
			not isOver
			and dt
			and dt.IsShown
			and dt:IsShown()
			and dt.IsMouseOver
			and dt:IsMouseOver()
		then
			isOver = true
		end

		if isOver then
			self.hideTimer = 0
			self.menuOpenTimer = 0
		else
			if BU.IsMenuOpen() then
				self.hideTimer = 0

				self.menuOpenTimer = (self.menuOpenTimer or 0) + checkInterval
				if self.menuOpenTimer > 2.0 then
					if LQT then
						pcall(function()
							LQT:ReleaseTooltip(tt)
						end)
					end
					self:SetScript("OnUpdate", nil)
				end
			else
				self.hideTimer = self.hideTimer + checkInterval
				self.menuOpenTimer = 0

				if self.hideTimer >= 0.25 then
					if LQT then
						pcall(function()
							LQT:ReleaseTooltip(tt)
						end)
					end
					self:SetScript("OnUpdate", nil)
				end
			end
		end
	end)
end

-- ========================================
-- Last Online Formatting
-- ========================================
function BU.FormatLastOnline(years, months, days, hours)
	if not years and not months and not days and not hours then
		return ""
	end

	local L = BFL.L

	years = years or 0
	months = months or 0
	days = days or 0
	hours = hours or 0

	if years > 0 then
		if L and L.GUILD_BROKER_LAST_ONLINE_YEARS then
			return string.format(L.GUILD_BROKER_LAST_ONLINE_YEARS, years)
		end
		return string.format("%dy", years)
	elseif months > 0 then
		if L and L.GUILD_BROKER_LAST_ONLINE_MONTHS then
			return string.format(L.GUILD_BROKER_LAST_ONLINE_MONTHS, months)
		end
		return string.format("%dmo", months)
	elseif days > 0 then
		if L and L.GUILD_BROKER_LAST_ONLINE_DAYS then
			return string.format(L.GUILD_BROKER_LAST_ONLINE_DAYS, days)
		end
		return string.format("%dd", days)
	elseif hours > 0 then
		if L and L.GUILD_BROKER_LAST_ONLINE_HOURS then
			return string.format(L.GUILD_BROKER_LAST_ONLINE_HOURS, hours)
		end
		return string.format("%dh", hours)
	else
		if L and L.GUILD_BROKER_LAST_ONLINE_NOW then
			return L.GUILD_BROKER_LAST_ONLINE_NOW
		end
		return "Online"
	end
end

-- ========================================
-- Chat Name Insert Helper
-- ========================================
function BU.AddNameToEditBox(name, realm)
	if not name then
		return false
	end

	-- Add realm suffix if different from player's realm
	local playerRealm = GetRealmName()
	if realm and realm ~= "" and realm ~= playerRealm then
		name = name .. "-" .. realm
	end

	-- Find active chat editbox and insert name
	local editboxes = {
		ChatEdit_GetActiveWindow(),
		ChatEdit_GetLastActiveWindow(),
	}

	for _, editbox in ipairs(editboxes) do
		if editbox and editbox:IsVisible() and editbox:HasFocus() then
			editbox:Insert(name)
			return true
		end
	end

	-- Fallback: Insert into default chat frame's editbox
	local defaultEditBox = ChatEdit_ChooseBoxForSend()
	if defaultEditBox then
		ChatEdit_ActivateChat(defaultEditBox)
		defaultEditBox:Insert(name)
		return true
	end

	return false
end
