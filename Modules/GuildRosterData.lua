-- Modules/GuildRosterData.lua
-- Shared, read-only guild roster provider for Guild Broker and Guild Tab.

local ADDON_NAME, BFL = ...

local GuildRosterData = BFL:RegisterModule("GuildRosterData", {})

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

local function SafeBoolean(value)
	if IsSecretValue(value) then
		return false
	end
	return value == true
end

function GuildRosterData:HasBaseRosterAPI()
	return IsInGuild ~= nil
		and GetNumGuildMembers ~= nil
		and BFL.GetGuildRosterInfo ~= nil
		and BFL.GuildRoster ~= nil
end

function GuildRosterData:IsInGuild()
	if not IsInGuild then
		return false
	end
	local ok, result = pcall(IsInGuild)
	return ok and result == true
end

function GuildRosterData:GetGuildName()
	if not GetGuildInfo then
		return ""
	end
	local ok, guildName = pcall(GetGuildInfo, "player")
	if ok then
		return SafeText(guildName, "")
	end
	return ""
end

function GuildRosterData:CanViewOfficerNote()
	if not (C_GuildInfo and C_GuildInfo.CanViewOfficerNote) then
		return false
	end
	local ok, result = pcall(C_GuildInfo.CanViewOfficerNote)
	return ok and result == true
end

function GuildRosterData:GetCounts()
	if not self:HasBaseRosterAPI() or not self:IsInGuild() then
		return 0, 0
	end

	local ok, total, online = pcall(GetNumGuildMembers)
	if not ok then
		return 0, 0
	end

	return SafeNumber(online, 0), SafeNumber(total, 0)
end

function GuildRosterData:RequestRosterUpdate()
	if not self:HasBaseRosterAPI() then
		return false
	end
	local ok = pcall(BFL.GuildRoster)
	return ok == true
end

function GuildRosterData:CollectRoster(options)
	options = options or {}

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

	return members, { online = online, total = total }
end

