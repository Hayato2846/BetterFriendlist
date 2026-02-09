-- TestData/ScenarioManager.lua
-- Save/Load System for Test Scenarios
-- Version 1.0 - February 2026
--
-- Purpose:
-- Manages custom test scenarios that can be saved to SavedVariables
-- and loaded later for reproducible testing.
--
-- Features:
-- - Save current mock state as named scenario
-- - Load saved scenarios
-- - Export/Import scenarios as strings
-- - Built-in preset scenarios
--
-- Usage:
--   /bfl test scenario save <name>    - Save current state
--   /bfl test scenario load <name>    - Load a scenario
--   /bfl test scenario delete <name>  - Delete a scenario
--   /bfl test scenario export <name>  - Export to chat
--   /bfl test scenario import         - Import from clipboard

local ADDON_NAME, BFL = ...

-- Ensure TestData namespace exists
BFL.TestData = BFL.TestData or {}

-- Create ScenarioManager module
local ScenarioManager = {}
BFL.ScenarioManager = ScenarioManager

-- ============================================
-- CONSTANTS
-- ============================================

local SCENARIO_VERSION = 1  -- For future migrations
local MAX_SAVED_SCENARIOS = 20
local MAX_SCENARIO_NAME_LENGTH = 32

-- ============================================
-- STATE
-- ============================================

-- Current active scenario (if any)
ScenarioManager.activeScenario = nil
ScenarioManager.isModified = false

-- ============================================
-- SAVEDVARIABLES ACCESS
-- ============================================

--[[
    Get saved scenarios from database
    @return table: Saved scenarios table
]]
function ScenarioManager:GetSavedScenarios()
    if not BetterFriendlistDB then return {} end
    
    BetterFriendlistDB.testScenarios = BetterFriendlistDB.testScenarios or {}
    return BetterFriendlistDB.testScenarios
end

--[[
    Save a scenario to database
    @param name: string - Scenario name
    @param data: table - Scenario data
]]
function ScenarioManager:SaveToDatabase(name, data)
    if not BetterFriendlistDB then
        BFL:DebugPrint("|cffff0000ScenarioManager:|r Database not available")
        return false
    end
    
    BetterFriendlistDB.testScenarios = BetterFriendlistDB.testScenarios or {}
    
    -- Check max scenarios
    local count = 0
    for _ in pairs(BetterFriendlistDB.testScenarios) do
        count = count + 1
    end
    
    if count >= MAX_SAVED_SCENARIOS and not BetterFriendlistDB.testScenarios[name] then
        BFL:DebugPrint("|cffff0000ScenarioManager:|r Maximum scenarios reached (" .. MAX_SAVED_SCENARIOS .. ")")
        return false
    end
    
    -- Add metadata
    data.version = SCENARIO_VERSION
    data.savedAt = time()
    data.savedBy = UnitName("player") or "Unknown"
    
    BetterFriendlistDB.testScenarios[name] = data
    return true
end

--[[
    Delete a scenario from database
    @param name: string - Scenario name
]]
function ScenarioManager:DeleteFromDatabase(name)
    if not BetterFriendlistDB or not BetterFriendlistDB.testScenarios then
        return false
    end
    
    if BetterFriendlistDB.testScenarios[name] then
        BetterFriendlistDB.testScenarios[name] = nil
        return true
    end
    
    return false
end

-- ============================================
-- SCENARIO CAPTURE
-- ============================================

--[[
    Capture current mock data state as a scenario
    @param options table:
        - includeFriends (boolean): Include friend data (default: true)
        - includeGroups (boolean): Include group data (default: true)
        - includeAssignments (boolean): Include group assignments (default: true)
        - includeRaid (boolean): Include raid data (default: false)
        - includeQuickJoin (boolean): Include quickjoin data (default: false)
    @return table: Scenario data
]]
function ScenarioManager:CaptureCurrentState(options)
    options = options or {}
    
    local includeFriends = options.includeFriends ~= false
    local includeGroups = options.includeGroups ~= false
    local includeAssignments = options.includeAssignments ~= false
    local includeRaid = options.includeRaid or false
    local includeQuickJoin = options.includeQuickJoin or false
    
    local scenario = {
        type = "custom",
        capturedAt = time(),
    }
    
    -- Capture from MockDataProvider if available
    local MockDataProvider = BFL.MockDataProvider
    if MockDataProvider and MockDataProvider.currentData then
        if includeFriends and MockDataProvider.currentData.friends then
            scenario.friends = self:SerializeFriends(MockDataProvider.currentData.friends)
        end
        
        if includeGroups and MockDataProvider.currentData.groups then
            scenario.groups = self:SerializeGroups(MockDataProvider.currentData.groups)
        end
        
        if includeAssignments and MockDataProvider.currentData.groupAssignments then
            scenario.groupAssignments = CopyTable(MockDataProvider.currentData.groupAssignments)
        end
        
        if includeRaid and MockDataProvider.currentData.raid then
            scenario.raid = self:SerializeRaid(MockDataProvider.currentData.raid)
        end
        
        if includeQuickJoin and MockDataProvider.currentData.quickJoinGroups then
            scenario.quickJoin = CopyTable(MockDataProvider.currentData.quickJoinGroups)
        end
    else
        -- Capture from PreviewMode
        local PreviewMode = BFL:GetModule("PreviewMode")
        if PreviewMode and PreviewMode.mockData then
            if includeFriends and PreviewMode.mockData.friends then
                scenario.friends = self:SerializeFriends(PreviewMode.mockData.friends)
            end
            
            if includeGroups and PreviewMode.mockData.groups then
                scenario.groups = self:SerializeGroups(PreviewMode.mockData.groups)
            end
            
            if includeAssignments and PreviewMode.mockData.groupAssignments then
                scenario.groupAssignments = CopyTable(PreviewMode.mockData.groupAssignments)
            end
        end
    end
    
    return scenario
end

--[[
    Serialize friends for storage (remove runtime-only data)
    @param friends table: Array of friend data
    @return table: Serialized friends
]]
function ScenarioManager:SerializeFriends(friends)
    local serialized = {}
    
    for i, friend in ipairs(friends) do
        local entry = {
            type = friend.type,
            connected = friend.connected,
            isFavorite = friend.isFavorite,
            note = friend.note,
        }
        
        if friend.type == "bnet" then
            entry.battleTag = friend.battleTag
            entry.accountName = friend.accountName
            
            if friend.gameAccountInfo then
                entry.game = friend.gameAccountInfo.clientProgram
                entry.gameName = friend.gameAccountInfo.gameName
                entry.isDND = friend.gameAccountInfo.isDND
                entry.isAFK = friend.gameAccountInfo.isAFK
                
                if friend.gameAccountInfo.clientProgram == "WoW" then
                    entry.characterName = friend.gameAccountInfo.characterName
                    entry.className = friend.gameAccountInfo.className
                    entry.classID = friend.gameAccountInfo.classID
                    entry.level = friend.gameAccountInfo.characterLevel
                    entry.zone = friend.gameAccountInfo.areaName
                    entry.realm = friend.gameAccountInfo.realmName
                    entry.faction = friend.gameAccountInfo.factionName
                end
            end
        else -- wow friend
            entry.name = friend.name
            entry.className = friend.className
            entry.level = friend.level
            entry.zone = friend.area
            entry.notes = friend.notes
        end
        
        table.insert(serialized, entry)
    end
    
    return serialized
end

--[[
    Deserialize friends from storage
    @param serialized table: Serialized friends
    @return table: Full friend data array
]]
function ScenarioManager:DeserializeFriends(serialized)
    local MockDataProvider = BFL.MockDataProvider
    if not MockDataProvider then
        return serialized  -- Return as-is if provider not available
    end
    
    local friends = {}
    
    for i, entry in ipairs(serialized) do
        local friend
        
        if entry.type == "bnet" then
            friend = MockDataProvider:CreateBNetFriend({
                isOnline = entry.connected,
                isFavorite = entry.isFavorite,
                note = entry.note,
                battleTag = entry.battleTag,
                characterName = entry.characterName,
                level = entry.level,
                zone = entry.zone,
                status = entry.isDND and "dnd" or (entry.isAFK and "afk" or "available"),
                game = entry.game and {program = entry.game, name = entry.gameName} or nil,
            })
        else
            friend = MockDataProvider:CreateWoWFriend({
                isOnline = entry.connected,
                name = entry.name and entry.name:match("([^%-]+)") or nil,
                note = entry.notes,
                level = entry.level,
                zone = entry.zone,
            })
        end
        
        table.insert(friends, friend)
    end
    
    return friends
end

--[[
    Serialize groups for storage
    @param groups table: Array of group data
    @return table: Serialized groups
]]
function ScenarioManager:SerializeGroups(groups)
    local serialized = {}
    
    for i, group in ipairs(groups) do
        table.insert(serialized, {
            id = group.id,
            name = group.name,
            collapsed = group.collapsed,
            builtin = group.builtin,
            order = group.order,
            color = group.color,
            icon = group.icon,
        })
    end
    
    return serialized
end

--[[
    Serialize raid members for storage
    @param raid table: Array of raid member data
    @return table: Serialized raid
]]
function ScenarioManager:SerializeRaid(raid)
    local serialized = {}
    
    for i, member in ipairs(raid) do
        table.insert(serialized, {
            name = member.name,
            rank = member.rank,
            subgroup = member.subgroup,
            level = member.level,
            class = member.class,
            fileName = member.fileName,
            online = member.online,
            isDead = member.isDead,
            role = member.role,
            combatRole = member.combatRole,
        })
    end
    
    return serialized
end

-- ============================================
-- SCENARIO LOADING
-- ============================================

--[[
    Load a scenario by name
    @param name string: Scenario name (preset or saved)
    @return boolean: Success
]]
function ScenarioManager:Load(name)
    -- Check MockDataProvider presets first
    local MockDataProvider = BFL.MockDataProvider
    if MockDataProvider and MockDataProvider.Presets and MockDataProvider.Presets[name] then
        local data = MockDataProvider:LoadPreset(name)
        if data then
            self.activeScenario = name
            self.isModified = false
            self:ApplyScenarioData(data)
            return true
        end
    end
    
    -- Check saved scenarios
    local saved = self:GetSavedScenarios()
    if saved[name] then
        local scenario = saved[name]
        
        -- Deserialize friends if needed
        local data = {
            friends = scenario.friends and self:DeserializeFriends(scenario.friends) or {},
            groups = scenario.groups or {},
            groupAssignments = scenario.groupAssignments or {},
            raid = scenario.raid or nil,
            quickJoinGroups = scenario.quickJoin or {},
        }
        
        self.activeScenario = name
        self.isModified = false
        self:ApplyScenarioData(data)
        return true
    end
    
    BFL:DebugPrint("|cffff0000ScenarioManager:|r Scenario not found: " .. name)
    return false
end

--[[
    Apply scenario data to mock systems
    @param data table: Scenario data (friends, groups, etc.)
]]
function ScenarioManager:ApplyScenarioData(data)
    local TestSuite = BFL:GetModule("TestSuite")
    if TestSuite and TestSuite.ApplyMockData then
        TestSuite:ApplyMockData(data)
    else
        -- Direct application fallback
        local PreviewMode = BFL:GetModule("PreviewMode")
        if PreviewMode then
            if not PreviewMode.enabled then
                PreviewMode:Enable()
            end
            
            if data.friends then
                PreviewMode.mockData.friends = data.friends
            end
            if data.groups then
                PreviewMode.mockData.groups = data.groups
            end
            if data.groupAssignments then
                PreviewMode.mockData.groupAssignments = data.groupAssignments
            end
            
            PreviewMode:ApplyMockFriends()
            PreviewMode:RefreshAllUI()
        end
    end
    
    -- Store in MockDataProvider
    local MockDataProvider = BFL.MockDataProvider
    if MockDataProvider then
        MockDataProvider.currentData = data
    end
end

--[[
    Save current state as a named scenario
    @param name string: Scenario name
    @param options table: Capture options
    @return boolean: Success
]]
function ScenarioManager:Save(name, options)
    -- Validate name
    if not name or name == "" then
        BFL:DebugPrint("|cffff0000ScenarioManager:|r Name required")
        return false
    end
    
    if #name > MAX_SCENARIO_NAME_LENGTH then
        BFL:DebugPrint("|cffff0000ScenarioManager:|r Name too long (max " .. MAX_SCENARIO_NAME_LENGTH .. ")")
        return false
    end
    
    -- Don't allow overwriting presets
    local MockDataProvider = BFL.MockDataProvider
    if MockDataProvider and MockDataProvider.Presets and MockDataProvider.Presets[name] then
        BFL:DebugPrint("|cffff0000ScenarioManager:|r Cannot overwrite preset: " .. name)
        return false
    end
    
    -- Capture current state
    local scenario = self:CaptureCurrentState(options or {
        includeFriends = true,
        includeGroups = true,
        includeAssignments = true,
        includeRaid = true,
        includeQuickJoin = true,
    })
    
    -- Validate we have data
    local hasData = (scenario.friends and #scenario.friends > 0) or
                    (scenario.groups and #scenario.groups > 0)
    
    if not hasData then
        BFL:DebugPrint("|cffff0000ScenarioManager:|r No mock data to save")
        return false
    end
    
    -- Save to database
    scenario.name = name
    if self:SaveToDatabase(name, scenario) then
        self.activeScenario = name
        self.isModified = false
        BFL:DebugPrint("|cff00ff00ScenarioManager:|r Saved scenario: " .. name)
        return true
    end
    
    return false
end

--[[
    Delete a saved scenario
    @param name string: Scenario name
    @return boolean: Success
]]
function ScenarioManager:Delete(name)
    -- Don't allow deleting presets
    local MockDataProvider = BFL.MockDataProvider
    if MockDataProvider and MockDataProvider.Presets and MockDataProvider.Presets[name] then
        BFL:DebugPrint("|cffff0000ScenarioManager:|r Cannot delete preset: " .. name)
        return false
    end
    
    if self:DeleteFromDatabase(name) then
        if self.activeScenario == name then
            self.activeScenario = nil
        end
        BFL:DebugPrint("|cff00ff00ScenarioManager:|r Deleted scenario: " .. name)
        return true
    end
    
    BFL:DebugPrint("|cffff0000ScenarioManager:|r Scenario not found: " .. name)
    return false
end

-- ============================================
-- LISTING
-- ============================================

--[[
    List all available scenarios (presets + saved)
    @return table: Array of {name, type, description, savedAt}
]]
function ScenarioManager:ListAll()
    local list = {}
    
    -- Add presets
    local MockDataProvider = BFL.MockDataProvider
    if MockDataProvider and MockDataProvider.Presets then
        for name, preset in pairs(MockDataProvider.Presets) do
            table.insert(list, {
                name = name,
                type = "preset",
                description = preset.description or preset.name,
                friendCount = preset.friends and 
                    ((preset.friends.bnet and preset.friends.bnet.count or 0) +
                     (preset.friends.wow and preset.friends.wow.count or 0)) or 0,
            })
        end
    end
    
    -- Add saved scenarios
    local saved = self:GetSavedScenarios()
    for name, scenario in pairs(saved) do
        table.insert(list, {
            name = name,
            type = "saved",
            description = scenario.description or "Custom scenario",
            savedAt = scenario.savedAt,
            savedBy = scenario.savedBy,
            friendCount = scenario.friends and #scenario.friends or 0,
        })
    end
    
    -- Sort: presets first, then saved by name
    table.sort(list, function(a, b)
        if a.type ~= b.type then
            return a.type == "preset"
        end
        return a.name < b.name
    end)
    
    return list
end

--[[
    Get info about a specific scenario
    @param name string: Scenario name
    @return table or nil: Scenario info
]]
function ScenarioManager:GetInfo(name)
    -- Check presets
    local MockDataProvider = BFL.MockDataProvider
    if MockDataProvider and MockDataProvider.Presets and MockDataProvider.Presets[name] then
        local preset = MockDataProvider.Presets[name]
        return {
            name = name,
            type = "preset",
            description = preset.description or preset.name,
            friends = preset.friends,
            groups = preset.groups,
            raid = preset.raid,
            quickJoin = preset.quickJoin,
        }
    end
    
    -- Check saved
    local saved = self:GetSavedScenarios()
    if saved[name] then
        local scenario = saved[name]
        return {
            name = name,
            type = "saved",
            description = scenario.description,
            savedAt = scenario.savedAt,
            savedBy = scenario.savedBy,
            friendCount = scenario.friends and #scenario.friends or 0,
            groupCount = scenario.groups and #scenario.groups or 0,
            hasRaid = scenario.raid ~= nil,
            hasQuickJoin = scenario.quickJoin ~= nil,
        }
    end
    
    return nil
end

-- ============================================
-- EXPORT / IMPORT
-- ============================================

--[[
    Export a scenario as a string (for sharing)
    @param name string: Scenario name
    @return string or nil: Encoded scenario string
]]
function ScenarioManager:Export(name)
    local info = self:GetInfo(name)
    if not info then
        return nil
    end
    
    local scenario
    if info.type == "preset" then
        -- Export preset definition
        local MockDataProvider = BFL.MockDataProvider
        scenario = MockDataProvider.Presets[name]
    else
        -- Export saved scenario
        local saved = self:GetSavedScenarios()
        scenario = saved[name]
    end
    
    if not scenario then
        return nil
    end
    
    -- Serialize to string
    local serialized = self:SerializeToString(scenario)
    
    -- Add header
    local exportString = "BFL_SCENARIO_V" .. SCENARIO_VERSION .. ":" .. serialized
    
    return exportString
end

--[[
    Import a scenario from string
    @param importString string: Encoded scenario
    @param saveName string: Name to save as
    @return boolean: Success
]]
function ScenarioManager:Import(importString, saveName)
    if not importString or importString == "" then
        BFL:DebugPrint("|cffff0000ScenarioManager:|r Empty import string")
        return false
    end
    
    -- Parse header
    local version, data = importString:match("^BFL_SCENARIO_V(%d+):(.+)$")
    if not version or not data then
        BFL:DebugPrint("|cffff0000ScenarioManager:|r Invalid import format")
        return false
    end
    
    version = tonumber(version)
    if version > SCENARIO_VERSION then
        BFL:DebugPrint("|cffff0000ScenarioManager:|r Scenario version too new (v" .. version .. ")")
        return false
    end
    
    -- Deserialize
    local scenario = self:DeserializeFromString(data)
    if not scenario then
        BFL:DebugPrint("|cffff0000ScenarioManager:|r Failed to parse scenario data")
        return false
    end
    
    -- Save with new name
    scenario.name = saveName
    scenario.importedAt = time()
    
    if self:SaveToDatabase(saveName, scenario) then
        BFL:DebugPrint("|cff00ff00ScenarioManager:|r Imported scenario as: " .. saveName)
        return true
    end
    
    return false
end

--[[
    Serialize scenario to string (simple implementation)
    @param scenario table: Scenario data
    @return string: Serialized string
]]
function ScenarioManager:SerializeToString(scenario)
    -- Use a simple serialization format
    -- In production, you might use LibSerialize or LibDeflate
    
    local function serializeValue(val, depth)
        depth = depth or 0
        if depth > 10 then return "nil" end  -- Prevent infinite recursion
        
        local t = type(val)
        if t == "nil" then
            return "nil"
        elseif t == "boolean" then
            return val and "true" or "false"
        elseif t == "number" then
            return tostring(val)
        elseif t == "string" then
            return string.format("%q", val)
        elseif t == "table" then
            local parts = {}
            for k, v in pairs(val) do
                local keyStr
                if type(k) == "number" then
                    keyStr = "[" .. k .. "]"
                else
                    keyStr = "[" .. string.format("%q", tostring(k)) .. "]"
                end
                table.insert(parts, keyStr .. "=" .. serializeValue(v, depth + 1))
            end
            return "{" .. table.concat(parts, ",") .. "}"
        else
            return "nil"
        end
    end
    
    local serialized = serializeValue(scenario)
    
    -- Base64-like encoding (simple version using hex)
    local encoded = ""
    for i = 1, #serialized do
        encoded = encoded .. string.format("%02x", string.byte(serialized, i))
    end
    
    return encoded
end

--[[
    Deserialize scenario from string
    @param data string: Serialized data
    @return table or nil: Scenario data
]]
function ScenarioManager:DeserializeFromString(data)
    -- Decode from hex
    local decoded = ""
    for i = 1, #data, 2 do
        local hex = data:sub(i, i+1)
        local byte = tonumber(hex, 16)
        if byte then
            decoded = decoded .. string.char(byte)
        end
    end
    
    if decoded == "" then
        return nil
    end
    
    -- Parse Lua table string (safely)
    local func, err = loadstring("return " .. decoded)
    if not func then
        BFL:DebugPrint("|cffff0000ScenarioManager:|r Parse error: " .. tostring(err))
        return nil
    end
    
    -- Execute in sandbox (limited environment)
    setfenv(func, {})
    
    local ok, result = pcall(func)
    if not ok then
        BFL:DebugPrint("|cffff0000ScenarioManager:|r Execution error: " .. tostring(result))
        return nil
    end
    
    return result
end

-- ============================================
-- UTILITY
-- ============================================

--[[
    Clear the active scenario (return to real data)
]]
function ScenarioManager:Clear()
    local PreviewMode = BFL:GetModule("PreviewMode")
    if PreviewMode and PreviewMode.enabled then
        PreviewMode:Disable()
    end
    
    local MockDataProvider = BFL.MockDataProvider
    if MockDataProvider then
        MockDataProvider:Reset()
    end
    
    self.activeScenario = nil
    self.isModified = false
end

--[[
    Get current status
    @return table: Status info
]]
function ScenarioManager:GetStatus()
    local PreviewMode = BFL:GetModule("PreviewMode")
    local MockDataProvider = BFL.MockDataProvider
    
    return {
        activeScenario = self.activeScenario,
        isModified = self.isModified,
        mockActive = PreviewMode and PreviewMode.enabled or false,
        friendCount = MockDataProvider and MockDataProvider.currentData and 
                      #MockDataProvider.currentData.friends or 0,
        savedCount = self:GetSavedScenarioCount(),
    }
end

--[[
    Get count of saved scenarios
    @return number: Count
]]
function ScenarioManager:GetSavedScenarioCount()
    local count = 0
    local saved = self:GetSavedScenarios()
    for _ in pairs(saved) do
        count = count + 1
    end
    return count
end

-- ============================================
-- DEBUG
-- ============================================

function ScenarioManager:PrintStatus()
    local status = self:GetStatus()
    
    print("|cff00ff00BFL ScenarioManager Status:|r")
    print("  |cffffffffActive Scenario:|r " .. (status.activeScenario or "None"))
    print("  |cffffffffModified:|r " .. (status.isModified and "Yes" or "No"))
    print("  |cffffffffMock Active:|r " .. (status.mockActive and "Yes" or "No"))
    print("  |cffffffffCurrent Friends:|r " .. status.friendCount)
    print("  |cffffffffSaved Scenarios:|r " .. status.savedCount .. "/" .. MAX_SAVED_SCENARIOS)
end

return ScenarioManager
