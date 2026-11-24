local _, BFL = ...
local Clock = BFL:RegisterModule("FriendLocalTime", {})

function Clock:IsEnabled()
	local db = BFL:GetModule("DB")
	return db ~= nil and db:Get("showFriendLocalTime", false) == true
end

function Clock:SetEnabled(enabled)
	local db = BFL:GetModule("DB")
	db:Set("showFriendLocalTime", enabled)
	if not enabled then
		if BFL.HideFriendClockTooltip then BFL:HideFriendClockTooltip() end
		local dialogs = BFL:GetModule("Dialogs")
		if dialogs then dialogs:HideFriendLocalTime() end
	end
end

function Clock:GetTimestamp()
	return GetServerTime and GetServerTime() or time()
end

function Clock:GetLocalOffset(timestamp)
	local utc = date("!*t", timestamp)
	local own = date("*t", timestamp)
	-- Compare the calendar dates so offsets across midnight keep their sign.
	local utcDay = utc.year * 10000 + utc.month * 100 + utc.day
	local ownDay = own.year * 10000 + own.month * 100 + own.day
	local days = ownDay < utcDay and -1 or (ownDay > utcDay and 1 or 0)
	return days * 1440 + (own.hour - utc.hour) * 60 + own.min - utc.min
end

function Clock:GetOffsetFromDifference(text, localOffset)
	text = text:match("^%s*(.-)%s*$")
	if text == "" then return nil, true end
	local sign, hours, minutes = text:match("^([+-])(%d%d?):(%d%d)$")
	if not hours then return nil, false end
	hours, minutes = tonumber(hours), tonumber(minutes)
	if minutes >= 60 then return nil, false end
	local offset = localOffset + (hours * 60 + minutes) * (sign == "-" and -1 or 1)
	if offset < -720 or offset > 840 then return nil, false end
	return offset, true
end

function Clock:FormatDifference(offset)
	local magnitude = math.abs(offset)
	return string.format("%s%02d:%02d", offset < 0 and "-" or "+", math.floor(magnitude / 60), magnitude % 60)
end

function Clock:FormatTime(timestamp, offset)
	local minutes = (math.floor(timestamp / 60) + offset) % 1440
	return string.format("%02d:%02d", math.floor(minutes / 60), minutes % 60)
end

function Clock:GetKey(uid)
	if BFL:IsSecret(uid) or type(uid) ~= "string" then return end
	local identity = BFL:GetModule("ContactIdentity")
	local battleTag = uid:match("^bnet_([^#%s]+#%d+)$")
	if battleTag then return identity:NormalizeLookupKey(identity:GetContactKeyFromBattleTag(battleTag)) end
	local name = uid:match("^wow_(.+)$")
	if name then return identity:NormalizeLookupKey(identity:GetContactKeyFromPlayerName(name)) end
	if BFL.IsForever and uid:match("^bnet_%d+$") then
		local db = BFL:GetModule("DB")
		return db and db:GetNicknameKey(uid)
	end
end

function Clock:GetFriendKey(friend)
	local friends = BFL:GetModule("FriendsList")
	if not friends or not friends:IsReadableInviteRecord(friend) then return end
	local uid = friends:GetReadableInviteField(friend, "uid")
	if uid then return self:GetKey(uid) end
	local kind = friends:GetReadableInviteField(friend, "type")
	if kind == "bnet" then
		local tag = friends:GetReadableInviteField(friend, "battleTag")
		if type(tag) == "string" then return self:GetKey("bnet_" .. tag) end
		local accountID = friends:GetReadableInviteField(friend, "bnetAccountID")
		if type(accountID) == "number" then return self:GetKey("bnet_" .. accountID) end
	elseif kind == "wow" then
		local name = friends:GetReadableInviteField(friend, "name")
		if type(name) == "string" then return self:GetKey("wow_" .. name) end
	end
end

function Clock:GetOffset(key)
	local db = BFL:GetModule("DB")
	local offsets = db and db:Get("friendTimeOffsets")
	local offset = type(offsets) == "table" and offsets[key]
	if type(offset) == "number" and offset >= -720 and offset <= 840 and offset % 1 == 0 then
		return offset
	end
end

function Clock:SetOffset(key, offset)
	local db = BFL:GetModule("DB")
	local offsets = db:Get("friendTimeOffsets", {})
	offsets[key] = offset
	db:Set("friendTimeOffsets", offsets)
end

function Clock:GetTooltipText(key)
	if not self:IsEnabled() then return end
	if BFL.StreamerMode and BFL.StreamerMode:IsActive() then return end
	local offset = self:GetOffset(key)
	if not offset then return end
	return string.format(BFL.L.FRIEND_LOCAL_TIME_TOOLTIP, self:FormatTime(self:GetTimestamp(), offset))
end
