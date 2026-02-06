-- RaidFrame.lua
-- Raid management system for BetterFriendlist
-- Provides raid roster display, control panel, and saved instances info
-- Version 0.14

local ADDON_NAME, BFL = ...
local L = BFL.L
local FontManager = BFL.FontManager
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
RaidFrame.pendingUpdate = false     -- Throttle flag for roster updates

-- Dirty flag: Set when data changes while frame is hidden
local needsRenderOnShow = false
local isUpdatingRaid = false

-- Difficulty constants (from Blizzard)
RaidFrame.DIFFICULTY_PRIMARYRAID_NORMAL = 14
RaidFrame.DIFFICULTY_PRIMARYRAID_HEROIC = 15
RaidFrame.DIFFICULTY_PRIMARYRAID_MYTHIC = 16
RaidFrame.DIFFICULTY_PRIMARYRAID_LFR = 17

-- ========================================
-- HELPER FUNCTIONS
-- ========================================

--- Get role icon string (Retail/Classic compatible)
local function GetRoleIconString(role, size)
    size = size or 16
    if BFL.IsRetail then
        if role == "TANK" then
            return CreateAtlasMarkup("UI-LFG-RoleIcon-Tank-Micro-GroupFinder", size, size)
        elseif role == "HEALER" then
            return CreateAtlasMarkup("UI-LFG-RoleIcon-Healer-Micro-GroupFinder", size, size)
        else
            return CreateAtlasMarkup("UI-LFG-RoleIcon-DPS-Micro-GroupFinder", size, size)
        end
    else
        -- Classic fallback using standard LFG role icons
        -- Texture: Interface\LFGFrame\UI-LFG-ICON-PORTRAITROLES
        if role == "TANK" then
            return string.format("|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:%d:%d:0:0:64:64:0:19:22:41|t", size, size)
        elseif role == "HEALER" then
            return string.format("|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:%d:%d:0:0:64:64:20:39:1:20|t", size, size)
        else
            return string.format("|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:%d:%d:0:0:64:64:20:39:22:41|t", size, size)
        end
    end
end

-- ========================================
-- RESPONSIVE LAYOUT (PHASE 4)
-- ========================================

-- Update group layout with proportional scaling (Phase 4)
-- Icons remain 28x28 fixed (user decision: no icon scaling)
function RaidFrame:UpdateGroupLayout()
    local frame = BetterFriendsFrame
    if not frame or not frame.RaidFrame then
        return
    end
    
    local raidFrame = frame.RaidFrame
    local groupsContainer = raidFrame.GroupsInset and raidFrame.GroupsInset.GroupsContainer
    if not groupsContainer then
        return
    end
    
    -- Get ACTUAL available space from GroupsInset
    local inset = raidFrame.GroupsInset
    if not inset then return end
    
    local insetWidth = inset:GetWidth()
    local insetHeight = inset:GetHeight()
    
    -- GroupsContainer padding (from XML)
    local containerPaddingX = 20  -- 10px left + 10px right
    local containerPaddingY = 4   -- 2px top + 2px bottom
    
    local availableWidth = insetWidth - containerPaddingX
    local availableHeight = insetHeight - containerPaddingY
    
    -- BFL:DebugPrint("|cff00ff00=== RaidFrame Layout Debug ===|r")
    -- BFL:DebugPrint(string.format("Frame size: %.1f x %.1f", frame:GetWidth(), frame:GetHeight()))
    -- BFL:DebugPrint(string.format("Inset size: %.1f x %.1f", insetWidth, insetHeight))
    -- BFL:DebugPrint(string.format("Available space: %.1f x %.1f", availableWidth, availableHeight))
    
    -- Group spacing and structure (from XML)
    local groupGapX = 4   -- Horizontal gap between groups (reduced from 10 for better space usage)
    local groupGapY = -5   -- Vertical gap between groups (reduced from 6 for tighter layout)
    local groupHeaderHeight = 20  -- GroupTitle + padding (from XML: y="-7" to y="-20")
    local buttonHeight = 20  -- Each member button (from XML)
    local buttonGap = 2  -- Gap between buttons (from XML)
    local numButtons = 5  -- 5 slots per group
    
    -- DYNAMIC GRID CALCULATION: Find optimal columns/rows for 8 groups
    local totalGroups = 8
    local bestCols = 2
    local bestRows = 4
    local bestGroupWidth = 0
    local bestGroupHeight = 0
    local bestArea = 0  -- Maximize total group area
    
-- BFL:DebugPrint("|cffff8800Testing grid configurations:|r")
    
    -- Try ONLY valid grid configurations that use all 8 groups
    -- Valid layouts: 1×8, 2×4, 4×2, 8×1
    local validLayouts = {
        {cols = 1, rows = 8},
        {cols = 2, rows = 4},
        {cols = 4, rows = 2},
        {cols = 8, rows = 1}
    }
    
    for _, layout in ipairs(validLayouts) do
        local cols = layout.cols
        local rows = layout.rows
        
        -- Calculate max group size for this configuration
        local totalGapX = (cols - 1) * groupGapX
        local totalGapY = (rows - 1) * groupGapY
        
        local maxGroupWidth = (availableWidth - totalGapX) / cols
        local maxGroupHeight = (availableHeight - totalGapY) / rows
        
        -- Each group needs: header + (5 buttons × buttonHeight) + (4 gaps × buttonGap)
        -- Minimum height: 20 + (5×20) + (4×2) = 128px at scale 1.0
        local minButtonAreaHeight = numButtons * buttonHeight + (numButtons - 1) * buttonGap
        local minGroupHeight = groupHeaderHeight + minButtonAreaHeight  -- 20 + 108 = 128px
        
        -- Check if this configuration provides enough height
        local groupArea = maxGroupWidth * maxGroupHeight
        
        -- Calculate aspect ratio (width/height) - prefer more vertical layouts
        local aspectRatio = maxGroupWidth / maxGroupHeight
        
        -- BFL:DebugPrint(string.format("  %dx%d: width=%.1f, height=%.1f (min=%.0f), area=%.0f, ratio=%.2f", 
        --     cols, rows, maxGroupWidth, maxGroupHeight, minGroupHeight, groupArea, aspectRatio))
        
        -- Scoring system for layout selection
        -- Prefer configurations that:
        -- 1. Have the largest area (primary factor)
        -- 2. Meet minimum height requirements (80% of ideal = 102px)
        -- 3. Have reasonable aspect ratios (0.5 to 5.0 for extreme flexibility)
        local minHeightThreshold = minGroupHeight * 0.6  -- Very lenient: 76px minimum
        local isValidHeight = maxGroupHeight >= minHeightThreshold
        local isReasonableRatio = aspectRatio >= 0.5 and aspectRatio <= 5.0
        
        -- Calculate score: area is primary, but penalize extreme ratios
        local score = groupArea
        if not isValidHeight then
            score = score * 0.5  -- 50% penalty for insufficient height
        end
        if not isReasonableRatio then
            score = score * 0.7  -- 30% penalty for extreme aspect ratio
        end
        
        -- ALWAYS track the best option, even if not perfect
        if score > bestArea or bestArea == 0 then
            bestArea = score
            bestGroupWidth = maxGroupWidth
            bestGroupHeight = maxGroupHeight
            bestCols = cols
            bestRows = rows
        end
    end
    
    -- Fallback: If somehow no layout was selected, force 2×4 (most common)
    if bestGroupWidth == 0 or bestGroupHeight == 0 then
        -- BFL:DebugPrint("|cffff0000WARNING: No valid layout found, forcing 2x4 grid|r")
        bestCols = 2
        bestRows = 4
        local totalGapX = (bestCols - 1) * groupGapX
        local totalGapY = (bestRows - 1) * groupGapY
        bestGroupWidth = (availableWidth - totalGapX) / bestCols
        bestGroupHeight = (availableHeight - totalGapY) / bestRows
        bestArea = bestGroupWidth * bestGroupHeight
    end
    
-- BFL:DebugPrint(string.format("|cff00ff00Best config: %dx%d grid, groups: %.1fx%.1f (area=%.0f)|r", 
-- 		bestCols, bestRows, bestGroupWidth, bestGroupHeight, bestArea))
	
	-- Calculate proportional button dimensions
	local newButtonHeight = (bestGroupHeight - groupHeaderHeight - (numButtons - 1) * buttonGap) / numButtons
	local newButtonGap = buttonGap
	
	-- BFL:DebugPrint(string.format("Button dimensions: %.1fpx height, %.1fpx gap", newButtonHeight, newButtonGap))
	
	groupsContainer:SetScale(1.0)
	
	-- Reposition and resize all 8 groups
	for i = 1, totalGroups do
		local group = groupsContainer["Group" .. i]
		if group then
			group:ClearAllPoints()
			group:SetScale(1.0)  -- No scaling!
			
			-- Calculate column and row (0-indexed)
			local col = (i - 1) % bestCols
			local row = math.floor((i - 1) / bestCols)
			
			local xPos = col * (bestGroupWidth + groupGapX)
			local yPos = -row * (bestGroupHeight + groupGapY)
			
			group:SetPoint("TOPLEFT", groupsContainer, "TOPLEFT", xPos, yPos)
			group:SetSize(bestGroupWidth, bestGroupHeight)
			
			-- Resize GroupTitle (stays at top)
			if group.GroupTitle then
				group.GroupTitle:ClearAllPoints()
				group.GroupTitle:SetPoint("TOP", group, "TOP", 0, -7)
				group.GroupTitle:SetWidth(bestGroupWidth)
			end
			
			-- Resize and reposition all 5 member button slots
			for slotNum = 1, numButtons do
				local slot = group["Slot" .. slotNum]
				if slot then
					slot:ClearAllPoints()
					slot:SetSize(bestGroupWidth, newButtonHeight)
					
					-- Position: first slot below header, others stacked with gaps
					if slotNum == 1 then
						slot:SetPoint("TOP", group, "TOP", 0, -(groupHeaderHeight))
					else
						local prevSlot = group["Slot" .. (slotNum - 1)]
						slot:SetPoint("TOP", prevSlot, "BOTTOM", 0, -newButtonGap)
					end
					
					-- Resize internal button elements (Background, ClassColorTint, etc.)
					if slot.Background then
						slot.Background:ClearAllPoints()
						slot.Background:SetPoint("TOPLEFT", slot, "TOPLEFT", -3, 0)
						slot.Background:SetPoint("BOTTOMRIGHT", slot, "BOTTOMRIGHT", 3, 0)
					end
					
					if slot.ClassColorTint then
						slot.ClassColorTint:ClearAllPoints()
						slot.ClassColorTint:SetPoint("TOPLEFT", slot, "TOPLEFT", 1, -1)
						slot.ClassColorTint:SetPoint("BOTTOMRIGHT", slot, "BOTTOMRIGHT", -1, 1)
					end
					
					if slot.CombatOverlay then
						slot.CombatOverlay:ClearAllPoints()
						slot.CombatOverlay:SetPoint("TOPLEFT", slot, "TOPLEFT", 1, -1)
						slot.CombatOverlay:SetPoint("BOTTOMRIGHT", slot, "BOTTOMRIGHT", -1, 1)
					end
					
					-- Scale icons proportionally to button height
					local iconSize = math.max(12, math.min(16, newButtonHeight * 0.8))
					if slot.ClassIcon then
						slot.ClassIcon:SetSize(iconSize, iconSize)
					end
					if slot.RankIcon then
						slot.RankIcon:SetSize(iconSize, iconSize)
					end
					if slot.RoleIcon then
						slot.RoleIcon:SetSize(iconSize, iconSize)
					end
				end
			end
			
			if i == 1 then
				-- BFL:DebugPrint(string.format("Group 1: pos=(%.1f, %.1f), size=%.1fx%.1f, buttonHeight=%.1f", 
				-- 	xPos, yPos, bestGroupWidth, bestGroupHeight, newButtonHeight))
			end
		end
	end
    
    self:UpdateControlPanelLayout()
    
    -- Refresh all visible member buttons to reflect new sizes
    -- This ensures Name, Level, Icons are repositioned correctly
    self:UpdateAllMemberButtons()
end

function RaidFrame:UpdateControlPanelLayout()
    local frame = BetterFriendsFrame
    if not frame or not frame.RaidFrame then
        -- BFL:DebugPrint("|cffff0000[ControlPanel] BetterFriendsFrame or RaidFrame not found|r")
        return
    end
    
    local raidFrame = frame.RaidFrame
    local controlPanel = raidFrame.ControlPanel
    if not controlPanel then
        -- BFL:DebugPrint("|cffff0000[ControlPanel] ControlPanel not found|r")
        return
    end
    
    -- BFL:DebugPrint(string.format("|cff00ffffBFL:RaidFrame:|r === ControlPanel Layout Calculation ==="))
    
    -- Get available width from ControlPanel
    local panelWidth = controlPanel:GetWidth()
    local panelHeight = controlPanel:GetHeight()
    
    -- BFL:DebugPrint(string.format("  ControlPanel size: %.1f x %.1f", panelWidth, panelHeight))
    
    -- Define layout constants
    local checkboxStartX = 35  -- Avatar clearance
    local checkboxLabelGap = 2  -- Gap between checkbox and label
    local buttonRightPadding = 3  -- Padding from right edge
    local centerElementGap = 5  -- Gap between RoleSummary and MemberCount (reduced from 8)
    
    -- Calculate dynamic Y-offset for vertical centering
    local checkboxHeight = controlPanel.EveryoneAssistCheckbox and controlPanel.EveryoneAssistCheckbox:GetHeight() or 24
    local checkboxYOffset = -((panelHeight - checkboxHeight) / 2)  -- Center vertically
    
    -- Measure actual element sizes
    local checkboxWidth = controlPanel.EveryoneAssistCheckbox and controlPanel.EveryoneAssistCheckbox:GetWidth() or 24
    local labelTextWidth = controlPanel.EveryoneAssistLabel and controlPanel.EveryoneAssistLabel:GetStringWidth() or 100
    local buttonWidth = controlPanel.RaidInfoButton and controlPanel.RaidInfoButton:GetWidth() or 90
    
    -- Reduce button width if needed
    local optimizedButtonWidth = 75  -- Reduced from 90
    
    -- Get actual text widths for center elements
    local roleSummaryWidth = controlPanel.RoleSummary and controlPanel.RoleSummary:GetStringWidth() or 90
    local memberCountWidth = controlPanel.MemberCount and controlPanel.MemberCount:GetStringWidth() or 50
    local centerSectionWidth = roleSummaryWidth + centerElementGap + memberCountWidth
    
    -- BFL:DebugPrint(string.format("  Measured widths: Checkbox=%.1f, LabelText=%.1f, Button=%.1f", 
    --     checkboxWidth, labelTextWidth, buttonWidth))
    -- BFL:DebugPrint(string.format("  Center section: RoleSummary=%.1f + gap=%.1f + MemberCount=%.1f = %.1f total", 
    --     roleSummaryWidth, centerElementGap, memberCountWidth, centerSectionWidth))
    
    -- Calculate section boundaries with actual positions
    local leftSectionEnd = checkboxStartX + checkboxWidth + checkboxLabelGap + labelTextWidth
    local rightSectionStart = panelWidth - optimizedButtonWidth - buttonRightPadding
    local availableCenter = rightSectionStart - leftSectionEnd
    
    -- Auto-hide Assist Label if space is too tight (Classic fix)
    if availableCenter < centerSectionWidth and controlPanel.EveryoneAssistLabel then
        controlPanel.EveryoneAssistLabel:Hide()
        leftSectionEnd = checkboxStartX + checkboxWidth + checkboxLabelGap -- Recalculate boundary
        availableCenter = rightSectionStart - leftSectionEnd
    elseif controlPanel.EveryoneAssistLabel then
        -- Only show if in Raid (User Request: Fix visibility)
        if IsInRaid() then
            controlPanel.EveryoneAssistLabel:Show()
        else
            controlPanel.EveryoneAssistLabel:Hide()
        end
    end
    
    -- BFL:DebugPrint(string.format("  Layout boundaries:"))
    -- BFL:DebugPrint(string.format("    Left section: %.1f to %.1f", checkboxStartX, leftSectionEnd))
    -- BFL:DebugPrint(string.format("    Right section: %.1f to %.1f (button width=%.1f)", rightSectionStart, panelWidth - buttonRightPadding, optimizedButtonWidth))
    -- BFL:DebugPrint(string.format("    Available center: %.1f (need %.1f) - %s", 
    --     availableCenter, centerSectionWidth, 
    --     availableCenter >= centerSectionWidth and "|cff00ff00OK|r" or "|cffff0000TIGHT|r"))
    
    -- Calculate center position (true center of available space)
    local centerStart = leftSectionEnd + math.max(5, (availableCenter - centerSectionWidth) / 2)

    -- Shift -3px for Classic per user request
    if not BFL.IsRetail then
        centerStart = centerStart - 5
    end
    
    -- BFL:DebugPrint(string.format("  Center section target: x=%.1f to %.1f", centerStart, centerStart + centerSectionWidth))
    
    -- Reposition EveryoneAssistCheckbox (left side, vertically centered, avoid avatar clipping)
    if controlPanel.EveryoneAssistCheckbox then
        controlPanel.EveryoneAssistCheckbox:ClearAllPoints()
        controlPanel.EveryoneAssistCheckbox:SetPoint("TOPLEFT", controlPanel, "TOPLEFT", checkboxStartX, checkboxYOffset)
        local actualX, actualY = controlPanel.EveryoneAssistCheckbox:GetCenter()
        -- BFL:DebugPrint(string.format("  ✓ EveryoneAssistCheckbox: Anchored at x=%d, y=%.1f (centered), Center=(%.1f, %.1f)", 
        --     checkboxStartX, checkboxYOffset, actualX or -1, actualY or -1))
    end
    
    -- Reposition EveryoneAssistLabel (right of checkbox)
    if controlPanel.EveryoneAssistLabel then
        controlPanel.EveryoneAssistLabel:ClearAllPoints()
        controlPanel.EveryoneAssistLabel:SetPoint("LEFT", controlPanel.EveryoneAssistCheckbox, "RIGHT", 2, 0)
        controlPanel.EveryoneAssistLabel:SetJustifyH("LEFT")
        local actualText = controlPanel.EveryoneAssistLabel:GetText()
        -- BFL:DebugPrint(string.format("  ✓ EveryoneAssistLabel: Anchored to checkbox+2, Text='%s'", 
        --     actualText or "nil"))
    end
    
    -- Reposition RaidInfoButton (right side with reduced width)
    if controlPanel.RaidInfoButton then
        controlPanel.RaidInfoButton:ClearAllPoints()
        controlPanel.RaidInfoButton:SetPoint("TOPRIGHT", controlPanel, "TOPRIGHT", -buttonRightPadding, -13)
        if not BFL.IsRetail then
            controlPanel.RaidInfoButton:SetPoint("TOPRIGHT", controlPanel, "TOPRIGHT", 2, -13)
        end
        controlPanel.RaidInfoButton:SetWidth(optimizedButtonWidth)  -- Resize button
        local actualX = controlPanel.RaidInfoButton:GetLeft()
        local actualWidth = controlPanel.RaidInfoButton:GetWidth()
        -- BFL:DebugPrint(string.format("  ✓ RaidInfoButton: Width=%.1f (optimized), x=-%.1f from right, Left edge=%.1f", 
        --     actualWidth or -1, buttonRightPadding, actualX or -1))
    end
    
    -- Reposition RoleSummary (centered in available space)
    if controlPanel.RoleSummary then
        controlPanel.RoleSummary:ClearAllPoints()
        -- Anchor to LEFT of panel, then offset to center position
        controlPanel.RoleSummary:SetPoint("LEFT", controlPanel, "LEFT", centerStart, 0)
        controlPanel.RoleSummary:SetJustifyH("LEFT")
        
        local actualX = controlPanel.RoleSummary:GetLeft()
        local actualText = controlPanel.RoleSummary:GetText()
        local actualStringWidth = controlPanel.RoleSummary:GetStringWidth()
        -- BFL:DebugPrint(string.format("  ✓ RoleSummary: Target x=%.1f, Actual x=%.1f, StringWidth=%.1f, Text='%s'", 
        --     centerStart, actualX or -1, actualStringWidth, actualText or "nil"))
    end
    
    -- Reposition MemberCount (right of RoleSummary with reduced gap)
    if controlPanel.MemberCount then
        controlPanel.MemberCount:ClearAllPoints()
        controlPanel.MemberCount:SetPoint("LEFT", controlPanel.RoleSummary, "RIGHT", centerElementGap, 0)
        controlPanel.MemberCount:SetJustifyH("LEFT")
        
        local actualX = controlPanel.MemberCount:GetLeft()
        local actualText = controlPanel.MemberCount:GetText()
        local actualStringWidth = controlPanel.MemberCount:GetStringWidth()
        -- BFL:DebugPrint(string.format("  ✓ MemberCount: Gap=%.1f, Actual x=%.1f, StringWidth=%.1f, Text='%s'", 
        --     centerElementGap, actualX or -1, actualStringWidth, actualText or "nil"))
    end
    
    -- Reposition CombatIcon (if visible, between counts and button)
    if controlPanel.CombatIcon then
        controlPanel.CombatIcon:ClearAllPoints()
        controlPanel.CombatIcon:SetPoint("RIGHT", controlPanel.RaidInfoButton, "LEFT", -5, -1)
        -- BFL:DebugPrint(string.format("  CombatIcon: Anchored to RaidInfoButton, offset=-5"))
    end
    
    -- BFL:DebugPrint("|cff00ff00ControlPanel layout completed|r")
end

-- ========================================
-- SECURE PROXY SYSTEM (Phase 8.3)
-- ========================================



--- Create the detached secure proxy button
--- Uses modern Blizzard pattern with secure action types for Main Tank/Assist
--- Reference: SecureTemplates.lua SECURE_ACTIONS.maintank and SECURE_ACTIONS.mainassist
function RaidFrame:CreateSecureProxy()
    if self.SecureProxy then return end
    
    -- Create the proxy frame
    -- CRITICAL: Parent must be UIParent to avoid tainting the addon frame
    local proxy = CreateFrame("Button", "BFL_RaidFrame_SecureProxy", UIParent, "InsecureActionButtonTemplate")
    
    -- Visual properties
    proxy:SetFrameStrata("DIALOG") -- High strata to sit above everything
    proxy:SetFrameLevel(9999) -- Ensure it is absolutely on top
    proxy:Hide() -- Hidden by default
    
    -- Add Highlight Texture to Proxy
    local highlight = proxy:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
    highlight:SetBlendMode("ADD")
    highlight:SetAllPoints(proxy)
    proxy:SetHighlightTexture(highlight)
    
    -- Register clicks
    proxy:RegisterForClicks("AnyUp", "AnyDown")
    
    -- Script Handlers
    proxy:SetScript("OnEnter", function(self)
        -- Just update display properties - menu handling is done via frame.menu callback
        local unit = self:GetAttribute("unit")
        if unit then
            local name = UnitName(unit)
            self.unit = unit
            self.name = name
            self.id = tonumber(string.match(unit, "raid(%d+)"))
            
            -- Copy visual button properties for Drag/Drop compatibility
            if self.visualButton then
                self.groupIndex = self.visualButton.groupIndex
                self.slotIndex = self.visualButton.slotIndex
            end
            
            -- BFL:DebugPrint("Proxy OnEnter: name=" .. tostring(name) .. " unit=" .. tostring(unit))
        end
        
        -- Show tooltip
        if self.unit then pcall(UnitFrame_UpdateTooltip, self) end
    end)
    
    proxy:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
        self:Hide()
        self:ClearAllPoints()
        self.visualButton = nil
        self.unit = nil
        self.groupIndex = nil
        self.slotIndex = nil
    end)
    
    -- Drag Support (Forwarding)
    proxy:RegisterForDrag("LeftButton")
    proxy:SetScript("OnDragStart", function(self)
        if self.visualButton and BetterRaidMemberButton_OnDragStart then
            BetterRaidMemberButton_OnDragStart(self.visualButton)
        end
    end)
    proxy:SetScript("OnDragStop", function(self)
        if BetterRaidMemberButton_OnDragStop then
            -- We pass visualButton because OnDragStop might rely on its object identity
            BetterRaidMemberButton_OnDragStop(self.visualButton or self)
        end
    end)
    
    -- Combat Protection
    -- Force hide when entering combat
    proxy:RegisterEvent("PLAYER_REGEN_DISABLED")
    proxy:SetScript("OnEvent", function(self, event)
        if event == "PLAYER_REGEN_DISABLED" then
            self:Hide()
            self:ClearAllPoints()
            self.visualButton = nil
        end
    end)
    
    -- PostClick Handler for Custom Actions
    proxy:SetScript("PostClick", function(self, button)
        if InCombatLockdown() then return end
        
        -- Resolve modifier prefix
        local prefix = ""
        if IsShiftKeyDown() then prefix = "shift-" .. prefix end
        if IsControlKeyDown() then prefix = "ctrl-" .. prefix end
        if IsAltKeyDown() then prefix = "alt-" .. prefix end
        
        -- Map button string to suffix number or *
        local btnSuffix = "1"
        if button == "RightButton" then btnSuffix = "2"
        elseif button == "MiddleButton" then btnSuffix = "3"
        elseif button == "Button4" then btnSuffix = "4"
        elseif button == "Button5" then btnSuffix = "5"
        end
        
        -- Check generic action then specific action
        local action = self:GetAttribute(prefix.."bfl-action"..btnSuffix) or self:GetAttribute("bfl-action"..btnSuffix) or self:GetAttribute("*bfl-action"..btnSuffix)
        
        if action then
            RaidFrame:PerformCustomAction(action, self.unit)
        elseif button == "LeftButton" then
            -- Fallback Logic: Restore original behavior when click is trapped but not assigned
            if IsControlKeyDown() then
                -- Ctrl+LeftClick: Toggle Single Selection (Restore Logic)
                local raidIndex = tonumber(string.match(self.unit, "raid(%d+)"))
                if raidIndex and BetterRaidFrame_SelectedPlayers and self.name then
                    -- Check if selected
                    local selectedIndex = nil
                    for i, data in ipairs(BetterRaidFrame_SelectedPlayers) do
                        if data.raidIndex == raidIndex then
                            selectedIndex = i
                            break
                        end
                    end
                    
                    if selectedIndex then
                        table.remove(BetterRaidFrame_SelectedPlayers, selectedIndex)
                        RaidFrame:SetButtonSelectionHighlight(raidIndex, false)
                    else
                        local _, _, subgroup = GetRaidRosterInfo(raidIndex)
                        table.insert(BetterRaidFrame_SelectedPlayers, {
                            raidIndex = raidIndex,
                            groupIndex = subgroup,
                            unit = self.unit,
                            name = self.name
                        })
                        RaidFrame:SetButtonSelectionHighlight(raidIndex, true)
                    end
                end
            elseif not prefix:find("-") then
                -- Normal LeftClick: Select for display + Clear multi-select
                if BetterRaidFrame_SelectedPlayers then
                    for _, data in ipairs(BetterRaidFrame_SelectedPlayers) do
                         RaidFrame:SetButtonSelectionHighlight(data.raidIndex, false)
                    end
                    wipe(BetterRaidFrame_SelectedPlayers)
                end
                
                if self.name then
                    RaidFrame:SetSelectedMember(self.name)
                    RaidFrame:RefreshMemberButtons() -- Update highlights
                end
            end
        end
    end)
    
    self.SecureProxy = proxy
    
    -- Initial setup
    self:UpdateSecureAttributes()
end

--- Apply configured shortcuts to Secure Proxy
function RaidFrame:UpdateSecureAttributes()
    local proxy = self.SecureProxy
    if not proxy then return end
    if InCombatLockdown() then return end -- Cannot update in combat
    
    local DB = BFL and BFL:GetModule("DB")
    local enabled = true -- Global toggle removed, always check individually
    local shortcuts = DB and DB:Get("raidShortcuts") or {}
    
    -- ALWAYS clear attributes first to ensure clean state
    for _, mod in ipairs({"", "shift-", "ctrl-", "alt-", "shift-ctrl-", "shift-alt-", "ctrl-alt-"}) do
        for i = 1, 5 do
            proxy:SetAttribute(mod.."type"..i, nil)
            proxy:SetAttribute(mod.."action"..i, nil)
            proxy:SetAttribute(mod.."bfl-action"..i, nil)
        end
    end
    proxy:SetAttribute("*type1", nil)
    proxy:SetAttribute("*type2", "togglemenu") -- Default Right Click Menu
    proxy:SetAttribute("type2", "togglemenu") 
    proxy:SetAttribute("*type3", nil)
    
    -- Track secure buttons to manage PassThrough
    local secureButtons = {}
    
    -- Apply shortcuts
    for actionKey, data in pairs(shortcuts) do
        -- Check if this specific shortcut is enabled
        if DB:Get("raidShortcutEnabled_" .. actionKey, true) then
            local modifier = data.modifier
            local button = data.button
            
            if button then
                -- Map to prefix
                local modPrefix = ""
                if modifier == "SHIFT" then modPrefix = "shift-"
                elseif modifier == "CTRL" then modPrefix = "ctrl-"
                elseif modifier == "ALT" then modPrefix = "alt-"
                elseif modifier == "SHIFT-CTRL" then modPrefix = "shift-ctrl-"
                elseif modifier == "SHIFT-ALT" then modPrefix = "shift-alt-"
                elseif modifier == "CTRL-ALT" then modPrefix = "ctrl-alt-"
                end
                
                -- Map to suffix
                local btnID = 1
                if button == "RightButton" then btnID = 2
                elseif button == "Button3" then btnID = 3
                elseif button == "Button4" then btnID = 4
                elseif button == "Button5" then btnID = 5
                end
                
                -- Apply
                if actionKey == "mainTank" then
                    proxy:SetAttribute(modPrefix.."type"..btnID, "maintank")
                    proxy:SetAttribute(modPrefix.."action"..btnID, "toggle")
                    secureButtons[button] = true
                elseif actionKey == "mainAssist" then
                    proxy:SetAttribute(modPrefix.."type"..btnID, "mainassist")
                    proxy:SetAttribute(modPrefix.."action"..btnID, "toggle")
                    secureButtons[button] = true
                elseif actionKey == "lead" then
                    proxy:SetAttribute(modPrefix.."bfl-action"..btnID, "lead")
                    proxy:SetAttribute(modPrefix.."type"..btnID, "macro") -- Prevent menu fallback
                    proxy:SetAttribute(modPrefix.."macrotext"..btnID, "")
                    secureButtons[button] = true
                elseif actionKey == "promote" then
                    proxy:SetAttribute(modPrefix.."bfl-action"..btnID, "promote")
                    proxy:SetAttribute(modPrefix.."type"..btnID, "macro") -- Prevent menu fallback
                    proxy:SetAttribute(modPrefix.."macrotext"..btnID, "")
                    secureButtons[button] = true
                end
            end
        end
    end
    
    -- Manage PassThroughButtons
    -- If LeftButton has bindings, we cannot PassThrough, so we rely on PostClick for default Select
    local pass = {}
    if not secureButtons["LeftButton"] then 
        table.insert(pass, "LeftButton") 
    end
    
    if proxy.SetPassThroughButtons then
        proxy:SetPassThroughButtons(unpack(pass))
    end
end

--- Execute custom non-secure actions
function RaidFrame:PerformCustomAction(action, unit)
    if not unit or not UnitExists(unit) then return end
    local name = UnitName(unit)
    
    if action == "lead" then
        PromoteToLeader(unit)
    elseif action == "promote" then
        if UnitIsGroupAssistant(unit) then
             DemoteAssistant(unit)
        else
             PromoteToAssistant(unit)
        end
    end
end

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
    
    -- Register events for roster updates
    self:RegisterEvents()
    
    -- Initialize member buttons (XML templates)
    self:InitializeMemberButtons()
    
    -- Initialize Secure Proxy (Phase 8.3)
    self:CreateSecureProxy()
    
    -- Localize Static UI Elements
    local frame = BetterFriendsFrame and BetterFriendsFrame.RaidFrame
    if frame then
        -- Localize empty state text
        if frame.NotInRaid then
            frame.NotInRaid:SetText(L.RAID_NOT_IN_RAID_DETAILS)
        end
        
        -- Localize control panel buttons
        if frame.ControlPanel and frame.ControlPanel.ConvertToRaidButton then
            frame.ControlPanel.ConvertToRaidButton:SetText(L.RAID_CREATE_BUTTON)
        end
    end
    
    -- Initial update of control panel (this will set label too)
    self:UpdateControlPanel()
    self:UpdateGroupLayout() -- Ensure layout matches Mock (responsive sizing)
    self:UpdateConvertButton() -- Initial update of convert button
    
    -- Hook OnShow to re-render if data changed while hidden
    if BetterFriendsFrame then
        BetterFriendsFrame:HookScript("OnShow", function()
            -- Always update if we have no data, or if dirty flag is set
            if needsRenderOnShow or #self.raidMembers == 0 then
                -- BFL:DebugPrint("|cff00ffffRaidFrame:|r Frame shown - triggering refresh")
                self:OnRaidRosterUpdate()
                needsRenderOnShow = false
            end
        end)
    end
    
    -- BFL:DebugPrint("[BFL] RaidFrame initialized")
end

-- ========================================
-- CONVERT BUTTON LOGIC
-- ========================================

--- Update the Convert to Raid/Party button state
function RaidFrame:UpdateConvertButton()
    local frame = BetterFriendsFrame and BetterFriendsFrame.RaidFrame
    if not frame or not frame.ConvertToRaidButton then
        return
    end
    
    local button = frame.ConvertToRaidButton
    local canControl = self:CanControlRaid() or (not IsInGroup()) -- Can create if solo
    local inRaid = IsInRaid()
    local inGroup = IsInGroup()
    local numMembers = GetNumGroupMembers()
    
    -- Update Text
    if inRaid then
        button:SetText(L.RAID_CONVERT_TO_PARTY or "Convert to Party")
    else
        button:SetText(L.RAID_CONVERT_TO_RAID or "Convert to Raid")
    end
    
    -- Update Enabled State
    if inRaid then
        -- Can only convert to party if <= 5 members and is leader
        if canControl and numMembers <= 5 then
            button:Enable()
            button.tooltip = nil
        else
            button:Disable()
            if not canControl then
                button.tooltip = L.RAID_MUST_BE_LEADER or "You must be the leader to do that"
            else
                button.tooltip = L.RAID_CONVERT_TOO_MANY or "Group creates too many players for a party"
            end
        end
    elseif inGroup then
        -- Can convert to raid if leader
        if canControl then
            button:Enable()
            button.tooltip = nil
        else
            button:Disable()
            button.tooltip = L.RAID_MUST_BE_LEADER or "You must be the leader to do that"
        end
    else
        -- Solo - can convert to raid (creates raid of 1) - wait, standard UI allows this?
        -- Yes, "Convert to Raid" is usually available to start a raid group.
        -- Actually, standard UI shows "Convert to Raid" only when in a party.
        -- But let's check standard behavior. Usually needs to be in a group.
        -- If solo, button should probably be disabled or act as "Form Group" (but that's different).
        
        -- Disable if solo
        button:Disable()
        button.tooltip = L.RAID_ERR_NOT_IN_GROUP or "You are not in a group"
    end
end

--- Handle Convert Button Click
function RaidFrame:ConvertToRaidOrParty()
    if IsInRaid() then
        -- Try to convert to Party
        if not self:ConvertToParty() then
             -- Error handling usually in ConvertToParty return or standard UI error
        end
    else
        -- Try to convert to Raid
        if not self:ConvertToRaid() then
            -- Error handling
        end
    end
    
    -- Force immediate update
    self:UpdateConvertButton()
end

-- Global Click Handler
function BetterRaidFrame_ConvertToRaidButton_OnClick(self)
    -- Use BFL.RaidFrame reference
    local RaidFrame = BFL:GetModule("RaidFrame")
    if RaidFrame then
        RaidFrame:ConvertToRaidOrParty()
    end
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
    
    -- Phase 8.2: Combat event to clear multi-selections
    BFL:RegisterEventCallback("PLAYER_REGEN_DISABLED", function(...)
        RaidFrame:OnCombatStart(...)
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
                role = role,  -- "MAINTANK", "MAINASSIST" or nil (raid assignment)
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

--- Cache font settings from DB to avoid repetitive lookups
function RaidFrame:CacheFontSettings()
    local db = BetterFriendlistDB or {}
    
    -- Determine default font props
    local defaultFontName, defaultFontSize, defaultFontOutline = _G.GameFontNormal:GetFont()
    
    -- Raid Name Text Settings
    local fontName = db.fontRaidName or defaultFontName
    local fontSize = db.fontSizeRaidName or defaultFontSize or 10
    local fontOutline = db.fontOutlineRaidName or "NORMAL"
    local fontShadow = db.fontShadowRaidName -- boolean
    
    -- Map outline
    local outlineValue = ""
    if fontOutline == "THINOUTLINE" then outlineValue = "OUTLINE" 
    elseif fontOutline == "THICKOUTLINE" then outlineValue = "THICKOUTLINE"
    elseif fontOutline == "MONOCHROME" then outlineValue = "MONOCHROME"
    end
    
    -- Resolve path
    local SharedMedia = LibStub and LibStub("LibSharedMedia-3.0", true)
    local fontPath = fontName
    if SharedMedia then
        -- Only fetch if it looks like a name, not a path
        if not fontName:find("\\") then
            fontPath = SharedMedia:Fetch("font", fontName) or fontName
        end
    end
    
    self.fontCache = {
        name = { path = fontPath, size = fontSize, outline = outlineValue, shadow = fontShadow }
    }
end

--- Update all member buttons in the UI
function RaidFrame:UpdateAllMemberButtons()
    local frame = BetterFriendsFrame and BetterFriendsFrame.RaidFrame
    if not frame then
        return
    end
    
    -- Update font cache before processing buttons
    self:CacheFontSettings()
    
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
            groupFrame.GroupTitle:SetText(string.format(L.RAID_GROUP_NAME, groupIndex))
        end
        
        -- Update each slot in the group using self.memberButtons[]
        local members = membersByGroup[groupIndex]
        local hasGroupMembers = #members > 0
        
        -- Always show group frame (User Request: Fix visibility)
        if groupFrame then
            groupFrame:Show()
        end
        
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
                groupFrame.GroupTitle:SetText(string.format(L.RAID_GROUP_NAME, groupIndex))
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
                    
                    -- Note: Secure Proxy Link is handled by BetterRaidMemberButton_OnEnter in RaidFrameCallbacks.lua
                    -- We don't need to hook it here anymore.
                end
            end
        end
    end
end

--- Update all member buttons based on current raid roster
function RaidFrame:UpdateMemberButtons()
    if not self.memberButtons or not self.raidMembers then return end
    
    -- Ensure fonts are cached
    self:CacheFontSettings()
    
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
    
    -- Update Main Tank / Main Assist icons (raid role assignment)
    if button.MainTankIcon then
        if member.role == "MAINTANK" then
            button.MainTankIcon:Show()
        else
            button.MainTankIcon:Hide()
        end
    end
    
    if button.MainAssistIcon then
        if member.role == "MAINASSIST" then
            button.MainAssistIcon:Show()
        else
            button.MainAssistIcon:Hide()
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
        -- BFL:DebugPrint("[BFL] UpdateMemberCount: Frame check failed - frame=" .. tostring(frame) .. ", ControlPanel=" .. tostring(frame and frame.ControlPanel) .. ", MemberCount=" .. tostring(frame and frame.ControlPanel and frame.ControlPanel.MemberCount))
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
    -- BFL:DebugPrint("[BFL] UpdateMemberCount: Setting text to '" .. textToSet .. "' (numMembers=" .. numMembers .. ")")
    frame.ControlPanel.MemberCount:SetText(textToSet)
    local actualText = frame.ControlPanel.MemberCount:GetText()
    -- BFL:DebugPrint("[BFL] UpdateMemberCount: Actual text after SetText: '" .. tostring(actualText) .. "'")
	
	-- Trigger layout update to recalculate centering with new string width
	self:UpdateControlPanelLayout()
end

--- Update Control Panel (role summary, member count, assist label)
function RaidFrame:UpdateControlPanel()
    local frame = BetterFriendsFrame and BetterFriendsFrame.RaidFrame
    if not frame or not frame.ControlPanel then
        return
    end
    
    -- BFL:DebugPrint("[BFL] UpdateControlPanel called")
    
    -- Set Assist All label if not already set
    if frame.ControlPanel.EveryoneAssistLabel then
        local currentText = frame.ControlPanel.EveryoneAssistLabel:GetText()
        if not currentText or currentText == "" then
            local ASSIST_ICON = "|TInterface\\GroupFrame\\UI-Group-AssistantIcon:14:14|t"
            frame.ControlPanel.EveryoneAssistLabel:SetText(L.ALL .. " " .. ASSIST_ICON)
            -- BFL:DebugPrint("[BFL] Assist All label set: All " .. ASSIST_ICON)
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
    local iconSize = 14 -- Reduced from 16 for better fit in Classic
    
    local tankIcon = GetRoleIconString("TANK", iconSize)
    local healIcon = GetRoleIconString("HEALER", iconSize)
    local dpsIcon = GetRoleIconString("DAMAGER", iconSize)
    
    local text = string.format("%s %d  %s %d  %s %d", tankIcon, tanks, healIcon, healers, dpsIcon, dps)
    frame.ControlPanel.RoleSummary:SetText(text)
	
	-- Trigger layout update to recalculate centering with new string width
	self:UpdateControlPanelLayout()
end

--- Update a single member button with raid member data
-- @param button: The button frame to update
-- @param memberData: Table with member info (name, class, level, rank, role, etc.) - can be nil for empty slot
function RaidFrame:UpdateMemberButton(button, memberData)
    if not button then return end
    
    -- Always show button frame (User Request: NEVER hide buttons)
    button:Show()
    
    -- If no member data, clear content and return
    if not memberData then
        button.memberData = nil
        
        -- CRITICAL: Clear button properties for callbacks (prevent stale data)
        button.unit = nil
        button.name = nil
        button.raidSlot = nil
        
        -- Clear visuals
        if button.Name then button.Name:SetText("") end
        if button.Level then button.Level:SetText(""); button.Level:Hide() end
        if button.ClassIcon then button.ClassIcon:Hide() end
        if button.RankIcon then button.RankIcon:Hide() end
        if button.RoleIcon then button.RoleIcon:Hide() end
        if button.MainTankIcon then button.MainTankIcon:Hide() end
        if button.MainAssistIcon then button.MainAssistIcon:Hide() end
        if button.ReadyCheckIcon then button.ReadyCheckIcon:Hide() end
        if button.ClassColorTint then button.ClassColorTint:SetColorTexture(0.1, 0.1, 0.1, 0.5) end
        
        -- Show "Empty" text
        if button.EmptyText then
            button.EmptyText:SetText(L.EMPTY_TEXT)
            button.EmptyText:Show()
        end
        
        return
    end
    
    -- Show button when occupied
    button:Show()
    
    -- Hide "Empty" text when slot is occupied
    if button.EmptyText then button.EmptyText:Hide() end
    
    -- CRITICAL FIX: Reset all visual elements FIRST to prevent stale data display
    -- This fixes issues where old values remain visible after member swap
    if button.Name then button.Name:SetText("") end
    if button.Level then button.Level:SetText(""); button.Level:Hide() end
    if button.ClassIcon then button.ClassIcon:Hide() end
    if button.RankIcon then button.RankIcon:Hide() end
    if button.RoleIcon then button.RoleIcon:Hide() end
    if button.MainTankIcon then button.MainTankIcon:Hide() end
    if button.MainAssistIcon then button.MainAssistIcon:Hide() end
    if button.ReadyCheckIcon then button.ReadyCheckIcon:Hide() end
    
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
        if FontManager then
            FontManager:ApplyFontSize(button.Level)
        end
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
        local displayName = memberData.name or ""
        if displayName:find("-") then
            displayName = strsplit("-", displayName)
        end
        button.Name:SetText(displayName)
        
        -- Apply cached raid font
        if self.fontCache and self.fontCache.name then
            local fc = self.fontCache.name
            button.Name:SetFont(fc.path, fc.size, fc.outline)
            
            if fc.shadow then
                button.Name:SetShadowOffset(1, -1)
            else
                button.Name:SetShadowOffset(0, 0)
            end
        elseif FontManager then
            -- Fallback
            FontManager:ApplyFontSize(button.Name)
        end
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
    -- FIX: Always fetch fresh from API if unit available, fallback to stored role field
    -- This fixes the combatRole vs role field mismatch after group swaps
    local combatRole = memberData.unit and UnitGroupRolesAssigned(memberData.unit) or memberData.role
    if combatRole and combatRole ~= "NONE" then
        if combatRole == "TANK" then
            button.RoleIcon:SetAtlas("UI-LFG-RoleIcon-Tank-Micro-GroupFinder")
            button.RoleIcon:Show()
        elseif combatRole == "HEALER" then
            button.RoleIcon:SetAtlas("UI-LFG-RoleIcon-Healer-Micro-GroupFinder")
            button.RoleIcon:Show()
        elseif combatRole == "DAMAGER" then
            button.RoleIcon:SetAtlas("UI-LFG-RoleIcon-DPS-Micro-GroupFinder")
            button.RoleIcon:Show()
        else
            button.RoleIcon:Hide()
        end
    else
        button.RoleIcon:Hide()
    end
    
    -- Update Main Tank / Main Assist Icons (raid role assignment)
    if button.MainTankIcon then
        if memberData.role == "MAINTANK" then
            button.MainTankIcon:Show()
        else
            button.MainTankIcon:Hide()
        end
    end
    
    if button.MainAssistIcon then
        if memberData.role == "MAINASSIST" then
            button.MainAssistIcon:Show()
        else
            button.MainAssistIcon:Hide()
        end
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
        -- BFL:DebugPrint("[BFL] UpdateCombatOverlay: No member buttons")
        return 
    end
    
    -- Use passed parameter or query current state
    local combatState = inCombat
    if combatState == nil then
        combatState = InCombatLockdown()
    end
    local buttonsUpdated = 0
    
    -- BFL:DebugPrint("[BFL] RaidFrame:UpdateCombatOverlay START - combatState: " .. tostring(combatState) .. " (param was: " .. tostring(inCombat) .. ")")
    -- BFL:DebugPrint("[BFL] memberButtons structure: " .. tostring(self.memberButtons) .. ", type: " .. type(self.memberButtons))
    
    for groupIndex = 1, 8 do
        if self.memberButtons[groupIndex] then
            -- BFL:DebugPrint("[BFL] Processing group " .. groupIndex)
            for slotIndex = 1, 5 do
                local button = self.memberButtons[groupIndex][slotIndex]
                if button then
                    local isShown = button:IsShown()
                    -- BFL:DebugPrint("[BFL] Button [" .. groupIndex .. "][" .. slotIndex .. "] - IsShown: " .. tostring(isShown) .. ", HasOverlay: " .. tostring(button.CombatOverlay ~= nil))
                    
                    -- Ensure CombatOverlay exists
                    if not button.CombatOverlay then
                        -- BFL:DebugPrint("[BFL] Button [" .. groupIndex .. "][" .. slotIndex .. "] missing CombatOverlay!")
                    else
                        if combatState and isShown then
                            button.CombatOverlay:Show()
                            buttonsUpdated = buttonsUpdated + 1
                            -- BFL:DebugPrint("[BFL] Showed overlay on button [" .. groupIndex .. "][" .. slotIndex .. "]")
                        else
                            button.CombatOverlay:Hide()
                            -- BFL:DebugPrint("[BFL] Hid overlay on button [" .. groupIndex .. "][" .. slotIndex .. "] (combatState=" .. tostring(combatState) .. ", isShown=" .. tostring(isShown) .. ")")
                        end
                    end
                end
            end
        end
    end
    
    -- BFL:DebugPrint("[BFL] Combat overlay updated on " .. buttonsUpdated .. " buttons (out of 40 possible)")
end

-- ========================================
-- MULTI-SELECT VISUAL HIGHLIGHTS (Phase 8.2)
-- ========================================

--- Set drag highlight on a specific raid member button
--- @param raidIndex number The raid index (raid1 = 1, raid2 = 2, etc.)
--- @param isDragging boolean Whether to show or hide drag highlight
function RaidFrame:SetButtonDragHighlight(raidIndex, isDragging)
    if not self.memberButtons then return end
    
    -- Find the button with this raidIndex
    for groupIndex = 1, 8 do
        if self.memberButtons[groupIndex] then
            for slotIndex = 1, 5 do
                local button = self.memberButtons[groupIndex][slotIndex]
                if button and button.unit then
                    local buttonRaidIndex = tonumber(string.match(button.unit, "raid(%d+)"))
                    if buttonRaidIndex == raidIndex then
                        -- Found the button, update highlight
                        if not button.DragHighlight then
                            -- Create drag highlight texture (same as selection but more visible)
                            button.DragHighlight = button:CreateTexture(nil, "OVERLAY")
                            button.DragHighlight:SetAllPoints()
                            button.DragHighlight:SetColorTexture(1.0, 0.843, 0.0, 0.5) -- Gold with 50% alpha (brighter than selection)
                            button.DragHighlight:SetBlendMode("ADD")
                        end
                        
                        if isDragging then
                            button.DragHighlight:Show()
                        else
                            button.DragHighlight:Hide()
                        end
                        return
                    end
                end
            end
        end
    end
end

--- Set selection highlight on a specific raid member button
--- @param raidIndex number The raid index (raid1 = 1, raid2 = 2, etc.)
--- @param isSelected boolean Whether to show or hide highlight
function RaidFrame:SetButtonSelectionHighlight(raidIndex, isSelected)
    if not self.memberButtons then return end
    
    -- Find the button with this raidIndex
    for groupIndex = 1, 8 do
        if self.memberButtons[groupIndex] then
            for slotIndex = 1, 5 do
                local button = self.memberButtons[groupIndex][slotIndex]
                if button and button.unit then
                    local buttonRaidIndex = tonumber(string.match(button.unit, "raid(%d+)"))
                    if buttonRaidIndex == raidIndex then
                        -- Found the button, update highlight
                        if button.SelectionHighlight then
                            if isSelected then
                                button.SelectionHighlight:Show()
                            else
                                button.SelectionHighlight:Hide()
                            end
                        else
                            -- Create highlight texture if it doesn't exist
                            if not button.SelectionHighlight then
                                button.SelectionHighlight = button:CreateTexture(nil, "OVERLAY")
                                button.SelectionHighlight:SetAllPoints()
                                button.SelectionHighlight:SetColorTexture(1.0, 0.843, 0.0, 0.4) -- Gold with 40% alpha
                                button.SelectionHighlight:SetBlendMode("ADD")
                            end
                            
                            if isSelected then
                                button.SelectionHighlight:Show()
                            else
                                button.SelectionHighlight:Hide()
                            end
                        end
                        return
                    end
                end
            end
        end
    end
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
    -- Visibility Optimization:
    -- If the frame is hidden, we don't need to fetch data or rebuild the list.
    -- Just mark it as dirty so it updates when shown.
    if not BetterFriendsFrame or not BetterFriendsFrame:IsShown() then
        needsRenderOnShow = true
        return
    end

    -- Event Coalescing (Micro-Throttling)
    if self.updateTimer then
        return
    end
    
    -- Increase delay to 0.1s to ensure WoW API has updated data
    -- This fixes issues where new members aren't visible immediately
    self.updateTimer = C_Timer.After(0.1, function()
        self.updateTimer = nil
        
        -- Immediate update for crisp UI response
        self:UpdateRaidMembers()
        self:BuildDisplayList()
        
        -- Update UI
        -- Note: UpdateGroupLayout calls UpdateAllMemberButtons internally
        self:UpdateControlPanel()
        self:UpdateGroupLayout()
        self:UpdateConvertButton()
        
        -- Central Update Logic (Restored)
        if BetterRaidFrame_Update then
            BetterRaidFrame_Update()
        end
    end)
end

function RaidFrame:OnGroupJoined(...)
    -- Use the throttled update to ensure data consistency
    self:OnRaidRosterUpdate(...)
end

function RaidFrame:OnGroupLeft(...)
    -- Clear member list
    wipe(self.raidMembers)
    wipe(self.displayList)
    self.selectedMember = nil
    
    -- Update UI to clear buttons
    self:UpdateAllMemberButtons()
    self:UpdateControlPanel()
    self:UpdateGroupLayout()
    self:UpdateConvertButton()
    
    if BetterRaidFrame_Update then
        BetterRaidFrame_Update()
    end
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
-- PHASE 8.2: MULTI-SELECT EVENT HANDLERS
-- ========================================

--- Handle combat start - clear all multi-selections
function RaidFrame:OnCombatStart()
    -- Clear selections via global function in RaidFrameCallbacks.lua
    if BetterRaidFrame_SelectedPlayers and #BetterRaidFrame_SelectedPlayers > 0 then
        -- Clear visual highlights
        for _, playerData in ipairs(BetterRaidFrame_SelectedPlayers) do
            self:SetButtonSelectionHighlight(playerData.raidIndex, false)
        end
        
        -- Clear state
        BetterRaidFrame_SelectedPlayers = {}
        
        -- Yellow warning toast
        UIErrorsFrame:AddMessage(
            L.MSG_MULTI_SELECTION_CLEARED,
            1.0, 0.8, 0.0, 1.0
        )
    end
end

-- ========================================
-- PROFESSIONAL MOCK SYSTEM (Debug/Testing)
-- ========================================
--[[
	Purpose: Simulate raid groups for testing RaidFrame functionality
	without requiring actual raid members.
	
	Design Principles:
	1. Mock data follows EXACT WoW raid structure
	2. Realistic player names, classes, and roles
	3. Dynamic updates simulate real raid activity
	4. Event simulation for testing event handlers
	5. Comprehensive presets for different scenarios
	
	Commands:
	- /bfl raid mock           - Create 25-player raid (5 groups)
	- /bfl raid mock full      - Create full 40-player raid (8 groups)
	- /bfl raid mock small     - Create 10-player raid (2 groups)
	- /bfl raid mock mythic    - Create 20-player mythic raid (4 groups)
	- /bfl raid mock stress    - Create 40 players with rapid changes
	- /bfl raid event readycheck - Simulate ready check
	- /bfl raid event rolechange - Simulate role changes
	- /bfl raid event move      - Simulate player group moves
	- /bfl raid config         - Show/set mock configuration
	- /bfl raid clear          - Remove mock data
]]

-- ============================================
-- MOCK SYSTEM CONSTANTS
-- ============================================

-- Realistic player names (lore characters + common MMO names)
local MOCK_PLAYER_NAMES = {
	-- Alliance Heroes
	"Anduin", "Jaina", "Genn", "Alleria", "Turalyon", "Velen", "Tyrande", "Malfurion",
	"Muradin", "Mekkatorque", "Aysa", "Tess", "Shaw", "Magni", "Khadgar", "Valeera",
	-- Horde Heroes
	"Thrall", "Baine", "Lor'themar", "Thalyssra", "Gazlowe", "Ji", "Rokhan", 
	"Geya'rah", "Calia", "Eitrigg", "Rexxar", "Zekhan", "Lilian",
	-- Neutral/Other
	"Chromie", "Wrathion", "Alexstrasza", "Ysera", "Nozdormu", "Kalecgos", "Ebonhorn",
	-- Common MMO-style Names
	"Shadowblade", "Lightforge", "Stormwind", "Ironhammer", "Darkflame", "Frostweaver",
	"Sunfire", "Moonshade", "Earthshaker", "Windwalker", "Bloodfang", "Steelclaw",
	"VeryLongNamePleaseTruncateMeCorrectlyOrResizeMeIfYouCanDoThatWithoutBreakingLayout"
}

-- Class data with role assignments
local MOCK_CLASSES = {
	{name = "Warrior", file = "WARRIOR", roles = {"TANK", "DAMAGER"}},
	{name = "Paladin", file = "PALADIN", roles = {"TANK", "HEALER", "DAMAGER"}},
	{name = "Hunter", file = "HUNTER", roles = {"DAMAGER"}},
	{name = "Rogue", file = "ROGUE", roles = {"DAMAGER"}},
	{name = "Priest", file = "PRIEST", roles = {"HEALER", "DAMAGER"}},
	{name = "Shaman", file = "SHAMAN", roles = {"HEALER", "DAMAGER"}},
	{name = "Mage", file = "MAGE", roles = {"DAMAGER"}},
	{name = "Warlock", file = "WARLOCK", roles = {"DAMAGER"}},
	{name = "Monk", file = "MONK", roles = {"TANK", "HEALER", "DAMAGER"}},
	{name = "Druid", file = "DRUID", roles = {"TANK", "HEALER", "DAMAGER"}},
	{name = "Demon Hunter", file = "DEMONHUNTER", roles = {"TANK", "DAMAGER"}},
	{name = "Death Knight", file = "DEATHKNIGHT", roles = {"TANK", "DAMAGER"}},
	{name = "Evoker", file = "EVOKER", roles = {"HEALER", "DAMAGER"}},
}

-- Zone names for variety
local MOCK_ZONES = {
	"Dornogal", "The Ringing Deeps", "Hallowfall", "Azj-Kahet", "Isle of Dorn",
	"City of Threads", "Priory of the Sacred Flame", "Cinderbrew Meadery",
	"The Stonevault", "The Dawnbreaker", "Ara-Kara, City of Echoes",
	"Nerub-ar Palace", "Grim Batol", "Siege of Boralus"
}

-- ============================================
-- MOCK SYSTEM STATE
-- ============================================

RaidFrame.mockEnabled = false           -- Is mock mode active?
RaidFrame.mockUpdateTimer = nil         -- Timer for dynamic updates
RaidFrame.mockConfig = {
	dynamicUpdates = true,              -- Enable/disable dynamic changes
	updateInterval = 5.0,               -- Seconds between dynamic updates
	readyCheckDuration = 35,            -- Ready check duration (seconds)
}

-- ============================================
-- MOCK MEMBER CREATION
-- ============================================

--[[
	Create a single mock raid member
	@param index: Raid index (1-40)
	@param name: Player name
	@param classInfo: Class data table
	@param subgroup: Group number (1-8)
	@param role: Combat role (TANK, HEALER, DAMAGER, NONE)
	@param rank: Raid rank (0=member, 1=assistant, 2=leader)
	@param options: Additional options (online, isDead, zone, raidRole)
	@return: Member data table
]]
local function CreateMockMember(index, name, classInfo, subgroup, role, rank, options)
	options = options or {}
	
	return {
		index = index,
		name = name,
		rank = rank or 0,
		subgroup = subgroup,
		level = options.level or 80,
		class = classInfo.name,
		classFileName = classInfo.file,
		zone = options.zone or MOCK_ZONES[math.random(#MOCK_ZONES)],
		online = options.online ~= false,  -- Default true
		isDead = options.isDead or false,
		role = options.raidRole or nil,  -- MAINTANK, MAINASSIST or nil (from GetRaidRosterInfo)
		combatRole = role,  -- TANK, HEALER, DAMAGER, NONE (from UnitGroupRolesAssigned)
		isML = options.isML or false,
		unit = "raid" .. index,
		raidIndex = index,
		-- Mock metadata
		_isMock = true,
		_created = GetTime(),
	}
end

--[[
	Generate a realistic raid composition
	@param numMembers: Total members (10, 20, 25, or 40)
	@return: Array of member data
]]
local function GenerateRaidComposition(numMembers)
	local members = {}
	local usedNames = {}
	
	-- Determine role counts based on raid size
	local numTanks, numHealers, numDPS
	if numMembers <= 10 then
		numTanks = 2
		numHealers = 2
		numDPS = numMembers - 4
	elseif numMembers <= 20 then
		numTanks = 2
		numHealers = 4
		numDPS = numMembers - 6
	elseif numMembers <= 25 then
		numTanks = 2
		numHealers = 5
		numDPS = numMembers - 7
	else
		numTanks = 2
		numHealers = 8
		numDPS = numMembers - 10
	end
	
	-- Helper: Get unique name
	local function getUniqueName()
		local name
		local attempts = 0
		repeat
			name = MOCK_PLAYER_NAMES[math.random(#MOCK_PLAYER_NAMES)]
			attempts = attempts + 1
			if attempts > 50 then
				-- Generate numbered name as fallback
				name = "Player" .. math.random(1000, 9999)
				break
			end
		until not usedNames[name]
		usedNames[name] = true
		return name
	end
	
	-- Helper: Get class for role
	local function getClassForRole(role)
		local validClasses = {}
		for _, classInfo in ipairs(MOCK_CLASSES) do
			for _, classRole in ipairs(classInfo.roles) do
				if classRole == role then
					table.insert(validClasses, classInfo)
					break
				end
			end
		end
		return validClasses[math.random(#validClasses)]
	end
	
	local index = 1
	local numGroups = math.ceil(numMembers / 5)
	
	-- Create tanks (Group 1)
	for i = 1, numTanks do
		local name = getUniqueName()
		local classInfo = getClassForRole("TANK")
		local rank = (i == 1) and 2 or 0  -- First tank is leader
		
		members[index] = CreateMockMember(index, name, classInfo, 1, "TANK", rank, {
			isML = (i == 1),  -- Leader is master looter
			raidRole = (i == 1) and "MAINTANK" or ((i == 2) and "MAINASSIST" or nil),  -- First tank = MT, second = MA
		})
		index = index + 1
	end
	
	-- Create healers (Group 2)
	for i = 1, numHealers do
		local name = getUniqueName()
		local classInfo = getClassForRole("HEALER")
		local rank = (i == 1) and 1 or 0  -- First healer is assistant
		local subgroup = math.min(2, numGroups)
		
		members[index] = CreateMockMember(index, name, classInfo, subgroup, "HEALER", rank)
		index = index + 1
	end
	
	-- Create DPS (Groups 3-8)
	local currentGroup = 3
	local membersInGroup = 0
	for i = 1, numDPS do
		local name
		if i == 1 then
			-- Force one long name for testing truncation/resizing
			name = "VeryLongNamePleaseTruncateMeCorrectlyOrResizeMeIfYouCanDoThatWithoutBreakingLayout"
			usedNames[name] = true
		else
			name = getUniqueName()
		end
		
		local classInfo = getClassForRole("DAMAGER")
		local rank = (i == 1) and 1 or 0  -- First DPS is assistant
		
		-- Distribute across groups
		local subgroup = math.min(currentGroup, numGroups)
		members[index] = CreateMockMember(index, name, classInfo, subgroup, "DAMAGER", rank)
		
		membersInGroup = membersInGroup + 1
		if membersInGroup >= 5 then
			currentGroup = currentGroup + 1
			membersInGroup = 0
		end
		
		index = index + 1
	end
	
	-- Add some variety: offline players, dead players
	if numMembers >= 10 then
		-- Make 1-2 players offline
		local offlineCount = math.max(1, math.floor(numMembers / 15))
		for i = 1, offlineCount do
			local randomIndex = math.random(numTanks + numHealers + 1, numMembers)  -- Only DPS
			if members[randomIndex] then
				members[randomIndex].online = false
			end
		end
		
		-- Make 1 player dead (if online)
		local deadIndex = math.random(numTanks + 1, numMembers)
		if members[deadIndex] and members[deadIndex].online then
			members[deadIndex].isDead = true
		end
	end
	
	return members
end

-- ============================================
-- MOCK PRESET FUNCTIONS
-- ============================================

--[[
	Create standard 25-player raid (Heroic/Normal)
]]
function RaidFrame:CreateMockPreset_Standard()
	self:ClearMockData()
	self.mockEnabled = true
	
	self.raidMembers = GenerateRaidComposition(25)
	
	self:ApplyMockData()
	self:StartMockDynamicUpdates()
	
	BFL:DebugPrint("BFL RaidFrame: " .. BFL.L.RAID_MOCK_CREATED_25)
	BFL:DebugPrint("  Tanks: 2, Healers: 5, DPS: 18")
	BFL:DebugPrint("  Leader + 2 Assistants assigned")
end

--[[
	Create full 40-player raid (Classic/Large events)
]]
function RaidFrame:CreateMockPreset_Full()
	self:ClearMockData()
	self.mockEnabled = true
	
	self.raidMembers = GenerateRaidComposition(40)
	
	self:ApplyMockData()
	self:StartMockDynamicUpdates()
	
	BFL:DebugPrint("BFL RaidFrame: " .. BFL.L.RAID_MOCK_CREATED_40)
	BFL:DebugPrint("  Tanks: 2, Healers: 8, DPS: 30")
	BFL:DebugPrint("  Full scrollbar test!")
end

--[[
	Create small 10-player raid (Flex minimum)
]]
function RaidFrame:CreateMockPreset_Small()
	self:ClearMockData()
	self.mockEnabled = true
	
	self.raidMembers = GenerateRaidComposition(10)
	
	self:ApplyMockData()
	self:StartMockDynamicUpdates()
	
	BFL:DebugPrint("BFL RaidFrame: " .. BFL.L.RAID_MOCK_CREATED_10)
	BFL:DebugPrint("  Tanks: 2, Healers: 2, DPS: 6")
end

--[[
	Create 20-player mythic raid
]]
function RaidFrame:CreateMockPreset_Mythic()
	self:ClearMockData()
	self.mockEnabled = true
	
	self.raidMembers = GenerateRaidComposition(20)
	
	self:ApplyMockData()
	self:StartMockDynamicUpdates()
	
	BFL:DebugPrint("BFL RaidFrame: " .. BFL.L.RAID_MOCK_CREATED_MYTHIC)
	BFL:DebugPrint("  Tanks: 2, Healers: 4, DPS: 14")
	BFL:DebugPrint("  Mythic composition!")
end

--[[
	Create stress test with rapid changes
]]
function RaidFrame:CreateMockPreset_Stress()
	self:ClearMockData()
	self.mockEnabled = true
	
	self.raidMembers = GenerateRaidComposition(40)
	
	-- Override config for stress test
	self.mockConfig.updateInterval = 1.0  -- Very fast updates
	
	self:ApplyMockData()
	self:StartMockDynamicUpdates()
	
	BFL:DebugPrint("BFL RaidFrame: " .. BFL.L.RAID_MOCK_STRESS)
	BFL:DebugPrint(BFL.L.RAID_WARN_CPU)
end

-- ============================================
-- MOCK DATA APPLICATION
-- ============================================

--[[
	Apply mock data to the UI
]]
function RaidFrame:ApplyMockData()
	-- Build display list
	self:BuildDisplayList()
	self:UpdateMemberButtons()
	
	-- Force UI to show mock raid (bypass IsInRaid() checks)
	local frame = BetterFriendsFrame and BetterFriendsFrame.RaidFrame
	if not frame then return end
	
	-- Hide "Not in Raid" text
	if frame.NotInRaid then
		frame.NotInRaid:Hide()
	end
	
	-- Show groups container
	if frame.GroupsInset and frame.GroupsInset.GroupsContainer then
		frame.GroupsInset.GroupsContainer:Show()
	end
	
	-- Update control panel
	self:UpdateMockControlPanel()
	
	-- Fix all button visuals
	self:FixMockButtonVisuals()
	
	-- Apply responsive layout
	self:UpdateGroupLayout()
end

--[[
	Update control panel for mock data
]]
function RaidFrame:UpdateMockControlPanel()
	local frame = BetterFriendsFrame and BetterFriendsFrame.RaidFrame
	if not frame or not frame.ControlPanel then return end
	
	local controlPanel = frame.ControlPanel
	
	-- Show all control panel elements
	if controlPanel.EveryoneAssistCheckbox then
		controlPanel.EveryoneAssistCheckbox:Show()
	end
	if controlPanel.EveryoneAssistLabel then
		controlPanel.EveryoneAssistLabel:Show()
		local ASSIST_ICON = "|TInterface\\GroupFrame\\UI-Group-AssistantIcon:14:14|t"
		controlPanel.EveryoneAssistLabel:SetText("All " .. ASSIST_ICON)
	end
	
	-- Update member count
	if controlPanel.MemberCount then
		controlPanel.MemberCount:Show()
		local FRIEND_ICON = "|TInterface\\FriendsFrame\\UI-Toast-FriendOnlineIcon:16:16|t"
		controlPanel.MemberCount:SetText(FRIEND_ICON .. " " .. #self.raidMembers .. "/40")
	end
	
	-- Update role summary
	if controlPanel.RoleSummary then
		controlPanel.RoleSummary:Show()
		
		local tanks, healers, dps = 0, 0, 0
		for _, member in ipairs(self.raidMembers) do
			if member.combatRole == "TANK" then
				tanks = tanks + 1
			elseif member.combatRole == "HEALER" then
				healers = healers + 1
			elseif member.combatRole == "DAMAGER" then
				dps = dps + 1
			end
		end
		
		local iconSize = 14 -- Reduced from 16
		local tankIcon = GetRoleIconString("TANK", iconSize)
		local healIcon = GetRoleIconString("HEALER", iconSize)
		local dpsIcon = GetRoleIconString("DAMAGER", iconSize)
		controlPanel.RoleSummary:SetText(string.format("%s %d  %s %d  %s %d", tankIcon, tanks, healIcon, healers, dpsIcon, dps))
	end
	
	-- Trigger layout update
	self:UpdateControlPanelLayout()
end

--[[
	Fix button visuals for mock data
]]
function RaidFrame:FixMockButtonVisuals()
	local frame = BetterFriendsFrame and BetterFriendsFrame.RaidFrame
	if not frame then return end
	
	local groupsContainer = frame.GroupsInset and frame.GroupsInset.GroupsContainer
	if not groupsContainer then return end
	
	for groupIndex = 1, 8 do
		local groupFrame = groupsContainer["Group" .. groupIndex]
		if groupFrame then
			for slotIndex = 1, 5 do
				local button = groupFrame["Slot" .. slotIndex]
				if button then
					-- Show ALL slots
					button:Show()
					
					if button.memberData then
						-- Occupied slot
						if button.EmptyText then
							button.EmptyText:Hide()
						end
						
						-- Background alpha
						if button.Background then
							button.Background:SetAlpha(button.memberData.online and 0.5 or 0.3)
						end
						
						-- Class color tint
						if button.ClassColorTint then
							local classColor = RAID_CLASS_COLORS[button.memberData.classFileName]
							if classColor and button.memberData.online then
								button.ClassColorTint:SetColorTexture(classColor.r, classColor.g, classColor.b, 0.3)
							else
								button.ClassColorTint:SetColorTexture(0.1, 0.1, 0.1, 0.5)
							end
						end
					else
						-- Empty slot
						if button.EmptyText then
							button.EmptyText:Show()
						end
						if button.Name then button.Name:SetText("") end
						if button.Level then button.Level:SetText("") end
						if button.ClassIcon then button.ClassIcon:Hide() end
						if button.RankIcon then button.RankIcon:Hide() end
						if button.RoleIcon then button.RoleIcon:Hide() end
						if button.MainTankIcon then button.MainTankIcon:Hide() end
						if button.MainAssistIcon then button.MainAssistIcon:Hide() end
						if button.ClassColorTint then
							button.ClassColorTint:SetColorTexture(0.1, 0.1, 0.1, 0.3)
						end
					end
				end
			end
		end
	end
end

-- ============================================
-- DYNAMIC UPDATE SYSTEM
-- ============================================

--[[
	Start timer for dynamic mock updates
]]
function RaidFrame:StartMockDynamicUpdates()
	if self.mockUpdateTimer then
		self.mockUpdateTimer:Cancel()
	end
	
	if not self.mockConfig.dynamicUpdates then return end
	
	self.mockUpdateTimer = C_Timer.NewTicker(self.mockConfig.updateInterval, function()
		self:ProcessMockDynamicUpdate()
	end)
	
	-- BFL:DebugPrint("|cff00ff00RaidFrame Mock:|r Dynamic updates started (interval: " .. self.mockConfig.updateInterval .. "s)")
end

--[[
	Process one cycle of dynamic updates
]]
function RaidFrame:ProcessMockDynamicUpdate()
	if not self.mockEnabled or not self.mockConfig.dynamicUpdates then return end
	
	-- Safety check: Need at least 3 members for meaningful updates
	local memberCount = #self.raidMembers
	if memberCount < 3 then return end
	
	local updated = false
	local updateType = math.random(1, 100)
	
	if updateType <= 20 then
		-- 20% chance: Player goes offline/online
		local memberIndex = math.random(3, memberCount)  -- Skip tanks
		local member = self.raidMembers[memberIndex]
		if member then
			member.online = not member.online
			member.isDead = false  -- Coming online = alive
			updated = true
			-- BFL:DebugPrint(string.format("|cff00ff00Mock Update:|r %s is now %s", 
			-- 	member.name, member.online and "online" or "offline"))
		end
		
	elseif updateType <= 35 then
		-- 15% chance: Player dies/revives
		local memberIndex = math.random(3, memberCount)
		local member = self.raidMembers[memberIndex]
		if member and member.online then
			member.isDead = not member.isDead
			updated = true
			-- BFL:DebugPrint(string.format("|cff00ff00Mock Update:|r %s %s", 
			-- 	member.name, member.isDead and "died" or "revived"))
		end
		
	elseif updateType <= 50 then
		-- 15% chance: Player changes zone
		local memberIndex = math.random(1, memberCount)
		local member = self.raidMembers[memberIndex]
		if member and member.online then
			member.zone = MOCK_ZONES[math.random(#MOCK_ZONES)]
			updated = true
			-- BFL:DebugPrint(string.format("|cff00ff00Mock Update:|r %s moved to %s", 
			-- 	member.name, member.zone))
		end
		
	elseif updateType <= 60 then
		-- 10% chance: Player swaps groups
		if memberCount >= 10 then
			local memberIndex = math.random(3, memberCount)
			local member = self.raidMembers[memberIndex]
			if member then
				local numGroups = math.ceil(memberCount / 5)
				local newGroup = math.random(1, numGroups)
				if newGroup ~= member.subgroup then
					member.subgroup = newGroup
					updated = true
					-- BFL:DebugPrint(string.format("|cff00ff00Mock Update:|r %s moved to Group %d", 
					-- 	member.name, newGroup))
				end
			end
		end
	end
	-- 40% chance: Nothing happens (realistic idle time)
	
	if updated then
		self:BuildDisplayList()
		self:UpdateMemberButtons()
		self:FixMockButtonVisuals()
		self:UpdateMockControlPanel()
	end
end

-- ============================================
-- EVENT SIMULATION
-- ============================================

--[[
	Simulate a ready check
]]
function RaidFrame:SimulateReadyCheck()
	if not self.mockEnabled or #self.raidMembers == 0 then
		BFL:DebugPrint(BFL.L.RAID_NO_MOCK_DATA)
		return
	end
	
	BFL:DebugPrint("BFL RaidFrame: " .. BFL.L.RAID_SIM_READY_CHECK)
	
	-- Set all online members to "waiting"
	for _, member in ipairs(self.raidMembers) do
		if member.online then
			member.readyStatus = "waiting"
		end
	end
	self:RefreshMemberButtons()
	
	-- Gradually confirm players
	local confirmedCount = 0
	local totalOnline = 0
	for _, member in ipairs(self.raidMembers) do
		if member.online then totalOnline = totalOnline + 1 end
	end
	
	-- Confirm players over 8 seconds
	for i, member in ipairs(self.raidMembers) do
		if member.online then
			local delay = math.random(1, 80) / 10  -- 0.1 to 8.0 seconds
			C_Timer.After(delay, function()
				if not self.mockEnabled then return end
				
				-- 90% ready, 10% not ready
				if math.random(1, 100) <= 90 then
					member.readyStatus = "ready"
				else
					member.readyStatus = "notready"
				end
				self:RefreshMemberButtons()
			end)
		end
	end
	
	-- Clear ready check after duration
	C_Timer.After(self.mockConfig.readyCheckDuration, function()
		if not self.mockEnabled then return end
		
		local ready, notReady = 0, 0
		for _, member in ipairs(self.raidMembers) do
			if member.readyStatus == "ready" then
				ready = ready + 1
			elseif member.readyStatus == "notready" then
				notReady = notReady + 1
			end
			member.readyStatus = nil
		end
		self:RefreshMemberButtons()
		
		BFL:DebugPrint(string.format("BFL RaidFrame: Ready Check finished: %d ready, %d not ready", ready, notReady))
	end)
end

--[[
	Simulate role changes
]]
function RaidFrame:SimulateRoleChanges()
	if not self.mockEnabled or #self.raidMembers == 0 then
		BFL:DebugPrint(BFL.L.RAID_NO_MOCK_DATA)
		return
	end
	
	local changed = 0
	for _, member in ipairs(self.raidMembers) do
		-- 30% chance to change role (if class supports multiple)
		if math.random(1, 100) <= 30 then
			local classInfo
			for _, c in ipairs(MOCK_CLASSES) do
				if c.file == member.classFileName then
					classInfo = c
					break
				end
			end
			
			if classInfo and #classInfo.roles > 1 then
				local newRole = classInfo.roles[math.random(#classInfo.roles)]
				if newRole ~= member.combatRole then
					member.role = newRole
					member.combatRole = newRole
					changed = changed + 1
				end
			end
		end
	end
	
	self:BuildDisplayList()
	self:UpdateMemberButtons()
	self:FixMockButtonVisuals()
	self:UpdateMockControlPanel()
	
	BFL:DebugPrint(string.format("BFL RaidFrame: Simulated %d role changes", changed))
end

--[[
	Simulate group moves (shuffle players)
]]
function RaidFrame:SimulateGroupMoves()
	if not self.mockEnabled or #self.raidMembers == 0 then
		BFL:DebugPrint(BFL.L.RAID_NO_MOCK_DATA)
		return
	end
	
	local numGroups = math.ceil(#self.raidMembers / 5)
	local moved = 0
	
	for _, member in ipairs(self.raidMembers) do
		-- 40% chance to move (skip leader)
		if member.rank ~= 2 and math.random(1, 100) <= 40 then
			local newGroup = math.random(1, numGroups)
			if newGroup ~= member.subgroup then
				member.subgroup = newGroup
				moved = moved + 1
			end
		end
	end
	
	self:BuildDisplayList()
	self:UpdateMemberButtons()
	self:FixMockButtonVisuals()
	
	BFL:DebugPrint(string.format("BFL RaidFrame: Moved %d players to different groups", moved))
end

-- ============================================
-- MOCK DATA MANAGEMENT
-- ============================================

--[[
	Clear all mock data and stop timers
]]
function RaidFrame:ClearMockData()
	-- Stop dynamic update timer
	if self.mockUpdateTimer then
		self.mockUpdateTimer:Cancel()
		self.mockUpdateTimer = nil
	end
	
	-- Reset config to defaults
	self.mockConfig.updateInterval = 5.0
	
	-- Clear state
	self.mockEnabled = false
	wipe(self.raidMembers)
	wipe(self.displayList)
	self.selectedMember = nil
	
	-- Reset all buttons
	if self.memberButtons then
		for groupIndex = 1, 8 do
			if self.memberButtons[groupIndex] then
				for slotIndex = 1, 5 do
					local button = self.memberButtons[groupIndex][slotIndex]
					if button then
						button.memberData = nil
						button.unit = nil
						button.name = nil
						button.raidSlot = nil
					end
				end
			end
		end
	end
	
	-- Update UI to show "Not in Raid" if applicable
	local frame = BetterFriendsFrame and BetterFriendsFrame.RaidFrame
	if frame then
		if not IsInRaid() and not IsInGroup() then
			if frame.NotInRaid then
				frame.NotInRaid:Show()
			end
			if frame.GroupsInset and frame.GroupsInset.GroupsContainer then
				frame.GroupsInset.GroupsContainer:Hide()
			end
		end
	end
	
	-- BFL:DebugPrint("|cff00ff00RaidFrame Mock:|r Cleared all mock data")
	BFL:DebugPrint("BFL RaidFrame: " .. BFL.L.RAID_MOCK_CLEARED)
end

-- ============================================
-- SLASH COMMAND HANDLER
-- ============================================

-- Legacy slash command (redirects to /bfl raid)
SLASH_BFLMOCKRAID1 = "/bflmock"
SLASH_BFLRAIDFRAME1 = "/bflraid"
SlashCmdList["BFLMOCKRAID"] = function(msg)
	SlashCmdList["BFLRAIDFRAME"](msg)
end

SlashCmdList["BFLRAIDFRAME"] = function(msg)
	local args = {}
	for word in msg:gmatch("%S+") do
		table.insert(args, word)
	end
	
	local cmd = args[1] and args[1]:lower() or "help"
	
	if cmd == "mock" then
		local subCmd = args[2] and args[2]:lower() or "standard"
		
		if subCmd == "full" or subCmd == "40" then
			RaidFrame:CreateMockPreset_Full()
		elseif subCmd == "small" or subCmd == "10" then
			RaidFrame:CreateMockPreset_Small()
		elseif subCmd == "mythic" or subCmd == "20" then
			RaidFrame:CreateMockPreset_Mythic()
		elseif subCmd == "stress" then
			RaidFrame:CreateMockPreset_Stress()
		else
			RaidFrame:CreateMockPreset_Standard()
		end
		
	elseif cmd == "event" then
		local eventType = args[2] and args[2]:lower() or "help"
		
		if eventType == "readycheck" or eventType == "ready" then
			RaidFrame:SimulateReadyCheck()
		elseif eventType == "rolechange" or eventType == "role" or eventType == "roles" then
			RaidFrame:SimulateRoleChanges()
		elseif eventType == "move" or eventType == "shuffle" then
			RaidFrame:SimulateGroupMoves()
		else
			print(BFL.L.RAID_EVENT_COMMANDS)
			print("  |cffffcc00/bfl raid event readycheck|r - Simulate ready check")
			print("  |cffffcc00/bfl raid event rolechange|r - Simulate role changes")
			print("  |cffffcc00/bfl raid event move|r - Shuffle players between groups")
		end
		
	elseif cmd == "config" then
		local setting = args[2] and args[2]:lower()
		local value = args[3]
		
		if setting == "dynamic" then
			RaidFrame.mockConfig.dynamicUpdates = (value == "on" or value == "true" or value == "1")
			BFL:DebugPrint("|cff00ff00BFL RaidFrame:|r " .. string.format(BFL.L.RAID_DYN_UPDATES, 
				RaidFrame.mockConfig.dynamicUpdates and "ON" or "OFF"))
		elseif setting == "interval" then
			local interval = tonumber(value) or 5.0
			RaidFrame.mockConfig.updateInterval = math.max(1.0, interval)
			BFL:DebugPrint("|cff00ff00BFL RaidFrame:|r " .. string.format(BFL.L.RAID_UPDATE_INTERVAL, 
				RaidFrame.mockConfig.updateInterval))
		else
			BFL:DebugPrint(BFL.L.RAID_CONFIG_HEADER)
			BFL:DebugPrint(string.format(BFL.L.RAID_MOCK_ENABLED_STATUS, RaidFrame.mockEnabled and "YES" or "NO"))
			BFL:DebugPrint(string.format(BFL.L.RAID_DYN_UPDATES_STATUS, RaidFrame.mockConfig.dynamicUpdates and "ON" or "OFF"))
			BFL:DebugPrint(string.format(BFL.L.RAID_UPDATE_INTERVAL_STATUS, RaidFrame.mockConfig.updateInterval))
			BFL:DebugPrint(string.format(BFL.L.RAID_MEMBERS_STATUS, #RaidFrame.raidMembers))
			BFL:DebugPrint("")
			BFL:DebugPrint("  |cffffcc00/bfl raid config dynamic on|off|r")
			BFL:DebugPrint("  |cffffcc00/bfl raid config interval <seconds>|r")
		end
		
	elseif cmd == "clear" then
		RaidFrame:ClearMockData()
		
	elseif cmd == "list" or cmd == "info" then
		if RaidFrame.mockEnabled and #RaidFrame.raidMembers > 0 then
			BFL:DebugPrint(BFL.L.RAID_INFO_HEADER)
			BFL:DebugPrint(string.format(BFL.L.RAID_TOTAL_MEMBERS, #RaidFrame.raidMembers))
			
			local tanks, healers, dps, offline, dead = 0, 0, 0, 0, 0
			for _, member in ipairs(RaidFrame.raidMembers) do
				if member.combatRole == "TANK" then tanks = tanks + 1
				elseif member.combatRole == "HEALER" then healers = healers + 1
				elseif member.combatRole == "DAMAGER" then dps = dps + 1 end
				if not member.online then offline = offline + 1 end
				if member.isDead then dead = dead + 1 end
			end
			
			BFL:DebugPrint(string.format(BFL.L.RAID_COMPOSITION, tanks, healers, dps))
			BFL:DebugPrint(string.format(BFL.L.RAID_STATUS, offline, dead))
			BFL:DebugPrint(string.format(BFL.L.RAID_DYN_UPDATES_STATUS, RaidFrame.mockConfig.dynamicUpdates and "ON" or "OFF"))
		else
			BFL:DebugPrint(BFL.L.RAID_NO_MOCK_ACTIVE)
		end
		
	else
		-- Help
		print(BFL.L.CORE_HELP_RAID_COMMANDS)
		print("")
		print(BFL.L.CORE_HELP_MOCK_COMMANDS)
		print(BFL.L.CORE_HELP_RAID_MOCK)
		print(BFL.L.CORE_HELP_RAID_FULL)
		print(BFL.L.CORE_HELP_RAID_SMALL)
		print(BFL.L.CORE_HELP_RAID_MYTHIC)
		print(BFL.L.RAID_CMD_STRESS)
		print("")
		print(BFL.L.RAID_HELP_EVENTS)
		print(BFL.L.CORE_HELP_RAID_READY)
		print(BFL.L.CORE_HELP_RAID_ROLE)
		print(BFL.L.CORE_HELP_RAID_MOVE)
		print("")
		print(BFL.L.RAID_HELP_MANAGEMENT)
		print(BFL.L.RAID_CMD_CONFIG)
		print(BFL.L.RAID_CMD_LIST)
		print(BFL.L.CORE_HELP_RAID_CLEAR)
	end
end

-- Keep old CreateMockRaidData for backwards compatibility
function RaidFrame:CreateMockRaidData()
	self:CreateMockPreset_Standard()
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
    
    Testing:
    - RaidFrame:CreateMockRaidData()
    - /bflmock raid - Slash command
]]

return RaidFrame
