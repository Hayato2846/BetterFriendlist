--------------------------------------------------------------------------
-- RAF Module - Recruit-A-Friend System
--------------------------------------------------------------------------
-- This module handles all Recruit-A-Friend functionality including:
-- - RAF frame initialization and event handling
-- - Recruit list display and management
-- - Reward system and claiming
-- - Activity tracking
-- - Integration with Blizzard's RAF frames
--------------------------------------------------------------------------

local ADDON_NAME, BFL = ...

-- Register the RAF module
local RAF = BFL:RegisterModule("RAF", {})

-- Local constants for RAF display
local RECRUIT_HEIGHT = 45
local DIVIDER_HEIGHT = 16

-- RAF state variables (module-level)
local maxRecruits = 0
local maxRecruitMonths = 0
local maxRecruitLinkUses = 0
local daysInCycle = 0
local latestRAFVersion = 0

--------------------------------------------------------------------------
-- RAF Frame Initialization and Event Handling
--------------------------------------------------------------------------

function RAF:OnLoad(frame)
	if not C_RecruitAFriend then
		print("BetterFriendlist: RAF system not available")
		return
	end
	
	-- Check if RAF is enabled
	frame.rafEnabled = C_RecruitAFriend.IsEnabled and C_RecruitAFriend.IsEnabled() or false
	frame.rafRecruitingEnabled = C_RecruitAFriend.IsRecruitingEnabled and C_RecruitAFriend.IsRecruitingEnabled() or false
	
	-- Register events
	frame:RegisterEvent("RAF_SYSTEM_ENABLED_STATUS")
	frame:RegisterEvent("RAF_RECRUITING_ENABLED_STATUS")
	frame:RegisterEvent("RAF_SYSTEM_INFO_UPDATED")
	frame:RegisterEvent("RAF_INFO_UPDATED")
	frame:RegisterEvent("BN_FRIEND_INFO_CHANGED")
	
	-- Set up no recruits text
	if frame.RecruitList and frame.RecruitList.NoRecruitsDesc then
		frame.RecruitList.NoRecruitsDesc:SetText(RAF_NO_RECRUITS_DESC or "You have not recruited any friends yet.")
	end
	
	-- Set up ScrollBox
	if frame.RecruitList and frame.RecruitList.ScrollBox and frame.RecruitList.ScrollBar then
		local view = CreateScrollBoxListLinearView()
		view:SetElementExtentCalculator(function(dataIndex, elementData)
			return elementData.isDivider and DIVIDER_HEIGHT or RECRUIT_HEIGHT
		end)
		view:SetElementInitializer("BetterRecruitListButtonTemplate", function(button, elementData)
			BetterRecruitListButton_Init(button, elementData)
		end)
		ScrollUtil.InitScrollBoxListWithScrollBar(frame.RecruitList.ScrollBox, frame.RecruitList.ScrollBar, view)
	end
	
	-- Get RAF system info
	if C_RecruitAFriend.GetRAFSystemInfo then
		local rafSystemInfo = C_RecruitAFriend.GetRAFSystemInfo()
		self:UpdateSystemInfo(rafSystemInfo)
	end
	
	-- Get RAF info
	if C_RecruitAFriend.GetRAFInfo then
		local rafInfo = C_RecruitAFriend.GetRAFInfo()
		self:UpdateRAFInfo(frame, rafInfo)
	end
end

function RAF:OnEvent(frame, event, ...)
	if event == "RAF_SYSTEM_ENABLED_STATUS" then
		local rafEnabled = ...
		frame.rafEnabled = rafEnabled
		if rafEnabled and C_RecruitAFriend.GetRAFInfo then
			self:UpdateRAFInfo(frame, C_RecruitAFriend.GetRAFInfo())
		end
	elseif event == "RAF_RECRUITING_ENABLED_STATUS" then
		local rafRecruitingEnabled = ...
		frame.rafRecruitingEnabled = rafRecruitingEnabled
		if frame.RecruitmentButton then
			frame.RecruitmentButton:SetShown(rafRecruitingEnabled)
		end
	elseif event == "RAF_SYSTEM_INFO_UPDATED" then
		local rafSystemInfo = ...
		self:UpdateSystemInfo(rafSystemInfo)
	elseif event == "RAF_INFO_UPDATED" then
		local rafInfo = ...
		self:UpdateRAFInfo(frame, rafInfo)
	elseif event == "BN_FRIEND_INFO_CHANGED" then
		if frame.rafInfo and frame.rafInfo.recruits then
			self:UpdateRecruitList(frame, frame.rafInfo.recruits)
		end
	end
end

function RAF:OnHide(frame)
	-- Hide splash frame if shown
	if frame.SplashFrame then
		frame.SplashFrame:Hide()
	end
end

--------------------------------------------------------------------------
-- RAF System Info Management
--------------------------------------------------------------------------

function RAF:UpdateSystemInfo(rafSystemInfo)
	if rafSystemInfo then
		maxRecruits = rafSystemInfo.maxRecruits or 0
		maxRecruitMonths = rafSystemInfo.maxRecruitMonths or 0
		maxRecruitLinkUses = rafSystemInfo.maxRecruitmentUses or 0
		daysInCycle = rafSystemInfo.daysInCycle or 0
	end
end

--------------------------------------------------------------------------
-- Recruit List Management
--------------------------------------------------------------------------

-- Sort recruits by online status, version, and name
local function SortRecruits(a, b)
	if a.isOnline ~= b.isOnline then
		return a.isOnline
	else
		if a.versionRecruited ~= b.versionRecruited then
			return a.versionRecruited > b.versionRecruited
		end
		return (a.nameText or "") < (b.nameText or "")
	end
end

-- Process and sort recruits with divider logic
local function ProcessAndSortRecruits(recruits)
	local seenAccounts = {}
	local haveOnlineFriends = false
	local haveOfflineFriends = false
	
	-- Get account info for all recruits
	for _, recruitInfo in ipairs(recruits) do
		if C_BattleNet and C_BattleNet.GetAccountInfoByID then
			local accountInfo = C_BattleNet.GetAccountInfoByID(recruitInfo.bnetAccountID, recruitInfo.wowAccountGUID)
			
			if accountInfo and accountInfo.gameAccountInfo and not accountInfo.gameAccountInfo.isWowMobile then
				recruitInfo.isOnline = accountInfo.gameAccountInfo.isOnline
				recruitInfo.characterName = accountInfo.gameAccountInfo.characterName
				
				-- Get name and status
				if FriendsFrame_GetBNetAccountNameAndStatus then
					recruitInfo.nameText, recruitInfo.nameColor = FriendsFrame_GetBNetAccountNameAndStatus(accountInfo)
				else
					recruitInfo.nameText = recruitInfo.battleTag or "Unknown"
					recruitInfo.nameColor = FRIENDS_GRAY_COLOR
				end
				
				if BNet_GetBNetAccountName then
					recruitInfo.plainName = BNet_GetBNetAccountName(accountInfo)
				else
					recruitInfo.plainName = recruitInfo.nameText
				end
			else
				-- No presence info yet
				recruitInfo.isOnline = false
				recruitInfo.nameText = BNet_GetTruncatedBattleTag and BNet_GetTruncatedBattleTag(recruitInfo.battleTag) or recruitInfo.battleTag or "Unknown"
				recruitInfo.plainName = recruitInfo.nameText
				recruitInfo.nameColor = FRIENDS_GRAY_COLOR
			end
			
			-- Handle pending recruits
			if recruitInfo.nameText == "" and RAF_PENDING_RECRUIT then
				recruitInfo.nameText = RAF_PENDING_RECRUIT
				recruitInfo.plainName = RAF_PENDING_RECRUIT
			end
			
			recruitInfo.accountInfo = accountInfo
			
			-- Track seen accounts
			if not seenAccounts[recruitInfo.bnetAccountID] then
				seenAccounts[recruitInfo.bnetAccountID] = 1
			else
				seenAccounts[recruitInfo.bnetAccountID] = seenAccounts[recruitInfo.bnetAccountID] + 1
			end
			
			recruitInfo.recruitIndex = seenAccounts[recruitInfo.bnetAccountID]
			
			if recruitInfo.isOnline then
				haveOnlineFriends = true
			else
				haveOfflineFriends = true
			end
		end
	end
	
	-- Append recruit index for multiple accounts
	for _, recruitInfo in ipairs(recruits) do
		if seenAccounts[recruitInfo.bnetAccountID] > 1 and not recruitInfo.characterName then
			if RAF_RECRUIT_NAME_MULTIPLE then
				recruitInfo.nameText = RAF_RECRUIT_NAME_MULTIPLE:format(recruitInfo.nameText, recruitInfo.recruitIndex)
			end
		end
	end
	
	-- Sort by online status, version, and name
	table.sort(recruits, SortRecruits)
	
	return haveOnlineFriends and haveOfflineFriends
end

function RAF:UpdateRecruitList(frame, recruits)
	if not frame or not frame.RecruitList then return end
	
	local numRecruits = #recruits
	
	-- Show/hide no recruits message
	if frame.RecruitList.NoRecruitsDesc then
		frame.RecruitList.NoRecruitsDesc:SetShown(numRecruits == 0)
	end
	
	-- Update header count
	if frame.RecruitList.Header and frame.RecruitList.Header.Count then
		frame.RecruitList.Header.Count:SetText(RAF_RECRUITED_FRIENDS_COUNT and RAF_RECRUITED_FRIENDS_COUNT:format(numRecruits, maxRecruits) or string.format("%d/%d", numRecruits, maxRecruits))
	end
	
	-- Process and sort recruits
	local needDivider = ProcessAndSortRecruits(recruits)
	
	-- Build data provider with divider
	local dataProvider = CreateDataProvider()
	for index = 1, numRecruits do
		local recruit = recruits[index]
		if needDivider and not recruit.isOnline then
			dataProvider:Insert({isDivider=true})
			needDivider = false
		end
		dataProvider:Insert(recruit)
	end
	
	-- Update ScrollBox
	if frame.RecruitList.ScrollBox then
		frame.RecruitList.ScrollBox:SetDataProvider(dataProvider, ScrollBoxConstants.RetainScrollPosition)
	end
end

--------------------------------------------------------------------------
-- Reward Display Management
--------------------------------------------------------------------------

function RAF:UpdateNextReward(frame, nextReward)
	if not frame or not frame.RewardClaiming then return end
	
	local rewardPanel = frame.RewardClaiming
	
	if not nextReward then
		if rewardPanel.EarnInfo then rewardPanel.EarnInfo:Hide() end
		if rewardPanel.NextRewardButton then rewardPanel.NextRewardButton:Hide() end
		if rewardPanel.NextRewardName then rewardPanel.NextRewardName:Hide() end
		return
	end
	
	-- Set earn info text
	if rewardPanel.EarnInfo then
		local earnText = ""
		if nextReward.canClaim then
			earnText = RAF_YOU_HAVE_EARNED or "You have earned:"
		elseif nextReward.monthCost and nextReward.monthCost > 1 then
			earnText = RAF_NEXT_REWARD_AFTER and RAF_NEXT_REWARD_AFTER:format(nextReward.monthCost - nextReward.availableInMonths, nextReward.monthCost) or "Next reward soon"
		elseif nextReward.monthsRequired == 0 then
			earnText = RAF_FIRST_REWARD or "First Reward:"
		else
			earnText = RAF_NEXT_REWARD or "Next Reward:"
		end
		rewardPanel.EarnInfo:SetText(earnText)
		rewardPanel.EarnInfo:Show()
	end
	
	-- Set reward icon
	if rewardPanel.NextRewardButton and nextReward.iconID then
		-- Apply circular mask (only once)
		if not rewardPanel.NextRewardButton.maskApplied then
			if rewardPanel.NextRewardButton.Icon and rewardPanel.NextRewardButton.IconOverlay and rewardPanel.NextRewardButton.CircleMask then
				rewardPanel.NextRewardButton.Icon:AddMaskTexture(rewardPanel.NextRewardButton.CircleMask)
				rewardPanel.NextRewardButton.IconOverlay:AddMaskTexture(rewardPanel.NextRewardButton.CircleMask)
				rewardPanel.NextRewardButton.maskApplied = true
			end
		end
		
		rewardPanel.NextRewardButton.Icon:SetTexture(nextReward.iconID)
		
		if not nextReward.canClaim then
			rewardPanel.NextRewardButton.Icon:SetDesaturated(true)
			rewardPanel.NextRewardButton.IconOverlay:Show()
		else
			rewardPanel.NextRewardButton.Icon:SetDesaturated(false)
			rewardPanel.NextRewardButton.IconOverlay:Hide()
		end
		rewardPanel.NextRewardButton:Show()
	end
	
	-- Set reward name
	if rewardPanel.NextRewardName and rewardPanel.NextRewardName.Text then
		local rewardName = ""
		if nextReward.petInfo and nextReward.petInfo.speciesName then
			rewardName = nextReward.petInfo.speciesName
		elseif nextReward.mountInfo and nextReward.mountInfo.mountID then
			rewardName = C_MountJournal.GetMountInfoByID and C_MountJournal.GetMountInfoByID(nextReward.mountInfo.mountID) or "Mount"
		elseif nextReward.titleInfo and nextReward.titleInfo.titleMaskID then
			local titleName = TitleUtil.GetNameFromTitleMaskID and TitleUtil.GetNameFromTitleMaskID(nextReward.titleInfo.titleMaskID) or "Title"
			rewardName = RAF_REWARD_TITLE and RAF_REWARD_TITLE:format(titleName) or titleName
		else
			rewardName = RAF_BENEFIT4 or "Game Time"
		end
		
		rewardPanel.NextRewardName.Text:SetText(rewardName)
		
		-- Set color using the same method as Blizzard
		if nextReward.rewardType == Enum.RafRewardType.GameTime then
			rewardPanel.NextRewardName.Text:SetTextColor(HEIRLOOM_BLUE_COLOR:GetRGBA())
		else
			rewardPanel.NextRewardName.Text:SetTextColor(EPIC_PURPLE_COLOR:GetRGBA())
		end
		
		rewardPanel.NextRewardName:Show()
	end
end

function RAF:UpdateRAFInfo(frame, rafInfo)
	if not frame or not rafInfo then return end
	
	frame.rafInfo = rafInfo
	
	-- Store latest RAF version globally for recruit button logic
	if rafInfo.versions and rafInfo.versions[1] then
		latestRAFVersion = rafInfo.versions[1].rafVersion or 0
	end
	
	-- Update recruit list
	if rafInfo.recruits then
		self:UpdateRecruitList(frame, rafInfo.recruits)
	end
	
	-- Update month count
	if frame.RewardClaiming and frame.RewardClaiming.MonthCount and frame.RewardClaiming.MonthCount.Text then
		local latestVersionInfo = rafInfo.versions and rafInfo.versions[1]
		if latestVersionInfo then
			local monthCount = latestVersionInfo.monthCount and latestVersionInfo.monthCount.lifetimeMonths or 0
			-- Format: "X Months Subscribed by Friends"
			local monthText = string.format(RAF_MONTH_COUNT or "%d Months Subscribed by Friends", monthCount)
			frame.RewardClaiming.MonthCount.Text:SetText(monthText)
			frame.RewardClaiming.MonthCount:Show()
		end
	end
	
	-- Update next reward
	local latestVersionInfo = rafInfo.versions and rafInfo.versions[1]
	if latestVersionInfo and latestVersionInfo.nextReward then
		self:UpdateNextReward(frame, latestVersionInfo.nextReward)
	end
	
	-- Update claim button
	if frame.RewardClaiming and frame.RewardClaiming.ClaimOrViewRewardButton then
		local nextReward = latestVersionInfo and latestVersionInfo.nextReward
		local haveUnclaimedReward = nextReward and nextReward.canClaim
		
		if haveUnclaimedReward then
			frame.RewardClaiming.ClaimOrViewRewardButton:SetEnabled(true)
			frame.RewardClaiming.ClaimOrViewRewardButton:SetText(CLAIM_REWARD or "Claim Reward")
		else
			frame.RewardClaiming.ClaimOrViewRewardButton:SetEnabled(true)
			frame.RewardClaiming.ClaimOrViewRewardButton:SetText(RAF_VIEW_ALL_REWARDS or "View All Rewards")
		end
	end
end

function RAF:ShowSplashScreen(frame)
	if not frame or not frame.SplashFrame then return end
	frame.SplashFrame:Show()
end

--------------------------------------------------------------------------
-- Recruit Button Handlers (Global Functions for XML)
--------------------------------------------------------------------------

function RAF:RecruitListButton_Init(button, elementData)
	if elementData.isDivider then
		self:RecruitListButton_SetupDivider(button)
	else
		self:RecruitListButton_SetupRecruit(button, elementData)
	end
end

function RAF:RecruitListButton_SetupDivider(button)
	button.DividerTexture:Show()
	button.Background:Hide()
	button.Name:Hide()
	button.InfoText:Hide()
	button.Icon:Hide()
	
	for i = 1, #button.Activities do
		button.Activities[i]:Hide()
	end
	
	button:SetHeight(DIVIDER_HEIGHT)
	button:Disable()
	button.recruitInfo = nil
	button:Show()
end

function RAF:RecruitListButton_SetupRecruit(button, recruitInfo)
	button.DividerTexture:Hide()
	button.Background:Show()
	button.Name:Show()
	button.InfoText:Show()
	
	-- Always show Icon, but set different atlas based on RAF version
	local versionRecruited = recruitInfo.versionRecruited or 0
	
	-- Show legacy icon for older RAF versions, or current icon for current version
	if versionRecruited > 0 and versionRecruited < latestRAFVersion then
		-- Legacy RAF version - show legacy icon
		button.Icon:SetAtlas("recruitafriend_friendslist_v2_icon", true)
		button.Icon:Show()
	elseif versionRecruited == latestRAFVersion then
		-- Current RAF version - show current icon
		button.Icon:SetAtlas("recruitafriend_friendslist_v3_icon", true)
		button.Icon:Show()
	else
		-- No valid version - hide icon
		button.Icon:Hide()
	end
	
	button:SetHeight(RECRUIT_HEIGHT)
	button:Enable()
	button.recruitInfo = recruitInfo
	
	-- Set name with color
	if recruitInfo.nameText and recruitInfo.nameColor then
		button.Name:SetText(recruitInfo.nameText)
		button.Name:SetTextColor(recruitInfo.nameColor:GetRGB())
	end
	
	-- Set background color based on online status
	if recruitInfo.isOnline then
		button.Background:SetColorTexture(0.2, 0.4, 0.8, 0.3) -- Blue tint for online
		
		-- Set info text based on subscription status
		if recruitInfo.subStatus == Enum.RafRecruitSubStatus.Active then
			button.InfoText:SetText(RAF_ACTIVE_RECRUIT or "Active")
			button.InfoText:SetTextColor(GREEN_FONT_COLOR:GetRGB())
		elseif recruitInfo.subStatus == Enum.RafRecruitSubStatus.Trial then
			button.InfoText:SetText(RAF_TRIAL_RECRUIT or "Trial")
			button.InfoText:SetTextColor(NORMAL_FONT_COLOR:GetRGB())
		else
			button.InfoText:SetText(RAF_INACTIVE_RECRUIT or "Inactive")
			button.InfoText:SetTextColor(GRAY_FONT_COLOR:GetRGB())
		end
	else
		button.Background:SetColorTexture(FRIENDS_OFFLINE_BACKGROUND_COLOR:GetRGBA())
		button.InfoText:SetTextColor(GRAY_FONT_COLOR:GetRGB())
		
		if recruitInfo.subStatus == Enum.RafRecruitSubStatus.Inactive then
			button.InfoText:SetText(RAF_INACTIVE_RECRUIT or "Inactive")
		else
			-- Show last online time
			if recruitInfo.accountInfo and FriendsFrame_GetLastOnlineText then
				button.InfoText:SetText(FriendsFrame_GetLastOnlineText(recruitInfo.accountInfo))
			else
				button.InfoText:SetText(FRIENDS_LIST_OFFLINE or "Offline")
			end
		end
	end
	
	-- Update activities (always process all activity buttons to ensure they're hidden when no activities)
	for i = 1, #button.Activities do
		local activityInfo = recruitInfo.activities and recruitInfo.activities[i] or nil
		self:RecruitActivityButton_Setup(button.Activities[i], activityInfo, recruitInfo)
	end
	
	button:Show()
end

function RAF:RecruitListButton_OnEnter(button)
	if not button.recruitInfo then return end
	
	local recruitInfo = button.recruitInfo
	GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
	
	if recruitInfo.nameText and recruitInfo.nameColor then
		GameTooltip_SetTitle(GameTooltip, recruitInfo.nameText, recruitInfo.nameColor)
	end
	
	local wrap = true
	if maxRecruitMonths > 0 then
		GameTooltip_AddNormalLine(GameTooltip, RAF_RECRUIT_TOOLTIP_DESC and RAF_RECRUIT_TOOLTIP_DESC:format(maxRecruitMonths) or string.format("Up to %d months", maxRecruitMonths), wrap)
		GameTooltip_AddBlankLineToTooltip(GameTooltip)
	end
	
	if recruitInfo.monthsRemaining then
		local usedMonths = math.max(maxRecruitMonths - recruitInfo.monthsRemaining, 0)
		GameTooltip_AddColoredLine(GameTooltip, RAF_RECRUIT_TOOLTIP_MONTH_COUNT and RAF_RECRUIT_TOOLTIP_MONTH_COUNT:format(usedMonths, maxRecruitMonths) or string.format("%d / %d months", usedMonths, maxRecruitMonths), HIGHLIGHT_FONT_COLOR, wrap)
	end
	
	GameTooltip:Show()
end

function RAF:RecruitListButton_OnClick(button, mouseButton)
	if mouseButton == "RightButton" and button.recruitInfo then
		local recruitInfo = button.recruitInfo
		local contextData = {
			name = recruitInfo.plainName,
			bnetIDAccount = recruitInfo.bnetAccountID,
			wowAccountGUID = recruitInfo.wowAccountGUID,
			isRafRecruit = true,
		}
		
		if recruitInfo.accountInfo and recruitInfo.accountInfo.gameAccountInfo then
			contextData.guid = recruitInfo.accountInfo.gameAccountInfo.playerGuid
		end
		
		UnitPopup_OpenMenu("RAF_RECRUIT", contextData)
	end
end

--------------------------------------------------------------------------
-- Recruit Activity Button Handlers
--------------------------------------------------------------------------

function RAF:RecruitActivityButton_Setup(button, activityInfo, recruitInfo)
	if not activityInfo then
		button:Hide()
		return
	end
	
	button.activityInfo = activityInfo
	button.recruitInfo = recruitInfo
	
	self:RecruitActivityButton_UpdateIcon(button)
	button:Show()
end

function RAF:RecruitActivityButton_UpdateIcon(button)
	if not button.activityInfo then return end
	
	local useAtlasSize = true
	if button:IsMouseOver() then
		if button.activityInfo.state == Enum.RafRecruitActivityState.RewardClaimed then
			button.Icon:SetAtlas("RecruitAFriend_RecruitedFriends_CursorOverChecked", useAtlasSize)
		else
			button.Icon:SetAtlas("RecruitAFriend_RecruitedFriends_CursorOver", useAtlasSize)
		end
	else
		if button.activityInfo.state == Enum.RafRecruitActivityState.Incomplete then
			button.Icon:SetAtlas("RecruitAFriend_RecruitedFriends_ActiveChest", useAtlasSize)
		elseif button.activityInfo.state == Enum.RafRecruitActivityState.Complete then
			button.Icon:SetAtlas("RecruitAFriend_RecruitedFriends_OpenChest", useAtlasSize)
		else
			button.Icon:SetAtlas("RecruitAFriend_RecruitedFriends_ClaimedChest", useAtlasSize)
		end
	end
end

function RAF:RecruitActivityButton_OnClick(button)
	if not button.activityInfo or not button.recruitInfo then return end
	
	if button.activityInfo.state == Enum.RafRecruitActivityState.Complete then
		if C_RecruitAFriend.ClaimActivityReward then
			if C_RecruitAFriend.ClaimActivityReward(button.activityInfo.activityID, button.recruitInfo.acceptanceID) then
				PlaySound(SOUNDKIT.RAF_RECRUIT_REWARD_CLAIM)
				C_Timer.After(0.3, function()
					button.activityInfo.state = Enum.RafRecruitActivityState.RewardClaimed
					RAF:RecruitActivityButton_UpdateIcon(button)
				end)
			end
		end
	end
end

function RAF:RecruitActivityButton_OnEnter(button)
	if not button.activityInfo or not button.recruitInfo then return end
	
	-- Enable highlight on parent recruit list button
	local parent = button:GetParent()
	if parent then
		parent:EnableDrawLayer("HIGHLIGHT")
	end
	
	GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
	
	local wrap = true
	local questName = button.activityInfo.rewardQuestID and C_QuestLog.GetTitleForQuestID and C_QuestLog.GetTitleForQuestID(button.activityInfo.rewardQuestID)
	
	if questName then
		GameTooltip_SetTitle(GameTooltip, questName, nil, wrap)
		GameTooltip:SetMinimumWidth(300)
		GameTooltip_AddNormalLine(GameTooltip, RAF_RECRUIT_ACTIVITY_DESCRIPTION and RAF_RECRUIT_ACTIVITY_DESCRIPTION:format(button.recruitInfo.nameText) or "Activity", true)
		
		if C_RecruitAFriend.GetRecruitActivityRequirementsText then
			local reqTextLines = C_RecruitAFriend.GetRecruitActivityRequirementsText(button.activityInfo.activityID, button.recruitInfo.acceptanceID)
			for i = 1, #reqTextLines do
				GameTooltip_AddColoredLine(GameTooltip, reqTextLines[i], HIGHLIGHT_FONT_COLOR, wrap)
			end
		end
		
		GameTooltip_AddBlankLineToTooltip(GameTooltip)
		
		if button.activityInfo.state == Enum.RafRecruitActivityState.Incomplete then
			GameTooltip_AddNormalLine(GameTooltip, QUEST_REWARDS or "Rewards", wrap)
		else
			GameTooltip_AddNormalLine(GameTooltip, YOU_EARNED_LABEL or "You earned:", wrap)
		end
		
		if GameTooltip_AddQuestRewardsToTooltip then
			GameTooltip_AddQuestRewardsToTooltip(GameTooltip, button.activityInfo.rewardQuestID, TOOLTIP_QUEST_REWARDS_STYLE_NONE)
		end
		
		if button.activityInfo.state == Enum.RafRecruitActivityState.Complete then
			GameTooltip_AddBlankLineToTooltip(GameTooltip)
			GameTooltip_AddInstructionLine(GameTooltip, CLICK_CHEST_TO_CLAIM_REWARD or "Click to claim reward", wrap)
		end
	else
		GameTooltip_SetTitle(GameTooltip, RETRIEVING_DATA or "Loading...", RED_FONT_COLOR)
	end
	
	self:RecruitActivityButton_UpdateIcon(button)
	GameTooltip:Show()
end

function RAF:RecruitActivityButton_OnLeave(button)
	-- Disable highlight on parent recruit list button
	local parent = button:GetParent()
	if parent then
		parent:DisableDrawLayer("HIGHLIGHT")
	end
	
	GameTooltip_Hide()
	RAF:RecruitActivityButton_UpdateIcon(button)
end

--------------------------------------------------------------------------
-- Next Reward Button Handlers
--------------------------------------------------------------------------

function RAF:NextRewardButton_OnClick(button, mouseButton)
	local frame = button:GetParent():GetParent()
	if not frame or not frame.rafInfo then return end
	
	local latestVersionInfo = frame.rafInfo.versions and frame.rafInfo.versions[1]
	local nextReward = latestVersionInfo and latestVersionInfo.nextReward
	
	if IsModifiedClick("DRESSUP") and nextReward then
		if nextReward.petInfo and DressUpBattlePet then
			DressUpBattlePet(nextReward.petInfo.creatureID, nextReward.petInfo.displayID, nextReward.petInfo.speciesID)
		elseif nextReward.mountInfo and DressUpMount then
			DressUpMount(nextReward.mountInfo.mountID)
		elseif nextReward.appearanceInfo and DressUpVisual then
			DressUpVisual(nextReward.appearanceInfo.appearanceID)
		end
	elseif IsModifiedClick("CHATLINK") and nextReward and nextReward.itemID then
		local name, link = C_Item.GetItemInfo(nextReward.itemID)
		if not ChatEdit_InsertLink(link) then
			ChatFrame_OpenChat(link)
		end
	end
end

function RAF:NextRewardButton_OnEnter(button)
	local frame = button:GetParent():GetParent()
	if not frame or not frame.rafInfo then return end
	
	local latestVersionInfo = frame.rafInfo.versions and frame.rafInfo.versions[1]
	local nextReward = latestVersionInfo and latestVersionInfo.nextReward
	
	if not nextReward or not nextReward.itemID then return end
	
	GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
	GameTooltip:SetItemByID(nextReward.itemID)
	
	if IsModifiedClick("DRESSUP") then
		ShowInspectCursor()
	else
		ResetCursor()
	end
end

--------------------------------------------------------------------------
-- Claim/View Reward Button Handler
--------------------------------------------------------------------------

function RAF:ClaimOrViewRewardButton_OnClick(button)
	local frame = button:GetParent():GetParent()
	if not frame or not frame.rafInfo then return end
	
	local latestVersionInfo = frame.rafInfo.versions and frame.rafInfo.versions[1]
	local nextReward = latestVersionInfo and latestVersionInfo.nextReward
	local haveUnclaimedReward = nextReward and nextReward.canClaim
	
	if haveUnclaimedReward then
		-- Claim reward
		if nextReward.rewardType == Enum.RafRewardType.GameTime then
			-- Game time requires special dialog
			PlaySound(SOUNDKIT.IG_MAINMENU_OPEN)
			if WowTokenRedemptionFrame_ShowDialog then
				WowTokenRedemptionFrame_ShowDialog("RAF_GAME_TIME_REDEEM_CONFIRMATION_SUB", latestVersionInfo.rafVersion)
			else
				DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00Recruit-A-Friend:|r Game time reward available. Use the Blizzard UI to claim.", 1, 1, 0)
			end
		elseif C_RecruitAFriend.ClaimNextReward then
			if C_RecruitAFriend.ClaimNextReward() then
				PlaySound(SOUNDKIT.RAF_RECRUIT_REWARD_CLAIM)
				-- Refresh RAF info after claim
				C_Timer.After(0.5, function()
					local rafInfo = C_RecruitAFriend.GetRAFInfo()
					if rafInfo then
						RAF:UpdateRAFInfo(frame, rafInfo)
					end
				end)
			end
		end
	else
		-- Show all rewards list
		if RecruitAFriendRewardsFrame then
			-- Load Blizzard's RAF addon if not already loaded
			if not RecruitAFriendFrame then
				LoadAddOn("Blizzard_RecruitAFriend")
			end
			
			-- Ensure Blizzard's RecruitAFriendFrame has the data it needs
			if RecruitAFriendFrame and frame.rafInfo then
				-- Store RAF info in Blizzard's frame (critical for RewardsFrame to work!)
				RecruitAFriendFrame.rafInfo = frame.rafInfo
				RecruitAFriendFrame.rafEnabled = true
				
				-- ALWAYS set selected RAF version to the latest when opening rewards
				-- This ensures we start with the correct version every time
				if frame.rafInfo.versions and #frame.rafInfo.versions > 0 then
					local latestVersion = frame.rafInfo.versions[1].rafVersion
					RecruitAFriendFrame.selectedRAFVersion = latestVersion
				end
				
				-- Store rafSystemInfo if we have it
				if frame.RecruitAFriendFrame and frame.RecruitAFriendFrame.rafSystemInfo then
					RecruitAFriendFrame.rafSystemInfo = frame.RecruitAFriendFrame.rafSystemInfo
				end
				
				-- CRITICAL: Override/Initialize the TriggerEvent system
				-- Even if it exists, we need to ensure it works with our setup
				local originalTriggerEvent = RecruitAFriendFrame.TriggerEvent
				
				RecruitAFriendFrame.callbacks = RecruitAFriendFrame.callbacks or {}
				
				RecruitAFriendFrame.TriggerEvent = function(self, event, ...)
					-- Handle NewRewardTabSelected event
					if event == "NewRewardTabSelected" then
						local newRAFVersion = ...
						self.selectedRAFVersion = newRAFVersion
						
						-- Refresh the rewards display
						if RecruitAFriendRewardsFrame and RecruitAFriendRewardsFrame.Refresh then
							RecruitAFriendRewardsFrame:Refresh()
						end
					elseif event == "RewardsListOpened" then
						-- Set to latest version when opening
						if self.rafInfo and self.rafInfo.versions and #self.rafInfo.versions > 0 then
							self.selectedRAFVersion = self.rafInfo.versions[1].rafVersion
						end
					end
					
					-- Call original if it was a real function (not our mock)
					if originalTriggerEvent and originalTriggerEvent ~= self.TriggerEvent then
						originalTriggerEvent(self, event, ...)
					end
				end
				
				-- Add helper methods that RecruitAFriendFrame needs (always set these)
				RecruitAFriendFrame.GetSelectedRAFVersion = function(self)
					return self.selectedRAFVersion
				end
				
				RecruitAFriendFrame.GetSelectedRAFVersionInfo = function(self)
					if not self.rafInfo or not self.rafInfo.versions then 
						return nil 
					end
					for _, versionInfo in ipairs(self.rafInfo.versions) do
						if versionInfo.rafVersion == self.selectedRAFVersion then
							return versionInfo
						end
					end
					return self.rafInfo.versions[1] -- Fallback to first version
				end
				
				RecruitAFriendFrame.GetLatestRAFVersion = function(self)
					if self.rafInfo and self.rafInfo.versions and #self.rafInfo.versions > 0 then
						return self.rafInfo.versions[1].rafVersion
					end
					return nil
				end
				
				RecruitAFriendFrame.IsLegacyRAFVersion = function(self, rafVersion)
					-- All versions except the latest are considered legacy
					local latestVersion = self:GetLatestRAFVersion()
					return rafVersion ~= latestVersion
				end
				
				RecruitAFriendFrame.GetRAFVersionInfo = function(self, rafVersion)
					if not self.rafInfo or not self.rafInfo.versions then return nil end
					for _, versionInfo in ipairs(self.rafInfo.versions) do
						if versionInfo.rafVersion == rafVersion then
							return versionInfo
						end
					end
					return nil
				end
			end
			
			-- Use Blizzard's rewards frame
			if RecruitAFriendRewardsFrame:IsShown() then
				RecruitAFriendRewardsFrame:Hide()
			else
				-- Set up tabs and refresh (Blizzard does this in UpdateRAFInfo)
				if frame.rafInfo then
					if RecruitAFriendRewardsFrame.SetUpTabs then
						RecruitAFriendRewardsFrame:SetUpTabs(frame.rafInfo)
					end
					
					if RecruitAFriendRewardsFrame.Refresh then
						RecruitAFriendRewardsFrame:Refresh()
					end
				end
				
				RecruitAFriendRewardsFrame:Show()
				PlaySound(SOUNDKIT.IG_MAINMENU_OPEN)
				StaticPopupSpecial_Hide(RecruitAFriendRecruitmentFrame)
			end
		else
			-- Fallback: Display rewards info in chat
			self:DisplayRewardsInChat(frame.rafInfo)
		end
	end
end

--------------------------------------------------------------------------
-- Utility Functions
--------------------------------------------------------------------------

function RAF:DisplayRewardsInChat(rafInfo)
	if not rafInfo or not rafInfo.versions then return end
	
	DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00=== Recruit-A-Friend Rewards ===|r", 1, 1, 0)
	
	for versionIndex, versionInfo in ipairs(rafInfo.versions) do
		local versionName = versionIndex == 1 and "Current RAF" or "Legacy RAF v" .. versionInfo.rafVersion
		DEFAULT_CHAT_FRAME:AddMessage("|cff00ccff" .. versionName .. ":|r", 0.8, 0.8, 1)
		DEFAULT_CHAT_FRAME:AddMessage("  Months earned: " .. (versionInfo.monthCount and versionInfo.monthCount.lifetimeMonths or 0), 1, 1, 1)
		DEFAULT_CHAT_FRAME:AddMessage("  Recruits: " .. (versionInfo.numRecruits or 0), 1, 1, 1)
		
		if versionInfo.rewards and #versionInfo.rewards > 0 then
			DEFAULT_CHAT_FRAME:AddMessage("  Available Rewards:", 1, 1, 1)
			for i, reward in ipairs(versionInfo.rewards) do
				if i <= 5 then -- Show first 5 rewards
					local status = reward.claimed and "|cff00ff00[Claimed]|r" or 
								   reward.canClaim and "|cffffff00[Can Claim]|r" or
								   reward.canAfford and "|cffff9900[Affordable]|r" or
								   "|cff666666[Locked]|r"
					local rewardName = "Reward"
					if reward.petInfo then
						rewardName = reward.petInfo.speciesName or "Pet"
					elseif reward.mountInfo then
						local mountName = C_MountJournal.GetMountInfoByID and C_MountJournal.GetMountInfoByID(reward.mountInfo.mountID)
						rewardName = mountName or "Mount"
					elseif reward.titleInfo then
						rewardName = TitleUtil.GetNameFromTitleMaskID and TitleUtil.GetNameFromTitleMaskID(reward.titleInfo.titleMaskID) or "Title"
					end
					DEFAULT_CHAT_FRAME:AddMessage("    - " .. rewardName .. " " .. status .. " (" .. reward.monthsRequired .. " months)", 0.9, 0.9, 0.9)
				end
			end
			if #versionInfo.rewards > 5 then
				DEFAULT_CHAT_FRAME:AddMessage("    ... and " .. (#versionInfo.rewards - 5) .. " more rewards", 0.7, 0.7, 0.7)
			end
		end
	end
	
	DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00Use the in-game Recruit-A-Friend interface for full details.|r", 1, 1, 0)
end

function RAF:RecruitmentButton_OnClick(button)
	-- Ensure RecruitAFriendRecruitmentFrame is loaded
	if not RecruitAFriendRecruitmentFrame then
		LoadAddOn("Blizzard_RecruitAFriend")
	end
	
	if not RecruitAFriendRecruitmentFrame then
		print("Error: Could not load RecruitAFriendRecruitmentFrame")
		return
	end
	
	-- Toggle recruitment frame (exact Blizzard logic)
	if RecruitAFriendRecruitmentFrame:IsShown() then
		StaticPopupSpecial_Hide(RecruitAFriendRecruitmentFrame)
	else
		C_RecruitAFriend.RequestUpdatedRecruitmentInfo()
		
		-- Hide rewards frame if shown
		if RecruitAFriendRewardsFrame then
			RecruitAFriendRewardsFrame:Hide()
		end
		
		StaticPopupSpecial_Show(RecruitAFriendRecruitmentFrame)
	end
end
