local _, BFL = ...

-- Friend identity and note access shared by sync and the cleanup wizard.
-- Title write identities are pinned to this session; cross-session ID persistence is unverified.
local FriendNotes = {}
BFL.FriendNotes = FriendNotes
local titleIdentities = setmetatable({}, { __mode = "k" })
local watchingRoster = false
local acceptedWrites = {}
local JOURNAL_KEY = "noteSyncPendingWrites"
local TITLE_GROUP_MARKER = "%[BFLG?:"
local TITLE_GROUP_PATTERN = "%[BFL(G?):(%w+)%]"
local TITLE_GROUP_TOKEN_LENGTH = 8
local BNET_NOTE_LIMIT = 127

local function IsSecret(value)
	return BFL.IsSecret and BFL:IsSecret(value)
end

function FriendNotes.IsReadableTable(value)
	return not IsSecret(value) and type(value) == "table" and not (issecrettable and issecrettable(value))
end

function FriendNotes.IsReadableString(value)
	return not IsSecret(value) and type(value) == "string"
end

local function IsTitleGroupToken(format, token)
	if format == "G" then return #token == 16 and not token:find("[^0-9a-f]") end
	return (#token == TITLE_GROUP_TOKEN_LENGTH or #token == 14) and not token:find("[^0-9ABCDEFGHJKMNPQRSTVWXYZ]")
end

function FriendNotes.SplitTitleGroupNote(note)
	if not FriendNotes.IsReadableString(note) then return nil, nil, "unavailable" end
	local start = note:find(TITLE_GROUP_MARKER)
	if not start then return note end
	local first, last, format, token = note:find(TITLE_GROUP_PATTERN, start)
	if first ~= start or not IsTitleGroupToken(format, token) or note:find(TITLE_GROUP_MARKER, last + 1) then
		return note, nil, "ambiguous"
	end
	-- Remove the single separator we added, preserving existing whitespace.
	if start > 1 and note:sub(start - 1, start - 1) == " " then start = start - 1 end
	return note:sub(1, start - 1) .. note:sub(last + 1), token
end

function FriendNotes.AppendTitleGroupToken(note, token)
	if not token then return note end
	local marker = #token == 16 and "[BFLG:" or "[BFL:"
	return note .. (note ~= "" and " " or "") .. marker .. token .. "]"
end

-- Account data is kept intact for writes and group lookups. Only strip the
-- marker when projecting a note into BFL's rows, tooltips and search.
function FriendNotes.GetBNetDisplayNote(account)
	local note = account.note
	if not BFL.IsTitleFriend or not BFL.IsTitleFriend(account) or not FriendNotes.IsReadableString(note) then
		return note
	end
	local localNote = BFL.TitleFriendNotes and BFL.TitleFriendNotes:GetDisplayNote(account)
	if localNote ~= nil then return localNote end
	local clean = note:gsub(" ?(" .. TITLE_GROUP_PATTERN .. ")", function(_, format, token)
		if IsTitleGroupToken(format, token) then return "" end
		return nil -- Keep invalid marker text, including any preceding space.
	end)
	return clean
end

function FriendNotes.PreserveTitleGroupToken(current, desired)
	if not FriendNotes.IsReadableString(desired) then return desired end
	local _, currentToken = FriendNotes.SplitTitleGroupNote(current)
	local _, desiredToken, problem = FriendNotes.SplitTitleGroupNote(desired)
	if currentToken and not desiredToken and not problem then
		return FriendNotes.AppendTitleGroupToken(desired, currentToken)
	end
	return desired
end

function FriendNotes.CountNoteLetters(note)
	-- Blizzard's editor limits letters, so count the leading bytes of UTF-8.
	local _, count = note:gsub("[^\128-\191]", "")
	return count
end

function FriendNotes.ForEachTitleGroupToken(note, callback)
	for format, token in note:gmatch(TITLE_GROUP_PATTERN) do
		if IsTitleGroupToken(format, token) then callback(token) end
	end
end

local function IsName(value)
	return FriendNotes.IsReadableString(value) and value ~= "" and not value:find("|K", 1, true)
end

local function ReadNote(info, key)
	if not FriendNotes.IsReadableTable(info) then return nil end
	local note = info[key]
	if IsSecret(note) then return nil end
	if note == nil then return "" end
	return FriendNotes.IsReadableString(note) and note or nil
end

function FriendNotes.GetBNetUID(account)
	if not FriendNotes.IsReadableTable(account) then return nil end
	local tag = account.battleTag
	if IsSecret(tag) then return nil end
	if IsName(tag) then return "bnet_" .. tag end
	if tag ~= nil and tag ~= "" then return nil end
	local level, id = account.friendLevel, account.bnetAccountID
	local titleLevel = Enum and Enum.BattleNetFriendLevel and Enum.BattleNetFriendLevel.Title
	if not IsSecret(level) and titleLevel and level == titleLevel
		and not IsSecret(id) and type(id) == "number" and id > 0 and id < math.huge and id % 1 == 0
	then
		return "bnet_" .. tostring(id)
	end
	return nil
end

function FriendNotes.GetBNetFriends()
	local friends, indices = {}, {}
	if type(BNGetNumFriends) ~= "function" or not (C_BattleNet and C_BattleNet.GetFriendAccountInfo) then
		return friends, false, 0
	end
	local ok, count = pcall(BNGetNumFriends)
	if not ok or IsSecret(count) or type(count) ~= "number" then return friends, false, 0 end
	local complete = true
	for index = 1, count do
		local readable, account = pcall(C_BattleNet.GetFriendAccountInfo, index)
		local uid = readable and FriendNotes.GetBNetUID(account)
		if uid and ReadNote(account, "note") ~= nil then
			friends[#friends + 1] = account
			if indices[uid] ~= nil then indices[uid] = false else indices[uid] = index end
		else
			complete = false
		end
	end
	return friends, complete, count, indices
end

function FriendNotes.FindBNetFriend(uid, snapshot)
	if not IsName(uid) or not uid:match("^bnet_.+") then return nil end
	if snapshot then
		local account = snapshot.bnet[uid]
		return FriendNotes.GetBNetUID(account) == uid and account or nil
	end
	local match
	for _, account in ipairs(FriendNotes.GetBNetFriends()) do
		if FriendNotes.GetBNetUID(account) == uid then
			if match then return nil end -- An ambiguous identity must never select the first friend.
			match = account
		end
	end
	return match
end

function FriendNotes.ReadBNetNote(uid)
	return ReadNote(FriendNotes.FindBNetFriend(uid), "note")
end

function FriendNotes.GetWoWFriends()
	local friends, indices = {}, {}
	if BFL.CanUseWoWFriendList then
		local ok, enabled = pcall(BFL.CanUseWoWFriendList)
		if not ok or IsSecret(enabled) or type(enabled) ~= "boolean" then return friends, false, 0 end
		if not enabled then return friends, true, 0 end
	end
	if not BFL.GetNumWoWFriends or not BFL.GetWoWFriendInfoByIndex then return friends, false, 0 end
	local ok, count = pcall(BFL.GetNumWoWFriends)
	if not ok or IsSecret(count) or type(count) ~= "number" then return friends, false, 0 end
	local complete = true
	for index = 1, count do
		local readable, info = pcall(BFL.GetWoWFriendInfoByIndex, index)
		if readable and FriendNotes.IsReadableTable(info) and IsName(info.name) and ReadNote(info, "notes") ~= nil then
			friends[#friends + 1] = info
			if indices[info.name] ~= nil then indices[info.name] = false else indices[info.name] = index end
		else
			complete = false
		end
	end
	return friends, complete, count, indices
end

function FriendNotes.FindWoWFriend(name, snapshot)
	if not IsName(name) then return nil end
	if snapshot then
		local info = snapshot.wow[name]
		return FriendNotes.IsReadableTable(info) and info or nil
	end
	local match
	for _, info in ipairs(FriendNotes.GetWoWFriends()) do
		if info.name == name then
			if match then return nil end
			match = info
		end
	end
	return match
end

function FriendNotes.ReadWoWNote(name)
	return ReadNote(FriendNotes.FindWoWFriend(name), "notes")
end

function FriendNotes.GetWoWUID(name)
	if not IsName(name) then return nil end
	local normalized = BFL.NormalizeWoWFriendName and BFL:NormalizeWoWFriendName(name) or name
	return IsName(normalized) and ("wow_" .. normalized) or nil
end

function FriendNotes.GetAcceptedWrite(uid)
	if not IsName(uid) then return nil end
	if acceptedWrites[uid] then return acceptedWrites[uid] end
	-- The journal is installation-local and excluded from profile import/export.
	local saved = BetterFriendlistDB and BetterFriendlistDB[JOURNAL_KEY]
	local record = type(saved) == "table" and saved[uid]
	if not uid:match("^bnet_%d+$") and FriendNotes.IsReadableTable(record)
		and FriendNotes.IsReadableString(record.note) and FriendNotes.IsReadableString(record.before)
	then
		acceptedWrites[uid] = { note = record.note, before = record.before, deliveryOnly = record.deliveryOnly == true,
			guid = FriendNotes.IsReadableString(record.guid) and record.guid or nil,
			name = FriendNotes.IsReadableString(record.name) and record.name or nil }
		return acceptedWrites[uid]
	end
end

function FriendNotes.ObserveAcceptedWrite(uid, current, snapshot)
	local record = FriendNotes.GetAcceptedWrite(uid)
	if not record then return nil end
	if record.identity and not FriendNotes.ResolveBNetIdentity(record.identity, snapshot and snapshot.bnet) then return record end
	if record.guid and record.name then
		local info = snapshot and snapshot.wow and snapshot.wow[record.name] or FriendNotes.FindWoWFriend(record.name)
		if not FriendNotes.IsReadableTable(info) or IsSecret(info.guid) or info.guid ~= record.guid then return record end
	end
	if current ~= record.note then return record end
	record.confirmed = true
	acceptedWrites[uid] = nil
	local saved = BetterFriendlistDB and BetterFriendlistDB[JOURNAL_KEY]
	local entry = type(saved) == "table" and saved[uid]
	if type(entry) == "table" and entry.note == record.note and entry.before == record.before then
		if entry.deliveryOnly then saved[uid] = nil else saved[uid] = true end
		BetterFriendlistDB[JOURNAL_KEY] = next(saved) and saved or nil
	end
	return nil
end

function FriendNotes.PreserveAcceptedWrites()
	if not BetterFriendlistDB then return end
	local saved = BetterFriendlistDB[JOURNAL_KEY] or {}
	for uid, record in pairs(acceptedWrites) do
		if not uid:match("^bnet_%d+$") and saved[uid] == nil then
			saved[uid] = { note = record.note, before = record.before, deliveryOnly = true, name = record.name, guid = record.guid }
		end
	end
	BetterFriendlistDB[JOURNAL_KEY] = next(saved) and saved or nil
end

local function TrackAccepted(uid, note, before, identity, owner, name, guid)
	local saved = BetterFriendlistDB and BetterFriendlistDB[JOURNAL_KEY]
	local previous = type(saved) == "table" and saved[uid] or nil
	local deliveryOnly = owner == "wizard" and (previous == nil or (type(previous) == "table" and previous.deliveryOnly == true))
	local record = { note = note, before = before, identity = identity, deliveryOnly = deliveryOnly, name = name, guid = guid }
	acceptedWrites[uid] = record
	if BetterFriendlistDB and not uid:match("^bnet_%d+$") then
		if type(saved) ~= "table" then saved = {} end
		saved[uid] = { note = note, before = before, deliveryOnly = deliveryOnly or nil, name = name, guid = guid }
		BetterFriendlistDB[JOURNAL_KEY] = saved
	end
	return record
end

-- One fresh snapshot per synchronous batch. Never retain it across timer ticks.
function FriendNotes.CaptureSnapshot()
	local bnet, bnetComplete, bnetTotal, bnetIndices = FriendNotes.GetBNetFriends()
	local wow, wowComplete, wowTotal, wowIndices = FriendNotes.GetWoWFriends()
	local snapshot = { bnet = {}, wow = {}, bnetIndices = bnetIndices or {}, wowIndices = wowIndices or {},
		bnetComplete = bnetComplete, wowComplete = wowComplete,
		complete = bnetComplete and wowComplete, total = bnetTotal + wowTotal }
	for _, account in ipairs(bnet) do
		local uid = FriendNotes.GetBNetUID(account)
		if snapshot.bnet[uid] ~= nil then snapshot.bnet[uid] = false else snapshot.bnet[uid] = account end
	end
	for _, info in ipairs(wow) do
		if snapshot.wow[info.name] ~= nil then snapshot.wow[info.name] = false else snapshot.wow[info.name] = info end
	end
	return snapshot
end

local function FreshBNetFriend(uid, snapshot)
	local index = snapshot and snapshot.bnetIndices[uid]
	if type(index) == "number" then
		local ok, account = pcall(C_BattleNet.GetFriendAccountInfo, index)
		if ok and FriendNotes.GetBNetUID(account) == uid then return account end
	end
	return FriendNotes.FindBNetFriend(uid)
end

local function FreshWoWFriend(name, snapshot)
	local index = snapshot and snapshot.wowIndices[name]
	if type(index) == "number" then
		local ok, info = pcall(BFL.GetWoWFriendInfoByIndex, index)
		if ok and FriendNotes.IsReadableTable(info) and IsName(info.name) and info.name == name then return info end
	end
	return FriendNotes.FindWoWFriend(name)
end

local function GetCharacterGUID(account)
	local game = account.gameAccountInfo
	if FriendNotes.IsReadableTable(game) and IsName(game.playerGuid) then return game.playerGuid end
end

function FriendNotes.CreateBNetIdentity(account)
	local uid = FriendNotes.GetBNetUID(account)
	if not uid then return nil end
	local identity = { uid = uid }
	if not IsName(account.battleTag) then
		identity.title = true
		local _, groupToken = FriendNotes.SplitTitleGroupNote(account.note)
		identity.groupToken = groupToken
		if not groupToken then identity.characterGUID = GetCharacterGUID(account) end
		titleIdentities[identity] = true
		if not watchingRoster and BFL.RegisterEventCallback then
			watchingRoster = true
			local function InvalidateTitleIdentities()
				titleIdentities = setmetatable({}, { __mode = "k" })
			end
			BFL:RegisterEventCallback("BN_FRIEND_LIST_SIZE_CHANGED", InvalidateTitleIdentities)
			BFL:RegisterEventCallback("BN_DISCONNECTED", InvalidateTitleIdentities)
		end
	end
	return identity
end

function FriendNotes.ResolveBNetIdentity(identity, accountsByUID)
	if not FriendNotes.IsReadableTable(identity) or not IsName(identity.uid) or IsSecret(identity.title) then return nil, "identity" end
	if identity.uid:match("^bnet_%d+$") and identity.title ~= true then return nil, "identity" end
	if identity.title and not titleIdentities[identity] then return nil, "identity" end
	-- Callers checking a whole batch may supply one freshly read roster snapshot.
	local account
	if accountsByUID then account = accountsByUID[identity.uid]
	else account = FriendNotes.FindBNetFriend(identity.uid) end
	if FriendNotes.GetBNetUID(account) ~= identity.uid then return nil, "unavailable" end
	if identity.title then
		if identity.groupToken then
			local _, token = FriendNotes.SplitTitleGroupNote(account.note)
			if token ~= identity.groupToken then return nil, "identity" end
			return account
		end
		local guid = identity.characterGUID
		if IsSecret(guid) or (guid ~= nil and not IsName(guid)) then return nil, "identity" end
		if guid ~= nil then
			local currentGUID = GetCharacterGUID(account)
			if currentGUID == nil then return nil, "unavailable" end
			if currentGUID ~= guid then return nil, "identity" end
		end
	end
	return account
end

local function ValidateWrite(current, note, expected)
	if current == nil or not FriendNotes.IsReadableString(note) then return false, "unavailable" end
	if IsSecret(expected) then return false, "unavailable" end
	-- A previous accepted request may be confirmed while its manual retry is
	-- still queued. Reaching the desired state requires no further write.
	if current == note then return true end
	if expected ~= nil and (not FriendNotes.IsReadableString(expected) or current ~= expected) then return false, "changed" end
	return true
end

function FriendNotes.WriteBNetNote(uid, note, expected, snapshot, identity, owner)
	local account = FreshBNetFriend(uid, snapshot)
	if BFL.TitleFriendNotes and BFL.TitleFriendNotes:ManagesAccount(account) then
		return false, "unavailable"
	end
	if identity and not FriendNotes.ResolveBNetIdentity(identity, { [uid] = account }) then return false, "unavailable" end
	local current = ReadNote(account, "note")
	local active = FriendNotes.ObserveAcceptedWrite(uid, current, { bnet = { [uid] = account } })
	if active then return false, "blocked", active end
	local valid, reason = ValidateWrite(current, note, expected)
	if not valid then return false, reason end
	if current == note then return true end
	if uid:match("^bnet_%d+$") then
		local _, currentToken, currentProblem = FriendNotes.SplitTitleGroupNote(current)
		local _, nextToken, nextProblem = FriendNotes.SplitTitleGroupNote(note)
		if currentProblem or nextProblem or currentToken ~= nextToken then
			return false, "identity"
		end
		if nextToken and FriendNotes.CountNoteLetters(note) > BNET_NOTE_LIMIT then return false, "note-full" end
	end
	if type(BNSetFriendNote) ~= "function" then return false, "unavailable" end
	local id = account.bnetAccountID
	if IsSecret(id) or type(id) ~= "number" then return false, "unavailable" end
	local ok, result = pcall(BNSetFriendNote, id, note)
	if not ok or IsSecret(result) or result == false then return false, "failed" end
	if ReadNote(FreshBNetFriend(uid, snapshot), "note") == note then return true end
	TrackAccepted(uid, note, current, identity or FriendNotes.CreateBNetIdentity(account), owner)
	return false, "pending"
end

-- Only the Title Friend migration can replace the link. Recheck the live
-- slot and its exact old note immediately before addressing the native API.
function FriendNotes.WriteTitleFriendLink(uid, index, expected, value)
	if type(BNSetFriendNote) ~= "function" or FriendNotes.CountNoteLetters(value) > BNET_NOTE_LIMIT then
		return false, "unavailable"
	end
	local function ReadCurrent()
		local ok, account = pcall(BFL.GetBNetFriendInfo, index)
		if ok and FriendNotes.GetBNetUID(account) == uid and BFL.IsTitleFriend(account)
			and not IsSecret(account.isFriend) and account.isFriend == true then return account end
	end
	local account = ReadCurrent()
	if not account or ReadNote(account, "note") ~= expected then return false, "changed" end
	local ok, result = pcall(BNSetFriendNote, account.bnetAccountID, value)
	if not ok or IsSecret(result) or result == false then return false, "failed" end
	if ReadNote(ReadCurrent(), "note") == value then return true end
	return false, "pending"
end

function FriendNotes.WriteWoWNote(name, note, expected, snapshot, identity, owner)
	local info = FreshWoWFriend(name, snapshot)
	if identity ~= nil and (not FriendNotes.IsReadableString(identity) or not FriendNotes.IsReadableTable(info)
		or IsSecret(info.guid) or info.guid ~= identity) then return false, "unavailable" end
	local current = ReadNote(info, "notes")
	local uid = FriendNotes.GetWoWUID(name)
	if not uid then return false, "unavailable" end
	local active = FriendNotes.ObserveAcceptedWrite(uid, current, { wow = { [name] = info } })
	if active then return false, "blocked", active end
	local valid, reason = ValidateWrite(current, note, expected)
	if not valid then return false, reason end
	if current == note then return true end
	local setter = C_FriendList and C_FriendList.SetFriendNotes or SetFriendNotes or BFL.SetFriendNotes
	if type(setter) ~= "function" then return false, "unavailable" end
	local ok, result = pcall(setter, name, note)
	if not ok or IsSecret(result) or result == false then return false, "failed" end
	if ReadNote(FreshWoWFriend(name, snapshot), "notes") == note then return true end
	local guid = FriendNotes.IsReadableTable(info) and info.guid
	TrackAccepted(uid, note, current, nil, owner, name, FriendNotes.IsReadableString(guid) and guid or nil)
	return false, "pending"
end
