-- BetterFriendlist_Tooltip.lua
-- Friend list tooltip: uses Blizzard's native FriendsTooltip (Retail) / FriendsFrameTooltip_Show (Classic)
-- Ensures compatibility with RaiderIO and other addons that hook into FriendsTooltip

local _, BFL = ...

local ShowSafeRetailBNetTooltip

-- Proxy button for Retail: a real Frame object avoids taint on FriendsTooltip.button
-- Blizzard's FriendsTooltip OnUpdate calls: if self.hasBroadcast then self.button:OnEnter() end
-- so the proxy needs a real :OnEnter() method that re-triggers tooltip population
local proxyButton
if not BFL.IsClassic then
	proxyButton = CreateFrame("Button", nil, UIParent)
	proxyButton:Hide()
	proxyButton:EnableMouse(false)

	proxyButton.OnEnter = function(self)
		if FriendsListButtonMixin and FriendsListButtonMixin.OnEnter then
			if BFL.HasSecretValues and self.friendData and self.friendData.type == "bnet" and ShowSafeRetailBNetTooltip then
				ShowSafeRetailBNetTooltip(self, self.anchorButton, self.friendData)
				return
			end

			FriendsListButtonMixin.OnEnter(self)

			-- Re-anchor tooltip to the actual visible button (Blizzard anchored to proxyButton)
			if self.anchorButton then
				FriendsTooltip:ClearAllPoints()
				FriendsTooltip:SetPoint("TOPLEFT", self.anchorButton, "TOPRIGHT", 36, 0)
			end

			-- [STREAMER MODE] Override Real ID in header after Blizzard re-populates
			if BFL.StreamerMode and BFL.StreamerMode:IsActive() and self.friendData then
				local FriendsList = BFL:GetModule("FriendsList")
				if FriendsList and FriendsTooltipHeader then
					local safeName = FriendsList:GetDisplayName(self.friendData)
					if safeName then
						FriendsTooltipHeader:SetText(safeName)
					end
				end
			end
		end
	end

	proxyButton.OnLeave = function()
		-- No-op; leave is handled by BetterFriendsList_Button_OnLeave
	end
end

local function IsSecret(value)
	return BFL and BFL.IsSecret and BFL:IsSecret(value)
end

local function SafeString(value, fallback)
	if IsSecret(value) then
		return fallback
	end
	if value and value ~= "" then
		return value
	end
	return fallback
end

local function SafeBool(value, fallback)
	if IsSecret(value) then
		return fallback or false
	end
	return not not value
end

local function SafeNumber(value, fallback)
	if IsSecret(value) then
		return fallback
	end
	if value ~= nil then
		return value
	end
	return fallback
end

local function SetFontStringColor(fontString, color)
	if not fontString or not color then
		return
	end
	if color.GetRGB then
		fontString:SetTextColor(color:GetRGB())
	else
		fontString:SetTextColor(color.r or 1, color.g or 1, color.b or 1)
	end
end

local function SetTooltipLine(line, anchor, text, yOffset)
	if not line then
		return anchor
	end
	if FriendsFrameTooltip_SetLine then
		return FriendsFrameTooltip_SetLine(line, anchor, text, yOffset)
	end

	line:SetText(text or "")
	if anchor then
		line:SetPoint("TOP", anchor, "BOTTOM", 0, yOffset or 0)
	end
	line:Show()
	return line
end

local function HideTooltipLine(line)
	if line then
		line:SetText("")
		line:Hide()
	end
end

local function GetSafeLastOnlineText(lastOnlineTime)
	lastOnlineTime = SafeNumber(lastOnlineTime, 0) or 0
	if lastOnlineTime == 0 or (HasTimePassed and HasTimePassed(lastOnlineTime, SECONDS_PER_YEAR)) then
		return FRIENDS_LIST_OFFLINE or ""
	end
	if FriendsFrame_GetLastOnline and BNET_LAST_ONLINE_TIME then
		return string.format(BNET_LAST_ONLINE_TIME, FriendsFrame_GetLastOnline(lastOnlineTime))
	end
	return FRIENDS_LIST_OFFLINE or ""
end

local regionNames = {
	[1] = NORTH_AMERICA,
	[2] = KOREA,
	[3] = EUROPE,
	[4] = TAIWAN,
	[5] = CHINA,
}

local function GetGameAccountField(gameAccountInfo, field, fallback)
	if not gameAccountInfo then
		return fallback
	end
	local value = gameAccountInfo[field]
	if IsSecret(value) then
		return fallback
	end
	if value == nil then
		return fallback
	end
	return value
end

local function GetPrimaryGameAccount(friendData)
	return friendData and friendData.gameAccountInfo
end

local function GetSafeDisplayName(friendData)
	if BFL and BFL.GetSafeAccountName then
		return BFL:GetSafeAccountName(SafeString(friendData.accountName, nil), SafeString(friendData.battleTag, nil))
	end

	return SafeString(friendData.accountName, nil) or SafeString(friendData.battleTag, nil) or UNKNOWN or "Unknown"
end

local function GetSafeFormattedCharacterName(characterName, battleTag, clientProgram, timerunningSeasonID)
	characterName = SafeString(characterName, "")
	battleTag = SafeString(battleTag, nil)
	clientProgram = SafeString(clientProgram, nil)
	timerunningSeasonID = SafeNumber(timerunningSeasonID, nil)
	if FriendsFrame_GetFormattedCharacterName then
		local ok, result = pcall(FriendsFrame_GetFormattedCharacterName, characterName, battleTag, clientProgram, timerunningSeasonID)
		if ok and result then
			return result
		end
	end
	return characterName
end

local function ShouldUseClassColorNames()
	if BetterFriendlistDB and BetterFriendlistDB.colorClassNames ~= nil then
		return BetterFriendlistDB.colorClassNames and true or false
	end
	return true
end

local function GetClassColorForGameAccount(gameAccountInfo)
	if not ShouldUseClassColorNames() or not RAID_CLASS_COLORS then
		return nil
	end

	local classID = SafeNumber(GetGameAccountField(gameAccountInfo, "classID", nil), nil)
	if classID and classID > 0 then
		local classFile
		if C_CreatureInfo and C_CreatureInfo.GetClassInfo then
			local classInfo = C_CreatureInfo.GetClassInfo(classID)
			classFile = classInfo and classInfo.classFile
		end
		if not classFile and GetClassInfo then
			local _
			_, classFile = GetClassInfo(classID)
		end
		if classFile and RAID_CLASS_COLORS[classFile] then
			return RAID_CLASS_COLORS[classFile]
		end
	end

	local className = SafeString(GetGameAccountField(gameAccountInfo, "className", nil), nil)
	if className and BFL.ClassUtils and BFL.ClassUtils.GetClassFileFromClassName then
		local classFile = BFL.ClassUtils:GetClassFileFromClassName(className)
		if classFile and RAID_CLASS_COLORS[classFile] then
			return RAID_CLASS_COLORS[classFile]
		end
	end

	return nil
end

local function ClassColorTextForGameAccount(gameAccountInfo, text)
	text = SafeString(text, "")
	if text == "" then
		return text
	end

	local classColor = GetClassColorForGameAccount(gameAccountInfo)
	if classColor then
		if classColor.WrapTextInColorCode then
			return classColor:WrapTextInColorCode(text)
		end
		if classColor.colorStr then
			return "|c" .. classColor.colorStr .. text .. "|r"
		end
	end

	return text
end

local function CanSafelyCooperateWithGameAccount(gameAccountInfo)
	local realmID = SafeNumber(GetGameAccountField(gameAccountInfo, "realmID", nil), nil)
	local factionName = SafeString(GetGameAccountField(gameAccountInfo, "factionName", nil), nil)
	return realmID and realmID > 0 and factionName == playerFactionGroup
end

local function ShouldSafeGameAccountShowRichPresence(gameAccountInfo)
	local clientProgram = SafeString(GetGameAccountField(gameAccountInfo, "clientProgram", nil), nil)
	local wowProjectID = SafeNumber(GetGameAccountField(gameAccountInfo, "wowProjectID", nil), nil)
	local factionName = SafeString(GetGameAccountField(gameAccountInfo, "factionName", nil), nil)
	local realmID = SafeNumber(GetGameAccountField(gameAccountInfo, "realmID", nil), nil)
	local areaName = SafeString(GetGameAccountField(gameAccountInfo, "areaName", nil), nil)
	if clientProgram ~= BNET_CLIENT_WOW or wowProjectID ~= WOW_PROJECT_ID then
		return true
	end
	if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC and (factionName ~= playerFactionGroup or realmID ~= playerRealmID) then
		return true
	end
	return not areaName
end

local function GetSafeGameAccountCharacterLine(gameAccountInfo, battleTag)
	local characterName = SafeString(GetGameAccountField(gameAccountInfo, "characterName", nil), UNKNOWN or "")
	local characterLevel = SafeNumber(GetGameAccountField(gameAccountInfo, "characterLevel", nil), 0)
	local raceName = SafeString(GetGameAccountField(gameAccountInfo, "raceName", nil), UNKNOWN or "")
	local className = SafeString(GetGameAccountField(gameAccountInfo, "className", nil), UNKNOWN or "")
	local coloredCharacterName = ClassColorTextForGameAccount(gameAccountInfo, characterName)
	local text
	if CanSafelyCooperateWithGameAccount(gameAccountInfo) then
		text = string.format(FRIENDS_TOOLTIP_WOW_TOON_TEMPLATE, coloredCharacterName, characterLevel, raceName, className)
	else
		text = string.format(
			FRIENDS_TOOLTIP_WOW_TOON_TEMPLATE,
			coloredCharacterName .. (CANNOT_COOPERATE_LABEL or ""),
			characterLevel,
			raceName,
			className
		)
	end
	if SafeNumber(GetGameAccountField(gameAccountInfo, "timerunningSeasonID", nil), nil) and TimerunningUtil and TimerunningUtil.AddSmallIcon then
		text = TimerunningUtil.AddSmallIcon(text)
	end
	return text
end

local function BuildGameAccountIconPrefix(clientProgram)
	clientProgram = SafeString(clientProgram, nil)
	if
		clientProgram
		and C_Texture
		and C_Texture.IsTitleIconTextureReady
		and C_Texture.GetTitleIconTexture
		and Enum
		and Enum.TitleIconVersion
		and BNet_GetClientEmbeddedTexture
		and C_Texture.IsTitleIconTextureReady(clientProgram, Enum.TitleIconVersion.Small)
	then
		local text = ""
		C_Texture.GetTitleIconTexture(clientProgram, Enum.TitleIconVersion.Small, function(success, texture)
			if success then
				text = BNet_GetClientEmbeddedTexture(texture, 32, 32, 0) .. " "
			end
		end)
		return text
	end
	return ""
end

ShowSafeRetailBNetTooltip = function(button, anchorButton, friendData)
	local tooltip = FriendsTooltip
	if not tooltip or not friendData then
		return
	end

	tooltip:SetParent(UIParent)
	tooltip.height = 0
	tooltip.maxWidth = 0
	tooltip.hasBroadcast = nil

	local text
	local numGameAccounts = 0
	local battleTag = SafeString(friendData.battleTag, nil)
	local gameAccountInfo = GetPrimaryGameAccount(friendData)

	local anchor = SetTooltipLine(FriendsTooltipHeader, nil, GetSafeDisplayName(friendData))
	SetFontStringColor(FriendsTooltipHeader, SafeBool(friendData.connected, false) and FRIENDS_BNET_NAME_COLOR or FRIENDS_GRAY_COLOR)

	if gameAccountInfo and GetGameAccountField(gameAccountInfo, "gameAccountID", nil) then
		if ShouldSafeGameAccountShowRichPresence(gameAccountInfo) then
			local characterName = GetSafeFormattedCharacterName(
				GetGameAccountField(gameAccountInfo, "characterName", nil),
				battleTag,
				GetGameAccountField(gameAccountInfo, "clientProgram", nil),
				GetGameAccountField(gameAccountInfo, "timerunningSeasonID", nil)
			)
			characterName = ClassColorTextForGameAccount(gameAccountInfo, characterName)
			SetTooltipLine(FriendsTooltipGameAccount1Name, nil, characterName)
			anchor = SetTooltipLine(
				FriendsTooltipGameAccount1Info,
				nil,
				SafeString(GetGameAccountField(gameAccountInfo, "richPresence", nil), ""),
				-4
			)
		else
			SetTooltipLine(FriendsTooltipGameAccount1Name, nil, GetSafeGameAccountCharacterLine(gameAccountInfo, battleTag))
			local areaName = SafeString(GetGameAccountField(gameAccountInfo, "areaName", nil), UNKNOWN or "")
			if SafeBool(GetGameAccountField(gameAccountInfo, "isInCurrentRegion", nil), false) then
				local realmName = SafeString(
					GetGameAccountField(gameAccountInfo, "realmDisplayName", nil),
					SafeString(GetGameAccountField(gameAccountInfo, "realmName", nil), UNKNOWN or "")
				)
				anchor = SetTooltipLine(FriendsTooltipGameAccount1Info, nil, BNET_FRIEND_TOOLTIP_ZONE_AND_REALM:format(areaName, realmName), -4)
			else
				local regionID = SafeNumber(GetGameAccountField(gameAccountInfo, "regionID", nil), nil)
				local regionNameString = regionNames[regionID] or UNKNOWN or ""
				anchor = SetTooltipLine(FriendsTooltipGameAccount1Info, nil, BNET_FRIEND_TOOLTIP_ZONE_AND_REGION:format(areaName, regionNameString), -4)
			end
		end
	else
		HideTooltipLine(FriendsTooltipGameAccount1Name)
		HideTooltipLine(FriendsTooltipGameAccount1Info)
	end

	local note = SafeString(friendData.note or friendData.notes, "")
	if note ~= "" then
		FriendsTooltipNoteIcon:Show()
		anchor = SetTooltipLine(FriendsTooltipNoteText, anchor, note, -8)
	else
		FriendsTooltipNoteIcon:Hide()
		HideTooltipLine(FriendsTooltipNoteText)
	end

	local customMessage = SafeString(friendData.customMessage, "")
	if customMessage ~= "" then
		FriendsTooltipBroadcastIcon:Show()
		local customMessageTime = SafeNumber(friendData.customMessageTime, 0) or 0
		if customMessageTime ~= 0 and (not HasTimePassed or not HasTimePassed(customMessageTime, SECONDS_PER_YEAR)) then
			local lastOnlineText = FriendsFrame_GetLastOnline and FriendsFrame_GetLastOnline(customMessageTime) or ""
			customMessage = customMessage
				.. "|n"
				.. (FRIENDS_BROADCAST_TIME_COLOR_CODE or "")
				.. string.format(BNET_BROADCAST_SENT_TIME, lastOnlineText .. (FONT_COLOR_CODE_CLOSE or ""))
		end
		anchor = SetTooltipLine(FriendsTooltipBroadcastText, anchor, customMessage, -8)
		FriendsTooltip.hasBroadcast = true
	else
		FriendsTooltipBroadcastIcon:Hide()
		HideTooltipLine(FriendsTooltipBroadcastText)
		FriendsTooltip.hasBroadcast = nil
	end

	if SafeBool(GetGameAccountField(gameAccountInfo, "isOnline", nil), SafeBool(friendData.connected, false)) then
		HideTooltipLine(FriendsTooltipLastOnline)
		numGameAccounts = SafeNumber(friendData.totalGameAccounts, SafeNumber(friendData.numGameAccounts, 0)) or 0
	else
		text = GetSafeLastOnlineText(friendData.lastOnlineTime)
		anchor = SetTooltipLine(FriendsTooltipLastOnline, anchor, text, -4)
	end

	local gameAccountIndex = 1
	local gameAccounts = friendData.gameAccounts
	if type(gameAccounts) == "table" and numGameAccounts > 1 then
		local headerSet = false
		for _, otherGameAccountInfo in ipairs(gameAccounts) do
			local hasFocus = SafeBool(GetGameAccountField(otherGameAccountInfo, "hasFocus", nil), false)
			local clientProgram = SafeString(GetGameAccountField(otherGameAccountInfo, "clientProgram", nil), nil)
			if otherGameAccountInfo ~= gameAccountInfo and not hasFocus and clientProgram ~= BNET_CLIENT_APP and clientProgram ~= BNET_CLIENT_CLNT then
				local areaName = SafeString(GetGameAccountField(otherGameAccountInfo, "areaName", nil), UNKNOWN or "")
				local gameText = SafeString(GetGameAccountField(otherGameAccountInfo, "richPresence", nil), "")

				if not headerSet then
					SetTooltipLine(FriendsTooltipOtherGameAccounts, anchor, nil, -8)
					headerSet = true
				end
				gameAccountIndex = gameAccountIndex + 1
				if gameAccountIndex > (FRIENDS_TOOLTIP_MAX_GAME_ACCOUNTS or 4) then
					break
				end

				local characterNameString = _G["FriendsTooltipGameAccount" .. gameAccountIndex .. "Name"]
				local gameAccountInfoString = _G["FriendsTooltipGameAccount" .. gameAccountIndex .. "Info"]
				text = BuildGameAccountIconPrefix(clientProgram)
				if clientProgram == BNET_CLIENT_WOW and SafeNumber(GetGameAccountField(otherGameAccountInfo, "wowProjectID", nil), nil) == WOW_PROJECT_ID then
					local characterName = SafeString(GetGameAccountField(otherGameAccountInfo, "characterName", nil), UNKNOWN or "")
					local characterLevel = SafeNumber(GetGameAccountField(otherGameAccountInfo, "characterLevel", nil), 0)
					local raceName = SafeString(GetGameAccountField(otherGameAccountInfo, "raceName", nil), UNKNOWN or "")
					local className = SafeString(GetGameAccountField(otherGameAccountInfo, "className", nil), UNKNOWN or "")
					local realmName = SafeString(GetGameAccountField(otherGameAccountInfo, "realmName", nil), nil)
					local factionName = SafeString(GetGameAccountField(otherGameAccountInfo, "factionName", nil), nil)
					local coloredCharacterName = ClassColorTextForGameAccount(otherGameAccountInfo, characterName)
					if realmName == playerRealmName and factionName == playerFactionGroup then
						text = text .. string.format(FRIENDS_TOOLTIP_WOW_TOON_TEMPLATE, coloredCharacterName, characterLevel, raceName, className)
					else
						text = text .. string.format(
							FRIENDS_TOOLTIP_WOW_TOON_TEMPLATE,
							coloredCharacterName .. (CANNOT_COOPERATE_LABEL or ""),
							characterLevel,
							raceName,
							className
						)
					end
					gameText = areaName
				else
					local characterName = ""
					if SafeBool(GetGameAccountField(otherGameAccountInfo, "isOnline", nil), false) then
						characterName = GetSafeFormattedCharacterName(
							GetGameAccountField(otherGameAccountInfo, "characterName", nil),
							battleTag,
							clientProgram,
							GetGameAccountField(otherGameAccountInfo, "timerunningSeasonID", nil)
						)
						characterName = ClassColorTextForGameAccount(otherGameAccountInfo, characterName)
					end
					text = text .. characterName
				end
				SetTooltipLine(characterNameString, nil, text)
				SetTooltipLine(gameAccountInfoString, nil, gameText)
			end
		end
		if not headerSet then
			HideTooltipLine(FriendsTooltipOtherGameAccounts)
		end
	else
		HideTooltipLine(FriendsTooltipOtherGameAccounts)
	end

	for i = gameAccountIndex + 1, FRIENDS_TOOLTIP_MAX_GAME_ACCOUNTS or 4 do
		HideTooltipLine(_G["FriendsTooltipGameAccount" .. i .. "Name"])
		HideTooltipLine(_G["FriendsTooltipGameAccount" .. i .. "Info"])
	end
	if numGameAccounts > (FRIENDS_TOOLTIP_MAX_GAME_ACCOUNTS or 4) then
		SetTooltipLine(
			FriendsTooltipGameAccountMany,
			nil,
			string.format(FRIENDS_TOOLTIP_TOO_MANY_CHARACTERS, numGameAccounts - (FRIENDS_TOOLTIP_MAX_GAME_ACCOUNTS or 4)),
			0
		)
	else
		HideTooltipLine(FriendsTooltipGameAccountMany)
	end

	tooltip.button = button
	tooltip:ClearAllPoints()
	tooltip:SetPoint("TOPLEFT", anchorButton or button, "TOPRIGHT", 36, 0)
	tooltip:SetHeight((tooltip.height or 0) + (FRIENDS_TOOLTIP_MARGIN_WIDTH or 16))
	tooltip:SetWidth(math.min(FRIENDS_TOOLTIP_MAX_WIDTH or 320, (tooltip.maxWidth or 0) + (FRIENDS_TOOLTIP_MARGIN_WIDTH or 16)))
	tooltip:Show()
end

-- Helper: Apply StreamerMode header override
local function ApplyStreamerModeOverride(friendData)
	if BFL.StreamerMode and BFL.StreamerMode:IsActive() and friendData then
		local FriendsList = BFL:GetModule("FriendsList")
		if FriendsList and FriendsTooltipHeader then
			local safeName = FriendsList:GetDisplayName(friendData)
			if safeName then
				FriendsTooltipHeader:SetText(safeName)
			end
		end
	end
end

-- Button OnEnter handler
function BetterFriendsList_Button_OnEnter(self)
	if not self.friendIndex or not self.friendData then
		return
	end

	local friendData = self.friendData
	local tooltip = FriendsTooltip
	local FriendsList = BFL and BFL:GetModule("FriendsList")

	-- Determine buttonType and resolve current index
	local buttonType, resolvedIndex

	if friendData.type == "bnet" then
		buttonType = FRIENDS_BUTTON_TYPE_BNET
		if friendData._isMock then
			resolvedIndex = friendData.index
		else
			resolvedIndex = FriendsList
					and FriendsList.ResolveBNetFriendIndex
					and FriendsList:ResolveBNetFriendIndex(friendData.bnetAccountID, friendData.battleTag)
				or friendData.index
		end
	else
		buttonType = FRIENDS_BUTTON_TYPE_WOW
		if friendData._isMock then
			resolvedIndex = friendData.index
		else
			resolvedIndex = FriendsList
					and FriendsList.ResolveWoWFriendIndex
					and FriendsList:ResolveWoWFriendIndex(friendData.name)
				or friendData.index
		end
	end

	if not buttonType or not resolvedIndex or resolvedIndex <= 0 then
		return
	end

	-- Mock/Preview mode: simple GameTooltip (Blizzard's API can't resolve mock indices)
	-- NOTE: Preview Mode is internal-only (developer screenshots/testing), NOT user-facing.
	-- Do not document Preview Mode features in CHANGELOG.md.
	if friendData._isMock then
		BFL_Tooltip:SetOwner(self, "ANCHOR_RIGHT")
		local displayName
		if FriendsList then
			displayName = FriendsList:GetDisplayName(friendData)
		end
		displayName = displayName or friendData.name or friendData.characterName or "Unknown"
		BFL_Tooltip:SetText(displayName, 1, 1, 1)
		if friendData.characterName and friendData.level and friendData.className then
			BFL_Tooltip:AddLine(
				string.format(FRIENDS_LEVEL_TEMPLATE or "Level %d %s", friendData.level, friendData.className),
				HIGHLIGHT_FONT_COLOR.r,
				HIGHLIGHT_FONT_COLOR.g,
				HIGHLIGHT_FONT_COLOR.b
			)
		end
		if friendData.area or friendData.areaName then
			BFL_Tooltip:AddLine(
				friendData.area or friendData.areaName,
				HIGHLIGHT_FONT_COLOR.r,
				HIGHLIGHT_FONT_COLOR.g,
				HIGHLIGHT_FONT_COLOR.b
			)
		end
		if friendData.note and friendData.note ~= "" then
			BFL_Tooltip:AddLine(" ")
			BFL_Tooltip:AddLine(friendData.note, 1, 0.82, 0, true)
		end

		-- RaiderIO integration: query public API for M+ score in Preview Mode
		if _G.RaiderIO and _G.RaiderIO.GetProfile and friendData.characterName then
			local realm = friendData.realmName
			if (not realm or realm == "") and GetNormalizedRealmName then
				realm = GetNormalizedRealmName()
			end
			if realm and realm ~= "" then
				local profile = _G.RaiderIO.GetProfile(friendData.characterName, realm)
				if profile and profile.mythicKeystoneProfile and profile.mythicKeystoneProfile.currentScore then
					local score = profile.mythicKeystoneProfile.currentScore
					if score > 0 then
						local r, g, b = 1, 1, 1
						if _G.RaiderIO.GetScoreColor then
							r, g, b = _G.RaiderIO.GetScoreColor(score)
						end
						BFL_Tooltip:AddLine(" ")
						BFL_Tooltip:AddDoubleLine("Raider.IO M+ Score", tostring(score), 0.8, 0.8, 0.8, r, g, b)
					end
				end
			end
		end

		BFL_Tooltip:Show()
		return
	end

	-- Classic path: use FriendsFrameTooltip_Show (exists only in Classic)
	if BFL.IsClassic then
		self.buttonType = buttonType
		self.id = resolvedIndex

		tooltip.button = self
		tooltip:SetParent(UIParent)

		if FriendsFrameTooltip_Show then
			FriendsFrameTooltip_Show(self)
		end

		ApplyStreamerModeOverride(friendData)

		tooltip:Show()
		return
	end

	-- Retail path: delegate to Blizzard's FriendsListButtonMixin.OnEnter()
	if FriendsListButtonMixin and FriendsListButtonMixin.OnEnter then
		proxyButton.buttonType = buttonType
		proxyButton.id = resolvedIndex
		proxyButton.friendData = friendData
		proxyButton.anchorButton = self

		-- Reparent FriendsTooltip to UIParent BEFORE Blizzard populates it.
		-- FriendsTooltip is a child of FriendsFrame in the XML, but BFL keeps
		-- FriendsFrame hidden. Without reparenting first, FriendsTooltip:Show()
		-- has a hidden parent, so external addons (ArchonTooltip, RaiderIO) that
		-- anchor GameTooltip to FriendsTooltip cannot position it correctly.
		tooltip:SetParent(UIParent)

		-- On 12.0.0+, avoid Blizzard's BNet tooltip path. It reads raw
		-- accountInfo fields through BNet_GetBNetAccountName/FriendsFrame helpers,
		-- which taints SecretValue reads when entered from addon-owned buttons.
		if BFL.HasSecretValues and friendData.type == "bnet" then
			ShowSafeRetailBNetTooltip(proxyButton, self, friendData)
		else
			FriendsListButtonMixin.OnEnter(proxyButton)

			-- Reposition tooltip to our actual visible button
			-- (Blizzard anchored to proxyButton which has no visible position)
			tooltip:ClearAllPoints()
			tooltip:SetPoint("TOPLEFT", self, "TOPRIGHT", 36, 0)
		end

		ApplyStreamerModeOverride(friendData)
	end
end

-- Button OnLeave handler
function BetterFriendsList_Button_OnLeave(self)
	BFL_Tooltip:Hide()
	local tooltip = FriendsTooltip
	tooltip.button = nil
	tooltip:Hide()
end
