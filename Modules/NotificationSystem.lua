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
local GLOBAL_COOLDOWN_DURATION = 5 -- Prevent burst spam (any alert for same friend every 5 seconds)
local OFFLINE_DEBOUNCE_DURATION = 5 -- Wait 5s before showing offline toast to detect char switch

-- Module State
NotificationSystem.initialized = false
NotificationSystem.quietMode = false
NotificationSystem.lastNotifications = {} -- Track cooldowns
NotificationSystem.alertSystem = nil -- AlertFrame SubSystem
NotificationSystem.wowFriendCache = {} -- Cache for WoW friend states
NotificationSystem.bnetFriendCache = {} -- Cache for BNet friend states (game tracking)
NotificationSystem.offlineTimers = {} -- Track pending offline notifications

-- Forward Declarations
local CheckRules
local ShowNotification
local IsQuietTime
local NotificationAlertFrame_SetUp
local SnapshotWoWFriends
local ProcessWoWFriendChanges
local ExecuteOfflineNotification

--[[--------------------------------------------------
    Module Lifecycle
--]]--------------------------------------------------

function NotificationSystem:Initialize()
    if self.initialized then return end
    
    -- BFL:DebugPrint("|cff00ffffBFL:NotificationSystem:|r Initializing NotificationSystem...")
    
    -- Initialize database
    self:InitializeDatabase()
    
    -- Register AlertFrame SubSystem
    self:InitializeAlertSystem()
    
    -- Register events
    self:RegisterEvents()
    
    -- Initial snapshot of WoW friends
    SnapshotWoWFriends()
    
    self.initialized = true
    -- BFL:DebugPrint("|cff00ffffBFL:NotificationSystem:|r NotificationSystem initialized successfully")
end

function NotificationSystem:OnEnable()
    -- BFL:DebugPrint("|cff00ffffBFL:NotificationSystem:|r NotificationSystem enabled")
    
    -- Disable Blizzard's default BNet toasts to prevent duplicates
    if BNToastFrame then
        self.originalToastDuration = BNToastFrame:GetDuration()
        BNToastFrame:SetDuration(0) -- Effectively disables it
    end
end

function NotificationSystem:OnDisable()
    -- BFL:DebugPrint("|cff00ffffBFL:NotificationSystem:|r NotificationSystem disabled")
    
    -- Cancel all pending offline timers
    for key, timer in pairs(self.offlineTimers) do
        if timer then timer:Cancel() end
    end
    self.offlineTimers = {}
    
    -- Restore Blizzard's default BNet toasts
    if BNToastFrame and self.originalToastDuration then
        BNToastFrame:SetDuration(self.originalToastDuration)
    end
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
            enabled = true,
            onlyFavorites = false,
            showApp = true,
            showGameChanges = true,
            showOffline = true
        }
    end
    
    -- Display Mode (from Database defaults)
    if not BetterFriendlistDB.notificationDisplayMode then
        BetterFriendlistDB.notificationDisplayMode = "alert"
    end
    
    -- BFL:DebugPrint("|cff00ffffBFL:NotificationSystem:|r Database initialized")
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
    
    -- BFL:DebugPrint("|cff00ffffBFL:NotificationSystem:|r AlertFrame SubSystem registered")
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
    
    BFL:RegisterEventCallback("BN_FRIEND_INFO_CHANGED", function(...)
        local bnetAccountID = ...
        self:OnFriendInfoChanged(bnetAccountID)
    end)
    
    -- WoW Friend Events
    BFL:RegisterEventCallback("FRIENDLIST_UPDATE", function(...)
        self:OnFriendListUpdate()
    end)
    
    -- Combat Events (Quiet Hours)
    BFL:RegisterEventCallback("PLAYER_REGEN_DISABLED", function(...)
        self.quietMode = true
        -- BFL:DebugPrint("|cff00ffffBFL:NotificationSystem:|r Combat started - Quiet mode enabled")
    end)
    
    BFL:RegisterEventCallback("PLAYER_REGEN_ENABLED", function(...)
        self.quietMode = false
        -- BFL:DebugPrint("|cff00ffffBFL:NotificationSystem:|r Combat ended - Quiet mode disabled")
    end)
    
    -- BFL:DebugPrint("|cff00ffffBFL:NotificationSystem:|r Events registered")
end

--[[--------------------------------------------------
    Event Handlers
--]]--------------------------------------------------

function NotificationSystem:OnFriendOnline(friendType, identifier)
    if not BetterFriendlistDB.notificationSettings.enabled then return end
    if IsQuietTime() then return end
    
    -- BFL:DebugPrint("|cff00ffffBFL:NotificationSystem:|r Friend online: " .. tostring(identifier) .. " (" .. friendType .. ")")
    
    local isSwitch = false
    -- Check for pending offline timer (Character Switch Detection)
    local timerKey = friendType .. "_" .. tostring(identifier)
    if self.offlineTimers[timerKey] then
        -- Cancel offline timer -> It was a character switch!
        self.offlineTimers[timerKey]:Cancel()
        self.offlineTimers[timerKey] = nil
        -- BFL:DebugPrint("|cff00ffffBFL:NotificationSystem:|r Character switch detected for " .. tostring(identifier))
        isSwitch = true
    end
    
    -- Get friend data
    local friendData = self:GetFriendData(friendType, identifier)
    if not friendData then return end
    
    -- Check cooldowns (Event-specific AND Global)
    local cooldownKey = friendType .. "_" .. tostring(identifier) .. "_ONLINE"
    local globalKey = friendType .. "_" .. tostring(identifier) .. "_GLOBAL"
    
    if self:IsOnCooldown(cooldownKey) or self:IsOnCooldown(globalKey) then return end
    
    -- Check notification rules (Phase 2)
    if CheckRules("ONLINE", friendData) then
        -- Show notification
        local message = BFL.L.NOTIFICATION_IS_NOW_ONLINE
        if isSwitch then
            message = BFL.L.NOTIFICATION_RECONNECTED
        elseif friendData.gameAccountInfo and friendData.gameAccountInfo.clientProgram then
            local clientName = friendData.gameAccountInfo.clientProgram == BNET_CLIENT_WOW and "World of Warcraft" or friendData.gameAccountInfo.clientProgram
            message = string.format(BFL.L.NOTIFICATION_ONLINE_PLAYING_FMT, clientName)
        end
        ShowNotification(friendData.name, "ONLINE", message, nil)
    end
    
    -- Set cooldowns
    self:SetCooldown(cooldownKey)
    self:SetCooldown(globalKey)
end

function NotificationSystem:OnFriendOffline(friendType, identifier)
    if not BetterFriendlistDB.notificationSettings.enabled then return end
    if IsQuietTime() then return end
    
    -- BFL:DebugPrint("|cff00ffffBFL:NotificationSystem:|r Friend offline (Pending): " .. tostring(identifier) .. " (" .. friendType .. ")")
    
    -- Start Debounce Timer instead of showing immediately
    local timerKey = friendType .. "_" .. tostring(identifier)
    
    -- Cancel existing timer if any (shouldn't happen usually)
    if self.offlineTimers[timerKey] then
        self.offlineTimers[timerKey]:Cancel()
    end
    
    self.offlineTimers[timerKey] = C_Timer.After(OFFLINE_DEBOUNCE_DURATION, function()
        self.offlineTimers[timerKey] = nil
        ExecuteOfflineNotification(friendType, identifier)
    end)
end

ExecuteOfflineNotification = function(friendType, identifier)
    -- Re-check conditions (settings might have changed in 5s)
    if not BetterFriendlistDB.notificationSettings.enabled then return end
    if IsQuietTime() then return end

    -- Get friend data (might be nil if fully removed, but we usually have cached name)
    -- Note: GetFriendData might fail if friend is offline, so we might need to rely on cached data or pass name
    -- For BNet, we can still get info usually. For WoW, we might need to pass name.
    local friendData = NotificationSystem:GetFriendData(friendType, identifier)
    
    -- Fallback for WoW friends if not found (since they are offline now)
    if not friendData and friendType == "WOW" then
        friendData = { name = identifier, type = "WOW" }
    end
    
    if not friendData then return end
    
    -- Check cooldowns
    local cooldownKey = friendType .. "_" .. tostring(identifier) .. "_OFFLINE"
    local globalKey = friendType .. "_" .. tostring(identifier) .. "_GLOBAL"
    
    if NotificationSystem:IsOnCooldown(cooldownKey) or NotificationSystem:IsOnCooldown(globalKey) then return end
    
    -- Check notification rules
    if CheckRules("OFFLINE", friendData) then
        -- Show notification
        local message = BFL.L.NOTIFICATION_GONE_OFFLINE
        ShowNotification(friendData.name, "OFFLINE", message, nil)
    end
    
    -- Set cooldowns
    NotificationSystem:SetCooldown(cooldownKey)
    NotificationSystem:SetCooldown(globalKey)
end

function NotificationSystem:OnFriendInfoChanged(bnetAccountID)
    if not BetterFriendlistDB.notificationSettings.enabled then return end
    if not BetterFriendlistDB.notificationSettings.showGameChanges then return end
    if IsQuietTime() then return end
    
    local friendData = self:GetFriendData("BNET", bnetAccountID)
    if not friendData then return end
    
    -- Check if game changed
    local oldProgram = self.bnetFriendCache[bnetAccountID]
    local newProgram = friendData.clientProgram
    
    -- Update cache
    self.bnetFriendCache[bnetAccountID] = newProgram
    
    -- Only notify if program changed AND it's not just going offline/online (handled by other events)
    if oldProgram and newProgram and oldProgram ~= newProgram and newProgram ~= "App" and oldProgram ~= "App" then
        -- Check cooldowns
        local cooldownKey = "BNET_" .. tostring(bnetAccountID) .. "_GAMECHANGE"
        local globalKey = "BNET_" .. tostring(bnetAccountID) .. "_GLOBAL"
        
        if self:IsOnCooldown(cooldownKey) or self:IsOnCooldown(globalKey) then return end
        
        -- Check notification rules
        if CheckRules("GAME_CHANGE", friendData) then
            local clientName = newProgram == BNET_CLIENT_WOW and "World of Warcraft" or newProgram
            local message = string.format(BFL.L.NOTIFICATION_PLAYING_FMT, clientName)
            ShowNotification(friendData.name, "ONLINE", message, nil)
        end
        
        self:SetCooldown(cooldownKey)
        self:SetCooldown(globalKey)
    end
end

function NotificationSystem:OnFriendListUpdate()
    -- Process WoW friend changes
    ProcessWoWFriendChanges()
end

--[[--------------------------------------------------
    WoW Friend Tracking
--]]--------------------------------------------------

function SnapshotWoWFriends()
    local numFriends = C_FriendList.GetNumFriends()
    local playerRealm = GetNormalizedRealmName()
    for i = 1, numFriends do
        local info = C_FriendList.GetFriendInfoByIndex(i)
        if info and info.name then
            local normalizedName = BFL:NormalizeWoWFriendName(info.name, playerRealm)
            NotificationSystem.wowFriendCache[normalizedName] = info.connected
        end
    end
end

function ProcessWoWFriendChanges()
    local numFriends = C_FriendList.GetNumFriends()
    local currentFriends = {}
    local playerRealm = GetNormalizedRealmName()
    
    for i = 1, numFriends do
        local info = C_FriendList.GetFriendInfoByIndex(i)
        if info and info.name then
            local normalizedName = BFL:NormalizeWoWFriendName(info.name, playerRealm)
            currentFriends[normalizedName] = info.connected
            
            local wasConnected = NotificationSystem.wowFriendCache[normalizedName]
            
            -- Check for status change
            if wasConnected ~= nil and wasConnected ~= info.connected then
                if info.connected then
                    NotificationSystem:OnFriendOnline("WOW", normalizedName)
                else
                    NotificationSystem:OnFriendOffline("WOW", normalizedName)
                end
            end
            
            -- Update cache
            NotificationSystem.wowFriendCache[normalizedName] = info.connected
        end
    end
    
    -- Handle removed friends (optional cleanup)
    for name, _ in pairs(NotificationSystem.wowFriendCache) do
        if currentFriends[name] == nil then
            NotificationSystem.wowFriendCache[name] = nil
        end
    end
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
    
    -- Determine duration based on key type
    local duration = COOLDOWN_DURATION
    if string.find(key, "_GLOBAL$") then
        duration = GLOBAL_COOLDOWN_DURATION
    end
    
    return elapsed < duration
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
    Rule Checking
--]]--------------------------------------------------

function CheckRules(triggerType, friendData)
    local settings = BetterFriendlistDB.notificationSettings
    
    -- 1. Offline Filter
    if triggerType == "OFFLINE" and not settings.showOffline then
        return false
    end
    
    -- 2. Favorites Only Filter
    if settings.onlyFavorites then
        -- BNet favorites
        if friendData.type == "BNET" then
            local accountInfo = C_BattleNet.GetFriendAccountInfo(friendData.bnetAccountID)
            if not accountInfo or not accountInfo.isFavorite then
                return false
            end
        end
        -- WoW favorites (check notes for [Fav] tag or similar if implemented, otherwise skip)
        -- For now, WoW friends are not filtered by favorite status as API doesn't support it natively
    end
    
    -- 3. App Filter (Hide "Online in App")
    if not settings.showApp and friendData.clientProgram == "App" and triggerType == "ONLINE" then
        return false
    end
    
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
    ShowNotification("TestPlayer", "ONLINE", string.format(BFL.L.NOTIFICATION_ONLINE_PLAYING_FMT, "World of Warcraft"), nil)
    print("|cff00ff00[BFL]|r " .. string.format(BFL.L.NOTIFICATION_TEST_TRIGGERED, BetterFriendlistDB.notificationDisplayMode))
end

-- Export module
BFL.NotificationSystem = NotificationSystem
