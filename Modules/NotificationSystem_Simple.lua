--[[
    NotificationSystem - Simple Toast Notifications
    Clean, working implementation without AlertFrame complexity
--]]

local _, BFL = ...
local NotificationSystem = {}

-- Queue for notifications when all 3 toasts are showing
local notificationQueue = {}
local toastInitialized = false

-- Active toast slots (up to 3 simultaneous toasts)
-- NOTE: Frames don't exist at load time, must be accessed dynamically
local activeToasts = nil

-- Get active toast frames (lazy initialization)
local function GetActiveToasts()
    if not activeToasts then
        activeToasts = {
            _G["BFL_FriendNotificationToast1"],
            _G["BFL_FriendNotificationToast2"],
            _G["BFL_FriendNotificationToast3"]
        }
        
        -- Verify all frames exist
        for i, frame in ipairs(activeToasts) do
            if not frame then
                -- BFL:DebugPrint("|cffff0000BFL:NotificationSystem:|r Toast frame " .. i .. " not found!")
                return nil
            end
        end
    end
    return activeToasts
end

--[[--------------------------------------------------
    Beta Feature Guard
    CRITICAL: Nothing in this module should work if Beta Features are disabled
--]]--------------------------------------------------

local function IsBetaEnabled()
    return BetterFriendlistDB and BetterFriendlistDB.enableBetaFeatures == true
end

--[[--------------------------------------------------
    Toast Display Functions
--]]--------------------------------------------------

-- Find next available toast slot (up to 3 simultaneous toasts)
local function GetAvailableToastSlot()
    local toasts = GetActiveToasts()
    if not toasts then
        -- BFL:DebugPrint("|cffff0000BFL:NotificationSystem:|r Toast frames not available!")
        return nil
    end
    
    for i, frame in ipairs(toasts) do
        if frame and not frame:IsShown() then
            return frame
        end
    end
    return nil -- All 3 slots occupied
end

local function ShowToast(name, message, icon)
    -- Find available toast slot
    local frame = GetAvailableToastSlot()
    
    if not frame then
        -- All 3 slots occupied, queue it
        table.insert(notificationQueue, {name = name, message = message, icon = icon})
        -- BFL:DebugPrint("|cffffcc00BFL:NotificationSystem:|r All 3 toast slots occupied, queued notification")
        return true
    end
    
    -- Set content
    frame.Name:SetText(name)
    frame.Message:SetText(message)
    
    if icon then
        frame.Icon:SetTexture(icon)
        
        -- Auto-color based on known icons
        if icon:find("user%-check") then
            frame.Icon:SetVertexColor(0.3, 1, 0.3, 1) -- Green
        elseif icon:find("user%-x") then
            frame.Icon:SetVertexColor(0.5, 0.5, 0.5, 1) -- Grey
        else
            frame.Icon:SetVertexColor(1, 1, 1, 1) -- White (Game icons etc)
        end
    else
        frame.Icon:SetTexture("Interface\\AddOns\\BetterFriendlist\\Icons\\user-check")
        frame.Icon:SetVertexColor(0.3, 1, 0.3, 1)
    end
    
    -- Play sound if enabled (only for first toast to avoid sound spam)
    if BetterFriendlistDB.notificationSoundEnabled and frame == activeToasts[1] then
        PlaySound(SOUNDKIT.UI_BNET_TOAST)
    end
    
    -- Show with animation
    frame:Show()
    frame.FadeIn:Play()
    
    return true
end

local function InitializeToast()
    if toastInitialized then return end
    
    local toasts = GetActiveToasts()
    if not toasts then
        -- BFL:DebugPrint("|cffff0000BFL:NotificationSystem:|r Cannot initialize toasts - frames not found!")
        return
    end
    
    -- Set up animation callbacks for all 3 toast frames
    for i, frame in ipairs(toasts) do
        
        -- FadeIn -> FadeOut
        frame.FadeIn:SetScript("OnFinished", function(self)
            self:GetParent().FadeOut:Play()
        end)
        
        -- FadeOut -> Hide and process queue
        frame.FadeOut:SetScript("OnFinished", function(self)
            local toast = self:GetParent()
            toast:Hide()
            
            -- Show next queued notification (after small delay for smooth transition)
            if #notificationQueue > 0 then
                local next = table.remove(notificationQueue, 1)
                C_Timer.After(0.3, function()
                    ShowToast(next.name, next.message, next.icon)
                end)
            end
        end)
    end
    
    toastInitialized = true
    -- BFL:DebugPrint("|cff00ffffBFL:NotificationSystem:|r Initialized 3 toast frames")
end

--[[--------------------------------------------------
    Public API
--]]--------------------------------------------------

function NotificationSystem:ShowNotification(friendName, message, iconTexture)
    -- CRITICAL: Block if Beta Features disabled
    if not IsBetaEnabled() then
        return
    end
    
    -- Initialize on first use
    if not toastInitialized then
        InitializeToast()
    end
    
    local displayMode = BetterFriendlistDB.notificationDisplayMode
    
    if displayMode == "alert" then
        if toastInitialized then
            ShowToast(friendName, message, iconTexture)
        else
            -- Fallback to chat
            -- BFL:DebugPrint(string.format("|cff00ff00%s|r %s", friendName, message))
        end
    elseif displayMode == "chat" then
        -- Chat notification
        -- BFL:DebugPrint(string.format("|cff00ff00%s|r %s", friendName, message))
    end
    -- "disabled" - do nothing
end

function NotificationSystem:ShowTestNotification()
    -- CRITICAL: Block if Beta Features disabled
    if not IsBetaEnabled() then
        print("|cffff0000BetterFriendlist:|r Beta Features must be enabled to use notifications")
        print("|cffffcc00[>]|r Enable in Settings > Advanced > Beta Features")
        return
    end
    
    -- Initialize if needed
    if not toastInitialized then
        InitializeToast()
    end
    
    -- Mock data for testing custom templates (Phase 11)
    local mockData = {
        name = UnitName("player") or "TestFriend",
        game = "World of Warcraft",
        level = tostring(UnitLevel("player") or "70"),
        zone = GetZoneText() or "Dornogal",
        class = UnitClass("player") or "Paladin",
        realm = GetRealmName() or "Ravencrest"
    }
    
    -- Use custom template
    local template = BetterFriendlistDB.notificationMessageOnline or "%name% is now online"
    local message = self:ReplaceMessageTemplate(template, mockData)
    
    self:ShowNotification(
        mockData.name,
        message,
        "Interface\\AddOns\\BetterFriendlist\\Icons\\user-check"
    )
    
    -- BFL:DebugPrint("Test notification triggered! (Mode: " .. (BetterFriendlistDB.notificationDisplayMode or "alert") .. ")")
end

-- Test group notification rules
function NotificationSystem:TestGroupRules()
    -- CRITICAL: Block if Beta Features disabled
    if not IsBetaEnabled() then
        print("|cffff0000BetterFriendlist:|r Beta Features must be enabled to use notifications")
        print("|cffffcc00[>]|r Enable in Settings > Advanced > Beta Features")
        return
    end
    
    print("|cff00ff00BetterFriendlist:|r Testing Group Notification Rules...")
    print(" ")
    
    -- Test with first BNet friend
    local numBNet = BNGetNumFriends()
    if numBNet == 0 then
        print("|cffffcc00[>]|r No BattleNet friends found")
        return
    end
    
    local accountInfo = C_BattleNet.GetFriendAccountInfo(1)
    if not accountInfo then
        print("|cffffcc00[>]|r Could not get friend info")
        return
    end
    
    local battleTag = accountInfo.battleTag or "Unknown"
    local friendName = battleTag:match("^([^#]+)") or battleTag
    local friendUID = "bnet_" .. (accountInfo.battleTag or tostring(accountInfo.bnetAccountID))
    
    print("|cff00ffffTesting with friend:|r " .. friendName .. " (UID: " .. friendUID .. ")")
    print(" ")
    
    -- Check rules
    local shouldNotify, isWhitelisted, ruleSource = self:CheckNotificationRules(friendUID)
    
    -- Display results
    print("|cff00ffffRule Check Results:|r")
    print("  Should Notify: " .. (shouldNotify and "|cff00ff00YES|r" or "|cffff0000NO|r"))
    print("  Is Whitelisted: " .. (isWhitelisted and "|cff00ff00YES|r" or "|cffff0000NO|r"))
    print("  Rule Source: |cffffcc00" .. ruleSource .. "|r")
    print(" ")
    
    -- Show friend's groups
    if BetterFriendlistDB.friendGroups and BetterFriendlistDB.friendGroups[friendUID] then
        print("|cff00ffffFriend's Groups:|r")
        for _, groupId in ipairs(BetterFriendlistDB.friendGroups[friendUID]) do
            local groupRule = BetterFriendlistDB.notificationGroupRules and BetterFriendlistDB.notificationGroupRules[groupId]
            local ruleText = groupRule or "default"
            local color = groupRule == "whitelist" and "|cff00ff00" or (groupRule == "blacklist" and "|cffff0000" or "|cffffffff")
            print("  • " .. groupId .. ": " .. color .. ruleText .. "|r")
        end
    else
        print("|cffffcc00Friend is not in any custom groups|r")
    end
    print(" ")
    
    -- Show favorites status
    if accountInfo.isFavorite then
        local favRule = BetterFriendlistDB.notificationGroupRules and BetterFriendlistDB.notificationGroupRules["favorites"]
        local ruleText = favRule or "default"
        local color = favRule == "whitelist" and "|cff00ff00" or (favRule == "blacklist" and "|cffff0000" or "|cffffffff")
        print("|cff00ffffFavorites Group:|r " .. color .. ruleText .. "|r")
    end
    
    print("|cff00ff00Test complete!|r")
end

-- ========================================
-- Event System
-- ========================================

function NotificationSystem:RegisterEvents()
    -- CRITICAL: Do NOT register events if Beta Features disabled
    if not IsBetaEnabled() then
        -- BFL:DebugPrint("|cffffcc00BFL:NotificationSystem:|r Events NOT registered (Beta Features disabled)")
        return
    end
    
    -- BFL:DebugPrint("|cff00ffffBFL:NotificationSystem:|r Registering events (Beta Features enabled)")
    
    -- BattleNet Friend Online
    BFL:RegisterEventCallback("BN_FRIEND_ACCOUNT_ONLINE", function(bnetAccountID)
        self:OnFriendOnline("BNET", bnetAccountID)
    end)
    
    -- BattleNet Friend Offline
    BFL:RegisterEventCallback("BN_FRIEND_ACCOUNT_OFFLINE", function(bnetAccountID)
        self:OnFriendOffline("BNET", bnetAccountID)
    end)
    
    -- WoW Friends (need to track status changes)
    BFL:RegisterEventCallback("FRIENDLIST_UPDATE", function()
        self:OnFriendListUpdate()
    end)
    
    -- Phase 11.5: BattleNet Friend Info Changed (game/character changes)
    BFL:RegisterEventCallback("BN_FRIEND_INFO_CHANGED", function()
        self:OnFriendInfoChanged()
    end)
    
    -- Initialize friend state cache on PLAYER_LOGIN (avoid false positives on addon load)
    BFL:RegisterEventCallback("PLAYER_LOGIN", function()
        self:InitializeFriendStateCache()
    end)
end

-- Track previous online state for WoW friends
NotificationSystem.lastWoWFriendState = {}

-- Phase 11.5: Track friend game/character state for detailed notifications
-- Structure: {bnetAccountID = {clientProgram, characterName, lastUpdate}}
NotificationSystem.friendStateCache = {}

--[[--------------------------------------------------
    Notification Rules Checking (Phase 9 + Group Rules)
    Priority: Per-friend > Group Whitelist > Group Blacklist > Global
--]]--------------------------------------------------

-- Check if friend should trigger notification based on rules
-- Returns: shouldNotify (bool), isWhitelisted (bool), ruleSource (string)
function NotificationSystem:CheckNotificationRules(friendUID)
    -- 1. Check per-friend rule (HIGHEST PRIORITY)
    if BetterFriendlistDB.notificationFriendRules then
        local friendRule = BetterFriendlistDB.notificationFriendRules[friendUID]
        
        if friendRule == "blacklist" then
            -- BFL:DebugPrint("|cffffcc00BFL:NotificationSystem:|r Friend " .. friendUID .. " is blacklisted (per-friend rule)")
            return false, false, "friend-blacklist"
        elseif friendRule == "whitelist" then
            -- BFL:DebugPrint("|cf00ffffBFL:NotificationSystem:|r Friend " .. friendUID .. " is whitelisted (per-friend rule)")
            return true, true, "friend-whitelist"  -- Bypass quiet time + cooldown
        end
    end
    
    -- 2. Check group rules for ALL groups this friend belongs to
    if BetterFriendlistDB.friendGroups and BetterFriendlistDB.friendGroups[friendUID] then
        local hasWhitelist = false
        local hasBlacklist = false
        local whitelistGroup = nil
        local blacklistGroup = nil
        
        -- Check all groups this friend is in
        for _, groupId in ipairs(BetterFriendlistDB.friendGroups[friendUID]) do
            if BetterFriendlistDB.notificationGroupRules then
                local groupRule = BetterFriendlistDB.notificationGroupRules[groupId]
                
                if groupRule == "whitelist" then
                    hasWhitelist = true
                    whitelistGroup = groupId
                elseif groupRule == "blacklist" then
                    hasBlacklist = true
                    blacklistGroup = groupId
                end
            end
        end
        
        -- Priority: Whitelist > Blacklist
        if hasWhitelist then
            -- BFL:DebugPrint("|cf00ffffBFL:NotificationSystem:|r Friend " .. friendUID .. " is whitelisted (group: " .. whitelistGroup .. ")")
            return true, true, "group-whitelist"  -- Bypass quiet time + cooldown
        elseif hasBlacklist then
            -- BFL:DebugPrint("|cffffcc00BFL:NotificationSystem:|r Friend " .. friendUID .. " is blacklisted (group: " .. blacklistGroup .. ")")
            return false, false, "group-blacklist"
        end
    end
    
    -- 3. Check favorites group (special built-in group)
    if friendUID:match("^bnet_") then
        -- Get BNet account info to check isFavorite
        local battleTag = friendUID:match("^bnet_(.+)$")
        if battleTag then
            local numBNet = BNGetNumFriends()
            for i = 1, numBNet do
                local accountInfo = C_BattleNet.GetFriendAccountInfo(i)
                if accountInfo and accountInfo.battleTag == battleTag then
                    if accountInfo.isFavorite and BetterFriendlistDB.notificationGroupRules then
                        local favRule = BetterFriendlistDB.notificationGroupRules["favorites"]
                        if favRule == "whitelist" then
                            -- BFL:DebugPrint("|cf00ffffBFL:NotificationSystem:|r Friend " .. friendUID .. " is whitelisted (favorites group)")
                            return true, true, "favorites-whitelist"
                        elseif favRule == "blacklist" then
                            -- BFL:DebugPrint("|cffffcc00BFL:NotificationSystem:|r Friend " .. friendUID .. " is blacklisted (favorites group)")
                            return false, false, "favorites-blacklist"
                        end
                    end
                    break
                end
            end
        end
    end
    
    -- 4. Default: Use global settings (no special rule)
    -- BFL:DebugPrint("|cf00ffffBFL:NotificationSystem:|r Friend " .. friendUID .. " using default (global settings)")
    return true, false, "global"
end

-- Flag to track if initial state has been captured
NotificationSystem.initialStateLoaded = false

--[[--------------------------------------------------
    Cooldown System (Anti-Spam)
    Prevents notification spam when friends relog quickly
    
    IMPROVED (Phase 14d): Separate cooldowns per event type
    - online/offline: 30s (prevent rapid relog spam)
    - charSwitch: 10s (allow frequent char switches, but throttle rapid switching)
    - gameSwitch: 10s (allow game switches)
--]]--------------------------------------------------

NotificationSystem.cooldownTimers = {} -- {friendUID = {online = timestamp, offline = timestamp, charSwitch = timestamp, gameSwitch = timestamp}}
NotificationSystem.offlineTimers = {} -- {friendUID = timer}

-- Cooldown durations per event type (in seconds)
local COOLDOWN_DURATIONS = {
    online = 30,      -- Friend comes online (prevent rapid relog spam)
    offline = 30,     -- Friend goes offline (prevent rapid disconnect spam)
    charSwitch = 10,  -- Character switch (allow more frequent, but throttle rapid switching)
    gameSwitch = 10,  -- Game switch (allow more frequent)
    wowLogin = 30,    -- WoW login (same as online)
}

local GLOBAL_COOLDOWN_DURATION = 5
local OFFLINE_DEBOUNCE_DURATION = 5

-- Check if notification is on cooldown for specific event type
function NotificationSystem:IsOnCooldown(friendUID, eventType)
    eventType = eventType or "online" -- Default to online if not specified
    
    if not self.cooldownTimers[friendUID] then
        return false
    end
    
    -- Check Global Cooldown
    local lastGlobal = self.cooldownTimers[friendUID]["global"]
    if lastGlobal and (GetTime() - lastGlobal < GLOBAL_COOLDOWN_DURATION) then
        return true
    end
    
    local lastShown = self.cooldownTimers[friendUID][eventType]
    if not lastShown then
        return false
    end
    
    local duration = COOLDOWN_DURATIONS[eventType] or 30
    local elapsed = GetTime() - lastShown
    return elapsed < duration
end

-- Set cooldown for specific event type
function NotificationSystem:SetCooldown(friendUID, eventType)
    eventType = eventType or "online" -- Default to online if not specified
    
    if not self.cooldownTimers[friendUID] then
        self.cooldownTimers[friendUID] = {}
    end
    
    local currentTime = GetTime()
    self.cooldownTimers[friendUID][eventType] = currentTime
    self.cooldownTimers[friendUID]["global"] = currentTime -- Set global cooldown
    
    local duration = COOLDOWN_DURATIONS[eventType] or 30
    -- BFL:DebugPrint("|cff00ffffBFL:NotificationSystem:|r Cooldown set for " .. friendUID .. " [" .. eventType .. "] (" .. duration .. "s)")
end

-- Clean up expired cooldowns (called periodically)
function NotificationSystem:CleanupCooldowns()
    local currentTime = GetTime()
	local friendsToRemove = {}
	
	for friendUID, cooldowns in pairs(self.cooldownTimers) do
		local eventsToRemove = {}
		
		-- Phase 1: Collect expired events (safe iteration)
		for eventType, timestamp in pairs(cooldowns) do
			local duration = COOLDOWN_DURATIONS[eventType] or 30
			if (currentTime - timestamp) > duration then
				table.insert(eventsToRemove, eventType)
			end
		end
		
		-- Phase 2: Remove expired events
		for _, eventType in ipairs(eventsToRemove) do
			cooldowns[eventType] = nil
		end
		
		-- Phase 3: Mark empty friend entries for removal
		if not next(cooldowns) then
			table.insert(friendsToRemove, friendUID)
		end
	end
	
	-- Phase 4: Remove empty friend entries
	for _, friendUID in ipairs(friendsToRemove) do
		self.cooldownTimers[friendUID] = nil
	end
	
	if #friendsToRemove > 0 then
		-- BFL:DebugPrint("|cff00ffffBFL:NotificationSystem:|r Cooldown cleanup complete (removed " .. #friendsToRemove .. " expired friends)")
	end
end

--[[--------------------------------------------------
    Friend State Tracking (Phase 11.5)
    Tracks game/character changes to detect WoW logins and character switches
--]]--------------------------------------------------

-- Get cached friend state
function NotificationSystem:GetFriendState(bnetAccountID)
    return self.friendStateCache[bnetAccountID]
end

-- Initialize friend state cache (called on PLAYER_LOGIN)
function NotificationSystem:InitializeFriendStateCache()
    if self.initialStateLoaded then
        return
    end
    
    -- BFL:DebugPrint("|cff00ffffBFL:NotificationSystem:|r Initializing friend state cache...")
    
    local numBNetFriends = BNGetNumFriends()
    for i = 1, numBNetFriends do
        local accountInfo = C_BattleNet.GetFriendAccountInfo(i)
        if accountInfo and accountInfo.gameAccountInfo and accountInfo.bnetAccountID then
            local gameInfo = accountInfo.gameAccountInfo
            if gameInfo.isOnline then
                -- Store initial state WITHOUT triggering notifications
                self.friendStateCache[accountInfo.bnetAccountID] = {
                    clientProgram = gameInfo.clientProgram,
                    characterName = gameInfo.characterName,
                    isOnline = gameInfo.isOnline,
                    lastUpdate = GetTime()
                }
            end
        end
    end
    
    self.initialStateLoaded = true
    -- BFL:DebugPrint("|cff00ffffBFL:NotificationSystem:|r Friend state cache initialized with " .. numBNetFriends .. " friends")
end

-- Update friend state and return what changed
-- Returns: changeType ("wowLogin", "charSwitch", "gameSwitch", nil)
function NotificationSystem:UpdateFriendState(bnetAccountID, accountInfo)
    if not accountInfo or not accountInfo.gameAccountInfo then
        return nil
    end
    
    local gameInfo = accountInfo.gameAccountInfo
    local currentState = {
        clientProgram = gameInfo.clientProgram,
        characterName = gameInfo.characterName,
        isOnline = gameInfo.isOnline,
        lastUpdate = GetTime()
    }
    
    -- CRITICAL: Ignore if characterName is nil/empty (loading/transitioning)
    -- This prevents false "char switch" detections when data is temporarily missing
    if currentState.clientProgram == "WoW" and (not currentState.characterName or currentState.characterName == "") then
        -- BFL:DebugPrint("|cffffcc00BFL:NotificationSystem:|r Ignoring state update for " .. bnetAccountID .. " (characterName is nil/empty)")
        return nil
    end
    
    local previousState = self:GetFriendState(bnetAccountID)
    local changeType = nil
    
    if previousState then
        -- IMPROVED (Phase 14d): Detect transient BNet state during character switches
        -- Scenario: CharA → BNet (loading) → CharB
        -- Don't trigger "game switch" for this transient state
        if previousState.clientProgram == "WoW" and 
           previousState.characterName and previousState.characterName ~= "" and
           currentState.clientProgram ~= "WoW" and 
           currentState.isOnline then
            -- This is likely a CHARACTER SWITCH in progress (transitioning through BNet state)
            -- DON'T trigger notification
            -- BFL:DebugPrint("|cffffcc00BFL:NotificationSystem:|r Ignoring transient BNet state for " .. bnetAccountID .. " (likely char switch in progress: " .. previousState.characterName .. " → ?)")
            
            -- Store current state but don't trigger notification
            self.friendStateCache[bnetAccountID] = currentState
            return nil, previousState, currentState
        end
        
        -- Detect WoW Login (wasn't in WoW, now is)
        if previousState.clientProgram ~= "WoW" and currentState.clientProgram == "WoW" then
            changeType = "wowLogin"
            -- BFL:DebugPrint("|cff00ffffBFL:NotificationSystem:|r WoW Login detected for " .. bnetAccountID .. " (was " .. (previousState.clientProgram or "nil") .. ", now WoW)")
        -- Detect Character Switch (was in WoW, still in WoW, different character)
        elseif previousState.clientProgram == "WoW" and currentState.clientProgram == "WoW" then
            -- CRITICAL: Only detect switch if BOTH previous and current names are valid AND different
            if previousState.characterName and previousState.characterName ~= "" and
               currentState.characterName and currentState.characterName ~= "" and
               previousState.characterName ~= currentState.characterName then
                changeType = "charSwitch"
                -- BFL:DebugPrint("|cff00ffffBFL:NotificationSystem:|r Char Switch detected for " .. bnetAccountID .. " (" .. previousState.characterName .. " -> " .. currentState.characterName .. ")")
            end
        -- Detect Game Switch (switched to different game)
        elseif previousState.clientProgram ~= currentState.clientProgram and currentState.clientProgram ~= "WoW" then
            changeType = "gameSwitch"
            -- BFL:DebugPrint("|cff00ffffBFL:NotificationSystem:|r Game Switch detected for " .. bnetAccountID .. " (" .. (previousState.clientProgram or "nil") .. " -> " .. (currentState.clientProgram or "nil") .. ")")
        end
    else
        -- First time seeing this friend - DON'T trigger notification if initial state not loaded
        -- This prevents false positives when addon loads with friends already online
        if not self.initialStateLoaded then
            -- BFL:DebugPrint("|cffffcc00BFL:NotificationSystem:|r Skipping first-time notification for " .. bnetAccountID .. " (initial state not loaded)")
        elseif currentState.clientProgram == "WoW" and currentState.isOnline then
            changeType = "wowLogin"
            -- BFL:DebugPrint("|cff00ffffBFL:NotificationSystem:|r First time seeing " .. bnetAccountID .. " in WoW, treating as WoW Login")
        end
    end
    
    -- Store current state
    self.friendStateCache[bnetAccountID] = currentState
    
    return changeType, previousState, currentState
end

-- Check group triggers (Phase 10)
local TRIGGER_COOLDOWN = 300 -- 5 minutes between trigger notifications

function NotificationSystem:CheckGroupTriggers()
    if not BetterFriendlistDB.notificationGroupTriggers then
        return
    end
    
    -- Get Groups module to access group membership
    local Groups = BFL:GetModule("Groups")
    if not Groups then
        return
    end
    
    local currentTime = GetTime()
    
    -- Check each trigger
    for triggerID, trigger in pairs(BetterFriendlistDB.notificationGroupTriggers) do
        if trigger.enabled then
            -- Check cooldown (5 minutes between notifications)
            local lastTriggered = trigger.lastTriggered or 0
            if (currentTime - lastTriggered) > TRIGGER_COOLDOWN then
                -- Count online friends in this group
                local onlineCount = self:CountOnlineFriendsInGroup(trigger.groupId)
                
                -- Check if threshold reached
                if onlineCount >= trigger.threshold then
                    -- Get group name
                    local group = Groups:Get(trigger.groupId)
                    local groupName = group and group.name or trigger.groupId
                    
                    -- Show notification
                    local message = string.format("%d friends from '%s' are online", onlineCount, groupName)
                    self:ShowNotification("Group Alert", message, "Interface\\AddOns\\BetterFriendlist\\Icons\\users")
                    
                    -- Set cooldown
                    trigger.lastTriggered = currentTime
                    -- BFL:DebugPrint("|cff00ffffBFL:NotificationSystem:|r Group trigger fired: " .. triggerID)
                end
            end
        end
    end
end

-- Count online friends in a specific group
function NotificationSystem:CountOnlineFriendsInGroup(groupId)
    local count = 0
    
    -- Get all Battle.net friends
    local numBNet = BNGetNumFriends()
    for i = 1, numBNet do
        local accountInfo = C_BattleNet.GetFriendAccountInfo(i)
        if accountInfo and accountInfo.gameAccountInfo and accountInfo.gameAccountInfo.isOnline then
            local friendUID = "bnet_" .. (accountInfo.battleTag or tostring(accountInfo.bnetAccountID))
            
            -- Check if in group
            if BetterFriendlistDB.friendGroups and BetterFriendlistDB.friendGroups[friendUID] then
                for _, gid in ipairs(BetterFriendlistDB.friendGroups[friendUID]) do
                    if gid == groupId then
                        count = count + 1
                        break
                    end
                end
            end
            
            -- Check favorites group
            if groupId == "favorites" and accountInfo.isFavorite then
                count = count + 1
            end
        end
    end
    
    -- Get all WoW friends
    local numWoW = C_FriendList.GetNumFriends()
    for i = 1, numWoW do
        local info = C_FriendList.GetFriendInfoByIndex(i)
        if info and info.connected then
            local friendUID = "wow_" .. (info.name or "")
            
            -- Check if in group
            if BetterFriendlistDB.friendGroups and BetterFriendlistDB.friendGroups[friendUID] then
                for _, gid in ipairs(BetterFriendlistDB.friendGroups[friendUID]) do
                    if gid == groupId then
                        count = count + 1
                        break
                    end
                end
            end
        end
    end
    
    return count
end

-- Check if in quiet mode (combat, instance, manual DND, scheduled)
local function IsQuietTime()
    -- Manual DND mode (highest priority)
    if BetterFriendlistDB.notificationQuietManual then
        return true
    end
    
    -- Combat detection
    if BetterFriendlistDB.notificationQuietCombat and UnitAffectingCombat("player") then
        return true
    end
    
    -- Instance detection (dungeons, raids, battlegrounds, arenas)
    if BetterFriendlistDB.notificationQuietInstance then
        local inInstance, instanceType = IsInInstance()
        if inInstance and (instanceType == "party" or instanceType == "raid" or instanceType == "pvp" or instanceType == "arena") then
            return true
        end
    end
    
    -- Scheduled quiet hours (time-based, 15-minute precision)
    if BetterFriendlistDB.notificationQuietScheduled then
        local startMinutes = BetterFriendlistDB.notificationQuietScheduleStartMinutes or 1320 -- Default: 22:00
        local endMinutes = BetterFriendlistDB.notificationQuietScheduleEndMinutes or 480 -- Default: 08:00
        
        -- Get current time in minutes since midnight
        local currentHour = tonumber(date("%H"))
        local currentMin = tonumber(date("%M"))
        local currentMinutes = (currentHour * 60) + currentMin
        
        -- Handle time ranges that cross midnight
        if startMinutes > endMinutes then
            -- e.g., 22:00 (1320) - 08:00 (480)
            if currentMinutes >= startMinutes or currentMinutes < endMinutes then
                return true
            end
        else
            -- e.g., 08:00 (480) - 22:00 (1320)
            if currentMinutes >= startMinutes and currentMinutes < endMinutes then
                return true
            end
        end
    end
    
    return false
end

-- Replace template variables in custom message (Phase 11 + 11.5)
function NotificationSystem:ReplaceMessageTemplate(template, friendData)
    if not template then return nil end
    
    local message = template
    message = message:gsub("%%name%%", friendData.name or "Unknown")
    message = message:gsub("%%game%%", friendData.game or "")
    message = message:gsub("%%level%%", friendData.level or "")
    message = message:gsub("%%zone%%", friendData.zone or "")
    message = message:gsub("%%class%%", friendData.class or "")
    message = message:gsub("%%realm%%", friendData.realm or "")
    -- Phase 11.5: Character switch variables
    message = message:gsub("%%char%%", friendData.char or "")
    message = message:gsub("%%prevchar%%", friendData.prevchar or "")
    
    return message
end

function NotificationSystem:OnFriendOnline(friendType, bnetAccountID)
    -- CRITICAL: Block if Beta Features disabled (defense in depth)
    if not IsBetaEnabled() then
        return
    end
    
    if not BetterFriendlistDB.notificationDisplayMode or BetterFriendlistDB.notificationDisplayMode == "disabled" then
        return
    end
    
    -- Get friend info FIRST (need friendUID for rule checking)
    local friendName, gameName, icon
    local friendUID
    local friendData = {} -- For template replacement (Phase 11)
    
    if friendType == "BNET" then
        local accountInfo = C_BattleNet.GetAccountInfoByID(bnetAccountID)
        if accountInfo then
            -- Toast title: BattleTag without #1234
            local battleTag = accountInfo.battleTag or "Unknown"
            friendName = battleTag:match("^([^#]+)") or battleTag
            friendUID = "bnet_" .. (accountInfo.battleTag or tostring(bnetAccountID))
            friendData.name = friendName
            if accountInfo.gameAccountInfo and accountInfo.gameAccountInfo.clientProgram then
                if accountInfo.gameAccountInfo.clientProgram == "WoW" then
                    gameName = "World of Warcraft"
                    friendData.game = gameName
                    friendData.level = tostring(accountInfo.gameAccountInfo.characterLevel or "")
                    friendData.zone = accountInfo.gameAccountInfo.areaName or ""
                    friendData.class = accountInfo.gameAccountInfo.className or ""
                    friendData.realm = accountInfo.gameAccountInfo.realmName or ""
                else
                    gameName = accountInfo.gameAccountInfo.clientProgram
                    friendData.game = gameName
                end
            end
            icon = "Interface\\AddOns\\BetterFriendlist\\Icons\\user-check"
        end
    end
    
    local isSwitch = false
    if friendUID and self.offlineTimers[friendUID] then
        self.offlineTimers[friendUID]:Cancel()
        self.offlineTimers[friendUID] = nil
        isSwitch = true
        -- BFL:DebugPrint("|cff00ffffBFL:NotificationSystem:|r Character switch detected for " .. friendUID)
    end
    
    -- Check notification rules (per-friend + group rules)
    if friendUID then
        local shouldNotify, isWhitelisted, ruleSource = self:CheckNotificationRules(friendUID)
        
        if not shouldNotify then
            -- Blacklisted (friend or group)
            return
        end
        
        if isWhitelisted then
            -- Whitelisted: Bypass quiet time and cooldown
            if friendName and friendUID then
                local template = BetterFriendlistDB.notificationMessageOnline or "%name% is now online"
                if isSwitch then template = "reconnected" end
                local message = self:ReplaceMessageTemplate(template, friendData)
                self:ShowNotification(friendName, message, icon)
                self:SetCooldown(friendUID, "online")
            else
                -- BFL:DebugPrint("|cffff0000BFL:NotificationSystem:|r Invalid friendUID - skipping whitelisted notification (online)")
            end
            return
        end
    end
    
    -- Check quiet time (only if NOT whitelisted)
    if IsQuietTime() then
        return
    end
    
    -- Check cooldown (anti-spam)
    if friendUID and self:IsOnCooldown(friendUID) then
        -- BFL:DebugPrint("|cffffcc00BFL:NotificationSystem:|r Friend " .. friendUID .. " on cooldown, skipping")
        return
    end
    
    if friendName then
        -- Use custom template (Phase 11)
        local template = BetterFriendlistDB.notificationMessageOnline or "%name% is now online"
        if isSwitch then template = "reconnected" end
        local message = self:ReplaceMessageTemplate(template, friendData)
        self:ShowNotification(friendName, message, icon)
        
        -- Set cooldown AFTER showing notification
        if friendUID then
            self:SetCooldown(friendUID)
            -- BFL:DebugPrint("|cff00ffffBFL:NotificationSystem:|r Cooldown set for " .. friendUID .. " (30s)")
        end
    end
    
    -- Check group triggers (Phase 10)
    self:CheckGroupTriggers()
end

function NotificationSystem:OnFriendOffline(friendType, bnetAccountID)
    -- CRITICAL: Block if Beta Features disabled (defense in depth)
    if not IsBetaEnabled() then return end
    
    -- Check if offline notifications are enabled
    if not BetterFriendlistDB.notificationOfflineEnabled then return end
    
    if not BetterFriendlistDB.notificationDisplayMode or BetterFriendlistDB.notificationDisplayMode == "disabled" then return end
    
    -- Construct UID for timer
    local friendUID
    if friendType == "BNET" then
        local accountInfo = C_BattleNet.GetAccountInfoByID(bnetAccountID)
        if accountInfo then
            friendUID = "bnet_" .. (accountInfo.battleTag or tostring(bnetAccountID))
        end
    end
    
    if not friendUID then return end
    
    -- Start Debounce Timer
    if self.offlineTimers[friendUID] then self.offlineTimers[friendUID]:Cancel() end
    
    self.offlineTimers[friendUID] = C_Timer.After(OFFLINE_DEBOUNCE_DURATION, function()
        self.offlineTimers[friendUID] = nil
        self:ProcessFriendOffline(friendType, bnetAccountID)
    end)
end

function NotificationSystem:ProcessFriendOffline(friendType, bnetAccountID)
    -- CRITICAL: Block if Beta Features disabled (defense in depth)
    if not IsBetaEnabled() then
        return
    end
    
    -- Check if offline notifications are enabled
    if not BetterFriendlistDB.notificationOfflineEnabled then
        return
    end
    
    if not BetterFriendlistDB.notificationDisplayMode or BetterFriendlistDB.notificationDisplayMode == "disabled" then
        return
    end
    
    -- Get friend info FIRST (need friendUID for rule checking)
    local friendName, icon
    local friendUID
    local friendData = {} -- For template replacement (Phase 11)
    
    if friendType == "BNET" then
        local accountInfo = C_BattleNet.GetAccountInfoByID(bnetAccountID)
        if accountInfo then
            -- Toast title: BattleTag without #1234
            local battleTag = accountInfo.battleTag or "Unknown"
            local displayName = battleTag:match("^([^#]+)") or battleTag
            friendName = displayName
            friendUID = "bnet_" .. (accountInfo.battleTag or tostring(bnetAccountID))
            icon = "Interface\\AddOns\\BetterFriendlist\\Icons\\user-x" -- Different icon for offline
            
            friendData.name = displayName
            
            -- Try to get last known game info (may not be available when offline)
            if accountInfo.gameAccountInfo and accountInfo.gameAccountInfo.clientProgram then
                friendData.game = accountInfo.gameAccountInfo.clientProgram
                if accountInfo.gameAccountInfo.characterName then
                    friendData.name = accountInfo.gameAccountInfo.characterName
                    friendName = accountInfo.gameAccountInfo.characterName
                end
            end
        end
    end
    
    -- Check notification rules (per-friend + group rules)
    if friendUID then
        local shouldNotify, isWhitelisted, ruleSource = self:CheckNotificationRules(friendUID)
        
        if not shouldNotify then
            -- Blacklisted (friend or group)
            return
        end
        
        if isWhitelisted then
            -- Whitelisted: Bypass quiet time and cooldown
            if friendName and friendUID then
                local template = BetterFriendlistDB.notificationMessageOffline or "%name% went offline"
                local message = self:ReplaceMessageTemplate(template, friendData)
                self:ShowNotification(friendName, message, icon)
                self:SetCooldown(friendUID, "offline")
            else
                -- BFL:DebugPrint("|cffff0000BFL:NotificationSystem:|r Invalid friendUID - skipping whitelisted notification (offline)")
            end
            return
        end
    end
    
    -- Check quiet time (only if NOT whitelisted)
    if IsQuietTime() then
        return
    end
        -- Check cooldown (anti-spam for rapid on/off) - use 'offline' event type (30s)
    if friendUID and self:IsOnCooldown(friendUID, "offline") then
        -- BFL:DebugPrint("|cffffcc00BFL:NotificationSystem:|r Friend " .. friendUID .. " on cooldown [offline], skipping offline notification")
        return
    end
    
    if friendName then
        -- Use custom template (Phase 11)
        local template = BetterFriendlistDB.notificationMessageOffline or "%name% went offline"
        local message = self:ReplaceMessageTemplate(template, friendData)
        self:ShowNotification(friendName, message, icon)
        
        -- Set cooldown AFTER showing notification (offline event type, 30s)
        if friendUID then
            self:SetCooldown(friendUID, "offline")
        end
    end
end

--[[--------------------------------------------------
    Phase 11.5: Game/Character Change Detection
--]]--------------------------------------------------

function NotificationSystem:OnFriendInfoChanged()
    -- CRITICAL: Block if Beta Features disabled
    if not IsBetaEnabled() then
        return
    end
    
    -- Check if notification system is enabled
    if not BetterFriendlistDB.notificationDisplayMode or BetterFriendlistDB.notificationDisplayMode == "disabled" then
        return
    end
    
    -- BN_FRIEND_INFO_CHANGED doesn't pass parameters, iterate through all BNet friends
	-- CRITICAL: Snapshot friend IDs FIRST to prevent race conditions during rapid changes
	local numBNetFriends = BNGetNumFriends()
	local friendsToProcess = {}
	
	-- Phase 1: Snapshot all friend account IDs (safe iteration)
	for i = 1, numBNetFriends do
		local accountInfo = C_BattleNet.GetFriendAccountInfo(i)
		if accountInfo and accountInfo.bnetAccountID then
			table.insert(friendsToProcess, accountInfo.bnetAccountID)
		end
	end
	
	--BFL:DebugPrint("|cff00ffffBFL:NotificationSystem:|r BN_FRIEND_INFO_CHANGED fired, processing " .. #friendsToProcess .. " friends")
	
	-- Phase 2: Process each friend's state change safely
	for _, bnetAccountID in ipairs(friendsToProcess) do
		-- Get FRESH account info (might have changed during Phase 1)
		local accountInfo = C_BattleNet.GetAccountInfoByID(bnetAccountID)
		
		if accountInfo and accountInfo.gameAccountInfo then
			-- Update state and detect changes
			local changeType, previousState, currentState = self:UpdateFriendState(bnetAccountID, accountInfo)
			
			if changeType then
				-- BFL:DebugPrint("|cff00ffffBFL:NotificationSystem:|r Detected " .. changeType .. " for bnetID " .. bnetAccountID)
				
				-- Get display name (BattleTag without #1234)
				local battleTag = accountInfo.battleTag or "Unknown"
				local displayName = battleTag:match("^([^#]+)") or battleTag
				
				local friendName = displayName
				local friendUID = "bnet_" .. (accountInfo.battleTag or tostring(bnetAccountID))
                
                -- Check notification rules (per-friend + group rules)
                local shouldNotify, isWhitelisted, ruleSource = self:CheckNotificationRules(friendUID)
                
                if not shouldNotify then
                    -- Blacklisted (friend or group)
                    -- BFL:DebugPrint("|cffffcc00BFL:NotificationSystem:|r Friend " .. friendUID .. " blocked by " .. ruleSource .. ", skipping " .. changeType)
                end
                
                -- Only check quiet time and cooldown if NOT whitelisted
                if shouldNotify and not isWhitelisted then
                    if IsQuietTime() then
                        -- BFL:DebugPrint("|cffffcc00BFL:NotificationSystem:|r Quiet time active, skipping " .. changeType .. " for " .. friendUID)
                        shouldNotify = false
                    elseif self:IsOnCooldown(friendUID, changeType) then
                        -- Check cooldown for specific event type (Phase 14d)
                        -- charSwitch: 10s, gameSwitch: 10s, wowLogin: 30s
                        -- BFL:DebugPrint("|cffffcc00BFL:NotificationSystem:|r Friend " .. friendUID .. " on cooldown [" .. changeType .. "], skipping " .. changeType)
                        shouldNotify = false
                    end
                end
                
                -- Check if this notification type is enabled
                if shouldNotify then
                    local notificationType = "notificationWowLoginEnabled"
                    if changeType == "charSwitch" then
                        notificationType = "notificationCharSwitchEnabled"
                    elseif changeType == "gameSwitch" then
                        notificationType = "notificationGameSwitchEnabled"
                    end
                    
                    local isEnabled = BetterFriendlistDB[notificationType]
                    -- BFL:DebugPrint("|cff00ffffBFL:NotificationSystem:|r Checking " .. notificationType .. " = " .. tostring(isEnabled))
                    
                    if not isEnabled then
                        -- BFL:DebugPrint("|cffffcc00BFL:NotificationSystem:|r " .. notificationType .. " is disabled, skipping " .. changeType)
                        shouldNotify = false
                    end
                end
    
                -- Show notification if all checks passed
                if shouldNotify then
                    -- Prepare friend data for template
                    local friendData = {
                        name = currentState.characterName or displayName,
                        game = currentState.clientProgram or "",
                        char = currentState.characterName or "",
                        prevchar = previousState and previousState.characterName or ""
                    }
                    
                    -- Keep friendName as displayName (BattleTag without #1234) for toast title
                    
                    -- Build notification message
                    local template
                    local message
                    
                    if changeType == "wowLogin" then
                        template = BetterFriendlistDB.notificationMessageWowLogin or "%name% logged into World of Warcraft"
                        message = self:ReplaceMessageTemplate(template, friendData)
                    elseif changeType == "charSwitch" then
                        template = BetterFriendlistDB.notificationMessageCharSwitch or "%name% switched character"
                        message = self:ReplaceMessageTemplate(template, friendData)
                    elseif changeType == "gameSwitch" then
                        template = BetterFriendlistDB.notificationMessageGameSwitch or "%name% is now playing %game%"
                        message = self:ReplaceMessageTemplate(template, friendData)
                    end
                    
                    if message then
                        self:ShowNotification(friendName, message, "Interface\\AddOns\\BetterFriendlist\\Icons\\user-check")
                        
                        -- Set cooldown with event-specific type (Phase 14d)
                        -- wowLogin uses 'wowLogin' (30s), charSwitch uses 'charSwitch' (10s), gameSwitch uses 'gameSwitch' (10s)
                        self:SetCooldown(friendUID, changeType)
                        -- BFL:DebugPrint("|cff00ffffBFL:NotificationSystem:|r " .. changeType .. " notification shown for " .. friendUID)
                    end
                end -- End shouldNotify
            end -- End if changeType check
        end -- End if accountInfo check
    end -- End for loop
end

function NotificationSystem:OnFriendListUpdate()
    -- CRITICAL: Block if Beta Features disabled (defense in depth)
    if not IsBetaEnabled() then
        return
    end
    
    if not BetterFriendlistDB.notificationDisplayMode or BetterFriendlistDB.notificationDisplayMode == "disabled" then
        return
    end
    
    -- Check quiet time
    if IsQuietTime() then
        return
    end
    
    -- Track WoW friend status changes
    local numFriends = C_FriendList.GetNumFriends()
    for i = 1, numFriends do
        local friendInfo = C_FriendList.GetFriendInfoByIndex(i)
        if friendInfo then
            local friendUID = "wow_" .. friendInfo.name
            local wasOnline = self.lastWoWFriendState[friendUID]
            local isOnline = friendInfo.connected
            
            if wasOnline == false and isOnline == true then
                -- Check cooldown FIRST (anti-spam)
                if not self:IsOnCooldown(friendUID) then
                    -- Friend just came online
                    self:ShowNotification(friendInfo.name, "is now online", "Interface\\AddOns\\BetterFriendlist\\Icons\\user-check")
                    
                    -- Set cooldown AFTER showing notification
                    self:SetCooldown(friendUID)
                    -- BFL:DebugPrint("|cff00ffffBFL:NotificationSystem:|r Cooldown set for " .. friendUID .. " (30s)")
                else
                    -- BFL:DebugPrint("|cffffcc00BFL:NotificationSystem:|r Friend " .. friendUID .. " on cooldown, skipping")
                end
            end
            
            self.lastWoWFriendState[friendUID] = isOnline
        end
    end
end

-- Compatibility properties for Core.lua checks
NotificationSystem.initialized = true
NotificationSystem.quietMode = false

--[[--------------------------------------------------
    Initialization
--]]--------------------------------------------------

function NotificationSystem:Initialize()
    -- Register events for friend online/offline notifications
    self:RegisterEvents()
    
    -- Set up cooldown cleanup timer (runs every 60 seconds)
    C_Timer.NewTicker(60, function()
        if IsBetaEnabled() then
            self:CleanupCooldowns()
            -- BFL:DebugPrint("|cff00ffffBFL:NotificationSystem:|r Cooldown cleanup completed")
        end
    end)
    
    -- BFL:DebugPrint("|cff00ffffBFL:NotificationSystem:|r Module initialized (Cooldown: 30s, Cleanup: 60s)")
end

-- Export
BFL.NotificationSystem = NotificationSystem
