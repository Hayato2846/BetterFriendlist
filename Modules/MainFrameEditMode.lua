--[[Perfy has instrumented this file]] local Perfy_GetTime, Perfy_Trace, Perfy_Trace_Passthrough = Perfy_GetTime, Perfy_Trace, Perfy_Trace_Passthrough; Perfy_Trace(Perfy_GetTime(), "Enter", "(main chunk) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MainFrameEditMode.lua"); --[[
    MainFrameEditMode - Edit Mode Integration for Main Frame
    Allows users to position and resize the BetterFriendlist frame in Blizzard's Edit Mode
    NOTE: Edit Mode is Retail-only (10.0+) - this module is disabled in Classic
--]]

local _, BFL = ...
local MainFrameEditMode = {}

-- Classic Guard: Edit Mode is Retail-only
if BFL.IsClassic then
    -- Register empty module so other code doesn't error
    BFL.MainFrameEditMode = MainFrameEditMode
    function MainFrameEditMode:Initialize() Perfy_Trace(Perfy_GetTime(), "Enter", "MainFrameEditMode:Initialize file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MainFrameEditMode.lua:14:4"); Perfy_Trace(Perfy_GetTime(), "Leave", "MainFrameEditMode:Initialize file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MainFrameEditMode.lua:14:4"); end
    function MainFrameEditMode:ApplyPosition() Perfy_Trace(Perfy_GetTime(), "Enter", "MainFrameEditMode:ApplyPosition file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MainFrameEditMode.lua:15:4"); Perfy_Trace(Perfy_GetTime(), "Leave", "MainFrameEditMode:ApplyPosition file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MainFrameEditMode.lua:15:4"); end
    function MainFrameEditMode:SavePosition() Perfy_Trace(Perfy_GetTime(), "Enter", "MainFrameEditMode:SavePosition file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MainFrameEditMode.lua:16:4"); Perfy_Trace(Perfy_GetTime(), "Leave", "MainFrameEditMode:SavePosition file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MainFrameEditMode.lua:16:4"); end
    function MainFrameEditMode:ApplySize() Perfy_Trace(Perfy_GetTime(), "Enter", "MainFrameEditMode:ApplySize file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MainFrameEditMode.lua:17:4"); Perfy_Trace(Perfy_GetTime(), "Leave", "MainFrameEditMode:ApplySize file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MainFrameEditMode.lua:17:4"); end
    function MainFrameEditMode:SaveSize() Perfy_Trace(Perfy_GetTime(), "Enter", "MainFrameEditMode:SaveSize file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MainFrameEditMode.lua:18:4"); Perfy_Trace(Perfy_GetTime(), "Leave", "MainFrameEditMode:SaveSize file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MainFrameEditMode.lua:18:4"); end
    Perfy_Trace(Perfy_GetTime(), "Leave", "(main chunk) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MainFrameEditMode.lua"); return
end

-- Check if LibEditMode is available (optional dependency)
local LEM = LibStub and LibStub("LibEditMode", true)

--[[--------------------------------------------------
    Validation & Clamping
--]]--------------------------------------------------

local MIN_WIDTH = 380
local MAX_WIDTH = 800
local MIN_HEIGHT = 400
local MAX_HEIGHT = 1200
local DEFAULT_WIDTH = 415
local DEFAULT_HEIGHT = 570

local function ValidateSize(width, height) Perfy_Trace(Perfy_GetTime(), "Enter", "ValidateSize file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MainFrameEditMode.lua:36:6");
    width = Clamp(width or DEFAULT_WIDTH, MIN_WIDTH, MAX_WIDTH)
    height = Clamp(height or DEFAULT_HEIGHT, MIN_HEIGHT, MAX_HEIGHT)
    Perfy_Trace(Perfy_GetTime(), "Leave", "ValidateSize file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MainFrameEditMode.lua:36:6"); return width, height
end

--[[--------------------------------------------------
    Migration (One-Time)
--]]--------------------------------------------------

function MainFrameEditMode:MigrateOldPosition(frame) Perfy_Trace(Perfy_GetTime(), "Enter", "MainFrameEditMode:MigrateOldPosition file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MainFrameEditMode.lua:46:0");
    -- Check if migration already done
    if BetterFriendlistDB.mainFramePositionMigrated then
        Perfy_Trace(Perfy_GetTime(), "Leave", "MainFrameEditMode:MigrateOldPosition file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MainFrameEditMode.lua:46:0"); return
    end
    
    -- Get current frame position (from WoW's layout-local.txt)
    local numPoints = frame:GetNumPoints()
    if numPoints > 0 then
        local point, relativeTo, relativePoint, xOfs, yOfs = frame:GetPoint(1)
        
        -- Only migrate if frame has been moved from default XML position
        -- Default: TOPLEFT x="16" y="-116"
        local isDefaultPosition = (point == "TOPLEFT" and math.abs(xOfs - 16) < 1 and math.abs(yOfs - (-116)) < 1)
        
        if not isDefaultPosition then
            -- Frame has been moved by user - migrate to new system
            local layoutName = (LEM and LEM.GetActiveLayoutName and LEM.GetActiveLayoutName()) or "Default"
            
            -- Save to new system
            if not BetterFriendlistDB.mainFramePosition then
                BetterFriendlistDB.mainFramePosition = {}
            end
            
            BetterFriendlistDB.mainFramePosition[layoutName] = {
                point = point,
                x = xOfs,
                y = yOfs
            }
            
            -- BFL:DebugPrint("|cff00ff00BFL:MainFrameEditMode:|r Migrated old position: " .. point .. " (" .. xOfs .. ", " .. yOfs .. ")")
        end
    end
    
    -- Mark migration as done (even if no position to migrate)
    BetterFriendlistDB.mainFramePositionMigrated = true
Perfy_Trace(Perfy_GetTime(), "Leave", "MainFrameEditMode:MigrateOldPosition file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MainFrameEditMode.lua:46:0"); end

--[[--------------------------------------------------
    Position Management
--]]--------------------------------------------------

function MainFrameEditMode:ApplyPosition(layoutName) Perfy_Trace(Perfy_GetTime(), "Enter", "MainFrameEditMode:ApplyPosition file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MainFrameEditMode.lua:88:0");
    layoutName = layoutName or (LEM and LEM.GetActiveLayoutName and LEM.GetActiveLayoutName()) or "Default"
    
    local frame = BetterFriendsFrame
    if not frame then Perfy_Trace(Perfy_GetTime(), "Leave", "MainFrameEditMode:ApplyPosition file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MainFrameEditMode.lua:88:0"); return end
    
    local position = BetterFriendlistDB.mainFramePosition and BetterFriendlistDB.mainFramePosition[layoutName]
    
    if position then
        frame:ClearAllPoints()
        frame:SetPoint(position.point or "CENTER", UIParent, position.point or "CENTER", position.x or 0, position.y or 0)
        -- BFL:DebugPrint("|cff00ffffBFL:MainFrameEditMode:|r Applied position for layout '" .. layoutName .. "'")
    else
        -- Use default position (center of screen)
        frame:ClearAllPoints()
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
Perfy_Trace(Perfy_GetTime(), "Leave", "MainFrameEditMode:ApplyPosition file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MainFrameEditMode.lua:88:0"); end

function MainFrameEditMode:SavePosition(layoutName, point, x, y) Perfy_Trace(Perfy_GetTime(), "Enter", "MainFrameEditMode:SavePosition file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MainFrameEditMode.lua:107:0");
    if not BetterFriendlistDB.mainFramePosition then
        BetterFriendlistDB.mainFramePosition = {}
    end
    
    BetterFriendlistDB.mainFramePosition[layoutName] = BetterFriendlistDB.mainFramePosition[layoutName] or {}
    BetterFriendlistDB.mainFramePosition[layoutName].point = point
    BetterFriendlistDB.mainFramePosition[layoutName].x = x
    BetterFriendlistDB.mainFramePosition[layoutName].y = y
    
    -- BFL:DebugPrint("|cff00ffffBFL:MainFrameEditMode:|r Position saved: " .. point .. " (" .. x .. ", " .. y .. ")")
Perfy_Trace(Perfy_GetTime(), "Leave", "MainFrameEditMode:SavePosition file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MainFrameEditMode.lua:107:0"); end

--[[--------------------------------------------------
    Size Management
--]]--------------------------------------------------

function MainFrameEditMode:ApplySize(layoutName) Perfy_Trace(Perfy_GetTime(), "Enter", "MainFrameEditMode:ApplySize file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MainFrameEditMode.lua:124:0");
    layoutName = layoutName or (LEM and LEM.GetActiveLayoutName and LEM.GetActiveLayoutName()) or "Default"
    
    local frame = BetterFriendsFrame
    if not frame then Perfy_Trace(Perfy_GetTime(), "Leave", "MainFrameEditMode:ApplySize file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MainFrameEditMode.lua:124:0"); return end
    
    local sizeData = BetterFriendlistDB.mainFrameSize and BetterFriendlistDB.mainFrameSize[layoutName]
    local width, height
    
    if sizeData then
        width, height = ValidateSize(sizeData.width, sizeData.height)
        -- BFL:DebugPrint("|cff00ffffBFL:MainFrameEditMode:|r Applied size for layout '" .. layoutName .. "': " .. width .. "x" .. height)
    else
        -- Use default or user-preferred size
        width = BetterFriendlistDB.defaultFrameWidth or DEFAULT_WIDTH
        height = BetterFriendlistDB.defaultFrameHeight or DEFAULT_HEIGHT
        width, height = ValidateSize(width, height)
    end
    
    frame:SetSize(width, height)
    
    -- Trigger responsive updates
    self:TriggerResponsiveUpdates()
Perfy_Trace(Perfy_GetTime(), "Leave", "MainFrameEditMode:ApplySize file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MainFrameEditMode.lua:124:0"); end

function MainFrameEditMode:SaveSize(layoutName, width, height) Perfy_Trace(Perfy_GetTime(), "Enter", "MainFrameEditMode:SaveSize file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MainFrameEditMode.lua:149:0");
    -- Validate and clamp
    width, height = ValidateSize(width, height)
    
    if not BetterFriendlistDB.mainFrameSize then
        BetterFriendlistDB.mainFrameSize = {}
    end
    
    BetterFriendlistDB.mainFrameSize[layoutName] = {
        width = width,
        height = height
    }
Perfy_Trace(Perfy_GetTime(), "Leave", "MainFrameEditMode:SaveSize file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MainFrameEditMode.lua:149:0"); end

--[[--------------------------------------------------
    Scale Management (Feature Request: Window Scale)
--]]--------------------------------------------------

-- Scale constants
local MIN_SCALE = 0.5  -- 50%
local MAX_SCALE = 2.0  -- 200%
local DEFAULT_SCALE = 1.0  -- 100%

-- Apply scale to main frame
function MainFrameEditMode:ApplyScale() Perfy_Trace(Perfy_GetTime(), "Enter", "MainFrameEditMode:ApplyScale file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MainFrameEditMode.lua:173:0");
    local frame = BetterFriendsFrame
    if not frame then Perfy_Trace(Perfy_GetTime(), "Leave", "MainFrameEditMode:ApplyScale file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MainFrameEditMode.lua:173:0"); return end
    
    local scale = BetterFriendlistDB.windowScale or DEFAULT_SCALE
    -- Clamp between valid range
    scale = Clamp(scale, MIN_SCALE, MAX_SCALE)
    
    frame:SetScale(scale)
    -- BFL:DebugPrint("|cff00ffffBFL:MainFrameEditMode:|r Applied scale: " .. (scale * 100) .. "%")
Perfy_Trace(Perfy_GetTime(), "Leave", "MainFrameEditMode:ApplyScale file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MainFrameEditMode.lua:173:0"); end

-- Set scale and save to database
function MainFrameEditMode:SetScale(scale) Perfy_Trace(Perfy_GetTime(), "Enter", "MainFrameEditMode:SetScale file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MainFrameEditMode.lua:186:0");
    -- Clamp between valid range
    scale = Clamp(scale or DEFAULT_SCALE, MIN_SCALE, MAX_SCALE)
    
    -- Save to database
    BetterFriendlistDB.windowScale = scale
    
    -- Apply immediately
    self:ApplyScale()
Perfy_Trace(Perfy_GetTime(), "Leave", "MainFrameEditMode:SetScale file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MainFrameEditMode.lua:186:0"); end

-- Get current scale
function MainFrameEditMode:GetScale() Perfy_Trace(Perfy_GetTime(), "Enter", "MainFrameEditMode:GetScale file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MainFrameEditMode.lua:198:0");
    return Perfy_Trace_Passthrough("Leave", "MainFrameEditMode:GetScale file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MainFrameEditMode.lua:198:0", BetterFriendlistDB.windowScale or DEFAULT_SCALE)
end

--[[--------------------------------------------------
    Responsive Update Triggers
--]]--------------------------------------------------

function MainFrameEditMode:TriggerResponsiveUpdates() Perfy_Trace(Perfy_GetTime(), "Enter", "MainFrameEditMode:TriggerResponsiveUpdates file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MainFrameEditMode.lua:206:0");
    -- BFL:DebugPrint("|cffff00ffBFL:MainFrameEditMode:|r TriggerResponsiveUpdates() called")
    
    -- Update FriendsList ScrollBox extent
    if BFL.FriendsList and BFL.FriendsList.UpdateScrollBoxExtent then
        BFL.FriendsList:UpdateScrollBoxExtent()
        -- BFL:DebugPrint("  - FriendsList:UpdateScrollBoxExtent() called")
    end
    
    -- Update SearchBox width
    if BFL.FriendsList and BFL.FriendsList.UpdateSearchBoxWidth then
        BFL.FriendsList:UpdateSearchBoxWidth()
        -- BFL:DebugPrint("  - FriendsList:UpdateSearchBoxWidth() called")
    end
    
    -- Update WhoFrame responsive layout
    if BFL.WhoFrame and BFL.WhoFrame.UpdateResponsiveLayout then
        BFL.WhoFrame:UpdateResponsiveLayout()
        -- BFL:DebugPrint("  - WhoFrame:UpdateResponsiveLayout() called")
    end
    
    -- Update RaidFrame group layout (grid positioning and sizing)
    local RaidFrame = BFL.Modules and BFL.Modules.RaidFrame
    if RaidFrame and RaidFrame.UpdateGroupLayout then
        -- BFL:DebugPrint("  - Calling RaidFrame:UpdateGroupLayout()...")
        RaidFrame:UpdateGroupLayout()
        -- BFL:DebugPrint("  - RaidFrame:UpdateGroupLayout() completed")
    else
        -- BFL:DebugPrint("  - RaidFrame or UpdateGroupLayout not available")
    end
    
    -- Update RaidFrame control panel layout (AllAssist, Counts, Button positioning)
    -- Note: This is now called automatically by UpdateGroupLayout(), but we can call it separately too
    if RaidFrame and RaidFrame.UpdateControlPanelLayout then
        -- BFL:DebugPrint("  - Calling RaidFrame:UpdateControlPanelLayout()...")
        RaidFrame:UpdateControlPanelLayout()
        -- BFL:DebugPrint("  - RaidFrame:UpdateControlPanelLayout() completed")
    else
        -- BFL:DebugPrint("  - RaidFrame or UpdateControlPanelLayout not available")
    end
    
    -- BFL:DebugPrint("|cffff00ffBFL:MainFrameEditMode:|r TriggerResponsiveUpdates() finished")
Perfy_Trace(Perfy_GetTime(), "Leave", "MainFrameEditMode:TriggerResponsiveUpdates file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MainFrameEditMode.lua:206:0"); end

--[[--------------------------------------------------
    EditMode Settings (Width & Height Sliders)
--]]--------------------------------------------------

function MainFrameEditMode:CreateEditModeSettings() Perfy_Trace(Perfy_GetTime(), "Enter", "MainFrameEditMode:CreateEditModeSettings file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MainFrameEditMode.lua:254:0");
    local frame = BetterFriendsFrame
    if not frame or not LEM then Perfy_Trace(Perfy_GetTime(), "Leave", "MainFrameEditMode:CreateEditModeSettings file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MainFrameEditMode.lua:254:0"); return end
    
    -- Create settings for LibEditMode dialog (Sliders)
    local settings = {
        {
            name = BFL.L.EDITMODE_FRAME_WIDTH,
            kind = LEM.SettingType.Slider,
            default = DEFAULT_WIDTH,
            get = function(layoutName) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MainFrameEditMode.lua:264:18");
                -- Return saved width or current width
                local savedSize = BetterFriendlistDB.mainFrameSize[layoutName]
                if savedSize and savedSize.width then
                    return Perfy_Trace_Passthrough("Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MainFrameEditMode.lua:264:18", savedSize.width)
                end
                return Perfy_Trace_Passthrough("Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MainFrameEditMode.lua:264:18", frame:GetWidth())
            end,
            set = function(layoutName, value) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MainFrameEditMode.lua:272:18");
                local currentHeight = frame:GetHeight()
                
                -- Apply size
                frame:SetSize(value, currentHeight)
                
                -- Save to DB
                MainFrameEditMode:SaveSize(layoutName, value, currentHeight)
                
                -- Trigger responsive updates
                MainFrameEditMode:TriggerResponsiveUpdates()
            Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MainFrameEditMode.lua:272:18"); end,
            minValue = MIN_WIDTH,
            maxValue = MAX_WIDTH,
            valueStep = 5,
            formatter = function(value) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MainFrameEditMode.lua:287:24");
                return Perfy_Trace_Passthrough("Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MainFrameEditMode.lua:287:24", string.format("%d px", value))
            end,
        },
        {
            name = BFL.L.EDITMODE_FRAME_HEIGHT,
            kind = LEM.SettingType.Slider,
            default = DEFAULT_HEIGHT,
            get = function(layoutName) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MainFrameEditMode.lua:295:18");
                -- Return saved height or current height
                local savedSize = BetterFriendlistDB.mainFrameSize[layoutName]
                if savedSize and savedSize.height then
                    return Perfy_Trace_Passthrough("Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MainFrameEditMode.lua:295:18", savedSize.height)
                end
                return Perfy_Trace_Passthrough("Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MainFrameEditMode.lua:295:18", frame:GetHeight())
            end,
            set = function(layoutName, value) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MainFrameEditMode.lua:303:18");
                local currentWidth = frame:GetWidth()
                
                -- Apply size
                frame:SetSize(currentWidth, value)
                
                -- Save to DB
                MainFrameEditMode:SaveSize(layoutName, currentWidth, value)
                
                -- Trigger responsive updates
                MainFrameEditMode:TriggerResponsiveUpdates()
            Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MainFrameEditMode.lua:303:18"); end,
            minValue = MIN_HEIGHT,
            maxValue = MAX_HEIGHT,
            valueStep = 10,
            formatter = function(value) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MainFrameEditMode.lua:318:24");
                return Perfy_Trace_Passthrough("Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MainFrameEditMode.lua:318:24", string.format("%d px", value))
            end,
        },
        {
            name = BFL.L.SETTINGS_WINDOW_SCALE,
            kind = LEM.SettingType.Slider,
            default = 100,  -- 100%
            get = function(layoutName) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MainFrameEditMode.lua:326:18");
                -- Return saved scale as percentage (50-200)
                local scale = BetterFriendlistDB.windowScale or 1.0
                return Perfy_Trace_Passthrough("Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MainFrameEditMode.lua:326:18", math.floor(scale * 100))
            end,
            set = function(layoutName, value) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MainFrameEditMode.lua:331:18");
                -- Convert percentage to scale factor
                local scale = value / 100
                scale = math.max(MIN_SCALE, math.min(MAX_SCALE, scale))
                
                -- Save to DB
                BetterFriendlistDB.windowScale = scale
                
                -- Apply scale
                MainFrameEditMode:ApplyScale()
            Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MainFrameEditMode.lua:331:18"); end,
            minValue = 50,   -- 50%
            maxValue = 200,  -- 200%
            valueStep = 5,   -- 5% steps
            formatter = function(value) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MainFrameEditMode.lua:345:24");
                return Perfy_Trace_Passthrough("Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MainFrameEditMode.lua:345:24", string.format("%d%%", value))
            end,
        },
    }
    
    -- Register settings with LibEditMode
    LEM:AddFrameSettings(frame, settings)
    
    -- BFL:DebugPrint("|cff00ffffBFL:MainFrameEditMode:|r EditMode settings registered (Width: " .. MIN_WIDTH .. "-" .. MAX_WIDTH .. ", Height: " .. MIN_HEIGHT .. "-" .. MAX_HEIGHT .. ")")
Perfy_Trace(Perfy_GetTime(), "Leave", "MainFrameEditMode:CreateEditModeSettings file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MainFrameEditMode.lua:254:0"); end

--[[--------------------------------------------------
    Callbacks
--]]--------------------------------------------------

local function OnPositionChanged(frame, layoutName, point, x, y) Perfy_Trace(Perfy_GetTime(), "Enter", "OnPositionChanged file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MainFrameEditMode.lua:361:6");
    MainFrameEditMode:SavePosition(layoutName, point, x, y)
    MainFrameEditMode:ApplyPosition(layoutName)
Perfy_Trace(Perfy_GetTime(), "Leave", "OnPositionChanged file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MainFrameEditMode.lua:361:6"); end

function MainFrameEditMode:OnSizeChanged(frame, layoutName, width, height) Perfy_Trace(Perfy_GetTime(), "Enter", "MainFrameEditMode:OnSizeChanged file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MainFrameEditMode.lua:366:0");
    -- Save size
    self:SaveSize(layoutName, width, height)
    
    -- Apply size (with validation)
    self:ApplySize(layoutName)
Perfy_Trace(Perfy_GetTime(), "Leave", "MainFrameEditMode:OnSizeChanged file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MainFrameEditMode.lua:366:0"); end

--[[--------------------------------------------------
    Edit Mode Enter/Exit
--]]--------------------------------------------------

function MainFrameEditMode:OnEditModeEnter() Perfy_Trace(Perfy_GetTime(), "Enter", "MainFrameEditMode:OnEditModeEnter file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MainFrameEditMode.lua:378:0");
    local frame = BetterFriendsFrame
    if not frame then Perfy_Trace(Perfy_GetTime(), "Leave", "MainFrameEditMode:OnEditModeEnter file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MainFrameEditMode.lua:378:0"); return end
    
    -- Remember if frame was hidden before entering EditMode
    frame.wasHiddenBeforeEditMode = not frame:IsShown()
    
    -- Show frame in EditMode (even if user had it closed)
    -- This allows positioning/resizing even when frame is normally hidden
    if frame.wasHiddenBeforeEditMode then
        frame:Show()
    end
    
    -- BFL:DebugPrint("|cff00ffffBFL:MainFrameEditMode:|r Edit Mode entered (Settings dialog will appear on frame selection)")
Perfy_Trace(Perfy_GetTime(), "Leave", "MainFrameEditMode:OnEditModeEnter file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MainFrameEditMode.lua:378:0"); end

function MainFrameEditMode:OnEditModeExit() Perfy_Trace(Perfy_GetTime(), "Enter", "MainFrameEditMode:OnEditModeExit file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MainFrameEditMode.lua:394:0");
    local frame = BetterFriendsFrame
    if not frame then Perfy_Trace(Perfy_GetTime(), "Leave", "MainFrameEditMode:OnEditModeExit file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MainFrameEditMode.lua:394:0"); return end
    
    -- CRITICAL: Re-enable manual dragging after EditMode
    -- LibEditMode sets frame:SetMovable(false) on exit, but we need manual dragging
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    
    -- Restore previous visibility state
    -- If frame was hidden before EditMode, hide it again
    if frame.wasHiddenBeforeEditMode then
        frame:Hide()
        frame.wasHiddenBeforeEditMode = nil
    end
    
    -- BFL:DebugPrint("|cff00ffffBFL:MainFrameEditMode:|r Edit Mode exited, manual dragging re-enabled, visibility restored")
Perfy_Trace(Perfy_GetTime(), "Leave", "MainFrameEditMode:OnEditModeExit file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MainFrameEditMode.lua:394:0"); end

--[[--------------------------------------------------
    Initialization
--]]--------------------------------------------------

function MainFrameEditMode:Initialize() Perfy_Trace(Perfy_GetTime(), "Enter", "MainFrameEditMode:Initialize file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MainFrameEditMode.lua:417:0");
    -- Get frame
    local frame = BetterFriendsFrame
    if not frame then
        -- BFL:DebugPrint("|cffff0000BFL:MainFrameEditMode:|r BetterFriendsFrame not found!")
        Perfy_Trace(Perfy_GetTime(), "Leave", "MainFrameEditMode:Initialize file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MainFrameEditMode.lua:417:0"); return
    end
    
    -- MIGRATION: Import old frame position from WoW's layout-local.txt (one-time)
    -- This preserves user's frame position when upgrading to EditMode system
    self:MigrateOldPosition(frame)
    
    -- Set frame name for Edit Mode
    frame.editModeName = "BetterFriendlist"
    
    -- Set initial size immediately (since XML no longer defines <Size>)
    -- This ensures frame has correct dimensions before first show
    local layoutName = (LEM and LEM.GetActiveLayoutName and LEM.GetActiveLayoutName()) or "Default"
    local sizeData = BetterFriendlistDB.mainFrameSize and BetterFriendlistDB.mainFrameSize[layoutName]
    local width, height
    
    if sizeData then
        width, height = ValidateSize(sizeData.width, sizeData.height)
    else
        -- Use default or user-preferred size
        width = BetterFriendlistDB.defaultFrameWidth or DEFAULT_WIDTH
        height = BetterFriendlistDB.defaultFrameHeight or DEFAULT_HEIGHT
        width, height = ValidateSize(width, height)
    end
    
    frame:SetSize(width, height)
    -- BFL:DebugPrint("|cff00ffffBFL:MainFrameEditMode:|r Initial size set: " .. width .. "x" .. height)
    
    -- Enable resizing (required even with Settings dialog)
    frame:SetResizable(true)
    frame:SetResizeBounds(MIN_WIDTH, MIN_HEIGHT, MAX_WIDTH, MAX_HEIGHT)
    
    -- Hook OnShow to apply position/size BEFORE first display
    -- This ensures saved position/size is restored even without LibEditMode
    if not frame.editModeHooked then
        frame:HookScript("OnShow", function(self) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MainFrameEditMode.lua:457:35");
            -- Only apply on first show or when coming from hidden state
            if not self.editModeApplied then
                MainFrameEditMode:ApplyPosition()
                MainFrameEditMode:ApplySize()
                MainFrameEditMode:ApplyScale()  -- Feature: Window Scale
                self.editModeApplied = true
            end
        Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MainFrameEditMode.lua:457:35"); end)
        
        -- Hook OnDragStop to save position when user manually moves frame
        frame:HookScript("OnDragStop", function(self) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MainFrameEditMode.lua:468:39");
            self:StopMovingOrSizing()
            
            -- Save current position
            local layoutName = (LEM and LEM.GetActiveLayoutName and LEM.GetActiveLayoutName()) or "Default"
            local point, _, relativePoint, xOfs, yOfs = self:GetPoint()
            if point then
                MainFrameEditMode:SavePosition(layoutName, point, xOfs, yOfs)
            end
        Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MainFrameEditMode.lua:468:39"); end)
        
        -- Hook OnSizeChanged to trigger responsive updates (Phase 3)
        frame:HookScript("OnSizeChanged", function(self, width, height) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MainFrameEditMode.lua:480:42");
            -- Trigger responsive updates for FriendsList and RaidFrame
            MainFrameEditMode:TriggerResponsiveUpdates()
        Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MainFrameEditMode.lua:480:42"); end)
        
        frame.editModeHooked = true
    end
    
    -- Apply saved position & size immediately if frame is already shown
    if frame:IsShown() then
        self:ApplyPosition()
        self:ApplySize()
        self:ApplyScale()  -- Feature: Window Scale
        frame.editModeApplied = true
    end
    
    -- LibEditMode integration (optional)
    if not LEM then
        -- BFL:DebugPrint("|cffffcc00BFL:MainFrameEditMode:|r LibEditMode not found - using fixed position")
        -- BFL:DebugPrint("|cffffcc00BFL:MainFrameEditMode:|r Install LibEditMode for full Edit Mode support")
        Perfy_Trace(Perfy_GetTime(), "Leave", "MainFrameEditMode:Initialize file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MainFrameEditMode.lua:417:0"); return
    end
    
    -- Default position
    local defaults = {
        point = "CENTER",
        x = 0,
        y = 0
    }
    
    -- Register the main frame directly with LibEditMode
    LEM:AddFrame(frame, function(f, layoutName, point, x, y) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MainFrameEditMode.lua:511:24");
        MainFrameEditMode:SavePosition(layoutName, point, x, y)
        MainFrameEditMode:ApplyPosition(layoutName)
    Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MainFrameEditMode.lua:511:24"); end, defaults)
    
    -- Extend selection box to include bottom tabs
    -- LibEditMode creates a selection frame with SetAllPoints() - we need to adjust it
    local selection = LEM.frameSelections[frame]
    if selection then
        selection:ClearAllPoints()
        selection:SetPoint("TOPLEFT", frame, "TOPLEFT", -5, 10)
        selection:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 5, -35)
    end
    
    -- Create and register settings (Width & Height sliders)
    self:CreateEditModeSettings()
    
    -- Register callbacks for Edit Mode enter/exit
    LEM:RegisterCallback("enter", function() Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MainFrameEditMode.lua:529:34");
        MainFrameEditMode:OnEditModeEnter()
    Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MainFrameEditMode.lua:529:34"); end)
    
    LEM:RegisterCallback("exit", function() Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MainFrameEditMode.lua:533:33");
        MainFrameEditMode:OnEditModeExit()
    Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MainFrameEditMode.lua:533:33"); end)
    
    LEM:RegisterCallback("layout", function(layoutName) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MainFrameEditMode.lua:537:35");
        MainFrameEditMode:ApplyPosition(layoutName)
        MainFrameEditMode:ApplySize(layoutName)
    Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MainFrameEditMode.lua:537:35"); end)
    
    -- BFL:DebugPrint("|cff00ffffBFL:MainFrameEditMode:|r Edit Mode integration initialized with Width/Height settings")
Perfy_Trace(Perfy_GetTime(), "Leave", "MainFrameEditMode:Initialize file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MainFrameEditMode.lua:417:0"); end

-- Public API
BFL.MainFrameEditMode = MainFrameEditMode

Perfy_Trace(Perfy_GetTime(), "Leave", "(main chunk) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/MainFrameEditMode.lua");