local ADDON_NAME, BFL = ...
local Compat = BFL:RegisterModule("Compat_TotalRP3", {})

-- Total RP 3 compatibility for BFL-owned context menus.
-- This mirrors TRP3's public profile action without invoking Blizzard menu callbacks.

local CharacterProfileMenus = {
	CHAT_ROSTER = true,
	COMMUNITIES_GUILD_MEMBER = true,
	COMMUNITIES_WOW_MEMBER = true,
	FRIEND = true,
	FRIEND_OFFLINE = true,
	PARTY = true,
	PLAYER = true,
	RAID = true,
	RAID_PLAYER = true,
}

local BattleNetProfileMenus = {
	BN_FRIEND = true,
	COMMUNITIES_MEMBER = true,
}

local function IsSecret(value)
	return BFL.IsSecret and BFL:IsSecret(value)
end

local function SafeValue(tableValue, key)
	if not tableValue then
		return nil
	end

	local ok, value = pcall(function()
		return tableValue[key]
	end)
	if not ok or IsSecret(value) then
		return nil
	end
	return value
end

local function IsTotalRP3Ready()
	local api = _G.TRP3_API
	return api
		and api.configuration
		and type(api.configuration.getValue) == "function"
		and api.slash
		and type(api.slash.openProfile) == "function"
		and api.loc
end

local function GetTRP3Config(key, defaultValue)
	local api = _G.TRP3_API
	local configuration = api and api.configuration
	if not configuration or type(configuration.getValue) ~= "function" then
		return defaultValue
	end

	local ok, value = pcall(configuration.getValue, key)
	if not ok or value == nil then
		return defaultValue
	end
	return value
end

local function GetTRP3Locale(key)
	local api = _G.TRP3_API
	local loc = api and api.loc
	local value = loc and loc[key]
	if type(value) == "string" and value ~= "" then
		return value
	end
	return nil
end

local function IsForbidden(frame)
	if frame and type(frame.IsForbidden) == "function" then
		local ok, forbidden = pcall(frame.IsForbidden, frame)
		return ok and forbidden
	end
	return false
end

local function IsProtected(frame)
	if frame and type(frame.IsProtected) == "function" then
		local ok, protected = pcall(frame.IsProtected, frame)
		return ok and protected
	end
	return false
end

local function GetCurrentRealmName()
	if GetNormalizedRealmName then
		local ok, realmName = pcall(GetNormalizedRealmName)
		if ok and type(realmName) == "string" and realmName ~= "" then
			return realmName
		end
	end
	return nil
end

local function ContainsUnknownObject(value)
	local unknownObject = _G.UNKNOWNOBJECT
	return type(value) == "string"
		and type(unknownObject) == "string"
		and unknownObject ~= ""
		and string.find(value, unknownObject, 1, true) ~= nil
end

local function StartsWithUnknownObject(value)
	local unknownObject = _G.UNKNOWNOBJECT
	return type(value) == "string"
		and type(unknownObject) == "string"
		and unknownObject ~= ""
		and string.find(value, unknownObject, 1, true) == 1
end

local function UnitTokenExists(unitToken)
	if type(unitToken) ~= "string" or unitToken == "" or not UnitExists then
		return false
	end

	local ok, exists = pcall(UnitExists, unitToken)
	return ok and exists
end

local function GetBNetAccountID(contextData)
	local accountID = SafeValue(contextData, "bnetIDAccount")
	if type(accountID) ~= "number" then
		accountID = tonumber(accountID)
	end
	return accountID
end

local function GetBNetAccountInfo(contextData)
	local accountInfo = SafeValue(contextData, "accountInfo")
	if accountInfo then
		return accountInfo
	end

	local accountID = GetBNetAccountID(contextData)
	if not accountID or not (C_BattleNet and C_BattleNet.GetAccountInfoByID) then
		return nil
	end

	local ok, resolvedAccountInfo = pcall(C_BattleNet.GetAccountInfoByID, accountID)
	if ok then
		return resolvedAccountInfo
	end
	return nil
end

local function GetBattleNetProfileTarget(contextData)
	local accountInfo = GetBNetAccountInfo(contextData)
	local gameAccountInfo = SafeValue(accountInfo, "gameAccountInfo")
	if not gameAccountInfo then
		return nil
	end

	if SafeValue(gameAccountInfo, "clientProgram") ~= _G.BNET_CLIENT_WOW then
		return nil
	end
	if SafeValue(gameAccountInfo, "wowProjectID") ~= _G.WOW_PROJECT_ID then
		return nil
	end
	if SafeValue(gameAccountInfo, "isInCurrentRegion") ~= true then
		return nil
	end

	local unknownObject = _G.UNKNOWNOBJECT or _G.UNKNOWN or "Unknown"
	local characterName = SafeValue(gameAccountInfo, "characterName")
	local realmName = SafeValue(gameAccountInfo, "realmName")

	if type(characterName) ~= "string" or characterName == "" then
		characterName = unknownObject
	end
	if type(realmName) ~= "string" or realmName == "" then
		realmName = GetCurrentRealmName()
	end
	if not realmName then
		return nil
	end

	local characterID = characterName .. "-" .. realmName
	if Ambiguate then
		local ok, ambiguatedName = pcall(Ambiguate, characterID, "none")
		if ok and type(ambiguatedName) == "string" and ambiguatedName ~= "" then
			characterID = ambiguatedName
		end
	end

	if StartsWithUnknownObject(characterID) then
		return nil
	end
	return characterID
end

local function GetCharacterProfileTarget(contextData)
	local unitToken = SafeValue(contextData, "unit")
	if UnitTokenExists(unitToken) then
		return unitToken
	end

	local name = SafeValue(contextData, "name")
	if type(name) ~= "string" or name == "" then
		return nil
	end

	local fullName = name
	if not string.find(fullName, "-", 1, true) then
		local server = SafeValue(contextData, "server")
		if type(server) ~= "string" or server == "" then
			server = GetCurrentRealmName()
		end
		if type(server) == "string" and server ~= "" then
			fullName = fullName .. "-" .. server
		end
	end

	if ContainsUnknownObject(fullName) then
		return nil
	end
	return fullName
end

function Compat:ShouldCustomizeMenus(owner)
	if not IsTotalRP3Ready() then
		return false
	end
	if IsForbidden(owner) then
		return false
	end
	if GetTRP3Config("UnitPopups_DisableOnUnitFrames", false) and IsProtected(owner) then
		return false
	end
	if GetTRP3Config("UnitPopups_DisableInCombat", false) and InCombatLockdown and InCombatLockdown() then
		return false
	end

	if GetTRP3Config("UnitPopups_DisableInInstances", false) then
		local utils = _G.TRP3_API and _G.TRP3_API.utils
		local checker = utils and utils.IsInCombatInstance
		if type(checker) == "function" then
			local ok, inCombatInstance = pcall(checker)
			if ok and inCombatInstance then
				return false
			end
		end
	end

	if GetTRP3Config("UnitPopups_DisableOutOfCharacter", false) then
		local totalRP3 = _G.AddOn_TotalRP3
		local getCurrentUser = totalRP3 and totalRP3.Player and totalRP3.Player.GetCurrentUser
		if type(getCurrentUser) ~= "function" then
			return false
		end

		local ok, player = pcall(getCurrentUser)
		if not ok or not player or type(player.IsInCharacter) ~= "function" then
			return false
		end

		local inCharacterOk, inCharacter = pcall(player.IsInCharacter, player)
		if not inCharacterOk or not inCharacter then
			return false
		end
	end

	return true
end

function Compat:GetProfileTarget(contextData, menuType)
	if BattleNetProfileMenus[menuType] then
		return GetBattleNetProfileTarget(contextData)
	end
	if CharacterProfileMenus[menuType] then
		return GetCharacterProfileTarget(contextData)
	end
	return nil
end

function Compat:AddOpenProfileButton(owner, rootDescription, contextData, menuType)
	if not (rootDescription and rootDescription.CreateButton and contextData and menuType) then
		return false
	end
	if not self:ShouldCustomizeMenus(owner) then
		return false
	end
	if not GetTRP3Config("UnitPopups_ShowOpenProfile", true) then
		return false
	end

	local label = GetTRP3Locale("UNIT_POPUPS_OPEN_PROFILE")
	if not label then
		return false
	end

	local profileTarget = self:GetProfileTarget(contextData, menuType)
	if not profileTarget then
		return false
	end

	local header = GetTRP3Locale("UNIT_POPUPS_ROLEPLAY_OPTIONS_HEADER")
	if header and rootDescription.CreateDivider and rootDescription.CreateTitle then
		rootDescription:CreateDivider()
		rootDescription:CreateTitle(header)
	end

	rootDescription:CreateButton(label, function()
		if IsTotalRP3Ready() then
			pcall(_G.TRP3_API.slash.openProfile, profileTarget)
		end
	end)
	return true
end
