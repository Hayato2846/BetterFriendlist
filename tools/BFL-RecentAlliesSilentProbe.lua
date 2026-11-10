-- Retail QA only. Append after the deployed RecentAllies module for a live test.
do
	local addonName, BFL = ...
	local host, list, button, run
	local hooked = false
	local prefix = "[BFL-RA-SILENT]"

	local function Report(...)
		local parts = { prefix }
		for index = 1, select("#", ...) do
			parts[#parts + 1] = tostring((select(index, ...)))
		end
		DEFAULT_CHAT_FRAME:AddMessage(table.concat(parts, " "))
	end

	local function Finish(state, reason)
		if run ~= state then return end
		if not InCombatLockdown() then
			button:Hide()
			host:Hide()
		end
		run = nil
		Report(reason, "OnShow =", state.shows, "Request-Aufrufe =", state.requests,
			"Cache-Events =", state.cacheEvents, "UI-Töne =", state.sounds, "Blockaden =", state.blocked)
	end

	local function Setup()
		C_AddOns.LoadAddOn("Blizzard_RecentAllies")
		local container = CreateFrame("Frame", nil, UIParent, "SecureFrameTemplate")
		container:Hide()
		container:SetAlpha(0)
		container:SetSize(300, 260)
		container:SetPoint("BOTTOMRIGHT", UIParent, "TOPLEFT", -64, 64)
		local view = CreateFrame("Frame", nil, container, "RecentAlliesListTemplate")
		view:SetAllPoints()
		view:HookScript("OnShow", function()
			if run then run.shows = run.shows + 1 end
		end)

		local trigger = CreateFrame("Button", nil, UIParent, "SecureHandlerClickTemplate,SecureHandlerStateTemplate")
		trigger:Hide()
		trigger:SetSize(210, 32)
		trigger:SetPoint("CENTER", UIParent, "CENTER")
		trigger:SetFrameStrata("DIALOG")
		trigger:SetNormalTexture("Interface/Buttons/UI-Panel-Button-Up")
		trigger:SetHighlightTexture("Interface/Buttons/UI-Panel-Button-Highlight")
		trigger:SetNormalFontObject("GameFontNormal")
		trigger:SetText("Recent Allies Silent Test")
		trigger:RegisterForClicks("LeftButtonUp")
		trigger:SetFrameRef("viewHost", container)
		trigger:SetAttribute("_onclick", [[
			if button == "LeftButton" and not down then
				self:GetFrameRef("viewHost"):Show(true)
			end
		]])
		trigger:SetAttribute("_onstate-combat", [[
			if newstate == "combat" then
				self:Hide()
				self:GetFrameRef("viewHost"):Hide(true)
			end
		]])
		RegisterStateDriver(trigger, "combat", "[combat] combat; nocombat")
		trigger:SetScript("PostClick", function()
			local state = run
			if not state then return end
			trigger:Hide()
			Report("Klick angekommen. Native Ansicht sichtbar =", tostring(view:IsVisible()))
			C_Timer.After(5, function() Finish(state, "Messung beendet.") end)
		end)
		host, list, button = container, view, trigger
	end

	local events = CreateFrame("Frame")
	events:RegisterEvent("RECENT_ALLIES_CACHE_UPDATE")
	events:RegisterEvent("RECENT_ALLIES_DATA_READY")
	events:RegisterEvent("ADDON_ACTION_BLOCKED")
	events:RegisterEvent("ADDON_ACTION_FORBIDDEN")
	events:RegisterEvent("PLAYER_REGEN_DISABLED")
	events:SetScript("OnEvent", function(_, event, name, action)
		local state = run
		if not state then return end
		if event == "PLAYER_REGEN_DISABLED" then
			Finish(state, "Test bei Kampfbeginn beendet.")
		elseif event == "ADDON_ACTION_BLOCKED" or event == "ADDON_ACTION_FORBIDDEN" then
			if not BFL:IsSecret(name) and not BFL:IsSecret(action)
				and (name == addonName or (type(action) == "string" and action:find("TryRequestRecentAlliesData", 1, true)))
			then
				state.blocked = state.blocked + 1
				Report(event, name, action)
			end
		elseif list:IsVisible() then
			state.cacheEvents = state.cacheEvents + 1
			Report(event)
		end
	end)

	SLASH_BFLRECENTALLIESSILENTPROBE1 = "/bflrasilent"
	SlashCmdList.BFLRECENTALLIESSILENTPROBE = function()
		if InCombatLockdown() then
			Report("Bitte außerhalb des Kampfes testen.")
			return
		end
		if run then
			Finish(run, "Test beendet.")
			return
		end
		if not (C_RecentAllies and C_RecentAllies.TryRequestRecentAlliesData) then
			Report("Recent Allies ist in diesem Client nicht verfügbar.")
			return
		end
		if not button then
			local ok, err = pcall(Setup)
			if not ok then
				Report("Testansicht konnte nicht vorbereitet werden.", err)
				return
			end
		end
		if not hooked then
			hooksecurefunc(C_RecentAllies, "TryRequestRecentAlliesData", function()
				if run and list:IsVisible() then run.requests = run.requests + 1 end
			end)
			hooksecurefunc("PlaySound", function(kit)
				if run and list:IsVisible() and not BFL:IsSecret(kit) and (kit == 841 or kit == 851 or kit == 856) then
					run.sounds = run.sounds + 1
					Report("Blizzard-SoundKit", kit)
				end
			end)
			hooked = true
		end
		local state = { shows = 0, requests = 0, cacheEvents = 0, sounds = 0, blocked = 0 }
		run = state
		button:Show()
		Report("Klicke den Testbutton in der Bildschirmmitte.")
		C_Timer.After(20, function()
			if button:IsShown() then Finish(state, "Kein Klick innerhalb von 20 Sekunden.") end
		end)
	end
end
