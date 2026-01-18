--[[Perfy has instrumented this file]] local Perfy_GetTime, Perfy_Trace, Perfy_Trace_Passthrough = Perfy_GetTime, Perfy_Trace, Perfy_Trace_Passthrough; Perfy_Trace(Perfy_GetTime(), "Enter", "(main chunk) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua"); -- Modules/ElvUISkin.lua
-- ElvUI Skinning Module for BetterFriendlist
-- Adds native ElvUI skin support

local ADDON_NAME, BFL = ...

-- Register Module
local ElvUISkin = BFL:RegisterModule("ElvUISkin", {})

function ElvUISkin:Initialize() Perfy_Trace(Perfy_GetTime(), "Enter", "ElvUISkin:Initialize file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:10:0");
	-- Check if ElvUI is loaded immediately
	if _G.ElvUI then
		self:RegisterSkin()
	else
		-- Wait for ElvUI to load (in case BFL loads first)
		local listener = CreateFrame("Frame")
		listener:RegisterEvent("ADDON_LOADED")
		listener:SetScript("OnEvent", function(f, event, addonName) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:18:32");
			if addonName == "ElvUI" then
				self:RegisterSkin()
				f:UnregisterEvent("ADDON_LOADED")
			end
		Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:18:32"); end)
	end
Perfy_Trace(Perfy_GetTime(), "Leave", "ElvUISkin:Initialize file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:10:0"); end

function ElvUISkin:RegisterSkin() Perfy_Trace(Perfy_GetTime(), "Enter", "ElvUISkin:RegisterSkin file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:27:0");
	if not _G.ElvUI then Perfy_Trace(Perfy_GetTime(), "Leave", "ElvUISkin:RegisterSkin file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:27:0"); return end
	
	-- Check if skin is enabled in BFL settings (Point 1)
	-- Explicit check for false (nil means enabled by default if we wanted, but DB init sets it to false)
	if BetterFriendlistDB and BetterFriendlistDB.enableElvUISkin == false then
		-- BFL:DebugPrint("ElvUISkin: Skin disabled in settings")
		Perfy_Trace(Perfy_GetTime(), "Leave", "ElvUISkin:RegisterSkin file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:27:0"); return
	end

	BFL:DebugPrint("ElvUISkin: Registering skin...")
	local E, L, V, P, G = unpack(_G.ElvUI)
	local S = E:GetModule('Skins')
	if not S then Perfy_Trace(Perfy_GetTime(), "Leave", "ElvUISkin:RegisterSkin file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:27:0"); return end

	-- Register callback for skinning
	-- This ensures our skin runs when ElvUI skins are applied
	S:AddCallbackForAddon("BetterFriendlist", "BetterFriendlist", function() Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:44:63");
		BFL:DebugPrint("ElvUISkin: Callback triggered")
		xpcall(function() Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:46:9"); self:SkinFrames(E, S) Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:46:9"); end, function(err) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:46:47"); print("|cffff0000BetterFriendlist ElvUI Skin Error:|r " .. tostring(err)) Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:46:47"); end)
	Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:44:63"); end)
	
	-- If BetterFriendlist is already loaded (which it is), try to skin immediately
	-- This helps if ElvUI has already processed callbacks
	BFL:DebugPrint("ElvUISkin: Direct call triggered")
	xpcall(function() Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:52:8"); self:SkinFrames(E, S) Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:52:8"); end, function(err) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:52:46"); print("|cffff0000BetterFriendlist ElvUI Skin Error:|r " .. tostring(err)) Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:52:46"); end)
Perfy_Trace(Perfy_GetTime(), "Leave", "ElvUISkin:RegisterSkin file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:27:0"); end

function ElvUISkin:SkinFrames(E, S) Perfy_Trace(Perfy_GetTime(), "Enter", "ElvUISkin:SkinFrames file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:55:0");
	if not _G.BetterFriendsFrame then Perfy_Trace(Perfy_GetTime(), "Leave", "ElvUISkin:SkinFrames file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:55:0"); return end

	BFL:DebugPrint("ElvUISkin: SkinFrames started")
	local frame = _G.BetterFriendsFrame

	-- Skin Main Frame
	BFL:DebugPrint("ElvUISkin: Skinning Main Frame")
	if frame.PortraitContainer or frame.portrait then
		S:HandlePortraitFrame(frame)
	end

	-- Skin Portrait Button (Changelog)
	if frame.PortraitButton then
		BFL:DebugPrint("ElvUISkin: Skinning PortraitButton")
		local button = frame.PortraitButton
		
		-- Reset position and size to fit ElvUI style
		button:ClearAllPoints()
		button:SetPoint("TOPLEFT", frame, "TOPLEFT", 4, -4)
		button:SetSize(42, 42) -- Standard icon size
		button:SetFrameLevel(frame:GetFrameLevel() + 5)
		
		-- Create Backdrop
		button:CreateBackdrop("Transparent")
		
		-- Handle Icon
		-- Create a new texture to avoid mask/layer issues with the original
		if not button.Icon then
			button.Icon = button:CreateTexture(nil, "ARTWORK")
			button.Icon:SetInside()
			button.Icon:SetTexture("Interface\\AddOns\\BetterFriendlist\\Textures\\PortraitIcon")
			button.Icon:SetTexCoord(unpack(E.TexCoords))
		end
		button.Icon:Show()
		
		-- Hide original icon and mask
		if frame.PortraitIcon then frame.PortraitIcon:Hide() end
		if frame.PortraitMask then frame.PortraitMask:Hide() end
		
		-- Handle Glow (New Version Indicator)
		if button.Glow then
			button.Glow:SetParent(button)
			button.Glow:ClearAllPoints()
			button.Glow:SetInside()
			button.Glow:SetDrawLayer("OVERLAY")
			-- Use a cleaner glow texture for ElvUI
			button.Glow:SetTexture(E.Media.Textures.Highlight) 
			button.Glow:SetVertexColor(1, 0.82, 0, 0.5)
		end
		
		-- Add Hover Effect
		button:HookScript("OnEnter", function(self) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:107:31");
			if self.backdrop then
				local color = E.media.rgbvaluecolor
				if color then
					self.backdrop:SetBackdropBorderColor(color.r, color.g, color.b)
				end
			end
		Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:107:31"); end)
		
		button:HookScript("OnLeave", function(self) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:116:31");
			if self.backdrop then
				local color = E.media.bordercolor
				if color then
					self.backdrop:SetBackdropBorderColor(unpack(color))
				end
			end
		Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:116:31"); end)
	end

	-- Skin Tabs (Top)
	BFL:DebugPrint("ElvUISkin: Skinning Top Tabs")
	for i = 1, 4 do
		local tab = _G["BetterFriendsFrameTab"..i]
		if tab then
			S:HandleTab(tab)
			tab:SetHeight(25) -- Fixed height
			
			-- Adjust text position
			local text = tab.Text or (tab.GetFontString and tab:GetFontString())
			if text then
				text:ClearAllPoints()
				text:SetPoint("CENTER", tab, "CENTER", 0, 10) -- Move text up by 2 pixels
			end
		end
	end

	-- Skin Tabs (Bottom)
	BFL:DebugPrint("ElvUISkin: Skinning Bottom Tabs")
	for i = 1, 4 do
		local tab = _G["BetterFriendsFrameBottomTab"..i]
		if tab then
			S:HandleTab(tab)
			tab:SetHeight(28) -- Fixed height
			
			-- Re-anchor tabs to be left-aligned with no spacing
			tab:ClearAllPoints()
			if i == 1 then
				-- First tab anchors to the bottom left of the main frame
				tab:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", -2, 1)
			else
				-- Subsequent tabs anchor to the right of the previous one
				local prevTab = _G["BetterFriendsFrameBottomTab"..(i-1)]
				tab:SetPoint("LEFT", prevTab, "RIGHT", -5, 0)
			end
		end
	end

	-- Skin Insets
	BFL:DebugPrint("ElvUISkin: Skinning Insets")
	if frame.Inset then
		frame.Inset:StripTextures()
		frame.Inset:CreateBackdrop("Transparent")
	end
	
	if frame.ListInset then
		frame.ListInset:StripTextures()
		frame.ListInset:CreateBackdrop("Transparent")
	end

	-- Skin WhoFrame Inset
	if frame.WhoFrame and frame.WhoFrame.ListInset then
		frame.WhoFrame.ListInset:StripTextures()
		frame.WhoFrame.ListInset:CreateBackdrop("Transparent")
	end

	-- Skin RecruitAFriendFrame
	BFL:DebugPrint("ElvUISkin: Skinning RAF")
	self:SkinRecruitAFriend(E, S, frame)

	-- Skin RecentAlliesFrame ScrollBar
	BFL:DebugPrint("ElvUISkin: Skinning RecentAllies")
	if frame.RecentAlliesFrame and frame.RecentAlliesFrame.ScrollBar then
		S:HandleTrimScrollBar(frame.RecentAlliesFrame.ScrollBar)
	end

	-- Skin IgnoreListWindow
	BFL:DebugPrint("ElvUISkin: Skinning IgnoreList")
	if frame.IgnoreListWindow then
		S:HandlePortraitFrame(frame.IgnoreListWindow)
		
		if frame.IgnoreListWindow.Inset then
			frame.IgnoreListWindow.Inset:StripTextures()
			frame.IgnoreListWindow.Inset:CreateBackdrop("Transparent")
		end
		
		if frame.IgnoreListWindow.ScrollBar then
			S:HandleTrimScrollBar(frame.IgnoreListWindow.ScrollBar)
		end
		
		if frame.IgnoreListWindow.UnignorePlayerButton then
			S:HandleButton(frame.IgnoreListWindow.UnignorePlayerButton)
		end
	end

	-- Skin ScrollBars
	BFL:DebugPrint("ElvUISkin: Skinning ScrollBars")
	-- Friends List ScrollBar - Point 7
	if frame.MinimalScrollBar then
		S:HandleTrimScrollBar(frame.MinimalScrollBar)
	elseif frame.ScrollBar then
		if S.HandleMinimalScrollBar then
			S:HandleMinimalScrollBar(frame.ScrollBar)
		else
			S:HandleScrollBar(frame.ScrollBar)
		end
	end

	-- Who Frame ScrollBar
	if frame.WhoFrame and frame.WhoFrame.ScrollBar then
		S:HandleTrimScrollBar(frame.WhoFrame.ScrollBar)
	end
	
	-- Raid Frame ScrollBar
	if frame.RaidFrame and frame.RaidFrame.ScrollBar then
		S:HandleTrimScrollBar(frame.RaidFrame.ScrollBar)
	end

	-- Skin Buttons
	BFL:DebugPrint("ElvUISkin: Skinning Buttons")
	-- Add Friend / Send Who / etc
	if frame.AddFriendButton then S:HandleButton(frame.AddFriendButton) end
	if frame.SendMessageButton then S:HandleButton(frame.SendMessageButton) end
	if frame.RecruitmentButton then S:HandleButton(frame.RecruitmentButton) end
	
	-- Skin HelpButton
	if frame.HelpButton then 
		-- Do not skin the framework of the HelpButton, only color the icon
		-- S:HandleButton(frame.HelpButton) 
		if frame.HelpButton.Icon then
			frame.HelpButton.Icon:SetVertexColor(1, 1, 1)
		end
	end

	-- Point 2: MenuButton & SettingsButton
	if frame.FriendsTabHeader and frame.FriendsTabHeader.BattlenetFrame then
		if frame.FriendsTabHeader.BattlenetFrame.ContactsMenuButton then
			S:HandleButton(frame.FriendsTabHeader.BattlenetFrame.ContactsMenuButton)
		end
		if frame.FriendsTabHeader.BattlenetFrame.SettingsButton then
			S:HandleButton(frame.FriendsTabHeader.BattlenetFrame.SettingsButton)
		end
	end

	if frame.WhoFrame then
		if frame.WhoFrame.WhoButton then S:HandleButton(frame.WhoFrame.WhoButton) end
		if frame.WhoFrame.AddFriendButton then S:HandleButton(frame.WhoFrame.AddFriendButton) end
		if frame.WhoFrame.GroupInviteButton then S:HandleButton(frame.WhoFrame.GroupInviteButton) end
		
		-- EditBox
		if frame.WhoFrame.EditBox then 
			S:HandleEditBox(frame.WhoFrame.EditBox)
			if frame.WhoFrame.EditBox.Backdrop then 
				frame.WhoFrame.EditBox.Backdrop:StripTextures()
				frame.WhoFrame.EditBox.Backdrop:CreateBackdrop("Transparent")
			end
		end
		
		-- Dropdown
		if frame.WhoFrame.ColumnDropdown then S:HandleDropDownBox(frame.WhoFrame.ColumnDropdown) end
	end

	-- Skin TabHeader Elements
	BFL:DebugPrint("ElvUISkin: Skinning TabHeader")
	if frame.FriendsTabHeader then
		-- Battlenet Frame & Broadcast Frame
		if frame.FriendsTabHeader.BattlenetFrame then
			local bnet = frame.FriendsTabHeader.BattlenetFrame
			
			-- Skin Main Frame
			bnet:StripTextures()
			bnet:CreateBackdrop("Transparent")
			bnet.backdrop:SetPoint("TOPLEFT", 0, 0)
			bnet.backdrop:SetPoint("BOTTOMRIGHT", 0, 0)
			
			if bnet.Tag then
				bnet.Tag:SetParent(bnet.backdrop)
			end
			
			-- Set initial border color to default (not blue)
			if E.media and E.media.bordercolor then
				bnet.backdrop:SetBackdropBorderColor(unpack(E.media.bordercolor))
			end
			
			-- Add Hover Effect (like ElvUI)
			bnet:EnableMouse(true)
			bnet:SetScript("OnEnter", function(self) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:302:29");
				if self.backdrop then
					local c = _G.FRIENDS_BNET_NAME_COLOR
					if c then
						self.backdrop:SetBackdropBorderColor(c.r, c.g, c.b)
					end
				end
			Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:302:29"); end)
			
			bnet:SetScript("OnLeave", function(self) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:311:29");
				if self.backdrop then
					local c = E.media.bordercolor
					if c then
						self.backdrop:SetBackdropBorderColor(unpack(c))
					end
				end
			Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:311:29"); end)
			
			if bnet.BroadcastFrame then
				bnet.BroadcastFrame:StripTextures()
				bnet.BroadcastFrame:CreateBackdrop("Transparent")
				
				if bnet.BroadcastFrame.UpdateButton then S:HandleButton(bnet.BroadcastFrame.UpdateButton) end
				if bnet.BroadcastFrame.CancelButton then S:HandleButton(bnet.BroadcastFrame.CancelButton) end
				if bnet.BroadcastFrame.EditBox then S:HandleEditBox(bnet.BroadcastFrame.EditBox) end
			end
			
			if bnet.UnavailableInfoFrame then
				bnet.UnavailableInfoFrame:StripTextures()
				bnet.UnavailableInfoFrame:CreateBackdrop("Transparent")
			end
		end

		-- SearchBox
		if frame.FriendsTabHeader.SearchBox then
			S:HandleEditBox(frame.FriendsTabHeader.SearchBox)
		end
		
		-- Dropdowns - Point 3: Fix width
		if frame.FriendsTabHeader.StatusDropdown then S:HandleDropDownBox(frame.FriendsTabHeader.StatusDropdown) end
		
		if frame.FriendsTabHeader.QuickFilterDropdown then 
			S:HandleDropDownBox(frame.FriendsTabHeader.QuickFilterDropdown)
			frame.FriendsTabHeader.QuickFilterDropdown:SetWidth(51)
		end
		
		if frame.FriendsTabHeader.PrimarySortDropdown then 
			S:HandleDropDownBox(frame.FriendsTabHeader.PrimarySortDropdown)
			frame.FriendsTabHeader.PrimarySortDropdown:SetWidth(51)
		end
		
		if frame.FriendsTabHeader.SecondarySortDropdown then 
			S:HandleDropDownBox(frame.FriendsTabHeader.SecondarySortDropdown)
			frame.FriendsTabHeader.SecondarySortDropdown:SetWidth(51)
		end
	end

	-- Skin Headers (Who Frame)
	BFL:DebugPrint("ElvUISkin: Skinning WhoFrame Headers")
	if frame.WhoFrame then
		local headers = {frame.WhoFrame.NameHeader, frame.WhoFrame.LevelHeader, frame.WhoFrame.ClassHeader}
		for _, header in ipairs(headers) do
			if header then
				S:HandleButton(header)
				header:SetHeight(22) -- Fixed height for headers
			end
		end
		
		-- Fix NameHeader alignment
		if frame.WhoFrame.NameHeader and frame.WhoFrame.ListInset then
			frame.WhoFrame.NameHeader:ClearAllPoints()
			frame.WhoFrame.NameHeader:SetPoint("BOTTOMLEFT", frame.WhoFrame.ListInset, "TOPLEFT", 0, 1)
		end
		
		-- Fix Dropdown height and alignment
		if frame.WhoFrame.ColumnDropdown then
			frame.WhoFrame.ColumnDropdown:SetHeight(26) -- Match header height
			
			-- Re-anchor to NameHeader
			frame.WhoFrame.ColumnDropdown:ClearAllPoints()
			frame.WhoFrame.ColumnDropdown:SetPoint("LEFT", frame.WhoFrame.NameHeader, "RIGHT", -1, 0)
		end
		
		-- Re-anchor LevelHeader
		if frame.WhoFrame.LevelHeader and frame.WhoFrame.ColumnDropdown then
			frame.WhoFrame.LevelHeader:ClearAllPoints()
			frame.WhoFrame.LevelHeader:SetPoint("LEFT", frame.WhoFrame.ColumnDropdown, "RIGHT", -1, 0)
		end
		
		-- Re-anchor ClassHeader
		if frame.WhoFrame.ClassHeader and frame.WhoFrame.LevelHeader then
			frame.WhoFrame.ClassHeader:ClearAllPoints()
			frame.WhoFrame.ClassHeader:SetPoint("LEFT", frame.WhoFrame.LevelHeader, "RIGHT", -1, 0)
		end
	end
	
	-- Skin QuickJoin
	BFL:DebugPrint("ElvUISkin: Skinning QuickJoin")
	if frame.QuickJoinFrame then
		if frame.QuickJoinFrame.ContentInset then
			 frame.QuickJoinFrame.ContentInset:StripTextures()
			 frame.QuickJoinFrame.ContentInset:CreateBackdrop("Transparent")
			 
			 if frame.QuickJoinFrame.ContentInset.ScrollBar then
				 S:HandleTrimScrollBar(frame.QuickJoinFrame.ContentInset.ScrollBar)
			 end
		end
		
		-- Point 4: Join Queue Button (Check both possible paths)
		if frame.QuickJoinFrame.JoinQueueButton then
			S:HandleButton(frame.QuickJoinFrame.JoinQueueButton)
		elseif frame.QuickJoinFrame.ContentInset and frame.QuickJoinFrame.ContentInset.JoinQueueButton then
			S:HandleButton(frame.QuickJoinFrame.ContentInset.JoinQueueButton)
		end
	end
	
	-- Skin Raid Frame
	BFL:DebugPrint("ElvUISkin: Skinning RaidFrame")
	if frame.RaidFrame then
		 -- Fix: Use GroupsInset instead of ListInset
		 if frame.RaidFrame.GroupsInset then
			 frame.RaidFrame.GroupsInset:StripTextures()
			 frame.RaidFrame.GroupsInset:CreateBackdrop("Transparent")
		 elseif frame.RaidFrame.ListInset then
			 -- Fallback if ListInset exists
			 frame.RaidFrame.ListInset:StripTextures()
			 frame.RaidFrame.ListInset:CreateBackdrop("Transparent")
		 end
		 
		 if frame.RaidFrame.ConvertToRaidButton then S:HandleButton(frame.RaidFrame.ConvertToRaidButton) end
		 
		 -- Point 8: Raid Info Button
		 if frame.RaidFrame.ControlPanel and frame.RaidFrame.ControlPanel.RaidInfoButton then 
			S:HandleButton(frame.RaidFrame.ControlPanel.RaidInfoButton) 
		 end
		 
		 -- Skin EveryoneAssistCheckbox
		 if frame.RaidFrame.ControlPanel and frame.RaidFrame.ControlPanel.EveryoneAssistCheckbox then
			S:HandleCheckBox(frame.RaidFrame.ControlPanel.EveryoneAssistCheckbox)
		 end
	end

	-- Hook Friends List (ScrollBox Items)
	BFL:DebugPrint("ElvUISkin: Hooking FriendsList")
	self:HookFriendsList(E, S)

	-- Skin Settings Frame
	BFL:DebugPrint("ElvUISkin: Skinning Settings")
	self:SkinSettings(E, S)
	
	-- Skin Notifications
	BFL:DebugPrint("ElvUISkin: Skinning Notifications")
	self:SkinNotifications(E, S)
	
	-- Skin Broker
	BFL:DebugPrint("ElvUISkin: Skinning Broker")
	self:SkinBroker(E, S)
	
	-- Skin Context Menus
	BFL:DebugPrint("ElvUISkin: Skinning ContextMenus")
	xpcall(function() Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:462:8"); self:SkinContextMenus(E, S) Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:462:8"); end, function(err) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:462:52"); print("|cffff0000BetterFriendlist ElvUI Menu Error:|r " .. tostring(err)) Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:462:52"); end)

	-- Skin Changelog
	BFL:DebugPrint("ElvUISkin: Skinning Changelog")
	self:SkinChangelog(E, S)
	
	-- Skin HelpFrame
	BFL:DebugPrint("ElvUISkin: Skinning HelpFrame")
	self:SkinHelpFrame(E, S)

	-- Apply FontFix after Skinning to ensure correct font sizes
	local FontFix = BFL:GetModule("FontFix")
	if FontFix then
		BFL:DebugPrint("ElvUISkin: Re-applying FontFix")
		FontFix:ApplyFixedFonts()
	end

	BFL:DebugPrint("ElvUI Skin applied to BetterFriendlist")
Perfy_Trace(Perfy_GetTime(), "Leave", "ElvUISkin:SkinFrames file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:55:0"); end

function ElvUISkin:HookFriendsList(E, S) Perfy_Trace(Perfy_GetTime(), "Enter", "ElvUISkin:HookFriendsList file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:482:0");
	local FriendsList = BFL:GetModule("FriendsList")
	if not FriendsList then Perfy_Trace(Perfy_GetTime(), "Leave", "ElvUISkin:HookFriendsList file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:482:0"); return end
	
	-- Hook Group Header
	hooksecurefunc(FriendsList, "UpdateGroupHeaderButton", function(_, button, elementData) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:487:56");
		if not button.isSkinned then
			S:HandleButton(button)
			-- Strip the custom background texture if it exists
			if button.BG then button.BG:SetTexture(nil) end
			button.isSkinned = true
		end
	Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:487:56"); end)
	
	-- Hook Friend Button
	hooksecurefunc(FriendsList, "UpdateFriendButton", function(_, button, elementData) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:497:51");
		if not button.isSkinned then
			-- Don't full skin friend buttons as they are list items
			-- But we can skin the travel pass button - Point 3: Fix texture size
			if button.travelPassButton then
				S:HandleButton(button.travelPassButton)
				-- Ensure icon remains visible and sized correctly
				if button.travelPassButton.NormalTexture then
					button.travelPassButton.NormalTexture:SetAlpha(1)
					button.travelPassButton.NormalTexture:SetSize(22, 22)
					button.travelPassButton.NormalTexture:SetPoint("CENTER")
				end
			end
			button.isSkinned = true
		end
	Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:497:51"); end)
	
	-- Hook Invite Header
	hooksecurefunc(FriendsList, "UpdateInviteHeaderButton", function(_, button, elementData) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:515:57");
		if not button.isSkinned then
			S:HandleButton(button)
			button.isSkinned = true
		end
	Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:515:57"); end)
	
	-- Hook Invite Button
	hooksecurefunc(FriendsList, "UpdateInviteButton", function(_, button, elementData) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:523:51");
		if not button.isSkinned then
			if button.AcceptButton then S:HandleButton(button.AcceptButton) end
			if button.DeclineButton then S:HandleButton(button.DeclineButton) end
			button.isSkinned = true
		end
	Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:523:51"); end)
Perfy_Trace(Perfy_GetTime(), "Leave", "ElvUISkin:HookFriendsList file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:482:0"); end

function ElvUISkin:SkinRecruitAFriend(E, S, frame) Perfy_Trace(Perfy_GetTime(), "Enter", "ElvUISkin:SkinRecruitAFriend file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:532:0");
	local raf = frame.RecruitAFriendFrame
	if not raf then Perfy_Trace(Perfy_GetTime(), "Leave", "ElvUISkin:SkinRecruitAFriend file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:532:0"); return end

	-- Skin Main Elements
	if raf.Border then raf.Border:StripTextures() end
	if raf.Background then raf.Background:Hide() end
	
	-- Skin Reward Claiming
	if raf.RewardClaiming then
		-- ElvUI Style: Handle Background
		if raf.RewardClaiming.Background then raf.RewardClaiming.Background:SetAlpha(0) end
		
		-- Hide Parchment Elements
		local parchmentElements = {
			"Bracket_TopLeft", "Bracket_TopRight", "Bracket_BottomLeft", "Bracket_BottomRight", 
			"Watermark"
		}
		for _, name in ipairs(parchmentElements) do
			if raf.RewardClaiming[name] then raf.RewardClaiming[name]:Hide() end
		end
		
		-- Create Backdrop
		raf.RewardClaiming:CreateBackdrop("Transparent")
		
		-- Skin Claim/View Button
		if raf.RewardClaiming.ClaimOrViewRewardButton then
			S:HandleButton(raf.RewardClaiming.ClaimOrViewRewardButton)
		end
		
		if raf.RewardClaiming.Inset then
			raf.RewardClaiming.Inset:StripTextures()
			raf.RewardClaiming.Inset:CreateBackdrop("Transparent")
		end
		
		-- Next Reward Icon
		if raf.RewardClaiming.NextRewardButton then
			local button = raf.RewardClaiming.NextRewardButton
			-- CRITICAL: Do NOT strip textures, it removes the Icon!
			button:CreateBackdrop("Transparent")
			
			if button.Icon then
				button.Icon:SetTexCoord(unpack(E.TexCoords))
				button.Icon:SetParent(button.backdrop)
				button.Icon:SetInside()
				button.Icon:SetDrawLayer("ARTWORK")
			end
			
			if button.IconBorder then button.IconBorder:SetAlpha(0) end
			if button.IconOverlay then button.IconOverlay:SetAlpha(0) end
			if button.CircleMask then button.CircleMask:Hide() end
		end
	end
	
	-- Skin Recruit List
	if raf.RecruitList then
		if raf.RecruitList.ScrollFrameInset then
			raf.RecruitList.ScrollFrameInset:StripTextures()
			raf.RecruitList.ScrollFrameInset:CreateBackdrop("Transparent")
		end
		
		if raf.RecruitList.ScrollBar then
			S:HandleTrimScrollBar(raf.RecruitList.ScrollBar)
		end
		
		-- Header
		if raf.RecruitList.Header then
			if raf.RecruitList.Header.Background then
				raf.RecruitList.Header.Background:Hide()
			end
			raf.RecruitList.Header:StripTextures()
			raf.RecruitList.Header:CreateBackdrop("Transparent")
		end
	end
	
	-- Skin Splash Frame
	if raf.SplashFrame then
		raf.SplashFrame:StripTextures()
		raf.SplashFrame:CreateBackdrop("Transparent")
		
		if raf.SplashFrame.Background then raf.SplashFrame.Background:Hide() end
		if raf.SplashFrame.PictureFrame then raf.SplashFrame.PictureFrame:Hide() end
		if raf.SplashFrame.Watermark then raf.SplashFrame.Watermark:Hide() end
		if raf.SplashFrame.Bracket_TopLeft then raf.SplashFrame.Bracket_TopLeft:Hide() end
		if raf.SplashFrame.Bracket_TopRight then raf.SplashFrame.Bracket_TopRight:Hide() end
		if raf.SplashFrame.Bracket_BottomLeft then raf.SplashFrame.Bracket_BottomLeft:Hide() end
		if raf.SplashFrame.Bracket_BottomRight then raf.SplashFrame.Bracket_BottomRight:Hide() end
		
		if raf.SplashFrame.Picture then
			raf.SplashFrame.Picture:SetInside() -- Make picture fill the frame or adjust as needed
			-- ElvUI does this, but maybe we want to keep it centered?
			-- Let's stick to ElvUI logic:
			-- SplashFrame.Picture:SetInside()
		end
		
		if raf.SplashFrame.OKButton then
			S:HandleButton(raf.SplashFrame.OKButton)
		end
	end
Perfy_Trace(Perfy_GetTime(), "Leave", "ElvUISkin:SkinRecruitAFriend file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:532:0"); end

function ElvUISkin:SkinSettings(E, S) Perfy_Trace(Perfy_GetTime(), "Enter", "ElvUISkin:SkinSettings file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:633:0");
	local frame = _G.BetterFriendlistSettingsFrame
	if not frame then Perfy_Trace(Perfy_GetTime(), "Leave", "ElvUISkin:SkinSettings file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:633:0"); return end
	
	S:HandlePortraitFrame(frame)
	
	-- Skin Tabs (Top) - Point 4: Adjust height
	for i = 1, 10 do
		local tab = _G["BetterFriendlistSettingsFrameTab"..i]
		if tab then
			S:HandleTab(tab)
			tab:SetHeight(32) -- Fixed height
		end
	end
	
	-- Skin Main Inset
	if frame.MainInset then
		frame.MainInset:StripTextures()
		frame.MainInset:CreateBackdrop("Transparent")
	end
	
	-- Skin ScrollBar
	if frame.ContentScrollFrame and frame.ContentScrollFrame.ScrollBar then
		S:HandleScrollBar(frame.ContentScrollFrame.ScrollBar)
	end

	-- Hook Refresh functions to skin EditBoxes (Point 3)
	local Settings = BFL:GetModule("Settings")
	if Settings then
		local function SkinEditBoxesInTab(tab) Perfy_Trace(Perfy_GetTime(), "Enter", "SkinEditBoxesInTab file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:662:8");
			if not tab or not tab.components then Perfy_Trace(Perfy_GetTime(), "Leave", "SkinEditBoxesInTab file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:662:8"); return end
			for _, comp in ipairs(tab.components) do
				-- Check if it's an EditBox (or container with EditBox)
				if comp:IsObjectType("EditBox") then
					S:HandleEditBox(comp)
				elseif comp:IsObjectType("Frame") then
					-- Check children for EditBox (like nameFormatContainer)
					for _, child in ipairs({comp:GetChildren()}) do
						if child:IsObjectType("EditBox") then
							S:HandleEditBox(child)
						end
					end
				end
			end
		Perfy_Trace(Perfy_GetTime(), "Leave", "SkinEditBoxesInTab file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:662:8"); end

		hooksecurefunc(Settings, "RefreshGeneralTab", function() Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:679:48");
			local content = frame.ContentScrollFrame.Content
			if content and content.GeneralTab then
				SkinEditBoxesInTab(content.GeneralTab)
			end
		Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:679:48"); end)

		hooksecurefunc(Settings, "RefreshNotificationsTab", function() Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:686:54");
			local content = frame.ContentScrollFrame.Content
			if content and content.NotificationsTab then
				SkinEditBoxesInTab(content.NotificationsTab)
			end
		Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:686:54"); end)
	end
	
	-- Hook Components to skin dynamic elements
	if BFL.SettingsComponents then
		local C = BFL.SettingsComponents
		
		-- Checkbox
		if not C.IsSkinned then
			local oldCreateCheckbox = C.CreateCheckbox
			C.CreateCheckbox = function(...) Perfy_Trace(Perfy_GetTime(), "Enter", "C.CreateCheckbox file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:701:22");
				local holder = oldCreateCheckbox(...)
				if holder and holder.checkBox then
					S:HandleCheckBox(holder.checkBox)
				end
				Perfy_Trace(Perfy_GetTime(), "Leave", "C.CreateCheckbox file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:701:22"); return holder
			end
			
			-- Slider
			local oldCreateSlider = C.CreateSlider
			C.CreateSlider = function(...) Perfy_Trace(Perfy_GetTime(), "Enter", "C.CreateSlider file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:711:20");
				local holder = oldCreateSlider(...)
				if holder and holder.Slider then
					S:HandleSliderFrame(holder.Slider)
				end
				Perfy_Trace(Perfy_GetTime(), "Leave", "C.CreateSlider file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:711:20"); return holder
			end
			
			-- Dropdown
			local oldCreateDropdown = C.CreateDropdown
			C.CreateDropdown = function(...) Perfy_Trace(Perfy_GetTime(), "Enter", "C.CreateDropdown file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:721:22");
				local holder = oldCreateDropdown(...)
				if holder and holder.DropDown then
					S:HandleDropDownBox(holder.DropDown)
				end
				Perfy_Trace(Perfy_GetTime(), "Leave", "C.CreateDropdown file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:721:22"); return holder
			end
			
			-- Button
			local oldCreateButton = C.CreateButton
			C.CreateButton = function(...) Perfy_Trace(Perfy_GetTime(), "Enter", "C.CreateButton file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:731:20");
				local button = oldCreateButton(...)
				if button then
					S:HandleButton(button)
				end
				Perfy_Trace(Perfy_GetTime(), "Leave", "C.CreateButton file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:731:20"); return button
			end
			
			-- List Item (Group Management)
			local oldCreateListItem = C.CreateListItem
			C.CreateListItem = function(...) Perfy_Trace(Perfy_GetTime(), "Enter", "C.CreateListItem file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:741:22");
				local holder = oldCreateListItem(...)
				if holder then
					if holder.deleteButton then S:HandleButton(holder.deleteButton) end
					if holder.colorButton then S:HandleButton(holder.colorButton) end
					if holder.renameButton then S:HandleButton(holder.renameButton) end
					if holder.downButton then S:HandleButton(holder.downButton) end
					if holder.upButton then S:HandleButton(holder.upButton) end
					
					-- Skin the background if possible, or strip it
					if holder.bg then
						holder.bg:SetColorTexture(0, 0, 0, 0) -- Hide default bg
						holder:CreateBackdrop("Transparent")
					end
				end
				Perfy_Trace(Perfy_GetTime(), "Leave", "C.CreateListItem file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:741:22"); return holder
			end
			
			C.IsSkinned = true
		end
	end
Perfy_Trace(Perfy_GetTime(), "Leave", "ElvUISkin:SkinSettings file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:633:0"); end

function ElvUISkin:SkinNotifications(E, S) Perfy_Trace(Perfy_GetTime(), "Enter", "ElvUISkin:SkinNotifications file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:764:0");
	-- Skin Toast Frames
	for i = 1, 3 do
		local toast = _G["BFL_FriendNotificationToast"..i]
		if toast then
			toast:StripTextures()
			toast:CreateBackdrop("Transparent")
			
			-- Adjust icon position if needed
			if toast.Icon then
				-- toast.Icon:SetTexCoord(unpack(E.TexCoords)) -- If we want square icons
			end
		end
	end
Perfy_Trace(Perfy_GetTime(), "Leave", "ElvUISkin:SkinNotifications file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:764:0"); end

function ElvUISkin:SkinBroker(E, S) Perfy_Trace(Perfy_GetTime(), "Enter", "ElvUISkin:SkinBroker file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:780:0");
	-- Hook LibQTip to skin tooltips
	local LQT = LibStub("LibQTip-1.0", true)
	if LQT and not LQT.IsSkinnedByBFL then
		local oldAcquire = LQT.Acquire
		LQT.Acquire = function(self, key, ...) Perfy_Trace(Perfy_GetTime(), "Enter", "LQT.Acquire file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:785:16");
			local tooltip = oldAcquire(self, key, ...)
			if key == "BetterFriendlistBrokerTT" or key == "BetterFriendlistBrokerDetailTT" then
				if not tooltip.isSkinned then
					tooltip:StripTextures()
					tooltip:CreateBackdrop("Transparent")
					tooltip.isSkinned = true
				end
			end
			Perfy_Trace(Perfy_GetTime(), "Leave", "LQT.Acquire file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:785:16"); return tooltip
		end
		LQT.IsSkinnedByBFL = true
	end
Perfy_Trace(Perfy_GetTime(), "Leave", "ElvUISkin:SkinBroker file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:780:0"); end

function ElvUISkin:SkinContextMenus(E, S) Perfy_Trace(Perfy_GetTime(), "Enter", "ElvUISkin:SkinContextMenus file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:800:0");
	-- Hook MenuUtil to skin context menus
	if not MenuUtil then Perfy_Trace(Perfy_GetTime(), "Leave", "ElvUISkin:SkinContextMenus file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:800:0"); return end
	
	-- Helper to skin a single frame in the menu
	local function SkinMenuFrame(frame) Perfy_Trace(Perfy_GetTime(), "Enter", "SkinMenuFrame file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:805:7");
		if not frame then Perfy_Trace(Perfy_GetTime(), "Leave", "SkinMenuFrame file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:805:7"); return end
		
		-- Recursive search for CheckButtons and Checkbox-like Buttons
		local function FindAndSkin(obj, depth) Perfy_Trace(Perfy_GetTime(), "Enter", "FindAndSkin file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:809:8");
			if not obj then Perfy_Trace(Perfy_GetTime(), "Leave", "FindAndSkin file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:809:8"); return end
			depth = depth or 0
			if depth > 15 then Perfy_Trace(Perfy_GetTime(), "Leave", "FindAndSkin file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:809:8"); return end -- Prevent infinite recursion
			
			local objType = obj:GetObjectType()
			
			-- 1. Standard CheckButton
			if objType == "CheckButton" then
				if not obj.isSkinnedByBFL then
					S:HandleCheckBox(obj)
					obj.isSkinnedByBFL = true
				end
				
			-- 2. Button acting as Checkbox (MenuUtil)
			elseif objType == "Button" then
				local regions = {obj:GetRegions()}
				local checkboxRegion = nil
				local checkmarkRegion = nil
				
				-- Pass 1: Find the checkbox background (130940 or similar)
				for _, region in ipairs(regions) do
					if region:IsObjectType("Texture") then
						local tex = region:GetTexture()
						local atlas = region:GetAtlas()
						
						-- Check for standard checkbox background textures
						-- 130940: UI-CheckBox-Up
						-- 130941: UI-CheckBox-Down
						-- 130942: UI-CheckBox-Disabled
						if tex == 130940 or tex == 130941 or tex == 130942 or 
						   (atlas and (string.find(string.lower(atlas), "checkbox-off") or string.find(string.lower(atlas), "checkbox-up"))) then
							checkboxRegion = region
							break
						end
					end
				end
				
				-- CRITICAL FIX: Only skin if the checkbox region is actually SHOWN.
				-- This prevents skinning arrow buttons or other buttons that have hidden checkbox textures.
				if checkboxRegion and checkboxRegion:IsShown() then
					if not obj.isSkinnedByBFL then
						-- Create Backdrop
						local bd = CreateFrame("Frame", nil, obj)
						bd:SetFrameLevel(obj:GetFrameLevel())
						bd:SetSize(14, 14)
						bd:SetPoint("CENTER", checkboxRegion, "CENTER", 0, 0)
						bd:CreateBackdrop("Transparent")
						obj.BFLCheckboxBackdrop = bd
						
						-- Create Checkmark
						local check = bd:CreateTexture(nil, "OVERLAY")
						local checkTex = E.Media and E.Media.Textures and E.Media.Textures.Melli or 130751
						check:SetTexture(checkTex)
						check:SetSize(14, 14)
						check:SetPoint("CENTER")
						check:SetVertexColor(1, 0.82, 0) -- ElvUI Yellow
						check:Hide()
						obj.BFLCheckmark = check
						
						-- Hide original background
						checkboxRegion:SetAlpha(0)
						
						-- Pass 2: Find potential checkmark region (separate region)
						for _, region in ipairs(regions) do
							if region ~= checkboxRegion and region:IsObjectType("Texture") then
								local tex = region:GetTexture()
								local atlas = region:GetAtlas()
								
								-- Check for checkmark texture/atlas
								-- 130751: UI-CheckBox-Check
								if tex == 130751 or (atlas and (string.find(string.lower(atlas), "checkmark") or string.find(string.lower(atlas), "checkbox-on"))) then
									checkmarkRegion = region
									break
								end
							end
						end
						
						if checkmarkRegion then
							-- Case A: Separate Checkmark Region
							checkmarkRegion:SetAlpha(0)
							
							local function UpdateCheck() Perfy_Trace(Perfy_GetTime(), "Enter", "UpdateCheck file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:891:13");
								if checkmarkRegion:IsShown() then
									obj.BFLCheckmark:Show()
								else
									obj.BFLCheckmark:Hide()
								end
							Perfy_Trace(Perfy_GetTime(), "Leave", "UpdateCheck file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:891:13"); end
							
							hooksecurefunc(checkmarkRegion, "Show", UpdateCheck)
							hooksecurefunc(checkmarkRegion, "Hide", UpdateCheck)
							hooksecurefunc(checkmarkRegion, "SetShown", UpdateCheck)
							UpdateCheck()
						else
							-- Case B: Texture Swap on Background Region (or checkmark not found yet)
							-- We hook the background region to see if it turns into a checkmark
							local function UpdateTexture(self) Perfy_Trace(Perfy_GetTime(), "Enter", "UpdateTexture file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:906:13");
								if not obj.BFLCheckmark then Perfy_Trace(Perfy_GetTime(), "Leave", "UpdateTexture file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:906:13"); return end
								
								local tex = self:GetTexture()
								local atlas = self:GetAtlas()
								
								local isChecked = false
								if tex == 130751 then isChecked = true end
								if atlas and (string.find(string.lower(atlas), "checkbox-on") or string.find(string.lower(atlas), "checkmark")) then isChecked = true end
								
								if isChecked then
									obj.BFLCheckmark:Show()
								else
									obj.BFLCheckmark:Hide()
								end
							Perfy_Trace(Perfy_GetTime(), "Leave", "UpdateTexture file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:906:13"); end
							
							hooksecurefunc(checkboxRegion, "SetTexture", UpdateTexture)
							hooksecurefunc(checkboxRegion, "SetAtlas", UpdateTexture)
							-- Initial check
							UpdateTexture(checkboxRegion)
						end
						
						obj.isSkinnedByBFL = true
					end
				end
			end
			
			-- Recursively check children
			local children = {obj:GetChildren()}
			for _, child in ipairs(children) do
				FindAndSkin(child, depth + 1)
			end
			
			-- Special handling for ScrollBox to ensure we go deeper
			if obj.GetScrollTarget then
				FindAndSkin(obj:GetScrollTarget(), depth + 1)
			end
		Perfy_Trace(Perfy_GetTime(), "Leave", "FindAndSkin file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:809:8"); end
		
		FindAndSkin(frame)
	Perfy_Trace(Perfy_GetTime(), "Leave", "SkinMenuFrame file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:805:7"); end
	
	-- Hook Menu Manager to catch ALL menus (including submenus)
	local function HookMenuManager() Perfy_Trace(Perfy_GetTime(), "Enter", "HookMenuManager file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:950:7");
		if BFL.MenuManagerHooked then Perfy_Trace(Perfy_GetTime(), "Leave", "HookMenuManager file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:950:7"); return end
		
		if Menu and Menu.GetManager then
			local manager = Menu.GetManager()
			if manager and manager.OpenMenu then
				hooksecurefunc(manager, "OpenMenu", function(self, menu) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:956:40");
					-- Wait a frame for the menu to be created and populated
					C_Timer.After(0.05, function() Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:958:25");
						-- Get the currently open menu (which should be the one we just opened)
						local openMenu = manager:GetOpenMenu()
						if openMenu then
							-- Skin the menu frame if not already skinned
							if not openMenu.isSkinnedByBFL then
								openMenu:StripTextures()
								openMenu:CreateBackdrop("Transparent")
								openMenu.isSkinnedByBFL = true
								
								-- Hook ScrollBox to skin new frames as they appear
								if openMenu.ScrollBox then
									if openMenu.ScrollBox.RegisterCallback then
										pcall(function() Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:971:16");
											openMenu.ScrollBox:RegisterCallback("OnAcquiredFrame", function(o, frame, elementData, isNew) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:972:66");
												SkinMenuFrame(frame)
											Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:972:66"); end, self)
										Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:971:16"); end)
									end
								end
							end
							
							-- Always scan the menu for items (initial population)
							SkinMenuFrame(openMenu)
						end
					Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:958:25"); end)
				Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:956:40"); end)
				BFL.MenuManagerHooked = true
				-- BFL:DebugPrint("BFL: Hooked Menu Manager for SubMenus")
			end
		end
	Perfy_Trace(Perfy_GetTime(), "Leave", "HookMenuManager file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:950:7"); end

	-- Try to hook immediately
	HookMenuManager()
	
	-- Also hook CreateContextMenu as a backup/trigger
	hooksecurefunc(MenuUtil, "CreateContextMenu", function(owner, generator) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:995:47");
		HookMenuManager() -- Retry hooking if it wasn't ready
	Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:995:47"); end)
Perfy_Trace(Perfy_GetTime(), "Leave", "ElvUISkin:SkinContextMenus file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:800:0"); end

function ElvUISkin:SkinChangelog(E, S) Perfy_Trace(Perfy_GetTime(), "Enter", "ElvUISkin:SkinChangelog file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:1000:0");
	local Changelog = BFL:GetModule("Changelog")
	if not Changelog then Perfy_Trace(Perfy_GetTime(), "Leave", "ElvUISkin:SkinChangelog file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:1000:0"); return end

	local function Skin() Perfy_Trace(Perfy_GetTime(), "Enter", "Skin file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:1004:7");
		local frame = _G.BetterFriendlistChangelogFrame
		if not frame or frame.isSkinned then Perfy_Trace(Perfy_GetTime(), "Leave", "Skin file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:1004:7"); return end
		
		BFL:DebugPrint("ElvUISkin: Applying Skin to Changelog Window")
		S:HandlePortraitFrame(frame)
		
		-- Skin Main Inset
		if frame.MainInset then
			frame.MainInset:StripTextures()
			frame.MainInset:CreateBackdrop("Transparent")
		end
		
		-- Skin Buttons
		if frame.DiscordButton then S:HandleButton(frame.DiscordButton) end
		if frame.GitHubButton then S:HandleButton(frame.GitHubButton) end
		if frame.KoFiButton then S:HandleButton(frame.KoFiButton) end
		
		-- Skin ScrollBar
		if frame.ScrollBar then
			-- Retail
			S:HandleTrimScrollBar(frame.ScrollBar)
		elseif frame.ScrollFrame then
			-- Classic or Fallback
			local children = {frame.ScrollFrame:GetChildren()}
			for _, child in ipairs(children) do
				if child:IsObjectType("Slider") then
					S:HandleScrollBar(child)
				end
			end
		end
		
		frame.isSkinned = true
	Perfy_Trace(Perfy_GetTime(), "Leave", "Skin file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:1004:7"); end

	hooksecurefunc(Changelog, "CreateChangelogWindow", Skin)
	Skin()
Perfy_Trace(Perfy_GetTime(), "Leave", "ElvUISkin:SkinChangelog file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:1000:0"); end

function ElvUISkin:SkinHelpFrame(E, S) Perfy_Trace(Perfy_GetTime(), "Enter", "ElvUISkin:SkinHelpFrame file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:1043:0");
	local HelpFrame = BFL.HelpFrame or BFL:GetModule("HelpFrame")
	if not HelpFrame then Perfy_Trace(Perfy_GetTime(), "Leave", "ElvUISkin:SkinHelpFrame file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:1043:0"); return end

	local function Skin() Perfy_Trace(Perfy_GetTime(), "Enter", "Skin file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:1047:7");
		local frame = _G.BetterFriendlistHelpFrame
		if not frame or frame.isSkinned then Perfy_Trace(Perfy_GetTime(), "Leave", "Skin file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:1047:7"); return end
		
		BFL:DebugPrint("ElvUISkin: Skinning HelpFrame")
		S:HandlePortraitFrame(frame)
		
		-- Skin Inset if it exists (ButtonFrameTemplate feature)
		if frame.Inset then
			frame.Inset:StripTextures()
			frame.Inset:CreateBackdrop("Transparent")
		end
		
		-- Skin ScrollBar
		if frame.ScrollBar then
			S:HandleTrimScrollBar(frame.ScrollBar)
		elseif frame.ScrollFrame then
			-- Classic fallback or when using UIPanelScrollFrame
			if frame.ScrollFrame.ScrollBar then
				S:HandleScrollBar(frame.ScrollFrame.ScrollBar)
			else
				local scrollBar = _G[frame.ScrollFrame:GetName().."ScrollBar"]
				if scrollBar then
					S:HandleScrollBar(scrollBar)
				end
			end
		end

		frame.isSkinned = true
	Perfy_Trace(Perfy_GetTime(), "Leave", "Skin file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:1047:7"); end

	-- Hook creation
	hooksecurefunc(HelpFrame, "CreateFrame", Skin)
	-- Hook toggle as well just in case CreateFrame returns early but we missed skinning
	hooksecurefunc(HelpFrame, "Toggle", Skin)
	
	-- Try to skin immediately if it exists
	if _G.BetterFriendlistHelpFrame then Skin() end
Perfy_Trace(Perfy_GetTime(), "Leave", "ElvUISkin:SkinHelpFrame file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua:1043:0"); end

Perfy_Trace(Perfy_GetTime(), "Leave", "(main chunk) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/ElvUISkin.lua");