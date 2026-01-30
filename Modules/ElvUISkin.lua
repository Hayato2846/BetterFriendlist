-- Modules/ElvUISkin.lua
-- ElvUI Skinning Module for BetterFriendlist
-- Adds native ElvUI skin support

local ADDON_NAME, BFL = ...

-- Register Module
local ElvUISkin = BFL:RegisterModule("ElvUISkin", {})

-- Helper to handle scrollbars across Retail and Classic
local function SkinScrollBar(S, scrollBar)
	if not scrollBar then return end
	if S.HandleTrimScrollBar then
		S:HandleTrimScrollBar(scrollBar)
	elseif S.HandleScrollBar then
		S:HandleScrollBar(scrollBar)
	end
end

function ElvUISkin:Initialize()
	-- Check if ElvUI is loaded immediately
	if _G.ElvUI then
		self:RegisterSkin()
	else
		-- Wait for ElvUI to load (in case BFL loads first)
		-- Check for "ElvUI" or "ElvUI_Classic" or generic _G.ElvUI presence
		local listener = CreateFrame("Frame")
		listener:RegisterEvent("ADDON_LOADED")
		listener:SetScript("OnEvent", function(f, event, addonName)
			if addonName == "ElvUI" or addonName == "ElvUI_Classic" or _G.ElvUI then
				self:RegisterSkin()
				f:UnregisterEvent("ADDON_LOADED")
			end
		end)
	end
end

function ElvUISkin:RegisterSkin()
	if not _G.ElvUI then return end
	
	-- Check if skin is enabled in BFL settings (Point 1)
	-- Explicit check for false (nil means enabled by default if we wanted, but DB init sets it to false)
	local isEnabled = BetterFriendlistDB and BetterFriendlistDB.enableElvUISkin
	if isEnabled == false then
		print("|cff00ffffBFL ElvUI:|r Skin disabled in settings (DB.enableElvUISkin = false)")
		return
	end

	print("|cff00ffffBFL ElvUI:|r Registering skin...")
	local E, L, V, P, G = unpack(_G.ElvUI)
	local S = E:GetModule('Skins')
	if not S then 
		print("|cff00ffffBFL ElvUI:|r Skins module not found!")
		return 
	end

	-- Register callback for skinning
	-- This ensures our skin runs when ElvUI skins are applied
	-- Try both typical addon names to be safe
	S:AddCallbackForAddon("BetterFriendlist", "BetterFriendlist", function()
		print("|cff00ffffBFL ElvUI:|r Callback triggered")
		xpcall(function() self:SkinFrames(E, S) end, function(err) print("|cffff0000BetterFriendlist ElvUI Skin Error:|r " .. tostring(err)) end)
	end)
	
	-- Force run if ElvUI is already initialized (Classic fix)
	if E.initialized then
		print("|cff00ffffBFL ElvUI:|r Direct call triggered (E.initialized=true)")
		xpcall(function() self:SkinFrames(E, S) end, function(err) print("|cffff0000BetterFriendlist ElvUI Skin Error:|r " .. tostring(err)) end)
	else
		print("|cff00ffffBFL ElvUI:|r Direct call skipped (E.initialized=false)")
	end
end

function ElvUISkin:SkinFrames(E, S)
	if not _G.BetterFriendsFrame then return end

	-- Ensure Tab Text is centered (Hook for updates)
	if not self.TabHookInstalled then
		local function FixTabCenter(tab)
			if tab and tab:GetName() then
				local name = tab:GetName()
				if string.find(name, "BetterFriendsFrameTab") or 
				   string.find(name, "BetterFriendlistSettingsFrameTab") or 
				   string.find(name, "BetterFriendsFrameBottomTab") then
					local text = tab.Text or (tab.GetFontString and tab:GetFontString())
					if text then
						text:ClearAllPoints()
						text:SetPoint("CENTER", tab, "CENTER", 0, 0)
					end
				end
			end
		end

		if _G.PanelTemplates_SelectTab then
			hooksecurefunc("PanelTemplates_SelectTab", FixTabCenter)
		end
		if _G.PanelTemplates_DeselectTab then
			hooksecurefunc("PanelTemplates_DeselectTab", FixTabCenter)
		end
		
		self.TabHookInstalled = true
	end

	BFL:DebugPrint("ElvUISkin: SkinFrames started")
	local frame = _G.BetterFriendsFrame

	-- Skin Main Frame
	BFL:DebugPrint("ElvUISkin: Skinning Main Frame")
	if frame.PortraitContainer or frame.portrait then
		-- Use pcall to safeguard against ElvUI PixelPerfect errors (nil comparisons) 
		-- in case the frame isn't fully dimensioned yet
		pcall(function() S:HandlePortraitFrame(frame) end)
	end

	-- Skin Portrait Button (Changelog)
	if frame.PortraitButton then
		BFL:DebugPrint("ElvUISkin: Skinning PortraitButton")
		local button = frame.PortraitButton
		
		-- Classic: Hide portrait when ElvUI active and NOT in Simple Mode
		-- (Changelog will be accessible via Contacts Menu instead)
		local shouldSkinPortrait = true
		if BFL.IsClassic then
			local DB = BFL:GetModule("DB")
			local simpleMode = DB and DB:Get("simpleMode", false) or false
			if not simpleMode then
				button:Hide()
				shouldSkinPortrait = false
			end
		end
		
		if shouldSkinPortrait then
			-- Reset position and size to fit ElvUI style
			button:ClearAllPoints()
			button:SetPoint("TOPLEFT", frame, "TOPLEFT", 4, -4)
			button:SetSize(42, 42) -- Standard ElvUI icon size (square)
			button:SetFrameLevel(frame:GetFrameLevel() + 5)
		
			-- Create Backdrop
			button:CreateBackdrop("Transparent")
			
			-- Handle Icon
			if BFL.IsClassic then
				-- Classic: Hide the old circular icon and create a new square one
				if button.Icon then
					button.Icon:Hide()
				end
				
				-- Create new square icon without mask
				if not button.ElvUIIcon then
					button.ElvUIIcon = button:CreateTexture(nil, "ARTWORK")
					button.ElvUIIcon:SetTexture("Interface\\AddOns\\BetterFriendlist\\Textures\\PortraitIcon.blp")
				end
				button.ElvUIIcon:ClearAllPoints()
				button.ElvUIIcon:SetInside(button.backdrop)
				button.ElvUIIcon:SetTexCoord(unpack(E.TexCoords)) -- Square crop
				button.ElvUIIcon:Show()
				
				-- Reference for consistency
				button.Icon = button.ElvUIIcon
			elseif not button.Icon then
				-- Retail: Create a new texture
				button.Icon = button:CreateTexture(nil, "ARTWORK")
				button.Icon:SetInside(button.backdrop)
				button.Icon:SetTexture("Interface\\AddOns\\BetterFriendlist\\Textures\\PortraitIcon.blp")
				button.Icon:SetTexCoord(unpack(E.TexCoords))
				button.Icon:Show()
			end
			
			-- Hide original icon and mask (if different from button.Icon)
			if frame.PortraitIcon and frame.PortraitIcon ~= button.Icon then 
				frame.PortraitIcon:Hide() 
			end
			if frame.PortraitMask then frame.PortraitMask:Hide() end
			
			-- Handle Glow (New Version Indicator)
			if button.Glow then
				button.Glow:SetParent(button)
				button.Glow:ClearAllPoints()
				button.Glow:SetInside(button.backdrop)
				button.Glow:SetDrawLayer("OVERLAY")
				-- Use a cleaner glow texture for ElvUI
				button.Glow:SetTexture(E.Media.Textures.Highlight) 
				button.Glow:SetVertexColor(1, 0.82, 0, 0.5)
			end
			
			-- Add Hover Effect
			button:HookScript("OnEnter", function(self)
				if self.backdrop then
					local color = E.media.rgbvaluecolor
					if color then
						self.backdrop:SetBackdropBorderColor(color.r, color.g, color.b)
					end
				end
			end)
			
			button:HookScript("OnLeave", function(self)
				if self.backdrop then
					local color = E.media.bordercolor
					if color then
						self.backdrop:SetBackdropBorderColor(unpack(color))
					end
				end
			end)
		end
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
				text:SetPoint("CENTER", tab, "CENTER", 0, 0) -- Text centered
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
		SkinScrollBar(S, frame.RecentAlliesFrame.ScrollBar)
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
			SkinScrollBar(S, frame.IgnoreListWindow.ScrollBar)
		end
		
		if frame.IgnoreListWindow.UnignorePlayerButton then
			S:HandleButton(frame.IgnoreListWindow.UnignorePlayerButton)
		end
	end

	-- Skin ScrollBars
	BFL:DebugPrint("ElvUISkin: Skinning ScrollBars")
	-- Friends List ScrollBar - Point 7
	
	-- Check for Retail Minimal, Standard, or Classic ScrollBar (often on ScrollFrame)
	local scrollBar = frame.MinimalScrollBar or frame.ScrollBar
	if not scrollBar and frame.ScrollFrame then
		-- Classic FauxScrollFrame often names it $parentScrollBar
		if frame.ScrollFrame.ScrollBar then
			scrollBar = frame.ScrollFrame.ScrollBar
		elseif frame.ScrollFrame:GetName() then
			scrollBar = _G[frame.ScrollFrame:GetName().."ScrollBar"]
		end
	end

	if scrollBar then
		-- Use specific handler if available
		if frame.MinimalScrollBar and S.HandleMinimalScrollBar then
			S:HandleMinimalScrollBar(frame.MinimalScrollBar)
		else
			SkinScrollBar(S, scrollBar)
		end
	else
		-- Classic: Hook InitializeClassicScrollFrame to skin ScrollBar immediately after creation
		if BFL.IsClassic then
			local FriendsList = BFL:GetModule("FriendsList")
			if FriendsList and FriendsList.InitializeClassicScrollFrame then
				hooksecurefunc(FriendsList, "InitializeClassicScrollFrame", function(self, scrollFrame)
					-- ScrollBar is created by FauxScrollFrameTemplate with name $parentScrollBar
					if scrollFrame and scrollFrame.FauxScrollFrame then
						local classicScrollBar = _G["BetterFriendsClassicScrollFrameScrollBar"]
						if classicScrollBar and not classicScrollBar.isSkinned then
							SkinScrollBar(S, classicScrollBar)
							classicScrollBar.isSkinned = true
							BFL:DebugPrint("ElvUISkin: Classic ScrollBar skinned")
						end
					end
				end)
			end
		end
	end

	-- Who Frame ScrollBar
	if frame.WhoFrame and frame.WhoFrame.ScrollBar then
		SkinScrollBar(S, frame.WhoFrame.ScrollBar)
	end
	
	-- Raid Frame ScrollBar
	if frame.RaidFrame and frame.RaidFrame.ScrollBar then
		SkinScrollBar(S, frame.RaidFrame.ScrollBar)
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
		
		-- Classic: Reposition buttons 15px to the right (already anchored to bnet, which moved)
		-- No additional changes needed as they inherit bnet's new position
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
		if frame.WhoFrame.ColumnDropdown then
			S:HandleDropDownBox(frame.WhoFrame.ColumnDropdown)
			
			-- Classic: Expand clickable button area
			if BFL.IsClassic then
				local dropdown = frame.WhoFrame.ColumnDropdown
				local name = dropdown:GetName()
				if name then
					local button = _G[name.."Button"]
					if button then
						-- Get dropdown width to match button size
						local width = dropdown:GetWidth()
						if width > 0 then
							button:SetSize(width, 24)
							button:ClearAllPoints()
							button:SetPoint("CENTER", dropdown, "CENTER", 0, 0)
						end
					end
				end
			end
		end
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
			
			-- Classic: Reduce width to make room for StatusDropdown
			if BFL.IsClassic then
				bnet:SetWidth(180)
				-- Reposition 62px from right edge (use same anchor as Core.lua for consistency)
				bnet:ClearAllPoints()
				bnet:SetPoint("TOPRIGHT", frame.FriendsTabHeader, "TOPRIGHT", -62, -27)
			end
			
			if bnet.Tag then
				bnet.Tag:SetParent(bnet.backdrop)
			end
			
			-- Set initial border color to default (not blue)
			if E.media and E.media.bordercolor then
				bnet.backdrop:SetBackdropBorderColor(unpack(E.media.bordercolor))
			end
			
			-- Add Hover Effect (like ElvUI)
			bnet:EnableMouse(true)
			bnet:SetScript("OnEnter", function(self)
				if self.backdrop then
					local c = _G.FRIENDS_BNET_NAME_COLOR
					if c then
						self.backdrop:SetBackdropBorderColor(c.r, c.g, c.b)
					end
				end
			end)
			
			bnet:SetScript("OnLeave", function(self)
				if self.backdrop then
					local c = E.media.bordercolor
					if c then
						self.backdrop:SetBackdropBorderColor(unpack(c))
					end
				end
			end)
			
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
			
			-- Classic: Position below dropdowns
			if BFL.IsClassic then
				frame.FriendsTabHeader.SearchBox:ClearAllPoints()
				frame.FriendsTabHeader.SearchBox:SetPoint("TOP", frame.FriendsTabHeader.BattlenetFrame, "BOTTOM", 0, -35)
				frame.FriendsTabHeader.SearchBox:SetPoint("LEFT", frame.Inset, "LEFT", 10, 0)
				frame.FriendsTabHeader.SearchBox:SetPoint("RIGHT", frame.Inset, "RIGHT", -10, 0)
			end
		end
		
		-- Dropdowns - Point 3: Fix width & Layout (Classic adjustments)
		-- Common function to skin and size dropdowns
		local function SkinAndSizeDropdown(dropdown, width, height)
			if not dropdown then return end
			if S.HandleDropDownBox then
				S:HandleDropDownBox(dropdown, width)
			end
			
			-- Classic uses UIDropDownMenu, Retail uses modern dropdown
			if BFL.IsClassic and UIDropDownMenu_SetWidth then
				UIDropDownMenu_SetWidth(dropdown, width)
			else
				dropdown:SetWidth(width)
			end
			dropdown:SetHeight(height)
			
			-- Also force the button to match height if needed
			local name = dropdown:GetName()
			if name then
				local button = _G[name.."Button"]
				if button then
					button:SetHeight(height)
				end
			end
		end

		if frame.FriendsTabHeader.StatusDropdown then 
			if BFL.IsClassic then
				-- Classic: Keep visual width at 38px but expand clickable area
				local dropdown = frame.FriendsTabHeader.StatusDropdown
				
				if S.HandleDropDownBox then
					S:HandleDropDownBox(dropdown, 38)
				end
				
				UIDropDownMenu_SetWidth(dropdown, 38)
				
				-- Expand the clickable button area
				local name = dropdown:GetName()
				if name then
					local button = _G[name.."Button"]
					if button then
						-- Make button fill the entire dropdown width
						button:SetSize(38, 24)
						button:ClearAllPoints()
						button:SetPoint("CENTER", dropdown, "CENTER", 0, 0)
					end
				end
				
				-- Reposition: 1px gap left of BattlenetFrame
				dropdown:ClearAllPoints()
				dropdown:SetPoint("RIGHT", frame.FriendsTabHeader.BattlenetFrame, "LEFT", -1, 0)
			else
				SkinAndSizeDropdown(frame.FriendsTabHeader.StatusDropdown, 70, 22)
			end
		end
		
		if frame.FriendsTabHeader.QuickFilterDropdown then 
			if BFL.IsClassic then
				-- Classic: Keep visual width at 38px but expand clickable area
				local dropdown = frame.FriendsTabHeader.QuickFilterDropdown
				
				if S.HandleDropDownBox then
					S:HandleDropDownBox(dropdown, 38)
				end
				
				UIDropDownMenu_SetWidth(dropdown, 38)
				
				-- Expand the clickable button area
				local name = dropdown:GetName()
				if name then
					local button = _G[name.."Button"]
					if button then
						-- Make button fill the entire dropdown width
						button:SetSize(38, 24)
						button:ClearAllPoints()
						button:SetPoint("CENTER", dropdown, "CENTER", 0, 0)
					end
				end
				
				-- Position centered in frame (3 dropdowns: 38+3+38+3+38 = 120px total width)
				-- Center at x=0 relative to frame center
				dropdown:ClearAllPoints()
				dropdown:SetPoint("BOTTOMLEFT", frame.FriendsTabHeader.BattlenetFrame, "BOTTOM", -150, -35)
			else
				-- Retail: Use smaller width (50) to fit in one row
				SkinAndSizeDropdown(frame.FriendsTabHeader.QuickFilterDropdown, 50, 30)
			end
		end
		
		if frame.FriendsTabHeader.PrimarySortDropdown then 
			if BFL.IsClassic then
				-- Classic: Keep visual width at 38px but expand clickable area
				local dropdown = frame.FriendsTabHeader.PrimarySortDropdown
				
				if S.HandleDropDownBox then
					S:HandleDropDownBox(dropdown, 38)
				end
				
				UIDropDownMenu_SetWidth(dropdown, 38)
				
				-- Expand the clickable button area
				local name = dropdown:GetName()
				if name then
					local button = _G[name.."Button"]
					if button then
						-- Make button fill the entire dropdown width
						button:SetSize(38, 24)
						button:ClearAllPoints()
						button:SetPoint("CENTER", dropdown, "CENTER", 0, 0)
					end
				end
				
				-- Anchor to QuickFilter with small gap
				dropdown:ClearAllPoints()
				dropdown:SetPoint("LEFT", frame.FriendsTabHeader.QuickFilterDropdown, "RIGHT", 3, 0)
			else
				-- Retail: Keep existing size
				SkinAndSizeDropdown(frame.FriendsTabHeader.PrimarySortDropdown, 50, 30)
				
				-- Anchor to QuickFilter with positive spacing (ElvUI removes the transparent padding)
				frame.FriendsTabHeader.PrimarySortDropdown:ClearAllPoints()
				frame.FriendsTabHeader.PrimarySortDropdown:SetPoint("LEFT", frame.FriendsTabHeader.QuickFilterDropdown, "RIGHT", 5, 0)
			end
		end
		
		if frame.FriendsTabHeader.SecondarySortDropdown then 
			if BFL.IsClassic then
				-- Classic: Keep visual width at 38px but expand clickable area
				local dropdown = frame.FriendsTabHeader.SecondarySortDropdown
				
				if S.HandleDropDownBox then
					S:HandleDropDownBox(dropdown, 38)
				end
				
				UIDropDownMenu_SetWidth(dropdown, 38)
				
				-- Expand the clickable button area
				local name = dropdown:GetName()
				if name then
					local button = _G[name.."Button"]
					if button then
						-- Make button fill the entire dropdown width
						button:SetSize(38, 24)
						button:ClearAllPoints()
						button:SetPoint("CENTER", dropdown, "CENTER", 0, 0)
					end
				end
				
				-- Anchor to PrimarySort with small gap
				dropdown:ClearAllPoints()
				dropdown:SetPoint("LEFT", frame.FriendsTabHeader.PrimarySortDropdown, "RIGHT", 3, 0)
			else
				-- Retail: Keep existing size
				SkinAndSizeDropdown(frame.FriendsTabHeader.SecondarySortDropdown, 50, 30)
				
				-- Anchor to PrimarySort
				frame.FriendsTabHeader.SecondarySortDropdown:ClearAllPoints()
				frame.FriendsTabHeader.SecondarySortDropdown:SetPoint("LEFT", frame.FriendsTabHeader.PrimarySortDropdown, "RIGHT", 5, 0)
			end
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
				 SkinScrollBar(S, frame.QuickJoinFrame.ContentInset.ScrollBar)
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
	xpcall(function() self:SkinSettings(E, S) end, function(err) BFL:DebugPrint("ElvUISkin: Error skinning Settings: " .. tostring(err)) end)
	
	-- Skin Notifications
	BFL:DebugPrint("ElvUISkin: Skinning Notifications")
	self:SkinNotifications(E, S)
	
	-- Skin Broker
	BFL:DebugPrint("ElvUISkin: Skinning Broker")
	self:SkinBroker(E, S)
	
	-- Skin Context Menus
	BFL:DebugPrint("ElvUISkin: Skinning ContextMenus")
	xpcall(function() self:SkinContextMenus(E, S) end, function(err) print("|cffff0000BetterFriendlist ElvUI Menu Error:|r " .. tostring(err)) end)

	-- Skin Changelog
	BFL:DebugPrint("ElvUISkin: Skinning Changelog")
	xpcall(function() self:SkinChangelog(E, S) end, function(err) BFL:DebugPrint("ElvUISkin: Error skinning Changelog: " .. tostring(err)) end)
	
	-- Skin HelpFrame
	BFL:DebugPrint("ElvUISkin: Skinning HelpFrame")
	xpcall(function() self:SkinHelpFrame(E, S) end, function(err) BFL:DebugPrint("ElvUISkin: Error skinning HelpFrame: " .. tostring(err)) end)

	-- Apply FontFix after Skinning to ensure correct font sizes
	local FontFix = BFL:GetModule("FontFix")
	if FontFix then
		BFL:DebugPrint("ElvUISkin: Re-applying FontFix")
		FontFix:ApplyFixedFonts()
	end

	BFL:DebugPrint("ElvUI Skin applied to BetterFriendlist")
end

function ElvUISkin:HookFriendsList(E, S)
	local FriendsList = BFL:GetModule("FriendsList")
	if not FriendsList then return end
	
	-- Hook Group Header
	hooksecurefunc(FriendsList, "UpdateGroupHeaderButton", function(_, button, elementData)
		if not button.isSkinned then
			S:HandleButton(button)
			-- Strip the custom background texture if it exists
			if button.BG then button.BG:SetTexture(nil) end
			button.isSkinned = true
		end
	end)
	
	-- Hook Friend Button
	hooksecurefunc(FriendsList, "UpdateFriendButton", function(_, button, elementData)
		if not button.isSkinned then
			-- Don't full skin friend buttons as they are list items
			-- BFL: Travelpass button should NOT be skinned (User request)
			-- But we can skin the travel pass button in Retail only (not in Classic)
			-- if not BFL.IsClassic and button.travelPassButton then
			-- 	S:HandleButton(button.travelPassButton)
			-- 	-- Ensure icon remains visible and sized correctly
			-- 	if button.travelPassButton.NormalTexture then
			-- 		button.travelPassButton.NormalTexture:SetAlpha(1)
			-- 		button.travelPassButton.NormalTexture:SetSize(22, 22)
			-- 		button.travelPassButton.NormalTexture:SetPoint("CENTER")
			-- 	end
			-- end
			button.isSkinned = true
		end
	end)
	
	-- Hook Invite Header
	hooksecurefunc(FriendsList, "UpdateInviteHeaderButton", function(_, button, elementData)
		if not button.isSkinned then
			S:HandleButton(button)
			button.isSkinned = true
		end
	end)
	
	-- Hook Invite Button
	hooksecurefunc(FriendsList, "UpdateInviteButton", function(_, button, elementData)
		if not button.isSkinned then
			if button.AcceptButton then S:HandleButton(button.AcceptButton) end
			if button.DeclineButton then S:HandleButton(button.DeclineButton) end
			button.isSkinned = true
		end
	end)
end

function ElvUISkin:SkinRecruitAFriend(E, S, frame)
	local raf = frame.RecruitAFriendFrame
	if not raf then return end

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
			SkinScrollBar(S, raf.RecruitList.ScrollBar)
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
end

function ElvUISkin:SkinSettings(E, S)
	local frame = _G.BetterFriendlistSettingsFrame
	if not frame then return end
	
	S:HandlePortraitFrame(frame)
	
	-- Skin Tabs (Top) - Point 4: Adjust height
	for i = 1, 10 do
		local tab = _G["BetterFriendlistSettingsFrameTab"..i]
		if tab then
			-- Fixed: Removed IsShown() check to ensure all tabs (including Beta/Global Sync)
			-- are skinned even if hidden during initial load. 
			-- Tabs should exist if XML defines them.
			S:HandleTab(tab)
			tab:SetHeight(28) -- Fixed height
			
			local text = tab.Text or (tab.GetFontString and tab:GetFontString())
			if text then
				text:ClearAllPoints()
				text:SetPoint("CENTER", tab, "CENTER", 0, 0)
			end
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
		local function SkinEditBoxesInTab(tab)
			if not tab or not tab.components then return end
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
		end

		-- Hook RefreshTabs to ensure tabs stay skinned after visibility changes
		-- RefreshTabs calls PanelTemplates_UpdateTabs which might restore textures
		hooksecurefunc(Settings, "RefreshTabs", function()
			-- Adjust Tab1 Position (2px lower to fit ElvUI header better)
			local tab1 = _G["BetterFriendlistSettingsFrameTab1"]
			if tab1 then
				tab1:ClearAllPoints()
				tab1:SetPoint("TOPLEFT", _G.BetterFriendlistSettingsFrame, "TOPLEFT", 6, -19)
			end

			for i = 1, 10 do
				local tab = _G["BetterFriendlistSettingsFrameTab"..i]
				if tab and tab:IsShown() then
					S:HandleTab(tab)
					tab:SetHeight(28)
					
					local text = tab.Text or (tab.GetFontString and tab:GetFontString())
					if text then
						text:ClearAllPoints()
						text:SetPoint("CENTER", tab, "CENTER", 0, 0)
					end
				end
			end
			
			-- Adjust Tab Spacing for ElvUI (Gap between rows)
			local tab1 = _G["BetterFriendlistSettingsFrameTab1"]
			local tab6 = _G["BetterFriendlistSettingsFrameTab6"]
			
			if tab1 and tab6 and tab6:IsShown() then
				tab6:ClearAllPoints()
				-- Create a 0px gap between rows (negative Y)
				tab6:SetPoint("TOPLEFT", tab1, "BOTTOMLEFT", 0, 0)
			end
		end)

		hooksecurefunc(Settings, "RefreshGeneralTab", function()
			local content = frame.ContentScrollFrame.Content
			if content and content.GeneralTab then
				SkinEditBoxesInTab(content.GeneralTab)
			end
		end)

		hooksecurefunc(Settings, "RefreshNotificationsTab", function()
			local content = frame.ContentScrollFrame.Content
			if content and content.NotificationsTab then
				SkinEditBoxesInTab(content.NotificationsTab)
			end
		end)
		
		-- Hook Global Sync Tab (Point 5: Skin dynamic headers and buttons)
		hooksecurefunc(Settings, "RefreshGlobalSyncTab", function()
			local content = frame.ContentScrollFrame.Content
			if content and content.GlobalSyncTab then
				local tab = content.GlobalSyncTab
				
				-- Skin Layout Headers (if they weren't caught by CreateHeader hook)
				-- We can iterate children to find unskinned buttons or headers
				local children = {tab:GetChildren()}
				for _, child in ipairs(children) do
					-- Case 1: Direct Button (unlikely in Global Sync, but possible)
					if child:IsObjectType("Button") and not child.isSkinned then
						-- Filter for the small action buttons (size 20x20 usually)
						local w, h = child:GetSize()
						if w < 30 and h < 30 then
							S:HandleButton(child)
							child.isSkinned = true
						end
					
					-- Case 2: Row Frame containing Button
					elseif child:IsObjectType("Frame") then
						-- Check children of the row for the action button
						local rowChildren = {child:GetChildren()}
						for _, btn in ipairs(rowChildren) do
							-- Skin Buttons (except Edit Note button which has a specific texture)
							if btn:IsObjectType("Button") and not btn.isSkinned then
								local w, h = btn:GetSize()
								if w < 30 and h < 30 then
									-- Check for Edit Note Icon
									local icon = btn:GetNormalTexture()
									local iconPath = icon and icon:GetTexture()
									local isEditNote = iconPath and (type(iconPath) == "string" and string.find(iconPath, "UI%-GuildButton%-PublicNote"))
									
									if not isEditNote then
										S:HandleButton(btn)
										btn.isSkinned = true
									end
								end
							end
						end
					end
				end
			end
		end)
	end
	
	-- Hook Components to skin dynamic elements
	if BFL.SettingsComponents then
		local C = BFL.SettingsComponents
		
		-- Checkbox
		if not C.IsSkinned then
			local oldCreateCheckbox = C.CreateCheckbox
			C.CreateCheckbox = function(...)
				local holder = oldCreateCheckbox(...)
				if holder and holder.checkBox then
					S:HandleCheckBox(holder.checkBox)
				end
				return holder
			end
			
			-- Double Checkbox
			local oldCreateDoubleCheckbox = C.CreateDoubleCheckbox
			C.CreateDoubleCheckbox = function(...)
				local holder = oldCreateDoubleCheckbox(...)
				if holder then
					if holder.LeftCheckbox then S:HandleCheckBox(holder.LeftCheckbox) end
					if holder.RightCheckbox then S:HandleCheckBox(holder.RightCheckbox) end
				end
				return holder
			end
			
			-- Slider
			local oldCreateSlider = C.CreateSlider
			C.CreateSlider = function(...)
				local holder = oldCreateSlider(...)
				if holder and holder.Slider then
					local slider = holder.Slider
					slider:StripTextures()
					slider:CreateBackdrop("Transparent")
					if slider.backdrop then
						slider.backdrop:SetPoint("TOPLEFT", 0, -5)
						slider.backdrop:SetPoint("BOTTOMRIGHT", 0, 5)
					end
					
					local thumb = slider:GetThumbTexture()
					if thumb then
						thumb:SetAlpha(0)
						if not slider.BFLThumb then
							local t = slider:CreateTexture(nil, "OVERLAY")
							t:SetTexture(E.Media.Textures.Melli or 130751)
							t:SetVertexColor(1, 0.82, 0)
							t:SetSize(10, 18)
							t:SetPoint("CENTER", thumb, "CENTER")
							slider.BFLThumb = t
						end
					end
					
					if slider.Back then 
						S:HandleNextPrevButton(slider.Back, "left") 
						slider.Back:SetSize(16, 16)
					end
					if slider.Forward then 
						S:HandleNextPrevButton(slider.Forward, "right") 
						slider.Forward:SetSize(16, 16)
					end
				end
				return holder
			end
			
			-- SliderWithColorPicker
			local oldCreateSliderColor = C.CreateSliderWithColorPicker
			C.CreateSliderWithColorPicker = function(...)
				local holder = oldCreateSliderColor(...)
				if holder and holder.Slider then
					-- Aggressive Skinning for MinimalSliderWithSteppersTemplate
					local slider = holder.Slider
					
					-- 1. Strip all textures (removes default Blizzard borders/track art)
					slider:StripTextures()
					
					-- 2. Create proper ElvUI Backdrop (The Track)
					slider:CreateBackdrop("Transparent")
					if slider.backdrop then
						slider.backdrop:SetPoint("TOPLEFT", 0, -5) -- Adjust height of track
						slider.backdrop:SetPoint("BOTTOMRIGHT", 0, 5)
					end
					
					-- 3. Handle Thumb
					local thumb = slider:GetThumbTexture()
					if thumb then
						thumb:SetAlpha(0) -- Hide default geometry
						
						if not slider.BFLThumb then
							local t = slider:CreateTexture(nil, "OVERLAY")
							t:SetTexture(E.Media.Textures.Melli or 130751)
							t:SetVertexColor(1, 0.82, 0)
							t:SetSize(10, 18)
							t:SetPoint("CENTER", thumb, "CENTER")
							slider.BFLThumb = t
						end
					end

					-- 4. Skin Stepper Buttons
					if slider.Back then 
						S:HandleNextPrevButton(slider.Back, "left") 
						slider.Back:SetSize(16, 16) -- Force size
					end
					if slider.Forward then 
						S:HandleNextPrevButton(slider.Forward, "right") 
						slider.Forward:SetSize(16, 16)
					end
				end
				return holder
			end
			
			-- Dropdown
			local oldCreateDropdown = C.CreateDropdown
			C.CreateDropdown = function(...)
				local holder = oldCreateDropdown(...)
				if holder and holder.DropDown then
					S:HandleDropDownBox(holder.DropDown)
				end
				return holder
			end
			
			-- Button
			local oldCreateButton = C.CreateButton
			C.CreateButton = function(...)
				local button = oldCreateButton(...)
				if button then
					S:HandleButton(button)
				end
				return button
			end
			
			-- List Item (Group Management)
			local oldCreateListItem = C.CreateListItem
			C.CreateListItem = function(...)
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
				return holder
			end
			
			C.IsSkinned = true
		end
	end
end

function ElvUISkin:SkinNotifications(E, S)
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
end

function ElvUISkin:SkinBroker(E, S)
	-- Hook LibQTip to skin tooltips
	local LQT = LibStub("LibQTip-1.0", true)
	if LQT and not LQT.IsSkinnedByBFL then
		local oldAcquire = LQT.Acquire
		LQT.Acquire = function(self, key, ...)
			local tooltip = oldAcquire(self, key, ...)
			if key == "BetterFriendlistBrokerTT" or key == "BetterFriendlistBrokerDetailTT" then
				if not tooltip.isSkinned then
					tooltip:StripTextures()
					tooltip:CreateBackdrop("Transparent")
					tooltip.isSkinned = true
				end
			end
			return tooltip
		end
		LQT.IsSkinnedByBFL = true
	end
end

function ElvUISkin:SkinContextMenus(E, S)
	-- Hook MenuUtil to skin context menus
	if not MenuUtil then return end
	
	-- Helper to skin a single frame in the menu
	local function SkinMenuFrame(frame)
		if not frame then return end
		
		-- Recursive search for CheckButtons and Checkbox-like Buttons
		local function FindAndSkin(obj, depth)
			if not obj then return end
			depth = depth or 0
			if depth > 15 then return end -- Prevent infinite recursion
			
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
							
							local function UpdateCheck()
								if checkmarkRegion:IsShown() then
									obj.BFLCheckmark:Show()
								else
									obj.BFLCheckmark:Hide()
								end
							end
							
							hooksecurefunc(checkmarkRegion, "Show", UpdateCheck)
							hooksecurefunc(checkmarkRegion, "Hide", UpdateCheck)
							hooksecurefunc(checkmarkRegion, "SetShown", UpdateCheck)
							UpdateCheck()
						else
							-- Case B: Texture Swap on Background Region (or checkmark not found yet)
							-- We hook the background region to see if it turns into a checkmark
							local function UpdateTexture(self)
								if not obj.BFLCheckmark then return end
								
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
							end
							
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
		end
		
		FindAndSkin(frame)
	end
	
	-- Hook Menu Manager to catch ALL menus (including submenus)
	local function HookMenuManager()
		if BFL.MenuManagerHooked then return end
		
		if Menu and Menu.GetManager then
			local manager = Menu.GetManager()
			if manager and manager.OpenMenu then
				hooksecurefunc(manager, "OpenMenu", function(self, menu)
					-- Wait a frame for the menu to be created and populated
					C_Timer.After(0.05, function()
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
										pcall(function()
											openMenu.ScrollBox:RegisterCallback("OnAcquiredFrame", function(o, frame, elementData, isNew)
												SkinMenuFrame(frame)
											end, self)
										end)
									end
								end
							end
							
							-- Always scan the menu for items (initial population)
							SkinMenuFrame(openMenu)
						end
					end)
				end)
				BFL.MenuManagerHooked = true
				-- BFL:DebugPrint("BFL: Hooked Menu Manager for SubMenus")
			end
		end
	end

	-- Try to hook immediately
	HookMenuManager()
	
	-- Also hook CreateContextMenu as a backup/trigger
	hooksecurefunc(MenuUtil, "CreateContextMenu", function(owner, generator)
		HookMenuManager() -- Retry hooking if it wasn't ready
	end)
end

function ElvUISkin:SkinChangelog(E, S)
	local Changelog = BFL:GetModule("Changelog")
	if not Changelog then return end

	local function Skin()
		local frame = _G.BetterFriendlistChangelogFrame
		if not frame or frame.isSkinned then return end
		
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
			SkinScrollBar(S, frame.ScrollBar)
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
	end

	hooksecurefunc(Changelog, "CreateChangelogWindow", Skin)
	Skin()
end

function ElvUISkin:SkinHelpFrame(E, S)
	local HelpFrame = BFL.HelpFrame or BFL:GetModule("HelpFrame")
	if not HelpFrame then return end

	local function Skin()
		local frame = _G.BetterFriendlistHelpFrame
		if not frame or frame.isSkinned then return end
		
		BFL:DebugPrint("ElvUISkin: Skinning HelpFrame")
		S:HandlePortraitFrame(frame)
		
		-- Skin Inset if it exists (ButtonFrameTemplate feature)
		if frame.Inset then
			frame.Inset:StripTextures()
			frame.Inset:CreateBackdrop("Transparent")
		end
		
		-- Skin ScrollBar
		if frame.ScrollBar then
			SkinScrollBar(S, frame.ScrollBar)
		elseif frame.ScrollFrame then
			-- Classic fallback or when using UIPanelScrollFrame
			if frame.ScrollFrame.ScrollBar then
				SkinScrollBar(S, frame.ScrollFrame.ScrollBar)
			elseif frame.ScrollFrame:GetName() then
				local scrollBar = _G[frame.ScrollFrame:GetName().."ScrollBar"]
				if scrollBar then
					SkinScrollBar(S, scrollBar)
				end
			end
		end

		frame.isSkinned = true
	end

	-- Hook creation
	hooksecurefunc(HelpFrame, "CreateFrame", Skin)
	-- Hook toggle as well just in case CreateFrame returns early but we missed skinning
	hooksecurefunc(HelpFrame, "Toggle", Skin)
	
	-- Try to skin immediately if it exists
	if _G.BetterFriendlistHelpFrame then Skin() end
end