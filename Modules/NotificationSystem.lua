--[[
    NotificationSystem.lua
    Smart Friend Notifications System
    
    Features:
    - Per-friend alerts (online, offline, game change)
    - Content filters (game type, status)
    - Group triggers (X/Y friends online)
    - Quiet hours (combat, instance, schedule)
    
    Author: BetterFriendlist Team
    Version: 1.9.0
]]--

local addonName, BFL = ...

-- Module Registration
local NotificationSystem = BFL:RegisterModule("NotificationSystem", {
    name = "NotificationSystem",
    version = "1.0.0",
    description = "Smart friend notification system with triggers and filters"
})

-- Constants
local MODULE_NAME = "NotificationSystem"
local COOLDOWN_DURATION = 30 -- Prevent spam (same alert every 30 seconds)

-- Module State
NotificationSystem.initialized = false
NotificationSystem.quietMode = false
NotificationSystem.lastNotifications = {} -- Track cooldowns
NotificationSystem.alertSystem = nil -- AlertFrame SubSystem

-- Forward Declarations
local CheckRules
local ShowNotification
local IsQuietTime
local NotificationAlertFrame_SetUp

--[[--------------------------------------------------
    Module Lifecycle
--]]--------------------------------------------------

function NotificationSystem:Initialize()
    if self.initialized then return end
    
    BFL:DebugPrint("|cff00ffffBFL:NotificationSystem:|r Initializing NotificationSystem...")
    
    -- Initialize database
    self:InitializeDatabase()
    
    -- Register AlertFrame SubSystem
    self:InitializeAlertSystem()
    
    -- Register events
    self:RegisterEvents()
    
    self.initialized = true
    BFL:DebugPrint("|cff00ffffBFL:NotificationSystem:|r NotificationSystem initialized successfully")
end

function NotificationSystem:OnEnable()
    BFL:DebugPrint("|cff00ffffBFL:NotificationSystem:|r NotificationSystem enabled")
end

function NotificationSystem:OnDisable()
    BFL:DebugPrint("|cff00ffffBFL:NotificationSystem:|r NotificationSystem disabled")
end

--[[--------------------------------------------------
    Database
--]]--------------------------------------------------

function NotificationSystem:InitializeDatabase()
    -- Personal Alert Rules
    if not BetterFriendlistDB.notificationRules then
        BetterFriendlistDB.notificationRules = {}
    end
    
    -- Group Alert Rules
    if not BetterFriendlistDB.groupTriggers then
        BetterFriendlistDB.groupTriggers = {}
    end
    
    -- Quiet Hours Settings
    if not BetterFriendlistDB.quietHours then
        BetterFriendlistDB.quietHours = {
            enabled = true,
            duringCombat = true,
            duringInstance = true,
            manualDND = false,
            scheduleEnabled = false,
            startHour = 22,
            endHour = 6
        }
    end
    
    -- Notification Appearance Settings
    if not BetterFriendlistDB.notificationSettings then
        BetterFriendlistDB.notificationSettings = {
            enabled = true
        }
    end
    
    -- Display Mode (from Database defaults)
    if not BetterFriendlistDB.notificationDisplayMode then
        BetterFriendlistDB.notificationDisplayMode = "alert"
    end
    
    BFL:DebugPrint("|cff00ffffBFL:NotificationSystem:|r Database initialized")
end

--[[--------------------------------------------------
    AlertFrame System
--]]--------------------------------------------------

function NotificationSystem:InitializeAlertSystem()
    -- Register AlertFrame SubSystem for notifications
    self.alertSystem = AlertFrame:AddQueuedAlertFrameSubSystem(
        "BFL_FriendNotificationAlertFrameTemplate",
        NotificationAlertFrame_SetUp,
        3,  -- maxAlerts (max 3 visible at once)
        10  -- maxQueue (queue up to 10)
    )
    
    BFL:DebugPrint("|cff00ffffBFL:NotificationSystem:|r AlertFrame SubSystem registered")
end

function NotificationAlertFrame_SetUp(frame, friendName, statusType, message, iconTexture)
    -- Fix AnimationGroup structure for AlertFrame system
    -- AlertFrame expects frame.animOut.animIn to exist, but Animations section overwrites Frames
    -- So we use animOutFrame and rename it
    if frame.animOutFrame and not frame.animOut then
        frame.animOut = frame.animOutFrame
    end
    
    -- Setup alert frame with friend data
    frame.Name:SetText(friendName)
    frame.Message:SetText(message)
    
    -- Set status icon
    if iconTexture then
        frame.Icon:SetTexture(iconTexture)
    elseif statusType == "ONLINE" then
        frame.Icon:SetTexture("Interface\\FriendsFrame\\StatusIcon-Online")
    elseif statusType == "OFFLINE" then
        frame.Icon:SetTexture("Interface\\FriendsFrame\\StatusIcon-Offline")
    else
        frame.Icon:SetTexture("Interface\\FriendsFrame\\StatusIcon-Online")
    end
    
    -- Set icon color based on status
    if statusType == "ONLINE" then
        frame.Icon:SetVertexColor(0, 1, 0) -- Green
    elseif statusType == "OFFLINE" then
        frame.Icon:SetVertexColor(0.5, 0.5, 0.5) -- Gray
    else
        frame.Icon:SetVertexColor(1, 1, 1) -- White
    end
    
    -- Play sound if enabled
    if BetterFriendlistDB.notificationSoundEnabled then
        PlaySound(BetterFriendlistDB.notificationSoundKitID)
    end
end

--[[--------------------------------------------------
    Event System
--]]--------------------------------------------------

function NotificationSystem:RegisterEvents()
    -- BattleNet Friend Events
    BFL:RegisterEventCallback("BN_FRIEND_ACCOUNT_ONLINE", function(...)
        local bnetAccountID = ...
        self:OnFriendOnline("BNET", bnetAccountID)
    end)
    
    BFL:RegisterEventCallback("BN_FRIEND_ACCOUNT_OFFLINE", function(...)
        local bnetAccountID = ...
        self:OnFriendOffline("BNET", bnetAccountID)
    end)
    
    -- WoW Friend Events
    BFL:RegisterEventCallback("FRIENDLIST_UPDATE", function(...)
        self:OnFriendListUpdate()
    end)
    
    -- Combat Events (Quiet Hours)
    BFL:RegisterEventCallback("PLAYER_REGEN_DISABLED", function(...)
        self.quietMode = true
        BFL:DebugPrint("|cff00ffffBFL:NotificationSystem:|r Combat started - Quiet mode enabled")
    end)
    
    BFL:RegisterEventCallback("PLAYER_REGEN_ENABLED", function(...)
        self.quietMode = false
        BFL:DebugPrint("|cff00ffffBFL:NotificationSystem:|r Combat ended - Quiet mode disabled")
    end)
    
    BFL:DebugPrint("|cff00ffffBFL:NotificationSystem:|r Events registered")
end

--[[--------------------------------------------------
    Event Handlers
--]]--------------------------------------------------

function NotificationSystem:OnFriendOnline(friendType, identifier)
    if not BetterFriendlistDB.notificationSettings.enabled then return end
    if IsQuietTime() then return end
    
    BFL:DebugPrint("|cff00ffffBFL:NotificationSystem:|r Friend online: " .. tostring(identifier) .. " (" .. friendType .. ")")
    
    -- Get friend data
    local friendData = self:GetFriendData(friendType, identifier)
    if not friendData then return end
    
    -- Check cooldown
    local cooldownKey = friendType .. "_" .. tostring(identifier) .. "_ONLINE"
    if self:IsOnCooldown(cooldownKey) then return end
    
    -- Check notification rules (Phase 2)
    if CheckRules("ONLINE", friendData) then
        -- Show notification
        local message = "is now online"
        if friendData.gameAccountInfo and friendData.gameAccountInfo.clientProgram then
            local clientName = friendData.gameAccountInfo.clientProgram == BNET_CLIENT_WOW and "World of Warcraft" or friendData.gameAccountInfo.clientProgram
            message = "is now online playing " .. clientName
        end
        ShowNotification(friendData.name, "ONLINE", message, nil)
    end
    
    -- Set cooldown
    self:SetCooldown(cooldownKey)
end

function NotificationSystem:OnFriendOffline(friendType, identifier)
    if not BetterFriendlistDB.notificationSettings.enabled then return end
    if IsQuietTime() then return end
    
    BFL:DebugPrint("|cff00ffffBFL:NotificationSystem:|r Friend offline: " .. tostring(identifier) .. " (" .. friendType .. ")")
    
    -- Get friend data
    local friendData = self:GetFriendData(friendType, identifier)
    if not friendData then return end
    
    -- Check cooldown
    local cooldownKey = friendType .. "_" .. tostring(identifier) .. "_OFFLINE"
    if self:IsOnCooldown(cooldownKey) then return end
    
    -- Check notification rules (Phase 2)
    if CheckRules("OFFLINE", friendData) then
        -- Show notification
        local message = "has gone offline"
        ShowNotification(friendData.name, "OFFLINE", message, nil)
    end
    
    -- Set cooldown
    self:SetCooldown(cooldownKey)
end

function NotificationSystem:OnFriendListUpdate()
    -- This fires frequently, only process game changes
    -- Full implementation in Phase 2
end

--[[--------------------------------------------------
    Friend Data Retrieval
--]]--------------------------------------------------

function NotificationSystem:GetFriendData(friendType, identifier)
    if friendType == "BNET" then
        local accountInfo = C_BattleNet.GetFriendAccountInfo(identifier)
        if not accountInfo then return nil end
        
        return {
            type = "BNET",
            bnetAccountID = identifier,
            accountName = accountInfo.accountName,
            battleTag = accountInfo.battleTag,
            name = accountInfo.accountName or accountInfo.battleTag,
            gameAccountInfo = accountInfo.gameAccountInfo,
            isOnline = accountInfo.gameAccountInfo ~= nil,
            clientProgram = accountInfo.gameAccountInfo and accountInfo.gameAccountInfo.clientProgram or "App"
        }
    elseif friendType == "WOW" then
        -- WoW friend (by name)
        for i = 1, C_FriendList.GetNumFriends() do
            local friendInfo = C_FriendList.GetFriendInfoByIndex(i)
            if friendInfo and friendInfo.name == identifier then
                return {
                    type = "WOW",
                    name = friendInfo.name,
                    level = friendInfo.level,
                    class = friendInfo.className,
                    area = friendInfo.area,
                    isOnline = friendInfo.connected,
                    status = friendInfo.dnd and "DND" or (friendInfo.afk and "AFK" or "ONLINE")
                }
            end
        end
    end
    
    return nil
end

--[[--------------------------------------------------
    Cooldown System
--]]--------------------------------------------------

function NotificationSystem:IsOnCooldown(key)
    local lastTime = self.lastNotifications[key]
    if not lastTime then return false end
    
    local elapsed = time() - lastTime
    return elapsed < COOLDOWN_DURATION
end

function NotificationSystem:SetCooldown(key)
    self.lastNotifications[key] = time()
end

--[[--------------------------------------------------
    Quiet Hours
--]]--------------------------------------------------

function IsQuietTime()
    local settings = BetterFriendlistDB.quietHours
    if not settings.enabled then return false end
    
    -- Manual DND
    if settings.manualDND then
        return true
    end
    
    -- Combat
    if settings.duringCombat and NotificationSystem.quietMode then
        return true
    end
    
    -- Instance
    if settings.duringInstance then
        local inInstance, instanceType = IsInInstance()
        if inInstance and (instanceType == "party" or instanceType == "raid" or instanceType == "pvp" or instanceType == "arena") then
            return true
        end
    end
    
    -- Schedule
    if settings.scheduleEnabled then
        local currentHour = tonumber(date("%H"))
        local startHour = settings.startHour
        local endHour = settings.endHour
        
        if startHour > endHour then
            -- Overnight (e.g., 22:00 - 06:00)
            if currentHour >= startHour or currentHour < endHour then
                return true
            end
        else
            -- Same day (e.g., 14:00 - 18:00)
            if currentHour >= startHour and currentHour < endHour then
                return true
            end
        end
    end
    
    return false
end

--[[--------------------------------------------------
    Rule Checking (Stub for Phase 2)
--]]--------------------------------------------------

function CheckRules(triggerType, friendData)
    -- TODO: Implement in Phase 2 - Full rule engine with conditions
    -- For now, show all notifications (basic implementation)
    return true
end

--[[--------------------------------------------------
    Notification Display
--]]--------------------------------------------------

function ShowNotification(friendName, statusType, message, iconTexture)
    local displayMode = BetterFriendlistDB.notificationDisplayMode
    
    if displayMode == "alert" then
        -- Use AlertFrame System
        if NotificationSystem.alertSystem then
            NotificationSystem.alertSystem:AddAlert(friendName, statusType, message, iconTexture)
        end
    elseif displayMode == "chat" then
        -- Print to chat
        local colorCode = statusType == "ONLINE" and "|cff00ff00" or "|cff808080"
        print(string.format("%s[BFL]|r %s: %s", colorCode, friendName, message))
    end
    -- displayMode == "disabled" - do nothing
end

--[[--------------------------------------------------
    Test Command
--]]--------------------------------------------------

function NotificationSystem:ShowTestNotification()
    ShowNotification("TestPlayer", "ONLINE", "is now online playing World of Warcraft", nil)
    print("|cff00ff00[BFL]|r Test notification triggered (display mode: " .. BetterFriendlistDB.notificationDisplayMode .. ")")
end

-- Export module
BFL.NotificationSystem = NotificationSystem
