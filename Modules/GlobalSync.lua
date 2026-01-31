local _, BFL = ...
local GlobalSync = {}
BFL.GlobalSync = GlobalSync

-- Constants
local MODULE_NAME = "GlobalSync"
local BATCH_SIZE = 5 -- Number of friends to add per tick to avoid throttling

-- State
local isInitialized = false
local syncTimer = nil
local pendingAdds = {}
local processingQueue = false

-- Helper: Check if Beta is enabled
local function IsBetaEnabled()
    return BetterFriendlistDB and BetterFriendlistDB.enableBetaFeatures == true
end

-- Helper: Get Normalized Realm Name
local function GetRealmName()
    return GetNormalizedRealmName()
end

-- Helper: Get Faction
local function GetFaction()
    local faction = UnitFactionGroup("player")
    return faction
end

function GlobalSync:Initialize()
    if not IsBetaEnabled() then return end
    
    -- Initialize DB structure if missing
    if not BetterFriendlistDB.GlobalFriends then
        BetterFriendlistDB.GlobalFriends = {
            Alliance = {},
            Horde = {}
        }
    end

    -- Perform Migration to Flat Structure
    self:MigrateGlobalFriends()

    -- Hook Deletion APIs
    self:HookDeletionAPIs()

    self:RegisterEvents()
    
    -- Request friend list update from server to ensure we have data
    if C_FriendList.ShowFriends then
        C_FriendList.ShowFriends()
    end

    -- BFL:DebugPrint("GlobalSync Module Initialized")
end

function GlobalSync:MigrateGlobalFriends()
    if BetterFriendlistDB.globalFriendsMigrated then return end
    
    -- BFL:DebugPrint("GlobalSync: Starting migration to flat structure...")
    
    local newStructure = {
        Alliance = {},
        Horde = {}
    }
    
    local count = 0
    
    -- Iterate old structure: [Faction][StorageKey][Name]
    for faction, storageKeys in pairs(BetterFriendlistDB.GlobalFriends) do
        if newStructure[faction] then
            for storageKey, friends in pairs(storageKeys) do
                -- Extract Realm from StorageKey (Format: "Realm - CharacterName" or legacy "Realm")
                local realm = string.match(storageKey, "^(.+) %- .+$") or storageKey
                
                for name, data in pairs(friends) do
                    -- Construct FriendUID: Name-Realm
                    local friendUID
                    if string.find(name, "-") then
                        friendUID = name -- Already has realm
                    else
                        friendUID = name .. "-" .. realm
                    end
                    
                    -- Store in new structure (overwrite duplicates, last one wins)
                    newStructure[faction][friendUID] = {
                        notes = data.notes,
                        guid = data.guid,
                        lastSeen = data.lastSeen or time() -- Preserve or add timestamp
                    }
                    count = count + 1
                end
            end
        end
    end
    
    -- Replace old DB with new structure
    BetterFriendlistDB.GlobalFriends = newStructure
    BetterFriendlistDB.globalFriendsMigrated = true
    
    -- BFL:DebugPrint("GlobalSync: Migration complete. Migrated " .. count .. " friends.")
end

function GlobalSync:HookDeletionAPIs()
    if self.hooksInstalled then return end
    self.hooksInstalled = true
    
    -- Hook C_FriendList.RemoveFriend (Secure Hook is fine as we just need to know it happened)
    -- This handles /removefriend command and some UI actions
    hooksecurefunc(C_FriendList, "RemoveFriend", function(name)
        self:OnFriendRemoved(name)
    end)
    
    -- Hook C_FriendList.RemoveFriendByIndex (Must replace to get name before removal)
    -- This handles the right-click menu removal
    local originalRemoveByIndex = C_FriendList.RemoveFriendByIndex
    C_FriendList.RemoveFriendByIndex = function(index)
        -- Get info before removal
        local info = C_FriendList.GetFriendInfoByIndex(index)
        local nameToRemove = info and info.name
        
        -- Call original function
        local result = originalRemoveByIndex(index)
        
        -- Process removal if successful
        if nameToRemove then
            self:OnFriendRemoved(nameToRemove)
        end
        
        return result
    end
    
    -- Hook C_FriendList.AddFriend to clear deleted flag if re-added
    hooksecurefunc(C_FriendList, "AddFriend", function(name)
        self:OnFriendAdded(name)
    end)
    
    -- Hook C_FriendList.SetFriendNotes to update DB immediately
    hooksecurefunc(C_FriendList, "SetFriendNotes", function(name, notes)
        self:OnFriendNoteUpdated(name, notes)
    end)
    
    -- BFL:DebugPrint("GlobalSync: Deletion APIs hooked.")
end

function GlobalSync:OnFriendNoteUpdated(name, notes)
    if not IsBetaEnabled() then return end
    if not name then return end
    
    local faction = GetFaction()
    local realm = GetRealmName()
    
    if not faction or not realm then return end
    
    -- Construct FriendUID
    local friendUID
    if string.find(name, "-") then
        friendUID = name
    else
        friendUID = name .. "-" .. realm
    end
    
    -- Update DB if entry exists
    if BetterFriendlistDB.GlobalFriends[faction] and BetterFriendlistDB.GlobalFriends[faction][friendUID] then
        BetterFriendlistDB.GlobalFriends[faction][friendUID].notes = notes
        -- BFL:DebugPrint("GlobalSync: Updated DB note for " .. friendUID .. " (Hooked SetFriendNotes).")
    end
end

function GlobalSync:OnFriendAdded(name)
    if not IsBetaEnabled() then return end
    if not name then return end
    
    local faction = GetFaction()
    local realm = GetRealmName()
    
    if not faction or not realm then return end
    
    -- Construct FriendUID
    local friendUID
    if string.find(name, "-") then
        friendUID = name
    else
        friendUID = name .. "-" .. realm
    end
    
    -- If marked as deleted in DB, clear the flag
    if BetterFriendlistDB.GlobalFriends[faction] and BetterFriendlistDB.GlobalFriends[faction][friendUID] then
        if BetterFriendlistDB.GlobalFriends[faction][friendUID].deleted then
            BetterFriendlistDB.GlobalFriends[faction][friendUID].deleted = nil
            -- BFL:DebugPrint("GlobalSync: Cleared deleted flag for " .. friendUID .. " (Re-added manually).")
        end
    end
end

function GlobalSync:OnFriendRemoved(name)
    if not IsBetaEnabled() then return end
    if not BetterFriendlistDB.enableGlobalSyncDeletion then return end
    if not name then return end
    
    local faction = GetFaction()
    local realm = GetRealmName()
    
    if not faction or not realm then return end
    
    -- Construct FriendUID to find in DB
    local friendUID
    if string.find(name, "-") then
        friendUID = name
    else
        friendUID = name .. "-" .. realm
    end
    
    -- Check if exists in DB
    if BetterFriendlistDB.GlobalFriends[faction] and BetterFriendlistDB.GlobalFriends[faction][friendUID] then
        -- Mark as deleted instead of removing
        BetterFriendlistDB.GlobalFriends[faction][friendUID].deleted = true
        BetterFriendlistDB.GlobalFriends[faction][friendUID].deletedTime = time()
        -- BFL:DebugPrint("GlobalSync: Marked " .. friendUID .. " as DELETED in Global DB.")
        
        -- Refresh Settings UI if open
        local Settings = BFL:GetModule("Settings")
        if Settings and Settings.RefreshGlobalSyncTab then
            Settings:RefreshGlobalSyncTab()
        end
    end
end

function GlobalSync:RegisterEvents()
    if not IsBetaEnabled() then return end

    BFL:RegisterEventCallback("FRIENDLIST_UPDATE", function()
        self:OnFriendListUpdate()
    end)
end

function GlobalSync:OnFriendListUpdate()
    if not IsBetaEnabled() then return end
    
    -- Throttle updates
    if self.updateTimer then return end
    self.updateTimer = C_Timer.NewTimer(2, function()
        self:PerformSync()
        self.updateTimer = nil
    end)
end

function GlobalSync:PerformSync()
    local faction = GetFaction()
    local realm = GetRealmName()
    
    if not faction or not realm then return end
    
    -- 1. Export current friends to DB
    self:ExportFriends(faction, realm)
    
    -- 2. Import friends from connected realms
    self:ImportFriends(faction, realm)
    
    -- 3. Sync Deletions (Remove friends marked as deleted)
    self:SyncDeletions(faction, realm)
end

function GlobalSync:ExportFriends(faction, realm)
    local numFriends = C_FriendList.GetNumFriends() or 0

    
    -- Ensure faction table exists
    if not BetterFriendlistDB.GlobalFriends[faction] then
        BetterFriendlistDB.GlobalFriends[faction] = {}
    end
    
    local count = 0
    for i = 1, numFriends do
        local info = C_FriendList.GetFriendInfoByIndex(i)
        if info and info.name then
            -- Construct FriendUID
            local friendUID
            if string.find(info.name, "-") then
                friendUID = info.name
            else
                friendUID = info.name .. "-" .. realm
            end
            
            -- Check if marked as deleted
            local dbEntry = BetterFriendlistDB.GlobalFriends[faction][friendUID]
            local isDeleted = dbEntry and dbEntry.deleted
            local isRestoring = dbEntry and dbEntry.restoring
            
            local noteToSave = info.notes or ""
            local dbNote = dbEntry and dbEntry.notes
            
            -- SYNC NOTE LOGIC:
            -- 1. Restore: If restoring, force DB note.
            -- 2. DB Priority: If DB has a note, it overrides local note (DB is source of truth).
            -- 3. Local Priority: If DB has NO note, local note is saved to DB.
            
            if isRestoring then
                if dbNote and dbNote ~= "" then
                    C_FriendList.SetFriendNotes(info.name, dbNote)
                    noteToSave = dbNote
                    -- BFL:DebugPrint("GlobalSync: Restored note for " .. info.name)
                end
                BetterFriendlistDB.GlobalFriends[faction][friendUID].restoring = nil
            elseif dbNote and dbNote ~= "" then
                -- DB has a note. Check if we need to enforce it.
                if noteToSave ~= dbNote then
                    C_FriendList.SetFriendNotes(info.name, dbNote)
                    noteToSave = dbNote
                    -- BFL:DebugPrint("GlobalSync: Enforced DB note for " .. info.name)
                end
            end
            
            -- Only update if NOT marked as deleted (unless we want to force un-delete, but AddFriend hook handles that)
            if not isDeleted then
                -- Update DB entry
                BetterFriendlistDB.GlobalFriends[faction][friendUID] = {
                    notes = noteToSave,
                    guid = info.guid,
                    lastSeen = time()
                }
                count = count + 1
            end
        end
    end
    
    -- BFL:DebugPrint("GlobalSync: Exported " .. count .. " friends to flat DB.")
end

function GlobalSync:ImportFriends(faction, currentRealm)
    -- Check if sync is enabled in settings (default false)
    if not BetterFriendlistDB.enableGlobalSync then return end

    -- Ensure faction table exists
    if not BetterFriendlistDB.GlobalFriends[faction] then return end

    local friendsToAdd = {}
    local currentFriendList = {}
    
    -- Cache current friends for quick lookup
    local numFriends = C_FriendList.GetNumFriends() or 0
    for i = 1, numFriends do
        local info = C_FriendList.GetFriendInfoByIndex(i)
        if info and info.name then
            -- Store as Name-Realm for comparison
            local uid
            if string.find(info.name, "-") then
                uid = info.name
            else
                uid = info.name .. "-" .. currentRealm
            end
            currentFriendList[uid] = true
        end
    end

    -- Iterate FLAT structure: [Faction][FriendUID]
    for friendUID, data in pairs(BetterFriendlistDB.GlobalFriends[faction]) do
        -- Skip if marked as deleted
        if not data.deleted then
            -- Check if we already have this friend
            if not currentFriendList[friendUID] then
                -- Parse UID to get Name and Realm
                local name, realm = string.match(friendUID, "^(.+)%-(.+)$")
                
                if name and realm then
                    local nameToAdd = friendUID -- Default to full Name-Realm
                    
                    -- If on same realm, we can try adding just the name, but Name-Realm is safer
                    -- Blizzard API handles Name-Realm correctly even for same realm
                    
                    table.insert(friendsToAdd, nameToAdd)
                end
            end
        end
    end

    -- Process queue
    if #friendsToAdd > 0 then
        -- BFL:DebugPrint("GlobalSync: Found " .. #friendsToAdd .. " missing friends.")
        self:ProcessAddQueue(friendsToAdd)
    end
end

function GlobalSync:SyncDeletions(faction, currentRealm)
    -- Check if deletion sync is enabled
    if not BetterFriendlistDB.enableGlobalSyncDeletion then return end
    if not BetterFriendlistDB.GlobalFriends[faction] then return end
    
    local friendsToRemove = {}
    
    -- Iterate current friends
    local numFriends = C_FriendList.GetNumFriends() or 0
    for i = 1, numFriends do
        local info = C_FriendList.GetFriendInfoByIndex(i)
        if info and info.name then
            -- Construct UID
            local friendUID
            if string.find(info.name, "-") then
                friendUID = info.name
            else
                friendUID = info.name .. "-" .. currentRealm
            end
            
            -- Check if marked as deleted in DB
            local dbEntry = BetterFriendlistDB.GlobalFriends[faction][friendUID]
            if dbEntry and dbEntry.deleted then
                table.insert(friendsToRemove, info.name)
            end
        end
    end
    
    -- Process removals
    if #friendsToRemove > 0 then
        -- BFL:DebugPrint("GlobalSync: Found " .. #friendsToRemove .. " friends marked for deletion.")
        for _, name in ipairs(friendsToRemove) do
            -- BFL:DebugPrint("GlobalSync: Removing " .. name .. " (Synced Deletion)")
            C_FriendList.RemoveFriend(name)
        end
    end
end

function GlobalSync:ProcessAddQueue(queue)
    if self.processingQueue then return end
    self.processingQueue = true
    
    local index = 1
    local max = #queue
    
    C_Timer.NewTicker(0.5, function(timer)
        if not IsBetaEnabled() or not BetterFriendlistDB.enableGlobalSync then
            timer:Cancel()
            self.processingQueue = false
            return
        end

        for i = 1, BATCH_SIZE do
            if index > max then
                timer:Cancel()
                self.processingQueue = false
                -- BFL:DebugPrint("GlobalSync: Finished syncing friends.")
                return
            end
            
            local name = queue[index]
            -- BFL:DebugPrint("GlobalSync: Adding friend " .. name)
            C_FriendList.AddFriend(name)
            
            index = index + 1
        end
    end)
end

-- Register module
BFL.Modules[MODULE_NAME] = GlobalSync
