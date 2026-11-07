-- lua tools/BFL-FriendTagPersistenceSmoke.lua <repo>
-- Real editor/profile persistence in isolated fresh and migrated profiles.
local root = arg[1] or "."
local function read(path)
	local file = assert(io.open(root .. "/" .. path, "rb")); local source = file:read("*a"); file:close(); return source
end
local harness = read("tools/BFL-SettingsReliabilitySmoke.lua")
local boundary = assert(harness:find('execute("Libs/LibSettingsDesigner/LibSettingsDesignerConfig.lua")', 1, true))
local make = assert(load(harness:sub(1, boundary - 1) .. "\nreturn BFL, env, execute", "@isolated tag fixture", "t", _G))
local checks = 0
local function equal(actual, expected, message)
	checks = checks + 1
	assert(actual == expected, message .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end
for _, migrated in ipairs({ false, true }) do
	local BFL, env, execute = make()
	if migrated then
		env.BetterFriendlistDB = { contactMemory = { tags = {}, contacts = {} }, friendTagSettings = { enabled = true } }
		BFL.modules.DB:Initialize()
	end
	local tags = BFL.modules.FriendTags
	tags:Initialize()
	execute("Modules/FriendTagEditor.lua")
	local editor = BFL.modules.FriendTagEditor
	local frame = { Show = function() end, Raise = function() end, ClearAllPoints = function() end, SetPoint = function() end }
	editor.EnsureFrame = function() return frame end
	editor.RefreshList = function() end
	editor.RefreshEditor = function(self) self:LoadState(tags:GetTagDefinition(self.selectedTagId)) end
	local id = assert(tags:CreateCustomTag("Teacher"))
	editor:Show(id)
	local state = editor.editState
	state.name = "Personal name"
	state.color = { r = .13, g = .77, b = .46, a = .9 }
	state.iconMode, state.iconOptionID = "selected", nil
	state.iconType, state.iconValue, state.icon, state.texture = "texture", 1234567, 1234567, 1234567
	state.labelMode, state.labelValue = "custom", "Personal label"
	editor:MarkDraft()
	equal(tags:GetTagDefinition(id).name, "Teacher", "editing does not rename the saved tag")
	equal(editor:GetPreviewLabel(), "Personal label", "the preview uses the draft")
	assert(editor:CommitState())
	equal(tags:GetChipProfile(id).iconValue, 1234567, "first icon save")
	equal(tags:GetTagDefinition(id).name, "Personal name", "custom name save")
	for _ = 1, 3 do
		tags:ClearCaches()
		editor:LoadState(tags:GetTagDefinition(id))
		equal(editor:GetPreviewIconProfile().iconValue, 1234567, "reopening retains the selected icon")
		editor.editState.iconOnlyChip = not editor.editState.iconOnlyChip
		editor:MarkDraft()
		assert(editor:CommitState())
		equal(tags:GetChipProfile(id).iconValue, 1234567, "unrelated commit retains the selected icon")
		equal(tags:GetChipProfile(id).chipLabel, "Personal label", "unrelated commit retains the label")
		equal(tags:GetTagDefinition(id).name, "Personal name", "unrelated commit retains the name")
		equal(tags:GetChipProfile(id).color.g, .77, "unrelated commit retains the custom color")
	end

	editor.editState.labelValue, editor.editState.name = "Learner :)", "Learner"
	editor.editState.color = { r = .2, g = .8, b = .6, a = 1 }
	editor:MarkDraft()
	editor:Refresh()
	equal(editor:GetPreviewLabel(), "Learner :)", "refresh keeps the pending label")
	equal(tags:GetChipProfile(id).chipLabel, "Personal label", "refresh does not commit the draft")

	local second = assert(tags:CreateCustomTag("Second"))
	editor.editState.color = { r = .7, g = .3, b = .1, a = 1 }
	editor:MarkDraft()
	editor:Show(second)
	equal(tags:GetChipProfile(id).color.r, .13, "opening another tag does not apply the previous color")
	equal(editor.editState.tagId, second, "editor now owns the second tag")
	editor.editState.name, editor.editState.labelMode, editor.editState.labelValue = "Helper", "custom", "Helper :)"
	editor:MarkDraft()
	editor:DiscardDraft()
	equal(editor.editState.name, "Second", "discard restores the selected tag")
	assert(editor.drafts[id] and not editor.drafts[second], "discard only clears the selected draft")
	editor.editState.name, editor.editState.labelMode, editor.editState.labelValue = "Helper", "custom", "Helper :)"
	editor:MarkDraft()
	local third = assert(tags:CreateCustomTag("Third", function() editor:Refresh() end))
	equal(tags:GetTagDefinition(second).name, "Second", "creating a tag does not apply other drafts")
	editor:Show(third)
	equal(editor:GetPreviewLabel(), "Third", "a new tag has its own preview")
	editor:Show(id)
	equal(editor.editState.color.r, .7, "returning to the first tag restores its draft")
	editor:SetLabelMode("icon_only")
	equal(editor:GetPreviewLabel(), "", "Icon Only hides text in the preview")
	editor:SetLabelMode("custom")
	equal(editor:GetPreviewLabel(), "Learner :)", "switching back restores the custom text")
	editor:SetLabelMode("default")
	equal(editor:GetPreviewLabel(), "Learner", "Tag Name follows the name draft")
	editor:SetLabelMode("icon_only")
	assert(tags:SetTagOrder({ third, second, id }))
	local order = tags:GetChipProfile(id).order
	assert(editor:CommitState())
	equal(tags:GetChipProfile(id).order, order, "applying the draft keeps a newer tag order")
	equal(tags:GetChipProfile(id).chipLabel, "", "the saved tag displays only its icon")
	equal(editor.editState.labelValue, "Learner :)", "the editor reloads the inactive custom text")
	editor:Reset()
	equal(editor:GetPreviewLabel(), "Learner", "reset previews the tag name")
	equal(tags:GetChipProfile(id).chipLabel, "", "reset leaves the saved chip untouched before Apply")
	editor:DiscardDraft()
	equal(editor.editState.labelMode, "icon_only", "discard restores the saved mode after a reset")
	editor:Show(second)
	equal(editor:GetPreviewLabel(), "Helper :)", "applying the first draft leaves the second one intact")
	editor.editState.name = "Third"
	editor:MarkDraft()
	assert(not editor:CommitState(), "duplicate name prevents applying a draft")
	equal(tags:GetChipProfile(second).chipLabel, nil, "rejected rename leaves the chip profile untouched")
	editor.editState.name = "Helper"
	editor:MarkDraft()
	assert(editor:CommitState())
	local friend = { type = "bnet", uid = "bnet_Student#1234", battleTag = "Student#1234" }
	for _, tagID in ipairs({ id, second, third }) do assert(tags:SetCustomTagForFriend(friend, tagID, true)) end
	for _, tagID in ipairs({ third, second, id }) do
		assert(tags:SetCustomTagForFriend(friend, tagID, false))
		assert(tags:SetCustomTagForFriend(friend, tagID, true))
	end
	for _, surface in ipairs({ "row", "tooltip", "broker", "menu" }) do
		equal(#tags:GetTagsForFriend(friend, surface), 3, "all three custom tags survive assignment and surface cache rebuilds")
	end

	local deleteId = assert(tags:CreateCustomTag("To remove"))
	local offlineFriend = { type = "bnet", uid = "bnet_Offline#1234", battleTag = "Offline#1234", connected = false }
	local shown
	env.StaticPopup_Show = function(which, name, consequence, data)
		local popup = env.StaticPopupDialogs[which]
		shown = { name = name, consequence = consequence, text = string.format(popup.text, name, consequence), data = data, accept = popup.OnAccept }
	end
	editor:Initialize()
	editor:Show(deleteId)
	editor:ConfirmDelete()
	equal(shown.consequence, BFL.L.FRIEND_TAGS_EDITOR_DELETE_NO_ASSIGNMENTS, "an unassigned tag explains that no friends have it")
	assert(tags:SetCustomTagForFriend(friend, deleteId, true))
	editor:ConfirmDelete()
	equal(shown.consequence, BFL.L.FRIEND_TAGS_EDITOR_DELETE_ONE_ASSIGNMENT, "one friend uses the singular sentence")
	assert(tags:SetCustomTagForFriend(offlineFriend, deleteId, true))
	editor.editState.name = "Unsaved name"
	editor:MarkDraft()
	editor:ConfirmDelete()
	equal(shown.name, "To remove", "confirmation names the saved tag")
	local consequence = BFL.L.FRIEND_TAGS_EDITOR_DELETE_MANY_ASSIGNMENTS:format(2)
	equal(shown.consequence, consequence, "the plural sentence includes offline assignments")
	equal(shown.text, BFL.L.FRIEND_TAGS_EDITOR_DELETE_PROMPT:format("To remove", consequence), "confirmation combines the name and consequence")
	equal(tags:GetCustomTagAssignmentCount(deleteId), 2, "showing the confirmation does not delete anything")
	editor:Show(second)
	editor.editState.labelValue = "Keep this draft"
	editor:MarkDraft()
	shown.accept(nil, shown.data)
	equal(tags:GetTagDefinition(deleteId), nil, "accepting removes the target tag")
	equal(tags:GetCustomTagAssignmentCount(deleteId), 0, "accepting removes all assignments to the target")
	equal(tags:GetCustomTagAssignmentCount(id), 1, "deleting a tag keeps unrelated assignments")
	equal(editor.drafts[deleteId], nil, "deleting a tag clears its draft")
	equal(editor.selectedTagId, second, "accepting after switching tags preserves the selection")
	equal(editor.editState.labelValue, "Keep this draft", "deleting a tag preserves other drafts")

	tags:OnDatabaseImported()
	BFL.modules.DB:Initialize()
	equal(tags:GetChipProfile(id).iconValue, 1234567, "reload/normalization retains the selected icon")
	equal(tags:GetChipProfile(id).color.r, .7, "reload/normalization retains the color")
	equal(tags:GetTagDefinition(id).name, "Learner", "reload/normalization retains the name")
	equal(tags:GetChipProfile(second).chipLabel, "Helper :)", "another tag keeps its own label")
	local chosenRoleIcon = "Interface\\AddOns\\BetterFriendlist\\Icons\\zap"
	assert(tags:SetChipProfile("blizzard:damager", { replaceIcon = true, iconMode = "selected", iconType = "texture",
		iconValue = chosenRoleIcon, texture = chosenRoleIcon }))
	tags:OnDatabaseImported()
	equal(tags:GetChipProfile("blizzard:damager").iconValue, chosenRoleIcon, "role-icon migration preserves a deliberate current-format selection")
	-- Reconstruct the saved tables and load a fresh module, as after /reload.
	env.BetterFriendlistDB = env.CopyTable(env.BetterFriendlistDB)
	execute("Modules/FriendTags.lua")
	local restored = BFL.modules.FriendTags
	restored:Initialize()
	equal(restored:GetChipProfile(id).iconValue, 1234567, "fresh session retains the selected custom icon")
	equal(restored:GetChipProfile(id).color.r, .7, "fresh session retains the custom color")
	equal(restored:GetTagDefinition(id).name, "Learner", "fresh session retains the renamed tag")
	equal(restored:GetChipProfile(id).chipLabel, "", "fresh session retains Icon Only")
	equal(restored:GetChipProfile(second).chipLabel, "Helper :)", "fresh session preserves the other tag independently")
	equal(restored:GetChipProfile("blizzard:damager").iconValue, chosenRoleIcon, "fresh session does not migrate away an explicit role icon")
	execute("Modules/FriendTagEditor.lua")
	local reopened = BFL.modules.FriendTagEditor
	reopened.selectedTagId = id
	reopened:LoadState(restored:GetTagDefinition(id))
	reopened:SetLabelMode("custom")
	equal(reopened:GetPreviewLabel(), "Learner :)", "custom text survives applying Icon Only and reloading")
	reopened:SetLabelMode("icon_only")
	local chooseIcon, warning
	local button = {}
	reopened.frame = { IsShown = function() return true end }
	reopened.iconSelectButton = button
	reopened.iconInput = {
		SetShown = function(self, shown) self.shown = shown end,
	}
	reopened.preview = { empty = {
		SetText = function(_, text) warning = text end,
		Show = function() end,
	} }
	BFL.ShowIconSelector = function(anchor, _, callback, options)
		equal(anchor, button, "the icon library uses the editor control as owner")
		equal(options.source, "tags", "the shared icon library opens with tag icons")
		chooseIcon = callback
	end
	reopened:OpenIconSelector(button)
	assert(chooseIcon, "the editor opens the shared icon library directly")
	equal(reopened:GetPreviewIcon(), 1234567, "opening the library leaves the current icon in place")
	reopened:SetIconMode("none")
	equal(reopened:GetPreviewIcon(), nil, "Remove Icon immediately changes the preview")
	equal(warning, BFL.L.FRIEND_TAGS_EDITOR_ICON_REQUIRED, "the preview explains why Icon Only is empty")
	equal(restored:GetChipProfile(id).iconValue, 1234567, "Remove Icon does not change saved data before Apply")
	reopened:SetIconMode("custom")
	assert(reopened.iconInput.shown, "Custom Path reveals the field")
	assert(not reopened:CommitState(), "an empty custom path cannot apply")
	reopened.editState.customIconPath = "Interface\\Icons\\INV_Misc_QuestionMark"
	reopened:MarkDraft()
	reopened:SetIconMode("none")
	assert(not reopened.iconInput.shown, "Remove Icon hides the custom path field")
	reopened:SetIconMode("custom")
	equal(reopened:GetPreviewIcon(), "Interface\\Icons\\INV_Misc_QuestionMark", "switching back restores the draft path")
	reopened:OpenIconSelector(button)
	reopened:LoadState(restored:GetTagDefinition(second))
	chooseIcon(7654321)
	assert(reopened:GetPreviewIcon() ~= 7654321, "a stale icon callback cannot write to another tag")
	reopened:LoadState(restored:GetTagDefinition(id))
	reopened:OpenIconSelector(button)
	chooseIcon(7654321, { iconType = "texture", iconValue = 7654321, iconZoom = .2 })
	equal(reopened:GetPreviewIcon(), 7654321, "choosing an icon updates the current draft")
	equal(reopened:GetPreviewIconProfile().iconZoom, .2, "choosing an icon keeps its zoom metadata")
	equal(restored:GetChipProfile(id).iconValue, 1234567, "choosing a library icon still waits for Apply")
	reopened.EnsureFrame = function(self) return self.frame end
	reopened.RefreshList = function() end
	reopened.RefreshEditor = function(self) self:LoadState(restored:GetTagDefinition(self.selectedTagId)) end
	reopened:SetIconMode("custom")
	assert(reopened:CommitState())
	equal(restored:GetChipProfile(id).iconValue, "Interface\\Icons\\INV_Misc_QuestionMark", "Apply stores the chosen custom path")
	equal(reopened.editState.iconMode, "custom", "the applied path loads in Custom Icon Path mode")
	assert(restored:SetChipProfile(id, { rowVisible = true, tooltipVisible = false, brokerVisible = true }))
	reopened:LoadState(restored:GetTagDefinition(id))
	reopened.editState.visible = false
	reopened:MarkDraft()
	equal(restored:GetChipProfile(id).visible, true, "the master switch only edits the draft before Apply")
	assert(reopened:CommitState())
	for _, surface in ipairs({ "row", "tooltip", "broker" }) do
		equal(restored:ShouldIncludeTagOnSurface(restored:GetTagDefinition(id), surface), false, "the saved master hides " .. surface)
	end
	local hidden = restored:GetChipProfile(id)
	assert(hidden.rowVisible and not hidden.tooltipVisible and hidden.brokerVisible, "the master leaves individual selections intact")
	reopened.editState.visible = true
	reopened:MarkDraft()
	assert(reopened:CommitState())
	local definition = restored:GetTagDefinition(id)
	equal(restored:ShouldIncludeTagOnSurface(definition, "row"), true, "the friends list resumes its saved selection")
	equal(restored:ShouldIncludeTagOnSurface(definition, "tooltip"), false, "tooltips keep their unchecked state")
	equal(restored:ShouldIncludeTagOnSurface(definition, "broker"), true, "the broker resumes its saved selection")
end

-- A close request covers drafts on tags other than the current selection.
do
	local BFL, env, execute = make()
	local tags = BFL.modules.FriendTags
	tags:Initialize()
	execute("Modules/FriendTagEditor.lua")
	local editor = BFL.modules.FriendTagEditor
	local frame = {
		shown = false,
		Show = function(self) self.shown = true end,
		Hide = function(self) self.shown = false end,
		Raise = function() end,
		ClearAllPoints = function() end,
		SetPoint = function() end,
	}
	editor.EnsureFrame = function(self) self.frame = frame; return frame end
	editor.RefreshList = function() end
	editor.RefreshEditor = function(self) self:LoadState(tags:GetTagDefinition(self.selectedTagId)) end
	local errorText
	editor.ShowDraftError = function(_, text) errorText = text end
	local popup, opened
	env.StaticPopup_Show = function(which)
		opened = which
		popup = env.StaticPopupDialogs[which]
	end
	editor:Initialize()
	local first = assert(tags:CreateCustomTag("First draft"))
	local second = assert(tags:CreateCustomTag("Second draft"))
	editor:Show(first)
	editor:RequestClose()
	equal(frame.shown, false, "a clean editor closes directly")
	equal(opened, nil, "a clean editor does not prompt")

	local function Edit(id, name, label)
		editor:Show(id)
		editor.editState.name = name
		editor.editState.labelMode = "custom"
		editor.editState.labelValue = label
		editor:MarkDraft()
	end
	Edit(first, "Same name", "First label")
	editor:Show(second)
	editor:RequestClose()
	equal(opened, "BFL_FRIEND_TAG_EDITOR_UNSAVED_CLOSE", "drafts on other tags trigger the close warning")
	equal(frame.shown, true, "the editor stays open while the prompt is visible")
	equal(popup.button1, BFL.L.FRIEND_TAGS_EDITOR_SAVE_ALL, "Save All is offered in the warning")
	Edit(second, "Same name", "Second label")
	popup.OnAccept()
	equal(frame.shown, true, "a conflicting batch leaves the editor open")
	equal(errorText, BFL.L.FRIEND_TAGS_EDITOR_DUPLICATE_NAME, "a conflict between drafts is explained")
	equal(tags:GetChipProfile(first).chipLabel, nil, "the first profile stays unchanged on failure")
	equal(tags:GetChipProfile(second).chipLabel, nil, "the second profile stays unchanged on failure")
	assert(editor.drafts[first] and editor.drafts[second], "both drafts survive validation failure")

	Edit(first, "Second draft", "First label")
	Edit(second, "First draft", "Second label")
	editor:SetIconMode("custom")
	editor.editState.customIconPath = ""
	editor:MarkDraft()
	popup.OnAccept()
	equal(editor.selectedTagId, second, "an invalid icon path selects the affected tag")
	equal(errorText, BFL.L.FRIEND_TAGS_EDITOR_ICON_PATH_REQUIRED, "the icon path error is shown")
	equal(tags:GetTagDefinition(first).name, "First draft", "an invalid icon path prevents every rename")
	editor:SetIconMode("none")
	editor:RequestClose()
	local version = BFL.SettingsVersion
	popup.OnAccept()
	equal(frame.shown, false, "successful Save All closes the editor")
	equal(next(editor.drafts), nil, "successful Save All clears the saved drafts")
	equal(tags:GetTagDefinition(first).name, "Second draft", "a batch can reuse a name freed by another draft")
	equal(tags:GetTagDefinition(second).name, "First draft", "both tag names are saved")
	equal(tags:GetChipProfile(first).chipLabel, "First label", "Save All commits the first label")
	equal(tags:GetChipProfile(second).chipLabel, "Second label", "Save All commits the second label")
	equal(BFL.SettingsVersion, version + 1, "a batch invalidates the shared settings once")

	Edit(first, "Discard first", "Discard this")
	Edit(second, "Discard second", "Discard this too")
	editor:RequestClose()
	popup.OnAlt()
	equal(frame.shown, false, "Discard and Close closes the editor")
	equal(next(editor.drafts), nil, "Discard and Close clears every draft")
	equal(tags:GetTagDefinition(first).name, "Second draft", "discard preserves the first saved name")
	equal(tags:GetChipProfile(second).chipLabel, "Second label", "discard preserves the second saved label")
end

-- Exercise the real assignment callbacks and the shared hint's navigation.
do
	local BFL, env, execute = make()
	execute("Modules/FeatureHints.lua")
	execute("Modules/FriendTagHints.lua")
	local tags, db, settings = BFL.modules.FriendTags, BFL.modules.DB, BFL.modules.Settings
	tags:Initialize()
	local hint, hidden, center, destination
	local hints = BFL.modules.FeatureHints
	hints.Show = function(_, options) hint = options; return true end
	hints.frame = { Hide = function() hidden = true end }
	settings.IsSettingsCenterEnabled = function() return center end
	settings.ShowSettingsCenter = function(_, page, control)
		destination = page .. "/" .. control
		return true
	end
	settings.ShowLegacy = function(_, category, section)
		destination = category .. "/" .. (section or "")
	end
	BFL.modules.FriendTagEditor = { Show = function(_, id) destination = id end }
	local tagId = assert(tags:CreateCustomTag("Example tag"))
	local friend = { type = "bnet", uid = "bnet_Example#1234", connected = true }
	local function Pick(text)
		for _, item in ipairs(tags:GetMenuItems(friend, friend.uid)) do
			if item.text == text then return item.func() end
		end
		error("missing menu entry " .. text)
	end
	local function Assign()
		assert(tags:SetCustomTagForFriend(friend, tagId, false))
		hint = nil
		Pick("Example tag")
		assert(tags:GetCustomTagIdSetForFriend(friend)[tagId], "the tag is assigned before the hint")
		return hint
	end
	equal(Assign(), nil, "visible row suppresses the hint")
	tags:SetSetting("showRowChips", false)
	equal(Assign(), nil, "visible tooltip suppresses the hint")
	tags:SetSetting("showTooltipChips", false)
	db:Set("brokerEnabled", true)
	equal(Assign(), nil, "visible broker detail suppresses the hint")
	db:Set("brokerEnabled", false)
	tags:SetSetting("enableDynamicTagGroups", true)
	equal(Assign(), nil, "visible dynamic group suppresses the hint")
	db:Set("hideEmptyGroups", true)
	friend.connected = false
	equal(Assign().entries[1].control, "friendTags.showRowChips", "a hidden dynamic group does not suppress the hint")
	BFL.modules.FriendsList = {
		ResolveFriendByUID = function() return friend end,
		PassesFilters = function() return true end,
		cachedDisplayList = { { groupId = "tag:" .. tagId, onlineCount = 1 } },
	}
	equal(Assign(), nil, "an offline friend can join an already visible dynamic group")
	BFL.modules.FriendsList = nil
	db:Set("hideEmptyGroups", false)
	tags:SetSetting("enableDynamicTagGroups", false)
	hints:OpenEntry(Assign().entries[1])
	equal(destination, "13/friendTagsVisibility", "legacy opens the tag visibility section")
	equal(hidden, true, "navigation dismisses the hint")
	center = true
	local entry = Assign().entries[1]
	assert(entry.path:find(BFL.L.SETTINGS_CENTER_PAGE_FRIEND_TAGS, 1, true), "settings path follows Settings Center")
	hints:OpenEntry(entry)
	equal(destination, "groups.friendtags/friendTags.showRowChips", "Settings Center focuses the blocking toggle")

	tags:SetSetting("showRowChips", true)
	assert(tags:SetChipProfile(tagId, { visible = false }))
	hints:OpenEntry(Assign().entries[1])
	equal(destination, tagId, "editor opens the assigned tag directly")
	assert(tags:SetChipProfile(tagId, { visible = true, tooltipVisible = false }))
	db:Set("compactMode", true)
	tags:SetSetting("compactRowMode", "hidden")
	equal(Assign().entries[1].control, "friendTags.compactRowMode", "compact layout routes to its tag control")
	db:Set("infoFormatPreset", "disabled")
	equal(Assign().entries[1].legacySection, "friendInfoFormatting", "disabled info format points to the legacy section")
	db:Set("infoFormatPreset", "default")
	tags:SetSetting("compactRowMode", "icon_only")
	assert(tags:SetChipProfile(tagId, { replaceIcon = true, iconMode = "none", iconType = "none", iconValue = false }))
	equal(Assign().entries[1].control, "friendTags.compactRowMode", "icon-only layout explains a tag with only text")
	tags:SetSetting("compactRowMode", "hidden")
	db:Set("streamerModeActive", true)
	entry = Assign().entries[1]
	equal(entry.text, BFL.L.FRIEND_TAG_HINT_STREAMER, "streamer suppression has its own message")
	equal(entry.onClick, nil, "privacy hint has no tag-specific editor action")
	equal(entry.control, "friendTags.showTagsInStreamerMode", "streamer hint points to visibility settings")
	db:Set("streamerModeActive", false)
	hint = nil
	Pick("Example tag")
	equal(hint, nil, "removing a tag produces no hint")
	assert(tags:SetCustomTagForFriend(friend, tagId, true))
	equal(hint, nil, "model-only assignments produce no hint")
	Pick(BFL.L.FRIEND_TAGS_CLEAR_ALL)
	equal(hint, nil, "clearing all tags produces no hint")
	Pick(BFL.L.FRIEND_TAGS_SELECT_ALL)
	assert(hint and hint.entries[1], "select all explains when the added tags are hidden")
	hint = nil
	Pick(BFL.L.FRIEND_TAGS_SELECT_ALL)
	equal(hint, nil, "select all does not hint when nothing was added")
	local popup = env.StaticPopupDialogs.BFL_FRIEND_TAGS_CREATE_CUSTOM_TAG
	popup.OnAccept({ EditBox = { GetText = function() return "New assigned tag" end } }, { friend = friend })
	assert(hint and hint.entries[1], "creating and assigning a hidden tag uses the same hint")
end

-- Keep existing model/migration contracts in the offline regression gate too.
do
	local BFL, env, execute = make()
	execute("Modules/FriendTagEditor.lua")
	local source = read("Modules/TestSuite.lua"):gsub("return TestSuite%s*$", "RegisterBuiltInTests(); return TestSuite")
	local suite = assert(load(source, "@production existing tag contracts", "t", env))("BetterFriendlist", BFL)
	local contracts = 0
	local requiresNativeLayout = {
		FriendTags_RowCacheTracksStreamerMode = true,
		FriendTags_RowChipLayoutAndDynamicGroupContext = true,
		FriendTags_NativeSurfacesRemainActiveWhenFeatureDisabled = true,
		FriendTags_DynamicTagGroupCollapseState = true,
	}
	for _, test in ipairs(suite.tests.data) do
		if test.name:match("^FriendTags_") and not requiresNativeLayout[test.name] then
			local ok, err = pcall(test.action, suite.Validator)
			assert(ok, test.name .. ": " .. tostring(err))
			contracts = contracts + 1
		end
	end
	assert(contracts >= 16, "existing tag coverage unexpectedly shrank")
	io.write("[OK] Existing tag contracts: " .. contracts .. " cases\n")
end
io.write("[OK] Friend tag persistence: " .. checks .. " checks\n")
