-- Route hardware clicks to Blizzard's hyperlink handler.
local _, BFL = ...
local FriendMenu = BFL:RegisterModule("NativeFriendMenu", {})
local layers = {}
local whoRows = {}
local brokerLayers = {}
local messageLayers = {}
local menuLinks = {}
local rowsByLayer = {}
local linkText = string.rep("M", 64)
local DOUBLE_CLICK_WINDOW = 0.3

local function CanRoute()
	if InCombatLockdown() or (BFL.StreamerMode and BFL.StreamerMode:IsActive()) then return false end
	if C_ChatInfo and C_ChatInfo.InChatMessagingLockdown then
		local ok, locked = pcall(C_ChatInfo.InChatMessagingLockdown)
		if not ok or BFL:IsSecret(locked) or locked then return false end
	end
	return true
end

local function SafeName(name)
	return not BFL:IsSecret(name) and type(name) == "string" and name ~= "" and name ~= "???"
		and not name:find("[:%c]") and (not name:find("|", 1, true) or name:match("^|K[%w]+|k$"))
end

local function BindCharacterLink(text, name)
	text:SetFormattedText("|Hplayer:%s|h%s|h", name, linkText)
end

local function BindLink(friends, friend, text, isBroker)
	if not friends:IsReadableInviteRecord(friend) or friend._isMock then return false end
	if friend.type == "bnet" then
		local id, name = friend.bnetAccountID, friend.accountName
		if BFL:IsSecret(id) or type(id) ~= "number" or id <= 0 or id >= math.huge or id % 1 ~= 0 then return false end
		if isBroker then
			-- The broker display name can be a fallback label. Use the API name for the link.
			local account = friend.accountInfo
			name = nil
			if friends:IsReadableInviteRecord(account) then name = account.accountName end
		end
		if not SafeName(name) and not BFL:IsSecret(name) then
			local account = C_BattleNet.GetAccountInfoByID(id)
			if not friends:IsReadableInviteRecord(account) then return false end
			name = account.accountName
		end
		if not SafeName(name) and not BFL:IsSecret(name) then return false end
		-- The engine formats secret account names without Lua reading or concatenating them.
		text:SetFormattedText("|HBNplayer:%s:%d:0:BN_WHISPER:%s|h%s|h", name, id, name, linkText)
		return true
	end
	if friend.type == "wow" and SafeName(friend.name) then
		BindCharacterLink(text, friend.name)
		return true
	end
	return false
end

local function RunRowScript(row, script, ...)
	local handler = row:GetScript(script)
	if handler then handler(row, ...) end
end

local function PassLeftClick(state, pass)
	if state.passLeft == pass or InCombatLockdown() then return end
	if state.who then
		if pass then
			state.catch:SetPassThroughButtons("LeftButton")
		else
			state.catch:SetPassThroughButtons()
		end
	elseif pass then
		state.catch:SetPassThroughButtons("RightButton", "LeftButton")
	else
		state.catch:SetPassThroughButtons("RightButton")
	end
	state.passLeft = pass
end

local function CancelDoubleClick(state)
	if not state.doubleClickTimer then return end
	state.doubleClickTimer:Cancel()
	state.doubleClickTimer = nil
	PassLeftClick(state, false)
end

local function CanWhisper(friend, isWho)
	if not friend or (BFL.CanSendWhisper and not BFL.CanSendWhisper()) then return false end
	if isWho then return true end
	if BFL:IsSecret(friend.connected) then return false end
	if friend.type == "bnet" then
		return not (BFL.IsOfflineTitleFriend and BFL.IsOfflineTitleFriend(friend, friend.connected == false))
	end
	return friend.connected == true
end

local function UpdateWhisperRouting(friends, state)
	local mode
	if state.hasClickObserver then
		if state.who then
			local who = BFL:GetModule("WhoFrame")
			if who and who:GetSetting("whoDoubleClickAction", "whisper") ~= "invite"
				and not (IsAltKeyDown() or IsControlKeyDown() or IsShiftKeyDown())
			then mode = "double" end
		else
			mode = friends:GetClickWhisperMode()
		end
	end
	if mode and (not CanWhisper(state.friend, state.who) or not CanRoute()
		or (IsModifiedClick and IsModifiedClick("CHATLINK")))
	then mode = nil end
	if state.whisperMode ~= mode then
		CancelDoubleClick(state)
		state.whisperMode = mode
	end
	PassLeftClick(state, mode == "single" or state.doubleClickTimer ~= nil)
end

local function CreateLinkLayer(row)
	local hit = CreateFrame("Frame", nil, row, "InlineHyperlinkFrameTemplate")
	hit:Hide()
	if type(hit:GetScript("OnHyperlinkClick")) ~= "function" then return end
	hit:SetAllPoints(row)
	hit:EnableMouse(true)
	hit:SetScript("OnHyperlinkEnter", nil)
	hit:SetScript("OnHyperlinkLeave", nil)

	local text = hit:CreateFontString(nil, "ARTWORK")
	text:SetJustifyH("LEFT")
	text:SetJustifyV("TOP")
	text:SetWordWrap(false)
	text:SetAlpha(0)
	return { hit = hit, text = text }
end

local function CreateClickLayers(row)
	local state = CreateLinkLayer(row)
	if not state then return end
	local catch = CreateFrame("Button", nil, row)
	catch:Hide()
	if type(catch.SetPassThroughButtons) ~= "function" or type(catch.SetPropagateMouseMotion) ~= "function" then
		return
	end
	catch:SetAllPoints(row)
	catch:EnableMouse(true)
	catch:SetPropagateMouseMotion(true)
	state.catch = catch
	return state
end

local function LayoutLink(state, height)
	if height == state.height or height <= 0 then return end
	-- Cover the row with a tall line and overhang the text box by more than one glyph.
	local size = height + 8
	state.text:SetFont(STANDARD_TEXT_FONT, size, "")
	state.text:ClearAllPoints()
	state.text:SetPoint("TOPLEFT", state.hit, "TOPLEFT", -4, 5)
	state.text:SetPoint("RIGHT", state.hit, "RIGHT", 2 * size + 12, 0)
	state.height = height
end

local function CreateLayers(row, friends, isWho)
	local state = CreateClickLayers(row)
	if not state then return end
	local hit, catch = state.hit, state.catch
	state.who = isWho
	PassLeftClick(state, false)
	if isWho then
		catch:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	else
		catch:RegisterForClicks("LeftButtonUp")
		catch:RegisterForDrag("LeftButton")
	end

	catch:SetScript("OnDoubleClick", function(_, ...)
		if state.whisperMode ~= "double" then RunRowScript(row, "OnDoubleClick", ...) end
	end)
	catch:SetScript("OnMouseDown", function(_, button)
		if button == "LeftButton" or (isWho and button == "RightButton") then
			state.pressedFriend, state.pressedButton = state.friend, button
		end
	end)
	catch:SetScript("OnMouseUp", function(self, button)
		if button ~= state.pressedButton then return end
		local pressed = state.pressedFriend
		state.pressedFriend, state.pressedButton = nil, nil
		local current = isWho and row.info or row.friendData
		if pressed and pressed == state.friend and pressed == current and self:IsMouseOver() then
			local target = state.boundTarget
			RunRowScript(row, "OnClick", button)
			-- The client chooses the click target on press. Arm the next press
			-- after selection and let the inherited hyperlink script do the whisper.
			if button == "LeftButton" and state.whisperMode == "double"
				and pressed == state.friend and target == state.boundTarget
				and self:IsVisible() and CanRoute()
			then
				CancelDoubleClick(state)
				state.doubleClickTimer = C_Timer.NewTimer(DOUBLE_CLICK_WINDOW, function()
					state.doubleClickTimer = nil
					PassLeftClick(state, false)
				end)
				PassLeftClick(state, true)
			end
		end
	end)
	local function DragStart(_, ...)
		state.pressedFriend = nil
		CancelDoubleClick(state)
		RunRowScript(row, "OnDragStart", ...)
	end
	local function DragStop(_, ...)
		RunRowScript(row, "OnDragStop", ...)
	end
	catch:SetScript("OnDragStart", DragStart)
	catch:SetScript("OnDragStop", DragStop)

	-- Observe the native action after Blizzard handles it. No addon click
	-- handler is installed on the link, and the inherited script stays intact.
	if type(hit.HookScript) == "function" then
		local ok, hooked = pcall(hit.HookScript, hit, "OnHyperlinkClick", function(_, _, _, button)
			CancelDoubleClick(state)
			if button == "LeftButton" and state.whisperMode == "single" and state.friend == row.friendData then
				BetterFriendsList_Button_OnClick(row, button, true)
			end
		end)
		state.hasClickObserver = ok and hooked ~= false
		if state.hasClickObserver and not isWho then
			hit:RegisterForDrag("LeftButton")
			hit:SetScript("OnDragStart", DragStart)
			hit:SetScript("OnDragStop", DragStop)
		end
	end

	local function Enter()
		UpdateWhisperRouting(friends, state)
		if row.bflNativeHover then return end
		row.bflNativeHover = true
		if not isWho then friends:SetButtonSelectionVisual(row, row.bflSelected) end
		RunRowScript(row, "OnEnter")
	end
	local function Leave()
		CancelDoubleClick(state)
		if not row.bflNativeHover then return end
		row.bflNativeHover = nil
		if not isWho then friends:SetButtonSelectionVisual(row, row.bflSelected) end
		RunRowScript(row, "OnLeave")
	end
	state.leave = Leave
	-- The catch layer owns the row hover. Moving across the hidden link's
	-- glyphs must not clear the tooltip or the selected row's highlight.
	catch:SetScript("OnEnter", Enter)
	catch:SetScript("OnLeave", Leave)
	catch:SetScript("OnHide", function()
		state.pressedFriend, state.pressedButton = nil, nil
		state.whisperMode = nil
		PassLeftClick(state, false)
		Leave()
	end)

	return state
end

local function HideBrokerLayers(state)
	state.pressedButton = nil
	state.hit:Hide()
	state.catch:Hide()
end

local function RefreshBrokerLayer(state, canRoute)
	if not state.friend then return end
	if not canRoute then
		HideBrokerLayers(state)
		return
	end
	local unmodified = not (IsAltKeyDown() or IsShiftKeyDown() or (IsModifiedClick and IsModifiedClick("CHATLINK")))
	local passRight = unmodified and not state.whisperOnly
	local passLeft = unmodified and CanWhisper(state.friend)
	if passRight ~= state.passRight or passLeft ~= state.passLeft then
		local catch = state.catch
		local ok
		if passLeft and passRight then
			ok = pcall(catch.SetPassThroughButtons, catch, "RightButton", "LeftButton")
		elseif passLeft then
			ok = pcall(catch.SetPassThroughButtons, catch, "LeftButton")
		elseif passRight then
			ok = pcall(catch.SetPassThroughButtons, catch, "RightButton")
		else
			ok = pcall(catch.SetPassThroughButtons, catch)
		end
		if not ok then
			HideBrokerLayers(state)
			return
		end
		state.passRight = passRight
		state.passLeft = passLeft
	end
	state.hit:Show()
	state.catch:Show()
end

local function CreateBrokerLayers(row)
	local state = CreateClickLayers(row)
	if not state then return end
	local catch = state.catch
	catch:SetScript("OnSizeChanged", function(_, _, height) LayoutLink(state, height) end)
	catch:SetScript("OnEnter", function() RunRowScript(row, "OnEnter") end)
	catch:SetScript("OnLeave", function()
		if row:IsVisible() then RunRowScript(row, "OnLeave") end
	end)
	catch:SetScript("OnMouseDown", function(_, button)
		state.pressedButton = button
		RunRowScript(row, "OnMouseDown", button)
	end)
	catch:SetScript("OnMouseUp", function(self, button)
		local pressedButton = state.pressedButton
		state.pressedButton = nil
		if pressedButton == button and state.friend and self:IsMouseOver() then
			RunRowScript(row, "OnMouseUp", button)
		end
	end)
	-- LibQTip hides rows before releasing their scripts and reuses them for headers.
	row:HookScript("OnHide", function()
		state.friend = nil
		HideBrokerLayers(state)
	end)
	return state
end

local function HideLayers(row, state)
	if not state or not state.hit:IsShown() then return end
	state.hit:Hide()
	state.catch:Hide()
	state.friend = nil
	state.boundTarget = nil
	state.whisperMode = nil
	PassLeftClick(state, false)
	state.leave()
	if state.inviteLevel then
		row.travelPassButton:SetFrameLevel(state.inviteLevel)
		state.inviteLevel = nil
	end
end

function FriendMenu:IsSupported()
	return BFL.Compat.SupportsNativeMenuExtensions()
		and type(SetItemRef) == "function" and type(GetMouseFoci) == "function"
end

local function HideClickLayers(state)
	if not state then return end
	state.hit:Hide()
	state.catch:Hide()
end

local function ReleaseMessagePress(button, state)
	if not state.pressed then return end
	state.pressed = nil
	button:SetButtonState("NORMAL")
end

local function UpdateMessagePress(event, mouseButton)
	if mouseButton ~= "LeftButton" then return end
	for button, state in pairs(messageLayers) do
		if state and event == "GLOBAL_MOUSE_UP" then
			ReleaseMessagePress(button, state)
		elseif state and state.hovered and button:IsEnabled() then
			local foci = GetMouseFoci and GetMouseFoci()
			local focus = foci and foci[1]
			if focus == state.catch or focus == state.hit then
				state.pressed = true
				button:SetButtonState("PUSHED", true)
			end
		end
	end
end

function FriendMenu:HideLinks()
	for row, state in pairs(layers) do
		HideLayers(row, state)
	end
	for _, state in pairs(brokerLayers) do
		if state and state.friend then HideBrokerLayers(state) end
	end
	for _, state in pairs(messageLayers) do
		HideClickLayers(state)
	end
	for _, state in pairs(menuLinks) do
		HideClickLayers(state)
	end
end

function FriendMenu:RefreshBrokerRouting()
	local canRoute = CanRoute()
	for _, state in pairs(brokerLayers) do
		if state and state.friend then RefreshBrokerLayer(state, canRoute) end
	end
end

function FriendMenu:ShowWhisperUnavailable()
	if BFL.CanSendWhisper and not BFL.CanSendWhisper() and BFL:ShowWhisperRestrictionError() then return end
	if UIErrorsFrame and UIErrorsFrame.AddExternalErrorMessage then
		UIErrorsFrame:AddExternalErrorMessage(BFL.L.NATIVE_WHISPER_UNAVAILABLE)
	end
end

local function RefreshMenuLink(state)
	if state.menu and CanRoute() and not (IsModifiedClick and IsModifiedClick("CHATLINK"))
		and (not BFL.CanSendWhisper or BFL.CanSendWhisper())
	then
		state.hit:Show()
		state.catch:Show()
	else
		HideClickLayers(state)
	end
end

local function CreateMenuLink(button)
	local state = CreateClickLayers(button)
	if not state then return end
	local hit, catch = state.hit, state.catch
	catch:SetPassThroughButtons("LeftButton", "RightButton", "Button3", "Button4", "Button5")
	hit:SetPassThroughButtons("RightButton", "Button3", "Button4", "Button5")
	-- Keep Blizzard's menu hover while the separate link owns the left click.
	catch:SetScript("OnEnter", function()
		if state.menu then RunRowScript(button, "OnEnter") end
	end)
	catch:SetScript("OnLeave", function()
		if state.menu and button:IsVisible() then RunRowScript(button, "OnLeave") end
	end)
	hit:SetScript("OnSizeChanged", function(_, _, height) LayoutLink(state, height) end)
	-- The inherited script opens Blizzard chat before this visual cleanup runs.
	local hooked = hit:HookScript("OnHyperlinkClick", function(_, _, _, mouseButton)
		if mouseButton == "LeftButton" and state.menu then state.menu:Close() end
	end)
	if hooked == false then return end
	return state
end

function FriendMenu:AddCharacterWhisperMenuItem(root, name, label)
	local canWhisper = not BFL.CanSendWhisper or BFL.CanSendWhisper()
	local restriction = not canWhisper and BFL.GetAgeVerificationRestrictionTooltip
		and BFL.GetAgeVerificationRestrictionTooltip()
	local element = BFL.CreateMenuButton(root, label, function() self:ShowWhisperUnavailable() end, {
		enabled = canWhisper,
		tooltip = restriction,
		tooltipTitle = label,
	})
	if not canWhisper or not SafeName(name) or type(SetItemRef) ~= "function" or not element
		or not element.AddInitializer or not element.AddResetter
	then return end

	element:AddInitializer(function(button, _, menu)
		local state = menuLinks[button]
		if state then
			state.menu = nil
			HideClickLayers(state)
		end
		if not CanRoute() or not menu or not menu.Close then return end
		if state == nil then
			local ok, created = pcall(CreateMenuLink, button)
			state = ok and created or false
			menuLinks[button] = state
		end
		if not state then return end
		-- Blizzard lays out the menu button after initialization.
		LayoutLink(state, math.max(1, button:GetHeight()))
		if not pcall(BindCharacterLink, state.text, name) then return end
		local level = button:GetFrameLevel()
		state.hit:SetFrameLevel(level + 1)
		state.catch:SetFrameLevel(level + 2)
		state.menu = menu
		RefreshMenuLink(state)
	end)
	element:AddResetter(function(button)
		local state = menuLinks[button]
		if state then
			state.menu = nil
			HideClickLayers(state)
		end
	end)
end

local function CreateMessageLayers(button)
	local state = CreateClickLayers(button)
	if not state then return end
	local catch = state.catch
	catch:SetPassThroughButtons("LeftButton")
	-- Keep mouse motion reaching the link, as on broker rows, and reflect the
	-- upper layer's hover on the visible button.
	catch:SetScript("OnEnter", function(_, motion)
		if state.hovered then return end
		state.hovered = true
		button:LockHighlight()
		RunRowScript(button, "OnEnter", motion)
	end)
	local function Leave(_, motion)
		ReleaseMessagePress(button, state)
		if not state.hovered then return end
		state.hovered = nil
		button:UnlockHighlight()
		RunRowScript(button, "OnLeave", motion)
	end
	catch:SetScript("OnLeave", Leave)
	catch:SetScript("OnHide", Leave)
	return state
end

function FriendMenu:UpdateSendMessage(friends, button, friend)
	local state = messageLayers[button]
	if not self:IsSupported() or not CanRoute() or not CanWhisper(friend)
		or (IsModifiedClick and IsModifiedClick("CHATLINK"))
	then
		HideClickLayers(state)
		return
	end
	if state == nil then
		local ok, created = pcall(CreateMessageLayers, button)
		state = ok and created or false
		messageLayers[button] = state
	end
	if not state then return end
	local height = button:GetHeight()
	if height <= 0 then
		HideClickLayers(state)
		return
	end
	LayoutLink(state, height)
	local ok, bound = pcall(BindLink, friends, friend, state.text)
	if not ok or not bound then
		HideClickLayers(state)
		return
	end
	local level = button:GetFrameLevel()
	state.hit:SetFrameLevel(level + 3)
	state.catch:SetFrameLevel(level + 4)
	state.hit:Show()
	state.catch:Show()
end

function FriendMenu:RefreshClickRouting()
	self:RefreshBrokerRouting()
	for _, state in pairs(menuLinks) do
		if state and state.menu then RefreshMenuLink(state) end
	end
	local friends = BFL:GetModule("FriendsList")
	if not friends then return end
	for _, state in pairs(layers) do
		if state and state.hit:IsVisible() then UpdateWhisperRouting(friends, state) end
	end
	if CanRoute() then
		for row in pairs(whoRows) do
			local state = layers[row]
			if row:IsShown() and row.info and (state == nil or (state and not state.hit:IsShown())) then
				self:UpdateRow(friends, row, row.info, true)
			end
		end
	end
end

function FriendMenu:UpdateBrokerRow(row, friend, whisperOnly)
	local friends = BFL:GetModule("FriendsList")
	if not friends or not self:IsSupported() or not CanRoute() then return end
	local state = brokerLayers[row]
	if state == nil then
		local ok, created = pcall(CreateBrokerLayers, row)
		state = ok and created or false
		brokerLayers[row] = state
		if state then
			rowsByLayer[state.hit] = row
			rowsByLayer[state.catch] = row
		end
	end
	if not state then return end
	state.friend = nil
	HideBrokerLayers(state)
	-- A new FontString needs its font before it can accept the hyperlink text.
	LayoutLink(state, row:GetHeight())
	local ok, bound = pcall(BindLink, friends, friend, state.text, true)
	if not ok or not bound then return end

	local level = row:GetFrameLevel()
	state.hit:SetFrameLevel(level + 3)
	state.catch:SetFrameLevel(level + 4)
	state.friend = friend
	state.whisperOnly = whisperOnly
	RefreshBrokerLayer(state, true)
end

function FriendMenu:UpdateRow(friends, row, friend, isWho)
	if isWho then whoRows[row] = true end
	local state = layers[row]
	if not self:IsSupported() or not CanRoute() then
		HideLayers(row, state)
		return
	end
	if state == nil then
		local ok, created = pcall(CreateLayers, row, friends, isWho)
		state = ok and created or false
		layers[row] = state
		if state then
			rowsByLayer[state.hit] = row
			rowsByLayer[state.catch] = row
		end
	end
	if not state then return end

	local height = row:GetHeight()
	if height <= 0 then
		HideLayers(row, state)
		return
	end
	LayoutLink(state, height)

	local target = isWho and { type = "wow", name = friend.fullName, _isMock = friend._isMock } or friend
	local ok, bound = pcall(BindLink, friends, target, state.text)
	if not ok or not bound then
		HideLayers(row, state)
		return
	end
	local boundTarget = target.type == "bnet" and target.bnetAccountID or target.name
	if state.friend ~= friend or state.boundTarget ~= boundTarget then
		CancelDoubleClick(state)
		state.friend = friend
		state.boundTarget = boundTarget
		state.pressedFriend, state.pressedButton = nil, nil
		if row.bflNativeHover then
			RunRowScript(row, "OnLeave")
			RunRowScript(row, "OnEnter")
		end
	end
	local level = row:GetFrameLevel()
	state.hit:SetFrameLevel(level + 3)
	state.catch:SetFrameLevel(level + 4)
	local invite = row.travelPassButton
	if invite and invite:GetFrameLevel() <= level + 4 then
		state.inviteLevel = state.inviteLevel or invite:GetFrameLevel()
		invite:SetFrameLevel(level + 5)
	end
	state.catch:Show()
	state.hit:Show()
	UpdateWhisperRouting(friends, state)
end

function FriendMenu:GetMenuFriend(context, isBNet)
	if not CanRoute() or not GetMouseFoci then return end
	local friends = BFL:GetModule("FriendsList")
	if not friends or not friends:IsReadableInviteRecord(context) then return end
	for _, field in ipairs({ "chatFrame", "ownerFrame", "friendsList" }) do
		local value = context[field]
		if BFL:IsSecret(value) or value ~= nil then return end
	end

	-- InlineHyperlinkFrameTemplate does not pass an owner to SetItemRef.
	-- Menu population is synchronous, before the menu takes mouse focus.
	local foci = GetMouseFoci()
	local row = foci and rowsByLayer[foci[1]]
	local brokerState = row and brokerLayers[row]
	local state = brokerState or (row and layers[row])
	local friend = state and state.friend
	if not friend or state.who or not state.hit:IsVisible() then return end
	if brokerState then
		if not state.passRight then return end
	elseif row.friendData ~= friend then
		return
	end

	if isBNet and friend.type == "bnet" then
		local id = context.bnetIDAccount
		if BFL:IsSecret(id) or (type(id) ~= "number" and type(id) ~= "string") then return end
		if tonumber(id) == friend.bnetAccountID then return row, friend end
	elseif not isBNet and friend.type == "wow" then
		local name = context.name
		if SafeName(name) then
			local suffix = context.surname
			if BFL:IsSecret(suffix) then return end
			if not SafeName(suffix) then suffix = context.server end
			if BFL:IsSecret(suffix) then return end
			if SafeName(suffix) then name = name .. "-" .. suffix end
			if name == friend.name then return row, friend end
			local normalized = BFL.NormalizeWoWFriendName and BFL:NormalizeWoWFriendName(name)
			if normalized and normalized == BFL:NormalizeWoWFriendName(friend.name) then return row, friend end
		end
	end
end

function FriendMenu:HandleUnavailableClick()
	if not self:IsSupported() then return false end
	if UIErrorsFrame and UIErrorsFrame.AddExternalErrorMessage then
		UIErrorsFrame:AddExternalErrorMessage(BFL.L.NATIVE_FRIEND_MENU_UNAVAILABLE)
	end
	return true
end

function FriendMenu:Initialize()
	local events = CreateFrame("Frame")
	events:RegisterEvent("PLAYER_REGEN_DISABLED")
	events:RegisterEvent("PLAYER_REGEN_ENABLED")
	events:RegisterEvent("MODIFIER_STATE_CHANGED")
	-- Observe hardware input for the visible button state without owning the click.
	if BFL.Compat.RegisterEvent(events, "GLOBAL_MOUSE_UP") then
		BFL.Compat.RegisterEvent(events, "GLOBAL_MOUSE_DOWN")
	end
	events:SetScript("OnEvent", function(_, event, ...)
		if event == "GLOBAL_MOUSE_DOWN" or event == "GLOBAL_MOUSE_UP" then
			UpdateMessagePress(event, ...)
			return
		end
		if not self:IsSupported() then return end
		if event == "PLAYER_REGEN_DISABLED" then
			self:HideLinks()
		else
			self:RefreshClickRouting()
			local friends = BFL:GetModule("FriendsList")
			if friends then
				if event == "PLAYER_REGEN_ENABLED" and CanRoute() then friends:RenderDisplay() end
				friends:UpdateSendMessageButton()
			end
		end
	end)
end
