-- BetterFriendlist_Tooltip.lua
-- Friend list tooltip functionality using Blizzard's native FriendsTooltip
-- This allows compatibility with other addons (RaiderIO, etc.) that hook into FriendsTooltip

local _, BFL = ...
local L = BFL.L

-- Constants (must match Blizzard's values)
local FRIENDS_TOOLTIP_MAX_WIDTH = 200
local FRIENDS_TOOLTIP_MARGIN_WIDTH = 12

-- Local helper functions (copied from Blizzard's FriendsFrame.lua since they're local there)
local function ShowRichPresenceOnly(client, wowProjectID, faction, realmID, areaName)
	local playerFactionGroup = UnitFactionGroup("player")
	local playerRealmID = GetRealmID and GetRealmID() or 0
	
	if (client ~= BNET_CLIENT_WOW) or (wowProjectID ~= WOW_PROJECT_ID) then
		-- If they are not in wow or in a different version of wow, always show rich presence only
		return true
	elseif (WOW_PROJECT_ID == WOW_PROJECT_CLASSIC) and ((faction ~= playerFactionGroup) or (realmID ~= playerRealmID)) then
		-- If we are both in wow classic and our factions or realms don't match, show rich presence only
		return true
	else
		-- Otherwise show more detailed info about them
		return not areaName
	end
end

local function CanCooperateWithGameAccount(accountInfo)
	if not accountInfo or not accountInfo.gameAccountInfo then
		return false
	end
	local gameAccountInfo = accountInfo.gameAccountInfo
	local playerFactionGroup = UnitFactionGroup("player")
	
	-- Must be same faction and have valid realm
	return gameAccountInfo.factionName == playerFactionGroup and 
	       gameAccountInfo.realmID and gameAccountInfo.realmID > 0
end

-- Create our custom activity line inside FriendsTooltip
local function EnsureActivityLine()
	if not FriendsTooltip.BFLActivityText then
		-- Create a divider line
		local divider = FriendsTooltip:CreateTexture(nil, "ARTWORK")
		divider:SetColorTexture(0.3, 0.3, 0.3, 0.8)
		divider:SetHeight(1)
		FriendsTooltip.BFLActivityDivider = divider
		
		-- Create the activity text
		local activityText = FriendsTooltip:CreateFontString(nil, "ARTWORK", "FriendsFont_Small")
		activityText:SetJustifyH("LEFT")
		activityText:SetTextColor(0.5, 0.8, 1.0)
		activityText:SetWordWrap(false)
		FriendsTooltip.BFLActivityText = activityText
	end
	return FriendsTooltip.BFLActivityText, FriendsTooltip.BFLActivityDivider
end

-- Hook into FriendsTooltip:Show() to add our custom activity tracking info
local function AddBetterFriendlistInfo()
	local tooltip = FriendsTooltip
	local button = tooltip.button or tooltip.BFL_button
	
	if not button then return end
	
	-- Get friendData from our button if it exists, or use Blizzard's button properties
	local friendData = button.friendData
	local friendUID = nil
	
	if friendData then
		-- Optimization: Use pre-calculated UID from friendData (Phase 21)
		if friendData.uid then
			friendUID = friendData.uid
		elseif friendData.type == "bnet" and friendData.battleTag then
			local info = C_FriendList.GetFriendInfoByIndex(button.id)
			if info and info.name then
				friendUID = "wow_" .. info.name
			end
		end
	end
	
	-- Show activity tracking info if available
	if friendUID then
		local ActivityTracker = BFL and BFL:GetModule("ActivityTracker")
		if ActivityTracker then
			local lastActivity = ActivityTracker:GetLastActivity(friendUID)
			if lastActivity then
				local activityLine, divider = EnsureActivityLine()
				local timeSinceActivity = time() - lastActivity
				local activityText = "|cff80c0ff" .. L.TOOLTIP_LAST_CONTACT .. "|r " .. (L.TOOLTIP_AGO_PREFIX or "") .. SecondsToTime(timeSinceActivity) .. (L.TOOLTIP_AGO or "")
				
				-- Find the absolute bottom element to anchor below it
				local anchorElement = nil
				local elements = {
					FriendsTooltipGameAccountMany,
					FriendsTooltipGameAccount5Info,
					FriendsTooltipGameAccount4Info,
					FriendsTooltipGameAccount3Info,
					FriendsTooltipGameAccount2Info,
					FriendsTooltipLastOnline,
					FriendsTooltipBroadcastText,
					FriendsTooltipNoteText,
					FriendsTooltipGameAccount1Info,
					FriendsTooltipGameAccount1Name,
					FriendsTooltipHeader
				}
				
				for _, element in ipairs(elements) do
					if element and element:IsShown() then
						anchorElement = element
						break
					end
				end
				
				if anchorElement then
					-- Clear all constraints first to get accurate measurement
					activityLine:ClearAllPoints()
					activityLine:SetWidth(0)  -- Reset any fixed width
					
					-- Set text to measure width
					activityLine:SetText(activityText)
					
					-- Calculate required width for activity text and adjust tooltip width if needed
					-- Need left margin (6) + text width + right margin (6) + extra padding (8)
					local stringWidth = activityLine:GetStringWidth()
					local activityTextWidth = stringWidth + 28  -- 6px left + 6px right + 16px extra padding
					local currentWidth = tooltip:GetWidth()
					local newWidth = max(currentWidth, activityTextWidth)
					
					tooltip:SetWidth(newWidth + 8)  -- Add 8px extra padding to tooltip width
					
					-- Position divider anchored directly to tooltip, not to anchorElement for width
					-- This ensures divider spans full tooltip width
					divider:ClearAllPoints()
					local anchorBottom = anchorElement:GetBottom()
					local tooltipTop = tooltip:GetTop()
					local yOffset = anchorBottom - tooltipTop - 6  -- Calculate absolute Y position
					divider:SetPoint("TOPLEFT", tooltip, "TOPLEFT", 6, yOffset)
					divider:SetPoint("TOPRIGHT", tooltip, "TOPRIGHT", -6, yOffset)
					divider:Show()
					
					-- Position activity text below divider, centered
					activityLine:ClearAllPoints()
					activityLine:SetPoint("TOP", divider, "BOTTOM", 0, -4)
					activityLine:SetJustifyH("CENTER")
					activityLine:Show()
					
					-- Extend tooltip height
					local additionalHeight = 1 + 4 + activityLine:GetStringHeight() + 8  -- 8px bottom padding
					tooltip:SetHeight(tooltip:GetHeight() + additionalHeight)
				else
					divider:Hide()
					activityLine:Hide()
				end
			else
				if FriendsTooltip.BFLActivityText then
					FriendsTooltip.BFLActivityText:Hide()
					FriendsTooltip.BFLActivityDivider:Hide()
				end
			end
		end
	else
		if FriendsTooltip.BFLActivityText then
			FriendsTooltip.BFLActivityText:Hide()
			FriendsTooltip.BFLActivityDivider:Hide()
		end
	end
end

-- Hook FriendsTooltip:Show to add our info after Blizzard populates it
hooksecurefunc(FriendsTooltip, "Show", AddBetterFriendlistInfo)

-- Button OnEnter handler - Use Blizzard's native FriendsTooltip
function BetterFriendsList_Button_OnEnter(self)
	if not self.friendIndex or not self.friendData then
		return
	end

	local friendData = self.friendData
	local tooltip = FriendsTooltip
	local FriendsList = BFL and BFL:GetModule("FriendsList")
	local resolvedIndex = nil
	
	-- Create a fake button object that mimics Blizzard's FriendsListButton
	-- This allows RaiderIO and other addons to detect the friend info
	local fakeButton = {
		buttonType = nil,
		id = nil,
		-- Store our custom friendData for AddBetterFriendlistInfo
		friendData = friendData,
		-- Blizzard's code expects these methods on the button
		OnEnter = function() end,
		OnLeave = function() end,
	}
	
	if friendData.type == "bnet" then
		if friendData._isMock then
			fakeButton.buttonType = FRIENDS_BUTTON_TYPE_BNET
			fakeButton.id = friendData.index
		else
			-- Battle.net friend
			-- Resolve the current index since BNet indices are not persistent
			resolvedIndex = FriendsList and FriendsList.ResolveBNetFriendIndex and
				FriendsList:ResolveBNetFriendIndex(friendData.bnetAccountID, friendData.battleTag) or friendData.index
			fakeButton.buttonType = FRIENDS_BUTTON_TYPE_BNET
			fakeButton.id = resolvedIndex
		end
	else
		-- WoW friend
		-- Resolve the current index since WoW indices are not persistent
		resolvedIndex = FriendsList and FriendsList.ResolveWoWFriendIndex and
			FriendsList:ResolveWoWFriendIndex(friendData.name) or friendData.index
		if resolvedIndex and resolvedIndex > 0 then
			fakeButton.buttonType = FRIENDS_BUTTON_TYPE_WOW
			fakeButton.id = resolvedIndex
		end
	end
	
	if not fakeButton.buttonType or not fakeButton.id then
		return
	end
	
	-- Call Blizzard's tooltip population function via the mixin
	-- We simulate OnEnter by setting up tooltip.button and calling the display logic
	if BFL.IsClassic and not friendData._isMock then
		-- Classic Era: We must use the real button frame (self) instead of fakeButton (table)
		-- because FriendsFrame_OnUpdate expects a Frame object and will crash otherwise.
		-- We also need to ensure self has the required properties for FriendsFrameTooltip_Show.
		self.buttonType = fakeButton.buttonType
		self.id = fakeButton.id
		
		tooltip.button = self
		
		-- Ensure tooltip is visible and parented correctly
		tooltip:SetParent(UIParent)
		
		-- Manually call FriendsFrameTooltip_Show if available to populate immediately
		if FriendsFrameTooltip_Show then
			FriendsFrameTooltip_Show(self)
		end
		
		tooltip:Show()
		return -- Let Blizzard handle the rest for Classic
	else
		-- In Retail, use fakeButton. In Classic Mock mode, use nil (don't update)
		if not BFL.IsClassic then
			tooltip.button = fakeButton
		end
	end
	
	-- CRITICAL: Re-parent tooltip to UIParent so it shows even when FriendsFrame is hidden
	tooltip:SetParent(UIParent)
	
	-- Reset tooltip dimensions
	tooltip.height = 0
	tooltip.maxWidth = 0
	
	-- Hide activity line initially (will be shown by hook if needed)
	if FriendsTooltip.BFLActivityText then
		FriendsTooltip.BFLActivityText:Hide()
	end
	
	-- Populate tooltip using Blizzard's pattern
	local anchor, text
	local numGameAccounts = 0
	local battleTag = ""
	
	if fakeButton.buttonType == FRIENDS_BUTTON_TYPE_BNET then
		local accountInfo
		if friendData._isMock then
			accountInfo = friendData
			-- Ensure gameAccountID exists for logic checks if gameAccountInfo is present
			if accountInfo.gameAccountInfo and not accountInfo.gameAccountInfo.gameAccountID then
				accountInfo.gameAccountInfo.gameAccountID = 1
			end
		else
			accountInfo = C_BattleNet.GetFriendAccountInfo(fakeButton.id)
		end
		
		if accountInfo then
			local noCharacterName = true
			local nameText, nameColor
			
			-- [STREAMER MODE CHECK]
			if BFL.StreamerMode and BFL.StreamerMode:IsActive() and friendData then
				-- Force Streamer Mode compatible name
				nameText = BFL:GetModule("FriendsList"):GetDisplayName(friendData)
				nameColor = FRIENDS_BNET_NAME_COLOR
			else
				-- Classic Era: FriendsFrame_GetBNetAccountNameAndStatus doesn't exist
				if BFL.IsClassic or not FriendsFrame_GetBNetAccountNameAndStatus then
					-- Fallback: Use accountName and default color
					nameText = accountInfo.accountName or accountInfo.battleTag or "Unknown"
					nameColor = FRIENDS_BNET_NAME_COLOR
				else
					-- Retail: Use Blizzard's function
					nameText, nameColor = FriendsFrame_GetBNetAccountNameAndStatus(accountInfo, noCharacterName)
				end
			end

			battleTag = accountInfo.battleTag
			
			anchor = FriendsFrameTooltip_SetLine(FriendsTooltipHeader, nil, nameText)
			FriendsTooltipHeader:SetTextColor(nameColor:GetRGB())
			
			if accountInfo.gameAccountInfo and accountInfo.gameAccountInfo.gameAccountID then
				if ShowRichPresenceOnly(
					accountInfo.gameAccountInfo.clientProgram, 
					accountInfo.gameAccountInfo.wowProjectID, 
					accountInfo.gameAccountInfo.factionName, 
					accountInfo.gameAccountInfo.realmID, 
					accountInfo.gameAccountInfo.areaName
				) then
					local characterName
					if FriendsFrame_GetFormattedCharacterName then
						characterName = FriendsFrame_GetFormattedCharacterName(
							accountInfo.gameAccountInfo.characterName, 
							accountInfo.battleTag, 
							accountInfo.gameAccountInfo.clientProgram,
							accountInfo.gameAccountInfo.timerunningSeasonID
						)
					else
						-- Classic fallback: Just use character name
						characterName = accountInfo.gameAccountInfo.characterName or ""
					end
					FriendsFrameTooltip_SetLine(FriendsTooltipGameAccount1Name, nil, characterName)
					anchor = FriendsFrameTooltip_SetLine(FriendsTooltipGameAccount1Info, nil, accountInfo.gameAccountInfo.richPresence, -4)
				else
					local raceName = accountInfo.gameAccountInfo.raceName or UNKNOWN
					local className = accountInfo.gameAccountInfo.className or UNKNOWN
					if CanCooperateWithGameAccount(accountInfo) then
						text = string.format(FRIENDS_TOOLTIP_WOW_TOON_TEMPLATE, accountInfo.gameAccountInfo.characterName, accountInfo.gameAccountInfo.characterLevel, raceName, className)
					else
						text = string.format(FRIENDS_TOOLTIP_WOW_TOON_TEMPLATE, accountInfo.gameAccountInfo.characterName..CANNOT_COOPERATE_LABEL, accountInfo.gameAccountInfo.characterLevel, raceName, className)
					end
					if accountInfo.gameAccountInfo.timerunningSeasonID then
						text = TimerunningUtil.AddSmallIcon(text)
					end
					FriendsFrameTooltip_SetLine(FriendsTooltipGameAccount1Name, nil, text)
					local areaName = accountInfo.gameAccountInfo.areaName or UNKNOWN
					if accountInfo.gameAccountInfo.isInCurrentRegion then
						local realmName = accountInfo.gameAccountInfo.realmDisplayName or UNKNOWN
						local zoneRealmText
						if BNET_FRIEND_TOOLTIP_ZONE_AND_REALM then
							zoneRealmText = BNET_FRIEND_TOOLTIP_ZONE_AND_REALM:format(areaName, realmName)
						else
							-- Classic fallback
							zoneRealmText = areaName .. " - " .. realmName
						end
						anchor = FriendsFrameTooltip_SetLine(FriendsTooltipGameAccount1Info, nil, zoneRealmText, -4)
					else
						local regionNames = {
							[1] = NORTH_AMERICA,
							[2] = KOREA,
							[3] = EUROPE,
							[4] = TAIWAN,
							[5] = CHINA,
						}
						local regionNameString = regionNames[accountInfo.gameAccountInfo.regionID] or UNKNOWN
						local zoneRegionText
						if BNET_FRIEND_TOOLTIP_ZONE_AND_REGION then
							zoneRegionText = BNET_FRIEND_TOOLTIP_ZONE_AND_REGION:format(areaName, regionNameString)
						else
							-- Classic fallback
							zoneRegionText = areaName .. " - " .. regionNameString
						end
						anchor = FriendsFrameTooltip_SetLine(FriendsTooltipGameAccount1Info, nil, zoneRegionText, -4)
					end
				end
			else
				FriendsTooltipGameAccount1Info:Hide()
				FriendsTooltipGameAccount1Name:Hide()
			end
			
			-- Note
			if accountInfo.note and accountInfo.note ~= "" then
				FriendsTooltipNoteIcon:Show()
				anchor = FriendsFrameTooltip_SetLine(FriendsTooltipNoteText, anchor, accountInfo.note, -8)
			else
				FriendsTooltipNoteIcon:Hide()
				FriendsTooltipNoteText:Hide()
			end
			
			-- Broadcast
			if accountInfo.customMessage and accountInfo.customMessage ~= "" then
				FriendsTooltipBroadcastIcon:Show()
				local customMessage = accountInfo.customMessage
				if accountInfo.customMessageTime and not HasTimePassed(accountInfo.customMessageTime, 31536000) then
					customMessage = customMessage.."|n"..FRIENDS_BROADCAST_TIME_COLOR_CODE..string.format(BNET_BROADCAST_SENT_TIME, FriendsFrame_GetLastOnline(accountInfo.customMessageTime)..FONT_COLOR_CODE_CLOSE)
				end
				anchor = FriendsFrameTooltip_SetLine(FriendsTooltipBroadcastText, anchor, customMessage, -8)
				tooltip.hasBroadcast = true
			else
				FriendsTooltipBroadcastIcon:Hide()
				FriendsTooltipBroadcastText:Hide()
				tooltip.hasBroadcast = nil
			end
			
			if accountInfo.gameAccountInfo and accountInfo.gameAccountInfo.isOnline then
				FriendsTooltipLastOnline:Hide()
				numGameAccounts = C_BattleNet.GetFriendNumGameAccounts(fakeButton.id)
			else
			-- Classic Era fallback for FriendsFrame_GetLastOnlineText
			if FriendsFrame_GetLastOnlineText then
				text = FriendsFrame_GetLastOnlineText(accountInfo)
			elseif accountInfo.lastOnlineTime and accountInfo.lastOnlineTime > 0 then
				local SECONDS_PER_YEAR = 365 * 24 * 60 * 60
				local timeDiff = time() - accountInfo.lastOnlineTime
				if timeDiff >= SECONDS_PER_YEAR then
					text = FRIENDS_LIST_OFFLINE or "Offline"
				else
					local lastOnline = FriendsFrame_GetLastOnline and FriendsFrame_GetLastOnline(accountInfo.lastOnlineTime) or "Unknown"
					text = (BNET_LAST_ONLINE_TIME or "Last Online: %s"):format(lastOnline)
				end
			else
				text = FRIENDS_LIST_OFFLINE or "Offline"
			end
			anchor = FriendsFrameTooltip_SetLine(FriendsTooltipLastOnline, anchor, text, -4)
		end
	end
	
	elseif fakeButton.buttonType == FRIENDS_BUTTON_TYPE_WOW then
		local info
		if friendData._isMock then
			info = {
				name = friendData.name or "Unknown",
				level = friendData.level or 0,
				className = friendData.className or "Unknown",
				area = friendData.area or "Unknown",
				connected = friendData.connected,
				notes = friendData.notes,
			}
		else
			info = C_FriendList.GetFriendInfoByIndex(fakeButton.id)
		end

		if info then
			-- [STREAMER MODE CHECK]
			local displayName = info.name
			if BFL.StreamerMode and BFL.StreamerMode:IsActive() and friendData then
				displayName = BFL:GetModule("FriendsList"):GetDisplayName(friendData)
			end
			anchor = FriendsFrameTooltip_SetLine(FriendsTooltipHeader, nil, displayName)
			if info.connected then
				FriendsTooltipHeader:SetTextColor(FRIENDS_WOW_NAME_COLOR.r, FRIENDS_WOW_NAME_COLOR.g, FRIENDS_WOW_NAME_COLOR.b)
				FriendsFrameTooltip_SetLine(FriendsTooltipGameAccount1Name, nil, string.format(FRIENDS_LEVEL_TEMPLATE, info.level, info.className))
				anchor = FriendsFrameTooltip_SetLine(FriendsTooltipGameAccount1Info, nil, info.area)
			else
				FriendsTooltipHeader:SetTextColor(FRIENDS_GRAY_COLOR.r, FRIENDS_GRAY_COLOR.g, FRIENDS_GRAY_COLOR.b)
				FriendsTooltipGameAccount1Name:Hide()
				FriendsTooltipGameAccount1Info:Hide()
			end
			if info.notes and info.notes ~= "" then
				FriendsTooltipNoteIcon:Show()
				anchor = FriendsFrameTooltip_SetLine(FriendsTooltipNoteText, anchor, info.notes, -8)
			else
				FriendsTooltipNoteIcon:Hide()
				FriendsTooltipNoteText:Hide()
			end
			FriendsTooltipBroadcastIcon:Hide()
			FriendsTooltipBroadcastText:Hide()
			FriendsTooltipLastOnline:Hide()
		end
		end
		
		-- Handle multiple game accounts for BNet friends
		local gameAccountIndex = 1
		local playerRealmName = GetRealmName()
		local playerFactionGroup = UnitFactionGroup("player")
		local FRIENDS_TOOLTIP_MAX_GAME_ACCOUNTS = 5
		
		if numGameAccounts > 1 then
		local headerSet = false
		for i = 1, numGameAccounts do
			local gameAccountInfo = C_BattleNet.GetFriendGameAccountInfo(fakeButton.id, i)
			
			if gameAccountInfo and not gameAccountInfo.hasFocus and 
			   (gameAccountInfo.clientProgram ~= BNET_CLIENT_APP) and (gameAccountInfo.clientProgram ~= BNET_CLIENT_CLNT) then
				
				if not headerSet then
					FriendsFrameTooltip_SetLine(FriendsTooltipOtherGameAccounts, anchor, nil, -8)
					headerSet = true
				end
				
				gameAccountIndex = gameAccountIndex + 1
				if gameAccountIndex > FRIENDS_TOOLTIP_MAX_GAME_ACCOUNTS then
					break
				end
				
				local characterNameString = _G["FriendsTooltipGameAccount"..gameAccountIndex.."Name"]
				local gameAccountInfoString = _G["FriendsTooltipGameAccount"..gameAccountIndex.."Info"]
				local areaName = gameAccountInfo.areaName or UNKNOWN
				local raceName = gameAccountInfo.raceName or UNKNOWN
				local className = gameAccountInfo.className or UNKNOWN
				local gameText = gameAccountInfo.richPresence or ""
				text = ""
				local hasTitleIconTexture = false
				if C_Texture and C_Texture.GetTitleIconTexture and C_Texture.IsTitleIconTextureReady then
					hasTitleIconTexture = true
				end
				
				if Enum and Enum.TitleIconVersion and hasTitleIconTexture and
					C_Texture.IsTitleIconTextureReady(gameAccountInfo.clientProgram, Enum.TitleIconVersion.Small) then
					C_Texture.GetTitleIconTexture(gameAccountInfo.clientProgram, Enum.TitleIconVersion.Small, function(success, texture)
						if success then
							text = BNet_GetClientEmbeddedTexture(texture, 32, 32, 0).." "
						end
					end)
				end
				
				if (gameAccountInfo.clientProgram == BNET_CLIENT_WOW) and 
				   (gameAccountInfo.wowProjectID == WOW_PROJECT_ID) then
					if (gameAccountInfo.realmName == playerRealmName) and (gameAccountInfo.factionName == playerFactionGroup) then
						text = text..string.format(FRIENDS_TOOLTIP_WOW_TOON_TEMPLATE, gameAccountInfo.characterName, gameAccountInfo.characterLevel, raceName, className)
					else
						text = text..string.format(FRIENDS_TOOLTIP_WOW_TOON_TEMPLATE, gameAccountInfo.characterName..CANNOT_COOPERATE_LABEL, gameAccountInfo.characterLevel, raceName, className)
					end
					gameText = areaName
				else
					local characterName = ""
					if gameAccountInfo.isOnline then
						if FriendsFrame_GetFormattedCharacterName then
							characterName = FriendsFrame_GetFormattedCharacterName(gameAccountInfo.characterName, battleTag, gameAccountInfo.clientProgram, gameAccountInfo.timerunningSeasonID)
						else
							-- Classic fallback
							characterName = gameAccountInfo.characterName or ""
						end
					end
					text = text..characterName
				end
				
				FriendsFrameTooltip_SetLine(characterNameString, nil, text)
				FriendsFrameTooltip_SetLine(gameAccountInfoString, nil, gameText)
			end
		end
		
		if not headerSet then
			FriendsTooltipOtherGameAccounts:Hide()
		end
		else
		FriendsTooltipOtherGameAccounts:Hide()
		end
		
		-- Hide unused game account slots
		for i = gameAccountIndex + 1, FRIENDS_TOOLTIP_MAX_GAME_ACCOUNTS do
		local characterNameString = _G["FriendsTooltipGameAccount"..i.."Name"]
		local gameAccountInfoString = _G["FriendsTooltipGameAccount"..i.."Info"]
		if characterNameString then characterNameString:Hide() end
		if gameAccountInfoString then gameAccountInfoString:Hide() end
		end
		
		if numGameAccounts > FRIENDS_TOOLTIP_MAX_GAME_ACCOUNTS then
		FriendsFrameTooltip_SetLine(FriendsTooltipGameAccountMany, nil, string.format(FRIENDS_TOOLTIP_TOO_MANY_CHARACTERS, numGameAccounts - FRIENDS_TOOLTIP_MAX_GAME_ACCOUNTS), 0)
		else
		FriendsTooltipGameAccountMany:Hide()
		end
		
	-- Position and show the tooltip
	-- We must manually position the tooltip in both versions because:
	-- 1. Retail: Standard behavior
	-- 2. Classic: We cannot use tooltip.button (causes crash with table), so FriendsFrame_OnUpdate won't position it for us
	tooltip:ClearAllPoints()
	tooltip:SetPoint("TOPLEFT", self, "TOPRIGHT", 36, 0)
	
	-- Calculate dimensions
	local finalHeight = max(tooltip.height + FRIENDS_TOOLTIP_MARGIN_WIDTH, 40)
	local finalWidth = max(min(FRIENDS_TOOLTIP_MAX_WIDTH, tooltip.maxWidth + FRIENDS_TOOLTIP_MARGIN_WIDTH), 100)
	tooltip:SetHeight(finalHeight)
	tooltip:SetWidth(finalWidth)
	
	-- Ensure tooltip is visible
	tooltip:SetFrameStrata("TOOLTIP")
	tooltip:SetFrameLevel(100)
	tooltip:Show()
	tooltip:Raise()
	
	-- Classic Era logic handled above (early return)

end

-- Button OnLeave handler
function BetterFriendsList_Button_OnLeave(self)
	local tooltip = FriendsTooltip
	if BFL.IsClassic then
		tooltip.button = nil
	else
		tooltip.button = nil
	end
	tooltip:Hide()
end
