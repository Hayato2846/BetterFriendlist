-- Modules/FontFix.lua
-- Enforces fixed font sizes for critical UI elements
-- Prevents layout issues when ElvUI or other addons scale global fonts

local ADDON_NAME, BFL = ...
local FontFix = BFL:RegisterModule("FontFix", {})

function FontFix:Initialize()
    -- Apply immediately
    self:ApplyFixedFonts()

    -- Also apply after a short delay to handle other addons loading/changing fonts
    C_Timer.After(1, function()
        self:ApplyFixedFonts()
    end)
    
    -- And if ElvUI updates media
    if _G.ElvUI then
        local E = unpack(_G.ElvUI)
        if E and E.UpdateMedia then
            hooksecurefunc(E, "UpdateMedia", function()
                self:ApplyFixedFonts()
            end)
        end
    end
end

function FontFix:ApplyFixedFonts()
    local frame = _G.BetterFriendsFrame
    if not frame then return end
    
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
end
