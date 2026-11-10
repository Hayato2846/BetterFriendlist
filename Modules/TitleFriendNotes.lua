local _, BFL = ...

local Notes = BFL.FriendNotes
local TitleNotes = {}
BFL.TitleFriendNotes = TitleNotes

local durableBackups, durableNotes, durableOriginals
local pending, reserved = {}, {}
local timer, reportReturn
local alphabet = "0123456789ABCDEFGHJKMNPQRSTVWXYZ"
local keyPrefix = "bnet_title_"

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
	until not (tokens[token] or reserved[token] or store.active[token] or store.notes[token]
		or BetterFriendlistDB.friendGroups[keyPrefix .. token])
	reserved[token] = true
	return token
end

-- A complete, readable snapshot is necessary to prove marker uniqueness.
function TitleNotes:Inspect(accounts)
	local rows, tokens, uids = {}, {}, {}
	for index, account in ipairs(accounts) do
		if not Notes.IsReadableTable(account) or BFL:IsSecret(account.friendLevel) then return end
		if account.friendLevel == nil then
			local tag = account.battleTag
			if not Notes.IsReadableString(tag) or tag == "" then return end
		end
		if BFL.IsTitleFriend(account) then
			if BFL:IsSecret(account.isFriend) or account.isFriend ~= true then return end
			local uid = Notes.GetBNetUID(account)
			if not uid or uids[uid] then return end
			local note = account.note
			if not Notes.IsReadableString(note) then return end
			local text, token, problem = Notes.SplitTitleGroupNote(note)
			if token and note ~= Notes.AppendTitleGroupToken(text, token) then token, problem = nil, "ambiguous" end
			local row = { uid = uid, index = index, note = note, text = text, token = token, problem = problem }
			rows[#rows + 1], uids[uid] = row, row
			Notes.ForEachTitleGroupToken(note, function(found)
				if tokens[found] ~= nil then tokens[found] = false
				else tokens[found] = token == found and row or false end
			end)
		end
	end
	return rows, tokens, uids
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
	local uid = Notes.GetBNetUID(account)
	local token = uid and db and db:GetVerifiedTitleFriendToken(uid)
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
	if ok or reason == "pending" then
		pending[row.uid] = { token = token, value = value, operation = operation }
		return true
	end
	return false
end

local function ConfirmWrites(store, tokens, uids)
	for uid, write in pairs(pending) do
		local row = uids[uid]
		if write.operation == "return" then
			if row and row.note == write.value and tokens[write.token] == nil then
				store.active[write.token] = nil
				BetterFriendlistDB.friendGroups[keyPrefix .. write.token] = nil
				pending[uid] = nil
			end
		elseif row and row.token == write.token and tokens[write.token] == row and row.note == write.value then
			pending[uid] = nil
		end
	end
end

function TitleNotes:Process()
	local accounts = self:ReadRoster()
	if not accounts then return end
	local rows, tokens, uids = self:Inspect(accounts)
	if not rows then return end
	local store = GetStore()
	ConfirmWrites(store, tokens, uids)
	local batch, remaining = 0, 0
	if store.enabled == false then
		if not store.returning then return end
		for _, row in ipairs(rows) do
			local token = row.token
			if token and tokens[token] == row then
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
		if remaining == 0 and not next(pending) then
			store.returning = nil
			store.active = {}
			reportReturn = nil
			TellPlayer("TITLE_FRIEND_NOTES_RETURNED")
		elseif batch > 0 then
			self:Schedule()
		elseif reportReturn then
			reportReturn = nil
			TellPlayer("TITLE_FRIEND_NOTES_PENDING")
		end
		if batch > 0 then RefreshFriends() end
		return
	end

	local missing = false
	for token in pairs(store.active) do
		if not tokens[token] then missing = true; break end
	end
	local backupCodes = {}
	for code, value in pairs(store.backups) do
		if not backupCodes[value] or durableBackups[code] == value then backupCodes[value] = code end
	end
	for _, row in ipairs(rows) do
		local token, text = row.token, row.text
		if token and tokens[token] == row then
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
		elseif not token and not row.problem and not missing and not pending[row.uid] then
			local backup = backupCodes[text]
			if text ~= "" and not backup then
				repeat backup = RandomCode(8) until not store.backups[backup]
				store.backups[backup], backupCodes[text] = text, backup
			end
			if batch < 8 and (text == "" or backup and durableBackups[backup] == text) then
				token = GetToken(backup, store, tokens)
				if Write(row, Notes.AppendTitleGroupToken("", token), token, "link") then
					store.notes[token] = text
					store.active[token] = true
					batch = batch + 1
				end
			end
		end
	end
	if batch > 0 then
		RefreshFriends()
		self:Schedule()
	end
end

function TitleNotes:Schedule()
	if timer or not self:IsSupported() or not BetterFriendlistDB then return end
	local store = GetStore()
	if store.enabled == false and not store.returning then return end
	timer = C_Timer.NewTimer(0.35, function()
		timer = nil
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
	local token = db:GetVerifiedTitleFriendToken(uid, true)
	if not token then
		TellPlayer("TITLE_FRIEND_GROUP_ID_UNAVAILABLE")
		return true
	end
	local store = GetStore()
	local account = Notes.FindBNetFriend(uid)
	local original
	if account then
		local text, marker = Notes.SplitTitleGroupNote(account.note)
		if marker == token then original = text end
	end
	local function Save(dialog)
		if not self:IsEnabled() or db:GetVerifiedTitleFriendToken(uid, true) ~= token then return end
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

for _, event in ipairs({
	"PLAYER_ENTERING_WORLD", "BN_CONNECTED", "BN_FRIEND_LIST_SIZE_CHANGED", "BN_FRIEND_INFO_CHANGED",
	"PLAYER_REGEN_ENABLED",
}) do
	if BFL.IsForever then BFL:RegisterEventCallback(event, Schedule) end
end
if BFL.IsForever then
	BFL:RegisterEventCallback("PLAYER_LOGOUT", function()
		if timer then timer:Cancel(); timer = nil end
	end)
end
