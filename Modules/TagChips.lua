-- Modules/TagChips.lua
-- Lightweight row chip rendering for FriendTags.

local ADDON_NAME, BFL = ...

local TagChips = BFL:RegisterModule("TagChips", {})

local CHIP_HEIGHT = 14
local CHIP_GAP = 4
local CHIP_MAX_WIDTH = 88
local OVERFLOW_WIDTH = 30
local MAX_RENDERED_CHIPS = 4
local EMPTY_TABLE = {}
local OVERFLOW_PROFILE = { color = { r = 0.45, g = 0.45, b = 0.45, a = 1 }, textColor = { r = 1, g = 1, b = 1, a = 1 } }
local BACKDROP = {
	bgFile = "Interface\\Buttons\\WHITE8X8",
	edgeFile = "Interface\\Buttons\\WHITE8X8",
	edgeSize = 1,
}

local function GetFriendTags()
	return BFL:GetModule("FriendTags")
end

local function GetBackdropTemplate()
	return BackdropTemplateMixin and "BackdropTemplate" or nil
end

local function CopyColor(color, fallback)
	color = type(color) == "table" and color or fallback
	if type(color) ~= "table" then
		return 1, 1, 1, 1
	end
	return tonumber(color.r) or 1, tonumber(color.g) or 1, tonumber(color.b) or 1, color.a == nil and 1 or (tonumber(color.a) or 1)
end

local function ApplyFont(fontString)
	if not fontString then
		return
	end
	if _G.BetterFriendlistFriendsFontSmall then
		fontString:SetFontObject(_G.BetterFriendlistFriendsFontSmall)
	elseif _G.GameFontHighlightSmall then
		fontString:SetFontObject(_G.GameFontHighlightSmall)
	end
	if fontString.SetMaxLines then
		fontString:SetMaxLines(1)
	end
	fontString:SetWordWrap(false)
	fontString:SetJustifyH("LEFT")
end

local function GetSourceText(source)
	local L = BFL and BFL.L
	if source == "blizzard" then
		return (L and L.FRIEND_TAGS_SOURCE_BLIZZARD) or "Blizzard"
	elseif source == "custom" then
		return (L and L.FRIEND_TAGS_SOURCE_CUSTOM) or "Custom"
	end
	return source or ""
end

local function HideRow(row)
	if not row then
		return
	end
	row:Hide()
	if row.chips then
		for _, chip in ipairs(row.chips) do
			chip:Hide()
		end
	end
end

local function GetRowCacheVersions(friend, friendsList, FriendTags)
	local settingsCache = friendsList and friendsList.settingsCache
	FriendTags = FriendTags or GetFriendTags()
	local friendsVersion = BFL.FriendsListVersion or 0
	local tagsDefinitionVersion = FriendTags and FriendTags.GetDefinitionVersion and FriendTags:GetDefinitionVersion()
		or BFL.FriendTagsVersion
		or 0
	local tagsGlobalAssignmentVersion = FriendTags and FriendTags.GetAssignmentVersion and FriendTags:GetAssignmentVersion()
		or BFL.FriendTagsVersion
		or 0
	local settingsVersion = BFL.SettingsVersion or 0
	local compactModeFlag = settingsCache and settingsCache.compactMode and 1 or 0
	local infoDisabledFlag = settingsCache and settingsCache.infoDisabled and 1 or 0

	if type(friend) == "table" then
		if
			friend._bflTagChipsVersionFriendsVersion == friendsVersion
			and friend._bflTagChipsVersionTagsDefinitionVersion == tagsDefinitionVersion
			and friend._bflTagChipsVersionGlobalAssignmentVersion == tagsGlobalAssignmentVersion
			and friend._bflTagChipsVersionSettingsVersion == settingsVersion
			and friend._bflTagChipsVersionCompactMode == compactModeFlag
			and friend._bflTagChipsVersionInfoDisabled == infoDisabledFlag
		then
			return friendsVersion,
				tagsDefinitionVersion,
				friend._bflTagChipsVersionTagsAssignmentVersion or 0,
				settingsVersion,
				compactModeFlag,
				infoDisabledFlag
		end
	end

	local tagsAssignmentVersion = FriendTags and FriendTags.GetFriendAssignmentVersion and FriendTags:GetFriendAssignmentVersion(friend)
		or BFL.FriendTagsVersion
		or 0
	if type(friend) == "table" then
		friend._bflTagChipsVersionFriendsVersion = friendsVersion
		friend._bflTagChipsVersionTagsDefinitionVersion = tagsDefinitionVersion
		friend._bflTagChipsVersionGlobalAssignmentVersion = tagsGlobalAssignmentVersion
		friend._bflTagChipsVersionTagsAssignmentVersion = tagsAssignmentVersion
		friend._bflTagChipsVersionSettingsVersion = settingsVersion
		friend._bflTagChipsVersionCompactMode = compactModeFlag
		friend._bflTagChipsVersionInfoDisabled = infoDisabledFlag
	end

	return friendsVersion,
		tagsDefinitionVersion,
		tagsAssignmentVersion,
		settingsVersion,
		compactModeFlag,
		infoDisabledFlag
end

local function RowDataMatches(data, friendsVersion, tagsDefinitionVersion, tagsAssignmentVersion, settingsVersion, compactMode, infoDisabled)
	return data
		and data.cacheFriendsVersion == friendsVersion
		and data.cacheTagsDefinitionVersion == tagsDefinitionVersion
		and data.cacheTagsAssignmentVersion == tagsAssignmentVersion
		and data.cacheSettingsVersion == settingsVersion
		and data.cacheCompactMode == compactMode
		and data.cacheInfoDisabled == infoDisabled
end

local function CreateRowData(friendsVersion, tagsDefinitionVersion, tagsAssignmentVersion, settingsVersion, compactMode, infoDisabled)
	return {
		cacheFriendsVersion = friendsVersion,
		cacheTagsDefinitionVersion = tagsDefinitionVersion,
		cacheTagsAssignmentVersion = tagsAssignmentVersion,
		cacheSettingsVersion = settingsVersion,
		cacheCompactMode = compactMode,
		cacheInfoDisabled = infoDisabled,
		canRender = false,
		height = 0,
		compactMode = nil,
		iconOnly = false,
		maxChips = 0,
		renderableTags = EMPTY_TABLE,
	}
end

local function ReleaseRenderableTags(data)
	local renderableTags = data and data.renderableTags
	if type(renderableTags) ~= "table" or renderableTags == EMPTY_TABLE then
		return
	end
	local pool = data._renderableTagPool
	if type(pool) ~= "table" then
		pool = {}
		data._renderableTagPool = pool
	end
	for index = #renderableTags, 1, -1 do
		local entry = renderableTags[index]
		renderableTags[index] = nil
		if type(entry) == "table" then
			entry.tag = nil
			entry.labelText = nil
			entry.profile = nil
			pool[#pool + 1] = entry
		end
	end
end

local function ResetRowData(data, friendsVersion, tagsDefinitionVersion, tagsAssignmentVersion, settingsVersion, compactMode, infoDisabled)
	data = data or CreateRowData(friendsVersion, tagsDefinitionVersion, tagsAssignmentVersion, settingsVersion, compactMode, infoDisabled)
	ReleaseRenderableTags(data)
	data.cacheFriendsVersion = friendsVersion
	data.cacheTagsDefinitionVersion = tagsDefinitionVersion
	data.cacheTagsAssignmentVersion = tagsAssignmentVersion
	data.cacheSettingsVersion = settingsVersion
	data.cacheCompactMode = compactMode
	data.cacheInfoDisabled = infoDisabled
	data.canRender = false
	data.height = 0
	data.compactMode = nil
	data.iconOnly = false
	data.maxChips = 0
	data.renderableTags = EMPTY_TABLE
	return data
end

local function AcquireRenderableTagEntry(data)
	local pool = data and data._renderableTagPool
	local entry
	if type(pool) == "table" and #pool > 0 then
		entry = pool[#pool]
		pool[#pool] = nil
	else
		entry = {}
	end
	return entry
end

local function GetCompactRowMode(friendsList, FriendTags)
	FriendTags = FriendTags or GetFriendTags()
	if not (friendsList and friendsList.settingsCache and friendsList.settingsCache.compactMode) then
		return nil
	end
	return FriendTags and FriendTags:GetSetting("compactRowMode", "icon_only") or "icon_only"
end

local function CanRenderRow(friend, friendsList, FriendTags)
	if not friend or not friendsList or not friendsList.settingsCache then
		return false
	end
	if friendsList.settingsCache.infoDisabled then
		return false
	end
	FriendTags = FriendTags or GetFriendTags()
	if not (FriendTags and FriendTags.CanDisplayTags and FriendTags:CanDisplayTags("row")) then
		return false
	end
	local compactMode = GetCompactRowMode(friendsList, FriendTags)
	return compactMode ~= "hidden"
end

local function Chip_OnEnter(self)
	local tooltip = _G.BFL_Tooltip or _G.GameTooltip
	if not tooltip then
		return
	end
	tooltip:SetOwner(self, "ANCHOR_RIGHT")
	local L = BFL and BFL.L
	tooltip:SetText((L and L.FRIEND_TAGS_TOOLTIP_TITLE) or "Friend Tags", 1, 1, 1)
	if type(self.overflowTags) == "table" then
		for _, overflowTag in ipairs(self.overflowTags) do
			tooltip:AddLine((overflowTag.name or overflowTag.id or "") .. " - " .. GetSourceText(overflowTag.source), 0.50, 0.78, 1.00, true)
		end
	elseif type(self.tagData) == "table" then
		tooltip:AddLine(self.tagData.name or self.tagData.id or "", 0.50, 0.78, 1.00, true)
		tooltip:AddLine(GetSourceText(self.tagData.source), 0.75, 0.75, 0.75, true)
	end
	tooltip:Show()
end

local function Chip_OnLeave()
	local tooltip = _G.BFL_Tooltip or _G.GameTooltip
	if tooltip then
		tooltip:Hide()
	end
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
	profile = type(profile) == "table" and profile or {}
	local iconType = profile.iconType
	local iconValue = profile.iconValue or profile.icon
	if not iconValue or iconValue == "" then
		texture:Hide()
		return false
	end
	if iconType == "atlas" then
		if TrySetAtlas(texture, iconValue) or TrySetAtlas(texture, profile.atlas) or TrySetAtlas(texture, profile.fallbackAtlas) then
			return true
		end
	end

	local texturePath = profile.texture or profile.icon or (iconType ~= "atlas" and iconValue) or nil
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

local function SetChipTooltip(chip, tag, overflowTags)
	chip.tagData = tag
	chip.overflowTags = overflowTags
end

function TagChips:EnsureRow(button)
	if not button then
		return nil
	end
	if button.friendTagRow then
		return button.friendTagRow
	end

	local row = CreateFrame("Frame", nil, button)
	row:SetHeight(CHIP_HEIGHT)
	row:Hide()
	row.chips = {}

	for index = 1, MAX_RENDERED_CHIPS do
		local chip = CreateFrame("Frame", nil, row, GetBackdropTemplate())
		chip:SetHeight(CHIP_HEIGHT)
		if chip.SetBackdrop then
			chip:SetBackdrop(BACKDROP)
		end
		chip:Hide()

		chip.icon = chip:CreateTexture(nil, "ARTWORK")
		chip.icon:SetSize(10, 10)
		chip.icon:SetPoint("LEFT", chip, "LEFT", 4, 0)

		chip.label = chip:CreateFontString(nil, "OVERLAY")
		ApplyFont(chip.label)
		chip.label:SetPoint("LEFT", chip.icon, "RIGHT", 3, 0)
		chip.label:SetPoint("RIGHT", chip, "RIGHT", -5, 0)
		chip:SetScript("OnEnter", Chip_OnEnter)
		chip:SetScript("OnLeave", Chip_OnLeave)

		row.chips[index] = chip
	end

	button.friendTagRow = row
	return row
end

function TagChips:GetRowData(friend, friendsList)
	local FriendTags = GetFriendTags()
	local friendsVersion, tagsDefinitionVersion, tagsAssignmentVersion, settingsVersion, compactModeFlag, infoDisabledFlag =
		GetRowCacheVersions(friend, friendsList, FriendTags)
	local data
	local useFriendCache = type(friend) == "table"

	if useFriendCache then
		data = friend._bflTagChipsRowData
		if RowDataMatches(data, friendsVersion, tagsDefinitionVersion, tagsAssignmentVersion, settingsVersion, compactModeFlag, infoDisabledFlag) then
			return data
		end
	else
		if not self.scalarRowCache then
			self.scalarRowCache = {}
		end
		local cacheKey = friend
		if type(cacheKey) ~= "string" and type(cacheKey) ~= "number" then
			cacheKey = tostring(cacheKey or "")
		end
		data = self.scalarRowCache[cacheKey]
		if RowDataMatches(data, friendsVersion, tagsDefinitionVersion, tagsAssignmentVersion, settingsVersion, compactModeFlag, infoDisabledFlag) then
			return data
		end
	end

	local settingsCache = friendsList and friendsList.settingsCache
	data = ResetRowData(data, friendsVersion, tagsDefinitionVersion, tagsAssignmentVersion, settingsVersion, compactModeFlag, infoDisabledFlag)
	if useFriendCache then
		friend._bflTagChipsRowData = data
	else
		local cacheKey = friend
		if type(cacheKey) ~= "string" and type(cacheKey) ~= "number" then
			cacheKey = tostring(cacheKey or "")
		end
		self.scalarRowCache[cacheKey] = data
	end

	if not CanRenderRow(friend, friendsList, FriendTags) then
		return data
	end

	local tags = FriendTags and FriendTags:GetTagsForFriend(friend, "row") or EMPTY_TABLE
	if #tags == 0 then
		return data
	end

	local compactMode = GetCompactRowMode(friendsList, FriendTags)
	local iconOnly = compactMode == "icon_only"
	local maxChips = iconOnly and 2 or (tonumber(FriendTags:GetSetting("maxRowChips", 3)) or 3)
	maxChips = math.max(1, math.min(maxChips, MAX_RENDERED_CHIPS - 1))

	local renderableTags = data.renderableTags
	if renderableTags == EMPTY_TABLE then
		renderableTags = data._renderableTags
		if type(renderableTags) ~= "table" then
			renderableTags = {}
			data._renderableTags = renderableTags
		end
	end
	for _, tag in ipairs(tags) do
		local profile = tag.chipProfile or {}
		local labelText = FriendTags.GetChipLabel and FriendTags:GetChipLabel(tag) or tag.name or ""
		if iconOnly then
			labelText = ""
		end
		local iconValue = profile.iconValue or profile.icon
		local hasIcon = iconValue and iconValue ~= ""
		if labelText ~= "" or hasIcon then
			local entry = AcquireRenderableTagEntry(data)
			entry.tag = tag
			entry.labelText = labelText
			entry.profile = profile
			renderableTags[#renderableTags + 1] = entry
		end
	end

	if #renderableTags == 0 then
		return data
	end

	data.canRender = true
	data.height = CHIP_HEIGHT + (settingsCache.compactMode and 2 or 4)
	data.compactMode = compactMode
	data.iconOnly = iconOnly
	data.maxChips = maxChips
	data.renderableTags = renderableTags
	return data
end

function TagChips:GetRowExtraHeight(friend, friendsList)
	return self:GetRowData(friend, friendsList).height
end

function TagChips:UpdateRowChips(button, friend, friendsList, rowData)
	local row = self:EnsureRow(button)
	if rowData then
		local FriendTags = GetFriendTags()
		local friendsVersion, tagsDefinitionVersion, tagsAssignmentVersion, settingsVersion, compactModeFlag, infoDisabledFlag =
			GetRowCacheVersions(friend, friendsList, FriendTags)
		if not RowDataMatches(rowData, friendsVersion, tagsDefinitionVersion, tagsAssignmentVersion, settingsVersion, compactModeFlag, infoDisabledFlag) then
			rowData = nil
		end
	end
	rowData = rowData or self:GetRowData(friend, friendsList)
	if not row or not rowData.canRender then
		HideRow(row)
		return false
	end

	local renderableTags = rowData.renderableTags
	local visibleCount = math.min(#renderableTags, rowData.maxChips)
	local overflow = #renderableTags - visibleCount
	local renderCount = visibleCount + (overflow > 0 and 1 or 0)

	row:ClearAllPoints()
	local anchor = button.Info or button.Name or button
	row:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -1)
	row:SetPoint("RIGHT", button, "RIGHT", -80, 0)
	row:SetHeight(CHIP_HEIGHT)

	local availableWidth = math.max(36, (button:GetWidth() or 0) - 44 - 84)
	local cursorX = 0

	for index = 1, MAX_RENDERED_CHIPS do
		local chip = row.chips[index]
		if index <= renderCount then
			local entry = renderableTags[index]
			local tag = entry and entry.tag
			local labelText
			local profile
			local overflowTags
			if index > visibleCount then
				labelText = string.format("+%d", overflow)
				profile = OVERFLOW_PROFILE
				overflowTags = {}
				for hiddenIndex = visibleCount + 1, #renderableTags do
					overflowTags[#overflowTags + 1] = renderableTags[hiddenIndex].tag
				end
			else
				labelText = entry.labelText or ""
				profile = entry.profile or tag and tag.chipProfile or {}
			end

			local r, g, b, a = CopyColor(profile.color, { r = 0.50, g = 0.78, b = 1.00, a = 1 })
			local tr, tg, tb, ta = CopyColor(profile.textColor, { r = 1, g = 1, b = 1, a = 1 })
			if chip.SetBackdropColor then
				chip:SetBackdropColor(r * 0.16, g * 0.16, b * 0.16, math.min(0.88, a))
			end
			if chip.SetBackdropBorderColor then
				chip:SetBackdropBorderColor(r, g, b, 0.78)
			end
			chip.label:SetTextColor(tr, tg, tb, ta)
			chip.label:SetText(labelText)

			local hasIcon = (profile.iconValue or profile.icon) and index <= visibleCount
			if hasIcon then
				hasIcon = ApplyIcon(chip.icon, profile)
			end
			if hasIcon then
				chip.label:ClearAllPoints()
				chip.label:SetPoint("LEFT", chip.icon, "RIGHT", 3, 0)
				chip.label:SetPoint("RIGHT", chip, "RIGHT", -5, 0)
			else
				chip.icon:Hide()
				chip.label:ClearAllPoints()
				chip.label:SetPoint("LEFT", chip, "LEFT", 6, 0)
				chip.label:SetPoint("RIGHT", chip, "RIGHT", -6, 0)
			end

			local labelWidth = chip.label:GetStringWidth() or 0
			local desiredWidth
			if index > visibleCount then
				desiredWidth = OVERFLOW_WIDTH
			elseif labelText == "" and hasIcon then
				desiredWidth = 22
			else
				desiredWidth = math.min(CHIP_MAX_WIDTH, math.max(26, labelWidth + (hasIcon and 24 or 14)))
			end
			SetChipTooltip(chip, tag, overflowTags)
			if cursorX + desiredWidth > availableWidth and index > 1 then
				chip:Hide()
			else
				chip:ClearAllPoints()
				chip:SetPoint("LEFT", row, "LEFT", cursorX, 0)
				chip:SetWidth(desiredWidth)
				chip:Show()
				cursorX = cursorX + desiredWidth + CHIP_GAP
			end
		else
			chip:Hide()
		end
	end

	row:Show()
	return true
end

return TagChips
