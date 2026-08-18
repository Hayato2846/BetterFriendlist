-- Modules/TagChips.lua
-- Lightweight row chip rendering for FriendTags.

local ADDON_NAME, BFL = ...

local TagChips = BFL:RegisterModule("TagChips", {})

local DEFAULT_CHIP_ICON_SIZE = 11
local DEFAULT_CHIP_FONT = "Friz Quadrata TT"
local DEFAULT_CHIP_FONT_SIZE = 10
local DEFAULT_CHIP_FONT_FLAGS = "SLUG"
local DEFAULT_CHIPS_PER_LINE = 3
local FULL_WIDTH_ROW_INSET = 8
local STANDALONE_CHIP_MAX_WIDTH = 180
local MAX_ROW_CHIPS = 9
local MAX_RENDERED_CHIPS = MAX_ROW_CHIPS + 1
local CHIP_BORDER_INSET = 1
local BLIZZARD_PICKER_ICON_ZOOM = 0.16
local EMPTY_TABLE = {}
local OVERFLOW_PROFILE = { color = { r = 0.45, g = 0.45, b = 0.45, a = 1 }, textColor = { r = 1, g = 1, b = 1, a = 1 } }
local DEFAULT_CHIP_COLOR = { r = 0.50, g = 0.78, b = 1.00, a = 1 }
local DEFAULT_TEXT_COLOR = { r = 1, g = 1, b = 1, a = 1 }

local function GetFriendTags()
	return BFL:GetModule("FriendTags")
end

local function ClampNumber(value, minimum, maximum, fallback)
	value = tonumber(value)
	if not value then
		value = fallback
	end
	return math.max(minimum, math.min(maximum, value))
end

local function ResolveChipMetrics(FriendTags)
	FriendTags = FriendTags or GetFriendTags()
	local iconSize = ClampNumber(
		FriendTags and FriendTags:GetSetting("chipIconSize", DEFAULT_CHIP_ICON_SIZE),
		8,
		24,
		DEFAULT_CHIP_ICON_SIZE
	)
	local fontSize = ClampNumber(
		FriendTags and FriendTags:GetSetting("chipFontSize", DEFAULT_CHIP_FONT_SIZE),
		8,
		24,
		DEFAULT_CHIP_FONT_SIZE
	)
	local fontName = FriendTags and FriendTags:GetSetting("chipFont", DEFAULT_CHIP_FONT) or DEFAULT_CHIP_FONT
	if type(fontName) ~= "string" or fontName == "" then
		fontName = DEFAULT_CHIP_FONT
	end
	local fontFlags = FriendTags and FriendTags:GetSetting("chipFontFlags", DEFAULT_CHIP_FONT_FLAGS)
		or DEFAULT_CHIP_FONT_FLAGS
	local fontPath = STANDARD_TEXT_FONT
	if BFL.FontManager and BFL.FontManager.ResolveFontPath then
		fontPath = BFL.FontManager:ResolveFontPath(fontName)
	end
	if BFL.FontManager and BFL.FontManager.GetFontFlags then
		fontFlags = BFL.FontManager:GetFontFlags(fontFlags)
	end
	local height = math.max(iconSize + 3, fontSize + 4)
	return {
		iconSize = iconSize,
		fontName = fontName,
		fontPath = fontPath,
		fontSize = fontSize,
		fontFlags = fontFlags or "",
		height = height,
		chipGap = 4,
		rowGap = 2,
		iconLeft = 4,
		iconTextGap = 3,
		rightPadding = 5,
		textPadding = 6,
		minimumWidth = math.max(26, height),
		overflowWidth = math.max(30, height),
	}
end

local function CopyColor(color, fallback)
	color = type(color) == "table" and color or fallback
	if type(color) ~= "table" then
		return 1, 1, 1, 1
	end
	return tonumber(color.r) or 1, tonumber(color.g) or 1, tonumber(color.b) or 1, color.a == nil and 1 or (tonumber(color.a) or 1)
end

local function ApplyPillGeometry(pill, chip, inset, height)
	if not pill then
		return
	end
	local diameter = height - (inset * 2)
	local radius = diameter / 2
	pill.left:ClearAllPoints()
	pill.left:SetSize(diameter, diameter)
	pill.left:SetPoint("LEFT", chip, "LEFT", inset, 0)
	pill.right:ClearAllPoints()
	pill.right:SetSize(diameter, diameter)
	pill.right:SetPoint("RIGHT", chip, "RIGHT", -inset, 0)
	pill.middle:ClearAllPoints()
	pill.middle:SetPoint("TOPLEFT", chip, "TOPLEFT", inset + radius, -inset)
	pill.middle:SetPoint("BOTTOMRIGHT", chip, "BOTTOMRIGHT", -(inset + radius), inset)
end

local function CreatePillLayer(chip, layer, inset, height)
	local pill = {}
	-- Use the neutral portrait alpha circle directly. The previous RaidBlips
	-- atlas contains artwork around the circle and produced jagged pill seams.
	pill.left = chip:CreateTexture(nil, layer)
	pill.left:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask")

	pill.right = chip:CreateTexture(nil, layer)
	pill.right:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask")

	pill.middle = chip:CreateTexture(nil, layer)
	pill.middle:SetColorTexture(1, 1, 1, 1)
	ApplyPillGeometry(pill, chip, inset, height)
	return pill
end

local function SetPillColor(pill, r, g, b, a)
	if not pill then
		return
	end
	pill.left:SetVertexColor(r, g, b, a)
	pill.right:SetVertexColor(r, g, b, a)
	pill.middle:SetColorTexture(r, g, b, a)
end

local function SetPillShown(pill, shown)
	if not pill then
		return
	end
	for _, region in pairs(pill) do
		if shown then
			region:Show()
		else
			region:Hide()
		end
	end
end

local function ApplyFont(fontString, metrics)
	if not fontString then
		return
	end
	if _G.BetterFriendlistFriendsFontSmall then
		fontString:SetFontObject(_G.BetterFriendlistFriendsFontSmall)
	elseif _G.GameFontHighlightSmall then
		fontString:SetFontObject(_G.GameFontHighlightSmall)
	end
	metrics = metrics or ResolveChipMetrics()
	local applied = false
	if BFL.FontManager and BFL.FontManager.SafeSetFont then
		applied = BFL.FontManager:SafeSetFont(fontString, metrics.fontPath, metrics.fontSize, metrics.fontFlags)
	elseif fontString.SetFont and metrics.fontPath then
		local ok, result = pcall(fontString.SetFont, fontString, metrics.fontPath, metrics.fontSize, metrics.fontFlags)
		applied = ok and result ~= false
	end
	if not applied and fontString.GetFont and fontString.SetFont then
		local path, _, flags = fontString:GetFont()
		if path then
			pcall(fontString.SetFont, fontString, path, metrics.fontSize, flags)
		end
	end
	if fontString.SetMaxLines then
		fontString:SetMaxLines(1)
	end
	fontString:SetWordWrap(false)
	fontString:SetJustifyH("LEFT")
end

local measureLabel
local measuredLabelWidths = {}
local measuredLabelVersion
local chipFontPath
local chipFontFlags
local chipConfiguredFontSize
local chipFontVersion = 0

local function GetChipFontVersion()
	local metrics = ResolveChipMetrics()
	if
		metrics.fontPath ~= chipFontPath
		or metrics.fontFlags ~= chipFontFlags
		or metrics.fontSize ~= chipConfiguredFontSize
	then
		chipFontPath = metrics.fontPath
		chipFontFlags = metrics.fontFlags
		chipConfiguredFontSize = metrics.fontSize
		chipFontVersion = chipFontVersion + 1
		if measureLabel then
			ApplyFont(measureLabel, metrics)
		end
	end
	return chipFontVersion
end

local function MeasureLabelWidth(labelText, metrics)
	labelText = tostring(labelText or "")
	local version = GetChipFontVersion()
	if measuredLabelVersion ~= version then
		measuredLabelWidths = {}
		measuredLabelVersion = version
	end
	if measuredLabelWidths[labelText] then
		return measuredLabelWidths[labelText]
	end
	if not measureLabel then
		measureLabel = UIParent:CreateFontString(nil, "ARTWORK")
		ApplyFont(measureLabel, metrics)
	end
	measureLabel:SetText(labelText)
	local width = measureLabel:GetStringWidth() or 0
	measuredLabelWidths[labelText] = width
	return width
end

local function GetDesiredChipWidth(labelText, hasIcon, overflow, metrics)
	metrics = metrics or ResolveChipMetrics()
	if overflow then
		return metrics.overflowWidth
	elseif labelText == "" and hasIcon then
		return metrics.height
	end
	local padding = hasIcon
		and (metrics.iconLeft + metrics.iconSize + metrics.iconTextGap + metrics.rightPadding)
		or (metrics.textPadding * 2)
	return math.max(metrics.minimumWidth, MeasureLabelWidth(labelText, metrics) + padding)
end

local function GetAvailableRowWidth(friendsList, FriendTags)
	local buttonWidth = friendsList and friendsList.GetButtonWidth and friendsList:GetButtonWidth() or 300
	FriendTags = FriendTags or GetFriendTags()
	if FriendTags and FriendTags:GetSetting("fullWidthTagRows", false) == true then
		return math.max(36, math.floor(buttonWidth - (FULL_WIDTH_ROW_INSET * 2)))
	end
	local FriendsUI = BFL:GetModule("FriendsUI")
	local modern = FriendsUI and FriendsUI.IsModernActive and FriendsUI:IsModernActive()
	local textLeftInset = modern and 38 or 44
	return math.max(36, math.floor(buttonWidth - textLeftInset - 84))
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

local function GetRowCacheVersions(friend, friendsList, FriendTags, persistentUID)
	local settingsCache = friendsList and friendsList.settingsCache
	FriendTags = FriendTags or GetFriendTags()
	local friendsVersion = BFL.FriendsListVersion or 0
	local tagsDefinitionVersion = FriendTags and FriendTags.GetDefinitionVersion and FriendTags:GetDefinitionVersion()
		or BFL.FriendTagsVersion
		or 0
	local tagsGlobalAssignmentVersion = FriendTags and FriendTags.GetAssignmentVersion and FriendTags:GetAssignmentVersion()
		or BFL.FriendTagsVersion
		or 0
	-- Tag definitions carry every Friend Tag visual setting change. General BFL
	-- settings (filters, search, selected tab) must not invalidate all row chips.
	-- Streamer Mode is deliberately tracked separately from SettingsVersion: it
	-- changes tag visibility without changing definitions and must never reuse a
	-- previously visible row-chip result.
	local fontVersion = GetChipFontVersion()
	local streamerModeFlag = BetterFriendlistDB and BetterFriendlistDB.streamerModeActive and 1 or 0
	local settingsVersion = (fontVersion * 2) + streamerModeFlag
	local compactModeFlag = settingsCache and settingsCache.compactMode and 1 or 0
	local infoDisabledFlag = settingsCache and settingsCache.infoDisabled and 1 or 0
	local availableWidth = GetAvailableRowWidth(friendsList, FriendTags)

	if type(friend) == "table" then
		if
			friend._bflTagChipsVersionFriendsVersion == friendsVersion
			and friend._bflTagChipsVersionTagsDefinitionVersion == tagsDefinitionVersion
			and friend._bflTagChipsVersionGlobalAssignmentVersion == tagsGlobalAssignmentVersion
			and friend._bflTagChipsVersionSettingsVersion == settingsVersion
			and friend._bflTagChipsVersionCompactMode == compactModeFlag
			and friend._bflTagChipsVersionInfoDisabled == infoDisabledFlag
			and friend._bflTagChipsVersionAvailableWidth == availableWidth
		then
			return friendsVersion,
				tagsDefinitionVersion,
				friend._bflTagChipsVersionTagsAssignmentVersion or 0,
				settingsVersion,
				compactModeFlag,
				infoDisabledFlag,
				availableWidth
		end
	end

	local tagsAssignmentVersion = FriendTags and FriendTags.GetFriendAssignmentVersion and FriendTags:GetFriendAssignmentVersion(friend, persistentUID)
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
		friend._bflTagChipsVersionAvailableWidth = availableWidth
	end

	return friendsVersion,
		tagsDefinitionVersion,
		tagsAssignmentVersion,
		settingsVersion,
		compactModeFlag,
		infoDisabledFlag,
		availableWidth
end

local function NormalizeGroupCacheKey(groupId)
	return groupId == nil and "" or tostring(groupId)
end

local function RowDataMatches(data, friendsVersion, tagsDefinitionVersion, tagsAssignmentVersion, settingsVersion, compactMode, infoDisabled, availableWidth, groupCacheKey)
	return data
		and data.cacheFriendsVersion == friendsVersion
		and data.cacheTagsDefinitionVersion == tagsDefinitionVersion
		and data.cacheTagsAssignmentVersion == tagsAssignmentVersion
		and data.cacheSettingsVersion == settingsVersion
		and data.cacheCompactMode == compactMode
		and data.cacheInfoDisabled == infoDisabled
		and data.availableWidth == availableWidth
		and data.cacheGroupId == groupCacheKey
end

local function CreateRowData(friendsVersion, tagsDefinitionVersion, tagsAssignmentVersion, settingsVersion, compactMode, infoDisabled, availableWidth, groupCacheKey)
	return {
		cacheFriendsVersion = friendsVersion,
		cacheTagsDefinitionVersion = tagsDefinitionVersion,
		cacheTagsAssignmentVersion = tagsAssignmentVersion,
		cacheSettingsVersion = settingsVersion,
		cacheCompactMode = compactMode,
		cacheInfoDisabled = infoDisabled,
		cacheGroupId = groupCacheKey,
		availableWidth = availableWidth,
		canRender = false,
		height = 0,
		compactMode = nil,
		iconOnly = false,
		maxChips = 0,
		chipsPerLine = DEFAULT_CHIPS_PER_LINE,
		fullWidthTagRows = false,
		lineCount = 0,
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

local function ResetRowData(data, friendsVersion, tagsDefinitionVersion, tagsAssignmentVersion, settingsVersion, compactMode, infoDisabled, availableWidth, groupCacheKey)
	data = data or CreateRowData(friendsVersion, tagsDefinitionVersion, tagsAssignmentVersion, settingsVersion, compactMode, infoDisabled, availableWidth, groupCacheKey)
	ReleaseRenderableTags(data)
	data.cacheFriendsVersion = friendsVersion
	data.cacheTagsDefinitionVersion = tagsDefinitionVersion
	data.cacheTagsAssignmentVersion = tagsAssignmentVersion
	data.cacheSettingsVersion = settingsVersion
	data.cacheCompactMode = compactMode
	data.cacheInfoDisabled = infoDisabled
	data.cacheGroupId = groupCacheKey
	data.availableWidth = availableWidth
	data.canRender = false
	data.height = 0
	data.compactMode = nil
	data.iconOnly = false
	data.maxChips = 0
	data.chipsPerLine = DEFAULT_CHIPS_PER_LINE
	data.fullWidthTagRows = false
	data.lineCount = 0
	data.metrics = nil
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

local function GetIconZoom(profile)
	if type(profile) ~= "table" or profile.iconZoom == nil or profile.iconZoom == false then
		return nil
	end
	if profile.iconZoom == true then
		return BLIZZARD_PICKER_ICON_ZOOM
	end
	local zoom = tonumber(profile.iconZoom)
	return zoom and math.max(0, math.min(0.45, zoom)) or nil
end

local function ApplyZoomedTexCoord(texture, texCoord, zoom)
	local left = type(texCoord) == "table" and (tonumber(texCoord[1]) or 0) or 0
	local right = type(texCoord) == "table" and (tonumber(texCoord[2]) or 1) or 1
	local top = type(texCoord) == "table" and (tonumber(texCoord[3]) or 0) or 0
	local bottom = type(texCoord) == "table" and (tonumber(texCoord[4]) or 1) or 1
	zoom = tonumber(zoom) or BLIZZARD_PICKER_ICON_ZOOM
	local width = right - left
	local height = bottom - top
	texture:SetTexCoord(left + (width * zoom), right - (width * zoom), top + (height * zoom), bottom - (height * zoom))
end

local function ApplyZoomedAtlasName(texture, atlasName, zoom)
	if type(atlasName) ~= "string" or atlasName == "" then
		return false
	end
	local info = BFL.GetAtlasInfo(atlasName)
	local textureFile = info and (info.file or info.filename)
	if textureFile then
		texture:SetTexture(textureFile)
		local left = tonumber(info.leftTexCoord) or 0
		local right = tonumber(info.rightTexCoord) or 1
		local top = tonumber(info.topTexCoord) or 0
		local bottom = tonumber(info.bottomTexCoord) or 1
		local width = right - left
		local height = bottom - top
		texture:SetTexCoord(left + (width * zoom), right - (width * zoom), top + (height * zoom), bottom - (height * zoom))
		texture:Show()
		return true
	end
	return false
end

local function GetPersistentRowCacheKey(friend, FriendTags)
	local friendType = type(friend)
	if friendType == "string" or friendType == "number" then
		return friendType .. "|" .. tostring(friend), tostring(friend)
	end
	if friendType ~= "table" or not (FriendTags and FriendTags.GetFriendUID) then
		return nil
	end
	local uid = FriendTags:GetFriendUID(friend)
	if not uid then
		return nil
	end
	return tostring(friend.type or "friend") .. "|" .. tostring(uid), uid
end

local function ApplyZoomedAtlas(texture, profile, zoom)
	if not (texture and type(profile) == "table" and profile.iconType == "atlas" and BFL.GetAtlasInfo) then
		return false
	end
	local primary = profile.iconValue
	local atlas = profile.atlas
	local fallback = profile.fallbackAtlas
	if ApplyZoomedAtlasName(texture, primary, zoom) then
		return true
	end
	if atlas ~= primary and ApplyZoomedAtlasName(texture, atlas, zoom) then
		return true
	end
	if fallback ~= primary and fallback ~= atlas then
		if ApplyZoomedAtlasName(texture, fallback, zoom) then
			return true
		end
	end
	return false
end

local function ApplyIcon(texture, profile)
	if not (texture and type(profile) == "table") then
		return false
	end
	local iconZoom = GetIconZoom(profile)
	-- Zoom is opt-in profile metadata: picker Blizzard icons use the shared
	-- default, while selected map-legend defaults can provide an exact crop.
	if iconZoom and ApplyZoomedAtlas(texture, profile, iconZoom) then
		return true
	end
	local applied = BFL.ApplyIconProfile and BFL.ApplyIconProfile(texture, profile) or false
	if applied and iconZoom and profile.iconType ~= "atlas" then
		ApplyZoomedTexCoord(texture, profile.texCoord, iconZoom)
	end
	return applied
end

local function ApplyChipGeometry(chip, metrics)
	metrics = metrics or ResolveChipMetrics()
	local geometryKey = table.concat({ metrics.iconSize, metrics.fontSize, metrics.height }, ":")
	if chip._bflGeometryKey == geometryKey then
		return
	end
	chip:SetHeight(metrics.height)
	ApplyPillGeometry(chip.pillBorder, chip, 0, metrics.height)
	ApplyPillGeometry(chip.pillBackground, chip, CHIP_BORDER_INSET, metrics.height)
	ApplyFont(chip.label, metrics)
	chip._bflGeometryKey = geometryKey
end

local function CreateChip(parent)
	local metrics = ResolveChipMetrics()
	local chip = CreateFrame("Frame", nil, parent)
	chip:SetHeight(metrics.height)
	chip:EnableMouse(false)
	chip.pillBorder = CreatePillLayer(chip, "BACKGROUND", 0, metrics.height)
	chip.pillBackground = CreatePillLayer(chip, "BORDER", CHIP_BORDER_INSET, metrics.height)

	chip.icon = chip:CreateTexture(nil, "ARTWORK")
	chip.icon:SetSize(metrics.iconSize, metrics.iconSize)
	chip.icon:SetPoint("LEFT", chip, "LEFT", metrics.iconLeft, 0)

	chip.label = chip:CreateFontString(nil, "OVERLAY")
	ApplyFont(chip.label, metrics)
	chip.label:SetPoint("LEFT", chip.icon, "RIGHT", metrics.iconTextGap, 0)
	chip.label:SetPoint("RIGHT", chip, "RIGHT", -metrics.rightPadding, 0)
	chip._bflGeometryKey = table.concat({ metrics.iconSize, metrics.fontSize, metrics.height }, ":")
	chip:Hide()
	return chip
end

local function UpdateChipVisual(chip, profile, labelText, allowIcon, overflow, maxWidth, forceRefresh, metrics)
	if not chip then
		return 0, false
	end
	metrics = metrics or ResolveChipMetrics()
	ApplyChipGeometry(chip, metrics)
	profile = type(profile) == "table" and profile or {}
	labelText = tostring(labelText or "")
	allowIcon = allowIcon ~= false
	overflow = overflow == true
	local fontVersion = GetChipFontVersion()
	if chip._bflAppliedFontVersion ~= fontVersion then
		ApplyFont(chip.label, metrics)
		chip._bflAppliedFontVersion = fontVersion
	end
	if
		not forceRefresh
		and chip._bflVisualProfile == profile
		and chip._bflVisualLabel == labelText
		and chip._bflVisualAllowIcon == allowIcon
		and chip._bflVisualOverflow == overflow
		and chip._bflVisualMaxWidth == maxWidth
		and chip._bflVisualFontVersion == fontVersion
		and chip._bflVisualGeometryKey == chip._bflGeometryKey
	then
		chip:Show()
		return chip._bflVisualWidth or 0, chip._bflVisualHasIcon == true
	end

	local r, g, b, a = CopyColor(profile.color, DEFAULT_CHIP_COLOR)
	local tr, tg, tb, ta = CopyColor(profile.textColor, DEFAULT_TEXT_COLOR)
	SetPillColor(chip.pillBorder, 0, 0, 0, 1)
	-- The fill remains opaque enough to preserve the configured color while the
	-- one-pixel inset reveals the black outline underneath it.
	SetPillColor(chip.pillBackground, r, g, b, math.min(0.94, a))
	chip.label:SetTextColor(tr, tg, tb, ta)
	chip.label:SetText(labelText)

	local hasIcon = allowIcon and (profile.iconValue or profile.icon or profile.texture or profile.atlas)
	if hasIcon then
		hasIcon = ApplyIcon(chip.icon, profile)
	end
	local bareIcon = labelText == "" and hasIcon == true and not overflow
	chip.bareIcon = bareIcon
	SetPillShown(chip.pillBorder, not bareIcon)
	SetPillShown(chip.pillBackground, not bareIcon)
	chip.label:SetShown(not bareIcon)
	chip.icon:ClearAllPoints()
	chip.label:ClearAllPoints()
	if bareIcon then
		chip.icon:SetSize(metrics.iconSize, metrics.iconSize)
		chip.icon:SetPoint("CENTER", chip, "CENTER", 0, 0)
	elseif hasIcon then
		chip.icon:SetSize(metrics.iconSize, metrics.iconSize)
		chip.icon:SetPoint("LEFT", chip, "LEFT", metrics.iconLeft, 0)
		chip.label:SetPoint("LEFT", chip.icon, "RIGHT", metrics.iconTextGap, 0)
		chip.label:SetPoint("RIGHT", chip, "RIGHT", -metrics.rightPadding, 0)
	else
		chip.icon:Hide()
		chip.icon:SetSize(metrics.iconSize, metrics.iconSize)
		chip.icon:SetPoint("LEFT", chip, "LEFT", metrics.iconLeft, 0)
		chip.label:SetPoint("LEFT", chip, "LEFT", metrics.textPadding, 0)
		chip.label:SetPoint("RIGHT", chip, "RIGHT", -metrics.textPadding, 0)
	end

	local desiredWidth = GetDesiredChipWidth(labelText, hasIcon == true, overflow, metrics)
	if maxWidth then
		desiredWidth = math.min(desiredWidth, maxWidth)
	end
	chip:SetWidth(desiredWidth)
	chip:Show()
	chip._bflVisualProfile = profile
	chip._bflVisualLabel = labelText
	chip._bflVisualAllowIcon = allowIcon
	chip._bflVisualOverflow = overflow
	chip._bflVisualMaxWidth = maxWidth
	chip._bflVisualFontVersion = fontVersion
	chip._bflVisualGeometryKey = chip._bflGeometryKey
	chip._bflVisualWidth = desiredWidth
	chip._bflVisualHasIcon = hasIcon == true
	return desiredWidth, hasIcon == true
end

function TagChips:EnsureRow(button)
	if not button then
		return nil
	end
	if button.friendTagRow then
		return button.friendTagRow
	end

	local row = CreateFrame("Frame", nil, button)
	row:SetHeight(ResolveChipMetrics().height)
	row:EnableMouse(false)
	row:Hide()
	row.chips = {}

	for index = 1, MAX_RENDERED_CHIPS do
		row.chips[index] = CreateChip(row)
	end

	button.friendTagRow = row
	return row
end

function TagChips:GetRowData(friend, friendsList, groupId)
	local FriendTags = GetFriendTags()
	local persistentCacheKey, persistentUID = GetPersistentRowCacheKey(friend, FriendTags)
	local groupCacheKey = NormalizeGroupCacheKey(groupId)
	if persistentCacheKey then
		persistentCacheKey = persistentCacheKey .. "|group:" .. groupCacheKey
	end
	local friendsVersion, tagsDefinitionVersion, tagsAssignmentVersion, settingsVersion, compactModeFlag, infoDisabledFlag, availableWidth =
		GetRowCacheVersions(friend, friendsList, FriendTags, persistentUID)
	if self.rowDataCacheDefinitionVersion ~= tagsDefinitionVersion then
		self.rowDataCacheDefinitionVersion = tagsDefinitionVersion
		self.rowDataByFriend = {}
		self.rowDataByFriendCount = 0
		self.scalarRowCache = {}
	end
	local data
	local useFriendCache = type(friend) == "table" and persistentCacheKey == nil

	if persistentCacheKey then
		if not self.rowDataByFriend then
			self.rowDataByFriend = {}
		end
		data = self.rowDataByFriend[persistentCacheKey]
		if RowDataMatches(data, friendsVersion, tagsDefinitionVersion, tagsAssignmentVersion, settingsVersion, compactModeFlag, infoDisabledFlag, availableWidth, groupCacheKey) then
			return data
		end
	elseif useFriendCache then
		friend._bflTagChipsRowDataByGroup = friend._bflTagChipsRowDataByGroup or {}
		data = friend._bflTagChipsRowDataByGroup[groupCacheKey]
		if RowDataMatches(data, friendsVersion, tagsDefinitionVersion, tagsAssignmentVersion, settingsVersion, compactModeFlag, infoDisabledFlag, availableWidth, groupCacheKey) then
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
		cacheKey = tostring(cacheKey) .. "|group:" .. groupCacheKey
		data = self.scalarRowCache[cacheKey]
		if RowDataMatches(data, friendsVersion, tagsDefinitionVersion, tagsAssignmentVersion, settingsVersion, compactModeFlag, infoDisabledFlag, availableWidth, groupCacheKey) then
			return data
		end
	end

	data = ResetRowData(data, friendsVersion, tagsDefinitionVersion, tagsAssignmentVersion, settingsVersion, compactModeFlag, infoDisabledFlag, availableWidth, groupCacheKey)
	data.fullWidthTagRows = FriendTags and FriendTags:GetSetting("fullWidthTagRows", false) == true or false
	if persistentCacheKey then
		if not self.rowDataByFriend[persistentCacheKey] then
			self.rowDataByFriendCount = (self.rowDataByFriendCount or 0) + 1
			if self.rowDataByFriendCount > 2048 then
				self.rowDataByFriend = {}
				self.rowDataByFriendCount = 1
			end
		end
		self.rowDataByFriend[persistentCacheKey] = data
	elseif useFriendCache then
		friend._bflTagChipsRowDataByGroup[groupCacheKey] = data
	else
		local cacheKey = friend
		if type(cacheKey) ~= "string" and type(cacheKey) ~= "number" then
			cacheKey = tostring(cacheKey or "")
		end
		cacheKey = tostring(cacheKey) .. "|group:" .. groupCacheKey
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
	local maxChips = tonumber(FriendTags:GetSetting("maxRowChips", 3)) or 3
	maxChips = math.max(1, math.min(maxChips, MAX_ROW_CHIPS))
	local chipsPerLine = ClampNumber(FriendTags:GetSetting("chipsPerLine", DEFAULT_CHIPS_PER_LINE), 1, 9, DEFAULT_CHIPS_PER_LINE)
	local metrics = ResolveChipMetrics(FriendTags)
	local hiddenGroupTagId
	if FriendTags:GetSetting("hideDynamicGroupTagChip", false) and type(groupId) == "string" then
		hiddenGroupTagId = groupId:match("^tag:(.+)$")
	end

	local renderableTags = data.renderableTags
	if renderableTags == EMPTY_TABLE then
		renderableTags = data._renderableTags
		if type(renderableTags) ~= "table" then
			renderableTags = {}
			data._renderableTags = renderableTags
		end
	end
	for _, tag in ipairs(tags) do
		if not hiddenGroupTagId or tostring(tag.id or "") ~= tostring(hiddenGroupTagId) then
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
	end

	if #renderableTags == 0 then
		return data
	end

	data.canRender = true
	local visibleCount = math.min(#renderableTags, maxChips)
	local renderCount = visibleCount + (#renderableTags > visibleCount and 1 or 0)
	local cursorX = 0
	local chipsOnLine = 0
	local lineCount = 1
	for index = 1, renderCount do
		local overflow = index > visibleCount
		local entry = renderableTags[index]
		local profile = not overflow and entry and entry.profile or nil
		local labelText = overflow and string.format("+%d", #renderableTags - visibleCount) or (entry and entry.labelText or "")
		local hasIcon = not overflow and profile and (profile.iconValue or profile.icon or profile.texture or profile.atlas) ~= nil
		local desiredWidth = math.min(GetDesiredChipWidth(labelText, hasIcon == true, overflow, metrics), availableWidth)
		if chipsOnLine >= chipsPerLine or (chipsOnLine > 0 and cursorX + desiredWidth > availableWidth) then
			lineCount = lineCount + 1
			cursorX = 0
			chipsOnLine = 0
		end
		cursorX = cursorX + desiredWidth + metrics.chipGap
		chipsOnLine = chipsOnLine + 1
	end
	data.lineCount = lineCount
	data.height = (data.lineCount * metrics.height) + (data.lineCount * metrics.rowGap)
	data.compactMode = compactMode
	data.iconOnly = iconOnly
	data.maxChips = maxChips
	data.chipsPerLine = chipsPerLine
	data.metrics = metrics
	data.renderableTags = renderableTags
	return data
end

function TagChips:GetRowExtraHeight(friend, friendsList, groupId)
	return self:GetRowData(friend, friendsList, groupId).height
end

function TagChips:GetAvailableRowWidth(friendsList)
	return GetAvailableRowWidth(friendsList, GetFriendTags())
end

function TagChips:GetRowAnchor(button)
	if not button then
		return nil
	end
	local multiAccountRow = button.multiAccountRow
	if
		multiAccountRow
		and multiAccountRow.IsShown
		and multiAccountRow:IsShown()
	then
		return multiAccountRow
	end
	local info = button.Info
	if info and (not info.IsShown or info:IsShown()) then
		return info
	end
	return button.Name or button
end

function TagChips:UpdateRowChips(button, friend, friendsList, groupId, rowData)
	-- The provider can survive an in-place smart refresh while assignments or
	-- layout inputs change. Validate explicit data before rendering it; the
	-- version lookup itself is cached on the current friend record.
	if rowData then
		local FriendTags = GetFriendTags()
		local _, persistentUID = GetPersistentRowCacheKey(friend, FriendTags)
		local friendsVersion, definitionVersion, assignmentVersion, settingsVersion, compactMode, infoDisabled, availableWidth =
			GetRowCacheVersions(friend, friendsList, FriendTags, persistentUID)
		if not RowDataMatches(
			rowData,
			friendsVersion,
			definitionVersion,
			assignmentVersion,
			settingsVersion,
			compactMode,
			infoDisabled,
			availableWidth,
			NormalizeGroupCacheKey(groupId)
		) then
			rowData = nil
		end
	end
	rowData = rowData or self:GetRowData(friend, friendsList, groupId)
	if not rowData.canRender then
		HideRow(button and button.friendTagRow)
		return false
	end
	local row = self:EnsureRow(button)
	if not row then
		return false
	end

	local renderableTags = rowData.renderableTags
	local metrics = rowData.metrics or ResolveChipMetrics()
	local visibleCount = math.min(#renderableTags, rowData.maxChips)
	local overflow = #renderableTags - visibleCount
	local renderCount = visibleCount + (overflow > 0 and 1 or 0)

	row:ClearAllPoints()
	if rowData.fullWidthTagRows then
		-- Separate tag rows start below the complete friend-card content block and
		-- use the same inset for measurement and rendering. This keeps them clear
		-- of the status, game, and social-action controls on both UI styles.
		local buttonHeight = button.GetHeight and button:GetHeight() or rowData.height
		local baseRowHeight = math.max(0, buttonHeight - rowData.height)
		row:SetPoint(
			"TOPLEFT",
			button,
			"TOPLEFT",
			FULL_WIDTH_ROW_INSET,
			-(baseRowHeight + metrics.rowGap)
		)
		row:SetPoint("RIGHT", button, "RIGHT", -FULL_WIDTH_ROW_INSET, 0)
	else
		-- Multi-account details are a real third text line. Anchor chips below it
		-- instead of stacking both surfaces below Info.
		local anchor = self:GetRowAnchor(button)
		row:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -metrics.rowGap)
		row:SetPoint("RIGHT", button, "RIGHT", -80, 0)
	end
	row:SetHeight(rowData.height - metrics.rowGap)

	local availableWidth = rowData.availableWidth or GetAvailableRowWidth(friendsList, GetFriendTags())
	local cursorX = 0
	local lineIndex = 0
	local chipsOnLine = 0

	for index = 1, MAX_RENDERED_CHIPS do
		local chip = row.chips[index]
		if index <= renderCount then
			local entry = renderableTags[index]
			local tag = entry and entry.tag
			local labelText
			local profile
			if index > visibleCount then
				labelText = string.format("+%d", overflow)
				profile = OVERFLOW_PROFILE
			else
				labelText = entry.labelText or ""
				profile = entry.profile or tag and tag.chipProfile or {}
			end

			local desiredWidth = UpdateChipVisual(
				chip,
				profile,
				labelText,
				index <= visibleCount,
				index > visibleCount,
				availableWidth,
				nil,
				metrics
			)
			if chipsOnLine >= rowData.chipsPerLine or (chipsOnLine > 0 and cursorX + desiredWidth > availableWidth) then
				lineIndex = lineIndex + 1
				cursorX = 0
				chipsOnLine = 0
			end
			chip:ClearAllPoints()
			chip:SetPoint("TOPLEFT", row, "TOPLEFT", cursorX, -(lineIndex * (metrics.height + metrics.rowGap)))
			cursorX = cursorX + desiredWidth + metrics.chipGap
			chipsOnLine = chipsOnLine + 1
		else
			chip:Hide()
		end
	end

	row:Show()
	return true
end

function TagChips:CreateStandaloneChip(parent)
	return parent and CreateChip(parent) or nil
end

function TagChips:UpdateStandaloneChip(chip, profile, labelText, maxWidth)
	return UpdateChipVisual(chip, profile, labelText, true, false, maxWidth or STANDALONE_CHIP_MAX_WIDTH, true, ResolveChipMetrics())
end

return TagChips
