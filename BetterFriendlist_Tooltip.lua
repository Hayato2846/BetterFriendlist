-- BetterFriendlist_Tooltip.lua
-- Friend list tooltip functionality (exact replication of Blizzard's FriendsFrame tooltips)

-- Constants - Using Blizzard's exact values (scale applied in XML instead)
local FRIENDS_TOOLTIP_MAX_WIDTH = 200
local FRIENDS_TOOLTIP_MARGIN_WIDTH = 12
local FRIENDS_TOOLTIP_MAX_GAME_ACCOUNTS = 5
local CANNOT_COOPERATE_LABEL = CANNOT_COOPERATE_LABEL or "|cffff0000*|r"
local SECONDS_PER_YEAR = 31536000

-- Region names lookup
local regionNames = {
	[1] = NORTH_AMERICA,
	[2] = KOREA,
	[3] = EUROPE,
	[4] = TAIWAN,
	[5] = CHINA,
}

-- Set a line in the tooltip (Blizzard's exact implementation)
function BetterFriendsTooltip_SetLine(line, anchor, text, yOffset)
	local tooltip = BetterFriendsTooltip
	local top = 0
	
	-- Set text first
	if text then
		line:SetText(text)
	else
		line:SetText("")
	end
	
	-- Calculate width before getting line width
	local lineWidth = line:GetWidth()
	local left = FRIENDS_TOOLTIP_MAX_WIDTH - FRIENDS_TOOLTIP_MARGIN_WIDTH - lineWidth
	
	-- Position the line
	if anchor then
		top = yOffset or 0
		line:SetPoint("TOP", anchor, "BOTTOM", 0, top)
	else
		local point, _, _, _, y = line:GetPoint(1)
		if point == "TOP" or point == "TOPLEFT" then
			top = y
		end
	end
	
	line:Show()
	
	-- Accumulate dimensions
	local lineHeight = line:GetHeight()
	tooltip.height = tooltip.height + lineHeight - top
	
	local stringWidth = line:GetStringWidth()
	tooltip.maxWidth = max(tooltip.maxWidth, stringWidth + left)
	
	return line
end

-- Helper function to format character name
local function BetterFriends_GetFormattedCharacterName(characterName, battleTag, client)
	characterName = BNet_GetValidatedCharacterName(characterName, battleTag, client)
	return characterName
end

-- Helper function to check if we can cooperate with a game account
local function BetterFriends_CanCooperateWithGameAccount(accountInfo)
	if not accountInfo then
		return false
	end
	return accountInfo.gameAccountInfo.realmID and 
	       accountInfo.gameAccountInfo.realmID > 0 and 
	       accountInfo.gameAccountInfo.factionName == UnitFactionGroup("player")
end

-- Helper function to determine if we should show rich presence only
local function BetterFriends_ShowRichPresenceOnly(client, wowProjectID, faction, realmID, areaName)
	local playerFactionGroup = UnitFactionGroup("player")
	local playerRealmID = GetRealmID()
	
	if (client ~= BNET_CLIENT_WOW) or (wowProjectID and WOW_PROJECT_ID and wowProjectID ~= WOW_PROJECT_ID) then
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

-- Helper function to get Battle.net account name and status
local function BetterFriends_GetBNetAccountNameAndStatus(accountInfo, noCharacterName)
	if not accountInfo then
		return
	end

	local nameText, nameColor, statusTexture

	nameText = BNet_GetBNetAccountName(accountInfo)

	if not noCharacterName and accountInfo.gameAccountInfo then
		local characterName = BetterFriends_GetFormattedCharacterName(
			accountInfo.gameAccountInfo.characterName, 
			nil, 
			accountInfo.gameAccountInfo.clientProgram
		)
		if characterName ~= "" then
			if accountInfo.gameAccountInfo.clientProgram == BNET_CLIENT_WOW and BetterFriends_CanCooperateWithGameAccount(accountInfo) then
				nameText = nameText.." "..FRIENDS_WOW_NAME_COLOR_CODE.."("..characterName..")"..FONT_COLOR_CODE_CLOSE
			else
				if GetCVarBool("colorblindMode") then
					characterName = accountInfo.gameAccountInfo.characterName..CANNOT_COOPERATE_LABEL
				end
				nameText = nameText.." "..FRIENDS_OTHER_NAME_COLOR_CODE.."("..characterName..")"..FONT_COLOR_CODE_CLOSE
			end
		end
	end

	if accountInfo.gameAccountInfo and accountInfo.gameAccountInfo.isOnline then
		if accountInfo.isAFK or accountInfo.gameAccountInfo.isGameAFK then
			statusTexture = FRIENDS_TEXTURE_AFK
		elseif accountInfo.isDND or accountInfo.gameAccountInfo.isGameBusy then
			statusTexture = FRIENDS_TEXTURE_DND
		else
			statusTexture = FRIENDS_TEXTURE_ONLINE
		end
		nameColor = FRIENDS_BNET_NAME_COLOR
	else
		statusTexture = FRIENDS_TEXTURE_OFFLINE
		nameColor = FRIENDS_GRAY_COLOR
	end

	return nameText, nameColor, statusTexture
end

-- Button OnEnter handler (Blizzard's exact implementation)
function BetterFriendsList_Button_OnEnter(self)
	if not self.friendIndex or not self.friendData then
		return
	end

	local anchor, text
	local numGameAccounts = 0
	local tooltip = BetterFriendsTooltip
	local battleTag = ""
	tooltip.height = 0
	tooltip.maxWidth = 0
	local friendData = self.friendData

	if friendData.type == "bnet" then
		-- Battle.net friend - need to find the actual index
		local numBNet = BNGetNumFriends()
		local actualBNetIndex = nil
		local accountInfo = nil
		
		for i = 1, numBNet do
			local tempInfo = C_BattleNet.GetFriendAccountInfo(i)
			if tempInfo and tempInfo.bnetAccountID == friendData.bnetAccountID then
				actualBNetIndex = i
				accountInfo = tempInfo
				break
			end
		end
		
		if accountInfo then
			local noCharacterName = true
			local nameText, nameColor = BetterFriends_GetBNetAccountNameAndStatus(accountInfo, noCharacterName)

			battleTag = accountInfo.battleTag

			anchor = BetterFriendsTooltip_SetLine(BetterFriendsTooltipHeader, nil, nameText)
			BetterFriendsTooltipHeader:SetTextColor(nameColor:GetRGB())

			if accountInfo.gameAccountInfo and accountInfo.gameAccountInfo.gameAccountID then
				if BetterFriends_ShowRichPresenceOnly(
					accountInfo.gameAccountInfo.clientProgram, 
					accountInfo.gameAccountInfo.wowProjectID, 
					accountInfo.gameAccountInfo.factionName, 
					accountInfo.gameAccountInfo.realmID, 
					accountInfo.gameAccountInfo.areaName
				) then
					local characterName = BetterFriends_GetFormattedCharacterName(
						accountInfo.gameAccountInfo.characterName, 
						accountInfo.battleTag, 
						accountInfo.gameAccountInfo.clientProgram
					)
					anchor = BetterFriendsTooltip_SetLine(BetterFriendsTooltipGameAccount1Name, anchor, characterName, -4)
					anchor = BetterFriendsTooltip_SetLine(BetterFriendsTooltipGameAccount1Info, anchor, accountInfo.gameAccountInfo.richPresence, -4)
				else
					local raceName = accountInfo.gameAccountInfo.raceName or UNKNOWN
					local className = accountInfo.gameAccountInfo.className or UNKNOWN
					if BetterFriends_CanCooperateWithGameAccount(accountInfo) then
						text = string.format(FRIENDS_TOOLTIP_WOW_TOON_TEMPLATE, accountInfo.gameAccountInfo.characterName, accountInfo.gameAccountInfo.characterLevel, raceName, className)
					else
						text = string.format(FRIENDS_TOOLTIP_WOW_TOON_TEMPLATE, accountInfo.gameAccountInfo.characterName..CANNOT_COOPERATE_LABEL, accountInfo.gameAccountInfo.characterLevel, raceName, className)
					end
					anchor = BetterFriendsTooltip_SetLine(BetterFriendsTooltipGameAccount1Name, anchor, text, -4)
					local areaName = accountInfo.gameAccountInfo.areaName or UNKNOWN
					if accountInfo.gameAccountInfo.isInCurrentRegion then
						local realmName = accountInfo.gameAccountInfo.realmDisplayName or UNKNOWN
						anchor = BetterFriendsTooltip_SetLine(BetterFriendsTooltipGameAccount1Info, anchor, BNET_FRIEND_TOOLTIP_ZONE_AND_REALM:format(areaName, realmName), -4)
					else
						local regionNameString = regionNames[accountInfo.gameAccountInfo.regionID] or UNKNOWN
						anchor = BetterFriendsTooltip_SetLine(BetterFriendsTooltipGameAccount1Info, anchor, BNET_FRIEND_TOOLTIP_ZONE_AND_REGION:format(areaName, regionNameString), -4)
					end
				end
			else
				BetterFriendsTooltipGameAccount1Info:Hide()
				BetterFriendsTooltipGameAccount1Name:Hide()
			end

			-- Note
			if accountInfo.note and accountInfo.note ~= "" then
				BetterFriendsTooltipNoteIcon:Show()
				anchor = BetterFriendsTooltip_SetLine(BetterFriendsTooltipNoteText, anchor, accountInfo.note, -8)
			else
				BetterFriendsTooltipNoteIcon:Hide()
				BetterFriendsTooltipNoteText:Hide()
			end
			
			-- Broadcast
			if accountInfo.customMessage and accountInfo.customMessage ~= "" then
				BetterFriendsTooltipBroadcastIcon:Show()
				local customMessage = accountInfo.customMessage
				if accountInfo.customMessageTime and not HasTimePassed(accountInfo.customMessageTime, SECONDS_PER_YEAR) then
					customMessage = customMessage.."|n"..FRIENDS_BROADCAST_TIME_COLOR_CODE..string.format(BNET_BROADCAST_SENT_TIME, FriendsFrame_GetLastOnline(accountInfo.customMessageTime)..FONT_COLOR_CODE_CLOSE)
				end
				anchor = BetterFriendsTooltip_SetLine(BetterFriendsTooltipBroadcastText, anchor, customMessage, -8)
				tooltip.hasBroadcast = true
			else
				BetterFriendsTooltipBroadcastIcon:Hide()
				BetterFriendsTooltipBroadcastText:Hide()
				tooltip.hasBroadcast = nil
			end

			if accountInfo.gameAccountInfo and accountInfo.gameAccountInfo.isOnline then
				BetterFriendsTooltipLastOnline:Hide()
				
				-- Count game accounts for the "other accounts" section
				if actualBNetIndex then
					numGameAccounts = C_BattleNet.GetFriendNumGameAccounts(actualBNetIndex)
				end
			else
				text = FriendsFrame_GetLastOnlineText(accountInfo)
				anchor = BetterFriendsTooltip_SetLine(BetterFriendsTooltipLastOnline, anchor, text, -4)
			end
		end
	else
		-- WoW friend
		if not friendData.index or friendData.index <= 0 then
			BetterFriendsTooltip:Hide()
			return
		end
		
		local info = C_FriendList.GetFriendInfoByIndex(friendData.index)
		if info then
			anchor = BetterFriendsTooltip_SetLine(BetterFriendsTooltipHeader, nil, info.name)
			if info.connected then
				BetterFriendsTooltipHeader:SetTextColor(FRIENDS_WOW_NAME_COLOR.r, FRIENDS_WOW_NAME_COLOR.g, FRIENDS_WOW_NAME_COLOR.b)
				anchor = BetterFriendsTooltip_SetLine(BetterFriendsTooltipGameAccount1Name, anchor, string.format(FRIENDS_LEVEL_TEMPLATE, info.level, info.className), -4)
				anchor = BetterFriendsTooltip_SetLine(BetterFriendsTooltipGameAccount1Info, anchor, info.area, -4)
			else
				BetterFriendsTooltipHeader:SetTextColor(FRIENDS_GRAY_COLOR.r, FRIENDS_GRAY_COLOR.g, FRIENDS_GRAY_COLOR.b)
				BetterFriendsTooltipGameAccount1Name:Hide()
				BetterFriendsTooltipGameAccount1Info:Hide()
			end
			if info.notes and info.notes ~= "" then
				BetterFriendsTooltipNoteIcon:Show()
				anchor = BetterFriendsTooltip_SetLine(BetterFriendsTooltipNoteText, anchor, info.notes, -8)
			else
				BetterFriendsTooltipNoteIcon:Hide()
				BetterFriendsTooltipNoteText:Hide()
			end
			BetterFriendsTooltipBroadcastIcon:Hide()
			BetterFriendsTooltipBroadcastText:Hide()
			BetterFriendsTooltipLastOnline:Hide()
		end
	end

	-- Other game accounts (for Battle.net friends with multiple accounts)
	local gameAccountIndex = 1
	local characterNameString
	local gameAccountInfoString
	local playerRealmName = GetRealmName()
	local playerFactionGroup = UnitFactionGroup("player")
	
	if numGameAccounts > 1 and friendData.type == "bnet" and actualBNetIndex then
		local headerSet = false
		
		for i = 1, numGameAccounts do
			local gameAccountInfo = C_BattleNet.GetFriendGameAccountInfo(actualBNetIndex, i)

			-- The focused game account is already at the top of the tooltip
			if gameAccountInfo and not gameAccountInfo.hasFocus and 
			   (gameAccountInfo.clientProgram ~= BNET_CLIENT_APP) and (gameAccountInfo.clientProgram ~= BNET_CLIENT_CLNT) then
				local areaName = gameAccountInfo.areaName or UNKNOWN
				local raceName = gameAccountInfo.raceName or UNKNOWN
				local className = gameAccountInfo.className or UNKNOWN
				local gameText = gameAccountInfo.richPresence or ""

				if not headerSet then
					BetterFriendsTooltip_SetLine(BetterFriendsTooltipOtherGameAccounts, anchor, nil, -8)
					headerSet = true
				end
				
				gameAccountIndex = gameAccountIndex + 1
				if gameAccountIndex > FRIENDS_TOOLTIP_MAX_GAME_ACCOUNTS then
					break
				end
				
				characterNameString = _G["BetterFriendsTooltipGameAccount"..gameAccountIndex.."Name"]
				gameAccountInfoString = _G["BetterFriendsTooltipGameAccount"..gameAccountIndex.."Info"]
				text = ""
				
				-- Add game icon if available
				if C_Texture.IsTitleIconTextureReady(gameAccountInfo.clientProgram, Enum.TitleIconVersion.Small) then
					C_Texture.GetTitleIconTexture(gameAccountInfo.clientProgram, Enum.TitleIconVersion.Small, function(success, texture)
						if success then
							text = BNet_GetClientEmbeddedTexture(texture, 32, 32, 0).." "
						end
					end)
				end
				
				if (gameAccountInfo.clientProgram == BNET_CLIENT_WOW) and 
				   (gameAccountInfo.wowProjectID and WOW_PROJECT_ID and gameAccountInfo.wowProjectID == WOW_PROJECT_ID) then
					if (gameAccountInfo.realmName == playerRealmName) and (gameAccountInfo.factionName == playerFactionGroup) then
						text = text..string.format(FRIENDS_TOOLTIP_WOW_TOON_TEMPLATE, gameAccountInfo.characterName, gameAccountInfo.characterLevel, raceName, className)
					else
						text = text..string.format(FRIENDS_TOOLTIP_WOW_TOON_TEMPLATE, gameAccountInfo.characterName..CANNOT_COOPERATE_LABEL, gameAccountInfo.characterLevel, raceName, className)
					end
					gameText = areaName
				else
					local characterName = ""
					if gameAccountInfo.isOnline then
						characterName = BetterFriends_GetFormattedCharacterName(gameAccountInfo.characterName, battleTag, gameAccountInfo.clientProgram)
					end
					text = text..characterName
				end
				
				anchor = BetterFriendsTooltip_SetLine(characterNameString, anchor, text, -4)
				anchor = BetterFriendsTooltip_SetLine(gameAccountInfoString, anchor, gameText, -1)
			end
		end
		
		if not headerSet then
			BetterFriendsTooltipOtherGameAccounts:Hide()
		end
	else
		BetterFriendsTooltipOtherGameAccounts:Hide()
	end
	
	-- Hide unused game account slots
	for i = gameAccountIndex + 1, FRIENDS_TOOLTIP_MAX_GAME_ACCOUNTS do
		characterNameString = _G["BetterFriendsTooltipGameAccount"..i.."Name"]
		gameAccountInfoString = _G["BetterFriendsTooltipGameAccount"..i.."Info"]
		characterNameString:Hide()
		gameAccountInfoString:Hide()
	end
	
	-- Show message if there are too many game accounts
	if numGameAccounts > FRIENDS_TOOLTIP_MAX_GAME_ACCOUNTS then
		BetterFriendsTooltip_SetLine(BetterFriendsTooltipGameAccountMany, nil, string.format(FRIENDS_TOOLTIP_TOO_MANY_CHARACTERS, numGameAccounts - FRIENDS_TOOLTIP_MAX_GAME_ACCOUNTS), 0)
	else
		BetterFriendsTooltipGameAccountMany:Hide()
	end

	tooltip.button = self
	tooltip:SetPoint("TOPLEFT", self, "TOPRIGHT", 36, 0)
	
	-- Calculate and set final dimensions
	local finalHeight = tooltip.height + FRIENDS_TOOLTIP_MARGIN_WIDTH
	local finalWidth = min(FRIENDS_TOOLTIP_MAX_WIDTH, tooltip.maxWidth + FRIENDS_TOOLTIP_MARGIN_WIDTH)
	
	tooltip:SetHeight(finalHeight)
	tooltip:SetWidth(finalWidth)
	tooltip:Show()
end

-- Button OnLeave handler
function BetterFriendsList_Button_OnLeave(self)
	BetterFriendsTooltip.button = nil
	BetterFriendsTooltip:Hide()
end
