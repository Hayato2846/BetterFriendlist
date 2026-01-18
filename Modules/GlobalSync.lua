--[[Perfy has instrumented this file]] local Perfy_GetTime, Perfy_Trace, Perfy_Trace_Passthrough = Perfy_GetTime, Perfy_Trace, Perfy_Trace_Passthrough; Perfy_Trace(Perfy_GetTime(), "Enter", "(main chunk) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GlobalSync.lua"); local _, BFL = ...
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
local function IsBetaEnabled() Perfy_Trace(Perfy_GetTime(), "Enter", "IsBetaEnabled file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GlobalSync.lua:16:6");
    return Perfy_Trace_Passthrough("Leave", "IsBetaEnabled file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GlobalSync.lua:16:6", BetterFriendlistDB and BetterFriendlistDB.enableBetaFeatures == true)
end

-- Helper: Get Normalized Realm Name
local function GetRealmName() Perfy_Trace(Perfy_GetTime(), "Enter", "GetRealmName file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GlobalSync.lua:21:6");
    return Perfy_Trace_Passthrough("Leave", "GetRealmName file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GlobalSync.lua:21:6", GetNormalizedRealmName())
end

-- Helper: Get Faction
local function GetFaction() Perfy_Trace(Perfy_GetTime(), "Enter", "GetFaction file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GlobalSync.lua:26:6");
    local faction = UnitFactionGroup("player")
    Perfy_Trace(Perfy_GetTime(), "Leave", "GetFaction file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GlobalSync.lua:26:6"); return faction
end

function GlobalSync:Initialize() Perfy_Trace(Perfy_GetTime(), "Enter", "GlobalSync:Initialize file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GlobalSync.lua:31:0");
    if not IsBetaEnabled() then Perfy_Trace(Perfy_GetTime(), "Leave", "GlobalSync:Initialize file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GlobalSync.lua:31:0"); return end
    
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
Perfy_Trace(Perfy_GetTime(), "Leave", "GlobalSync:Initialize file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GlobalSync.lua:31:0"); end

function GlobalSync:MigrateGlobalFriends() Perfy_Trace(Perfy_GetTime(), "Enter", "GlobalSync:MigrateGlobalFriends file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GlobalSync.lua:58:0");
    if BetterFriendlistDB.globalFriendsMigrated then Perfy_Trace(Perfy_GetTime(), "Leave", "GlobalSync:MigrateGlobalFriends file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GlobalSync.lua:58:0"); return end
    
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
Perfy_Trace(Perfy_GetTime(), "Leave", "GlobalSync:MigrateGlobalFriends file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GlobalSync.lua:58:0"); end

function GlobalSync:HookDeletionAPIs() Perfy_Trace(Perfy_GetTime(), "Enter", "GlobalSync:HookDeletionAPIs file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GlobalSync.lua:105:0");
    if self.hooksInstalled then Perfy_Trace(Perfy_GetTime(), "Leave", "GlobalSync:HookDeletionAPIs file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GlobalSync.lua:105:0"); return end
    self.hooksInstalled = true
    
    -- Hook C_FriendList.RemoveFriend (Secure Hook is fine as we just need to know it happened)
    -- This handles /removefriend command and some UI actions
    hooksecurefunc(C_FriendList, "RemoveFriend", function(name) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GlobalSync.lua:111:49");
        self:OnFriendRemoved(name)
    Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GlobalSync.lua:111:49"); end)
    
    -- Hook C_FriendList.RemoveFriendByIndex (Must replace to get name before removal)
    -- This handles the right-click menu removal
    local originalRemoveByIndex = C_FriendList.RemoveFriendByIndex
    C_FriendList.RemoveFriendByIndex = function(index) Perfy_Trace(Perfy_GetTime(), "Enter", "C_FriendList.RemoveFriendByIndex file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GlobalSync.lua:118:39");
        -- Get info before removal
        local info = C_FriendList.GetFriendInfoByIndex(index)
        local nameToRemove = info and info.name
        
        -- Call original function
        local result = originalRemoveByIndex(index)
        
        -- Process removal if successful
        if nameToRemove then
            self:OnFriendRemoved(nameToRemove)
        end
        
        Perfy_Trace(Perfy_GetTime(), "Leave", "C_FriendList.RemoveFriendByIndex file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GlobalSync.lua:118:39"); return result
    end
    
    -- Hook C_FriendList.AddFriend to clear deleted flag if re-added
    hooksecurefunc(C_FriendList, "AddFriend", function(name) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GlobalSync.lua:135:46");
        self:OnFriendAdded(name)
    Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GlobalSync.lua:135:46"); end)
    
    -- Hook C_FriendList.SetFriendNotes to update DB immediately
    hooksecurefunc(C_FriendList, "SetFriendNotes", function(name, notes) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GlobalSync.lua:140:51");
        self:OnFriendNoteUpdated(name, notes)
    Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GlobalSync.lua:140:51"); end)
    
    -- BFL:DebugPrint("GlobalSync: Deletion APIs hooked.")
Perfy_Trace(Perfy_GetTime(), "Leave", "GlobalSync:HookDeletionAPIs file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GlobalSync.lua:105:0"); end

function GlobalSync:OnFriendNoteUpdated(name, notes) Perfy_Trace(Perfy_GetTime(), "Enter", "GlobalSync:OnFriendNoteUpdated file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GlobalSync.lua:147:0");
    if not IsBetaEnabled() then Perfy_Trace(Perfy_GetTime(), "Leave", "GlobalSync:OnFriendNoteUpdated file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GlobalSync.lua:147:0"); return end
    if not name then Perfy_Trace(Perfy_GetTime(), "Leave", "GlobalSync:OnFriendNoteUpdated file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GlobalSync.lua:147:0"); return end
    
    local faction = GetFaction()
    local realm = GetRealmName()
    
    if not faction or not realm then Perfy_Trace(Perfy_GetTime(), "Leave", "GlobalSync:OnFriendNoteUpdated file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GlobalSync.lua:147:0"); return end
    
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
Perfy_Trace(Perfy_GetTime(), "Leave", "GlobalSync:OnFriendNoteUpdated file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GlobalSync.lua:147:0"); end

function GlobalSync:OnFriendAdded(name) Perfy_Trace(Perfy_GetTime(), "Enter", "GlobalSync:OnFriendAdded file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GlobalSync.lua:171:0");
    if not IsBetaEnabled() then Perfy_Trace(Perfy_GetTime(), "Leave", "GlobalSync:OnFriendAdded file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GlobalSync.lua:171:0"); return end
    if not name then Perfy_Trace(Perfy_GetTime(), "Leave", "GlobalSync:OnFriendAdded file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GlobalSync.lua:171:0"); return end
    
    local faction = GetFaction()
    local realm = GetRealmName()
    
    if not faction or not realm then Perfy_Trace(Perfy_GetTime(), "Leave", "GlobalSync:OnFriendAdded file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GlobalSync.lua:171:0"); return end
    
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
Perfy_Trace(Perfy_GetTime(), "Leave", "GlobalSync:OnFriendAdded file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GlobalSync.lua:171:0"); end

function GlobalSync:OnFriendRemoved(name) Perfy_Trace(Perfy_GetTime(), "Enter", "GlobalSync:OnFriendRemoved file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GlobalSync.lua:197:0");
    if not IsBetaEnabled() then Perfy_Trace(Perfy_GetTime(), "Leave", "GlobalSync:OnFriendRemoved file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GlobalSync.lua:197:0"); return end
    if not BetterFriendlistDB.enableGlobalSyncDeletion then Perfy_Trace(Perfy_GetTime(), "Leave", "GlobalSync:OnFriendRemoved file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GlobalSync.lua:197:0"); return end
    if not name then Perfy_Trace(Perfy_GetTime(), "Leave", "GlobalSync:OnFriendRemoved file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GlobalSync.lua:197:0"); return end
    
    local faction = GetFaction()
    local realm = GetRealmName()
    
    if not faction or not realm then Perfy_Trace(Perfy_GetTime(), "Leave", "GlobalSync:OnFriendRemoved file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GlobalSync.lua:197:0"); return end
    
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
Perfy_Trace(Perfy_GetTime(), "Leave", "GlobalSync:OnFriendRemoved file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GlobalSync.lua:197:0"); end

function GlobalSync:RegisterEvents() Perfy_Trace(Perfy_GetTime(), "Enter", "GlobalSync:RegisterEvents file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GlobalSync.lua:230:0");
    if not IsBetaEnabled() then Perfy_Trace(Perfy_GetTime(), "Leave", "GlobalSync:RegisterEvents file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GlobalSync.lua:230:0"); return end

    BFL:RegisterEventCallback("FRIENDLIST_UPDATE", function() Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GlobalSync.lua:233:51");
        self:OnFriendListUpdate()
    Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GlobalSync.lua:233:51"); end)
Perfy_Trace(Perfy_GetTime(), "Leave", "GlobalSync:RegisterEvents file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GlobalSync.lua:230:0"); end

function GlobalSync:OnFriendListUpdate() Perfy_Trace(Perfy_GetTime(), "Enter", "GlobalSync:OnFriendListUpdate file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GlobalSync.lua:238:0");
    if not IsBetaEnabled() then Perfy_Trace(Perfy_GetTime(), "Leave", "GlobalSync:OnFriendListUpdate file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GlobalSync.lua:238:0"); return end
    
    -- Throttle updates
    if self.updateTimer then Perfy_Trace(Perfy_GetTime(), "Leave", "GlobalSync:OnFriendListUpdate file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GlobalSync.lua:238:0"); return end
    self.updateTimer = C_Timer.NewTimer(2, function() Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GlobalSync.lua:243:43");
        self:PerformSync()
        self.updateTimer = nil
    Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GlobalSync.lua:243:43"); end)
Perfy_Trace(Perfy_GetTime(), "Leave", "GlobalSync:OnFriendListUpdate file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GlobalSync.lua:238:0"); end

function GlobalSync:PerformSync() Perfy_Trace(Perfy_GetTime(), "Enter", "GlobalSync:PerformSync file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GlobalSync.lua:249:0");
    local faction = GetFaction()
    local realm = GetRealmName()
    
    if not faction or not realm then Perfy_Trace(Perfy_GetTime(), "Leave", "GlobalSync:PerformSync file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GlobalSync.lua:249:0"); return end
    
    -- 1. Export current friends to DB
    self:ExportFriends(faction, realm)
    
    -- 2. Import friends from connected realms
    self:ImportFriends(faction, realm)
    
    -- 3. Sync Deletions (Remove friends marked as deleted)
    self:SyncDeletions(faction, realm)
Perfy_Trace(Perfy_GetTime(), "Leave", "GlobalSync:PerformSync file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GlobalSync.lua:249:0"); end

function GlobalSync:ExportFriends(faction, realm) Perfy_Trace(Perfy_GetTime(), "Enter", "GlobalSync:ExportFriends file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GlobalSync.lua:265:0");
    local numFriends = C_FriendList.GetNumFriends()
    
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
Perfy_Trace(Perfy_GetTime(), "Leave", "GlobalSync:ExportFriends file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GlobalSync.lua:265:0"); end

function GlobalSync:ImportFriends(faction, currentRealm) Perfy_Trace(Perfy_GetTime(), "Enter", "GlobalSync:ImportFriends file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GlobalSync.lua:330:0");
    -- Check if sync is enabled in settings (default false)
    if not BetterFriendlistDB.enableGlobalSync then Perfy_Trace(Perfy_GetTime(), "Leave", "GlobalSync:ImportFriends file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GlobalSync.lua:330:0"); return end

    -- Ensure faction table exists
    if not BetterFriendlistDB.GlobalFriends[faction] then Perfy_Trace(Perfy_GetTime(), "Leave", "GlobalSync:ImportFriends file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GlobalSync.lua:330:0"); return end

    local friendsToAdd = {}
    local currentFriendList = {}
    
    -- Cache current friends for quick lookup
    local numFriends = C_FriendList.GetNumFriends()
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
Perfy_Trace(Perfy_GetTime(), "Leave", "GlobalSync:ImportFriends file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GlobalSync.lua:330:0"); end

function GlobalSync:SyncDeletions(faction, currentRealm) Perfy_Trace(Perfy_GetTime(), "Enter", "GlobalSync:SyncDeletions file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GlobalSync.lua:384:0");
    -- Check if deletion sync is enabled
    if not BetterFriendlistDB.enableGlobalSyncDeletion then Perfy_Trace(Perfy_GetTime(), "Leave", "GlobalSync:SyncDeletions file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GlobalSync.lua:384:0"); return end
    if not BetterFriendlistDB.GlobalFriends[faction] then Perfy_Trace(Perfy_GetTime(), "Leave", "GlobalSync:SyncDeletions file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GlobalSync.lua:384:0"); return end
    
    local friendsToRemove = {}
    
    -- Iterate current friends
    local numFriends = C_FriendList.GetNumFriends()
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
Perfy_Trace(Perfy_GetTime(), "Leave", "GlobalSync:SyncDeletions file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GlobalSync.lua:384:0"); end

function GlobalSync:ProcessAddQueue(queue) Perfy_Trace(Perfy_GetTime(), "Enter", "GlobalSync:ProcessAddQueue file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GlobalSync.lua:422:0");
    if self.processingQueue then Perfy_Trace(Perfy_GetTime(), "Leave", "GlobalSync:ProcessAddQueue file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GlobalSync.lua:422:0"); return end
    self.processingQueue = true
    
    local index = 1
    local max = #queue
    
    C_Timer.NewTicker(0.5, function(timer) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GlobalSync.lua:429:27");
        if not IsBetaEnabled() or not BetterFriendlistDB.enableGlobalSync then
            timer:Cancel()
            self.processingQueue = false
            Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GlobalSync.lua:429:27"); return
        end

        for i = 1, BATCH_SIZE do
            if index > max then
                timer:Cancel()
                self.processingQueue = false
                -- BFL:DebugPrint("GlobalSync: Finished syncing friends.")
                Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GlobalSync.lua:429:27"); return
            end
            
            local name = queue[index]
            -- BFL:DebugPrint("GlobalSync: Adding friend " .. name)
            C_FriendList.AddFriend(name)
            
            index = index + 1
        end
    Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GlobalSync.lua:429:27"); end)
Perfy_Trace(Perfy_GetTime(), "Leave", "GlobalSync:ProcessAddQueue file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GlobalSync.lua:422:0"); end

-- Register module
BFL.Modules[MODULE_NAME] = GlobalSync

Perfy_Trace(Perfy_GetTime(), "Leave", "(main chunk) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/GlobalSync.lua");