-- UI/FrameInitializer.lua
-- Handles UI initialization for BetterFriendlist frames
-- Extracted from BetterFriendlist.lua to reduce main file complexity

local ADDON_NAME, BFL = ...

-- Module registration
local FrameInitializer = {
	name = "FrameInitializer",
	initialized = false
}

-- Current sort mode tracking (for Sort Dropdown)
local currentSortMode = "status"

--------------------------------------------------------------------------
-- STATUS DROPDOWN INITIALIZATION
--------------------------------------------------------------------------

function FrameInitializer:InitializeStatusDropdown(frame)
	if not frame or not frame.FriendsTabHeader or not frame.FriendsTabHeader.StatusDropdown then return end
	
	local dropdown = frame.FriendsTabHeader.StatusDropdown
	
	-- Set up status tracking
	local bnetAFK, bnetDND = select(5, BNGetInfo())
	local bnStatus
	if bnetAFK then
		bnStatus = FRIENDS_TEXTURE_AFK
	elseif bnetDND then
		bnStatus = FRIENDS_TEXTURE_DND
	else
		bnStatus = FRIENDS_TEXTURE_ONLINE
	end
	
	local function IsSelected(status)
		return bnStatus == status
	end
	
	local function SetSelected(status)
		if status ~= bnStatus then
			bnStatus = status
			
			if status == FRIENDS_TEXTURE_ONLINE then
				BNSetAFK(false)
				BNSetDND(false)
			elseif status == FRIENDS_TEXTURE_AFK then
				BNSetAFK(true)
			elseif status == FRIENDS_TEXTURE_DND then
				BNSetDND(true)
			end
		end
	end
	
	local function CreateRadio(rootDescription, text, status)
		local radio = rootDescription:CreateButton(text, function() end, status)
		radio:SetIsSelected(IsSelected)
		radio:SetResponder(SetSelected)
	end
	
	dropdown:SetWidth(51)
	dropdown:SetupMenu(function(dropdown, rootDescription)
		rootDescription:SetTag("MENU_FRIENDS_STATUS")
		
		local optionText = "|T%s.tga:16:16:0:0|t %s"
		
		local onlineText = string.format(optionText, FRIENDS_TEXTURE_ONLINE, FRIENDS_LIST_AVAILABLE)
		CreateRadio(rootDescription, onlineText, FRIENDS_TEXTURE_ONLINE)
		
		local afkText = string.format(optionText, FRIENDS_TEXTURE_AFK, FRIENDS_LIST_AWAY)
		CreateRadio(rootDescription, afkText, FRIENDS_TEXTURE_AFK)
		
		local dndText = string.format(optionText, FRIENDS_TEXTURE_DND, FRIENDS_LIST_BUSY)
		CreateRadio(rootDescription, dndText, FRIENDS_TEXTURE_DND)
	end)
	
	dropdown:SetSelectionTranslator(function(selection)
		return string.format("|T%s.tga:16:16:0:0|t", selection.data)
	end)
	
	-- Generate menu once to trigger initial selection display
	-- This ensures the dropdown shows the current status icon on load
	dropdown:GenerateMenu()
	
	-- Set up tooltip
	dropdown:SetScript("OnEnter", function()
		local statusText
		if bnStatus == FRIENDS_TEXTURE_ONLINE then
			statusText = FRIENDS_LIST_AVAILABLE
		elseif bnStatus == FRIENDS_TEXTURE_AFK then
			statusText = FRIENDS_LIST_AWAY
		elseif bnStatus == FRIENDS_TEXTURE_DND then
			statusText = FRIENDS_LIST_BUSY
		end
		
		GameTooltip:SetOwner(dropdown, "ANCHOR_RIGHT", -18, 0)
		GameTooltip:SetText(string.format(FRIENDS_LIST_STATUS_TOOLTIP, statusText))
		GameTooltip:Show()
	end)
	dropdown:SetScript("OnLeave", GameTooltip_Hide)
end

--------------------------------------------------------------------------
-- SORT DROPDOWN INITIALIZATION
--------------------------------------------------------------------------

function FrameInitializer:InitializeSortDropdown(frame)
	if not frame or not frame.FriendsTabHeader or not frame.FriendsTabHeader.SortDropdown then return end
	
	local dropdown = frame.FriendsTabHeader.SortDropdown
	
	local function IsSelected(sortMode)
		return currentSortMode == sortMode
	end
	
	local function SetSelected(sortMode)
		if sortMode ~= currentSortMode then
			currentSortMode = sortMode
			-- Notify main file to update display
			if _G.UpdateFriendsList then _G.UpdateFriendsList() end
			if _G.UpdateFriendsDisplay then _G.UpdateFriendsDisplay() end
		end
	end
	
	local function CreateRadio(rootDescription, text, sortMode)
		local radio = rootDescription:CreateButton(text, function() end, sortMode)
		radio:SetIsSelected(IsSelected)
		radio:SetResponder(SetSelected)
	end
	
	dropdown:SetWidth(120)
	dropdown:SetupMenu(function(dropdown, rootDescription)
		rootDescription:SetTag("MENU_FRIENDS_SORT")
		
		CreateRadio(rootDescription, "Sort by Status", "status")
		CreateRadio(rootDescription, "Sort by Name", "name")
		CreateRadio(rootDescription, "Sort by Level", "level")
		CreateRadio(rootDescription, "Sort by Zone", "zone")
	end)
	
	dropdown:SetSelectionTranslator(function(selection)
		if selection.data == "status" then
			return "Sort: Status"
		elseif selection.data == "name" then
			return "Sort: Name"
		elseif selection.data == "level" then
			return "Sort: Level"
		elseif selection.data == "zone" then
			return "Sort: Zone"
		end
		return "Sort"
	end)
	
	-- Set up tooltip
	dropdown:SetScript("OnEnter", function()
		GameTooltip:SetOwner(dropdown, "ANCHOR_RIGHT")
		GameTooltip:SetText("Sort Friends List")
		GameTooltip:AddLine("Choose how to sort your friends list", 1, 1, 1)
		GameTooltip:Show()
	end)
	dropdown:SetScript("OnLeave", GameTooltip_Hide)
end

-- Get current sort mode (for external access)
function FrameInitializer:GetSortMode()
	return currentSortMode
end

-- Set current sort mode (for external access)
function FrameInitializer:SetSortMode(mode)
	currentSortMode = mode or "status"
end

--------------------------------------------------------------------------
-- TABS INITIALIZATION
--------------------------------------------------------------------------

function FrameInitializer:InitializeTabs(frame)
	if not frame or not frame.FriendsTabHeader then return end
	
	-- Set up the tabs on the FriendsTabHeader (11.2.5: 4 tabs - Friends, Recent Allies, RAF, Sort)
	PanelTemplates_SetNumTabs(frame.FriendsTabHeader, 4)
	PanelTemplates_SetTab(frame.FriendsTabHeader, 1)
	PanelTemplates_UpdateTabs(frame.FriendsTabHeader)
end

--------------------------------------------------------------------------
-- BROADCAST FRAME SETUP
--------------------------------------------------------------------------

function FrameInitializer:SetupBroadcastFrame(frame)
	local broadcastFrame = frame and frame.FriendsTabHeader and frame.FriendsTabHeader.BattlenetFrame and frame.FriendsTabHeader.BattlenetFrame.BroadcastFrame
	if not broadcastFrame then return end
	
	-- ToggleFrame method
	function broadcastFrame:ToggleFrame()
		PlaySound(SOUNDKIT.IG_CHAT_EMOTE_BUTTON)
		if self:IsShown() then
			self:HideFrame()
		else
			self:ShowFrame()
		end
	end
	
	-- ShowFrame method
	function broadcastFrame:ShowFrame()
		if self:IsShown() then return end
		self:Show()
		
		-- Update broadcast text
		local _, _, _, broadcastText = BNGetInfo()
		if self.EditBox then
			self.EditBox:SetText(broadcastText or "")
		end
		
		-- Focus edit box
		if self.EditBox then
			self.EditBox:SetFocus()
		end
	end
	
	-- HideFrame method
	function broadcastFrame:HideFrame()
		if not self:IsShown() then return end
		self:Hide()
		
		-- Clear focus
		if self.EditBox then
			self.EditBox:ClearFocus()
		end
	end
	
	-- Update broadcast display
	function broadcastFrame:UpdateBroadcast()
		local _, _, _, broadcastText = BNGetInfo()
		if self.EditBox then
			self.EditBox:SetText(broadcastText or "")
		end
	end
	
	-- SetBroadcast method (called by Update button and Enter key)
	function broadcastFrame:SetBroadcast()
		if not self.EditBox then return end
		
		local text = self.EditBox:GetText() or ""
		
		-- Set the broadcast message using BattleNet API
		BNSetCustomMessage(text)
		
		-- Hide the frame
		self:HideFrame()
		
		-- Play sound
		PlaySound(SOUNDKIT.IG_CHAT_EMOTE_BUTTON)
	end
end

--------------------------------------------------------------------------
-- BATTLE.NET FRAME INITIALIZATION
--------------------------------------------------------------------------

function FrameInitializer:InitializeBattlenetFrame(frame)
	if not frame or not frame.FriendsTabHeader or not frame.FriendsTabHeader.BattlenetFrame then return end
	
	local bnetFrame = frame.FriendsTabHeader.BattlenetFrame
	
	-- Setup BroadcastFrame methods first
	self:SetupBroadcastFrame(frame)
	
	if BNFeaturesEnabled() then
		if BNConnected() then
			-- Update broadcast display
			if bnetFrame.BroadcastFrame and bnetFrame.BroadcastFrame.UpdateBroadcast then
				bnetFrame.BroadcastFrame:UpdateBroadcast()
			end
			
			-- Get and display BattleTag
			local _, battleTag = BNGetInfo()
			if battleTag then
				-- Format battle tag with colored suffix (like Blizzard does)
				local symbol = string.find(battleTag, "#")
				if symbol then
					local suffix = string.sub(battleTag, symbol)
					battleTag = string.sub(battleTag, 1, symbol - 1).."|cff416380"..suffix.."|r"
				end
				bnetFrame.Tag:SetText(battleTag)
				bnetFrame.Tag:Show()
				bnetFrame:Show()
			else
				bnetFrame:Hide()
			end
			
			bnetFrame.UnavailableLabel:Hide()
			-- Show Contacts Menu Button (11.2.5 - replaces old BroadcastButton)
			if bnetFrame.ContactsMenuButton then
				bnetFrame.ContactsMenuButton:Show()
			end
		else
			-- Battle.net not connected
			bnetFrame:Show()
			bnetFrame.Tag:Hide()
			bnetFrame.UnavailableLabel:Show()
			-- Hide Contacts Menu Button when not connected
			if bnetFrame.ContactsMenuButton then
				bnetFrame.ContactsMenuButton:Hide()
			end
		end
	end
end

--------------------------------------------------------------------------
-- MAIN INITIALIZATION
--------------------------------------------------------------------------

function FrameInitializer:Initialize(frame)
	if self.initialized then return end
	if not frame then return end
	
	self:InitializeStatusDropdown(frame)
	self:InitializeSortDropdown(frame)
	self:InitializeTabs(frame)
	self:InitializeBattlenetFrame(frame)
	
	self.initialized = true
end

-- Reset initialization state (for reloads)
function FrameInitializer:Reset()
	self.initialized = false
end

-- Register module with BFL
BFL.FrameInitializer = FrameInitializer
