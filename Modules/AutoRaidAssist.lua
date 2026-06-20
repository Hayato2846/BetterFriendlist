-- Modules/AutoRaidAssist.lua
-- Automatically promotes configured raid members to raid assistant.

local ADDON_NAME, BFL = ...

local AutoRaidAssist = BFL:RegisterModule("AutoRaidAssist", {})

local AUTO_RAID_ASSIST_VERSION = 1
local PROMOTION_COOLDOWN = 2.5
local PROMOTION_QUEUE_DELAY = 0.75
local PROMOTION_RETRY_GRACE = 0.25
local PROMOTION_MAX_ATTEMPTS = 3
local PROMOTION_ATTEMPT_RESET = 30
local EVALUATE_DELAY = 0.35
local GUILD_ROSTER_REFRESH_INTERVAL = 30
local MAX_SUGGESTIONS = 5
local MAX_TARGET_ROWS = 12
local SUGGESTION_ROW_HEIGHT = 40
local TARGET_ROW_HEIGHT = 40
local ROSTER_SETTLE_DELAYS = { 1.0, 2.5 }

local function L(key, fallback)
	local locale = BFL and (BFL.L or _G.BFL_L)
	local value = locale and locale[key]
	if value ~= nil and value ~= "" and value ~= key then
		return value
	end
	return fallback or key
end

local function GetContactIdentity()
	return BFL and BFL.GetModule and BFL:GetModule("ContactIdentity")
end

local function GetFriendsList()
	return BFL and BFL.GetModule and BFL:GetModule("FriendsList")
end

local function GetDB()
	return BFL and BFL.GetModule and BFL:GetModule("DB")
end

local function GetGuildRosterData()
	return BFL and BFL.GetModule and BFL:GetModule("GuildRosterData")
end

local function SafeTime()
	if GetTime then
		return GetTime()
	end
	if time then
		return time()
	end
	return 0
end

local function DebugValue(value)
	if value == nil then
		return "<nil>"
	end
	if value == true then
		return "true"
	end
	if value == false then
		return "false"
	end
	return tostring(value)
end

local function CountTableKeys(tableValue)
	local count = 0
	if type(tableValue) == "table" then
		for _ in pairs(tableValue) do
			count = count + 1
		end
	end
	return count
end

local function DebugLog(message, ...)
	if not (BFL and BFL.DebugPrint) then
		return
	end
	if select("#", ...) > 0 then
		local ok, formatted = pcall(string.format, tostring(message), ...)
		if ok then
			message = formatted
		end
	end
	BFL:DebugPrint("|cff00bfff[BFL Auto Assist]|r " .. tostring(message or ""))
end

local function IsWoWGameAccount(gameAccountInfo)
	if type(gameAccountInfo) ~= "table" then
		return false
	end
	if gameAccountInfo.isOnline == false then
		return false
	end
	local client = gameAccountInfo.clientProgram
	if client and client ~= BNET_CLIENT_WOW and client ~= "WoW" then
		return false
	end
	if gameAccountInfo.wowProjectID and WOW_PROJECT_ID and gameAccountInfo.wowProjectID ~= WOW_PROJECT_ID then
		return false
	end
	return true
end

local function AddSearchText(parts, value)
	if value ~= nil and value ~= "" and not (BFL.IsSecret and BFL:IsSecret(value)) then
		parts[#parts + 1] = tostring(value):lower()
	end
end

local function GetCurrentGroupLabel()
	if IsInRaid and IsInRaid() then
		return RAID or GROUP or "Raid"
	end
	return PARTY or GROUP or "Group"
end

local function SetFrameBackdrop(frame, r, g, b, a, br, bg, bb, ba)
	if not frame or not frame.SetBackdrop then
		return
	end
	frame:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8X8",
		edgeFile = "Interface\\Buttons\\WHITE8X8",
		edgeSize = 1,
	})
	frame:SetBackdropColor(r or 0.03, g or 0.025, b or 0.02, a or 0.65)
	frame:SetBackdropBorderColor(br or 0.18, bg or 0.14, bb or 0.08, ba or 0.72)
end

local function ApplyInlineButtonStyle(button, state)
	if not (button and button.SetBackdrop) then
		return
	end
	local bg = { 0.030, 0.026, 0.018, 0.90 }
	local border = { 0.48, 0.34, 0.10, 0.72 }
	local textColor = { 1, 0.82, 0, 1 }
	if state == "hover" then
		bg = { 0.085, 0.070, 0.035, 0.95 }
		border = { 0.92, 0.72, 0.20, 0.95 }
		textColor = { 1, 0.92, 0.45, 1 }
	elseif state == "disabled" then
		bg = { 0.018, 0.016, 0.012, 0.72 }
		border = { 0.20, 0.16, 0.08, 0.46 }
		textColor = { 0.45, 0.43, 0.36, 1 }
	end

	button:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8X8",
		edgeFile = "Interface\\Buttons\\WHITE8X8",
		edgeSize = 1,
	})
	button:SetBackdropColor(bg[1], bg[2], bg[3], bg[4])
	button:SetBackdropBorderColor(border[1], border[2], border[3], border[4])
	if button.Text then
		button.Text:SetTextColor(textColor[1], textColor[2], textColor[3], textColor[4])
	end
end

local function TryHookTableFunction(owner, methodName, callback)
	if not (hooksecurefunc and type(owner) == "table" and type(owner[methodName]) == "function") then
		return false
	end
	local ok = pcall(hooksecurefunc, owner, methodName, callback)
	return ok == true
end

local function TryHookGlobalFunction(functionName, callback)
	if not (hooksecurefunc and type(functionName) == "string" and type(_G[functionName]) == "function") then
		return false
	end
	local ok = pcall(hooksecurefunc, functionName, callback)
	return ok == true
end

local function CreateSmallButton(parent, text, width, options)
	options = options or {}
	if options.variant == "legacy" then
		local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
		button:SetSize(width or 76, 22)
		button:SetText(text or "")
		button:SetNormalFontObject("BetterFriendlistFontNormal")
		button:SetHighlightFontObject("BetterFriendlistFontHighlight")
		button:SetDisabledFontObject("BetterFriendlistFontDisable")
		return button
	end

	local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
	button:SetSize(width or 76, 22)
	button.Text = button:CreateFontString(nil, "OVERLAY", "BetterFriendlistFontHighlightSmall")
	button.Text:SetPoint("CENTER", 0, 1)
	button.Text:SetText(text or "")
	ApplyInlineButtonStyle(button)
	button:SetScript("OnEnter", function(owner)
		ApplyInlineButtonStyle(owner, "hover")
	end)
	button:SetScript("OnLeave", function(owner)
		ApplyInlineButtonStyle(owner)
	end)
	button:SetScript("OnDisable", function(owner)
		ApplyInlineButtonStyle(owner, "disabled")
	end)
	button:SetScript("OnEnable", function(owner)
		ApplyInlineButtonStyle(owner)
	end)
	return button
end

local function CreateLabel(parent, text, fontObject)
	local label = parent:CreateFontString(nil, "ARTWORK", fontObject or "BetterFriendlistFontHighlightSmall")
	label:SetText(text or "")
	label:SetJustifyH("LEFT")
	return label
end

local function NotifySettingsChanged()
	if BFL then
		BFL.SettingsVersion = (BFL.SettingsVersion or 0) + 1
	end
end

function AutoRaidAssist:NormalizeDB()
	if type(BetterFriendlistDB) ~= "table" then
		return nil
	end
	if type(BetterFriendlistDB.autoRaidAssist) ~= "table" then
		BetterFriendlistDB.autoRaidAssist = {}
	end

	local db = BetterFriendlistDB.autoRaidAssist
	if db.version == nil then
		db.version = AUTO_RAID_ASSIST_VERSION
	end
	if db.enabled == nil then
		db.enabled = false
	end
	if type(db.targets) ~= "table" then
		db.targets = {}
	end

	local ContactIdentity = GetContactIdentity()
	if ContactIdentity then
		local seen = {}
		local normalizedTargets = {}
		for _, target in ipairs(db.targets) do
			if type(target) == "table" then
				local key = target.key or target.id
				local kind, value = ContactIdentity:SplitContactKey(key)
				local lookupKey = ContactIdentity:NormalizeLookupKey(key)
				if kind and value and lookupKey and not seen[lookupKey] then
					seen[lookupKey] = true
					target.key = key
					target.id = key
					target.kind = kind
					target.value = value
					target.source = target.source or (kind == "bnet" and "bnetFriend" or "manual")
					normalizedTargets[#normalizedTargets + 1] = target
				end
			end
		end
		db.targets = normalizedTargets
	end

	return db
end

function AutoRaidAssist:Initialize()
	self.lastPromotionAttempt = {}
	self.promotionAttemptCounts = {}
	self.promotionQueue = {}
	self.promotionQueueLookup = {}
	self.promotionRetryTimers = {}
	self:NormalizeDB()
	DebugLog("Initialize enabled=%s targets=%d", DebugValue(self:IsEnabled()), self:GetTargetCount())
	self:RegisterEvents()
	self:RegisterWithSettingsDesigner()
end

function AutoRaidAssist:OnPlayerLogin()
	self:RegisterWithSettingsDesigner()
	DebugLog("PLAYER_LOGIN scheduling initial evaluation")
	self:ScheduleEvaluate("login", 1)
end

function AutoRaidAssist:RegisterEvents()
	if self.eventsRegistered then
		DebugLog("RegisterEvents skipped; events already registered")
		return
	end
	self.eventsRegistered = true
	DebugLog("RegisterEvents installing callbacks")

	local function Schedule(reason)
		DebugLog("Event trigger reason=%s -> ScheduleEvaluate", DebugValue(reason))
		AutoRaidAssist:ScheduleEvaluate(reason)
	end
	local function ScheduleRoster(reason)
		DebugLog("Roster event trigger reason=%s -> ScheduleRosterEvaluate", DebugValue(reason))
		AutoRaidAssist:ScheduleRosterEvaluate(reason)
	end

	BFL:RegisterEventCallback("GROUP_ROSTER_UPDATE", function()
		ScheduleRoster("group")
	end, 70)
	BFL:RegisterEventCallback("RAID_ROSTER_UPDATE", function()
		ScheduleRoster("raid")
	end, 70)
	BFL:RegisterEventCallback("PARTY_LEADER_CHANGED", function()
		ScheduleRoster("leader")
	end, 70)
	BFL:RegisterEventCallback("GROUP_FORMED", function()
		ScheduleRoster("group-formed")
	end, 70)
	BFL:RegisterEventCallback("GROUP_JOINED", function()
		ScheduleRoster("group-joined")
	end, 70)
	BFL:RegisterEventCallback("BN_FRIEND_INFO_CHANGED", function()
		Schedule("bnet")
	end, 80)
	BFL:RegisterEventCallback("BN_FRIEND_ACCOUNT_ONLINE", function()
		Schedule("bnet-online")
	end, 80)
	BFL:RegisterEventCallback("PLAYER_REGEN_ENABLED", function()
		if AutoRaidAssist.needsCombatRetry then
			AutoRaidAssist.needsCombatRetry = nil
			DebugLog("PLAYER_REGEN_ENABLED retrying after combat/restriction")
			Schedule("combat")
		else
			DebugLog("PLAYER_REGEN_ENABLED no pending combat retry")
		end
	end, 70)

	self:RegisterConversionHooks()
end

function AutoRaidAssist:RegisterConversionHooks()
	if self.conversionHooksRegistered then
		DebugLog("RegisterConversionHooks skipped; hooks already registered")
		return
	end
	self.conversionHooksRegistered = true

	local function ScheduleConversion()
		DebugLog("Convert-to-raid hook fired")
		AutoRaidAssist:ScheduleRosterEvaluate("convert-to-raid")
	end

	DebugLog("Hook BFL.ConvertToRaid installed=%s", DebugValue(TryHookTableFunction(BFL, "ConvertToRaid", ScheduleConversion)))

	if C_PartyInfo then
		DebugLog(
			"Hook C_PartyInfo.ConvertToRaid installed=%s",
			DebugValue(TryHookTableFunction(C_PartyInfo, "ConvertToRaid", ScheduleConversion))
		)
		DebugLog(
			"Hook C_PartyInfo.ConfirmConvertToRaid installed=%s",
			DebugValue(TryHookTableFunction(C_PartyInfo, "ConfirmConvertToRaid", ScheduleConversion))
		)
	else
		DebugLog("C_PartyInfo unavailable; skipping C_PartyInfo conversion hooks")
	end

	DebugLog("Hook global ConvertToRaid installed=%s", DebugValue(TryHookGlobalFunction("ConvertToRaid", ScheduleConversion)))
	DebugLog(
		"Hook global RaidFrame_ConvertToRaid installed=%s",
		DebugValue(TryHookGlobalFunction("RaidFrame_ConvertToRaid", ScheduleConversion))
	)
end

function AutoRaidAssist:GetDB()
	return self:NormalizeDB()
end

function AutoRaidAssist:GetEnabledSetting()
	local db = self:GetDB()
	return db ~= nil and db.enabled == true
end

function AutoRaidAssist:IsEnabled()
	return self:GetEnabledSetting()
end

function AutoRaidAssist:SetEnabled(enabled)
	local db = self:GetDB()
	if not db then
		DebugLog("SetEnabled(%s) failed: missingDB", DebugValue(enabled == true))
		return false
	end
	local newValue = enabled == true
	if db.enabled == newValue then
		DebugLog("SetEnabled(%s) skipped: already in requested state", DebugValue(newValue))
		return true
	end
	db.enabled = newValue
	DebugLog("SetEnabled changed enabled=%s targets=%d", DebugValue(newValue), self:GetTargetCount())
	NotifySettingsChanged()
	if newValue then
		self:ScheduleEvaluate("enabled")
	else
		self:ClearPromotionQueue()
		self:CancelPromotionRetryTimers()
		self.promotionAttemptCounts = {}
		self:CancelRosterRetryTimers()
		if self.pendingTimer and self.pendingTimer.Cancel then
			self.pendingTimer:Cancel()
		end
		self.pendingTimer = nil
		self.needsCombatRetry = nil
		DebugLog("SetEnabled disabled: pending timers and promotion queue cleared")
	end
	return true
end

function AutoRaidAssist:GetTargets()
	local db = self:GetDB()
	return db and db.targets or {}
end

function AutoRaidAssist:GetTargetCount()
	return #self:GetTargets()
end

function AutoRaidAssist:AddTarget(contactKey, source, displayName)
	local ContactIdentity = GetContactIdentity()
	if not ContactIdentity then
		DebugLog("AddTarget failed key=%s source=%s reason=missingIdentity", DebugValue(contactKey), DebugValue(source))
		return false, "missingIdentity"
	end
	local kind, value = ContactIdentity:SplitContactKey(contactKey)
	if not kind or not value then
		DebugLog("AddTarget failed key=%s source=%s reason=invalid", DebugValue(contactKey), DebugValue(source))
		return false, "invalid"
	end

	local db = self:GetDB()
	if not db then
		DebugLog("AddTarget failed key=%s source=%s reason=missingDB", DebugValue(contactKey), DebugValue(source))
		return false, "missingDB"
	end

	local lookupKey = ContactIdentity:NormalizeLookupKey(contactKey)
	for _, target in ipairs(db.targets) do
		if ContactIdentity:NormalizeLookupKey(target.key or target.id) == lookupKey then
			DebugLog("AddTarget skipped key=%s lookup=%s reason=duplicate", DebugValue(contactKey), DebugValue(lookupKey))
			return false, "duplicate"
		end
	end

	db.targets[#db.targets + 1] = {
		id = contactKey,
		key = contactKey,
		kind = kind,
		value = value,
		source = source or (kind == "bnet" and "bnetFriend" or "manual"),
		displayName = displayName,
		addedAt = time and time() or 0,
	}
	DebugLog(
		"AddTarget key=%s lookup=%s kind=%s source=%s display=%s totalTargets=%d",
		DebugValue(contactKey),
		DebugValue(lookupKey),
		DebugValue(kind),
		DebugValue(source),
		DebugValue(displayName),
		#db.targets
	)
	NotifySettingsChanged()
	self:ScheduleEvaluate("target-added")
	return true
end

function AutoRaidAssist:AddTargetFromFriend(friend)
	local ContactIdentity = GetContactIdentity()
	if not ContactIdentity then
		DebugLog("AddTargetFromFriend failed reason=missingIdentity")
		return false, "missingIdentity"
	end
	local key = ContactIdentity:ResolveContactKeyFromFriend(friend)
	if not key then
		DebugLog("AddTargetFromFriend failed reason=invalid")
		return false, "invalid"
	end
	local kind = ContactIdentity:SplitContactKey(key)
	local displayName = self:GetFriendDisplayName(friend)
	local source = kind == "bnet" and "bnetFriend" or "wowFriend"
	DebugLog("AddTargetFromFriend resolved key=%s source=%s display=%s", DebugValue(key), DebugValue(source), DebugValue(displayName))
	return self:AddTarget(key, source, displayName)
end

function AutoRaidAssist:AddTargetFromCandidate(candidate)
	if type(candidate) ~= "table" then
		DebugLog("AddTargetFromCandidate failed reason=invalid")
		return false, "invalid"
	end
	DebugLog(
		"AddTargetFromCandidate kind=%s key=%s display=%s source=%s",
		DebugValue(candidate.kind),
		DebugValue(candidate.key),
		DebugValue(candidate.displayName),
		DebugValue(candidate.source)
	)
	if candidate.friend then
		return self:AddTargetFromFriend(candidate.friend)
	end
	if candidate.key then
		return self:AddTarget(candidate.key, candidate.source or "manual", candidate.displayName)
	end
	return false, "invalid"
end

function AutoRaidAssist:AddManualCharacterTarget(value)
	local ContactIdentity = GetContactIdentity()
	if not ContactIdentity then
		DebugLog("AddManualCharacterTarget failed value=%s reason=missingIdentity", DebugValue(value))
		return false, "missingIdentity"
	end
	local cleanValue = ContactIdentity:CleanString(value)
	if not cleanValue or not cleanValue:find("-", 1, true) then
		DebugLog("AddManualCharacterTarget failed value=%s clean=%s reason=invalidCharacter", DebugValue(value), DebugValue(cleanValue))
		return false, "invalidCharacter"
	end
	local characterName, realmName = strsplit("-", cleanValue, 2)
	if not characterName or characterName == "" or not realmName or realmName == "" then
		DebugLog("AddManualCharacterTarget failed value=%s clean=%s reason=invalidCharacterParts", DebugValue(value), DebugValue(cleanValue))
		return false, "invalidCharacter"
	end
	local key = ContactIdentity:GetContactKeyFromPlayerName(characterName, realmName)
	if not key then
		DebugLog("AddManualCharacterTarget failed value=%s clean=%s reason=missingKey", DebugValue(value), DebugValue(cleanValue))
		return false, "invalidCharacter"
	end
	DebugLog("AddManualCharacterTarget resolved value=%s clean=%s key=%s", DebugValue(value), DebugValue(cleanValue), DebugValue(key))
	return self:AddTarget(key, "manual", ContactIdentity:NormalizePlayerName(characterName, realmName))
end

function AutoRaidAssist:RemoveTarget(contactKey)
	local ContactIdentity = GetContactIdentity()
	local db = self:GetDB()
	if not (ContactIdentity and db) then
		DebugLog("RemoveTarget failed key=%s reason=missingIdentityOrDB", DebugValue(contactKey))
		return false
	end
	local lookupKey = ContactIdentity:NormalizeLookupKey(contactKey)
	if not lookupKey then
		DebugLog("RemoveTarget failed key=%s reason=invalidLookup", DebugValue(contactKey))
		return false
	end
	for index, target in ipairs(db.targets) do
		if ContactIdentity:NormalizeLookupKey(target.key or target.id) == lookupKey then
			table.remove(db.targets, index)
			NotifySettingsChanged()
			self:RemoveQueuedPromotion(lookupKey)
			self:CancelPromotionRetryTimer(lookupKey)
			self:ResetPromotionAttemptCount(lookupKey)
			DebugLog("RemoveTarget key=%s lookup=%s remainingTargets=%d", DebugValue(contactKey), DebugValue(lookupKey), #db.targets)
			return true
		end
	end
	DebugLog("RemoveTarget skipped key=%s lookup=%s reason=notFound", DebugValue(contactKey), DebugValue(lookupKey))
	return false
end

function AutoRaidAssist:GetFriendDisplayName(friend)
	local FriendsList = GetFriendsList()
	if FriendsList and FriendsList.GetDisplayName and type(friend) == "table" then
		local name = FriendsList:GetDisplayName(friend)
		if name and name ~= "" then
			return name
		end
	end
	if type(friend) == "table" then
		return friend.displayName or friend.accountName or friend.battleTag or friend.name or friend.characterName
	end
	return nil
end

function AutoRaidAssist:FindFriendByContactKey(contactKey)
	local ContactIdentity = GetContactIdentity()
	local FriendsList = GetFriendsList()
	if not (ContactIdentity and FriendsList and FriendsList.friendsList) then
		return nil
	end
	local lookupKey = ContactIdentity:NormalizeLookupKey(contactKey)
	for _, friend in ipairs(FriendsList.friendsList) do
		local friendKey = ContactIdentity:ResolveContactKeyFromFriend(friend)
		if ContactIdentity:NormalizeLookupKey(friendKey) == lookupKey then
			return friend
		end
	end
	return nil
end

function AutoRaidAssist:RequestGuildRosterRefresh()
	local GuildRosterData = GetGuildRosterData()
	if not (GuildRosterData and GuildRosterData.RequestRosterUpdate) then
		return false
	end
	local now = SafeTime()
	if self.lastGuildRosterRequest and now - self.lastGuildRosterRequest < GUILD_ROSTER_REFRESH_INTERVAL then
		return false
	end
	self.lastGuildRosterRequest = now
	return GuildRosterData:RequestRosterUpdate()
end

function AutoRaidAssist:GetCurrentGroupCandidateUnits()
	local units = {}
	if IsInRaid and IsInRaid() then
		local count = GetNumGroupMembers and GetNumGroupMembers() or 0
		for index = 1, count do
			units[#units + 1] = "raid" .. index
		end
	elseif IsInGroup and IsInGroup() then
		local count = GetNumSubgroupMembers and GetNumSubgroupMembers() or 0
		for index = 1, count do
			units[#units + 1] = "party" .. index
		end
	end
	return units
end

function AutoRaidAssist:AddCurrentGroupCandidates(candidates, seen, query)
	local ContactIdentity = GetContactIdentity()
	if not ContactIdentity then
		return
	end

	local DB = GetDB()
	local groupLabel = GetCurrentGroupLabel()
	for _, unit in ipairs(self:GetCurrentGroupCandidateUnits()) do
		if (not UnitExists or UnitExists(unit)) and not (UnitIsUnit and UnitIsUnit(unit, "player")) then
			local key = self:GetUnitContactKey(unit)
			local lookupKey = ContactIdentity:NormalizeLookupKey(key)
			if key and lookupKey and not seen[lookupKey] then
				local name, realm
				if UnitFullName then
					name, realm = UnitFullName(unit)
				end
				if not name and UnitName then
					name, realm = UnitName(unit)
				end
				if (not realm or realm == "") and GetNormalizedRealmName then
					realm = GetNormalizedRealmName()
				end

				local _, value = ContactIdentity:SplitContactKey(key)
				local normalizedName = ContactIdentity:NormalizePlayerName(name, realm) or value
				local nicknameUID = normalizedName and ("wow_" .. normalizedName) or nil
				local nickname = nicknameUID and DB and DB.GetNickname and DB:GetNickname(nicknameUID) or nil
				local displayName = ContactIdentity:CleanString(name) or value or key
				local parts = {}
				AddSearchText(parts, displayName)
				AddSearchText(parts, nickname)
				AddSearchText(parts, normalizedName)
				AddSearchText(parts, value)
				AddSearchText(parts, realm)
				AddSearchText(parts, groupLabel)

				local haystack = table.concat(parts, " ")
				if query == "" or haystack:find(query, 1, true) then
					seen[lookupKey] = true
					candidates[#candidates + 1] = {
						key = key,
						kind = "player",
						value = normalizedName or value,
						source = "group",
						displayName = displayName,
						nickname = nickname,
						subtitle = groupLabel .. " - " .. tostring(normalizedName or value or ""),
					}
				end
			end
		end
	end
end

function AutoRaidAssist:BuildCandidateList(query, limit)
	local ContactIdentity = GetContactIdentity()
	local FriendsList = GetFriendsList()
	if not ContactIdentity then
		return {}
	end

	query = ContactIdentity:CleanString(query) or ""
	query = query:lower()
	limit = limit or MAX_SUGGESTIONS

	local DB = GetDB()
	local candidates = {}
	local seen = {}

	if FriendsList and FriendsList.friendsList then
		for _, friend in ipairs(FriendsList.friendsList) do
			local key = ContactIdentity:ResolveContactKeyFromFriend(friend)
			local lookupKey = ContactIdentity:NormalizeLookupKey(key)
			if key and lookupKey and not seen[lookupKey] then
				local kind, value = ContactIdentity:SplitContactKey(key)
				local displayName = self:GetFriendDisplayName(friend) or value
				local nicknameUID = friend.uid
				if not nicknameUID and kind == "bnet" then
					nicknameUID = "bnet_" .. tostring(value or "")
				elseif not nicknameUID and kind == "player" then
					nicknameUID = "wow_" .. tostring(value or "")
				end
				local nickname = DB and DB.GetNickname and DB:GetNickname(nicknameUID) or nil
				local gameAccountInfo = type(friend.gameAccountInfo) == "table" and friend.gameAccountInfo or nil
				local parts = {}
				AddSearchText(parts, displayName)
				AddSearchText(parts, nickname)
				AddSearchText(parts, friend.accountName)
				AddSearchText(parts, friend.battleTag)
				AddSearchText(parts, friend.name)
				AddSearchText(parts, friend.characterName)
				AddSearchText(parts, friend.realmName)
				AddSearchText(parts, gameAccountInfo and gameAccountInfo.characterName)
				AddSearchText(parts, gameAccountInfo and gameAccountInfo.realmName)

				local haystack = table.concat(parts, " ")
				if query == "" or haystack:find(query, 1, true) then
					seen[lookupKey] = true
					candidates[#candidates + 1] = {
						key = key,
						kind = kind,
						value = value,
						friend = friend,
						displayName = displayName,
						nickname = nickname,
						subtitle = self:GetCandidateSubtitle(friend, kind, value),
					}
				end
			end
		end
	end

	local GuildRosterData = GetGuildRosterData()
	if GuildRosterData and GuildRosterData.CollectRoster and GuildRosterData.HasBaseRosterAPI
		and GuildRosterData:HasBaseRosterAPI() and (not GuildRosterData.IsInGuild or GuildRosterData:IsInGuild()) then
		self:RequestGuildRosterRefresh()

		local members = GuildRosterData:CollectRoster()
		for _, member in ipairs(members or {}) do
			local realm = member.realm
			if (not realm or realm == "") and GetNormalizedRealmName then
				realm = GetNormalizedRealmName()
			end
			local normalizedName = ContactIdentity:NormalizePlayerName(member.fullName or member.name, realm)
			local key = ContactIdentity:GetContactKeyFromPlayerName(member.fullName or member.name, realm)
			local lookupKey = ContactIdentity:NormalizeLookupKey(key)
			if key and normalizedName and lookupKey and not seen[lookupKey] then
				local nicknameUID = "wow_" .. normalizedName
				local nickname = DB and DB.GetNickname and DB:GetNickname(nicknameUID) or nil
				local displayName = member.name or normalizedName
				local parts = {}
				AddSearchText(parts, displayName)
				AddSearchText(parts, nickname)
				AddSearchText(parts, normalizedName)
				AddSearchText(parts, member.fullName)
				AddSearchText(parts, member.realm)
				AddSearchText(parts, member.rank)

				local haystack = table.concat(parts, " ")
				if query == "" or haystack:find(query, 1, true) then
					seen[lookupKey] = true
					candidates[#candidates + 1] = {
						key = key,
						kind = "player",
						value = normalizedName,
						source = "guild",
						displayName = displayName,
						nickname = nickname,
						subtitle = (GUILD or "Guild") .. " - " .. normalizedName,
					}
				end
			end
		end
	end

	self:AddCurrentGroupCandidates(candidates, seen, query)

	table.sort(candidates, function(a, b)
		return tostring(a.displayName or a.value):lower() < tostring(b.displayName or b.value):lower()
	end)

	if #candidates > limit then
		local limited = {}
		for i = 1, limit do
			limited[i] = candidates[i]
		end
		return limited
	end
	return candidates
end

function AutoRaidAssist:GetCandidateSubtitle(friend, kind, value)
	if kind == "bnet" then
		local gameAccountInfo = type(friend.gameAccountInfo) == "table" and friend.gameAccountInfo or nil
		local character = gameAccountInfo and gameAccountInfo.characterName or friend.characterName
		local realm = gameAccountInfo and gameAccountInfo.realmName or friend.realmName
		if character and character ~= "" then
			if realm and realm ~= "" then
				return L("AUTO_RAID_ASSIST_BNET", "BattleTag") .. " - " .. character .. "-" .. realm
			end
			return L("AUTO_RAID_ASSIST_BNET", "BattleTag") .. " - " .. character
		end
		return L("AUTO_RAID_ASSIST_BNET", "BattleTag")
	end
	return L("AUTO_RAID_ASSIST_WOW", "WoW Friend") .. " - " .. tostring(value or "")
end

function AutoRaidAssist:GetTargetDisplay(target)
	local ContactIdentity = GetContactIdentity()
	local kind, value
	if ContactIdentity then
		kind, value = ContactIdentity:SplitContactKey(target.key or target.id)
	end
	local friend = self:FindFriendByContactKey(target.key or target.id)
	local displayName = friend and self:GetFriendDisplayName(friend) or target.displayName or value or target.key or ""
	local source
	if kind == "bnet" then
		source = L("AUTO_RAID_ASSIST_BNET", "BattleTag")
	elseif target.source == "guild" then
		source = GUILD or "Guild"
	elseif target.source == "group" then
		source = GROUP or PARTY or "Group"
	elseif target.source == "manual" then
		source = L("AUTO_RAID_ASSIST_MANUAL", "Manual")
	else
		source = L("AUTO_RAID_ASSIST_WOW", "WoW Friend")
	end
	return displayName, source .. " - " .. tostring(value or "")
end

function AutoRaidAssist:GetUnitDebugName(unit)
	if not unit then
		return nil
	end
	local name, realm
	if UnitFullName then
		name, realm = UnitFullName(unit)
	end
	if not name and UnitName then
		name, realm = UnitName(unit)
	end
	if not name or name == "" then
		return nil
	end
	if not realm or realm == "" then
		realm = GetNormalizedRealmName and GetNormalizedRealmName() or nil
	end
	if realm and realm ~= "" then
		return name .. "-" .. realm
	end
	return name
end

function AutoRaidAssist:GetUnitPromotionName(unit)
	if not unit then
		return nil
	end
	local name, realm
	if UnitFullName then
		name, realm = UnitFullName(unit)
	end
	if not name and UnitName then
		name, realm = UnitName(unit)
	end
	if not name or name == "" then
		return nil
	end
	if not realm or realm == "" then
		realm = GetNormalizedRealmName and GetNormalizedRealmName() or nil
	end

	local isSameRealm = false
	if UnitRealmRelationship and LE_REALM_RELATION_SAME then
		isSameRealm = UnitRealmRelationship(unit) == LE_REALM_RELATION_SAME
	elseif realm and GetNormalizedRealmName then
		isSameRealm = realm == GetNormalizedRealmName()
	end

	if realm and realm ~= "" and not isSameRealm then
		return name .. "-" .. realm
	end
	return name
end

function AutoRaidAssist:GetUnitContactKey(unit)
	local ContactIdentity = GetContactIdentity()
	if not ContactIdentity or not unit then
		return nil
	end
	local name, realm
	if UnitFullName then
		name, realm = UnitFullName(unit)
	end
	if not name and UnitName then
		name, realm = UnitName(unit)
	end
	if not realm or realm == "" then
		realm = GetNormalizedRealmName and GetNormalizedRealmName() or nil
	end
	return ContactIdentity:GetContactKeyFromPlayerName(name, realm)
end

function AutoRaidAssist:AddGameAccountKey(gameAccountInfo, keySet)
	if not IsWoWGameAccount(gameAccountInfo) then
		DebugLog(
			"AddGameAccountKey skipped character=%s realm=%s client=%s online=%s reason=notWowGameAccount",
			DebugValue(gameAccountInfo and gameAccountInfo.characterName),
			DebugValue(gameAccountInfo and gameAccountInfo.realmName),
			DebugValue(gameAccountInfo and gameAccountInfo.clientProgram),
			DebugValue(gameAccountInfo and gameAccountInfo.isOnline)
		)
		return
	end
	local ContactIdentity = GetContactIdentity()
	if not ContactIdentity then
		DebugLog("AddGameAccountKey skipped reason=missingIdentity")
		return
	end
	local key = ContactIdentity:GetContactKeyFromPlayerName(gameAccountInfo.characterName, gameAccountInfo.realmName)
	if key then
		local lookupKey = ContactIdentity:NormalizeLookupKey(key)
		if lookupKey then
			keySet[lookupKey] = true
			DebugLog(
				"AddGameAccountKey added key=%s lookup=%s character=%s realm=%s",
				DebugValue(key),
				DebugValue(lookupKey),
				DebugValue(gameAccountInfo.characterName),
				DebugValue(gameAccountInfo.realmName)
			)
		else
			DebugLog(
				"AddGameAccountKey skipped key=%s character=%s realm=%s reason=missingLookup",
				DebugValue(key),
				DebugValue(gameAccountInfo.characterName),
				DebugValue(gameAccountInfo.realmName)
			)
		end
	else
		DebugLog(
			"AddGameAccountKey skipped character=%s realm=%s reason=missingKey",
			DebugValue(gameAccountInfo.characterName),
			DebugValue(gameAccountInfo.realmName)
		)
	end
end

function AutoRaidAssist:AddBNetTargetGameKeys(target, keySet)
	local battleTag = target and target.value
	if not battleTag or battleTag == "" then
		DebugLog("AddBNetTargetGameKeys skipped target=%s reason=missingBattleTag", DebugValue(target and target.key))
		return
	end
	local wanted = battleTag:lower()
	DebugLog("AddBNetTargetGameKeys target=%s battleTag=%s", DebugValue(target.key or target.id), DebugValue(battleTag))

	local FriendsList = GetFriendsList()
	if FriendsList and FriendsList.friendsList then
		for _, friend in ipairs(FriendsList.friendsList) do
			if friend.type == "bnet" and friend.battleTag and friend.battleTag:lower() == wanted then
				DebugLog("AddBNetTargetGameKeys matched BFL friend display=%s battleTag=%s", DebugValue(friend.displayName or friend.accountName), DebugValue(friend.battleTag))
				if type(friend.gameAccounts) == "table" then
					for _, gameAccountInfo in ipairs(friend.gameAccounts) do
						self:AddGameAccountKey(gameAccountInfo, keySet)
					end
				end
				self:AddGameAccountKey(friend.gameAccountInfo, keySet)
			end
		end
	end

	if not (BNGetNumFriends and BFL.GetBNetFriendInfo) then
		return
	end
	local numBNet = BNGetNumFriends() or 0
	for friendIndex = 1, numBNet do
		local accountInfo = BFL.GetBNetFriendInfo(friendIndex)
		if accountInfo and accountInfo.battleTag and accountInfo.battleTag:lower() == wanted then
			DebugLog("AddBNetTargetGameKeys matched BN friendIndex=%d battleTag=%s", friendIndex, DebugValue(accountInfo.battleTag))
			self:AddGameAccountKey(accountInfo.gameAccountInfo, keySet)
			local numGameAccounts = 0
			if C_BattleNet and C_BattleNet.GetFriendNumGameAccounts then
				numGameAccounts = C_BattleNet.GetFriendNumGameAccounts(friendIndex) or 0
			end
			for gameIndex = 1, numGameAccounts do
				local gameAccountInfo = BFL.GetBNetFriendGameAccountInfo
					and BFL.GetBNetFriendGameAccountInfo(friendIndex, gameIndex)
				self:AddGameAccountKey(gameAccountInfo, keySet)
			end
		end
	end
end

function AutoRaidAssist:BuildEffectiveTargetKeySet()
	local ContactIdentity = GetContactIdentity()
	local keySet = {}
	if not ContactIdentity then
		DebugLog("BuildEffectiveTargetKeySet failed reason=missingIdentity")
		return keySet
	end
	local targetCount = 0
	for _, target in ipairs(self:GetTargets()) do
		targetCount = targetCount + 1
		local kind = target.kind
		if not kind then
			kind = ContactIdentity:SplitContactKey(target.key or target.id)
		end
		if kind == "bnet" then
			self:AddBNetTargetGameKeys(target, keySet)
		else
			local lookupKey = ContactIdentity:NormalizeLookupKey(target.key or target.id)
			if lookupKey then
				keySet[lookupKey] = true
				DebugLog("BuildEffectiveTargetKeySet added direct target=%s lookup=%s kind=%s", DebugValue(target.key or target.id), DebugValue(lookupKey), DebugValue(kind))
			else
				DebugLog("BuildEffectiveTargetKeySet skipped target=%s reason=missingLookup", DebugValue(target.key or target.id))
			end
		end
	end
	DebugLog("BuildEffectiveTargetKeySet targets=%d effectiveKeys=%d", targetCount, CountTableKeys(keySet))
	return keySet
end

function AutoRaidAssist:ScheduleEvaluate(reason, delay)
	if not self:IsEnabled() then
		DebugLog("ScheduleEvaluate skipped reason=%s gate=disabled", DebugValue(reason))
		return
	end
	delay = delay or EVALUATE_DELAY
	if self.pendingTimer and self.pendingTimer.Cancel then
		self.pendingTimer:Cancel()
		DebugLog("ScheduleEvaluate canceled previous pending timer")
	end
	if C_Timer and C_Timer.NewTimer then
		DebugLog("ScheduleEvaluate reason=%s delay=%.2f", DebugValue(reason), delay)
		self.pendingTimer = C_Timer.NewTimer(delay, function()
			AutoRaidAssist.pendingTimer = nil
			AutoRaidAssist:Evaluate(reason)
		end)
	else
		DebugLog("ScheduleEvaluate immediate reason=%s reason=noTimerAPI", DebugValue(reason))
		self:Evaluate(reason)
	end
end

function AutoRaidAssist:CancelRosterRetryTimers()
	if type(self.rosterRetryTimers) ~= "table" then
		DebugLog("CancelRosterRetryTimers skipped reason=noTimers")
		return
	end
	local canceled = 0
	for _, timer in pairs(self.rosterRetryTimers) do
		if timer and timer.Cancel then
			timer:Cancel()
			canceled = canceled + 1
		end
	end
	self.rosterRetryTimers = {}
	DebugLog("CancelRosterRetryTimers canceled=%d", canceled)
end

function AutoRaidAssist:ScheduleRosterEvaluate(reason)
	DebugLog("ScheduleRosterEvaluate reason=%s", DebugValue(reason))
	self:ScheduleEvaluate(reason)
	if not (self:IsEnabled() and C_Timer and C_Timer.NewTimer) then
		DebugLog(
			"ScheduleRosterEvaluate settle retries skipped enabled=%s hasTimerAPI=%s",
			DebugValue(self:IsEnabled()),
			DebugValue(C_Timer and C_Timer.NewTimer ~= nil)
		)
		return
	end

	self:CancelRosterRetryTimers()
	self.rosterRetryTimers = {}
	for index, delay in ipairs(ROSTER_SETTLE_DELAYS) do
		DebugLog("ScheduleRosterEvaluate settleRetry index=%d delay=%.2f reason=%s", index, delay, DebugValue(reason))
		self.rosterRetryTimers[index] = C_Timer.NewTimer(delay, function()
			if AutoRaidAssist.rosterRetryTimers then
				AutoRaidAssist.rosterRetryTimers[index] = nil
			end
			DebugLog("Roster settle retry fired index=%d reason=%s", index, DebugValue(reason))
			AutoRaidAssist:Evaluate((reason or "roster") .. "-settle")
		end)
	end
end

function AutoRaidAssist:CanPromoteNow(reason)
	reason = reason or "unknown"
	local enabled = self:IsEnabled()
	local targetCount = self:GetTargetCount()
	local inRaid = IsInRaid and IsInRaid()
	local leader = UnitIsGroupLeader and UnitIsGroupLeader("player")
	local groupMembers = GetNumGroupMembers and GetNumGroupMembers() or 0

	if not enabled then
		DebugLog(
			"CanPromoteNow reason=%s result=false gate=disabled targets=%d isInRaid=%s leader=%s members=%d",
			DebugValue(reason),
			targetCount,
			DebugValue(inRaid),
			DebugValue(leader),
			groupMembers
		)
		return false
	end
	if targetCount == 0 then
		DebugLog(
			"CanPromoteNow reason=%s result=false gate=noTargets isInRaid=%s leader=%s members=%d",
			DebugValue(reason),
			DebugValue(inRaid),
			DebugValue(leader),
			groupMembers
		)
		return false
	end
	if not inRaid then
		DebugLog(
			"CanPromoteNow reason=%s result=false gate=notRaidGroup targets=%d leader=%s members=%d",
			DebugValue(reason),
			targetCount,
			DebugValue(leader),
			groupMembers
		)
		return false
	end
	if not leader then
		DebugLog(
			"CanPromoteNow reason=%s result=false gate=notGroupLeader targets=%d members=%d",
			DebugValue(reason),
			targetCount,
			groupMembers
		)
		return false
	end
	if BFL.IsActionRestricted and BFL:IsActionRestricted() then
		self.needsCombatRetry = true
		DebugLog(
			"CanPromoteNow reason=%s result=false gate=actionRestricted targets=%d members=%d retryOnRegen=true",
			DebugValue(reason),
			targetCount,
			groupMembers
		)
		return false
	end
	if not (GetNumGroupMembers and BFL.PromoteToAssistant) then
		DebugLog(
			"CanPromoteNow reason=%s result=false gate=missingAPI hasGetNumGroupMembers=%s hasPromote=%s",
			DebugValue(reason),
			DebugValue(GetNumGroupMembers ~= nil),
			DebugValue(BFL.PromoteToAssistant ~= nil)
		)
		return false
	end
	DebugLog(
		"CanPromoteNow reason=%s result=true targets=%d members=%d isInRaid=%s leader=%s",
		DebugValue(reason),
		targetCount,
		groupMembers,
		DebugValue(inRaid),
		DebugValue(leader)
	)
	return true
end

function AutoRaidAssist:GetNotPromotableReason(unit)
	if UnitExists and not UnitExists(unit) then
		return "missingUnit"
	end
	if UnitIsUnit and UnitIsUnit(unit, "player") then
		return "player"
	end
	if UnitIsGroupLeader and UnitIsGroupLeader(unit) then
		return "leader"
	end
	if UnitIsGroupAssistant and UnitIsGroupAssistant(unit) then
		return "alreadyAssistant"
	end
	return nil
end

function AutoRaidAssist:IsPromotableUnit(unit)
	return self:GetNotPromotableReason(unit) == nil
end

function AutoRaidAssist:FindPromotableUnitForLookupKey(lookupKey, ContactIdentity)
	if not (lookupKey and ContactIdentity and GetNumGroupMembers) then
		DebugLog(
			"FindPromotableUnitForLookupKey failed lookup=%s hasIdentity=%s hasGroupAPI=%s",
			DebugValue(lookupKey),
			DebugValue(ContactIdentity ~= nil),
			DebugValue(GetNumGroupMembers ~= nil)
		)
		return nil
	end

	local count = GetNumGroupMembers() or 0
	for index = 1, count do
		local unit = "raid" .. tostring(index)
		if self:IsPromotableUnit(unit) then
			local unitKey = self:GetUnitContactKey(unit)
			if ContactIdentity:NormalizeLookupKey(unitKey) == lookupKey then
				DebugLog(
					"FindPromotableUnitForLookupKey lookup=%s matched unit=%s name=%s key=%s",
					DebugValue(lookupKey),
					unit,
					DebugValue(self:GetUnitDebugName(unit)),
					DebugValue(unitKey)
				)
				return unit
			end
		end
	end
	DebugLog("FindPromotableUnitForLookupKey lookup=%s no promotable unit found members=%d", DebugValue(lookupKey), count)
	return nil
end

function AutoRaidAssist:CollectPromotionCandidates(targetKeys, ContactIdentity, now)
	local candidates = {}
	if not (targetKeys and ContactIdentity and GetNumGroupMembers) then
		DebugLog(
			"CollectPromotionCandidates failed hasTargetKeys=%s hasIdentity=%s hasGroupAPI=%s",
			DebugValue(targetKeys ~= nil),
			DebugValue(ContactIdentity ~= nil),
			DebugValue(GetNumGroupMembers ~= nil)
		)
		return candidates
	end

	local seen = {}
	if type(self.promotionQueueLookup) == "table" then
		for lookupKey in pairs(self.promotionQueueLookup) do
			seen[lookupKey] = true
		end
	end

	local count = GetNumGroupMembers() or 0
	DebugLog(
		"CollectPromotionCandidates start members=%d targetKeys=%d queuedSeen=%d",
		count,
		CountTableKeys(targetKeys),
		CountTableKeys(seen)
	)
	for index = 1, count do
		local unit = "raid" .. tostring(index)
		local unitName = self:GetUnitDebugName(unit)
		local unitKey = self:GetUnitContactKey(unit)
		local lookupKey = ContactIdentity:NormalizeLookupKey(unitKey)
		local notPromotableReason = self:GetNotPromotableReason(unit)
		if notPromotableReason then
			if lookupKey and targetKeys[lookupKey] and notPromotableReason == "alreadyAssistant" then
				self:ResetPromotionAttemptCount(lookupKey)
				self:CancelPromotionRetryTimer(lookupKey)
			end
			DebugLog(
				"CandidateCheck unit=%s name=%s key=%s lookup=%s result=skip reason=%s",
				unit,
				DebugValue(unitName),
				DebugValue(unitKey),
				DebugValue(lookupKey),
				notPromotableReason
			)
		else
			if lookupKey and targetKeys[lookupKey] and self:GetPromotionAttemptCount(lookupKey, now) >= PROMOTION_MAX_ATTEMPTS then
				DebugLog(
					"CandidateCheck unit=%s name=%s key=%s lookup=%s result=skip reason=maxAttempts attempts=%d",
					unit,
					DebugValue(unitName),
					DebugValue(unitKey),
					DebugValue(lookupKey),
					self:GetPromotionAttemptCount(lookupKey, now)
				)
			elseif lookupKey and targetKeys[lookupKey] and not seen[lookupKey] then
				local lastAttempt = self.lastPromotionAttempt[lookupKey] or 0
				local cooldownRemaining = PROMOTION_COOLDOWN - (now - lastAttempt)
				if cooldownRemaining <= 0 then
					seen[lookupKey] = true
					candidates[#candidates + 1] = lookupKey
					DebugLog(
						"CandidateCheck unit=%s name=%s key=%s lookup=%s result=queue",
						unit,
						DebugValue(unitName),
						DebugValue(unitKey),
						DebugValue(lookupKey)
					)
				else
					DebugLog(
						"CandidateCheck unit=%s name=%s key=%s lookup=%s result=skip reason=cooldown remaining=%.2f",
						unit,
						DebugValue(unitName),
						DebugValue(unitKey),
						DebugValue(lookupKey),
						cooldownRemaining
					)
					self:SchedulePromotionRetry(lookupKey, cooldownRemaining + PROMOTION_RETRY_GRACE, "candidate-cooldown")
				end
			elseif lookupKey and targetKeys[lookupKey] and seen[lookupKey] then
				DebugLog(
					"CandidateCheck unit=%s name=%s key=%s lookup=%s result=skip reason=alreadyQueuedOrSeen",
					unit,
					DebugValue(unitName),
					DebugValue(unitKey),
					DebugValue(lookupKey)
				)
			else
				DebugLog(
					"CandidateCheck unit=%s name=%s key=%s lookup=%s result=skip reason=noTargetMatch",
					unit,
					DebugValue(unitName),
					DebugValue(unitKey),
					DebugValue(lookupKey)
				)
			end
		end
	end
	DebugLog("CollectPromotionCandidates result count=%d", #candidates)
	return candidates
end

function AutoRaidAssist:ClearPromotionQueue()
	local queueLength = type(self.promotionQueue) == "table" and #self.promotionQueue or 0
	if self.promotionQueueTimer and self.promotionQueueTimer.Cancel then
		self.promotionQueueTimer:Cancel()
		DebugLog("ClearPromotionQueue canceled active queue timer")
	end
	self.promotionQueueTimer = nil
	self.promotionQueue = {}
	self.promotionQueueLookup = {}
	DebugLog("ClearPromotionQueue previousLength=%d", queueLength)
end

function AutoRaidAssist:CancelPromotionRetryTimer(lookupKey)
	if not lookupKey or type(self.promotionRetryTimers) ~= "table" then
		return
	end
	local timer = self.promotionRetryTimers[lookupKey]
	if timer and timer.Cancel then
		timer:Cancel()
	end
	self.promotionRetryTimers[lookupKey] = nil
	DebugLog("CancelPromotionRetryTimer lookup=%s", DebugValue(lookupKey))
end

function AutoRaidAssist:CancelPromotionRetryTimers()
	if type(self.promotionRetryTimers) ~= "table" then
		return
	end
	local canceled = 0
	for _, timer in pairs(self.promotionRetryTimers) do
		if timer and timer.Cancel then
			timer:Cancel()
			canceled = canceled + 1
		end
	end
	self.promotionRetryTimers = {}
	DebugLog("CancelPromotionRetryTimers canceled=%d", canceled)
end

function AutoRaidAssist:ResetPromotionAttemptCount(lookupKey)
	if not lookupKey or type(self.promotionAttemptCounts) ~= "table" then
		return
	end
	self.promotionAttemptCounts[lookupKey] = nil
	DebugLog("ResetPromotionAttemptCount lookup=%s", DebugValue(lookupKey))
end

function AutoRaidAssist:GetPromotionAttemptCount(lookupKey, now)
	if not lookupKey then
		return 0
	end
	if type(self.promotionAttemptCounts) ~= "table" then
		self.promotionAttemptCounts = {}
	end
	local entry = self.promotionAttemptCounts[lookupKey]
	if type(entry) ~= "table" then
		return 0
	end
	now = now or SafeTime()
	if (now - (entry.startedAt or now)) > PROMOTION_ATTEMPT_RESET then
		self.promotionAttemptCounts[lookupKey] = nil
		return 0
	end
	return entry.count or 0
end

function AutoRaidAssist:RecordPromotionAttempt(lookupKey, now)
	if not lookupKey then
		return 0
	end
	if type(self.promotionAttemptCounts) ~= "table" then
		self.promotionAttemptCounts = {}
	end
	now = now or SafeTime()
	local entry = self.promotionAttemptCounts[lookupKey]
	if type(entry) ~= "table" or (now - (entry.startedAt or now)) > PROMOTION_ATTEMPT_RESET then
		entry = {
			count = 0,
			startedAt = now,
		}
		self.promotionAttemptCounts[lookupKey] = entry
	end
	entry.count = (entry.count or 0) + 1
	entry.lastAt = now
	return entry.count
end

function AutoRaidAssist:SchedulePromotionRetry(lookupKey, delay, reason)
	if not lookupKey then
		DebugLog("SchedulePromotionRetry skipped reason=missingLookup")
		return false
	end
	if not self:IsEnabled() then
		DebugLog("SchedulePromotionRetry skipped lookup=%s reason=disabled", DebugValue(lookupKey))
		return false
	end
	delay = math.max(tonumber(delay) or EVALUATE_DELAY, EVALUATE_DELAY)
	if not (C_Timer and C_Timer.NewTimer) then
		DebugLog("SchedulePromotionRetry immediate lookup=%s reason=%s noTimerAPI=true", DebugValue(lookupKey), DebugValue(reason))
		self:ScheduleEvaluate(reason or "promotion-retry")
		return true
	end

	if type(self.promotionRetryTimers) ~= "table" then
		self.promotionRetryTimers = {}
	end
	local existingTimer = self.promotionRetryTimers[lookupKey]
	if existingTimer and existingTimer.Cancel then
		existingTimer:Cancel()
	end
	DebugLog(
		"SchedulePromotionRetry lookup=%s delay=%.2f reason=%s replaced=%s",
		DebugValue(lookupKey),
		delay,
		DebugValue(reason),
		DebugValue(existingTimer ~= nil)
	)
	self.promotionRetryTimers[lookupKey] = C_Timer.NewTimer(delay, function()
		if AutoRaidAssist.promotionRetryTimers then
			AutoRaidAssist.promotionRetryTimers[lookupKey] = nil
		end
		DebugLog("Promotion retry fired lookup=%s reason=%s", DebugValue(lookupKey), DebugValue(reason))
		AutoRaidAssist:Evaluate((reason or "promotion-retry") .. ":" .. tostring(lookupKey))
	end)
	return true
end

function AutoRaidAssist:RemoveQueuedPromotion(lookupKey)
	if not lookupKey or type(self.promotionQueue) ~= "table" then
		DebugLog("RemoveQueuedPromotion skipped lookup=%s reason=missingLookupOrQueue", DebugValue(lookupKey))
		return
	end

	if type(self.promotionQueueLookup) == "table" then
		self.promotionQueueLookup[lookupKey] = nil
	end
	local removed = 0
	for index = #self.promotionQueue, 1, -1 do
		if self.promotionQueue[index] == lookupKey then
			table.remove(self.promotionQueue, index)
			removed = removed + 1
		end
	end
	if #self.promotionQueue == 0 and self.promotionQueueTimer and self.promotionQueueTimer.Cancel then
		self.promotionQueueTimer:Cancel()
		self.promotionQueueTimer = nil
	end
	DebugLog("RemoveQueuedPromotion lookup=%s removed=%d queueLength=%d", DebugValue(lookupKey), removed, #self.promotionQueue)
end

function AutoRaidAssist:ScheduleNextQueuedPromotion(delayOverride)
	if self.promotionQueueTimer or type(self.promotionQueue) ~= "table" or #self.promotionQueue == 0 then
		DebugLog(
			"ScheduleNextQueuedPromotion skipped hasTimer=%s hasQueue=%s queueLength=%d",
			DebugValue(self.promotionQueueTimer ~= nil),
			DebugValue(type(self.promotionQueue) == "table"),
			type(self.promotionQueue) == "table" and #self.promotionQueue or 0
		)
		return
	end

	local delay = math.max(tonumber(delayOverride) or PROMOTION_QUEUE_DELAY, EVALUATE_DELAY)
	if C_Timer and C_Timer.NewTimer then
		DebugLog("ScheduleNextQueuedPromotion delay=%.2f queueLength=%d", delay, #self.promotionQueue)
		self.promotionQueueTimer = C_Timer.NewTimer(delay, function()
			AutoRaidAssist.promotionQueueTimer = nil
			AutoRaidAssist:ProcessPromotionQueue()
		end)
	else
		DebugLog("ScheduleNextQueuedPromotion immediate reason=noTimerAPI queueLength=%d", #self.promotionQueue)
		self:ProcessPromotionQueue()
	end
end

function AutoRaidAssist:EnqueuePromotionCandidates(candidates)
	if type(candidates) ~= "table" or #candidates == 0 then
		DebugLog("EnqueuePromotionCandidates skipped count=%d", type(candidates) == "table" and #candidates or 0)
		return false
	end

	if type(self.promotionQueue) ~= "table" then
		self.promotionQueue = {}
	end
	if type(self.promotionQueueLookup) ~= "table" then
		self.promotionQueueLookup = {}
	end

	local added = false
	local addedCount = 0
	for _, lookupKey in ipairs(candidates) do
		if lookupKey and not self.promotionQueueLookup[lookupKey] then
			self.promotionQueue[#self.promotionQueue + 1] = lookupKey
			self.promotionQueueLookup[lookupKey] = true
			added = true
			addedCount = addedCount + 1
			DebugLog("EnqueuePromotionCandidates added lookup=%s queueLength=%d", DebugValue(lookupKey), #self.promotionQueue)
		else
			DebugLog("EnqueuePromotionCandidates skipped lookup=%s reason=alreadyQueuedOrInvalid", DebugValue(lookupKey))
		end
	end

	if added and not self.promotionQueueTimer then
		DebugLog("EnqueuePromotionCandidates processing now added=%d queueLength=%d", addedCount, #self.promotionQueue)
		self:ProcessPromotionQueue()
	else
		DebugLog(
			"EnqueuePromotionCandidates result added=%d queueLength=%d hasTimer=%s",
			addedCount,
			#self.promotionQueue,
			DebugValue(self.promotionQueueTimer ~= nil)
		)
	end
	return added
end

function AutoRaidAssist:ProcessPromotionQueue()
	if type(self.promotionQueue) ~= "table" or #self.promotionQueue == 0 then
		DebugLog("ProcessPromotionQueue skipped reason=emptyQueue")
		self:ClearPromotionQueue()
		return false
	end

	DebugLog("ProcessPromotionQueue start queueLength=%d", #self.promotionQueue)
	if not self:CanPromoteNow("queue") then
		DebugLog("ProcessPromotionQueue stopping reason=CanPromoteNowFalse")
		self:ClearPromotionQueue()
		return false
	end

	local ContactIdentity = GetContactIdentity()
	if not ContactIdentity then
		DebugLog("ProcessPromotionQueue stopping reason=missingIdentity")
		self:ClearPromotionQueue()
		return false
	end

	local targetKeys = self:BuildEffectiveTargetKeySet()
	DebugLog("ProcessPromotionQueue targetKeys=%d", CountTableKeys(targetKeys))
	local now = SafeTime()
	local initialQueueLength = #self.promotionQueue
	local processed = 0
	local shortestCooldown
	while #self.promotionQueue > 0 and processed < initialQueueLength do
		processed = processed + 1
		local lookupKey = table.remove(self.promotionQueue, 1)
		self.promotionQueueLookup[lookupKey] = nil
		if targetKeys[lookupKey] then
			local unit = self:FindPromotableUnitForLookupKey(lookupKey, ContactIdentity)
			if unit then
				local lastAttempt = self.lastPromotionAttempt[lookupKey] or 0
				local cooldownRemaining = PROMOTION_COOLDOWN - (now - lastAttempt)
				if cooldownRemaining <= 0 then
					local attemptCount = self:GetPromotionAttemptCount(lookupKey, now)
					if attemptCount >= PROMOTION_MAX_ATTEMPTS then
						DebugLog(
							"ProcessPromotionQueue skipped lookup=%s reason=maxAttempts attempts=%d",
							DebugValue(lookupKey),
							attemptCount
						)
					else
						attemptCount = self:RecordPromotionAttempt(lookupKey, now)
						local promotionName = self:GetUnitPromotionName(unit) or unit
						self.lastPromotionAttempt[lookupKey] = now
						DebugLog(
							"PromoteAttempt lookup=%s unit=%s name=%s apiName=%s attempt=%d/%d queueRemaining=%d",
							DebugValue(lookupKey),
							unit,
							DebugValue(self:GetUnitDebugName(unit)),
							DebugValue(promotionName),
							attemptCount,
							PROMOTION_MAX_ATTEMPTS,
							#self.promotionQueue
						)
						local promoted = BFL.PromoteToAssistant(unit)
						DebugLog(
							"PromoteAttempt dispatched lookup=%s unit=%s apiName=%s apiResult=%s",
							DebugValue(lookupKey),
							unit,
							DebugValue(promotionName),
							DebugValue(promoted)
						)
						self:SchedulePromotionRetry(
							lookupKey,
							PROMOTION_COOLDOWN + PROMOTION_RETRY_GRACE,
							"promotion-verify"
						)
						self:ScheduleNextQueuedPromotion()
						return true
					end
				else
					DebugLog(
						"ProcessPromotionQueue skipped lookup=%s reason=cooldown remaining=%.2f",
						DebugValue(lookupKey),
						cooldownRemaining
					)
					self.promotionQueue[#self.promotionQueue + 1] = lookupKey
					self.promotionQueueLookup[lookupKey] = true
					shortestCooldown = math.min(shortestCooldown or cooldownRemaining, cooldownRemaining)
				end
			else
				DebugLog("ProcessPromotionQueue skipped lookup=%s reason=noPromotableUnit", DebugValue(lookupKey))
			end
		else
			DebugLog("ProcessPromotionQueue skipped lookup=%s reason=noLongerTarget", DebugValue(lookupKey))
		end
	end

	if shortestCooldown and type(self.promotionQueue) == "table" and #self.promotionQueue > 0 then
		local retryDelay = shortestCooldown + PROMOTION_RETRY_GRACE
		DebugLog(
			"ProcessPromotionQueue requeued cooldown targets queueLength=%d retryDelay=%.2f",
			#self.promotionQueue,
			retryDelay
		)
		self:ScheduleNextQueuedPromotion(retryDelay)
		return false
	end

	self:ClearPromotionQueue()
	DebugLog("ProcessPromotionQueue finished no promotions dispatched")
	return false
end

function AutoRaidAssist:Evaluate(reason)
	DebugLog("Evaluate start reason=%s", DebugValue(reason))
	if not self:CanPromoteNow("evaluate:" .. tostring(reason or "unknown")) then
		DebugLog("Evaluate stop reason=%s gate=CanPromoteNowFalse", DebugValue(reason))
		return false
	end

	local ContactIdentity = GetContactIdentity()
	if not ContactIdentity then
		DebugLog("Evaluate stop reason=%s gate=missingIdentity", DebugValue(reason))
		return false
	end

	local targetKeys = self:BuildEffectiveTargetKeySet()
	DebugLog("Evaluate reason=%s effectiveTargetKeys=%d", DebugValue(reason), CountTableKeys(targetKeys))
	local now = SafeTime()
	local candidates = self:CollectPromotionCandidates(targetKeys, ContactIdentity, now)
	local queued = self:EnqueuePromotionCandidates(candidates)
	DebugLog("Evaluate done reason=%s candidates=%d queued=%s", DebugValue(reason), #candidates, DebugValue(queued))
	return queued
end

function AutoRaidAssist:RegisterSettingsDesignerControls(app, options)
	if not (app and app.RegisterControl) then
		return false
	end
	options = options or {}
	local pageID = options.pageID or "social.raid"
	local groupID = options.groupID or "autoAssist"
	local groupTitle = L("AUTO_RAID_ASSIST_TITLE", "Auto Raid Assist")
	local controlOrder = options.order or 200
	local includeEnableToggle = options.includeEnableToggle ~= false
	local includeManageButton = options.includeManageButton ~= false
	local includeEditor = options.includeEditor == true

	if app.RegisterGroup then
		app:RegisterGroup(pageID, {
			id = groupID,
			title = groupTitle,
			order = options.groupOrder or 200,
		})
	end

	if includeEnableToggle then
		app:RegisterControl(pageID, {
			id = options.enabledControlID or "autoRaidAssist.enabled",
			groupID = groupID,
			groupTitle = groupTitle,
			type = "toggle",
			label = L("AUTO_RAID_ASSIST_ENABLE", "Enable Auto Raid Assist"),
			description = L(
				"AUTO_RAID_ASSIST_ENABLE_DESC",
				"Automatically promote selected friends and characters to raid assistant when they join your raid."
			),
			default = false,
			order = controlOrder,
			refreshOnChange = true,
			keywords = { "raid", "assistant", "assist", "promote", "battletag", "nickname" },
			getValue = function()
				return AutoRaidAssist:GetEnabledSetting()
			end,
			setValue = function(value)
				AutoRaidAssist:SetEnabled(value == true)
			end,
		})
	end

	if includeManageButton then
		app:RegisterControl(pageID, {
			id = options.manageControlID or "autoRaidAssist.manage",
			groupID = groupID,
			groupTitle = groupTitle,
			type = "button",
			label = L("AUTO_RAID_ASSIST_MANAGE", "Manage Auto Raid Assist"),
			description = L(
				"AUTO_RAID_ASSIST_MANAGE_DESC",
				"Choose BattleTag friends, nickname matches, or manual Character-Realm targets."
			),
			buttonText = L("AUTO_RAID_ASSIST_MANAGE_BUTTON", "Manage"),
			order = controlOrder + 10,
			trackCustomized = false,
			keywords = { "raid", "assistant", "assist", "battletag", "nickname", "character", "realm" },
			onClick = function()
				local SettingsDesigner = BFL:GetModule("SettingsDesigner")
				if SettingsDesigner and SettingsDesigner.Show then
					SettingsDesigner:Show("social.raid.autoAssist")
				end
			end,
		})
	end

	if includeEditor then
		app:RegisterControl(pageID, {
			id = options.editorControlID or "autoRaidAssist.targetsEditor",
			groupID = groupID,
			groupTitle = groupTitle,
			type = "custom",
			label = L("AUTO_RAID_ASSIST_TARGETS", "Targets"),
			order = options.editorOrder or (controlOrder + 10),
			trackCustomized = false,
			keywords = { "raid", "assistant", "assist", "battletag", "nickname", "character", "realm" },
			getHeight = function()
				return AutoRaidAssist:GetSettingsEditorControlHeight()
			end,
			render = function(parent, _, _, state, focusID)
				return AutoRaidAssist:RenderSettingsPage(parent, {
					focusID = focusID,
					settingsCenter = true,
					requestLayout = function()
						if state and state.RenderContent then
							state:RenderContent()
						end
					end,
				})
			end,
		})
	end

	return true
end

function AutoRaidAssist:RegisterWithSettingsDesigner()
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

function AutoRaidAssist:GetSettingsPageHeight(options)
	options = options or {}
	local targetRows = math.min(math.max(self:GetTargetCount(), 1), MAX_TARGET_ROWS)
	local includeEnableToggle = options.includeEnableToggle
	if includeEnableToggle == nil then
		includeEnableToggle = options.settingsCenter ~= true
	end
	return (includeEnableToggle and 196 or 160) + (targetRows * TARGET_ROW_HEIGHT)
end

function AutoRaidAssist:GetSettingsEditorControlHeight()
	return self:GetSettingsPageHeight({
		settingsCenter = true,
		includeEnableToggle = false,
	}) + 62
end

function AutoRaidAssist:RenderSettingsPage(parent, options)
	if not parent then
		return nil
	end
	options = options or {}
	local Components = BFL.SettingsComponents
	local buttonOptions = {
		variant = options.variant == "legacy" and "legacy" or nil,
	}
	local handle = {
		parent = parent,
		searchText = "",
		suggestionRows = {},
		targetRows = {},
		searchFocused = false,
		includeEnableToggle = options.settingsCenter ~= true,
		requestLayout = options.requestLayout,
	}
	local y = -14

	local function Add(frame, height)
		if height and frame.SetHeight then
			frame:SetHeight(height)
		end
		frame:SetPoint("TOPLEFT", parent, "TOPLEFT", 14, y)
		frame:SetPoint("RIGHT", parent, "RIGHT", -14, 0)
		y = y - (height or frame:GetHeight() or 24) - 8
		return frame
	end

	if handle.includeEnableToggle then
		local enableToggle = Components and Components:CreateCheckbox(parent, {
			label = L("AUTO_RAID_ASSIST_ENABLE", "Enable Auto Raid Assist"),
			initialValue = self:GetEnabledSetting(),
			callback = function(checked)
				AutoRaidAssist:SetEnabled(checked == true)
			end,
			tooltipTitle = L("AUTO_RAID_ASSIST_ENABLE", "Enable Auto Raid Assist"),
			tooltipDesc = L(
				"AUTO_RAID_ASSIST_ENABLE_DESC",
				"Automatically promote selected friends and characters to raid assistant when they join your raid."
			),
		})
		if enableToggle then
			Add(enableToggle, 28)
		end
	end

	local searchTitle = CreateLabel(
		parent,
		L("AUTO_RAID_ASSIST_SEARCH_LABEL", "Find Friend") .. " / " .. L("AUTO_RAID_ASSIST_MANUAL_LABEL", "Character-Realm"),
		"BetterFriendlistFontNormal"
	)
	Add(searchTitle, 18)

	local searchRow = CreateFrame("Frame", nil, parent)
	searchRow:SetHeight(26)
	local searchBox = CreateFrame("EditBox", nil, searchRow, "InputBoxTemplate")
	searchBox:SetAutoFocus(false)
	searchBox:SetHeight(22)
	searchBox:SetPoint("LEFT", searchRow, "LEFT", 0, 0)
	searchBox:SetPoint("RIGHT", searchRow, "RIGHT", -88, 0)
	searchBox:SetFontObject("BetterFriendlistFontHighlightSmall")

	local addButton = CreateSmallButton(searchRow, L("AUTO_RAID_ASSIST_ADD", "Add"), 76, buttonOptions)
	addButton:SetPoint("RIGHT", searchRow, "RIGHT", 0, 0)
	Add(searchRow, 28)

	local suggestionsFrame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
	suggestionsFrame:SetPoint("TOPLEFT", searchBox, "BOTTOMLEFT", 0, -4)
	suggestionsFrame:SetPoint("RIGHT", searchBox, "RIGHT", 0, 0)
	suggestionsFrame:SetHeight(32)
	suggestionsFrame:SetFrameLevel((parent:GetFrameLevel() or 1) + 30)
	SetFrameBackdrop(suggestionsFrame, 0.018, 0.016, 0.012, 0.96, 0.48, 0.34, 0.10, 0.84)
	suggestionsFrame:Hide()
	handle.suggestionsFrame = suggestionsFrame

	for index = 1, MAX_SUGGESTIONS do
		local row = CreateFrame("Button", nil, suggestionsFrame, "BackdropTemplate")
		row:SetHeight(SUGGESTION_ROW_HEIGHT - 4)
		row:SetPoint("TOPLEFT", suggestionsFrame, "TOPLEFT", 4, -4 - ((index - 1) * SUGGESTION_ROW_HEIGHT))
		row:SetPoint("RIGHT", suggestionsFrame, "RIGHT", -4, 0)
		SetFrameBackdrop(row)
		row.primary = CreateLabel(row, "", "BetterFriendlistFontHighlightSmall")
		row.primary:SetPoint("TOPLEFT", row, "TOPLEFT", 8, -5)
		row.primary:SetPoint("RIGHT", row, "RIGHT", -8, 0)
		row.primary:SetHeight(14)
		row.secondary = CreateLabel(row, "", "BetterFriendlistFontDisableSmall")
		row.secondary:SetPoint("TOPLEFT", row.primary, "BOTTOMLEFT", 0, -3)
		row.secondary:SetPoint("RIGHT", row.primary, "RIGHT", 0, 0)
		row.secondary:SetHeight(12)
		row:SetScript("OnEnter", function(button)
			SetFrameBackdrop(button, 0.07, 0.055, 0.03, 0.82, 0.45, 0.34, 0.12, 0.95)
		end)
		row:SetScript("OnLeave", function(button)
			SetFrameBackdrop(button)
		end)
		row:SetScript("OnClick", function()
			if row.candidate then
				local ok, reason = AutoRaidAssist:AddTargetFromCandidate(row.candidate)
				handle:SetStatus(ok and "" or reason)
				if ok then
					searchBox:SetText("")
					searchBox:ClearFocus()
					handle:HideSuggestions()
				end
				handle:RefreshTargets()
				handle:RefreshSuggestions()
			end
		end)
		handle.suggestionRows[index] = row
	end

	local noSuggestions = CreateLabel(suggestionsFrame, L("AUTO_RAID_ASSIST_NO_RESULTS", "No matching friends"), "BetterFriendlistFontDisableSmall")
	noSuggestions:SetPoint("LEFT", suggestionsFrame, "LEFT", 10, 0)
	noSuggestions:SetPoint("RIGHT", suggestionsFrame, "RIGHT", -10, 0)
	noSuggestions:SetHeight(24)
	handle.noSuggestions = noSuggestions

	local status = CreateLabel(parent, "", "BetterFriendlistFontDisableSmall")
	handle.status = Add(status, 18)

	local targetsTitle = CreateLabel(parent, L("AUTO_RAID_ASSIST_TARGETS", "Targets"), "BetterFriendlistFontNormal")
	Add(targetsTitle, 18)

	local targetsFrame = CreateFrame("Frame", nil, parent)
	targetsFrame:SetHeight(math.max(24, math.min(math.max(self:GetTargetCount(), 1), MAX_TARGET_ROWS) * TARGET_ROW_HEIGHT))
	handle.targetsFrame = Add(targetsFrame, targetsFrame:GetHeight())

	for index = 1, MAX_TARGET_ROWS do
		local row = CreateFrame("Frame", nil, targetsFrame, "BackdropTemplate")
		row:SetHeight(TARGET_ROW_HEIGHT - 4)
		row:SetPoint("TOPLEFT", targetsFrame, "TOPLEFT", 0, -((index - 1) * TARGET_ROW_HEIGHT))
		row:SetPoint("RIGHT", targetsFrame, "RIGHT", 0, 0)
		SetFrameBackdrop(row, 0.025, 0.022, 0.018, 0.55)
		row.primary = CreateLabel(row, "", "BetterFriendlistFontHighlightSmall")
		row.primary:SetPoint("TOPLEFT", row, "TOPLEFT", 8, -5)
		row.primary:SetPoint("RIGHT", row, "RIGHT", -88, 0)
		row.primary:SetHeight(14)
		row.secondary = CreateLabel(row, "", "BetterFriendlistFontDisableSmall")
		row.secondary:SetPoint("TOPLEFT", row.primary, "BOTTOMLEFT", 0, -3)
		row.secondary:SetPoint("RIGHT", row.primary, "RIGHT", 0, 0)
		row.secondary:SetHeight(12)
		row.removeButton = CreateSmallButton(row, L("AUTO_RAID_ASSIST_REMOVE", "Remove"), 74, buttonOptions)
		row.removeButton:SetPoint("RIGHT", row, "RIGHT", -6, 0)
		row.removeButton:SetScript("OnClick", function()
			if row.target then
				AutoRaidAssist:RemoveTarget(row.target.key or row.target.id)
				handle:SetStatus("")
				handle:RefreshTargets()
			end
		end)
		handle.targetRows[index] = row
	end

	local noTargets = CreateLabel(targetsFrame, L("AUTO_RAID_ASSIST_NO_TARGETS", "No targets selected"), "BetterFriendlistFontDisableSmall")
	noTargets:SetPoint("TOPLEFT", targetsFrame, "TOPLEFT", 0, -2)
	noTargets:SetPoint("RIGHT", targetsFrame, "RIGHT", 0, 0)
	noTargets:SetHeight(18)
	handle.noTargets = noTargets

	local function AddSearchInput()
		local ContactIdentity = GetContactIdentity()
		local query = ContactIdentity and ContactIdentity:CleanString(searchBox:GetText()) or (searchBox:GetText() or "")
		if not query or query == "" then
			handle:SetStatus("")
			handle:HideSuggestions()
			return
		end

		local candidates = AutoRaidAssist:BuildCandidateList(query, MAX_SUGGESTIONS)
		if candidates[1] then
			local ok, reason = AutoRaidAssist:AddTargetFromCandidate(candidates[1])
			handle:SetStatus(ok and "" or reason)
			if ok then
				searchBox:SetText("")
				searchBox:ClearFocus()
				handle:HideSuggestions()
			end
			handle:RefreshTargets()
			handle:RefreshSuggestions()
			return
		end

		local ok, reason = AutoRaidAssist:AddManualCharacterTarget(query)
		handle:SetStatus(ok and "" or (reason == "invalidCharacter" and "noResults" or reason))
		if ok then
			searchBox:SetText("")
			searchBox:ClearFocus()
			handle:HideSuggestions()
		end
		handle:RefreshTargets()
		handle:RefreshSuggestions()
	end

	addButton:SetScript("OnClick", AddSearchInput)
	searchBox:SetScript("OnTextChanged", function(editBox)
		handle.searchText = editBox:GetText() or ""
		handle:RefreshSuggestions()
	end)
	searchBox:SetScript("OnEditFocusGained", function()
		handle.searchFocused = true
		handle:RefreshSuggestions()
	end)
	searchBox:SetScript("OnEditFocusLost", function()
		handle.searchFocused = false
		if C_Timer and C_Timer.After then
			C_Timer.After(0.12, function()
				if not handle.searchFocused then
					handle:HideSuggestions()
				end
			end)
		else
			handle:HideSuggestions()
		end
	end)
	searchBox:SetScript("OnEnterPressed", function(editBox)
		AddSearchInput()
		editBox:ClearFocus()
	end)
	searchBox:SetScript("OnEscapePressed", function(editBox)
		editBox:ClearFocus()
		handle:HideSuggestions()
	end)

	function handle:SetStatus(reason)
		if not self.status then
			return
		end
		if reason == "duplicate" then
			self.status:SetText(L("AUTO_RAID_ASSIST_DUPLICATE", "Already selected."))
		elseif reason == "invalidCharacter" or reason == "invalid" then
			self.status:SetText(L("AUTO_RAID_ASSIST_INVALID_CHARACTER", "Use Name-Realm."))
		elseif reason == "noResults" then
			self.status:SetText(L("AUTO_RAID_ASSIST_NO_RESULTS", "No matching friends"))
		else
			self.status:SetText("")
		end
	end

	function handle:HideSuggestions()
		if self.suggestionsFrame then
			self.suggestionsFrame:Hide()
		end
	end

	function handle:RefreshSuggestions()
		if not self.suggestionsFrame then
			return
		end
		local query = self.searchText or ""
		if not self.searchFocused or query == "" then
			self:HideSuggestions()
			return
		end

		local candidates = AutoRaidAssist:BuildCandidateList(query, MAX_SUGGESTIONS)
		for index, row in ipairs(self.suggestionRows) do
			local candidate = candidates[index]
			row.candidate = candidate
			if candidate then
				row.primary:SetText(candidate.displayName or candidate.value or "")
				row.secondary:SetText(candidate.subtitle or "")
				row:Show()
			else
				row:Hide()
			end
		end
		if #candidates == 0 then
			self.noSuggestions:Show()
			self.suggestionsFrame:SetHeight(32)
		else
			self.noSuggestions:Hide()
			self.suggestionsFrame:SetHeight((math.min(#candidates, MAX_SUGGESTIONS) * SUGGESTION_ROW_HEIGHT) + 8)
		end
		self.suggestionsFrame:Show()
	end

	function handle:RefreshTargets()
		local targets = AutoRaidAssist:GetTargets()
		local visibleTargets = math.min(#targets, MAX_TARGET_ROWS)
		for index, row in ipairs(self.targetRows) do
			local target = targets[index]
			row.target = target
			if target then
				local primary, secondary = AutoRaidAssist:GetTargetDisplay(target)
				row.primary:SetText(primary or "")
				row.secondary:SetText(secondary or "")
				row:Show()
			else
				row:Hide()
			end
		end
		if #targets == 0 then
			self.noTargets:Show()
		else
			self.noTargets:Hide()
		end
		if self.targetsFrame then
			self.targetsFrame:SetHeight(#targets == 0 and 24 or (visibleTargets * TARGET_ROW_HEIGHT))
		end
		if self.parent and self.parent.SetHeight then
			local nextHeight = AutoRaidAssist:GetSettingsPageHeight({
				includeEnableToggle = self.includeEnableToggle,
			})
			self.parent:SetHeight(nextHeight)
			if self.layoutReady and self.lastHeight ~= nextHeight and type(self.requestLayout) == "function" then
				self.lastHeight = nextHeight
				self.requestLayout()
			else
				self.lastHeight = nextHeight
			end
		end
	end

	function handle:Refresh()
		self:RefreshSuggestions()
		self:RefreshTargets()
	end

	handle:Refresh()
	handle.layoutReady = true
	return handle
end

return AutoRaidAssist
