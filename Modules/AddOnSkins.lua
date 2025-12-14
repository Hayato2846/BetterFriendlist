-- Modules/AddOnSkins.lua
-- AddOnSkins Support Module for BetterFriendlist
-- Clean implementation based on AddOnSkins API

local ADDON_NAME, BFL = ...
local AddOnSkinsSupport = BFL:RegisterModule("AddOnSkinsSupport", {})

-- Forward declaration
local SkinBetterFriendlist

function AddOnSkinsSupport:Initialize()
	-- Check if AddOnSkins is loaded
	if _G.AddOnSkins then
		--self:RegisterSkin()
	end
end

function AddOnSkinsSupport:RegisterSkin()
	local AS, L, S, R = unpack(AddOnSkins)
	if not AS then return end
	
	-- 1. Register the skin
	-- We use ADDON_LOADED so AS attempts to skin when it sees us (or when we tell it we are here)
	AS:RegisterSkin('BetterFriendlist', SkinBetterFriendlist, 'ADDON_LOADED')
	-- 4. Trigger the skin immediately
	-- Since we likely loaded after AS, we need to tell it to skin us now
	AS:CallSkin('BetterFriendlist', SkinBetterFriendlist, 'ADDON_LOADED')
end

-- Helper for 11.x Dropdowns
local function SkinDropDown(S, obj, width)
	if not obj then return end
	
	-- Check for new DropdownButton intrinsic
	local isNewDropdown = false
	if obj.intrinsic and string.find(obj.intrinsic, "Dropdown") then
		isNewDropdown = true
	elseif obj:IsObjectType("Button") and not obj.Button then
		-- Heuristic: If it's a Button but doesn't have the .Button sub-frame typical of UIDropDownMenu
		isNewDropdown = true
	end
	
	if isNewDropdown then
		if S.HandleButton then S:HandleButton(obj) end
		if width then obj:SetWidth(width) end
	else
		if S.HandleDropDownBox then S:HandleDropDownBox(obj, width) end
	end
end

SkinBetterFriendlist = function(event, addon)
	-- Prevent multiple executions
	if BFL.AddOnSkinsSkinned then return end
	BFL.AddOnSkinsSkinned = true

	local AS = unpack(_G.AddOnSkins)
	local S = AS.Skins
	
	local frame = _G.BetterFriendsFrame
	if not frame then return end

	-- Main Frame
	S:HandlePortraitFrame(frame, true)
	
	-- Tabs (Top)
	for i = 1, 4 do
		local tab = _G["BetterFriendsFrameTab"..i]
		if tab then
			S:HandleTab(tab)
			tab:SetHeight(25)
			local text = tab.Text or (tab.GetFontString and tab:GetFontString())
			if text then
				text:ClearAllPoints()
				text:SetPoint("CENTER", tab, "CENTER", 0, 10)
			end
		end
	end

	-- Tabs (Bottom)
	for i = 1, 4 do
		local tab = _G["BetterFriendsFrameBottomTab"..i]
		if tab then
			S:HandleTab(tab)
			tab:SetHeight(28)
			tab:ClearAllPoints()
			if i == 1 then
				tab:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", -2, 1)
			else
				local prevTab = _G["BetterFriendsFrameBottomTab"..(i-1)]
				tab:SetPoint("LEFT", prevTab, "RIGHT", -5, 0)
			end
		end
	end

	-- Insets
	if frame.Inset then
		S:StripTextures(frame.Inset)
		S:CreateBackdrop(frame.Inset, "Transparent")
	end

	if frame.ListInset then
		S:StripTextures(frame.ListInset)
		S:CreateBackdrop(frame.ListInset, "Transparent")
	end
	
	if frame.WhoFrame and frame.WhoFrame.ListInset then
		S:StripTextures(frame.WhoFrame.ListInset)
		S:CreateBackdrop(frame.WhoFrame.ListInset, "Transparent")
	end

	-- RecruitAFriendFrame
	if frame.RecruitAFriendFrame then
		local raf = frame.RecruitAFriendFrame
		if raf.Border then S:StripTextures(raf.Border) end
		if raf.Background then raf.Background:Hide() end
		
		if raf.RewardClaiming then
			if raf.RewardClaiming.Background then raf.RewardClaiming.Background:SetAlpha(0) end
			S:CreateBackdrop(raf.RewardClaiming, "Transparent")
			if raf.RewardClaiming.ClaimOrViewRewardButton then S:HandleButton(raf.RewardClaiming.ClaimOrViewRewardButton) end
			if raf.RewardClaiming.Inset then
				S:StripTextures(raf.RewardClaiming.Inset)
				S:CreateBackdrop(raf.RewardClaiming.Inset, "Transparent")
			end
		end
		
		if raf.RecruitList then
			if raf.RecruitList.ScrollFrameInset then
				S:StripTextures(raf.RecruitList.ScrollFrameInset)
				S:CreateBackdrop(raf.RecruitList.ScrollFrameInset, "Transparent")
			end
			if raf.RecruitList.ScrollBar then S:HandleTrimScrollBar(raf.RecruitList.ScrollBar) end
		end
		
		if raf.SplashFrame then
			S:StripTextures(raf.SplashFrame)
			S:CreateBackdrop(raf.SplashFrame, "Transparent")
			if raf.SplashFrame.OKButton then S:HandleButton(raf.SplashFrame.OKButton) end
		end
	end

	-- ScrollBars
	if frame.RecentAlliesFrame and frame.RecentAlliesFrame.ScrollBar then S:HandleTrimScrollBar(frame.RecentAlliesFrame.ScrollBar) end
	if frame.MinimalScrollBar then S:HandleTrimScrollBar(frame.MinimalScrollBar)
	elseif frame.ScrollBar then S:HandleScrollBar(frame.ScrollBar) end
	if frame.WhoFrame and frame.WhoFrame.ScrollBar then S:HandleTrimScrollBar(frame.WhoFrame.ScrollBar) end
	if frame.RaidFrame and frame.RaidFrame.ScrollBar then S:HandleTrimScrollBar(frame.RaidFrame.ScrollBar) end

	-- IgnoreListWindow
	if frame.IgnoreListWindow then
		S:HandlePortraitFrame(frame.IgnoreListWindow, true)
		if frame.IgnoreListWindow.Inset then
			S:StripTextures(frame.IgnoreListWindow.Inset)
			S:CreateBackdrop(frame.IgnoreListWindow.Inset, "Transparent")
		end
		if frame.IgnoreListWindow.ScrollBar then S:HandleTrimScrollBar(frame.IgnoreListWindow.ScrollBar) end
		if frame.IgnoreListWindow.UnignorePlayerButton then S:HandleButton(frame.IgnoreListWindow.UnignorePlayerButton) end
	end

	-- Buttons
	if frame.AddFriendButton then S:HandleButton(frame.AddFriendButton) end
	if frame.SendMessageButton then S:HandleButton(frame.SendMessageButton) end
	if frame.RecruitmentButton then S:HandleButton(frame.RecruitmentButton) end

	-- WhoFrame Elements
	if frame.WhoFrame then
		if frame.WhoFrame.WhoButton then S:HandleButton(frame.WhoFrame.WhoButton) end
		if frame.WhoFrame.AddFriendButton then S:HandleButton(frame.WhoFrame.AddFriendButton) end
		if frame.WhoFrame.GroupInviteButton then S:HandleButton(frame.WhoFrame.GroupInviteButton) end
		
		if frame.WhoFrame.EditBox then 
			S:HandleEditBox(frame.WhoFrame.EditBox)
			if frame.WhoFrame.EditBox.Backdrop then 
				S:StripTextures(frame.WhoFrame.EditBox.Backdrop)
				S:CreateBackdrop(frame.WhoFrame.EditBox.Backdrop, "Transparent")
			end
		end
		
		if frame.WhoFrame.ColumnDropdown then 
			SkinDropDown(S, frame.WhoFrame.ColumnDropdown)
		end
		
		local headers = {frame.WhoFrame.NameHeader, frame.WhoFrame.LevelHeader, frame.WhoFrame.ClassHeader}
		for _, header in ipairs(headers) do
			if header then
				S:HandleButton(header)
				header:SetHeight(22)
			end
		end
	end

	-- FriendsTabHeader
	if frame.FriendsTabHeader then
		if frame.FriendsTabHeader.BattlenetFrame then
			local bnet = frame.FriendsTabHeader.BattlenetFrame
			S:StripTextures(bnet)
			S:CreateBackdrop(bnet, "Transparent")
			
			if bnet.BroadcastFrame then
				S:StripTextures(bnet.BroadcastFrame)
				S:CreateBackdrop(bnet.BroadcastFrame, "Transparent")
				if bnet.BroadcastFrame.UpdateButton then S:HandleButton(bnet.BroadcastFrame.UpdateButton) end
				if bnet.BroadcastFrame.CancelButton then S:HandleButton(bnet.BroadcastFrame.CancelButton) end
				if bnet.BroadcastFrame.EditBox then S:HandleEditBox(bnet.BroadcastFrame.EditBox) end
			end
			
			if bnet.ContactsMenuButton then S:HandleButton(bnet.ContactsMenuButton) end
		end
		
		if frame.FriendsTabHeader.SearchBox then S:HandleEditBox(frame.FriendsTabHeader.SearchBox) end
		
		if frame.FriendsTabHeader.StatusDropdown then SkinDropDown(S, frame.FriendsTabHeader.StatusDropdown) end
		if frame.FriendsTabHeader.QuickFilterDropdown then SkinDropDown(S, frame.FriendsTabHeader.QuickFilterDropdown, 51) end
		if frame.FriendsTabHeader.PrimarySortDropdown then SkinDropDown(S, frame.FriendsTabHeader.PrimarySortDropdown, 51) end
		if frame.FriendsTabHeader.SecondarySortDropdown then SkinDropDown(S, frame.FriendsTabHeader.SecondarySortDropdown, 51) end
	end
	
	-- QuickJoin
	if frame.QuickJoinFrame then
		if frame.QuickJoinFrame.ContentInset then
			S:StripTextures(frame.QuickJoinFrame.ContentInset)
			S:CreateBackdrop(frame.QuickJoinFrame.ContentInset, "Transparent")
			if frame.QuickJoinFrame.ContentInset.ScrollBar then S:HandleTrimScrollBar(frame.QuickJoinFrame.ContentInset.ScrollBar) end
		end
		if frame.QuickJoinFrame.JoinQueueButton then S:HandleButton(frame.QuickJoinFrame.JoinQueueButton) end
	end
	
	-- RaidFrame
	if frame.RaidFrame then
		if frame.RaidFrame.GroupsInset then
			S:StripTextures(frame.RaidFrame.GroupsInset)
			S:CreateBackdrop(frame.RaidFrame.GroupsInset, "Transparent")
		end
		if frame.RaidFrame.ConvertToRaidButton then S:HandleButton(frame.RaidFrame.ConvertToRaidButton) end
		if frame.RaidFrame.ControlPanel then
			if frame.RaidFrame.ControlPanel.RaidInfoButton then S:HandleButton(frame.RaidFrame.ControlPanel.RaidInfoButton) end
			if frame.RaidFrame.ControlPanel.EveryoneAssistCheckbox then S:HandleCheckBox(frame.RaidFrame.ControlPanel.EveryoneAssistCheckbox) end
		end
	end

	-- Settings Frame
	local settingsFrame = _G.BetterFriendlistSettingsFrame
	if settingsFrame then
		S:HandlePortraitFrame(settingsFrame, true)
		
		for i = 1, 10 do
			local tab = _G["BetterFriendlistSettingsFrameTab"..i]
			if tab then S:HandleTab(tab) end
		end
		
		if settingsFrame.MainInset then
			S:StripTextures(settingsFrame.MainInset)
			S:CreateBackdrop(settingsFrame.MainInset, "Transparent")
		end
		
		if settingsFrame.ContentScrollFrame and settingsFrame.ContentScrollFrame.ScrollBar then
			S:HandleScrollBar(settingsFrame.ContentScrollFrame.ScrollBar)
		end
	end

	-- Hook Settings Components
	if BFL.SettingsComponents and not BFL.SettingsComponents.IsSkinnedByAS then
		local C = BFL.SettingsComponents
		
		local oldCreateCheckbox = C.CreateCheckbox
		C.CreateCheckbox = function(...)
			local holder = oldCreateCheckbox(...)
			if holder and holder.checkBox then S:HandleCheckBox(holder.checkBox) end
			return holder
		end
		
		local oldCreateSlider = C.CreateSlider
		C.CreateSlider = function(...)
			local holder = oldCreateSlider(...)
			if holder and holder.Slider and S.HandleSliderFrame then S:HandleSliderFrame(holder.Slider) end
			return holder
		end
		
		local oldCreateDropdown = C.CreateDropdown
		C.CreateDropdown = function(...)
			local holder = oldCreateDropdown(...)
			if holder and holder.DropDown then SkinDropDown(S, holder.DropDown) end
			return holder
		end
		
		local oldCreateButton = C.CreateButton
		C.CreateButton = function(...)
			local button = oldCreateButton(...)
			if button then S:HandleButton(button) end
			return button
		end
		
		local oldCreateListItem = C.CreateListItem
		C.CreateListItem = function(...)
			local holder = oldCreateListItem(...)
			if holder then
				if holder.deleteButton then S:HandleButton(holder.deleteButton) end
				if holder.colorButton then S:HandleButton(holder.colorButton) end
				if holder.renameButton then S:HandleButton(holder.renameButton) end
				if holder.downButton then S:HandleButton(holder.downButton) end
				if holder.upButton then S:HandleButton(holder.upButton) end
				if holder.bg then
					holder.bg:SetColorTexture(0, 0, 0, 0)
					S:CreateBackdrop(holder, "Transparent")
				end
			end
			return holder
		end
		
		C.IsSkinnedByAS = true
	end

	-- Notifications
	for i = 1, 3 do
		local toast = _G["BFL_FriendNotificationToast"..i]
		if toast then
			S:StripTextures(toast)
			S:CreateBackdrop(toast, "Transparent")
		end
	end
end

-- Hook Friends List
local function HookFriendsList(AS)
	local S = AS.Skins
	local FriendsList = BFL:GetModule("FriendsList")
	if not FriendsList then return end
	
	hooksecurefunc(FriendsList, "UpdateGroupHeaderButton", function(_, button, elementData)
		if not button.isSkinned then
			S:HandleButton(button)
			if button.BG then button.BG:SetTexture(nil) end
			button.isSkinned = true
		end
	end)
	
	hooksecurefunc(FriendsList, "UpdateFriendButton", function(_, button, elementData)
		if not button.isSkinned then
			if button.travelPassButton then
				S:HandleButton(button.travelPassButton)
				if button.travelPassButton.NormalTexture then
					button.travelPassButton.NormalTexture:SetAlpha(1)
					button.travelPassButton.NormalTexture:SetSize(22, 22)
					button.travelPassButton.NormalTexture:SetPoint("CENTER")
				end
			end
			button.isSkinned = true
		end
	end)
	
	hooksecurefunc(FriendsList, "UpdateInviteHeaderButton", function(_, button, elementData)
		if not button.isSkinned then
			S:HandleButton(button)
			button.isSkinned = true
		end
	end)
	
	hooksecurefunc(FriendsList, "UpdateInviteButton", function(_, button, elementData)
		if not button.isSkinned then
			if button.AcceptButton then S:HandleButton(button.AcceptButton) end
			if button.DeclineButton then S:HandleButton(button.DeclineButton) end
			button.isSkinned = true
		end
	end)
end

-- Append hook call to skin function
local originalSkin = SkinBetterFriendlist
SkinBetterFriendlist = function(event, addon)
	originalSkin(event, addon)
	local AS = unpack(_G.AddOnSkins)
	HookFriendsList(AS)
end
