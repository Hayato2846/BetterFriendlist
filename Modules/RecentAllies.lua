-- Modules/RecentAllies.lua
-- Recent Allies System Module
-- Manages the recent allies list, data provider, and player interactions

local ADDON_NAME, BFL = ...

-- Register Module
local RecentAllies = BFL:RegisterModule("RecentAllies", {})

-- ========================================
-- Module Dependencies
-- ========================================

-- No direct dependencies, uses global WoW API

-- ========================================
-- Local Variables
-- ========================================

-- Recent Allies List Events
local RecentAlliesListEvents = {
	"RECENT_ALLIES_CACHE_UPDATE",
}

-- ========================================
-- Public API
-- ========================================

-- Initialize (called from ADDON_LOADED)
function RecentAllies:Initialize()
	-- Recent Allies is TWW-only (11.0.7+)
	if not BFL.HasRecentAllies then
		-- BFL:DebugPrint("|cffffcc00BFL RecentAllies:|r Not available in Classic - module disabled")
		return
	end
	-- Nothing else to initialize yet
end

-- Initialize Recent Allies Frame (RecentAlliesListMixin:OnLoad)
function RecentAllies:OnLoad(frame)
	-- Recent Allies is TWW-only (11.0.7+)
	if not BFL.HasRecentAllies then
		-- Show "Not Available" message for Classic users
		local notAvailableText = frame:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontNormal")
		notAvailableText:SetPoint("CENTER")
		notAvailableText:SetText(BFL.L.RECENT_ALLIES_NOT_AVAILABLE)
		notAvailableText:SetTextColor(0.5, 0.5, 0.5)
		frame.UnavailableText = notAvailableText
		
		-- Hide ScrollBox elements if they exist
		if frame.ScrollBox then frame.ScrollBox:Hide() end
		if frame.ScrollBar then frame.ScrollBar:Hide() end
		if frame.LoadingSpinner then frame.LoadingSpinner:Hide() end
		return
	end
	
	-- Initialize ScrollBox with element factory
	local elementSpacing = 1
	local topPadding, bottomPadding, leftPadding, rightPadding = 0, 0, 0, 0
	local view = CreateScrollBoxListLinearView(topPadding, bottomPadding, leftPadding, rightPadding, elementSpacing)
	
	view:SetElementFactory(function(factory, elementData)
		if elementData.isDivider then
			factory("BetterRecentAlliesDividerTemplate")
		else
			factory("BetterRecentAlliesEntryTemplate", function(button, elementData)
				RecentAllies:InitializeEntry(button, elementData)
				button:SetScript("OnClick", function(btn, mouseButtonName)
					if mouseButtonName == "LeftButton" then
						PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
						-- Selection behavior
						if frame.selectedEntry == btn then
							frame.selectedEntry = nil
							btn:UnlockHighlight()
						else
							if frame.selectedEntry then
								frame.selectedEntry:UnlockHighlight()
							end
							frame.selectedEntry = btn
							btn:LockHighlight()
						end
					elseif mouseButtonName == "RightButton" then
						RecentAllies:OpenMenu(btn)
					end
				end)
			end)
		end
	end)
	
	ScrollUtil.InitScrollBoxListWithScrollBar(frame.ScrollBox, frame.ScrollBar, view)
end

-- Show Recent Allies Frame (RecentAlliesListMixin:OnShow)
function RecentAllies:OnShow(frame)
	FrameUtil.RegisterFrameForEvents(frame, RecentAlliesListEvents)
	
	-- Show spinner initially, will hide when data is ready
	self:SetLoadingSpinnerShown(frame, true)
	
	-- Refresh will check if data is ready and hide spinner if it is
	self:Refresh(frame, ScrollBoxConstants.DiscardScrollPosition)
end

-- Hide Recent Allies Frame (RecentAlliesListMixin:OnHide)
function RecentAllies:OnHide(frame)
	FrameUtil.UnregisterFrameForEvents(frame, RecentAlliesListEvents)
end

-- Event handler (RecentAlliesListMixin:OnEvent)
function RecentAllies:OnEvent(frame, event, ...)
	if event == "RECENT_ALLIES_CACHE_UPDATE" then
		self:Refresh(frame, ScrollBoxConstants.RetainScrollPosition)
	end
end

-- Refresh the list (RecentAlliesListMixin:Refresh)
function RecentAllies:Refresh(frame, retainScrollPosition)
	-- Check if the Recent Allies system is enabled at all
	if not C_RecentAllies or not C_RecentAllies.IsSystemEnabled() then
		self:SetLoadingSpinnerShown(frame, false)
		-- Show a message that the system is not available
		if not frame.UnavailableText then
			frame.UnavailableText = frame:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontNormal")
			frame.UnavailableText:SetPoint("CENTER")
			frame.UnavailableText:SetText(BFL.L.RECENT_ALLIES_SYSTEM_UNAVAILABLE)
		end
		frame.UnavailableText:Show()
		return
	end
	
	-- Hide unavailable message if it exists
	if frame.UnavailableText then
		frame.UnavailableText:Hide()
	end
	
	-- Check if data is ready
	local dataReady = C_RecentAllies.IsRecentAllyDataReady()
	self:SetLoadingSpinnerShown(frame, not dataReady)
	
	if not dataReady then
		-- Data will load automatically, and we'll get RECENT_ALLIES_CACHE_UPDATE event
		return
	end
	
	local dataProvider = self:BuildDataProvider()
	frame.ScrollBox:SetDataProvider(dataProvider, retainScrollPosition)
end

-- Build data provider (RecentAlliesListMixin:BuildRecentAlliesDataProvider)
function RecentAllies:BuildDataProvider()
	-- Get recent allies (presorted by pin state, online status, most recent interaction, alphabetically)
	local recentAllies = C_RecentAllies.GetRecentAllies()
	local dataProvider = CreateDataProvider(recentAllies)
	
	-- Insert divider between pinned and unpinned allies
	local firstUnpinnedIndex = dataProvider:FindIndexByPredicate(function(elementData)
		return not elementData.stateData.pinExpirationDate
	end)
	
	if firstUnpinnedIndex and firstUnpinnedIndex > 1 then
		dataProvider:InsertAtIndex({ isDivider = true }, firstUnpinnedIndex)
	end
	
	return dataProvider
end

-- Set loading spinner visibility (RecentAlliesListMixin:SetLoadingSpinnerShown)
function RecentAllies:SetLoadingSpinnerShown(frame, shown)
	frame.LoadingSpinner:SetShown(shown)
	frame.ScrollBox:SetShown(not shown)
	frame.ScrollBar:SetShown(not shown)
end

-- Initialize a recent ally entry button (RecentAlliesEntryMixin:Initialize)
function RecentAllies:InitializeEntry(button, elementData)
	button.elementData = elementData
	
	local characterData = elementData.characterData
	local stateData = elementData.stateData
	local interactionData = elementData.interactionData
	
	-- Set online status icon
	local statusIcon = "Interface\\FriendsFrame\\StatusIcon-Offline"
	if stateData.isOnline then
		if stateData.isAFK then
			statusIcon = "Interface\\FriendsFrame\\StatusIcon-Away"
		elseif stateData.isDND then
			statusIcon = "Interface\\FriendsFrame\\StatusIcon-DnD"
		else
			statusIcon = "Interface\\FriendsFrame\\StatusIcon-Online"
		end
	end
	button.OnlineStatusIcon:SetTexture(statusIcon)
	
	-- Update background color based on online status
	button.NormalTexture:Show()
	local backgroundColor = stateData.isOnline and FRIENDS_WOW_BACKGROUND_COLOR or FRIENDS_OFFLINE_BACKGROUND_COLOR
	button.NormalTexture:SetColorTexture(backgroundColor:GetRGBA())
	
	-- Set name in class color (Line 1, Part 1)
	local classInfo = C_CreatureInfo.GetClassInfo(characterData.classID)
	local nameColor
	if stateData.isOnline and classInfo then
		nameColor = GetClassColorObj(classInfo.classFile)
	else
		nameColor = FRIENDS_GRAY_COLOR
	end
	button.CharacterData.Name:SetText(nameColor:WrapTextInColorCode(characterData.name))
	button.CharacterData.Name:SetWidth(math.min(button.CharacterData.Name:GetUnboundedStringWidth(), 150))
	
	-- Set level (Line 1, Part 2)
	local levelColor = stateData.isOnline and NORMAL_FONT_COLOR or FRIENDS_GRAY_COLOR
	button.CharacterData.Level:SetText(levelColor:WrapTextInColorCode(characterData.level))
	button.CharacterData.Level:SetWidth(button.CharacterData.Level:GetUnboundedStringWidth())
	
	-- Class (Line 1, Part 3)
	if classInfo then
		local classColor = stateData.isOnline and GetClassColorObj(classInfo.classFile) or FRIENDS_GRAY_COLOR
		button.CharacterData.Class:SetText(classColor:WrapTextInColorCode(classInfo.className))
	else
		button.CharacterData.Class:SetText("")
	end
	
	-- Update divider colors
	if button.CharacterData.Dividers then
		for _, divider in ipairs(button.CharacterData.Dividers) do
			if divider.SetTextColor then
				divider:SetTextColor(levelColor:GetRGB())
			else
				divider:SetVertexColor(levelColor:GetRGB())
			end
		end
	end
	
	-- Set most recent interaction (Line 2)
	local mostRecentInteraction = interactionData.interactions and #interactionData.interactions > 0 and interactionData.interactions[1]
	if mostRecentInteraction then
		button.CharacterData.MostRecentInteraction:SetText(mostRecentInteraction.description or "")
	else
		button.CharacterData.MostRecentInteraction:SetText("")
	end
	
	-- Set location (Line 3)
	button.CharacterData.Location:SetText(stateData.currentLocation or "")
	
	-- Update state icons
	button.StateIconContainer.PinDisplay:SetShown(stateData.pinExpirationDate ~= nil)
	if stateData.pinExpirationDate then
		-- Check if pin is nearing expiration
		local remainingDays = (stateData.pinExpirationDate - GetServerTime()) / SECONDS_PER_DAY
		local isNearingExpiration = remainingDays <= 7
		local atlas = isNearingExpiration and "friendslist-recentallies-pin" or "friendslist-recentallies-pin-yellow"
		button.StateIconContainer.PinDisplay.Icon:SetAtlas(atlas, true)
	end
	
	button.StateIconContainer.FriendRequestPendingDisplay:SetShown(stateData.hasFriendRequestPending or false)
	
	-- Enable/disable party button based on online status
	button.PartyButton:SetEnabled(stateData.isOnline)
	
	-- Setup party button click handler
	button.PartyButton:SetScript("OnClick", function()
		if characterData and characterData.fullName then
			C_PartyInfo.InviteUnit(characterData.fullName)
		end
	end)
	
	-- Setup party button tooltip
	button.PartyButton:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip_AddHighlightLine(GameTooltip, BFL.L.RECENT_ALLIES_INVITE)
		if not self:IsEnabled() then
			GameTooltip_AddErrorLine(GameTooltip, BFL.L.RECENT_ALLIES_PLAYER_OFFLINE)
		end
		GameTooltip:Show()
	end)
	
	button.PartyButton:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	
	-- Setup pin display tooltip
	if button.StateIconContainer.PinDisplay then
		button.StateIconContainer.PinDisplay:SetScript("OnEnter", function(self)
			if stateData.pinExpirationDate then
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				local timeUntilExpiration = math.max(stateData.pinExpirationDate - GetServerTime(), 1)
				local timeText = RecentAlliesUtil.GetFormattedTime(timeUntilExpiration)
				GameTooltip_AddHighlightLine(GameTooltip, BFL.L.RECENT_ALLIES_PIN_EXPIRES:format(timeText))
				GameTooltip:Show()
			end
		end)
		
		button.StateIconContainer.PinDisplay:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)
	end
end

-- Open context menu for recent ally
function RecentAllies:OpenMenu(button)
	local elementData = button.elementData
	if not elementData then return end
	
	local recentAllyData = elementData
	local contextData = {
		recentAllyData = recentAllyData,
		name = recentAllyData.characterData.name,
		server = recentAllyData.characterData.realmName,
		guid = recentAllyData.characterData.guid,
		isOffline = not recentAllyData.stateData.isOnline,
	}
	
	-- Use appropriate menu based on online status
	local bestMenu = recentAllyData.stateData.isOnline and "RECENT_ALLY" or "RECENT_ALLY_OFFLINE"
	
	-- Fallback to FRIEND menu if RECENT_ALLY not available
	if not UnitPopupMenus[bestMenu] then
		bestMenu = recentAllyData.stateData.isOnline and "FRIEND" or "FRIEND_OFFLINE"
	end
	
	-- Use compatibility wrapper for Classic support
	BFL.OpenContextMenu(button, bestMenu, contextData, contextData.name)
end

-- Build tooltip for recent ally (RecentAlliesEntryMixin:BuildRecentAllyTooltip)
function RecentAllies:BuildTooltip(button, tooltip)
	local elementData = button.elementData
	if not elementData then return end
	
	local characterData = elementData.characterData
	local stateData = elementData.stateData
	local interactionData = elementData.interactionData
	
	-- Character name
	GameTooltip_AddNormalLine(tooltip, characterData.fullName)
	
	-- Race and level
	local raceInfo = C_CreatureInfo.GetRaceInfo(characterData.raceID)
	if raceInfo then
		GameTooltip_AddHighlightLine(tooltip, BFL.L.RECENT_ALLIES_LEVEL_RACE:format(characterData.level, raceInfo.raceName))
	end
	
	-- Class
	local classInfo = C_CreatureInfo.GetClassInfo(characterData.classID)
	if classInfo then
		GameTooltip_AddHighlightLine(tooltip, classInfo.className)
	end
	
	-- Faction
	local factionInfo = C_CreatureInfo.GetFactionInfo(characterData.raceID)
	if factionInfo then
		GameTooltip_AddHighlightLine(tooltip, factionInfo.name)
	end
	
	-- Current location
	if stateData.currentLocation then
		GameTooltip_AddHighlightLine(tooltip, stateData.currentLocation)
	end
	
	-- Note
	if interactionData.note and interactionData.note ~= "" then
		GameTooltip_AddNormalLine(tooltip, BFL.L.RECENT_ALLIES_NOTE:format(interactionData.note))
	end
	
	-- Most recent interaction
	if interactionData.interactions and #interactionData.interactions > 0 and interactionData.interactions[1] then
		GameTooltip_AddBlankLineToTooltip(tooltip)
		local mostRecent = interactionData.interactions[1]
		GameTooltip_AddNormalLine(tooltip, BFL.L.RECENT_ALLIES_ACTIVITY)
		GameTooltip_AddHighlightLine(tooltip, mostRecent.description or "")
	end
end
