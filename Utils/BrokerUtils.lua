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
-- Broker Tooltip Font Helpers
-- ========================================
local function GetBrokerFontSize(sizeOffset)
	local size = BetterFriendlistDB and tonumber(BetterFriendlistDB.brokerFontSize) or 12
	size = size + (sizeOffset or 0)
	return math.max(6, math.floor(size + 0.5))
end

function BU.GetBrokerFontObject(sizeOffset)
	local fontName = BetterFriendlistDB and BetterFriendlistDB.brokerFont or "Friz Quadrata TT"
	local fontSize = GetBrokerFontSize(sizeOffset)

	if BFL.FontManager and BFL.FontManager.ResolveFontPath and BFL.FontManager.GetOrCreateFontFamily then
		local fontPath = BFL.FontManager:ResolveFontPath(fontName)
		if fontPath then
			local useCustomNonLatinFont = BetterFriendlistDB and BetterFriendlistDB.brokerUseCustomFontForNonLatin == true
			local fontFlags = BetterFriendlistDB and BetterFriendlistDB.brokerFontFlags or "SLUG"
			local fontObject = BFL.FontManager:GetOrCreateFontFamily(
				fontPath,
				fontSize,
				fontFlags,
				false,
				useCustomNonLatinFont
			)
			if fontObject then
				return fontObject
			end
		end
	end

	return (sizeOffset and sizeOffset > 0) and "GameTooltipHeaderText" or "GameTooltipText"
end

function BU.ApplyBrokerFontToFontString(fontString, sizeOffset)
	local valueType = type(fontString)
	if (valueType == "table" or valueType == "userdata") and fontString.SetFontObject then
		pcall(fontString.SetFontObject, fontString, BU.GetBrokerFontObject(sizeOffset))
	end
end

function BU.ApplyBrokerFontToCell(cell, sizeOffset)
	local valueType = type(cell)
	if (valueType == "table" or valueType == "userdata") and cell.SetFontObject then
		pcall(cell.SetFontObject, cell, BU.GetBrokerFontObject(sizeOffset))
		if cell.OnContentChanged then
			pcall(cell.OnContentChanged, cell)
		end
	end
end

function BU.ApplyBrokerFontToRow(row, sizeOffset)
	if not row then
		return
	end

	if row.Cells then
		for _, cell in pairs(row.Cells) do
			BU.ApplyBrokerFontToCell(cell, sizeOffset)
		end
	end

	if row.ColSpanCells then
		for _, cell in pairs(row.ColSpanCells) do
			BU.ApplyBrokerFontToCell(cell, sizeOffset)
		end
	end
end

function BU.ApplyBrokerFontToTooltip(tt, sizeOffset)
	if not tt or not tt.Rows then
		return
	end

	for _, row in pairs(tt.Rows) do
		BU.ApplyBrokerFontToRow(row, sizeOffset)
	end
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
	if dt and entry.LQT and dt.Key then
		pcall(entry.LQT.ReleaseTooltip, entry.LQT, dt)
	else
		BU.HideBrokerDetailTooltip(dt)
	end

	-- Release main tooltip
	if entry.tooltip and entry.LQT then
		pcall(entry.LQT.ReleaseTooltip, entry.LQT, entry.tooltip)
	end
end

function BU.SetActiveBrokerTooltip(tt, LQT, detailTooltipRef)
	activeBrokerEntry = { tooltip = tt, LQT = LQT, detailTooltipRef = detailTooltipRef }
end

function BU.ClearActiveBrokerTooltip(tt)
	if not activeBrokerEntry then
		return
	end

	if not tt or activeBrokerEntry.tooltip == tt then
		activeBrokerEntry = nil
	end
end

function BU.ScheduleBrokerTooltipRelease(LQT, tt)
	if not LQT or not tt or not tt.Key then
		return
	end

	if not C_Timer or not C_Timer.After then
		return
	end

	local releaseKey = tt.Key
	if tt.bflReleaseScheduled == releaseKey then
		return
	end

	tt.bflReleaseScheduled = releaseKey
	C_Timer.After(0, function()
		if tt.bflReleaseScheduled == releaseKey then
			tt.bflReleaseScheduled = nil
		end

		if tt.Key == releaseKey and (not tt.IsShown or not tt:IsShown()) then
			pcall(LQT.ReleaseTooltip, LQT, tt)
		end
	end)
end

function BU.GetOrCreateBrokerDetailTooltip(name)
	local tt = _G[name]
	if not tt then
		tt = CreateFrame("GameTooltip", name, UIParent, "GameTooltipTemplate")
	end
	tt:SetClampedToScreen(true)
	return tt
end

function BU.AnchorBrokerDetailTooltip(tt, owner, mainTooltip)
	if not tt or not owner then
		return
	end

	tt:SetOwner(owner, "ANCHOR_NONE")
	tt:ClearAllPoints()
	tt:SetFrameStrata("TOOLTIP")

	if mainTooltip and mainTooltip.GetFrameLevel and tt.SetFrameLevel then
		tt:SetFrameLevel((mainTooltip:GetFrameLevel() or 0) + 50)
	end

	local ownerCenter = owner.GetCenter and owner:GetCenter()
	local screenWidth = UIParent and UIParent.GetWidth and UIParent:GetWidth()
	if ownerCenter and screenWidth and ownerCenter > (screenWidth * 0.55) then
		tt:SetPoint("TOPRIGHT", owner, "TOPLEFT", -8, 2)
	else
		tt:SetPoint("TOPLEFT", owner, "TOPRIGHT", 8, 2)
	end
end

function BU.HideBrokerDetailTooltip(tt)
	if not tt then
		return
	end
	if tt.ClearLines then
		tt:ClearLines()
	end
	if tt.Hide then
		tt:Hide()
	end
end

-- ========================================
-- ElvUI Tooltip Skin Helpers
-- ========================================

--- Get the ElvUI engine object (cached check)
function BFL:GetElvUIEngine(requireInitialized)
	if type(_G.ElvUI) ~= "table" then
		return nil
	end

	local ok, E = pcall(function()
		return select(1, unpack(_G.ElvUI))
	end)
	if not ok or type(E) ~= "table" or type(E.GetModule) ~= "function" then
		return nil
	end
	if requireInitialized and not E.initialized then
		return nil
	end
	return E
end

function BFL:IsElvUIAvailable()
	return self:GetElvUIEngine(false) ~= nil
end

function BU.GetElvUIEngine()
	return BFL.GetElvUIEngine and BFL:GetElvUIEngine(true) or nil
end

--- Apply ElvUI skin to a LibQTip tooltip (mirrors ElvUI TT:SetStyle)
function BU.ApplyElvUISkin(tt)
	if not tt then return end
	if BFL and BFL.IsThemeActive and BFL:IsThemeActive("dark") then
		local Engine = BFL:GetModule("SkinEngine")
		if Engine then
			Engine:SkinTooltip(tt)
		end
		return
	end

	local E = BU.GetElvUIEngine()
	if not E then return end

	local wantSkin = BFL and BFL.IsThemeActive and BFL:IsThemeActive("elvui")
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
	if not tt then return end

	if tt.bflDarkSkinned and BFL then
		local Engine = BFL:GetModule("SkinEngine")
		if Engine then
			Engine:RestoreFrame(tt)
		end
	end

	if not tt.bflElvUISkinned then return end

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
-- Class Icon Helper (Inline Texture String)
-- ========================================
function BU.GetClassIcon(classFile, size)
	if not classFile or classFile == "" then
		return ""
	end
	size = size or 14
	local coords = CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[classFile]
	if not coords then
		return ""
	end
	return string.format(
		"|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:%d:%d:0:0:256:256:%d:%d:%d:%d|t",
		size, size,
		coords[1] * 256, coords[2] * 256, coords[3] * 256, coords[4] * 256
	)
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
