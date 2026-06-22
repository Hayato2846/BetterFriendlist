-- Modules/FriendTags.lua
-- Unified friend tag layer with 12.0.x local Blizzard-compatible tags and 12.1 native handoff.

local ADDON_NAME, BFL = ...

local FriendTags = BFL:RegisterModule("FriendTags", {})

local SCHEMA_VERSION = 1
local SOURCE_BLIZZARD = "blizzard"
local SOURCE_CUSTOM = "custom"
local CUSTOM_PREFIX = "custom:"
local TAG_ICON = "Interface\\AddOns\\BetterFriendlist\\Icons\\tag"
local ROLE_ICON_TEXTURE = "Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES"

local ROLE_ICONS = {
	damager = {
		atlas = "UI-LFG-RoleIcon-DPS-Micro-GroupFinder",
		fallbackAtlas = "groupfinder-icon-role-large-dps",
		texture = ROLE_ICON_TEXTURE,
		texCoord = { 20 / 64, 39 / 64, 22 / 64, 41 / 64 },
		legacyValues = {
			"roleicon-tiny-dps",
			"Interface\\AddOns\\BetterFriendlist\\Icons\\zap",
			"Interface\\AddOns\\BetterFriendlist\\Icons\\crosshair",
			"Interface\\AddOns\\BetterFriendlist\\Icons\\target",
		},
	},
	healer = {
		atlas = "UI-LFG-RoleIcon-Healer-Micro-GroupFinder",
		fallbackAtlas = "groupfinder-icon-role-large-heal",
		texture = ROLE_ICON_TEXTURE,
		texCoord = { 20 / 64, 39 / 64, 1 / 64, 20 / 64 },
		legacyValues = {
			"roleicon-tiny-healer",
			"Interface\\AddOns\\BetterFriendlist\\Icons\\heart",
			"Interface\\AddOns\\BetterFriendlist\\Icons\\life-buoy",
		},
	},
	tank = {
		atlas = "UI-LFG-RoleIcon-Tank-Micro-GroupFinder",
		fallbackAtlas = "groupfinder-icon-role-large-tank",
		texture = ROLE_ICON_TEXTURE,
		texCoord = { 0, 19 / 64, 22 / 64, 41 / 64 },
		legacyValues = {
			"roleicon-tiny-tank",
			"Interface\\AddOns\\BetterFriendlist\\Icons\\shield",
		},
	},
}

local DEFAULT_SETTINGS = {
	enabled = true,
	showRowChips = true,
	showTooltipChips = true,
	showBrokerChips = true,
	showMenuTagCounts = true,
	showTagsInStreamerMode = false,
	rowMode = "chip_line",
	compactRowMode = "icon_only",
	maxRowChips = 3,
	maxTooltipChips = 8,
	enableDynamicTagGroups = false,
	includeCustomTagsInSearch = true,
	includeBlizzardTagsInSearch = true,
}

local ICON_OPTIONS = {
	{ id = "tag", labelKey = "FRIEND_TAGS_ICON_TAG", fallback = "Tag", texture = TAG_ICON },
	{ id = "professions", labelKey = "FRIEND_TAGS_ICON_PROFESSIONS", fallback = "Professions", atlas = "Professions-Icon-Crafter", texture = "Interface\\Icons\\INV_Misc_Gear_08" },
	{ id = "pvp", labelKey = "FRIEND_TAGS_ICON_PVP", fallback = "PvP", atlas = "groupfinder-button-battlegrounds", texture = "Interface\\Icons\\Achievement_BG_winWSG" },
	{ id = "raid", labelKey = "FRIEND_TAGS_ICON_RAID", fallback = "Raid", atlas = "groupfinder-button-raids-war-within", fallbackAtlas = "groupfinder-button-raids", texture = "Interface\\EncounterJournal\\UI-EJ-PortraitIcon" },
	{ id = "dungeon", labelKey = "FRIEND_TAGS_ICON_DUNGEON", fallback = "Dungeon", atlas = "groupfinder-button-dungeons", texture = "Interface\\Icons\\Achievement_Dungeon_Heroic_GloryoftheHero" },
	{ id = "delves", labelKey = "FRIEND_TAGS_ICON_DELVES", fallback = "Delves", atlas = "delves-regular", fallbackAtlas = "groupfinder-button-delves", texture = "Interface\\Icons\\INV_Misc_Map_01" },
	{ id = "questing", labelKey = "FRIEND_TAGS_ICON_QUESTING", fallback = "Questing", atlas = "FXAM-QuestBang", fallbackAtlas = "groupfinder-button-questing", texture = "Interface\\GossipFrame\\AvailableQuestIcon" },
	{ id = "roleplaying", labelKey = "FRIEND_TAGS_ICON_ROLEPLAYING", fallback = "Roleplaying", texture = "Interface\\Icons\\INV_Misc_Book_09" },
	{ id = "damager", labelKey = "FRIEND_TAGS_ICON_DAMAGER", fallback = "Damage", atlas = ROLE_ICONS.damager.atlas, fallbackAtlas = ROLE_ICONS.damager.fallbackAtlas, texture = ROLE_ICONS.damager.texture, texCoord = ROLE_ICONS.damager.texCoord },
	{ id = "healer", labelKey = "FRIEND_TAGS_ICON_HEALER", fallback = "Healing", atlas = ROLE_ICONS.healer.atlas, fallbackAtlas = ROLE_ICONS.healer.fallbackAtlas, texture = ROLE_ICONS.healer.texture, texCoord = ROLE_ICONS.healer.texCoord },
	{ id = "tank", labelKey = "FRIEND_TAGS_ICON_TANK", fallback = "Tank", atlas = ROLE_ICONS.tank.atlas, fallbackAtlas = ROLE_ICONS.tank.fallbackAtlas, texture = ROLE_ICONS.tank.texture, texCoord = ROLE_ICONS.tank.texCoord },
}

local ICON_OPTION_BY_ID = {}
for _, icon in ipairs(ICON_OPTIONS) do
	ICON_OPTION_BY_ID[icon.id] = icon
end

local BLIZZARD_TAGS = {
	{
		id = "blizzard:professions",
		enumKey = "Professions",
		enumFallback = 0,
		labelKey = "FRIEND_TAGS_BLIZZARD_PROFESSIONS",
		fallback = "Professions",
		group = "interests",
		color = { r = 0.29, g = 0.63, b = 0.94, a = 1 },
		defaultIcon = "professions",
		order = 10,
	},
	{
		id = "blizzard:pvp",
		enumKey = "PvP",
		enumFallback = 1,
		labelKey = "FRIEND_TAGS_BLIZZARD_PVP",
		fallback = "PvP",
		group = "interests",
		color = { r = 0.86, g = 0.25, b = 0.25, a = 1 },
		defaultIcon = "pvp",
		order = 20,
	},
	{
		id = "blizzard:raiding",
		enumKey = "Raiding",
		enumFallback = 2,
		labelKey = "FRIEND_TAGS_BLIZZARD_RAIDING",
		fallback = "Raiding",
		group = "interests",
		color = { r = 0.80, g = 0.44, b = 0.95, a = 1 },
		defaultIcon = "raid",
		order = 30,
	},
	{
		id = "blizzard:dungeons",
		enumKey = "Dungeons",
		enumFallback = 3,
		labelKey = "FRIEND_TAGS_BLIZZARD_DUNGEONS",
		fallback = "Dungeons",
		group = "interests",
		color = { r = 0.45, g = 0.78, b = 0.45, a = 1 },
		defaultIcon = "dungeon",
		order = 40,
	},
	{
		id = "blizzard:delves",
		enumKey = "Delves",
		enumFallback = 4,
		labelKey = "FRIEND_TAGS_BLIZZARD_DELVES",
		fallback = "Delves",
		group = "interests",
		color = { r = 0.95, g = 0.70, b = 0.28, a = 1 },
		defaultIcon = "delves",
		order = 50,
	},
	{
		id = "blizzard:questing",
		enumKey = "Questing",
		enumFallback = 5,
		labelKey = "FRIEND_TAGS_BLIZZARD_QUESTING",
		fallback = "Questing",
		group = "interests",
		color = { r = 0.24, g = 0.72, b = 0.82, a = 1 },
		defaultIcon = "questing",
		order = 60,
	},
	{
		id = "blizzard:roleplaying",
		enumKey = "Roleplaying",
		enumFallback = 6,
		labelKey = "FRIEND_TAGS_BLIZZARD_ROLEPLAYING",
		fallback = "Roleplaying",
		group = "interests",
		color = { r = 0.96, g = 0.48, b = 0.67, a = 1 },
		defaultIcon = "roleplaying",
		order = 70,
	},
	{
		id = "blizzard:damager",
		enumKey = "DamagerRole",
		enumFallback = 7,
		labelKey = "FRIEND_TAGS_BLIZZARD_DAMAGER",
		fallback = "DPS",
		group = "roles",
		color = { r = 0.86, g = 0.34, b = 0.31, a = 1 },
		defaultIcon = "damager",
		order = 80,
	},
	{
		id = "blizzard:healer",
		enumKey = "HealerRole",
		enumFallback = 8,
		labelKey = "FRIEND_TAGS_BLIZZARD_HEALER",
		fallback = "Healer",
		group = "roles",
		color = { r = 0.32, g = 0.78, b = 0.40, a = 1 },
		defaultIcon = "healer",
		order = 90,
	},
	{
		id = "blizzard:tank",
		enumKey = "TankRole",
		enumFallback = 9,
		labelKey = "FRIEND_TAGS_BLIZZARD_TANK",
		fallback = "Tank",
		group = "roles",
		color = { r = 0.36, g = 0.56, b = 0.93, a = 1 },
		defaultIcon = "tank",
		order = 100,
	},
}

FriendTags.DEFAULT_SETTINGS = DEFAULT_SETTINGS
FriendTags.BLIZZARD_TAGS = BLIZZARD_TAGS
FriendTags.ICON_OPTIONS = ICON_OPTIONS

local BLIZZARD_TAG_BY_ID = {}
for _, tag in ipairs(BLIZZARD_TAGS) do
	BLIZZARD_TAG_BY_ID[tag.id] = tag
end

local ROLE_ICON_KEY_BY_TAG_ID = {
	["blizzard:damager"] = "damager",
	["blizzard:healer"] = "healer",
	["blizzard:tank"] = "tank",
}

local function T(key, fallback)
	local L = BFL and BFL.L
	return (L and key and L[key]) or fallback
end

local function IsSecret(value)
	return BFL and BFL.IsSecret and BFL:IsSecret(value)
end

local function Trim(value)
	if type(value) ~= "string" then
		return nil
	end
	if strtrim then
		value = strtrim(value)
	else
		value = value:gsub("^%s+", ""):gsub("%s+$", "")
	end
	if value == "" then
		return nil
	end
	return value
end

local function CopyColor(color, fallback)
	color = type(color) == "table" and color or fallback
	if type(color) ~= "table" then
		return { r = 0.50, g = 0.78, b = 1.00, a = 1 }
	end
	return {
		r = tonumber(color.r) or 0.50,
		g = tonumber(color.g) or 0.78,
		b = tonumber(color.b) or 1.00,
		a = color.a == nil and 1 or (tonumber(color.a) or 1),
	}
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

local function HasAny(set)
	if type(set) ~= "table" then
		return false
	end
	for _, enabled in pairs(set) do
		if enabled then
			return true
		end
	end
	return false
end

local function IsUsableFriendUID(uid)
	if IsSecret(uid) then
		return false
	end
	if type(uid) ~= "string" and type(uid) ~= "number" then
		return false
	end
	uid = tostring(uid)
	if uid == "" or uid == "bnet_unknown" or uid == "wow_unknown" then
		return false
	end
	return true
end

local function CopySet(set)
	local result = {}
	if type(set) == "table" then
		for key, value in pairs(set) do
			if value == true then
				result[key] = true
			elseif type(key) == "number" and type(value) == "string" then
				result[value] = true
			end
		end
	end
	return result
end

local function CountSet(set)
	local count = 0
	if type(set) == "table" then
		for _, enabled in pairs(set) do
			if enabled then
				count = count + 1
			end
		end
	end
	return count
end

local function SetToOrderedList(set, definitions)
	local list = {}
	if type(set) ~= "table" then
		return list
	end
	for _, def in ipairs(definitions or {}) do
		if set[def.id] then
			list[#list + 1] = def.id
		end
	end
	for id, enabled in pairs(set) do
		if enabled and not BLIZZARD_TAG_BY_ID[id] then
			list[#list + 1] = id
		end
	end
	return list
end

local function CopyProfile(profile)
	local copy = {}
	if type(profile) ~= "table" then
		return copy
	end
	for key, value in pairs(profile) do
		if key == "color" or key == "textColor" then
			copy[key] = CopyColor(value)
		elseif key == "texCoord" then
			copy[key] = CopyTexCoord(value)
		else
			copy[key] = value
		end
	end
	return copy
end

local function SameColor(a, b)
	a = type(a) == "table" and a or {}
	b = type(b) == "table" and b or {}
	return (tonumber(a.r) or 0) == (tonumber(b.r) or 0)
		and (tonumber(a.g) or 0) == (tonumber(b.g) or 0)
		and (tonumber(a.b) or 0) == (tonumber(b.b) or 0)
		and (a.a == nil and 1 or tonumber(a.a) or 1) == (b.a == nil and 1 or tonumber(b.a) or 1)
end

local function SameTexCoord(a, b)
	a = CopyTexCoord(a)
	b = CopyTexCoord(b)
	if not a and not b then
		return true
	elseif not a or not b then
		return false
	end
	return a[1] == b[1] and a[2] == b[2] and a[3] == b[3] and a[4] == b[4]
end

local function NormalizeIconValue(value)
	if type(value) ~= "string" then
		return nil
	end
	value = value:gsub("/", "\\")
	value = value:lower()
	value = value:gsub("%.blp$", ""):gsub("%.tga$", "")
	return value
end

local function IsLegacyRoleIconValue(value, roleIcon)
	local normalized = NormalizeIconValue(value)
	if not normalized or type(roleIcon) ~= "table" then
		return false
	end
	for _, legacyValue in ipairs(roleIcon.legacyValues or {}) do
		if normalized == NormalizeIconValue(legacyValue) then
			return true
		end
	end
	return normalized == NormalizeIconValue(roleIcon.fallbackAtlas)
end

local function HasLegacyRoleIconOverride(profile, roleIcon)
	if type(profile) ~= "table" or type(roleIcon) ~= "table" then
		return false
	end
	if IsLegacyRoleIconValue(profile.iconValue, roleIcon)
		or IsLegacyRoleIconValue(profile.icon, roleIcon)
		or IsLegacyRoleIconValue(profile.atlas, roleIcon)
		or IsLegacyRoleIconValue(profile.fallbackAtlas, roleIcon) then
		return true
	end
	return NormalizeIconValue(profile.texture) == NormalizeIconValue(roleIcon.texture)
		and (profile.texCoord == nil or SameTexCoord(profile.texCoord, roleIcon.texCoord))
end

local function NormalizeRoleTagIconOverrides(db)
	if type(db) ~= "table" or type(db.friendTagProfiles) ~= "table" then
		return
	end
	for tagId, roleKey in pairs(ROLE_ICON_KEY_BY_TAG_ID) do
		local profile = db.friendTagProfiles[tagId]
		local roleIcon = ROLE_ICONS[roleKey]
		if HasLegacyRoleIconOverride(profile, roleIcon) then
			profile.iconType = nil
			profile.iconValue = nil
			profile.icon = nil
			profile.atlas = nil
			profile.fallbackAtlas = nil
			profile.texture = nil
			profile.texCoord = nil
			if not next(profile) then
				db.friendTagProfiles[tagId] = nil
			end
		end
	end
end

local function CopyIconInfo(source, fallback)
	source = type(source) == "table" and source or {}
	fallback = type(fallback) == "table" and fallback or {}

	local atlas = source.atlas ~= nil and source.atlas or fallback.atlas
	local fallbackAtlas = source.fallbackAtlas ~= nil and source.fallbackAtlas or fallback.fallbackAtlas
	local texture = source.texture ~= nil and source.texture or fallback.texture
	local sourceHasAtlas = type(source.atlas) == "string" and source.atlas ~= ""
	local iconType = source.iconType
	if not iconType then
		iconType = sourceHasAtlas and "atlas" or fallback.iconType
	end
	local iconValue = source.iconValue
	if iconValue == nil then
		if iconType == "atlas" then
			iconValue = source.atlas or fallback.atlas
		else
			iconValue = source.texture or source.icon or fallback.iconValue
		end
	end
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
		icon = iconType == "atlas" and iconValue or texture or iconValue or fallback.icon
	end

	return {
		iconType = iconType,
		iconValue = iconValue,
		icon = icon,
		atlas = atlas,
		fallbackAtlas = fallbackAtlas,
		texture = texture,
		texCoord = CopyTexCoord(source.texCoord) or CopyTexCoord(fallback.texCoord),
	}
end

local function GetIconInfo(iconID)
	if type(iconID) == "table" then
		return CopyIconInfo(iconID, { iconType = "texture", iconValue = TAG_ICON, icon = TAG_ICON, texture = TAG_ICON })
	end
	local option = iconID and ICON_OPTION_BY_ID[iconID]
	if option then
		return CopyIconInfo(option, { iconType = "texture", iconValue = TAG_ICON, icon = TAG_ICON, texture = TAG_ICON })
	end
	local texture = iconID or TAG_ICON
	return {
		iconType = "texture",
		iconValue = texture,
		icon = texture,
		texture = texture,
	}
end

local function GetIconTexture(iconID)
	local icon = GetIconInfo(iconID)
	return icon and (icon.texture or icon.icon or icon.iconValue) or TAG_ICON
end

local function NormalizeBoolean(value, defaultValue)
	if value == nil then
		return defaultValue
	end
	return value == true
end

local function GetTagSortOrder(tag)
	if type(tag) ~= "table" then
		return 0
	end
	local profile = tag.chipProfile
	if type(profile) == "table" and tonumber(profile.order) then
		return tonumber(profile.order)
	end
	return tonumber(tag.order) or 0
end

local function GetPopupEditBox(dialog)
	if not dialog then
		return nil
	end
	return dialog.editBox or dialog.EditBox or (_G[dialog:GetName() and (dialog:GetName() .. "EditBox") or ""])
end

local function RefreshSurfaces(refreshCallback)
	BFL.FriendTagsVersion = (BFL.FriendTagsVersion or 0) + 1
	BFL.SettingsVersion = (BFL.SettingsVersion or 0) + 1
	if type(refreshCallback) == "function" then
		refreshCallback()
	elseif BFL.ForceRefreshFriendsList then
		BFL:ForceRefreshFriendsList()
	end
end

local function NormalizeTagName(name)
	name = Trim(name)
	if not name then
		return nil
	end
	if name:len() > 32 then
		name = name:sub(1, 32)
	end
	return name
end

local function AddUniqueUID(target, seen, uid)
	if not IsUsableFriendUID(uid) then
		return
	end
	uid = tostring(uid)
	if seen[uid] then
		return
	end
	seen[uid] = true
	target[#target + 1] = uid
end

local function GetWoWFriendUID(name, realm)
	name = Trim(name)
	if not name then
		return nil
	end
	local fullName = realm and realm ~= "" and (name .. "-" .. realm) or name
	if BFL.NormalizeWoWFriendName then
		fullName = BFL:NormalizeWoWFriendName(fullName) or fullName
	end
	return fullName and ("wow_" .. fullName) or nil
end

local function GetFriendUIDsFromLegacyContactKey(contactKey)
	local uids = {}
	local seen = {}
	if type(contactKey) ~= "string" or contactKey == "" then
		return uids
	end

	local bnetValue = contactKey:match("^bnet:(.+)$")
	if bnetValue then
		AddUniqueUID(uids, seen, "bnet_" .. bnetValue)
		return uids
	end

	local playerValue = contactKey:match("^player:(.+)$")
	if playerValue then
		AddUniqueUID(uids, seen, GetWoWFriendUID(playerValue))
		return uids
	end

	if contactKey:match("^bnet_") or contactKey:match("^wow_") then
		AddUniqueUID(uids, seen, contactKey)
	end
	return uids
end

local function FindCustomTagIdByName(db, name)
	local normalizedName = name and name:lower()
	if not normalizedName then
		return nil
	end
	for id, def in pairs(db.customFriendTags or {}) do
		if type(def) == "table" and type(def.name) == "string" and def.name:lower() == normalizedName then
			return id
		end
	end
	return nil
end

local function EnsureMigratedCustomTag(db, legacyTagId, legacyTag)
	if type(db) ~= "table" or type(legacyTagId) ~= "string" or type(legacyTag) ~= "table" then
		return nil
	end
	local name = NormalizeTagName(legacyTag.name or legacyTagId)
	if not name then
		return nil
	end

	db.friendTagsLegacyContactMemoryTagMap = db.friendTagsLegacyContactMemoryTagMap or {}
	local mappedId = db.friendTagsLegacyContactMemoryTagMap[legacyTagId]
	if mappedId and db.customFriendTags[mappedId] then
		return mappedId
	end

	local existingId = FindCustomTagIdByName(db, name)
	if existingId then
		db.friendTagsLegacyContactMemoryTagMap[legacyTagId] = existingId
		return existingId
	end

	local id = CUSTOM_PREFIX .. tostring(db.nextCustomFriendTagID)
	db.nextCustomFriendTagID = db.nextCustomFriendTagID + 1
	local now = time and time() or 0
	db.customFriendTags[id] = {
		id = id,
		name = name,
		source = SOURCE_CUSTOM,
		enabled = true,
		order = tonumber(legacyTag.order) or (1000 + db.nextCustomFriendTagID),
		createdAt = now,
		updatedAt = now,
		color = CopyColor(legacyTag.color, { r = 0.64, g = 0.86, b = 0.56, a = 1 }),
		iconType = "texture",
		iconValue = TAG_ICON,
		icon = TAG_ICON,
	}
	db.friendTagsLegacyContactMemoryTagMap[legacyTagId] = id
	return id
end

local function GetEnumValue(def)
	if Enum and Enum.BattleNetFriendTag and Enum.BattleNetFriendTag[def.enumKey] ~= nil then
		return Enum.BattleNetFriendTag[def.enumKey]
	end
	return def.enumFallback
end

local function GetEnumToTagIdMap()
	local map = {}
	for _, def in ipairs(BLIZZARD_TAGS) do
		map[GetEnumValue(def)] = def.id
	end
	return map
end

local function GetLocalizedTagName(def)
	if not def then
		return nil
	end
	if def.enumKey and SocialUIUtil and SocialUIUtil.GetLabelForBattleNetFriendTag then
		local ok, label = pcall(SocialUIUtil.GetLabelForBattleNetFriendTag, GetEnumValue(def))
		if ok and type(label) == "string" and label ~= "" then
			return label
		end
	end
	return T(def.labelKey, def.name or def.fallback or def.id)
end

function FriendTags:NormalizeDB()
	if not BetterFriendlistDB then
		BetterFriendlistDB = {}
	end

	BetterFriendlistDB.friendTagSettings = BetterFriendlistDB.friendTagSettings or {}
	for key, value in pairs(DEFAULT_SETTINGS) do
		if BetterFriendlistDB.friendTagSettings[key] == nil then
			BetterFriendlistDB.friendTagSettings[key] = value
		end
	end

	BetterFriendlistDB.friendTagProfiles = BetterFriendlistDB.friendTagProfiles or {}
	BetterFriendlistDB.customFriendTags = BetterFriendlistDB.customFriendTags or {}
	BetterFriendlistDB.friendCustomTags = BetterFriendlistDB.friendCustomTags or {}
	BetterFriendlistDB.friendBlizzardTags = BetterFriendlistDB.friendBlizzardTags or {}
	BetterFriendlistDB.friendTagsLegacyContactMemoryTagMap =
		BetterFriendlistDB.friendTagsLegacyContactMemoryTagMap or {}
	if BetterFriendlistDB.friendTagsLegacyContactMemoryMigrated == nil then
		BetterFriendlistDB.friendTagsLegacyContactMemoryMigrated = false
	end
	BetterFriendlistDB.nextCustomFriendTagID = tonumber(BetterFriendlistDB.nextCustomFriendTagID) or 1
	NormalizeRoleTagIconOverrides(BetterFriendlistDB)
	self:MigrateLegacyContactMemoryTags(BetterFriendlistDB)
	BetterFriendlistDB.friendTagsSchemaVersion = SCHEMA_VERSION
	BFL.FriendTagsVersion = BFL.FriendTagsVersion or 1

	return BetterFriendlistDB
end

function FriendTags:MigrateLegacyContactMemoryTags(db)
	db = db or BetterFriendlistDB
	if type(db) ~= "table" or db.friendTagsLegacyContactMemoryMigrated == true then
		return 0, 0
	end

	local contactMemory = db.contactMemory
	if type(contactMemory) ~= "table" then
		db.friendTagsLegacyContactMemoryMigrated = true
		return 0, 0
	end

	if type(contactMemory.tags) ~= "table" or type(contactMemory.contacts) ~= "table" then
		db.friendTagsLegacyContactMemoryMigrated = true
		return 0, 0
	end

	local tagMap = db.friendTagsLegacyContactMemoryTagMap or {}
	local migratedTags = 0
	for legacyTagId, legacyTag in pairs(contactMemory.tags) do
		if type(legacyTag) == "table" then
			local customTagId = EnsureMigratedCustomTag(db, legacyTagId, legacyTag)
			if customTagId then
				tagMap[legacyTagId] = customTagId
				migratedTags = migratedTags + 1
			end
		end
	end
	db.friendTagsLegacyContactMemoryTagMap = tagMap

	local migratedAssignments = 0
	local contactsToRemove = {}
	for contactKey, contact in pairs(contactMemory.contacts) do
		if type(contact) == "table" and type(contact.tags) == "table" then
			local uids = GetFriendUIDsFromLegacyContactKey(contactKey)
			if #uids > 0 then
				for legacyTagId, enabled in pairs(contact.tags) do
					local customTagId = enabled and tagMap[legacyTagId]
					if customTagId then
						for _, uid in ipairs(uids) do
							local set = db.friendCustomTags[uid]
							if type(set) ~= "table" then
								set = {}
								db.friendCustomTags[uid] = set
							end
							if set[customTagId] ~= true then
								set[customTagId] = true
								migratedAssignments = migratedAssignments + 1
							end
						end
						contact.tags[legacyTagId] = nil
					end
				end
				if not HasAny(contact.tags) then
					contact.tags = nil
					if not contact.privateNote then
						contactsToRemove[#contactsToRemove + 1] = contactKey
					end
				end
			end
		end
	end
	for _, contactKey in ipairs(contactsToRemove) do
		contactMemory.contacts[contactKey] = nil
	end

	db.friendTagsLegacyContactMemoryMigrated = true
	if migratedAssignments > 0 or migratedTags > 0 then
		BFL.FriendTagsVersion = (BFL.FriendTagsVersion or 0) + 1
	end
	return migratedAssignments, migratedTags
end

function FriendTags:NormalizeFriendContext(friend, explicitUID)
	local normalized
	if type(friend) == "table" then
		normalized = {}
		for key, value in pairs(friend) do
			normalized[key] = value
		end
	elseif type(friend) == "string" then
		normalized = {
			uid = friend,
			type = friend:match("^bnet_") and "bnet" or "wow",
		}
	else
		normalized = {}
	end

	local uid = self:GetFriendUID(normalized, explicitUID)
	if uid then
		normalized.uid = uid
	elseif normalized.uid and not IsUsableFriendUID(normalized.uid) then
		normalized.uid = nil
	end

	if not normalized.type and normalized.uid then
		normalized.type = normalized.uid:match("^bnet_") and "bnet" or "wow"
	end
	return normalized
end

function FriendTags:GetSettings()
	local db = self:NormalizeDB()
	return db.friendTagSettings
end

function FriendTags:GetSetting(key, fallback)
	local settings = self:GetSettings()
	local value = settings and settings[key]
	if value == nil then
		if fallback ~= nil then
			return fallback
		end
		return DEFAULT_SETTINGS[key]
	end
	return value
end

function FriendTags:SetSetting(key, value, refreshCallback)
	if not key then
		return false
	end
	local settings = self:GetSettings()
	settings[key] = value
	RefreshSurfaces(refreshCallback)
	return true
end

function FriendTags:Invalidate(reason, refreshCallback)
	RefreshSurfaces(refreshCallback)
end

function FriendTags:IsEnabled()
	if not BetterFriendlistDB or BetterFriendlistDB.enableBetaFeatures ~= true then
		return false
	end
	local ContactMemory = BFL:GetModule("ContactMemory")
	if ContactMemory and ContactMemory.GetEnabledSetting and ContactMemory:GetEnabledSetting() ~= true then
		return false
	end
	return self:GetSetting("enabled", true) ~= false
end

function FriendTags:CanDisplayTags(surface)
	if not self:IsEnabled() then
		return false
	end
	if BetterFriendlistDB and BetterFriendlistDB.streamerModeActive and self:GetSetting("showTagsInStreamerMode", false) ~= true then
		return false
	end
	if surface == "row" and self:GetSetting("showRowChips", true) ~= true then
		return false
	end
	if surface == "tooltip" and self:GetSetting("showTooltipChips", true) ~= true then
		return false
	end
	if surface == "broker" and self:GetSetting("showBrokerChips", true) ~= true then
		return false
	end
	return true
end

function FriendTags:IsBlizzardTagAPIAvailable()
	if BFL.IsRetail ~= true then
		return false
	end
	return C_BattleNet
		and type(C_BattleNet.AreFriendTagsEnabled) == "function"
		and type(C_BattleNet.SetFriendTags) == "function"
		and Enum
		and Enum.BattleNetFriendTag
end

function FriendTags:AreBlizzardTagsEnabled()
	if not self:IsBlizzardTagAPIAvailable() then
		return false
	end
	if BFL.AreBattleNetFriendTagsEnabled then
		local ok, enabled = pcall(BFL.AreBattleNetFriendTagsEnabled)
		if ok then
			return enabled == true
		end
	end
	local ok, enabled = pcall(C_BattleNet.AreFriendTagsEnabled)
	return ok and enabled == true
end

function FriendTags:GetFriendUID(friend, explicitUID)
	if IsUsableFriendUID(explicitUID) then
		return tostring(explicitUID)
	end
	if IsSecret(friend) then
		return nil
	end
	if type(friend) == "string" then
		return IsUsableFriendUID(friend) and friend or nil
	end
	if type(friend) ~= "table" then
		return nil
	end
	if IsUsableFriendUID(friend.uid) then
		return tostring(friend.uid)
	end
	if friend.type == "bnet" then
		if friend.battleTag and not IsSecret(friend.battleTag) then
			return "bnet_" .. tostring(friend.battleTag)
		end
		if friend.bnetAccountID and not IsSecret(friend.bnetAccountID) then
			return "bnet_" .. tostring(friend.bnetAccountID)
		end
	end

	local name = friend.name or friend.characterName
	local realm = friend.realmName
	if name and BFL.NormalizeWoWFriendName then
		local normalized = BFL:NormalizeWoWFriendName(realm and (name .. "-" .. realm) or name)
		return normalized and ("wow_" .. normalized) or nil
	end
	return name and ("wow_" .. tostring(name)) or nil
end

function FriendTags:GetRelatedFriendUIDs(friend, explicitUID)
	local uids = {}
	local seen = {}
	AddUniqueUID(uids, seen, self:GetFriendUID(friend, explicitUID))

	if type(friend) ~= "table" or IsSecret(friend) then
		return uids
	end

	if friend.type == "bnet" then
		if friend.battleTag and not IsSecret(friend.battleTag) then
			AddUniqueUID(uids, seen, "bnet_" .. tostring(friend.battleTag))
		end
		if friend.bnetAccountID and not IsSecret(friend.bnetAccountID) then
			AddUniqueUID(uids, seen, "bnet_" .. tostring(friend.bnetAccountID))
		end

		local gameAccountInfo = type(friend.gameAccountInfo) == "table" and friend.gameAccountInfo or nil
		AddUniqueUID(
			uids,
			seen,
			GetWoWFriendUID(
				friend.characterName or (gameAccountInfo and gameAccountInfo.characterName),
				friend.realmName or (gameAccountInfo and gameAccountInfo.realmName)
			)
		)
	else
		AddUniqueUID(uids, seen, GetWoWFriendUID(friend.name or friend.characterName, friend.realmName))
	end

	return uids
end

function FriendTags:GetBlizzardTagDefinitions()
	local definitions = {}
	for _, def in ipairs(BLIZZARD_TAGS) do
		local icon = GetIconInfo(def.defaultIcon)
		definitions[#definitions + 1] = {
			id = def.id,
			source = SOURCE_BLIZZARD,
			enumKey = def.enumKey,
			enumFallback = def.enumFallback,
			labelKey = def.labelKey,
			fallback = def.fallback,
			name = GetLocalizedTagName(def),
			group = def.group,
			color = CopyColor(def.color),
			defaultIcon = def.defaultIcon,
			iconType = icon.iconType,
			iconValue = icon.iconValue,
			icon = icon.icon,
			atlas = icon.atlas,
			fallbackAtlas = icon.fallbackAtlas,
			texture = icon.texture,
			texCoord = CopyTexCoord(icon.texCoord),
			order = tonumber(def.order) or 0,
		}
	end
	return definitions
end

function FriendTags:GetBlizzardTagLabel(tagId)
	return GetLocalizedTagName(BLIZZARD_TAG_BY_ID[tagId])
end

function FriendTags:GetIconOptions()
	local options = {}
	for _, icon in ipairs(ICON_OPTIONS) do
		local iconInfo = GetIconInfo(icon)
		options[#options + 1] = {
			id = icon.id,
			label = T(icon.labelKey, icon.fallback),
			iconType = iconInfo.iconType,
			iconValue = iconInfo.iconValue,
			icon = iconInfo.icon,
			atlas = iconInfo.atlas,
			fallbackAtlas = iconInfo.fallbackAtlas,
			texture = iconInfo.texture,
			texCoord = CopyTexCoord(iconInfo.texCoord),
		}
	end
	return options
end

function FriendTags:GetIconInfo(iconID)
	local icon = GetIconInfo(iconID)
	return {
		iconType = icon.iconType,
		iconValue = icon.iconValue,
		icon = icon.icon,
		atlas = icon.atlas,
		fallbackAtlas = icon.fallbackAtlas,
		texture = icon.texture,
		texCoord = CopyTexCoord(icon.texCoord),
	}
end

function FriendTags:GetCustomTagDefinitions()
	local db = self:NormalizeDB()
	local definitions = {}
	for id, def in pairs(db.customFriendTags) do
		if type(def) == "table" and def.enabled ~= false then
			local name = NormalizeTagName(def.name)
			if name then
				local icon = CopyIconInfo(def, GetIconInfo("tag"))
				definitions[#definitions + 1] = {
					id = id,
					source = SOURCE_CUSTOM,
					name = name,
					order = tonumber(def.order) or 0,
					color = CopyColor(def.color, { r = 0.50, g = 0.78, b = 1.00, a = 1 }),
					iconType = icon.iconType,
					iconValue = icon.iconValue,
					icon = icon.icon,
					atlas = icon.atlas,
					fallbackAtlas = icon.fallbackAtlas,
					texture = icon.texture,
					texCoord = CopyTexCoord(icon.texCoord),
					createdAt = def.createdAt,
					updatedAt = def.updatedAt,
				}
			end
		end
	end
	table.sort(definitions, function(a, b)
		if a.order ~= b.order then
			return a.order < b.order
		end
		return (a.name or a.id) < (b.name or b.id)
	end)
	return definitions
end

function FriendTags:GetAllTagDefinitions()
	local definitions = {}
	for _, def in ipairs(self:GetBlizzardTagDefinitions()) do
		definitions[#definitions + 1] = def
	end
	for _, def in ipairs(self:GetCustomTagDefinitions()) do
		definitions[#definitions + 1] = def
	end
	table.sort(definitions, function(a, b)
		local aProfile = self:GetChipProfile(a)
		local bProfile = self:GetChipProfile(b)
		local aOrder = aProfile and aProfile.order or a.order or 0
		local bOrder = bProfile and bProfile.order or b.order or 0
		if aOrder ~= bOrder then
			return aOrder < bOrder
		end
		return (a.name or a.id) < (b.name or b.id)
	end)
	return definitions
end

function FriendTags:GetTagDefinition(tagId)
	if BLIZZARD_TAG_BY_ID[tagId] then
		for _, def in ipairs(self:GetBlizzardTagDefinitions()) do
			if def.id == tagId then
				return def
			end
		end
	end
	for _, def in ipairs(self:GetCustomTagDefinitions()) do
		if def.id == tagId then
			return def
		end
	end
	return nil
end

function FriendTags:GetDefaultChipProfile(tag)
	if type(tag) == "string" then
		tag = self:GetTagDefinition(tag)
	end
	if type(tag) ~= "table" then
		return nil
	end

	local defaultIcon = tag.defaultIcon and GetIconInfo(tag.defaultIcon) or GetIconInfo("tag")
	defaultIcon = CopyIconInfo(tag, defaultIcon)
	local defaultOrder = tonumber(tag.order) or (tag.source == SOURCE_CUSTOM and 1000 or 0)
	return {
		chipLabel = nil,
		iconType = defaultIcon.iconType,
		iconValue = defaultIcon.iconValue,
		icon = defaultIcon.icon,
		atlas = defaultIcon.atlas,
		fallbackAtlas = defaultIcon.fallbackAtlas,
		texture = defaultIcon.texture,
		texCoord = CopyTexCoord(defaultIcon.texCoord),
		color = CopyColor(tag.color, tag.source == SOURCE_BLIZZARD and { r = 0.50, g = 0.78, b = 1.00, a = 1 } or { r = 0.64, g = 0.86, b = 0.56, a = 1 }),
		textColor = { r = 1, g = 1, b = 1, a = 1 },
		visible = true,
		rowVisible = true,
		tooltipVisible = true,
		brokerVisible = true,
		order = defaultOrder,
	}
end

function FriendTags:PruneChipProfileOverride(tagId, profile)
	local defaultProfile = self:GetDefaultChipProfile(tagId)
	if type(defaultProfile) ~= "table" or type(profile) ~= "table" then
		return nil
	end

	local pruned = {}
	if profile.chipLabel ~= nil then
		pruned.chipLabel = tostring(profile.chipLabel)
	end
	if profile.iconType ~= nil and profile.iconType ~= defaultProfile.iconType then
		pruned.iconType = profile.iconType
	end
	if profile.iconValue ~= nil and profile.iconValue ~= defaultProfile.iconValue then
		pruned.iconValue = profile.iconValue
	end
	if profile.icon ~= nil and profile.icon ~= defaultProfile.icon then
		pruned.icon = profile.icon
	end
	if profile.atlas ~= nil and profile.atlas ~= defaultProfile.atlas then
		pruned.atlas = profile.atlas
	end
	if profile.fallbackAtlas ~= nil and profile.fallbackAtlas ~= defaultProfile.fallbackAtlas then
		pruned.fallbackAtlas = profile.fallbackAtlas
	end
	if profile.texture ~= nil and profile.texture ~= defaultProfile.texture then
		pruned.texture = profile.texture
	end
	if type(profile.texCoord) == "table" and not SameTexCoord(profile.texCoord, defaultProfile.texCoord) then
		pruned.texCoord = CopyTexCoord(profile.texCoord)
	end
	if profile.visible == false then
		pruned.visible = false
	end
	if profile.rowVisible == false then
		pruned.rowVisible = false
	end
	if profile.tooltipVisible == false then
		pruned.tooltipVisible = false
	end
	if profile.brokerVisible == false then
		pruned.brokerVisible = false
	end
	if tonumber(profile.order) and tonumber(profile.order) ~= tonumber(defaultProfile.order) then
		pruned.order = tonumber(profile.order)
	end
	if type(profile.color) == "table" and not SameColor(profile.color, defaultProfile.color) then
		pruned.color = CopyColor(profile.color)
	end
	if type(profile.textColor) == "table" and not SameColor(profile.textColor, defaultProfile.textColor) then
		pruned.textColor = CopyColor(profile.textColor)
	end

	return next(pruned) and pruned or nil
end

function FriendTags:GetChipProfile(tag)
	if type(tag) == "string" then
		tag = self:GetTagDefinition(tag)
	end
	if type(tag) ~= "table" then
		return nil
	end

	local db = self:NormalizeDB()
	local defaultProfile = self:GetDefaultChipProfile(tag)
	local override = CopyProfile(db.friendTagProfiles[tag.id])
	local iconType = override.iconType ~= nil and override.iconType or defaultProfile.iconType
	local iconValue = override.iconValue ~= nil and override.iconValue or defaultProfile.iconValue
	local legacyIcon = override.icon ~= nil and override.icon or defaultProfile.icon
	local atlas = override.atlas ~= nil and override.atlas or defaultProfile.atlas
	local fallbackAtlas = override.fallbackAtlas ~= nil and override.fallbackAtlas or defaultProfile.fallbackAtlas
	local texture = override.texture ~= nil and override.texture or defaultProfile.texture
	local texCoord = override.texCoord ~= nil and CopyTexCoord(override.texCoord) or CopyTexCoord(defaultProfile.texCoord)
	if iconType == "none" or iconType == false or iconValue == false or legacyIcon == false then
		iconValue = nil
		legacyIcon = nil
		atlas = nil
		fallbackAtlas = nil
		texture = nil
		texCoord = nil
	end

	return {
		chipLabel = override.chipLabel,
		iconType = iconType,
		iconValue = iconValue,
		icon = iconType == "atlas" and (iconValue or atlas or fallbackAtlas) or texture or legacyIcon or iconValue,
		atlas = atlas,
		fallbackAtlas = fallbackAtlas,
		texture = texture,
		texCoord = texCoord,
		visible = NormalizeBoolean(override.visible, defaultProfile.visible),
		rowVisible = NormalizeBoolean(override.rowVisible, defaultProfile.rowVisible),
		tooltipVisible = NormalizeBoolean(override.tooltipVisible, defaultProfile.tooltipVisible),
		brokerVisible = NormalizeBoolean(override.brokerVisible, defaultProfile.brokerVisible),
		order = tonumber(override.order) or defaultProfile.order,
		color = CopyColor(override.color, defaultProfile.color),
		textColor = CopyColor(override.textColor, defaultProfile.textColor),
	}
end

function FriendTags:SetChipProfile(tagId, profilePatch, refreshCallback)
	if type(tagId) ~= "string" or type(profilePatch) ~= "table" or not self:GetTagDefinition(tagId) then
		return false
	end
	local db = self:NormalizeDB()
	if profilePatch.reset == true then
		db.friendTagProfiles[tagId] = nil
		RefreshSurfaces(refreshCallback)
		return true
	end

	local profile = CopyProfile(db.friendTagProfiles[tagId])
	local clearFields = type(profilePatch.clearFields) == "table" and profilePatch.clearFields or {}
	for field, shouldClear in pairs(clearFields) do
		if shouldClear then
			profile[field] = nil
		end
	end

	if profilePatch.chipLabel ~= nil then
		profile.chipLabel = profilePatch.chipLabel == false and nil or tostring(profilePatch.chipLabel)
	end
	if profilePatch.iconType ~= nil then
		profile.iconType = profilePatch.iconType == false and "none" or tostring(profilePatch.iconType)
	end
	if profilePatch.iconValue ~= nil then
		profile.iconValue = profilePatch.iconValue == false and false or tostring(profilePatch.iconValue)
		profile.icon = profile.iconValue
	end
	if profilePatch.icon ~= nil then
		profile.icon = profilePatch.icon == false and false or tostring(profilePatch.icon)
		if profilePatch.icon ~= false and profilePatch.iconValue == nil then
			profile.iconValue = profile.icon
			profile.iconType = profile.iconType or "texture"
		end
	end
	if profilePatch.atlas ~= nil then
		profile.atlas = profilePatch.atlas == false and nil or tostring(profilePatch.atlas)
	end
	if profilePatch.fallbackAtlas ~= nil then
		profile.fallbackAtlas = profilePatch.fallbackAtlas == false and nil or tostring(profilePatch.fallbackAtlas)
	end
	if profilePatch.texture ~= nil then
		profile.texture = profilePatch.texture == false and nil or tostring(profilePatch.texture)
	end
	if profilePatch.texCoord ~= nil then
		profile.texCoord = profilePatch.texCoord == false and nil or CopyTexCoord(profilePatch.texCoord)
	end
	if profilePatch.visible ~= nil then
		profile.visible = profilePatch.visible == true
	end
	if profilePatch.rowVisible ~= nil then
		profile.rowVisible = profilePatch.rowVisible == true
	end
	if profilePatch.tooltipVisible ~= nil then
		profile.tooltipVisible = profilePatch.tooltipVisible == true
	end
	if profilePatch.brokerVisible ~= nil then
		profile.brokerVisible = profilePatch.brokerVisible == true
	end
	if profilePatch.order ~= nil then
		profile.order = tonumber(profilePatch.order) or profile.order
	end
	if type(profilePatch.color) == "table" then
		profile.color = CopyColor(profilePatch.color)
	end
	if type(profilePatch.textColor) == "table" then
		profile.textColor = CopyColor(profilePatch.textColor)
	end

	db.friendTagProfiles[tagId] = self:PruneChipProfileOverride(tagId, profile)
	RefreshSurfaces(refreshCallback)
	return true
end

function FriendTags:ResetChipProfile(tagId, refreshCallback)
	return self:SetChipProfile(tagId, { reset = true }, refreshCallback)
end

function FriendTags:GetNativeBlizzardTagIdSet(friend)
	local result = {}
	if type(friend) ~= "table" or friend.type ~= "bnet" or not self:AreBlizzardTagsEnabled() then
		return result
	end

	local nativeTags = friend.friendTags
	if type(nativeTags) ~= "table" and friend.bnetAccountID and C_BattleNet and C_BattleNet.GetAccountInfoByID then
		local ok, accountInfo = pcall(C_BattleNet.GetAccountInfoByID, friend.bnetAccountID)
		if ok and type(accountInfo) == "table" then
			nativeTags = accountInfo.friendTags
		end
	end
	if type(nativeTags) ~= "table" then
		return result
	end

	local enumToId = GetEnumToTagIdMap()
	for _, enumValue in ipairs(nativeTags) do
		local tagId = enumToId[enumValue]
		if tagId then
			result[tagId] = true
		end
	end
	return result
end

function FriendTags:GetStoredBlizzardTagIdSet(friend, explicitUID)
	local db = self:NormalizeDB()
	local uid = self:GetFriendUID(friend, explicitUID)
	if not uid then
		return {}
	end
	return CopySet(db.friendBlizzardTags[uid])
end

function FriendTags:TryHandoffLocalBlizzardTags(friend, nativeSet)
	if type(friend) ~= "table" or friend.type ~= "bnet" or not friend.bnetAccountID then
		return false, nativeSet
	end
	if not self:AreBlizzardTagsEnabled() then
		return false, nativeSet
	end

	local uid = self:GetFriendUID(friend)
	if not uid or (self.migrationFailures and self.migrationFailures[uid]) then
		return false, nativeSet
	end

	local storedSet = self:GetStoredBlizzardTagIdSet(friend, uid)
	if not HasAny(storedSet) then
		return false, nativeSet
	end

	local merged = CopySet(nativeSet)
	for tagId, enabled in pairs(storedSet) do
		if enabled and BLIZZARD_TAG_BY_ID[tagId] then
			merged[tagId] = true
		end
	end

	local ok = self:SetBlizzardTagsForFriend(friend, merged, { suppressRefresh = true, userInitiated = true })
	if ok then
		return true, merged
	end

	self.migrationFailures = self.migrationFailures or {}
	self.migrationFailures[uid] = true
	return false, nativeSet
end

function FriendTags:GetBlizzardTagIdSetForFriend(friend, explicitUID)
	if type(friend) ~= "table" or friend.type ~= "bnet" then
		return {}
	end
	if self:AreBlizzardTagsEnabled() then
		local nativeSet = self:GetNativeBlizzardTagIdSet(friend)
		local uid = self:GetFriendUID(friend, explicitUID)
		local pendingSet = uid and self.pendingBlizzardTagSets and self.pendingBlizzardTagSets[uid]
		if HasAny(pendingSet) then
			return CopySet(pendingSet)
		end

		local storedSet = self:GetStoredBlizzardTagIdSet(friend, explicitUID)
		for tagId, enabled in pairs(storedSet) do
			if enabled and BLIZZARD_TAG_BY_ID[tagId] then
				nativeSet[tagId] = true
			end
		end
		return nativeSet
	end
	return self:GetStoredBlizzardTagIdSet(friend, explicitUID)
end

function FriendTags:SetBlizzardTagsForFriend(friend, tagIds, options)
	options = options or {}
	if type(friend) ~= "table" or friend.type ~= "bnet" then
		return false, "notBNet"
	end
	local uid = self:GetFriendUID(friend)
	if not uid then
		return false, "missingUID"
	end

	local desired = CopySet(tagIds)
	for tagId in pairs(desired) do
		if not BLIZZARD_TAG_BY_ID[tagId] then
			desired[tagId] = nil
		end
	end

	local db = self:NormalizeDB()
	if self:AreBlizzardTagsEnabled() and friend.bnetAccountID then
		if options.userInitiated ~= true then
			return false, "notUserInitiated"
		end
		local enumTags = {}
		for _, def in ipairs(BLIZZARD_TAGS) do
			if desired[def.id] then
				enumTags[#enumTags + 1] = GetEnumValue(def)
			end
		end
		local ok = pcall(C_BattleNet.SetFriendTags, friend.bnetAccountID, enumTags)
		if ok then
			db.friendBlizzardTags[uid] = nil
			self.pendingBlizzardTagSets = self.pendingBlizzardTagSets or {}
			self.pendingBlizzardTagSets[uid] = CopySet(desired)
			if not options.suppressRefresh then
				RefreshSurfaces(options.refreshCallback)
			else
				BFL.FriendTagsVersion = (BFL.FriendTagsVersion or 0) + 1
			end
			return true
		end
	end

	db.friendBlizzardTags[uid] = HasAny(desired) and desired or nil
	if self.pendingBlizzardTagSets then
		self.pendingBlizzardTagSets[uid] = nil
	end
	if not options.suppressRefresh then
		RefreshSurfaces(options.refreshCallback)
	else
		BFL.FriendTagsVersion = (BFL.FriendTagsVersion or 0) + 1
	end
	return true
end

function FriendTags:GetLocalBlizzardHandoffInfo(friend, explicitUID)
	if type(friend) ~= "table" or friend.type ~= "bnet" then
		return { available = false, count = 0, reason = "notBNet" }
	end
	if not self:AreBlizzardTagsEnabled() then
		return { available = false, count = 0, reason = "apiUnavailable" }
	end
	if not friend.bnetAccountID then
		return { available = false, count = 0, reason = "missingAccountID" }
	end
	local storedSet = self:GetStoredBlizzardTagIdSet(friend, explicitUID)
	return {
		available = HasAny(storedSet),
		count = CountSet(storedSet),
		tags = storedSet,
	}
end

function FriendTags:HandoffLocalBlizzardTagsForFriend(friend, refreshCallback, explicitUID)
	friend = self:NormalizeFriendContext(friend, explicitUID)
	local info = self:GetLocalBlizzardHandoffInfo(friend, explicitUID)
	if not info.available then
		return false, info.reason or "nothingToSync"
	end

	local merged = self:GetNativeBlizzardTagIdSet(friend)
	for tagId, enabled in pairs(info.tags or {}) do
		if enabled and BLIZZARD_TAG_BY_ID[tagId] then
			merged[tagId] = true
		end
	end

	return self:SetBlizzardTagsForFriend(friend, merged, {
		refreshCallback = refreshCallback,
		userInitiated = true,
	})
end

function FriendTags:GetLocalBlizzardTagAssignmentCount()
	local db = self:NormalizeDB()
	local friendCount = 0
	local tagCount = 0
	for _, set in pairs(db.friendBlizzardTags or {}) do
		local count = CountSet(set)
		if count > 0 then
			friendCount = friendCount + 1
			tagCount = tagCount + count
		end
	end
	return friendCount, tagCount
end

function FriendTags:HandoffKnownLocalBlizzardTags(refreshCallback)
	if not self:AreBlizzardTagsEnabled() then
		return 0, "apiUnavailable"
	end

	local FriendsList = BFL:GetModule("FriendsList")
	local friends = FriendsList and FriendsList.friendsList
	if type(friends) ~= "table" then
		return 0, "missingFriendsList"
	end

	local synced = 0
	local failed = 0
	for _, friend in ipairs(friends) do
		if type(friend) == "table" and friend.type == "bnet" then
			local ok = self:HandoffLocalBlizzardTagsForFriend(friend, nil, friend.uid)
			if ok then
				synced = synced + 1
			elseif self:GetLocalBlizzardHandoffInfo(friend, friend.uid).available then
				failed = failed + 1
			end
		end
	end

	if synced > 0 then
		RefreshSurfaces(refreshCallback)
	end
	return synced, failed > 0 and "partial" or nil
end

function FriendTags:GetCustomTagIdSetForFriend(friend, explicitUID)
	local db = self:NormalizeDB()
	local result = {}
	for _, uid in ipairs(self:GetRelatedFriendUIDs(friend, explicitUID)) do
		local set = db.friendCustomTags[uid]
		if type(set) == "table" then
			for tagId, enabled in pairs(set) do
				if enabled == true then
					result[tagId] = true
				end
			end
		end
	end
	return result
end

function FriendTags:IsCustomTag(tagId)
	return type(tagId) == "string" and tagId:match("^" .. CUSTOM_PREFIX) ~= nil and self:GetTagDefinition(tagId) ~= nil
end

function FriendTags:SetCustomTagsForFriend(friend, tagIds, refreshCallback, explicitUID)
	local db = self:NormalizeDB()
	local uid = self:GetFriendUID(friend, explicitUID)
	if not uid then
		return false, "missingUID"
	end

	local desired = CopySet(tagIds)
	local filtered = {}
	for tagId, enabled in pairs(desired) do
		if enabled and self:IsCustomTag(tagId) then
			filtered[tagId] = true
		end
	end

	db.friendCustomTags[uid] = HasAny(filtered) and filtered or nil
	RefreshSurfaces(refreshCallback)
	return true
end

function FriendTags:SetCustomTagForFriend(friend, tagId, enabled, refreshCallback)
	local db = self:NormalizeDB()
	local uid = self:GetFriendUID(friend)
	if not uid or type(tagId) ~= "string" then
		return false
	end
	if not db.customFriendTags[tagId] then
		return false, "unknownTag"
	end
	local set = CopySet(db.friendCustomTags[uid])
	set[tagId] = enabled == true or nil
	db.friendCustomTags[uid] = HasAny(set) and set or nil
	RefreshSurfaces(refreshCallback)
	return true
end

function FriendTags:CreateCustomTag(name, refreshCallback)
	name = NormalizeTagName(name)
	if not name then
		return nil, "invalidName"
	end

	local db = self:NormalizeDB()
	local normalizedName = name:lower()
	for id, def in pairs(db.customFriendTags) do
		if type(def) == "table" and type(def.name) == "string" and def.name:lower() == normalizedName then
			return id, "exists"
		end
	end

	local id = CUSTOM_PREFIX .. tostring(db.nextCustomFriendTagID)
	db.nextCustomFriendTagID = db.nextCustomFriendTagID + 1
	local now = time and time() or 0
	db.customFriendTags[id] = {
		id = id,
		name = name,
		source = SOURCE_CUSTOM,
		enabled = true,
		order = db.nextCustomFriendTagID,
		createdAt = now,
		updatedAt = now,
		color = { r = 0.64, g = 0.86, b = 0.56, a = 1 },
		iconType = "texture",
		iconValue = TAG_ICON,
		icon = TAG_ICON,
	}
	RefreshSurfaces(refreshCallback)
	return id
end

function FriendTags:AddCustomTag(name, refreshCallback)
	return self:CreateCustomTag(name, refreshCallback)
end

function FriendTags:RenameCustomTag(tagId, name, refreshCallback)
	name = NormalizeTagName(name)
	local db = self:NormalizeDB()
	local def = type(tagId) == "string" and db.customFriendTags[tagId]
	if type(def) ~= "table" or not name then
		return false, "invalidTag"
	end

	local normalizedName = name:lower()
	for id, otherDef in pairs(db.customFriendTags) do
		if id ~= tagId and type(otherDef) == "table" and type(otherDef.name) == "string" and otherDef.name:lower() == normalizedName then
			return false, "exists"
		end
	end

	def.name = name
	def.updatedAt = time and time() or def.updatedAt
	RefreshSurfaces(refreshCallback)
	return true
end

function FriendTags:DeleteCustomTag(tagId, refreshCallback)
	local db = self:NormalizeDB()
	if type(tagId) ~= "string" or type(db.customFriendTags[tagId]) ~= "table" then
		return false, "invalidTag"
	end

	db.customFriendTags[tagId] = nil
	db.friendTagProfiles[tagId] = nil
	for uid, set in pairs(db.friendCustomTags or {}) do
		if type(set) == "table" and set[tagId] then
			set[tagId] = nil
			if not HasAny(set) then
				db.friendCustomTags[uid] = nil
			end
		end
	end
	RefreshSurfaces(refreshCallback)
	return true
end

function FriendTags:GetChipLabel(tag)
	if type(tag) ~= "table" then
		return nil
	end
	local profile = tag.chipProfile or self:GetChipProfile(tag)
	if type(profile) == "table" and profile.chipLabel ~= nil then
		return profile.chipLabel
	end
	return tag.name
end

function FriendTags:ShouldIncludeTagOnSurface(tag, surface)
	if type(tag) ~= "table" then
		return false
	end
	local profile = tag.chipProfile or self:GetChipProfile(tag)
	if type(profile) ~= "table" or profile.visible == false then
		return false
	end
	if surface == "row" and profile.rowVisible == false then
		return false
	end
	if surface == "tooltip" and profile.tooltipVisible == false then
		return false
	end
	if surface == "broker" and profile.brokerVisible == false then
		return false
	end
	if surface == "search" then
		if tag.source == SOURCE_BLIZZARD and self:GetSetting("includeBlizzardTagsInSearch", true) ~= true then
			return false
		end
		if tag.source == SOURCE_CUSTOM and self:GetSetting("includeCustomTagsInSearch", true) ~= true then
			return false
		end
	end
	return true
end

function FriendTags:GetTagsForFriend(friend, surface)
	if not self:CanDisplayTags(surface) then
		return {}
	end

	local tags = {}
	local seen = {}

	if type(friend) == "table" and friend.type == "bnet" then
		local blizzardSet = self:GetBlizzardTagIdSetForFriend(friend)
		for _, def in ipairs(self:GetBlizzardTagDefinitions()) do
			if blizzardSet[def.id] then
				local tag = {
					id = def.id,
					source = SOURCE_BLIZZARD,
					name = def.name or GetLocalizedTagName(def),
					group = def.group,
					color = def.color,
					iconType = def.iconType or "texture",
					iconValue = def.iconValue or def.icon,
					icon = def.icon or TAG_ICON,
					atlas = def.atlas,
					fallbackAtlas = def.fallbackAtlas,
					texture = def.texture,
					texCoord = CopyTexCoord(def.texCoord),
					order = def.order,
				}
				tag.chipProfile = self:GetChipProfile(tag)
				if self:ShouldIncludeTagOnSurface(tag, surface) then
					tags[#tags + 1] = tag
					seen[tag.source .. ":" .. tag.name:lower()] = true
				end
			end
		end
	end

	local customSet = self:GetCustomTagIdSetForFriend(friend)
	for _, def in ipairs(self:GetCustomTagDefinitions()) do
		if customSet[def.id] then
				local tag = {
					id = def.id,
					source = SOURCE_CUSTOM,
					name = def.name,
					color = def.color,
					iconType = def.iconType,
					iconValue = def.iconValue,
					icon = def.icon or TAG_ICON,
					atlas = def.atlas,
					fallbackAtlas = def.fallbackAtlas,
					texture = def.texture,
					texCoord = CopyTexCoord(def.texCoord),
					order = def.order,
				}
				tag.chipProfile = self:GetChipProfile(tag)
				if self:ShouldIncludeTagOnSurface(tag, surface) then
					tags[#tags + 1] = tag
					seen[tag.source .. ":" .. tag.name:lower()] = true
				end
		end
	end

	table.sort(tags, function(a, b)
		local aOrder = GetTagSortOrder(a)
		local bOrder = GetTagSortOrder(b)
		if aOrder ~= bOrder then
			return aOrder < bOrder
		end
		return (a.name or a.id) < (b.name or b.id)
	end)
	return tags
end

function FriendTags:GetTagIdsForFriend(friend, surface)
	local tagIds = {}
	for _, tag in ipairs(self:GetTagsForFriend(friend, surface)) do
		tagIds[#tagIds + 1] = tag.id
	end
	return tagIds
end

function FriendTags:GetSearchText(friend)
	if not self:CanDisplayTags("search") then
		return ""
	end
	local tags = self:GetTagsForFriend(friend, "search")
	if #tags == 0 then
		return ""
	end
	local parts = {}
	for _, tag in ipairs(tags) do
		parts[#parts + 1] = tag.name
		local chipLabel = self:GetChipLabel(tag)
		if chipLabel and chipLabel ~= "" and chipLabel ~= tag.name then
			parts[#parts + 1] = chipLabel
		end
	end
	return table.concat(parts, " ")
end

function FriendTags:GetTooltipTextForFriend(friend, includeLegacy)
	if not self:CanDisplayTags("tooltip") then
		return nil
	end
	local tags = self:GetTagsForFriend(friend, "tooltip")
	if #tags == 0 then
		return nil
	end
	local maxTags = tonumber(self:GetSetting("maxTooltipChips", 8)) or 8
	local names = {}
	for _, tag in ipairs(tags) do
		if includeLegacy ~= false or not tag.legacy then
			names[#names + 1] = tag.name
		end
	end
	if #names == 0 then
		return nil
	end
	local visibleNames = {}
	for index, name in ipairs(names) do
		if index > maxTags then
			visibleNames[#visibleNames + 1] = string.format("+%d", #names - maxTags)
			break
		end
		visibleNames[#visibleNames + 1] = name
	end
	return table.concat(visibleNames, ", ")
end

function FriendTags:GetBrokerTextForFriend(friend)
	if not self:CanDisplayTags("broker") then
		return nil
	end
	local tags = self:GetTagsForFriend(friend, "broker")
	if #tags == 0 then
		return nil
	end
	local maxTags = tonumber(self:GetSetting("maxTooltipChips", 8)) or 8
	local names = {}
	for index, tag in ipairs(tags) do
		if index > maxTags then
			names[#names + 1] = string.format("+%d", #tags - maxTags)
			break
		end
		names[#names + 1] = tag.name
	end
	return table.concat(names, ", ")
end

function FriendTags:FriendHasTag(friend, query, surface)
	query = Trim(query)
	if not query then
		return false
	end
	local normalized = query:lower()
	for _, tag in ipairs(self:GetTagsForFriend(friend, surface or "group")) do
		if tag.id == query or (tag.name and tag.name:lower() == normalized) then
			return true
		end
		local chipLabel = self:GetChipLabel(tag)
		if chipLabel and chipLabel ~= "" and chipLabel:lower() == normalized then
			return true
		end
	end
	return false
end

function FriendTags:GetTagSourceText(friend)
	local hasBlizzard = false
	local hasCustom = false
	for _, tag in ipairs(self:GetTagsForFriend(friend, "search")) do
		if tag.source == SOURCE_BLIZZARD then
			hasBlizzard = true
		elseif tag.source == SOURCE_CUSTOM then
			hasCustom = true
		end
	end
	if hasBlizzard and hasCustom then
		return "blizzard custom"
	elseif hasBlizzard then
		return "blizzard"
	elseif hasCustom then
		return "custom"
	end
	return ""
end

function FriendTags:GetTagCount(friend)
	return #self:GetTagsForFriend(friend, "search")
end

function FriendTags:ShowCustomTagDialog(friend, displayName, refreshCallback)
	StaticPopup_Show("BFL_FRIEND_TAGS_CREATE_CUSTOM_TAG", displayName or T("FRIEND_TAGS_CUSTOM_SECTION", "Custom Tags"), nil, {
		friend = friend,
		refreshCallback = refreshCallback,
	})
end

function FriendTags:OpenSettings(tagId)
	local Settings = BFL:GetModule("Settings")
	if Settings and Settings.IsSettingsCenterEnabled and Settings:IsSettingsCenterEnabled() then
		local Designer = BFL:GetModule("SettingsDesigner")
		if Designer and Designer.Show then
			Designer:Show("groups.friendtags", tagId)
			return true
		end
	end
	if Settings and Settings.ShowLegacy then
		Settings:ShowLegacy(13, tagId)
		return true
	elseif Settings and Settings.Show then
		Settings:Show("groups.friendtags", tagId)
		return true
	end
	return false
end

function FriendTags:PopulateMenuContent(submenu, friend, explicitUID, displayName, refreshCallback, options)
	if not submenu or not submenu.CreateTitle or not self:IsEnabled() then
		return false
	end
	options = options or {}
	friend = self:NormalizeFriendContext(friend, explicitUID)

	if options.showHeader and submenu.CreateTitle then
		submenu:CreateTitle(T("FRIEND_TAGS_MENU_TITLE", "Friend Tags"))
	end

	if friend.type == "bnet" then
		local sectionTitle = self:AreBlizzardTagsEnabled()
			and T("FRIEND_TAGS_BLIZZARD_SECTION", "Blizzard Tags")
			or T("FRIEND_TAGS_BLIZZARD_COMPAT_SECTION", "Blizzard-compatible Tags")
		submenu:CreateTitle(sectionTitle)

		local workingBlizzardSet = self:GetBlizzardTagIdSetForFriend(friend, explicitUID)
		local function CommitBlizzardTags()
			self:SetBlizzardTagsForFriend(friend, workingBlizzardSet, {
				refreshCallback = refreshCallback,
				userInitiated = true,
			})
		end

		local handoffInfo = self:GetLocalBlizzardHandoffInfo(friend, explicitUID)
		if handoffInfo.available then
			submenu:CreateButton(
				string.format(T("FRIEND_TAGS_SYNC_TO_BLIZZARD", "Sync %d local tags to Blizzard"), handoffInfo.count or 0),
				function()
					self:HandoffLocalBlizzardTagsForFriend(friend, refreshCallback, explicitUID)
				end
			)
			submenu:CreateDivider()
		end

		submenu:CreateTitle(T("FRIEND_TAGS_INTERESTS_SECTION", "Interests"))
		for _, def in ipairs(self:GetBlizzardTagDefinitions()) do
			if def.group == "roles" then
				if not submenu.bflRolesTitleCreated then
					submenu:CreateDivider()
					submenu:CreateTitle(T("FRIEND_TAGS_ROLES_SECTION", "Roles"))
					submenu.bflRolesTitleCreated = true
				end
			end
			local tagId = def.id
			submenu:CreateCheckbox(GetLocalizedTagName(def), function()
				return workingBlizzardSet[tagId] == true
			end, function()
				workingBlizzardSet[tagId] = not workingBlizzardSet[tagId] or nil
				CommitBlizzardTags()
				return MenuResponse and MenuResponse.Refresh
			end)
		end
		submenu:CreateDivider()
	end

	submenu:CreateTitle(T("FRIEND_TAGS_CUSTOM_SECTION", "Custom Tags"))
	submenu:CreateButton(T("FRIEND_TAGS_CREATE_CUSTOM", "Create Custom Tag"), function()
		self:ShowCustomTagDialog(friend, displayName, refreshCallback)
	end)

	local customTags = self:GetCustomTagDefinitions()
	if #customTags > 0 then
		for _, def in ipairs(customTags) do
			local tagId = def.id
			submenu:CreateCheckbox(def.name, function()
				return self:GetCustomTagIdSetForFriend(friend, explicitUID)[tagId] == true
			end, function()
				local selected = self:GetCustomTagIdSetForFriend(friend, explicitUID)[tagId] == true
				self:SetCustomTagForFriend(friend, tagId, not selected, refreshCallback)
				return MenuResponse and MenuResponse.Refresh
			end)
		end
	else
		submenu:CreateTitle(T("FRIEND_TAGS_NO_CUSTOM_TAGS", "No custom tags yet"))
	end

	submenu:CreateDivider()
	submenu:CreateButton(T("FRIEND_TAGS_MANAGE", "Manage Tags"), function()
		local Editor = BFL:GetModule("FriendTagEditor")
		if Editor and Editor.Show then
			Editor:Show()
		else
			self:OpenSettings()
		end
	end)

	return true
end

function FriendTags:PopulateMenu(rootDescription, friend, explicitUID, displayName, refreshCallback)
	if not rootDescription or not rootDescription.CreateButton or not self:IsEnabled() then
		return false
	end
	friend = self:NormalizeFriendContext(friend, explicitUID)

	local tags = self:GetTagsForFriend(friend, "menu")
	local title = T("FRIEND_TAGS_MENU_TITLE", "Friend Tags")
	if self:GetSetting("showMenuTagCounts", true) and #tags > 0 then
		title = string.format(T("FRIEND_TAGS_MENU_TITLE_COUNT", "Friend Tags (%d)"), #tags)
	end

	local submenu = rootDescription:CreateButton(title)
	if submenu.SetScrollMode then
		submenu:SetScrollMode(320)
	end

	return self:PopulateMenuContent(submenu, friend, explicitUID, displayName, refreshCallback)
end

function FriendTags:Initialize()
	self:NormalizeDB()
	self.migrationFailures = {}
	self.pendingBlizzardTagSets = {}

	StaticPopupDialogs["BFL_FRIEND_TAGS_CREATE_CUSTOM_TAG"] = {
		text = T("FRIEND_TAGS_CUSTOM_PROMPT", "Create custom friend tag for %s:"),
		button1 = ACCEPT,
		button2 = CANCEL,
		hasEditBox = true,
		editBoxWidth = 220,
		OnShow = function(dialog)
			local editBox = GetPopupEditBox(dialog)
			if editBox then
				editBox:SetText("")
				editBox:SetFocus()
			end
		end,
		OnAccept = function(dialog, data)
			local editBox = GetPopupEditBox(dialog)
			local tagId = FriendTags:CreateCustomTag(editBox and editBox:GetText())
			if tagId and data and data.friend then
				FriendTags:SetCustomTagForFriend(data.friend, tagId, true, data.refreshCallback)
			end
		end,
		EditBoxOnEnterPressed = function(editBox, data)
			local dialog = editBox:GetParent()
			local popupData = data or (dialog and dialog.data)
			local tagId = FriendTags:CreateCustomTag(editBox:GetText())
			if tagId and popupData and popupData.friend then
				FriendTags:SetCustomTagForFriend(popupData.friend, tagId, true, popupData.refreshCallback)
			end
			if dialog then
				dialog:Hide()
			end
		end,
		EditBoxOnEscapePressed = function(editBox)
			editBox:GetParent():Hide()
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = 3,
	}

	if BFL.RegisterEventCallback then
		if self:IsBlizzardTagAPIAvailable() then
			BFL:RegisterEventCallback("BATTLE_NET_FRIEND_TAG_ENABLED_STATUS_UPDATED", function()
				self.migrationFailures = {}
				RefreshSurfaces()
			end, 35)
		end
		BFL:RegisterEventCallback("BN_FRIEND_INFO_CHANGED", function()
			self.pendingBlizzardTagSets = {}
			BFL.FriendTagsVersion = (BFL.FriendTagsVersion or 0) + 1
		end, 85)
	end
end

return FriendTags
