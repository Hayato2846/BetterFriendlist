--[[Perfy has instrumented this file]] local Perfy_GetTime, Perfy_Trace, Perfy_Trace_Passthrough = Perfy_GetTime, Perfy_Trace, Perfy_Trace_Passthrough; Perfy_Trace(Perfy_GetTime(), "Enter", "(main chunk) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/FontFix.lua"); -- Modules/FontFix.lua
-- Enforces fixed font sizes for critical UI elements
-- Prevents layout issues when ElvUI or other addons scale global fonts

local ADDON_NAME, BFL = ...
local FontFix = BFL:RegisterModule("FontFix", {})

function FontFix:Initialize() Perfy_Trace(Perfy_GetTime(), "Enter", "FontFix:Initialize file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/FontFix.lua:8:0");
    -- Apply immediately
    self:ApplyFixedFonts()

    -- Also apply after a short delay to handle other addons loading/changing fonts
    C_Timer.After(1, function() Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/FontFix.lua:13:21");
        self:ApplyFixedFonts()
    Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/FontFix.lua:13:21"); end)
    
    -- And if ElvUI updates media
    if _G.ElvUI then
        local E = unpack(_G.ElvUI)
        if E and E.UpdateMedia then
            hooksecurefunc(E, "UpdateMedia", function() Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/FontFix.lua:21:45");
                self:ApplyFixedFonts()
            Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/FontFix.lua:21:45"); end)
        end
    end
Perfy_Trace(Perfy_GetTime(), "Leave", "FontFix:Initialize file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/FontFix.lua:8:0"); end

function FontFix:ApplyFixedFonts() Perfy_Trace(Perfy_GetTime(), "Enter", "FontFix:ApplyFixedFonts file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/FontFix.lua:28:0");
    local frame = _G.BetterFriendsFrame
    if not frame then Perfy_Trace(Perfy_GetTime(), "Leave", "FontFix:ApplyFixedFonts file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/FontFix.lua:28:0"); return end
    
    BFL:DebugPrint("FontFix: Applying fixed fonts to UI elements")
    
    local fontName = "BetterFriendlistFixedSmallFont"
    
    -- 1. Tabs
    for i = 1, 10 do
        local tab = _G["BetterFriendsFrameTab"..i]
        if tab then
            if tab.SetNormalFontObject then
                tab:SetNormalFontObject(fontName)
                tab:SetHighlightFontObject(fontName)
                tab:SetDisabledFontObject(fontName)
            end
            
            local fs = tab.Text or (tab.GetFontString and tab:GetFontString())
            if fs then
                fs:SetFontObject(fontName)
            end
            
            -- Classic/Legacy named regions
            if tab:GetName() then
                local namedText = _G[tab:GetName().."Text"]
                if namedText then
                    namedText:SetFontObject(fontName)
                end
            end
        end
    end
    
    -- 2. Dropdowns
    if frame.FriendsTabHeader then
        local dropdowns = {
            frame.FriendsTabHeader.StatusDropdown,
            frame.FriendsTabHeader.QuickFilterDropdown,
            frame.FriendsTabHeader.PrimarySortDropdown,
            frame.FriendsTabHeader.SecondarySortDropdown
        }
        
        for _, dropdown in pairs(dropdowns) do
            if dropdown then
                if dropdown.SetNormalFontObject then
                    dropdown:SetNormalFontObject(fontName)
                    dropdown:SetHighlightFontObject(fontName)
                    dropdown:SetDisabledFontObject(fontName)
                end
                
                local fs = dropdown.Text or (dropdown.GetFontString and dropdown:GetFontString())
                if fs then
                    fs:SetFontObject(fontName)
                end
            end
        end
    end
Perfy_Trace(Perfy_GetTime(), "Leave", "FontFix:ApplyFixedFonts file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/FontFix.lua:28:0"); end

Perfy_Trace(Perfy_GetTime(), "Leave", "(main chunk) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Modules/FontFix.lua");