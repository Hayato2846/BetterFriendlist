local ADDON_NAME, BFL = ...
local FrameSettings = BFL:RegisterModule("FrameSettings", {})

-- Constants for Limits
local MIN_WIDTH = 380
local MAX_WIDTH = 800
local MIN_HEIGHT = 400
local MAX_HEIGHT = 1200
local MIN_SCALE = 0.5
local MAX_SCALE = 2.0

-- Layout key for storage (removing complexity of multiple layouts)
local LAYOUT_KEY = "Default"

function FrameSettings:Initialize()
    self.db = BetterFriendlistDB

    -- Ensure DB structures exist
    if not self.db.mainFrameSize then self.db.mainFrameSize = {} end
    if not self.db.mainFramePosition then self.db.mainFramePosition = {} end
    if not self.db.windowScale then self.db.windowScale = 1.0 end
    if self.db.lockWindow == nil then self.db.lockWindow = false end
    
    -- Ensure "Default" entries exist
    if not self.db.mainFrameSize[LAYOUT_KEY] then
        self.db.mainFrameSize[LAYOUT_KEY] = {
            width = self.db.defaultFrameWidth or 415,
            height = self.db.defaultFrameHeight or 570
        }
    end

    -- Hook MainFrame movement to save position
    -- Fix: Ensure BFL.MainFrame is set
    if not BFL.MainFrame and _G.BetterFriendsFrame then
        BFL.MainFrame = _G.BetterFriendsFrame
    end

    if BFL.MainFrame then
        local frame = BFL.MainFrame
        
        -- Apply initial settings
        self:ApplySettings()

        -- Hook for saving position after drag
        frame:HookScript("OnDragStop", function()
            self:SavePosition()
        end)
        
        -- Also hook OnMouseUp as a backup if OnDragStop isn't reliably firing for custom frames
        frame:HookScript("OnMouseUp", function()
            if frame.isMoving then
                self:SavePosition()
            end
        end)
    end
end

function FrameSettings:ApplySettings()
    if not BFL.MainFrame then return end
    
    self:ApplySize()
    self:ApplyScale()
    self:ApplyPosition()
    self:ApplyLock()
end

function FrameSettings:ApplyLock(locked)
    local frame = BFL.MainFrame
    if not frame then return end

    local isLocked = locked
    if isLocked == nil then
        isLocked = self.db.lockWindow
    end
    
    -- Save if explicitly changed
    if locked ~= nil then
        self.db.lockWindow = locked
    end

    frame:SetMovable(not isLocked)
    if isLocked then
        frame:RegisterForDrag() -- Unregister drag events
    else
        frame:RegisterForDrag("LeftButton")
    end
end

function FrameSettings:ApplySize(bgWidth, bgHeight)
    local frame = BFL.MainFrame
    if not frame then return end

    local currentSize = self.db.mainFrameSize[LAYOUT_KEY]
    local width = bgWidth or currentSize.width
    local height = bgHeight or currentSize.height

    -- Clamp values
    width = math.max(MIN_WIDTH, math.min(MAX_WIDTH, width))
    height = math.max(MIN_HEIGHT, math.min(MAX_HEIGHT, height))

    -- Save if explicitly changed (bgWidth/Height passed)
    if bgWidth or bgHeight then
        currentSize.width = width
        currentSize.height = height
    end

    frame:SetSize(width, height)
    -- BFL:DebugPrint("FrameSettings: Applied size " .. width .. "x" .. height)
end

function FrameSettings:ApplyScale(scale)
    local frame = BFL.MainFrame
    if not frame then return end

    local newScale = scale or self.db.windowScale
    -- Clamp values
    newScale = math.max(MIN_SCALE, math.min(MAX_SCALE, newScale))

    -- Save if explicitly changed
    if scale then
        self.db.windowScale = newScale
    end

    frame:SetScale(newScale)
    -- BFL:DebugPrint("FrameSettings: Applied scale " .. newScale)
end

function FrameSettings:ApplyPosition()
    local frame = BFL.MainFrame
    if not frame then return end

    local pos = self.db.mainFramePosition[LAYOUT_KEY]
    if pos and pos.point then
        frame:ClearAllPoints()
        -- Safety check for bad coordinates
        local x = pos.x or 0
        local y = pos.y or 0
        if math.abs(x) > 5000 or math.abs(y) > 5000 then
            x, y = 0, 0
        end
        frame:SetPoint(pos.point, UIParent, pos.relativePoint or pos.point, x, y)
    else
        -- Default position if nothing saved
        frame:ClearAllPoints()
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
end

function FrameSettings:SavePosition()
    local frame = BFL.MainFrame
    if not frame then return end

    local point, _, relativePoint, x, y = frame:GetPoint()
    
    if point then
        self.db.mainFramePosition[LAYOUT_KEY] = {
            point = point,
            relativePoint = relativePoint,
            x = x,
            y = y
        }
        -- BFL:DebugPrint("FrameSettings: Position saved")
    end
end

function FrameSettings:ResetDefaults()
    -- Reset to defaults defined in Database.lua indirectly
    self.db.windowScale = 1.0
    self.db.mainFrameSize[LAYOUT_KEY] = {
        width = 415,
        height = 570
    }
    
    -- Reset position to center
    self.db.mainFramePosition[LAYOUT_KEY] = {
        point = "CENTER",
        relativePoint = "CENTER",
        x = 0,
        y = 0
    }

    self:ApplySettings()
    print("|cff00ff00BetterFriendlist:|r Frame settings reset to defaults.")
end
