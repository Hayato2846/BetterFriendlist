-- The PowerShell runner supplies the fixture, width and optional hint or editor scene.
-- Load through wow-sim --exec-lua only. This file is excluded from the addon package.
assert(A_Admin and A_Admin.SetManualClock and A_Admin.AdvanceTime, "WoW UI Simulator is required")
local slash = assert(SlashCmdList.BETTERFRIENDLIST, "BetterFriendlist did not register /bfl")
local preview = assert(BFL:GetModule("PreviewMode"))
local settings = assert(BFL:GetModule("FrameSettings"))
local frame = assert(BetterFriendsFrame)
local profileID, profileDefinition = preview:GetProfileDefinition(profile)
assert(profileDefinition, "Unknown BFL preview profile: " .. profile)

A_Admin.SetManualClock(GetTime())
if hintStyle then
	local friendsUI = assert(BFL:GetModule("FriendsUI"))
	assert(friendsUI:SetStyle(hintStyle) and friendsUI:GetAppliedStyle() == hintStyle,
		"Could not switch the simulator friends window to " .. hintStyle)
end
local layout = settings:GetLayoutKey()
local defaultWidth, height = settings:GetDefaultSize(layout)
-- Let the production size handler clamp the narrow variant to its supported minimum.
settings:ApplySize(narrow and 1 or defaultWidth, height)
slash("preview " .. profile)
for _ = 1, 160 do
	if not preview.activationInProgress then
		break
	end
	A_Admin.AdvanceTime(0.016)
end
assert(preview.activeProfile == profileID and not preview.activationInProgress and not preview.activationTrace,
	"BFL preview did not finish: " .. profile)
assert(frame:IsVisible(), "BFL friends frame is hidden")
assert(not narrow or frame:GetWidth() < defaultWidth, "Narrow capture did not shrink the frame")
if profileDefinition.section then
	assert(preview.activeSection == profileDefinition.section, "BFL preview did not open " .. profileDefinition.section)
end

frame:ClearAllPoints()
frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 40, -32)
for _ = 1, 8 do
	A_Admin.AdvanceTime(0.016)
end

local function restoreCardAlignment(parent)
	if not parent:IsVisible() then
		return
	end
	-- These fields together identify the visible friend cards. Their star anchors stay as rendered.
	if parent.Name and parent.Info and parent.favoriteIcon then
		for _, key in ipairs(leftAlignedFields) do
			local text = parent[key]
			if text:GetJustifyH() == "CENTER" then
				text:SetJustifyH("LEFT")
			end
		end
	end
	for _, child in ipairs({ parent:GetChildren() }) do
		restoreCardAlignment(child)
	end
end

if layout == "RetailModern" and #leftAlignedFields > 0 then
	restoreCardAlignment(frame)
end

if hintStyle then
	assert(BFL:GetModule("NicknameHints")):ShowPreview()
	local hints = assert(BFL:GetModule("FeatureHints"))
	local badge = assert(hints.frame)
	if hintExpanded then badge.more:Click() end
	for _ = 1, 8 do A_Admin.AdvanceTime(0.016) end

	assert(badge:IsVisible() and badge.modern == (hintStyle == "modern"), "Incorrect nickname hint style")
	assert(badge.details:IsVisible() == hintExpanded and not badge.pager:IsVisible(), "Incorrect nickname hint state")
	local scale = badge:GetEffectiveScale()
	local function Edge(region, method)
		return region[method](region) * region:GetEffectiveScale() / scale
	end
	local bounds = hints:GetDockBounds()
	assert(math.abs(badge:GetTop() - Edge(frame, "GetTop")) < 1, "The nickname hint title is misaligned")
	assert(math.abs(badge:GetLeft() - Edge(frame, "GetRight")) < 1, "The nickname hint is no longer docked")
	if hintExpanded and hintStyle == "modern" then
		assert(bounds.tabRight and bounds.tabTop, "The Modern scene has no visible side tabs")
		assert(Edge(badge.details, "GetLeft") >= bounds.tabRight, "The detail area overlaps the side tabs")
		local _, shelf, inner = unpack(badge.nativeBorderClips)
		local gap = Edge(shelf, "GetBottom") - bounds.tabTop
		local transparentGutter = BFL.IsForever and 5 or 2
		assert(gap >= -0.5 and Edge(inner, "GetLeft") >= bounds.tabRight - transparentGutter - 0.5,
			"The native frame overlaps visible side-tab art")
		assert(not inner:IsMouseEnabled(), "The decorative frame intercepts side-tab clicks")
		local shelfMarker = CreateFrame("Frame", "BFLUISimNicknameShelf", frame)
		shelfMarker:SetSize(1, 1)
		shelfMarker:SetPoint("BOTTOMLEFT", shelf, "BOTTOMLEFT")
		shelfMarker:Hide()
	elseif hintExpanded then
		assert(math.abs(Edge(badge.details, "GetLeft") - badge:GetLeft()) < 1, "Legacy details do not align with the card")
	end
	if hintExpanded then
		assert(math.abs(Edge(badge.details, "GetRight") - badge:GetRight()) < 1, "The hint's right edge splits on expansion")
	end
	if hintFade then
		badge.elapsed = badge.displaySeconds
		A_Admin.AdvanceTime(0.5)
		assert(badge:IsVisible() and math.abs(badge:GetAlpha() - 0.5) < 0.05, "The hint is not midway through its fade")
	end
end

if tagScene == "normal" or tagScene == "settings" then
	local friendsUI = BFL:GetModule("FriendsUI")
	friendsUI:SetStyle("modern")
	BFL:GetModule("ThemeManager"):SetTheme("blizzard", "tag-editor-settings-reference")
	assert(friendsUI:IsModernActive(), "The settings comparison requires the Modern layout")
end

local germanTagScene = tagScene == "narrow-dark-de" or tagScene == "settings-dark-de"
local customTagScene = tagScene == "custom" or tagScene == "custom-picker"
if customTagScene then
	BFL:GetModule("FriendsUI"):SetStyle("modern")
	BFL:GetModule("ThemeManager"):SetTheme("custom", "tag-editor-settings-reference")
end
if germanTagScene then
	BFL:SetLocale("deDE")
	BFL:GetModule("ThemeManager"):SetTheme("dark", "tag-editor-settings-reference")
end
if tagScene == "settings" or tagScene == "settings-dark-de" then
	BFL:GetModule("Settings"):ShowLegacy()
	BFL:GetModule("LegacySettingsReview"):Navigate("tags")
	frame = assert(BetterFriendlistSettingsFrame)
	frame:ClearAllPoints()
	frame:SetPoint("CENTER", UIParent, "CENTER")
	if germanTagScene then
		assert(frame.BFL_DarkBackdrop:IsShown(), "Settings are missing their Dark background")
	else
		assert(frame.BFL_ModernSettingsBackgrounds.body:IsShown(), "Settings are missing their Modern background")
	end
elseif tagScene then
	local tags = assert(BFL:GetModule("FriendTags"))
	local editor = assert(BFL:GetModule("FriendTagEditor"))
	local german = germanTagScene
	local id = assert(tags:CreateCustomTag(german and "Gemeinsame Schlachtzugsabende" or "Raid Nights"))
	local otherId = assert(tags:CreateCustomTag("Dungeons Together"))
	local textOnlyId
	if tagScene == "normal" then
		textOnlyId = assert(tags:CreateCustomTag("Text Only"))
		assert(tags:SetChipProfile(textOnlyId, { replaceIcon = true, iconMode = "none", iconType = "none", iconValue = false }))
	end
	editor:Show(id)
	frame = editor.frame
	frame:ClearAllPoints()
	frame:SetPoint("CENTER", UIParent, "CENTER")
	if tagScene == "narrow" or german then
		frame:SetSize(german and 490 or 660, 570)
	elseif tagScene == "stacked" then
		frame:SetWidth(850)
	end
	if frame.previewPane then
		-- Drive the size handler explicitly because the simulator may defer OnSizeChanged for scripted resizes.
		if tagScene ~= "normal" then frame:GetScript("OnSizeChanged")(frame, frame:GetWidth(), frame:GetHeight()) end
		for _ = 1, 4 do A_Admin.AdvanceTime(0.016) end
		assert(editor.selectedTagId == id and editor.preview.widgets[1], "The editor did not render the selected tag")
		assert(editor.preview.widgets[1]:IsMouseEnabled() == false, "The preview row is interactive")
		-- Scripted SetText does not dispatch the edit-box hook in the simulator.
		editor:SetFilter("nothing matches")
		assert(#frame.tagRows == 0 and editor.selectedTagId == id, "Filtering changed the current tag")
		editor:SetFilter("")
		assert(#frame.tagRows > 0, "Clearing search did not restore the tag list")
		local sectionRow = frame.sectionRows[1]
		local openCount = #frame.tagRows
		assert(sectionRow.toggle:GetHeight() >= 24 and sectionRow.labelButton:GetWidth() > 40,
			"Section expansion has no usable arrow and label targets")
		assert(sectionRow.toggle.actionLabel == BFL.L.FRIEND_TAGS_EDITOR_SECTION_COLLAPSE, "The expanded section has no localized hover text")
		sectionRow.toggle:GetScript("OnEnter")(sectionRow.toggle)
		sectionRow.toggle:GetScript("OnLeave")(sectionRow.toggle)
		sectionRow.labelButton:Click()
		assert(#frame.tagRows < openCount, "Clicking a section name did not collapse it")
		assert(sectionRow.toggle.actionLabel == BFL.L.FRIEND_TAGS_EDITOR_SECTION_EXPAND, "The collapsed section has no localized hover text")
		sectionRow.toggle:GetScript("OnEnter")(sectionRow.toggle)
		sectionRow.toggle:GetScript("OnLeave")(sectionRow.toggle)
		sectionRow.toggle:Click()
		assert(#frame.tagRows == openCount, "Clicking the arrow did not expand the section")
		for _, header in ipairs(frame.sectionRows) do
			if header.section.id == tags:GetChipProfile(id).section then
				header.visibility:Click()
				assert(editor.selectedTagId == id and editor.preview.empty:GetText() == BFL.L.FRIEND_TAGS_EDITOR_PREVIEW_HIDDEN,
					"Hiding a section changed selection or left its preview visible")
				header.visibility:Click()
				assert(editor.selectedTagId == id and editor.preview.empty:GetText() == "", "Showing the section did not restore its preview")
				break
			end
		end
		local saved = tags:GetChipProfile(id).rowVisible
		editor.editState.rowVisible = false
		editor:MarkDraft()
		assert(tags:GetChipProfile(id).rowVisible == saved, "Preview wrote to the profile")
		assert(editor.preview.empty:GetText() == BFL.L.FRIEND_TAGS_EDITOR_PREVIEW_HIDDEN, "The preview did not show the hidden state")
		editor.editState.rowVisible = saved
		editor:MarkDraft()
		assert(frame.leftPane:IsShown() == (frame:GetWidth() >= 720), "The tag sidebar has the wrong compact layout")
		if german then
			assert(frame.BFL_DarkBackdrop:IsShown(), "Tag Editor is missing the shared Dark background")
			assert(frame.resetTag.Icon:IsVisible() and frame.resetTag.Icon:GetAlpha() > 0
				and frame.removeTag.Icon:IsVisible() and frame.removeTag.Icon:GetAlpha() > 0,
				"The Dark theme hid the compact tag actions")
		end
		if tagScene == "normal" then
			local textOnlyRow
			for _, row in ipairs(frame.tagRows) do if row.tagId == textOnlyId then textOnlyRow = row; break end end
			assert(textOnlyRow and not textOnlyRow.icon:IsShown(), "The text-only tag still has an icon")
			local _, relativeTo, _, offset = textOnlyRow.name:GetPoint(1)
			assert(relativeTo == textOnlyRow and offset == 24, "The text-only tag still reserves an empty icon slot")
			assert(frame.BFL_ModernSettingsBackgrounds.body:IsShown(), "Tag Editor is missing the shared Settings background")
			assert(frame.BFL_ModernSettingsBackgrounds.navigationDivider:IsShown(), "Tag Editor has no navigation divider")
			assert(editor.visibilityHeader.BFL_SectionDivider:IsShown(), "Visibility has no section divider")
			assert(frame.createSection:IsVisible() and not frame.restoreTags:IsShown(), "List actions show the wrong availability")
			local firstSection = frame.sectionRows[1]
			firstSection.visibility:Click()
			assert(firstSection.section.hidden and firstSection.visibility.actionLabel == BFL.L.FRIEND_TAGS_EDITOR_SECTION_SHOW,
				"The section's visibility action did not hide it")
			firstSection.visibility:Click()
			assert(not firstSection.section.hidden, "The section's visibility action did not show it")
			local removedId = frame.tagRows[1].tagId
			assert(tags:SetBlizzardTagRemoved(removedId, true), "The fixture could not remove a Blizzard tag")
			editor:RefreshList()
			assert(frame.restoreTags:IsVisible(), "Restore is missing when a removed tag exists")
			local openMenu = BFL.OpenSimpleContextMenu
			BFL.OpenSimpleContextMenu = function(owner, _, items)
				assert(owner == frame.restoreTags and #items == 1, "Restore did not list the removed tag directly")
				items[1].func()
			end
			frame.restoreTags:Click()
			BFL.OpenSimpleContextMenu = openMenu
			assert(not frame.restoreTags:IsShown() and tags:GetTagDefinition(removedId), "The removed tag was not restored")
			editor:Show(otherId)
			local otherSaved = tags:GetChipProfile(otherId).rowVisible
			editor.editState.rowVisible = not otherSaved
			editor:MarkDraft()
			assert(editor.drafts[otherId], "The second tag has no draft to reset")
			editor:Show(id)
			local otherRow
			for _, row in ipairs(frame.tagRows) do if row.tagId == otherId then otherRow = row; break end end
			assert(otherRow and otherRow.reset:IsVisible() and otherRow.remove:IsVisible(),
				"The unselected tag has no direct actions")
			editor.editState.name = "Unsaved Raid Nights"
			editor:MarkDraft()
			local activeDraft = assert(editor.drafts[id])
			local popup, popupData
			local showPopup = StaticPopup_Show
			local showInput = BFL.ShowInputDialog
			StaticPopup_Show = function(dialog, _, _, data) popup, popupData = dialog, data end
			BFL.ShowInputDialog = StaticPopup_Show
			otherRow.remove:Click()
			assert(popup == "BFL_FRIEND_TAG_EDITOR_DELETE_CUSTOM" and popupData.tagId == otherId and editor.selectedTagId == id,
				"The unselected tag's Delete did not target its own tag")
			frame.createSection:Click()
			assert(popup == "BFL_FRIEND_TAG_EDITOR_CREATE_SECTION", "Create Section did not open directly")
			local sectionRow = frame.sectionRows[1]
			sectionRow.delete:Click()
			assert(popup == "BFL_FRIEND_TAG_EDITOR_DELETE_SECTION" and popupData == sectionRow.section.id,
				"Delete Section did not target its row")
			StaticPopup_Show = showPopup
			BFL.ShowInputDialog = showInput
			assert(editor.drafts[id] == activeDraft and editor.editState.name == "Unsaved Raid Nights",
				"Opening a confirmation changed the current draft")
			otherRow.reset:Click()
			assert(editor.selectedTagId == otherId and editor.editState.rowVisible == otherSaved,
				"The unselected tag's Reset did not reset its own draft")
			assert(editor.drafts[id] and editor.drafts[id].name == "Unsaved Raid Nights", "Reset lost the previous draft")
			editor:Show(id)
			editor:DiscardDraft()
		end
		local first = frame.tagRows[1]
		assert(first:GetLeft() > frame.listContent:GetLeft(), "Tags must remain indented")
		editor:BeginDrag(first, frame.tagRows, first.sectionFirst, first.sectionLast)
		assert(editor.dragState and editor.dragState.ghost:IsShown(), "Dragging a tag did not show the ghost")
		local ghost = editor.dragState.ghost
		editor:CancelDrag()
		assert(not ghost:IsShown(), "Canceling the drag left the ghost visible")
		if frame.back:IsShown() then
			frame.back:Click()
			assert(frame.leftPane:IsShown() and not frame.rightPane:IsShown(), "Back did not restore the tag list")
			for _, row in ipairs(frame.tagRows) do if row.tagId == id then row:Click(); break end end
			assert(frame.rightPane:IsShown() and editor.selectedTagId == id, "The selected tag did not reopen")
		end
		if customTagScene or german then
			local engine = BFL:GetModule("SkinEngine")
			local function CheckEditorSkin()
				local dropdown
				for _, row in ipairs(editor.editorRows) do
					if row.DropDown then dropdown = row.DropDown; break end
				end
				assert(dropdown and math.abs(editor.nameInput:GetLeft() - dropdown:GetLeft()) < 0.5
					and math.abs(editor.nameInput:GetRight() - dropdown:GetRight()) < 0.5,
					"The Name field does not align with the settings control column")
				local left, right = editor.nameInput:GetTextInsets()
				assert(left >= 4 and right >= 4, "The Name text touches its border")
				assert(editor.nameInput.BFL_DarkBackdrop:IsShown() and editor.nameInput.Left:GetAlpha() == 0,
					"The custom tag name still uses native input artwork")
				assert(frame.CloseButton:IsShown() and frame.CloseButton.BFL_DarkIcon,
					"The Tag Editor does not use the shared close icon")
				for _, row in ipairs(editor.editorRows) do
					if row.checkBox then assert(row.checkBox.BFL_DarkBackdrop:IsShown(), "A visibility control lost its theme") end
				end
				for _, button in ipairs({ frame.createSection, frame.resetTag, frame.removeTag,
					frame.sectionRows[1].visibility, frame.sectionRows[1].delete, frame.tagRows[1].reset, frame.tagRows[1].remove }) do
					assert(button.BFL_DarkIcon == button.Icon and button.Icon:GetAlpha() > 0,
						"A list action bypasses the theme icon renderer")
					local _, _, _, alpha = button.BFL_DarkBackdrop:GetBackdropColor()
					assert(alpha == 0, "A compact action has an opaque backdrop")
					engine:ApplyButtonState(button, "hover")
					assert(button.BFL_DarkInteractionState == "hover", "An action lost its hover state")
					engine:ApplyButtonState(button, "down")
					engine:ApplyButtonState(button)
				end
			end
			CheckEditorSkin()
			BFL:GetModule("ThemeManager"):SetTheme("blizzard", "tag-editor-restoration")
			assert(not editor.nameInput.BFL_DarkBackdrop:IsShown() and editor.nameInput.Left:GetAlpha() > 0,
				"Leaving the theme did not restore the native Name field")
			BFL:GetModule("ThemeManager"):SetTheme(customTagScene and "custom" or "dark", "tag-editor-restoration")
			CheckEditorSkin()
		end
	end
	if tagScene == "tag-picker" or tagScene == "custom-picker" then
		editor.iconSelectButton:Click()
		local picker = BFL:GetModule("IconSelector")
		frame = picker.frame
		assert(frame:IsShown() and frame.customPath:IsShown(), "The picker has no visible custom path option")
		local path = [[Interface\Icons\INV_Misc_QuestionMark]]
		frame.customPath:SetText(path)
		picker:ConfirmCustomPath()
		assert(editor.editState.iconMode == "custom" and editor.editState.customIconPath == path and editor.drafts[id],
			"Custom path did not update the draft")
		assert(tags:GetChipProfile(id).iconValue ~= editor.editState.customIconPath, "Custom path saved before Apply")
		editor.iconSelectButton:Click()
		-- The simulator has no native macro-icon catalog. Keep the production
		-- picker and scrolling logic, supplying enough real BFL icons to overflow.
		local getBlizzardIcons, catalog = picker.GetBlizzardIcons, {}
		local samples = picker:GetBFLIcons()
		assert(#samples > 0, "The picker fixture has no sample icons")
		for index = 1, 180 do catalog[index] = samples[(index - 1) % #samples + 1] end
		picker.GetBlizzardIcons = function() return catalog end
		frame.blizzardButton:Click()
		for _ = 1, 10 do A_Admin.AdvanceTime(0.016) end
		local bar = frame.scroll.ScrollBar
		local scrollbarStyle = BFL:GetModule("ScrollbarStyle")
		local function CheckPickerScrollbar()
			assert(scrollbarStyle:IsModern(bar) and scrollbarStyle.bars[bar]
				and scrollbarStyle.bars[bar].owner == frame.inner, "The picker is not using its registered modern scrollbar")
			assert(bar:GetWidth() == 8 and not bar.BFL_DarkScrollBarSkinned, "The picker scrollbar was rebuilt by a skin")
			local r, g, b = BFL:GetThemeAccentColor()
			for _, widget in ipairs({ bar:GetThumb(), bar.Back, bar.Forward }) do
				assert(not widget.BFL_DarkBackdrop or not widget.BFL_DarkBackdrop:IsShown(), "A picker scrollbar part has replacement chrome")
				if BFL:GetEffectiveTheme() ~= "blizzard" then
					local texture = widget.Texture or widget.Middle
					local tr, tg, tb = texture:GetVertexColor()
					if widget:IsEnabled() then
						assert(math.abs(tr-r) < 0.001 and math.abs(tg-g) < 0.001 and math.abs(tb-b) < 0.001, "The picker scrollbar lost its accent")
					else
						assert(tr == 1 and tg == 1 and tb == 1 and texture:IsDesaturated(), "A disabled picker arrow retained an accent")
					end
				end
			end
		end
		assert(bar:IsShown() and frame.scroll:GetVerticalScrollRange() > 0, "The icon catalog has no scrollable content")
		bar:SetScrollPercentage(0)
		assert(not bar.Back:IsEnabled() and bar.Forward:IsEnabled(), "The picker top arrow states are wrong")
		CheckPickerScrollbar()
		bar:SetScrollPercentage(1)
		assert(bar.Back:IsEnabled() and not bar.Forward:IsEnabled(), "The picker bottom arrow states are wrong")
		CheckPickerScrollbar()
		frame.search:SetText("no-icon-matches-this-search")
		frame.search:GetScript("OnTextChanged")(frame.search)
		for _ = 1, 10 do A_Admin.AdvanceTime(0.016) end
		assert(not bar:IsShown() and frame.scroll:GetVerticalScroll() == 0,
			string.format("Searching left an empty picker scrolled or its scrollbar visible: shown=%s, offset=%.2f, range=%.2f, height=%.2f, content=%.2f",
				tostring(bar:IsShown()), frame.scroll:GetVerticalScroll(), frame.scroll:GetVerticalScrollRange(), frame.scroll:GetHeight(), frame.content:GetHeight()))
		frame.search:SetText("")
		frame.search:GetScript("OnTextChanged")(frame.search)
		for _ = 1, 10 do A_Admin.AdvanceTime(0.016) end
		assert(bar:IsShown(), "Clearing search did not restore the native scrollbar")
		frame.scroll:GetScript("OnMouseWheel")(frame.scroll, -1)
		assert(frame.scroll:GetVerticalScroll() > 0, "The picker no longer scrolls with the mouse wheel")
		bar:SetScrollPercentage(0)
		if customTagScene then
			local function CheckPickerSkin()
				CheckPickerScrollbar()
				assert(frame.BFL_DarkBackdrop:IsShown() and frame.inner.BFL_DarkBackdrop:IsShown(), "The picker shell is unskinned")
				assert(frame.search.BFL_DarkBackdrop:IsShown() and frame.customPath.BFL_DarkBackdrop:IsShown(), "Picker inputs are unskinned")
				assert(frame.close.BFL_DarkBackdrop:IsShown() and frame.customApply.BFL_DarkBackdrop:IsShown(), "Picker buttons are unskinned")
				assert(frame.CloseButton.BFL_DarkIcon:GetTexture() == editor.frame.CloseButton.BFL_DarkIcon:GetTexture(),
					"The picker and editor use different close artwork")
				assert(frame.buttons[1].BFL_DarkBackdrop:IsShown() and frame.buttons[1].icon:GetAlpha() > 0,
					"Picker cell styling hid the icon")
			end
			CheckPickerSkin()
			BFL:GetModule("ThemeManager"):SetTheme("blizzard", "picker-restoration")
			assert(not frame.BFL_DarkBackdrop:IsShown() and frame.search.Left:GetAlpha() > 0,
				"Leaving the theme did not restore the native picker")
			BFL:GetModule("ThemeManager"):SetTheme("custom", "picker-restoration")
			CheckPickerSkin()
		end
		picker.GetBlizzardIcons = getBlizzardIcons
	end
end


if feedbackScene then
	local db = BFL:GetModule("DB")
	local settingsUI = BFL:GetModule("Settings")
	local review = BFL:GetModule("LegacySettingsReview")
	local themes = BFL:GetModule("ThemeManager")
	if feedbackScene == "window-fonts" or feedbackScene == "input" or feedbackScene == "scroll"
		or ((feedbackScene == "filters" or feedbackScene == "diagnostics" or feedbackScene == "diagnostics-warning"
			or feedbackScene == "behavior") and narrow) then BFL:SetLocale("deDE") end
	local function Advance()
		for _ = 1, 10 do A_Admin.AdvanceTime(0.016) end
	end
	local function FindRow(label)
		for _, row in ipairs(review.controlRows or {}) do
			for _, name in ipairs(row.BFL_SearchLabels or {}) do
				if name == label then return row end
			end
		end
		error("Missing setting row " .. tostring(label))
	end
	local function FindButton(parent, text)
		if parent:IsVisible() and parent.GetText and parent:GetText() == text and parent:IsObjectType("Button") then return parent end
		for _, child in ipairs({ parent:GetChildren() }) do
			if child:IsVisible() then
				local button = FindButton(child, text)
				if button then return button end
			end
		end
	end

	BFL:GetModule("FriendsUI"):SetStyle("modern")
	if feedbackScene == "groups" then
		db:Set("showFavoritesGroup", false)
		db:Set("enableInGameGroup", true)
		db:Set("hideEmptyGroups", true)
		db:Set("enableRecentlyAddedGroup", false)
	elseif feedbackScene == "format" then
		db:Set("nameFormatPreset", "custom")
		db:Set("infoFormatPreset", "custom")
	elseif feedbackScene == "performance" or feedbackScene == "filters" or feedbackScene == "diagnostics"
		or feedbackScene == "diagnostics-warning" or feedbackScene == "behavior" then
		db:Set("enableBetaFeatures", true)
		db:Set("settingsWindowSize", narrow and { width = 760, height = 620 } or { width = 1170, height = 800 })
	elseif feedbackScene == "skin-tabs" then
		db:Set("enableBetaFeatures", true)
	elseif feedbackScene == "scale" then
		db:Set("settingsWindowSize", narrow and { width = 760, height = 620 } or { width = 1170, height = 800 })
		BetterFriendsFrame:SetSize(410, 400)
	elseif feedbackScene == "scrollbars" then
		db:Set("settingsWindowSize", narrow and { width = 760, height = 620 } or { width = 1170, height = 800 })
		db:Set("customTheme", { accentColor = { r = 0.1, g = 0.8, b = 0.65, a = 1 } })
	elseif feedbackScene == "scroll" or feedbackScene == "skin-hover" then
		db:Set("settingsWindowSize", narrow and { width = 760, height = 620 } or { width = 1170, height = 800 })
	end
	themes:SetTheme(feedbackScene == "groups" and "blizzard" or "custom", "settings-feedback-fixture")
	if feedbackScene == "groups" then
		local list, tags = BFL:GetModule("FriendsList"), BFL:GetModule("FriendTags")
		local friend
		for _, candidate in ipairs(list.friendsList) do
			if candidate.type == "wow" then friend = candidate; break end
		end
		assert(friend, "The fixture has no ordinary WoW friend")
		db:Set("enableInGameGroup", false)
		db:SetFriendGroups(tags:GetFriendUID(friend), {})
		tags:SetSetting("enabled", true)
		tags:SetSetting("enableDynamicTagGroups", true)
		local id = assert(tags:CreateCustomTag("External Friends"))
		assert(tags:SetCustomTagForFriend(friend, id, true))
		list:UpdateSettingsCache()
		list:RenderDisplay(true)
		local target = list:GetFriendsForGroup("tag:" .. id)
		assert(#target == 1 and target[1] == friend, "The dynamic tag group lost its friend")
		for _, member in ipairs(list:GetFriendsForGroup("nogroup")) do
			assert(member ~= friend, "A tagged friend is duplicated in No Group")
		end
		assert(list:GetInvitableCount("tag:" .. id) <= #target, "The invite count uses a different group")
		local sectionID = tags:GetChipProfile(id).section
		local editor = BFL:GetModule("FriendTagEditor")
		editor:Show(id)
		Advance()
		local function SectionVisibilityButton()
			for _, header in ipairs(editor.frame.sectionRows) do
				if header.section.id == sectionID then return header.visibility end
			end
			error("The assigned tag's section has no visibility button")
		end
		local function HasDynamicGroupHeader()
			for _, entry in ipairs(list.cachedDisplayList or {}) do
				if entry.virtualTagGroup and entry.groupId == "tag:" .. id then return true end
			end
			return false
		end
		assert(HasDynamicGroupHeader(), "The fixture has no rendered dynamic group header")
		SectionVisibilityButton():Click()
		Advance()
		assert(not HasDynamicGroupHeader(), "The section button left a stale dynamic group header until another update")
		assert(#list:GetFriendsForGroup("tag:" .. id) == 0, "A hidden section still contributes dynamic group members")
		SectionVisibilityButton():Click()
		Advance()
		assert(HasDynamicGroupHeader(), "Showing a section did not restore its rendered header automatically")
		assert(#list:GetFriendsForGroup("tag:" .. id) == 1, "Showing the section lost its dynamic group")
		editor.frame:Hide()
		tags:SetSetting("enableDynamicTagGroups", false)
		list:UpdateSettingsCache()
		list:RenderDisplay(true)
		local found
		for _, member in ipairs(list:GetFriendsForGroup("nogroup")) do if member == friend then found = true end end
		assert(found, "Disabling dynamic groups did not restore the ungrouped friend")
		db:Set("enableInGameGroup", true)
	end
	settingsUI:ShowLegacy()
	frame = BetterFriendlistSettingsFrame
	frame:ClearAllPoints()
	frame:SetPoint("CENTER", UIParent, "CENTER")
	if narrow then
		frame:SetSize(760, 620)
		review:Layout()
	end

	if feedbackScene == "diagnostics" or feedbackScene == "diagnostics-warning" or feedbackScene == "behavior" then
		review:Navigate(feedbackScene == "behavior" and "behavior" or "advanced")
		Advance()
		if feedbackScene == "diagnostics-warning" then
			local row = FindRow(BFL.L.SETTINGS_SHOW_BLIZZARD)
			assert(row.checkBox, "The diagnostic setting is not a checkbox")
			row.checkBox:Click()
			Advance()
			assert(db:Get("showBlizzardOption", false) == false, "The diagnostic setting enabled before confirmation")
			assert(StaticPopup_Visible("BETTERFRIENDLIST_BLIZZARD_DIAGNOSTICS_CONFIRM"), "The diagnostic warning did not appear")
		end
	elseif feedbackScene == "groups" then
		review:Navigate("automatic")
		Advance()
		local unit = FindRow(BFL.L.SETTINGS_RECENTLY_ADDED_DURATION_UNIT)
		local value = FindRow(BFL.L.SETTINGS_RECENTLY_ADDED_DURATION_VALUE)
		assert(unit.BFL_SettingDisabled and unit:GetAlpha() <= 0.5 and not unit.DropDown:IsEnabled(),
			"An unavailable duration dropdown looks active")
		assert(value.Input:IsNumeric(), "Duration Value accepts letters")
		assert(review.previewNote:IsShown() and review.previewNote:GetText():find(BFL.L.GROUP_NO_GROUP, 1, true),
			"The preview does not name its hidden empty group")
	elseif feedbackScene == "theme" then
		review:Navigate("theme")
		Advance()
		assert(review.sectionRows.SETTINGS_THEME_CUSTOM_HEADER:IsVisible(), "Custom settings are hidden after choosing Custom")
		assert(not review.detailsOpen and review.detailsButton.label:GetText() == BFL.L.SETTINGS_THEME_BROKER_TOOLTIP_HEADER,
			"The theme's collapsed options have the wrong label")
		settingsUI:OnThemeChanged("dark")
		Advance()
		assert(review.sectionRows.SETTINGS_THEME_DARK_HEADER:IsVisible(), "Dark settings are hidden after choosing Dark")
		settingsUI:OnThemeChanged("custom")
		Advance()
	elseif feedbackScene == "format" then
		local function CheckSearchSkin()
			assert(review.search.BFL_DarkBackdrop and review.search.BFL_DarkBackdrop:IsShown()
				and review.search.Left:GetAlpha() == 0, "Settings search is missing its theme")
		end
		CheckSearchSkin()
		for _, theme in ipairs({ "blizzard", "dark", "custom" }) do
			themes:SetTheme(theme, "search-skin-fixture")
			if theme == "blizzard" then
				assert(not review.search.BFL_DarkBackdrop:IsShown() and review.search.Left:GetAlpha() > 0,
					"The native search artwork was not restored")
			else
				CheckSearchSkin()
			end
		end
		frame:Hide()
		settingsUI:ShowLegacy()
		if narrow then
			frame:SetSize(760, 620)
			review:Layout()
		end
		Advance()
		CheckSearchSkin()
		review.search:SetFocus()
		review.search:SetText("tags")
		Advance()
		CheckSearchSkin()
		review.search.clearButton:Click()
		Advance()
		assert(review.search:GetText() == "", "The skinned search cannot clear its text")
		CheckSearchSkin()
		review:Navigate("rows")
		Advance()
		CheckSearchSkin()
		local lists = 0
		for _, row in ipairs(review.controlRows) do
			if row.GetText and row:GetText() and row:GetText():find(BFL.L.SETTINGS_FORMAT_FIELDS, 1, true) then
				assert(row:GetText():find("%%name%%") or row:GetText():find("%%level%%"), "The format list has no tokens")
				lists = lists + 1
			end
		end
		assert(lists == 0, "Format fields still clutter the settings rows")
		local nameRow = FindRow(BFL.L.SETTINGS_NAME_FORMAT_TOOLTIP)
		local infoRow = FindRow(BFL.L.SETTINGS_INFO_FORMAT_TOOLTIP)
		local function ShowFields(row)
			if review.pinnedGuideID then review:ToggleSettingHelpPin(review.guideRow, 1) end
			review:ShowSettingHelp(row, 1)
			review:ToggleSettingHelpPin(row, 1)
			assert(review.formatFieldsPanel and review.formatFieldsPanel:IsVisible(), "Format fields are missing from Setting details")
		end
		ShowFields(nameRow)
		local panel = review.formatFieldsPanel
		assert(review.formatFieldsExpanded ~= true and not panel.rows[1]:IsShown(), "Format fields must start collapsed")
		panel.header:GetScript("OnClick")(panel.header)
		assert(panel.rows[1].token:GetText() == "%name%", "Name fields use the wrong reference")
		local height = panel:GetHeight()
		panel.header:GetScript("OnClick")(panel.header)
		assert(panel:GetHeight() < height and not panel.rows[1]:IsShown(), "The reference list did not collapse")
		ShowFields(infoRow)
		assert(review.formatFieldsExpanded == false and not panel.rows[1]:IsShown(), "Changing format fields forgot the collapsed state")
		panel.header:GetScript("OnClick")(panel.header)
		local nameBefore, infoBefore = db:Get("nameFormatCustom"), db:Get("infoFormatCustom")
		local tokens = {}
		for _, item in ipairs(panel.rows) do
			if item:IsShown() then
				local box, token = item.token, item.token:GetText()
				tokens[token] = true
				box:SetFocus()
				box:GetScript("OnMouseUp")(box)
				box:SetText("Attempted edit")
				A_Admin.AdvanceTime(0.016)
				assert(box:GetText() == token, "Copy token changed: expected " .. token .. ", got " .. box:GetText())
				box:ClearFocus()
			end
		end
		assert(tokens["%accounts%"] and tokens["%games%"], "Info reference is missing its extra fields")
		assert(db:Get("nameFormatCustom") == nameBefore and db:Get("infoFormatCustom") == infoBefore,
			"Copying a reference token changed a saved format")
		if narrow then ShowFields(nameRow) end
		ShowFields(narrow and infoRow or nameRow)
		review:Focus(narrow and infoRow or nameRow, narrow and infoRow or nameRow)
		Advance()
		if narrow then
			local _, _, _, _, rowY = panel.rows[1]:GetPoint(1)
			local first = panel.top - rowY
			local offset = review.hoverHelp.scroll:GetVerticalScroll()
			assert(first >= offset - 1 and first + panel.rows[1]:GetHeight() <= offset + review.hoverHelp.scroll:GetHeight() + 1,
				"The narrow details hide the first copy field below the fold")
		end
		panel.header:GetScript("OnClick")(panel.header)
		assert(not panel.rows[1]:IsShown() and not panel.hint:IsShown(), "Collapsing leaves reference content visible")
	elseif feedbackScene == "help" then
		review:Navigate("help")
		Advance()
		assert(not review.sectionRows.SETTINGS_BETA_FEATURES_TITLE and not review.sectionRows.SETTINGS_LEGACY_DIAGNOSTICS,
			"Help still contains Beta or Diagnostics")
		review:Navigate("advanced")
		Advance()
		assert(review.sectionRows.SETTINGS_BETA_FEATURES_TITLE:IsVisible()
			and review.sectionRows.SETTINGS_LEGACY_DIAGNOSTICS:IsVisible(), "Advanced lost the moved controls")
		review:Navigate("help")
		Advance()
	elseif feedbackScene == "filters" then
		review:Navigate("filters")
		Advance()
		local registry = BFL:GetModule("FilterSortRegistry")
		local function FindFilterRow(id)
			for _, row in ipairs(review.controlRows) do
				if row.BFL_SettingIdentity == "filter/" .. id then return row end
			end
			error("Missing built-in filter " .. id)
		end
		for _, id in ipairs({ "all", "online", "offline", "wowonline", "wow", "bnet", "hideafk", "retail", "forever", "ingame" }) do
			local entry = registry:ResolveQuickFilter(id, false)
			local row = FindFilterRow(id)
			assert(entry.description and row.BFL_SettingGuide[2][2]:find(entry.description, 1, true),
				"A built-in filter has no purpose in Setting details: " .. id)
			assert(not row.BFL_DarkBackdrop or not row.BFL_DarkBackdrop:IsShown(), "QuickFilter rows still have button borders")
		end
		FindFilterRow("wow"):Click()
		Advance()
		local panel = settingsUI.filterSortInlineEditorFrame
		assert(not panel:IsShown(), "Read-only built-ins still open an unnecessary editor panel")
		local row = FindFilterRow("wow")
		review:ShowSettingHelp(row, 2)
		review:ToggleSettingHelpPin(row, 2)
		assert(review.pinnedGuideID and review.guideEntry[2]:find(registry:ResolveQuickFilter("wow", false).description, 1, true),
			"The filter purpose did not pin in Setting details")
		Advance()
	elseif feedbackScene == "performance" then
		review:Navigate("automatic")
		Advance()
		local engine = BFL:GetModule("SkinEngine")
		local skinTree, scans = engine.SkinTree, 0
		engine.SkinTree = function(owner, target, ...)
			if target == frame then scans = scans + 1 end
			return skinTree(owner, target, ...)
		end
		for _, route in ipairs({ "rows", "automatic", "layout", "tags", "theme", "filters", "raid", "rows", "automatic" }) do
			review:Navigate(route)
			for _, row in ipairs(review.controlRows) do
				for _, field in ipairs({ "Input", "DropDown", "RightDropdown", "Slider", "checkBox", "LeftCheckbox" }) do
					local control = row[field]
					if control and control:IsVisible() then
						assert(control.BFL_DarkBackdrop and control.BFL_DarkBackdrop:IsShown(),
							"Unstyled " .. field .. " before the first frame on " .. route)
					end
				end
			end
			Advance()
			if route == "raid" then
				assert(review.sectionRows.SETTINGS_RAID_SHORTCUTS_TITLE:IsVisible(), "Raid Shortcuts are hidden")
			end
		end
		review:Navigate("filters")
		Advance()
		for _ = 1, 3 do
			local visibility
			for _, row in ipairs(review.controlRows) do
				if row.BFL_SettingIdentity and row.BFL_SettingIdentity:match("^filter/") then
					visibility = row.BFL_SettingSlotRects[1]
					break
				end
			end
			assert(visibility, "The QuickFilter visibility checkbox is missing")
			visibility:Click()
			Advance()
		end
		settingsUI:OnSimpleModeChanged(true)
		Advance()
		settingsUI:OnSimpleModeChanged(false)
		Advance()
		engine.SkinTree = skinTree
		assert(scans == 0, "Navigation or Simple Mode rescanned the complete Settings tree " .. scans .. " times")
	elseif feedbackScene == "window-fonts" then
		review:Navigate("windowFonts")
		Advance()
		assert(review.sectionRows.SETTINGS_WINDOW_TITLE_FONT:IsVisible(), "Window title fonts are unreachable")
		assert(review.sectionRows.SETTINGS_ACTION_BUTTON_FONT:IsVisible(), "Action button fonts are unreachable")
		local title = frame.TitleContainer.TitleText
		local originalPath, originalSize = title:GetFont()
		db:Set("fontWindowTitle", "Arial Narrow")
		db:Set("fontSizeWindowTitle", 18)
		db:Set("fontSizeActionButton", 16)
		BFL.FontManager:RefreshWindowFonts()
		local selectedPath, size = title:GetFont()
		assert(size == 18, "Changing the title font did not update the open Settings window")
		assert(selectedPath:lower():find("arialn", 1, true), "The selected title font face did not apply")
		BFL.FontManager:ResetWindowFont("WindowTitle")
		local resetPath, resetSize = title:GetFont()
		assert(resetSize == originalSize and resetPath == originalPath, "Reset did not restore the native title font")
		assert(db:Get("fontSizeActionButton") == 16, "Resetting titles changed the action-button setting")
		db:Set("fontSizeWindowTitle", 18)
		BFL.FontManager:RefreshWindowFonts()
		settingsUI:RefreshFontsTab()
		for _, row in ipairs(review.controlRows) do
			local entry = row.BFL_SettingGuide and row.BFL_SettingGuide[1]
			if entry and entry[4] and entry[4][1] == "fontSizeWindowTitle" then
				review:ShowSettingHelp(row, 1)
				review:ToggleSettingHelpPin(row, 1)
				assert(review.pinnedGuideID, "Window font help did not pin")
				local _, _, _, current = review:GetComparison()
				assert(current == 18, "The font preview does not represent the selected size")
				break
			end
		end
		assert(review.guideEntry and review.guideEntry[4].windowFont, "Window fonts have no preview")
	elseif feedbackScene == "skin-footer" then
		settingsUI:HideLegacyWindow()
		settings:ApplySize(700, 700)
		frame = BetterFriendsFrame
		local friendsUI = BFL:GetModule("FriendsUI")
		for _, theme in ipairs({ "dark", "custom", "blizzard", "custom" }) do
			themes:SetTheme(theme, "footer-regression")
			Advance()
			assert(friendsUI.root.BottomFade:IsShown() == (theme == "blizzard"), "The footer gradient has the wrong theme visibility")
			assert(friendsUI.root.TopFade:IsShown() == (theme == "blizzard"), "The header gradient has the wrong theme visibility")
		end
	elseif feedbackScene == "input-layer" then
		local editor = BFL:GetModule("FriendTagEditor")
		editor:Show()
		Advance()
		frame = assert(BFL.ShowInputDialog("BFL_FRIEND_TAG_EDITOR_CREATE_SECTION"))
		local point, parent, relative, x, y = frame:GetPoint(1)
		assert(point == "TOP" and relative == "TOP" and x == 0 and y == -135,
			"The input dialog does not match Blizzard's top anchor")
		assert(frame:GetFrameStrata() == "DIALOG" and frame:GetFrameLevel() > editor.frame:GetFrameLevel(),
			"The Section input opens behind the Tag Editor")
		assert(frame.EditBox:GetFrameLevel() > frame:GetFrameLevel() and frame.button1:GetFrameLevel() > frame:GetFrameLevel(),
			"The input controls did not rise with the private dialog")
		frame:ClearAllPoints()
		frame:SetPoint("CENTER")
		frame.button2:Click()
		frame = assert(BFL.ShowInputDialog("BFL_FRIEND_TAG_EDITOR_CREATE_SECTION"))
		point, parent, relative, x, y = frame:GetPoint(1)
		assert(point == "TOP" and y == -135, "Reopening did not restore the native dialog anchor")
	elseif feedbackScene == "skin-tabs" then
		review:Navigate("filters")
		Advance()
		for index = 1, 8 do
			themes:SetTheme(index <= 4 and "dark" or "custom", "tab-regression")
			local text = index % 2 == 1 and BFL.L.FILTER_BUILDER_SORTERS or BFL.L.FILTER_BUILDER_FILTERS
			local button = assert(FindButton(review.content, text), "Missing builder tab")
			button:GetScript("OnClick")(button)
			Advance()
			button = assert(FindButton(review.content, text))
			assert(button.BFL_DarkTabButton and BFL:GetModule("SkinEngine"):IsTabSelected(button),
				"Anonymous tab state: themed=" .. tostring(button.BFL_DarkTabButton) .. " activeArt=" .. tostring(button.LeftActive and button.LeftActive:IsShown())
				.. " id=" .. tostring(button:GetID()) .. " parentSelection=" .. tostring(button:GetParent().selectedTab))
			for _, key in ipairs({ "Left", "Middle", "Right", "LeftActive", "MiddleActive", "RightActive", "LeftHighlight", "MiddleHighlight", "RightHighlight" }) do
				assert(not button[key] or button[key]:GetAlpha() == 0, "A native tab texture bleeds through: " .. key)
			end
			local anchor, _, _, _, textY = button.Text:GetPoint(1)
			assert(anchor == "CENTER" and textY == 0, "Tab text is not centered in its themed surface")
		end
		themes:SetTheme("blizzard", "tab-native-restoration")
		Advance()
		assert(FindButton(review.content, BFL.L.FILTER_BUILDER_FILTERS).LeftActive:GetAlpha() > 0, "Restoring Blizzard lost native tab art")
		themes:SetTheme("custom", "tab-final")
		Advance()
	elseif feedbackScene == "skin-hover" then
		review:Navigate("layout")
		Advance()
		review.scroll:SetVerticalScroll(math.max(0, review.scroll.BFL_SettingsContentHeight - review.scroll:GetHeight()))
		local button = assert(FindButton(review.content, RESET), "Missing window reset action")
		local enter = button:GetScript("OnEnter")
		if enter then enter(button) end
		button:LockHighlight()
		BFL:GetModule("SkinEngine"):ApplyButtonState(button, "hover")
		assert(not button:GetHighlightTexture() or button:GetHighlightTexture():GetAlpha() == 0, "Button hover exposes native artwork")
		local scrollRow = FindRow(BFL.L.SETTINGS_WINDOW_SMOOTH_SCROLLING)
		assert(scrollRow:GetTop() > button:GetTop(), "The Reset action is still above Smooth Scrolling")
	elseif feedbackScene == "scrollbars" then
		review:Navigate("rows")
		Advance()
		review.scroll:SetVerticalScroll(0)
		Advance()
		assert(not review.scroll.ScrollBar.Back:IsEnabled() and review.scroll.ScrollBar.Forward:IsEnabled(),
			"The scrollbar fixture needs a disabled Back and an enabled Forward button")
		local bar = review.scroll.ScrollBar
		local function CheckAccent(expected)
			local r, g, b = BFL:GetThemeAccentColor()
			assert(math.abs(r-expected[1]) < 0.001 and math.abs(g-expected[2]) < 0.001 and math.abs(b-expected[3]) < 0.001,
				string.format("Expected custom accent %.2f/%.2f/%.2f, got %.2f/%.2f/%.2f (theme %s)",
					expected[1], expected[2], expected[3], r, g, b, BFL:GetEffectiveTheme()))
		end
		local function CheckColors()
			local r, g, b = BFL:GetThemeAccentColor()
			for _, widget in ipairs({ bar:GetThumb(), bar.Back, bar.Forward }) do
				local texture = widget.Texture or widget.Middle
				local tr, tg, tb = texture:GetVertexColor()
				if widget:IsEnabled() then
					assert(math.abs(tr-r) < 0.001 and math.abs(tg-g) < 0.001 and math.abs(tb-b) < 0.001,
						"An active native scrollbar part lost its accent")
				else
					assert(tr == 1 and tg == 1 and tb == 1 and texture:IsDesaturated(),
						"A disabled native arrow retained an accent tint")
				end
				assert(not widget.BFL_DarkBackdrop or not widget.BFL_DarkBackdrop:IsShown(), "A native scrollbar part was rebuilt")
			end
			assert(bar:GetWidth() == 8 and not bar.BFL_DarkScrollBarSkinned, "The native scrollbar geometry was replaced")
		end
		CheckColors()
		CheckAccent({ 0.1, 0.8, 0.65 })
		bar:SetScrollPercentage(0.5)
		Advance()
		CheckColors()
		assert(bar.Back:IsEnabled() and bar.Forward:IsEnabled(), "Both middle-position arrows must be usable")
		bar.Forward:OnEnter(); bar.Forward:OnMouseDown(); bar.Forward:OnMouseUp(); bar.Forward:OnLeave()
		CheckColors()
		bar:SetScrollPercentage(1)
		Advance()
		CheckColors()
		assert(not bar.Forward:IsEnabled(), "Forward must disable at the bottom")
		themes:SetTheme("blizzard", "scrollbar-restoration")
		local r, g, b = bar:GetThumb().Middle:GetVertexColor()
		assert(r == 1 and g == 1 and b == 1 and not bar:GetThumb().Middle:IsDesaturated(), "Blizzard scrollbar colors were not restored")
		themes:SetTheme("dark", "scrollbar-restoration")
		CheckColors()
		themes:SetTheme("custom", "scrollbar-restoration")
		CheckColors()
		db:Set("customTheme", { accentColor = { r = 0.8, g = 0.2, b = 0.6, a = 1 } })
		themes:ApplyCurrentTheme("custom-theme-color")
		CheckColors()
		CheckAccent({ 0.8, 0.2, 0.6 })
		db:Set("customTheme", { accentColor = { r = 0.1, g = 0.8, b = 0.65, a = 1 } })
		themes:ApplyCurrentTheme("custom-theme-color")
		bar:SetScrollPercentage(0)
		Advance()
		CheckColors()
		CheckAccent({ 0.1, 0.8, 0.65 })
	elseif feedbackScene == "scroll" then
		review:Navigate("layout")
		Advance()
		local row = FindRow(BFL.L.SETTINGS_WINDOW_SMOOTH_SCROLLING)
		assert(db:Get("enableSettingsSmoothScrolling") == false, "Settings scrolling is not opt-in")
		local friendScrolling = db:Get("enableSmoothScrolling")
		row.checkBox:SetChecked(true)
		row.checkBox:GetScript("OnClick")(row.checkBox)
		assert(db:Get("enableSettingsSmoothScrolling") == true, "The Settings checkbox did not enable smooth scrolling")
		assert(db:Get("enableSmoothScrolling") == friendScrolling, "The Settings option changed friends list scrolling")
		review:Navigate("rows")
		Advance()
		local scroll = review.scroll
		scroll:SetVerticalScroll(0)
		scroll:GetScript("OnMouseWheel")(scroll, -1)
		A_Admin.AdvanceTime(0.016)
		assert(scroll:GetVerticalScroll() > 0 and scroll:GetVerticalScroll() < 30, "Settings did not animate wheel input")
		scroll:GetScript("OnMouseWheel")(scroll, -1)
		Advance()
		assert(math.abs(scroll:GetVerticalScroll() - 60) < 0.1, "Fast wheel input lost scroll distance")
		scroll:GetScript("OnMouseWheel")(scroll, -1)
		review:Navigate("layout")
		Advance()
		assert(scroll:GetVerticalScroll() == 0, "A category change resumed the old scroll animation")
		local designer = BFL:GetModule("SettingsDesigner")
		settingsUI:HideLegacyWindow()
		local center = designer:Show("appearance.fonts")
		center.Scroll:SetVerticalScroll(0)
		center.Scroll:GetScript("OnMouseWheel")(center.Scroll, -1)
		A_Admin.AdvanceTime(0.016)
		assert(center.Scroll:GetVerticalScroll() > 0 and center.Scroll:GetVerticalScroll() < 64,
			"The optional Settings Center does not animate wheel input")
		center.Scroll:SetVerticalScroll(0)
		Advance()
		assert(center.Scroll:GetVerticalScroll() == 0, "Settings Center navigation did not stop the animation")
		designer:Hide()
		settingsUI:ShowLegacy()
		review:Navigate("layout")
		Advance()
		row = FindRow(BFL.L.SETTINGS_WINDOW_SMOOTH_SCROLLING)
		row.checkBox:SetChecked(false)
		row.checkBox:GetScript("OnClick")(row.checkBox)
		assert(db:Get("enableSettingsSmoothScrolling") == false, "The Settings checkbox did not disable smooth scrolling")
		row.checkBox:SetChecked(true)
		row.checkBox:GetScript("OnClick")(row.checkBox)
		review.scroll:SetVerticalScroll(math.max(0, review.scroll.BFL_SettingsContentHeight - review.scroll:GetHeight()))
		review:ShowSettingHelp(row, 1)
		review:ToggleSettingHelpPin(row, 1)
		assert(review.pinnedGuideID and not review.guideEntry.showComparison, "Scrolling help did not pin as an explanation")
		assert(not review.favoriteHighlight or not review.favoriteHighlight:IsShown(), "Settings scrolling highlights an unrelated friend")
	elseif feedbackScene == "scale" then
		review:Navigate("layout")
		Advance()
		local preferredWidth, preferredHeight = narrow and 760 or 1170, narrow and 620 or 800
		local function ChangeScale(value)
			local input = FindRow(BFL.L.SETTINGS_FRAME_SCALE).Input
			input:SetText(tostring(value))
			input:GetScript("OnEnterPressed")(input)
			Advance()
			assert(db:Get("windowScale") == value, "The scale input did not apply its value")
			local x, y, width, height = BFL.WindowGeometry:GetRect(frame)
			assert(x >= -0.01 and y >= -0.01 and x + width <= UIParent:GetWidth() + 0.01
				and y + height <= UIParent:GetHeight() + 0.01, "Live scaling leaves Settings outside the screen")
			local saved = db:Get("settingsWindowSize")
			assert(saved.width == preferredWidth and saved.height == preferredHeight,
				"Live scaling overwrites the preferred Settings size")
		end
		for _, value in ipairs({ 1.5, 0.75, 2, 1 }) do ChangeScale(value) end
		assert(math.abs(frame:GetWidth() - preferredWidth) < 1 and math.abs(frame:GetHeight() - preferredHeight) < 1,
			"Scaling back down does not restore the preferred Settings size")
		ChangeScale(1.5)
	elseif feedbackScene == "resize" then
		local frameSettings = BFL:GetModule("FrameSettings")
		local grip = frame.BFL_ResizeGrip
		assert(grip and grip:IsVisible(), "Settings has no resize grip")
		grip:GetScript("OnMouseDown")(grip, "LeftButton")
		frame:SetSize(760, 620)
		grip:GetScript("OnMouseUp")(grip, "LeftButton")
		local saved = db:Get("settingsWindowSize")
		assert(saved.width == 760 and saved.height == 620, "Resizing did not persist the chosen dimensions")
		settingsUI:Hide()
		settingsUI:ShowLegacy()
		assert(math.abs(frame:GetWidth() - 760) < 1 and math.abs(frame:GetHeight() - 620) < 1,
			"Settings forgot its size when reopened")
		frameSettings:ResetSettingsWindowSize()
		assert(frame:GetWidth() > 760, "Reset did not restore the default Settings width")
		db:Set("settingsWindowSize", saved)
		frameSettings:FitSettingsWindow(frame)
		review:Navigate("windowFonts")
	elseif feedbackScene == "docking" then
		local geometry = BFL.WindowGeometry
		local owner = BetterFriendsFrame
		local function Move(x)
			geometry:SetTopLeft(owner, x, UIParent:GetHeight() - 8)
			Advance()
		end
		Move(UIParent:GetWidth() - owner:GetWidth() - 40)
		local ownerX = geometry:GetRect(owner)
		local settingsX = geometry:GetRect(frame)
		assert(settingsX < ownerX, "Settings did not dock on the available left side")
		Move(10)
		ownerX = geometry:GetRect(owner)
		settingsX = geometry:GetRect(frame)
		assert(settingsX > ownerX, "Settings remained stuck at the screen edge")
		local fs = BFL:GetModule("FrameSettings")
		db:Set("useUIPanelSystem", false)
		fs:SavePosition()
		local x, y = geometry:GetRect(owner)
		geometry:SetTopLeft(owner, 400, 600)
		fs:ApplyPosition()
		local newX, newY = geometry:GetRect(owner)
		assert(math.abs(x - newX) < 1 and math.abs(y - newY) < 1, "Reopening changed the effective saved position")
		HideBetterFriendsFrame()
		Advance()
		geometry:SetTopLeft(owner, 400, 600)
		ShowBetterFriendsFrame()
		Advance()
		newX, newY = geometry:GetRect(owner)
		assert(math.abs(x - newX) < 1 and math.abs(y - newY) < 1, "The normal close/open path lost the saved position")
	elseif feedbackScene == "input" then
		local dialogs = BFL:GetModule("Dialogs")
		local editor = BFL:GetModule("FriendTagEditor")
		if withFrameColor then
			C_AddOns.EnableAddOn("FrameColor")
			local loaded, reason = C_AddOns.LoadAddOn("FrameColor")
			assert(loaded, "FrameColor could not load: " .. tostring(reason))
			FrameColor:EnableSkin("_PopUpDialogs")
		end
		db:Set("useThemedDialogs", true)
		editor:Show()
		editor.frame.createSection:Click()
		local input = assert(dialogs.inputDialog)
		assert(input.which == "BFL_FRIEND_TAG_EDITOR_CREATE_SECTION", "Create Section did not use the private input dialog")
		input.button2:Click()
		input = assert(BFL.ShowInputDialog("BETTER_FRIENDLIST_CREATE_GROUP"))
		assert(input:GetName() == "BFLInputDialog" and input.BFL_DarkSkin, "Group input did not receive the BFL theme")
		assert(not input.EditBox:IsNumeric(), "The private group input blocks letters")
		input.EditBox:SetText("")
		assert(not input.button1:IsEnabled(), "An invalid group name is accepted")
		input.EditBox:SetText("Raid Friends")
		Advance()
		assert(input.button1:IsEnabled(), "A valid group name is rejected: " .. tostring(input.BFL_ErrorLabel:GetText())
			.. "; validator=" .. tostring(input.BFL_GroupEditBoxColor) .. "; spec=" .. tostring(input.which))
		input.button2:Click()
		local list = BFL:GetModule("FriendsList")
		local createGroup, renameGroup = list.CreateGroup, list.RenameGroup
		local acceptedName, acceptedFriend, renamedID
		list.CreateGroup = function(_, name, friend) acceptedName, acceptedFriend = name, friend; return "qa" end
		list.RenameGroup = function(_, id, name) renamedID, acceptedName = id, name; return true end
		input = BFL.ShowInputDialog("BETTER_FRIENDLIST_CREATE_GROUP_AND_ADD_FRIEND", nil, nil, "qa-friend")
		input.EditBox:SetText("QA Group")
		Advance()
		input.EditBox:GetScript("OnEnterPressed")(input.EditBox)
		Advance()
		assert(acceptedName == "QA Group" and acceptedFriend == "qa-friend" and not input:IsShown(),
			"Enter did not preserve the group/friend context")
		input = BFL.ShowInputDialog("BETTER_FRIENDLIST_RENAME_GROUP", nil, nil, "favorites")
		input.EditBox:SetText("QA Renamed")
		Advance()
		input.button1:Click()
		Advance()
		assert(renamedID == "favorites" and acceptedName == "QA Renamed" and not input:IsShown(),
			"Rename did not preserve the selected group")
		list.CreateGroup, list.RenameGroup = createGroup, renameGroup
		db:Set("useThemedDialogs", false)
		local native = assert(BFL.ShowInputDialog("BETTER_FRIENDLIST_CREATE_GROUP"))
		assert(native ~= input and not native.BFL_DarkSkin, "The native popup received a BFL skin")
		native.EditBox:SetNumeric(true)
		native:Hide()
		native = assert(BFL.ShowInputDialog("BETTER_FRIENDLIST_CREATE_GROUP"))
		assert(not native.EditBox:IsNumeric(), "The native fallback lost the numeric-input reset")
		native:Hide()
		local other = assert(StaticPopup_Show("SET_FRIENDNOTE", "Sample Friend", nil, "sample"))
		assert(not other.BFL_DarkSkin, "Another Blizzard dialog inherited the BFL popup skin")
		other:Hide()
		db:Set("useThemedDialogs", true)
		editor.frame:Hide()
		frame = assert(BFL.ShowInputDialog("BETTER_FRIENDLIST_CREATE_GROUP"))
		frame.EditBox:SetText("Raid Friends")
	elseif feedbackScene == "popup" then
		if withFrameColor then
			assert(C_AddOns.DoesAddOnExist("FrameColor"), "FrameColor was not discovered in the isolated addon directory")
			C_AddOns.EnableAddOn("FrameColor")
			local loaded, reason = C_AddOns.LoadAddOn("FrameColor")
			assert(loaded, "FrameColor could not load in the fixture " .. tostring(reason))
			FrameColor:EnableSkin("_PopUpDialogs")
		end
		local popup = assert(StaticPopup_Show("BETTER_FRIENDLIST_CREATE_GROUP"))
		popup.EditBox:SetNumeric(true)
		popup:Hide()
		popup = assert(StaticPopup_Show("BETTER_FRIENDLIST_CREATE_GROUP"))
		assert(not popup.EditBox:IsNumeric(), "A reused numeric popup blocks group-name letters")
		popup.EditBox:SetText("Raid Friends")
		assert(popup.EditBox:GetText() == "Raid Friends", "The group dialog did not retain a text name")
		frame = popup
	end
	Advance()
end

if sideTabPosition and sideTabPosition ~= "" then
	local friendsUI = assert(BFL:GetModule("FriendsUI"))
	local function AdvanceTabs() for _ = 1, 10 do A_Admin.AdvanceTime(0.016) end end
	if sideTabTheme and sideTabTheme ~= "" then
		BFL:GetModule("ThemeManager"):SetTheme(sideTabTheme, "side-tab-fixture")
	end
	local originalSection = friendsUI.selectedSection
	for _, side in ipairs({ "left", "right", "left", sideTabPosition }) do
		friendsUI:SetSideTabPosition(side)
		frame:ClearAllPoints()
		frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 100, -32)
		AdvanceTabs()
		assert(friendsUI:GetSideTabPosition() == side, "The tab side was not saved")
		assert(friendsUI.selectedSection == originalSection, "Changing tab side changed the selected section")
		for _, tab in ipairs(friendsUI.sideTabs) do
			if tab:IsVisible() then
				local layer, sublevel = tab.Icon:GetDrawLayer()
				assert(tab.Icon:IsShown() and tab.Icon:GetAlpha() > 0 and layer == "OVERLAY" and sublevel >= 4,
					"The tab icon is hidden or behind the mirrored tab artwork")
				local point, _, relativePoint = tab:GetPoint()
				assert(point == (side == "left" and "TOPRIGHT" or "TOPLEFT"), "The tab rail uses the wrong side")
				local x = select(4, tab.Icon:GetPoint())
				if sideTabTheme ~= "dark" and sideTabTheme ~= "custom" then
					assert(side == "left" and x > 0 or side == "right" and x < 0, "The icon did not follow the mirrored shell")
				end
				if tab.Mask then
					assert(tab.Mask:GetAtlas() == "common-sidetab-mask", "The native icon mask was converted into mirrored chrome")
				end
				for _, key in ipairs({ "Background", "SelectedTexture", "HighlightTexture", "TabGlow" }) do
					local texture = tab[key]
					local state = texture and texture.BFL_SideTabCoordinates
					if state then
						if side == "left" then
							local ulX = texture:GetTexCoord()
							assert(ulX == state.normal[5], "The tab artwork has stale texture coordinates")
						else
							assert(texture:GetAtlas() == state.atlas, "The original tab atlas was not restored")
						end
					end
				end
			end
		end
	end
	if showFriendTabSettings then
		BFL:SetLocale("deDE")
		BFL:GetModule("Settings"):ShowLegacyReview()
		if narrow then BetterFriendlistSettingsFrame:SetSize(760, 620) end
		local review = BFL:GetModule("LegacySettingsReview")
		review:Navigate("friendTabs")
		AdvanceTabs()
		local found
		for _, row in ipairs(review.controlRows) do
			if row.BFL_Comparison and row.BFL_Comparison[1] and row.BFL_Comparison[1][1] == "modernSideTabPosition" then
				found = row
				break
			end
		end
		assert(found and found:IsVisible(), "The Tab Position setting is unreachable")
		review:ShowSettingHelp(found, 1)
		review:ToggleSettingHelpPin(found, 1)
		AdvanceTabs()
		frame = assert(BetterFriendlistSettingsFrame)
	end
end

-- The screenshot command can exit zero after a Lua error. Its frame dump must include this marker.
local marker = CreateFrame("Frame", "BFLUISimCaptureComplete", frame)
marker:SetSize(1, 1)
marker:SetPoint("TOPLEFT")
marker:Hide()
