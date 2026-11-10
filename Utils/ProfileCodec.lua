-- Data-only codec for existing BFL Lua-table profile strings. Never executes input.
local _, BFL = ...
local Codec = {
	MAX_BYTES = 4 * 1024 * 1024,
	MAX_DEPTH = 40,
	MAX_NODES = 200000,
	LOCAL_KEYS = {
		knownCharacters = true,
		appearanceOnboardingVersion = true,
		appearanceOnboardingResume = true,
		settingsRedesignHintSeen = true,
		settingsSearchSelections = true,
		socialKeybindMigrated = true,
		socialKeybindMigrationVersion = true,
		socialKeybindMigratedKeys = true,
		lastInvitedAccounts = true,
		preferredGameAccounts = true,
		noteSyncPendingWrites = true,
	},
	FLAVOR_KEYS = {
		titleFriendNotes = true,
		GlobalFriends = true,
		globalFriendsMigrated = true,
		enableGlobalSync = true,
		enableGlobalSyncDeletion = true,
	},
}
BFL.ProfileCodec = Codec

local function ReadBuildFlag(fn)
	if type(fn) ~= "function" then return false end
	local ok, value = pcall(fn)
	if not ok or (BFL.IsSecret and BFL:IsSecret(value)) or type(value) ~= "boolean" then return nil end
	return value
end

function Codec:GetCurrentFlavor()
	local flavor
	-- IsRetail is a compatibility alias for the whole Mainline family, so
	-- Forever must be identified before considering the Retail fallback.
	if BFL.IsForever then flavor = "forever"
	elseif BFL.IsClassicEra then flavor = "classic-era"
	elseif BFL.IsTBCClassic then flavor = "classic-tbc"
	elseif BFL.IsWrathClassic then flavor = "classic-wrath"
	elseif BFL.IsCataClassic then flavor = "classic-cata"
	elseif BFL.IsMoPClassic then flavor = "classic-mists"
	elseif BFL.IsMainline or BFL.IsRetail then flavor = "retail"
	else return nil end
	local beta, test = ReadBuildFlag(IsBetaBuild), ReadBuildFlag(IsPublicTestClient)
	if beta == nil or test == nil then return nil end
	if beta then return flavor .. ":beta" end
	if test then return flavor .. ":test" end
	return flavor
end

local function IsFinite(value)
	return value == value and value ~= math.huge and value ~= -math.huge
end

function Codec:ValidateData(value)
	local active, nodes = {}, 0
	local function visit(item, depth)
		nodes = nodes + 1
		if nodes > self.MAX_NODES or depth > self.MAX_DEPTH then return false end
		if BFL.IsSecret and BFL:IsSecret(item) then return false end
		local kind = type(item)
		if kind == "number" then return IsFinite(item) end
		if kind == "string" then return #item <= self.MAX_BYTES end
		if kind == "boolean" or kind == "nil" then return true end
		if kind ~= "table" or (issecrettable and issecrettable(item))
			or active[item] or getmetatable(item) ~= nil then return false end
		active[item] = true
		for key, child in pairs(item) do
			local keyType = type(key)
			if (keyType ~= "string" and keyType ~= "number" and keyType ~= "boolean")
				or not visit(key, depth + 1) or not visit(child, depth + 1) then return false end
		end
		active[item] = nil
		return true
	end
	return visit(value, 0)
end

function Codec:Copy(value)
	if type(value) ~= "table" then return value end
	local result = {}
	for key, child in pairs(value) do result[key] = self:Copy(child) end
	return result
end

function Codec:Serialize(value)
	if type(value) ~= "table" or not self:ValidateData(value) then return nil end
	local parts, length = {}, 0
	local function append(part)
		length = length + #part
		if length > self.MAX_BYTES then error("profile size limit", 0) end
		parts[#parts + 1] = part
	end
	local rank = { boolean = 1, number = 2, string = 3 }
	local function emit(item)
		local kind = type(item)
		if kind == "table" then
			append("{")
			local keys = {}
			for key in pairs(item) do keys[#keys + 1] = key end
			table.sort(keys, function(left, right)
				local lt, rt = type(left), type(right)
				if lt ~= rt then return rank[lt] < rank[rt] end
				if lt == "boolean" then return left == false and right == true end
				return left < right
			end)
			for _, key in ipairs(keys) do
				append("["); emit(key); append("]="); emit(item[key]); append(",")
			end
			append("}")
		elseif kind == "string" then append(string.format("%q", item))
		elseif kind == "number" then append(string.format("%.17g", item))
		elseif kind == "boolean" then append(item and "true" or "false")
		else append("nil") end
	end
	local ok = pcall(emit, value)
	return ok and table.concat(parts) or nil
end

function Codec:Deserialize(source)
	if type(source) ~= "string" or #source == 0 or #source > self.MAX_BYTES then return nil end
	local position, size, nodes = 1, #source, 0
	local function fail() error("invalid profile literal", 0) end
	local function skip()
		local _, finish = source:find("^[ \t\r\n\f\v]*", position)
		position = (finish or position - 1) + 1
	end
	local function take(token)
		skip()
		if source:sub(position, position + #token - 1) ~= token then fail() end
		position = position + #token
	end
	local escapes = { a = "\a", b = "\b", f = "\f", n = "\n", r = "\r", t = "\t", v = "\v", ["\\"] = "\\", ['"'] = '"', ["'"] = "'" }
	local function readString()
		local quote = source:sub(position, position)
		position = position + 1
		local parts, start = {}, position
		while position <= size do
			local char = source:sub(position, position)
			if char == quote then
				parts[#parts + 1] = source:sub(start, position - 1)
				position = position + 1
				return table.concat(parts)
			elseif char == "\n" or char == "\r" then fail()
			elseif char == "\\" then
				parts[#parts + 1] = source:sub(start, position - 1)
				position = position + 1
				local escaped = source:sub(position, position)
				if escapes[escaped] then
					parts[#parts + 1] = escapes[escaped]; position = position + 1
				elseif escaped:match("%d") then
					local digits = source:match("^%d%d?%d?", position)
					local byte = tonumber(digits)
					if byte > 255 then fail() end
					parts[#parts + 1] = string.char(byte); position = position + #digits
				elseif escaped == "x" then
					local digits = source:sub(position + 1, position + 2)
					if not digits:match("^%x%x$") then fail() end
					parts[#parts + 1] = string.char(tonumber(digits, 16)); position = position + 3
				elseif escaped == "\n" or escaped == "\r" then
					if escaped == "\r" and source:sub(position + 1, position + 1) == "\n" then position = position + 1 end
					parts[#parts + 1] = "\n"; position = position + 1
				elseif escaped == "z" then position = position + 1; skip()
				else fail() end
				start = position
			else position = position + 1 end
		end
		fail()
	end
	local readValue
	local function readTable(depth)
		take("{")
		local result, seen, nextIndex = {}, {}, 1
		skip()
		while source:sub(position, position) ~= "}" do
			local key, value
			local explicitKey = source:sub(position, position) == "["
			if explicitKey then
				position = position + 1; key = readValue(depth + 1); take("]"); take("=")
				if key == nil or type(key) == "table" then fail() end
				value = readValue(depth + 1)
			else
				local identifier = source:match("^[_%a][_%w]*", position)
				local after = identifier and (position + #identifier)
				local assignment = after and source:match("^[ \t\r\n]*=", after)
				if assignment then
					key = identifier; position = after + #assignment; value = readValue(depth + 1)
				else key = nextIndex; nextIndex = nextIndex + 1; value = readValue(depth + 1) end
			end
			if not explicitKey then nodes = nodes + 1 end
			if nodes > self.MAX_NODES or seen[key] then fail() end
			seen[key] = true; result[key] = value
			skip()
			local separator = source:sub(position, position)
			if separator == "," or separator == ";" then position = position + 1; skip()
			elseif separator ~= "}" then fail() end
		end
		position = position + 1
		return result
	end
	readValue = function(depth)
		nodes = nodes + 1
		if nodes > self.MAX_NODES or depth > self.MAX_DEPTH then fail() end
		skip()
		local char = source:sub(position, position)
		if char == "{" then return readTable(depth) end
		if char == '"' or char == "'" then return readString() end
		for token, value in pairs({ ["true"] = true, ["false"] = false }) do
			if source:sub(position, position + #token - 1) == token then position = position + #token; return value end
		end
		if source:sub(position, position + 2) == "nil" then position = position + 3; return nil end
		local number = source:match("^[-+]?0[xX]%x+", position)
			or source:match("^[-+]?%d+%.?%d*[eE][-+]?%d+", position)
			or source:match("^[-+]?%.%d+[eE][-+]?%d+", position)
			or source:match("^[-+]?%d+%.?%d*", position)
			or source:match("^[-+]?%.%d+", position)
		local value = number and tonumber(number)
		if not value or not IsFinite(value) then fail() end
		position = position + #number
		return value
	end
	local ok, result = pcall(function()
		local value = readValue(0)
		skip()
		if position <= size or type(value) ~= "table" then fail() end
		return value
	end)
	return ok and result or nil
end
