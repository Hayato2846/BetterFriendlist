-- Guidance after a user saves a nickname; never shown by imports or library sync.
local ADDON_NAME, BFL = ...
local NicknameHints = BFL:RegisterModule("NicknameHints", {})

local function HasToken(format, token)
	return type(format) == "string" and format:lower():find("%" .. token .. "%", 1, true) ~= nil
end

local function Path(...)
	return table.concat({ ... }, " > ")
end

function NicknameHints:GetGuidance(kind, uid, preview)
	local DB = BFL:GetModule("DB")
	local Settings = BFL:GetModule("Settings")
	if not DB or not Settings then
		return
	end
	local L = BFL.L
	local center = Settings:IsSettingsCenterEnabled()
	local lines = {}
	local entries = {}
	local page, control, category
	local function Add(text, targetPage, targetControl, targetCategory, label, path)
		lines[#lines + 1] = path and (text .. "\n" .. path) or text
		entries[#entries + 1] = {
			text = text, label = label, path = path,
			page = targetPage, control = targetControl, category = targetCategory,
		}
		if not page then
			page, control, category = targetPage, targetControl, targetCategory
		end
	end
	local brokerRoot = center and L.SETTINGS_CENTER_CATEGORY_BROKER_SYNC or L.SETTINGS_TAB_DATABROKER
	if kind == "guild" then
		local GuildFrame = BFL:GetModule("GuildFrame")
		if GuildFrame and GuildFrame:IsEnabled() and DB:Get("guildTabUseNicknames", true) == false then
			local path = center and Path(L.SETTINGS_CENTER_CATEGORY_SOCIAL, L.SETTINGS_TAB_GUILD)
				or L.SETTINGS_TAB_GUILD
			Add(string.format(L.NICKNAME_HINT_GUILD, L.SETTINGS_GUILD_USE_NICKNAMES),
				"social.guild", "guildTabUseNicknames", 12, L.SETTINGS_TAB_GUILD, path)
		end
		if DB:Get("guildBrokerEnabled", false) and not DB:Get("guildBrokerShowColNickname", false) then
			local section = center and L.SETTINGS_CENTER_PAGE_BROKER_GUILD or L.GUILD_BROKER_SETTINGS_HEADER
			local path = Path(brokerRoot, section, L.GUILD_BROKER_SETTINGS_COLUMNS)
			Add(string.format(L.NICKNAME_HINT_BROKER, L.GUILD_BROKER_COL_NICKNAME),
				"broker.guild", "guildBroker.columns.order", 5, L.SETTINGS_CENTER_PAGE_BROKER_GUILD, path)
		end
	else
		local nameFormat = DB:GetNameFormatString()
		local infoFormat = DB:GetInfoFormatString()
		local externalFormatter = not preview and _G.FriendListColorsAPI and type(_G.FriendListColorsAPI.Format) == "function"
		local streamerActive = BFL.StreamerMode and BFL.StreamerMode:IsActive()
		local streamerNickname = streamerActive and DB:Get("streamerModeNameFormat", "battletag") == "nickname"
			and type(uid) == "string" and uid:find("bnet_", 1, true) == 1 and HasToken(nameFormat, "name")
		if not preview and ((not externalFormatter and (HasToken(nameFormat, "nickname") or streamerNickname))
			or (not DB:Get("compactMode", false) and HasToken(infoFormat, "nickname"))) then
			return
		end
		local path = center and Path(L.SETTINGS_CENTER_CATEGORY_FRIENDS, L.SETTINGS_CENTER_PAGE_FRIENDS_FORMATTING)
			or L.SETTINGS_TAB_GENERAL
		if externalFormatter then
			Add(L.NICKNAME_HINT_EXTERNAL,
				"friends.formatting", "infoFormatPreset", 1, "FriendListColors")
		else
			Add(string.format(L.NICKNAME_HINT_FRIENDS, L.NAME_PRESET_NICKNAME),
				"friends.formatting", "nameFormatPreset", 1, L.SETTINGS_NAME_FORMAT_HEADER,
				Path(path, L.SETTINGS_NAME_FORMAT_HEADER))
		end
		if preview or not DB:Get("compactMode", false) then
			Add(string.format(L.NICKNAME_HINT_INFO), "friends.formatting", "infoFormatPreset", 1,
				L.SETTINGS_INFO_FORMAT_HEADER, Path(path, L.SETTINGS_INFO_FORMAT_HEADER))
		end
		if preview or (streamerActive and not streamerNickname) then
			local streamerPath = center and Path(L.SETTINGS_CENTER_CATEGORY_PRIVACY, L.STREAMER_MODE_TITLE)
				or L.STREAMER_MODE_TITLE
			Add(string.format(L.NICKNAME_HINT_STREAMER, L.SETTINGS_STREAMER_NAME_FORMAT_NICKNAME),
				"privacy.streamer", "streamerModeNameFormat", 7, L.STREAMER_MODE_TITLE,
				Path(streamerPath, L.SETTINGS_STREAMER_NAME_FORMAT))
		end
		if preview or (DB:Get("brokerEnabled", false) and not DB:Get("brokerShowColNickname", false)) then
			local brokerPath = center and Path(brokerRoot, L.SETTINGS_CENTER_PAGE_BROKER_FRIENDS, L.BROKER_SETTINGS_HEADER_COLUMNS)
				or Path(brokerRoot, L.BROKER_SETTINGS_HEADER_COLUMNS)
			Add(string.format(L.NICKNAME_HINT_BROKER, L.BROKER_COLUMN_NICKNAME),
				"broker.friends", "broker.columns.order", 5, L.SETTINGS_CENTER_PAGE_BROKER_FRIENDS, brokerPath)
		end
	end
	if #lines > 0 then
		return table.concat(lines, "\n\n"), page, control, category, entries
	end
end

local function ShowGuidance(self, kind, uid, preview)
	local hints = BFL:GetModule("FeatureHints")
	if not hints then return false end
	local _, _, _, _, entries = self:GetGuidance(kind, uid, preview)
	return hints:Show({
		id = "nickname." .. kind,
		title = BFL.L.NICKNAME_HINT_TITLE,
		icon = "Interface\\AddOns\\BetterFriendlist\\Icons\\check-circle.blp",
		entries = entries,
		oncePerSession = not preview,
		replace = preview,
	})
end

function NicknameHints:OnNicknameSaved(nickname, previous, kind, uid)
	if type(nickname) ~= "string" or nickname:match("^%s*$") or nickname == previous then return end
	return ShowGuidance(self, kind or "friends", uid, false)
end

-- Repeatable visual QA without changing nicknames, display settings or hint history.
function NicknameHints:ShowPreview()
	local friendsFrame = _G.BetterFriendsFrame
	if friendsFrame and not friendsFrame:IsShown() and _G.ToggleBetterFriendsFrame then
		_G.ToggleBetterFriendsFrame()
	end
	return ShowGuidance(self, "friends", nil, true)
end
