-- Explain display settings only after an explicit friend-tag assignment.
local _, BFL = ...
local FriendTagHints = BFL:RegisterModule("FriendTagHints", {})

local function Path(...)
	return table.concat({ ... }, " > ")
end

function FriendTagHints:GetGuidance(friend, tagIds)
	local tags = BFL:GetModule("FriendTags")
	local db = BFL:GetModule("DB")
	local settings = BFL:GetModule("Settings")
	if not (tags and db and settings) or #tagIds == 0 then return end

	local L = BFL.L
	local center = settings:IsSettingsCenterEnabled()
	local tagPath = center and Path(L.SETTINGS_CENTER_CATEGORY_GROUPS_SORTING, L.SETTINGS_CENTER_PAGE_FRIEND_TAGS)
		or L.SETTINGS_TAB_FRIEND_TAGS
	local function TagSetting(key, label, section, message)
		return key, {
			text = message or string.format(L.FRIEND_TAG_HINT_SETTING, label),
			path = Path(tagPath, label),
			page = "groups.friendtags", control = "friendTags." .. key,
			category = 13, legacySection = section,
		}
	end

	if db:Get("streamerModeActive", false) and not tags:GetSetting("showTagsInStreamerMode", false) then
		local label = center and L.FRIEND_TAGS_SETTINGS_STREAMER or L.FRIEND_TAGS_STREAMER_MODE
		return TagSetting("showTagsInStreamerMode", label,
			"friendTagsVisibility", L.FRIEND_TAG_HINT_STREAMER)
	end
	if not tags:IsEnabled() then
		return TagSetting("enabled", center and L.FRIEND_TAGS_SETTINGS_ENABLE or L.FRIEND_TAGS_ENABLE)
	end

	local infoHidden = db:IsInfoDisabled()
	local compactMode = db:Get("compactMode", false) and tags:GetSetting("compactRowMode", "icon_only")
	local compactHidden = compactMode == "hidden"
	local row = not infoHidden and not compactHidden and tags:CanDisplayTags("row")
	local tooltip = tags:CanDisplayTags("tooltip")
	local brokerEnabled = db:Get("brokerEnabled", false)
	local broker = brokerEnabled and tags:CanDisplayTags("broker")
	local group = tags:GetSetting("enableDynamicTagGroups", false) and tags:CanDisplayTags("group")
	local visibleGroups
	if group then
		local friends = BFL:GetModule("FriendsList")
		local currentFriend = friends and friends:ResolveFriendByUID(tags:GetFriendUID(friend))
		local connected = (currentFriend or friend).connected
		if currentFriend then
			group = friends:PassesFilters(currentFriend)
		end
		if group and db:Get("hideEmptyGroups", false) and not BFL:IsSecret(connected) and connected == false then
			-- An offline friend can still join a group that has other online members.
			visibleGroups = {}
			local list = friends and friends.cachedDisplayList
			for _, item in ipairs(list or {}) do
				if item.groupId and item.onlineCount and item.onlineCount > 0 then
					visibleGroups[item.groupId] = true
				end
			end
		end
	end

	local firstHiddenTag, hiddenByIconOnly
	for _, id in ipairs(tagIds) do
		local tag = tags:GetTagDefinition(id)
		if tag then
			local rowVisible = row and tags:ShouldIncludeTagOnSurface(tag, "row")
			if rowVisible then
				local profile = tags:GetChipProfile(tag)
				local icon = profile.iconValue or profile.icon
				local label = tags:GetChipLabel(tag)
				rowVisible = (icon and icon ~= "") or (compactMode ~= "icon_only" and label and label ~= "")
				if not firstHiddenTag and not rowVisible and compactMode == "icon_only" and label and label ~= "" then
					hiddenByIconOnly = true
				end
			end
			if rowVisible
				or (tooltip and tags:ShouldIncludeTagOnSurface(tag, "tooltip"))
				or (broker and tags:ShouldIncludeTagOnSurface(tag, "broker"))
				or (group and (not visibleGroups or visibleGroups["tag:" .. id])
					and tags:ShouldIncludeTagOnSurface(tag, "group")) then
				return
			end
			firstHiddenTag = firstHiddenTag or tag
		end
	end
	if not firstHiddenTag then return end
	if hiddenByIconOnly then
		return TagSetting("compactRowMode", L.FRIEND_TAGS_SETTINGS_COMPACT_MODE, "friendTagsCompact")
	end

	local rowAllowed = tags:ShouldIncludeTagOnSurface(firstHiddenTag, "row")
	local tooltipAllowed = tags:ShouldIncludeTagOnSurface(firstHiddenTag, "tooltip")
	local brokerAllowed = tags:ShouldIncludeTagOnSurface(firstHiddenTag, "broker")
	if row or tooltip or broker or not (rowAllowed or tooltipAllowed or (brokerEnabled and brokerAllowed)) then
		local editor = BFL:GetModule("FriendTagEditor")
		if editor then
			local id = firstHiddenTag.id
			return "editor", {
				text = L.FRIEND_TAG_HINT_EDITOR,
				path = Path(L.FRIEND_TAGS_EDITOR_TITLE, L.FRIEND_TAGS_EDITOR_VISIBLE),
				onClick = function() editor:Show(id) end,
			}, L.FRIEND_TAGS_EDITOR_OPEN
		end
	end

	local rowLabel = center and L.FRIEND_TAGS_SETTINGS_ROW_CHIPS or L.FRIEND_TAGS_SHOW_ROW_CHIPS
	if rowAllowed and not infoHidden and not compactHidden then
		return TagSetting("showRowChips", rowLabel, "friendTagsVisibility")
	elseif tooltipAllowed then
		local label = center and L.FRIEND_TAGS_SETTINGS_TOOLTIPS or L.FRIEND_TAGS_SHOW_TOOLTIP_CHIPS
		return TagSetting("showTooltipChips", label, "friendTagsVisibility")
	elseif brokerEnabled and brokerAllowed then
		local label = center and L.FRIEND_TAGS_SETTINGS_BROKER or L.FRIEND_TAGS_SHOW_BROKER_CHIPS
		return TagSetting("showBrokerChips", label, "friendTagsVisibility")
	elseif rowAllowed then
		if not tags:CanDisplayTags("row") then
			return TagSetting("showRowChips", rowLabel, "friendTagsVisibility")
		elseif infoHidden then
			local formatPath = center
				and Path(L.SETTINGS_CENTER_CATEGORY_FRIENDS, L.SETTINGS_CENTER_PAGE_FRIENDS_FORMATTING)
				or L.SETTINGS_TAB_GENERAL
			return "infoFormat", {
				text = string.format(L.FRIEND_TAG_HINT_SETTING, L.SETTINGS_INFO_FORMAT_HEADER),
				path = Path(formatPath, L.SETTINGS_INFO_FORMAT_HEADER),
				page = "friends.formatting", control = "infoFormatPreset",
				category = 1, legacySection = "friendInfoFormatting",
			}
		end
		return TagSetting("compactRowMode", L.FRIEND_TAGS_SETTINGS_COMPACT_MODE, "friendTagsCompact")
	end
end

function FriendTagHints:OnAssigned(friend, tagIds)
	local hints = BFL:GetModule("FeatureHints")
	if not hints then return end
	local reason, entry, actionText = self:GetGuidance(friend, tagIds)
	if not entry then return end
	return hints:Show({
		id = "friendTags." .. reason,
		title = BFL.L.FRIEND_TAG_HINT_TITLE,
		icon = "Interface\\AddOns\\BetterFriendlist\\Icons\\check-circle.blp",
		entries = { entry },
		actionText = actionText,
	})
end
