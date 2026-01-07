local _, BFL = ...
local GuildDetails = BFL:RegisterModule("GuildDetails", {})
local L = BFL.L

-- Constants from Blizzard's GuildFrame
local GUILD_DETAIL_NORM_HEIGHT = 195
local GUILD_DETAIL_OFFICER_HEIGHT = 255
local FRIENDS_LEVEL_TEMPLATE = FRIENDS_LEVEL_TEMPLATE or "Level %d %s"

function GuildDetails:Initialize()
    self.frame = BFL_GuildMemberDetailFrame
    if self.frame then
        self.frame:Hide()
        -- Hook standard static popups if needed, or rely on Blizzard's
    end
end

function GuildDetails:ShowForMember(guildIndex)
    if not self.frame then return end
    
    if guildIndex == 0 or not guildIndex then
        self.frame:Hide()
        return
    end
    
    local fullName, rank, rankIndex, level, class, zone, note, 
          officernote, online = GetGuildRosterInfo(guildIndex)
    
    if not fullName then
        self.frame:Hide()
        return
    end
    
    self.currentIndex = guildIndex
    local displayedName = Ambiguate(fullName, "guild")
    
    -- Update frame texts
    if BFL_GuildMemberDetailName then
        BFL_GuildMemberDetailName:SetText(displayedName)
    end
    if BFL_GuildMemberDetailLevel then
        BFL_GuildMemberDetailLevel:SetText(format(FRIENDS_LEVEL_TEMPLATE, level, class))
    end
    if BFL_GuildMemberDetailZoneText then
        BFL_GuildMemberDetailZoneText:SetText(zone)
    end
    if BFL_GuildMemberDetailRankText then
        BFL_GuildMemberDetailRankText:SetText(rank)
    end
    
    -- Last online
    if BFL_GuildMemberDetailOnlineText then
        if online then
            BFL_GuildMemberDetailOnlineText:SetText(GUILD_ONLINE_LABEL or "Online")
        else
            if BFL.GuildRoster and BFL.GuildRoster.GetLastOnlineText then
                BFL_GuildMemberDetailOnlineText:SetText(BFL.GuildRoster:GetLastOnlineText(guildIndex))
            else
                BFL_GuildMemberDetailOnlineText:SetText("Offline")
            end
        end
    end
    
    -- Public note
    self:UpdatePublicNote(note)
    
    -- Officer note
    self:UpdateOfficerNote(officernote)
    
    -- Promote/Demote buttons
    self:UpdatePromoteDemote(rankIndex, online, displayedName)
    
    -- Remove/Invite buttons
    self:UpdateActionButtons(rankIndex, online, displayedName)
    
    self.frame:Show()
end

function GuildDetails:UpdatePublicNote(note)
    if BFL_PersonalNoteText then
        BFL_PersonalNoteText:SetText(note or "")
        
        if CanEditPublicNote() then
            BFL_PersonalNoteText:SetTextColor(1, 1, 1)
        else
            BFL_PersonalNoteText:SetTextColor(0.65, 0.65, 0.65)
        end
    end
end

function GuildDetails:UpdateOfficerNote(officernote)
    if CanViewOfficerNote() then
        if BFL_OfficerNoteText then
            BFL_OfficerNoteText:SetText(officernote or "")
            -- Check permissions for text color
             if CanEditOfficerNote() then
                BFL_OfficerNoteText:SetTextColor(1, 1, 1)
            else
                BFL_OfficerNoteText:SetTextColor(0.65, 0.65, 0.65)
            end
        end
        
        if BFL_GuildMemberOfficerNoteBackground then
            BFL_GuildMemberOfficerNoteBackground:Show()
        end
        
        self.frame:SetHeight(GUILD_DETAIL_OFFICER_HEIGHT)
    else
        if BFL_GuildMemberOfficerNoteBackground then
            BFL_GuildMemberOfficerNoteBackground:Hide()
        end
        self.frame:SetHeight(GUILD_DETAIL_NORM_HEIGHT)
    end
end

function GuildDetails:UpdatePromoteDemote(rankIndex, online, displayedName)
    if not BFL_GuildFramePromoteButton or not BFL_GuildFrameDemoteButton then return end

    local guildName, guildRankName, guildRankIndex = GetGuildInfo("player")
    -- Returns nil, nil, nil if not in guild, handled upstream
    guildRankIndex = guildRankIndex or 100 
    
    local maxRankIndex = GuildControlGetNumRanks() - 1
    
    -- Promote button
    if CanGuildPromote() and rankIndex >= 1 and 
       rankIndex > guildRankIndex and rankIndex ~= 0 then
        BFL_GuildFramePromoteButton:Enable()
    else
        BFL_GuildFramePromoteButton:Disable()
    end
    
    -- Demote button
    if CanGuildDemote() and rankIndex >= 1 and 
       rankIndex > guildRankIndex and rankIndex ~= maxRankIndex then
        BFL_GuildFrameDemoteButton:Enable()
    else
        BFL_GuildFrameDemoteButton:Disable()
    end
    
    -- Hide both if disabled? The plan says hide if both disabled.
    -- But standard UI usually keeps them visible but disabled?
    -- Plan: "Hide both if disabled" (Smart UI)
    if not BFL_GuildFrameDemoteButton:IsEnabled() and 
       not BFL_GuildFramePromoteButton:IsEnabled() then
        BFL_GuildFramePromoteButton:Hide()
        BFL_GuildFrameDemoteButton:Hide()
    else
        BFL_GuildFramePromoteButton:Show()
        BFL_GuildFrameDemoteButton:Show()
    end
end

function GuildDetails:UpdateActionButtons(rankIndex, online, displayedName)
    local guildName, guildRankName, guildRankIndex = GetGuildInfo("player")
    guildRankIndex = guildRankIndex or 100
    
    -- Remove button
    if BFL_GuildMemberRemoveButton then
        if CanGuildRemove() and rankIndex >= 1 and rankIndex > guildRankIndex then
            BFL_GuildMemberRemoveButton:Enable()
        else
            BFL_GuildMemberRemoveButton:Disable()
        end
    end
    
    -- Group Invite button
    if BFL_GuildMemberGroupInviteButton then
        if UnitName("player") == displayedName or not online then
            BFL_GuildMemberGroupInviteButton:Disable()
        else
            BFL_GuildMemberGroupInviteButton:Enable()
        end
    end
end

function GuildDetails:PromoteMember()
    local fullName = GetGuildRosterInfo(self.currentIndex)
    if fullName then
        C_GuildInfo.Promote(fullName)
        -- Disable button immediately to prevent double click
        if BFL_GuildFramePromoteButton then BFL_GuildFramePromoteButton:Disable() end
    end
end

function GuildDetails:DemoteMember()
    local fullName = GetGuildRosterInfo(self.currentIndex)
    if fullName then
        C_GuildInfo.Demote(fullName)
        if BFL_GuildFrameDemoteButton then BFL_GuildFrameDemoteButton:Disable() end
    end
end

function GuildDetails:RemoveMember()
    local fullName = GetGuildRosterInfo(self.currentIndex)
    if fullName then
        StaticPopup_Show("REMOVE_GUILDMEMBER", nil, nil, {name = fullName})
    end
end

function GuildDetails:InviteMember()
    local fullName = GetGuildRosterInfo(self.currentIndex)
    if fullName then
        InviteToGroup(fullName)
    end
end

function GuildDetails:EditPublicNote()
    if not CanEditPublicNote() then return end
    
    local fullName, rank, rankIndex, level, class, zone, note = 
        GetGuildRosterInfo(self.currentIndex)
    
    StaticPopup_Show("SET_GUILDPLAYERNOTE", nil, nil, {
        index = self.currentIndex,
        note = note or ""
    })
end

function GuildDetails:EditOfficerNote()
    if not CanEditOfficerNote() then return end
    -- Check View permissions inside
    
    local fullName, rank, rankIndex, level, class, zone, note, officernote = 
        GetGuildRosterInfo(self.currentIndex)
    
    StaticPopup_Show("SET_GUILDOFFICERNOTE", nil, nil, {
        index = self.currentIndex,
        note = officernote or ""
    })
end
