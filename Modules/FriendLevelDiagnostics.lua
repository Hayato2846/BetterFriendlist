-- Internal, deliberately undocumented diagnostics for inconsistent friend levels.
-- Output stays locale-neutral so reports from different clients remain comparable.

local ADDON_NAME, BFL = ...
local Diagnostics = BFL:RegisterModule("FriendLevelDiagnostics", {})

local COMMAND = "/bfllvldiag"
local PREFIX = "[BFL-LVL]"
local WOW_CLIENT = BNET_CLIENT_WOW or "WoW"
local MAX_REPORTS = 25

local function IsSecret(value)
	if not BFL.IsSecret then
		return false
	end
	local ok, secret = pcall(BFL.IsSecret, BFL, value)
	return ok and secret == true
end

local function SafeValue(value)
	if value == nil then
		return "<nil>"
	end
	if IsSecret(value) then
		return "<secret>"
	end
	local ok, text = pcall(tostring, value)
	if not ok then
		return "<unprintable>"
	end
	text = text:gsub("[\r\n;]", " ")
	if #text > 120 then
		text = text:sub(1, 117) .. "..."
	end
	return text
end

local function Emit(label, fields)
	local parts = { PREFIX, label }
	for _, field in ipairs(fields or {}) do
		parts[#parts + 1] = field[1] .. "=" .. SafeValue(field[2])
	end
	if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
		DEFAULT_CHAT_FRAME:AddMessage(table.concat(parts, " "))
	end
end

local function CanInspect(value)
	return value ~= nil and not IsSecret(value)
end

local function SafeEqual(left, right)
	if not CanInspect(left) or not CanInspect(right) then
		return false
	end
	local ok, equal = pcall(function()
		return left == right
	end)
	return ok and equal == true
end

local function SafeFirstCall(callback, ...)
	if type(callback) ~= "function" then
		return nil, "unavailable"
	end
	local ok, value = pcall(callback, ...)
	if not ok then
		return nil, SafeValue(value)
	end
	return value, nil
end

local function IsWoWAccount(info)
	return type(info) == "table" and info.clientProgram == WOW_CLIENT
end

local function IsPositiveLevel(level)
	return type(level) == "number" and level > 0
end

local function IsOnlineWoWAccount(info)
	return IsWoWAccount(info) and info.isOnline == true
end

local function AddReason(reasons, seen, reason)
	if reason and not seen[reason] then
		seen[reason] = true
		reasons[#reasons + 1] = reason
	end
end

local function LevelsDiffer(left, right)
	return type(left) == "number" and type(right) == "number" and left ~= right
end

local function FindGameAccountByID(record, gameAccountID)
	if not CanInspect(gameAccountID) then
		return nil
	end
	for _, snapshot in ipairs(record.gameAccounts or {}) do
		local raw = snapshot.raw
		if raw and SafeEqual(raw.gameAccountID, gameAccountID) then
			return raw
		end
	end
	return nil
end

function Diagnostics:AnalyzeRecord(record)
	local reasons, seen = {}, {}
	local rawInvalid = false
	local positiveAlternative = false
	local normalizationMismatch = false
	local focused = record.focused
	local bflFriend = record.bflFriend
	local maxLevel = BFL.GetMaxLevel and BFL.GetMaxLevel() or nil

	if IsOnlineWoWAccount(focused) then
		if not IsPositiveLevel(focused.characterLevel) then
			rawInvalid = true
			AddReason(reasons, seen, "api.focused.characterLevel=" .. SafeValue(focused.characterLevel))
		elseif maxLevel and focused.characterLevel > maxLevel then
			AddReason(reasons, seen, "api.focused.level_above_client_max")
		end
	end
	local accountByIDFocused = record.accountByID and record.accountByID.gameAccountInfo or nil
	if IsOnlineWoWAccount(focused) and accountByIDFocused then
		if IsPositiveLevel(accountByIDFocused.characterLevel) then
			positiveAlternative = true
		end
		if LevelsDiffer(focused.characterLevel, accountByIDFocused.characterLevel) then
			AddReason(reasons, seen, "api.focused.account_by_id_level_mismatch")
		end
	end

	for _, snapshot in ipairs(record.gameAccounts or {}) do
		local raw = snapshot.raw
		if IsOnlineWoWAccount(raw) then
			if not IsPositiveLevel(raw.characterLevel) then
				rawInvalid = true
				AddReason(
					reasons,
					seen,
					"api.gameAccount[" .. SafeValue(snapshot.index) .. "].characterLevel=" .. SafeValue(raw.characterLevel)
				)
			elseif maxLevel and raw.characterLevel > maxLevel then
				AddReason(reasons, seen, "api.gameAccount[" .. SafeValue(snapshot.index) .. "].level_above_client_max")
			end

			for _, alternate in ipairs({ snapshot.byID, snapshot.byGUID, snapshot.accountByGUID, snapshot.legacy }) do
				if alternate and IsPositiveLevel(alternate.characterLevel) then
					positiveAlternative = true
				end
				if alternate and LevelsDiffer(raw.characterLevel, alternate.characterLevel) then
					AddReason(
						reasons,
						seen,
						"api.gameAccount[" .. SafeValue(snapshot.index) .. "].accessor_level_mismatch"
					)
				end
			end
		end
	end

	if record.kind == "wow" then
		local wowInfo = record.wowInfo
		if wowInfo and wowInfo.connected == true and not IsPositiveLevel(wowInfo.level) then
			rawInvalid = true
			AddReason(reasons, seen, "api.wowFriend.level=" .. SafeValue(wowInfo.level))
		end
	end

	if bflFriend then
		local selected = bflFriend.gameAccountInfo
		local shouldHaveLevel = bflFriend.connected == true
			and ((record.kind == "wow") or IsWoWAccount(selected) or IsWoWAccount(focused))
		if shouldHaveLevel and not IsPositiveLevel(bflFriend.level) then
			AddReason(reasons, seen, "bfl.level=" .. SafeValue(bflFriend.level))
		end

		local selectedRaw = selected and FindGameAccountByID(record, selected.gameAccountID) or focused
		if record.kind == "wow" then
			selectedRaw = record.wowInfo and { characterLevel = record.wowInfo.level } or nil
		end
		if selectedRaw and IsPositiveLevel(selectedRaw.characterLevel) and not IsPositiveLevel(bflFriend.level) then
			normalizationMismatch = true
			AddReason(reasons, seen, "bfl.level_missing_while_selected_api_level_is_positive")
		elseif selectedRaw and LevelsDiffer(bflFriend.level, selectedRaw.characterLevel) then
			normalizationMismatch = true
			AddReason(reasons, seen, "bfl.level_differs_from_selected_api_account")
		end
	end

	local verdict = "NO_LEVEL_DISCREPANCY"
	if normalizationMismatch then
		verdict = "BFL_NORMALIZATION_MISMATCH"
	elseif rawInvalid and positiveAlternative then
		verdict = "API_ACCESSOR_MISMATCH"
	elseif rawInvalid then
		verdict = "API_REPORTED_NONPOSITIVE_LEVEL"
	elseif #reasons > 0 then
		verdict = "OTHER_LEVEL_DISCREPANCY"
	end

	return reasons, verdict
end

local function FindBFLFriend(FriendsList, friendIndex, accountInfo, kind)
	local indexFallback
	for _, friend in ipairs((FriendsList and FriendsList.friendsList) or {}) do
		if friend.type == kind then
			if kind == "bnet" then
				if accountInfo and SafeEqual(friend.bnetAccountID, accountInfo.bnetAccountID) then
					return friend
				end
			elseif friend.index == friendIndex then
				return friend
			end
			if friend.index == friendIndex then
				indexFallback = friend
			end
		end
	end
	return indexFallback
end

local function SnapshotLegacyGameAccount(friendIndex, accountIndex)
	if type(BNGetFriendGameAccountInfo) ~= "function" then
		return nil
	end
	local values = { pcall(BNGetFriendGameAccountInfo, friendIndex, accountIndex) }
	if not values[1] then
		return { error = SafeValue(values[2]) }
	end
	return {
		hasFocus = values[2],
		characterName = values[3],
		clientProgram = values[4],
		realmName = values[5],
		realmID = values[6],
		areaName = values[11],
		characterLevel = values[12],
		richPresence = values[13],
		isOnline = values[16],
		gameAccountID = values[17],
		playerGuid = values[21],
		wowProjectID = values[22],
	}
end

local function SnapshotGameAccount(friendIndex, accountIndex, raw)
	local snapshot = {
		index = accountIndex,
		raw = raw,
		legacy = SnapshotLegacyGameAccount(friendIndex, accountIndex),
	}
	if not raw then
		return snapshot
	end

	if C_BattleNet and CanInspect(raw.gameAccountID) then
		snapshot.byID = SafeFirstCall(C_BattleNet.GetGameAccountInfoByID, raw.gameAccountID)
	end
	if C_BattleNet and CanInspect(raw.playerGuid) then
		snapshot.byGUID = SafeFirstCall(C_BattleNet.GetGameAccountInfoByGUID, raw.playerGuid)
		local accountByGUID = SafeFirstCall(C_BattleNet.GetFriendAccountInfo, friendIndex, raw.playerGuid)
		snapshot.accountByGUID = accountByGUID and accountByGUID.gameAccountInfo or nil
	end
	return snapshot
end

local function BuildBNetRecord(FriendsList, friendIndex, accountInfo)
	local record = {
		kind = "bnet",
		friendIndex = friendIndex,
		accountInfo = accountInfo,
		focused = accountInfo and accountInfo.gameAccountInfo or nil,
		bflFriend = FindBFLFriend(FriendsList, friendIndex, accountInfo, "bnet"),
		gameAccounts = {},
	}
	if accountInfo and C_BattleNet and CanInspect(accountInfo.bnetAccountID) then
		record.accountByID = SafeFirstCall(C_BattleNet.GetAccountInfoByID, accountInfo.bnetAccountID)
	end
	local numGameAccounts = 0
	if C_BattleNet and C_BattleNet.GetFriendNumGameAccounts then
		numGameAccounts = SafeFirstCall(C_BattleNet.GetFriendNumGameAccounts, friendIndex) or 0
	end
	record.numGameAccounts = tonumber(numGameAccounts) or 0
	for accountIndex = 1, record.numGameAccounts do
		local raw
		if C_BattleNet and C_BattleNet.GetFriendGameAccountInfo then
			raw = SafeFirstCall(C_BattleNet.GetFriendGameAccountInfo, friendIndex, accountIndex)
		elseif BFL.GetBNetFriendGameAccountInfo then
			raw = SafeFirstCall(BFL.GetBNetFriendGameAccountInfo, friendIndex, accountIndex)
		end
		record.gameAccounts[#record.gameAccounts + 1] = SnapshotGameAccount(friendIndex, accountIndex, raw)
	end
	record.reasons, record.verdict = Diagnostics:AnalyzeRecord(record)
	return record
end

local function BuildWoWRecord(FriendsList, friendIndex, wowInfo)
	local record = {
		kind = "wow",
		friendIndex = friendIndex,
		wowInfo = wowInfo,
		bflFriend = FindBFLFriend(FriendsList, friendIndex, nil, "wow"),
		gameAccounts = {},
	}
	record.reasons, record.verdict = Diagnostics:AnalyzeRecord(record)
	return record
end

local function AddSearchCandidate(candidates, value)
	if type(value) == "string" and not IsSecret(value) and value ~= "" then
		candidates[#candidates + 1] = value
	end
end

local function MatchesQuery(record, query)
	if not query or query == "" then
		return true
	end
	local candidates = {}
	local accountInfo = record.accountInfo
	local bflFriend = record.bflFriend
	local wowInfo = record.wowInfo
	if accountInfo then
		AddSearchCandidate(candidates, accountInfo.accountName)
		AddSearchCandidate(candidates, accountInfo.battleTag)
		AddSearchCandidate(candidates, accountInfo.gameAccountInfo and accountInfo.gameAccountInfo.characterName)
	end
	if bflFriend then
		AddSearchCandidate(candidates, bflFriend.accountName)
		AddSearchCandidate(candidates, bflFriend.battleTag)
		AddSearchCandidate(candidates, bflFriend.characterName)
		AddSearchCandidate(candidates, bflFriend.name)
		AddSearchCandidate(candidates, bflFriend.displayName)
	end
	if wowInfo then
		AddSearchCandidate(candidates, wowInfo.name)
	end
	for _, snapshot in ipairs(record.gameAccounts or {}) do
		AddSearchCandidate(candidates, snapshot.raw and snapshot.raw.characterName)
	end
	query = query:lower()
	for _, candidate in ipairs(candidates) do
		local ok, lowered = pcall(string.lower, candidate)
		if ok and lowered:find(query, 1, true) then
			return true
		end
	end
	return false
end

local function EmitGameAccount(label, info)
	if not info then
		Emit(label, { { "value", nil } })
		return
	end
	Emit(label .. ".core", {
		{ "id", info.gameAccountID },
		{ "client", info.clientProgram },
		{ "online", info.isOnline },
		{ "focus", info.hasFocus },
		{ "project", info.wowProjectID },
		{ "character", info.characterName },
		{ "level", info.characterLevel },
		{ "realm", info.realmName },
		{ "zone", info.areaName },
	})
	Emit(label .. ".meta", {
		{ "realmID", info.realmID },
		{ "classID", info.classID },
		{ "class", info.className },
		{ "faction", info.factionName },
		{ "guid", info.playerGuid },
		{ "region", info.regionID },
		{ "currentRegion", info.isInCurrentRegion },
		{ "timerunning", info.timerunningSeasonID },
		{ "richPresence", info.richPresence },
	})
end

local function EmitBNetRecord(record, reportIndex)
	local accountInfo = record.accountInfo
	local friend = record.bflFriend
	local FriendsList = BFL:GetModule("FriendsList")
	local formattedInfo
	if friend and FriendsList and FriendsList.FormatInfoLine then
		formattedInfo = SafeFirstCall(FriendsList.FormatInfoLine, FriendsList, friend)
	end
	Emit("record", {
		{ "n", reportIndex },
		{ "kind", "bnet" },
		{ "friendIndex", record.friendIndex },
		{ "bnetID", accountInfo and accountInfo.bnetAccountID },
		{ "account", accountInfo and accountInfo.accountName },
		{ "battleTag", accountInfo and accountInfo.battleTag },
		{ "gameAccounts", record.numGameAccounts },
	})
	Emit("account", {
		{ "friendLevel", accountInfo and accountInfo.friendLevel },
		{ "appearOffline", accountInfo and accountInfo.appearOffline },
		{ "isAFK", accountInfo and accountInfo.isAFK },
		{ "isDND", accountInfo and accountInfo.isDND },
		{ "lastOnline", accountInfo and accountInfo.lastOnlineTime },
	})
	Emit("bfl", {
		{ "present", friend ~= nil },
		{ "index", friend and friend.index },
		{ "connected", friend and friend.connected },
		{ "character", friend and friend.characterName },
		{ "level", friend and friend.level },
		{ "zone", friend and friend.areaName },
		{ "isAFK", friend and friend.isAFK },
		{ "isDND", friend and friend.isDND },
		{ "selectedID", friend and friend.gameAccountInfo and friend.gameAccountInfo.gameAccountID },
		{ "preferredOverride", friend and friend.hasPreferredAccountOverride },
		{ "originalFocusedID", friend and friend.originalGameAccountInfo and friend.originalGameAccountInfo.gameAccountID },
	})
	Emit("render", {
		{ "infoPreset", FriendsList and FriendsList.settingsCache and FriendsList.settingsCache.infoFormatPreset },
		{ "formattedInfo", formattedInfo },
		{ "hideMaxLevel", FriendsList and FriendsList.settingsCache and FriendsList.settingsCache.hideMaxLevel },
		{ "colorLevel", FriendsList and FriendsList.settingsCache and FriendsList.settingsCache.colorLevelByDifficulty },
	})
	EmitGameAccount("focused", record.focused)
	EmitGameAccount("accountByID.focused", record.accountByID and record.accountByID.gameAccountInfo)
	for _, snapshot in ipairs(record.gameAccounts or {}) do
		local label = "ga[" .. SafeValue(snapshot.index) .. "]"
		EmitGameAccount(label, snapshot.raw)
		Emit(label .. ".accessors", {
			{ "byID.level", snapshot.byID and snapshot.byID.characterLevel },
			{ "byGUID.level", snapshot.byGUID and snapshot.byGUID.characterLevel },
			{ "accountByGUID.level", snapshot.accountByGUID and snapshot.accountByGUID.characterLevel },
			{ "legacy.level", snapshot.legacy and snapshot.legacy.characterLevel },
			{ "legacy.online", snapshot.legacy and snapshot.legacy.isOnline },
			{ "legacy.id", snapshot.legacy and snapshot.legacy.gameAccountID },
		})
	end
	Emit("result", {
		{ "verdict", record.verdict },
		{ "reasons", table.concat(record.reasons or {}, ",") },
	})
end

local function EmitWoWRecord(record, reportIndex)
	local raw = record.wowInfo
	local friend = record.bflFriend
	Emit("record", {
		{ "n", reportIndex },
		{ "kind", "wow" },
		{ "friendIndex", record.friendIndex },
		{ "name", raw and raw.name },
		{ "api.connected", raw and raw.connected },
		{ "api.level", raw and raw.level },
		{ "api.zone", raw and raw.area },
		{ "bfl.level", friend and friend.level },
		{ "bfl.connected", friend and friend.connected },
	})
	Emit("result", {
		{ "verdict", record.verdict },
		{ "reasons", table.concat(record.reasons or {}, ",") },
	})
end

function Diagnostics:PrintReport(message)
	message = type(message) == "string" and message:match("^%s*(.-)%s*$") or ""
	local modeAll = message:lower() == "all"
	local query = modeAll and "" or message
	local suspiciousOnly = query == "" and not modeAll
	local FriendsList = BFL:GetModule("FriendsList")
	local version, build, buildDate, tocVersion = GetBuildInfo()
	local totalBNet = BNGetNumFriends and select(1, BNGetNumFriends()) or 0
	local totalWoW = BFL.GetNumWoWFriends and BFL.GetNumWoWFriends() or 0
	Emit("header", {
		{ "addon", BFL.Version or "unknown" },
		{ "client", version },
		{ "build", build },
		{ "buildDate", buildDate },
		{ "toc", tocVersion },
		{ "project", WOW_PROJECT_ID },
		{ "serverTime", GetServerTime and GetServerTime() or time() },
		{ "friendsVersion", BFL.FriendsListVersion },
		{ "mode", modeAll and "all" or (query ~= "" and "query" or "suspicious") },
		{ "query", query ~= "" and query or nil },
	})

	if not (C_BattleNet and C_BattleNet.GetFriendAccountInfo) then
		Emit("error", { { "message", "C_BattleNet.GetFriendAccountInfo unavailable" } })
		return
	end

	local reportCount, suspiciousCount = 0, 0
	for friendIndex = 1, tonumber(totalBNet) or 0 do
		local accountInfo = SafeFirstCall(C_BattleNet.GetFriendAccountInfo, friendIndex)
		local record = BuildBNetRecord(FriendsList, friendIndex, accountInfo)
		local suspicious = #(record.reasons or {}) > 0
		if suspicious then
			suspiciousCount = suspiciousCount + 1
		end
		if MatchesQuery(record, query) and (not suspiciousOnly or suspicious) then
			reportCount = reportCount + 1
			EmitBNetRecord(record, reportCount)
			if reportCount >= MAX_REPORTS then
				break
			end
		end
	end

	if reportCount < MAX_REPORTS then
		for friendIndex = 1, tonumber(totalWoW) or 0 do
			local wowInfo = BFL.GetWoWFriendInfoByIndex and BFL.GetWoWFriendInfoByIndex(friendIndex) or nil
			local record = BuildWoWRecord(FriendsList, friendIndex, wowInfo)
			local suspicious = #(record.reasons or {}) > 0
			if suspicious then
				suspiciousCount = suspiciousCount + 1
			end
			if MatchesQuery(record, query) and (not suspiciousOnly or suspicious) then
				reportCount = reportCount + 1
				EmitWoWRecord(record, reportCount)
				if reportCount >= MAX_REPORTS then
					break
				end
			end
		end
	end

	Emit("footer", {
		{ "reported", reportCount },
		{ "suspicious", suspiciousCount },
		{ "bnetFriends", totalBNet },
		{ "wowFriends", totalWoW },
		{ "truncated", reportCount >= MAX_REPORTS },
	})
	if reportCount == 0 and query ~= "" then
		Emit("hint", { { "message", "No matching friend; use " .. COMMAND .. " or " .. COMMAND .. " all" } })
	end
end

SLASH_BFLLEVELDIAG1 = COMMAND
SlashCmdList.BFLLEVELDIAG = function(message)
	Diagnostics:PrintReport(message)
end
