local _, BFL = ...

local Notes = BFL.FriendNotes
local TitleNotes = {}
BFL.TitleFriendNotes = TitleNotes

local durableBackups, durableNotes, durableOriginals
local pending, reserved = {}, {}
local reportReturn
local alphabet = "0123456789ABCDEFGHJKMNPQRSTVWXYZ"
local keyPrefix = "bnet_title_"
local WRITE_RETRY_DELAY = 5
local MAX_WRITE_ATTEMPTS = 3
local INLINE_MARKER_LENGTH = #" [BFL:00000000]"

local function TellPlayer(key)
	if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage(BFL.L[key]) end
end

function TitleNotes:IsSupported()
	return BFL.IsForever and BFL.AreTitleFriendsEnabled and BFL.AreTitleFriendsEnabled()
end

function TitleNotes:IsEnabled()
	local store = BetterFriendlistDB and BetterFriendlistDB.titleFriendNotes
	return self:IsSupported() and store and store.enabled ~= false
end

function TitleNotes:ManagesAccount(account)
	local store = BetterFriendlistDB and BetterFriendlistDB.titleFriendNotes
	if not self:IsSupported() or not store or not Notes.IsReadableTable(account) or not BFL.IsTitleFriend(account) then
		return false
	end
	local _, token, problem = Notes.SplitTitleGroupNote(account.note)
	return store.enabled ~= false or store.returning or token ~= nil or problem ~= nil
end

local function GetStore()
	local store = BetterFriendlistDB.titleFriendNotes
	if not durableBackups then
		-- Only data loaded from SavedVariables can authorize replacing native text.
		durableBackups, durableNotes, durableOriginals = {}, {}, {}
		for code, value in pairs(store.backups) do durableBackups[code] = value end
		for token, value in pairs(store.notes) do durableNotes[token] = value end
		for token, value in pairs(store.originals) do durableOriginals[token] = value end
	end
	return store
end

local function RandomCode(length)
	local chars = {}
	for index = 1, length do
		local digit = math.random(#alphabet)
		chars[index] = alphabet:sub(digit, digit)
	end
	return table.concat(chars)
end

local function GetToken(backup, store, tokens)
	local token
	repeat
		token = backup and backup .. RandomCode(6) or RandomCode(8)
	until not (tokens[token] ~= nil or reserved[token] or store.active[token] or store.notes[token] or store.originals[token]
		or BetterFriendlistDB.friendGroups[keyPrefix .. token])
	reserved[token] = true
	return token
end

-- Inspect every possible Title Friend note for collisions, even when that row
-- lacks a usable account ID. Only rows with unique live IDs can be addressed.
function TitleNotes:Inspect(accounts)
	local rows, tokens, uids = {}, {}, {}
	local hasUnaddressableMarker = false
	for index, account in ipairs(accounts) do
		if not Notes.IsReadableTable(account) then return end
		local level, tag = account.friendLevel, account.battleTag
		local isTitle = BFL.IsTitleFriend(account)
		if isTitle or BFL:IsSecret(level) or (level == nil and (not Notes.IsReadableString(tag) or tag == "")) then
			local note = account.note
			if not Notes.IsReadableString(note) then return end
			local row
			local uid = Notes.GetTitleFriendUID(account)
			local text, token, problem = Notes.SplitTitleGroupNote(note)
			if token and note ~= Notes.AppendTitleGroupToken(text, token) then token, problem = nil, "ambiguous" end
			if uid and not BFL:IsSecret(account.isFriend) and account.isFriend == true then
				row = { uid = uid, index = index, note = note, text = text, token = token, problem = problem }
				rows[#rows + 1] = row
			elseif token or problem then
				hasUnaddressableMarker = true
			end
			if uid then uids[uid] = uids[uid] == nil and row or false end
			Notes.ForEachTitleGroupToken(note, function(found)
				tokens[found] = tokens[found] == nil and row and row.token == found and row or false
			end)
		end
	end
	return rows, tokens, uids, hasUnaddressableMarker
end

function TitleNotes:ReadRoster()
	if not self:IsSupported() or not BetterFriendlistDB or not BNGetNumFriends
		or not BFL.GetBNetFriendInfo then return end
	if BNConnected and not BNConnected() then return end
	local ok, count = pcall(BNGetNumFriends)
	if not ok or BFL:IsSecret(count) or type(count) ~= "number" or count < 1
		or count > 2000 or count % 1 ~= 0 then return end
	local accounts = {}
	for index = 1, count do
		local readable, account = pcall(BFL.GetBNetFriendInfo, index)
		if not readable or not Notes.IsReadableTable(account) then return end
		accounts[index] = account
	end
	local stillReadable, latestCount = pcall(BNGetNumFriends)
	if not stillReadable or BFL:IsSecret(latestCount) or latestCount ~= count then return end
	return accounts
end

local function GetLocalText(store, token)
	local text = store.notes[token]
	if text == nil and #token == 14 then
		-- The prefix points to a backup that was already on disk before the
		-- native write, including if the client stopped before saving this ID.
		text = durableBackups[token:sub(1, 8)]
	end
	return text
end

function TitleNotes:GetDisplayNote(account)
	if not self:IsEnabled() then return end
	local db = BFL:GetModule("DB")
	local uid = Notes.GetTitleFriendUID(account)
	if not uid or not db then return end
	local token = db:GetVerifiedTitleFriendToken(uid)
	local _, marker = Notes.SplitTitleGroupNote(account.note)
	if token and token == marker then return GetLocalText(GetStore(), token) end
end

local function RefreshFriends()
	local db = BFL:GetModule("DB")
	if db then db:InvalidateTitleFriendGroupKeys() end
	BFL.SettingsVersion = (BFL.SettingsVersion or 0) + 1
	if BFL.FriendsList and BFL.FriendsList.OnFriendListUpdate then BFL.FriendsList:OnFriendListUpdate() end
end

local function Write(row, value, token, operation)
	if pending[row.uid] then return false end
	local ok, reason = Notes.WriteTitleFriendLink(row.uid, row.index, row.note, value)
	if ok or reason == "pending" or reason == "failed" then
		pending[row.uid] = { token = token, value = value, before = row.note, operation = operation,
			attempts = 1, retryAt = GetTime() + WRITE_RETRY_DELAY }
		return true
	end
	return false
end

local function ConfirmWrites(store, tokens, uids)
	local now, waiting, retries = GetTime(), false, 0
	for uid, write in pairs(pending) do
		local row = uids[uid]
		local returning = write.operation == "return"
		if not row or (row.note ~= write.before and row.note ~= write.value) then
			pending[uid] = nil
		elseif row.note == write.value then
			if returning and tokens[write.token] == nil then
				store.active[write.token] = nil
				BetterFriendlistDB.friendGroups[keyPrefix .. write.token] = nil
				pending[uid] = nil
			elseif not returning and tokens[write.token] == row then
				pending[uid] = nil
			end
		elseif not returning and store.enabled == false then
			-- While returning notes, allow the last link write to settle.
			if now >= write.retryAt then pending[uid] = nil else waiting = true end
		elseif write.attempts < MAX_WRITE_ATTEMPTS and (tokens[write.token] == nil or tokens[write.token] == row) then
			waiting = true
			if now >= write.retryAt and retries < 8 then
				Notes.WriteTitleFriendLink(uid, row.index, row.note, write.value)
				write.attempts = write.attempts + 1
				write.retryAt = now + WRITE_RETRY_DELAY
				retries = retries + 1
			end
		end
	end
	if retries > 0 then RefreshFriends() end
	return waiting
end

function TitleNotes:Process()
	local accounts = self:ReadRoster()
	if not accounts then return end
	local rows, tokens, uids, hasUnaddressableMarker = self:Inspect(accounts)
	if not rows then return end
	local store = GetStore()
	local waiting = ConfirmWrites(store, tokens, uids)
	local batch, remaining = 0, 0
	if store.enabled == false then
		if not store.returning then return end
		for _, row in ipairs(rows) do
			local token = row.token
			if uids[row.uid] == row and token and tokens[token] == row then
				local text = GetLocalText(store, token)
				if text == nil and row.text ~= "" then text = row.text end
				local clean = row.text == "" or row.text == text or store.originals[token] == row.text
				if text ~= nil and clean and Notes.CountNoteLetters(text) <= 127
					and batch < 8 and Write(row, text, token, "return") then batch = batch + 1 end
			end
		end
		for _, row in ipairs(rows) do
			if row.token or row.problem then remaining = remaining + 1 end
		end
		if remaining == 0 and not hasUnaddressableMarker and not next(pending) then
			store.returning = nil
			store.active = {}
			reportReturn = nil
			TellPlayer("TITLE_FRIEND_NOTES_RETURNED")
		elseif reportReturn and batch == 0 and not waiting then
			reportReturn = nil
			TellPlayer("TITLE_FRIEND_NOTES_PENDING")
		end
		if batch > 0 then RefreshFriends() end
		if batch > 0 or waiting then self:Schedule(batch == 0 and WRITE_RETRY_DELAY or nil) end
		return
	end

	local backupCodes = {}
	for code, value in pairs(store.backups) do
		if not backupCodes[value] or durableBackups[code] == value then backupCodes[value] = code end
	end
	for _, row in ipairs(rows) do
		local token, text = row.token, row.text
		local verifiedID = uids[row.uid] == row
		if verifiedID and token and tokens[token] == row then
			if text ~= "" and not store.active[token] then store.originals[token] = text end
			store.active[token] = true
			if store.notes[token] == nil then
				store.notes[token] = row.text ~= "" and row.text or GetLocalText(store, token)
			end
			if text ~= "" and durableOriginals[token] == text and durableNotes[token] == store.notes[token]
				and durableNotes[token] ~= nil and batch < 8
				and Write(row, Notes.AppendTitleGroupToken("", token), token, "link")
			then
				batch = batch + 1
			end
		elseif verifiedID and not token and not row.problem and not pending[row.uid] then
			local backup = backupCodes[text]
			if text ~= "" and not backup then
				repeat backup = RandomCode(8) until not store.backups[backup]
				store.backups[backup], backupCodes[text] = text, backup
			end
			local backedUp = text == "" or backup and durableBackups[backup] == text
			local inline = not backedUp and Notes.CountNoteLetters(text) + INLINE_MARKER_LENGTH <= 127
			if batch < 8 and (backedUp or inline) then
				-- Until the backup is on disk, keep the full text in the native note.
				if inline then backup = nil end
				token = GetToken(backup, store, tokens)
				if Write(row, Notes.AppendTitleGroupToken(inline and text or "", token), token, "link") then
					store.notes[token] = text
					if inline then store.originals[token] = text end
					batch = batch + 1
				end
			end
		end
	end
	if batch > 0 then
		RefreshFriends()
	end
	if batch > 0 or waiting then self:Schedule(batch == 0 and WRITE_RETRY_DELAY or nil) end
end

function TitleNotes:Schedule(delay)
	if not self:IsSupported() or not BetterFriendlistDB then return end
	local store = GetStore()
	if store.enabled == false and not store.returning then return end
	delay = delay or 0.35
	local due = GetTime() + delay
	if self.timer then
		if due >= self.timerDue then return end
		self.timer:Cancel()
	end
	self.timerDue = due
	self.timer = C_Timer.NewTimer(delay, function()
		self.timer, self.timerDue = nil, nil
		self:Process()
	end)
end

function TitleNotes:SetEnabled(enabled)
	local store = GetStore()
	if enabled and next(pending) then
		TellPlayer("TITLE_FRIEND_NOTES_PENDING")
		return
	end
	store.enabled = enabled
	store.returning = not enabled or nil
	reportReturn = store.returning
	RefreshFriends()
	self:Schedule()
	TellPlayer(enabled and "TITLE_FRIEND_NOTES_ENABLED" or "TITLE_FRIEND_NOTES_RETURNING")
end

function TitleNotes:ShowEditor(id, name)
	if not self:IsEnabled() or BFL:IsSecret(id) or type(id) ~= "number" then return false end
	local uid = "bnet_" .. id
	local db = BFL:GetModule("DB")
	local token, original = db:GetVerifiedTitleFriendToken(uid, true)
	if not token then
		TellPlayer("TITLE_FRIEND_GROUP_ID_UNAVAILABLE")
		self:Schedule()
		return true
	end
	local store = GetStore()
	local function Save(dialog)
		if not self:IsEnabled() then return end
		if db:GetVerifiedTitleFriendToken(uid, true) ~= token then
			TellPlayer("TITLE_FRIEND_GROUP_ID_UNAVAILABLE")
			self:Schedule()
			return
		end
		local box = dialog.GetEditBox and dialog:GetEditBox() or dialog.editBox
		local text = box:GetText()
		if Notes.IsReadableString(text) and Notes.CountNoteLetters(text) <= 127 then
			GetStore().notes[token] = text
			RefreshFriends()
		end
	end
	StaticPopupDialogs.BFL_SET_TITLE_FRIEND_NOTE = {
		text = SET_FRIENDNOTE_LABEL,
		button1 = ACCEPT,
		button2 = CANCEL,
		hasEditBox = 1,
		maxLetters = 127,
		countInvisibleLetters = true,
		editBoxWidth = 350,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		OnShow = function(dialog)
			local box = dialog.GetEditBox and dialog:GetEditBox() or dialog.editBox
			box:SetText(GetLocalText(store, token) or original or "")
			box:SetFocus()
			box:HighlightText()
		end,
		OnAccept = Save,
		EditBoxOnEnterPressed = function(box)
			local dialog = box:GetParent()
			Save(dialog)
			dialog:Hide()
		end,
	}
	StaticPopup_Show("BFL_SET_TITLE_FRIEND_NOTE", name)
	return true
end

local function Schedule()
	TitleNotes:Schedule()
end

if BFL.IsForever then
	BFL:RegisterEventCallback("BN_FRIEND_LIST_SIZE_CHANGED", function()
		-- An account ID can be reused after a roster change. Observe any
		-- outstanding writes, and do not resubmit against the old ID.
		for _, write in pairs(pending) do write.attempts = MAX_WRITE_ATTEMPTS end
		Schedule()
	end)
	BFL:RegisterEventCallback("BN_DISCONNECTED", function() pending = {} end)
end
for _, event in ipairs({
	"PLAYER_ENTERING_WORLD", "BN_CONNECTED", "BN_FRIEND_INFO_CHANGED",
	"PLAYER_REGEN_ENABLED",
}) do
	if BFL.IsForever then BFL:RegisterEventCallback(event, Schedule) end
end
if BFL.IsForever then
	BFL:RegisterEventCallback("PLAYER_LOGOUT", function()
		if TitleNotes.timer then
			TitleNotes.timer:Cancel()
			TitleNotes.timer, TitleNotes.timerDue = nil, nil
		end
	end)
end
