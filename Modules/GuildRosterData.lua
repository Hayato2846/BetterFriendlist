-- Modules/GuildRosterData.lua
-- Shared guild roster data provider for Guild Broker and Guild Tab.

local ADDON_NAME, BFL = ...

local GuildRosterData = BFL:RegisterModule("GuildRosterData", {})

local GUILD_NEWS_FILTER_IDS = { 1, 2, 3, 4, 5, 6, 9 }

local function IsSecretValue(value)
	return BFL.HasSecretValues and BFL.IsSecret and BFL:IsSecret(value)
end

local function SafeText(value, fallback)
	if IsSecretValue(value) then
		return fallback or ""
	end
	if value == nil then
		return fallback or ""
	end
	return tostring(value)
end

local function SafeNumber(value, fallback)
	if IsSecretValue(value) then
		return fallback or 0
	end
	if type(value) == "number" then
		return value
	end
	local parsed = tonumber(value)
	if parsed ~= nil then
		return parsed
	end
	return fallback or 0
end

local function SafeOptionalNumber(value)
	if IsSecretValue(value) or value == nil then
		return nil
	end
	return tonumber(value)
end

local function SafeBoolean(value)
	if IsSecretValue(value) then
		return false
	end
	return value == true
end

local function GetCacheTime()
	if GetTime then
		return GetTime()
	end
	return time and time() or 0
end

local function NormalizeMemberName(value)
	local text = SafeText(value, "")
	if text == "" then
		return nil
	end
	return text:gsub("%s+", ""):lower()
end

function GuildRosterData:GetPreviewData()
	local PreviewMode = BFL:GetModule("PreviewMode")
	if not (
		PreviewMode
		and PreviewMode.IsComponentEnabled
		and PreviewMode:IsComponentEnabled("guild")
		and PreviewMode.mockData
		and type(PreviewMode.mockData.guildRosterMembers) == "table"
	) then
		return nil
	end
	return PreviewMode.mockData
end

function GuildRosterData:HasBaseRosterAPI()
	if self:GetPreviewData() then
		return true
	end
	return IsInGuild ~= nil
		and GetNumGuildMembers ~= nil
		and BFL.GetGuildRosterInfo ~= nil
		and BFL.GuildRoster ~= nil
end

function GuildRosterData:HasPreferredPlaySettingsAPI()
	return BFL.IsMainline == true
		and not BFL:IsGameRuleActive("GuildsDisabled")
		and type(C_GuildInfo) == "table"
		and type(C_GuildInfo.GetPreferredPlaySettings) == "function"
		and type(C_GuildInfo.GetPreferredPlaySettingsFeatures) == "function"
end

function GuildRosterData:HasClubMemberInfoAPI()
	return type(C_Club) == "table"
		and type(C_Club.GetGuildClubId) == "function"
		and type(C_Club.GetClubMembers) == "function"
		and type(C_Club.GetMemberInfo) == "function"
end

function GuildRosterData:HasGuildInfoTextAPI()
	return type(C_GuildInfo) == "table" and type(C_GuildInfo.GetInfoText) == "function"
end

function GuildRosterData:HasGuildNewsAPI()
	return type(C_GuildInfo) == "table"
		and type(C_GuildInfo.GetGuildNewsInfo) == "function"
		and type(GetNumGuildNews) == "function"
		and type(QueryGuildNews) == "function"
end

function GuildRosterData:HasGuildNewsFilterAPI()
	return self:HasGuildNewsAPI()
		and type(GetGuildNewsFilters) == "function"
		and type(SetGuildNewsFilter) == "function"
		and type(GuildNewsSort) == "function"
end

function GuildRosterData:IsGuildNewsFilterAvailable(filterID)
	filterID = tonumber(filterID)
	if filterID == 1 and C_AchievementInfo and type(C_AchievementInfo.AreGuildAchievementsEnabled) == "function" then
		local ok, available = pcall(C_AchievementInfo.AreGuildAchievementsEnabled)
		return ok and not IsSecretValue(available) and available == true
	elseif filterID == 2 and type(CanShowAchievementUI) == "function" then
		local ok, available = pcall(CanShowAchievementUI)
		return ok and not IsSecretValue(available) and available == true
	elseif filterID == 3 and C_GuildInfo and type(C_GuildInfo.IsEncounterGuildNewsEnabled) == "function" then
		local ok, available = pcall(C_GuildInfo.IsEncounterGuildNewsEnabled)
		return ok and not IsSecretValue(available) and available == true
	end
	return true
end

function GuildRosterData:GetGuildNewsFilters()
	if not self:HasGuildNewsFilterAPI() then
		return {}
	end
	local results = { pcall(GetGuildNewsFilters) }
	if not results[1] then
		return {}
	end
	local filters = {}
	for _, filterID in ipairs(GUILD_NEWS_FILTER_IDS) do
		local value = results[filterID + 1]
		filters[filterID] = not IsSecretValue(value) and (value == true or value == 1) or false
	end
	return filters
end

function GuildRosterData:SetGuildNewsFilter(filterID, enabled)
	filterID = tonumber(filterID)
	local valid = false
	for _, candidateID in ipairs(GUILD_NEWS_FILTER_IDS) do
		if filterID == candidateID then
			valid = true
			break
		end
	end
	if not valid or not self:HasGuildNewsFilterAPI() or not self:IsGuildNewsFilterAvailable(filterID) then
		return false
	end

	local ok = pcall(SetGuildNewsFilter, filterID, enabled and 1 or 0)
	if not ok then
		return false
	end
	pcall(GuildNewsSort, 0)
	self:InvalidateGuildNews()
	return true
end

function GuildRosterData:HasGuildRecipeAPI()
	return type(C_GuildInfo) == "table" and type(C_GuildInfo.QueryGuildMemberRecipes) == "function"
end

-- Read-only compatibility surface. BFL intentionally does not duplicate
-- Blizzard's mutation UI until there is a concrete friend-list workflow.
function GuildRosterData:GetPreferredPlaySettingsSnapshot()
	if not self:HasPreferredPlaySettingsAPI() then
		return { available = false }
	end
	local okSettings, loaded, localeID, localityID, localeChangedAt, localityChangedAt, cooldownDays =
		pcall(C_GuildInfo.GetPreferredPlaySettings)
	local okFeatures, canChangeLocale, canChangeLocality = pcall(C_GuildInfo.GetPreferredPlaySettingsFeatures)
	if not okSettings or not okFeatures
		or IsSecretValue(loaded)
		or IsSecretValue(localeID)
		or IsSecretValue(localityID)
	then
		return { available = true, readable = false }
	end
	return {
		available = true,
		readable = true,
		loaded = loaded == true,
		preferredLocaleID = SafeNumber(localeID, 0),
		preferredDatacenterLocalityID = SafeNumber(localityID, 0),
		lastPreferredLocaleChangeDate = SafeNumber(localeChangedAt, 0),
		lastPreferredDatacenterLocalityChangeDate = SafeNumber(localityChangedAt, 0),
		changeCooldownDays = SafeNumber(cooldownDays, 0),
		canChangeLocale = SafeBoolean(canChangeLocale),
		canChangeDatacenterLocality = SafeBoolean(canChangeLocality),
	}
end

function GuildRosterData:Initialize()
	if self:HasPreferredPlaySettingsAPI() then
		pcall(function()
			BFL:RegisterEventCallback("GUILD_PREFERRED_PLAY_SETTINGS_UPDATED", function()
				self.preferredPlaySettingsVersion = (self.preferredPlaySettingsVersion or 0) + 1
			end, 20)
		end)
	end

	pcall(function()
		BFL:RegisterEventCallback("GUILD_NEWS_UPDATE", function()
			self:InvalidateGuildNews()
		end, 20)
	end)
end

function GuildRosterData:IsInGuild()
	if self:GetPreviewData() then
		return true
	end
	if not IsInGuild then
		return false
	end
	local ok, result = pcall(IsInGuild)
	return ok and result == true
end

function GuildRosterData:GetGuildName()
	local previewData = self:GetPreviewData()
	if previewData then
		return previewData.guildRosterName or ""
	end
	if not GetGuildInfo then
		return ""
	end
	local ok, guildName = pcall(GetGuildInfo, "player")
	if ok then
		return SafeText(guildName, "")
	end
	return ""
end

function GuildRosterData:GetGuildMOTD()
	local previewData = self:GetPreviewData()
	if previewData then
		return previewData.guildRosterMOTD or ""
	end
	if not BFL.GetGuildMOTD then
		return ""
	end
	local ok, motd = pcall(BFL.GetGuildMOTD)
	if ok then
		return SafeText(motd, "")
	end
	return ""
end

function GuildRosterData:GetGuildInfoText()
	local previewData = self:GetPreviewData()
	if previewData then
		return SafeText(previewData.guildInfoText, "")
	end
	if not self:HasGuildInfoTextAPI() then
		return ""
	end
	local ok, infoText = pcall(C_GuildInfo.GetInfoText)
	if not ok then
		return ""
	end
	return SafeText(infoText, "")
end

function GuildRosterData:CanViewOfficerNote()
	if not (C_GuildInfo and C_GuildInfo.CanViewOfficerNote) then
		return false
	end
	local ok, result = pcall(C_GuildInfo.CanViewOfficerNote)
	return ok and result == true
end

function GuildRosterData:GetCounts()
	local previewData = self:GetPreviewData()
	if previewData then
		local members = previewData.guildRosterMembers
		local online = 0
		for _, member in ipairs(members) do
			if member.online then
				online = online + 1
			end
		end
		return online, #members
	end
	if not self:HasBaseRosterAPI() or not self:IsInGuild() then
		return 0, 0
	end

	local ok, total, online = pcall(GetNumGuildMembers)
	if not ok then
		return 0, 0
	end

	return SafeNumber(online, 0), SafeNumber(total, 0)
end

function GuildRosterData:InvalidateCache()
	self.rosterSnapshotCache = nil
	self.clubMemberSnapshotCache = nil
end

function GuildRosterData:InvalidateGuildNews()
	self.guildNewsCache = nil
end

function GuildRosterData:GetClubMemberSnapshot()
	if not self:HasClubMemberInfoAPI() then
		return nil
	end

	local now = GetCacheTime()
	local cache = self.clubMemberSnapshotCache
	if cache and now - (cache.time or 0) <= 10 then
		return cache
	end

	local okClub, clubId = pcall(C_Club.GetGuildClubId)
	if not okClub or IsSecretValue(clubId) or not clubId then
		return nil
	end
	local okMembers, memberIDs = pcall(C_Club.GetClubMembers, clubId)
	if not okMembers or type(memberIDs) ~= "table" then
		return nil
	end

	cache = {
		time = now,
		clubId = clubId,
		byGUID = {},
		byName = {},
		memberIDByInfo = {},
	}
	for _, memberId in ipairs(memberIDs) do
		local okInfo, info = pcall(C_Club.GetMemberInfo, clubId, memberId)
		if okInfo and type(info) == "table" then
			cache.memberIDByInfo[info] = memberId
			local guid = info.guid
			if not IsSecretValue(guid) and guid ~= nil then
				cache.byGUID[guid] = info
			end
			local normalizedName = NormalizeMemberName(info.name)
			if normalizedName then
				cache.byName[normalizedName] = info
			end
		end
	end
	self.clubMemberSnapshotCache = cache
	return cache
end

function GuildRosterData:EnrichRosterWithClubInfo(members)
	if type(members) ~= "table" or #members == 0 then
		return members
	end
	local snapshot = self:GetClubMemberSnapshot()
	if not snapshot then
		return members
	end

	for _, member in ipairs(members) do
		local info = member.guid and snapshot.byGUID[member.guid]
		if not info then
			info = snapshot.byName[NormalizeMemberName(member.fullName)]
				or snapshot.byName[NormalizeMemberName(member.name)]
		end
		if info then
			member.clubId = snapshot.clubId
			member.memberId = info.memberId or snapshot.memberIDByInfo[info]
			if (not member.guid or member.guid == "") and info.guid and not IsSecretValue(info.guid) then
				member.guid = info.guid
			end
			member.profession1ID = SafeOptionalNumber(info.profession1ID)
			member.profession1Rank = SafeOptionalNumber(info.profession1Rank)
			member.profession1Name = SafeText(info.profession1Name, "")
			member.profession2ID = SafeOptionalNumber(info.profession2ID)
			member.profession2Rank = SafeOptionalNumber(info.profession2Rank)
			member.profession2Name = SafeText(info.profession2Name, "")
		end
	end
	return members
end

function GuildRosterData:GetProfessionCatalog(members)
	local byID = {}
	for _, member in ipairs(members or {}) do
		for slot = 1, 2 do
			local professionID = SafeOptionalNumber(member["profession" .. slot .. "ID"])
			if professionID and professionID > 0 then
				local entry = byID[professionID]
				if not entry then
					entry = {
						id = professionID,
						name = SafeText(member["profession" .. slot .. "Name"], tostring(professionID)),
						count = 0,
					}
					byID[professionID] = entry
				end
				entry.count = entry.count + 1
			end
		end
	end

	local catalog = {}
	for _, entry in pairs(byID) do
		catalog[#catalog + 1] = entry
	end
	table.sort(catalog, function(a, b)
		return (a.name or ""):lower() < (b.name or ""):lower()
	end)
	return catalog
end

function GuildRosterData:RequestGuildNews()
	if not self:HasGuildNewsAPI() or type(QueryGuildNews) ~= "function" then
		return false
	end
	self:InvalidateGuildNews()
	local ok = pcall(QueryGuildNews)
	if ok and type(GuildNewsSort) == "function" then
		pcall(GuildNewsSort, 0)
	end
	return ok
end

function GuildRosterData:CollectGuildNews(limit)
	limit = math.max(1, math.min(tonumber(limit) or 20, 50))
	local previewData = self:GetPreviewData()
	if previewData and type(previewData.guildNews) == "table" then
		local entries = {}
		for index = 1, math.min(limit, #previewData.guildNews) do
			entries[index] = previewData.guildNews[index]
		end
		return entries
	end
	if not self:HasGuildNewsAPI() then
		return {}
	end

	local cache = self.guildNewsCache
	if cache and cache.limit >= limit then
		local entries = {}
		for index = 1, math.min(limit, #cache.entries) do
			entries[index] = cache.entries[index]
		end
		return entries
	end

	local okCount, count = pcall(GetNumGuildNews)
	if not okCount or IsSecretValue(count) then
		return {}
	end
	count = math.max(0, math.min(tonumber(count) or 0, 100))
	local entries = {}
	for index = 1, count do
		local okInfo, info = pcall(C_GuildInfo.GetGuildNewsInfo, index)
		if okInfo and type(info) == "table"
			and not IsSecretValue(info.isHeader)
			and not info.isHeader
		then
			local data = type(info.data) == "table" and info.data or {}
			entries[#entries + 1] = {
				index = index,
				newsType = SafeNumber(info.newsType, 0),
				newsDataID = SafeNumber(info.newsDataID, 0),
				whoText = SafeText(info.whoText, ""),
				whatText = SafeText(info.whatText, ""),
				isSticky = SafeBoolean(info.isSticky),
				data = {
					SafeOptionalNumber(data[1]),
					SafeOptionalNumber(data[2]),
					SafeOptionalNumber(data[3]),
					SafeOptionalNumber(data[4]),
				},
				weekday = SafeNumber(info.weekday, 0),
				day = SafeNumber(info.day, 0),
				month = SafeNumber(info.month, 0),
				year = SafeNumber(info.year, 0),
			}
			if #entries >= limit then
				break
			end
		end
	end
	self.guildNewsCache = { limit = limit, entries = entries }
	return entries
end

function GuildRosterData:RequestRosterUpdate()
	if self:GetPreviewData() then
		self:InvalidateCache()
		return true
	end
	if not self:HasBaseRosterAPI() then
		return false
	end
	self:InvalidateCache()
	local ok = pcall(BFL.GuildRoster)
	return ok == true
end

function GuildRosterData:CollectRoster(options)
	options = options or {}

	local previewData = self:GetPreviewData()
	if previewData then
		local members = previewData.guildRosterMembers
		local online, total = self:GetCounts()
		local maxRows = SafeNumber(options.maxRows, total)
		if maxRows <= 0 or maxRows > total then
			maxRows = total
		end
		if maxRows == total then
			return members, { online = online, total = total }
		end
		local limited = {}
		for index = 1, maxRows do
			limited[index] = members[index]
		end
		return limited, { online = online, total = total }
	end

	if not self:HasBaseRosterAPI() or not self:IsInGuild() then
		return {}, { online = 0, total = 0 }
	end

	local okCounts, total, online = pcall(GetNumGuildMembers)
	if not okCounts then
		return {}, { online = 0, total = 0 }
	end

	total = SafeNumber(total, 0)
	online = SafeNumber(online, 0)

	local maxRows = SafeNumber(options.maxRows, total)
	if maxRows <= 0 or maxRows > total then
		maxRows = total
	end

	local members = {}
	for i = 1, maxRows do
		local okInfo, fullName, rank, rankIndex, level, className, zone, note, officerNote, isOnline, status,
			classFile, achievementPoints, achievementRank, isMobile, isSoREligible, standingID, guid =
			pcall(BFL.GetGuildRosterInfo, i)

		if okInfo then
			local safeFullName = SafeText(fullName, "Unknown")
			local name, realm
			if safeFullName == "Unknown" then
				name, realm = "Unknown", ""
			else
				name, realm = strsplit("-", safeFullName, 2)
			end

			local onlineState = SafeBoolean(isOnline)
			local statusValue = SafeNumber(status, 0)
			local lastYears, lastMonths, lastDays, lastHours = 0, 0, 0, 0

			if not onlineState and BFL.GetGuildRosterLastOnline then
				local okLastOnline, years, months, days, hours = pcall(BFL.GetGuildRosterLastOnline, i)
				if okLastOnline then
					lastYears = SafeNumber(years, 0)
					lastMonths = SafeNumber(months, 0)
					lastDays = SafeNumber(days, 0)
					lastHours = SafeNumber(hours, 0)
				end
			end

			members[#members + 1] = {
				index = i,
				guildIndex = i,
				fullName = safeFullName,
				name = SafeText(name, safeFullName),
				realm = SafeText(realm, ""),
				rank = SafeText(rank, ""),
				rankIndex = SafeNumber(rankIndex, 0),
				level = SafeNumber(level, 0),
				classFile = SafeText(classFile, ""),
				className = SafeText(className, ""),
				zone = SafeText(zone, ""),
				note = SafeText(note, ""),
				officerNote = SafeText(officerNote, ""),
				online = onlineState,
				isAFK = statusValue == 1,
				isDND = statusValue == 2,
				isMobile = SafeBoolean(isMobile),
				achievementPoints = SafeNumber(achievementPoints, 0),
				achievementRank = SafeNumber(achievementRank, 0),
				itemLevel = nil,
				guid = SafeText(guid, ""),
				lastOnlineYears = lastYears,
				lastOnlineMonths = lastMonths,
				lastOnlineDays = lastDays,
				lastOnlineHours = lastHours,
			}
		end
	end

	if options.includeClubInfo then
		self:EnrichRosterWithClubInfo(members)
	end

	return members, { online = online, total = total }
end

function GuildRosterData:CollectRosterCached(options)
	options = options or {}
	local maxAge = tonumber(options.maxAge) or 10
	if maxAge <= 0 then
		return self:CollectRoster(options)
	end

	if not self:HasBaseRosterAPI() or not self:IsInGuild() then
		self.rosterSnapshotCache = nil
		return {}, { online = 0, total = 0 }
	end

	local online, total = self:GetCounts()
	local maxRows = SafeNumber(options.maxRows, total)
	if maxRows <= 0 or maxRows > total then
		maxRows = total
	end
	local signature = table.concat({
		self:GetGuildName() or "",
		total or 0,
		online or 0,
		maxRows or 0,
		options.includeClubInfo and "club" or "base",
	}, "|")
	local now = GetCacheTime()
	local cache = self.rosterSnapshotCache
	if
		cache
		and cache.signature == signature
		and now - (cache.time or 0) <= maxAge
	then
		return cache.members, cache.counts
	end

	local collectOptions = {}
	for key, value in pairs(options) do
		if key ~= "maxAge" then
			collectOptions[key] = value
		end
	end
	collectOptions.maxRows = maxRows
	local members, counts = self:CollectRoster(collectOptions)
	self.rosterSnapshotCache = {
		signature = signature,
		time = now,
		members = members,
		counts = counts,
	}
	return members, counts
end

