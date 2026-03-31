-- BetterFriendlist_Tooltip.lua
-- Friend list tooltip: delegates to Blizzard's native FriendsTooltip (Retail) / FriendsFrameTooltip_Show (Classic)
-- Ensures compatibility with RaiderIO and other addons that hook into FriendsTooltip

local _, BFL = ...

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
			-- Use securecallfunction on 12.0.0+ (see main OnEnter for rationale)
			if BFL.HasSecretValues and securecallfunction then
				securecallfunction(FriendsListButtonMixin.OnEnter, self)
			else
				FriendsListButtonMixin.OnEnter(self)
			end

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

		-- On 12.0.0+, call Blizzard's code via securecallfunction to run in an
		-- untainted execution context. BNet_GetBNetAccountName does comparisons
		-- on accountInfo.accountName which can be a secret value (kString) in
		-- Midnight. In tainted execution, this comparison throws a Lua error and
		-- prevents FriendsTooltip:Show() from firing, breaking external addon
		-- hooks (ArchonTooltip, RaiderIO). securecallfunction avoids this by
		-- running the code in a secure (untainted) context.
		if BFL.HasSecretValues and securecallfunction then
			securecallfunction(FriendsListButtonMixin.OnEnter, proxyButton)
		else
			FriendsListButtonMixin.OnEnter(proxyButton)
		end

		-- Reposition tooltip to our actual visible button
		-- (Blizzard anchored to proxyButton which has no visible position)
		tooltip:ClearAllPoints()
		tooltip:SetPoint("TOPLEFT", self, "TOPRIGHT", 36, 0)

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
