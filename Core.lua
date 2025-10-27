-- Core.lua
-- Main initialization file for BetterFriendlist addon
-- Version 0.1

-- Create addon namespace
local ADDON_NAME, BFL = ...
BFL.Version = "0.1"

-- Module registry
BFL.Modules = {}

-- Register a module
function BFL:RegisterModule(name, module)
	if self.Modules[name] then
		error(string.format("Module '%s' is already registered!", name))
	end
	self.Modules[name] = module
	return module
end

-- Get a module
function BFL:GetModule(name)
	return self.Modules[name]
end

-- Core event frame
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")

-- Event handler
eventFrame:SetScript("OnEvent", function(self, event, ...)
	if event == "ADDON_LOADED" then
		local addonName = ...
		if addonName == ADDON_NAME then
			-- Initialize database
			if BFL.DB then
				BFL.DB:Initialize()
			end
			
			-- Initialize all modules
			for name, module in pairs(BFL.Modules) do
				if module.Initialize then
					module:Initialize()
				end
			end
			
			print("|cff00ff00BetterFriendlist v" .. BFL.Version .. "|r loaded successfully!")
		end
	elseif event == "PLAYER_LOGIN" then
		-- Late initialization for modules that need PLAYER_LOGIN
		for name, module in pairs(BFL.Modules) do
			if module.OnPlayerLogin then
				module:OnPlayerLogin()
			end
		end
	end
end)

-- Expose namespace globally for backward compatibility
_G.BetterFriendlist = BFL
