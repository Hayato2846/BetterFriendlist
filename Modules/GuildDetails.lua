--[[Perfy has instrumented this file]] local Perfy_GetTime, Perfy_Trace, Perfy_Trace_Passthrough = Perfy_GetTime, Perfy_Trace, Perfy_Trace_Passthrough; Perfy_Trace(Perfy_GetTime(), "Enter", "(main chunk) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GuildDetails.lua"); local _, BFL = ...
local GuildDetails = BFL:RegisterModule("GuildDetails", {})
local L = BFL.L

-- Constants from Blizzard's GuildFrame
local GUILD_DETAIL_NORM_HEIGHT = 195
local GUILD_DETAIL_OFFICER_HEIGHT = 255
local FRIENDS_LEVEL_TEMPLATE = FRIENDS_LEVEL_TEMPLATE or "Level %d %s"

function GuildDetails:Initialize() Perfy_Trace(Perfy_GetTime(), "Enter", "GuildDetails:Initialize file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GuildDetails.lua:10:0");
    self.frame = BFL_GuildMemberDetailFrame
    if self.frame then
        self.frame:Hide()
        -- Hook standard static popups if needed, or rely on Blizzard's
    end
Perfy_Trace(Perfy_GetTime(), "Leave", "GuildDetails:Initialize file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GuildDetails.lua:10:0"); end

function GuildDetails:ShowForMember(guildIndex) Perfy_Trace(Perfy_GetTime(), "Enter", "GuildDetails:ShowForMember file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GuildDetails.lua:18:0");
    if not self.frame then Perfy_Trace(Perfy_GetTime(), "Leave", "GuildDetails:ShowForMember file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GuildDetails.lua:18:0"); return end
    
    if guildIndex == 0 or not guildIndex then
        self.frame:Hide()
        Perfy_Trace(Perfy_GetTime(), "Leave", "GuildDetails:ShowForMember file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GuildDetails.lua:18:0"); return
    end
    
    local fullName, rank, rankIndex, level, class, zone, note, 
          officernote, online = GetGuildRosterInfo(guildIndex)
    
    if not fullName then
        self.frame:Hide()
        Perfy_Trace(Perfy_GetTime(), "Leave", "GuildDetails:ShowForMember file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GuildDetails.lua:18:0"); return
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
            BFL_GuildMemberDetailOnlineText:SetText(GUILD_ONLINE_LABEL or BFL.L.ONLINE_STATUS)
        else
            if BFL.GuildRoster and BFL.GuildRoster.GetLastOnlineText then
                BFL_GuildMemberDetailOnlineText:SetText(BFL.GuildRoster:GetLastOnlineText(guildIndex))
            else
                BFL_GuildMemberDetailOnlineText:SetText(BFL.L.OFFLINE_STATUS)
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
Perfy_Trace(Perfy_GetTime(), "Leave", "GuildDetails:ShowForMember file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GuildDetails.lua:18:0"); end

function GuildDetails:UpdatePublicNote(note) Perfy_Trace(Perfy_GetTime(), "Enter", "GuildDetails:UpdatePublicNote file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GuildDetails.lua:79:0");
    if BFL_PersonalNoteText then
        BFL_PersonalNoteText:SetText(note or "")
        
        if CanEditPublicNote() then
            BFL_PersonalNoteText:SetTextColor(1, 1, 1)
        else
            BFL_PersonalNoteText:SetTextColor(0.65, 0.65, 0.65)
        end
    end
Perfy_Trace(Perfy_GetTime(), "Leave", "GuildDetails:UpdatePublicNote file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GuildDetails.lua:79:0"); end

function GuildDetails:UpdateOfficerNote(officernote) Perfy_Trace(Perfy_GetTime(), "Enter", "GuildDetails:UpdateOfficerNote file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GuildDetails.lua:91:0");
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
Perfy_Trace(Perfy_GetTime(), "Leave", "GuildDetails:UpdateOfficerNote file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GuildDetails.lua:91:0"); end

function GuildDetails:UpdatePromoteDemote(rankIndex, online, displayedName) Perfy_Trace(Perfy_GetTime(), "Enter", "GuildDetails:UpdatePromoteDemote file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GuildDetails.lua:116:0");
    if not BFL_GuildFramePromoteButton or not BFL_GuildFrameDemoteButton then Perfy_Trace(Perfy_GetTime(), "Leave", "GuildDetails:UpdatePromoteDemote file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GuildDetails.lua:116:0"); return end

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
Perfy_Trace(Perfy_GetTime(), "Leave", "GuildDetails:UpdatePromoteDemote file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GuildDetails.lua:116:0"); end

function GuildDetails:UpdateActionButtons(rankIndex, online, displayedName) Perfy_Trace(Perfy_GetTime(), "Enter", "GuildDetails:UpdateActionButtons file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GuildDetails.lua:154:0");
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
Perfy_Trace(Perfy_GetTime(), "Leave", "GuildDetails:UpdateActionButtons file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GuildDetails.lua:154:0"); end

function GuildDetails:PromoteMember() Perfy_Trace(Perfy_GetTime(), "Enter", "GuildDetails:PromoteMember file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GuildDetails.lua:177:0");
    local fullName = GetGuildRosterInfo(self.currentIndex)
    if fullName then
        C_GuildInfo.Promote(fullName)
        -- Disable button immediately to prevent double click
        if BFL_GuildFramePromoteButton then BFL_GuildFramePromoteButton:Disable() end
    end
Perfy_Trace(Perfy_GetTime(), "Leave", "GuildDetails:PromoteMember file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GuildDetails.lua:177:0"); end

function GuildDetails:DemoteMember() Perfy_Trace(Perfy_GetTime(), "Enter", "GuildDetails:DemoteMember file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GuildDetails.lua:186:0");
    local fullName = GetGuildRosterInfo(self.currentIndex)
    if fullName then
        C_GuildInfo.Demote(fullName)
        if BFL_GuildFrameDemoteButton then BFL_GuildFrameDemoteButton:Disable() end
    end
Perfy_Trace(Perfy_GetTime(), "Leave", "GuildDetails:DemoteMember file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GuildDetails.lua:186:0"); end

function GuildDetails:RemoveMember() Perfy_Trace(Perfy_GetTime(), "Enter", "GuildDetails:RemoveMember file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GuildDetails.lua:194:0");
    local fullName = GetGuildRosterInfo(self.currentIndex)
    if fullName then
        StaticPopup_Show("REMOVE_GUILDMEMBER", nil, nil, {name = fullName})
    end
Perfy_Trace(Perfy_GetTime(), "Leave", "GuildDetails:RemoveMember file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GuildDetails.lua:194:0"); end

function GuildDetails:InviteMember() Perfy_Trace(Perfy_GetTime(), "Enter", "GuildDetails:InviteMember file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GuildDetails.lua:201:0");
    local fullName = GetGuildRosterInfo(self.currentIndex)
    if fullName then
        InviteToGroup(fullName)
    end
Perfy_Trace(Perfy_GetTime(), "Leave", "GuildDetails:InviteMember file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GuildDetails.lua:201:0"); end

function GuildDetails:EditPublicNote() Perfy_Trace(Perfy_GetTime(), "Enter", "GuildDetails:EditPublicNote file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GuildDetails.lua:208:0");
    if not CanEditPublicNote() then Perfy_Trace(Perfy_GetTime(), "Leave", "GuildDetails:EditPublicNote file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GuildDetails.lua:208:0"); return end
    
    local fullName, rank, rankIndex, level, class, zone, note = 
        GetGuildRosterInfo(self.currentIndex)
    
    StaticPopup_Show("SET_GUILDPLAYERNOTE", nil, nil, {
        index = self.currentIndex,
        note = note or ""
    })
Perfy_Trace(Perfy_GetTime(), "Leave", "GuildDetails:EditPublicNote file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GuildDetails.lua:208:0"); end

function GuildDetails:EditOfficerNote() Perfy_Trace(Perfy_GetTime(), "Enter", "GuildDetails:EditOfficerNote file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GuildDetails.lua:220:0");
    if not CanEditOfficerNote() then Perfy_Trace(Perfy_GetTime(), "Leave", "GuildDetails:EditOfficerNote file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GuildDetails.lua:220:0"); return end
    -- Check View permissions inside
    
    local fullName, rank, rankIndex, level, class, zone, note, officernote = 
        GetGuildRosterInfo(self.currentIndex)
    
    StaticPopup_Show("SET_GUILDOFFICERNOTE", nil, nil, {
        index = self.currentIndex,
        note = officernote or ""
    })
Perfy_Trace(Perfy_GetTime(), "Leave", "GuildDetails:EditOfficerNote file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GuildDetails.lua:220:0"); end

Perfy_Trace(Perfy_GetTime(), "Leave", "(main chunk) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GuildDetails.lua");