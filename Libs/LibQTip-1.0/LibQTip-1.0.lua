--[[Perfy has instrumented this file]] local Perfy_GetTime, Perfy_Trace, Perfy_Trace_Passthrough = Perfy_GetTime, Perfy_Trace, Perfy_Trace_Passthrough; Perfy_Trace(Perfy_GetTime(), "Enter", "(main chunk) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua"); local MAJOR = "LibQTip-1.0"
local MINOR = 49 -- Should be manually increased
local LibStub = _G.LibStub

assert(LibStub, MAJOR .. " requires LibStub")

local lib, oldMinor = LibStub:NewLibrary(MAJOR, MINOR)

if not lib then
    Perfy_Trace(Perfy_GetTime(), "Leave", "(main chunk) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua"); return
end -- No upgrade needed

------------------------------------------------------------------------------
-- Upvalued globals
------------------------------------------------------------------------------
local table = _G.table
local tinsert = table.insert
local tremove = table.remove
local wipe = table.wipe

local error = error
local math = math
local min, max = math.min, math.max
local next = next
local pairs, ipairs = pairs, ipairs
local select = select
local setmetatable = setmetatable
local tonumber, tostring = tonumber, tostring
local type = type

local CreateFrame = _G.CreateFrame
local GameTooltip = _G.GameTooltip
local UIParent = _G.UIParent

local geterrorhandler = _G.geterrorhandler

------------------------------------------------------------------------------
-- Tables and locals
------------------------------------------------------------------------------
lib.frameMetatable = lib.frameMetatable or {__index = CreateFrame("Frame")}

lib.tipPrototype = lib.tipPrototype or setmetatable({}, lib.frameMetatable)
lib.tipMetatable = lib.tipMetatable or {__index = lib.tipPrototype}

lib.providerPrototype = lib.providerPrototype or {}
lib.providerMetatable = lib.providerMetatable or {__index = lib.providerPrototype}

lib.cellPrototype = lib.cellPrototype or setmetatable({}, lib.frameMetatable)
lib.cellMetatable = lib.cellMetatable or {__index = lib.cellPrototype}

lib.activeTooltips = lib.activeTooltips or {}

lib.tooltipHeap = lib.tooltipHeap or {}
lib.frameHeap = lib.frameHeap or {}
lib.timerHeap = lib.timerHeap or {}
lib.tableHeap = lib.tableHeap or {}

lib.onReleaseHandlers = lib.onReleaseHandlers or {}

local tipPrototype = lib.tipPrototype
local tipMetatable = lib.tipMetatable

local providerPrototype = lib.providerPrototype
local providerMetatable = lib.providerMetatable

local cellPrototype = lib.cellPrototype
local cellMetatable = lib.cellMetatable

local activeTooltips = lib.activeTooltips

local highlightFrame = CreateFrame("Frame", nil, UIParent)
highlightFrame:SetFrameStrata("TOOLTIP")
highlightFrame:Hide()

local DEFAULT_HIGHLIGHT_TEXTURE_PATH = [[Interface\QuestFrame\UI-QuestTitleHighlight]]

local highlightTexture = highlightFrame:CreateTexture(nil, "OVERLAY")
highlightTexture:SetTexture(DEFAULT_HIGHLIGHT_TEXTURE_PATH)
highlightTexture:SetBlendMode("ADD")
highlightTexture:SetAllPoints(highlightFrame)

------------------------------------------------------------------------------
-- Private methods for Caches and Tooltip
------------------------------------------------------------------------------
local AcquireTooltip, ReleaseTooltip
local AcquireCell, ReleaseCell
local AcquireTable, ReleaseTable

local InitializeTooltip, SetTooltipSize, ResetTooltipSize, FixCellSizes
local ClearTooltipScripts
local SetFrameScript, ClearFrameScripts

------------------------------------------------------------------------------
-- Cache debugging.
------------------------------------------------------------------------------
-- @debug @
local usedTables, usedFrames, usedTooltips = 0, 0, 0
--@end-debug@

------------------------------------------------------------------------------
-- Internal constants to tweak the layout
------------------------------------------------------------------------------
local TOOLTIP_PADDING = 10
local CELL_MARGIN_H = 6
local CELL_MARGIN_V = 3

------------------------------------------------------------------------------
-- Public library API
------------------------------------------------------------------------------
--- Create or retrieve the tooltip with the given key.
-- If additional arguments are passed, they are passed to :SetColumnLayout for the acquired tooltip.
-- @name LibQTip:Acquire(key[, numColumns, column1Justification, column2justification, ...])
-- @param key string or table - the tooltip key. Any value that can be used as a table key is accepted though you should try to provide unique keys to avoid conflicts.
-- Numbers and booleans should be avoided and strings should be carefully chosen to avoid namespace clashes - no "MyTooltip" - you have been warned!
-- @return tooltip Frame object - the acquired tooltip.
-- @usage Acquire a tooltip with at least 5 columns, justification : left, center, left, left, left
-- <pre>local tip = LibStub('LibQTip-1.0'):Acquire('MyFooBarTooltip', 5, "LEFT", "CENTER")</pre>
function lib:Acquire(key, ...) Perfy_Trace(Perfy_GetTime(), "Enter", "lib:Acquire file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:118:0");
    if key == nil then
        error("attempt to use a nil key", 2)
    end

    local tooltip = activeTooltips[key]

    if not tooltip then
        tooltip = AcquireTooltip()
        InitializeTooltip(tooltip, key)
        activeTooltips[key] = tooltip
    end

    if select("#", ...) > 0 then
        -- Here we catch any error to properly report it for the calling code
        local ok, msg = pcall(tooltip.SetColumnLayout, tooltip, ...)

        if not ok then
            error(msg, 2)
        end
    end

    Perfy_Trace(Perfy_GetTime(), "Leave", "lib:Acquire file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:118:0"); return tooltip
end

function lib:Release(tooltip) Perfy_Trace(Perfy_GetTime(), "Enter", "lib:Release file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:143:0");
    local key = tooltip and tooltip.key

    if not key or activeTooltips[key] ~= tooltip then
        Perfy_Trace(Perfy_GetTime(), "Leave", "lib:Release file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:143:0"); return
    end

    ReleaseTooltip(tooltip)
    activeTooltips[key] = nil
Perfy_Trace(Perfy_GetTime(), "Leave", "lib:Release file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:143:0"); end

function lib:IsAcquired(key) Perfy_Trace(Perfy_GetTime(), "Enter", "lib:IsAcquired file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:154:0");
    if key == nil then
        error("attempt to use a nil key", 2)
    end

    return Perfy_Trace_Passthrough("Leave", "lib:IsAcquired file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:154:0", not (not activeTooltips[key]))
end

function lib:IterateTooltips() Perfy_Trace(Perfy_GetTime(), "Enter", "lib:IterateTooltips file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:162:0");
    return Perfy_Trace_Passthrough("Leave", "lib:IterateTooltips file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:162:0", pairs(activeTooltips))
end

------------------------------------------------------------------------------
-- Frame cache (for lines and columns)
------------------------------------------------------------------------------
local frameHeap = lib.frameHeap

local function AcquireFrame(parent) Perfy_Trace(Perfy_GetTime(), "Enter", "AcquireFrame file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:171:6");
    local frame = tremove(frameHeap) or CreateFrame("Frame", nil, nil, BackdropTemplateMixin and "BackdropTemplate")
    frame:SetParent(parent)
    --@debug@
    usedFrames = usedFrames + 1
    --@end-debug@
    Perfy_Trace(Perfy_GetTime(), "Leave", "AcquireFrame file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:171:6"); return frame
end

local function ReleaseFrame(frame) Perfy_Trace(Perfy_GetTime(), "Enter", "ReleaseFrame file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:180:6");
    frame:Hide()
    frame:SetParent(nil)
    frame:ClearAllPoints()
    frame:SetBackdrop(nil)

    ClearFrameScripts(frame)

    tinsert(frameHeap, frame)
    --@debug@
    usedFrames = usedFrames - 1
    --@end-debug@
Perfy_Trace(Perfy_GetTime(), "Leave", "ReleaseFrame file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:180:6"); end

------------------------------------------------------------------------------
-- Timer cache
------------------------------------------------------------------------------
local timerHeap = lib.timerHeap

local function AcquireTimer(parent) Perfy_Trace(Perfy_GetTime(), "Enter", "AcquireTimer file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:199:6");
    local frame = tremove(timerHeap) or CreateFrame("Frame")
    frame:SetParent(parent)
    Perfy_Trace(Perfy_GetTime(), "Leave", "AcquireTimer file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:199:6"); return frame
end

local function ReleaseTimer(frame) Perfy_Trace(Perfy_GetTime(), "Enter", "ReleaseTimer file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:205:6");
    frame:Hide()
    frame:SetParent(nil)

    ClearFrameScripts(frame)

    tinsert(timerHeap, frame)
Perfy_Trace(Perfy_GetTime(), "Leave", "ReleaseTimer file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:205:6"); end

------------------------------------------------------------------------------
-- Dirty layout handler
------------------------------------------------------------------------------
lib.layoutCleaner = lib.layoutCleaner or CreateFrame("Frame")

local layoutCleaner = lib.layoutCleaner
layoutCleaner.registry = layoutCleaner.registry or {}

function layoutCleaner:RegisterForCleanup(tooltip) Perfy_Trace(Perfy_GetTime(), "Enter", "layoutCleaner:RegisterForCleanup file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:222:0");
    self.registry[tooltip] = true
    self:Show()
Perfy_Trace(Perfy_GetTime(), "Leave", "layoutCleaner:RegisterForCleanup file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:222:0"); end

function layoutCleaner:CleanupLayouts() Perfy_Trace(Perfy_GetTime(), "Enter", "layoutCleaner:CleanupLayouts file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:227:0");
    self:Hide()

    for tooltip in pairs(self.registry) do
        FixCellSizes(tooltip)
    end

    wipe(self.registry)
Perfy_Trace(Perfy_GetTime(), "Leave", "layoutCleaner:CleanupLayouts file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:227:0"); end

layoutCleaner:SetScript("OnUpdate", layoutCleaner.CleanupLayouts)

------------------------------------------------------------------------------
-- CellProvider and Cell
------------------------------------------------------------------------------
function providerPrototype:AcquireCell() Perfy_Trace(Perfy_GetTime(), "Enter", "providerPrototype:AcquireCell file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:242:0");
    local cell = tremove(self.heap)

    if not cell then
        cell = CreateFrame("Frame", nil, UIParent, BackdropTemplateMixin and "BackdropTemplate")
        setmetatable(cell, self.cellMetatable)

        if type(cell.InitializeCell) == "function" then
            cell:InitializeCell()
        end
    end

    self.cells[cell] = true

    Perfy_Trace(Perfy_GetTime(), "Leave", "providerPrototype:AcquireCell file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:242:0"); return cell
end

function providerPrototype:ReleaseCell(cell) Perfy_Trace(Perfy_GetTime(), "Enter", "providerPrototype:ReleaseCell file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:259:0");
    if not self.cells[cell] then
        Perfy_Trace(Perfy_GetTime(), "Leave", "providerPrototype:ReleaseCell file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:259:0"); return
    end

    if type(cell.ReleaseCell) == "function" then
        cell:ReleaseCell()
    end

    self.cells[cell] = nil
    tinsert(self.heap, cell)
Perfy_Trace(Perfy_GetTime(), "Leave", "providerPrototype:ReleaseCell file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:259:0"); end

function providerPrototype:GetCellPrototype() Perfy_Trace(Perfy_GetTime(), "Enter", "providerPrototype:GetCellPrototype file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:272:0");
    return Perfy_Trace_Passthrough("Leave", "providerPrototype:GetCellPrototype file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:272:0", self.cellPrototype, self.cellMetatable)
end

function providerPrototype:IterateCells() Perfy_Trace(Perfy_GetTime(), "Enter", "providerPrototype:IterateCells file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:276:0");
    return Perfy_Trace_Passthrough("Leave", "providerPrototype:IterateCells file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:276:0", pairs(self.cells))
end

function lib:CreateCellProvider(baseProvider) Perfy_Trace(Perfy_GetTime(), "Enter", "lib:CreateCellProvider file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:280:0");
    local cellBaseMetatable, cellBasePrototype

    if baseProvider and baseProvider.GetCellPrototype then
        cellBasePrototype, cellBaseMetatable = baseProvider:GetCellPrototype()
    else
        cellBaseMetatable = cellMetatable
    end

    local newCellPrototype = setmetatable({}, cellBaseMetatable)
    local newCellProvider = setmetatable({}, providerMetatable)

    newCellProvider.heap = {}
    newCellProvider.cells = {}
    newCellProvider.cellPrototype = newCellPrototype
    newCellProvider.cellMetatable = {__index = newCellPrototype}

    Perfy_Trace(Perfy_GetTime(), "Leave", "lib:CreateCellProvider file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:280:0"); return newCellProvider, newCellPrototype, cellBasePrototype
end

------------------------------------------------------------------------------
-- Basic label provider
------------------------------------------------------------------------------
if not lib.LabelProvider then
    lib.LabelProvider, lib.LabelPrototype = lib:CreateCellProvider()
end

local labelProvider = lib.LabelProvider
local labelPrototype = lib.LabelPrototype

function labelPrototype:InitializeCell() Perfy_Trace(Perfy_GetTime(), "Enter", "labelPrototype:InitializeCell file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:310:0");
    self.fontString = self:CreateFontString()
    self.fontString:SetFontObject(_G.GameTooltipText)
Perfy_Trace(Perfy_GetTime(), "Leave", "labelPrototype:InitializeCell file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:310:0"); end

function labelPrototype:SetupCell(tooltip, value, justification, font, leftPadding, rightPadding, maxWidth, minWidth, ...) Perfy_Trace(Perfy_GetTime(), "Enter", "labelPrototype:SetupCell file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:315:0");
    local fontString = self.fontString
    local line = tooltip.lines[self._line]

    -- detatch fs from cell for size calculations
    fontString:ClearAllPoints()
    fontString:SetFontObject(font or (line.is_header and tooltip:GetHeaderFont() or tooltip:GetFont()))
    fontString:SetJustifyH(justification)
    fontString:SetText(tostring(value))

    leftPadding = leftPadding or 0
    rightPadding = rightPadding or 0

    local width = fontString:GetStringWidth() + leftPadding + rightPadding

    if maxWidth and minWidth and (maxWidth < minWidth) then
        error("maximum width cannot be lower than minimum width: " .. tostring(maxWidth) .. " < " .. tostring(minWidth), 2)
    end

    if maxWidth and (maxWidth < (leftPadding + rightPadding)) then
        error("maximum width cannot be lower than the sum of paddings: " .. tostring(maxWidth) .. " < " .. tostring(leftPadding) .. " + " .. tostring(rightPadding), 2)
    end

    if minWidth and width < minWidth then
        width = minWidth
    end

    if maxWidth and maxWidth < width then
        width = maxWidth
    end

    fontString:SetWidth(width - (leftPadding + rightPadding))
    -- Use GetHeight() instead of GetStringHeight() so lines which are longer than width will wrap.
    local height = fontString:GetHeight()

    -- reanchor fs to cell
    fontString:SetWidth(0)
    fontString:SetPoint("TOPLEFT", self, "TOPLEFT", leftPadding, 0)
    fontString:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -rightPadding, 0)
    --~ 	fs:SetPoint("TOPRIGHT", self, "TOPRIGHT", -r_pad, 0)

    self._paddingL = leftPadding
    self._paddingR = rightPadding

    Perfy_Trace(Perfy_GetTime(), "Leave", "labelPrototype:SetupCell file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:315:0"); return width, height
end

function labelPrototype:getContentHeight() Perfy_Trace(Perfy_GetTime(), "Enter", "labelPrototype:getContentHeight file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:362:0");
    local fontString = self.fontString
    fontString:SetWidth(self:GetWidth() - (self._paddingL + self._paddingR))

    local height = self.fontString:GetHeight()
    fontString:SetWidth(0)

    Perfy_Trace(Perfy_GetTime(), "Leave", "labelPrototype:getContentHeight file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:362:0"); return height
end

function labelPrototype:GetPosition() Perfy_Trace(Perfy_GetTime(), "Enter", "labelPrototype:GetPosition file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:372:0");
    return Perfy_Trace_Passthrough("Leave", "labelPrototype:GetPosition file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:372:0", self._line, self._column)
end

------------------------------------------------------------------------------
-- Tooltip cache
------------------------------------------------------------------------------
local tooltipHeap = lib.tooltipHeap

-- Returns a tooltip
function AcquireTooltip() Perfy_Trace(Perfy_GetTime(), "Enter", "AcquireTooltip file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:382:0");
    local tooltip = tremove(tooltipHeap)

    if not tooltip then
        local template = (TooltipBackdropTemplateMixin and "TooltipBackdropTemplate") or (BackdropTemplateMixin and "BackdropTemplate")
        tooltip = CreateFrame("Frame", nil, UIParent, template)

        local scrollFrame = CreateFrame("ScrollFrame", nil, tooltip)
        scrollFrame:SetPoint("TOP", tooltip, "TOP", 0, -TOOLTIP_PADDING)
        scrollFrame:SetPoint("BOTTOM", tooltip, "BOTTOM", 0, TOOLTIP_PADDING)
        scrollFrame:SetPoint("LEFT", tooltip, "LEFT", TOOLTIP_PADDING, 0)
        scrollFrame:SetPoint("RIGHT", tooltip, "RIGHT", -TOOLTIP_PADDING, 0)
        tooltip.scrollFrame = scrollFrame

        local scrollChild = CreateFrame("Frame", nil, tooltip.scrollFrame)
        scrollFrame:SetScrollChild(scrollChild)
        tooltip.scrollChild = scrollChild

        setmetatable(tooltip, tipMetatable)
    end

    --@debug@
    usedTooltips = usedTooltips + 1
    --@end-debug@
    Perfy_Trace(Perfy_GetTime(), "Leave", "AcquireTooltip file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:382:0"); return tooltip
end

-- Cleans the tooltip and stores it in the cache
function ReleaseTooltip(tooltip) Perfy_Trace(Perfy_GetTime(), "Enter", "ReleaseTooltip file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:410:0");
    if tooltip.releasing then
        Perfy_Trace(Perfy_GetTime(), "Leave", "ReleaseTooltip file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:410:0"); return
    end

    tooltip.releasing = true
    tooltip:Hide()

    local releaseHandler = lib.onReleaseHandlers[tooltip]

    if releaseHandler then
        lib.onReleaseHandlers[tooltip] = nil

        local success, errorMessage = pcall(releaseHandler, tooltip)

        if not success then
            geterrorhandler()(errorMessage)
        end
    elseif tooltip.OnRelease then
        local success, errorMessage = pcall(tooltip.OnRelease, tooltip)
        if not success then
            geterrorhandler()(errorMessage)
        end

        tooltip.OnRelease = nil
    end

    tooltip.releasing = nil
    tooltip.key = nil
    tooltip.step = nil

    ClearTooltipScripts(tooltip)

    tooltip:SetAutoHideDelay(nil)
    tooltip:ClearAllPoints()
    tooltip:Clear()

    if tooltip.slider then
        tooltip.slider:SetValue(0)
        tooltip.slider:Hide()
        tooltip.scrollFrame:SetPoint("RIGHT", tooltip, "RIGHT", -TOOLTIP_PADDING, 0)
        tooltip:EnableMouseWheel(false)
    end

    for i, column in ipairs(tooltip.columns) do
        tooltip.columns[i] = ReleaseFrame(column)
    end

    tooltip.columns = ReleaseTable(tooltip.columns)
    tooltip.lines = ReleaseTable(tooltip.lines)
    tooltip.colspans = ReleaseTable(tooltip.colspans)

    layoutCleaner.registry[tooltip] = nil

    if TooltipBackdropTemplateMixin and not tooltip.NineSlice then
        -- don't recycle outdated tooltips into heap
        tooltip = nil
    end

    if tooltip then
        tinsert(tooltipHeap, tooltip)
    end

    highlightTexture:SetTexture(DEFAULT_HIGHLIGHT_TEXTURE_PATH)
    highlightTexture:SetTexCoord(0, 1, 0, 1)

    --@debug@
    usedTooltips = usedTooltips - 1
    --@end-debug@
Perfy_Trace(Perfy_GetTime(), "Leave", "ReleaseTooltip file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:410:0"); end

------------------------------------------------------------------------------
-- Cell 'cache' (just a wrapper to the provider's cache)
------------------------------------------------------------------------------
-- Returns a cell for the given tooltip from the given provider
function AcquireCell(tooltip, provider) Perfy_Trace(Perfy_GetTime(), "Enter", "AcquireCell file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:485:0");
    local cell = provider:AcquireCell(tooltip)

    cell:SetParent(tooltip.scrollChild)
    cell:SetFrameLevel(tooltip.scrollChild:GetFrameLevel() + 3)
    cell._provider = provider

    Perfy_Trace(Perfy_GetTime(), "Leave", "AcquireCell file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:485:0"); return cell
end

-- Cleans the cell hands it to its provider for storing
function ReleaseCell(cell) Perfy_Trace(Perfy_GetTime(), "Enter", "ReleaseCell file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:496:0");
    if cell.fontString and cell.r then
        cell.fontString:SetTextColor(cell.r, cell.g, cell.b, cell.a)
    end

    cell._font = nil
    cell._justification = nil
    cell._colSpan = nil
    cell._line = nil
    cell._column = nil

    cell:Hide()
    cell:ClearAllPoints()
    cell:SetParent(nil)
    cell:SetBackdrop(nil)

    ClearFrameScripts(cell)

    cell._provider:ReleaseCell(cell)
    cell._provider = nil
Perfy_Trace(Perfy_GetTime(), "Leave", "ReleaseCell file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:496:0"); end

------------------------------------------------------------------------------
-- Table cache
------------------------------------------------------------------------------
local tableHeap = lib.tableHeap

-- Returns a table
function AcquireTable() Perfy_Trace(Perfy_GetTime(), "Enter", "AcquireTable file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:524:0");
    local tbl = tremove(tableHeap) or {}
    --@debug@
    usedTables = usedTables + 1
    --@end-debug@
    Perfy_Trace(Perfy_GetTime(), "Leave", "AcquireTable file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:524:0"); return tbl
end

-- Cleans the table and stores it in the cache
function ReleaseTable(tableInstance) Perfy_Trace(Perfy_GetTime(), "Enter", "ReleaseTable file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:533:0");
    wipe(tableInstance)
    tinsert(tableHeap, tableInstance)
    --@debug@
    usedTables = usedTables - 1
    --@end-debug@
Perfy_Trace(Perfy_GetTime(), "Leave", "ReleaseTable file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:533:0"); end

------------------------------------------------------------------------------
-- Tooltip prototype
------------------------------------------------------------------------------
function InitializeTooltip(tooltip, key) Perfy_Trace(Perfy_GetTime(), "Enter", "InitializeTooltip file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:544:0");
    ----------------------------------------------------------------------
    -- (Re)set frame settings
    ----------------------------------------------------------------------
    if TooltipBackdropTemplateMixin then
        tooltip.layoutType = GameTooltip.layoutType
        NineSlicePanelMixin.OnLoad(tooltip.NineSlice)
        if GameTooltip.layoutType then
            tooltip.NineSlice:SetCenterColor(GameTooltip.NineSlice:GetCenterColor())
            tooltip.NineSlice:SetBorderColor(GameTooltip.NineSlice:GetBorderColor())
        end
    else
        local backdrop = GameTooltip:GetBackdrop()

        tooltip:SetBackdrop(backdrop)

        if backdrop then
            tooltip:SetBackdropColor(GameTooltip:GetBackdropColor())
            tooltip:SetBackdropBorderColor(GameTooltip:GetBackdropBorderColor())
        end
    end

    tooltip:SetScale(GameTooltip:GetScale())
    tooltip:SetAlpha(1)
    tooltip:SetFrameStrata("TOOLTIP")
    tooltip:SetClampedToScreen(false)

    ----------------------------------------------------------------------
    -- Internal data. Since it's possible to Acquire twice without calling
    -- release, check for pre-existence.
    ----------------------------------------------------------------------
    tooltip.key = key
    tooltip.columns = tooltip.columns or AcquireTable()
    tooltip.lines = tooltip.lines or AcquireTable()
    tooltip.colspans = tooltip.colspans or AcquireTable()
    tooltip.regularFont = _G.GameTooltipText
    tooltip.headerFont = _G.GameTooltipHeaderText
    tooltip.labelProvider = labelProvider
    tooltip.cell_margin_h = tooltip.cell_margin_h or CELL_MARGIN_H
    tooltip.cell_margin_v = tooltip.cell_margin_v or CELL_MARGIN_V

    ----------------------------------------------------------------------
    -- Finishing procedures
    ----------------------------------------------------------------------
    tooltip:SetAutoHideDelay(nil)
    tooltip:Hide()
    ResetTooltipSize(tooltip)
Perfy_Trace(Perfy_GetTime(), "Leave", "InitializeTooltip file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:544:0"); end

function tipPrototype:SetDefaultProvider(myProvider) Perfy_Trace(Perfy_GetTime(), "Enter", "tipPrototype:SetDefaultProvider file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:593:0");
    if not myProvider then
        Perfy_Trace(Perfy_GetTime(), "Leave", "tipPrototype:SetDefaultProvider file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:593:0"); return
    end

    self.labelProvider = myProvider
Perfy_Trace(Perfy_GetTime(), "Leave", "tipPrototype:SetDefaultProvider file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:593:0"); end

function tipPrototype:GetDefaultProvider() Perfy_Trace(Perfy_GetTime(), "Enter", "tipPrototype:GetDefaultProvider file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:601:0");
    return Perfy_Trace_Passthrough("Leave", "tipPrototype:GetDefaultProvider file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:601:0", self.labelProvider)
end

local function checkJustification(justification, level, silent) Perfy_Trace(Perfy_GetTime(), "Enter", "checkJustification file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:605:6");
    if justification ~= "LEFT" and justification ~= "CENTER" and justification ~= "RIGHT" then
        if silent then
            Perfy_Trace(Perfy_GetTime(), "Leave", "checkJustification file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:605:6"); return false
        end
        error("invalid justification, must one of LEFT, CENTER or RIGHT, not: " .. tostring(justification), level + 1)
    end

    Perfy_Trace(Perfy_GetTime(), "Leave", "checkJustification file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:605:6"); return true
end

function tipPrototype:SetColumnLayout(numColumns, ...) Perfy_Trace(Perfy_GetTime(), "Enter", "tipPrototype:SetColumnLayout file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:616:0");
    if type(numColumns) ~= "number" or numColumns < 1 then
        error("number of columns must be a positive number, not: " .. tostring(numColumns), 2)
    end

    for i = 1, numColumns do
        local justification = select(i, ...) or "LEFT"

        checkJustification(justification, 2)

        if self.columns[i] then
            self.columns[i].justification = justification
        else
            self:AddColumn(justification)
        end
    end
Perfy_Trace(Perfy_GetTime(), "Leave", "tipPrototype:SetColumnLayout file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:616:0"); end

function tipPrototype:AddColumn(justification) Perfy_Trace(Perfy_GetTime(), "Enter", "tipPrototype:AddColumn file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:634:0");
    justification = justification or "LEFT"
    checkJustification(justification, 2)

    local colNum = #self.columns + 1
    local column = self.columns[colNum] or AcquireFrame(self.scrollChild)

    column:SetFrameLevel(self.scrollChild:GetFrameLevel() + 1)
    column.justification = justification
    column.width = 0
    column:SetWidth(1)
    column:SetPoint("TOP", self.scrollChild)
    column:SetPoint("BOTTOM", self.scrollChild)

    if colNum > 1 then
        local h_margin = self.cell_margin_h or CELL_MARGIN_H

        column:SetPoint("LEFT", self.columns[colNum - 1], "RIGHT", h_margin, 0)
        SetTooltipSize(self, self.width + h_margin, self.height)
    else
        column:SetPoint("LEFT", self.scrollChild)
    end

    column:Show()
    self.columns[colNum] = column

    Perfy_Trace(Perfy_GetTime(), "Leave", "tipPrototype:AddColumn file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:634:0"); return colNum
end

------------------------------------------------------------------------------
-- Convenient methods
------------------------------------------------------------------------------
function tipPrototype:Release() Perfy_Trace(Perfy_GetTime(), "Enter", "tipPrototype:Release file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:666:0");
    lib:Release(self)
Perfy_Trace(Perfy_GetTime(), "Leave", "tipPrototype:Release file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:666:0"); end

function tipPrototype:IsAcquiredBy(key) Perfy_Trace(Perfy_GetTime(), "Enter", "tipPrototype:IsAcquiredBy file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:670:0");
    return Perfy_Trace_Passthrough("Leave", "tipPrototype:IsAcquiredBy file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:670:0", key ~= nil and self.key == key)
end

------------------------------------------------------------------------------
-- Script hooks
------------------------------------------------------------------------------
local RawSetScript = lib.frameMetatable.__index.SetScript

function ClearTooltipScripts(tooltip) Perfy_Trace(Perfy_GetTime(), "Enter", "ClearTooltipScripts file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:679:0");
    if tooltip.scripts then
        for scriptType in pairs(tooltip.scripts) do
            RawSetScript(tooltip, scriptType, nil)
        end

        tooltip.scripts = ReleaseTable(tooltip.scripts)
    end
Perfy_Trace(Perfy_GetTime(), "Leave", "ClearTooltipScripts file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:679:0"); end

function tipPrototype:SetScript(scriptType, handler) Perfy_Trace(Perfy_GetTime(), "Enter", "tipPrototype:SetScript file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:689:0");
    RawSetScript(self, scriptType, handler)

    if handler then
        if not self.scripts then
            self.scripts = AcquireTable()
        end

        self.scripts[scriptType] = true
    elseif self.scripts then
        self.scripts[scriptType] = nil
    end
Perfy_Trace(Perfy_GetTime(), "Leave", "tipPrototype:SetScript file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:689:0"); end

-- That might break some addons ; those addons were breaking other
-- addons' tooltip though.
function tipPrototype:HookScript() Perfy_Trace(Perfy_GetTime(), "Enter", "tipPrototype:HookScript file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:705:0");
    geterrorhandler()(":HookScript is not allowed on LibQTip tooltips")
Perfy_Trace(Perfy_GetTime(), "Leave", "tipPrototype:HookScript file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:705:0"); end

------------------------------------------------------------------------------
-- Scrollbar data and functions
------------------------------------------------------------------------------
local BACKDROP_SLIDER_8_8 = BACKDROP_SLIDER_8_8 or {
    bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
    edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
    tile = true,
    tileEdge = true,
    tileSize = 8,
    edgeSize = 8,
    insets = { left = 3, right = 3, top = 6, bottom = 6 },
};

local function slider_OnValueChanged(self) Perfy_Trace(Perfy_GetTime(), "Enter", "slider_OnValueChanged file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:722:6");
    self.scrollFrame:SetVerticalScroll(self:GetValue())
Perfy_Trace(Perfy_GetTime(), "Leave", "slider_OnValueChanged file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:722:6"); end

local function tooltip_OnMouseWheel(self, delta) Perfy_Trace(Perfy_GetTime(), "Enter", "tooltip_OnMouseWheel file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:726:6");
    local slider = self.slider
    local currentValue = slider:GetValue()
    local minValue, maxValue = slider:GetMinMaxValues()
    local stepValue = self.step or 10

    if delta < 0 and currentValue < maxValue then
        slider:SetValue(min(maxValue, currentValue + stepValue))
    elseif delta > 0 and currentValue > minValue then
        slider:SetValue(max(minValue, currentValue - stepValue))
    end
Perfy_Trace(Perfy_GetTime(), "Leave", "tooltip_OnMouseWheel file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:726:6"); end

-- Set the step size for the scroll bar
function tipPrototype:SetScrollStep(step) Perfy_Trace(Perfy_GetTime(), "Enter", "tipPrototype:SetScrollStep file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:740:0");
    self.step = step
Perfy_Trace(Perfy_GetTime(), "Leave", "tipPrototype:SetScrollStep file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:740:0"); end

-- will resize the tooltip to fit the screen and show a scrollbar if needed
function tipPrototype:UpdateScrolling(maxheight) Perfy_Trace(Perfy_GetTime(), "Enter", "tipPrototype:UpdateScrolling file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:745:0");
    self:SetClampedToScreen(false)

    -- all data is in the tooltip; fix colspan width and prevent the layout cleaner from messing up the tooltip later
    FixCellSizes(self)
    layoutCleaner.registry[self] = nil

    local scale = self:GetScale()
    local topside = self:GetTop()
    local bottomside = self:GetBottom()
    local screensize = UIParent:GetHeight() / scale
    local tipsize = (topside - bottomside)

    -- if the tooltip would be too high, limit its height and show the slider
    if bottomside < 0 or topside > screensize or (maxheight and tipsize > maxheight) then
        local shrink = (bottomside < 0 and (5 - bottomside) or 0) + (topside > screensize and (topside - screensize + 5) or 0)

        if maxheight and tipsize - shrink > maxheight then
            shrink = tipsize - maxheight
        end

        self:SetHeight(2 * TOOLTIP_PADDING + self.height - shrink)
        self:SetWidth(2 * TOOLTIP_PADDING + self.width + 20)
        self.scrollFrame:SetPoint("RIGHT", self, "RIGHT", -(TOOLTIP_PADDING + 20), 0)

        if not self.slider then
            local slider = CreateFrame("Slider", nil, self, BackdropTemplateMixin and "BackdropTemplate")
            slider.scrollFrame = self.scrollFrame

            slider:SetOrientation("VERTICAL")
            slider:SetPoint("TOPRIGHT", self, "TOPRIGHT", -TOOLTIP_PADDING, -TOOLTIP_PADDING)
            slider:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -TOOLTIP_PADDING, TOOLTIP_PADDING)
            slider:SetBackdrop(BACKDROP_SLIDER_8_8)
            slider:SetThumbTexture([[Interface\Buttons\UI-SliderBar-Button-Vertical]])
            slider:SetMinMaxValues(0, 1)
            slider:SetValueStep(1)
            slider:SetWidth(12)
            slider:SetScript("OnValueChanged", slider_OnValueChanged)
            slider:SetValue(0)

            self.slider = slider
        end

        self.slider:SetMinMaxValues(0, shrink)
        self.slider:Show()

        self:EnableMouseWheel(true)
        self:SetScript("OnMouseWheel", tooltip_OnMouseWheel)
    else
        self:SetHeight(2 * TOOLTIP_PADDING + self.height)
        self:SetWidth(2 * TOOLTIP_PADDING + self.width)

        self.scrollFrame:SetPoint("RIGHT", self, "RIGHT", -TOOLTIP_PADDING, 0)

        if self.slider then
            self.slider:SetValue(0)
            self.slider:Hide()

            self:EnableMouseWheel(false)
            self:SetScript("OnMouseWheel", nil)
        end
    end
Perfy_Trace(Perfy_GetTime(), "Leave", "tipPrototype:UpdateScrolling file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:745:0"); end

------------------------------------------------------------------------------
-- Tooltip methods for changing its contents.
------------------------------------------------------------------------------
function tipPrototype:Clear() Perfy_Trace(Perfy_GetTime(), "Enter", "tipPrototype:Clear file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:812:0");
    for i, line in ipairs(self.lines) do
        for _, cell in pairs(line.cells) do
            if cell then
                ReleaseCell(cell)
            end
        end

        ReleaseTable(line.cells)

        line.cells = nil
        line.is_header = nil

        ReleaseFrame(line)

        self.lines[i] = nil
    end

    for _, column in ipairs(self.columns) do
        column.width = 0
        column:SetWidth(1)
    end

    wipe(self.colspans)

    self.cell_margin_h = nil
    self.cell_margin_v = nil

    ResetTooltipSize(self)
Perfy_Trace(Perfy_GetTime(), "Leave", "tipPrototype:Clear file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:812:0"); end

function tipPrototype:SetCellMarginH(size) Perfy_Trace(Perfy_GetTime(), "Enter", "tipPrototype:SetCellMarginH file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:843:0");
    if #self.lines > 0 then
        error("Unable to set horizontal margin while the tooltip has lines.", 2)
    end

    if not size or type(size) ~= "number" or size < 0 then
        error("Margin size must be a positive number or zero.", 2)
    end

    self.cell_margin_h = size
Perfy_Trace(Perfy_GetTime(), "Leave", "tipPrototype:SetCellMarginH file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:843:0"); end

function tipPrototype:SetCellMarginV(size) Perfy_Trace(Perfy_GetTime(), "Enter", "tipPrototype:SetCellMarginV file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:855:0");
    if #self.lines > 0 then
        error("Unable to set vertical margin while the tooltip has lines.", 2)
    end

    if not size or type(size) ~= "number" or size < 0 then
        error("Margin size must be a positive number or zero.", 2)
    end

    self.cell_margin_v = size
Perfy_Trace(Perfy_GetTime(), "Leave", "tipPrototype:SetCellMarginV file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:855:0"); end

function SetTooltipSize(tooltip, width, height) Perfy_Trace(Perfy_GetTime(), "Enter", "SetTooltipSize file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:867:0");
    tooltip.height = height
    tooltip.width = width

    tooltip:SetHeight(2 * TOOLTIP_PADDING + height)
    tooltip:SetWidth(2 * TOOLTIP_PADDING + width)

    tooltip.scrollChild:SetHeight(height)
    tooltip.scrollChild:SetWidth(width)
Perfy_Trace(Perfy_GetTime(), "Leave", "SetTooltipSize file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:867:0"); end

-- Add 2 pixels to height so dangling letters (g, y, p, j, etc) are not clipped.
function ResetTooltipSize(tooltip) Perfy_Trace(Perfy_GetTime(), "Enter", "ResetTooltipSize file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:879:0");
    local h_margin = tooltip.cell_margin_h or CELL_MARGIN_H

    SetTooltipSize(tooltip, max(0, (h_margin * (#tooltip.columns - 1)) + (h_margin / 2)), 2)
Perfy_Trace(Perfy_GetTime(), "Leave", "ResetTooltipSize file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:879:0"); end

local function EnlargeColumn(tooltip, column, width) Perfy_Trace(Perfy_GetTime(), "Enter", "EnlargeColumn file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:885:6");
    if width > column.width then
        SetTooltipSize(tooltip, tooltip.width + width - column.width, tooltip.height)

        column.width = width
        column:SetWidth(width)
    end
Perfy_Trace(Perfy_GetTime(), "Leave", "EnlargeColumn file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:885:6"); end

local function ResizeLine(tooltip, line, height) Perfy_Trace(Perfy_GetTime(), "Enter", "ResizeLine file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:894:6");
    SetTooltipSize(tooltip, tooltip.width, tooltip.height + height - line.height)

    line.height = height
    line:SetHeight(height)
Perfy_Trace(Perfy_GetTime(), "Leave", "ResizeLine file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:894:6"); end

function FixCellSizes(tooltip) Perfy_Trace(Perfy_GetTime(), "Enter", "FixCellSizes file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:901:0");
    local columns = tooltip.columns
    local colspans = tooltip.colspans
    local lines = tooltip.lines
    local h_margin = tooltip.cell_margin_h or CELL_MARGIN_H

    -- resize columns to make room for the colspans
    while next(colspans) do
        local maxNeedCols
        local maxNeedWidthPerCol = 0

        -- calculate the colspan with the highest additional width need per column
        for colRange, width in pairs(colspans) do
            local left, right = colRange:match("^(%d+)%-(%d+)$")

            left, right = tonumber(left), tonumber(right)

            for col = left, right - 1 do
                width = width - columns[col].width - h_margin
            end

            width = width - columns[right].width

            if width <= 0 then
                colspans[colRange] = nil
            else
                width = width / (right - left + 1)

                if width > maxNeedWidthPerCol then
                    maxNeedCols = colRange
                    maxNeedWidthPerCol = width
                end
            end
        end

        -- resize all columns for that colspan
        if maxNeedCols then
            local left, right = maxNeedCols:match("^(%d+)%-(%d+)$")

            for col = left, right do
                EnlargeColumn(tooltip, columns[col], columns[col].width + maxNeedWidthPerCol)
            end

            colspans[maxNeedCols] = nil
        end
    end

    --now that the cell width is set, recalculate the rows' height
    for _, line in ipairs(lines) do
        if #(line.cells) > 0 then
            local lineheight = 0

            for _, cell in pairs(line.cells) do
                if cell then
                    lineheight = max(lineheight, cell:getContentHeight())
                end
            end

            if lineheight > 0 then
                ResizeLine(tooltip, line, lineheight)
            end
        end
    end
Perfy_Trace(Perfy_GetTime(), "Leave", "FixCellSizes file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:901:0"); end

local function _SetCell(tooltip, lineNum, colNum, value, font, justification, colSpan, provider, ...) Perfy_Trace(Perfy_GetTime(), "Enter", "_SetCell file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:966:6");
    local line = tooltip.lines[lineNum]
    local cells = line.cells

    -- Unset: be quick
    if value == nil then
        local cell = cells[colNum]

        if cell then
            for i = colNum, colNum + cell._colSpan - 1 do
                cells[i] = nil
            end

            ReleaseCell(cell)
        end

        Perfy_Trace(Perfy_GetTime(), "Leave", "_SetCell file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:966:6"); return lineNum, colNum
    end

    font = font or (line.is_header and tooltip.headerFont or tooltip.regularFont)

    -- Check previous cell
    local cell
    local prevCell = cells[colNum]

    if prevCell then
        -- There is a cell here
        justification = justification or prevCell._justification
        colSpan = colSpan or prevCell._colSpan

        -- Clear the currently marked colspan
        for i = colNum + 1, colNum + prevCell._colSpan - 1 do
            cells[i] = nil
        end

        if provider == nil or prevCell._provider == provider then
            -- Reuse existing cell
            cell = prevCell
            provider = cell._provider
        else
            -- A new cell is required
            cells[colNum] = ReleaseCell(prevCell)
        end
    elseif prevCell == nil then
        -- Creating a new cell, using meaningful defaults.
        provider = provider or tooltip.labelProvider
        justification = justification or tooltip.columns[colNum].justification or "LEFT"
        colSpan = colSpan or 1
    else
        error("overlapping cells at column " .. colNum, 3)
    end

    local tooltipWidth = #tooltip.columns
    local rightColNum

    if colSpan > 0 then
        rightColNum = colNum + colSpan - 1

        if rightColNum > tooltipWidth then
            error("ColSpan too big, cell extends beyond right-most column", 3)
        end
    else
        -- Zero or negative: count back from right-most columns
        rightColNum = max(colNum, tooltipWidth + colSpan)
        -- Update colspan to its effective value
        colSpan = 1 + rightColNum - colNum
    end

    -- Cleanup colspans
    for i = colNum + 1, rightColNum do
        local columnCell = cells[i]

        if columnCell then
            ReleaseCell(columnCell)
        elseif columnCell == false then
            error("overlapping cells at column " .. i, 3)
        end

        cells[i] = false
    end

    -- Create the cell
    if not cell then
        cell = AcquireCell(tooltip, provider)
        cells[colNum] = cell
    end

    -- Anchor the cell
    cell:SetPoint("LEFT", tooltip.columns[colNum])
    cell:SetPoint("RIGHT", tooltip.columns[rightColNum])
    cell:SetPoint("TOP", line)
    cell:SetPoint("BOTTOM", line)

    -- Store the cell settings directly into the cell
    -- That's a bit risky but is really cheap compared to other ways to do it
    cell._font, cell._justification, cell._colSpan, cell._line, cell._column = font, justification, colSpan, lineNum, colNum

    -- Setup the cell content
    local width, height = cell:SetupCell(tooltip, value, justification, font, ...)
    cell:Show()

    if colSpan > 1 then
        -- Postpone width changes until the tooltip is shown
        local colRange = colNum .. "-" .. rightColNum

        tooltip.colspans[colRange] = max(tooltip.colspans[colRange] or 0, width)
        layoutCleaner:RegisterForCleanup(tooltip)
    else
        -- Enlarge the column and tooltip if need be
        EnlargeColumn(tooltip, tooltip.columns[colNum], width)
    end

    -- Enlarge the line and tooltip if need be
    if height > line.height then
        SetTooltipSize(tooltip, tooltip.width, tooltip.height + height - line.height)

        line.height = height
        line:SetHeight(height)
    end

    if rightColNum < tooltipWidth then
        return Perfy_Trace_Passthrough("Leave", "_SetCell file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:966:6", lineNum, rightColNum + 1)
    else
        Perfy_Trace(Perfy_GetTime(), "Leave", "_SetCell file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:966:6"); return lineNum, nil
    end
Perfy_Trace(Perfy_GetTime(), "Leave", "_SetCell file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:966:6"); end

do
    local function CreateLine(tooltip, font, ...) Perfy_Trace(Perfy_GetTime(), "Enter", "CreateLine file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:1094:10");
        if #tooltip.columns == 0 then
            error("column layout should be defined before adding line", 3)
        end

        local lineNum = #tooltip.lines + 1
        local line = tooltip.lines[lineNum] or AcquireFrame(tooltip.scrollChild)

        line:SetFrameLevel(tooltip.scrollChild:GetFrameLevel() + 2)
        line:SetPoint("LEFT", tooltip.scrollChild)
        line:SetPoint("RIGHT", tooltip.scrollChild)

        if lineNum > 1 then
            local v_margin = tooltip.cell_margin_v or CELL_MARGIN_V

            line:SetPoint("TOP", tooltip.lines[lineNum - 1], "BOTTOM", 0, -v_margin)
            SetTooltipSize(tooltip, tooltip.width, tooltip.height + v_margin)
        else
            line:SetPoint("TOP", tooltip.scrollChild)
        end

        tooltip.lines[lineNum] = line

        line.cells = line.cells or AcquireTable()
        line.height = 0
        line:SetHeight(1)
        line:Show()

        local colNum = 1

        for i = 1, #tooltip.columns do
            local value = select(i, ...)

            if value ~= nil then
                lineNum, colNum = _SetCell(tooltip, lineNum, i, value, font, nil, 1, tooltip.labelProvider)
            end
        end

        Perfy_Trace(Perfy_GetTime(), "Leave", "CreateLine file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:1094:10"); return lineNum, colNum
    end

    function tipPrototype:AddLine(...) Perfy_Trace(Perfy_GetTime(), "Enter", "tipPrototype:AddLine file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:1135:4");
        return Perfy_Trace_Passthrough("Leave", "tipPrototype:AddLine file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:1135:4", CreateLine(self, self.regularFont, ...))
    end

    function tipPrototype:AddHeader(...) Perfy_Trace(Perfy_GetTime(), "Enter", "tipPrototype:AddHeader file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:1139:4");
        local line, col = CreateLine(self, self.headerFont, ...)

        self.lines[line].is_header = true

        Perfy_Trace(Perfy_GetTime(), "Leave", "tipPrototype:AddHeader file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:1139:4"); return line, col
    end
end -- do-block

local GenericBackdrop = {
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background"
}

function tipPrototype:AddSeparator(height, r, g, b, a) Perfy_Trace(Perfy_GetTime(), "Enter", "tipPrototype:AddSeparator file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:1152:0");
    local lineNum, colNum = self:AddLine()
    local line = self.lines[lineNum]
    local color = _G.NORMAL_FONT_COLOR

    height = height or 1

    SetTooltipSize(self, self.width, self.height + height)

    line.height = height
    line:SetHeight(height)
    line:SetBackdrop(GenericBackdrop)
    line:SetBackdropColor(r or color.r, g or color.g, b or color.b, a or 1)

    Perfy_Trace(Perfy_GetTime(), "Leave", "tipPrototype:AddSeparator file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:1152:0"); return lineNum, colNum
end

function tipPrototype:SetCellColor(lineNum, colNum, r, g, b, a) Perfy_Trace(Perfy_GetTime(), "Enter", "tipPrototype:SetCellColor file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:1169:0");
    local cell = self.lines[lineNum].cells[colNum]

    if cell then
        local sr, sg, sb, sa = self:GetBackdropColor()

        cell:SetBackdrop(GenericBackdrop)
        cell:SetBackdropColor(r or sr, g or sg, b or sb, a or sa)
    end
Perfy_Trace(Perfy_GetTime(), "Leave", "tipPrototype:SetCellColor file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:1169:0"); end

function tipPrototype:SetColumnColor(colNum, r, g, b, a) Perfy_Trace(Perfy_GetTime(), "Enter", "tipPrototype:SetColumnColor file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:1180:0");
    local column = self.columns[colNum]

    if column then
        local sr, sg, sb, sa = self:GetBackdropColor()
        column:SetBackdrop(GenericBackdrop)
        column:SetBackdropColor(r or sr, g or sg, b or sb, a or sa)
    end
Perfy_Trace(Perfy_GetTime(), "Leave", "tipPrototype:SetColumnColor file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:1180:0"); end

function tipPrototype:SetLineColor(lineNum, r, g, b, a) Perfy_Trace(Perfy_GetTime(), "Enter", "tipPrototype:SetLineColor file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:1190:0");
    local line = self.lines[lineNum]

    if line then
        local sr, sg, sb, sa = self:GetBackdropColor()

        line:SetBackdrop(GenericBackdrop)
        line:SetBackdropColor(r or sr, g or sg, b or sb, a or sa)
    end
Perfy_Trace(Perfy_GetTime(), "Leave", "tipPrototype:SetLineColor file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:1190:0"); end

function tipPrototype:SetCellTextColor(lineNum, colNum, r, g, b, a) Perfy_Trace(Perfy_GetTime(), "Enter", "tipPrototype:SetCellTextColor file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:1201:0");
    local line = self.lines[lineNum]
    local column = self.columns[colNum]

    if not line or not column then
        Perfy_Trace(Perfy_GetTime(), "Leave", "tipPrototype:SetCellTextColor file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:1201:0"); return
    end

    local cell = self.lines[lineNum].cells[colNum]

    if cell then
        if not cell.fontString then
            error("cell's label provider did not assign a fontString field", 2)
        end

        if not cell.r then
            cell.r, cell.g, cell.b, cell.a = cell.fontString:GetTextColor()
        end

        cell.fontString:SetTextColor(r or cell.r, g or cell.g, b or cell.b, a or cell.a)
    end
Perfy_Trace(Perfy_GetTime(), "Leave", "tipPrototype:SetCellTextColor file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:1201:0"); end

function tipPrototype:SetColumnTextColor(colNum, r, g, b, a) Perfy_Trace(Perfy_GetTime(), "Enter", "tipPrototype:SetColumnTextColor file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:1224:0");
    if not self.columns[colNum] then
        Perfy_Trace(Perfy_GetTime(), "Leave", "tipPrototype:SetColumnTextColor file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:1224:0"); return
    end

    for lineIndex = 1, #self.lines do
        self:SetCellTextColor(lineIndex, colNum, r, g, b, a)
    end
Perfy_Trace(Perfy_GetTime(), "Leave", "tipPrototype:SetColumnTextColor file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:1224:0"); end

function tipPrototype:SetLineTextColor(lineNum, r, g, b, a) Perfy_Trace(Perfy_GetTime(), "Enter", "tipPrototype:SetLineTextColor file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:1234:0");
    local line = self.lines[lineNum]

    if not line then
        Perfy_Trace(Perfy_GetTime(), "Leave", "tipPrototype:SetLineTextColor file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:1234:0"); return
    end

    for cellIndex = 1, #line.cells do
        self:SetCellTextColor(lineNum, line.cells[cellIndex]._column, r, g, b, a)
    end
Perfy_Trace(Perfy_GetTime(), "Leave", "tipPrototype:SetLineTextColor file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:1234:0"); end

function tipPrototype:SetHighlightTexture(...) Perfy_Trace(Perfy_GetTime(), "Enter", "tipPrototype:SetHighlightTexture file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:1246:0");
    return Perfy_Trace_Passthrough("Leave", "tipPrototype:SetHighlightTexture file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:1246:0", highlightTexture:SetTexture(...))
end

function tipPrototype:SetHighlightTexCoord(...) Perfy_Trace(Perfy_GetTime(), "Enter", "tipPrototype:SetHighlightTexCoord file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:1250:0");
    highlightTexture:SetTexCoord(...)
Perfy_Trace(Perfy_GetTime(), "Leave", "tipPrototype:SetHighlightTexCoord file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:1250:0"); end

do
    local function checkFont(font, level, silent) Perfy_Trace(Perfy_GetTime(), "Enter", "checkFont file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:1255:10");
        local bad = false

        if not font then
            bad = true
        elseif type(font) == "string" then
            local ref = _G[font]

            if not ref or type(ref) ~= "table" or type(ref.IsObjectType) ~= "function" or not ref:IsObjectType("Font") then
                bad = true
            end
        elseif type(font) ~= "table" or type(font.IsObjectType) ~= "function" or not font:IsObjectType("Font") then
            bad = true
        end

        if bad then
            if silent then
                Perfy_Trace(Perfy_GetTime(), "Leave", "checkFont file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:1255:10"); return false
            end

            error("font must be a Font instance or a string matching the name of a global Font instance, not: " .. tostring(font), level + 1)
        end
        Perfy_Trace(Perfy_GetTime(), "Leave", "checkFont file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:1255:10"); return true
    end

    function tipPrototype:SetFont(font) Perfy_Trace(Perfy_GetTime(), "Enter", "tipPrototype:SetFont file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:1280:4");
        local is_string = type(font) == "string"

        checkFont(font, 2)
        self.regularFont = is_string and _G[font] or font
    Perfy_Trace(Perfy_GetTime(), "Leave", "tipPrototype:SetFont file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:1280:4"); end

    function tipPrototype:SetHeaderFont(font) Perfy_Trace(Perfy_GetTime(), "Enter", "tipPrototype:SetHeaderFont file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:1287:4");
        local is_string = type(font) == "string"

        checkFont(font, 2)
        self.headerFont = is_string and _G[font] or font
    Perfy_Trace(Perfy_GetTime(), "Leave", "tipPrototype:SetHeaderFont file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:1287:4"); end

    -- TODO: fixed argument positions / remove checks for performance?
    function tipPrototype:SetCell(lineNum, colNum, value, ...) Perfy_Trace(Perfy_GetTime(), "Enter", "tipPrototype:SetCell file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:1295:4");
        -- Mandatory argument checking
        if type(lineNum) ~= "number" then
            error("line number must be a number, not: " .. tostring(lineNum), 2)
        elseif lineNum < 1 or lineNum > #self.lines then
            error("line number out of range: " .. tostring(lineNum), 2)
        elseif type(colNum) ~= "number" then
            error("column number must be a number, not: " .. tostring(colNum), 2)
        elseif colNum < 1 or colNum > #self.columns then
            error("column number out of range: " .. tostring(colNum), 2)
        end

        -- Variable argument checking
        local font, justification, colSpan, provider
        local i, arg = 1, ...

        if arg == nil or checkFont(arg, 2, true) then
            i, font, arg = 2, ...
        end

        if arg == nil or checkJustification(arg, 2, true) then
            i, justification, arg = i + 1, select(i, ...)
        end

        if arg == nil or type(arg) == "number" then
            i, colSpan, arg = i + 1, select(i, ...)
        end

        if arg == nil or type(arg) == "table" and type(arg.AcquireCell) == "function" then
            i, provider = i + 1, arg
        end

        return Perfy_Trace_Passthrough("Leave", "tipPrototype:SetCell file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:1295:4", _SetCell(self, lineNum, colNum, value, font, justification, colSpan, provider, select(i, ...)))
    end
end -- do-block

function tipPrototype:GetFont() Perfy_Trace(Perfy_GetTime(), "Enter", "tipPrototype:GetFont file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:1331:0");
    return Perfy_Trace_Passthrough("Leave", "tipPrototype:GetFont file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:1331:0", self.regularFont)
end

function tipPrototype:GetHeaderFont() Perfy_Trace(Perfy_GetTime(), "Enter", "tipPrototype:GetHeaderFont file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:1335:0");
    return Perfy_Trace_Passthrough("Leave", "tipPrototype:GetHeaderFont file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:1335:0", self.headerFont)
end

function tipPrototype:GetLineCount() Perfy_Trace(Perfy_GetTime(), "Enter", "tipPrototype:GetLineCount file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:1339:0");
    return Perfy_Trace_Passthrough("Leave", "tipPrototype:GetLineCount file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:1339:0", #self.lines)
end

function tipPrototype:GetColumnCount() Perfy_Trace(Perfy_GetTime(), "Enter", "tipPrototype:GetColumnCount file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:1343:0");
    return Perfy_Trace_Passthrough("Leave", "tipPrototype:GetColumnCount file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:1343:0", #self.columns)
end

------------------------------------------------------------------------------
-- Frame Scripts
------------------------------------------------------------------------------
local scripts = {
    OnEnter = function(frame, ...) Perfy_Trace(Perfy_GetTime(), "Enter", "scripts.OnEnter file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:1351:14");
        highlightFrame:SetParent(frame)
        highlightFrame:SetAllPoints(frame)
        highlightFrame:Show()

        if frame._OnEnter_func then
            frame:_OnEnter_func(frame._OnEnter_arg, ...)
        end
    Perfy_Trace(Perfy_GetTime(), "Leave", "scripts.OnEnter file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:1351:14"); end,
    OnLeave = function(frame, ...) Perfy_Trace(Perfy_GetTime(), "Enter", "scripts.OnLeave file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:1360:14");
        highlightFrame:Hide()
        highlightFrame:ClearAllPoints()
        highlightFrame:SetParent(nil)

        if frame._OnLeave_func then
            frame:_OnLeave_func(frame._OnLeave_arg, ...)
        end
    Perfy_Trace(Perfy_GetTime(), "Leave", "scripts.OnLeave file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:1360:14"); end,
    OnMouseDown = function(frame, ...) Perfy_Trace(Perfy_GetTime(), "Enter", "scripts.OnMouseDown file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:1369:18");
        frame:_OnMouseDown_func(frame._OnMouseDown_arg, ...)
    Perfy_Trace(Perfy_GetTime(), "Leave", "scripts.OnMouseDown file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:1369:18"); end,
    OnMouseUp = function(frame, ...) Perfy_Trace(Perfy_GetTime(), "Enter", "scripts.OnMouseUp file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:1372:16");
        frame:_OnMouseUp_func(frame._OnMouseUp_arg, ...)
    Perfy_Trace(Perfy_GetTime(), "Leave", "scripts.OnMouseUp file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:1372:16"); end,
    OnReceiveDrag = function(frame, ...) Perfy_Trace(Perfy_GetTime(), "Enter", "scripts.OnReceiveDrag file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:1375:20");
        frame:_OnReceiveDrag_func(frame._OnReceiveDrag_arg, ...)
    Perfy_Trace(Perfy_GetTime(), "Leave", "scripts.OnReceiveDrag file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:1375:20"); end
}

function SetFrameScript(frame, script, func, arg) Perfy_Trace(Perfy_GetTime(), "Enter", "SetFrameScript file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:1380:0");
    if not scripts[script] then
        Perfy_Trace(Perfy_GetTime(), "Leave", "SetFrameScript file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:1380:0"); return
    end

    frame["_" .. script .. "_func"] = func
    frame["_" .. script .. "_arg"] = arg

    if script == "OnMouseDown" or script == "OnMouseUp" or script == "OnReceiveDrag" then
        if func then
            frame:SetScript(script, scripts[script])
        else
            frame:SetScript(script, nil)
        end
    end

    -- if at least one script is set, set the OnEnter/OnLeave scripts for the highlight
    if frame._OnEnter_func or frame._OnLeave_func or frame._OnMouseDown_func or frame._OnMouseUp_func or frame._OnReceiveDrag_func then
        frame:EnableMouse(true)
        frame:SetScript("OnEnter", scripts.OnEnter)
        frame:SetScript("OnLeave", scripts.OnLeave)
    else
        frame:EnableMouse(false)
        frame:SetScript("OnEnter", nil)
        frame:SetScript("OnLeave", nil)
    end
Perfy_Trace(Perfy_GetTime(), "Leave", "SetFrameScript file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:1380:0"); end

function ClearFrameScripts(frame) Perfy_Trace(Perfy_GetTime(), "Enter", "ClearFrameScripts file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:1408:0");
    if frame._OnEnter_func or frame._OnLeave_func or frame._OnMouseDown_func or frame._OnMouseUp_func or frame._OnReceiveDrag_func then
        frame:EnableMouse(false)

        frame:SetScript("OnEnter", nil)
        frame._OnEnter_func = nil
        frame._OnEnter_arg = nil

        frame:SetScript("OnLeave", nil)
        frame._OnLeave_func = nil
        frame._OnLeave_arg = nil

        frame:SetScript("OnReceiveDrag", nil)
        frame._OnReceiveDrag_func = nil
        frame._OnReceiveDrag_arg = nil

        frame:SetScript("OnMouseDown", nil)
        frame._OnMouseDown_func = nil
        frame._OnMouseDown_arg = nil

        frame:SetScript("OnMouseUp", nil)
        frame._OnMouseUp_func = nil
        frame._OnMouseUp_arg = nil
    end
Perfy_Trace(Perfy_GetTime(), "Leave", "ClearFrameScripts file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:1408:0"); end

function tipPrototype:SetLineScript(lineNum, script, func, arg) Perfy_Trace(Perfy_GetTime(), "Enter", "tipPrototype:SetLineScript file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:1434:0");
    SetFrameScript(self.lines[lineNum], script, func, arg)
Perfy_Trace(Perfy_GetTime(), "Leave", "tipPrototype:SetLineScript file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:1434:0"); end

function tipPrototype:SetColumnScript(colNum, script, func, arg) Perfy_Trace(Perfy_GetTime(), "Enter", "tipPrototype:SetColumnScript file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:1438:0");
    SetFrameScript(self.columns[colNum], script, func, arg)
Perfy_Trace(Perfy_GetTime(), "Leave", "tipPrototype:SetColumnScript file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:1438:0"); end

function tipPrototype:SetCellScript(lineNum, colNum, script, func, arg) Perfy_Trace(Perfy_GetTime(), "Enter", "tipPrototype:SetCellScript file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:1442:0");
    local cell = self.lines[lineNum].cells[colNum]

    if cell then
        SetFrameScript(cell, script, func, arg)
    end
Perfy_Trace(Perfy_GetTime(), "Leave", "tipPrototype:SetCellScript file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:1442:0"); end

------------------------------------------------------------------------------
-- Auto-hiding feature
------------------------------------------------------------------------------

-- Script of the auto-hiding child frame
local function AutoHideTimerFrame_OnUpdate(self, elapsed) Perfy_Trace(Perfy_GetTime(), "Enter", "AutoHideTimerFrame_OnUpdate file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:1455:6");
    self.checkElapsed = self.checkElapsed + elapsed

    if self.checkElapsed > 0.1 then
        if self.parent:IsMouseOver() or (self.alternateFrame and self.alternateFrame:IsMouseOver()) then
            self.elapsed = 0
        else
            self.elapsed = self.elapsed + self.checkElapsed

            if self.elapsed >= self.delay then
                lib:Release(self.parent)
            end
        end

        self.checkElapsed = 0
    end
Perfy_Trace(Perfy_GetTime(), "Leave", "AutoHideTimerFrame_OnUpdate file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:1455:6"); end

-- Usage:
-- :SetAutoHideDelay(0.25) => hides after 0.25sec outside of the tooltip
-- :SetAutoHideDelay(0.25, someFrame) => hides after 0.25sec outside of both the tooltip and someFrame
-- :SetAutoHideDelay() => disable auto-hiding (default)
function tipPrototype:SetAutoHideDelay(delay, alternateFrame, releaseHandler) Perfy_Trace(Perfy_GetTime(), "Enter", "tipPrototype:SetAutoHideDelay file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:1477:0");
    local timerFrame = self.autoHideTimerFrame
    delay = tonumber(delay) or 0

    if releaseHandler then
        if type(releaseHandler) ~= "function" then
            error("releaseHandler must be a function", 2)
        end

        lib.onReleaseHandlers[self] = releaseHandler
    end

    if delay > 0 then
        if not timerFrame then
            timerFrame = AcquireTimer(self)
            timerFrame:SetScript("OnUpdate", AutoHideTimerFrame_OnUpdate)

            self.autoHideTimerFrame = timerFrame
        end

        timerFrame.parent = self
        timerFrame.checkElapsed = 0
        timerFrame.elapsed = 0
        timerFrame.delay = delay
        timerFrame.alternateFrame = alternateFrame
        timerFrame:Show()
    elseif timerFrame then
        self.autoHideTimerFrame = nil

        timerFrame.alternateFrame = nil
        timerFrame:SetScript("OnUpdate", nil)

        ReleaseTimer(timerFrame)
    end
Perfy_Trace(Perfy_GetTime(), "Leave", "tipPrototype:SetAutoHideDelay file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:1477:0"); end

------------------------------------------------------------------------------
-- "Smart" Anchoring
------------------------------------------------------------------------------
local function GetTipAnchor(frame) Perfy_Trace(Perfy_GetTime(), "Enter", "GetTipAnchor file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:1516:6");
    local x, y = frame:GetCenter()

    if not x or not y then
        Perfy_Trace(Perfy_GetTime(), "Leave", "GetTipAnchor file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:1516:6"); return "TOPLEFT", "BOTTOMLEFT"
    end

    local hhalf = (x > UIParent:GetWidth() * 2 / 3) and "RIGHT" or (x < UIParent:GetWidth() / 3) and "LEFT" or ""
    local vhalf = (y > UIParent:GetHeight() / 2) and "TOP" or "BOTTOM"

    return Perfy_Trace_Passthrough("Leave", "GetTipAnchor file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:1516:6", vhalf .. hhalf, frame, (vhalf == "TOP" and "BOTTOM" or "TOP") .. hhalf)
end

function tipPrototype:SmartAnchorTo(frame) Perfy_Trace(Perfy_GetTime(), "Enter", "tipPrototype:SmartAnchorTo file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:1529:0");
    if not frame then
        error("Invalid frame provided.", 2)
    end

    self:ClearAllPoints()
    self:SetClampedToScreen(true)
    self:SetPoint(GetTipAnchor(frame))
Perfy_Trace(Perfy_GetTime(), "Leave", "tipPrototype:SmartAnchorTo file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:1529:0"); end

------------------------------------------------------------------------------
-- Debug slashcmds
------------------------------------------------------------------------------
-- @debug @
local print = print
local function PrintStats() Perfy_Trace(Perfy_GetTime(), "Enter", "PrintStats file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:1544:6");
    local tipCache = tostring(#tooltipHeap)
    local frameCache = tostring(#frameHeap)
    local tableCache = tostring(#tableHeap)
    local header = false

    print("Tooltips used: " .. usedTooltips .. ", Cached: " .. tipCache .. ", Total: " .. tipCache + usedTooltips)
    print("Frames used: " .. usedFrames .. ", Cached: " .. frameCache .. ", Total: " .. frameCache + usedFrames)
    print("Tables used: " .. usedTables .. ", Cached: " .. tableCache .. ", Total: " .. tableCache + usedTables)

    for k in pairs(activeTooltips) do
        if not header then
            print("Active tooltips:")
            header = true
        end
        print("- " .. k)
    end
Perfy_Trace(Perfy_GetTime(), "Leave", "PrintStats file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua:1544:6"); end

SLASH_LibQTip1 = "/qtip"
_G.SlashCmdList["LibQTip"] = PrintStats
--@end-debug@

Perfy_Trace(Perfy_GetTime(), "Leave", "(main chunk) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibQTip-1.0/LibQTip-1.0.lua");