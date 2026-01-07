local _, BFL = ...
local GuildRoster = BFL:RegisterModule("GuildRoster", {})
BFL.GuildRoster = GuildRoster

-- Constants
local GUILDMEMBERS_TO_DISPLAY = 11
local FRIENDS_FRAME_GUILD_HEIGHT = 14

-- Localization
local L = BFL.L

function GuildRoster:Initialize()
    self.displayMode = "player" -- "player" or "guild"
    self.sortColumn = "name"
    
    -- Safety check for C_GuildInfo
    if not C_GuildInfo then
        BFL:DebugPrint("C_GuildInfo API not available")
        return
    end

    self.showOffline = GetGuildRosterShowOffline()
    self:RegisterEvents()
end

function GuildRoster:RegisterEvents()
    BFL:RegisterEventCallback("GUILD_ROSTER_UPDATE", function(canRequest)
        self:OnRosterUpdate(canRequest)
    end)
    BFL:RegisterEventCallback("PLAYER_GUILD_UPDATE", function()
        self:OnGuildUpdate()
    end)
end

function GuildRoster:OnFrameLoad(frame)
    if self.buttonsInitialized then return end
    
    -- Create buttons 2-13 for PlayerStatusFrame
    for i = 2, GUILDMEMBERS_TO_DISPLAY do
        local button = CreateFrame("Button", "BFL_GuildFrameButton"..i, BFL_GuildPlayerStatusFrame, "FriendsFrameGuildPlayerStatusButtonTemplate")
        button:SetID(i)
        button:SetPoint("TOP", _G["BFL_GuildFrameButton"..(i-1)], "BOTTOM")
        button:SetScript("OnClick", function(self, btn)
             BFL.GuildRoster:OnButtonClick(self, btn)
        end)
    end

    -- Create buttons 2-13 for GuildStatusFrame
    for i = 2, GUILDMEMBERS_TO_DISPLAY do
        local button = CreateFrame("Button", "BFL_GuildFrameGuildStatusButton"..i, BFL_GuildStatusFrame, "FriendsFrameGuildStatusButtonTemplate")
        button:SetID(i)
        button:SetPoint("TOP", _G["BFL_GuildFrameGuildStatusButton"..(i-1)], "BOTTOM")
        button:SetScript("OnClick", function(self, btn)
             BFL.GuildRoster:OnButtonClick(self, btn)
        end)
    end
    
    self.buttonsInitialized = true
end

function GuildRoster:OnRosterUpdate(canRequest)
    if canRequest then
        C_GuildInfo.GuildRoster()
    end
    self:RefreshDisplay()
end

function GuildRoster:OnGuildUpdate()
    if IsInGuild() then
        if not BFL_GuildFrame:IsShown() and BetterFriendlistDB and BetterFriendlistDB.guild and BetterFriendlistDB.guild.enabled then
             -- Logic to enable/show tab if needed, managed by Settings usually
        end
    else
        -- Hide guild specific stuff if user left guild
    end
end

function GuildRoster:RefreshDisplay()
    if not BFL_GuildFrame or not BFL_GuildFrame:IsShown() then return end

    local totalMembers, onlineMembers = GetNumGuildMembers()
    local numToDisplay = self.showOffline and totalMembers or onlineMembers
    
    -- Update FauxScrollFrame
    FauxScrollFrame_Update(
        BFL_GuildListScrollFrame,
        numToDisplay,
        GUILDMEMBERS_TO_DISPLAY,
        FRIENDS_FRAME_GUILD_HEIGHT
    )
    
    -- Update visible buttons
    local offset = FauxScrollFrame_GetOffset(BFL_GuildListScrollFrame)
    for i = 1, GUILDMEMBERS_TO_DISPLAY do
        local guildIndex = offset + i
        local button = _G["BFL_GuildFrameButton"..i]
        -- Handle button existence check just in case, though they should be created by XML/OnLoad
        if button then
            self:UpdateButton(button, guildIndex, numToDisplay)
        end
    end
    
    -- Safety: Hide any extra buttons if they exist (e.g. from previous session with higher count)
    for i = GUILDMEMBERS_TO_DISPLAY + 1, 20 do
        local button = _G["BFL_GuildFrameButton"..i]
        if button then button:Hide() end
        local statusButton = _G["BFL_GuildFrameGuildStatusButton"..i]
        if statusButton then statusButton:Hide() end
    end
    
    -- Update totals
    self:UpdateTotals(totalMembers, onlineMembers)
end

function GuildRoster:UpdateButton(button, guildIndex, maxMembers)
    -- Determine which button template/frames are being used
    -- The plan uses a clever switch where BFL_GuildFrameButtonX (PlayerStatus) and BFL_GuildFrameGuildStatusButtonX (GuildStatus) are swapped visibility-wise.
    -- Wait, the XML structure in plan shows TWO sets of buttons?
    -- No, usually it's one set of buttons with different sub-elements shown/hidden, OR two separate frames each with buttons.
    -- Looking at Plan XML:
    -- Frame BFL_GuildPlayerStatusFrame has BFL_GuildFrameButton1..13
    -- Frame BFL_GuildStatusFrame has BFL_GuildFrameGuildStatusButton1..13
    
    -- We need to update the buttons for the currently visible frame.
    
    if self.displayMode == "player" then
        button = _G["BFL_GuildFrameButton"..button:GetID()]
    else
        button = _G["BFL_GuildFrameGuildStatusButton"..button:GetID()]
    end
    
    if not button then return end

    if guildIndex > maxMembers then
        button:Hide()
        return
    end
    
    local fullName, rank, rankIndex, level, class, zone, note, 
          officernote, online, isAway = GetGuildRosterInfo(guildIndex)
    
    if not fullName then
        button:Hide()
        return
    end
    
    button.guildIndex = guildIndex
    local displayedName = Ambiguate(fullName, "guild")
    
    if self.displayMode == "player" then
        self:UpdatePlayerButton(button, displayedName, zone, level, class, online)
    else
        self:UpdateGuildButton(button, displayedName, rank, note, online, isAway, guildIndex)
    end
    
    -- Selection highlight
    if GetGuildRosterSelection() == guildIndex then
        button:LockHighlight()
    else
        button:UnlockHighlight()
    end
    
    button:Show()
end

function GuildRoster:UpdatePlayerButton(button, name, zone, level, class, online)
    -- Use _G to access children as parentKey is not available in Classic templates
    local buttonName = button:GetName()
    local nameString = _G[buttonName.."Name"]
    local zoneString = _G[buttonName.."Zone"]
    local levelString = _G[buttonName.."Level"]
    local classString = _G[buttonName.."Class"]

    if nameString then nameString:SetText(name) end
    if zoneString then zoneString:SetText(zone) end
    if levelString then levelString:SetText(level) end
    if classString then classString:SetText(class) end
    
    local color = online and {r=1, g=1, b=1} or {r=0.5, g=0.5, b=0.5}
    if nameString then nameString:SetTextColor(color.r, color.g, color.b) end
    if zoneString then zoneString:SetTextColor(color.r, color.g, color.b) end
    if levelString then levelString:SetTextColor(color.r, color.g, color.b) end
    if classString then classString:SetTextColor(color.r, color.g, color.b) end
end

function GuildRoster:UpdateGuildButton(button, name, rank, note, online, isAway, guildIndex)
    -- Use _G to access children as parentKey is not available in Classic templates
    local buttonName = button:GetName()
    local nameString = _G[buttonName.."Name"]
    local rankString = _G[buttonName.."Rank"]
    local noteString = _G[buttonName.."Note"]
    local onlineString = _G[buttonName.."Online"]

    if nameString then nameString:SetText(name) end
    if rankString then rankString:SetText(rank) end
    if noteString then noteString:SetText(note) end
    
    local onlineText
    if online then
        if isAway == 2 then
            onlineText = CHAT_FLAG_DND
        elseif isAway == 1 then
            onlineText = CHAT_FLAG_AFK
        else
            onlineText = GUILD_ONLINE_LABEL
        end
    else
        onlineText = self:GetLastOnlineText(guildIndex)
    end
    if onlineString then onlineString:SetText(onlineText) end
    
    local color = online and {r=1, g=1, b=1} or {r=0.5, g=0.5, b=0.5}
    if nameString then nameString:SetTextColor(color.r, color.g, color.b) end
    if rankString then rankString:SetTextColor(color.r, color.g, color.b) end
    if noteString then noteString:SetTextColor(color.r, color.g, color.b) end
    if onlineString then onlineString:SetTextColor(color.r, color.g, color.b) end
end

function GuildRoster:GetLastOnlineText(guildIndex)
    local year, month, day, hour = GetGuildRosterLastOnline(guildIndex)
    if not year or year == 0 or year == 10000 then
        return FRIENDS_LIST_OFFLINE or "Offline"
    end
    
    -- Calculate time difference
    local lastOnline = time({
        year = year,
        month = month,
        day = day,
        hour = hour,
        min = 0,
        sec = 0
    })
    
    local timeDiff = time() - lastOnline
    
    if timeDiff < 60 then
        return LASTONLINE_SECS or "< 1 min"
    elseif timeDiff < 3600 then
        return format(LASTONLINE_MINUTES or "%d min", floor(timeDiff / 60))
    elseif timeDiff < 86400 then
        return format(LASTONLINE_HOURS or "%d hr", floor(timeDiff / 3600))
    elseif timeDiff < 2592000 then
        return format(LASTONLINE_DAYS or "%d days", floor(timeDiff / 86400))
    elseif timeDiff < 31536000 then
        return format(LASTONLINE_MONTHS or "%d months", floor(timeDiff / 2592000))
    else
        return format(LASTONLINE_YEARS or "%d years", floor(timeDiff / 31536000))
    end
end

function GuildRoster:ToggleDisplayMode()
    self.displayMode = (self.displayMode == "player") and "guild" or "player"
    
    if self.displayMode == "player" then
        BFL_GuildPlayerStatusFrame:Show()
        BFL_GuildStatusFrame:Hide()
    else
        BFL_GuildPlayerStatusFrame:Hide()
        BFL_GuildStatusFrame:Show()
    end
    
    self:RefreshDisplay()
end

function GuildRoster:SortRoster(column)
    self.sortColumn = column
    SortGuildRoster(column)
    self:RefreshDisplay()
end

function GuildRoster:ToggleOfflineMembers()
    self.showOffline = not self.showOffline
    SetGuildRosterShowOffline(self.showOffline)
    self:RefreshDisplay()
end

function GuildRoster:UpdateTotals(total, online)
    if BFL_GuildFrameTotals then
        BFL_GuildFrameTotals:SetText(format(GUILD_TOTAL or "Total: %d", total))
    end
    if BFL_GuildFrameOnlineTotals then
        BFL_GuildFrameOnlineTotals:SetText(format(GUILD_TOTALONLINE or "Online: %d", online))
    end
    
    local motd = GetGuildRosterMOTD()
    if BFL_GuildFrameNotesText then
        BFL_GuildFrameNotesText:SetText(motd or "")
        
        if CanEditMOTD() then
            BFL_GuildFrameNotesText:SetTextColor(1, 1, 1)
        else
            BFL_GuildFrameNotesText:SetTextColor(0.65, 0.65, 0.65)
        end
    end
end

function GuildRoster:OnButtonClick(button, mouseButton)
    if mouseButton == "LeftButton" then
        self:SelectMember(button.guildIndex)
    elseif mouseButton == "RightButton" then
        self:ShowContextMenu(button)
    end
end

function GuildRoster:SelectMember(guildIndex)
    SetGuildRosterSelection(guildIndex)
    self:RefreshDisplay()
    
    -- Show detail frame if installed
    if BFL.GuildDetails and guildIndex > 0 then
        BFL.GuildDetails:ShowForMember(guildIndex)
    end
end

function GuildRoster:ShowContextMenu(button)
    local fullName, rank, rankIndex, level, class, zone, note, 
          officernote, online = GetGuildRosterInfo(button.guildIndex)
    
    if not fullName then return end
    
    local contextData = {
        name = Ambiguate(fullName, "guild"),
        guid = UnitGUID("guild"..button.guildIndex),
        fromGuildFrame = true,
        guildIndex = button.guildIndex
    }
    
    local which = online and "GUILD" or "GUILD_OFFLINE"
    -- UnitPopup_OpenMenu(which, contextData) -- Requires Blizzard_UnitPopup or similar. 
    -- FriendsFrame.lua uses UnitPopup_OpenMenu. 
    
    if UnitPopup_OpenMenu then
         UnitPopup_OpenMenu(which, contextData)
    end
end
