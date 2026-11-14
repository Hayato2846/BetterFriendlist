-- Shared Friend Tags & Chips editor for legacy settings and Settings Center.

local ADDON_NAME, BFL = ...

local FriendTagEditor = BFL:RegisterModule("FriendTagEditor", { drafts = {} })

local FRAME_NAME = "BetterFriendlistFriendTagEditorFrame"
local ROW_HEIGHT = 32
local SECTION_HEADER_HEIGHT = 26
local LEFT_WIDTH = 244
local EDITOR_WIDTH = 1060
local EDITOR_HEIGHT = 654
local BACKDROP = {
	bgFile = "Interface\\Buttons\\WHITE8X8",
	edgeFile = "Interface\\Buttons\\WHITE8X8",
	edgeSize = 1,
}

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
	local components = BFL.SettingsComponents
	local template = components and components:GetActionButtonTemplate(BFL.IsClassic and "UIPanelButtonTemplate" or "SharedButtonTemplate")
		or (BFL.IsClassic and "UIPanelButtonTemplate" or "SharedButtonTemplate")
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

local function SetActionIcon(button, icon)
	local path = "Interface\\AddOns\\BetterFriendlist\\Icons\\" .. icon .. ".blp"
	button:SetIcon(path)
	button:GetHighlightTexture():SetTexture(path)
end

local function CreateIconAction(parent, icon, label, action)
	local button = CreateFrame("Button", nil, parent, "CommonSquareIconButtonTemplate")
	button.BFL_SettingsIconButton = true
	button:SetHitRectInsets(0, 0, 0, 0)
	button:SetSize(24, 24)
	button:SetHighlightTexture("Interface\\Buttons\\WHITE8X8", "ADD")
	SetActionIcon(button, icon)
	button.Icon:SetSize(14, 14)
	button.Icon:SetVertexColor(1, 0.82, 0)
	local highlight = button:GetHighlightTexture()
	highlight:ClearAllPoints()
	highlight:SetAllPoints(button.Icon)
	highlight:SetAlpha(0.25)
	button.actionLabel = label
	button:SetScript("OnMouseDown", IconButtonMixin.OnMouseDown)
	button:SetScript("OnMouseUp", IconButtonMixin.OnMouseUp)
	button:SetScript("OnClick", action)
	button:HookScript("OnEnter", function(owner)
		if type(owner.actionLabel) ~= "string" or owner.actionLabel == "" then BFL_Tooltip:Hide(); return end
		BFL_Tooltip:SetOwner(owner, "ANCHOR_RIGHT")
		BFL_Tooltip:SetText(owner.actionLabel)
		BFL_Tooltip:Show()
	end)
	button:HookScript("OnLeave", function() BFL_Tooltip:Hide() end)
	return button
end

local function DeleteTagLabel(def)
	return def.source == "custom" and L("FRIEND_TAGS_EDITOR_DELETE", "Delete Tag")
		or L("FRIEND_TAGS_EDITOR_REMOVE_BLIZZARD", "Remove Tag")
end

function FriendTagEditor:CreateTagActions(parent, getTagId)
	local remove = CreateIconAction(parent, "trash-2", nil, function()
		self:ConfirmDelete(getTagId())
	end)
	local reset = CreateIconAction(parent, "rotate-ccw", L("FRIEND_TAGS_EDITOR_RESET", "Reset"), function()
		local tagId = getTagId()
		if not tagId then return end
		if self.selectedTagId ~= tagId then self:Show(tagId) end
		self:Reset()
	end)
	reset:SetPoint("RIGHT", remove, "LEFT")
	return reset, remove
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
		iconColor = source.iconColor,
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
	local function DeleteTag(_, data)
		local tags = GetFriendTags()
		if not (tags and data and data.tagId) then return end
		FriendTagEditor:CancelColorEdit()
		local function Refresh()
			FriendTagEditor:RefreshAfterDefinitionChange("delete")
		end
		if data.blizzard then
			tags:SetBlizzardTagRemoved(data.tagId, true, Refresh)
		else
			tags:DeleteCustomTag(data.tagId, Refresh)
		end
	end

	local function SaveSection(editBox)
		local tags = GetFriendTags()
		if not (tags and editBox) then return end
		local id, reason = tags:CreateTagSection(editBox:GetText(), function()
			FriendTagEditor:Refresh()
		end)
		if id then
			for _, row in ipairs(FriendTagEditor.frame.sectionRows or {}) do
				if row.section.id == id then
					FriendTagEditor:ScrollRowIntoView(row)
					break
				end
			end
			return
		end
		if UIErrorsFrame and UIErrorsFrame.AddMessage then
			local text = reason == "exists"
				and L("FRIEND_TAGS_EDITOR_SECTION_EXISTS", "A section already uses this name.")
				or L("FRIEND_TAGS_EDITOR_SECTION_PROMPT", "Enter a name for the new section.")
			UIErrorsFrame:AddMessage(text, 1, 0.2, 0.2, 1)
		end
		return true
	end

	StaticPopupDialogs["BFL_FRIEND_TAG_EDITOR_CREATE_SECTION"] = {
		text = L("FRIEND_TAGS_EDITOR_SECTION_PROMPT", "Enter a name for the new section."),
		button1 = ACCEPT or "Accept",
		button2 = CANCEL or "Cancel",
		hasEditBox = true,
		editBoxWidth = 220,
		OnShow = function(dialog)
			local editBox = GetPopupEditBox(dialog)
			if editBox then
				editBox:SetNumeric(false)
				editBox:SetText("")
				editBox:SetMaxLetters(32)
				editBox:SetFocus()
			end
		end,
		OnHide = function(dialog)
			local editBox = GetPopupEditBox(dialog)
			if editBox then editBox:SetMaxLetters(0) end
		end,
		OnAccept = function(dialog) return SaveSection(GetPopupEditBox(dialog)) end,
		EditBoxOnEnterPressed = function(editBox)
			if not SaveSection(editBox) then editBox:GetParent():Hide() end
		end,
		EditBoxOnEscapePressed = function(editBox) editBox:GetParent():Hide() end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = 3,
	}

	StaticPopupDialogs["BFL_FRIEND_TAG_EDITOR_DELETE_SECTION"] = {
		text = L("FRIEND_TAGS_EDITOR_SECTION_DELETE_PROMPT", "Delete section '%s'? If you keep the tags, they move to No Section. Deleting the tags removes custom tags permanently. Built-in tags can be restored."),
		button1 = L("FRIEND_TAGS_EDITOR_SECTION_KEEP_TAGS", "Keep Tags"),
		button2 = CANCEL or "Cancel",
		button3 = L("FRIEND_TAGS_EDITOR_SECTION_DELETE_TAGS", "Delete Tags"),
		OnAccept = function(_, id) FriendTagEditor:DeleteSection(id, false) end,
		OnAlt = function(_, id) FriendTagEditor:DeleteSection(id, true) end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = 3,
	}

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
				editBox:SetNumeric(false)
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
				return true
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
		OnAccept = DeleteTag,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = 3,
	}

	StaticPopupDialogs["BFL_FRIEND_TAG_EDITOR_REMOVE_BLIZZARD"] = {
		text = L("FRIEND_TAGS_EDITOR_REMOVE_BLIZZARD_PROMPT", "Remove '%s' from BetterFriendlist? Its assignments are kept, and you can restore it later."),
		button1 = L("FRIEND_TAGS_EDITOR_REMOVE_BLIZZARD", "Remove Tag"),
		button2 = CANCEL or "Cancel",
		OnAccept = DeleteTag,
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

local function CreateScroll(parent, top, bottom)
	local settings = BFL:GetModule("Settings")
	local scroll = settings and settings:CreateSettingsScrollFrame(parent)
		or CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
	scroll:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, top)
	scroll:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -25, bottom)
	local content = CreateFrame("Frame", nil, scroll)
	content:SetSize(1, 1)
	scroll:SetScrollChild(content)
	scroll:HookScript("OnSizeChanged", function(_, width) content:SetWidth(math.max(1, width)) end)
	return scroll, content
end

function FriendTagEditor:EnsureFrame()
	if self.frame then return self.frame end

	local frame = CreateFrame("Frame", FRAME_NAME, UIParent, "ButtonFrameTemplate")
	self.frame = frame
	self.collapsed = {}
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
	frame:HookScript("OnHide", function()
		self:CancelColorEdit()
		self:CancelDrag()
	end)
	frame:Hide()

	if ButtonFrameTemplate_HidePortrait then ButtonFrameTemplate_HidePortrait(frame) end
	if ButtonFrameTemplate_HideAttic then ButtonFrameTemplate_HideAttic(frame) end
	if frame.PortraitContainer then frame.PortraitContainer:Hide() end
	if frame.Inset then frame.Inset:Hide() end
	frame.title = frame.TitleContainer and frame.TitleContainer.TitleText or frame.TitleText
	if not frame.title then
		frame.title = CreateFont(frame)
		frame.title:SetPoint("TOP", frame, "TOP", 0, -8)
	end
	frame.title:SetText(L("FRIEND_TAGS_EDITOR_TITLE", "Friend Tags & Chips"))

	local style = BFL:GetModule("LegacySettingsStyle")
	frame.CategoryList = CreateFrame("Frame", nil, frame)
	frame.leftPane = frame.CategoryList
	frame.leftPane:SetPoint("TOPLEFT", 12, -33)
	frame.leftPane:SetPoint("BOTTOMLEFT", 12, 12)
	frame.MainInset = CreateFrame("Frame", nil, frame, "BackdropTemplate")
	frame.rightPane = frame.MainInset
	frame.rightPane:SetBackdrop({
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 16, edgeSize = 6,
		insets = { left = 1, right = 1, top = 1, bottom = 1 },
	})
	frame.previewPane = CreateFrame("Frame", nil, frame)
	frame.previewDivider = style:CreateRule(frame)
	frame.previewDivider:SetPoint("TOPLEFT", frame.previewPane, "TOPLEFT", -5, 0)
	frame.previewDivider:SetPoint("BOTTOMLEFT", frame.previewPane, "BOTTOMLEFT", -5, 0)
	frame.previewDivider:SetWidth(1)
	frame.listScroll, frame.listContent = CreateScroll(frame.leftPane, -43, 8)
	frame.sectionHeaders, frame.tagPool = {}, {}

	frame.search = CreateFrame("EditBox", nil, frame.leftPane, "SearchBoxTemplate")
	frame.search:SetPoint("TOPLEFT", 10, -10)
	frame.search:SetHeight(24)
	frame.search:SetAutoFocus(false)
	if frame.search.Instructions then frame.search.Instructions:SetText(L("SEARCH_PLACEHOLDER", "Search...")) end
	frame.search:SetScript("OnEnterPressed", frame.search.ClearFocus)
	frame.search:HookScript("OnTextChanged", function(owner) self:SetFilter(owner:GetText()) end)

	frame.createSection = CreateIconAction(frame.leftPane, "folder-plus", L("FRIEND_TAGS_EDITOR_SECTION_CREATE", "Create Section"), function()
		BFL.ShowInputDialog("BFL_FRIEND_TAG_EDITOR_CREATE_SECTION")
	end)
	frame.createSection:SetPoint("TOPRIGHT", -8, -9)
	frame.restoreTags = CreateIconAction(frame.leftPane, "archive", L("FRIEND_TAGS_EDITOR_RESTORE", "Restore Tags"), function(owner)
		self:OpenRestoreMenu(owner)
	end)
	frame.restoreTags:SetPoint("RIGHT", frame.createSection, "LEFT")
	frame.restoreTags:Hide()
	frame.search:SetPoint("TOPRIGHT", frame.createSection, "TOPLEFT", -4, -1)
	frame.createButton = CreateSmallButton(frame.leftPane, L("FRIEND_TAGS_CREATE_CUSTOM", "Create Custom Tag"), 0, function()
		BFL.ShowInputDialog("BFL_FRIEND_TAG_EDITOR_CREATE_CUSTOM")
	end, 18)
	frame.createButton:SetPoint("BOTTOMLEFT", 8, 8)
	frame.createButton:SetPoint("BOTTOMRIGHT", -8, 8)
	frame.listScroll:SetPoint("BOTTOMRIGHT", frame.leftPane, "BOTTOMRIGHT", -25, 43)
	frame.listEmpty = CreateFont(frame.listContent, "BetterFriendlistFontDisableSmall")
	frame.listEmpty:SetPoint("TOPLEFT", 3, -7)
	frame.listEmpty:SetPoint("RIGHT", -3, 0)
	frame.listEmpty:SetJustifyH("LEFT")

	frame.dragMarker = frame.listContent:CreateTexture(nil, "OVERLAY")
	frame.dragMarker:SetHeight(2)
	frame.dragMarker:Hide()

	frame.back = CreateTextAction(frame.rightPane, "‹  " .. L("ONBOARDING_BACK", "Back"), function()
		self:CancelColorEdit()
		self.detailActive = false
		self:Layout()
	end)
	frame.back:SetPoint("TOPLEFT", 7, -4)
	frame.detailTitle = CreateFont(frame.rightPane, "BetterFriendlistFontNormalLarge")
	frame.detailTitle:SetWordWrap(false)
	frame.detailTitle:SetJustifyH("LEFT")
	frame.source = CreateFont(frame.rightPane, "BetterFriendlistFontDisableSmall")
	frame.source:SetJustifyH("LEFT")

	frame.detailScroll, frame.editorContent = CreateScroll(frame.rightPane, -66, 60)
	frame.footer = CreateFrame("Frame", nil, frame.rightPane)
	frame.footer:SetPoint("BOTTOMLEFT", 8, 8)
	frame.footer:SetPoint("BOTTOMRIGHT", -8, 8)
	frame.footer:SetHeight(43)
	local footerRule = style:CreateRule(frame.rightPane)
	footerRule:SetPoint("BOTTOMLEFT", frame.footer, "TOPLEFT", 0, 4)
	footerRule:SetPoint("BOTTOMRIGHT", frame.footer, "TOPRIGHT", 0, 4)
	self:CreateActionButtons(frame.footer)

	self:CreatePreview(frame.previewPane)
	if frame.CloseButton then
		frame.CloseButton:SetScript("OnClick", function() self:RequestClose() end)
	end
	frame:SetScript("OnSizeChanged", function() self:Layout() end)
	if frame.SetResizable and frame.SetResizeBounds and frame.StartSizing then
		frame:SetResizable(true)
		frame:SetResizeBounds(420, 455, EDITOR_WIDTH, EDITOR_HEIGHT)
		local grip = CreateFrame("Button", nil, frame)
		grip:SetSize(18, 18)
		grip:SetPoint("BOTTOMRIGHT", -1, 1)
		grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
		grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
		grip:SetScript("OnMouseDown", function(_, button)
			if button == "LeftButton" then frame:StartSizing("BOTTOMRIGHT") end
		end)
		grip:SetScript("OnMouseUp", function()
			frame:StopMovingOrSizing()
			self:FitWindow()
			local settings = BFL:GetModule("FrameSettings")
			if settings then settings:ApplyAuxiliaryScale(frame) end
		end)
	end
	self:Layout()
	self:RefreshAppearance()
	return frame
end

function FriendTagEditor:Layout()
	local frame = self.frame
	if not (frame and frame.previewPane) then return end
	local width = frame:GetWidth()
	local single = width < 720
	local stacked = width < 940
	self.previewStacked = stacked
	local showDetail = not single or self.detailActive == true
	frame.leftPane:SetWidth(single and width - 24 or LEFT_WIDTH)
	frame.leftPane:SetShown(not single or not showDetail)
	frame.rightPane:ClearAllPoints()
	if single then
		frame.rightPane:SetPoint("TOPLEFT", 12, -33)
	else
		frame.rightPane:SetPoint("TOPLEFT", frame.leftPane, "TOPRIGHT", 10, 0)
	end
	frame.rightPane:SetPoint("BOTTOMRIGHT", stacked and -12 or -290, 12)
	frame.rightPane:SetShown(showDetail)
	frame.back:SetShown(single)
	frame.detailTitle:ClearAllPoints()
	local titleTop = single and -32 or -12
	frame.detailTitle:SetPoint("TOPLEFT", 12, titleTop)
	frame.detailTitle:SetPoint("TOPRIGHT", single and -62 or -12, titleTop)
	frame.source:SetPoint("TOPLEFT", frame.detailTitle, "BOTTOMLEFT", 0, -4)
	local showTagActions = single and self.selectedTagId ~= nil
	frame.resetTag:SetShown(showTagActions)
	frame.removeTag:SetShown(showTagActions)

	local preview = frame.previewPane
	preview:ClearAllPoints()
	local titleHeight = single and 78 or 62
	if stacked then
		preview:SetPoint("TOPLEFT", frame.rightPane, "TOPLEFT", 8, -titleHeight)
		preview:SetPoint("TOPRIGHT", frame.rightPane, "TOPRIGHT", -8, -titleHeight)
		preview:SetHeight(142)
	else
		preview:SetPoint("TOPLEFT", frame.rightPane, "TOPRIGHT", 10, 0)
		preview:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -12, -33)
		preview:SetPoint("BOTTOM", frame.rightPane, "BOTTOM", 0, 0)
	end
	local selected = self.selectedTagId ~= nil
	preview.help:SetHeight(stacked and 44 or 0)
	preview:SetShown(showDetail and selected)
	frame.previewDivider:SetShown(not stacked and selected)
	local backgrounds = frame.BFL_ModernSettingsBackgrounds
	if backgrounds and backgrounds.navigationDivider then
		backgrounds.navigationDivider:SetShown(frame.settingsModern and not single)
	end
	if stacked and selected then
		frame.detailScroll:SetPoint("TOPLEFT", preview, "BOTTOMLEFT", 0, -8)
	else
		frame.detailScroll:SetPoint("TOPLEFT", frame.rightPane, "TOPLEFT", 8, -titleHeight)
	end
	self:RefreshPreview()
end

function FriendTagEditor:RefreshAppearance()
	local frame = self.frame
	if not (frame and frame.previewPane) then return end
	local style = BFL:GetModule("LegacySettingsStyle")
	local theme, modern, palette = style:GetWindowStyle()
	local engine = BFL:GetModule("SkinEngine")
	local skinActive = engine and engine.IsActive and engine:IsActive()
	style:SkinAuxiliaryWindow(frame)
	frame.MainInset:SetBackdropBorderColor(0.4, 0.4, 0.4, (modern or skinActive) and 0 or 0.8)
	style:RefreshWindowBackground(frame, theme, modern, palette)
	frame.settingsModern = modern
	local backgrounds = frame.BFL_ModernSettingsBackgrounds
	if backgrounds and backgrounds.navigationDivider then
		backgrounds.navigationDivider:SetShown(modern and frame:GetWidth() >= 720)
	end
	local border = palette and palette.border or { 1, 1, 1, 0.16 }
	frame.previewDivider:SetColorTexture(border[1], border[2], border[3], theme == "blizzard" and 0.25 or border[4])
	if self.visibilityHeader then
		style:RefreshSectionDivider(self.visibilityHeader, true, border)
	end
	local buttons = { frame.createButton, self.applyButton }
	if self.iconSelectButton then buttons[#buttons + 1] = self.iconSelectButton end
	if self.iconRemoveButton then buttons[#buttons + 1] = self.iconRemoveButton end
	for _, row in ipairs(self.editorRows or {}) do
		if skinActive and (row.DropDown or row.checkBox) then
			BFL:GetModule("DarkTheme"):SkinSettingsControl(engine, row)
		end
		if row.input then style:SkinActions(nil, row.input) end
	end
	style:SkinActions(buttons, frame.search)
	self:RefreshListActions()
	local r, g, b = BFL:GetThemeAccentColor(1, 0.82, 0.3, 1)
	frame.dragMarker:SetColorTexture(r, g, b, 1)
	self:UpdateListSelection()
	self:RefreshPreview()
end

function FriendTagEditor:RequestClose()
	self:CancelColorEdit()
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

function FriendTagEditor:FitWindow()
	local frame = self.frame
	if not (frame and frame.previewPane) then return end
	local scale = math.max(0.01, BFL.MainFrame and BFL.MainFrame:GetScale() or frame:GetScale())
	local width = math.max(420, math.floor((UIParent:GetWidth() - 20) / scale))
	local height = math.max(455, math.floor((UIParent:GetHeight() - 20) / scale))
	local fittedWidth = math.min(frame:GetWidth(), width)
	local fittedHeight = math.min(frame:GetHeight(), height)
	if fittedWidth ~= frame:GetWidth() or fittedHeight ~= frame:GetHeight() then
		frame:SetSize(fittedWidth, fittedHeight)
	end
end

function FriendTagEditor:Show(tagId)
	local frame = self:EnsureFrame()
	if not frame:IsShown() then
		local FrameSettings = BFL:GetModule("FrameSettings")
		self:FitWindow()
		if FrameSettings then FrameSettings:ApplyAuxiliaryScale(frame) end
		local FriendsUI = BFL:GetModule("FriendsUI")
		if _G.BetterFriendsFrame and _G.BetterFriendsFrame:IsShown() and FriendsUI and FriendsUI.AnchorAuxiliaryWindow then
			FriendsUI:AnchorAuxiliaryWindow(frame, 0)
		else
			frame:ClearAllPoints()
			frame:SetPoint("CENTER")
		end
	end
	if tagId then
		local tags = GetFriendTags()
		local def = tags and tags:GetTagDefinition(tagId)
		if def then
			self.selectedTagId = tagId
			self.detailActive = true
			self.previewSaved = false
			self.collapsed = self.collapsed or {}
			self.collapsed[def.chipProfile.section or ""] = false
			if self.filter and self.filter ~= "" then
				self.filter = ""
				frame.search:SetText("")
			end
		end
	elseif not frame:IsShown() then
		self.detailActive = false
	end
	self:Refresh()
	self:RefreshAppearance()
	frame:Show()
	BFL.FontManager:RefreshWindowFonts()
	frame:Raise()
	if tagId then self:ScrollTagIntoView(tagId) end
end

function FriendTagEditor:Refresh()
	self:EnsureFrame()
	local tags = GetFriendTags()
	for id in pairs(self.drafts) do
		if not tags or not tags:GetTagDefinition(id) then self.drafts[id] = nil end
	end
	if not self:GetSelectedDefinition() then
		self.selectedTagId = nil
		for _, group in ipairs(tags and tags:GroupTagDefinitions(self:GetDefinitions()) or {}) do
			if not self:IsSectionCollapsed(group) and group.tags[1] then
				self.selectedTagId = group.tags[1].id
				break
			end
		end
	end
	self:RefreshList()
	self:RefreshEditor()
	self:Layout()
end

function FriendTagEditor:OnDatabaseImported()
	self:CancelColorEdit()
	self.drafts = {}
	self.editState, self.savedState = nil, nil
	self.previewSaved = false
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

function FriendTagEditor:OpenRestoreMenu(owner)
	local tags = GetFriendTags()
	if not (tags and BFL.OpenSimpleContextMenu) then return end
	local restore = {}
	for _, tag in ipairs(tags:GetRemovedBlizzardTags()) do
		local tagId = tag.id
		restore[#restore + 1] = {
			text = tag.name,
			func = function()
				tags:SetBlizzardTagRemoved(tagId, false, function()
					self:Show(tagId)
					self:RefreshAfterDefinitionChange("restore")
				end)
			end,
		}
	end
	if #restore > 0 then
		BFL.OpenSimpleContextMenu(owner, "BFLFriendTagRestoreMenu", restore)
	end
end

function FriendTagEditor:ToggleSectionVisibility(section)
	local tags = GetFriendTags()
	if not tags then return end
	tags:SetTagSectionHidden(section.id, not section.hidden, function()
		self:RefreshAfterDefinitionChange("section-visibility")
	end)
end

function FriendTagEditor:DeleteSection(id, deleteTags)
	local tags = GetFriendTags()
	if not tags then return end
	self:CancelColorEdit()
	tags:DeleteTagSection(id, deleteTags, function()
		for tagId, draft in pairs(self.drafts) do
			if draft.section == id then
				local def = tags:GetTagDefinition(tagId)
				if def then
					draft.section = def.chipProfile.section
					if not self:HasDraftChanges(def, draft) then self.drafts[tagId] = nil end
				end
			end
		end
		self:RefreshAfterDefinitionChange("delete-section")
	end)
end

function FriendTagEditor:SetFilter(value)
	value = Trim(value)
	if self.filter == value then return end
	self.filter = value
	self:RefreshList()
end

local function NormalizeFilter(text)
	local intl = BFL.IntlCompat
	return intl and intl.NormalizeForSearch(text) or string.lower(text or "")
end

function FriendTagEditor:IsSectionCollapsed(section)
	local collapsed = self.collapsed and self.collapsed[section.id]
	if collapsed ~= nil then return collapsed end
	return section.hidden == true
end

function FriendTagEditor:GetTagListGroups(definitions)
	local tags = GetFriendTags()
	if not tags then return {} end
	local groups = tags:GroupTagDefinitions(definitions)
	local query = NormalizeFilter(self.filter)
	if query == "" then return groups end
	local matches = {}
	for _, section in ipairs(groups) do
		local filtered = {}
		for _, def in ipairs(section.tags) do
			if NormalizeFilter(def.name):find(query, 1, true) then
				filtered[#filtered + 1] = def
			end
		end
		if #filtered > 0 then
			matches[#matches + 1] = { id = section.id, name = section.name, hidden = section.hidden, tags = filtered }
		end
	end
	return matches
end

function FriendTagEditor:RefreshList()
	local frame = self:EnsureFrame()
	local tags = GetFriendTags()
	local canRestore = tags and #tags:GetRemovedBlizzardTags() > 0
	frame.restoreTags:SetShown(canRestore == true)
	frame.search:SetPoint("TOPRIGHT", canRestore and frame.restoreTags or frame.createSection, "TOPLEFT", -4, -1)
	self:CancelDrag()
	local scroll = frame.listScroll
	local offset = scroll:GetVerticalScroll()
	local filtering = NormalizeFilter(self.filter) ~= ""
	if filtering and not self.wasFiltering then
		self.beforeFilterScroll = offset
		offset = 0
	elseif not filtering and self.wasFiltering then
		offset = self.beforeFilterScroll or 0
	end
	self.wasFiltering = filtering
	for _, row in ipairs(frame.sectionHeaders) do row:Hide() end
	for _, row in ipairs(frame.tagPool) do row:Hide() end
	frame.tagRows, frame.sectionRows = {}, {}
	local groups = self:GetTagListGroups(self:GetDefinitions())
	frame.listEmpty:SetText(#groups == 0 and L("FRIEND_TAGS_EDITOR_NO_MATCH", "No tags found.") or "")
	local y = 0
	for index, group in ipairs(groups) do
		local expanded = filtering or not self:IsSectionCollapsed(group)
		local header = self:CreateSectionRow(frame, group, index, y, expanded, filtering)
		y = y + SECTION_HEADER_HEIGHT
		if expanded then
			local first = #frame.tagRows + 1
			local last = first + #group.tags - 1
			for _, def in ipairs(group.tags) do
				self:CreateTagRow(frame, def, y, first, last, filtering)
				y = y + ROW_HEIGHT
			end
			if last >= first then header.sectionBottom = frame.tagRows[last] end
		end
	end
	frame.listContent:SetHeight(math.max(24, y))
	scroll:UpdateScrollChildRect()
	scroll:SetVerticalScroll(math.min(offset, scroll:GetVerticalScrollRange()))
	self:UpdateListSelection()
	self:RefreshListActions()
end

function FriendTagEditor:RefreshListActions()
	local frame = self.frame
	local buttons = { frame.createSection, frame.restoreTags, frame.resetTag, frame.removeTag }
	for _, row in ipairs(frame.sectionHeaders) do
		buttons[#buttons + 1] = row.toggle
		buttons[#buttons + 1] = row.visibility
		buttons[#buttons + 1] = row.delete
	end
	for _, row in ipairs(frame.tagPool) do
		buttons[#buttons + 1] = row.reset
		buttons[#buttons + 1] = row.remove
	end
	BFL:GetModule("LegacySettingsStyle"):SkinActions(buttons)
end

local function CreateGrip(row, onStart, onStop)
	local grip = CreateFrame("Button", nil, row)
	grip:SetSize(20, 24)
	grip:SetPoint("LEFT")
	grip:SetNormalTexture("Interface\\AddOns\\BetterFriendlist\\Icons\\move")
	local icon = grip:GetNormalTexture()
	icon:ClearAllPoints()
	icon:SetPoint("CENTER")
	icon:SetSize(12, 12)
	icon:SetAlpha(0.7)
	grip:RegisterForDrag("LeftButton")
	grip:SetScript("OnDragStart", onStart)
	grip:SetScript("OnDragStop", onStop)
	return grip
end

function FriendTagEditor:CreateSectionRow(frame, section, index, y, expanded, filtering)
	local row = frame.sectionHeaders[index]
	if not row then
		row = CreateFrame("Frame", nil, frame.listContent)
		row:SetHeight(SECTION_HEADER_HEIGHT)
		row.grip = CreateGrip(row, function()
			self:BeginDrag(row, frame.sectionRows, 1, #frame.sectionRows, true)
		end, function() self:EndDrag(row) end)
		row.toggle = CreateIconAction(row, "chevron-down", nil, function()
			self.collapsed[row.section.id] = not self:IsSectionCollapsed(row.section)
			self:RefreshList()
		end)
		row.toggle:SetPoint("LEFT", 20, 0)
		row.toggle.Icon:SetSize(16, 16)
		row.delete = CreateIconAction(row, "trash-2", L("FRIEND_TAGS_EDITOR_SECTION_DELETE", "Delete Section"), function()
			StaticPopup_Show("BFL_FRIEND_TAG_EDITOR_DELETE_SECTION", row.section.name, nil, row.section.id)
		end)
		row.delete:SetPoint("RIGHT")
		row.visibility = CreateIconAction(row, "eye", nil, function()
			self:ToggleSectionVisibility(row.section)
		end)
		row.visibility:SetPoint("RIGHT", row.delete, "LEFT")
		row.rule = BFL:GetModule("LegacySettingsStyle"):CreateRule(row)
		row.rule:SetPoint("TOPLEFT", 4, 0)
		row.rule:SetPoint("TOPRIGHT", -3, 0)
		row.labelButton = CreateTextAction(row, "", function() row.toggle:Click() end)
		row.labelButton.BFL_DarkNoButtonChrome = true
		row.labelButton:SetPoint("LEFT", row.toggle, "RIGHT", 1, 0)
		row.labelButton:SetPoint("RIGHT", row.visibility, "LEFT", -3, 0)
		row.label = row.labelButton:GetFontString()
		row.label:ClearAllPoints()
		row.label:SetWordWrap(false)
		row.label:SetPoint("LEFT")
		row.label:SetPoint("RIGHT")
		frame.sectionHeaders[index] = row
	end
	local named = section.id ~= ""
	row:ClearAllPoints()
	row:SetPoint("TOPLEFT", 0, -y)
	row:SetPoint("RIGHT", -2, 0)
	row.section, row.sectionBottom = section, row
	row.listOffset = y
	row.grip:SetShown(named and not filtering)
	row.delete:SetShown(named)
	row.visibility:SetShown(named)
	SetActionIcon(row.visibility, section.hidden and "eye-off" or "eye")
	row.visibility.actionLabel = section.hidden and L("FRIEND_TAGS_EDITOR_SECTION_SHOW", "Show Section")
		or L("FRIEND_TAGS_EDITOR_SECTION_HIDE", "Hide Section")
	row.rule:SetShown(index > 1)
	SetActionIcon(row.toggle, expanded and "chevron-down" or "chevron-right")
	row.toggle.actionLabel = expanded and L("FRIEND_TAGS_EDITOR_SECTION_COLLAPSE", "Collapse Section")
		or L("FRIEND_TAGS_EDITOR_SECTION_EXPAND", "Expand Section")
	row.toggle:SetEnabled(not filtering)
	row.labelButton:SetEnabled(not filtering)
	row.label:SetFontObject(section.hidden and "BetterFriendlistFontDisableSmall" or "BetterFriendlistFontNormalSmall")
	row.label:SetJustifyH("LEFT")
	row.label:SetText(named and section.name or L("FRIEND_TAGS_EDITOR_NO_SECTION", "No Section"))
	row:Show()
	if named then
		row.orderIndex = #frame.sectionRows + 1
		frame.sectionRows[row.orderIndex] = row
	end
	return row
end

function FriendTagEditor:CreateTagRow(frame, def, y, first, last, filtering)
	local index = #frame.tagRows + 1
	local row = frame.tagPool[index]
	if not row then
		row = CreateFrame("Button", nil, frame.listContent)
		row:SetHeight(ROW_HEIGHT)
		row:SetHighlightTexture("Interface\\Buttons\\WHITE8X8")
		row:GetHighlightTexture():SetVertexColor(1, 1, 1, 0.09)
		row.selection = row:CreateTexture(nil, "BACKGROUND")
		row.selection:SetAllPoints()
		row.marker = row:CreateTexture(nil, "ARTWORK")
		row.marker:SetPoint("TOPLEFT", 0, -3)
		row.marker:SetPoint("BOTTOMLEFT", 0, 3)
		row.marker:SetWidth(2)
		row.grip = CreateGrip(row, function()
			self:BeginDrag(row, frame.tagRows, row.sectionFirst, row.sectionLast)
		end, function() self:EndDrag(row) end)
		row.icon = row:CreateTexture(nil, "ARTWORK")
		row.icon:SetSize(17, 17)
		row.icon:SetPoint("LEFT", 24, 0)
		row.name = CreateFont(row, "BetterFriendlistFontHighlightSmall")
		row.name:SetJustifyH("LEFT")
		row.name:SetWordWrap(false)
		row.name:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
		row.reset, row.remove = self:CreateTagActions(row, function() return row.tagId end)
		row.remove:SetPoint("RIGHT", -1, 0)
		row.name:SetPoint("RIGHT", row.reset, "LEFT", -10, 0)
		row.draftMarker = row:CreateTexture(nil, "OVERLAY")
		row.draftMarker:SetSize(6, 6)
		row.draftMarker:SetPoint("RIGHT", row.reset, "LEFT", -3, 0)
		row.draftMarker:SetColorTexture(1, 0.76, 0.18, 1)
		row:SetScript("OnClick", function()
			if self.selectedTagId ~= row.tagId then
				self.selectedTagId = row.tagId
				self.previewSaved = false
				self:RefreshEditor()
				frame.detailScroll:SetVerticalScroll(0)
			end
			self.detailActive = true
			self:UpdateListSelection()
			self:Layout()
		end)
		frame.tagPool[index] = row
	end
	row:ClearAllPoints()
	row:SetPoint("TOPLEFT", 16, -y)
	row:SetPoint("RIGHT", -2, 0)
	row.tagId = def.id
	row.remove.actionLabel = DeleteTagLabel(def)
	row.orderIndex = index
	row.listOffset = y
	row.sectionFirst, row.sectionLast = first, last
	row.grip:SetShown(not filtering and first < last)
	row.icon:SetShown(ApplyIcon(row.icon, def.chipProfile))
	row.name:ClearAllPoints()
	if row.icon:IsShown() then
		row.name:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
	else
		row.name:SetPoint("LEFT", 24, 0)
	end
	row.name:SetPoint("RIGHT", row.reset, "LEFT", -10, 0)
	row.name:SetText(def.name or def.id)
	row.draftMarker:SetShown(self.drafts[def.id] ~= nil)
	row:Show()
	frame.tagRows[index] = row
end

function FriendTagEditor:UpdateListSelection()
	local review = BFL:GetModule("LegacySettingsReview")
	local r, g, b = BFL:GetThemeAccentColor(1, 0.82, 0.3, 1)
	for _, row in ipairs(self.frame and self.frame.tagRows or {}) do
		local selected = row.tagId == self.selectedTagId
		local modern = selected and review and review:ApplyModernSettingSelection(row.selection)
		if selected and not modern then
			row.selection:SetColorTexture(r, g, b, 0.14)
			row.selection:SetBlendMode("BLEND")
		end
		row.selection:SetShown(selected)
		row.marker:SetColorTexture(r, g, b, 0.9)
		row.marker:SetShown(selected and not modern)
		row.name:SetFontObject(selected and "BetterFriendlistFontNormalSmall" or "BetterFriendlistFontHighlightSmall")
		row.name:SetJustifyH("LEFT")
	end
end

function FriendTagEditor:ScrollRowIntoView(row)
	local scroll = self.frame.listScroll
	local offset, height = scroll:GetVerticalScroll(), scroll:GetHeight()
	local rowBottom = row.listOffset + row:GetHeight()
	local target = math.min(row.listOffset, math.max(offset, rowBottom - height))
	if target ~= offset then scroll:SetVerticalScroll(target) end
end

function FriendTagEditor:ScrollTagIntoView(tagId)
	for _, row in ipairs(self.frame and self.frame.tagRows or {}) do
		if row.tagId == tagId then
			self:ScrollRowIntoView(row)
			return
		end
	end
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
				row.name:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
			else
				row.icon:Hide()
				row.name:SetPoint("LEFT", row, "LEFT", 24, 0)
			end
			return true
		end
	end
	return false
end

function FriendTagEditor:BeginDrag(row, rows, first, last, isSection)
	local frame = self:EnsureFrame()
	if first >= last or NormalizeFilter(self.filter) ~= "" then return end
	self:CancelDrag()
	self.dragState = {
		fromIndex = row.orderIndex,
		targetIndex = row.orderIndex,
		row = row,
		rows = rows,
		first = first,
		last = last,
		isSection = isSection,
	}
	row:SetAlpha(0.42)
	local ghost = BFL.GetDragGhost and BFL:GetDragGhost()
	if ghost then
		if ghost.BFLFriendTabIcon then ghost.BFLFriendTabIcon:Hide() end
		ghost:SetScript("OnUpdate", nil)
		ghost.text:ClearAllPoints()
		ghost.text:SetPoint("CENTER", 3, 0)
		ghost.text:SetText((isSection and row.label or row.name):GetText())
		local r, g, b = BFL:GetThemeAccentColor(1, 0.82, 0.3, 1)
		ghost.text:SetTextColor(r, g, b)
		ghost.stripe:SetColorTexture(r, g, b)
		ghost:SetSize(math.max(140, ghost.text:GetStringWidth() + 36), row:GetHeight())
		ghost:Show()
		self.dragState.ghost = ghost
	end
	frame:SetScript("OnUpdate", function(_, elapsed)
		self:UpdateDrag(elapsed)
	end)
	self:UpdateDrag(0)
end

function FriendTagEditor:UpdateDrag(elapsed)
	local frame = self.frame
	local drag = self.dragState
	if not (frame and drag) then return end
	local cursorX, cursorY = GetCursorPosition()
	if drag.ghost then
		local scale = UIParent:GetEffectiveScale()
		drag.ghost:ClearAllPoints()
		drag.ghost:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", cursorX / scale + 12, cursorY / scale - 8)
	end
	cursorY = cursorY / frame:GetEffectiveScale()
	local scroll = frame.listScroll
	local top, bottom = scroll:GetTop(), scroll:GetBottom()
	if top and bottom then
		local direction = cursorY > top - 20 and -1 or (cursorY < bottom + 20 and 1 or 0)
		if direction ~= 0 then
			local offset = scroll:GetVerticalScroll() + direction * elapsed * 240
			scroll:SetVerticalScroll(math.max(0, math.min(offset, scroll:GetVerticalScrollRange())))
		end
	end
	local last = drag.last
	local targetIndex = last + 1
	for index = drag.first, last do
		local row = drag.rows[index]
		local rowTop, rowBottom = row:GetTop(), (row.sectionBottom or row):GetBottom()
		if rowTop and rowBottom and cursorY >= (rowTop + rowBottom) / 2 then
			targetIndex = index
			break
		end
	end
	drag.targetIndex = targetIndex
	frame.dragMarker:ClearAllPoints()
	local target = drag.rows[targetIndex]
	if targetIndex > last then target = nil end
	if target then
		frame.dragMarker:SetPoint("TOPLEFT", target, "TOPLEFT", 0, 2)
		frame.dragMarker:SetPoint("TOPRIGHT", target, "TOPRIGHT", 0, 2)
	else
		local lastRow = drag.rows[last].sectionBottom or drag.rows[last]
		frame.dragMarker:SetPoint("BOTTOMLEFT", lastRow, "BOTTOMLEFT", 0, -2)
		frame.dragMarker:SetPoint("BOTTOMRIGHT", lastRow, "BOTTOMRIGHT", 0, -2)
	end
	frame.dragMarker:Show()
end

function FriendTagEditor:CancelDrag()
	local frame = self.frame
	local drag = self.dragState
	if not drag then return end
	frame:SetScript("OnUpdate", nil)
	frame.dragMarker:Hide()
	drag.row:SetAlpha(1)
	if drag.ghost then
		drag.ghost:Hide()
		drag.ghost:ClearAllPoints()
	end
	self.dragState = nil
end

function FriendTagEditor:EndDrag(row)
	local drag = self.dragState
	if not drag or drag.row ~= row then return end
	self:CancelDrag()
	local insertIndex = drag.targetIndex
	if insertIndex > drag.fromIndex then
		insertIndex = insertIndex - 1
	end
	if insertIndex == drag.fromIndex then
		return
	end

	local tags = GetFriendTags()
	if not tags then return end
	local function Refresh()
		if C_Timer and C_Timer.After then
			C_Timer.After(0, function() self:RefreshAfterDefinitionChange("order") end)
		else
			self:RefreshAfterDefinitionChange("order")
		end
	end
	if drag.isSection then
		local ids = {}
		for _, sectionRow in ipairs(drag.rows) do ids[#ids + 1] = sectionRow.section.id end
		table.insert(ids, insertIndex, table.remove(ids, drag.fromIndex))
		tags:SetTagSectionOrder(ids, Refresh)
		return
	end

	local first, last = drag.first, drag.last
	local sectionOrder, sectionMembers = {}, {}
	for index = first, last do
		local tagId = drag.rows[index].tagId
		sectionOrder[#sectionOrder + 1] = tagId
		sectionMembers[tagId] = true
	end
	local moved = table.remove(sectionOrder, drag.fromIndex - first + 1)
	table.insert(sectionOrder, insertIndex - first + 1, moved)

	-- Keep positions occupied by other sections in the underlying chip order.
	local tagIds = {}
	local sectionIndex = 1
	for _, def in ipairs(self:GetDefinitions()) do
		local tagId = def.id
		if sectionMembers[tagId] then
			tagId = sectionOrder[sectionIndex]
			sectionIndex = sectionIndex + 1
		end
		tagIds[#tagIds + 1] = tagId
	end
	tags:SetTagOrder(tagIds, Refresh)
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
		iconColor = profile.iconColor and CopyColor(profile.iconColor),
		section = profile.section,
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

function FriendTagEditor:AddEditorRow(row)
	self.editorRows[#self.editorRows + 1] = row
	return row
end

function FriendTagEditor:LayoutEditorRows()
	local content = self.dynamicEditorContent
	if not content then return end
	local y = 0
	for _, row in ipairs(self.editorRows) do
		if row:IsShown() then
			if row == self.visibilityHeader then y = y + 12 end
			row:ClearAllPoints()
			row:SetPoint("TOPLEFT", 4, -y)
			row:SetPoint("RIGHT", -5, 0)
			y = y + row:GetHeight() + 3
			if row == self.fieldErrorTarget then
				local errorText = self.fieldError
				errorText:ClearAllPoints()
				errorText:SetPoint("TOPLEFT", 10, -y)
				errorText:SetPoint("RIGHT", -8, 0)
				y = y + errorText:GetStringHeight() + 6
			end
		end
	end
	self.frame.editorContent:SetHeight(math.max(1, y + 6))
	self.frame.detailScroll:UpdateScrollChildRect()
end

function FriendTagEditor:RefreshEditor()
	self:CancelColorEdit()
	local frame = self:EnsureFrame()
	local editorHost = frame.editorContent
	ClearChildren(editorHost)
	self.editorRows = {}
	self.helpTopic, self.hoverHelpTopic, self.pinnedHelpTopic = nil, nil, nil
	local content = CreateFrame("Frame", nil, editorHost)
	content:SetAllPoints(editorHost)
	self.dynamicEditorContent = content
	self.iconInputRow, self.labelInputRow = nil, nil
	self.iconInput, self.iconSelectButton, self.iconButtonPreview, self.nameInput = nil, nil, nil, nil
	self.fieldError, self.fieldErrorTarget = nil, nil

	local def = self:GetSelectedDefinition()
	if def then frame.removeTag.actionLabel = DeleteTagLabel(def) end
	self.visibilityHeader = nil
	frame.detailTitle:SetText(def and (def.name or def.id) or L("FRIEND_TAGS_EDITOR_SELECT_TAG", "Select a tag to edit."))
	frame.source:SetText(def and (def.source == "blizzard" and L("FRIEND_TAGS_SOURCE_BLIZZARD", "Blizzard")
		or L("FRIEND_TAGS_SOURCE_CUSTOM", "Custom")) or "")
	if not def then
		self.editState, self.savedState = nil, nil
		self:LayoutEditorRows()
		self:UpdateDraftControls()
		return
	end

	self:LoadState(def)
	local state = self.editState
	local components = BFL.SettingsComponents
	self:AddEditorRow(components:CreateHeader(content, L("SETTINGS_TAB_APPEARANCE", "Appearance")))
	if def.source == "custom" then
		local row, box = self:CreateLabeledInput(content, L("FRIEND_TAGS_EDITOR_NAME", "Name"), state.name, 32, function(value)
			state.name = value
			frame.detailTitle:SetText(value ~= "" and value or def.name)
		end)
		self.nameInput = box
		self:AddEditorRow(row)
		self:BindHelp(row, box, L("FRIEND_TAGS_EDITOR_NAME", "Name"),
			L("FRIEND_TAGS_EDITOR_NAME_HELP", "Rename this custom tag. The chip uses this name when its label is set to Tag Name."), "label")
	end
	self:CreateIconControls(content)
	self:CreateLabelControls(content)
	self:CreateColorControl(content, "color", L("FRIEND_TAGS_EDITOR_COLOR", "Chip Color"), "colorButton")
	self:CreateColorControl(content, "textColor", L("FRIEND_TAGS_EDITOR_TEXT_COLOR", "Chip Font Color"), "textColorButton")
	self:CreateColorControl(content, "iconColor", L("FRIEND_TAGS_EDITOR_ICON_COLOR", "Icon Color"), "iconColorButton")
	self:CreateSectionControl(content, state)
	self.visibilityHeader = self:AddEditorRow(components:CreateHeader(content, L("FRIEND_TAGS_EDITOR_VISIBILITY", "Visibility")))
	self:CreateVisibilityControls(content)
	self:LayoutEditorRows()
	self:UpdateDraftControls()
	self:RefreshHelp()
	self:RefreshPreview()
	self:RefreshAppearance()
end

function FriendTagEditor:CreateLabelControls(content)
	local state = self.editState
	local title = L("FRIEND_TAGS_EDITOR_LABEL", "Chip Label")
	local components = BFL.SettingsComponents
	local options = {
		values = { "default", "custom", "icon_only" },
		labels = {
			L("FRIEND_TAGS_EDITOR_LABEL_DEFAULT", "Tag Name"),
			L("FRIEND_TAGS_EDITOR_LABEL_CUSTOM", "Custom Text"),
			L("FRIEND_TAGS_EDITOR_LABEL_ICON_ONLY", "Icon Only"),
		},
	}
	local mode = components:CreateDropdown(content, title, options, function(value)
		return state.labelMode == value
	end, function(value) self:SetLabelMode(value) end, 145)
	self:AddEditorRow(mode)
	self:BindHelp(mode, mode.DropDown, title,
		L("FRIEND_TAGS_EDITOR_LABEL_HELP", "Choose the tag name, custom text, or just the icon. Your custom text is kept when you change modes."), "label")
	local input = self:CreateLabeledInput(content, options.labels[2], state.labelValue, 32, function(value)
		state.labelValue = value
	end)
	self.labelInputRow = self:AddEditorRow(input)
	self:BindHelp(input, input.input, options.labels[2],
		L("FRIEND_TAGS_EDITOR_LABEL_HELP", "Choose the tag name, custom text, or just the icon. Your custom text is kept when you change modes."), "label")

	local checkbox = components:CreateCheckbox(content, L("FRIEND_TAGS_EDITOR_ICON_ONLY_CHIP", "Keep Chip Color"),
		state.iconOnlyChip, function(checked)
			state.iconOnlyChip = checked == true
			self:MarkDraft()
		end)
	self.iconOnlyChipHolder = self:AddEditorRow(checkbox)
	self:BindHelp(checkbox, checkbox.checkBox, L("FRIEND_TAGS_EDITOR_ICON_ONLY_CHIP", "Keep Chip Color"),
		L("FRIEND_TAGS_EDITOR_ICON_ONLY_CHIP_DESC", "Keep the colored chip background when this tag uses Icon Only."))
	self:UpdateLabelControls()
end

function FriendTagEditor:UpdateLabelControls()
	if not self.labelInputRow then return end
	local mode = self.editState.labelMode
	self.labelInputRow:SetShown(mode == "custom")
	self.iconOnlyChipHolder:SetShown(mode == "icon_only")
	self:LayoutEditorRows()
end

function FriendTagEditor:SetLabelMode(mode)
	self.editState.labelMode = mode
	self:UpdateLabelControls()
	self:MarkDraft()
end

function FriendTagEditor:CreatePreview(parent)
	local preview = parent
	self.preview = preview
	local header = CreateFont(preview, "BetterFriendlistFontNormal")
	preview.title = header
	header:SetPoint("TOPLEFT", 10, -9)
	header:SetPoint("TOPRIGHT", -84, -9)
	header:SetJustifyH("LEFT")
	header:SetWordWrap(false)
	header:SetText(L("FRIEND_TAGS_EDITOR_PREVIEW", "Preview"))
	preview.compare = CreateTextAction(preview, "", function()
		self.previewSaved = not self.previewSaved
		self:RefreshPreview()
	end)
	preview.compare:SetPoint("TOPRIGHT", -7, -4)

	local style = BFL:GetModule("LegacySettingsStyle")
	local previewRule = style:CreateRule(preview)
	previewRule:SetPoint("TOPLEFT", 8, -27)
	previewRule:SetPoint("TOPRIGHT", -8, -27)
	preview.rowHost = CreateFrame("Frame", nil, preview)
	preview.rowHost:SetPoint("TOPLEFT", 8, -31)
	preview.rowHost:SetPoint("RIGHT", -8, 0)
	preview.rowHost:SetHeight(48)
	preview.widgets = {}
	preview.empty = CreateFont(preview, "BetterFriendlistFontDisableSmall")
	preview.empty:SetPoint("TOPLEFT", preview.rowHost, "BOTTOMLEFT", 1, -2)
	preview.empty:SetPoint("RIGHT", -9, 0)
	preview.empty:SetJustifyH("LEFT")
	preview.status = CreateFont(preview, "BetterFriendlistFontHighlightSmall")
	preview.status:SetPoint("TOPLEFT", preview.empty, "BOTTOMLEFT", 0, -5)
	preview.status:SetPoint("RIGHT", -9, 0)
	preview.status:SetJustifyH("LEFT")

	preview.section = CreateFont(preview, "BetterFriendlistFontHighlightSmall")
	preview.section:SetPoint("TOPLEFT", preview.status, "BOTTOMLEFT", 0, -4)
	preview.section:SetPoint("RIGHT", -9, 0)
	preview.section:SetHeight(14)
	preview.section:SetWordWrap(false)
	preview.section:SetJustifyH("LEFT")
	preview.highlight = preview:CreateTexture(nil, "OVERLAY", nil, 7)
	preview.highlight:Hide()
	preview.helpRule = style:CreateRule(preview)
	preview.helpRule:SetPoint("TOPLEFT", preview.section, "BOTTOMLEFT", 0, -6)
	preview.helpRule:SetPoint("TOPRIGHT", preview.section, "BOTTOMRIGHT", 0, -6)
	preview.helpRule:Hide()
	preview.help = CreateFont(preview, "BetterFriendlistFontHighlightSmall")
	preview.help:SetPoint("TOPLEFT", preview.section, "BOTTOMLEFT", 0, -13)
	preview.help:SetPoint("RIGHT", -40, 0)
	preview.help:SetJustifyH("LEFT")
	preview.help:SetJustifyV("TOP")
	preview.help:SetWordWrap(true)
	preview.pin = CreateTextAction(preview, "", function()
		self:ToggleHelpPin(self.helpTopic)
	end)
	preview.pin:SetPoint("TOPRIGHT", preview.help, "TOPRIGHT", 34, 5)
end

local function PaintHelpHighlight(texture, pinned)
	local review = BFL:GetModule("LegacySettingsReview")
	if review and review:ApplyModernSettingSelection(texture, pinned and 0.75 or 0.45) then return end
	local r, g, b = BFL:GetThemeAccentColor(1, 0.82, 0.3)
	texture:SetBlendMode("BLEND")
	texture:SetVertexColor(1, 1, 1, 1)
	texture:SetColorTexture(r, g, b, pinned and 0.25 or 0.14)
end

function FriendTagEditor:ToggleHelpPin(topic)
	if not topic then return end
	self.pinnedHelpTopic = self.pinnedHelpTopic ~= topic and topic or nil
	self.helpTopic = self.pinnedHelpTopic or self.hoverHelpTopic or topic
	self:RefreshHelp()
end

function FriendTagEditor:BindHelp(row, control, title, description, target)
	local tint = row:CreateTexture(nil, "BACKGROUND")
	tint:SetAllPoints()
	tint:Hide()
	local topic = { row = row, tint = tint, title = title, description = description, target = target }
	local function Enter()
		self.hoverHelpTopic = topic
		if not self.pinnedHelpTopic then
			self.helpTopic = topic
			self:RefreshHelp()
		end
	end
	local function Leave()
		C_Timer.After(0, function()
			if self.hoverHelpTopic ~= topic or BFL:IsRegionMouseOver(row) then return end
			self.hoverHelpTopic = nil
			self:RefreshHelp()
		end)
	end
	row:EnableMouse(true)
	row:HookScript("OnEnter", Enter)
	row:HookScript("OnLeave", Leave)
	row:HookScript("OnMouseDown", function(_, button)
		if button == "LeftButton" then topic.pressX, topic.pressY = GetCursorPosition() end
	end)
	row:HookScript("OnMouseUp", function(_, button)
		local x, y = GetCursorPosition()
		if button == "LeftButton" and topic.pressX and math.abs(topic.pressX - x) <= 6
			and math.abs(topic.pressY - y) <= 6 and BFL:IsRegionMouseOver(row)
		then
			self:ToggleHelpPin(topic)
		end
		topic.pressX, topic.pressY = nil, nil
	end)
	if control then
		control:HookScript("OnEnter", Enter)
		control:HookScript("OnLeave", Leave)
	end
end

function FriendTagEditor:RefreshPreviewHighlight()
	local preview = self.preview
	if not (preview and preview.highlight) then return end
	local topic = self.pinnedHelpTopic or self.hoverHelpTopic
	local widget = preview.widgets[1]
	local tagRow = widget and widget.friendTagRow
	local chip = tagRow and tagRow:IsShown() and tagRow.chips[1]
	local target
	if topic then
		if topic.target == "section" then
			target = preview.section
		elseif topic.target == "status" then
			target = preview.status
		elseif chip and chip:IsShown() then
			target = topic.target == "icon" and chip.icon or topic.target == "label" and chip.label or chip
			if not target:IsShown() then target = chip end
		end
	end
	local highlight = preview.highlight
	highlight:SetShown(target ~= nil)
	if target then
		highlight:ClearAllPoints()
		highlight:SetPoint("TOPLEFT", target, "TOPLEFT", -3, 2)
		highlight:SetPoint("BOTTOMRIGHT", target, "BOTTOMRIGHT", 3, -2)
		PaintHelpHighlight(highlight, self.pinnedHelpTopic ~= nil)
	end
end

function FriendTagEditor:RefreshHelp()
	if not self.preview then return end
	local active = self.pinnedHelpTopic or self.hoverHelpTopic
	if self.highlightedHelpTopic then self.highlightedHelpTopic.tint:Hide() end
	self.highlightedHelpTopic = active
	if active then
		PaintHelpHighlight(active.tint, self.pinnedHelpTopic ~= nil)
		active.tint:Show()
	end
	local topic = self.helpTopic
	self.preview.help:SetText(topic and (topic.title .. "\n" .. topic.description) or "")
	local label = self.pinnedHelpTopic and L("FRIEND_TAGS_EDITOR_UNPIN", "Unpin") or L("FRIEND_TAGS_EDITOR_PIN", "Pin")
	self.preview.pin:SetText(label)
	local width = math.ceil(self.preview.pin:GetFontString():GetStringWidth() + 8)
	self.preview.pin:SetWidth(width)
	self.preview.pin:SetShown(topic ~= nil)
	self.preview.helpRule:SetShown(topic ~= nil)
	self.preview.pin:SetPoint("TOPRIGHT", self.preview.section, "BOTTOMRIGHT", 0, -7)
	self.preview.help:SetPoint("RIGHT", self.preview, "RIGHT", -(width + 12), 0)
	self:RefreshPreviewHighlight()
	self:FitPreviewHeight()
end

function FriendTagEditor:GetPreviewLabel(state)
	local def = self:GetSelectedDefinition()
	state = state or self.editState or {}
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

function FriendTagEditor:GetPreviewChipProfile(state)
	state = state or self.editState or {}
	local profile = self:GetPreviewIconProfile(state) or { iconType = "none" }
	profile.color = CopyColor(state.color)
	profile.textColor = CopyColor(state.textColor, { r = 1, g = 1, b = 1, a = 1 })
	profile.iconColor = state.iconColor and CopyColor(state.iconColor)
	profile.iconOnlyChip = state.iconOnlyChip == true
	return profile
end

function FriendTagEditor:BuildPreviewTag(state)
	local profile = self:GetPreviewChipProfile(state)
	profile.chipLabel = self:GetPreviewLabel(state)
	profile.visible, profile.rowVisible = state.visible, state.rowVisible
	profile.tooltipVisible, profile.brokerVisible = state.tooltipVisible, state.brokerVisible
	return { id = state.tagId, name = state.name, chipProfile = profile }
end

local function DisablePreviewInput(frame)
	if frame.EnableMouse then frame:EnableMouse(false) end
	if frame.SetMouseClickEnabled then frame:SetMouseClickEnabled(false) end
	if frame.SetMouseMotionEnabled then frame:SetMouseMotionEnabled(false) end
	for _, child in ipairs({ frame:GetChildren() }) do DisablePreviewInput(child) end
end

function FriendTagEditor:RefreshPreview()
	local preview, draft = self.preview, self.editState
	if not (preview and draft and preview:IsShown()) then return end
	local dirty = self.drafts[draft.tagId] ~= nil
	if not dirty then self.previewSaved = false end
	local state = self.previewSaved and self.savedState or draft
	local compareLabel = self.previewSaved and L("FRIEND_TAGS_EDITOR_DRAFT", "Draft") or L("FRIEND_TAGS_EDITOR_SAVED", "Saved")
	preview.compare:SetText(compareLabel)
	preview.compare:SetWidth(preview.compare:GetFontString():GetStringWidth() + 12)
	preview.compare:SetShown(dirty)
	local heading = L("FRIEND_TAGS_EDITOR_PREVIEW", "Preview")
	if dirty then
		heading = heading .. " · " .. (self.previewSaved and L("FRIEND_TAGS_EDITOR_SAVED", "Saved") or L("FRIEND_TAGS_EDITOR_DRAFT", "Draft"))
	end
	preview.title:SetText(heading)

	local tags = GetFriendTags()
	local db = BFL:GetModule("DB")
	local friends = BFL:GetModule("FriendsList")
	if not (tags and db and friends and friends.CreateSettingsSampleContext) then return end
	local tag = self:BuildPreviewTag(state)
	local profile = tag.chipProfile
	local icon = profile.iconValue or profile.texture or profile.icon or profile.atlas
	local hasIcon = profile.iconType ~= "none" and icon ~= nil and icon ~= ""
	local hasContent = profile.chipLabel ~= "" or hasIcon
	local settings = db:Get("friendTagSettings", {})
	local section = settings.sections and settings.sections[state.section]
	local sectionVisible = not (type(section) == "table" and section.hidden == true)
	local streamer = db:Get("streamerModeActive", false)
	local compact = db:Get("compactMode", false) and (settings.compactRowMode or "icon_only")
	local rowVisible = sectionVisible and profile.visible and profile.rowVisible and tags:CanDisplayTags("row", nil, streamer, settings)
		and not (db.IsInfoDisabled and db:IsInfoDisabled()) and compact ~= "hidden"
	local showChip = rowVisible and hasContent and (compact ~= "icon_only" or hasIcon)
	local sampleName = L("SETTINGS_LEGACY_SAMPLE_ONLINE", "Aster")
	local sample = {
		type = "wow", connected = true, name = sampleName, characterName = sampleName,
		level = BFL.GetMaxLevel and BFL.GetMaxLevel() or 60, classFilename = "MAGE", _isMock = true,
		settingsTagDefinitions = showChip and { tag } or {},
	}
	preview.renderer = preview.renderer or friends:CreateSettingsSampleContext(preview.rowHost)
	local renderer = preview.renderer
	renderer.settingsSampleTagSettings = settings
	renderer.settingsSampleStreamerMode = streamer
	local width = preview.rowHost:GetWidth()
	if width > 30 then
		local widget = renderer:RenderSettingsSample(preview.rowHost, preview.widgets, 1, { friend = sample }, width)
		widget:ClearAllPoints()
		widget:SetPoint("TOPLEFT", preview.rowHost, "TOPLEFT")
		widget:Show()
		preview.rowHost:SetHeight(widget:GetHeight())
		DisablePreviewInput(widget)
	end
	local message = ""
	if rowVisible and state.labelMode == "icon_only" and not hasIcon then
		message = L("FRIEND_TAGS_EDITOR_ICON_REQUIRED", "Icon Only needs an icon. Choose one or switch to a text mode.")
	elseif not showChip then
		message = L("FRIEND_TAGS_EDITOR_PREVIEW_HIDDEN", "This tag is hidden in the friends list.")
	end
	preview.empty:SetText(message)
	preview.empty:SetHeight(message == "" and 1 or math.max(14, preview.empty:GetStringHeight()))
	local function Status(visible)
		return visible and L("FRIEND_TAGS_EDITOR_STATUS_SHOWN", "Shown") or L("FRIEND_TAGS_COMPACT_HIDDEN", "Hidden")
	end
	local tooltip = sectionVisible and hasContent and profile.visible and profile.tooltipVisible
		and tags:CanDisplayTags("tooltip", nil, streamer, settings)
	local broker = sectionVisible and hasContent and profile.visible and profile.brokerVisible and db:Get("brokerEnabled", false)
		and tags:CanDisplayTags("broker", nil, streamer, settings)
	local separator = self.previewStacked and "   /   " or "\n"
	preview.status:SetText(L("FRIEND_TAGS_EDITOR_TOOLTIP_VISIBLE", "Tooltips") .. " · " .. Status(tooltip)
		.. separator .. L("FRIEND_TAGS_EDITOR_BROKER_VISIBLE", "Broker") .. " · " .. Status(broker))
	if preview.section then
		local sectionName = self.sectionNames and self.sectionNames[state.section or ""]
		preview.section:SetText(L("FRIEND_TAGS_EDITOR_SECTION", "Section") .. " · "
			.. (sectionName or L("FRIEND_TAGS_EDITOR_NO_SECTION", "No Section"))
			.. (sectionVisible and "" or (" · " .. L("FRIEND_TAGS_COMPACT_HIDDEN", "Hidden"))))
	end
	self:RefreshPreviewHighlight()
	self:FitPreviewHeight()
end

function FriendTagEditor:FitPreviewHeight()
	local preview = self.preview
	if not (self.previewStacked and preview and preview:IsShown()) then return end
	preview:SetHeight(67 + preview.rowHost:GetHeight() + preview.empty:GetHeight()
		+ preview.status:GetStringHeight() + preview.help:GetHeight())
end

local function CreateEditorRow(parent, label, height)
	local row = CreateFrame("Frame", nil, parent)
	row:SetHeight(height or 30)
	local text = CreateFont(row, "BetterFriendlistFontHighlight")
	text:SetPoint("LEFT", 6, 0)
	text:SetJustifyH("LEFT")
	text:SetWordWrap(false)
	text:SetText(label)
	row.label = text
	return row
end

function FriendTagEditor:CreateLabeledInput(parent, label, value, maxLetters, update)
	local row = BFL.SettingsComponents:CreateInput(parent, label, value, nil, 145)
	local input = row.Input
	row.label = row.Label
	input:SetHeight(24)
	input:SetMaxLetters(maxLetters or 128)
	input:SetFontObject("BetterFriendlistFontHighlightSmall")
	input:SetTextInsets(6, 6, 0, 0)
	SetEditBoxText(input, value)
	input:SetScript("OnTextChanged", function(editBox, userInput)
		if not userInput then return end
		update(GetEditBoxText(editBox))
		self:MarkDraft()
	end)
	self:BindEditorInputFocusHandlers(input)
	row.input = input
	return row, input
end

function FriendTagEditor:CreateSectionControl(parent, state)
	local noSection = L("FRIEND_TAGS_EDITOR_NO_SECTION", "No Section")
	local options = { labels = { noSection }, values = { "" } }
	self.sectionNames = { [""] = noSection }
	for _, section in ipairs(GetFriendTags():GetTagSections()) do
		options.labels[#options.labels + 1] = section.name
		options.values[#options.values + 1] = section.id
		self.sectionNames[section.id] = section.name
	end
	local title = L("FRIEND_TAGS_EDITOR_SECTION", "Section")
	local row = self:AddEditorRow(BFL.SettingsComponents:CreateDropdown(parent, title, options,
		function(id) return (state.section or "") == id end, function(id)
			state.section = id ~= "" and id or nil
			self:MarkDraft()
		end, 145))
	self:BindHelp(row, row.DropDown, title,
		L("FRIEND_TAGS_EDITOR_SECTION_HELP", "Choose the section that contains this tag in the editor and friend menu."), "section")
end

function FriendTagEditor:SetIconMode(mode)
	self.editState.iconMode = mode
	self:UpdateIconControls()
	self:LayoutEditorRows()
	self:MarkDraft()
end

function FriendTagEditor:OpenIconSelector(anchor)
	local state = self.editState
	if not (state and BFL.ShowIconSelector) then return end
	local function IsCurrent()
		return self.editState == state and self.iconSelectButton == anchor and self.frame:IsShown()
	end

	BFL.ShowIconSelector(anchor, self:GetPreviewIcon(), function(iconRef, iconProfile)
		if not IsCurrent() then return end
		local profile = CopyIconProfile(iconProfile or { iconType = "texture", iconValue = iconRef })
		state.iconOptionID = iconProfile and iconProfile.id or nil
		state.iconType, state.iconValue, state.icon = profile.iconType, profile.iconValue or iconRef, profile.icon or iconRef
		state.atlas, state.fallbackAtlas, state.texture = profile.atlas, profile.fallbackAtlas, profile.texture
		state.texCoord, state.iconZoom = profile.texCoord, profile.iconZoom
		self:SetIconMode("selected")
	end, {
		source = "tags", extraIcons = GetFriendTags():GetIconOptions(), anchorFrame = self.frame,
		customPath = state.customIconPath,
		onCustomPath = function(path)
			if not IsCurrent() then return end
			state.customIconPath = path
			if self.iconInput then SetEditBoxText(self.iconInput, path) end
			self:SetIconMode("custom")
		end,
	})
end

function FriendTagEditor:CreateIconControls(parent)
	local state = self.editState
	local label = L("FRIEND_TAGS_EDITOR_ICON", "Icon")
	local row = self:AddEditorRow(CreateEditorRow(parent, label, 36))
	local remove = CreateSmallButton(row, L("FRIEND_TAGS_EDITOR_ICON_REMOVE", "Remove Icon"), 70,
		function() self:SetIconMode("none") end, 14)
	remove:SetPoint("RIGHT", -8, 0)
	self.iconRemoveButton = remove
	local button = CreateSmallButton(row, "+", 36, function(owner) self:OpenIconSelector(owner) end, 12)
	button:SetWidth(40)
	button:SetPoint("TOPRIGHT", remove, "TOPLEFT", -6, 0)
	button:SetPoint("BOTTOMRIGHT", remove, "BOTTOMLEFT", -6, 0)
	row.label:SetPoint("RIGHT", button, "LEFT", -8, 0)
	button:SetEnabled(BFL.ShowIconSelector ~= nil)
	self.iconSelectButton = button
	local chips = GetTagChips()
	button.chip = chips and chips:CreateStandaloneChip(button)
	if button.chip then button.chip:SetPoint("CENTER") end
	self.iconButtonPreview = button
	self:BindHelp(row, button, label,
		L("FRIEND_TAGS_EDITOR_ICON_HELP", "Click the icon to choose one from the library or enter your own path in the picker."), "icon")
	local inputRow, input = self:CreateLabeledInput(parent, L("FRIEND_TAGS_EDITOR_ICON_CUSTOM", "Custom Path"),
		state.customIconPath, 180, function(value)
			state.customIconPath = value
			self:UpdateIconControls()
		end)
	self.iconInputRow, self.iconInput = self:AddEditorRow(inputRow), input
	self:BindHelp(inputRow, input, L("FRIEND_TAGS_EDITOR_ICON_CUSTOM", "Custom Path"),
		L("FRIEND_TAGS_EDITOR_ICON_HELP", "Click the icon to choose one from the library or enter your own path in the picker."), "icon")
	self:UpdateIconControls()
end

function FriendTagEditor:UpdateIconControls()
	local state = self.editState or {}
	if self.iconRemoveButton then self.iconRemoveButton:SetEnabled(state.iconMode ~= "none") end
	if self.iconButtonPreview then
		local profile = self:GetPreviewChipProfile()
		local iconValue = profile.iconValue or profile.icon or profile.texture or profile.atlas
		local TagChips = GetTagChips()
		if self.iconButtonPreview.chip and TagChips and TagChips.UpdateStandaloneChip and profile.iconType ~= "none" and iconValue and iconValue ~= "" then
			local chip = self.iconButtonPreview.chip
			TagChips:UpdateStandaloneChip(chip, profile, "", 28, math.max(1, self.iconButtonPreview:GetHeight() - 6))
			self.iconButtonPreview:SetText(chip:IsShown() and "" or "+")
		else
			self.iconButtonPreview:SetText("+")
			if self.iconButtonPreview.chip then
				self.iconButtonPreview.chip:Hide()
			end
		end
	end
	if self.iconInputRow then
		self.iconInputRow:SetShown(state.iconMode == "custom")
	end
end

function FriendTagEditor:CreateColorControl(parent, stateKey, labelText, buttonField)
	local state = self.editState
	local isIconColor = stateKey == "iconColor"
	local fallback = (stateKey == "textColor" or isIconColor) and { r = 1, g = 1, b = 1, a = 1 } or nil
	local row = self:AddEditorRow(CreateEditorRow(parent, labelText))
	local button = CreateFrame("Button", nil, row, "BackdropTemplate")
	button:SetPoint("RIGHT", -8, 0)
	button:SetSize(34, 21)
	row.label:SetPoint("RIGHT", button, "LEFT", -8, 0)
	BFL.SetOwnedBackdrop(button, BACKDROP)
	self[buttonField] = button
	local help, target
	if stateKey == "textColor" then
		help, target = L("FRIEND_TAGS_EDITOR_TEXT_COLOR_HELP", "Change the color of the text inside this tag."), "label"
	elseif isIconColor then
		help, target = L("FRIEND_TAGS_EDITOR_ICON_COLOR_HELP", "Tint this tag’s icon. Reset restores the icon’s original colors."), "icon"
	else
		help = L("FRIEND_TAGS_EDITOR_COLOR_HELP", "Change the background color of this tag’s chip.")
	end
	self:BindHelp(row, button, labelText, help, target)

	local resetButton
	local function UpdateSwatch()
		local color = CopyColor(state[stateKey], fallback)
		button:SetBackdropColor(color.r, color.g, color.b, color.a or 1)
		button:SetBackdropBorderColor(0, 0, 0, 1)
		if resetButton then resetButton:SetEnabled(state[stateKey] ~= nil) end
	end

	local function UpdateColor(value)
		state[stateKey] = value
		UpdateSwatch()
		self:UpdateIconControls()
		self:MarkDraft()
	end

	if isIconColor then
		resetButton = CreateTextAction(row, L("FRIEND_TAGS_EDITOR_RESET", "Reset"), function()
			self:CancelColorEdit()
			UpdateColor(nil)
		end)
		resetButton:SetPoint("RIGHT", button, "LEFT", -8, 0)
		row.label:SetPoint("RIGHT", resetButton, "LEFT", -8, 0)
	end
	UpdateSwatch()

	button:SetScript("OnClick", function()
		local picker = ColorPickerFrame
		if not (picker and BFL.ShowColorPicker) or self.colorEdit then return end

		local original = state[stateKey]
		local color = CopyColor(original, fallback)
		local edit = {}
		self.colorEdit = edit
		local function PreviewColor(value)
			if self.colorEdit ~= edit or self.editState ~= state then return end
			UpdateColor(value)
		end
		edit.restore = function() PreviewColor(original) end

		if not self.colorPickerHooked then
			self.colorPickerHooked = true
			picker:HookScript("OnHide", function()
				local closingEdit = self.colorEdit
				if not closingEdit then return end
				-- Classic can call Cancel after hiding the picker. Keep Apply
				-- disabled through that callback and Retail's outside click.
				C_Timer.After(0, function()
					if self.colorEdit ~= closingEdit then return end
					self.colorEdit = nil
					self:UpdateDraftControls()
				end)
			end)
		end
		BFL.ShowColorPicker(color.r, color.g, color.b, color.a or 1, function(r, g, b, a)
			PreviewColor({ r = r, g = g, b = b, a = a or 1 })
		end, edit.restore)
		edit.cancelFunc = picker.cancelFunc
		self:UpdateDraftControls()
	end)
end

function FriendTagEditor:CancelColorEdit()
	local edit = self.colorEdit
	if not edit then return end
	-- A hidden picker has already accepted the preview or restored the old color.
	local picker = ColorPickerFrame
	if picker and picker:IsShown() and picker.cancelFunc == edit.cancelFunc then
		edit.restore()
		picker:Hide()
	end
	self.colorEdit = nil
	self:UpdateDraftControls()
end

function FriendTagEditor:CreateVisibilityControls(parent)
	local state = self.editState
	local entries = {
		{ "visible", L("FRIEND_TAGS_EDITOR_VISIBLE", "Show Tag"), L("FRIEND_TAGS_EDITOR_VISIBLE_DESC", "Show or hide this tag everywhere. Your choices below are kept.") },
		{ "rowVisible", L("FRIEND_TAGS_EDITOR_ROW_VISIBLE", "Friends List"), L("FRIEND_TAGS_EDITOR_ROW_VISIBLE_DESC", "Show this tag next to friends in the list.") },
		{ "tooltipVisible", L("FRIEND_TAGS_EDITOR_TOOLTIP_VISIBLE", "Tooltips"), L("FRIEND_TAGS_EDITOR_TOOLTIP_VISIBLE_DESC", "Show this tag in friend tooltips.") },
		{ "brokerVisible", L("FRIEND_TAGS_EDITOR_BROKER_VISIBLE", "Broker"), L("FRIEND_TAGS_EDITOR_BROKER_VISIBLE_DESC", "Show this tag in the Data Broker tooltip.") },
	}
	local surfaces = {}
	local function UpdateSurfaces()
		for _, surface in ipairs(surfaces) do
			surface.checkBox:SetEnabled(state.visible)
			surface:SetAlpha(state.visible and 1 or 0.55)
		end
	end
	for index, entry in ipairs(entries) do
		local key, title, description = unpack(entry)
		local row = BFL.SettingsComponents:CreateCheckbox(parent, title, state[key], function(checked)
			state[key] = checked == true
			if index == 1 then UpdateSurfaces() end
			self:MarkDraft()
		end)
		self:BindHelp(row, row.checkBox, title, description, index > 2 and "status" or nil)
		self:AddEditorRow(row)
		if index > 1 then surfaces[#surfaces + 1] = row end
	end
	UpdateSurfaces()
end

function FriendTagEditor:CreateActionButtons(parent)
	self.applyButton = CreateSmallButton(parent, L("FRIEND_TAGS_EDITOR_APPLY", "Apply"), 90, function() self:CommitState() end, 24)
	self.applyButton:SetPoint("BOTTOMRIGHT")
	self.discardButton = CreateTextAction(parent, L("FRIEND_TAGS_EDITOR_DISCARD", "Discard"), function() self:DiscardDraft() end)
	self.discardButton:SetPoint("RIGHT", self.applyButton, "LEFT", -10, 0)
	self.draftStatus = CreateFont(parent, "BetterFriendlistFontHighlightSmall")
	self.draftStatus:SetPoint("TOPLEFT")
	self.draftStatus:SetPoint("RIGHT")
	self.draftStatus:SetJustifyH("LEFT")
	local frame = self.frame
	frame.resetTag, frame.removeTag = self:CreateTagActions(frame.rightPane, function() return self.selectedTagId end)
	frame.removeTag:SetPoint("TOPRIGHT", -8, -28)
end

function FriendTagEditor:ConfirmDelete(tagId)
	local FriendTags = GetFriendTags()
	local def = FriendTags and FriendTags:GetTagDefinition(tagId or self.selectedTagId)
	if not def then
		return
	end
	if def.source == "blizzard" then
		return StaticPopup_Show("BFL_FRIEND_TAG_EDITOR_REMOVE_BLIZZARD", def.name or def.id, nil, { tagId = def.id, blizzard = true })
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

function FriendTagEditor:HasDraftChanges(def, state)
	return not SameState(state, BuildState(def))
end

function FriendTagEditor:UpdateDraftControls()
	local dirty = self.drafts[self.selectedTagId] ~= nil
	if self.applyButton then self.applyButton:SetEnabled(dirty and not self.colorEdit) end
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
	self.previewSaved = false
	if self.fieldErrorTarget then
		self.fieldError:Hide()
		self.fieldErrorTarget = nil
		self:LayoutEditorRows()
	end
	self:UpdateDraftControls()
	self:RefreshPreview()
end

function FriendTagEditor:DiscardDraft()
	self:CancelColorEdit()
	self.drafts[self.selectedTagId] = nil
	self:Refresh()
end

function FriendTagEditor:ShowDraftError(text, field)
	local box = field == "icon" and self.iconInput or self.nameInput
	if box and self.dynamicEditorContent then
		self.fieldError = self.fieldError or CreateFont(self.dynamicEditorContent, "BetterFriendlistFontHighlightSmall")
		self.fieldError:SetTextColor(1, 0.40, 0.35)
		self.fieldError:SetJustifyH("LEFT")
		self.fieldError:SetText(text)
		self.fieldError:Show()
		self.fieldErrorTarget = box:GetParent()
		self:LayoutEditorRows()
		local top, target = self.dynamicEditorContent:GetTop(), self.fieldErrorTarget:GetTop()
		local scroll = self.frame.detailScroll
		if top and target then
			scroll:SetVerticalScroll(math.min(scroll:GetVerticalScrollRange(), math.max(0, top - target - 5)))
		end
	elseif self.draftStatus then
		self.draftStatus:SetText(text)
		self.draftStatus:SetTextColor(1, 0.32, 0.28)
	end
end

local function BuildDraftPatch(self, def, state)
	if state.iconMode == "custom" and state.customIconPath == "" then
		return nil, L("FRIEND_TAGS_EDITOR_ICON_PATH_REQUIRED", "Enter an icon path or choose Remove Icon.")
	end
	local name = def.source == "custom" and state.name ~= def.name and state.name or nil
	local customLabel = state.labelMode == "custom" and state.labelValue ~= ""
	local chipLabel = state.labelMode == "icon_only" and "" or (customLabel and state.labelValue or false)
	local section
	if state.section ~= def.chipProfile.section then section = state.section or false end

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
		iconColor = state.iconColor or false,
		section = section,
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
	if self.colorEdit then return false end
	local FriendTags = GetFriendTags()
	local def = self:GetSelectedDefinition()
	local state = self.editState
	if not (FriendTags and def and state and self.drafts[def.id]) or state.tagId ~= def.id then
		return false
	end
	local patch, message = BuildDraftPatch(self, def, state)
	if not patch then
		self:ShowDraftError(message, "icon")
		return false
	end

	local saved, reason = FriendTags:SetChipProfile(def.id, patch, function()
		self.drafts[def.id] = nil
		self:RefreshAfterDefinitionChange("apply")
		self:ScrollTagIntoView(def.id)
	end)
	if not saved then
		self:ShowDraftError(GetDraftSaveError(reason))
	end
	return saved == true
end

function FriendTagEditor:CommitAllDrafts()
	if self.colorEdit then return false end
	local FriendTags = GetFriendTags()
	if not FriendTags then return false end
	local patches = {}
	for tagId, state in pairs(self.drafts) do
		local def = FriendTags:GetTagDefinition(tagId)
		if def then
			local patch, message = BuildDraftPatch(self, def, state)
			if not patch then
				self:Show(tagId)
				self:ShowDraftError(message, "icon")
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
		self:Show(invalidTagId)
		self:ShowDraftError(GetDraftSaveError(reason))
	end
	return saved == true
end

function FriendTagEditor:Reset()
	self:CancelColorEdit()
	local def = self:GetSelectedDefinition()
	if def and self.editState then
		local defaults = BuildState(def, true)
		defaults.name = self.editState.name
		defaults.section = self.editState.section
		self.editState = defaults
		self:MarkDraft()
		self:RefreshEditor()
		if self.draftStatus and self.drafts[def.id] then
			self.draftStatus:SetText(L("FRIEND_TAGS_EDITOR_RESET_PREVIEW", "Defaults previewed. Apply to save."))
		end
	end
end

return FriendTagEditor
