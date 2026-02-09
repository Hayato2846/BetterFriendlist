-- TestData/EventSimulator.lua
-- Event Simulation System for BetterFriendlist Testing
-- Version 1.0 - February 2026
--
-- Purpose:
-- Programmatically fire WoW events and simulate game scenarios
-- for testing addon functionality without real players.
--
-- Features:
-- - Fire any event through BFL's callback system
-- - Mock WoW API functions temporarily
-- - Simulate friend online/offline transitions
-- - Simulate whisper messages
-- - Sequence events over time
--
-- Usage:
--   /bfl test event fire <event> [args...]    - Fire single event
--   /bfl test event friend online <id>       - Simulate friend coming online
--   /bfl test event friend offline <id>      - Simulate friend going offline
--   /bfl test event whisper <sender>         - Simulate whisper received
--   /bfl test event sequence <name>          - Run event sequence

local ADDON_NAME, BFL = ...

-- Ensure TestData namespace exists
BFL.TestData = BFL.TestData or {}

-- Create EventSimulator module
local EventSimulator = {}
BFL.EventSimulator = EventSimulator

-- ============================================
-- CONSTANTS
-- ============================================

-- Common events used by BFL
EventSimulator.EVENTS = {
    -- Friend List Events
    FRIENDLIST_UPDATE = "FRIENDLIST_UPDATE",
    BN_FRIEND_LIST_SIZE_CHANGED = "BN_FRIEND_LIST_SIZE_CHANGED",
    BN_FRIEND_ACCOUNT_ONLINE = "BN_FRIEND_ACCOUNT_ONLINE",
    BN_FRIEND_ACCOUNT_OFFLINE = "BN_FRIEND_ACCOUNT_OFFLINE",
    BN_FRIEND_INFO_CHANGED = "BN_FRIEND_INFO_CHANGED",
    BN_CONNECTED = "BN_CONNECTED",
    BN_DISCONNECTED = "BN_DISCONNECTED",
    
    -- Group/Raid Events
    GROUP_ROSTER_UPDATE = "GROUP_ROSTER_UPDATE",
    RAID_ROSTER_UPDATE = "RAID_ROSTER_UPDATE",
    GROUP_JOINED = "GROUP_JOINED",
    GROUP_LEFT = "GROUP_LEFT",
    PARTY_INVITE_REQUEST = "PARTY_INVITE_REQUEST",
    
    -- Chat Events
    CHAT_MSG_WHISPER = "CHAT_MSG_WHISPER",
    CHAT_MSG_WHISPER_INFORM = "CHAT_MSG_WHISPER_INFORM",
    CHAT_MSG_BN_WHISPER = "CHAT_MSG_BN_WHISPER",
    CHAT_MSG_BN_WHISPER_INFORM = "CHAT_MSG_BN_WHISPER_INFORM",
    
    -- System Events
    PLAYER_LOGIN = "PLAYER_LOGIN",
    PLAYER_ENTERING_WORLD = "PLAYER_ENTERING_WORLD",
    ADDON_LOADED = "ADDON_LOADED",
}

-- ============================================
-- STATE
-- ============================================

-- Active event sequences
EventSimulator.activeSequences = {}

-- Mocked API functions (original -> mock)
EventSimulator.mockedAPIs = {}
EventSimulator.originalAPIs = {}

-- Event log for debugging
EventSimulator.eventLog = {}
EventSimulator.maxLogEntries = 100
EventSimulator.loggingEnabled = false

-- ============================================
-- CORE EVENT FIRING
-- ============================================

--[[
    Fire an event through BFL's callback system
    @param event string: Event name
    @param ...: Event arguments
    @return boolean: Success
]]
function EventSimulator:FireEvent(event, ...)
    if not event or event == "" then
        BFL:DebugPrint("|cffff0000EventSimulator:|r No event specified")
        return false
    end
    
    -- Log the event if logging is enabled
    if self.loggingEnabled then
        self:LogEvent("FIRE", event, ...)
    end
    
    -- Fire through BFL's callback system
    if BFL.FireEventCallbacks then
        BFL:FireEventCallbacks(event, ...)
        return true
    end
    
    BFL:DebugPrint("|cffff0000EventSimulator:|r BFL.FireEventCallbacks not available")
    return false
end

--[[
    Fire multiple events in sequence with optional delays
    @param events table: Array of {event, args, delay} tables
    @param callback function: Optional callback when sequence completes
    @return string: Sequence ID
]]
function EventSimulator:FireEventSequence(events, callback)
    local sequenceId = "seq_" .. time() .. "_" .. math.random(1000, 9999)
    
    self.activeSequences[sequenceId] = {
        events = events,
        currentIndex = 0,
        callback = callback,
        cancelled = false,
    }
    
    -- Start the sequence
    self:ProcessSequenceStep(sequenceId)
    
    return sequenceId
end

--[[
    Process next step in an event sequence
    @param sequenceId string: Sequence identifier
]]
function EventSimulator:ProcessSequenceStep(sequenceId)
    local sequence = self.activeSequences[sequenceId]
    if not sequence or sequence.cancelled then
        self.activeSequences[sequenceId] = nil
        return
    end
    
    sequence.currentIndex = sequence.currentIndex + 1
    local step = sequence.events[sequence.currentIndex]
    
    if not step then
        -- Sequence complete
        if sequence.callback then
            sequence.callback()
        end
        self.activeSequences[sequenceId] = nil
        return
    end
    
    -- Fire the event
    local event = step.event or step[1]
    local args = step.args or step[2] or {}
    local delay = step.delay or step[3] or 0
    
    self:FireEvent(event, unpack(args))
    
    -- Schedule next step
    if delay > 0 then
        C_Timer.After(delay, function()
            self:ProcessSequenceStep(sequenceId)
        end)
    else
        -- Immediate next step (but yield to allow event processing)
        C_Timer.After(0.01, function()
            self:ProcessSequenceStep(sequenceId)
        end)
    end
end

--[[
    Cancel an active event sequence
    @param sequenceId string: Sequence identifier
]]
function EventSimulator:CancelSequence(sequenceId)
    if self.activeSequences[sequenceId] then
        self.activeSequences[sequenceId].cancelled = true
    end
end

--[[
    Cancel all active sequences
]]
function EventSimulator:CancelAllSequences()
    for id, sequence in pairs(self.activeSequences) do
        sequence.cancelled = true
    end
    wipe(self.activeSequences)
end

-- ============================================
-- API MOCKING
-- ============================================

--[[
    Mock a WoW API function
    @param apiName string: Function name (e.g., "BNGetNumFriends")
    @param mockFunc function: Replacement function
    @return boolean: Success
]]
function EventSimulator:MockAPI(apiName, mockFunc)
    if not apiName or not mockFunc then
        return false
    end
    
    -- Store original if not already stored
    if not self.originalAPIs[apiName] then
        self.originalAPIs[apiName] = _G[apiName]
    end
    
    -- Apply mock
    _G[apiName] = mockFunc
    self.mockedAPIs[apiName] = mockFunc
    
    BFL:DebugPrint("|cff00ff00EventSimulator:|r Mocked API: " .. apiName)
    return true
end

--[[
    Restore a mocked API to original
    @param apiName string: Function name
    @return boolean: Success
]]
function EventSimulator:RestoreAPI(apiName)
    if not self.originalAPIs[apiName] then
        return false
    end
    
    _G[apiName] = self.originalAPIs[apiName]
    self.mockedAPIs[apiName] = nil
    
    BFL:DebugPrint("|cff00ff00EventSimulator:|r Restored API: " .. apiName)
    return true
end

--[[
    Restore all mocked APIs
]]
function EventSimulator:RestoreAllAPIs()
    for apiName, _ in pairs(self.mockedAPIs) do
        if self.originalAPIs[apiName] then
            _G[apiName] = self.originalAPIs[apiName]
        end
    end
    
    wipe(self.mockedAPIs)
    BFL:DebugPrint("|cff00ff00EventSimulator:|r All APIs restored")
end

--[[
    Get list of currently mocked APIs
    @return table: Array of API names
]]
function EventSimulator:GetMockedAPIs()
    local list = {}
    for apiName, _ in pairs(self.mockedAPIs) do
        table.insert(list, apiName)
    end
    return list
end

-- ============================================
-- FRIEND EVENT HELPERS
-- ============================================

--[[
    Simulate a BNet friend coming online
    @param bnetIDAccount number: Account ID (from mock data)
    @param options table: Optional overrides
]]
function EventSimulator:SimulateFriendOnline(bnetIDAccount, options)
    options = options or {}
    
    -- Fire BN_FRIEND_ACCOUNT_ONLINE event
    self:FireEvent(self.EVENTS.BN_FRIEND_ACCOUNT_ONLINE, bnetIDAccount)
    
    -- Also fire FRIENDLIST_UPDATE after a short delay (simulates real behavior)
    if options.updateList ~= false then
        C_Timer.After(0.1, function()
            self:FireEvent(self.EVENTS.FRIENDLIST_UPDATE)
        end)
    end
    
    BFL:DebugPrint("|cff00ff00EventSimulator:|r Simulated friend online: " .. tostring(bnetIDAccount))
end

--[[
    Simulate a BNet friend going offline
    @param bnetIDAccount number: Account ID
    @param options table: Optional overrides
]]
function EventSimulator:SimulateFriendOffline(bnetIDAccount, options)
    options = options or {}
    
    -- Fire BN_FRIEND_ACCOUNT_OFFLINE event
    self:FireEvent(self.EVENTS.BN_FRIEND_ACCOUNT_OFFLINE, bnetIDAccount)
    
    -- Also fire FRIENDLIST_UPDATE after a short delay
    if options.updateList ~= false then
        C_Timer.After(0.1, function()
            self:FireEvent(self.EVENTS.FRIENDLIST_UPDATE)
        end)
    end
    
    BFL:DebugPrint("|cff00ff00EventSimulator:|r Simulated friend offline: " .. tostring(bnetIDAccount))
end

--[[
    Simulate friend info changed (e.g., zone change, status change)
    @param bnetIDAccount number: Account ID
]]
function EventSimulator:SimulateFriendInfoChanged(bnetIDAccount)
    self:FireEvent(self.EVENTS.BN_FRIEND_INFO_CHANGED, bnetIDAccount)
    BFL:DebugPrint("|cff00ff00EventSimulator:|r Simulated friend info change: " .. tostring(bnetIDAccount))
end

--[[
    Simulate Battle.net connection state change
    @param connected boolean: true = connected, false = disconnected
]]
function EventSimulator:SimulateBNetConnection(connected)
    if connected then
        self:FireEvent(self.EVENTS.BN_CONNECTED)
        -- Follow up with friend list update
        C_Timer.After(0.2, function()
            self:FireEvent(self.EVENTS.FRIENDLIST_UPDATE)
        end)
    else
        self:FireEvent(self.EVENTS.BN_DISCONNECTED)
    end
    
    BFL:DebugPrint("|cff00ff00EventSimulator:|r Simulated BNet " .. (connected and "connected" or "disconnected"))
end

--[[
    Simulate friend list refresh (common test scenario)
]]
function EventSimulator:SimulateFriendListRefresh()
    self:FireEvent(self.EVENTS.FRIENDLIST_UPDATE)
    BFL:DebugPrint("|cff00ff00EventSimulator:|r Simulated friend list refresh")
end

-- ============================================
-- GROUP/RAID EVENT HELPERS
-- ============================================

--[[
    Simulate group roster update
]]
function EventSimulator:SimulateGroupUpdate()
    self:FireEvent(self.EVENTS.GROUP_ROSTER_UPDATE)
    BFL:DebugPrint("|cff00ff00EventSimulator:|r Simulated group roster update")
end

--[[
    Simulate raid roster update
]]
function EventSimulator:SimulateRaidUpdate()
    self:FireEvent(self.EVENTS.RAID_ROSTER_UPDATE)
    BFL:DebugPrint("|cff00ff00EventSimulator:|r Simulated raid roster update")
end

--[[
    Simulate party invite request
    @param inviter string: Name of inviter
]]
function EventSimulator:SimulatePartyInvite(inviter)
    inviter = inviter or "TestPlayer"
    self:FireEvent(self.EVENTS.PARTY_INVITE_REQUEST, inviter)
    BFL:DebugPrint("|cff00ff00EventSimulator:|r Simulated party invite from: " .. inviter)
end

-- ============================================
-- CHAT EVENT HELPERS
-- ============================================

--[[
    Simulate receiving a whisper
    @param sender string: Sender name
    @param message string: Message text
    @param isBNet boolean: Is BNet whisper (default: false)
]]
function EventSimulator:SimulateWhisper(sender, message, isBNet)
    sender = sender or "TestPlayer"
    message = message or "Test message"
    
    local event = isBNet and self.EVENTS.CHAT_MSG_BN_WHISPER or self.EVENTS.CHAT_MSG_WHISPER
    
    -- WoW whisper event args: message, sender, language, channelString, ...
    -- Simplified version for testing
    self:FireEvent(event, message, sender, "Common", "", "", "", 0, 0, "", 0, 0, "", 0)
    
    BFL:DebugPrint("|cff00ff00EventSimulator:|r Simulated whisper from: " .. sender)
end

--[[
    Simulate sending a whisper (inform event)
    @param target string: Target name
    @param message string: Message text
    @param isBNet boolean: Is BNet whisper
]]
function EventSimulator:SimulateWhisperSent(target, message, isBNet)
    target = target or "TestPlayer"
    message = message or "Test message sent"
    
    local event = isBNet and self.EVENTS.CHAT_MSG_BN_WHISPER_INFORM or self.EVENTS.CHAT_MSG_WHISPER_INFORM
    
    self:FireEvent(event, message, target, "Common", "", "", "", 0, 0, "", 0, 0, "", 0)
    
    BFL:DebugPrint("|cff00ff00EventSimulator:|r Simulated whisper sent to: " .. target)
end

-- ============================================
-- PREDEFINED SEQUENCES
-- ============================================

EventSimulator.Sequences = {}

-- Friend comes online and their info updates
EventSimulator.Sequences.friend_login = {
    name = "Friend Login Sequence",
    description = "Simulates a friend logging in (online event + info change + list update)",
    create = function(bnetIDAccount)
        return {
            {event = "BN_FRIEND_ACCOUNT_ONLINE", args = {bnetIDAccount}},
            {event = "BN_FRIEND_INFO_CHANGED", args = {bnetIDAccount}, delay = 0.2},
            {event = "FRIENDLIST_UPDATE", args = {}, delay = 0.3},
        }
    end,
}

-- Friend goes offline
EventSimulator.Sequences.friend_logout = {
    name = "Friend Logout Sequence",
    description = "Simulates a friend logging out",
    create = function(bnetIDAccount)
        return {
            {event = "BN_FRIEND_ACCOUNT_OFFLINE", args = {bnetIDAccount}},
            {event = "FRIENDLIST_UPDATE", args = {}, delay = 0.2},
        }
    end,
}

-- Multiple friends come online rapidly (stress test)
EventSimulator.Sequences.mass_login = {
    name = "Mass Friend Login",
    description = "Simulates many friends logging in rapidly",
    create = function(count, startId)
        count = count or 10
        startId = startId or 1000
        local events = {}
        
        for i = 1, count do
            table.insert(events, {
                event = "BN_FRIEND_ACCOUNT_ONLINE",
                args = {startId + i},
                delay = 0.05,
            })
        end
        
        -- Final list update
        table.insert(events, {
            event = "FRIENDLIST_UPDATE",
            args = {},
            delay = 0.5,
        })
        
        return events
    end,
}

-- BNet reconnection sequence
EventSimulator.Sequences.bnet_reconnect = {
    name = "BNet Reconnection",
    description = "Simulates BNet disconnecting and reconnecting",
    create = function()
        return {
            {event = "BN_DISCONNECTED", args = {}},
            {event = "BN_CONNECTED", args = {}, delay = 2.0},
            {event = "FRIENDLIST_UPDATE", args = {}, delay = 0.5},
        }
    end,
}

-- Activity tracking test sequence
EventSimulator.Sequences.activity_test = {
    name = "Activity Tracking Test",
    description = "Simulates whisper activity for ActivityTracker",
    create = function(friendName)
        friendName = friendName or "TestFriend"
        return {
            {event = "CHAT_MSG_WHISPER", args = {"Hello!", friendName, "Common"}},
            {event = "CHAT_MSG_WHISPER_INFORM", args = {"Hi there!", friendName, "Common"}, delay = 1.0},
            {event = "CHAT_MSG_WHISPER", args = {"How are you?", friendName, "Common"}, delay = 2.0},
        }
    end,
}

--[[
    Run a predefined sequence
    @param sequenceName string: Name of sequence (e.g., "friend_login")
    @param ...: Arguments passed to sequence creator
    @return string or nil: Sequence ID if started
]]
function EventSimulator:RunSequence(sequenceName, ...)
    local sequenceDef = self.Sequences[sequenceName]
    if not sequenceDef then
        BFL:DebugPrint("|cffff0000EventSimulator:|r Unknown sequence: " .. tostring(sequenceName))
        return nil
    end
    
    local events = sequenceDef.create(...)
    BFL:DebugPrint("|cff00ff00EventSimulator:|r Running sequence: " .. sequenceDef.name)
    
    return self:FireEventSequence(events, function()
        BFL:DebugPrint("|cff00ff00EventSimulator:|r Sequence complete: " .. sequenceDef.name)
    end)
end

--[[
    List available sequences
    @return table: Array of {id, name, description}
]]
function EventSimulator:ListSequences()
    local list = {}
    for id, def in pairs(self.Sequences) do
        table.insert(list, {
            id = id,
            name = def.name,
            description = def.description,
        })
    end
    table.sort(list, function(a, b) return a.id < b.id end)
    return list
end

-- ============================================
-- EVENT LOGGING
-- ============================================

--[[
    Log an event
    @param action string: Action type (FIRE, MOCK, etc.)
    @param event string: Event name
    @param ...: Event arguments
]]
function EventSimulator:LogEvent(action, event, ...)
    local entry = {
        timestamp = GetTime(),
        action = action,
        event = event,
        args = {...},
    }
    
    table.insert(self.eventLog, entry)
    
    -- Trim log if too long
    while #self.eventLog > self.maxLogEntries do
        table.remove(self.eventLog, 1)
    end
end

--[[
    Enable/disable event logging
    @param enabled boolean: Enable logging
]]
function EventSimulator:SetLogging(enabled)
    self.loggingEnabled = enabled
    BFL:DebugPrint("|cff00ff00EventSimulator:|r Logging " .. (enabled and "enabled" or "disabled"))
end

--[[
    Get event log
    @param count number: Max entries to return (default: all)
    @return table: Log entries
]]
function EventSimulator:GetEventLog(count)
    if not count then
        return self.eventLog
    end
    
    local result = {}
    local start = math.max(1, #self.eventLog - count + 1)
    for i = start, #self.eventLog do
        table.insert(result, self.eventLog[i])
    end
    return result
end

--[[
    Clear event log
]]
function EventSimulator:ClearEventLog()
    wipe(self.eventLog)
end

--[[
    Print event log to chat
    @param count number: Number of entries to print
]]
function EventSimulator:PrintEventLog(count)
    count = count or 20
    local log = self:GetEventLog(count)
    
    print("|cff00ff00EventSimulator Log|r (last " .. #log .. " entries):")
    
    for i, entry in ipairs(log) do
        local argsStr = ""
        if entry.args and #entry.args > 0 then
            local argParts = {}
            for _, arg in ipairs(entry.args) do
                table.insert(argParts, tostring(arg))
            end
            argsStr = " [" .. table.concat(argParts, ", ") .. "]"
        end
        
        print(string.format("  %.2f: %s %s%s", 
            entry.timestamp, entry.action, entry.event, argsStr))
    end
end

-- ============================================
-- STATUS & DEBUG
-- ============================================

--[[
    Get current status
    @return table: Status info
]]
function EventSimulator:GetStatus()
    local activeCount = 0
    for _ in pairs(self.activeSequences) do
        activeCount = activeCount + 1
    end
    
    local mockedCount = 0
    for _ in pairs(self.mockedAPIs) do
        mockedCount = mockedCount + 1
    end
    
    return {
        activeSequences = activeCount,
        mockedAPIs = mockedCount,
        loggingEnabled = self.loggingEnabled,
        logEntries = #self.eventLog,
    }
end

--[[
    Print status to chat
]]
function EventSimulator:PrintStatus()
    local status = self:GetStatus()
    
    print("|cff00ff00BFL EventSimulator Status:|r")
    print("  |cffffffffActive Sequences:|r " .. status.activeSequences)
    print("  |cffffffffMocked APIs:|r " .. status.mockedAPIs)
    print("  |cffffffffLogging:|r " .. (status.loggingEnabled and "Enabled" or "Disabled"))
    print("  |cffffffffLog Entries:|r " .. status.logEntries)
    
    if status.mockedAPIs > 0 then
        print("  |cffffffffMocked:|r " .. table.concat(self:GetMockedAPIs(), ", "))
    end
end

--[[
    Reset all state (sequences, mocks, log)
]]
function EventSimulator:Reset()
    self:CancelAllSequences()
    self:RestoreAllAPIs()
    self:ClearEventLog()
    self.loggingEnabled = false
    BFL:DebugPrint("|cff00ff00EventSimulator:|r Reset complete")
end

return EventSimulator
