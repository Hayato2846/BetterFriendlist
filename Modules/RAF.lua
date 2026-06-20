--------------------------------------------------------------------------
-- RAF Module - Recruit-A-Friend System
--------------------------------------------------------------------------
-- This module handles all Recruit-A-Friend functionality including:
-- - RAF frame initialization and event handling
-- - Recruit list display and management
-- - Reward system and claiming
-- - Activity tracking
-- - Integration with Blizzard's RAF frames
--
-- NOTE: RAF is Retail-only. This module is disabled in Classic.
--------------------------------------------------------------------------

local ADDON_NAME, BFL = ...
local L = BFL.L

-- Register the RAF module
local RAF = BFL:RegisterModule("RAF", {})

-- Classic Guard: RAF doesn't exist in Classic Era or MoP Classic
BFL.HasRAF = BFL.IsRAFSystemSupported and BFL.IsRAFSystemSupported() or (BFL.IsRetail and C_RecruitAFriend ~= nil)

-- Local constants for RAF display
local RECRUIT_HEIGHT = 34
local DIVIDER_HEIGHT = 16

-- RAF state variables (module-level)
local maxRecruits = 0
local maxRecruitMonths = 0
local maxRecruitLinkUses = 0
local daysInCycle = 0
local latestRAFVersion = 0

--------------------------------------------------------------------------
-- RAFUtil-compatible helpers (uses Blizzard RAFUtil when available)
--------------------------------------------------------------------------

-- Texture kit mapping: RAF version -> texture kit string
-- Matches Blizzard's RAFUtil.GetTextureKitForRAFVersion
local function GetTextureKitForRAFVersion(rafVersion)
	if RAFUtil and RAFUtil.GetTextureKitForRAFVersion then
		return RAFUtil.GetTextureKitForRAFVersion(rafVersion)
	end
	-- Fallback: replicate Blizzard's mapping
	if Enum and Enum.RecruitAFriendRewardsVersion then
		if rafVersion == Enum.RecruitAFriendRewardsVersion.VersionTwo then
			return "V2"
		elseif rafVersion == Enum.RecruitAFriendRewardsVersion.VersionThree then
			return "V3"
		end
	end
	return nil
end

-- Color mapping: RAF version -> online background color
-- Matches Blizzard's RAFUtil.GetColorForRAFVersion
local function GetColorForRAFVersion(rafVersion)
	if RAFUtil and RAFUtil.GetColorForRAFVersion then
		return RAFUtil.GetColorForRAFVersion(rafVersion)
	end
	-- Fallback: use known color constants
	if Enum and Enum.RecruitAFriendRewardsVersion then
		if rafVersion == Enum.RecruitAFriendRewardsVersion.VersionTwo and RAF_VERSION_TWO_COLOR then
			return RAF_VERSION_TWO_COLOR
		elseif rafVersion == Enum.RecruitAFriendRewardsVersion.VersionThree and RAF_VERSION_THREE_COLOR then
			return RAF_VERSION_THREE_COLOR
		end
	end
	-- Ultimate fallback blue tint
	return CreateColor(0.2, 0.4, 0.8, 0.3)
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

local function CallBlizzardFunction(func, ...)
	if not func then
		return nil
	end
	if securecallfunction then
		return securecallfunction(func, ...)
	end
	return func(...)
end

local function CallBlizzardMethod(owner, method, ...)
	if not owner or not method then
		return nil
	end
	return CallBlizzardFunction(method, owner, ...)
end

local function LoadBlizzardRecruitAFriend()
	if RecruitAFriendFrame and RecruitAFriendRewardsFrame and RecruitAFriendRecruitmentFrame then
		return true
	end

	local loadAddOn = C_AddOns and C_AddOns.LoadAddOn or LoadAddOn
	if loadAddOn then
		pcall(CallBlizzardFunction, loadAddOn, "Blizzard_RecruitAFriend")
	end

	return RecruitAFriendFrame and RecruitAFriendRewardsFrame and RecruitAFriendRecruitmentFrame
end

local function ClickNativeRAFButton(button, fallbackMixin)
	if not button then
		return false
	end

	local onClick = button.OnClick or (fallbackMixin and fallbackMixin.OnClick)
	if not onClick then
		return false
	end

	CallBlizzardMethod(button, onClick)
	return true
end

local nativeRewardsState = {
	rafInfo = nil,
	selectedRAFVersion = nil,
}
local nativeRewardTabHooks = setmetatable({}, { __mode = "k" })
local SelectNativeRewardVersion

local function GetNativeRewardVersionInfo(rafInfo, rafVersion)
	if not rafInfo or not rafInfo.versions then
		return nil
	end

	for _, versionInfo in ipairs(rafInfo.versions) do
		if versionInfo.rafVersion == rafVersion then
			return versionInfo
		end
	end

	return nil
end

local function GetNativeLatestRewardVersion(rafInfo)
	local latestVersionInfo = rafInfo and rafInfo.versions and rafInfo.versions[1]
	return latestVersionInfo and latestVersionInfo.rafVersion
end

local function IsNativeLegacyRewardVersion(rafInfo, rafVersion)
	return rafVersion ~= GetNativeLatestRewardVersion(rafInfo)
end

local function RefreshNativeRewardTabs()
	local rewardsFrame = RecruitAFriendRewardsFrame
	local rewardTabPool = rewardsFrame and rewardsFrame.rewardTabPool
	local rafInfo = nativeRewardsState.rafInfo
	if not rewardTabPool or not rafInfo then
		return
	end

	for rewardTab in rewardTabPool:EnumerateActive() do
		local selected = rewardTab.rafVersion == nativeRewardsState.selectedRAFVersion
		rewardTab:SetChecked(selected)

		if rewardTab.UnclaimedRewardsAnim then
			local versionInfo = GetNativeRewardVersionInfo(rafInfo, rewardTab.rafVersion)
			local canClaimNextReward = versionInfo and versionInfo.nextReward and versionInfo.nextReward.canClaim
			rewardTab.UnclaimedRewardsAnim:SetPlaying(
				not selected and IsNativeLegacyRewardVersion(rafInfo, rewardTab.rafVersion) and canClaimNextReward
			)
		end
	end
end

local function UpdateNativeRewardsBackground(rewardsFrame, selectedRAFVersion)
	if not rewardsFrame or not rewardsFrame.Background or not RAFUtil then
		return
	end

	local useLegacyArt = RAFUtil.DoesRAFVersionUseLegacyArt
		and RAFUtil.DoesRAFVersionUseLegacyArt(selectedRAFVersion)
	local atlas = useLegacyArt and rewardsFrame.legacyBackgroundAtlas or rewardsFrame.backgroundAtlas
	if atlas then
		local useAtlasSize = TextureKitConstants and TextureKitConstants.UseAtlasSize
		rewardsFrame.Background:SetAtlas(atlas, useAtlasSize)
	end

	if SetupTextureKitOnRegions and RAFUtil.GetTextureKitForRAFVersion then
		local textureKitRegions = {
			Watermark = "recruitafriend_%s_iwatermark_big",
		}
		local setVisibility = TextureKitConstants and TextureKitConstants.SetVisibility
		local useAtlasSize = TextureKitConstants and TextureKitConstants.UseAtlasSize
		SetupTextureKitOnRegions(
			RAFUtil.GetTextureKitForRAFVersion(selectedRAFVersion),
			rewardsFrame,
			textureKitRegions,
			setVisibility,
			useAtlasSize
		)
	end
end

local function UpdateNativeRewardsList(rewardsFrame, rewards)
	if not rewardsFrame or not rewardsFrame.rewardPool then
		return
	end

	rewardsFrame.rewardPool:ReleaseAll()
	if not rewards then
		return
	end

	local lastRewardFrame
	for index, rewardInfo in ipairs(rewards) do
		if index > 13 then
			return
		end

		local leftColumnStartIndex = 1
		local rightColumnStartIndex = leftColumnStartIndex + (#rewards - 1) / 2
		local finalRewardIndex = #rewards
		local rewardFrame = rewardsFrame.rewardPool:Acquire()

		if index == leftColumnStartIndex then
			rewardFrame:SetPoint("TOPLEFT", rewardsFrame.Background, "TOPLEFT", 69, -98)
		elseif index == rightColumnStartIndex then
			rewardFrame:SetPoint("TOPLEFT", rewardsFrame.Background, "TOPLEFT", 209, -98)
		elseif index == finalRewardIndex then
			rewardFrame:SetPoint("BOTTOM", rewardsFrame.Background, "BOTTOM", 0, 44)
		else
			rewardFrame:SetPoint("TOPLEFT", lastRewardFrame, "BOTTOMLEFT", 0, -9)
		end

		local tooltipRightAligned = index >= rightColumnStartIndex and index < finalRewardIndex
		if rewardFrame.Setup then
			CallBlizzardMethod(rewardFrame, rewardFrame.Setup, rewardInfo, tooltipRightAligned)
		end

		lastRewardFrame = rewardFrame
	end
end

local function RefreshNativeRewardsFrame()
	local rewardsFrame = RecruitAFriendRewardsFrame
	local rafInfo = nativeRewardsState.rafInfo
	local selectedRAFVersion = nativeRewardsState.selectedRAFVersion
	local selectedVersionInfo = GetNativeRewardVersionInfo(rafInfo, selectedRAFVersion)
	if not rewardsFrame or not selectedVersionInfo then
		return false
	end

	if SideDressUpFrame and CloseSideDressUpFrame then
		CloseSideDressUpFrame(rewardsFrame)
	end

	UpdateNativeRewardsBackground(rewardsFrame, selectedRAFVersion)

	if rewardsFrame.Description then
		local description = IsNativeLegacyRewardVersion(rafInfo, selectedRAFVersion)
			and RAF_LEGACY_REWARDS_DESC
			or RAF_REWARDS_DESC
		rewardsFrame.Description:SetText(description or "")
	end

	UpdateNativeRewardsList(rewardsFrame, selectedVersionInfo.rewards)

	if rewardsFrame.ClaimLegacyRewardsButton and rewardsFrame.ClaimLegacyRewardsButton.Update then
		CallBlizzardMethod(
			rewardsFrame.ClaimLegacyRewardsButton,
			rewardsFrame.ClaimLegacyRewardsButton.Update,
			selectedVersionInfo,
			rafInfo.claimInProgress
		)
	end

	if rewardsFrame.Layout then
		CallBlizzardMethod(rewardsFrame, rewardsFrame.Layout)
	end

	if SetUpSideDressUpFrame then
		SetUpSideDressUpFrame(rewardsFrame, 500, 682, "TOPLEFT", "TOPRIGHT", -5, -2)
	end

	RefreshNativeRewardTabs()
	return true
end

function SelectNativeRewardVersion(rafVersion)
	if not nativeRewardsState.rafInfo or not GetNativeRewardVersionInfo(nativeRewardsState.rafInfo, rafVersion) then
		return false
	end

	nativeRewardsState.selectedRAFVersion = rafVersion
	return RefreshNativeRewardsFrame()
end

local function IsBetterFriendlistRewardsContext()
	return BetterFriendsFrame
		and BetterFriendsFrame:IsShown()
		and BetterFriendsFrame.RecruitAFriendFrame
		and BetterFriendsFrame.RecruitAFriendFrame:IsShown()
end

local function HookNativeRewardTabs()
	local rewardsFrame = RecruitAFriendRewardsFrame
	local rewardTabPool = rewardsFrame and rewardsFrame.rewardTabPool
	if not rewardTabPool then
		return false
	end

	for rewardTab in rewardTabPool:EnumerateActive() do
		if not nativeRewardTabHooks[rewardTab] then
			rewardTab:HookScript("OnClick", function(tab)
				if RecruitAFriendRewardsFrame and RecruitAFriendRewardsFrame:IsShown() and IsBetterFriendlistRewardsContext() then
					SelectNativeRewardVersion(tab.rafVersion)
				end
			end)
			nativeRewardTabHooks[rewardTab] = true
		end
	end

	return true
end

local function PrepareNativeRewardsFrame(resetToLatest)
	if not LoadBlizzardRecruitAFriend() or not C_RecruitAFriend or not RecruitAFriendRewardsFrame then
		return false
	end

	local rafInfo = C_RecruitAFriend.GetRAFInfo and C_RecruitAFriend.GetRAFInfo() or RecruitAFriendFrame and RecruitAFriendFrame.rafInfo
	if not rafInfo or not rafInfo.versions or #rafInfo.versions == 0 then
		return false
	end

	nativeRewardsState.rafInfo = rafInfo
	if resetToLatest or not GetNativeRewardVersionInfo(rafInfo, nativeRewardsState.selectedRAFVersion) then
		nativeRewardsState.selectedRAFVersion = GetNativeLatestRewardVersion(rafInfo)
	end

	local refreshed = RefreshNativeRewardsFrame()
	HookNativeRewardTabs()
	return refreshed
end

local function GetNextRewardDisplayName(nextReward, fallback)
	if not nextReward or IsSecret(nextReward) then
		return fallback
	end

	if nextReward.petInfo and not IsSecret(nextReward.petInfo) and nextReward.petInfo.speciesName then
		return nextReward.petInfo.speciesName
	end

	if nextReward.mountInfo and not IsSecret(nextReward.mountInfo) and nextReward.mountInfo.mountID then
		if C_MountJournal and C_MountJournal.GetMountInfoByID then
			local mountName = C_MountJournal.GetMountInfoByID(nextReward.mountInfo.mountID)
			if mountName then
				return mountName
			end
		end
	end

	if nextReward.titleInfo and not IsSecret(nextReward.titleInfo) and nextReward.titleInfo.titleMaskID then
		local titleName = TitleUtil
			and TitleUtil.GetNameFromTitleMaskID
			and TitleUtil.GetNameFromTitleMaskID(nextReward.titleInfo.titleMaskID)
		if titleName then
			local fmtStr = RAF_REWARD_TITLE or L.RAF_REWARD_TITLE_FMT or "Title: %s"
			return fmtStr:format(titleName)
		end
	end

	local itemID = SafeNumber(nextReward.itemID, 0) or 0
	if itemID > 0 and C_Item and C_Item.GetItemInfo then
		local itemName = C_Item.GetItemInfo(itemID)
		if itemName then
			return itemName
		end
	end

	if Enum and Enum.RafRewardType and nextReward.rewardType == Enum.RafRewardType.GameTime then
		return RAF_BENEFIT4 or L.RAF_REWARD_GAMETIME or fallback
	end

	return fallback
end

local function GetVisibleNextRewardName(frame)
	local text = frame
		and frame.RewardClaiming
		and frame.RewardClaiming.NextRewardName
		and frame.RewardClaiming.NextRewardName.Text
	if text and text.GetText then
		local rewardName = text:GetText()
		if rewardName and rewardName ~= "" then
			return rewardName
		end
	end
	return nil
end

local function IsNextRewardDressupReward(nextReward)
	if not nextReward or IsSecret(nextReward) then
		return false
	end

	if nextReward.petInfo and not IsSecret(nextReward.petInfo) then
		return (SafeNumber(nextReward.petInfo.displayID, 0) or 0) > 0
	end

	if nextReward.mountInfo and not IsSecret(nextReward.mountInfo) then
		return (SafeNumber(nextReward.mountInfo.mountID, 0) or 0) > 0
	end

	return (nextReward.appearanceInfo ~= nil and not IsSecret(nextReward.appearanceInfo))
		or (nextReward.appearanceSetInfo ~= nil and not IsSecret(nextReward.appearanceSetInfo))
		or (nextReward.illusionInfo ~= nil and not IsSecret(nextReward.illusionInfo))
end

local function SafeBattleTagName(battleTag, fallback)
	if IsSecret(battleTag) then
		return fallback or "Unknown"
	end
	if BNet_GetTruncatedBattleTag and battleTag then
		return BNet_GetTruncatedBattleTag(battleTag)
	end
	return battleTag or fallback or "Unknown"
end

local function GetSafeLastOnlineText(lastOnlineTime)
	lastOnlineTime = SafeNumber(lastOnlineTime, 0) or 0
	if lastOnlineTime == 0 or (HasTimePassed and HasTimePassed(lastOnlineTime, SECONDS_PER_YEAR)) then
		return FRIENDS_LIST_OFFLINE or L.RAF_OFFLINE
	end
	if FriendsFrame_GetLastOnline and BNET_LAST_ONLINE_TIME then
		return string.format(BNET_LAST_ONLINE_TIME, FriendsFrame_GetLastOnline(lastOnlineTime))
	end
	return L.RAF_OFFLINE
end

local function CopyRecruitActivity(activityInfo)
	if not activityInfo or IsSecret(activityInfo) then
		return nil
	end

	return {
		activityID = SafeNumber(activityInfo.activityID, 0) or 0,
		rewardQuestID = SafeNumber(activityInfo.rewardQuestID, 0) or 0,
		state = SafeNumber(activityInfo.state, 0) or 0,
	}
end

local function CopyRecruitActivities(activities)
	local displayActivities = {}
	if not activities or IsSecret(activities) then
		return displayActivities
	end

	for i = 1, #activities do
		local activityInfo = CopyRecruitActivity(activities[i])
		if activityInfo then
			displayActivities[#displayActivities + 1] = activityInfo
		end
	end

	return displayActivities
end

local function CreateRecruitDisplayRecord(recruitInfo)
	if not recruitInfo or IsSecret(recruitInfo) then
		return nil
	end

	local battleTag = SafeString(recruitInfo.battleTag, "") or ""
	local nameText = SafeBattleTagName(battleTag)

	return {
		bnetAccountID = SafeNumber(recruitInfo.bnetAccountID, 0) or 0,
		wowAccountGUID = SafeString(recruitInfo.wowAccountGUID, "") or "",
		battleTag = battleTag,
		monthsRemaining = SafeNumber(recruitInfo.monthsRemaining, 0) or 0,
		subStatus = SafeNumber(recruitInfo.subStatus, 0) or 0,
		acceptanceID = SafeNumber(recruitInfo.acceptanceID, 0) or 0,
		versionRecruited = SafeNumber(recruitInfo.versionRecruited, 0) or 0,
		activities = CopyRecruitActivities(recruitInfo.activities),
		isOnline = false,
		nameText = nameText,
		plainName = nameText,
		nameColor = FRIENDS_GRAY_COLOR,
		lastOnlineText = L.RAF_OFFLINE,
		contextGuid = nil,
	}
end

-- Current search text for filtering
RAF.searchText = ""

--------------------------------------------------------------------------
-- RAF Frame Initialization and Event Handling
--------------------------------------------------------------------------

function RAF:OnLoad(frame)
	-- Classic Guard: RAF is Retail-only
	if BFL.IsClassic or not BFL.HasRAF then
		-- BFL:DebugPrint("|cffffcc00BFL RAF:|r Not available in Classic - module disabled")
		if frame then
			frame:Hide()
		end
		return
	end

	if not C_RecruitAFriend then
		-- BFL:DebugPrint("BetterFriendlist: RAF system not available")
		return
	end

	-- Check if RAF is enabled. 12.1 replaced IsEnabled() with system status APIs.
	frame.rafEnabled = BFL.IsRAFSystemEnabled and BFL.IsRAFSystemEnabled() or false
	frame.rafRecruitingEnabled = C_RecruitAFriend.IsRecruitingEnabled and C_RecruitAFriend.IsRecruitingEnabled()
		or false

	-- Unregister existing events to prevent duplicates
	frame:UnregisterAllEvents()

	-- Register events
	frame:RegisterEvent("RAF_SYSTEM_ENABLED_STATUS")
	frame:RegisterEvent("RAF_RECRUITING_ENABLED_STATUS")
	frame:RegisterEvent("RAF_SYSTEM_INFO_UPDATED")
	frame:RegisterEvent("RAF_INFO_UPDATED")
	frame:RegisterEvent("BN_FRIEND_INFO_CHANGED")

	-- Set up no recruits text (use Blizzard global)
	if frame.RecruitList and frame.RecruitList.NoRecruitsDesc then
		frame.RecruitList.NoRecruitsDesc:SetText(RAF_NO_RECRUITS_DESC or L.RAF_NO_RECRUITS_DESC)
	end

	-- Set up ScrollBox (Retail) or FauxScrollFrame (Classic)
	if frame.RecruitList and frame.RecruitList.ScrollBox and frame.RecruitList.ScrollBar then
		-- Classic: Use FauxScrollFrame approach
		if BFL.IsClassic or not BFL.HasModernScrollBox then
			-- BFL:DebugPrint("|cff00ffffRAF:|r Using Classic FauxScrollFrame mode")
			self:InitializeClassicRAF(frame)
		else
			-- Retail: Use ScrollBox
			-- BFL:DebugPrint("|cff00ffffRAF:|r Using Retail ScrollBox mode")
			local view = CreateScrollBoxListLinearView()
			view:SetElementExtentCalculator(function(dataIndex, elementData)
				return elementData.isDivider and DIVIDER_HEIGHT or RECRUIT_HEIGHT
			end)
			view:SetElementInitializer("BetterRecruitListButtonTemplate", function(button, elementData)
				BetterRecruitListButton_Init(button, elementData)
			end)
			BFL.InitScrollBoxListWithScrollBar(frame.RecruitList.ScrollBox, frame.RecruitList.ScrollBar, view)
		end
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

-- Initialize Classic RAF FauxScrollFrame
function RAF:InitializeClassicRAF(frame)
	self.classicRAFFrame = frame
	self.classicRAFButtonPool = {}
	self.classicRAFDataList = {}

	local NUM_BUTTONS = 8

	-- Create buttons for Classic mode
	for i = 1, NUM_BUTTONS do
		local button =
			CreateFrame("Button", "BetterRecruitListButton" .. i, frame.RecruitList, "BetterRecruitListButtonTemplate")
		button:SetPoint("TOPLEFT", frame.RecruitList, "TOPLEFT", 5, -((i - 1) * RECRUIT_HEIGHT) - 5)
		button:SetPoint("RIGHT", frame.RecruitList, "RIGHT", -27, 0)
		button:SetHeight(RECRUIT_HEIGHT)
		button.classicIndex = i
		button:Hide()
		self.classicRAFButtonPool[i] = button
	end

	-- Create scroll bar
	if not frame.RecruitList.ClassicScrollBar then
		local scrollBar = CreateFrame("Slider", "BetterRAFScrollBar", frame.RecruitList, "UIPanelScrollBarTemplate")
		scrollBar:SetPoint("TOPRIGHT", frame.RecruitList, "TOPRIGHT", -4, -16)
		scrollBar:SetPoint("BOTTOMRIGHT", frame.RecruitList, "BOTTOMRIGHT", -4, 16)
		scrollBar:SetMinMaxValues(0, 0)
		scrollBar:SetValue(0)
		scrollBar:SetScript("OnValueChanged", function(self, value)
			RAF:RenderClassicRAFButtons()
		end)
		frame.RecruitList.ClassicScrollBar = scrollBar
	end
end

-- Render Classic RAF buttons
function RAF:RenderClassicRAFButtons()
	if not self.classicRAFButtonPool then
		return
	end

	local dataList = self.classicRAFDataList or {}
	local numItems = #dataList
	local numButtons = #self.classicRAFButtonPool
	local offset = 0

	if
		self.classicRAFFrame
		and self.classicRAFFrame.RecruitList
		and self.classicRAFFrame.RecruitList.ClassicScrollBar
	then
		offset = math.floor(self.classicRAFFrame.RecruitList.ClassicScrollBar:GetValue() or 0)
	end

	-- Update scroll bar range
	if self.classicRAFFrame and self.classicRAFFrame.RecruitList.ClassicScrollBar then
		local maxValue = math.max(0, numItems - numButtons)
		self.classicRAFFrame.RecruitList.ClassicScrollBar:SetMinMaxValues(0, maxValue)
	end

	-- Render buttons
	for i, button in ipairs(self.classicRAFButtonPool) do
		local dataIndex = offset + i
		if dataIndex <= numItems then
			local elementData = dataList[dataIndex]
			BetterRecruitListButton_Init(button, elementData)
			button:Show()
		else
			button:Hide()
		end
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

-- Pre-sort recruits that share a bnetAccountID by wowAccountGUID (consistent order)
-- Matches Blizzard's SortRecruitsByWoWAccount
local function SortRecruitsByWoWAccount(a, b)
	if a.bnetAccountID == b.bnetAccountID then
		return tostring(a.wowAccountGUID or "") < tostring(b.wowAccountGUID or "")
	end

	return (a.bnetAccountID or 0) < (b.bnetAccountID or 0)
end

-- Process and sort recruits with divider logic
local function ProcessAndSortRecruits(recruits)
	local displayRecruits = {}
	local seenAccounts = {}
	local haveOnlineFriends = false
	local haveOfflineFriends = false

	for _, recruitInfo in ipairs(recruits or {}) do
		local displayRecruit = CreateRecruitDisplayRecord(recruitInfo)
		if displayRecruit then
			displayRecruits[#displayRecruits + 1] = displayRecruit
		end
	end

	-- First, sort copied recruits that share a bnetAccountID by wowAccountGUID
	table.sort(displayRecruits, SortRecruitsByWoWAccount)

	-- Get account info for all recruits
	for _, recruitInfo in ipairs(displayRecruits) do
		if C_BattleNet and C_BattleNet.GetAccountInfoByID then
			local accountInfo = C_BattleNet.GetAccountInfoByID(recruitInfo.bnetAccountID, recruitInfo.wowAccountGUID)
			local gameAccountInfo
			if accountInfo and not IsSecret(accountInfo) then
				gameAccountInfo = accountInfo.gameAccountInfo
				if IsSecret(gameAccountInfo) then
					gameAccountInfo = nil
				end
			end
			local isWowMobile = gameAccountInfo and SafeBool(gameAccountInfo.isWowMobile, false)

			if accountInfo and gameAccountInfo and not isWowMobile then
				local accountBattleTag = SafeString(accountInfo.battleTag, recruitInfo.battleTag)
				local accountName = SafeString(accountInfo.accountName, nil)
				local characterName = SafeString(gameAccountInfo.characterName, nil)
				local clientProgram = SafeString(gameAccountInfo.clientProgram, nil)
				local timerunningSeasonID = SafeNumber(gameAccountInfo.timerunningSeasonID, nil)

				recruitInfo.isOnline = SafeBool(gameAccountInfo.isOnline, false)
				recruitInfo.characterName = characterName
				recruitInfo.lastOnlineText = GetSafeLastOnlineText(accountInfo.lastOnlineTime)
				recruitInfo.contextGuid = SafeString(gameAccountInfo.playerGuid, nil)

				-- [STREAMER MODE CHECK] Use safe name instead of Real ID
				if BFL.StreamerMode and BFL.StreamerMode:IsActive() then
					local FL = BFL:GetModule("FriendsList")
					if FL then
						local friendObj = {
							type = "bnet",
							accountName = accountName,
							battleTag = accountBattleTag,
							note = SafeString(accountInfo.note, nil),
							uid = tostring(recruitInfo.bnetAccountID),
						}
						local safeName = FL:GetDisplayName(friendObj)
						recruitInfo.nameText = safeName
						recruitInfo.nameColor = FRIENDS_BNET_NAME_COLOR
					else
						recruitInfo.nameText = accountBattleTag or "Unknown"
						recruitInfo.nameColor = FRIENDS_BNET_NAME_COLOR
					end
					recruitInfo.plainName = recruitInfo.nameText
				else
					local nameText = BFL:GetSafeAccountName(accountName, accountBattleTag)
					if characterName and characterName ~= "" and FriendsFrame_GetFormattedCharacterName then
						local formattedCharacterName =
							FriendsFrame_GetFormattedCharacterName(characterName, nil, clientProgram, timerunningSeasonID)
						if formattedCharacterName and formattedCharacterName ~= "" then
							nameText = nameText
								.. " "
								.. (FRIENDS_WOW_NAME_COLOR_CODE or "")
								.. "("
								.. formattedCharacterName
								.. ")"
								.. (FONT_COLOR_CODE_CLOSE or "")
						end
					end

					recruitInfo.nameText = nameText
					if recruitInfo.isOnline then
						recruitInfo.nameColor = FRIENDS_BNET_NAME_COLOR
					else
						recruitInfo.nameColor = FRIENDS_GRAY_COLOR
					end
					recruitInfo.plainName = BFL:GetSafeAccountName(accountName, accountBattleTag)
				end
			else
				-- No presence info yet
				recruitInfo.isOnline = false
				recruitInfo.nameText = SafeBattleTagName(recruitInfo.battleTag)
				recruitInfo.plainName = recruitInfo.nameText
				recruitInfo.nameColor = FRIENDS_GRAY_COLOR
				recruitInfo.lastOnlineText = L.RAF_OFFLINE
				recruitInfo.contextGuid = nil
			end
		end

		-- Handle pending recruits (use Blizzard global)
		if recruitInfo.nameText == "" then
			recruitInfo.nameText = RAF_PENDING_RECRUIT or "Pending Recruit"
			recruitInfo.plainName = recruitInfo.nameText
		end

		recruitInfo.accountInfo = nil

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

	-- Append recruit index for multiple accounts (use Blizzard global)
	for _, recruitInfo in ipairs(displayRecruits) do
		if seenAccounts[recruitInfo.bnetAccountID] > 1 and not recruitInfo.characterName then
			local fmtStr = RAF_RECRUIT_NAME_MULTIPLE or "%s (%d)"
			recruitInfo.nameText = fmtStr:format(recruitInfo.nameText, recruitInfo.recruitIndex)
		end
	end

	-- Sort by online status, version, and name
	table.sort(displayRecruits, SortRecruits)

	return displayRecruits, haveOnlineFriends and haveOfflineFriends
end

function RAF:UpdateRecruitList(frame, recruits)
	if not frame or not frame.RecruitList then
		return
	end

	local numRecruits = recruits and #recruits or 0

	-- Show/hide no recruits message
	if frame.RecruitList.NoRecruitsDesc then
		frame.RecruitList.NoRecruitsDesc:SetShown(numRecruits == 0)
	end

	-- Update header count (use Blizzard global RAF_RECRUITED_FRIENDS_COUNT)
	if frame.RecruitList.Header and frame.RecruitList.Header.Count then
		local fmtStr = RAF_RECRUITED_FRIENDS_COUNT or "%d/%d"
		frame.RecruitList.Header.Count:SetText(fmtStr:format(numRecruits, maxRecruits))
	end

	-- Process and sort recruits
	local displayRecruits, needDivider = ProcessAndSortRecruits(recruits)

	-- Apply search filter if active
	if self.searchText and self.searchText ~= "" then
		local searchNormalized = BFL:StripAccents(self.searchText)
		local filtered = {}
		for _, recruit in ipairs(displayRecruits) do
			if self:MatchesSearch(recruit, searchNormalized) then
				filtered[#filtered + 1] = recruit
			end
		end
		displayRecruits = filtered

		-- Recalculate divider need after filtering
		local haveOnline, haveOffline = false, false
		for _, r in ipairs(displayRecruits) do
			if r.isOnline then
				haveOnline = true
			else
				haveOffline = true
			end
		end
		needDivider = haveOnline and haveOffline
	end

	-- Build data list with divider
	local dataList = {}
	for index = 1, #displayRecruits do
		local recruit = displayRecruits[index]
		if needDivider and not recruit.isOnline then
			table.insert(dataList, { isDivider = true })
			needDivider = false
		end
		table.insert(dataList, recruit)
	end

	-- Classic mode: Use simple list and render
	if BFL.IsClassic or not BFL.HasModernScrollBox then
		self.classicRAFDataList = dataList
		self:RenderClassicRAFButtons()
		return
	end

	-- Retail: Update ScrollBox with DataProvider
	if frame.RecruitList.ScrollBox then
		local dataProvider = CreateDataProvider()
		for _, data in ipairs(dataList) do
			dataProvider:Insert(data)
		end
		frame.RecruitList.ScrollBox:SetDataProvider(dataProvider, ScrollBoxConstants.RetainScrollPosition)
	end
end

--------------------------------------------------------------------------
-- Reward Display Management
--------------------------------------------------------------------------

function RAF:UpdateNextReward(frame, nextReward)
	if not frame or not frame.RewardClaiming then
		return
	end

	local rewardPanel = frame.RewardClaiming

	if not nextReward then
		if rewardPanel.EarnInfo then
			rewardPanel.EarnInfo:Hide()
		end
		if rewardPanel.NextRewardButton then
			rewardPanel.NextRewardButton:Hide()
		end
		if rewardPanel.NextRewardName then
			rewardPanel.NextRewardName:Hide()
		end
		return
	end

	-- Set earn info text (using Blizzard globals)
	if rewardPanel.EarnInfo then
		local earnText = ""
		if nextReward.canClaim then
			earnText = RAF_YOU_HAVE_EARNED or L.RAF_YOU_HAVE_EARNED or ""
		elseif nextReward.monthCost and nextReward.monthCost > 1 then
			local fmtStr = RAF_NEXT_REWARD_AFTER or L.RAF_NEXT_REWARD_AFTER or "%d/%d"
			earnText = fmtStr:format(nextReward.monthCost - nextReward.availableInMonths, nextReward.monthCost)
		elseif nextReward.monthsRequired == 0 then
			earnText = RAF_FIRST_REWARD or L.RAF_FIRST_REWARD or ""
		else
			earnText = RAF_NEXT_REWARD or L.RAF_NEXT_REWARD or ""
		end
		rewardPanel.EarnInfo:SetText(earnText)
		rewardPanel.EarnInfo:Show()
	end

	-- Set reward icon
	if rewardPanel.NextRewardButton and nextReward.iconID then
		-- Apply circular mask (only once)
		if not rewardPanel.NextRewardButton.maskApplied then
			if
				rewardPanel.NextRewardButton.Icon
				and rewardPanel.NextRewardButton.IconOverlay
				and rewardPanel.NextRewardButton.CircleMask
			then
				rewardPanel.NextRewardButton.Icon:AddMaskTexture(rewardPanel.NextRewardButton.CircleMask)
				rewardPanel.NextRewardButton.IconOverlay:AddMaskTexture(rewardPanel.NextRewardButton.CircleMask)
				rewardPanel.NextRewardButton.maskApplied = true
			end
		end

		rewardPanel.NextRewardButton.Icon:SetTexture(nextReward.iconID)

		-- Match Blizzard's three-condition desaturation logic
		local shouldDesaturate = not nextReward.claimed
			and not nextReward.canClaim
			and not (nextReward.canAfford or false)
		rewardPanel.NextRewardButton.Icon:SetDesaturated(shouldDesaturate)
		rewardPanel.NextRewardButton.IconOverlay:SetShown(shouldDesaturate)
		if rewardPanel.NextRewardButton.IconBorder and rewardPanel.NextRewardButton.IconBorder.SetAtlas then
			local borderAtlas = (not nextReward.claimed and not nextReward.canClaim)
				and "RecruitAFriend_ClaimPane_SepiaRing"
				or "RecruitAFriend_ClaimPane_GoldRing"
			rewardPanel.NextRewardButton.IconBorder:SetAtlas(borderAtlas, true)
		end
		rewardPanel.NextRewardButton:Show()
	end

	-- Set reward name (matching Blizzard's SetNextRewardName logic with repeatableClaimCount)
	if rewardPanel.NextRewardName and rewardPanel.NextRewardName.Text then
		local rewardName = ""
		local repeatCount = nextReward.repeatableClaimCount or 1

		if nextReward.petInfo and nextReward.petInfo.speciesName then
			rewardName = nextReward.petInfo.speciesName
		elseif nextReward.mountInfo and nextReward.mountInfo.mountID then
			rewardName = C_MountJournal.GetMountInfoByID
					and C_MountJournal.GetMountInfoByID(nextReward.mountInfo.mountID)
				or "Mount"
		elseif nextReward.titleInfo and nextReward.titleInfo.titleMaskID then
			local titleName = TitleUtil
				and TitleUtil.GetNameFromTitleMaskID
				and TitleUtil.GetNameFromTitleMaskID(nextReward.titleInfo.titleMaskID)
			if titleName then
				local fmtStr = RAF_REWARD_TITLE or L.RAF_REWARD_TITLE_FMT or "Title: %s"
				rewardName = fmtStr:format(titleName)
			end
		elseif nextReward.appearanceInfo or nextReward.appearanceSetInfo or nextReward.illusionInfo then
			-- Appearance-based rewards: try to get name from item
			if nextReward.itemID and nextReward.itemID > 0 then
				local item = Item:CreateFromItemID(nextReward.itemID)
				if item then
					item:ContinueOnItemLoad(function()
						local itemName = item:GetItemName()
						if itemName and rewardPanel.NextRewardName and rewardPanel.NextRewardName.Text then
							self:SetNextRewardNameText(rewardPanel, itemName, repeatCount, nextReward.rewardType)
						end
					end)
				end
			end
		else
			-- Game time (use Blizzard global RAF_BENEFIT4)
			rewardName = RAF_BENEFIT4 or L.RAF_REWARD_GAMETIME or "Game Time"
		end

		self:SetNextRewardNameText(rewardPanel, rewardName, repeatCount, nextReward.rewardType)
	end
end

-- Helper: Set the reward name text with count and color (matches Blizzard's SetNextRewardName)
function RAF:SetNextRewardNameText(rewardPanel, rewardName, count, rewardType)
	if not rewardPanel or not rewardPanel.NextRewardName or not rewardPanel.NextRewardName.Text then
		return
	end
	if not rewardName or rewardName == "" then
		return
	end

	-- Show count for repeatable rewards (matches Blizzard)
	if count and count > 1 and RAF_REWARD_NAME_MULTIPLE then
		rewardPanel.NextRewardName.Text:SetText(RAF_REWARD_NAME_MULTIPLE:format(rewardName, count))
	else
		rewardPanel.NextRewardName.Text:SetText(rewardName)
	end

	-- Set color using the same method as Blizzard
	if rewardType == Enum.RafRewardType.GameTime then
		rewardPanel.NextRewardName.Text:SetTextColor(HEIRLOOM_BLUE_COLOR:GetRGBA())
	else
		rewardPanel.NextRewardName.Text:SetTextColor(EPIC_PURPLE_COLOR:GetRGBA())
	end

	rewardPanel.NextRewardName:Show()
end

function RAF:UpdateRAFInfo(frame, rafInfo)
	if not frame or not rafInfo then
		return
	end

	frame.rafInfo = rafInfo

	-- Store latest RAF version globally for recruit button logic
	if rafInfo.versions and #rafInfo.versions > 0 and rafInfo.versions[1] then
		latestRAFVersion = rafInfo.versions[1].rafVersion or 0
	end

	-- Update recruit list
	if rafInfo.recruits then
		self:UpdateRecruitList(frame, rafInfo.recruits)
	end

	-- Update month count (matches Blizzard's conditional logic)
	if frame.RewardClaiming and frame.RewardClaiming.MonthCount and frame.RewardClaiming.MonthCount.Text then
		local latestVersionInfo = rafInfo.versions and #rafInfo.versions > 0 and rafInfo.versions[1]
		if latestVersionInfo then
			local numRecruits = latestVersionInfo.numRecruits or 0
			local lifetimeMonths = latestVersionInfo.monthCount and latestVersionInfo.monthCount.lifetimeMonths or 0

			-- Blizzard: if no recruits and no months, show "first month" text; otherwise show earned months
			if numRecruits == 0 and lifetimeMonths == 0 then
				local firstMonthText = RAF_FIRST_MONTH or L.RAF_FIRST_MONTH or ""
				frame.RewardClaiming.MonthCount.Text:SetText(firstMonthText)
			else
				local monthsEarned = RAF_MONTHS_EARNED or L.RAF_MONTH_COUNT
				if monthsEarned then
					frame.RewardClaiming.MonthCount.Text:SetText(monthsEarned:format(lifetimeMonths))
				end
			end
			frame.RewardClaiming.MonthCount:Show()
		end
	end

	-- Update next reward
	local latestVersionInfo = rafInfo.versions and #rafInfo.versions > 0 and rafInfo.versions[1]
	if latestVersionInfo and latestVersionInfo.nextReward then
		self:UpdateNextReward(frame, latestVersionInfo.nextReward)
	end

	-- Update claim button
	if frame.RewardClaiming and frame.RewardClaiming.ClaimOrViewRewardButton then
		local nextReward = latestVersionInfo and latestVersionInfo.nextReward
		local haveUnclaimedReward = nextReward and nextReward.canClaim

		if haveUnclaimedReward then
			frame.RewardClaiming.ClaimOrViewRewardButton:SetEnabled(true)
			frame.RewardClaiming.ClaimOrViewRewardButton:SetText(CLAIM_REWARD or L.RAF_CLAIM_REWARD)
		else
			frame.RewardClaiming.ClaimOrViewRewardButton:SetEnabled(true)
			frame.RewardClaiming.ClaimOrViewRewardButton:SetText(RAF_VIEW_ALL_REWARDS or L.RAF_VIEW_ALL_REWARDS)
		end
	end
end

function RAF:ShowSplashScreen(frame)
	if not frame or not frame.SplashFrame then
		return
	end
	frame.SplashFrame:Show()
end

--------------------------------------------------------------------------
-- Search Functionality
--------------------------------------------------------------------------

-- Check if a recruit matches the search text (accent-insensitive)
function RAF:MatchesSearch(recruit, searchNormalized)
	-- Helper: check if field contains the search (accent-insensitive)
	local function contains(text)
		if text and text ~= "" then
			return BFL:StripAccents(text):find(searchNormalized, 1, true) ~= nil
		end
		return false
	end

	-- Search in name, battleTag, and character name
	return contains(recruit.nameText)
		or contains(recruit.plainName)
		or contains(recruit.battleTag)
		or contains(recruit.characterName)
end

-- Set search text and refresh the list
function RAF:SetSearchText(text, skipRefresh)
	local newText = text or ""
	if self.searchText == newText then
		return
	end
	self.searchText = newText

	if skipRefresh then
		return
	end

	-- Refresh the list with the new search filter
	local frame = BetterFriendsFrame and BetterFriendsFrame.RecruitAFriendFrame
	if frame and frame:IsShown() and frame.rafInfo and frame.rafInfo.recruits then
		self:UpdateRecruitList(frame, frame.rafInfo.recruits)
	end
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

	local versionRecruited = recruitInfo.versionRecruited or 0
	local kit = GetTextureKitForRAFVersion(versionRecruited)
	if kit and button.Icon and button.Icon.SetAtlas then
		local ok = pcall(button.Icon.SetAtlas, button.Icon, ("recruitafriend_friendslist_%s_icon"):format(kit), true)
		if ok then
			button.Icon:Show()
		else
			button.Icon:Hide()
		end
	elseif button.Icon then
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

	-- Set background color based on online status (matches Blizzard: uses RAF version color)
	if recruitInfo.isOnline then
		local versionColor = GetColorForRAFVersion(versionRecruited)
		if versionColor then
			button.Background:SetColorTexture(versionColor:GetRGBA())
		else
			button.Background:SetColorTexture(0.2, 0.4, 0.8, 0.3)
		end

		-- Set info text based on subscription status (using Blizzard globals)
		if recruitInfo.subStatus == Enum.RafRecruitSubStatus.Active then
			button.InfoText:SetText(RAF_ACTIVE_RECRUIT or L.RAF_ACTIVE_RECRUIT)
			button.InfoText:SetTextColor(GREEN_FONT_COLOR:GetRGB())
		elseif recruitInfo.subStatus == Enum.RafRecruitSubStatus.Trial then
			button.InfoText:SetText(RAF_TRIAL_RECRUIT or L.RAF_TRIAL_RECRUIT)
			button.InfoText:SetTextColor(NORMAL_FONT_COLOR:GetRGB())
		else
			button.InfoText:SetText(RAF_INACTIVE_RECRUIT or L.RAF_INACTIVE_RECRUIT)
			button.InfoText:SetTextColor(GRAY_FONT_COLOR:GetRGB())
		end
	else
		button.Background:SetColorTexture(FRIENDS_OFFLINE_BACKGROUND_COLOR:GetRGBA())
		button.InfoText:SetTextColor(GRAY_FONT_COLOR:GetRGB())

		if recruitInfo.subStatus == Enum.RafRecruitSubStatus.Inactive then
			button.InfoText:SetText(RAF_INACTIVE_RECRUIT or L.RAF_INACTIVE_RECRUIT)
		else
			button.InfoText:SetText(recruitInfo.lastOnlineText or L.RAF_OFFLINE)
		end
	end

	-- Update activities (always process all activity buttons to ensure they're hidden when no activities)
	if button.Activities then
		for i = 1, #button.Activities do
			if button.Activities[i] then
				local activityInfo = recruitInfo.activities and recruitInfo.activities[i] or nil
				self:RecruitActivityButton_Setup(button.Activities[i], activityInfo, recruitInfo)
			end
		end
	end

	button:Show()
end

function RAF:RecruitListButton_OnEnter(button)
	if not button.recruitInfo then
		return
	end

	local recruitInfo = button.recruitInfo
	BFL_Tooltip:SetOwner(button, "ANCHOR_RIGHT")

	if recruitInfo.nameText and recruitInfo.nameColor then
		GameTooltip_SetTitle(BFL_Tooltip, recruitInfo.nameText, recruitInfo.nameColor)
	end

	-- Use Blizzard globals (matches Blizzard exactly)
	local wrap = true
	local tooltipDesc = RAF_RECRUIT_TOOLTIP_DESC or L.RAF_TOOLTIP_DESC
	if maxRecruitMonths > 0 and tooltipDesc then
		GameTooltip_AddNormalLine(BFL_Tooltip, tooltipDesc:format(maxRecruitMonths), wrap)
		GameTooltip_AddBlankLineToTooltip(BFL_Tooltip)
	end

	if recruitInfo.monthsRemaining then
		local usedMonths = math.max(maxRecruitMonths - recruitInfo.monthsRemaining, 0)
		local monthCountFmt = RAF_RECRUIT_TOOLTIP_MONTH_COUNT or L.RAF_TOOLTIP_MONTH_COUNT
		if monthCountFmt then
			GameTooltip_AddColoredLine(
				BFL_Tooltip,
				monthCountFmt:format(usedMonths, maxRecruitMonths),
				HIGHLIGHT_FONT_COLOR,
				wrap
			)
		end
	end

	BFL_Tooltip:Show()
end

function RAF:RecruitListButton_OnClick(button, mouseButton)
	if mouseButton == "RightButton" and button.recruitInfo then
		local recruitInfo = button.recruitInfo
		local contextData = {
			name = recruitInfo.plainName,
			bnetIDAccount = recruitInfo.bnetAccountID,
			wowAccountGUID = recruitInfo.wowAccountGUID,
			isRafRecruit = true,
			guid = recruitInfo.contextGuid,
		}

		-- Use compatibility wrapper for Classic support
		BFL.OpenContextMenu(button, "RAF_RECRUIT", contextData, contextData.name)
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
	if not button.activityInfo then
		return
	end

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
	if not button.activityInfo or not button.recruitInfo then
		return
	end

	if button.activityInfo.state == Enum.RafRecruitActivityState.Complete then
		if C_RecruitAFriend.ClaimActivityReward then
			if
				C_RecruitAFriend.ClaimActivityReward(button.activityInfo.activityID, button.recruitInfo.acceptanceID)
			then
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
	if not button.activityInfo or not button.recruitInfo then
		return
	end

	-- Enable highlight on parent recruit list button
	local parent = button:GetParent()
	if parent then
		parent:EnableDrawLayer("HIGHLIGHT")
	end

	-- Use EmbeddedItemTooltip to match Blizzard's RAF tooltip behavior
	local tooltip = EmbeddedItemTooltip or GameTooltip
	tooltip:SetOwner(button, "ANCHOR_RIGHT")

	local wrap = true

	-- Update quest name (cache it like Blizzard does)
	if not button.questName and button.activityInfo.rewardQuestID then
		button.questName = C_QuestLog.GetTitleForQuestID
			and C_QuestLog.GetTitleForQuestID(button.activityInfo.rewardQuestID)
	end

	self:RecruitActivityButton_UpdateIcon(button)

	if not button.questName then
		-- Data not loaded yet - show loading state (matches Blizzard)
		GameTooltip_SetTitle(tooltip, RETRIEVING_DATA or L.RAF_LOADING, RED_FONT_COLOR)
		if GameTooltip_SetTooltipWaitingForData then
			GameTooltip_SetTooltipWaitingForData(tooltip, true)
		end
		button.UpdateTooltip = function()
			RAF:RecruitActivityButton_OnEnter(button)
		end
	else
		GameTooltip_SetTitle(tooltip, button.questName, nil, wrap)
		tooltip:SetMinimumWidth(300)

		-- Activity description (Blizzard global)
		local activityDesc = RAF_RECRUIT_ACTIVITY_DESCRIPTION or L.RAF_ACTIVITY_DESCRIPTION
		if activityDesc then
			GameTooltip_AddNormalLine(tooltip, activityDesc:format(button.recruitInfo.nameText), true)
		end

		-- Requirements text
		if C_RecruitAFriend.GetRecruitActivityRequirementsText then
			local reqTextLines = C_RecruitAFriend.GetRecruitActivityRequirementsText(
				button.activityInfo.activityID,
				button.recruitInfo.acceptanceID
			)
			if reqTextLines then
				for i = 1, #reqTextLines do
					if reqTextLines[i] then
						GameTooltip_AddColoredLine(tooltip, reqTextLines[i], HIGHLIGHT_FONT_COLOR, wrap)
					end
				end
			end
		end

		GameTooltip_AddBlankLineToTooltip(tooltip)

		-- Rewards label (Blizzard globals)
		if button.activityInfo.state == Enum.RafRecruitActivityState.Incomplete then
			GameTooltip_AddNormalLine(tooltip, QUEST_REWARDS or L.RAF_REWARDS_LABEL, wrap)
		else
			GameTooltip_AddNormalLine(tooltip, YOU_EARNED_LABEL or L.RAF_YOU_EARNED_LABEL, wrap)
		end

		if GameTooltip_AddQuestRewardsToTooltip then
			GameTooltip_AddQuestRewardsToTooltip(
				tooltip,
				button.activityInfo.rewardQuestID,
				TOOLTIP_QUEST_REWARDS_STYLE_NONE
			)
		end

		if button.activityInfo.state == Enum.RafRecruitActivityState.Complete then
			GameTooltip_AddBlankLineToTooltip(tooltip)
			GameTooltip_AddInstructionLine(tooltip, CLICK_CHEST_TO_CLAIM_REWARD or L.RAF_CLICK_TO_CLAIM, wrap)
		end

		if GameTooltip_SetTooltipWaitingForData then
			GameTooltip_SetTooltipWaitingForData(tooltip, false)
		end
		button.UpdateTooltip = nil
	end

	tooltip:Show()
end

function RAF:RecruitActivityButton_OnLeave(button)
	-- Disable highlight on parent recruit list button
	local parent = button:GetParent()
	if parent then
		parent:DisableDrawLayer("HIGHLIGHT")
	end

	-- Clear UpdateTooltip callback (matches Blizzard)
	button.UpdateTooltip = nil

	-- Hide EmbeddedItemTooltip (matching OnEnter change)
	if EmbeddedItemTooltip then
		EmbeddedItemTooltip:Hide()
	end
	GameTooltip_Hide()
	RAF:RecruitActivityButton_UpdateIcon(button)
end

--------------------------------------------------------------------------
-- Next Reward Button Handlers
--------------------------------------------------------------------------

function RAF:NextRewardButton_OnClick(button, mouseButton)
	local frame = button:GetParent():GetParent()
	if not frame or not frame.rafInfo then
		return
	end

	local latestVersionInfo = frame.rafInfo.versions and #frame.rafInfo.versions > 0 and frame.rafInfo.versions[1]
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
			BFL:SecureOpenChat(link)
		end
	end
end

function RAF:NextRewardButton_OnEnter(button)
	local frame = button:GetParent():GetParent()
	if not frame or not frame.rafInfo then
		return
	end

	local latestVersionInfo = frame.rafInfo.versions and #frame.rafInfo.versions > 0 and frame.rafInfo.versions[1]
	local nextReward = latestVersionInfo and latestVersionInfo.nextReward

	if not nextReward then
		return
	end

	local tooltip = BFL_Tooltip or GameTooltip
	local itemID = SafeNumber(nextReward.itemID, 0) or 0
	local dressupReward = IsNextRewardDressupReward(nextReward)
	local itemLink
	if itemID > 0 and C_Item and C_Item.GetItemInfo then
		_, itemLink = C_Item.GetItemInfo(itemID)
	end

	tooltip:SetOwner(button, "ANCHOR_RIGHT")
	local itemTooltipSet = itemID > 0 and tooltip.SetItemByID and tooltip:SetItemByID(itemID)
	if not itemTooltipSet then
		if itemLink and tooltip.SetHyperlink then
			tooltip:SetHyperlink(itemLink)
		else
			if tooltip.ClearLines then
				tooltip:ClearLines()
			end
			local rewardName = GetNextRewardDisplayName(nextReward, GetVisibleNextRewardName(frame))
				or RAF_NEXT_REWARD
				or L.RAF_NEXT_REWARD
			GameTooltip_SetTitle(tooltip, rewardName, HIGHLIGHT_FONT_COLOR, true)
			if itemID > 0 and RETRIEVING_DATA then
				GameTooltip_AddNormalLine(tooltip, RETRIEVING_DATA, true)
			end
		end
	end
	tooltip:Show()

	if dressupReward then
		button.UpdateTooltip = function()
			RAF:NextRewardButton_OnEnter(button)
		end
	else
		button.UpdateTooltip = nil
	end

	if IsModifiedClick("DRESSUP") and dressupReward then
		ShowInspectCursor()
	else
		ResetCursor()
	end
end

function RAF:NextRewardButton_OnLeave(button)
	if button then
		button.UpdateTooltip = nil
	end
	if BFL_Tooltip then
		BFL_Tooltip:Hide()
	elseif GameTooltip_Hide then
		GameTooltip_Hide()
	end
	ResetCursor()
end

--------------------------------------------------------------------------
-- Claim/View Reward Button Handler
--------------------------------------------------------------------------

function RAF:ClaimOrViewRewardButton_OnClick(button)
	local frame = button:GetParent():GetParent()
	if not frame or not frame.rafInfo then
		return
	end

	local latestVersionInfo = frame.rafInfo.versions and #frame.rafInfo.versions > 0 and frame.rafInfo.versions[1]
	local nextReward = latestVersionInfo and latestVersionInfo.nextReward
	local haveUnclaimedReward = nextReward and nextReward.canClaim

	if haveUnclaimedReward then
		-- Claim reward
		if nextReward.rewardType == Enum.RafRewardType.GameTime then
			-- Game time requires special dialog
			PlaySound(SOUNDKIT.IG_MAINMENU_OPEN)
			if WowTokenRedemptionFrame_ShowDialog then
				WowTokenRedemptionFrame_ShowDialog(
					"RAF_GAME_TIME_REDEEM_CONFIRMATION_SUB",
					latestVersionInfo.rafVersion
				)
			else
				print("|cffFFFF00" .. L.RAF_GAME_TIME_MESSAGE .. "|r")
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
		local nativeHasRAFInfo = PrepareNativeRewardsFrame(not RecruitAFriendRewardsFrame or not RecruitAFriendRewardsFrame:IsShown())
		if RecruitAFriendRewardsFrame and nativeHasRAFInfo then
			if RecruitAFriendRewardsFrame:IsShown() then
				CallBlizzardMethod(RecruitAFriendRewardsFrame, RecruitAFriendRewardsFrame.Hide)
			else
				CallBlizzardMethod(RecruitAFriendRewardsFrame, RecruitAFriendRewardsFrame.Show)
				PrepareNativeRewardsFrame(true)
				if RecruitAFriendRecruitmentFrame and StaticPopupSpecial_Hide then
					CallBlizzardFunction(StaticPopupSpecial_Hide, RecruitAFriendRecruitmentFrame)
				end
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
	if not rafInfo or not rafInfo.versions then
		return
	end

	print("|cffFFFF00" .. L.RAF_CHAT_HEADER .. "|r")

	for versionIndex, versionInfo in ipairs(rafInfo.versions) do
		local versionName = versionIndex == 1 and L.RAF_CHAT_CURRENT_VERSION
			or L.RAF_CHAT_LEGACY_VERSION:format(versionInfo.rafVersion)
		print("|cff00ccff" .. versionName .. ":|r")
		print(L.RAF_CHAT_MONTHS_EARNED:format(versionInfo.monthCount and versionInfo.monthCount.lifetimeMonths or 0))
		print(L.RAF_CHAT_RECRUITS_COUNT:format(versionInfo.numRecruits or 0))

		if versionInfo.rewards and #versionInfo.rewards > 0 then
			print(L.RAF_CHAT_AVAILABLE_REWARDS)
			for i, reward in ipairs(versionInfo.rewards) do
				if i <= 5 then -- Show first 5 rewards
					local status = reward.claimed and L.RAF_CHAT_REWARD_CLAIMED
						or reward.canClaim and L.RAF_CHAT_REWARD_CAN_CLAIM
						or reward.canAfford and L.RAF_CHAT_REWARD_AFFORDABLE
						or L.RAF_CHAT_REWARD_LOCKED
					local rewardName = "Reward"
					if reward.petInfo then
						rewardName = reward.petInfo.speciesName or "Pet"
					elseif reward.mountInfo then
						local mountName = C_MountJournal.GetMountInfoByID
							and C_MountJournal.GetMountInfoByID(reward.mountInfo.mountID)
						rewardName = mountName or L.RAF_REWARD_MOUNT
					elseif reward.titleInfo then
						rewardName = TitleUtil.GetNameFromTitleMaskID
								and TitleUtil.GetNameFromTitleMaskID(reward.titleInfo.titleMaskID)
							or L.RAF_REWARD_TITLE_DEFAULT
					end
					print(
						"|cffe6e6e6" .. L.RAF_CHAT_REWARD_FMT:format(rewardName, status, reward.monthsRequired) .. "|r"
					)
				end
			end
			if #versionInfo.rewards > 5 then
				print("|cffb3b3b3" .. L.RAF_CHAT_MORE_REWARDS:format(#versionInfo.rewards - 5) .. "|r")
			end
		end
	end

	print("|cffFFFF00" .. L.RAF_CHAT_USE_UI .. "|r")
end

function RAF:RecruitmentButton_OnClick(button)
	if not LoadBlizzardRecruitAFriend() then
		return
	end

	local nativeButton = RecruitAFriendFrame and RecruitAFriendFrame.RecruitmentButton
	if ClickNativeRAFButton(nativeButton, RecruitAFriendRecruitmentButtonMixin) then
		return
	end

	-- Toggle recruitment frame (exact Blizzard logic)
	if RecruitAFriendRecruitmentFrame:IsShown() then
		CallBlizzardFunction(StaticPopupSpecial_Hide, RecruitAFriendRecruitmentFrame)
	else
		CallBlizzardFunction(C_RecruitAFriend.RequestUpdatedRecruitmentInfo)

		-- Hide rewards frame if shown
		if RecruitAFriendRewardsFrame then
			CallBlizzardMethod(RecruitAFriendRewardsFrame, RecruitAFriendRewardsFrame.Hide)
		end

		CallBlizzardFunction(StaticPopupSpecial_Show, RecruitAFriendRecruitmentFrame)
	end
end
