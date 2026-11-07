-- Shared Friend Tags & Chips editor for legacy settings and Settings Center.

local ADDON_NAME, BFL = ...

local FriendTagEditor = BFL:RegisterModule("FriendTagEditor", { drafts = {} })

local FRAME_NAME = "BetterFriendlistFriendTagEditorFrame"
local ROW_HEIGHT = 42
local ROW_GAP = 4
local LEFT_WIDTH = 230
local EDITOR_WIDTH = 800
local EDITOR_HEIGHT = 550

local function L(key, fallback)
	local locale = BFL and BFL.L
	return (locale and key and locale[key]) or fallback
end

local function GetFriendTags()
	return BFL and BFL:GetModule("FriendTags")
end

local function GetTagChips()
	return BFL and BFL:GetModule("TagChips")
end

local function CopyColor(color, fallback)
	color = type(color) == "table" and color or fallback
	if type(color) ~= "table" then
		return { r = 0.64, g = 0.86, b = 0.56, a = 1 }
	end
	return {
		r = tonumber(color.r) or 0.64,
		g = tonumber(color.g) or 0.86,
		b = tonumber(color.b) or 0.56,
		a = color.a == nil and 1 or (tonumber(color.a) or 1),
	}
end

local function ClearChildren(frame)
	if not frame then
		return
	end
	local regions = { frame:GetRegions() }
	for _, region in ipairs(regions) do
		region:Hide()
	end
	local children = { frame:GetChildren() }
	for _, child in ipairs(children) do
		child:Hide()
		child:SetParent(nil)
	end
end

local function Trim(value)
	if type(value) ~= "string" then
		return ""
	end
	if strtrim then
		return strtrim(value)
	end
	return value:gsub("^%s+", ""):gsub("%s+$", "")
end

local function GetEditBoxText(editBox)
	return editBox and editBox.GetText and Trim(editBox:GetText()) or ""
end

local function SetEditBoxText(editBox, text)
	if editBox and editBox.SetText then
		editBox:SetText(text == nil and "" or tostring(text))
	end
end

local function CreateFont(parent, template)
	return parent:CreateFontString(nil, "OVERLAY", template or "BetterFriendlistFontHighlight")
end

local function CreateSmallButton(parent, text, width, onClick, textPadding)
	local template = not BFL.IsClassic and "SharedButtonTemplate" or "UIPanelButtonTemplate"
	local ok, button = pcall(CreateFrame, "Button", nil, parent, template)
	if not ok or not button then
		button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	end
	button:SetText(text or "")
	local fontString = button.GetFontString and button:GetFontString()
	local textWidth = fontString and fontString:GetStringWidth() or 0
	button:SetSize(math.max(width or 110, math.ceil(textWidth + (textPadding or 30))), 26)
	button:SetScript("OnClick", function(self)
		if onClick then
			onClick(self)
		end
	end)
	return button
end

local function CreateTextAction(parent, text, onClick)
	local button = CreateFrame("Button", nil, parent)
	local label = CreateFont(button, "BetterFriendlistFontNormalSmall")
	label:SetPoint("CENTER")
	button:SetFontString(label)
	button:SetNormalFontObject("BetterFriendlistFontNormalSmall")
	button:SetHighlightFontObject("BetterFriendlistFontHighlightSmall")
	button:SetDisabledFontObject("BetterFriendlistFontDisableSmall")
	button:SetText(text)
	button:SetSize(math.ceil(label:GetStringWidth()) + 8, 26)
	button:SetScript("OnClick", onClick)
	return button
end

local function CreateCheckbox(parent, label, checked, onClick, tooltipTitle, tooltipDesc)
	local template = BFL.IsClassic and "InterfaceOptionsCheckButtonTemplate" or "SettingsCheckboxTemplate"
	local check = CreateFrame("CheckButton", nil, parent, template)
	check:SetSize(24, 24)
	check:SetChecked(checked == true)
	check:SetScript("OnClick", function(self)
		if onClick then
			onClick(self:GetChecked() == true)
		end
	end)
	if check.Text then
		check.Text:SetText("")
	elseif check.SetText then
		check:SetText("")
	end

	local text = CreateFont(parent, "BetterFriendlistFontHighlightSmall")
	text:SetText(label or "")
	text:SetJustifyH("LEFT")
	text:SetPoint("LEFT", check, "RIGHT", 4, 0)
	text:SetPoint("RIGHT", parent, "RIGHT", -4, 0)
	if tooltipTitle or tooltipDesc then
		local function ShowTooltip(owner)
			BFL_Tooltip:SetOwner(owner, "ANCHOR_RIGHT")
			BFL_Tooltip:ClearLines()
			BFL_Tooltip:SetText(tooltipTitle or label or "", 1, 1, 1)
			if tooltipDesc then
				BFL_Tooltip:AddLine(tooltipDesc, 0.8, 0.8, 0.8, true)
			end
			BFL_Tooltip:Show()
		end
		local function HideTooltip()
			BFL_Tooltip:Hide()
		end
		check:SetScript("OnEnter", ShowTooltip)
		check:SetScript("OnLeave", HideTooltip)
		parent:EnableMouse(true)
		parent:SetScript("OnEnter", ShowTooltip)
		parent:SetScript("OnLeave", HideTooltip)
	end
	return check, text
end

local function CreateInput(parent, width, maxLetters)
	local editBox = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
	editBox:SetSize(width or 220, 24)
	editBox:SetAutoFocus(false)
	editBox:SetMaxLetters(maxLetters or 128)
	editBox:SetFontObject("BetterFriendlistFontHighlightSmall")
	return editBox
end

function FriendTagEditor:BindEditorInputFocusHandlers(editBox)
	editBox:SetScript("OnEnterPressed", editBox.ClearFocus)
	editBox:SetScript("OnEscapePressed", editBox.ClearFocus)
end

local function FindIconOptionByTexture(options, texture)
	if type(options) ~= "table" then
		return nil
	end
	for _, option in ipairs(options) do
		if texture and (option.iconValue == texture or option.texture == texture or option.icon == texture or option.atlas == texture) then
			return option
		end
	end
	return nil
end

local VALID_ICON_MODES = {
	option = true,
	selected = true,
	custom = true,
	none = true,
}

local function ResolveStoredIconMode(profile, dbProfile, selectedIcon)
	profile = type(profile) == "table" and profile or {}
	dbProfile = type(dbProfile) == "table" and dbProfile or {}
	local storedMode = type(dbProfile.iconMode) == "string" and dbProfile.iconMode or nil
	if storedMode and VALID_ICON_MODES[storedMode] then
		return storedMode
	end

	local iconValue = profile.iconValue or profile.atlas or profile.texture or profile.icon
	if not iconValue or iconValue == "" or profile.iconType == "none" then
		return "none"
	end
	if selectedIcon then
		-- Profiles saved before iconMode existed can contain a custom path that is
		-- also the fallback texture of an atlas option. Treat an explicit
		-- texture-only override as Custom Path so reopening the tag cannot replace
		-- it with that option's atlas.
		local explicitTexture = dbProfile.texture or dbProfile.iconValue or dbProfile.icon
		local matchesOptionFallback = explicitTexture ~= nil
			and selectedIcon.texture ~= nil
			and tostring(explicitTexture) == tostring(selectedIcon.texture)
		local hasOptionAtlasState = dbProfile.atlas ~= nil
			or dbProfile.fallbackAtlas ~= nil
			or dbProfile.texCoord ~= nil
		if
			profile.iconType == "texture"
			and matchesOptionFallback
			and (selectedIcon.atlas ~= nil or selectedIcon.fallbackAtlas ~= nil)
			and not hasOptionAtlasState
		then
			return "custom"
		end
		return "option"
	end
	if NormalizeIconZoom(profile.iconZoom) ~= false then
		return "selected"
	end
	return "custom"
end

local function CopyTexCoord(texCoord)
	if type(texCoord) ~= "table" then
		return nil
	end
	return {
		tonumber(texCoord[1]) or 0,
		tonumber(texCoord[2]) or 1,
		tonumber(texCoord[3]) or 0,
		tonumber(texCoord[4]) or 1,
	}
end

local function NormalizeIconZoom(value)
	if value == true then
		return true
	elseif value == nil or value == false then
		return false
	end
	local zoom = tonumber(value)
	if not zoom or zoom <= 0 then
		return false
	end
	return math.max(0, math.min(0.45, zoom))
end

local function CopyIconProfile(source)
	source = type(source) == "table" and source or {}
	local iconType = source.iconType
	local iconValue = source.iconValue
	local atlas = source.atlas
	local texture = source.texture
	local icon = source.icon

	if not iconType then
		iconType = atlas and "atlas" or "texture"
	end
	if not iconValue then
		iconValue = iconType == "atlas" and atlas or texture or icon
	end
	if not texture and iconType == "texture" then
		texture = iconValue
	end
	if not icon then
		icon = texture or iconValue
	end

	return {
		iconType = iconType,
		iconValue = iconValue,
		icon = icon,
		atlas = atlas,
		fallbackAtlas = source.fallbackAtlas,
		texture = texture,
		texCoord = CopyTexCoord(source.texCoord),
		iconZoom = NormalizeIconZoom(source.iconZoom),
	}
end

local function ApplyIcon(texture, profile)
	if not texture then
		return false
	end
	profile = CopyIconProfile(profile)
	return BFL.ApplyIconProfile and BFL.ApplyIconProfile(texture, profile) or false
end

local function GetPopupEditBox(dialog)
	if not dialog then
		return nil
	end
	return dialog.editBox or dialog.EditBox or (_G[dialog:GetName() and (dialog:GetName() .. "EditBox") or ""])
end

function FriendTagEditor:Initialize()
	StaticPopupDialogs["BFL_FRIEND_TAG_EDITOR_CREATE_CUSTOM"] = {
		text = L("FRIEND_TAGS_EDITOR_CREATE_PROMPT", "Create a new custom friend tag:"),
		button1 = ACCEPT or "Accept",
		button2 = CANCEL or "Cancel",
		hasEditBox = true,
		editBoxWidth = 220,
		OnShow = function(dialog)
			local editBox = GetPopupEditBox(dialog)
			if editBox then
				editBox:SetText("")
				editBox:SetFocus()
			end
		end,
		OnAccept = function(dialog)
			local editBox = GetPopupEditBox(dialog)
			local FriendTags = GetFriendTags()
			local tagId, reason
			if FriendTags then
				tagId, reason = FriendTags:CreateCustomTag(editBox and editBox:GetText(), function()
					FriendTagEditor:Refresh()
				end)
			end
			if tagId then
				FriendTagEditor:Show(tagId)
			elseif FriendTags and FriendTags.ShowTagNameError then
				FriendTags:ShowTagNameError(reason)
			end
		end,
		EditBoxOnEnterPressed = function(editBox)
			local FriendTags = GetFriendTags()
			local tagId, reason
			if FriendTags then
				tagId, reason = FriendTags:CreateCustomTag(editBox:GetText(), function()
					FriendTagEditor:Refresh()
				end)
			end
			if tagId then
				FriendTagEditor:Show(tagId)
			elseif FriendTags and FriendTags.ShowTagNameError then
				FriendTags:ShowTagNameError(reason)
			end
			editBox:GetParent():Hide()
		end,
		EditBoxOnEscapePressed = function(editBox)
			editBox:GetParent():Hide()
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = 3,
	}

	StaticPopupDialogs["BFL_FRIEND_TAG_EDITOR_DELETE_CUSTOM"] = {
		text = L("FRIEND_TAGS_EDITOR_DELETE_PROMPT", "Permanently delete custom tag '%s'?\n\n%s"),
		button1 = L("FRIEND_TAGS_EDITOR_DELETE", "Delete Tag"),
		button2 = CANCEL or "Cancel",
		OnAccept = function(_, data)
			local FriendTags = GetFriendTags()
			if FriendTags and data and data.tagId then
				FriendTags:DeleteCustomTag(data.tagId, function()
					FriendTagEditor.drafts[data.tagId] = nil
					if FriendTagEditor.selectedTagId == data.tagId then
						FriendTagEditor.selectedTagId = nil
					end
					FriendTagEditor:RefreshAfterDefinitionChange("delete")
				end)
			end
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = 3,
	}

	StaticPopupDialogs["BFL_FRIEND_TAG_EDITOR_UNSAVED_CLOSE"] = {
		text = L("FRIEND_TAGS_EDITOR_CLOSE_PROMPT", "Some tags have unapplied changes. Save them before closing the editor?"),
		button1 = L("FRIEND_TAGS_EDITOR_SAVE_ALL", "Save All"),
		button2 = L("FRIEND_TAGS_EDITOR_KEEP_EDITING", "Keep Editing"),
		button3 = L("FRIEND_TAGS_EDITOR_DISCARD_CLOSE", "Discard and Close"),
		OnAccept = function()
			if FriendTagEditor:CommitAllDrafts() then
				FriendTagEditor.frame:Hide()
			end
		end,
		OnAlt = function()
			wipe(FriendTagEditor.drafts)
			FriendTagEditor.frame:Hide()
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = 3,
	}
end

function FriendTagEditor:EnsureFrame()
	if self.frame then
		return self.frame
	end

	local template = not BFL.IsClassic and "ButtonFrameTemplate" or "BasicFrameTemplateWithInset"
	local frame = CreateFrame("Frame", FRAME_NAME, UIParent, template)
	frame:SetSize(EDITOR_WIDTH, EDITOR_HEIGHT)
	frame:SetPoint("CENTER")
	frame:SetFrameStrata("DIALOG")
	frame:SetToplevel(true)
	frame:SetClampedToScreen(true)
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
	frame:Hide()

	if not BFL.IsClassic then
		if ButtonFrameTemplate_HidePortrait then
			ButtonFrameTemplate_HidePortrait(frame)
		end
		if ButtonFrameTemplate_HideAttic then
			ButtonFrameTemplate_HideAttic(frame)
		end
		if frame.Inset then
			frame.Inset:Hide()
		end
	end
	frame.title = frame.TitleContainer and frame.TitleContainer.TitleText or frame.TitleText
	if not frame.title then
		frame.title = frame:CreateFontString(nil, "OVERLAY", "BetterFriendlistFontHighlight")
		frame.title:SetPoint("TOP", frame, "TOP", 0, -8)
	end
	frame.title:SetText(L("FRIEND_TAGS_EDITOR_TITLE", "Friend Tags & Chips"))

	frame.leftPane = CreateFrame("Frame", nil, frame, "BackdropTemplate")
	frame.leftPane:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -30)
	frame.leftPane:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 14, 10)
	frame.leftPane:SetWidth(LEFT_WIDTH)
	BFL.SetOwnedBackdrop(frame.leftPane, {
		bgFile = "Interface\\Buttons\\WHITE8X8",
		edgeFile = "Interface\\Buttons\\WHITE8X8",
		edgeSize = 1,
	})
	frame.leftPane:SetBackdropColor(0.03, 0.03, 0.04, 0.55)
	frame.leftPane:SetBackdropBorderColor(0.36, 0.36, 0.40, 0.45)

	frame.rightPane = CreateFrame("Frame", nil, frame, "BackdropTemplate")
	frame.rightPane:SetPoint("TOPLEFT", frame.leftPane, "TOPRIGHT", 12, 0)
	frame.rightPane:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -14, 10)
	BFL.SetOwnedBackdrop(frame.rightPane, {
		bgFile = "Interface\\Buttons\\WHITE8X8",
		edgeFile = "Interface\\Buttons\\WHITE8X8",
		edgeSize = 1,
	})
	frame.rightPane:SetBackdropColor(0.03, 0.03, 0.04, 0.40)
	frame.rightPane:SetBackdropBorderColor(0.36, 0.36, 0.40, 0.35)

	frame.listScroll = CreateFrame("ScrollFrame", nil, frame.leftPane, "UIPanelScrollFrameTemplate")
	frame.listScroll:SetPoint("TOPLEFT", frame.leftPane, "TOPLEFT", 6, -8)
	frame.listScroll:SetPoint("BOTTOMRIGHT", frame.leftPane, "BOTTOMRIGHT", -26, 54)
	frame.listContent = CreateFrame("Frame", nil, frame.listScroll)
	frame.listContent:SetSize(LEFT_WIDTH - 38, 1)
	frame.listScroll:SetScrollChild(frame.listContent)

	frame.editorContent = CreateFrame("Frame", nil, frame.rightPane)
	frame.editorContent:SetPoint("TOPLEFT", frame.rightPane, "TOPLEFT", 14, -14)
	frame.editorContent:SetPoint("BOTTOMRIGHT", frame.rightPane, "BOTTOMRIGHT", -14, 14)

	local createButton = CreateSmallButton(frame.leftPane, L("FRIEND_TAGS_CREATE_CUSTOM", "Create Custom Tag"), LEFT_WIDTH - 20, function()
		StaticPopup_Show("BFL_FRIEND_TAG_EDITOR_CREATE_CUSTOM")
	end)
	createButton:SetPoint("BOTTOM", frame.leftPane, "BOTTOM", 0, 14)
	frame.createButton = createButton

	frame.dragMarker = frame.leftPane:CreateTexture(nil, "OVERLAY")
	frame.dragMarker:SetColorTexture(1, 0.76, 0.18, 1)
	frame.dragMarker:SetHeight(2)
	frame.dragMarker:Hide()

	if frame.CloseButton then
		frame.CloseButton:SetScript("OnClick", function() self:RequestClose() end)
	end

	self.frame = frame
	return frame
end

function FriendTagEditor:RequestClose()
	if next(self.drafts) then
		StaticPopup_Show("BFL_FRIEND_TAG_EDITOR_UNSAVED_CLOSE")
	else
		self.frame:Hide()
	end
end

function FriendTagEditor:GetDefinitions()
	local FriendTags = GetFriendTags()
	return FriendTags and FriendTags:GetAllTagDefinitions() or {}
end

function FriendTagEditor:Show(tagId)
	local frame = self:EnsureFrame()
	local FriendsUI = BFL:GetModule("FriendsUI")
	if _G.BetterFriendsFrame and _G.BetterFriendsFrame:IsShown() and FriendsUI and FriendsUI.AnchorAuxiliaryWindow then
		FriendsUI:AnchorAuxiliaryWindow(frame, 0)
	else
		frame:ClearAllPoints()
		frame:SetPoint("CENTER")
	end
	self.selectedTagId = tagId or self.selectedTagId
	if not self.selectedTagId then
		local definitions = self:GetDefinitions()
		self.selectedTagId = definitions[1] and definitions[1].id or nil
	end
	self:Refresh()
	frame:Show()
	frame:Raise()
end

function FriendTagEditor:Refresh()
	self:EnsureFrame()
	local tags = GetFriendTags()
	for id in pairs(self.drafts) do
		if not tags or not tags:GetTagDefinition(id) then self.drafts[id] = nil end
	end
	if not self:GetSelectedDefinition() then
		local definitions = self:GetDefinitions()
		self.selectedTagId = definitions[1] and definitions[1].id or nil
	end
	self:RefreshList()
	self:RefreshEditor()
end

function FriendTagEditor:OnDatabaseImported()
	self.drafts = {}
	self.editState, self.savedState = nil, nil
	if self.frame and self.frame:IsShown() then self:Refresh() end
end

function FriendTagEditor:RefreshAfterDefinitionChange(reason)
	if BFL.ScheduleFriendsListRefresh then
		BFL:ScheduleFriendsListRefresh("friend-tag-editor-" .. tostring(reason or "change"), 0.05)
	elseif BFL.ForceRefreshFriendsList then
		BFL:ForceRefreshFriendsList()
	end
	self:Refresh()
end

function FriendTagEditor:RefreshList()
	local frame = self:EnsureFrame()
	ClearChildren(frame.listContent)

	local definitions = self:GetDefinitions()
	local FriendTags = GetFriendTags()
	frame.tagRows = {}

	for index, def in ipairs(definitions) do
		local row = CreateFrame("Button", nil, frame.listContent, "BackdropTemplate")
		row:SetPoint("TOPLEFT", frame.listContent, "TOPLEFT", 0, -((index - 1) * (ROW_HEIGHT + ROW_GAP)))
		row:SetPoint("RIGHT", frame.listContent, "RIGHT", -2, 0)
		row:SetHeight(ROW_HEIGHT)
		row:RegisterForDrag("LeftButton")
		row.tagId = def.id
		row.orderIndex = index
		BFL.SetOwnedBackdrop(row, {
			bgFile = "Interface\\Buttons\\WHITE8X8",
			edgeFile = "Interface\\Buttons\\WHITE8X8",
			edgeSize = 1,
		})
		local selected = self.selectedTagId == def.id
		row:SetBackdropColor(selected and 0.15 or 0.05, selected and 0.13 or 0.05, selected and 0.09 or 0.06, selected and 0.86 or 0.42)
		row:SetBackdropBorderColor(selected and 0.95 or 0.22, selected and 0.72 or 0.22, selected and 0.30 or 0.24, selected and 0.82 or 0.48)
		row:SetHighlightTexture("Interface\\Buttons\\WHITE8X8")
		local highlight = row:GetHighlightTexture()
		if highlight then
			highlight:SetVertexColor(1, 0.76, 0.18, 0.08)
		end

		local dragHandle = row:CreateTexture(nil, "ARTWORK")
		dragHandle:SetTexture("Interface\\AddOns\\BetterFriendlist\\Icons\\move")
		dragHandle:SetSize(13, 13)
		dragHandle:SetPoint("LEFT", row, "LEFT", 5, 0)
		dragHandle:SetVertexColor(0.55, 0.55, 0.58, 0.9)

		local profile = FriendTags and FriendTags:GetChipProfile(def)
		local icon = row:CreateTexture(nil, "ARTWORK")
		icon:SetSize(18, 18)
		icon:SetPoint("LEFT", row, "LEFT", 23, 0)
		if not ApplyIcon(icon, profile) then
			icon:Hide()
		end
		row.icon = icon

		local name = CreateFont(row, "BetterFriendlistFontHighlightSmall")
		name:SetPoint("LEFT", icon, "RIGHT", 6, 7)
		name:SetPoint("RIGHT", row, "RIGHT", -18, 7)
		name:SetHeight(15)
		name:SetJustifyH("LEFT")
		name:SetJustifyV("MIDDLE")
		name:SetText(def.name or def.id)

		local source = CreateFont(row, "BetterFriendlistFontDisableSmall")
		source:SetPoint("LEFT", icon, "RIGHT", 6, -9)
		source:SetPoint("RIGHT", row, "RIGHT", -6, -9)
		source:SetHeight(13)
		source:SetJustifyH("LEFT")
		source:SetJustifyV("MIDDLE")
		source:SetText(def.source == "custom" and L("FRIEND_TAGS_SOURCE_CUSTOM", "Custom") or L("FRIEND_TAGS_SOURCE_BLIZZARD", "Blizzard"))
		local marker = row:CreateTexture(nil, "OVERLAY")
		marker:SetSize(6, 6)
		marker:SetPoint("RIGHT", row, "RIGHT", -7, 7)
		marker:SetColorTexture(1, 0.76, 0.18, 1)
		marker:SetShown(self.drafts[def.id] ~= nil)
		row.draftMarker = marker

		row:SetScript("OnClick", function()
			self.selectedTagId = def.id
			self:Refresh()
		end)
		row:SetScript("OnDragStart", function()
			self:BeginTagDrag(row)
		end)
		row:SetScript("OnDragStop", function()
			self:EndTagDrag(row)
		end)
		frame.tagRows[index] = row
	end

	if #definitions == 0 then
		local empty = CreateFont(frame.listContent, "BetterFriendlistFontDisableSmall")
		empty:SetPoint("TOPLEFT", frame.listContent, "TOPLEFT", 8, -8)
		empty:SetText(L("FRIEND_TAGS_NO_CUSTOM_TAGS", "No custom tags yet"))
	end

	frame.listContent:SetHeight(math.max(1, (#definitions * (ROW_HEIGHT + ROW_GAP)) - ROW_GAP))
end

function FriendTagEditor:RefreshListRowIcon(tagId)
	local frame = self.frame
	local FriendTags = GetFriendTags()
	if not (frame and frame.tagRows and FriendTags and tagId) then
		return false
	end
	for _, row in ipairs(frame.tagRows) do
		if row.tagId == tagId and row.icon then
			local profile = FriendTags:GetChipProfile(tagId)
			if ApplyIcon(row.icon, profile) then
				row.icon:Show()
			else
				row.icon:Hide()
			end
			return true
		end
	end
	return false
end

function FriendTagEditor:BeginTagDrag(row)
	local frame = self:EnsureFrame()
	if not (row and row.orderIndex and frame.tagRows) then
		return
	end
	self.dragState = { fromIndex = row.orderIndex, targetIndex = row.orderIndex, row = row }
	row:SetAlpha(0.42)
	frame:SetScript("OnUpdate", function()
		self:UpdateTagDrag()
	end)
	self:UpdateTagDrag()
end

function FriendTagEditor:UpdateTagDrag()
	local frame = self.frame
	local drag = self.dragState
	if not (frame and drag and frame.tagRows and #frame.tagRows > 0) then
		return
	end
	local _, cursorY = GetCursorPosition()
	cursorY = cursorY / UIParent:GetEffectiveScale()
	local targetIndex = #frame.tagRows + 1
	for index, row in ipairs(frame.tagRows) do
		local top, bottom = row:GetTop(), row:GetBottom()
		if top and bottom and cursorY >= ((top + bottom) / 2) then
			targetIndex = index
			break
		end
	end
	drag.targetIndex = targetIndex
	frame.dragMarker:ClearAllPoints()
	local target = frame.tagRows[targetIndex]
	if target then
		frame.dragMarker:SetPoint("TOPLEFT", target, "TOPLEFT", 0, 2)
		frame.dragMarker:SetPoint("TOPRIGHT", target, "TOPRIGHT", 0, 2)
	else
		local lastRow = frame.tagRows[#frame.tagRows]
		frame.dragMarker:SetPoint("BOTTOMLEFT", lastRow, "BOTTOMLEFT", 0, -2)
		frame.dragMarker:SetPoint("BOTTOMRIGHT", lastRow, "BOTTOMRIGHT", 0, -2)
	end
	frame.dragMarker:Show()
end

function FriendTagEditor:EndTagDrag(row)
	local frame = self.frame
	local drag = self.dragState
	if frame then
		frame:SetScript("OnUpdate", nil)
		frame.dragMarker:Hide()
	end
	if row then
		row:SetAlpha(1)
	end
	self.dragState = nil
	if not drag then
		return
	end

	local definitions = {}
	for index, def in ipairs(self:GetDefinitions()) do
		definitions[index] = def
	end
	local moved = table.remove(definitions, drag.fromIndex)
	if not moved then
		return
	end
	local insertIndex = drag.targetIndex
	if insertIndex > drag.fromIndex then
		insertIndex = insertIndex - 1
	end
	insertIndex = math.max(1, math.min(insertIndex, #definitions + 1))
	if insertIndex == drag.fromIndex then
		return
	end
	table.insert(definitions, insertIndex, moved)
	local tagIds = {}
	for _, def in ipairs(definitions) do
		tagIds[#tagIds + 1] = def.id
	end
	local FriendTags = GetFriendTags()
	if FriendTags and FriendTags.SetTagOrder then
		FriendTags:SetTagOrder(tagIds, function()
			if C_Timer and C_Timer.After then
				C_Timer.After(0, function()
					self:RefreshAfterDefinitionChange("order")
				end)
			else
				self:RefreshAfterDefinitionChange("order")
			end
		end)
	end
end

local function BuildState(def, useDefaults)
	local FriendTags = GetFriendTags()
	local profile = (useDefaults and FriendTags:GetDefaultChipProfile(def) or FriendTags:GetChipProfile(def)) or {}
	local dbProfile = BetterFriendlistDB and BetterFriendlistDB.friendTagProfiles and BetterFriendlistDB.friendTagProfiles[def.id] or {}
	if useDefaults or type(dbProfile) ~= "table" then dbProfile = {} end
	local iconOptions = FriendTags:GetIconOptions()
	local selectedIcon = FindIconOptionByTexture(iconOptions, profile.iconValue or profile.atlas or profile.texture or profile.icon)

	local labelMode = "default"
	local labelValue = type(dbProfile.customChipLabel) == "string" and dbProfile.customChipLabel or ""
	if dbProfile.chipLabel ~= nil then
		if dbProfile.chipLabel == "" then
			labelMode = "icon_only"
		else
			labelMode = "custom"
			labelValue = tostring(dbProfile.chipLabel)
		end
	end

	local iconMode = ResolveStoredIconMode(profile, dbProfile, selectedIcon)
	local iconValue = profile.iconValue or profile.atlas or profile.texture or profile.icon or ""
	local iconOptionID = selectedIcon and selectedIcon.id or nil

	return {
		tagId = def.id,
		source = def.source,
		name = def.name or "",
		labelMode = labelMode,
		labelValue = labelValue,
		iconMode = iconMode,
		customIconPath = iconMode == "custom" and iconValue or "",
		iconOptionID = iconOptionID,
		iconType = profile.iconType or "texture",
		iconValue = iconValue,
		icon = profile.icon,
		atlas = profile.atlas,
		fallbackAtlas = profile.fallbackAtlas,
		texture = profile.texture,
		texCoord = CopyTexCoord(profile.texCoord),
		iconZoom = NormalizeIconZoom(profile.iconZoom),
		iconOnlyChip = profile.iconOnlyChip == true,
		color = CopyColor(profile.color),
		textColor = CopyColor(profile.textColor, { r = 1, g = 1, b = 1, a = 1 }),
		visible = profile.visible ~= false,
		rowVisible = profile.rowVisible ~= false,
		tooltipVisible = profile.tooltipVisible ~= false,
		brokerVisible = profile.brokerVisible ~= false,
	}
end

function FriendTagEditor:LoadState(def)
	self.savedState = BuildState(def)
	self.editState = self.drafts[def.id] or CopyTable(self.savedState)
end

function FriendTagEditor:GetSelectedDefinition()
	local FriendTags = GetFriendTags()
	return FriendTags and self.selectedTagId and FriendTags:GetTagDefinition(self.selectedTagId) or nil
end

function FriendTagEditor:RefreshEditor()
	local frame = self:EnsureFrame()
	local editorHost = frame.editorContent
	ClearChildren(editorHost)
	self.labelModeButtons, self.preview = nil, nil
	local content = CreateFrame("Frame", nil, editorHost)
	content:SetAllPoints(editorHost)
	self.dynamicEditorContent = content

	local def = self:GetSelectedDefinition()
	if not def then
		self.editState, self.savedState = nil, nil
		local empty = CreateFont(content, "BetterFriendlistFontHighlight")
		empty:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -4)
		empty:SetText(L("FRIEND_TAGS_NO_CUSTOM_TAGS", "No custom tags yet"))
		return
	end

	self:LoadState(def)
	local state = self.editState
	local y = -2

	local title = CreateFont(content, "BetterFriendlistFontNormalLarge")
	title:SetPoint("TOPLEFT", content, "TOPLEFT", 0, y)
	title:SetText(def.name or def.id)

	local source = CreateFont(content, "BetterFriendlistFontDisableSmall")
	source:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, y - 2)
	source:SetText(def.source == "blizzard" and L("FRIEND_TAGS_SOURCE_BLIZZARD", "Blizzard") or L("FRIEND_TAGS_SOURCE_CUSTOM", "Custom"))
	y = y - 28

	self:CreatePreview(content, y)
	y = y - 52

	if def.source == "custom" then
		self.nameInput = self:CreateLabeledInput(content, L("FRIEND_TAGS_EDITOR_NAME", "Tag Name"), state.name, y, 280, 32)
		self.nameInput:SetScript("OnTextChanged", function(_, userInput)
			if not userInput then return end
			state.name = GetEditBoxText(self.nameInput)
			self:RefreshPreview()
			self:MarkDraft()
		end)
		self:BindEditorInputFocusHandlers(self.nameInput)
		y = y - 36
	end

	self:CreateLabelControls(content, y)
	y = y - 64

	y = y - self:CreateIconControls(content, y)

	self:CreateColorControl(content, y, "color", L("FRIEND_TAGS_EDITOR_COLOR", "Chip Color"), "colorButton")
	y = y - 38

	self:CreateColorControl(content, y, "textColor", L("FRIEND_TAGS_EDITOR_TEXT_COLOR", "Chip Font Color"), "textColorButton")
	y = y - 38

	self:CreateVisibilityControls(content, y)
	self:CreateActionButtons(content)
end

function FriendTagEditor:CreateLabelControls(content, y)
	local state = self.editState
	local title = CreateFont(content, "BetterFriendlistFontHighlightSmall")
	title:SetPoint("TOPLEFT", content, "TOPLEFT", 0, y - 4)
	title:SetWidth(108)
	title:SetJustifyH("LEFT")
	title:SetText(L("FRIEND_TAGS_EDITOR_LABEL", "Chip Label"))
	local modes = {
		{ id = "default", label = L("FRIEND_TAGS_EDITOR_LABEL_DEFAULT", "Tag Name") },
		{ id = "custom", label = L("FRIEND_TAGS_EDITOR_LABEL_CUSTOM", "Custom Text") },
		{ id = "icon_only", label = L("FRIEND_TAGS_EDITOR_LABEL_ICON_ONLY", "Icon Only") },
	}
	self.labelModeButtons = {}
	local x = 118
	for _, mode in ipairs(modes) do
		local button = CreateFrame("CheckButton", nil, content, "UIRadioButtonTemplate")
		button:SetPoint("TOPLEFT", content, "TOPLEFT", x, y - 5)
		button.text:SetFontObject("BetterFriendlistFontHighlightSmall")
		button.text:SetText(mode.label)
		local textWidth = math.ceil(button.text:GetStringWidth())
		button:SetHitRectInsets(-3, -(textWidth + 8), -5, -5)
		button:SetScript("OnClick", function() self:SetLabelMode(mode.id) end)
		x = x + button:GetWidth() + 5 + textWidth + 20
		self.labelModeButtons[mode.id] = button
	end

	local input = CreateInput(content, 260, 32)
	input:SetPoint("TOPLEFT", content, "TOPLEFT", 118, y - 33)
	SetEditBoxText(input, state.labelValue)
	input:SetScript("OnTextChanged", function(editBox, userInput)
		if not userInput then return end
		state.labelValue = GetEditBoxText(editBox)
		self:RefreshPreview()
		self:MarkDraft()
	end)
	self:BindEditorInputFocusHandlers(input)
	self.labelInput = input

	local chipBackground = CreateFrame("Frame", nil, content)
	chipBackground:SetPoint("TOPLEFT", content, "TOPLEFT", 118, y - 32)
	chipBackground:SetSize(300, 26)
	local check = CreateCheckbox(chipBackground,
		L("FRIEND_TAGS_EDITOR_ICON_ONLY_CHIP", "Keep Chip Color"), state.iconOnlyChip, function(checked)
			state.iconOnlyChip = checked
			self:RefreshPreview()
			self:MarkDraft()
		end,
		L("FRIEND_TAGS_EDITOR_ICON_ONLY_CHIP", "Keep Chip Color"),
		L("FRIEND_TAGS_EDITOR_ICON_ONLY_CHIP_DESC", "Keep the colored chip background when this tag uses Icon Only."))
	check:SetPoint("LEFT", chipBackground, "LEFT", 0, 0)
	self.iconOnlyChipHolder = chipBackground
	self:UpdateLabelControls()
end

function FriendTagEditor:UpdateLabelControls()
	if not self.labelModeButtons then return end
	local mode = self.editState.labelMode
	for id, button in pairs(self.labelModeButtons) do
		local selected = id == mode
		button:SetChecked(selected)
		button.text:SetFontObject(selected and "BetterFriendlistFontNormalSmall" or "BetterFriendlistFontHighlightSmall")
	end
	self.labelInput:SetShown(mode == "custom")
	self.iconOnlyChipHolder:SetShown(mode == "icon_only")
end

function FriendTagEditor:SetLabelMode(mode)
	self.editState.labelMode = mode
	self:UpdateLabelControls()
	self:RefreshPreview()
	self:MarkDraft()
end

function FriendTagEditor:CreatePreview(parent, y)
	local preview = CreateFrame("Frame", nil, parent, "BackdropTemplate")
	preview:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y)
	preview:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, y)
	preview:SetHeight(40)
	BFL.SetOwnedBackdrop(preview, {
		bgFile = "Interface\\Buttons\\WHITE8X8",
		edgeFile = "Interface\\Buttons\\WHITE8X8",
		edgeSize = 1,
	})
	preview:SetBackdropColor(0.015, 0.015, 0.018, 0.76)
	preview:SetBackdropBorderColor(0.28, 0.28, 0.31, 0.62)
	local TagChips = GetTagChips()
	preview.chip = TagChips and TagChips.CreateStandaloneChip and TagChips:CreateStandaloneChip(preview)
	if preview.chip then
		preview.chip:SetPoint("LEFT", preview, "LEFT", 12, 0)
	end
	preview.empty = CreateFont(preview, "BetterFriendlistFontDisableSmall")
	preview.empty:SetPoint("LEFT", preview, "LEFT", 12, 0)
	preview.empty:SetPoint("RIGHT", preview, "RIGHT", -12, 0)
	preview.empty:SetJustifyH("LEFT")
	preview.empty:Hide()
	self.preview = preview
	self:RefreshPreview()
end

function FriendTagEditor:GetPreviewLabel()
	local def = self:GetSelectedDefinition()
	local state = self.editState or {}
	if state.labelMode == "icon_only" then
		return ""
	elseif state.labelMode == "custom" and state.labelValue and state.labelValue ~= "" then
		return state.labelValue
	end
	return (state.name and state.name ~= "" and state.name) or (def and def.name) or ""
end

function FriendTagEditor:GetPreviewIconProfile(state)
	state = state or self.editState or {}
	if state.iconMode == "none" then
		return nil
	elseif state.iconMode == "custom" then
		return CopyIconProfile({
			iconType = "texture",
			iconValue = state.customIconPath,
		})
	end
	if state.iconMode == "option" then
		local FriendTags = GetFriendTags()
		for _, option in ipairs(FriendTags and FriendTags:GetIconOptions() or {}) do
			if option.id == state.iconOptionID then
				return CopyIconProfile(option)
			end
		end
	end
	return CopyIconProfile(state)
end

function FriendTagEditor:GetPreviewIcon()
	local icon = self:GetPreviewIconProfile()
	return icon and (icon.iconValue or icon.texture or icon.icon) or nil
end

function FriendTagEditor:GetPreviewChipProfile()
	local state = self.editState or {}
	local profile = self:GetPreviewIconProfile() or { iconType = "none" }
	profile.color = CopyColor(state.color)
	profile.textColor = CopyColor(state.textColor, { r = 1, g = 1, b = 1, a = 1 })
	profile.iconOnlyChip = state.iconOnlyChip == true
	return profile
end

function FriendTagEditor:RefreshPreview()
	local preview = self.preview
	local state = self.editState
	if not (preview and state) then
		return
	end
	local label = self:GetPreviewLabel()
	local profile = self:GetPreviewChipProfile()
	local iconValue = profile.iconValue or profile.icon or profile.texture or profile.atlas
	local hasIcon = profile.iconType ~= "none" and iconValue ~= nil and iconValue ~= ""
	local shownInFriendList = state.visible ~= false and state.rowVisible ~= false
	local TagChips = GetTagChips()
	if shownInFriendList and preview.chip and TagChips and TagChips.UpdateStandaloneChip and (label ~= "" or hasIcon) then
		TagChips:UpdateStandaloneChip(preview.chip, profile, label, 180)
		preview.chip:SetAlpha(1)
		preview.empty:Hide()
	else
		if preview.chip then
			preview.chip:Hide()
		end
		preview.empty:SetText(shownInFriendList and state.labelMode == "icon_only" and not hasIcon
			and L("FRIEND_TAGS_EDITOR_ICON_REQUIRED", "Icon Only needs an icon. Choose one or switch to a text mode.")
			or L("FRIEND_TAGS_EDITOR_PREVIEW_HIDDEN", "This tag is hidden in the friends list."))
		preview.empty:Show()
	end
end

function FriendTagEditor:CreateLabeledInput(parent, label, value, y, width, maxLetters)
	local text = CreateFont(parent, "BetterFriendlistFontHighlightSmall")
	text:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y - 4)
	text:SetWidth(108)
	text:SetJustifyH("LEFT")
	text:SetText(label)

	local editBox = CreateInput(parent, width, maxLetters)
	editBox:SetPoint("TOPLEFT", parent, "TOPLEFT", 118, y)
	SetEditBoxText(editBox, value)
	return editBox
end

function FriendTagEditor:SetIconMode(mode)
	self.editState.iconMode = mode
	self:UpdateIconControls()
	self:RefreshPreview()
	self:MarkDraft()
end

function FriendTagEditor:OpenIconSelector(anchor)
	local state = self.editState
	if not BFL.ShowIconSelector then return end

	BFL.ShowIconSelector(anchor, self:GetPreviewIcon(), function(iconRef, iconProfile)
		if self.editState ~= state or self.iconSelectButton ~= anchor or not self.frame:IsShown() then return end
		local profile = CopyIconProfile(iconProfile or { iconType = "texture", iconValue = iconRef })
		state.iconOptionID = iconProfile and iconProfile.id or nil
		state.iconType, state.iconValue, state.icon = profile.iconType, profile.iconValue or iconRef, profile.icon or iconRef
		state.atlas, state.fallbackAtlas, state.texture = profile.atlas, profile.fallbackAtlas, profile.texture
		state.texCoord, state.iconZoom = profile.texCoord, profile.iconZoom
		self:SetIconMode("selected")
	end, { source = "tags", extraIcons = GetFriendTags():GetIconOptions(), anchorFrame = self.frame })
end

function FriendTagEditor:CreateIconControls(parent, y)
	local state = self.editState

	local label = CreateFont(parent, "BetterFriendlistFontHighlightSmall")
	label:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y - 4)
	label:SetWidth(108)
	label:SetJustifyH("LEFT")
	label:SetText(L("FRIEND_TAGS_EDITOR_ICON", "Chip Icon"))

	local previewHolder = CreateFrame("Frame", nil, parent, "BackdropTemplate")
	previewHolder:SetPoint("TOPLEFT", parent, "TOPLEFT", 118, y)
	previewHolder:SetSize(32, 32)
	BFL.SetOwnedBackdrop(previewHolder, {
		bgFile = "Interface\\Buttons\\WHITE8X8",
		edgeFile = "Interface\\Buttons\\WHITE8X8",
		edgeSize = 1,
	})
	previewHolder:SetBackdropColor(0.02, 0.02, 0.025, 0.82)
	previewHolder:SetBackdropBorderColor(0.28, 0.28, 0.31, 0.72)
	local TagChips = GetTagChips()
	previewHolder.chip = TagChips and TagChips.CreateStandaloneChip and TagChips:CreateStandaloneChip(previewHolder)
	if previewHolder.chip then
		previewHolder.chip:SetPoint("CENTER", previewHolder, "CENTER", 0, 0)
	end
	self.iconButtonPreview = previewHolder

	local selectButton = CreateSmallButton(parent, L("FRIEND_TAGS_EDITOR_ICON_CHOOSE", "Select Icon") .. "…", 96,
		function(button) self:OpenIconSelector(button) end)
	selectButton:SetPoint("LEFT", previewHolder, "RIGHT", 8, 0)
	selectButton:SetEnabled(BFL.ShowIconSelector ~= nil)
	self.iconSelectButton = selectButton

	local customPath = CreateTextAction(parent, L("FRIEND_TAGS_EDITOR_ICON_CUSTOM", "Custom Path"), function()
		self:SetIconMode("custom")
		self.iconInput:SetFocus()
	end)
	customPath:SetPoint("LEFT", selectButton, "RIGHT", 8, 0)
	self.iconRemoveButton = CreateTextAction(parent, L("FRIEND_TAGS_EDITOR_ICON_REMOVE", "Remove Icon"), function()
		self:SetIconMode("none")
	end)
	self.iconRemoveButton:SetPoint("LEFT", customPath, "RIGHT", 8, 0)

	self.iconInput = CreateInput(parent, 380, 180)
	self.iconInput:SetPoint("TOPLEFT", parent, "TOPLEFT", 118, y - 34)
	SetEditBoxText(self.iconInput, state.customIconPath)
	self.iconInput:SetScript("OnTextChanged", function(input, userInput)
		if not userInput or state.iconMode ~= "custom" then
			return
		end
		state.customIconPath = GetEditBoxText(input)
		self:UpdateIconControls()
		self:RefreshPreview()
		self:MarkDraft()
	end)
	self:BindEditorInputFocusHandlers(self.iconInput)

	self:UpdateIconControls()
	return 66
end

function FriendTagEditor:UpdateIconControls()
	local state = self.editState or {}
	if self.iconRemoveButton then self.iconRemoveButton:SetEnabled(state.iconMode ~= "none") end
	if self.iconButtonPreview then
		local profile = self:GetPreviewChipProfile()
		local iconValue = profile.iconValue or profile.icon or profile.texture or profile.atlas
		local TagChips = GetTagChips()
		if self.iconButtonPreview.chip and TagChips and TagChips.UpdateStandaloneChip and profile.iconType ~= "none" and iconValue and iconValue ~= "" then
			TagChips:UpdateStandaloneChip(self.iconButtonPreview.chip, profile, "", 28)
		else
			if self.iconButtonPreview.chip then
				self.iconButtonPreview.chip:Hide()
			end
		end
	end
	if self.iconInput then
		self.iconInput:SetShown(state.iconMode == "custom")
	end
end

function FriendTagEditor:CreateColorControl(parent, y, stateKey, labelText, buttonField)
	local state = self.editState
	stateKey = stateKey or "color"
	labelText = labelText or L("FRIEND_TAGS_EDITOR_COLOR", "Chip Color")
	buttonField = buttonField or "colorButton"
	local fallback = stateKey == "textColor" and { r = 1, g = 1, b = 1, a = 1 } or nil
	local label = CreateFont(parent, "BetterFriendlistFontHighlightSmall")
	label:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y - 4)
	label:SetWidth(108)
	label:SetText(labelText)

	local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
	button:SetPoint("TOPLEFT", parent, "TOPLEFT", 118, y)
	button:SetSize(28, 24)
	BFL.SetOwnedBackdrop(button, {
		bgFile = "Interface\\Buttons\\WHITE8X8",
		edgeFile = "Interface\\Buttons\\WHITE8X8",
		edgeSize = 1,
	})
	self[buttonField] = button

	local function UpdateSwatch()
		local color = CopyColor(state[stateKey], fallback)
		button:SetBackdropColor(color.r, color.g, color.b, color.a or 1)
		button:SetBackdropBorderColor(0, 0, 0, 1)
	end
	UpdateSwatch()

	button:SetScript("OnClick", function()
		local color = CopyColor(state[stateKey], fallback)
		if BFL.ShowColorPicker then
			local function ChangeColor(r, g, b, a)
				if self.editState ~= state or self[buttonField] ~= button or not self.frame:IsShown() then return end
				state[stateKey] = { r = r, g = g, b = b, a = a or 1 }
				UpdateSwatch()
				self:UpdateIconControls()
				self:RefreshPreview()
				self:MarkDraft()
			end
			BFL.ShowColorPicker(color.r, color.g, color.b, color.a or 1, ChangeColor, ChangeColor)
		end
	end)
end

function FriendTagEditor:CreateVisibilityControls(parent, y)
	local state = self.editState
	local sectionLabel = CreateFont(parent, "BetterFriendlistFontHighlightSmall")
	sectionLabel:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y - 4)
	sectionLabel:SetWidth(108)
	sectionLabel:SetJustifyH("LEFT")
	sectionLabel:SetText(L("FRIEND_TAGS_EDITOR_VISIBILITY", "Visibility"))
	local entries = {
		{
			key = "visible",
			text = L("FRIEND_TAGS_EDITOR_VISIBLE", "Show Tag"),
			desc = L("FRIEND_TAGS_EDITOR_VISIBLE_DESC", "Show or hide this tag everywhere. Your choices below are kept."),
		},
		{
			key = "rowVisible",
			text = L("FRIEND_TAGS_EDITOR_ROW_VISIBLE", "Friends List"),
			desc = L("FRIEND_TAGS_EDITOR_ROW_VISIBLE_DESC", "Show this tag next to friends in the list."),
		},
		{
			key = "tooltipVisible",
			text = L("FRIEND_TAGS_EDITOR_TOOLTIP_VISIBLE", "Tooltips"),
			desc = L("FRIEND_TAGS_EDITOR_TOOLTIP_VISIBLE_DESC", "Show this tag in friend tooltips."),
		},
		{
			key = "brokerVisible",
			text = L("SETTINGS_TAB_DATABROKER", "Data Broker"),
			desc = L("FRIEND_TAGS_EDITOR_BROKER_VISIBLE_DESC", "Show this tag in the Data Broker tooltip."),
		},
	}
	local surfaces = {}
	local function UpdateSurfaces()
		for _, surface in ipairs(surfaces) do
			surface.check:SetEnabled(state.visible)
			surface.text:SetAlpha(state.visible and 1 or 0.55)
		end
	end
	for index, entry in ipairs(entries) do
		local isMaster = index == 1
		local holder = CreateFrame("Frame", nil, parent)
		holder:SetPoint("TOPLEFT", parent, "TOPLEFT", isMaster and 118 or 138, y - (index - 1) * 24)
		holder:SetSize(245, 24)
		local check, text = CreateCheckbox(holder, entry.text, state[entry.key], function(checked)
			state[entry.key] = checked
			if isMaster then UpdateSurfaces() end
			self:RefreshPreview()
			self:MarkDraft()
		end, entry.text, entry.desc)
		check:SetPoint("LEFT", holder, "LEFT", 0, 0)
		if not isMaster then
			-- The templates provide a disabled checkmark but no disabled box.
			if not check:GetDisabledTexture() then
				local box = check:CreateTexture(nil, "BACKGROUND")
				box:SetAllPoints(check)
				BFL.SetTextureOrAtlas(box, not BFL.IsClassic and "checkbox-minimal" or nil,
					"Interface\\Buttons\\UI-CheckBox-Up", false)
				box:SetAlpha(0.75)
				check:SetDisabledTexture(box)
			end
			surfaces[#surfaces + 1] = { check = check, text = text }
		end
	end
	UpdateSurfaces()
end

function FriendTagEditor:CreateActionButtons(parent)
	local function CreateFooterButton(label, onClick)
		return CreateSmallButton(parent, label, 76, onClick, 18)
	end

	local reset = CreateFooterButton(L("FRIEND_TAGS_EDITOR_RESET", "Reset"), function()
		self:Reset()
	end)

	local close = CreateFooterButton(CLOSE or "Close", function()
		self:RequestClose()
	end)
	close:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 0)
	self.applyButton = CreateFooterButton(L("FRIEND_TAGS_EDITOR_APPLY", "Apply"), function() self:CommitState() end)
	self.applyButton:SetPoint("RIGHT", close, "LEFT", -8, 0)
	self.discardButton = CreateFooterButton(L("FRIEND_TAGS_EDITOR_DISCARD", "Discard"), function() self:DiscardDraft() end)
	self.discardButton:SetPoint("RIGHT", self.applyButton, "LEFT", -8, 0)
	self.draftStatus = CreateFont(parent, "BetterFriendlistFontHighlightSmall")
	self.draftStatus:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 0, 31)
	self.draftStatus:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 31)
	self.draftStatus:SetJustifyH("LEFT")

	local def = self:GetSelectedDefinition()
	if def and def.source == "custom" then
		local deleteButton = CreateFooterButton(L("FRIEND_TAGS_EDITOR_DELETE", "Delete Tag") .. "…", function()
			self:ConfirmDelete()
		end)
		deleteButton:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 0, 0)
		reset:SetPoint("LEFT", deleteButton, "RIGHT", 8, 0)
	else
		reset:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 0, 0)
	end
	self:UpdateDraftControls()
end

function FriendTagEditor:ConfirmDelete()
	local def = self:GetSelectedDefinition()
	local FriendTags = GetFriendTags()
	if not (def and def.source == "custom" and FriendTags) then
		return
	end

	local count = FriendTags:GetCustomTagAssignmentCount(def.id)
	local consequence
	if count == 0 then
		consequence = L("FRIEND_TAGS_EDITOR_DELETE_NO_ASSIGNMENTS", "This tag is not assigned to any friends.")
	elseif count == 1 then
		consequence = L("FRIEND_TAGS_EDITOR_DELETE_ONE_ASSIGNMENT", "This will remove the tag from one friend.")
	else
		consequence = L("FRIEND_TAGS_EDITOR_DELETE_MANY_ASSIGNMENTS", "This will remove the tag from %d friends."):format(count)
	end
	return StaticPopup_Show("BFL_FRIEND_TAG_EDITOR_DELETE_CUSTOM", def.name or def.id, consequence, { tagId = def.id })
end

local function SameState(left, right)
	if left == right then return true end
	if type(left) ~= "table" or type(right) ~= "table" then return false end
	for key, value in pairs(left) do
		if not SameState(value, right[key]) then return false end
	end
	for key in pairs(right) do
		if left[key] == nil then return false end
	end
	return true
end

function FriendTagEditor:UpdateDraftControls()
	local dirty = self.drafts[self.selectedTagId] ~= nil
	if self.applyButton then self.applyButton:SetEnabled(dirty) end
	if self.discardButton then self.discardButton:SetEnabled(dirty) end
	if self.draftStatus then
		self.draftStatus:SetText(dirty and L("FRIEND_TAGS_EDITOR_UNSAVED", "Unapplied changes") or "")
		self.draftStatus:SetTextColor(1, 0.76, 0.18)
	end
	for _, row in ipairs(self.frame and self.frame.tagRows or {}) do
		if row.tagId == self.selectedTagId then
			row.draftMarker:SetShown(dirty)
			break
		end
	end
end

function FriendTagEditor:MarkDraft()
	local state = self.editState
	if not state then return end
	self.drafts[state.tagId] = not SameState(state, self.savedState) and state or nil
	self:UpdateDraftControls()
end

function FriendTagEditor:DiscardDraft()
	self.drafts[self.selectedTagId] = nil
	self:Refresh()
end

function FriendTagEditor:ShowDraftError(text)
	if not self.draftStatus then return end
	self.draftStatus:SetText(text)
	self.draftStatus:SetTextColor(1, 0.32, 0.28)
end

local function BuildDraftPatch(self, def, state)
	if state.iconMode == "custom" and state.customIconPath == "" then
		return nil, L("FRIEND_TAGS_EDITOR_ICON_PATH_REQUIRED", "Enter an icon path or choose Remove Icon.")
	end
	local name = def.source == "custom" and state.name ~= def.name and state.name or nil
	local customLabel = state.labelMode == "custom" and state.labelValue ~= ""
	local chipLabel = state.labelMode == "icon_only" and "" or (customLabel and state.labelValue or false)

	local iconType, iconValue, icon, atlas, fallbackAtlas, texture, texCoord, iconZoom
	if state.iconMode == "none" then
		iconType = "none"
		iconValue = false
		icon = false
		atlas = false
		fallbackAtlas = false
		texture = false
		texCoord = false
		iconZoom = false
	else
		local iconProfile = self:GetPreviewIconProfile(state) or {}
		iconType = iconProfile.iconType or "texture"
		iconValue = iconProfile.iconValue or iconProfile.texture or iconProfile.icon
		icon = iconProfile.icon or iconProfile.texture or iconValue
		atlas = iconProfile.atlas
		fallbackAtlas = iconProfile.fallbackAtlas
		texture = iconProfile.texture
		texCoord = iconProfile.texCoord
		iconZoom = NormalizeIconZoom(iconProfile.iconZoom)
	end

	return {
		tagName = name,
		chipLabel = chipLabel,
		customChipLabel = not customLabel and state.labelValue or false,
		replaceIcon = true,
		iconMode = state.iconMode,
		iconType = iconType,
		iconValue = iconValue,
		icon = icon,
		atlas = atlas,
		fallbackAtlas = fallbackAtlas,
		texture = texture,
		texCoord = texCoord,
		iconZoom = iconZoom,
		iconOnlyChip = state.iconOnlyChip,
		color = state.color,
		textColor = state.textColor,
		visible = state.visible,
		rowVisible = state.rowVisible,
		tooltipVisible = state.tooltipVisible,
		brokerVisible = state.brokerVisible,
	}
end

local function GetDraftSaveError(reason)
	return reason == "reservedName" and L("FRIEND_TAGS_NAME_RESERVED_ERROR", "That name is already used by a built-in tag.")
		or reason == "exists" and L("FRIEND_TAGS_EDITOR_DUPLICATE_NAME", "A tag already uses this name.")
		or L("FRIEND_TAGS_EDITOR_INVALID_NAME", "Enter a tag name.")
end

function FriendTagEditor:CommitState()
	local FriendTags = GetFriendTags()
	local def = self:GetSelectedDefinition()
	local state = self.editState
	if not (FriendTags and def and state and self.drafts[def.id]) or state.tagId ~= def.id then
		return false
	end
	local patch, message = BuildDraftPatch(self, def, state)
	if not patch then
		self:ShowDraftError(message)
		return false
	end

	local saved, reason = FriendTags:SetChipProfile(def.id, patch, function()
		self.drafts[def.id] = nil
		self:RefreshAfterDefinitionChange("apply")
	end)
	if not saved then
		self:ShowDraftError(GetDraftSaveError(reason))
	end
	return saved == true
end

function FriendTagEditor:CommitAllDrafts()
	local FriendTags = GetFriendTags()
	if not FriendTags then return false end
	local patches = {}
	for tagId, state in pairs(self.drafts) do
		local def = FriendTags:GetTagDefinition(tagId)
		if def then
			local patch, message = BuildDraftPatch(self, def, state)
			if not patch then
				self.selectedTagId = tagId
				self:Refresh()
				self:ShowDraftError(message)
				return false
			end
			patches[tagId] = patch
		end
	end
	if not next(patches) then
		wipe(self.drafts)
		return true
	end

	local saved, reason, invalidTagId = FriendTags:SetChipProfiles(patches, function()
		wipe(self.drafts)
		self:RefreshAfterDefinitionChange("apply")
	end)
	if not saved then
		self.selectedTagId = invalidTagId
		self:Refresh()
		self:ShowDraftError(GetDraftSaveError(reason))
	end
	return saved == true
end

function FriendTagEditor:Reset()
	local def = self:GetSelectedDefinition()
	if def and self.editState then
		local defaults = BuildState(def, true)
		defaults.name = self.editState.name
		self.editState = defaults
		self:MarkDraft()
		self:RefreshEditor()
		if self.draftStatus and self.drafts[def.id] then
			self.draftStatus:SetText(L("FRIEND_TAGS_EDITOR_RESET_PREVIEW", "Defaults previewed. Apply to save."))
		end
	end
end

return FriendTagEditor
