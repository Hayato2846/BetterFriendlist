--[[Perfy has instrumented this file]] local Perfy_GetTime, Perfy_Trace, Perfy_Trace_Passthrough = Perfy_GetTime, Perfy_Trace, Perfy_Trace_Passthrough; Perfy_Trace(Perfy_GetTime(), "Enter", "(main chunk) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/NotificationEditMode.lua"); --[[
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

local function IsBetaEnabled() Perfy_Trace(Perfy_GetTime(), "Enter", "IsBetaEnabled file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/NotificationEditMode.lua:16:6");
    return Perfy_Trace_Passthrough("Leave", "IsBetaEnabled file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/NotificationEditMode.lua:16:6", BetterFriendlistDB and BetterFriendlistDB.enableBetaFeatures == true)
end

--[[--------------------------------------------------
    Edit Mode Setup
--]]--------------------------------------------------

function NotificationEditMode:Initialize() Perfy_Trace(Perfy_GetTime(), "Enter", "NotificationEditMode:Initialize file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/NotificationEditMode.lua:24:0");
    -- STOP: Edit Mode is Retail-only (10.0+)
    if not BFL.HasEditMode then
        -- BFL:DebugPrint("|cffffcc00BFL:NotificationEditMode:|r Edit Mode not available in Classic")
        Perfy_Trace(Perfy_GetTime(), "Leave", "NotificationEditMode:Initialize file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/NotificationEditMode.lua:24:0"); return
    end
    
    -- STOP: Beta Features must be enabled
    if not IsBetaEnabled() then
        -- BFL:DebugPrint("|cffffcc00BFL:NotificationEditMode:|r Beta Features disabled - Edit Mode integration skipped")
        Perfy_Trace(Perfy_GetTime(), "Leave", "NotificationEditMode:Initialize file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/NotificationEditMode.lua:24:0"); return
    end
    
    -- Get container frame
    local container = _G["BFL_NotificationToastContainer"]
    if not container then
        -- BFL:DebugPrint("|cffff0000BFL:NotificationEditMode:|r Toast container not found!")
        Perfy_Trace(Perfy_GetTime(), "Leave", "NotificationEditMode:Initialize file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/NotificationEditMode.lua:24:0"); return
    end
    
    -- Apply saved position (works without LibEditMode)
    self:ApplyPosition()
    
    -- LibEditMode integration (optional)
    if not LEM then
        -- BFL:DebugPrint("|cffffcc00BFL:NotificationEditMode:|r LibEditMode not found - using fixed position")
        -- BFL:DebugPrint("|cffffcc00BFL:NotificationEditMode:|r Install LibEditMode for drag & drop support")
        Perfy_Trace(Perfy_GetTime(), "Leave", "NotificationEditMode:Initialize file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/NotificationEditMode.lua:24:0"); return
    end
    
    -- Set frame name for Edit Mode
    container.editModeName = BFL.L.EDITMODE_NOTIFICATIONS_LABEL
    
    -- Position callback - save position when moved in Edit Mode
    local function OnPositionChanged(frame, layoutName, point, x, y) Perfy_Trace(Perfy_GetTime(), "Enter", "OnPositionChanged file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/NotificationEditMode.lua:58:10");
        if not BetterFriendlistDB.notificationToastPosition then
            BetterFriendlistDB.notificationToastPosition = {}
        end
        
        BetterFriendlistDB.notificationToastPosition[layoutName] = BetterFriendlistDB.notificationToastPosition[layoutName] or {}
        BetterFriendlistDB.notificationToastPosition[layoutName].point = point
        BetterFriendlistDB.notificationToastPosition[layoutName].x = x
        BetterFriendlistDB.notificationToastPosition[layoutName].y = y
        
        -- Don't re-apply position here, LibEditMode handles the drag
        -- self:ApplyPosition(layoutName) 
        
        -- BFL:DebugPrint("|cff00ffffBFL:NotificationEditMode:|r Position saved: " .. point .. " (" .. x .. ", " .. y .. ")")
    Perfy_Trace(Perfy_GetTime(), "Leave", "OnPositionChanged file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/NotificationEditMode.lua:58:10"); end
    
    -- Default position
    local defaults = {
        point = "TOP",
        x = 0,
        y = -150
    }
    
    -- Register frame with LibEditMode
    LEM:AddFrame(container, OnPositionChanged, defaults)
    
    -- Register callbacks for Edit Mode enter/exit
    LEM:RegisterCallback("enter", function() Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/NotificationEditMode.lua:85:34");
        NotificationEditMode:OnEditModeEnter()
    Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/NotificationEditMode.lua:85:34"); end)
    
    LEM:RegisterCallback("exit", function() Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/NotificationEditMode.lua:89:33");
        NotificationEditMode:OnEditModeExit()
    Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/NotificationEditMode.lua:89:33"); end)
    
    LEM:RegisterCallback("layout", function(layoutName) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/NotificationEditMode.lua:93:35");
        NotificationEditMode:ApplyPosition(layoutName)
    Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/NotificationEditMode.lua:93:35"); end)
    
    -- Apply saved position on load
    self:ApplyPosition()
    
    -- BFL:DebugPrint("|cff00ffffBFL:NotificationEditMode:|r Edit Mode integration initialized")
Perfy_Trace(Perfy_GetTime(), "Leave", "NotificationEditMode:Initialize file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/NotificationEditMode.lua:24:0"); end

function NotificationEditMode:ApplyPosition(layoutName) Perfy_Trace(Perfy_GetTime(), "Enter", "NotificationEditMode:ApplyPosition file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/NotificationEditMode.lua:103:0");
    layoutName = layoutName or (LEM and LEM.GetActiveLayoutName and LEM.GetActiveLayoutName()) or "Default"
    
    local container = _G["BFL_NotificationToastContainer"]
    if not container then Perfy_Trace(Perfy_GetTime(), "Leave", "NotificationEditMode:ApplyPosition file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/NotificationEditMode.lua:103:0"); return end
    
    local position = BetterFriendlistDB.notificationToastPosition and BetterFriendlistDB.notificationToastPosition[layoutName]
    
    if position then
        container:ClearAllPoints()
        container:SetPoint(position.point or "TOP", UIParent, position.point or "TOP", position.x or 0, position.y or -150)
        -- BFL:DebugPrint("|cff00ffffBFL:NotificationEditMode:|r Applied position for layout '" .. layoutName .. "'")
    else
        -- Use default position
        container:ClearAllPoints()
        container:SetPoint("TOP", UIParent, "TOP", 0, -150)
    end
Perfy_Trace(Perfy_GetTime(), "Leave", "NotificationEditMode:ApplyPosition file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/NotificationEditMode.lua:103:0"); end

function NotificationEditMode:OnEditModeEnter() Perfy_Trace(Perfy_GetTime(), "Enter", "NotificationEditMode:OnEditModeEnter file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/NotificationEditMode.lua:122:0");
    -- STOP: Beta Features must be enabled
    if not IsBetaEnabled() then
        Perfy_Trace(Perfy_GetTime(), "Leave", "NotificationEditMode:OnEditModeEnter file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/NotificationEditMode.lua:122:0"); return
    end
    
    -- Show all 3 toast frames with preview content when entering Edit Mode
    local container = _G["BFL_NotificationToastContainer"]
    if not container then Perfy_Trace(Perfy_GetTime(), "Leave", "NotificationEditMode:OnEditModeEnter file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/NotificationEditMode.lua:122:0"); return end
    
    -- Ensure container is visible for dragging
    container:Show()
    container:SetAlpha(1)
    
    local toasts = {container.Toast1, container.Toast2, container.Toast3}
    
    for i, toast in ipairs(toasts) do
        if toast then
            toast.Name:SetText(string.format(BFL.L.EDITMODE_PREVIEW_NAME, i))
            toast.Message:SetText(BFL.L.EDITMODE_PREVIEW_MESSAGE)
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
    
    -- BFL:DebugPrint("|cff00ffffBFL:NotificationEditMode:|r Edit Mode entered, showing toast previews")
Perfy_Trace(Perfy_GetTime(), "Leave", "NotificationEditMode:OnEditModeEnter file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/NotificationEditMode.lua:122:0"); end

function NotificationEditMode:OnEditModeExit() Perfy_Trace(Perfy_GetTime(), "Enter", "NotificationEditMode:OnEditModeExit file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/NotificationEditMode.lua:158:0");
    -- STOP: Beta Features must be enabled
    if not IsBetaEnabled() then
        Perfy_Trace(Perfy_GetTime(), "Leave", "NotificationEditMode:OnEditModeExit file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/NotificationEditMode.lua:158:0"); return
    end
    
    -- Hide all preview toasts when exiting Edit Mode
    local container = _G["BFL_NotificationToastContainer"]
    if not container then Perfy_Trace(Perfy_GetTime(), "Leave", "NotificationEditMode:OnEditModeExit file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/NotificationEditMode.lua:158:0"); return end
    
    local toasts = {container.Toast1, container.Toast2, container.Toast3}
    
    for i, toast in ipairs(toasts) do
        if toast then
            toast:SetAlpha(1.0) -- Reset to full opacity
            toast:SetFrameStrata("DIALOG") -- Restore original strata
            toast:EnableMouse(true) -- Re-enable mouse for click-to-dismiss
            toast:Hide()
        end
    end
    
    -- BFL:DebugPrint("|cff00ffffBFL:NotificationEditMode:|r Edit Mode exited, hiding toast previews")
Perfy_Trace(Perfy_GetTime(), "Leave", "NotificationEditMode:OnEditModeExit file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/NotificationEditMode.lua:158:0"); end

-- Public API
BFL.NotificationEditMode = NotificationEditMode

Perfy_Trace(Perfy_GetTime(), "Leave", "(main chunk) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/NotificationEditMode.lua");