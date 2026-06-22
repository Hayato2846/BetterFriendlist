-- Modules/TagChips.lua
-- Lightweight row chip rendering for FriendTags.

local ADDON_NAME, BFL = ...

local TagChips = BFL:RegisterModule("TagChips", {})

local CHIP_HEIGHT = 14
local CHIP_GAP = 4
local CHIP_MAX_WIDTH = 88
local OVERFLOW_WIDTH = 30
local MAX_RENDERED_CHIPS = 4
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

local function GetCompactRowMode(friendsList)
	local FriendTags = GetFriendTags()
	if not (friendsList and friendsList.settingsCache and friendsList.settingsCache.compactMode) then
		return nil
	end
	return FriendTags and FriendTags:GetSetting("compactRowMode", "icon_only") or "icon_only"
end

local function CanRenderRow(friend, friendsList)
	if not friend or not friendsList or not friendsList.settingsCache then
		return false
	end
	if friendsList.settingsCache.infoDisabled then
		return false
	end
	local FriendTags = GetFriendTags()
	if not (FriendTags and FriendTags.CanDisplayTags and FriendTags:CanDisplayTags("row")) then
		return false
	end
	local compactMode = GetCompactRowMode(friendsList)
	return compactMode ~= "hidden"
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
	chip:SetScript("OnEnter", function(self)
		local tooltip = _G.BFL_Tooltip or _G.GameTooltip
		if not tooltip then
			return
		end
		tooltip:SetOwner(self, "ANCHOR_RIGHT")
		local L = BFL and BFL.L
		tooltip:SetText((L and L.FRIEND_TAGS_TOOLTIP_TITLE) or "Friend Tags", 1, 1, 1)
		if type(overflowTags) == "table" then
			for _, overflowTag in ipairs(overflowTags) do
				tooltip:AddLine((overflowTag.name or overflowTag.id or "") .. " - " .. GetSourceText(overflowTag.source), 0.50, 0.78, 1.00, true)
			end
		elseif type(tag) == "table" then
			tooltip:AddLine(tag.name or tag.id or "", 0.50, 0.78, 1.00, true)
			tooltip:AddLine(GetSourceText(tag.source), 0.75, 0.75, 0.75, true)
		end
		tooltip:Show()
	end)
	chip:SetScript("OnLeave", function()
		local tooltip = _G.BFL_Tooltip or _G.GameTooltip
		if tooltip then
			tooltip:Hide()
		end
	end)
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

		row.chips[index] = chip
	end

	button.friendTagRow = row
	return row
end

function TagChips:GetRowExtraHeight(friend, friendsList)
	if not CanRenderRow(friend, friendsList) then
		return 0
	end
	local FriendTags = GetFriendTags()
	local tags = FriendTags and FriendTags:GetTagsForFriend(friend, "row") or {}
	if #tags == 0 then
		return 0
	end
	return CHIP_HEIGHT + (friendsList.settingsCache.compactMode and 2 or 4)
end

function TagChips:UpdateRowChips(button, friend, friendsList)
	local row = self:EnsureRow(button)
	if not row or not CanRenderRow(friend, friendsList) then
		HideRow(row)
		return false
	end

	local FriendTags = GetFriendTags()
	local tags = FriendTags and FriendTags:GetTagsForFriend(friend, "row") or {}
	if #tags == 0 then
		HideRow(row)
		return false
	end

	local compactMode = GetCompactRowMode(friendsList)
	local iconOnly = compactMode == "icon_only"
	local maxChips = iconOnly and 2 or (tonumber(FriendTags:GetSetting("maxRowChips", 3)) or 3)
	maxChips = math.max(1, math.min(maxChips, MAX_RENDERED_CHIPS - 1))
	local renderableTags = {}
	for _, tag in ipairs(tags) do
		local profile = tag.chipProfile or {}
		local labelText = FriendTags.GetChipLabel and FriendTags:GetChipLabel(tag) or tag.name or ""
		if iconOnly then
			labelText = ""
		end
		local iconValue = profile.iconValue or profile.icon
		local hasIcon = iconValue and iconValue ~= ""
		if labelText ~= "" or hasIcon then
			tag.bflChipLabel = labelText
			tag.bflChipHasIcon = hasIcon
			renderableTags[#renderableTags + 1] = tag
		end
	end
	if #renderableTags == 0 then
		HideRow(row)
		return false
	end

	local visibleCount = math.min(#renderableTags, maxChips)
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
			local tag = renderableTags[index]
			local labelText
			local profile
			local overflowTags
			if index > visibleCount then
				labelText = string.format("+%d", overflow)
				profile = { color = { r = 0.45, g = 0.45, b = 0.45, a = 1 }, textColor = { r = 1, g = 1, b = 1, a = 1 } }
				overflowTags = {}
				for hiddenIndex = visibleCount + 1, #renderableTags do
					overflowTags[#overflowTags + 1] = renderableTags[hiddenIndex]
				end
			else
				labelText = tag.bflChipLabel or ""
				profile = tag.chipProfile or {}
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
