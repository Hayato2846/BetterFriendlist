local _, BFL = ...

local Notes = BFL.FriendNotes
local Actions = {}
BFL.FriendActions = Actions

local function Read(record, field)
	if not Notes.IsReadableTable(record) then return end
	local value = record[field]
	if not BFL:IsSecret(value) then return value end
end

local function Name(value)
	return Notes.IsReadableString(value) and value ~= "" and value ~= "???" and value ~= UNKNOWN
		and not value:find("[|%c]") and value or nil
end

local function IsID(value)
	return type(value) == "number" and value > 0 and value < math.huge and value % 1 == 0
end

-- Only copy readable identity fields. Roster records and row tables are pooled.
function Actions.Capture(friend, groupKey)
	local captured = Read(friend, "bflFriendAction")
	if captured ~= nil then return captured or nil end
	local kind = Read(friend, "type")
	if kind == "wow" then
		local name = Name(Read(friend, "fullName")) or Name(Read(friend, "name"))
		if name then
			return { kind = kind, name = name, guid = Name(Read(friend, "guid")) }
		end
	elseif kind == "bnet" then
		local account = Read(friend, "accountInfo") or friend
		local id = Read(account, "bnetAccountID")
		if not IsID(id) then return end
		local tag = Name(Read(account, "battleTag"))
		if tag then return { kind = kind, id = id, tag = tag } end
		if not (BFL.IsTitleFriend and BFL.IsTitleFriend(account)) then return end
		local db = BFL:GetModule("DB")
		if groupKey == nil and db and db.GetTitleFriendGroupActionKey then
			groupKey = db:GetTitleFriendGroupActionKey("bnet_" .. id, Read(friend, "rawNote") or Read(account, "note"))
		end
		local titleNotes = BFL.TitleFriendNotes
		if groupKey and titleNotes and titleNotes:IsEnabled() then return { kind = kind, id = id, groupKey = groupKey } end

		-- Before enrollment or with BFL notes disabled, use the character's
		-- identity. Forever character names are unique in their region.
		local game = Read(account, "gameAccountInfo") or Read(friend, "gameAccountInfo")
		local guid = Name(Read(game, "playerGuid"))
		local name = BFL.IsForever and BFL.AreRegionalUniqueNamesEnabled and BFL.AreRegionalUniqueNamesEnabled()
			and Name(Read(game, "characterName"))
		if guid or name then return { kind = kind, id = id, guid = guid, name = name, title = true } end
	end
end

local function MatchesBNet(identity, account)
	if Read(account, "bnetAccountID") ~= identity.id or Read(account, "isFriend") ~= true then return false end
	if identity.tag then return Read(account, "battleTag") == identity.tag end
	if not BFL.IsTitleFriend(account) then return false end
	if identity.groupKey then
		local db = BFL:GetModule("DB")
		return db and db:GetTitleFriendGroupActionKey("bnet_" .. identity.id, Read(account, "note")) == identity.groupKey
	end
	local game = Read(account, "gameAccountInfo")
	if identity.guid then return Read(game, "playerGuid") == identity.guid end
	return identity.name ~= nil and Read(game, "characterName") == identity.name
end

function Actions.Same(first, second)
	if not first or not second then return first == second end
	return first.kind == second.kind and first.id == second.id and first.tag == second.tag
		and first.groupKey == second.groupKey and first.guid == second.guid and first.name == second.name
end

local function HasUniqueTitleLink(identity, fresh)
	if not identity.groupKey then return true end
	local db = BFL:GetModule("DB")
	return db and db:MatchesTitleFriendGroupActionKey("bnet_" .. identity.id, identity.groupKey, fresh)
end

function Actions.ResolveBNetIndex(identity, fresh)
	if not identity or identity.kind ~= "bnet" or not BFL.GetBNetFriendInfo then return end
	if not HasUniqueTitleLink(identity, fresh ~= false) then return end
	local function ReadIndex(index)
		local ok, account = pcall(BFL.GetBNetFriendInfo, index)
		if ok and MatchesBNet(identity, account) then return account, index end
	end
	if BNGetFriendIndex then
		local ok, index = pcall(BNGetFriendIndex, identity.id)
		if ok and not BFL:IsSecret(index) and IsID(index) then return ReadIndex(index) end
	end
	if not BNGetNumFriends then return end
	local ok, count = pcall(BNGetNumFriends)
	if not ok or BFL:IsSecret(count) or not IsID(count) then return end
	for index = 1, count do
		local account = ReadIndex(index)
		if account then return account, index end
	end
end

function Actions.Resolve(identity, fresh)
	if not identity then return end
	if identity.kind == "bnet" then
		local getAccount = C_BattleNet and C_BattleNet.GetAccountInfoByID
		if not getAccount then return (Actions.ResolveBNetIndex(identity, fresh)) end
		local ok, account = pcall(getAccount, identity.id)
		if ok and MatchesBNet(identity, account) and HasUniqueTitleLink(identity, fresh ~= false) then return account end
	elseif identity.kind == "wow" then
		local expected = BFL:NormalizeWoWFriendName(identity.name)
		if not expected then return end
		local function Matches(info)
			local name = Name(Read(info, "name"))
			return name and BFL:NormalizeWoWFriendName(name) == expected
				and (not identity.guid or Read(info, "guid") == identity.guid)
		end
		if BFL.GetWoWFriendInfo then
			local ok, info = pcall(BFL.GetWoWFriendInfo, identity.name)
			if ok and Matches(info) then return info end
		end
		local friends = BFL:GetModule("FriendsList")
		if friends and friends.ResolveWoWFriendIndex and BFL.GetWoWFriendInfoByIndex then
			local ok, index = pcall(friends.ResolveWoWFriendIndex, friends, identity.name)
			if not ok or BFL:IsSecret(index) or not IsID(index) then return end
			local readable, info = pcall(BFL.GetWoWFriendInfoByIndex, index)
			if readable and Matches(info) then return info end
		end
	end
end

function Actions.ResolveGameAccount(identity, gameID, guid)
	if BFL:IsSecret(gameID) or not IsID(gameID) or BFL:IsSecret(guid) then return end
	local account, index = Actions.ResolveBNetIndex(identity)
	if not account then return end
	local function Matches(game)
		return Read(game, "gameAccountID") == gameID and Read(game, "isOnline") == true
			and (not guid or guid == "" or Read(game, "playerGuid") == guid)
	end
	local countAPI = C_BattleNet and C_BattleNet.GetFriendNumGameAccounts
	local gameAPI = C_BattleNet and C_BattleNet.GetFriendGameAccountInfo
	if countAPI and gameAPI then
		local ok, count = pcall(countAPI, index)
		if not ok or BFL:IsSecret(count) or not IsID(count) then return end
		for i = 1, count do
			local readable, game = pcall(gameAPI, index, i)
			if readable and Matches(game) then
				-- The roster can re-sort while the game accounts are read.
				local verified, info = pcall(BFL.GetBNetFriendInfo, index)
				if verified and MatchesBNet(identity, info) then return game end
				return
			end
		end
	else
		local game = Read(account, "gameAccountInfo")
		if Matches(game) then return game end
	end
end
