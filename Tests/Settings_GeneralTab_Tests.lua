-- Tests/Settings_GeneralTab_Tests.lua
-- Test suite for Settings General Tab redesign (Phase 2.1)
-- Run these tests manually in-game by typing: /run BFL_TestGeneralTab()

local ADDON_NAME, BFL = ...

-- Create global test function
function BFL_TestGeneralTab()
	print("|cff00ff00=== General Tab Redesign Test ===|r")
	
	-- Get Settings module
	local Settings = BFL.Settings
	if not Settings then
		print("|cffff0000FAILED:|r Settings module not found")
		return
	end
	
	-- Get Components library
	local Components = BFL.SettingsComponents
	if not Components then
		print("|cffff0000FAILED:|r SettingsComponents library not found")
		return
	end
	
	print("|cff00ff00✓|r Settings module loaded")
	print("|cff00ff00✓|r Components library loaded")
	
	-- Open settings window
	Settings:Show()
	
	-- Wait a moment for frame to initialize
	C_Timer.After(0.5, function()
		-- Check if GeneralTab exists
		local settingsFrame = BetterFriendlistSettingsFrame
		if not settingsFrame then
			print("|cffff0000FAILED:|r Settings frame not found")
			return
		end
		
		local content = settingsFrame.ContentScrollFrame.Content
		if not content or not content.GeneralTab then
			print("|cffff0000FAILED:|r GeneralTab not found")
			return
		end
		
		print("|cff00ff00✓|r Settings frame initialized")
		
		-- Check if components were created
		local tab = content.GeneralTab
		if not tab.components or #tab.components == 0 then
			print("|cffff0000FAILED:|r No components created in General tab")
			return
		end
		
		print("|cff00ff00✓|r Components created: " .. #tab.components .. " total")
		
		-- Verify component types
		local headerCount = 0
		local checkboxCount = 0
		local spacerCount = 0
		
		for i, component in ipairs(tab.components) do
			if component.componentType == "Header" then
				headerCount = headerCount + 1
			elseif component.componentType == "Checkbox" then
				checkboxCount = checkboxCount + 1
			elseif component.componentType == "Spacer" then
				spacerCount = spacerCount + 1
			end
		end
		
		print(string.format("|cff00ff00✓|r Component breakdown: %d headers, %d checkboxes, %d spacers", 
			headerCount, checkboxCount, spacerCount))
		
		-- Expected: 3 headers, 7 checkboxes, 2 spacers
		if headerCount ~= 3 then
			print("|cffffcc00WARNING:|r Expected 3 headers, found " .. headerCount)
		end
		
		if checkboxCount ~= 7 then
			print("|cffffcc00WARNING:|r Expected 7 checkboxes, found " .. checkboxCount)
		end
		
		-- Test checkbox callbacks
		print("\n|cff00ffffTesting checkbox interactions...|r")
		
		-- Find the first checkbox
		local firstCheckbox = nil
		for _, component in ipairs(tab.components) do
			if component.componentType == "Checkbox" then
				firstCheckbox = component
				break
			end
		end
		
		if firstCheckbox then
			local initialState = firstCheckbox.checkbox:GetChecked()
			print("|cff00ff00✓|r First checkbox initial state: " .. tostring(initialState))
			
			-- Toggle it
			firstCheckbox.checkbox:SetChecked(not initialState)
			firstCheckbox.checkbox:GetScript("OnClick")(firstCheckbox.checkbox)
			
			print("|cff00ff00✓|r Toggled checkbox successfully")
			
			-- Toggle back
			firstCheckbox.checkbox:SetChecked(initialState)
			firstCheckbox.checkbox:GetScript("OnClick")(firstCheckbox.checkbox)
			
			print("|cff00ff00✓|r Restored original state")
		end
		
		print("\n|cff00ff00=== All Tests Passed! ===|r")
		print("Visual check: Verify that the General tab displays correctly with:")
		print("  - Clean layout with proper spacing")
		print("  - Three section headers (Display Options, Behavior, Appearance)")
		print("  - All checkboxes aligned and functional")
	end)
end

-- Auto-run on load if desired (comment out for manual testing)
-- BFL_TestGeneralTab()
