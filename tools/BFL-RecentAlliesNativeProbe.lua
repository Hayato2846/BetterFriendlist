-- Development probe. Append after Modules/RecentAllies.lua in a local QA build.
-- The release addon does not load this file.
do
	local run, pendingCleanup, proxy
	local requestHookInstalled
	local events = CreateFrame("Frame")

	local function Report(message)
		print("|cff67ccff[BFL-RA]|r " .. message)
	end

	local function DataReady()
		local ready = C_RecentAllies and C_RecentAllies.IsRecentAllyDataReady
		if not ready then return nil end
		local ok, value = pcall(ready)
		if ok and not BFL:IsSecret(value) and type(value) == "boolean" then return value end
	end

	local function CloseNative(state)
		proxy:Hide()
		proxy:SetAttribute("clickbutton1", nil)
		if state.frame:IsShown() then
			pcall(HideUIPanel, state.frame)
			if state.frame:IsShown() then Report("Blizzard-Fenster blieb offen. Sichtbarkeit wird wiederhergestellt.") end
		end
		state.frame:SetAlpha(state.alpha)
		BFL.AllowBlizzardFriendsFrame = state.allowNative
	end

	local function Finish(state, message)
		if run ~= state then return end
		run = nil
		Report(message)
		if InCombatLockdown() then
			state.frame:SetAlpha(state.alpha)
			pendingCleanup = state
		else
			CloseNative(state)
		end
	end

	local function CheckResult(state)
		if run ~= state or state.warm or not state.clicked or not state.selected or state.blocked then return end
		if state.cacheUpdate and DataReady() then
			Finish(state, "ERFOLG. Cache-Update empfangen, Daten lesbar, Blizzard-Fenster wird geschlossen.")
		end
	end

	local function InstallRequestObserver()
		if requestHookInstalled ~= nil then return end
		requestHookInstalled = pcall(hooksecurefunc, C_RecentAllies, "TryRequestRecentAlliesData", function()
			if run then run.requestCalls = run.requestCalls + 1 end
		end)
	end

	local function RequestSummary(state)
		local visible = state.view and state.view:IsVisible()
		return "Native Liste sichtbar = " .. (visible and "ja" or "nein")
			.. ", beobachtete Request-Aufrufe = "
			.. (requestHookInstalled and tostring(state.requestCalls) or "unbekannt") .. "."
	end

	events:RegisterEvent("RECENT_ALLIES_CACHE_UPDATE")
	events:RegisterEvent("RECENT_ALLIES_DATA_READY")
	events:RegisterEvent("RECENT_ALLIES_SYSTEM_STATUS_UPDATED")
	events:RegisterEvent("SOCIAL_UI_SYSTEM_STATUS_UPDATED")
	events:RegisterEvent("ADDON_ACTION_BLOCKED")
	events:RegisterEvent("ADDON_ACTION_FORBIDDEN")
	events:RegisterEvent("PLAYER_REGEN_DISABLED")
	events:RegisterEvent("PLAYER_REGEN_ENABLED")
	events:SetScript("OnEvent", function(_, event, _, action)
		if event == "PLAYER_REGEN_ENABLED" and pendingCleanup then
			CloseNative(pendingCleanup)
			pendingCleanup = nil
		end
		local state = run
		if not state then return end
		if event == "PLAYER_REGEN_DISABLED" then
			Finish(state, "Abbruch wegen Kampfbeginn. Das Blizzard-Fenster wird nach dem Kampf geschlossen.")
		elseif event == "RECENT_ALLIES_SYSTEM_STATUS_UPDATED" or event == "SOCIAL_UI_SYSTEM_STATUS_UPDATED" then
			Finish(state, "Abbruch. Blizzard kann seine Tabs nach einem Statuswechsel neu zuordnen.")
		elseif event == "ADDON_ACTION_BLOCKED" or event == "ADDON_ACTION_FORBIDDEN" then
			if not BFL:IsSecret(action) and type(action) == "string" and action:find("TryRequestRecentAlliesData", 1, true) then
				state.blocked = true
				C_Timer.After(0, function()
					Finish(state, event .. " bei TryRequestRecentAlliesData.")
				end)
			end
		elseif event == "RECENT_ALLIES_CACHE_UPDATE" or event == "RECENT_ALLIES_DATA_READY" then
			if event == "RECENT_ALLIES_CACHE_UPDATE" then state.cacheUpdate = true end
			Report(event)
			C_Timer.After(0, function() CheckResult(state) end)
		end
	end)

	local function GetProxy()
		if proxy then return proxy end
		proxy = CreateFrame("Button", nil, UIParent, "SecureActionButtonTemplate,SecureHandlerStateTemplate")
		proxy:Hide()
		proxy:EnableMouse(true)
		proxy:SetFrameStrata("TOOLTIP")
		proxy:SetFrameLevel(10000)
		proxy:RegisterForClicks("LeftButtonUp")
		proxy:SetAttribute("useOnKeyDown", false)
		proxy:SetAttribute("type1", "click")
		proxy:SetAttribute("_onstate-combat", [[if newstate == "combat" then self:Hide() end]])
		RegisterStateDriver(proxy, "combat", "[combat] combat; nocombat")
		proxy:SetScript("PostClick", function()
			local state = run
			if not state then return end
			proxy:Hide()
			state.clicked = true
			state.selected = state.frame:IsShown() and state.isSelected()
			Report("Klick am Proxy. Blizzard-Tab aktiv = " .. (state.selected and "ja" or "nein") .. ".")
			Report(RequestSummary(state))
			local ok, failure = pcall(state.friendsUI.SelectSection, state.friendsUI, "recent_allies")
			if not ok then Report("BFL-Tabwechsel fehlgeschlagen. " .. tostring(failure)) end
			if state.selected and not state.blocked then
				CheckResult(state)
				if run == state then
					C_Timer.After(state.warm and 3 or 30, function()
						if run ~= state then return end
						Report(RequestSummary(state))
						local cacheUpdate = state.cacheUpdate and "ja" or "nein"
						if state.warm then
							Finish(state, "WARMTEST beendet. Cache war bereits lesbar, Cache-Update im Test = " .. cacheUpdate .. ".")
						else
							Finish(state, "Zeitlimit nach dem Klick. Cache lesbar = " .. (DataReady() and "ja" or "nein")
								.. ", Cache-Update empfangen = " .. cacheUpdate .. ".")
						end
					end)
				end
			elseif not state.blocked then
				Finish(state, "FEHLER. Der weitergereichte Klick hat Blizzards Tab nicht aktiviert.")
			end
		end)
		return proxy
	end

	local function FindBFLTab(friendsUI)
		if friendsUI:IsModernActive() then
			for _, tab in ipairs(friendsUI.sideTabs or {}) do
				if tab.sectionID == "recent_allies" then return tab end
			end
		elseif BetterFriendsFrame and BetterFriendsFrame.FriendsTabHeader then
			return BetterFriendsFrame.FriendsTabHeader.Tab2
		end
	end

	local function Arm(withHover, warm)
		if InCombatLockdown() or pendingCleanup then
			Report("Bitte außerhalb des Kampfes starten.")
			return
		end
		if DataReady() ~= warm then
			Report(warm and "Der Warmtest braucht einen bereits lesbaren Cache."
				or "Der Cache muss für diesen Test ungeladen sein. Für einen geladenen Cache nutze /bflraprobe warm.")
			return
		end
		local friendsUI = BFL:GetModule("FriendsUI")
		local tab = friendsUI and FindBFLTab(friendsUI)
		if not tab or not tab:IsVisible() or not tab:IsEnabled() then
			Report("Bitte zuerst BFLs Freundesliste öffnen. Der Tab Letzte Mitspieler muss sichtbar sein.")
			return
		end

		local modern = friendsUI:IsSocialUIEnabled()
		if modern and not SocialUIFrame then C_AddOns.LoadAddOn("Blizzard_SocialUI") end
		local native = modern and SocialUIFrame or FriendsFrame
		if not native or native:IsShown() then
			Report("Blizzards Fenster muss verfügbar und zu Testbeginn geschlossen sein.")
			return
		end

		local button = GetProxy()
		button:SetPropagateMouseMotion(withHover)
		local state = {
			frame = native,
			alpha = native:GetAlpha(),
			allowNative = BFL.AllowBlizzardFriendsFrame,
			friendsUI = friendsUI,
			requestCalls = 0,
			warm = warm,
		}
		run = state
		BFL.AllowBlizzardFriendsFrame = true
		native:SetAlpha(0)

		local target
		if modern then
			friendsUI:OpenLoadedBlizzardSocialUI(native, SocialUITabType.Friends)
			target = native:GetTabByType(SocialUITabType.RecentAllies)
			state.view = native.RecentAlliesList
			state.isSelected = function() return native:GetSelectedTab() == SocialUITabType.RecentAllies end
		else
			local header = assert(FriendsTabHeader)
			header:SelectTab(header.friendsTabID)
			ShowUIPanel(native)
			target = header:GetTabButton(header.recentAlliesTabID)
			state.view = RecentAlliesFrame and RecentAlliesFrame.List
			state.isSelected = function() return header:GetTab() == header.recentAlliesTabID end
		end

		if not native:IsShown() or not target or not target:IsVisible() or native:GetAlpha() ~= 0 then
			Finish(state, "Abbruch. Das unsichtbare Blizzard-Fenster oder sein Originaltab ist nicht verfügbar.")
			return
		end
		if not target:IsEnabled() or target:HasAccessConstraints()
			or target:HasAnyForbiddenAspects(Enum.ForbiddenAspect.ScriptedInput)
		then
			Finish(state, "Abbruch. Der native Tab lässt die Klickweiterleitung nicht zu.")
			return
		end
		if state.isSelected() or DataReady() ~= warm or (not warm and state.cacheUpdate) then
			Finish(state, "Abbruch. Cache-Zustand oder nativer Tab stimmt vor dem Klick nicht mit dem Testmodus überein.")
			return
		end
		state.cacheUpdate, state.requestCalls = false, 0

		local left, bottom, width, height = tab:GetScaledRect()
		if not tab:IsVisible() or not left or not width or width <= 0 or height <= 0 then
			Finish(state, "Abbruch. BFLs Tab ist nach dem Öffnen des nativen Fensters nicht mehr erreichbar.")
			return
		end
		local scale = UIParent:GetEffectiveScale()
		button:ClearAllPoints()
		button:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", left / scale, bottom / scale)
		button:SetSize(width / scale, height / scale)
		button:SetAttribute("clickbutton1", target)
		InstallRequestObserver()
		button:Show()
		Report("Bereit. Cache = " .. (warm and "warm" or "kalt") .. ", Mausbewegung weiterreichen = " .. (withHover and "ja" or "nein")
			.. ". Klicke innerhalb von 30 Sekunden in BFL auf Letzte Mitspieler.")
		C_Timer.After(30, function()
			if not state.clicked then Finish(state, "Zeitlimit. Kein Klick am Proxy.") end
		end)
	end

	SLASH_BFLRECENTALLIESPROBE1 = "/bflraprobe"
	SlashCmdList.BFLRECENTALLIESPROBE = function(message)
		message = message:match("^%s*(.-)%s*$"):lower()
		if run then
			Finish(run, "Test abgebrochen.")
		elseif message ~= "cancel" then
			local warm = message == "warm" or message == "warm bare"
			local withHover = message ~= "bare" and message ~= "warm bare"
			if message ~= "" and message ~= "bare" and not warm then
				Report("Verfügbare Optionen für /bflraprobe sind bare, warm, warm bare und cancel.")
				return
			end
			local ok, failure = pcall(Arm, withHover, warm)
			if not ok then
				Report(tostring(failure))
				if run then Finish(run, "Abbruch während der Vorbereitung.") end
			end
		end
	end
end
