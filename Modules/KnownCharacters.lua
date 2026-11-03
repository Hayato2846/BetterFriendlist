-- Local, opt-in contact associations. No social mutations or native UI hooks.
local _, BFL = ...
local Known = BFL:RegisterModule("KnownCharacters", {})
local MAX_CONTACTS, MAX_CHARACTERS = 200, 20

local function Secret(value) return BFL.IsSecret and BFL:IsSecret(value) end
local function SafeTable(value) return not Secret(value) and type(value) == "table" end
local function Text(value)
	if Secret(value) or type(value) ~= "string" or #value > 128 or value:find("[|%c:#]") then return nil end
	value = value:match("^%s*(.-)%s*$")
	return value ~= "" and value or nil
end
local function Number(value)
	return not Secret(value) and type(value) == "number" and value == value
		and value > 0 and value < math.huge and value % 1 == 0 and value or nil
end
local function InCombat() return InCombatLockdown and InCombatLockdown() end
local function Count(values) local count = 0; for _ in pairs(values) do count = count + 1 end; return count end
local function Region()
	if type(GetCurrentRegion) ~= "function" then return nil end
	local ok, value = pcall(GetCurrentRegion)
	return ok and Number(value) or nil
end
local function Scope()
	local project, region = Number(WOW_PROJECT_ID), Region()
	if not project or not region then return nil end
	return (BFL.IsForever and "forever:" or "wow:") .. project .. ":" .. region
end
local function BattleTag(value)
	if Secret(value) or type(value) ~= "string" or #value > 128 or value:find("[|%c:]") then return nil end
	return value:match("^[^#%s]+#%d+$") and value:lower() or nil
end
local function Name(value, realm)
	value = Text(value)
	if not value then return nil end
	if BFL.AreRegionalUniqueNamesEnabled and BFL.AreRegionalUniqueNamesEnabled() then
		-- Regional surnames are part of the identity, not a realm suffix.
		return value:gsub("%-", " "):gsub("%s+", " ")
	end
	local first, suffix = value:match("^(.-)%-(.+)$")
	if not first then first, suffix = value, Text(realm) end
	if not suffix or first == "" or first:find("%s") or suffix:gsub("%s+", "") == "" then return nil end -- Never guess a friend's realm.
	value = first .. "-" .. suffix:gsub("%s+", "")
	return Text(value)
end
local function CharacterKey(name) return name:lower() end
local function ValidOwner(owner)
	if Secret(owner) or type(owner) ~= "string" or #owner > 256 then return false end
	local kind, family, project, region, identity = owner:match("^([bp]):([a-z]+):(%d+):(%d+):(.+)$")
	if (family ~= "wow" and family ~= "forever") or not Number(tonumber(project)) or not Number(tonumber(region)) then return false end
	if kind == "b" then return BattleTag(identity) == identity end
	local name = Text(identity)
	return name ~= nil and CharacterKey(name) == identity
end
local function Subject(owner, anchor)
	if owner and owner:sub(1, 2) == "b:" then
		return { battleTag = BattleTag(owner:match("^b:[a-z]+:%d+:%d+:(.+)$")) }
	end
	return { type = "wow", name = anchor }
end
local function SafeGroup(group)
	return SafeTable(group) and SafeTable(group.characters)
end
local function Active(module, method, ...)
	if not module or type(module[method]) ~= "function" then return false end
	local ok, value = pcall(module[method], module, ...)
	if not ok or Secret(value) then return true end -- Unknown privacy state fails closed.
	return value ~= nil and value ~= false
end

function Known:Sanitize(store)
	local contacts, scanned = {}, 0
	for owner, group in pairs(store.contacts) do
		scanned = scanned + 1; if scanned > MAX_CONTACTS then break end
		if ValidOwner(owner) and SafeGroup(group)
		then
			local safe = { characters = {}, blocked = Secret(group.blocked) or group.blocked == true }
			local characterCount = 0
			for _, entry in pairs(group.characters) do
				characterCount = characterCount + 1; if characterCount > MAX_CHARACTERS then break end
				if SafeTable(entry) and not Secret(entry.source) then
					local name, stamp = Text(entry.name), Number(entry.lastSeen)
					if name and (entry.source == "manual" or (entry.source == "observed" and stamp)) then
						safe.characters[CharacterKey(name)] = { name = name, source = entry.source,
							lastSeen = entry.source == "observed" and stamp or nil }
					end
				end
			end
			contacts[owner] = safe
		end
	end
	store.contacts = contacts
	store.maxTooltipCharacters = math.min(10, Number(store.maxTooltipCharacters) or 3)
	self.validatedStore, self.validatedContacts = store, contacts
end

function Known:GetStore(create)
	if not SafeTable(BetterFriendlistDB) then return nil end
	local store = BetterFriendlistDB.knownCharacters
	if not SafeTable(store) then
		if not create then return nil end
		store = { enabled = false, observeBattleNet = false, maxTooltipCharacters = 3, contacts = {} }
		BetterFriendlistDB.knownCharacters = store
	end
	if not SafeTable(store.contacts) then
		if not create then return nil end
		store.contacts = {}
	end
	if not Secret(store.enabled) and store.enabled == true
		and (self.validatedStore ~= store or self.validatedContacts ~= store.contacts)
	then self:Sanitize(store) end
	return store
end

function Known:IsEnabled()
	local store = self:GetStore(false)
	return store ~= nil and not Secret(store.enabled) and store.enabled == true
end

function Known:CanUse()
	if not self:IsEnabled() then return false end
	-- No display, edits or observation while privacy/preview mode is active.
	local streamer = BFL.StreamerMode or BFL:GetModule("StreamerMode")
	if Active(streamer, "IsActive") then return false end
	local preview = BFL:GetModule("PreviewMode")
	return not Active(preview, "IsComponentEnabled", "friends")
end

function Known:HideSurfaces()
	if self.dialog then self.dialog:Hide() end -- Our ordinary UIParent child only.
	if self.menuOwner then
		self.menuOwner:Hide()
		if Menu and Menu.GetManager then
			local menu = Menu.GetManager():GetOpenMenu()
			if menu and menu.GetOwnerRegion and menu:GetOwnerRegion() == self.menuOwner then menu:Close() end
		end
	end
	if BFLKnownCharactersMenu and UIDROPDOWNMENU_OPEN_MENU == BFLKnownCharactersMenu and CloseDropDownMenus then
		CloseDropDownMenus() -- Legacy fallback: never close an unrelated dropdown.
	end
	if FriendsTooltip and FriendsTooltip.KnownCharacterLines then
		for _, line in ipairs(FriendsTooltip.KnownCharacterLines) do line:SetText(""); line:Hide() end
	end
	if self.tooltip and self.tooltip.GetOwner and self.tooltip:GetOwner() == self.tooltipOwner then self.tooltip:Hide() end
	self.tooltip, self.tooltipOwner = nil, nil
end

function Known:SetSetting(key, value)
	if Secret(value) then return false end
	local store = self:GetStore(true)
	if not store then return false end
	if key == "enabled" or key == "observeBattleNet" then
		if type(value) ~= "boolean" then return false end
	elseif key == "maxTooltipCharacters" then
		value = Number(value)
		if not value then return false end
		value = math.max(1, math.min(10, value))
	else return false end
	store[key] = value
	self:HideSurfaces()
	return true
end

function Known:ResolveIdentity(friend)
	if not SafeTable(friend) or Secret(friend._isMock) or friend._isMock then return nil end
	local scope = Scope()
	if not scope then return nil end
	local tag = BattleTag(friend.battleTag)
	local game = SafeTable(friend.gameAccountInfo) and friend.gameAccountInfo or nil
	local name = Name(friend.characterName, friend.realmName)
	if not name and not Secret(friend.type) and friend.type == "wow" then name = Name(friend.name, friend.realmName) end
	if not name and game then name = Name(game.characterName, game.realmName) end
	if tag then return "b:" .. scope .. ":" .. tag, name, scope end
	if name then return "p:" .. scope .. ":" .. CharacterKey(name), name, scope end
	return nil
end

function Known:FindOwner(friend)
	local owner, name, scope = self:ResolveIdentity(friend)
	if not owner then return nil end
	local store = self:GetStore(false)
	if not store then return owner, name, scope end
	if SafeGroup(store.contacts[owner]) or owner:sub(1, 2) == "b:" or not name then return owner, name, scope end
	local match, scanned = nil, 0
	for key, group in pairs(store.contacts) do
		scanned = scanned + 1; if scanned > MAX_CONTACTS then break end
		if not Secret(key) and type(key) == "string" and key:sub(3, #scope + 3) == scope .. ":" and SafeGroup(group) then
			local entry = group.characters[CharacterKey(name)]
			local recordedName = SafeTable(entry) and Text(entry.name)
			if recordedName and CharacterKey(recordedName) == CharacterKey(name) then
				if match then return nil end -- Ambiguous associations never reveal a guessed account.
				match = key
			end
		end
	end
	return match or owner, name, scope
end

function Known:EnsureGroup(owner)
	local store = self:GetStore(true)
	if not store or not ValidOwner(owner) then return nil end
	if not SafeGroup(store.contacts[owner]) then
		if Count(store.contacts) >= MAX_CONTACTS then return nil end
		store.contacts[owner] = { characters = {} }
	end
	return store.contacts[owner]
end

function Known:Put(owner, name, source, timestamp)
	local group = self:EnsureGroup(owner)
	if not group then return false end
	local key = CharacterKey(name)
	local previous = group.characters[key]
	if Secret(previous) then previous = nil end
	if not previous and Count(group.characters) >= MAX_CHARACTERS then return false end
	-- Explicit manual associations are never silently reclassified by observation.
	if SafeTable(previous) and not Secret(previous.source) and previous.source == "manual" and source == "observed" then return true end
	if SafeTable(previous) and not Secret(previous.name) and not Secret(previous.lastSeen) and not Secret(previous.source)
		and previous.name == name and previous.lastSeen == timestamp and previous.source == source
	then return true end
	group.characters[key] = { name = name, source = source, lastSeen = timestamp }
	return true
end

function Known:AddManual(friend, value)
	if not self:CanUse() or InCombat() then return false, BFL.L.KC_INVALID end
	local owner, anchor = self:FindOwner(friend)
	local name = Name(value)
	if not owner or not name then return false, BFL.L.KC_INVALID end
	local group = self:EnsureGroup(owner)
	if not group then return false, BFL.L.KC_FULL end
	local needed = not group.characters[CharacterKey(name)] and 1 or 0
	if anchor and CharacterKey(anchor) ~= CharacterKey(name) and not group.characters[CharacterKey(anchor)] then needed = needed + 1 end
	if Count(group.characters) + needed > MAX_CHARACTERS then return false, BFL.L.KC_FULL end
	if anchor then self:Put(owner, anchor, "manual") end
	self:Put(owner, name, "manual")
	self:HideSurfaces()
	return true
end

-- The atomic native friend snapshot ties its primary character to its BattleTag.
-- Separately indexed game-account rows are deliberately not accepted as proof.
-- No extra API requests, scans, timers or mutations.
function Known:ObserveAccount(account)
	if not self:CanUse() then return end
	local store = self:GetStore(false)
	if Secret(store.observeBattleNet) or store.observeBattleNet ~= true or not SafeTable(account) then return end
	if Secret(account._isMock) or account._isMock then return end
	if Secret(account.isFriend) or account.isFriend == false or Secret(account.appearOffline) or account.appearOffline == true then return end
	local tag, scope = BattleTag(account.battleTag), Scope()
	if not tag or not scope then return end -- Never persist session-only account IDs.
	local owner = "b:" .. scope .. ":" .. tag
	local group = store.contacts[owner]
	if SafeTable(group) and (Secret(group.blocked) or group.blocked == true) then return end
	local stamp
	if type(GetServerTime) == "function" then
		local ok, value = pcall(GetServerTime)
		if ok then stamp = value end
	end
	stamp = Number(stamp)
	if not stamp then return end
	local function Observe(game)
		if not SafeTable(game) or Secret(game.isOnline) or game.isOnline ~= true
			or Secret(game.isAppearOffline) or game.isAppearOffline == true
			or Secret(game.clientProgram) or game.clientProgram ~= "WoW"
			or Number(game.wowProjectID) ~= Number(WOW_PROJECT_ID) or Number(game.regionID) ~= Region()
		then return end
		local name = Name(game.characterName, game.realmName)
		if name then self:Put(owner, name, "observed", stamp) end
	end
	Observe(account.gameAccountInfo)
end

function Known:GetEntries(friend)
	if not self:CanUse() then return {} end
	local owner = self:FindOwner(friend)
	local store = self:GetStore(false)
	local group = owner and store and store.contacts[owner]
	local entries = {}
	if not SafeGroup(group) then return entries end
	local scanned = 0
	for _, entry in pairs(group.characters) do
		scanned = scanned + 1; if scanned > MAX_CHARACTERS then break end
		if SafeTable(entry) and not Secret(entry.source) then
			local name = Text(entry.name)
			local stamp = Number(entry.lastSeen)
			if name and (entry.source == "manual" or (entry.source == "observed" and stamp)) then
				entries[#entries + 1] = { name = name, source = entry.source, lastSeen = stamp }
			end
		end
	end
	table.sort(entries, function(a, b)
		if a.source ~= b.source then return a.source == "manual" end
		return a.name:lower() < b.name:lower()
	end)
	return entries
end

function Known:Remove(friend, name)
	if not self:CanUse() then return false end
	name = Name(name)
	local owner = self:FindOwner(friend)
	local store = self:GetStore(false)
	local group = owner and store and store.contacts[owner]
	if not name or not SafeGroup(group) then return false end
	group.characters[CharacterKey(name)] = nil
	group.blocked = true -- A deleted observation must not return at the next event.
	if owner:sub(1, 2) == "p:" and next(group.characters) == nil then store.contacts[owner] = nil end
	self:HideSurfaces()
	return true
end

function Known:ClearContact(friend)
	if not self:CanUse() then return end
	local owner = self:FindOwner(friend)
	local store = self:GetStore(false)
	if owner and store and (owner:sub(1, 2) ~= "b:" or self:EnsureGroup(owner)) then
		store.contacts[owner] = owner:sub(1, 2) == "b:" and { blocked = true, characters = {} } or nil
	end
	self:HideSurfaces()
end

function Known:ClearAll()
	local store = self:GetStore(true)
	if store then store.contacts, store.observeBattleNet = {}, false end
	self:HideSurfaces()
end

function Known:GetTooltipLines(friend)
	-- A BFL hover uses the same already-read native snapshot. This makes an
	-- explicit observation opt-in useful immediately, without fetching/scanning.
	if self:CanUse() and SafeTable(friend) and not Secret(friend.type) and friend.type == "bnet" then
		self:ObserveAccount({ battleTag = friend.battleTag, gameAccountInfo = friend.knownCharacterPrimary,
			appearOffline = friend.knownCharacterAppearOffline, isFriend = friend.knownCharacterIsFriend, _isMock = friend._isMock })
	end
	local entries = self:GetEntries(friend)
	if #entries == 0 then return nil end
	local store = self:GetStore(false)
	local limit = math.min(10, Number(store.maxTooltipCharacters) or 3)
	local lines = { BFL.L.KC_TITLE }
	for i = 1, math.min(limit, #entries) do
		local entry = entries[i]
		if entry.source == "manual" then lines[#lines + 1] = BFL.L.KC_MANUAL:format(entry.name)
		else
			local ok, dateText = pcall(date, "%x", entry.lastSeen)
			lines[#lines + 1] = BFL.L.KC_OBSERVED:format(entry.name, ok and dateText or "?")
		end
	end
	if #entries > limit then lines[#lines + 1] = BFL.L.KC_MORE:format(#entries - limit) end
	return lines
end

function Known:AddTooltipLines(tooltip, friend)
	local lines = self:GetTooltipLines(friend)
	if not lines or not tooltip or not tooltip.AddLine then return false end
	tooltip:AddLine(" ")
	for index, text in ipairs(lines) do tooltip:AddLine(text, 1, index == 1 and 0.82 or 1, index == 1 and 0 or 1, true) end
	self.tooltip, self.tooltipOwner = tooltip, tooltip.GetOwner and tooltip:GetOwner()
	return true
end

function Known:ShowDialog(friend, clearAll)
	if InCombat() or (not clearAll and not self:CanUse()) then return false end
	if not clearAll and not self:FindOwner(friend) then return false end
	local frame = self.dialog
	if not frame then
		frame = CreateFrame("Frame", nil, UIParent, "BasicFrameTemplateWithInset")
		frame:SetSize(420, 190)
		frame:SetPoint("CENTER", UIParent, "CENTER")
		frame:SetFrameStrata("DIALOG")
		frame:SetClampedToScreen(true)
		frame.TitleText:SetText(BFL.L.KC_TITLE)
		frame.CloseButton:SetScript("OnClick", function() frame:Hide() end)
		frame.prompt = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
		frame.prompt:SetPoint("TOPLEFT", 20, -36); frame.prompt:SetWidth(380); frame.prompt:SetJustifyH("LEFT")
		frame.editBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
		frame.editBox:SetPoint("TOPLEFT", 20, -80); frame.editBox:SetSize(380, 24)
		frame.editBox:SetAutoFocus(false); frame.editBox:SetMaxLetters(128)
		frame.error = frame:CreateFontString(nil, "OVERLAY", "GameFontRedSmall")
		frame.error:SetPoint("TOPLEFT", 20, -110); frame.error:SetWidth(380); frame.error:SetJustifyH("LEFT")
		local save = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
		save:SetPoint("BOTTOMRIGHT", -14, 12); save:SetSize(150, 24)
		local cancel = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
		cancel:SetPoint("BOTTOMLEFT", 14, 12); cancel:SetSize(120, 24); cancel:SetText(CANCEL)
		cancel:SetScript("OnClick", function() frame:Hide() end)
		local function Accept()
			if InCombat() then frame:Hide(); return end
			if frame.clearAll then Known:ClearAll(); return end
			if not Known:CanUse() then frame:Hide(); return end
			local ok, reason = Known:AddManual(frame.friend, frame.editBox:GetText())
			if ok then frame:Hide() else frame.error:SetText(reason) end
		end
		save:SetScript("OnClick", Accept)
		frame.editBox:SetScript("OnEnterPressed", Accept)
		frame.editBox:SetScript("OnEscapePressed", function() frame:Hide() end)
		frame:SetScript("OnHide", function() frame.friend = nil; frame.editBox:SetText(""); frame.editBox:ClearFocus() end)
		frame.save = save
		self.dialog = frame
	end
	-- Capture only safe identities, never a recycled row or an account index.
	local owner, anchor = self:FindOwner(friend)
	frame.friend = Subject(owner, anchor)
	frame.clearAll = clearAll == true
	frame.prompt:SetText(clearAll and BFL.L.KC_CLEAR_CONFIRM or BFL.L.KC_PROMPT)
	frame.error:SetText(""); frame.editBox:SetText("")
	frame.editBox:SetShown(not clearAll)
	frame.save:SetText(clearAll and BFL.L.KC_FORGET or BFL.L.KC_ADD)
	frame:Show()
	if not clearAll then frame.editBox:SetFocus() end
	return true
end

function Known:PopulateMenu(root, friend)
	if not self:CanUse() or not self:FindOwner(friend) or not root or not root.CreateButton then return false end
	-- Own menus only; the caller deliberately excludes native Blizzard menus.
	local owner, anchor = self:FindOwner(friend)
	local subject = Subject(owner, anchor)
	root:CreateButton(BFL.L.KC_TITLE, function()
		if not self:CanUse() or InCombat() then return end
		if not self.menuOwner then
			self.menuOwner = CreateFrame("Frame", nil, UIParent)
			self.menuOwner:SetSize(1, 1)
			self.menuOwner:SetPoint("CENTER", UIParent, "CENTER")
		end
		self.menuOwner:Show()
		local entries = self:GetEntries(subject)
		local items = { { type = "title", text = BFL.L.KC_TITLE },
			{ text = BFL.L.KC_ADD, disabled = InCombat(), func = function() self:ShowDialog(subject) end } }
		for _, entry in ipairs(entries) do
			local name = entry.name
			items[#items + 1] = { text = BFL.L.KC_REMOVE:format(name), destructive = true, func = function() self:Remove(subject, name) end }
		end
		items[#items + 1] = { text = BFL.L.KC_CLEAR_CONTACT, destructive = true, func = function() self:ClearContact(subject) end }
		local store = self:GetStore(false)
		local group = store and store.contacts[owner]
		if SafeGroup(group) and not Secret(group.blocked) and group.blocked == true
			and not Secret(store.observeBattleNet) and store.observeBattleNet == true
		then
			items[#items + 1] = { text = BFL.L.KC_RESUME, func = function()
				if self:CanUse() then
					local current = self:GetStore(false).contacts[owner]
					if SafeGroup(current) then current.blocked = false end
				end
			end }
		end
		BFL.OpenSimpleContextMenu(self.menuOwner, "BFLKnownCharactersMenu", items)
	end)
	return true
end

function Known:RegisterLegacyControls(parent, components, frames)
	local store = self:GetStore(false)
	table.insert(frames, components:CreateSpacer(parent))
	table.insert(frames, components:CreateHeader(parent, BFL.L.KC_TITLE))
	for _, info in ipairs({ { "enabled", "KC_ENABLE", "KC_DESC" }, { "observeBattleNet", "KC_AUTO", "KC_AUTO_DESC" } }) do
		local key = info[1]
		table.insert(frames, components:CreateCheckbox(parent, {
			label = BFL.L[info[2]], tooltipTitle = BFL.L[info[2]], tooltipDesc = BFL.L[info[3]],
			initialValue = store and not Secret(store[key]) and store[key] == true or false,
			callback = function(value) Known:SetSetting(key, value) end,
		}))
	end
	local slider = components:CreateSlider(parent, BFL.L.KC_LIMIT, 1, 10,
		math.min(10, store and Number(store.maxTooltipCharacters) or 3), tostring,
		function(value) Known:SetSetting("maxTooltipCharacters", value) end)
	slider:SetStep(1)
	table.insert(frames, slider)
	table.insert(frames, components:CreateButton(parent, BFL.L.KC_CLEAR_ALL,
		function() Known:ShowDialog(nil, true) end, BFL.L.KC_CLEAR_CONFIRM))
end

function Known:RegisterSettingsDesignerControls(app)
	local page, group = "privacy.characters", "knownCharacters"
	app:RegisterGroup(page, { id = group, title = BFL.L.KC_TITLE, order = 100 })
	local function Control(id, kind, label, description, order, extra)
		local data = { id = "knownCharacters." .. id, groupID = group, groupTitle = BFL.L.KC_TITLE,
			type = kind, label = label, description = description, order = order, refreshOnChange = true }
		for key, value in pairs(extra or {}) do data[key] = value end
		app:RegisterControl(page, data)
	end
	for order, info in ipairs({ { "enabled", "KC_ENABLE", "KC_DESC" }, { "observeBattleNet", "KC_AUTO", "KC_AUTO_DESC" } }) do
		local key = info[1]
		Control(key, "toggle", BFL.L[info[2]], BFL.L[info[3]], order * 10, { default = false,
			getValue = function() local store = Known:GetStore(false); return store and not Secret(store[key]) and store[key] == true or false end,
			setValue = function(value) Known:SetSetting(key, value) end })
	end
	Control("maxTooltipCharacters", "slider", BFL.L.KC_LIMIT, BFL.L.KC_LIMIT_DESC, 30, {
		min = 1, max = 10, step = 1, integer = true, default = 3,
		getValue = function() local store = Known:GetStore(false); return math.min(10, store and Number(store.maxTooltipCharacters) or 3) end,
		setValue = function(value) Known:SetSetting("maxTooltipCharacters", value) end })
	Control("clear", "button", BFL.L.KC_CLEAR_ALL, BFL.L.KC_CLEAR_CONFIRM, 40, {
		buttonText = BFL.L.KC_CLEAR_ALL, trackCustomized = false, onClick = function() Known:ShowDialog(nil, true) end })
end

function Known:Initialize()
	BFL:RegisterEventCallback("PLAYER_REGEN_DISABLED", function() if self.dialog then self.dialog:Hide() end end, 10)
end

return Known
