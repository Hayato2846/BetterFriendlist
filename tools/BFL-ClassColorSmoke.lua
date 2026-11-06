-- lua tools/BFL-ClassColorSmoke.lua <repo>
-- Runs production class identity/color logic against client-gap and restricted
-- API fixtures. Does not query or mutate a live WoW client.
local repo = arg[1] or "."
local function read(path)
	local file = assert(io.open(repo .. "/" .. path, "rb"))
	local source = file:read("*a"); file:close(); return source
end
local checks = 0
local function check(value, message) checks = checks + 1; assert(value, message) end
local function equal(actual, expected, message)
	check(actual == expected, message .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end
local tokens = { "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "DEATHKNIGHT", "SHAMAN", "MAGE",
	"WARLOCK", "MONK", "DRUID", "DEMONHUNTER", "EVOKER" }
local absent = { [6] = "DEATHKNIGHT", [10] = "MONK", [12] = "DEMONHUNTER", [13] = "EVOKER" }
local function fixture()
	local function restricted()
		return setmetatable({}, { __index = function() error("restricted indexed") end,
			__pairs = function() error("restricted iterated") end, __len = function() error("restricted measured") end,
			__tostring = function() error("restricted formatted") end })
	end
	local secret, secretTable = restricted(), restricted()
	local BFL = {}
	function BFL:IsSecret(value) return rawequal(value, secret) end
	local calls = { color = 0, class = 0, number = 0 }
	local available = { [1] = true, [2] = true, [3] = true, [4] = true, [5] = true, [7] = true,
		[8] = true, [9] = true, [11] = true }
	local raid = {}
	for id in pairs(available) do raid[tokens[id]] = { r = 0.2, g = 0.3, b = 0.4, colorStr = "ff334d66" } end
	local env = setmetatable({ RAID_CLASS_COLORS = raid, C_ClassColor = {}, C_CreatureInfo = {},
		C_SpecializationInfo = {}, LOCALIZED_CLASS_NAMES_MALE = {}, LOCALIZED_CLASS_NAMES_FEMALE = {},
		issecrettable = function(value) return rawequal(value, secretTable) end,
		tonumber = function(value)
			check(not rawequal(value, secret), "Secret ID cannot reach tonumber")
			calls.number = calls.number + 1; return tonumber(value)
		end,
	}, { __index = _G })
	env.C_ClassColor.GetClassColor = function() calls.color = calls.color + 1; return nil end
	env.GetNumClasses = function() return 9 end
	env.GetClassInfo = function(id)
		calls.class = calls.class + 1
		if available[id] then return "Localized" .. id, tokens[id], id end
	end
	assert(load(read("Data/ClassColors.lua"), "@Data/ClassColors.lua", "t", env))("BetterFriendlist", BFL)
	assert(load(read("Utils/ClassUtils.lua"), "@Utils/ClassUtils.lua", "t", env))("BetterFriendlist", BFL)
	return BFL.ClassUtils, BFL, env, calls, secret, secretTable, available
end

local utils, BFL, env, calls, secret, secretTable = fixture()
-- Real payload shape reported on Forever: Retail ID only; every class token
-- and localized name is absent, and all local native sources omit Monk.
local retailFriend = { type = "bnet", wowProjectID = 1, classID = 10 }
equal(utils:GetClassFileForFriend(retailFriend), "MONK", "Retail ID-only friend resolves independently of native classes")
equal(utils:GetClassColorForFriend(retailFriend), BFL.ClassColors.MONK, "ID-only friend receives addon-owned missing-class color")
equal(utils:GetClassColorHex(retailFriend), BFL.ClassColors.MONK.colorStr, "Missing-class hex agrees with its fallback palette")
equal(env.RAID_CLASS_COLORS.MONK, nil, "Missing native class color stays absent from Blizzard's table")
for id, token in ipairs(tokens) do
	equal(utils:GetClassFileFromClassID(id), token, "Every canonical ID remains a known identity")
	equal(utils:GetClassFileFromClassName(token), token, "Every canonical token remains known without native color")
end
for id, token in pairs(absent) do
	local friend = { classID = id }
	equal(utils:GetClassColorByFile(token), BFL.ClassColors[token], "Each omitted class has a local fallback")
	equal(utils:GetClassColorForFriend(friend), BFL.ClassColors[token], "Each omitted ID uses its matching fallback")
	equal(env.RAID_CLASS_COLORS[token], nil, "Fallback never modifies native class availability")
	local native = { r = 0.1, g = 0.2, b = 0.3, colorStr = "ff19334c" }
	env.RAID_CLASS_COLORS[token] = native
	equal(utils:GetClassColorByFile(token), native, "Readable native color takes precedence by object identity")
	env.RAID_CLASS_COLORS[token] = nil
	env.C_ClassColor.GetClassColor = function(classFile) if classFile == token then return native end end
	equal(utils:GetClassColorByFile(token), native, "Optional native color getter fills a missing global entry")
	env.C_ClassColor.GetClassColor = function() error("native getter unavailable") end
	equal(utils:GetClassColorByFile(token), BFL.ClassColors[token], "Native getter error retains usable fallback")
end

-- Invalid or restricted input stays neutral and cannot become a table key or
-- pass through numeric conversion. Readable optional enrichment still works.
for _, value in ipairs({ -1, 0, 1.5, 999, "unknown", "10.5", math.huge, -math.huge, false, {} }) do
	equal(utils:GetClassFileFromClassID(value), nil, "Invalid/unknown ID is neutral")
end
equal(utils:GetClassFileFromClassID(0 / 0), nil, "NaN ID is neutral")
equal(utils:GetClassFileFromClassID("10"), "MONK", "Readable legacy numeric string is supported")
local beforeNumber = calls.number
equal(utils:GetClassFileFromClassID(secret), nil, "Secret class ID is rejected")
equal(calls.number, beforeNumber, "Secret class ID is rejected before tonumber")
equal(utils:GetClassFileFromClassName(secret), nil, "Secret class name is rejected before string operations")
equal(utils:GetClassColorByFile(secret), nil, "Secret token cannot index color containers")
equal(utils:GetClassFileForFriend(secret), nil, "Secret friend is never indexed")
equal(utils:GetClassFileForFriend(secretTable), nil, "Secret friend table is never indexed")
equal(utils:GetClassFileForFriend({ classFile = secret, classFileName = secret, classFilename = secret, classID = 10 }), "MONK",
	"Secret token fields do not hide a readable class ID")
equal(utils:GetClassFileForFriend({ classID = secret, className = "Death Knight" }), "DEATHKNIGHT",
	"Secret ID does not hide a readable class name")
equal(utils:GetClassFileForFriend({ classFileName = "DEMONHUNTER", classID = 10 }), "DEMONHUNTER",
	"Direct class token retains priority over ID")
equal(utils:GetClassColorByFile("UNKNOWN_CLASS"), nil, "Unknown class color lookup has no white fallback")
equal(utils:GetClassColorHex({}), "ffffffff", "Friend color lookup retains white fallback")

env.RAID_CLASS_COLORS = secretTable
env.C_ClassColor.GetClassColor = function() return secretTable end
equal(utils:GetClassColorByFile("MONK"), BFL.ClassColors.MONK, "Secret native color containers are not inspected")
env.C_ClassColor = secretTable
equal(utils:GetClassColorByFile("MONK"), BFL.ClassColors.MONK, "Secret API namespace is not indexed")
env.C_ClassColor = { GetClassColor = function() return { r = secret, g = 1, b = 1 } end }
equal(utils:GetClassColorByFile("MONK"), BFL.ClassColors.MONK, "Secret native RGB fields are rejected")
env.C_ClassColor.GetClassColor = function() return { r = 0 / 0, g = 1, b = 1 } end
equal(utils:GetClassColorByFile("MONK"), BFL.ClassColors.MONK, "NaN native RGB is rejected")
local recoveredColor = { r = 0.25, g = 0.5, b = 0.75 }
env.C_ClassColor.GetClassColor = function() return recoveredColor end
equal(utils:GetClassColorByFile("MONK"), recoveredColor, "Native color recovery is not masked by a cached fallback")

utils, BFL, env, calls, secret, secretTable = fixture()
local ids = utils:GetAvailableClassIDs()
equal(table.concat(ids, ","), "1,2,3,4,5,7,8,9,11", "Who filters keep Classic gaps and omit unavailable fallback classes")
for id in pairs(absent) do
	check(not (function() for _, actual in ipairs(ids) do if id == actual then return true end end end)(),
		"Cross-client color fallback never adds a Who option")
end
env.C_SpecializationInfo.GetAllClassIDs = function() return { 11, 1, 11, -1, 1.5, secret, 0, "10" } end
equal(table.concat(utils:GetAvailableClassIDs(), ","), "1,11", "Native ID list is validated and deduplicated")
env.C_SpecializationInfo.GetAllClassIDs = function() return secretTable end
equal(table.concat(utils:GetAvailableClassIDs(), ","), "1,2,3,4,5,7,8,9,11", "Secret native ID list recovers through readable client probes")
env.C_SpecializationInfo = secretTable
equal(table.concat(utils:GetAvailableClassIDs(), ","), "1,2,3,4,5,7,8,9,11", "Secret specialization namespace is skipped")
env.GetClassInfo = function() return secret, secret, secret end
equal(#utils:GetAvailableClassIDs(), 0, "Restricted class-info returns cannot create options")
env.GetClassInfo = function(id) if id == 11 then return "Druide", "DRUID", 11 end end
equal(table.concat(utils:GetAvailableClassIDs(), ","), "11", "Native class availability recovers after restrictions")
equal(utils:GetClassFileFromClassName("Druide"), "DRUID", "Localized API matching probes ID gaps")
env.LOCALIZED_CLASS_NAMES_MALE = secretTable
env.LOCALIZED_CLASS_NAMES_FEMALE = { WARRIOR = "Kriegerin", DEATHKNIGHT = "Todesritterin" }
equal(utils:GetClassFileFromClassName("Todesritterin"), "DEATHKNIGHT", "Localized missing-class identity does not depend on colors")
equal(utils:GetClassFileFromClassName("Kriegerin"), "WARRIOR", "Readable gender table survives restricted enrichment")
env.LOCALIZED_CLASS_NAMES_FEMALE = secretTable
env.C_CreatureInfo = { GetClassInfo = function() return secretTable end }
equal(utils:GetClassFileFromClassName("Unbekannt"), nil, "Restricted creature/localized tables are never indexed")
env.C_CreatureInfo.GetClassInfo = function(id) if id == 11 then return { className = "Druide", classFile = "DRUID" } end end
equal(utils:GetClassFileFromClassName("Druide"), "DRUID", "Readable native creature info remains usable")

utils, BFL, env = fixture()
for _, token in ipairs({ "ADVENTURER", "TRAVELER" }) do
	local native = { r = 0.8, g = 0.7, b = 0.6 }
	env.RAID_CLASS_COLORS[token] = native
	equal(utils:GetClassFileFromClassName(token), token, "Native custom class token is retained")
	equal(utils:GetClassColorByFile(token), native, "Native custom class color is retained")
	equal(utils:GetClassColorForFriend({ classFilename = token }), native, "Native custom friend color is retained")
end
env.GetClassInfo = function(id) if id == 14 then return "Traveler", "TRAVELER", 14 end end
equal(utils:GetClassFileFromClassID(14), "TRAVELER", "Native custom class ID remains supported")
io.write(string.format("PASS: %d ClassUtils checks (production modules; mocked native APIs)\n", checks))
