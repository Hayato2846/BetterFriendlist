local addonName, BFL = ...
local L = BFL.L

local StreamerMode = {}
BFL.StreamerMode = StreamerMode
BFL.Modules["StreamerMode"] = StreamerMode

function StreamerMode:Initialize()
    -- Enable Streamer Mode if DB has it active (defaults handled in Database.lua)
    self:UpdateState()
    
    -- Find the XML button
    if BetterFriendsFrame and BetterFriendsFrame.StreamerModeButton then
        self.toggleButton = BetterFriendsFrame.StreamerModeButton
    end
    
    self:UpdateState()
end

function StreamerMode:Toggle()
    BetterFriendlistDB.streamerModeActive = not BetterFriendlistDB.streamerModeActive
    self:UpdateState()
    
    -- Refresh Friends List to update names
    if BFL.ForceRefreshFriendsList then
        BFL:ForceRefreshFriendsList()
    end

    -- Refresh QuickJoin List to update names (Streamer Mode Toggled)
    local QuickJoin = BFL:GetModule("QuickJoin")
    if QuickJoin then
        QuickJoin:Update(true)
    end
    
    -- Print status
    if BetterFriendlistDB.streamerModeActive then
        BFL:DebugPrint(L.STREAMER_MODE_TITLE .. ": " .. (L.STATUS_ENABLED or "Enabled"))
    else
        BFL:DebugPrint(L.STREAMER_MODE_TITLE .. ": " .. (L.STATUS_DISABLED or "Disabled"))
    end
end

function StreamerMode:IsActive()
    return BetterFriendlistDB and BetterFriendlistDB.streamerModeActive
end

function StreamerMode:UpdateState()
    if not self.toggleButton then 
        -- Try to find it again (if loaded late)
        if BetterFriendsFrame and BetterFriendsFrame.StreamerModeButton then
            self.toggleButton = BetterFriendsFrame.StreamerModeButton
        else
            return 
        end
    end

    -- Check Visibility Setting
    if not BetterFriendlistDB.showStreamerModeButton then
        self.toggleButton:Hide()
        return
    else
        self.toggleButton:Show()
    end
    
    if self:IsActive() then
        -- Privacy ON -> Twitch Purple (Active)
        self.toggleButton.Icon:SetTexture("Interface\\AddOns\\BetterFriendlist\\Icons\\twitch")
        self.toggleButton.Icon:SetDesaturated(true) -- Desaturate to remove native icon color (likely gold/orange)
        self.toggleButton.Icon:SetVertexColor(0.64, 0.33, 1.0) -- Twitch Purple
        self.toggleButton.Icon:SetAlpha(1.0)
        
        -- Update Header Text if parent frame exists
        if BetterFriendsFrame and BetterFriendsFrame.FriendsTabHeader and BetterFriendsFrame.FriendsTabHeader.BattlenetFrame then
             local battlenetFrame = BetterFriendsFrame.FriendsTabHeader.BattlenetFrame
             local header = battlenetFrame.Tag
             if header then
                 -- Don't store original text if we just set it ourselves previously
                 if header:GetText() ~= BetterFriendlistDB.streamerModeHeaderText then
                    self.originalHeaderText = header:GetText()
                 end
                 header:SetText(BetterFriendlistDB.streamerModeHeaderText)
             end
        end
    else
        -- Privacy OFF -> Gray (Inactive)
        self.toggleButton.Icon:SetTexture("Interface\\AddOns\\BetterFriendlist\\Icons\\twitch")
        self.toggleButton.Icon:SetDesaturated(true) -- Force Grayscale
        self.toggleButton.Icon:SetVertexColor(1, 1, 1) -- White vertex + Desaturated = Pure Gray
        self.toggleButton.Icon:SetAlpha(0.7)
        
        -- Restore Header Text & Color
        if BetterFriendsFrame and BetterFriendsFrame.FriendsTabHeader and BetterFriendsFrame.FriendsTabHeader.BattlenetFrame then
            local battlenetFrame = BetterFriendsFrame.FriendsTabHeader.BattlenetFrame
            local header = battlenetFrame.Tag
            
            if header and self.originalHeaderText then
                -- Try to restore original text, but BNet frame might update itself
                -- Force a check of BNet info to get the real tag back
                if BNGetInfo then
                     local _, battleTag = BNGetInfo()
                     if battleTag then 
                        header:SetText(battleTag) 
                     elseif self.originalHeaderText ~= BetterFriendlistDB.streamerModeHeaderText then
                        header:SetText(self.originalHeaderText)
                     end
                end
            end
        end
    end
end
