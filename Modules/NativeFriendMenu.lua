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

local function IsStreamerChatLinkClick()
	local streamer = BFL.StreamerMode
	return streamer and streamer:IsActive() and IsModifiedClick and IsModifiedClick("CHATLINK") == true
end

local function CanRouteLink()
	return not IsStreamerChatLinkClick()
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
	if friend.type == "wow" then
		local name = isBroker and friend.fullName or friend.name
		if SafeName(name) then
			BindCharacterLink(text, name)
			return true
		end
	end
	return false
end

local function RunRowScript(row, script, ...)
	local handler = row:GetScript(script)
	if handler then handler(row, ...) end
end

local function ShowCatch(state, catch)
	local previous = state.activeCatch
	if previous ~= catch then
		state.activeCatch = catch
		state.pressedFriend, state.pressedButton = nil, nil
		if previous then previous:Hide() end
	end
	catch:Show()
end

local function CancelDoubleClick(state)
	if not state.doubleClickTimer then return end
	state.doubleClickTimer:Cancel()
	state.doubleClickTimer = nil
	if state.hit:IsShown() then ShowCatch(state, state.catch) end
end

local function IsWhisperRecipient(friend, isWho)
	if not friend then return false end
	if isWho then return true end
	if BFL:IsSecret(friend.connected) then return false end
	if friend.type == "bnet" then
		return not (BFL.IsOfflineTitleFriend and BFL.IsOfflineTitleFriend(friend, friend.connected == false))
	end
	return friend.connected == true
end

local function CanWhisper(friend, isWho)
	return IsWhisperRecipient(friend, isWho) and (not BFL.CanSendWhisper or BFL.CanSendWhisper())
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
	if mode and (not CanWhisper(state.friend, state.who) or not CanRouteLink()
		or (IsModifiedClick and IsModifiedClick("CHATLINK")))
	then mode = nil end
	if state.whisperMode ~= mode then
		CancelDoubleClick(state)
		state.whisperMode = mode
	end
	local passLeft = mode == "single" or state.doubleClickTimer ~= nil
	ShowCatch(state, passLeft and state.leftCatch or state.catch)
end

local function LayoutLink(state, height)
	if height == state.height or height <= 0 then return end
	local text = state.text
	-- The clickable line box follows the font's metrics, which can differ from its size.
	local size = math.max(1, math.ceil(height))
	text:SetFont(STANDARD_TEXT_FONT, size, "")
	local lineHeight = text:GetLineHeight()
	while lineHeight > height and size > 1 do
		size = math.max(1, math.min(size - 1, math.floor(size * height / lineHeight)))
		text:SetFont(STANDARD_TEXT_FONT, size, "")
		lineHeight = text:GetLineHeight()
	end
	-- Give the last glyph room to finish past the clipped right edge.
	text:SetPoint("BOTTOMRIGHT", state.hit, "BOTTOMRIGHT", 2 * size + 12, 0)
	state.height = height
end

local function CreateLinkLayer(row, template)
	-- Use Blizzard's own template directly for row and Send Message hardware clicks.
	local hit = CreateFrame("Frame", nil, row, template or "InlineHyperlinkFrameTemplate")
	hit:Hide()
	if type(hit:GetScript("OnHyperlinkClick")) ~= "function" then return end
	hit:SetAllPoints(row)
	hit:SetClipsChildren(true)
	if not template then hit:EnableMouse(true) end
	hit:SetScript("OnHyperlinkEnter", nil)
	hit:SetScript("OnHyperlinkLeave", nil)

	local text = hit:CreateFontString(nil, "ARTWORK")
	text:SetFont(STANDARD_TEXT_FONT, 12, "")
	text:SetJustifyH("LEFT")
	text:SetJustifyV("MIDDLE")
	text:SetWordWrap(false)
	text:SetAlpha(0)
	text:SetPoint("TOPLEFT", hit, "TOPLEFT")
	text:SetPoint("BOTTOMRIGHT", hit, "BOTTOMRIGHT")
	local state = { hit = hit, text = text }
	hit:SetScript("OnSizeChanged", function(_, _, height) LayoutLink(state, height) end)
	return state
end

local function CreateCatch(row, template)
	local catch = CreateFrame("Button", nil, row, template)
	catch:Hide()
	catch:SetAllPoints(row)
	return catch
end

local function CreateClickLayers(row, catchTemplate, linkTemplate)
	local state = CreateLinkLayer(row, linkTemplate)
	if not state then return end
	state.catch = CreateCatch(row, catchTemplate)
	return state
end

local function SetCatchLevel(state, level)
	state.catch:SetFrameLevel(level)
	state.leftCatch:SetFrameLevel(level)
	if state.bothCatch then state.bothCatch:SetFrameLevel(level) end
end

local function HideCatch(state)
	if state.activeCatch then
		state.activeCatch:Hide()
		state.activeCatch = nil
	end
end

local function CreateLayers(row, friends, isWho)
	local state = CreateClickLayers(row, isWho and "BFLNativeWhoCatchTemplate" or "BFLNativeFriendCatchTemplate")
	if not state then return end
	local hit, catch = state.hit, state.catch
	state.who = isWho
	if not isWho then catch:RegisterForDrag("LeftButton") end

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
				and self:IsVisible() and CanRouteLink()
			then
				CancelDoubleClick(state)
				local timer = C_Timer.NewTimer(DOUBLE_CLICK_WINDOW, function()
					state.doubleClickTimer = nil
					if state.hit:IsShown() then ShowCatch(state, state.catch) end
				end)
				state.doubleClickTimer = timer
				ShowCatch(state, state.leftCatch)
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
	catch:SetScript("OnLeave", function(self)
		if self == state.activeCatch then Leave() end
	end)
	catch:SetScript("OnHide", function(self)
		if self ~= state.activeCatch then return end
		state.pressedFriend, state.pressedButton = nil, nil
		state.whisperMode = nil
		Leave()
	end)
	local leftCatch = CreateCatch(row, isWho and "BFLNativeWhoLeftCatchTemplate" or "BFLNativeBothCatchTemplate")
	state.leftCatch = leftCatch
	if not isWho then leftCatch:RegisterForDrag("LeftButton") end
	for _, script in ipairs({
		"OnDoubleClick", "OnMouseDown", "OnMouseUp", "OnDragStart", "OnDragStop", "OnEnter", "OnLeave", "OnHide",
	}) do
		leftCatch:SetScript(script, catch:GetScript(script))
	end

	return state
end

local function HideBrokerLayers(state)
	state.pressedButton = nil
	state.hit:Hide()
	HideCatch(state)
end

local function RefreshBrokerLayer(state)
	if not state.friend then return end
	if not CanRouteLink() then
		HideBrokerLayers(state)
		return
	end
	local unmodified = not (IsAltKeyDown() or IsShiftKeyDown() or (IsModifiedClick and IsModifiedClick("CHATLINK")))
	local passLeft = CanWhisper(state.friend)
	if not unmodified or (state.whisperOnly and not passLeft) then
		HideBrokerLayers(state)
		return
	end
	local catch = state.whisperOnly and state.leftCatch or (passLeft and state.bothCatch or state.catch)
	state.hit:Show()
	ShowCatch(state, catch)
end

local function CreateBrokerLayers(row)
	local state = CreateClickLayers(row, "BFLNativeFriendCatchTemplate")
	if not state then return end
	local catch = state.catch
	catch:SetScript("OnEnter", function() RunRowScript(row, "OnEnter") end)
	catch:SetScript("OnLeave", function(self)
		if self == state.activeCatch and row:IsVisible() then RunRowScript(row, "OnLeave") end
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
	state.leftCatch = CreateCatch(row, "BFLNativeLeftCatchTemplate")
	state.bothCatch = CreateCatch(row, "BFLNativeBothCatchTemplate")
	for _, alternative in ipairs({ state.leftCatch, state.bothCatch }) do
		for _, script in ipairs({ "OnEnter", "OnLeave", "OnMouseDown", "OnMouseUp" }) do
			alternative:SetScript(script, catch:GetScript(script))
		end
	end
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
	HideCatch(state)
	state.friend = nil
	state.boundTarget = nil
	state.whisperMode = nil
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

function FriendMenu:RefreshBrokerRouting()
	for _, state in pairs(brokerLayers) do
		if state and state.friend then RefreshBrokerLayer(state) end
	end
end

function FriendMenu:ShowWhisperUnavailable()
	if BFL.CanSendWhisper and not BFL.CanSendWhisper() and BFL:ShowWhisperRestrictionError() then return end
	if UIErrorsFrame and UIErrorsFrame.AddExternalErrorMessage then
		UIErrorsFrame:AddExternalErrorMessage(BFL.L.NATIVE_WHISPER_UNAVAILABLE)
	end
end

local function RefreshMenuLink(state)
	if state.menu and CanRouteLink() and not (IsModifiedClick and IsModifiedClick("CHATLINK"))
		and (not BFL.CanSendWhisper or BFL.CanSendWhisper())
	then
		state.hit:Show()
		state.catch:Show()
	else
		HideClickLayers(state)
	end
end

local function CreateMenuLink(button)
	local state = CreateClickLayers(button, "BFLNativeWhisperCatchTemplate", "BFLNativeWhisperLinkTemplate")
	if not state then return end
	local hit, catch = state.hit, state.catch
	-- Keep Blizzard's menu hover while the separate link owns the left click.
	catch:SetScript("OnEnter", function()
		if state.menu then RunRowScript(button, "OnEnter") end
	end)
	catch:SetScript("OnLeave", function()
		if state.menu and button:IsVisible() then RunRowScript(button, "OnLeave") end
	end)
	-- The inherited script opens Blizzard chat before this visual cleanup runs.
	local hooked = hit:HookScript("OnHyperlinkClick", function(_, _, _, mouseButton)
		if mouseButton == "LeftButton" and state.menu then state.menu:Close() end
	end)
	if hooked == false then return end
	return state
end

local function AddWhisperMenuItem(self, root, label, bindLink)
	local canWhisper = not BFL.CanSendWhisper or BFL.CanSendWhisper()
	local restriction = not canWhisper and BFL.GetAgeVerificationRestrictionTooltip
		and BFL.GetAgeVerificationRestrictionTooltip()
	local element = BFL.CreateMenuButton(root, label, function() self:ShowWhisperUnavailable() end, {
		enabled = canWhisper,
		tooltip = restriction,
		tooltipTitle = label,
	})
	if not canWhisper or type(SetItemRef) ~= "function" or not element
		or not element.AddInitializer or not element.AddResetter
	then return end

	element:AddInitializer(function(button, _, menu)
		local state = menuLinks[button]
		if state then
			state.menu = nil
			HideClickLayers(state)
		end
		if not CanRouteLink() or not menu or not menu.Close then return end
		if state == nil then
			local ok, created = pcall(CreateMenuLink, button)
			state = ok and created or false
			menuLinks[button] = state
		end
		if not state then return end
		-- Blizzard lays out the menu button after initialization.
		LayoutLink(state, button:GetHeight())
		local ok, bound = pcall(bindLink, state.text)
		if not ok or not bound then return end
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

function FriendMenu:AddCharacterWhisperMenuItem(root, name, label)
	AddWhisperMenuItem(self, root, label, function(text)
		if not SafeName(name) then return false end
		BindCharacterLink(text, name)
		return true
	end)
end

function FriendMenu:AddFriendWhisperMenuItem(root, friend, isBroker, label)
	local friends = BFL:GetModule("FriendsList")
	if not friends or not IsWhisperRecipient(friend) then return end
	AddWhisperMenuItem(self, root, label, function(text)
		return BindLink(friends, friend, text, isBroker)
	end)
end

local function CreateMessageLayers(button)
	local state = CreateClickLayers(button, "BFLNativeLeftCatchTemplate")
	if not state then return end
	local catch = state.catch
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
	if not self:IsSupported() or not CanRouteLink() or not CanWhisper(friend)
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
	local canRoute = CanRouteLink()
	for row, state in pairs(layers) do
		if state and state.hit:IsVisible() then
			if canRoute then
				UpdateWhisperRouting(friends, state)
			else
				HideLayers(row, state)
			end
		end
	end
	if canRoute then
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
	local state = brokerLayers[row]
	if not friends or not self:IsSupported() or not CanRouteLink() then
		if state then
			state.friend = nil
			HideBrokerLayers(state)
		end
		return
	end
	if state == nil then
		local ok, created = pcall(CreateBrokerLayers, row)
		state = ok and created or false
		brokerLayers[row] = state
		if state then
			rowsByLayer[state.hit] = row
			rowsByLayer[state.catch] = row
			rowsByLayer[state.leftCatch] = row
			rowsByLayer[state.bothCatch] = row
		end
	end
	if not state then return end
	state.friend = nil
	HideBrokerLayers(state)
	LayoutLink(state, row:GetHeight())
	local ok, bound = pcall(BindLink, friends, friend, state.text, true)
	if not ok or not bound then return end

	local level = row:GetFrameLevel()
	state.hit:SetFrameLevel(level + 3)
	SetCatchLevel(state, level + 4)
	state.friend = friend
	state.whisperOnly = whisperOnly
	RefreshBrokerLayer(state)
end

function FriendMenu:UpdateRow(friends, row, friend, isWho)
	if isWho then whoRows[row] = true end
	local state = layers[row]
	if not self:IsSupported() or not CanRouteLink() then
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
			rowsByLayer[state.leftCatch] = row
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
	SetCatchLevel(state, level + 4)
	local invite = row.travelPassButton
	if invite and invite:GetFrameLevel() <= level + 4 then
		state.inviteLevel = state.inviteLevel or invite:GetFrameLevel()
		invite:SetFrameLevel(level + 5)
	end
	state.hit:Show()
	UpdateWhisperRouting(friends, state)
end

local function GetFocusedMenuFriend()
	if not CanRouteLink() or not GetMouseFoci then return end
	-- InlineHyperlinkFrameTemplate does not pass an owner to SetItemRef.
	-- Menu population is synchronous, before the menu takes mouse focus.
	local foci = GetMouseFoci()
	local row = foci and rowsByLayer[foci[1]]
	local brokerState = row and brokerLayers[row]
	local state = brokerState or (row and layers[row])
	local friend = state and state.friend
	if not friend or state.who or state.whisperOnly or not state.hit:IsVisible() then return end
	if not brokerState and row.friendData ~= friend then
		return
	end
	return row, friend
end

function FriendMenu:MaskNativeMenuTitle(root, friend, isBNet)
	local streamer = BFL.StreamerMode
	if not streamer or not streamer:IsActive() then return end
	local title = streamer:GetFriendMenuLabel(friend)
	if not friend and isBNet then
		-- A native menu can have unreadable context even when the BFL link has focus.
		local _, focused = GetFocusedMenuFriend()
		if focused and focused.type == "bnet" then title = BFL.L.UNKNOWN end
	end
	if not title then return end
	-- UnitPopup creates its title first and sets the name in an initializer.
	-- Append a display-only initializer, leaving the native whisper context alone.
	for _, element in root:EnumerateElementDescriptions() do
		if element.AddInitializer then
			element:AddInitializer(function(frame)
				if frame.fontString then frame.fontString:SetText(title) end
			end)
		end
		break
	end
end

function FriendMenu:GetMenuFriend(context, isBNet)
	local row, friend = GetFocusedMenuFriend()
	if not friend then return end
	local friends = BFL:GetModule("FriendsList")
	if not friends or not friends:IsReadableInviteRecord(context) then return end
	for _, field in ipairs({ "chatFrame", "ownerFrame", "friendsList" }) do
		local value = context[field]
		if BFL:IsSecret(value) or value ~= nil then return end
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

function FriendMenu:Initialize()
	local streamerChatLink = false
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
		local wasStreamerChatLink = streamerChatLink
		streamerChatLink = IsStreamerChatLinkClick() == true
		self:RefreshClickRouting()
		local friends = BFL:GetModule("FriendsList")
		if friends then
			if (event == "PLAYER_REGEN_ENABLED" or wasStreamerChatLink) and CanRouteLink() then
				friends:RenderDisplay()
			end
			friends:UpdateSendMessageButton()
		end
	end)
end
