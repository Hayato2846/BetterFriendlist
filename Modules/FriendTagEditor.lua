-- Shared Friend Tags & Chips editor for legacy settings and Settings Center.

local ADDON_NAME, BFL = ...

local FriendTagEditor = BFL:RegisterModule("FriendTagEditor", {})

local FRAME_NAME = "BetterFriendlistFriendTagEditorFrame"
local ROW_HEIGHT = 30
local SECTION_HEIGHT = 18
local LEFT_WIDTH = 232
local EDITOR_WIDTH = 760
local EDITOR_HEIGHT = 512

local dropdownCounter = 0

local function L(key, fallback)
	local locale = BFL and BFL.L
	return (locale and key and locale[key]) or fallback
end

local function GetFriendTags()
	return BFL and BFL:GetModule("FriendTags")
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
		editBox:SetText(text or "")
	end
end

local function CreateFont(parent, template)
	return parent:CreateFontString(nil, "OVERLAY", template or "BetterFriendlistFontHighlight")
end

local function CreateSmallButton(parent, text, width, onClick)
	local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	button:SetSize(width or 110, 24)
	button:SetText(text or "")
	button:SetScript("OnClick", function(self)
		if onClick then
			onClick(self)
		end
	end)
	return button
end

local function CreateCheckbox(parent, label, checked, onClick)
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
	}
end

local function ResetTexCoord(texture)
	if texture and texture.SetTexCoord then
		texture:SetTexCoord(0, 1, 0, 1)
	end
end

local function ApplyTexCoord(texture, texCoord)
	if texture and texture.SetTexCoord and type(texCoord) == "table" then
		texture:SetTexCoord(
			tonumber(texCoord[1]) or 0,
			tonumber(texCoord[2]) or 1,
			tonumber(texCoord[3]) or 0,
			tonumber(texCoord[4]) or 1
		)
	end
end

local function TrySetAtlas(texture, atlas)
	if not (texture and texture.SetAtlas and atlas and atlas ~= "") then
		return false
	end
	local width = texture.GetWidth and texture:GetWidth() or nil
	local height = texture.GetHeight and texture:GetHeight() or nil
	ResetTexCoord(texture)
	local ok = pcall(texture.SetAtlas, texture, atlas, false)
	if ok then
		if width and height and width > 0 and height > 0 and texture.SetSize then
			texture:SetSize(width, height)
		end
		texture:Show()
		return true
	end
	return false
end

local function ApplyIcon(texture, profile)
	if not texture then
		return false
	end
	profile = CopyIconProfile(profile)
	if not profile.iconValue or profile.iconValue == "" or profile.iconType == "none" then
		texture:Hide()
		return false
	end
	if profile.iconType == "atlas" then
		if TrySetAtlas(texture, profile.iconValue) or TrySetAtlas(texture, profile.atlas) or TrySetAtlas(texture, profile.fallbackAtlas) then
			return true
		end
	end
	local texturePath = profile.texture or profile.icon or (profile.iconType ~= "atlas" and profile.iconValue) or nil
	if not texturePath or texturePath == "" then
		texture:Hide()
		return false
	end
	ResetTexCoord(texture)
	texture:SetTexture(texturePath)
	ApplyTexCoord(texture, profile.texCoord)
	texture:Show()
	return true
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
			local tagId = FriendTags and FriendTags:CreateCustomTag(editBox and editBox:GetText(), function()
				FriendTagEditor:Refresh()
			end)
			if tagId then
				FriendTagEditor:Show(tagId)
			end
		end,
		EditBoxOnEnterPressed = function(editBox)
			local FriendTags = GetFriendTags()
			local tagId = FriendTags and FriendTags:CreateCustomTag(editBox:GetText(), function()
				FriendTagEditor:Refresh()
			end)
			if tagId then
				FriendTagEditor:Show(tagId)
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
		text = L("FRIEND_TAGS_EDITOR_DELETE_PROMPT", "Delete custom tag '%s'? Assignments for this tag will be removed."),
		button1 = DELETE or "Delete",
		button2 = CANCEL or "Cancel",
		OnAccept = function(_, data)
			local FriendTags = GetFriendTags()
			if FriendTags and data and data.tagId then
				FriendTags:DeleteCustomTag(data.tagId, function()
					FriendTagEditor.selectedTagId = nil
					FriendTagEditor:Refresh()
				end)
			end
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

	local frame = CreateFrame("Frame", FRAME_NAME, UIParent, "ButtonFrameTemplate")
	frame:SetSize(EDITOR_WIDTH, EDITOR_HEIGHT)
	frame:SetPoint("CENTER")
	frame:SetFrameStrata("DIALOG")
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
	frame:Hide()

	if frame.TitleText then
		frame.TitleText:SetText(L("FRIEND_TAGS_EDITOR_TITLE", "Friend Tags & Chips"))
	end

	frame.leftPane = CreateFrame("Frame", nil, frame, "BackdropTemplate")
	frame.leftPane:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -58)
	frame.leftPane:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 18, 44)
	frame.leftPane:SetWidth(LEFT_WIDTH)
	frame.leftPane:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8X8",
		edgeFile = "Interface\\Buttons\\WHITE8X8",
		edgeSize = 1,
	})
	frame.leftPane:SetBackdropColor(0.03, 0.03, 0.04, 0.55)
	frame.leftPane:SetBackdropBorderColor(0.36, 0.36, 0.40, 0.45)

	frame.rightPane = CreateFrame("Frame", nil, frame, "BackdropTemplate")
	frame.rightPane:SetPoint("TOPLEFT", frame.leftPane, "TOPRIGHT", 12, 0)
	frame.rightPane:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -18, 44)
	frame.rightPane:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8X8",
		edgeFile = "Interface\\Buttons\\WHITE8X8",
		edgeSize = 1,
	})
	frame.rightPane:SetBackdropColor(0.03, 0.03, 0.04, 0.40)
	frame.rightPane:SetBackdropBorderColor(0.36, 0.36, 0.40, 0.35)

	frame.listScroll = CreateFrame("ScrollFrame", nil, frame.leftPane, "UIPanelScrollFrameTemplate")
	frame.listScroll:SetPoint("TOPLEFT", frame.leftPane, "TOPLEFT", 4, -10)
	frame.listScroll:SetPoint("BOTTOMRIGHT", frame.leftPane, "BOTTOMRIGHT", -26, 42)
	frame.listContent = CreateFrame("Frame", nil, frame.listScroll)
	frame.listContent:SetSize(LEFT_WIDTH - 34, 1)
	frame.listScroll:SetScrollChild(frame.listContent)

	frame.editorContent = CreateFrame("Frame", nil, frame.rightPane)
	frame.editorContent:SetPoint("TOPLEFT", frame.rightPane, "TOPLEFT", 14, -14)
	frame.editorContent:SetPoint("BOTTOMRIGHT", frame.rightPane, "BOTTOMRIGHT", -14, 14)

	local createButton = CreateSmallButton(frame.leftPane, L("FRIEND_TAGS_CREATE_CUSTOM", "Create Custom Tag"), LEFT_WIDTH - 38, function()
		StaticPopup_Show("BFL_FRIEND_TAG_EDITOR_CREATE_CUSTOM")
	end)
	createButton:SetPoint("BOTTOMLEFT", frame.leftPane, "BOTTOMLEFT", 8, 10)
	frame.createButton = createButton

	self.frame = frame
	return frame
end

function FriendTagEditor:GetDefinitions()
	local FriendTags = GetFriendTags()
	return FriendTags and FriendTags:GetAllTagDefinitions() or {}
end

function FriendTagEditor:Show(tagId)
	local frame = self:EnsureFrame()
	self.selectedTagId = tagId or self.selectedTagId
	if not self.selectedTagId then
		local definitions = self:GetDefinitions()
		self.selectedTagId = definitions[1] and definitions[1].id or nil
	end
	self:Refresh()
	frame:Show()
end

function FriendTagEditor:Refresh()
	local frame = self:EnsureFrame()
	self:RefreshList()
	self:RefreshEditor()
end

function FriendTagEditor:RefreshList()
	local frame = self:EnsureFrame()
	ClearChildren(frame.listContent)

	local definitions = self:GetDefinitions()
	local sections = {
		{ source = "blizzard", title = L("FRIEND_TAGS_BLIZZARD_SECTION", "Blizzard Tags"), definitions = {} },
		{ source = "custom", title = L("FRIEND_TAGS_CUSTOM_SECTION", "Custom Tags"), definitions = {} },
	}
	for _, def in ipairs(definitions) do
		if def.source == "custom" then
			sections[2].definitions[#sections[2].definitions + 1] = def
		else
			sections[1].definitions[#sections[1].definitions + 1] = def
		end
	end

	local y = 0
	local FriendTags = GetFriendTags()

	local function AddSectionTitle(title)
		local header = CreateFont(frame.listContent, "BetterFriendlistFontDisableSmall")
		header:SetPoint("TOPLEFT", frame.listContent, "TOPLEFT", 6, y - 2)
		header:SetPoint("RIGHT", frame.listContent, "RIGHT", -4, 0)
		header:SetJustifyH("LEFT")
		header:SetText(title or "")
		y = y - SECTION_HEIGHT
	end

	local function AddEmptyText(text)
		local empty = CreateFont(frame.listContent, "BetterFriendlistFontDisableSmall")
		empty:SetPoint("TOPLEFT", frame.listContent, "TOPLEFT", 8, y - 2)
		empty:SetPoint("RIGHT", frame.listContent, "RIGHT", -8, 0)
		empty:SetJustifyH("LEFT")
		empty:SetText(text or "")
		y = y - (ROW_HEIGHT - 4)
	end

	local function AddRow(def)
		local row = CreateFrame("Button", nil, frame.listContent, "BackdropTemplate")
		row:SetPoint("TOPLEFT", frame.listContent, "TOPLEFT", 0, y)
		row:SetPoint("RIGHT", frame.listContent, "RIGHT", -2, 0)
		row:SetHeight(ROW_HEIGHT)
		row:SetBackdrop({
			bgFile = "Interface\\Buttons\\WHITE8X8",
			edgeFile = "Interface\\Buttons\\WHITE8X8",
			edgeSize = 1,
		})
		local selected = self.selectedTagId == def.id
		row:SetBackdropColor(selected and 0.15 or 0.05, selected and 0.13 or 0.05, selected and 0.09 or 0.06, selected and 0.86 or 0.42)
		row:SetBackdropBorderColor(selected and 0.95 or 0.22, selected and 0.72 or 0.22, selected and 0.30 or 0.24, selected and 0.82 or 0.48)

		local profile = FriendTags and FriendTags:GetChipProfile(def)
		local icon = row:CreateTexture(nil, "ARTWORK")
		icon:SetSize(16, 16)
		icon:SetPoint("LEFT", row, "LEFT", 7, 0)
		if not ApplyIcon(icon, profile) then
			icon:Hide()
		end

		local text = CreateFont(row, "BetterFriendlistFontHighlightSmall")
		text:SetPoint("LEFT", icon, "RIGHT", 6, 0)
		text:SetPoint("RIGHT", row, "RIGHT", -8, 0)
		text:SetJustifyH("LEFT")
		text:SetText(def.name or def.id)

		row:SetScript("OnClick", function()
			self.selectedTagId = def.id
			self:Refresh()
		end)

		y = y - (ROW_HEIGHT + 4)
	end

	for _, section in ipairs(sections) do
		if #section.definitions > 0 or section.source == "custom" then
			AddSectionTitle(section.title)
			if #section.definitions == 0 then
				AddEmptyText(L("FRIEND_TAGS_NO_CUSTOM_TAGS", "No custom tags yet"))
			else
				for _, def in ipairs(section.definitions) do
					AddRow(def)
				end
			end
			y = y - 4
		end
	end

	frame.listContent:SetHeight(math.max(1, math.abs(y) + 4))
end

function FriendTagEditor:LoadState(def)
	local FriendTags = GetFriendTags()
	local profile = FriendTags and FriendTags:GetChipProfile(def) or {}
	local dbProfile = BetterFriendlistDB and BetterFriendlistDB.friendTagProfiles and BetterFriendlistDB.friendTagProfiles[def.id] or {}
	local iconOptions = FriendTags and FriendTags:GetIconOptions() or {}
	local selectedIcon = FindIconOptionByTexture(iconOptions, profile.iconValue or profile.atlas or profile.texture or profile.icon)

	local labelMode = "default"
	local labelValue = def.name or ""
	if type(dbProfile) == "table" and dbProfile.chipLabel ~= nil then
		if dbProfile.chipLabel == "" then
			labelMode = "icon_only"
			labelValue = ""
		else
			labelMode = "custom"
			labelValue = dbProfile.chipLabel
		end
	end

	local iconMode = "option"
	local iconValue = profile.iconValue or profile.atlas or profile.texture or profile.icon or ""
	local iconOptionID = selectedIcon and selectedIcon.id or "tag"
	if not iconValue or iconValue == "" or profile.iconType == "none" then
		iconMode = "none"
	elseif not selectedIcon then
		iconMode = "custom"
	end

	self.editState = {
		tagId = def.id,
		source = def.source,
		name = def.name or "",
		labelMode = labelMode,
		labelValue = labelValue,
		iconMode = iconMode,
		iconOptionID = iconOptionID,
		iconType = profile.iconType or "texture",
		iconValue = iconValue,
		icon = profile.icon,
		atlas = profile.atlas,
		fallbackAtlas = profile.fallbackAtlas,
		texture = profile.texture,
		texCoord = CopyTexCoord(profile.texCoord),
		color = CopyColor(profile.color),
		visible = profile.visible ~= false,
		rowVisible = profile.rowVisible ~= false,
		tooltipVisible = profile.tooltipVisible ~= false,
		brokerVisible = profile.brokerVisible ~= false,
		order = tonumber(profile.order) or tonumber(def.order) or 0,
	}
end

function FriendTagEditor:GetSelectedDefinition()
	local FriendTags = GetFriendTags()
	return FriendTags and self.selectedTagId and FriendTags:GetTagDefinition(self.selectedTagId) or nil
end

function FriendTagEditor:RefreshEditor()
	local frame = self:EnsureFrame()
	local content = frame.editorContent
	ClearChildren(content)

	local def = self:GetSelectedDefinition()
	if not def then
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
	y = y - 34

	self:CreatePreview(content, y)
	y = y - 54

	if def.source == "custom" then
		self.nameInput = self:CreateLabeledInput(content, L("FRIEND_TAGS_EDITOR_NAME", "Tag Name"), state.name, y, 220, 32)
		y = y - 34
	end

	self.labelInput = self:CreateLabeledInput(content, L("FRIEND_TAGS_EDITOR_LABEL", "Chip Label"), state.labelValue, y, 220, 32)
	self.labelInput:SetScript("OnTextChanged", function()
		state.labelValue = GetEditBoxText(self.labelInput)
		if state.labelMode ~= "icon_only" then
			state.labelMode = state.labelValue == "" and "default" or "custom"
		end
		self:RefreshPreview()
	end)

	local defaultButton = CreateSmallButton(content, L("FRIEND_TAGS_EDITOR_LABEL_DEFAULT", "Default"), 78, function()
		state.labelMode = "default"
		state.labelValue = def.name or ""
		SetEditBoxText(self.labelInput, state.labelValue)
		self:RefreshPreview()
	end)
	defaultButton:SetPoint("TOPLEFT", content, "TOPLEFT", 284, y + 2)

	local iconOnlyButton = CreateSmallButton(content, L("FRIEND_TAGS_EDITOR_LABEL_ICON_ONLY", "Icon Only"), 92, function()
		state.labelMode = "icon_only"
		state.labelValue = ""
		SetEditBoxText(self.labelInput, "")
		self:RefreshPreview()
	end)
	iconOnlyButton:SetPoint("LEFT", defaultButton, "RIGHT", 8, 0)
	y = y - 38

	self:CreateIconControls(content, y)
	y = y - 38

	self:CreateColorControl(content, y)
	y = y - 42

	self:CreateVisibilityControls(content, y)
	y = y - 94

	self.orderInput = self:CreateLabeledInput(content, L("FRIEND_TAGS_EDITOR_ORDER", "Order"), tostring(state.order), y, 80, 6)
	self.orderInput:SetNumeric(true)
	y = y - 40

	self:CreateActionButtons(content)
end

function FriendTagEditor:CreatePreview(parent, y)
	local preview = CreateFrame("Frame", nil, parent, "BackdropTemplate")
	preview:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y)
	preview:SetSize(242, 32)
	preview:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8X8",
		edgeFile = "Interface\\Buttons\\WHITE8X8",
		edgeSize = 1,
	})
	preview.icon = preview:CreateTexture(nil, "ARTWORK")
	preview.icon:SetSize(14, 14)
	preview.icon:SetPoint("LEFT", preview, "LEFT", 8, 0)
	preview.label = CreateFont(preview, "BetterFriendlistFontHighlightSmall")
	preview.label:SetPoint("LEFT", preview.icon, "RIGHT", 4, 0)
	preview.label:SetPoint("RIGHT", preview, "RIGHT", -8, 0)
	self.preview = preview
	self:RefreshPreview()
end

function FriendTagEditor:GetPreviewLabel()
	local def = self:GetSelectedDefinition()
	local state = self.editState or {}
	if state.labelMode == "icon_only" then
		return ""
	elseif state.labelMode == "custom" then
		return state.labelValue or ""
	end
	return def and def.name or ""
end

function FriendTagEditor:GetPreviewIconProfile()
	local state = self.editState or {}
	if state.iconMode == "none" then
		return nil
	elseif state.iconMode == "custom" then
		return CopyIconProfile({
			iconType = "texture",
			iconValue = state.iconValue,
			icon = state.iconValue,
			texture = state.iconValue,
		})
	end
	local FriendTags = GetFriendTags()
	for _, option in ipairs(FriendTags and FriendTags:GetIconOptions() or {}) do
		if option.id == state.iconOptionID then
			return CopyIconProfile(option)
		end
	end
	return CopyIconProfile(state)
end

function FriendTagEditor:GetPreviewIcon()
	local icon = self:GetPreviewIconProfile()
	return icon and (icon.iconValue or icon.texture or icon.icon) or nil
end

function FriendTagEditor:RefreshPreview()
	local preview = self.preview
	local state = self.editState
	if not (preview and state) then
		return
	end
	local color = CopyColor(state.color)
	preview:SetBackdropColor(color.r * 0.16, color.g * 0.16, color.b * 0.16, 0.88)
	preview:SetBackdropBorderColor(color.r, color.g, color.b, 0.78)

	local icon = self:GetPreviewIconProfile()
	local hasIcon = icon and ApplyIcon(preview.icon, icon) or false
	if not hasIcon then
		preview.icon:Hide()
	end

	local label = self:GetPreviewLabel()
	if label == "" and not hasIcon then
		label = L("FRIEND_TAGS_EDITOR_PREVIEW_HIDDEN", "Hidden until an icon or label is set")
	end
	preview.label:SetText(label)
	preview.label:SetTextColor(1, 1, 1, 1)
end

function FriendTagEditor:CreateLabeledInput(parent, label, value, y, width, maxLetters)
	local text = CreateFont(parent, "BetterFriendlistFontHighlightSmall")
	text:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y - 4)
	text:SetWidth(118)
	text:SetJustifyH("LEFT")
	text:SetText(label)

	local editBox = CreateInput(parent, width, maxLetters)
	editBox:SetPoint("TOPLEFT", parent, "TOPLEFT", 128, y)
	SetEditBoxText(editBox, value)
	return editBox
end

function FriendTagEditor:CreateIconControls(parent, y)
	local state = self.editState
	local FriendTags = GetFriendTags()
	local options = FriendTags and FriendTags:GetIconOptions() or {}

	local label = CreateFont(parent, "BetterFriendlistFontHighlightSmall")
	label:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y - 4)
	label:SetWidth(118)
	label:SetText(L("FRIEND_TAGS_EDITOR_ICON", "Chip Icon"))

	dropdownCounter = dropdownCounter + 1
	local dropdownName = "BFLFriendTagIconDropdown" .. tostring(dropdownCounter)
	local dropdown = CreateFrame("Frame", dropdownName, parent, "UIDropDownMenuTemplate")
	dropdown:SetPoint("TOPLEFT", parent, "TOPLEFT", 120, y + 2)
	UIDropDownMenu_SetWidth(dropdown, 150)
	UIDropDownMenu_JustifyText(dropdown, "LEFT")
	self.iconDropdown = dropdown

	local function SetDropdownText()
		if state.iconMode == "none" then
			UIDropDownMenu_SetText(dropdown, NONE or "None")
		elseif state.iconMode == "custom" then
			UIDropDownMenu_SetText(dropdown, L("FRIEND_TAGS_EDITOR_ICON_CUSTOM", "Custom Path"))
		else
			for _, option in ipairs(options) do
				if option.id == state.iconOptionID then
					UIDropDownMenu_SetText(dropdown, option.label)
					return
				end
			end
			UIDropDownMenu_SetText(dropdown, L("FRIEND_TAGS_ICON_TAG", "Tag"))
		end
	end

	local function UpdateCustomInput()
		if self.iconInput then
			self.iconInput:SetShown(state.iconMode == "custom")
		end
	end

	local function ApplyOption(option)
		local icon = CopyIconProfile(option)
		state.iconMode = "option"
		state.iconOptionID = option.id
		state.iconType = icon.iconType
		state.iconValue = icon.iconValue
		state.icon = icon.icon
		state.atlas = icon.atlas
		state.fallbackAtlas = icon.fallbackAtlas
		state.texture = icon.texture
		state.texCoord = CopyTexCoord(icon.texCoord)
		SetEditBoxText(self.iconInput, icon.texture or icon.icon or icon.iconValue or "")
	end

	UIDropDownMenu_Initialize(dropdown, function(_, level)
		level = level or 1
		local noneInfo = UIDropDownMenu_CreateInfo()
		noneInfo.text = NONE or "None"
		noneInfo.checked = state.iconMode == "none"
		noneInfo.func = function()
			state.iconMode = "none"
			state.iconType = "none"
			state.iconValue = ""
			state.icon = nil
			state.atlas = nil
			state.fallbackAtlas = nil
			state.texture = nil
			state.texCoord = nil
			SetDropdownText()
			UpdateCustomInput()
			self:RefreshPreview()
			CloseDropDownMenus()
		end
		UIDropDownMenu_AddButton(noneInfo, level)

		for _, option in ipairs(options) do
			local info = UIDropDownMenu_CreateInfo()
			info.text = option.label
			info.checked = state.iconMode == "option" and state.iconOptionID == option.id
			info.func = function()
				ApplyOption(option)
				SetDropdownText()
				UpdateCustomInput()
				self:RefreshPreview()
				CloseDropDownMenus()
			end
			UIDropDownMenu_AddButton(info, level)
		end

		local customInfo = UIDropDownMenu_CreateInfo()
		customInfo.text = L("FRIEND_TAGS_EDITOR_ICON_CUSTOM", "Custom Path")
		customInfo.checked = state.iconMode == "custom"
		customInfo.func = function()
			state.iconMode = "custom"
			state.iconType = "texture"
			state.iconValue = GetEditBoxText(self.iconInput)
			state.icon = state.iconValue
			state.atlas = nil
			state.fallbackAtlas = nil
			state.texture = state.iconValue
			state.texCoord = nil
			SetDropdownText()
			UpdateCustomInput()
			self:RefreshPreview()
			CloseDropDownMenus()
		end
		UIDropDownMenu_AddButton(customInfo, level)
	end)
	SetDropdownText()

	self.iconInput = CreateInput(parent, 148, 180)
	self.iconInput:SetPoint("TOPLEFT", parent, "TOPLEFT", 306, y)
	SetEditBoxText(self.iconInput, state.texture or state.icon or state.iconValue)
	self.iconInput:SetScript("OnTextChanged", function()
		if state.iconMode == "custom" then
			state.iconValue = GetEditBoxText(self.iconInput)
			state.icon = state.iconValue
			state.texture = state.iconValue
			self:RefreshPreview()
		end
	end)
	UpdateCustomInput()
end

function FriendTagEditor:CreateColorControl(parent, y)
	local state = self.editState
	local label = CreateFont(parent, "BetterFriendlistFontHighlightSmall")
	label:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y - 4)
	label:SetWidth(118)
	label:SetText(L("FRIEND_TAGS_EDITOR_COLOR", "Chip Color"))

	local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
	button:SetPoint("TOPLEFT", parent, "TOPLEFT", 128, y)
	button:SetSize(28, 24)
	button:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8X8",
		edgeFile = "Interface\\Buttons\\WHITE8X8",
		edgeSize = 1,
	})
	self.colorButton = button

	local function UpdateSwatch()
		local color = CopyColor(state.color)
		button:SetBackdropColor(color.r, color.g, color.b, color.a or 1)
		button:SetBackdropBorderColor(0, 0, 0, 1)
	end
	UpdateSwatch()

	button:SetScript("OnClick", function()
		local color = CopyColor(state.color)
		if BFL.ShowColorPicker then
			BFL.ShowColorPicker(color.r, color.g, color.b, color.a or 1, function(r, g, b, a)
				state.color = { r = r, g = g, b = b, a = a or 1 }
				UpdateSwatch()
				self:RefreshPreview()
			end, function(r, g, b, a)
				state.color = { r = r, g = g, b = b, a = a or 1 }
				UpdateSwatch()
				self:RefreshPreview()
			end)
		end
	end)
end

function FriendTagEditor:CreateVisibilityControls(parent, y)
	local state = self.editState
	local labels = {
		{ key = "visible", text = L("FRIEND_TAGS_EDITOR_VISIBLE", "Visible") },
		{ key = "rowVisible", text = L("FRIEND_TAGS_EDITOR_ROW_VISIBLE", "Friend Rows") },
		{ key = "tooltipVisible", text = L("FRIEND_TAGS_EDITOR_TOOLTIP_VISIBLE", "Tooltips") },
		{ key = "brokerVisible", text = L("FRIEND_TAGS_EDITOR_BROKER_VISIBLE", "Broker") },
	}
	for index, entry in ipairs(labels) do
		local holder = CreateFrame("Frame", nil, parent)
		holder:SetPoint("TOPLEFT", parent, "TOPLEFT", index <= 2 and 0 or 230, y - (((index - 1) % 2) * 30))
		holder:SetSize(220, 26)
		local check = CreateCheckbox(holder, entry.text, state[entry.key], function(checked)
			state[entry.key] = checked
		end)
		check:SetPoint("LEFT", holder, "LEFT", 0, 0)
	end
end

function FriendTagEditor:CreateActionButtons(parent)
	local save = CreateSmallButton(parent, SAVE or "Save", 90, function()
		self:Save()
	end)
	save:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -190, 0)

	local reset = CreateSmallButton(parent, RESET or "Reset", 90, function()
		self:Reset()
	end)
	reset:SetPoint("LEFT", save, "RIGHT", 8, 0)

	local close = CreateSmallButton(parent, CLOSE or "Close", 90, function()
		self.frame:Hide()
	end)
	close:SetPoint("LEFT", reset, "RIGHT", 8, 0)

	local def = self:GetSelectedDefinition()
	if def and def.source == "custom" then
		local deleteButton = CreateSmallButton(parent, DELETE or "Delete", 90, function()
			StaticPopup_Show("BFL_FRIEND_TAG_EDITOR_DELETE_CUSTOM", def.name or def.id, nil, { tagId = def.id })
		end)
		deleteButton:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 0, 0)
	end
end

function FriendTagEditor:Save()
	local FriendTags = GetFriendTags()
	local def = self:GetSelectedDefinition()
	local state = self.editState
	if not (FriendTags and def and state) then
		return
	end

	if def.source == "custom" and self.nameInput then
		local name = GetEditBoxText(self.nameInput)
		if name ~= "" and name ~= def.name then
			FriendTags:RenameCustomTag(def.id, name)
		end
	end

	local clearFields = {}
	local chipLabel
	if state.labelMode == "default" then
		clearFields.chipLabel = true
	elseif state.labelMode == "icon_only" then
		chipLabel = ""
	else
		chipLabel = GetEditBoxText(self.labelInput)
	end

	local iconType, iconValue, icon, atlas, fallbackAtlas, texture, texCoord
	if state.iconMode == "none" then
		iconType = "none"
		iconValue = false
		icon = false
		atlas = false
		fallbackAtlas = false
		texture = false
		texCoord = false
	elseif state.iconMode == "custom" then
		iconType = "texture"
		iconValue = GetEditBoxText(self.iconInput)
		icon = iconValue
		texture = iconValue
	else
		local iconProfile = self:GetPreviewIconProfile() or {}
		iconType = iconProfile.iconType or "texture"
		iconValue = iconProfile.iconValue or iconProfile.texture or iconProfile.icon
		icon = iconProfile.icon or iconProfile.texture or iconValue
		atlas = iconProfile.atlas
		fallbackAtlas = iconProfile.fallbackAtlas
		texture = iconProfile.texture
		texCoord = iconProfile.texCoord
	end

	FriendTags:SetChipProfile(def.id, {
		chipLabel = chipLabel,
		clearFields = clearFields,
		iconType = iconType,
		iconValue = iconValue,
		icon = icon,
		atlas = atlas,
		fallbackAtlas = fallbackAtlas,
		texture = texture,
		texCoord = texCoord,
		color = state.color,
		visible = state.visible,
		rowVisible = state.rowVisible,
		tooltipVisible = state.tooltipVisible,
		brokerVisible = state.brokerVisible,
		order = tonumber(GetEditBoxText(self.orderInput)) or state.order,
	}, function()
		self:Refresh()
	end)
	self:Refresh()
end

function FriendTagEditor:Reset()
	local FriendTags = GetFriendTags()
	local def = self:GetSelectedDefinition()
	if FriendTags and def then
		FriendTags:ResetChipProfile(def.id, function()
			self:Refresh()
		end)
		self:Refresh()
	end
end

return FriendTagEditor
