-- RaidFrame.lua
-- Raid management system for BetterFriendlist
-- Provides raid roster display, control panel, and saved instances info
-- Version 0.14

local ADDON_NAME, BFL = ...
local RaidFrame = BFL:RegisterModule("RaidFrame", {})

-- ========================================
-- CONSTANTS
-- ========================================

local RAID_MEMBERS_TO_DISPLAY = 40  -- Maximum raid size
local RAID_MEMBER_HEIGHT = 20       -- Height of each member button

-- Sort modes
local SORT_MODE_GROUP = 1           -- By group then name
local SORT_MODE_NAME = 2            -- Alphabetically
local SORT_MODE_CLASS = 3           -- By class
local SORT_MODE_RANK = 4            -- By raid rank (leader, assist, member)

-- Tab modes
local TAB_MODE_ROSTER = 1           -- Raid roster view
local TAB_MODE_INFO = 2             -- Saved instances info

-- ========================================
-- STATE
-- ========================================

RaidFrame.raidMembers = {}          -- Array of raid member data
RaidFrame.displayList = {}          -- Sorted/filtered display list
RaidFrame.selectedMember = nil      -- Currently selected member name
RaidFrame.sortMode = SORT_MODE_GROUP
RaidFrame.currentTab = TAB_MODE_ROSTER
RaidFrame.savedInstances = {}       -- Saved instance data

-- Difficulty constants (from Blizzard)
RaidFrame.DIFFICULTY_PRIMARYRAID_NORMAL = 14
RaidFrame.DIFFICULTY_PRIMARYRAID_HEROIC = 15
RaidFrame.DIFFICULTY_PRIMARYRAID_MYTHIC = 16
RaidFrame.DIFFICULTY_PRIMARYRAID_LFR = 17

-- ========================================
-- INITIALIZATION
-- ========================================

function RaidFrame:Initialize()
    -- Initialize state
    self.raidMembers = {}
    self.displayList = {}
    self.selectedMember = nil
    self.sortMode = SORT_MODE_GROUP
    self.currentTab = TAB_MODE_ROSTER
    self.savedInstances = {}
    
    -- Button pool for 8 groups × 5 members
    self.memberButtons = {}
    self.buttonPool = {}
    
    -- Register for events
    self:RegisterEvents()
    
    -- Initialize member buttons (XML templates)
    self:InitializeMemberButtons()
    
    -- Initial update of control panel (this will set label too)
    self:UpdateControlPanel()
    
    BFL:DebugPrint("[BFL] RaidFrame initialized")
end

function RaidFrame:RegisterEvents()
    -- Raid roster events
    BFL:RegisterEventCallback("RAID_ROSTER_UPDATE", function(...)
        RaidFrame:OnRaidRosterUpdate(...)
    end, 50)
    
    BFL:RegisterEventCallback("GROUP_ROSTER_UPDATE", function(...)
        RaidFrame:OnRaidRosterUpdate(...)
    end, 50)
    
    -- Group events
    BFL:RegisterEventCallback("GROUP_JOINED", function(...)
        RaidFrame:OnGroupJoined(...)
    end, 50)
    
    BFL:RegisterEventCallback("GROUP_LEFT", function(...)
        RaidFrame:OnGroupLeft(...)
    end, 50)
    
    -- Role assignment events
    BFL:RegisterEventCallback("PLAYER_ROLES_ASSIGNED", function(...)
        RaidFrame:UpdateRoleSummary()
    end, 50)
    
    -- Instance info events
    BFL:RegisterEventCallback("UPDATE_INSTANCE_INFO", function(...)
        RaidFrame:OnInstanceInfoUpdate(...)
    end, 50)
    
    BFL:RegisterEventCallback("PLAYER_DIFFICULTY_CHANGED", function(...)
        RaidFrame:OnDifficultyChanged(...)
    end, 50)
    
    -- Ready Check events
    BFL:RegisterEventCallback("READY_CHECK", function(...)
        RaidFrame:OnReadyCheck(...)
    end, 50)
    
    BFL:RegisterEventCallback("READY_CHECK_CONFIRM", function(...)
        RaidFrame:OnReadyCheckConfirm(...)
    end, 50)
    
    BFL:RegisterEventCallback("READY_CHECK_FINISHED", function(...)
        RaidFrame:OnReadyCheckFinished(...)
    end, 50)
end

-- ========================================
-- ROSTER MANAGER
-- ========================================

--- Update raid member list from WoW API
function RaidFrame:UpdateRaidMembers()
    wipe(self.raidMembers)
    
    -- Check if we're in a raid
    if not IsInRaid() then
        -- Not in raid - check if in party
        if IsInGroup() then
            -- In party - show party members
            self:UpdatePartyMembers()
        end
        return
    end
    
    -- Get raid members
    local numMembers = GetNumGroupMembers()
    
    for i = 1, numMembers do
        local name, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML = GetRaidRosterInfo(i)
        
        if name then
            local member = {
                index = i,
                name = name,
                rank = rank,  -- 0 = member, 1 = assistant, 2 = leader
                subgroup = subgroup,
                level = level,
                class = class,
                classFileName = fileName,
                zone = zone,
                online = online,
                isDead = isDead,
                role = role,  -- "TANK", "HEALER", "DAMAGER", "NONE"
                isML = isML,  -- Is master looter
                unit = "raid" .. i,
            }
            
            table.insert(self.raidMembers, member)
        end
    end
end

--- Update party members (when in party, not raid)
function RaidFrame:UpdatePartyMembers()
    -- Player
    local playerName = UnitName("player")
    local playerLevel = UnitLevel("player")
    local playerClass, playerFileName = UnitClass("player")
    local playerRole = UnitGroupRolesAssigned("player")
    
    table.insert(self.raidMembers, {
        index = 0,
        name = playerName,
        rank = UnitIsGroupLeader("player") and 2 or 0,
        subgroup = 1,
        level = playerLevel,
        class = playerClass,
        classFileName = playerFileName,
        zone = GetRealZoneText(),
        online = true,
        isDead = UnitIsDead("player"),
        role = playerRole,
        isML = false,
        unit = "player",
    })
    
    -- Party members
    for i = 1, GetNumSubgroupMembers() do
        local unit = "party" .. i
        if UnitExists(unit) then
            local name = UnitName(unit)
            local level = UnitLevel(unit)
            local class, fileName = UnitClass(unit)
            local role = UnitGroupRolesAssigned(unit)
            
            table.insert(self.raidMembers, {
                index = i,
                name = name,
                rank = 0,
                subgroup = 1,
                level = level,
                class = class,
                classFileName = fileName,
                zone = GetRealZoneText(),
                online = UnitIsConnected(unit),
                isDead = UnitIsDead(unit),
                role = role,
                isML = false,
                unit = unit,
            })
        end
    end
end

--- Build sorted display list
function RaidFrame:BuildDisplayList()
    wipe(self.displayList)
    
    -- Copy members to display list
    for _, member in ipairs(self.raidMembers) do
        table.insert(self.displayList, member)
    end
    
    -- Sort based on current sort mode
    self:SortDisplayList()
end

--- Sort display list
function RaidFrame:SortDisplayList()
    if self.sortMode == SORT_MODE_GROUP then
        -- Sort by group then name
        table.sort(self.displayList, function(a, b)
            if a.subgroup ~= b.subgroup then
                return a.subgroup < b.subgroup
            end
            return a.name < b.name
        end)
    elseif self.sortMode == SORT_MODE_NAME then
        -- Sort alphabetically
        table.sort(self.displayList, function(a, b)
            return a.name < b.name
        end)
    elseif self.sortMode == SORT_MODE_CLASS then
        -- Sort by class then name
        table.sort(self.displayList, function(a, b)
            if a.classFileName ~= b.classFileName then
                return a.classFileName < b.classFileName
            end
            return a.name < b.name
        end)
    elseif self.sortMode == SORT_MODE_RANK then
        -- Sort by rank (leader > assist > member) then name
        table.sort(self.displayList, function(a, b)
            if a.rank ~= b.rank then
                return a.rank > b.rank  -- Higher rank first
            end
            return a.name < b.name
        end)
    end
end

-- ========================================
-- MEMBER BUTTON MANAGEMENT
-- ========================================

--- Update all member buttons in the UI
function RaidFrame:UpdateAllMemberButtons()
    local frame = BetterFriendsFrame and BetterFriendsFrame.RaidFrame
    if not frame then
        return
    end
    
    -- GroupsContainer is inside GroupsInset
    local groupsContainer = frame.GroupsInset and frame.GroupsInset.GroupsContainer
    if not groupsContainer then
        return
    end
    
    -- Organize members by subgroup
    local membersByGroup = {}
    for i = 1, 8 do
        membersByGroup[i] = {}
    end
    
    for _, member in ipairs(self.raidMembers) do
        local subgroup = member.subgroup or 1
        if subgroup >= 1 and subgroup <= 8 then
            -- Get combat role for this member
            if member.unit then
                member.combatRole = UnitGroupRolesAssigned(member.unit)
            end
            
            table.insert(membersByGroup[subgroup], member)
        end
    end
    
    -- Update each group's buttons
    for groupIndex = 1, 8 do
        -- Update group title
        local groupFrame = groupsContainer["Group" .. groupIndex]
        if groupFrame and groupFrame.GroupTitle then
            groupFrame.GroupTitle:SetText("Group " .. groupIndex)
        end
        
        -- Update each slot in the group using self.memberButtons[]
        local members = membersByGroup[groupIndex]
        
        if self.memberButtons[groupIndex] then
            for slotIndex = 1, 5 do
                local button = self.memberButtons[groupIndex][slotIndex]
                if button then
                    local memberData = members[slotIndex]
                    self:UpdateMemberButton(button, memberData)
                end
            end
        end
    end
end

--- Initialize member buttons in all 8 groups
function RaidFrame:InitializeMemberButtons()
    local frame = BetterFriendsFrame and BetterFriendsFrame.RaidFrame
    if not frame then return end

    local groupsContainer = frame.GroupsContainer or (frame.GroupsInset and frame.GroupsInset.GroupsContainer)
    if not groupsContainer then return end
    
    -- Use existing XML template buttons (Slot1-Slot5)
    for groupIndex = 1, 8 do
        local groupFrame = groupsContainer["Group" .. groupIndex]
        if groupFrame then
            -- Set group title
            if groupFrame.GroupTitle then
                groupFrame.GroupTitle:SetText("Group " .. groupIndex)
            end
            
            -- Reference XML template buttons (already created)
            if not self.memberButtons[groupIndex] then
                self.memberButtons[groupIndex] = {}
            end
            
            for slotIndex = 1, 5 do
                -- Use the XML-defined buttons (Slot1, Slot2, etc.)
                local button = groupFrame["Slot" .. slotIndex]
                
                -- Store button reference
                if button then
                    button.groupIndex = groupIndex
                    button.slotIndex = slotIndex
                    self.memberButtons[groupIndex][slotIndex] = button
                end
            end
        end
    end
end

--- Update all member buttons based on current raid roster
function RaidFrame:UpdateMemberButtons()
    if not self.memberButtons or not self.raidMembers then return end
    
    -- First, hide all buttons
    for groupIndex = 1, 8 do
        if self.memberButtons[groupIndex] then
            for slotIndex = 1, 5 do
                local button = self.memberButtons[groupIndex][slotIndex]
                if button then
                    button:Hide()
                    button.memberData = nil
                end
            end
        end
    end
    
    -- Now assign members to buttons based on their subgroup
    for _, member in ipairs(self.raidMembers) do
        local groupIndex = member.subgroup or 1
        if groupIndex >= 1 and groupIndex <= 8 and self.memberButtons[groupIndex] then
            -- Find first empty slot in this group
            for slotIndex = 1, 5 do
                local button = self.memberButtons[groupIndex][slotIndex]
                if button and not button.memberData then
                    -- Assign member to this button
                    button.memberData = member
                    button:Show()
                    
                    -- Update button visuals
                    self:UpdateMemberButtonVisuals(button, member)
                    break
                end
            end
        end
    end
    
    -- Update combat overlay state
    self:UpdateCombatOverlay()
end

--- Update visual appearance of a member button
function RaidFrame:UpdateMemberButtonVisuals(button, member)
    if not button or not member then return end
    
    -- Set secure unit attribute for targeting (must be set before combat)
    if not InCombatLockdown() and member.unit then
        button:SetAttribute("unit", member.unit)
    end
    
    -- Update class icon
    if button.ClassIcon then
        if member.classFileName then
            button.ClassIcon:SetTexture("Interface\\WorldStateFrame\\Icons-Classes")
            local coords = CLASS_ICON_TCOORDS[member.classFileName]
            if coords then
                button.ClassIcon:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
                button.ClassIcon:Show()
            else
                button.ClassIcon:Hide()
            end
        else
            button.ClassIcon:Hide()
        end
    end
    
    -- Store data in button for callbacks
    button.unit = member.unit
    button.name = member.name
    button.raidSlot = member.index
    
    -- Update level
    if button.Level then
        if member.level and member.level > 0 then
            button.Level:SetText(member.level)
            button.Level:Show()
        else
            button.Level:Hide()
        end
    end
    
    -- Update name with class color
    if button.Name then
        button.Name:SetText(member.name or "")
        
        -- Apply class color
        local classColor = RAID_CLASS_COLORS[member.classFileName]
        if member.online then
            if member.isDead then
                -- Dead: Red
                button.Name:SetTextColor(1.0, 0, 0)
            elseif classColor then
                -- Alive & Online: Class color
                button.Name:SetTextColor(classColor.r, classColor.g, classColor.b)
            else
                -- Fallback: White
                button.Name:SetTextColor(1.0, 1.0, 1.0)
            end
        else
            -- Offline: Gray
            button.Name:SetTextColor(0.5, 0.5, 0.5)
        end
    end
    
    -- Update rank icon (Leader/Assistant)
    if button.RankIcon then
        if member.rank == 2 then
            -- Leader
            button.RankIcon:SetTexture("Interface\\GroupFrame\\UI-Group-LeaderIcon")
            button.RankIcon:Show()
        elseif member.rank == 1 then
            -- Assistant
            button.RankIcon:SetTexture("Interface\\GroupFrame\\UI-Group-AssistantIcon")
            button.RankIcon:Show()
        else
            button.RankIcon:Hide()
        end
    end
    
    -- Update role icon (Tank/Healer/DPS)
    if button.RoleIcon then
        if member.combatRole == "TANK" then
            button.RoleIcon:SetAtlas("UI-LFG-RoleIcon-Tank-Micro-GroupFinder")
            button.RoleIcon:Show()
        elseif member.combatRole == "HEALER" then
            button.RoleIcon:SetAtlas("UI-LFG-RoleIcon-Healer-Micro-GroupFinder")
            button.RoleIcon:Show()
        elseif member.combatRole == "DAMAGER" then
            button.RoleIcon:SetAtlas("UI-LFG-RoleIcon-DPS-Micro-GroupFinder")
            button.RoleIcon:Show()
        else
            button.RoleIcon:Hide()
        end
    end
    
    -- Update ready check icon (will be updated by events)
    if button.ReadyCheckIcon then
        button.ReadyCheckIcon:Hide()  -- Hidden by default
    end
    
    -- Update background alpha based on online status
    if button.Background then
        if member.online then
            button.Background:SetAlpha(0.5)
        else
            button.Background:SetAlpha(0.3)
        end
    end
end

--- Update Member Count display
function RaidFrame:UpdateMemberCount()
    local frame = BetterFriendsFrame and BetterFriendsFrame.RaidFrame
    if not frame or not frame.ControlPanel or not frame.ControlPanel.MemberCount then
        BFL:DebugPrint("[BFL] UpdateMemberCount: Frame check failed - frame=" .. tostring(frame) .. ", ControlPanel=" .. tostring(frame and frame.ControlPanel) .. ", MemberCount=" .. tostring(frame and frame.ControlPanel and frame.ControlPanel.MemberCount))
        return
    end
    
    local numMembers = 0
    if IsInRaid() then
        numMembers = GetNumGroupMembers()
    elseif IsInGroup() then
        numMembers = GetNumSubgroupMembers() + 1 -- +1 for player
    end
    
    -- Add friend icon before the count (same icon as in Quick Filters "All Friends")
    local FRIEND_ICON = "|TInterface\\FriendsFrame\\UI-Toast-FriendOnlineIcon:16:16|t"
    local textToSet = FRIEND_ICON .. " " .. numMembers .. "/40"
    BFL:DebugPrint("[BFL] UpdateMemberCount: Setting text to '" .. textToSet .. "' (numMembers=" .. numMembers .. ")")
    frame.ControlPanel.MemberCount:SetText(textToSet)
    local actualText = frame.ControlPanel.MemberCount:GetText()
    BFL:DebugPrint("[BFL] UpdateMemberCount: Actual text after SetText: '" .. tostring(actualText) .. "'")
end

--- Update all Control Panel elements (MemberCount, RoleSummary, Labels)
function RaidFrame:UpdateControlPanel()
    local frame = BetterFriendsFrame and BetterFriendsFrame.RaidFrame
    if not frame or not frame.ControlPanel then
        return
    end
    
    BFL:DebugPrint("[BFL] UpdateControlPanel called")
    
    -- Set Assist All label if not already set
    if frame.ControlPanel.EveryoneAssistLabel then
        local currentText = frame.ControlPanel.EveryoneAssistLabel:GetText()
        if not currentText or currentText == "" then
            local ASSIST_ICON = "|TInterface\\GroupFrame\\UI-Group-AssistantIcon:14:14|t"
            frame.ControlPanel.EveryoneAssistLabel:SetText("All " .. ASSIST_ICON)
            BFL:DebugPrint("[BFL] Assist All label set: All " .. ASSIST_ICON)
        end
    end
    
    -- Update Role Summary
    self:UpdateRoleSummary()
    
    -- Update Member Count
    self:UpdateMemberCount()
end

function RaidFrame:UpdateRoleSummary()
    local frame = BetterFriendsFrame.RaidFrame
    if not frame or not frame.ControlPanel or not frame.ControlPanel.RoleSummary then
        return
    end
    
    local tanks = 0
    local healers = 0
    local dps = 0
    
    -- Count roles from raid members
    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do
            local unit = "raid" .. i
            if UnitExists(unit) then
                local role = UnitGroupRolesAssigned(unit)
                if role == "TANK" then
                    tanks = tanks + 1
                elseif role == "HEALER" then
                    healers = healers + 1
                elseif role == "DAMAGER" then
                    dps = dps + 1
                end
            end
        end
    else
        -- Party mode (player + party members)
        local playerRole = UnitGroupRolesAssigned("player")
        if playerRole == "TANK" then
            tanks = tanks + 1
        elseif playerRole == "HEALER" then
            healers = healers + 1
        elseif playerRole == "DAMAGER" then
            dps = dps + 1
        end
        
        for i = 1, GetNumSubgroupMembers() do
            local unit = "party" .. i
            if UnitExists(unit) then
                local role = UnitGroupRolesAssigned(unit)
                if role == "TANK" then
                    tanks = tanks + 1
                elseif role == "HEALER" then
                    healers = healers + 1
                elseif role == "DAMAGER" then
                    dps = dps + 1
                end
            end
        end
    end
    
    -- Format: Tank Icon + count, Healer Icon + count, DPS Icon + count
    -- Using Blizzard's modern micro role icons (same as in GroupFinder and FriendsFrame)
    local iconSize = 16
    
    -- Using the modern UI-LFG micro role icons
    local tankIcon = CreateAtlasMarkup("UI-LFG-RoleIcon-Tank-Micro-GroupFinder", iconSize, iconSize)
    local healIcon = CreateAtlasMarkup("UI-LFG-RoleIcon-Healer-Micro-GroupFinder", iconSize, iconSize)
    local dpsIcon = CreateAtlasMarkup("UI-LFG-RoleIcon-DPS-Micro-GroupFinder", iconSize, iconSize)
    
    local text = string.format("%s %d  %s %d  %s %d", tankIcon, tanks, healIcon, healers, dpsIcon, dps)
    frame.ControlPanel.RoleSummary:SetText(text)
end

--- Update a single member button with raid member data
-- @param button: The button frame to update
-- @param memberData: Table with member info (name, class, level, rank, role, etc.) - can be nil for empty slot
function RaidFrame:UpdateMemberButton(button, memberData)
    if not button then return end
    
    -- Show button even if empty (for visual consistency)
    button:Show()
    
    -- If no member data, show empty slot
    if not memberData then
        button.memberData = nil
        
        -- CRITICAL: Clear button properties for callbacks (prevent stale data)
        button.unit = nil
        button.name = nil
        button.raidSlot = nil
        
        -- Hide all content
        if button.Name then button.Name:SetText("") end
        if button.Level then button.Level:SetText("") end
        if button.ClassIcon then button.ClassIcon:Hide() end
        if button.RankIcon then button.RankIcon:Hide() end
        if button.RoleIcon then button.RoleIcon:Hide() end
        if button.ReadyCheckIcon then button.ReadyCheckIcon:Hide() end
        
        -- Show "Empty" text
        if button.EmptyText then button.EmptyText:Show() end
        
        -- Reset to empty slot appearance
        if button.ClassColorTint then
            button.ClassColorTint:SetColorTexture(0.1, 0.1, 0.1, 0.3)
        end
        
        -- Update Combat Overlay even for empty slots
        if button.CombatOverlay then
            local inCombat = InCombatLockdown()
            if inCombat then
                button.CombatOverlay:Show()
            else
                button.CombatOverlay:Hide()
            end
        end
        
        return
    end
    
    -- Hide "Empty" text when slot is occupied
    if button.EmptyText then button.EmptyText:Hide() end
    
    -- Store member data in button
    button.memberData = memberData
    
    -- CRITICAL: Set button properties for callbacks (tooltip, context menu, drag&drop)
    button.unit = memberData.unit
    button.name = memberData.name
    button.raidSlot = memberData.raidIndex
    
    -- Update class icon
    if button.ClassIcon and memberData.classFileName then
        button.ClassIcon:SetTexture("Interface\\WorldStateFrame\\Icons-Classes")
        local coords = CLASS_ICON_TCOORDS[memberData.classFileName]
        if coords then
            button.ClassIcon:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
            button.ClassIcon:Show()
        else
            button.ClassIcon:Hide()
        end
    elseif button.ClassIcon then
        button.ClassIcon:Hide()
    end
    
    -- Update level
    if button.Level and memberData.level and memberData.level > 0 then
        button.Level:SetText(memberData.level)
        button.Level:Show()
    elseif button.Level then
        button.Level:Hide()
    end
    
    -- Update name with class color
    local classColor = RAID_CLASS_COLORS[memberData.classFileName]
    if classColor then
        if memberData.online then
            if memberData.isDead then
                -- Dead: Red
                button.Name:SetTextColor(RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b)
            else
                -- Alive: Class Color
                button.Name:SetTextColor(classColor.r, classColor.g, classColor.b)
            end
        else
            -- Offline: Gray
            button.Name:SetTextColor(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b)
        end
    end
    if button.Name then
        button.Name:SetText(memberData.name or "")
    end
    
    -- Update class color tint overlay (subtle tint over textured background)
    if button.ClassColorTint then
        if classColor and memberData.online then
            button.ClassColorTint:SetColorTexture(classColor.r, classColor.g, classColor.b, 0.3)
        else
            button.ClassColorTint:SetColorTexture(0.1, 0.1, 0.1, 0.5)
        end
    end
    
    -- Update Rank Icon (Leader/Assistant)
    if memberData.rank == 2 then
        -- Leader
        button.RankIcon:SetTexture("Interface\\GroupFrame\\UI-Group-LeaderIcon")
        button.RankIcon:Show()
    elseif memberData.rank == 1 then
        -- Assistant
        button.RankIcon:SetTexture("Interface\\GroupFrame\\UI-Group-AssistantIcon")
        button.RankIcon:Show()
    else
        button.RankIcon:Hide()
    end
    
    -- Update Role Icon (Tank/Healer/DPS)
    if memberData.combatRole and memberData.combatRole ~= "NONE" then
        if memberData.combatRole == "TANK" then
            button.RoleIcon:SetAtlas("UI-LFG-RoleIcon-Tank-Micro-GroupFinder")
            button.RoleIcon:Show()
        elseif memberData.combatRole == "HEALER" then
            button.RoleIcon:SetAtlas("UI-LFG-RoleIcon-Healer-Micro-GroupFinder")
            button.RoleIcon:Show()
        elseif memberData.combatRole == "DAMAGER" then
            button.RoleIcon:SetAtlas("UI-LFG-RoleIcon-DPS-Micro-GroupFinder")
            button.RoleIcon:Show()
        end
    else
        button.RoleIcon:Hide()
    end
    
    -- Update Ready Check Icon (if active)
    if memberData.readyStatus then
        if memberData.readyStatus == "ready" then
            button.ReadyCheckIcon:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
            button.ReadyCheckIcon:Show()
        elseif memberData.readyStatus == "notready" then
            button.ReadyCheckIcon:SetTexture("Interface\\RaidFrame\\ReadyCheck-NotReady")
            button.ReadyCheckIcon:Show()
        elseif memberData.readyStatus == "waiting" then
            button.ReadyCheckIcon:SetTexture("Interface\\RaidFrame\\ReadyCheck-Waiting")
            button.ReadyCheckIcon:Show()
        end
    else
        button.ReadyCheckIcon:Hide()
    end
    
    -- Update Combat Overlay (always check, even for filled buttons)
    if button.CombatOverlay then
        local inCombat = InCombatLockdown()
        if inCombat then
            button.CombatOverlay:Show()
        else
            button.CombatOverlay:Hide()
        end
    end
end

--- Update combat overlay on all buttons
--- @param inCombat boolean|nil Optional combat state (defaults to InCombatLockdown())
function RaidFrame:UpdateCombatOverlay(inCombat)
    if not self.memberButtons then 
        BFL:DebugPrint("[BFL] UpdateCombatOverlay: No member buttons")
        return 
    end
    
    -- Use passed parameter or query current state
    local combatState = inCombat
    if combatState == nil then
        combatState = InCombatLockdown()
    end
    local buttonsUpdated = 0
    
    BFL:DebugPrint("[BFL] RaidFrame:UpdateCombatOverlay START - combatState: " .. tostring(combatState) .. " (param was: " .. tostring(inCombat) .. ")")
    BFL:DebugPrint("[BFL] memberButtons structure: " .. tostring(self.memberButtons) .. ", type: " .. type(self.memberButtons))
    
    for groupIndex = 1, 8 do
        if self.memberButtons[groupIndex] then
            BFL:DebugPrint("[BFL] Processing group " .. groupIndex)
            for slotIndex = 1, 5 do
                local button = self.memberButtons[groupIndex][slotIndex]
                if button then
                    local isShown = button:IsShown()
                    BFL:DebugPrint("[BFL] Button [" .. groupIndex .. "][" .. slotIndex .. "] - IsShown: " .. tostring(isShown) .. ", HasOverlay: " .. tostring(button.CombatOverlay ~= nil))
                    
                    -- Ensure CombatOverlay exists
                    if not button.CombatOverlay then
                        BFL:DebugPrint("[BFL] Button [" .. groupIndex .. "][" .. slotIndex .. "] missing CombatOverlay!")
                    else
                        if combatState and isShown then
                            button.CombatOverlay:Show()
                            buttonsUpdated = buttonsUpdated + 1
                            BFL:DebugPrint("[BFL] Showed overlay on button [" .. groupIndex .. "][" .. slotIndex .. "]")
                        else
                            button.CombatOverlay:Hide()
                            BFL:DebugPrint("[BFL] Hid overlay on button [" .. groupIndex .. "][" .. slotIndex .. "] (combatState=" .. tostring(combatState) .. ", isShown=" .. tostring(isShown) .. ")")
                        end
                    end
                end
            end
        end
    end
    
    BFL:DebugPrint("[BFL] Combat overlay updated on " .. buttonsUpdated .. " buttons (out of 40 possible)")
end

--- Get number of raid members
function RaidFrame:GetNumMembers()
    return #self.raidMembers
end

--- Get selected member data
function RaidFrame:GetSelectedMember()
    if not self.selectedMember then
        return nil
    end
    
    for _, member in ipairs(self.raidMembers) do
        if member.name == self.selectedMember then
            return member
        end
    end
    
    return nil
end

--- Set selected member
function RaidFrame:SetSelectedMember(name)
    self.selectedMember = name
end

-- ========================================
-- CONTROL PANEL
-- ========================================

--- Check if player can control raid
function RaidFrame:CanControlRaid()
    return UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")
end

--- Check if player is raid leader
function RaidFrame:IsRaidLeader()
    return UnitIsGroupLeader("player")
end

--- Convert to raid
function RaidFrame:ConvertToRaid()
    if not IsInGroup() then
        return false
    end
    
    if IsInRaid() then
        return false  -- Already in raid
    end
    
    C_PartyInfo.ConvertToRaid()
    return true
end

--- Convert to party
function RaidFrame:ConvertToParty()
    if not IsInRaid() then
        return false
    end
    
    if GetNumGroupMembers() > 5 then
        return false  -- Too many members for party
    end
    
    C_PartyInfo.ConvertToParty()
    return true
end

--- Initiate ready check
function RaidFrame:DoReadyCheck()
    if not self:CanControlRaid() then
        return false
    end
    
    DoReadyCheck()
    return true
end

--- Initiate role poll
function RaidFrame:DoRolePoll()
    if not self:CanControlRaid() then
        return false
    end
    
    InitiateRolePoll()
    return true
end

--- Set raid difficulty
function RaidFrame:SetRaidDifficulty(difficultyID)
    if not self:IsRaidLeader() then
        return false
    end
    
    SetRaidDifficultyID(difficultyID)
    return true
end

--- Toggle everyone is assistant
function RaidFrame:SetEveryoneIsAssistant(enabled)
    if not self:IsRaidLeader() then
        return false
    end
    
    SetEveryoneIsAssistant(enabled)
    return true
end

--- Check if everyone is assistant
function RaidFrame:GetEveryoneIsAssistant()
    return IsEveryoneAssistant()
end

-- ========================================
-- INFO PANEL (SAVED INSTANCES)
-- ========================================

--- Request saved instance info
function RaidFrame:RequestInstanceInfo()
    RequestRaidInfo()
end

--- Update saved instances
function RaidFrame:UpdateSavedInstances()
    wipe(self.savedInstances)
    
    local numSaved = GetNumSavedInstances()
    
    for i = 1, numSaved do
        local name, id, reset, difficulty, locked, extended, instanceIDMostSig, isRaid, maxPlayers, difficultyName, numEncounters, encounterProgress = GetSavedInstanceInfo(i)
        
        if name and locked then
            table.insert(self.savedInstances, {
                index = i,
                name = name,
                id = id,
                reset = reset,
                difficulty = difficulty,
                difficultyName = difficultyName,
                locked = locked,
                extended = extended,
                isRaid = isRaid,
                maxPlayers = maxPlayers,
                numEncounters = numEncounters,
                encounterProgress = encounterProgress,
            })
        end
    end
end

--- Extend raid lock
function RaidFrame:ExtendRaidLock(instanceIndex)
    if not instanceIndex then
        return false
    end
    
    SetSavedInstanceExtend(instanceIndex, true)
    return true
end

-- ========================================
-- TAB MANAGEMENT
-- ========================================

--- Switch tabs (Roster / Info)
function RaidFrame:SetTab(tabIndex)
    if tabIndex < TAB_MODE_ROSTER or tabIndex > TAB_MODE_INFO then
        return false
    end
    
    self.currentTab = tabIndex
    
    -- Request instance info when switching to info tab
    if tabIndex == TAB_MODE_INFO then
        self:RequestInstanceInfo()
    end
    
    return true
end

--- Get current tab
function RaidFrame:GetCurrentTab()
    return self.currentTab
end

-- ========================================
-- EVENT HANDLERS
-- ========================================

function RaidFrame:OnRaidRosterUpdate(...)
    -- Update member list
    self:UpdateRaidMembers()
    self:BuildDisplayList()
    
    -- Update UI
    self:UpdateAllMemberButtons()
    self:UpdateControlPanel()
    
    -- Note: We DON'T need to call BetterRaidFrame_Update() here anymore
    -- The EveryoneAssistCheckbox handles its own state via events (GROUP_ROSTER_UPDATE)
end

function RaidFrame:OnGroupJoined(...)
    -- Update member list
    self:UpdateRaidMembers()
    self:BuildDisplayList()
    
    -- Update UI
    self:UpdateAllMemberButtons()
    self:UpdateControlPanel()
end

function RaidFrame:OnGroupLeft(...)
    -- Clear member list
    wipe(self.raidMembers)
    wipe(self.displayList)
    self.selectedMember = nil
end

function RaidFrame:OnInstanceInfoUpdate(...)
    -- Update saved instances
    self:UpdateSavedInstances()
end

function RaidFrame:OnDifficultyChanged(...)
    -- Difficulty changed - update control panel state
    -- UI will refresh on next render
end

--- Handle Ready Check start
function RaidFrame:OnReadyCheck(initiator, timeLeft)
    -- Mark all members with their current ready check status
    for _, member in ipairs(self.raidMembers) do
        if member.unit then
            local status = GetReadyCheckStatus(member.unit)
            -- Only set status if we don't already have one (CONFIRM event might have fired first)
            if not member.readyStatus then
                -- For offline players, status might be nil initially
                if not member.online and not status then
                    member.readyStatus = "waiting"
                else
                    member.readyStatus = status or "waiting"
                end
            end
        end
    end
    
    -- Update all visible buttons
    self:RefreshMemberButtons()
end

--- Handle Ready Check confirmation
function RaidFrame:OnReadyCheckConfirm(unitTarget, isReady)
    -- Find member by unit and update status
    for _, member in ipairs(self.raidMembers) do
        if member.unit == unitTarget then
            -- Get actual status from API (more reliable than event param)
            local status = GetReadyCheckStatus(member.unit)
            member.readyStatus = status or (isReady and "ready" or "notready")
            break
        end
    end
    
    -- Update all visible buttons
    self:RefreshMemberButtons()
end

--- Handle Ready Check finished
function RaidFrame:OnReadyCheckFinished(preempted)
    -- Clear ready check status after a delay (like Blizzard does)
    C_Timer.After(5, function()
        for _, member in ipairs(self.raidMembers) do
            member.readyStatus = nil
        end
        
        -- Update all visible buttons
        self:RefreshMemberButtons()
    end)
end

--- Refresh all visible member buttons (for Ready Check updates)
function RaidFrame:RefreshMemberButtons()
    local frame = BetterFriendsFrame and BetterFriendsFrame.RaidFrame
    if not frame then return end
    
    local groupsContainer = frame.GroupsInset and frame.GroupsInset.GroupsContainer
    if not groupsContainer then return end
    
    -- Update each group's buttons
    for groupIndex = 1, 8 do
        local groupFrame = groupsContainer["Group" .. groupIndex]
        if groupFrame then
            for slotIndex = 1, 5 do
                local button = groupFrame["Slot" .. slotIndex]
                if button and button.memberData then
                    -- Find updated member data from raidMembers
                    local memberName = button.memberData.name
                    for _, member in ipairs(self.raidMembers) do
                        if member.name == memberName then
                            -- Update button with fresh member data (including readyStatus)
                            button.memberData = member
                            self:UpdateMemberButton(button, member)
                            break
                        end
                    end
                end
            end
        end
    end
end

-- ========================================
-- PUBLIC API SUMMARY
-- ========================================
--[[
    Initialization:
    - RaidFrame:Initialize()
    
    Roster Management:
    - RaidFrame:UpdateRaidMembers()
    - RaidFrame:BuildDisplayList()
    - RaidFrame:GetNumMembers()
    - RaidFrame:GetSelectedMember()
    - RaidFrame:SetSelectedMember(name)
    
    Control Panel:
    - RaidFrame:CanControlRaid()
    - RaidFrame:IsRaidLeader()
    - RaidFrame:ConvertToRaid()
    - RaidFrame:ConvertToParty()
    - RaidFrame:DoReadyCheck()
    - RaidFrame:DoRolePoll()
    - RaidFrame:SetRaidDifficulty(difficultyID)
    - RaidFrame:SetEveryoneIsAssistant(enabled)
    - RaidFrame:GetEveryoneIsAssistant()
    
    Info Panel:
    - RaidFrame:RequestInstanceInfo()
    - RaidFrame:UpdateSavedInstances()
    - RaidFrame:ExtendRaidLock(instanceIndex)
    
    Tab Management:
    - RaidFrame:SetTab(tabIndex)
    - RaidFrame:GetCurrentTab()
]]

return RaidFrame
