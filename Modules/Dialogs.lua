--------------------------------------------------------------------------
-- Dialogs Module - StaticPopup Dialog Management
--------------------------------------------------------------------------
-- This module manages all StaticPopup dialogs for the addon including:
-- - Group creation dialogs
-- - Group rename/delete dialogs
-- - Friend assignment dialogs
--------------------------------------------------------------------------

local ADDON_NAME, BFL = ...
local L = BFL.L

-- Register the Dialogs module
local Dialogs = BFL:RegisterModule("Dialogs", {})

-- Only these addon-owned text workflows may use the private dialog. Native
-- confirmations, invitations and other addons' StaticPopup slots stay native.
local INPUT_DIALOGS = {
	BFL_FRIEND_LOCAL_TIME = true,
	BETTER_FRIENDLIST_CREATE_GROUP = true,
	BETTER_FRIENDLIST_CREATE_GROUP_AND_ADD_FRIEND = true,
	BETTER_FRIENDLIST_RENAME_GROUP = true,
	BFL_FRIEND_TAG_EDITOR_CREATE_SECTION = true,
	BFL_FRIEND_TAG_EDITOR_CREATE_CUSTOM = true,
	BFL_FRIEND_TAGS_CREATE_CUSTOM_TAG = true,
	BFL_COPY_TEXT = true,
}

function Dialogs:RefreshInputDialogTheme()
	local frame = self.inputDialog
	if not frame then return end
	local engine = BFL:GetModule("SkinEngine")
	local theme = BFL:GetEffectiveTheme()
	local external = theme == "ellesmereui" and BFL:GetModule("EllesmereUISkin")
		or theme == "elvui" and BFL:GetModule("ElvUISkin")
	if external and external:SkinInputDialog(frame) then
		-- Only this private BFL frame is handed to external skin adapters.
		-- Shared Blizzard StaticPopup slots are never styled here.
	elseif engine and engine:IsActive() and BFL:UsesDarkSkinTheme() then
		frame:SetBackdrop(nil)
		engine:SkinFrame(frame, "popup")
		engine:SkinEditBox(frame.EditBox)
		engine:SkinButton(frame.button1)
		engine:SkinButton(frame.button2)
	else
		if engine then
			engine:RestoreFrame(frame)
			engine:RestoreFrame(frame.EditBox)
			engine:RestoreFrame(frame.button1)
			engine:RestoreFrame(frame.button2)
		end
		frame:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
			edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true,
			tileSize = 32, edgeSize = 32, insets = { left = 11, right = 11, top = 11, bottom = 11 } })
		frame:SetBackdropColor(1, 1, 1, 1)
		frame:SetBackdropBorderColor(1, 1, 1, 1)
	end
	if BFL.FontManager then BFL.FontManager:RefreshWindowFonts() end
end

function Dialogs:AcceptInputDialog()
	local frame = self.inputDialog
	if not (frame and frame.spec and frame.button1:IsEnabled()) then return end
	local keepOpen = frame.spec.OnAccept and frame.spec.OnAccept(frame, frame.data)
	if not keepOpen then frame:Hide() end
end

function Dialogs:LayoutInputDialog()
	local frame = self.inputDialog
	if not frame then return end
	local ratio = BFL.WindowGeometry:GetRatio(frame)
	local buttonWidth = math.max(145, frame.button1:GetFontString():GetStringWidth() + 24,
		frame.button2:GetFontString():GetStringWidth() + 24)
	local width = math.min(UIParent:GetWidth() / ratio - 24, math.max(380, frame.EditBox:GetWidth() + 48, buttonWidth * 2 + 58))
	frame:SetWidth(width)
	local inputTop = 57 + frame.text:GetStringHeight()
	frame.EditBox:SetPoint("TOP", 0, -inputTop)
	frame.BFL_ErrorLabel:SetPoint("TOPLEFT", 24, -(inputTop + 30))
	frame.BFL_ErrorLabel:SetPoint("TOPRIGHT", -24, -(inputTop + 30))
	local buttonHeight = math.max(24, frame.button1:GetFontString():GetStringHeight() + 8,
		frame.button2:GetFontString():GetStringHeight() + 8)
	frame.button1:SetSize((width - 58) / 2, buttonHeight)
	frame.button2:SetSize((width - 58) / 2, buttonHeight)
	local copy = frame.spec and frame.spec.copyText
	frame.button2:SetShown(not copy)
	frame.button1:ClearAllPoints()
	if copy then
		frame.button1:SetWidth(buttonWidth)
		frame.button1:SetPoint("BOTTOM", 0, 18)
	else
		frame.button1:SetPoint("BOTTOMRIGHT", frame, "BOTTOM", -5, 18)
	end
	frame:SetHeight(inputTop + 30 + math.max(20, frame.BFL_ErrorLabel:GetStringHeight()) + buttonHeight + 28)
end

function Dialogs:CreateInputDialog()
	local frame = CreateFrame("Frame", "BFLInputDialog", UIParent, "BackdropTemplate")
	frame:Hide()
	frame:SetSize(380, 188)
	frame:SetFrameStrata("DIALOG")
	frame:SetToplevel(true)
	frame:SetClampedToScreen(true)
	frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
	frame.title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	frame.title:SetPoint("TOPLEFT", 24, -18)
	frame.title:SetPoint("TOPRIGHT", -24, -18)
	frame.title:SetWordWrap(false)
	frame.title:SetText("BetterFriendlist")
	frame.TitleContainer = { TitleText = frame.title }
	frame.text = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	frame.text:SetPoint("TOPLEFT", 24, -45)
	frame.text:SetPoint("TOPRIGHT", -24, -45)
	frame.text:SetWordWrap(true)
	frame.EditBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
	frame.editBox = frame.EditBox
	frame.EditBox:SetSize(280, 24)
	frame.EditBox:SetPoint("TOP", 0, -82)
	frame.EditBox:SetAutoFocus(false)
	frame.BFL_ErrorLabel = frame:CreateFontString(nil, "ARTWORK", "GameFontRedSmall")
	frame.BFL_ErrorLabel:SetPoint("TOPLEFT", 24, -111)
	frame.BFL_ErrorLabel:SetPoint("TOPRIGHT", -24, -111)
	frame.BFL_ErrorLabel:SetWordWrap(true)
	frame.button1 = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	frame.button2 = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	frame.button1:SetSize(145, 24)
	frame.button2:SetSize(145, 24)
	frame.button1:SetPoint("BOTTOMRIGHT", frame, "BOTTOM", -5, 18)
	frame.button2:SetPoint("BOTTOMLEFT", frame, "BOTTOM", 5, 18)
	frame.button1:SetScript("OnClick", function() self:AcceptInputDialog() end)
	frame.button2:SetScript("OnClick", function()
		if frame.spec and frame.spec.OnCancel then frame.spec.OnCancel(frame, frame.data) end
		frame:Hide()
	end)
	frame.EditBox:SetScript("OnEnterPressed", function() self:AcceptInputDialog() end)
	frame.EditBox:SetScript("OnEscapePressed", function()
		if frame.spec and frame.spec.copyText then frame:Hide() else frame.button2:Click() end
	end)
	frame.EditBox:SetScript("OnKeyUp", function(_, key)
		if frame.spec and frame.spec.copyText and key == "C" and IsControlKeyDown() then frame:Hide() end
	end)
	frame.EditBox:SetScript("OnTextChanged", function(editBox, userInput)
		if frame.spec and frame.spec.EditBoxOnTextChanged then
			frame.spec.EditBoxOnTextChanged(editBox, userInput)
		end
		self:LayoutInputDialog()
	end)
	frame:SetScript("OnHide", function()
		if frame.spec and frame.spec.OnHide then frame.spec.OnHide(frame, frame.data) end
		frame.spec, frame.data, frame.which = nil, nil, nil
		frame.EditBox:ClearFocus()
	end)
	table.insert(UISpecialFrames, "BFLInputDialog")
	self.inputDialog = frame
	return frame
end

function Dialogs:RaiseInputDialog(frame)
	local level = frame:GetParent():GetFrameLevel()
	local function Include(window)
		if not window or not window:IsVisible() or window:GetFrameStrata() ~= "DIALOG" then return end
		level = math.max(level, window:GetFrameLevel())
		for _, child in ipairs({ window:GetChildren() }) do Include(child) end
	end
	local editor = BFL:GetModule("FriendTagEditor")
	local designer = BFL:GetModule("SettingsDesigner")
	Include(editor and editor.frame)
	Include(_G.BetterFriendlistSettingsFrame)
	Include(designer and designer.GetFrame and designer:GetFrame())
	-- Keep Blizzard's DIALOG strata and top-level Raise behavior, while placing
	-- our private frame above the visible BFL editor hierarchy as well.
	local function SetLevel(window, value)
		window:SetFrameLevel(value)
		for _, child in ipairs({ window:GetChildren() }) do
			SetLevel(child, value + ((child == window.BFL_DarkBackdrop or child == window.backdrop) and -1 or 1))
		end
	end
	-- The flat backdrop sits one level below its owner. Keep that backdrop
	-- above the editor too, and move the private controls with their parent.
	SetLevel(frame, level + 2)
	frame:Raise()
end

function Dialogs:ShowInput(which, text1, text2, data)
	local db = BFL:GetModule("DB")
	local spec = StaticPopupDialogs[which]
	if not (INPUT_DIALOGS[which] and spec and db and db:Get("useThemedDialogs", true)) then
		return StaticPopup_Show(which, text1, text2, data)
	end
	local frame = self.inputDialog or self:CreateInputDialog()
	if frame:IsShown() then frame:Hide() end
	frame.spec, frame.data, frame.which = nil, nil, nil
	frame.EditBox:SetNumeric(false)
	frame.EditBox:SetMaxLetters(0)
	frame.EditBox:SetText("")
	frame.BFL_ErrorLabel:SetText("")
	frame.button1:Enable()
	frame.spec, frame.data, frame.which = spec, data, which
	frame.text:SetText((text1 or text2) and string.format(spec.text, text1 or "", text2 or "") or spec.text)
	frame.button1:SetText(spec.button1)
	frame.button2:SetText(spec.button2 or CANCEL)
	frame.EditBox:SetWidth(math.min(spec.editBoxWidth or 280, math.max(80, UIParent:GetWidth() / BFL.WindowGeometry:GetRatio(frame) - 72)))
	self:RefreshInputDialogTheme()
	-- Match StaticPopup's ordinary in-game anchor and top-level dialog ordering
	-- without joining its shared popup pool or changing Blizzard-owned frames.
	local parent = GetFullScreenFrame and GetFullScreenFrame() or UIParent
	frame:SetParent(parent)
	frame:ClearAllPoints()
	frame:SetPoint("TOP", parent, "TOP", 0, spec.topOffset or -135)
	frame:Show()
	self:RaiseInputDialog(frame)
	if spec.OnShow then spec.OnShow(frame, data) end
	self:LayoutInputDialog()
	return frame
end

function BFL.ShowInputDialog(...)
	return Dialogs:ShowInput(...)
end

-- Links and explicit copy actions share the private input dialog, including
-- theme, layering and the user's native-dialog preference. Never skin a pooled
-- StaticPopup slot or leave a copy-specific key handler installed on it.
function Dialogs:HideFriendLocalTime()
	local frame = self.inputDialog
	if frame and frame.which == "BFL_FRIEND_LOCAL_TIME" and frame:IsShown() then frame:Hide() end
	if StaticPopup_Hide then StaticPopup_Hide("BFL_FRIEND_LOCAL_TIME") end
end

function Dialogs:ShowFriendLocalTime(key)
	local clock = BFL:GetModule("FriendLocalTime")
	if not clock:IsEnabled() then return end

	local function RefreshPreview(frame)
		if not frame.data or not frame:IsShown() then return end
		if not clock:IsEnabled() then
			frame:Hide()
			return
		end
		local now = clock:GetTimestamp()
		local ownOffset = clock:GetLocalOffset(now)
		local box = frame.EditBox or frame:GetEditBox()
		local offset = clock:GetOffsetFromDifference(box:GetText(), ownOffset)
		local ownTime = clock:FormatTime(now, ownOffset)
		local friendTime = offset and clock:FormatTime(now, offset) or "--:--"
		local text = L.FRIEND_LOCAL_TIME_PROMPT .. "\n\n" .. L.FRIEND_LOCAL_TIME_PREVIEW:format(ownTime, friendTime)
		local label = frame.BFL_ErrorLabel and frame.text or frame:GetTextFontString()
		if label:GetText() == text then return end
		label:SetText(text)
		if frame.BFL_ErrorLabel then self:LayoutInputDialog() else frame:Resize() end
	end

	StaticPopupDialogs.BFL_FRIEND_LOCAL_TIME = {
		text = L.FRIEND_LOCAL_TIME_PROMPT,
		button1 = SAVE or ACCEPT,
		button2 = CANCEL,
		hasEditBox = true,
		hideOnEscape = true,
		OnShow = function(frame, data)
			local box = frame.EditBox or frame:GetEditBox()
			local offset = clock:GetOffset(data.key)
			local ownOffset = clock:GetLocalOffset(clock:GetTimestamp())
			box:SetMaxLetters(8)
			box:SetText(offset and clock:FormatDifference(offset - ownOffset) or "")
			box:SetFocus()
			box:HighlightText()
			RefreshPreview(frame)
			local ticker = C_Timer.NewTicker(1, function() RefreshPreview(frame) end)
			data.previewTicker = ticker
		end,
		OnHide = function(_, data)
			if data and data.previewTicker then
				data.previewTicker:Cancel()
				data.previewTicker = nil
			end
		end,
		OnAccept = function(frame, data)
			if not clock:IsEnabled() then return end
			local box = frame.EditBox or frame:GetEditBox()
			local ownOffset = clock:GetLocalOffset(clock:GetTimestamp())
			local offset, valid = clock:GetOffsetFromDifference(box:GetText(), ownOffset)
			if not valid then
				if frame.BFL_ErrorLabel then
					frame.BFL_ErrorLabel:SetText(L.FRIEND_LOCAL_TIME_INVALID)
					self:LayoutInputDialog()
				else
					UIErrorsFrame:AddExternalErrorMessage(L.FRIEND_LOCAL_TIME_INVALID)
				end
				box:SetFocus()
				return true
			end
			clock:SetOffset(data.key, offset)
		end,
		EditBoxOnTextChanged = function(box)
			local frame = box:GetParent()
			if frame.BFL_ErrorLabel then frame.BFL_ErrorLabel:SetText("") end
			RefreshPreview(frame)
		end,
		EditBoxOnEnterPressed = function(box)
			box:GetParent():GetButton1():Click()
		end,
		EditBoxOnEscapePressed = function(box)
			box:GetParent():Hide()
		end,
	}
	return self:ShowInput("BFL_FRIEND_LOCAL_TIME", nil, nil, { key = key })
end

-- Links and explicit copy actions share the private input dialog, including
-- theme, layering and the user's native-dialog preference. Never skin a pooled
-- StaticPopup slot or leave a copy-specific key handler installed on it.
function Dialogs:ShowCopy(value, title, width)
	StaticPopupDialogs.BFL_COPY_TEXT = {
		text = title or L.SETTINGS_CENTER_SUPPORT_COPY_LINKS,
		button1 = CLOSE or OKAY,
		hasEditBox = true,
		copyText = true,
		maxLetters = 0,
		editBoxWidth = width or 350,
		OnShow = function(dialog)
			local editBox = dialog.EditBox or dialog.editBox
			editBox:SetNumeric(false)
			editBox:SetMaxLetters(0)
			editBox:SetText(value)
			editBox:SetFocus()
			editBox:HighlightText()
		end,
		EditBoxOnEnterPressed = function(editBox) editBox:GetParent():Hide() end,
		EditBoxOnEscapePressed = function(editBox) editBox:GetParent():Hide() end,
		timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
	}
	return self:ShowInput("BFL_COPY_TEXT")
end

local function ApplyDefaultSlugToFontString(fontString)
	if BFL.FontManager and BFL.FontManager.ApplyDefaultSlugToFontString then
		BFL.FontManager:ApplyDefaultSlugToFontString(fontString)
	end
end

--------------------------------------------------------------------------
-- Dialog Registration
--------------------------------------------------------------------------

-- Helper to add error label to dialog if it doesn't exist
local function EnsureErrorLabel(dialog)
	if not dialog.BFL_ErrorLabel then
		local errorLabel = dialog:CreateFontString(nil, "ARTWORK", "GameFontRedSmall")
		ApplyDefaultSlugToFontString(errorLabel)
		errorLabel:SetPoint("TOP", dialog.EditBox, "BOTTOM", 0, 0)
		errorLabel:SetPoint("LEFT", dialog, "LEFT", 30, 0)
		errorLabel:SetPoint("RIGHT", dialog, "RIGHT", -30, 0)
		errorLabel:SetWordWrap(true)
		dialog.BFL_ErrorLabel = errorLabel
	end
	return dialog.BFL_ErrorLabel
end

local function EndGroupValidation(dialog)
	local color = dialog.BFL_GroupEditBoxColor
	if color then
		dialog.BFL_GroupEditBoxColor = nil
		dialog.EditBox:SetTextColor(unpack(color))
	end
	if dialog.BFL_ErrorLabel then
		dialog.BFL_ErrorLabel:SetText("")
	end
end

-- Shared validation logic
local function ValidateDialogInput(editBox, isRename)
	local dialog = editBox:GetParent()
	local color = dialog.BFL_GroupEditBoxColor
	-- StaticPopup clears the edit box after OnHide and may dispatch a text change.
	if not color then
		return
	end
	local text = editBox:GetText()
	local Groups = BFL:GetModule("Groups")
	local errorLabel = EnsureErrorLabel(dialog)
	
	-- Safely get the accept button (Button1)
	local button1 = dialog.button1
	
	-- Last resort: Check global name if we have one (covers Button1)
	if not button1 and dialog.GetName and dialog:GetName() then
		button1 = _G[dialog:GetName().."Button1"]
	end

	-- Absolute fallback for standard StaticPopup1 (Common case)
	if not button1 and dialog == StaticPopup1 and _G["StaticPopup1Button1"] then
		button1 = _G["StaticPopup1Button1"]
	end

	-- Ultimate fallback: Scan children for the button (Robustness for renamed/hooked frames)
	if not button1 and dialog.GetChildren then
		local children = {dialog:GetChildren()}
		for _, child in ipairs(children) do
			if child and child.GetObjectType and child:GetObjectType() == "Button" and child.GetText then
				local btnText = child:GetText()
				-- Check for Create or Rename button text
				if btnText and (btnText == L.DIALOG_CREATE_GROUP_BTN1 or btnText == L.DIALOG_RENAME_GROUP_BTN1) then
					button1 = child
					break
				end
			end
		end
	end
	
	if not Groups then return end
	
	local currentGroupId = isRename and dialog.data or nil
	local isValid, errorMsg = Groups:ValidateGroupName(text, currentGroupId)

	-- Debug visualization for troubleshooting
	-- if BFL.DebugPrint then
	-- 	BFL:DebugPrint("Validation:", text, "| Rename:", isRename, "| Valid:", isValid, "| ButtonFound:", (button1 ~= nil))
	-- end
	
	if isValid then
		if button1 then
			button1:Enable()
		end
		if errorLabel then
			errorLabel:SetText("")
			editBox:SetTextColor(unpack(color))
		end
	else
		if button1 then
			button1:Disable()
		end
		if errorLabel then
			errorLabel:SetText(errorMsg or "")
			editBox:SetTextColor(1, 0.5, 0.5) -- Reddish text to indicate error
		end
	end
end

local function StartGroupValidation(dialog, isRename)
	-- StaticPopup edit boxes are shared with numeric dialogs and other skins.
	dialog.EditBox:SetNumeric(false)
	dialog.BFL_GroupEditBoxColor = { dialog.EditBox:GetTextColor() }
	ValidateDialogInput(dialog.EditBox, isRename)
end

local function CreateGroupFromDialog(editBox, friendUID)
	local groups = BFL:GetModule("Groups")
	local friends = BFL:GetModule("FriendsList")
	local expectedGroupKey
	if type(friendUID) == "table" then
		expectedGroupKey = friendUID.groupKey
		friendUID = friendUID.uid
	end
	local name = editBox:GetText()
	if groups and friends and groups:ValidateGroupName(name) then
		return friends:CreateGroup(name, friendUID, expectedGroupKey)
	end
end

function Dialogs:RegisterDialogs()
	-- Dialog for creating a new group
	StaticPopupDialogs["BETTER_FRIENDLIST_CREATE_GROUP"] = {
		text = L.DIALOG_CREATE_GROUP_TEXT,
		button1 = L.DIALOG_CREATE_GROUP_BTN1,
		button2 = L.DIALOG_CREATE_GROUP_BTN2,
		hasEditBox = true,
		OnAccept = function(self)
			CreateGroupFromDialog(self.EditBox)
		end,
		EditBoxOnTextChanged = function(self)
			ValidateDialogInput(self, false)
		end,
		EditBoxOnEnterPressed = function(self)
			if CreateGroupFromDialog(self) then self:GetParent():Hide() end
		end,
		EditBoxOnEscapePressed = function(self)
			self:GetParent():Hide()
		end,
		OnShow = function(self)
			self.EditBox:SetFocus()
			StartGroupValidation(self, false)
		end,
		OnHide = EndGroupValidation,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = 3,
	}

	-- Dialog for creating a new group and adding a friend to it
	StaticPopupDialogs["BETTER_FRIENDLIST_CREATE_GROUP_AND_ADD_FRIEND"] = {
		text = L.DIALOG_CREATE_GROUP_TEXT,
		button1 = L.DIALOG_CREATE_GROUP_BTN1,
		button2 = L.DIALOG_CREATE_GROUP_BTN2,
		hasEditBox = true,
		OnAccept = function(self, friendUID)
			CreateGroupFromDialog(self.EditBox, friendUID)
		end,
		EditBoxOnTextChanged = function(self)
			ValidateDialogInput(self, false)
		end,
		EditBoxOnEnterPressed = function(self, friendUID)
			local parent = self:GetParent()
			if CreateGroupFromDialog(self, friendUID or parent.data) then parent:Hide() end
		end,
		EditBoxOnEscapePressed = function(self)
			self:GetParent():Hide()
		end,
		OnShow = function(self)
			self.EditBox:SetFocus()
			StartGroupValidation(self, false)
		end,
		OnHide = EndGroupValidation,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = 3,
	}

	-- Dialog for renaming a group
	StaticPopupDialogs["BETTER_FRIENDLIST_RENAME_GROUP"] = {
		text = L.DIALOG_RENAME_GROUP_TEXT,
		button1 = L.DIALOG_RENAME_GROUP_BTN1,
		button2 = L.DIALOG_RENAME_GROUP_BTN2,
		hasEditBox = true,
		OnAccept = function(self, data)
			local newName = self.EditBox:GetText()
			local FriendsList = BFL and BFL:GetModule("FriendsList")
			if FriendsList then
				-- We assume validation passed because button was enabled
				local success, err = FriendsList:RenameGroup(data, newName)
				if success then
					local Settings = BFL and BFL:GetModule("Settings")
					if Settings then
						Settings:RefreshGroupList()
					end
					BFL:ForceRefreshFriendsList()
				end
			end
		end,
		EditBoxOnTextChanged = function(self)
			ValidateDialogInput(self, true)
		end,
		EditBoxOnEnterPressed = function(self, data)
			local parent = self:GetParent()
			local newName = self:GetText()
			
			-- Double check validation manually if needed, or rely on visual state logic
			local Groups = BFL:GetModule("Groups")
			if Groups then
				local isValid = Groups:ValidateGroupName(newName, data)
				if isValid then
					local FriendsList = BFL and BFL:GetModule("FriendsList")
					if FriendsList then
						local success, err = FriendsList:RenameGroup(data, newName)
						if success then
							local Settings = BFL and BFL:GetModule("Settings")
							if Settings then
								Settings:RefreshGroupList()
							end
							BFL:ForceRefreshFriendsList()
							parent:Hide()
						end
					end
				end
			end
		end,
		EditBoxOnEscapePressed = function(self)
			self:GetParent():Hide()
		end,
		OnShow = function(self, data)
			-- Get group info from Groups module
			local Groups = BFL and BFL:GetModule("Groups")
			local groupName = ""
			
			if Groups and data then
				local groupInfo = Groups:Get(data)
				if groupInfo then
					groupName = groupInfo.name or ""
				end
			end
			
			self.EditBox:SetText(groupName)
			self.EditBox:SetFocus()
			self.EditBox:HighlightText()
			StartGroupValidation(self, true)
		end,
		OnHide = EndGroupValidation,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = 3,
	}

	-- Dialog for deleting a group
	StaticPopupDialogs["BETTER_FRIENDLIST_DELETE_GROUP"] = {
		text = L.DIALOG_DELETE_GROUP_TEXT,
		button1 = L.DIALOG_DELETE_GROUP_BTN1,
		button2 = L.DIALOG_DELETE_GROUP_BTN2,
		OnAccept = function(self, data)
			local groupId = data
			local FriendsList = BFL:GetModule("FriendsList")
			if FriendsList then
				FriendsList:DeleteGroup(groupId)
			end
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = 3,
	}
	
	-- Dialog for resetting all Edit Mode layouts (Phase 5)
	StaticPopupDialogs["BETTER_FRIENDLIST_RESET_ALL_LAYOUTS"] = {
		text = BFL.L.DIALOG_RESET_LAYOUTS_TEXT,
		button1 = BFL.L.DIALOG_RESET_LAYOUTS_BTN1,
		button2 = BFL.L.DIALOG_RESET_BTN2, -- Cancel
		OnAccept = function(self)
			-- Clear all layout data
			BetterFriendlistDB.mainFrameSize = {}
			BetterFriendlistDB.mainFramePosition = {}
			BetterFriendlistDB.mainFramePositionMigrated = false
			
			-- Reset frame to default size and position
			local frame = BetterFriendsFrame
			if frame then
				frame:ClearAllPoints()
				frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
				frame:SetSize(415, 570)
				
				-- Trigger responsive updates
				if BFL.MainFrameEditMode then
					BFL.MainFrameEditMode:TriggerResponsiveUpdates()
				end
			end
			
			-- BFL:DebugPrint("|cff00ff00All Edit Mode layouts reset to default|r")
			print("|cff00ffffBetterFriendlist:|r " .. BFL.L.MSG_LAYOUTS_RESET)
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = 3,
	}

	-- Confirm UI Panel System Change (requires reload)
	StaticPopupDialogs["BFL_CONFIRM_UI_PANEL_RELOAD"] = {
		text = BFL.L.DIALOG_UI_PANEL_RELOAD_TEXT or "Changing the UI Hierarchy setting requires a UI reload.\n\nReload now?",
		button1 = BFL.L.DIALOG_UI_PANEL_RELOAD_BTN1 or "Reload",
		button2 = BFL.L.DIALOG_UI_PANEL_RELOAD_BTN2 or "Cancel",
		OnAccept = function(self)
			local DB = BFL:GetModule("DB")
			if DB and DB.pendingUIPanelSystemChange ~= nil then
				DB:Set("useUIPanelSystem", DB.pendingUIPanelSystemChange)
				DB.pendingUIPanelSystemChange = nil
				ReloadUI()
			end
		end,
		OnCancel = function(self)
			local DB = BFL:GetModule("DB")
			if DB then
				DB.pendingUIPanelSystemChange = nil
				-- Revert checkbox to original state
				if BFL.Settings and BFL.Settings.RefreshSettingsPanel then
					BFL.Settings:RefreshSettingsPanel()
				end
			end
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = 3,
	}
	

end

--------------------------------------------------------------------------
-- Module Initialization
--------------------------------------------------------------------------

-- Auto-register dialogs when module loads
Dialogs:RegisterDialogs()

