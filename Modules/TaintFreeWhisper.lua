local _, BFL = ...

local TaintFreeWhisper = BFL:RegisterModule("TaintFreeWhisper", {})

local RETAIL_LAYOUT_INTERVAL = 0.10
local RETAIL_CONFLICT_GAP = 2
local RETAIL_DEFAULT_HEIGHT = 32
local MAX_MESSAGE_LETTERS = 255

local state = {
	draft = "",
}

local retailComposer
local inlineBar
local closingComposer = false

local function IsSafeNumber(value)
	return not BFL:IsSecret(value) and type(value) == "number"
end

local function GetSafeWhisperValue(value)
	if BFL:IsSecret(value) then
		return nil
	end
	if type(value) == "string" and value ~= "" then
		return value
	end
	return nil
end

local function GetSafeWhisperAccountID(value)
	if BFL:IsSecret(value) then
		return nil
	end
	if type(value) == "number" then
		return value
	end
	if type(value) == "string" then
		return tonumber(value)
	end
	return nil
end

local function CallChatAPI(func, ...)
	if not func then
		return nil
	end
	if BFL.HasSecretValues and securecallfunction then
		return securecallfunction(func, ...)
	end
	return func(...)
end

local function ResetState()
	state.displayName = nil
	state.whisperTarget = nil
	state.bnetIDAccount = nil
	state.isBNet = nil
	state.targetKey = nil
	state.draft = ""
	state.nativeEditBox = nil
	state.nativeConflict = nil
	state.layoutElapsed = nil
	state.lastLeft = nil
	state.lastBottom = nil
	state.lastWidth = nil
	state.lastHeight = nil
	state.presentation = nil
end

local function GetTargetKey(whisperTarget, bnetIDAccount, isBNet)
	if isBNet then
		return bnetIDAccount and ("bnet:" .. bnetIDAccount) or nil
	end
	return whisperTarget and ("wow:" .. whisperTarget) or nil
end

local function GetComposerDraft()
	local editBox
	if retailComposer and retailComposer:IsShown() then
		editBox = retailComposer
	elseif inlineBar and inlineBar:IsShown() then
		editBox = inlineBar.EditBox
	end

	if editBox then
		local text = editBox:GetText()
		if not BFL:IsSecret(text) and type(text) == "string" then
			return text
		end
	end

	return state.draft or ""
end

local function SendWhisper(text)
	if state.isBNet then
		local bnetIDAccount = GetSafeWhisperAccountID(state.bnetIDAccount)
		if not bnetIDAccount then
			return false
		end
		local func = C_BattleNet and C_BattleNet.SendWhisper or BNSendWhisper
		if not func then
			return false
		end
		local success = CallChatAPI(func, bnetIDAccount, text)
		return success ~= false
	end

	local whisperTarget = GetSafeWhisperValue(state.whisperTarget)
	if not whisperTarget then
		return false
	end
	local func = C_ChatInfo and C_ChatInfo.SendChatMessage or SendChatMessage
	if not func then
		return false
	end
	CallChatAPI(func, text, "WHISPER", nil, whisperTarget)
	return true
end

local function ResolveNativeEditBox()
	if not (BFL.IsRetail and UIParent) then
		return nil
	end

	local candidate
	local chooser = ChatFrameUtil and ChatFrameUtil.ChooseBoxForSend
	if type(chooser) == "function" then
		-- Retail 12.1's chooser is read-only. Its result is used only as a geometry source.
		local ok, result = pcall(chooser)
		if ok and not BFL:IsSecret(result) then
			candidate = result
		end
	end

	if not candidate and DEFAULT_CHAT_FRAME then
		candidate = DEFAULT_CHAT_FRAME.editBox or _G.ChatFrame1EditBox
	end

	if candidate and candidate ~= retailComposer and candidate.GetRect and candidate.GetEffectiveScale then
		return candidate
	end
	return nil
end

local function HasActiveNativeEditBox()
	local getter = ChatFrameUtil and ChatFrameUtil.GetActiveWindow
	if type(getter) == "function" then
		local ok, active = pcall(getter)
		if ok then
			if BFL:IsSecret(active) then
				return true
			end
			return active ~= nil
		end
	end

	local active = _G.ACTIVE_CHAT_EDIT_BOX
	if BFL:IsSecret(active) then
		return true
	end
	return active ~= nil
end

local function GetWhisperColor()
	local chatType = state.isBNet and "BN_WHISPER" or "WHISPER"
	local info = ChatTypeInfo and ChatTypeInfo[chatType]
	if type(info) == "table" and not BFL:IsSecret(info) then
		local r, g, b = info.r, info.g, info.b
		if IsSafeNumber(r) and IsSafeNumber(g) and IsSafeNumber(b) then
			return r, g, b
		end
	end
	return 1, 0.5, 1
end

local function SetRetailFocusShown(shown)
	if not retailComposer then
		return
	end
	retailComposer.FocusLeft:SetShown(shown)
	retailComposer.FocusMid:SetShown(shown)
	retailComposer.FocusRight:SetShown(shown)
end

local function GetRetailHeaderText()
	local displayName = GetSafeWhisperValue(state.displayName) or UNKNOWN or "Unknown"
	local headerPattern = state.isBNet and CHAT_BN_WHISPER_SEND or CHAT_WHISPER_SEND
	if not BFL:IsSecret(headerPattern) and type(headerPattern) == "string" then
		local ok, text = pcall(string.format, headerPattern, displayName)
		if ok then
			return text
		end
	end

	local fallbackPattern = BFL.L and BFL.L.TAINT_FREE_WHISPER_TITLE or "Whisper to %s"
	return string.format(fallbackPattern, displayName) .. ":"
end

local function UpdateRetailAppearance()
	local editBox = retailComposer
	if not editBox then
		return
	end

	local r, g, b = GetWhisperColor()
	editBox:SetTextColor(r, g, b)
	editBox.Header:SetTextColor(r, g, b)
	editBox.HeaderSuffix:SetTextColor(r, g, b)
	editBox.FocusLeft:SetVertexColor(r, g, b)
	editBox.FocusMid:SetVertexColor(r, g, b)
	editBox.FocusRight:SetVertexColor(r, g, b)

	local width = editBox:GetWidth()
	if not IsSafeNumber(width) or width <= 0 then
		return
	end

	local header = editBox.Header
	local suffix = editBox.HeaderSuffix
	header:SetWidth(0)
	header:SetText(GetRetailHeaderText())
	local headerWidth = header:GetStringWidth()
	if not IsSafeNumber(headerWidth) then
		headerWidth = 0
	end

	local maxHeaderWidth = width / 2
	if headerWidth > maxHeaderWidth then
		headerWidth = maxHeaderWidth
		header:SetWidth(maxHeaderWidth)
		suffix:Show()
	else
		header:SetWidth(headerWidth)
		suffix:Hide()
	end

	local suffixWidth = 0
	if suffix:IsShown() then
		suffixWidth = suffix:GetStringWidth()
		if not IsSafeNumber(suffixWidth) then
			suffixWidth = 0
		end
	end
	editBox:SetTextInsets(15 + headerWidth + suffixWidth, 13, 0, 0)
end

local function ApplyRetailGeometry(force)
	local editBox = retailComposer
	local nativeEditBox = state.nativeEditBox
	if not (editBox and nativeEditBox) then
		return false
	end

	local rectOK, left, bottom, width, height = pcall(nativeEditBox.GetRect, nativeEditBox)
	if
		not rectOK
		or not IsSafeNumber(left)
		or not IsSafeNumber(bottom)
		or not IsSafeNumber(width)
		or not IsSafeNumber(height)
		or width <= 0
		or height <= 0
	then
		return false
	end

	local sourceScaleOK, sourceScale = pcall(nativeEditBox.GetEffectiveScale, nativeEditBox)
	local uiScale = UIParent:GetEffectiveScale()
	if
		not sourceScaleOK
		or not IsSafeNumber(sourceScale)
		or not IsSafeNumber(uiScale)
		or sourceScale <= 0
		or uiScale <= 0
	then
		return false
	end

	local scaleRatio = sourceScale / uiScale
	left = left * scaleRatio
	bottom = bottom * scaleRatio
	width = width * scaleRatio
	height = height * scaleRatio
	if state.nativeConflict then
		bottom = bottom + height + RETAIL_CONFLICT_GAP
	end

	local changed = force
		or not state.lastLeft
		or math.abs(left - state.lastLeft) > 0.01
		or math.abs(bottom - state.lastBottom) > 0.01
		or math.abs(width - state.lastWidth) > 0.01
		or math.abs(height - state.lastHeight) > 0.01
	if changed then
		state.lastLeft = left
		state.lastBottom = bottom
		state.lastWidth = width
		state.lastHeight = height
		editBox:ClearAllPoints()
		editBox:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", left, bottom)
		editBox:SetSize(width, height)
		UpdateRetailAppearance()
	end
	return true
end

local function CreateRetailTexture(editBox, layer, path, width, point)
	local texture = editBox:CreateTexture(nil, layer)
	texture:SetTexture(path)
	texture:SetSize(width, RETAIL_DEFAULT_HEIGHT)
	texture:SetPoint(point)
	return texture
end

local function EnsureRetailComposer()
	if retailComposer then
		return retailComposer
	end
	if not (BFL.IsRetail and UIParent) then
		return nil
	end

	local editBox = CreateFrame("EditBox", nil, UIParent)
	editBox:SetSize(5, RETAIL_DEFAULT_HEIGHT)
	editBox:SetFrameStrata("DIALOG")
	editBox:SetFrameLevel(50)
	if editBox.SetToplevel then
		editBox:SetToplevel(true)
	end
	editBox:SetAutoFocus(false)
	editBox:SetMultiLine(false)
	editBox:SetMaxLetters(MAX_MESSAGE_LETTERS)
	editBox:SetFontObject(ChatFontNormal or GameFontNormal)
	editBox:SetJustifyH("LEFT")
	editBox:EnableMouse(true)

	editBox.Left = CreateRetailTexture(editBox, "BACKGROUND", "Interface\\ChatFrame\\UI-ChatInputBorder-Left2", 32, "LEFT")
	editBox.Right = CreateRetailTexture(editBox, "BACKGROUND", "Interface\\ChatFrame\\UI-ChatInputBorder-Right2", 32, "RIGHT")
	editBox.Mid = editBox:CreateTexture(nil, "BACKGROUND")
	editBox.Mid:SetTexture("Interface\\ChatFrame\\UI-ChatInputBorder-Mid2")
	editBox.Mid:SetHorizTile(true)
	editBox.Mid:SetHeight(RETAIL_DEFAULT_HEIGHT)
	editBox.Mid:SetPoint("TOPLEFT", editBox.Left, "TOPRIGHT")
	editBox.Mid:SetPoint("TOPRIGHT", editBox.Right, "TOPLEFT")

	editBox.FocusLeft = CreateRetailTexture(editBox, "BORDER", "Interface\\ChatFrame\\UI-ChatInputBorderFocus-Left", 32, "LEFT")
	editBox.FocusRight = CreateRetailTexture(editBox, "BORDER", "Interface\\ChatFrame\\UI-ChatInputBorderFocus-Right", 32, "RIGHT")
	editBox.FocusMid = editBox:CreateTexture(nil, "BORDER")
	editBox.FocusMid:SetTexture("Interface\\ChatFrame\\UI-ChatInputBorderFocus-Mid")
	editBox.FocusMid:SetHorizTile(true)
	editBox.FocusMid:SetHeight(RETAIL_DEFAULT_HEIGHT)
	editBox.FocusMid:SetPoint("TOPLEFT", editBox.FocusLeft, "TOPRIGHT")
	editBox.FocusMid:SetPoint("TOPRIGHT", editBox.FocusRight, "TOPLEFT")

	local header = editBox:CreateFontString(nil, "ARTWORK", "ChatFontNormal")
	header:SetHeight(14)
	header:SetPoint("LEFT", editBox, "LEFT", 15, 0)
	header:SetJustifyH("LEFT")
	header:SetWordWrap(false)
	header:SetMaxLines(1)
	editBox.Header = header

	local suffix = editBox:CreateFontString(nil, "ARTWORK", "ChatFontNormal")
	suffix:SetPoint("LEFT", header, "RIGHT")
	suffix:SetText(CHAT_HEADER_SUFFIX or "...")
	editBox.HeaderSuffix = suffix

	retailComposer = editBox
	SetRetailFocusShown(false)

	editBox:SetScript("OnEditFocusGained", function()
		SetRetailFocusShown(true)
	end)
	editBox:SetScript("OnEditFocusLost", function(self)
		SetRetailFocusShown(false)
		if closingComposer then
			return
		end
		local text = self:GetText()
		if not text or text == "" then
			TaintFreeWhisper:Close(true)
		else
			state.draft = text
		end
	end)
	editBox:SetScript("OnEnterPressed", function(self)
		local text = self:GetText()
		if not text or text == "" then
			TaintFreeWhisper:Close(true)
			return
		end
		if SendWhisper(text) then
			TaintFreeWhisper:Close(true)
		else
			BFL:DebugPrint("TaintFreeWhisper: Missing safe whisper target")
			self:SetFocus()
		end
	end)
	editBox:SetScript("OnEscapePressed", function()
		TaintFreeWhisper:Close(true)
	end)
	editBox:SetScript("OnUpdate", function(_, elapsed)
		state.layoutElapsed = (state.layoutElapsed or 0) + elapsed
		if state.layoutElapsed >= RETAIL_LAYOUT_INTERVAL then
			state.layoutElapsed = 0
			ApplyRetailGeometry(false)
		end
	end)
	editBox:SetScript("OnEvent", function(_, event)
		if event == "UPDATE_CHAT_COLOR" then
			UpdateRetailAppearance()
		end
	end)
	editBox:RegisterEvent("UPDATE_CHAT_COLOR")
	editBox:Hide()
	return editBox
end

local function HideRetailComposer()
	if not retailComposer then
		return
	end
	retailComposer:ClearFocus()
	retailComposer:Hide()
	retailComposer:SetText("")
	SetRetailFocusShown(false)
end

local function EnsureInlineBar()
	if inlineBar then
		return inlineBar
	end

	local parent = _G.BetterFriendsFrame
	if not parent then
		return nil
	end

	local bar = CreateFrame("Frame", nil, parent)
	bar:SetHeight(25)
	bar:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 6, 3)
	bar:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -6, 3)
	bar:SetFrameLevel(parent:GetFrameLevel() + 10)

	local toLabel = bar:CreateFontString(nil, "OVERLAY", "BetterFriendlistFontNormal")
	toLabel:SetPoint("LEFT", bar, "LEFT", 6, 0)
	toLabel:SetJustifyH("LEFT")
	toLabel:SetTextColor(0.6, 0.6, 0.6)
	bar.ToLabel = toLabel

	local editBox = CreateFrame("EditBox", nil, bar, "InputBoxTemplate")
	editBox:SetHeight(20)
	editBox:SetPoint("LEFT", toLabel, "RIGHT", 4, 0)
	editBox:SetPoint("RIGHT", bar, "RIGHT", -60, 0)
	editBox:SetAutoFocus(false)
	editBox:SetMaxLetters(MAX_MESSAGE_LETTERS)
	editBox:SetFontObject("BetterFriendlistFontNormal")
	bar.EditBox = editBox

	local sendButton = CreateFrame("Button", nil, bar)
	sendButton:SetSize(22, 22)
	sendButton:SetPoint("LEFT", editBox, "RIGHT", 2, 0)
	sendButton:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")
	sendButton:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
	sendButton:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Down")
	bar.SendButton = sendButton

	local closeButton = CreateFrame("Button", nil, bar)
	closeButton:SetSize(22, 22)
	closeButton:SetPoint("LEFT", sendButton, "RIGHT", 0, 0)
	closeButton:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
	closeButton:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
	closeButton:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
	bar.CloseButton = closeButton

	local hiddenByBar = {}
	local function GetBottomElements()
		local elements = {
			parent.AddFriendButton,
			parent.SendMessageButton,
			parent.RecruitmentButton,
		}
		if parent.WhoFrame then
			elements[#elements + 1] = parent.WhoFrame.WhoButton
			elements[#elements + 1] = parent.WhoFrame.AddFriendButton
			elements[#elements + 1] = parent.WhoFrame.GroupInviteButton
		end
		if parent.RaidFrame then
			elements[#elements + 1] = parent.RaidFrame.ConvertToRaidButton
			elements[#elements + 1] = parent.RaidFrame.RaidToolsButton
		end
		if parent.QuickJoinFrame and parent.QuickJoinFrame.ScrollFrame then
			elements[#elements + 1] = parent.QuickJoinFrame.ScrollFrame.JoinQueueButton
		end
		return elements
	end

	function bar:HideBottomElements()
		wipe(hiddenByBar)
		for _, element in ipairs(GetBottomElements()) do
			if element and element:IsShown() then
				hiddenByBar[element] = true
				element:Hide()
			end
		end
	end

	function bar:RestoreBottomElements()
		for element in pairs(hiddenByBar) do
			element:Show()
		end
		wipe(hiddenByBar)
	end

	local function DoSend()
		local text = editBox:GetText()
		if not text or text == "" then
			TaintFreeWhisper:Close(true)
			return
		end
		if SendWhisper(text) then
			TaintFreeWhisper:Close(true)
		else
			BFL:DebugPrint("TaintFreeWhisper: Missing safe whisper target")
			editBox:SetFocus()
		end
	end

	editBox:SetScript("OnEnterPressed", DoSend)
	editBox:SetScript("OnEscapePressed", function()
		TaintFreeWhisper:Close(true)
	end)
	sendButton:SetScript("OnClick", DoSend)
	closeButton:SetScript("OnClick", function()
		TaintFreeWhisper:Close(true)
	end)
	bar:SetScript("OnHide", function()
		if not closingComposer then
			local text = editBox:GetText()
			if not BFL:IsSecret(text) and type(text) == "string" then
				state.draft = text
			end
		end
		bar:RestoreBottomElements()
		editBox:SetText("")
		editBox:ClearFocus()
	end)

	sendButton:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:SetText(BFL.L and BFL.L.TAINT_FREE_WHISPER_SEND or "Send")
		GameTooltip:Show()
	end)
	sendButton:SetScript("OnLeave", GameTooltip_Hide)
	closeButton:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:SetText(BFL.L and BFL.L.TAINT_FREE_WHISPER_CANCEL or "Cancel")
		GameTooltip:Show()
	end)
	closeButton:SetScript("OnLeave", GameTooltip_Hide)

	bar:Hide()
	inlineBar = bar
	parent:EnableKeyboard(false)
	return bar
end

local function HideInlineBar()
	if not inlineBar then
		return
	end
	inlineBar:RestoreBottomElements()
	inlineBar.EditBox:ClearFocus()
	inlineBar:Hide()
	inlineBar.EditBox:SetText("")
end

function TaintFreeWhisper:ShowRetailComposer()
	local editBox = EnsureRetailComposer()
	local nativeEditBox = ResolveNativeEditBox()
	if not (editBox and nativeEditBox) then
		return false
	end

	state.nativeEditBox = nativeEditBox
	state.nativeConflict = HasActiveNativeEditBox()
	state.layoutElapsed = 0
	state.lastLeft = nil
	if not ApplyRetailGeometry(true) then
		state.nativeEditBox = nil
		state.nativeConflict = nil
		return false
	end

	HideInlineBar()
	editBox:SetText(state.draft or "")
	UpdateRetailAppearance()
	editBox:Show()
	state.presentation = "retail"
	if not state.nativeConflict then
		editBox:SetFocus()
	else
		SetRetailFocusShown(false)
	end
	return true
end

function TaintFreeWhisper:ShowInlineBar()
	local bar = EnsureInlineBar()
	if not bar then
		return false
	end

	HideRetailComposer()
	local titlePattern = BFL.L and BFL.L.TAINT_FREE_WHISPER_TITLE or "Whisper to %s"
	bar.ToLabel:SetText(string.format(titlePattern, state.displayName or UNKNOWN or "Unknown") .. ":")

	local parent = _G.BetterFriendsFrame
	if parent and not parent:IsShown() then
		if ShowBetterFriendsFrame then
			ShowBetterFriendsFrame(1)
		else
			parent:Show()
		end
	end

	bar:HideBottomElements()
	bar.EditBox:SetText(state.draft or "")
	bar:Show()
	bar.EditBox:SetFocus()
	state.presentation = "inline"
	return true
end

function TaintFreeWhisper:Open(displayName, whisperTarget, bnetIDAccount, isBNet)
	local safeDisplayName = GetSafeWhisperValue(displayName)
	local safeWhisperTarget = GetSafeWhisperValue(whisperTarget)
	local safeBNetID = GetSafeWhisperAccountID(bnetIDAccount)
	local labelName = safeDisplayName or safeWhisperTarget or UNKNOWN or "Unknown"

	if isBNet then
		if not safeBNetID then
			BFL:DebugPrint("TaintFreeWhisper: Missing safe BNet account ID")
			return false
		end
	else
		safeWhisperTarget = safeWhisperTarget or safeDisplayName
		if not safeWhisperTarget then
			BFL:DebugPrint("TaintFreeWhisper: Missing safe character whisper target")
			return false
		end
		labelName = safeDisplayName or safeWhisperTarget
	end

	local targetKey = GetTargetKey(safeWhisperTarget, safeBNetID, isBNet)
	if state.targetKey == targetKey then
		state.draft = GetComposerDraft()
	else
		state.draft = ""
	end

	state.displayName = labelName
	state.whisperTarget = safeWhisperTarget
	state.bnetIDAccount = safeBNetID
	state.isBNet = isBNet and true or false
	state.targetKey = targetKey

	if BFL.IsRetail and self:ShowRetailComposer() then
		return true
	end
	if self:ShowInlineBar() then
		return true
	end

	BFL:DebugPrint("TaintFreeWhisper: No safe composer surface is available")
	return false
end

function TaintFreeWhisper:Close(clearState)
	if not clearState then
		state.draft = GetComposerDraft()
	end

	closingComposer = true
	HideRetailComposer()
	HideInlineBar()
	closingComposer = false

	state.nativeEditBox = nil
	state.nativeConflict = nil
	state.presentation = nil
	if clearState then
		ResetState()
	end
end

function TaintFreeWhisper:Restore()
	if not state.targetKey then
		return
	end
	if not BetterFriendlistDB or not BetterFriendlistDB.taintFreeWhisper then
		self:Close(true)
		return
	end
	self:Open(state.displayName, state.whisperTarget, state.bnetIDAccount, state.isBNet)
end

function TaintFreeWhisper:IsInlineShown()
	return inlineBar and inlineBar:IsShown() or false
end

function BFL:OpenTaintFreeWhisper(displayName, whisperTarget, bnetIDAccount, isBNet)
	return TaintFreeWhisper:Open(displayName, whisperTarget, bnetIDAccount, isBNet)
end

function BFL:CloseTaintFreeWhisper(clearState)
	return TaintFreeWhisper:Close(clearState)
end

function BFL:RestoreTaintFreeWhisper()
	return TaintFreeWhisper:Restore()
end

function BFL:IsInlineTaintFreeWhisperShown()
	return TaintFreeWhisper:IsInlineShown()
end
