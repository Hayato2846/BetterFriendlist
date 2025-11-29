-- BetterFriendlist_Tooltip.lua
-- Friend list tooltip functionality using Blizzard's native FriendsTooltip
-- This allows compatibility with other addons (RaiderIO, etc.) that hook into FriendsTooltip

local _, BFL = ...

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
	local button = tooltip.button
	
	if not button then return end
	
	-- Get friendData from our button if it exists, or use Blizzard's button properties
	local friendData = button.friendData
	local friendUID = nil
	
	if friendData then
		-- Our BetterFriendlist button
		if friendData.type == "bnet" and friendData.battleTag then
			friendUID = "bnet_" .. friendData.battleTag
		elseif friendData.type == "wow" and friendData.name then
			friendUID = "wow_" .. friendData.name
		end
	elseif button.buttonType then
		-- Blizzard's FriendsFrame button
		if button.buttonType == FRIENDS_BUTTON_TYPE_BNET then
			local accountInfo = C_BattleNet.GetFriendAccountInfo(button.id)
			if accountInfo and accountInfo.battleTag then
				friendUID = "bnet_" .. accountInfo.battleTag
			end
		elseif button.buttonType == FRIENDS_BUTTON_TYPE_WOW then
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
				local activityText = "|cff80c0ffLast contact:|r " .. SecondsToTime(timeSinceActivity) .. " ago"
				
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
					-- Position divider
					divider:ClearAllPoints()
					divider:SetPoint("TOPLEFT", anchorElement, "BOTTOMLEFT", 0, -6)
					divider:SetPoint("TOPRIGHT", anchorElement, "BOTTOMRIGHT", 0, -6)
					divider:Show()
					
					-- Position activity text below divider
					activityLine:ClearAllPoints()
					activityLine:SetPoint("TOPLEFT", divider, "BOTTOMLEFT", 0, -4)
					activityLine:SetPoint("TOPRIGHT", divider, "BOTTOMRIGHT", 0, -4)
					activityLine:SetText(activityText)
					activityLine:Show()
					
					-- Extend tooltip height
					local additionalHeight = 1 + 4 + activityLine:GetStringHeight() + 6
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

	local success, errorMsg = pcall(function()
		local friendData = self.friendData
		local tooltip = FriendsTooltip
		
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
			-- Battle.net friend - find the actual index for C_BattleNet API
			local numBNet = BNGetNumFriends()
			local actualBNetIndex = nil
			
			for i = 1, numBNet do
				local tempInfo = C_BattleNet.GetFriendAccountInfo(i)
				if tempInfo and tempInfo.bnetAccountID == friendData.bnetAccountID then
					actualBNetIndex = i
					break
				end
			end
			
			if actualBNetIndex then
				fakeButton.buttonType = FRIENDS_BUTTON_TYPE_BNET
				fakeButton.id = actualBNetIndex
			end
		else
			-- WoW friend
			if friendData.index and friendData.index > 0 then
				fakeButton.buttonType = FRIENDS_BUTTON_TYPE_WOW
				fakeButton.id = friendData.index
			end
		end
		
		if not fakeButton.buttonType or not fakeButton.id then
			return
		end
		
		-- Call Blizzard's tooltip population function via the mixin
		-- We simulate OnEnter by setting up tooltip.button and calling the display logic
		tooltip.button = fakeButton
		
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
			local accountInfo = C_BattleNet.GetFriendAccountInfo(fakeButton.id)
			if accountInfo then
				local noCharacterName = true
				local nameText, nameColor = FriendsFrame_GetBNetAccountNameAndStatus(accountInfo, noCharacterName)
				
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
						local characterName = FriendsFrame_GetFormattedCharacterName(
							accountInfo.gameAccountInfo.characterName, 
							accountInfo.battleTag, 
							accountInfo.gameAccountInfo.clientProgram,
							accountInfo.gameAccountInfo.timerunningSeasonID
						)
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
							anchor = FriendsFrameTooltip_SetLine(FriendsTooltipGameAccount1Info, nil, BNET_FRIEND_TOOLTIP_ZONE_AND_REALM:format(areaName, realmName), -4)
						else
							local regionNames = {
								[1] = NORTH_AMERICA,
								[2] = KOREA,
								[3] = EUROPE,
								[4] = TAIWAN,
								[5] = CHINA,
							}
							local regionNameString = regionNames[accountInfo.gameAccountInfo.regionID] or UNKNOWN
							anchor = FriendsFrameTooltip_SetLine(FriendsTooltipGameAccount1Info, nil, BNET_FRIEND_TOOLTIP_ZONE_AND_REGION:format(areaName, regionNameString), -4)
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
					text = FriendsFrame_GetLastOnlineText(accountInfo)
					anchor = FriendsFrameTooltip_SetLine(FriendsTooltipLastOnline, anchor, text, -4)
				end
			end
			
		elseif fakeButton.buttonType == FRIENDS_BUTTON_TYPE_WOW then
			local info = C_FriendList.GetFriendInfoByIndex(fakeButton.id)
			if info then
				anchor = FriendsFrameTooltip_SetLine(FriendsTooltipHeader, nil, info.name)
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
					
					if C_Texture.IsTitleIconTextureReady(gameAccountInfo.clientProgram, Enum.TitleIconVersion.Small) then
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
							characterName = FriendsFrame_GetFormattedCharacterName(gameAccountInfo.characterName, battleTag, gameAccountInfo.clientProgram, gameAccountInfo.timerunningSeasonID)
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
	end)
	
	if not success then
		FriendsTooltip:Hide()
		if errorMsg then
			-- Debug output enabled
			BFL:DebugPrint("|cffff0000BetterFriendlist Tooltip Error:|r " .. tostring(errorMsg))
		end
	end
end

-- Button OnLeave handler
function BetterFriendsList_Button_OnLeave(self)
	FriendsTooltip.button = nil
	FriendsTooltip:Hide()
	-- Hide our custom activity line
	if FriendsTooltip.BFLActivityText then
		FriendsTooltip.BFLActivityText:Hide()
	end
	if FriendsTooltip.BFLActivityDivider then
		FriendsTooltip.BFLActivityDivider:Hide()
	end
end
