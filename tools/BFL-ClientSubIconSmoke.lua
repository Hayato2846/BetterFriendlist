-- Lua 5.4: lua tools/BFL-ClientSubIconSmoke.lua <repo> [FriendsList source override]
-- Runs production row selection, texture loading and account comparisons.
-- Native texture APIs are mocked; actual artwork needs an in-game check.
local repo = assert(arg[1], "repository root is required")
local function read(path)
	local file = assert(io.open(path, "rb"))
	local content = file:read("*a"); file:close(); return content
end
local source = read(arg[2] or (repo .. "/Modules/FriendsList.lua"))
local function between(text, first, last)
	local start = assert(text:find(first, 1, true), "missing anchor: " .. first)
	local finish = assert(text:find(last, start + #first, true), "missing anchor: " .. last)
	return text:sub(start, finish - 1)
end
local assertions = 0
local function equal(actual, expected, message)
	assertions = assertions + 1
	assert(actual == expected, message .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end
local secret = setmetatable({}, { __tostring = function() error("A secret sub-icon must not be stringified") end })
local BFL = { IsClassic = false }
function BFL:IsSecret(value) return value == secret end
local env = setmetatable({ BFL = BFL, SlashCmdList = {}, StaticPopupDialogs = {}, Enum = { ["TitleIconVersion"] = { Small = 0, Medium = 1 } },
	BNet_GetClientTexture = function(client) return "legacy:" .. client end,
	BNet_GetClientEmbeddedTexture = function(texture, width) return texture .. "@" .. width end,
}, { __index = _G })
local function execute(text, name)
	return assert(load(text, "@" .. name, "t", env))("BetterFriendlist", BFL)
end
execute(read(repo .. "/Utils/ClassicCompat.lua"), "Utils/ClassicCompat.lua")
local iconHelpers = between(source, "local function ApplyLegacyClientIcon(", "function FriendsList:UpdateMultiAccountRow(")
local rowSelection = between(source, "\t\t\tlocal clientProgram = friend.gameAccountInfo.clientProgram", "\t\t\t-- Fade icon")
local apply, updateRow = execute(iconHelpers .. "\nlocal function updateRow(friend, button, modern)\n"
	.. rowSelection .. "\nend\nreturn ApplyClientIcon, updateRow", "production icon selection")
local compare = execute(between(source, "local function AreSafeValuesEqual(", "local function IsVisibleGameAccount(")
	.. "\nreturn AreGameAccountInfosEqual", "production account comparison")
local function newTexture()
	local texture = {}
	function texture:SetTexture(value) self.value = value end
	function texture:GetTexture() return self.value end
	function texture:SetTexCoord() end
	function texture:SetSize(width) self.width = width end
	return texture
end
local calls, readySubIcon, resolvedSubIcon = {}, nil, nil
local textureAPI = {
	SetTitleIconTexture = function(texture, client, version, subIcon)
		calls[#calls + 1] = { client = client, version = version, subIcon = subIcon }
		texture:SetTexture("icon:" .. (subIcon or "default"))
	end,
	IsTitleIconTextureReady = function(_, _, subIcon) readySubIcon = subIcon; return true end,
	GetTitleIconTexture = function(_, _, callback, subIcon)
		resolvedSubIcon = subIcon
		callback(true, "icon:" .. (subIcon or "default"))
	end,
}
env["C_" .. "Texture"] = textureAPI
local button = { gameIcon = newTexture() }
local friend = { gameAccountInfo = { clientProgram = "WoW", wowProjectID = 18, subIcon = "forever" } }
updateRow(friend, button, true)
equal(button.gameIcon.value, "icon:forever", "The modern row selects Blizzard's account-specific artwork")
equal(calls[#calls].subIcon, "forever", "The native setter receives the sub-icon")
local count = #calls
updateRow(friend, button, true)
equal(#calls, count, "An unchanged variant retains its resolved icon")
friend.gameAccountInfo.subIcon = "retail"
updateRow(friend, button, true)
equal(button.gameIcon.value, "icon:retail", "Recycling a WoW row invalidates both caches when only the variant changes")
friend.gameAccountInfo.subIcon = nil
updateRow(friend, button, true)
equal(button.gameIcon.value, "icon:default", "Removing the variant restores the standard icon")
friend.gameAccountInfo.subIcon = secret
updateRow(friend, button, true)
equal(button.gameIcon.value, "icon:default", "A restricted variant never enters a cache key or native call")
equal(BFL.Compat.GetClientSubIcon(42), nil, "Non-string variants use the standard icon")
equal(BFL.Compat.GetClientSubIcon(""), nil, "Empty variants use the standard icon")
apply(button.gameIcon, "WoW", 16, 0, false, nil, "forever")
equal(readySubIcon, "forever", "The legacy layout checks readiness for the correct variant")
equal(button.gameIcon.value, "icon:forever", "The legacy layout also selects the account-specific icon")
apply(button.gameIcon, "WoW", 16, 0, true, "preview-art", "forever")
equal(button.gameIcon.value, "preview-art", "Explicit Preview artwork remains independent of title variants")
equal(BFL:GetClientEmbeddedIcon("WoW", 16, "forever"), "icon:forever@16 ", "Menu and Broker markup resolves the variant")
equal(resolvedSubIcon, "forever", "The resolver receives the variant after its callback argument")
equal(BFL.GetClientProgramIconPrefix("WoW", 32, "forever"), "icon:forever@32 ", "Tooltip markup resolves the same variant")
equal(BFL.GetClientProgramIconPrefix("WoW", 32, secret), "icon:default@32 ", "Tooltip markup ignores restricted variants")
equal(compare({ clientProgram = "WoW", subIcon = "forever" }, { clientProgram = "WoW", subIcon = "retail" }), false,
	"A variant-only account update triggers a friend refresh")
equal(compare({ clientProgram = "WoW", subIcon = "forever" }, { clientProgram = "WoW", subIcon = "forever" }), true,
	"Identical account variants avoid unnecessary refreshes")

local callbacks = {}
textureAPI.SetTitleIconTexture = nil
textureAPI.IsTitleIconTextureReady = function(_, _, subIcon) readySubIcon = subIcon; return false end
textureAPI.GetTitleIconTexture = function(_, _, callback, subIcon) callbacks[subIcon] = callback end
local recycled = newTexture()
apply(recycled, "WoW", 16, 0, false, nil, "forever")
apply(recycled, "WoW", 16, 0, false, nil, "retail")
callbacks.forever(true, "stale-forever")
equal(recycled.value, nil, "A delayed response for a previous variant cannot paint a recycled row")
callbacks.retail(true, "current-retail")
equal(recycled.value, "current-retail", "The current variant's delayed response paints its row")

env["C_" .. "Texture"] = nil
local classic = newTexture()
apply(classic, "WoW", 16, nil, false)
equal(classic.value, "legacy:WoW", "Clients without the title API retain their legacy fallback")
equal(BFL:GetClientEmbeddedIcon("WoW", 16), "legacy:WoW@16 ", "Classic embedded icons still use the legacy fallback")
io.write("[OK] Client sub-icon smoke: " .. assertions .. " assertions passed\n")
