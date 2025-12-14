--[[
    NotificationEditMode - Edit Mode Integration for Toast Container
    Allows users to move notification toasts in Blizzard's Edit Mode
--]]

local _, BFL = ...
local NotificationEditMode = {}

-- Check if LibEditMode is available (optional dependency)
local LEM = LibStub and LibStub("LibEditMode", true)

--[[--------------------------------------------------
    Beta Feature Guard
--]]--------------------------------------------------

local function IsBetaEnabled()
    return BetterFriendlistDB and BetterFriendlistDB.enableBetaFeatures == true
end

--[[--------------------------------------------------
    Edit Mode Setup
--]]--------------------------------------------------

function NotificationEditMode:Initialize()
    -- STOP: Beta Features must be enabled
    if not IsBetaEnabled() then
        BFL:DebugPrint("|cffffcc00BFL:NotificationEditMode:|r Beta Features disabled - Edit Mode integration skipped")
        return
    end
    
    -- Get container frame
    local container = _G["BFL_NotificationToastContainer"]
    if not container then
        BFL:DebugPrint("|cffff0000BFL:NotificationEditMode:|r Toast container not found!")
        return
    end
    
    -- Apply saved position (works without LibEditMode)
    self:ApplyPosition()
    
    -- LibEditMode integration (optional)
    if not LEM then
        BFL:DebugPrint("|cffffcc00BFL:NotificationEditMode:|r LibEditMode not found - using fixed position")
        BFL:DebugPrint("|cffffcc00BFL:NotificationEditMode:|r Install LibEditMode for drag & drop support")
        return
    end
    
    -- Set frame name for Edit Mode
    container.editModeName = "BetterFriendlist Notifications"
    
    -- Position callback - save position when moved in Edit Mode
    local function OnPositionChanged(frame, layoutName, point, x, y)
        if not BetterFriendlistDB.notificationToastPosition then
            BetterFriendlistDB.notificationToastPosition = {}
        end
        
        BetterFriendlistDB.notificationToastPosition[layoutName] = BetterFriendlistDB.notificationToastPosition[layoutName] or {}
        BetterFriendlistDB.notificationToastPosition[layoutName].point = point
        BetterFriendlistDB.notificationToastPosition[layoutName].x = x
        BetterFriendlistDB.notificationToastPosition[layoutName].y = y
        
        -- Don't re-apply position here, LibEditMode handles the drag
        -- self:ApplyPosition(layoutName) 
        
        BFL:DebugPrint("|cff00ffffBFL:NotificationEditMode:|r Position saved: " .. point .. " (" .. x .. ", " .. y .. ")")
    end
    
    -- Default position
    local defaults = {
        point = "TOP",
        x = 0,
        y = -150
    }
    
    -- Register frame with LibEditMode
    LEM:AddFrame(container, OnPositionChanged, defaults)
    
    -- Register callbacks for Edit Mode enter/exit
    LEM:RegisterCallback("enter", function()
        NotificationEditMode:OnEditModeEnter()
    end)
    
    LEM:RegisterCallback("exit", function()
        NotificationEditMode:OnEditModeExit()
    end)
    
    LEM:RegisterCallback("layout", function(layoutName)
        NotificationEditMode:ApplyPosition(layoutName)
    end)
    
    -- Apply saved position on load
    self:ApplyPosition()
    
    BFL:DebugPrint("|cff00ffffBFL:NotificationEditMode:|r Edit Mode integration initialized")
end

function NotificationEditMode:ApplyPosition(layoutName)
    layoutName = layoutName or (LEM and LEM.GetActiveLayoutName and LEM.GetActiveLayoutName()) or "Default"
    
    local container = _G["BFL_NotificationToastContainer"]
    if not container then return end
    
    local position = BetterFriendlistDB.notificationToastPosition and BetterFriendlistDB.notificationToastPosition[layoutName]
    
    if position then
        container:ClearAllPoints()
        container:SetPoint(position.point or "TOP", UIParent, position.point or "TOP", position.x or 0, position.y or -150)
        BFL:DebugPrint("|cff00ffffBFL:NotificationEditMode:|r Applied position for layout '" .. layoutName .. "'")
    else
        -- Use default position
        container:ClearAllPoints()
        container:SetPoint("TOP", UIParent, "TOP", 0, -150)
    end
end

function NotificationEditMode:OnEditModeEnter()
    -- STOP: Beta Features must be enabled
    if not IsBetaEnabled() then
        return
    end
    
    -- Show all 3 toast frames with preview content when entering Edit Mode
    local container = _G["BFL_NotificationToastContainer"]
    if not container then return end
    
    -- Ensure container is visible for dragging
    container:Show()
    container:SetAlpha(1)
    
    local toasts = {container.Toast1, container.Toast2, container.Toast3}
    
    for i, toast in ipairs(toasts) do
        if toast then
            toast.Name:SetText("Preview " .. i)
            toast.Message:SetText("Notification preview for positioning")
            toast.Icon:SetTexture("Interface\\AddOns\\BetterFriendlist\\Icons\\user-check")
            toast.Icon:SetVertexColor(0.3, 1, 0.3, 1)
            toast:SetAlpha(0.8) -- More visible preview
            toast:SetFrameStrata("BACKGROUND") -- Lower strata to not block Edit Mode UI
            toast:EnableMouse(false) -- Disable mouse to allow clicking through
            toast:Show()
            
            -- Stop fade animations
            if toast.FadeIn then toast.FadeIn:Stop() end
            if toast.FadeOut then toast.FadeOut:Stop() end
        end
    end
    
    BFL:DebugPrint("|cff00ffffBFL:NotificationEditMode:|r Edit Mode entered, showing toast previews")
end

function NotificationEditMode:OnEditModeExit()
    -- STOP: Beta Features must be enabled
    if not IsBetaEnabled() then
        return
    end
    
    -- Hide all preview toasts when exiting Edit Mode
    local container = _G["BFL_NotificationToastContainer"]
    if not container then return end
    
    local toasts = {container.Toast1, container.Toast2, container.Toast3}
    
    for i, toast in ipairs(toasts) do
        if toast then
            toast:SetAlpha(1.0) -- Reset to full opacity
            toast:SetFrameStrata("DIALOG") -- Restore original strata
            toast:EnableMouse(true) -- Re-enable mouse for click-to-dismiss
            toast:Hide()
        end
    end
    
    BFL:DebugPrint("|cff00ffffBFL:NotificationEditMode:|r Edit Mode exited, hiding toast previews")
end

-- Public API
BFL.NotificationEditMode = NotificationEditMode
