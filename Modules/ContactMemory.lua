-- Modules/ContactMemory.lua
-- Local private notes and tags for friends and ignored contacts.

local ADDON_NAME, BFL = ...

local ContactMemory = BFL:RegisterModule("ContactMemory", {})

local CONTACT_MEMORY_VERSION = 1
local PLAYER_PREFIX = "player:"
local BNET_PREFIX = "bnet:"
local SETTINGS_DESIGNER_PAGE_ID = "advanced.beta"

local DEFAULT_SETTINGS = {
	showTooltipSection = true,
	hideInStreamerMode = true,
	nextTagId = 1,
}

local TAG_COLORS = {
	{ r = 0.36, g = 0.70, b = 1.00 },
	{ r = 0.48, g = 0.82, b = 0.42 },
	{ r = 1.00, g = 0.72, b = 0.28 },
	{ r = 0.92, g = 0.45, b = 0.58 },
	{ r = 0.72, g = 0.58, b = 1.00 },
}

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

local function CleanString(value)
	if IsSecret(value) or type(value) ~= "string" then
		return nil
	end
	value = value:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
	return Trim(value)
end

local function FirstCleanString(...)
	for i = 1, select("#", ...) do
		local cleanValue = CleanString(select(i, ...))
		if cleanValue then
			return cleanValue
		end
	end
	return nil
end

local function ShallowCopyColor(color)
	if type(color) ~= "table" then
		return nil
	end
	return {
		r = color.r or 1,
		g = color.g or 1,
		b = color.b or 1,
	}
end

local function GetPopupEditBox(dialog)
	return dialog and (dialog.EditBox or dialog.editBox)
end

local function HasAnyTags(tags)
	if type(tags) ~= "table" then
		return false
	end
	return next(tags) ~= nil
end

local function LocaleValue(key, fallback)
	local locale = BFL and (BFL.L or _G.BFL_L)
	local value = locale and locale[key]
	if value ~= nil and value ~= "" and value ~= key then
		return value
	end
	return fallback or key
end

local function RefreshSurfaces(refreshCallback)
	if type(refreshCallback) == "function" then
		refreshCallback()
	end
	if BFL and BFL.ForceRefreshFriendsList then
		BFL:ForceRefreshFriendsList()
	end
end

local function NotifySettingsChanged(refreshCallback)
	if BFL then
		BFL.SettingsVersion = (BFL.SettingsVersion or 0) + 1
		local FriendsList = BFL.GetModule and BFL:GetModule("FriendsList")
		if FriendsList and FriendsList.InvalidateSettingsCache then
			FriendsList:InvalidateSettingsCache()
		end
	end
	RefreshSurfaces(refreshCallback)
end

local function SafeTime()
	return time and time() or 0
end

local function DebugChatLine(message)
	message = tostring(message or "")
	if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
		DEFAULT_CHAT_FRAME:AddMessage("|cff33ccffBFL Contact Memory Debug|r " .. message)
	elseif BFL and BFL.DebugPrint then
		BFL:DebugPrint("ContactMemory Debug: " .. message)
	end
end

local function DebugFormatValue(value)
	if IsSecret(value) then
		return "<secret>"
	end
	if value == nil then
		return "<nil>"
	end
	if type(value) == "boolean" then
		return value and "true" or "false"
	end
	return tostring(value)
end

local function DebugFormatText(value, maxLength)
	value = DebugFormatValue(value)
	value = value:gsub("\r", "\\r"):gsub("\n", "\\n")
	maxLength = maxLength or 180
	if value:len() > maxLength then
		return value:sub(1, maxLength - 3) .. "..."
	end
	return value
end

local function DebugFormatList(values)
	if type(values) ~= "table" or #values == 0 then
		return "<none>"
	end
	return table.concat(values, ", ")
end

local function DebugCountMap(values)
	if type(values) ~= "table" then
		return 0
	end
	local count = 0
	for _ in pairs(values) do
		count = count + 1
	end
	return count
end

local function DebugStringMatches(value, needle, shortNeedle)
	if IsSecret(value) or value == nil then
		return false
	end
	local text = tostring(value):lower()
	return (needle and needle ~= "" and text:find(needle, 1, true))
		or (shortNeedle and shortNeedle ~= "" and text:find(shortNeedle, 1, true))
end

local function DebugAddTagIDs(target, tags)
	if type(tags) ~= "table" then
		return
	end
	for tagId, enabled in pairs(tags) do
		if enabled then
			target[#target + 1] = tostring(tagId)
		end
	end
	table.sort(target)
end

local function DebugGetStreamerActive()
	if BFL and BFL.StreamerMode and BFL.StreamerMode.IsActive then
		local ok, active = pcall(BFL.StreamerMode.IsActive, BFL.StreamerMode)
		if ok then
			return active == true
		end
		return "error: " .. tostring(active)
	end
	return false
end

function ContactMemory:NormalizeDB()
	if type(BetterFriendlistDB) ~= "table" then
		return nil
	end

	if type(BetterFriendlistDB.contactMemory) ~= "table" then
		BetterFriendlistDB.contactMemory = {}
	end

	local db = BetterFriendlistDB.contactMemory
	if db.version == nil then
		db.version = CONTACT_MEMORY_VERSION
	end
	if db.enabled == nil then
		db.enabled = false
	end
	if type(db.contacts) ~= "table" then
		db.contacts = {}
	end
	if type(db.tags) ~= "table" then
		db.tags = {}
	end
	if type(db.settings) ~= "table" then
		db.settings = {}
	end

	for key, value in pairs(DEFAULT_SETTINGS) do
		if db.settings[key] == nil then
			db.settings[key] = value
		end
	end

	return db
end

function ContactMemory:Initialize()
	self:NormalizeDB()

	StaticPopupDialogs["BFL_CONTACT_MEMORY_SET_NOTE"] = {
		text = (BFL.L and BFL.L.CONTACT_MEMORY_NOTE_PROMPT) or "Private note for %s:",
		button1 = ACCEPT,
		button2 = CANCEL,
		hasEditBox = true,
		editBoxWidth = 260,
		OnShow = function(dialog, data)
			local editBox = GetPopupEditBox(dialog)
			if editBox then
				editBox:SetText(data and data.note or "")
				editBox:SetFocus()
				editBox:HighlightText()
			end
		end,
		OnAccept = function(dialog, data)
			local editBox = GetPopupEditBox(dialog)
			if data and data.contactKey and editBox then
				ContactMemory:SetPrivateNote(data.contactKey, editBox:GetText())
				RefreshSurfaces(data.refreshCallback)
			end
		end,
		EditBoxOnEnterPressed = function(editBox, data)
			local dialog = editBox:GetParent()
			local popupData = data or (dialog and dialog.data)
			if popupData and popupData.contactKey then
				ContactMemory:SetPrivateNote(popupData.contactKey, editBox:GetText())
				RefreshSurfaces(popupData.refreshCallback)
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

	StaticPopupDialogs["BFL_CONTACT_MEMORY_CREATE_TAG"] = {
		text = (BFL.L and BFL.L.CONTACT_MEMORY_TAG_PROMPT) or "Create Contact Memory tag:",
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
			local tagName = editBox and editBox:GetText()
			local tagId = ContactMemory:CreateTag(tagName)
			if tagId and data and data.contactKey then
				ContactMemory:SetTag(data.contactKey, tagId, true)
				RefreshSurfaces(data.refreshCallback)
			end
		end,
		EditBoxOnEnterPressed = function(editBox, data)
			local dialog = editBox:GetParent()
			local popupData = data or (dialog and dialog.data)
			local tagId = ContactMemory:CreateTag(editBox:GetText())
			if tagId and popupData and popupData.contactKey then
				ContactMemory:SetTag(popupData.contactKey, tagId, true)
				RefreshSurfaces(popupData.refreshCallback)
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

	self:RegisterWithSettingsDesigner()
	self:RegisterDebugSlashCommand()
end

function ContactMemory:OnPlayerLogin()
	self:RegisterWithSettingsDesigner()
	self:RegisterDebugSlashCommand()
end

function ContactMemory:GetEnabledSetting()
	local db = self:NormalizeDB()
	return db ~= nil and db.enabled == true
end

function ContactMemory:IsEnabled()
	return self:GetEnabledSetting() and BetterFriendlistDB and BetterFriendlistDB.enableBetaFeatures == true
end

function ContactMemory:SetEnabled(enabled, refreshCallback)
	local db = self:NormalizeDB()
	if not db then
		return false
	end
	local newValue = enabled == true
	if db.enabled == newValue then
		return true
	end
	db.enabled = newValue
	NotifySettingsChanged(refreshCallback)
	return true
end

function ContactMemory:GetSettings()
	local db = self:NormalizeDB()
	return db and db.settings or DEFAULT_SETTINGS
end

function ContactMemory:GetSetting(key, defaultValue)
	local settings = self:GetSettings()
	if type(settings) == "table" and settings[key] ~= nil then
		return settings[key]
	end
	if defaultValue ~= nil then
		return defaultValue
	end
	return DEFAULT_SETTINGS[key]
end

function ContactMemory:SetSetting(key, value, refreshCallback)
	if DEFAULT_SETTINGS[key] == nil then
		return false
	end
	local db = self:NormalizeDB()
	if not db then
		return false
	end
	if db.settings[key] == value then
		return true
	end
	db.settings[key] = value
	NotifySettingsChanged(refreshCallback)
	return true
end

function ContactMemory:RegisterSettingsDesignerControls(app, options)
	if not (app and app.RegisterControl) then
		return false
	end
	options = options or {}
	local pageID = options.pageID or SETTINGS_DESIGNER_PAGE_ID
	local groupTitle = LocaleValue("CONTACT_MEMORY_TITLE", "Contact Memory")
	if app.GetPage and not app:GetPage(pageID) then
		return false
	end

	if app.RegisterGroup then
		app:RegisterGroup(pageID, {
			id = "contactMemory",
			title = groupTitle,
			order = options.groupOrder or 200,
		})
	end

	local function IsBetaEnabled()
		return type(BetterFriendlistDB) == "table" and BetterFriendlistDB.enableBetaFeatures == true
	end

	local function IsContactMemoryEnabled()
		return ContactMemory:IsEnabled()
	end

	app:RegisterControl(pageID, {
		id = "contactMemory.enabled",
		groupID = "contactMemory",
		groupTitle = groupTitle,
		type = "toggle",
		label = LocaleValue("CONTACT_MEMORY_SETTINGS_ENABLE", "Contact Memory (Beta)"),
		description = LocaleValue("CONTACT_MEMORY_SETTINGS_ENABLE_DESC", "Adds local private notes and tags for friends and ignored players."),
		default = false,
		order = 200,
		visibleWhen = IsBetaEnabled,
		refreshOnChange = true,
		keywords = { "contact", "memory", "notes", "tags", "friends", "ignore" },
		getValue = function()
			return ContactMemory:GetEnabledSetting()
		end,
		setValue = function(value)
			ContactMemory:SetEnabled(value == true)
		end,
	})

	app:RegisterControl(pageID, {
		id = "contactMemory.showTooltipSection",
		groupID = "contactMemory",
		groupTitle = groupTitle,
		type = "toggle",
		label = LocaleValue("CONTACT_MEMORY_SETTINGS_TOOLTIPS", "Show in Tooltips"),
		description = LocaleValue("CONTACT_MEMORY_SETTINGS_TOOLTIPS_DESC", "Show private notes and tags in supported friend and ignore tooltips."),
		default = true,
		order = 210,
		visibleWhen = IsBetaEnabled,
		parentCheck = IsContactMemoryEnabled,
		refreshOnChange = true,
		keywords = { "contact", "memory", "tooltip", "notes", "tags" },
		getValue = function()
			return ContactMemory:GetSetting("showTooltipSection", true) == true
		end,
		setValue = function(value)
			ContactMemory:SetSetting("showTooltipSection", value == true)
		end,
	})

	app:RegisterControl(pageID, {
		id = "contactMemory.hideInStreamerMode",
		groupID = "contactMemory",
		groupTitle = groupTitle,
		type = "toggle",
		label = LocaleValue("CONTACT_MEMORY_SETTINGS_HIDE_STREAMER", "Hide in Streamer Mode"),
		description = LocaleValue("CONTACT_MEMORY_SETTINGS_HIDE_STREAMER_DESC", "Hide Contact Memory notes and tags while Streamer Mode is active."),
		default = true,
		order = 220,
		visibleWhen = IsBetaEnabled,
		parentCheck = IsContactMemoryEnabled,
		refreshOnChange = true,
		keywords = { "contact", "memory", "streamer", "privacy", "notes", "tags" },
		getValue = function()
			return ContactMemory:GetSetting("hideInStreamerMode", true) == true
		end,
		setValue = function(value)
			ContactMemory:SetSetting("hideInStreamerMode", value == true)
		end,
	})

	return true
end

function ContactMemory:RegisterWithSettingsDesigner()
	local SettingsDesigner = BFL and BFL.GetModule and BFL:GetModule("SettingsDesigner")
	if not SettingsDesigner then
		return false
	end
	local settingsApp = SettingsDesigner.app
	if not settingsApp and SettingsDesigner.Register then
		settingsApp = SettingsDesigner:Register()
	end
	if not settingsApp then
		return false
	end
	return self:RegisterSettingsDesignerControls(settingsApp)
end

function ContactMemory:CanDisplayPrivateData()
	if not self:IsEnabled() then
		return false
	end

	if self:GetSetting("hideInStreamerMode", true) and BFL.StreamerMode and BFL.StreamerMode.IsActive and BFL.StreamerMode:IsActive() then
		return false
	end

	return true
end

function ContactMemory:GetContactKeyFromBattleTag(battleTag)
	local ContactIdentity = BFL:GetModule("ContactIdentity")
	if ContactIdentity and ContactIdentity.GetContactKeyFromBattleTag then
		return ContactIdentity:GetContactKeyFromBattleTag(battleTag)
	end
	if IsSecret(battleTag) then
		return nil
	end
	if type(battleTag) == "number" then
		return BNET_PREFIX .. tostring(battleTag)
	end
	battleTag = CleanString(battleTag)
	if not battleTag then
		return nil
	end
	return BNET_PREFIX .. battleTag
end

function ContactMemory:NormalizePlayerName(name, realm)
	local ContactIdentity = BFL:GetModule("ContactIdentity")
	if ContactIdentity and ContactIdentity.NormalizePlayerName then
		return ContactIdentity:NormalizePlayerName(name, realm)
	end
	name = CleanString(name)
	realm = CleanString(realm)
	if not name then
		return nil
	end

	if realm and not name:find("-", 1, true) then
		name = name .. "-" .. realm:gsub("%s+", "")
	elseif name:find("-", 1, true) then
		local characterName, realmName = strsplit("-", name, 2)
		if realmName and realmName ~= "" then
			name = characterName .. "-" .. realmName:gsub("%s+", "")
		end
	end

	if BFL.NormalizeWoWFriendName then
		name = BFL:NormalizeWoWFriendName(name)
	end
	return name
end

function ContactMemory:GetContactKeyFromPlayerName(name, realm)
	local ContactIdentity = BFL:GetModule("ContactIdentity")
	if ContactIdentity and ContactIdentity.GetContactKeyFromPlayerName then
		return ContactIdentity:GetContactKeyFromPlayerName(name, realm)
	end
	local normalizedName = self:NormalizePlayerName(name, realm)
	if not normalizedName then
		return nil
	end
	return PLAYER_PREFIX .. normalizedName
end

function ContactMemory:ResolveContactKeyFromFriend(friend)
	local ContactIdentity = BFL:GetModule("ContactIdentity")
	if ContactIdentity and ContactIdentity.ResolveContactKeyFromFriend then
		return ContactIdentity:ResolveContactKeyFromFriend(friend)
	end
	if IsSecret(friend) then
		return nil
	end

	if type(friend) == "string" then
		if friend:match("^bnet_") then
			return self:GetContactKeyFromBattleTag(friend:gsub("^bnet_", "", 1))
		end
		if friend:match("^wow_") then
			return self:GetContactKeyFromPlayerName(friend:gsub("^wow_", "", 1))
		end
		if friend:find("#", 1, true) then
			return self:GetContactKeyFromBattleTag(friend)
		end
		return self:GetContactKeyFromPlayerName(friend)
	end

	if type(friend) ~= "table" then
		return nil
	end

	local friendType
	if not IsSecret(friend.type) then
		friendType = friend.type
	end
	if friendType == "bnet" then
		local key = self:GetContactKeyFromBattleTag(friend.battleTag)
		if key then
			return key
		end
		local accountID = friend.bnetAccountID
		if not IsSecret(accountID) and accountID ~= nil then
			return self:GetContactKeyFromBattleTag(accountID)
		end
	end

	local gameAccountInfo = friend.gameAccountInfo
	if IsSecret(gameAccountInfo) or type(gameAccountInfo) ~= "table" then
		gameAccountInfo = nil
	end
	local name = FirstCleanString(friend.name, friend.characterName, gameAccountInfo and gameAccountInfo.characterName)
	local realm = FirstCleanString(friend.realmName, gameAccountInfo and gameAccountInfo.realmName)

	return self:GetContactKeyFromPlayerName(name, realm)
end

function ContactMemory:ResolveContactKeyFromContext(contextData)
	local ContactIdentity = BFL:GetModule("ContactIdentity")
	if ContactIdentity and ContactIdentity.ResolveContactKeyFromContext then
		return ContactIdentity:ResolveContactKeyFromContext(contextData)
	end
	if IsSecret(contextData) or type(contextData) ~= "table" then
		return nil
	end

	local key = self:GetContactKeyFromBattleTag(contextData.battleTag)
	if key then
		return key
	end

	local accountID = contextData.bnetIDAccount
	if not IsSecret(accountID) and accountID ~= nil then
		return self:GetContactKeyFromBattleTag(accountID)
	end

	return self:GetContactKeyFromPlayerName(
		FirstCleanString(contextData.name),
		FirstCleanString(contextData.server, contextData.realmName)
	)
end

function ContactMemory:ResolveContactKeyFromIgnore(squelchType, index)
	local ContactIdentity = BFL:GetModule("ContactIdentity")
	if ContactIdentity and ContactIdentity.ResolveContactKeyFromIgnore then
		return ContactIdentity:ResolveContactKeyFromIgnore(squelchType, index)
	end
	if not index then
		return nil
	end

	if squelchType == SQUELCH_TYPE_IGNORE and C_FriendList and C_FriendList.GetIgnoreName then
		local name = C_FriendList.GetIgnoreName(index)
		return self:GetContactKeyFromPlayerName(name), CleanString(name)
	end

	if squelchType == SQUELCH_TYPE_BLOCK_INVITE and BNGetBlockedInfo then
		local blockID, blockName = BNGetBlockedInfo(index)
		local key = self:GetContactKeyFromBattleTag(blockName)
		if not key and blockID then
			key = self:GetContactKeyFromBattleTag(blockID)
		end
		return key, CleanString(blockName)
	end

	return nil
end

function ContactMemory:GetContact(contactKey, create)
	local db = self:NormalizeDB()
	if not db or type(contactKey) ~= "string" or contactKey == "" then
		return nil
	end

	local contact = db.contacts[contactKey]
	if not contact and create then
		local now = SafeTime()
		contact = {
			tags = {},
			firstSeen = now,
			lastSeen = now,
			lastSeenSource = "manual",
		}
		db.contacts[contactKey] = contact
	end

	if contact then
		if type(contact.tags) ~= "table" then
			contact.tags = {}
		end
		if not contact.firstSeen then
			contact.firstSeen = SafeTime()
		end
	end

	return contact
end

function ContactMemory:UpsertContact(source, contactInfo)
	if type(contactInfo) ~= "table" then
		return nil
	end

	local key = contactInfo.key or self:ResolveContactKeyFromFriend(contactInfo)
	if not key then
		return nil
	end

	local contact = self:GetContact(key, true)
	if not contact then
		return nil
	end

	contact.lastSeen = SafeTime()
	contact.lastSeenSource = source or contact.lastSeenSource or "manual"
	contact.displayName = FirstCleanString(contactInfo.displayName) or contact.displayName
	contact.normalizedName = FirstCleanString(contactInfo.normalizedName) or contact.normalizedName
	contact.battleTag = FirstCleanString(contactInfo.battleTag) or contact.battleTag

	return key, contact
end

function ContactMemory:CleanupContact(contactKey)
	local db = self:NormalizeDB()
	local contact = db and db.contacts[contactKey]
	if not contact then
		return
	end
	if not contact.privateNote and not HasAnyTags(contact.tags) then
		db.contacts[contactKey] = nil
	end
end

function ContactMemory:SetPrivateNote(contactKey, note)
	local contact = self:GetContact(contactKey, true)
	if not contact then
		return false
	end

	note = CleanString(note)
	contact.privateNote = note
	contact.lastSeen = SafeTime()
	contact.lastSeenSource = "manual"
	self:CleanupContact(contactKey)
	return true
end

function ContactMemory:GetSortedTags()
	local db = self:NormalizeDB()
	local sorted = {}
	if not db then
		return sorted
	end

	for tagId, tag in pairs(db.tags) do
		if type(tag) == "table" then
			sorted[#sorted + 1] = {
				id = tagId,
				name = tag.name or tagId,
				order = tag.order or 0,
				color = tag.color,
			}
		end
	end

	table.sort(sorted, function(a, b)
		if a.order ~= b.order then
			return a.order < b.order
		end
		return tostring(a.name):lower() < tostring(b.name):lower()
	end)

	return sorted
end

function ContactMemory:CreateTag(name)
	local db = self:NormalizeDB()
	name = CleanString(name)
	if not db or not name then
		return nil
	end

	local baseId = name:lower():gsub("[^%w]+", "_"):gsub("^_+", ""):gsub("_+$", "")
	if baseId == "" then
		baseId = "tag"
	end

	local tagId = baseId
	local suffix = 1
	while db.tags[tagId] and db.tags[tagId].name ~= name do
		suffix = suffix + 1
		tagId = baseId .. "_" .. suffix
	end

	if not db.tags[tagId] then
		local order = db.settings.nextTagId or 1
		local color = TAG_COLORS[((order - 1) % #TAG_COLORS) + 1]
		db.tags[tagId] = {
			name = name,
			order = order,
			color = ShallowCopyColor(color),
		}
		db.settings.nextTagId = order + 1
	end

	return tagId
end

function ContactMemory:SetTag(contactKey, tagId, enabled)
	local db = self:NormalizeDB()
	if not db or not db.tags[tagId] then
		return false
	end

	local contact = self:GetContact(contactKey, enabled == true)
	if not contact then
		return false
	end

	if enabled then
		contact.tags[tagId] = true
	else
		contact.tags[tagId] = nil
	end

	contact.lastSeen = SafeTime()
	contact.lastSeenSource = "manual"
	self:CleanupContact(contactKey)
	return true
end

function ContactMemory:ClearTags(contactKey)
	local contact = self:GetContact(contactKey, false)
	if not contact then
		return
	end
	contact.tags = {}
	self:CleanupContact(contactKey)
end

function ContactMemory:GetContactTagNames(contactKey)
	local db = self:NormalizeDB()
	local contact = self:GetContact(contactKey, false)
	local names = {}
	if not db or not contact or type(contact.tags) ~= "table" then
		return names
	end

	for _, tag in ipairs(self:GetSortedTags()) do
		if contact.tags[tag.id] then
			names[#names + 1] = tag.name
		end
	end

	return names
end

local function AddUniqueKey(target, seen, key)
	if type(key) ~= "string" or key == "" or seen[key] then
		return
	end
	seen[key] = true
	target[#target + 1] = key
end

function ContactMemory:GetRelatedContactKeysFromFriend(friend, primaryKey)
	local keys = {}
	local seen = {}
	AddUniqueKey(keys, seen, primaryKey or self:ResolveContactKeyFromFriend(friend))

	if type(friend) == "string" then
		AddUniqueKey(keys, seen, self:ResolveContactKeyFromFriend(friend))
		return keys
	end
	if type(friend) ~= "table" then
		return keys
	end

	local gameAccountInfo = type(friend.gameAccountInfo) == "table" and friend.gameAccountInfo or nil
	if friend.type == "bnet" then
		AddUniqueKey(keys, seen, self:GetContactKeyFromBattleTag(friend.battleTag))
		AddUniqueKey(keys, seen, self:GetContactKeyFromBattleTag(friend.bnetAccountID))
		AddUniqueKey(keys, seen, self:GetContactKeyFromPlayerName(
			FirstCleanString(friend.characterName, gameAccountInfo and gameAccountInfo.characterName),
			FirstCleanString(friend.realmName, gameAccountInfo and gameAccountInfo.realmName)
		))
	else
		AddUniqueKey(keys, seen, self:GetContactKeyFromPlayerName(
			FirstCleanString(friend.name, friend.characterName),
			FirstCleanString(friend.realmName)
		))
	end

	return keys
end

function ContactMemory:FindTooltipContactKey(contactKeys)
	if type(contactKeys) ~= "table" then
		return nil
	end
	for _, contactKey in ipairs(contactKeys) do
		local contact = self:GetContact(contactKey, false)
		if contact and (contact.privateNote or HasAnyTags(contact.tags)) then
			return contactKey
		end
	end
	return contactKeys[1]
end

function ContactMemory:GetTooltipSummary(contactKey)
	if not self:CanDisplayPrivateData() then
		return nil
	end

	local settings = self:GetSettings()
	if self:GetSetting("showTooltipSection", settings.showTooltipSection ~= false) == false then
		return nil
	end

	local contact = self:GetContact(contactKey, false)
	if not contact then
		return nil
	end

	local note = contact.privateNote
	local tagNames = self:GetContactTagNames(contactKey)
	if not note and #tagNames == 0 then
		return nil
	end

	if note and note:len() > 260 then
		note = note:sub(1, 257) .. "..."
	end

	return {
		title = (BFL.L and BFL.L.CONTACT_MEMORY_TOOLTIP_TITLE) or "Contact Memory",
		note = note,
		tagsText = #tagNames > 0 and table.concat(tagNames, ", ") or nil,
	}
end

function ContactMemory:AddTooltipLines(tooltip, contactKey)
	if not tooltip or not tooltip.AddLine then
		return false
	end

	local summary = self:GetTooltipSummary(contactKey)
	if not summary then
		return false
	end

	return self:AddTooltipSummaryLines(tooltip, summary)
end

function ContactMemory:AddTooltipSummaryLines(tooltip, summary)
	if not tooltip or not tooltip.AddLine or type(summary) ~= "table" then
		return false
	end

	tooltip:AddLine(" ")
	tooltip:AddLine(summary.title, 1, 0.82, 0, true)
	if summary.tagsText then
		tooltip:AddLine(summary.tagsText, 0.50, 0.78, 1.00, true)
	end
	if summary.note then
		tooltip:AddLine(summary.note, 1, 1, 1, true)
	end
	if tooltip.Show then
		tooltip:Show()
	end
	return true
end

function ContactMemory:GetTooltipSummaryForFriend(friendData)
	local key = self:ResolveContactKeyFromFriend(friendData)
	if not key then
		return nil
	end
	local tooltipKey = self:FindTooltipContactKey(self:GetRelatedContactKeysFromFriend(friendData, key)) or key

	local displayName
	local battleTag
	if type(friendData) == "table" then
		displayName = FirstCleanString(friendData.name, friendData.accountName, friendData.battleTag)
		battleTag = FirstCleanString(friendData.battleTag)
	elseif type(friendData) == "string" then
		displayName = friendData:gsub("^bnet_", ""):gsub("^wow_", "")
	end

	self:UpsertContact("friend-tooltip", {
		key = key,
		displayName = displayName,
		battleTag = battleTag,
	})
	return self:GetTooltipSummary(tooltipKey), tooltipKey, key
end

function ContactMemory:AddTooltipLinesForFriend(tooltip, friendData)
	if not tooltip or not tooltip.AddLine then
		return false
	end

	local summary = self:GetTooltipSummaryForFriend(friendData)
	if not summary then
		return false
	end

	return self:AddTooltipSummaryLines(tooltip, summary)
end

function ContactMemory:AddTooltipLinesForIgnore(tooltip, squelchType, index)
	local key, displayName = self:ResolveContactKeyFromIgnore(squelchType, index)
	if not key then
		return false
	end
	self:UpsertContact("ignore-tooltip", { key = key, displayName = displayName })
	return self:AddTooltipLines(tooltip, key)
end

function ContactMemory:RegisterDebugSlashCommand()
	if self.debugSlashRegistered or not SlashCmdList then
		return self.debugSlashRegistered == true
	end

	self.debugSlashRegistered = true
	_G.SLASH_BFLCONTACTMEMORYDEBUG1 = "/bflcmdebug"
	_G.SLASH_BFLCONTACTMEMORYDEBUG2 = "/bflcontactdebug"
	SlashCmdList.BFLCONTACTMEMORYDEBUG = function(msg)
		ContactMemory:DebugFriendTooltip(msg)
	end
	return true
end

function ContactMemory:DebugDescribeContactKey(contactKey, prefix)
	prefix = prefix or ""
	if not contactKey then
		DebugChatLine(prefix .. "key=<nil>")
		return
	end

	local contact = self:GetContact(contactKey, false)
	if not contact then
		DebugChatLine(prefix .. "key=" .. DebugFormatValue(contactKey) .. " savedContact=false")
		return
	end

	local tagNames = self:GetContactTagNames(contactKey)
	local tagIDs = {}
	DebugAddTagIDs(tagIDs, contact.tags)
	DebugChatLine(prefix .. "key=" .. DebugFormatValue(contactKey) .. " savedContact=true")
	DebugChatLine(prefix .. "  note=" .. DebugFormatText(contact.privateNote))
	DebugChatLine(prefix .. "  tagNames=" .. DebugFormatList(tagNames) .. " tagIDs=" .. DebugFormatList(tagIDs))
	DebugChatLine(
		prefix .. "  meta displayName=" .. DebugFormatText(contact.displayName, 90)
			.. " normalizedName=" .. DebugFormatText(contact.normalizedName, 90)
			.. " battleTag=" .. DebugFormatText(contact.battleTag, 90)
			.. " lastSeenSource=" .. DebugFormatValue(contact.lastSeenSource)
	)

	local summary = self:GetTooltipSummary(contactKey)
	if summary then
		DebugChatLine(
			prefix .. "  summary title=" .. DebugFormatText(summary.title, 90)
				.. " tagsText=" .. DebugFormatText(summary.tagsText, 120)
				.. " note=" .. DebugFormatText(summary.note, 120)
		)
	else
		DebugChatLine(prefix .. "  summary=<nil>")
	end
end

function ContactMemory:DebugFriendTooltip(target)
	target = CleanString(target) or "Feya#2528"
	local targetLower = target:lower()
	local shortNeedle = targetLower:gsub("#.*$", "")
	local db = self:NormalizeDB()
	local settings = self:GetSettings()
	local FriendsList = BFL and BFL.GetModule and BFL:GetModule("FriendsList")

	DebugChatLine("START target=" .. DebugFormatValue(target) .. " command=/bflcmdebug [BattleTag]")
	DebugChatLine(
		"gates beta=" .. DebugFormatValue(BetterFriendlistDB and BetterFriendlistDB.enableBetaFeatures == true)
			.. " cmEnabledSetting=" .. DebugFormatValue(db and db.enabled == true)
			.. " isEnabled=" .. DebugFormatValue(self:IsEnabled())
			.. " showTooltips=" .. DebugFormatValue(self:GetSetting("showTooltipSection", true) == true)
			.. " hideStreamer=" .. DebugFormatValue(self:GetSetting("hideInStreamerMode", true) == true)
			.. " streamerActive=" .. DebugFormatValue(DebugGetStreamerActive())
			.. " canDisplayPrivateData=" .. DebugFormatValue(self:CanDisplayPrivateData())
	)
	DebugChatLine(
		"db contacts=" .. DebugFormatValue(DebugCountMap(db and db.contacts))
			.. " tagsTable=" .. DebugFormatValue(type(db and db.tags))
			.. " settings.showTooltipSectionRaw=" .. DebugFormatValue(settings and settings.showTooltipSection)
	)

	local directKeys = {}
	local directSeen = {}
	AddUniqueKey(directKeys, directSeen, self:GetContactKeyFromBattleTag(target))
	if target:find("-", 1, true) then
		AddUniqueKey(directKeys, directSeen, self:GetContactKeyFromPlayerName(target))
	end
	DebugChatLine("directKeys=" .. DebugFormatList(directKeys))
	for _, contactKey in ipairs(directKeys) do
		self:DebugDescribeContactKey(contactKey, "  direct ")
	end

	local matchingContacts = {}
	if db and type(db.contacts) == "table" then
		for contactKey, contact in pairs(db.contacts) do
			if DebugStringMatches(contactKey, targetLower, shortNeedle)
				or DebugStringMatches(contact.displayName, targetLower, shortNeedle)
				or DebugStringMatches(contact.normalizedName, targetLower, shortNeedle)
				or DebugStringMatches(contact.battleTag, targetLower, shortNeedle) then
				matchingContacts[#matchingContacts + 1] = contactKey
			end
		end
	end
	table.sort(matchingContacts)
	DebugChatLine("matchingSavedContacts=" .. DebugFormatValue(#matchingContacts))
	for index, contactKey in ipairs(matchingContacts) do
		if index > 10 then
			DebugChatLine("  savedContact output truncated after 10 matches")
			break
		end
		self:DebugDescribeContactKey(contactKey, "  saved ")
	end

	local friendCount = FriendsList and FriendsList.friendsList and #FriendsList.friendsList or 0
	DebugChatLine("friendsList.count=" .. DebugFormatValue(friendCount))

	local matchCount = 0
	if FriendsList and type(FriendsList.friendsList) == "table" then
		for friendIndex, friend in ipairs(FriendsList.friendsList) do
			local gameAccountInfo = type(friend.gameAccountInfo) == "table" and friend.gameAccountInfo or nil
			local matched = DebugStringMatches(friend.uid, targetLower, shortNeedle)
				or DebugStringMatches(friend.type, targetLower, shortNeedle)
				or DebugStringMatches(friend.name, targetLower, shortNeedle)
				or DebugStringMatches(friend.accountName, targetLower, shortNeedle)
				or DebugStringMatches(friend.battleTag, targetLower, shortNeedle)
				or DebugStringMatches(friend.bnetAccountID, targetLower, shortNeedle)
				or DebugStringMatches(friend.characterName, targetLower, shortNeedle)
				or DebugStringMatches(friend.realmName, targetLower, shortNeedle)
				or DebugStringMatches(gameAccountInfo and gameAccountInfo.characterName, targetLower, shortNeedle)
				or DebugStringMatches(gameAccountInfo and gameAccountInfo.realmName, targetLower, shortNeedle)

			if not matched and type(friend.gameAccounts) == "table" then
				for _, account in ipairs(friend.gameAccounts) do
					if DebugStringMatches(account.characterName, targetLower, shortNeedle)
						or DebugStringMatches(account.realmName, targetLower, shortNeedle)
						or DebugStringMatches(account.gameAccountID, targetLower, shortNeedle)
						or DebugStringMatches(account.playerGuid, targetLower, shortNeedle) then
						matched = true
						break
					end
				end
			end

			if matched then
				matchCount = matchCount + 1
				if matchCount > 5 then
					DebugChatLine("friend match output truncated after 5 matches")
					break
				end

				local displayName
				if FriendsList.GetDisplayName then
					local ok, value = pcall(FriendsList.GetDisplayName, FriendsList, friend)
					if ok then
						displayName = value
					end
				end

				local primaryKey = self:ResolveContactKeyFromFriend(friend)
				local relatedKeys = self:GetRelatedContactKeysFromFriend(friend, primaryKey)
				local tooltipKey = self:FindTooltipContactKey(relatedKeys)
				DebugChatLine(
					"friendMatch #" .. friendIndex
						.. " type=" .. DebugFormatValue(friend.type)
						.. " uid=" .. DebugFormatText(friend.uid, 90)
						.. " display=" .. DebugFormatText(displayName, 90)
				)
				DebugChatLine(
					"  accountName=" .. DebugFormatText(friend.accountName, 90)
						.. " battleTag=" .. DebugFormatText(friend.battleTag, 90)
						.. " bnetAccountID=" .. DebugFormatValue(friend.bnetAccountID)
				)
				DebugChatLine(
					"  character=" .. DebugFormatText(friend.characterName or friend.name, 90)
						.. " realm=" .. DebugFormatText(friend.realmName, 90)
						.. " connected=" .. DebugFormatValue(friend.connected)
				)
				DebugChatLine(
					"  gameAccountInfo char=" .. DebugFormatText(gameAccountInfo and gameAccountInfo.characterName, 90)
						.. " realm=" .. DebugFormatText(gameAccountInfo and gameAccountInfo.realmName, 90)
						.. " client=" .. DebugFormatValue(gameAccountInfo and gameAccountInfo.clientProgram)
						.. " gameAccountID=" .. DebugFormatValue(gameAccountInfo and gameAccountInfo.gameAccountID)
				)
				DebugChatLine(
					"  primaryKey=" .. DebugFormatValue(primaryKey)
						.. " relatedKeys=" .. DebugFormatList(relatedKeys)
						.. " tooltipKey=" .. DebugFormatValue(tooltipKey)
				)
				for _, contactKey in ipairs(relatedKeys) do
					self:DebugDescribeContactKey(contactKey, "  related ")
				end

				if type(friend.gameAccounts) == "table" then
					DebugChatLine("  gameAccounts.count=" .. DebugFormatValue(#friend.gameAccounts))
					for accountIndex, account in ipairs(friend.gameAccounts) do
						if accountIndex > 8 then
							DebugChatLine("    gameAccount output truncated after 8 entries")
							break
						end
						local accountKey = self:GetContactKeyFromPlayerName(account.characterName, account.realmName)
						DebugChatLine(
							"    #" .. accountIndex
								.. " char=" .. DebugFormatText(account.characterName, 80)
								.. " realm=" .. DebugFormatText(account.realmName, 80)
								.. " client=" .. DebugFormatValue(account.clientProgram)
								.. " key=" .. DebugFormatValue(accountKey)
						)
						self:DebugDescribeContactKey(accountKey, "      ")
					end
				end

				local fakeTooltip = {
					lines = {},
					AddLine = function(owner, text)
						owner.lines[#owner.lines + 1] = text or ""
					end,
					Show = function(owner)
						owner.shown = true
					end,
				}
				local ok, result = pcall(function()
					return ContactMemory:AddTooltipLinesForFriend(fakeTooltip, friend)
				end)
				DebugChatLine(
					"  AddTooltipLinesForFriend ok=" .. DebugFormatValue(ok)
						.. " result=" .. DebugFormatValue(result)
						.. " shown=" .. DebugFormatValue(fakeTooltip.shown)
						.. " lines=" .. DebugFormatValue(#fakeTooltip.lines)
				)
				for lineIndex, line in ipairs(fakeTooltip.lines) do
					DebugChatLine("    tooltipLine" .. lineIndex .. "=" .. DebugFormatText(line, 160))
				end
			end
		end
	end

	DebugChatLine("friendMatches=" .. DebugFormatValue(matchCount))
	DebugChatLine("END")
end

function ContactMemory:EnsureNoteDialog()
	if self.noteDialog then
		return self.noteDialog
	end

	local L = BFL.L or {}
	local frame = CreateFrame("Frame", "BFLContactMemoryNoteDialog", UIParent, "BasicFrameTemplateWithInset")
	frame:SetSize(500, 340)
	frame:SetPoint("CENTER")
	frame:SetFrameStrata("DIALOG")
	frame:SetClampedToScreen(true)
	frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
	frame:SetScript("OnHide", function(owner)
		owner.contactKey = nil
		owner.refreshCallback = nil
	end)
	frame:Hide()

	frame.title = frame:CreateFontString(nil, "OVERLAY", "BetterFriendlistFontHighlight")
	frame.title:SetPoint("TOP", 0, -6)
	frame.title:SetText(L.CONTACT_MEMORY_EDIT_NOTE or "Edit Private Note")

	frame.targetLabel = frame:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontNormal")
	frame.targetLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -36)
	frame.targetLabel:SetPoint("RIGHT", frame, "RIGHT", -18, 0)
	frame.targetLabel:SetHeight(18)
	frame.targetLabel:SetJustifyH("LEFT")

	local inputBackdrop = CreateFrame("Frame", nil, frame, "BackdropTemplate")
	inputBackdrop:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -60)
	inputBackdrop:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -34, 54)
	inputBackdrop:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8X8",
		edgeFile = "Interface\\Buttons\\WHITE8X8",
		edgeSize = 1,
	})
	inputBackdrop:SetBackdropColor(0.018, 0.016, 0.012, 0.92)
	inputBackdrop:SetBackdropBorderColor(0.42, 0.31, 0.10, 0.72)

	local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
	scrollFrame:SetPoint("TOPLEFT", inputBackdrop, "TOPLEFT", 8, -8)
	scrollFrame:SetPoint("BOTTOMRIGHT", inputBackdrop, "BOTTOMRIGHT", -24, 8)
	frame.scrollFrame = scrollFrame

	local editBox = CreateFrame("EditBox", nil, scrollFrame)
	editBox:SetMultiLine(true)
	editBox:SetAutoFocus(false)
	editBox:SetFontObject("BetterFriendlistFontHighlightSmall")
	editBox:SetTextInsets(2, 2, 2, 2)
	editBox:SetScript("OnEscapePressed", function()
		frame:Hide()
	end)
	editBox:SetScript("OnTabPressed", function(box)
		box:Insert("    ")
	end)
	scrollFrame:SetScrollChild(editBox)
	frame.editBox = editBox

	frame:SetScript("OnSizeChanged", function(owner, width, height)
		local editWidth = math.max(260, (width or 500) - 84)
		local editHeight = math.max(160, (height or 340) - 140)
		owner.editBox:SetSize(editWidth, editHeight)
	end)
	editBox:SetSize(416, 200)

	local clearButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	clearButton:SetSize(148, 24)
	clearButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 18, 18)
	clearButton:SetText(L.CONTACT_MEMORY_CLEAR_NOTE or "Clear Private Note")
	clearButton:SetNormalFontObject("BetterFriendlistFontNormal")
	clearButton:SetHighlightFontObject("BetterFriendlistFontHighlight")
	clearButton:SetScript("OnClick", function()
		if frame.contactKey then
			ContactMemory:SetPrivateNote(frame.contactKey, nil)
			RefreshSurfaces(frame.refreshCallback)
		end
		frame:Hide()
	end)

	local cancelButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	cancelButton:SetSize(96, 24)
	cancelButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -18, 18)
	cancelButton:SetText(CANCEL or "Cancel")
	cancelButton:SetNormalFontObject("BetterFriendlistFontNormal")
	cancelButton:SetHighlightFontObject("BetterFriendlistFontHighlight")
	cancelButton:SetScript("OnClick", function()
		frame:Hide()
	end)

	local saveButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	saveButton:SetSize(96, 24)
	saveButton:SetPoint("RIGHT", cancelButton, "LEFT", -8, 0)
	saveButton:SetText(SAVE or ACCEPT or "Save")
	saveButton:SetNormalFontObject("BetterFriendlistFontNormal")
	saveButton:SetHighlightFontObject("BetterFriendlistFontHighlight")
	saveButton:SetScript("OnClick", function()
		if frame.contactKey then
			ContactMemory:SetPrivateNote(frame.contactKey, frame.editBox:GetText())
			RefreshSurfaces(frame.refreshCallback)
		end
		frame:Hide()
	end)

	self.noteDialog = frame
	return frame
end

function ContactMemory:ShowNoteDialog(contactKey, displayName, refreshCallback)
	local contact = self:GetContact(contactKey, false)
	local dialog = self:EnsureNoteDialog()
	local prompt = (BFL.L and BFL.L.CONTACT_MEMORY_NOTE_PROMPT) or "Private note for %s:"
	dialog.contactKey = contactKey
	dialog.refreshCallback = refreshCallback
	dialog.title:SetText((BFL.L and BFL.L.CONTACT_MEMORY_EDIT_NOTE) or "Edit Private Note")
	dialog.targetLabel:SetText(string.format(prompt, displayName or contactKey or ""))
	dialog.editBox:SetText(contact and contact.privateNote or "")
	dialog.editBox:SetCursorPosition(dialog.editBox:GetNumLetters())
	dialog:Show()
	dialog:Raise()
	dialog.editBox:SetFocus()
	return dialog
end

function ContactMemory:ShowTagDialog(contactKey, refreshCallback)
	StaticPopup_Show("BFL_CONTACT_MEMORY_CREATE_TAG", nil, nil, {
		contactKey = contactKey,
		refreshCallback = refreshCallback,
	})
end

function ContactMemory:PopulateMenu(rootDescription, contactKey, displayName, refreshCallback)
	if not rootDescription or not rootDescription.CreateButton or not self:IsEnabled() or not contactKey then
		return false
	end

	self:UpsertContact("context-menu", { key = contactKey, displayName = displayName })

	local L = BFL.L or {}
	local contact = self:GetContact(contactKey, false)
	local submenu = rootDescription:CreateButton(L.CONTACT_MEMORY_TITLE or "Contact Memory")
	if submenu.SetScrollMode then
		submenu:SetScrollMode(260)
	end

	submenu:CreateButton(L.CONTACT_MEMORY_EDIT_NOTE or "Edit Private Note", function()
		self:ShowNoteDialog(contactKey, displayName, refreshCallback)
	end)

	if contact and contact.privateNote then
		submenu:CreateButton(L.CONTACT_MEMORY_CLEAR_NOTE or "Clear Private Note", function()
			self:SetPrivateNote(contactKey, nil)
			RefreshSurfaces(refreshCallback)
		end)
	end

	submenu:CreateDivider()
	submenu:CreateButton(L.CONTACT_MEMORY_CREATE_TAG or "Create Tag", function()
		self:ShowTagDialog(contactKey, refreshCallback)
	end)

	local tags = self:GetSortedTags()
	if #tags > 0 then
		submenu:CreateTitle(L.CONTACT_MEMORY_TAGS or "Tags")
		for _, tag in ipairs(tags) do
			local tagId = tag.id
			submenu:CreateCheckbox(tag.name, function()
				local current = self:GetContact(contactKey, false)
				return current and current.tags and current.tags[tagId] == true or false
			end, function()
				local current = self:GetContact(contactKey, false)
				local isSelected = current and current.tags and current.tags[tagId] == true
				self:SetTag(contactKey, tagId, not isSelected)
				RefreshSurfaces(refreshCallback)
			end)
		end
	else
		submenu:CreateTitle(L.CONTACT_MEMORY_NO_TAGS or "No tags yet")
	end

	local current = self:GetContact(contactKey, false)
	if current and HasAnyTags(current.tags) then
		submenu:CreateDivider()
		submenu:CreateButton(L.CONTACT_MEMORY_REMOVE_ALL_TAGS or "Remove All Tags", function()
			self:ClearTags(contactKey)
			RefreshSurfaces(refreshCallback)
		end)
	end

	return true
end

function ContactMemory:AddClassicDropdownButton(text, level, func, checked)
	if not UIDropDownMenu_CreateInfo or not UIDropDownMenu_AddButton then
		return
	end
	local info = UIDropDownMenu_CreateInfo()
	info.text = text
	info.func = func
	info.checked = checked
	info.notCheckable = checked == nil
	info.keepShownOnClick = checked ~= nil
	UIDropDownMenu_AddButton(info, level)
end

function ContactMemory:OpenMenu(anchor, contactKey, displayName, refreshCallback)
	if not self:IsEnabled() or not contactKey then
		return false
	end

	if MenuUtil and MenuUtil.CreateContextMenu then
		MenuUtil.CreateContextMenu(anchor, function(owner, rootDescription)
			self:PopulateMenu(rootDescription, contactKey, displayName, refreshCallback)
		end)
		return true
	end

	if not (UIDropDownMenu_Initialize and ToggleDropDownMenu) then
		return false
	end

	if not self.dropdown then
		self.dropdown = CreateFrame("Frame", "BFLContactMemoryDropdown", UIParent, "UIDropDownMenuTemplate")
	end

	self:UpsertContact("context-menu", { key = contactKey, displayName = displayName })
	local L = BFL.L or {}
	UIDropDownMenu_Initialize(self.dropdown, function(dropdown, level)
		level = level or 1
		local title = UIDropDownMenu_CreateInfo()
		title.text = L.CONTACT_MEMORY_TITLE or "Contact Memory"
		title.isTitle = true
		title.notCheckable = true
		UIDropDownMenu_AddButton(title, level)

		self:AddClassicDropdownButton(L.CONTACT_MEMORY_EDIT_NOTE or "Edit Private Note", level, function()
			self:ShowNoteDialog(contactKey, displayName, refreshCallback)
		end)

		local contact = self:GetContact(contactKey, false)
		if contact and contact.privateNote then
			self:AddClassicDropdownButton(L.CONTACT_MEMORY_CLEAR_NOTE or "Clear Private Note", level, function()
				self:SetPrivateNote(contactKey, nil)
				RefreshSurfaces(refreshCallback)
			end)
		end

		self:AddClassicDropdownButton(L.CONTACT_MEMORY_CREATE_TAG or "Create Tag", level, function()
			self:ShowTagDialog(contactKey, refreshCallback)
		end)

		for _, tag in ipairs(self:GetSortedTags()) do
			local tagId = tag.id
			self:AddClassicDropdownButton(tag.name, level, function()
				local current = self:GetContact(contactKey, false)
				local isSelected = current and current.tags and current.tags[tagId] == true
				self:SetTag(contactKey, tagId, not isSelected)
				RefreshSurfaces(refreshCallback)
			end, contact and contact.tags and contact.tags[tagId] == true)
		end

		if contact and HasAnyTags(contact.tags) then
			self:AddClassicDropdownButton(L.CONTACT_MEMORY_REMOVE_ALL_TAGS or "Remove All Tags", level, function()
				self:ClearTags(contactKey)
				RefreshSurfaces(refreshCallback)
			end)
		end
	end, "MENU")

	ToggleDropDownMenu(1, nil, self.dropdown, anchor, 0, 0)
	return true
end

return ContactMemory
