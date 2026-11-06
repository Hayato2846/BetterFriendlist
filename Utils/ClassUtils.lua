-- Utils/ClassUtils.lua
-- Class identity is independent of which classes the current client can play.
local ADDON_NAME, BFL = ...
local ClassUtils = {}
BFL.ClassUtils = ClassUtils

local FALLBACK_COLOR = { r = 1, g = 1, b = 1 }
local CLASS_ID_TO_FILE = {
	[1] = "WARRIOR", [2] = "PALADIN", [3] = "HUNTER", [4] = "ROGUE", [5] = "PRIEST",
	[6] = "DEATHKNIGHT", [7] = "SHAMAN", [8] = "MAGE", [9] = "WARLOCK", [10] = "MONK",
	[11] = "DRUID", [12] = "DEMONHUNTER", [13] = "EVOKER",
}
local CLASS_FILE_TO_ID = {}
for classID, classFile in pairs(CLASS_ID_TO_FILE) do CLASS_FILE_TO_ID[classFile] = classID end
local MAX_CLASS_ID = 13

local function IsSecret(value)
	return BFL.IsSecret and BFL:IsSecret(value)
end

local function IsReadableTable(value)
	if IsSecret(value) or type(value) ~= "table" then return false end
	if type(issecrettable) == "function" then
		local ok, restricted = pcall(issecrettable, value)
		if not ok or IsSecret(restricted) or restricted then return false end
	end
	return true
end

local function ReadField(container, key)
	if not IsReadableTable(container) then return nil end
	local ok, value = pcall(function() return container[key] end)
	if ok and not IsSecret(value) then return value end
	return nil
end

local function GetAPI(namespace, key)
	local value = ReadField(namespace, key)
	return type(value) == "function" and value or nil
end

local function IsPositiveInteger(value)
	return not IsSecret(value) and type(value) == "number"
		and value > 0 and value < math.huge and value % 1 == 0
end

local function ToClassID(value)
	if IsSecret(value) or (type(value) ~= "number" and type(value) ~= "string") then return nil end
	local classID = tonumber(value)
	return IsPositiveInteger(classID) and classID or nil
end

local function CleanString(value)
	if IsSecret(value) or type(value) ~= "string" then return nil end
	value = value:match("^%s*(.-)%s*$")
	return value ~= "" and value or nil
end

local function NormalizeClassToken(value)
	value = CleanString(value)
	if not value then return nil end
	return value:upper():gsub("%s+", ""):gsub("[%-_']", "")
end

local function IsReadableColor(color)
	if not IsReadableTable(color) then return false end
	for _, key in ipairs({ "r", "g", "b" }) do
		local value = ReadField(color, key)
		if type(value) ~= "number" or value ~= value or value < 0 or value > 1 then return false end
	end
	-- Callers also consume the optional hex string directly.
	local ok, hex = pcall(function() return color.colorStr end)
	return ok and not IsSecret(hex) and (hex == nil or (type(hex) == "string" and hex:match("^%x%x%x%x%x%x%x%x$")))
end

-- Preserve readable native colors, including native custom class tokens. The
-- addon-owned table only supplies missing cross-client colors; never fill RAID.
function ClassUtils:GetClassColorByFile(classFile)
	classFile = NormalizeClassToken(classFile)
	if not classFile then return nil end
	local color = ReadField(RAID_CLASS_COLORS, classFile)
	if IsReadableColor(color) then return color end
	local api = GetAPI(C_ClassColor, "GetClassColor")
	if api then
		local ok, nativeColor = pcall(api, classFile)
		if ok and IsReadableColor(nativeColor) then return nativeColor end
	end
	color = ReadField(BFL.ClassColors, classFile)
	return IsReadableColor(color) and color or nil
end

local function KnownClassFile(value)
	local token = NormalizeClassToken(value)
	if token and (CLASS_FILE_TO_ID[token] or ClassUtils:GetClassColorByFile(token)) then return token end
	return nil
end

local function GetProbeMaxID()
	local maxID = MAX_CLASS_ID
	if type(GetNumClasses) == "function" then
		local ok, count = pcall(GetNumClasses)
		if ok and IsPositiveInteger(count) then maxID = math.max(maxID, count) end
	end
	return maxID
end

function ClassUtils:GetAvailableClassIDs()
	local result, seen = {}, {}
	local function AddID(value)
		if IsPositiveInteger(value) and not seen[value] then
			seen[value] = true
			result[#result + 1] = value
		end
	end
	local api = GetAPI(C_SpecializationInfo, "GetAllClassIDs")
	if api then
		local ok, ids = pcall(api)
		if ok and IsReadableTable(ids) then
			for _, classID in ipairs(ids) do AddID(classID) end
			if #result > 0 then table.sort(result); return result end
		end
	end
	-- Probe the current client, including Classic ID gaps. Static identity/color
	-- fallbacks must never add unplayable classes to Who filter options.
	if type(GetClassInfo) ~= "function" then return nil end
	for candidateID = 1, GetProbeMaxID() do
		local ok, name, _, classID = pcall(GetClassInfo, candidateID)
		if ok and CleanString(name) and not IsSecret(classID) then AddID(classID or candidateID) end
	end
	table.sort(result)
	return result
end

function ClassUtils:GetClassFileFromClassID(value)
	local classID = ToClassID(value)
	if not classID then return nil end
	if CLASS_ID_TO_FILE[classID] then return CLASS_ID_TO_FILE[classID] end
	-- Retain native custom classes without treating an unknown numeric ID as a
	-- known class merely because a fallback color exists.
	local api = GetAPI(C_CreatureInfo, "GetClassInfo")
	if api then
		local ok, info = pcall(api, classID)
		if ok then
			local token = KnownClassFile(ReadField(info, "classFile"))
			if token then return token end
		end
	end
	if type(GetClassInfo) == "function" then
		local ok, _, classFile = pcall(GetClassInfo, classID)
		if ok then return KnownClassFile(classFile) end
	end
	return nil
end

local function MatchLocalizedClassTable(className, localizedTable)
	if not IsReadableTable(localizedTable) then return nil end
	for classFile, localizedName in pairs(localizedTable) do
		if not IsSecret(localizedName) and localizedName == className then
			local token = KnownClassFile(classFile)
			if token then return token end
		end
	end
	return nil
end

local function ResolveLocalizedClassName(className)
	local token = MatchLocalizedClassTable(className, LOCALIZED_CLASS_NAMES_MALE)
		or MatchLocalizedClassTable(className, LOCALIZED_CLASS_NAMES_FEMALE)
	if token then return token end
	if type(GetClassInfo) == "function" then
		for classID = 1, GetProbeMaxID() do
			local ok, localizedName, classFile = pcall(GetClassInfo, classID)
			if ok and not IsSecret(localizedName) and localizedName == className then
				token = KnownClassFile(classFile) or CLASS_ID_TO_FILE[classID]
				if token then return token end
			end
		end
	end
	local api = GetAPI(C_CreatureInfo, "GetClassInfo")
	if api then
		for classID = 1, MAX_CLASS_ID do
			local ok, info = pcall(api, classID)
			if ok and ReadField(info, "className") == className then
				token = KnownClassFile(ReadField(info, "classFile")) or CLASS_ID_TO_FILE[classID]
				if token then return token end
			end
		end
	end
	return nil
end

function ClassUtils:GetClassFileFromClassName(value)
	local className = CleanString(value)
	if not className then return nil end
	local token = KnownClassFile(className) or ResolveLocalizedClassName(className)
	if token then return token end
	local variants = {}
	if #className > 2 and className:sub(-2) == "in" then variants[#variants + 1] = className:sub(1, -3) end
	if #className > 1 and className:sub(-1) == "e" then variants[#variants + 1] = className:sub(1, -2) end
	if #className > 1 and className:sub(-1) == "a" then variants[#variants + 1] = className:sub(1, -2) .. "o" end
	for _, variant in ipairs(variants) do
		token = ResolveLocalizedClassName(variant)
		if token then return token end
	end
	return nil
end

-- Direct token fields, then classID, then localized name. Secret optional
-- enrichment is skipped so another readable source can still supply identity.
function ClassUtils:GetClassFileForFriend(friend)
	if not IsReadableTable(friend) then return nil end
	for _, key in ipairs({ "classFile", "classFileName", "classFilename" }) do
		local token = KnownClassFile(ReadField(friend, key))
		if token then return token end
	end
	local token = self:GetClassFileFromClassID(ReadField(friend, "classID"))
	return token or self:GetClassFileFromClassName(ReadField(friend, "className"))
end

function ClassUtils:GetClassColorForFriend(friend)
	return self:GetClassColorByFile(self:GetClassFileForFriend(friend)) or FALLBACK_COLOR
end

function ClassUtils:GetClassColorHex(friend)
	local color = self:GetClassColorForFriend(friend)
	local hex = ReadField(color, "colorStr")
	if type(hex) == "string" and hex:match("^%x%x%x%x%x%x%x%x$") then return hex end
	return string.format("ff%02x%02x%02x", math.floor(color.r * 255 + 0.5),
		math.floor(color.g * 255 + 0.5), math.floor(color.b * 255 + 0.5))
end
