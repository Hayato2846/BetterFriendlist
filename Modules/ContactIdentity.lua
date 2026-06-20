-- Modules/ContactIdentity.lua
-- Shared contact key helpers for BNet and character identities.

local ADDON_NAME, BFL = ...

local ContactIdentity = BFL:RegisterModule("ContactIdentity", {})

local PLAYER_PREFIX = "player:"
local BNET_PREFIX = "bnet:"

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

function ContactIdentity:CleanString(value)
	if IsSecret(value) or type(value) ~= "string" then
		return nil
	end
	value = value:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
	return Trim(value)
end

function ContactIdentity:FirstCleanString(...)
	for i = 1, select("#", ...) do
		local cleanValue = self:CleanString(select(i, ...))
		if cleanValue then
			return cleanValue
		end
	end
	return nil
end

function ContactIdentity:GetContactKeyFromBattleTag(battleTag)
	if IsSecret(battleTag) then
		return nil
	end
	if type(battleTag) == "number" then
		return BNET_PREFIX .. tostring(battleTag)
	end
	battleTag = self:CleanString(battleTag)
	if not battleTag then
		return nil
	end
	return BNET_PREFIX .. battleTag
end

function ContactIdentity:NormalizePlayerName(name, realm)
	name = self:CleanString(name)
	realm = self:CleanString(realm)
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

function ContactIdentity:GetContactKeyFromPlayerName(name, realm)
	local normalizedName = self:NormalizePlayerName(name, realm)
	if not normalizedName then
		return nil
	end
	return PLAYER_PREFIX .. normalizedName
end

function ContactIdentity:SplitContactKey(contactKey)
	contactKey = self:CleanString(contactKey)
	if not contactKey then
		return nil, nil
	end
	if contactKey:sub(1, #BNET_PREFIX) == BNET_PREFIX then
		return "bnet", contactKey:sub(#BNET_PREFIX + 1)
	end
	if contactKey:sub(1, #PLAYER_PREFIX) == PLAYER_PREFIX then
		return "player", contactKey:sub(#PLAYER_PREFIX + 1)
	end
	return nil, nil
end

function ContactIdentity:NormalizeLookupKey(contactKey)
	contactKey = self:CleanString(contactKey)
	return contactKey and contactKey:lower() or nil
end

function ContactIdentity:ResolveContactKeyFromFriend(friend)
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
	local name = self:FirstCleanString(friend.name, friend.characterName, gameAccountInfo and gameAccountInfo.characterName)
	local realm = self:FirstCleanString(friend.realmName, gameAccountInfo and gameAccountInfo.realmName)

	return self:GetContactKeyFromPlayerName(name, realm)
end

function ContactIdentity:ResolveContactKeyFromContext(contextData)
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
		self:FirstCleanString(contextData.name),
		self:FirstCleanString(contextData.server, contextData.realmName)
	)
end

function ContactIdentity:ResolveContactKeyFromIgnore(squelchType, index)
	if not index then
		return nil
	end

	if SQUELCH_TYPE_IGNORE and squelchType == SQUELCH_TYPE_IGNORE and C_FriendList and C_FriendList.GetIgnoreName then
		local name = C_FriendList.GetIgnoreName(index)
		return self:GetContactKeyFromPlayerName(name), self:CleanString(name)
	end

	if SQUELCH_TYPE_BLOCK_INVITE and squelchType == SQUELCH_TYPE_BLOCK_INVITE and BNGetBlockedInfo then
		local blockName, blockID = BNGetBlockedInfo(index)
		local key = self:GetContactKeyFromBattleTag(blockName)
		if not key then
			key = self:GetContactKeyFromBattleTag(blockID)
		end
		return key, self:CleanString(blockName)
	end

	return nil
end

return ContactIdentity
