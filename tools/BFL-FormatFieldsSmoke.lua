-- lua tools/BFL-FormatFieldsSmoke.lua <repo>
-- Production field extraction from all translated descriptions, without a profile or clipboard.
local root, checks = arg[1] or ".", 0
local BFL = { modules = {}, UI = { CONSTANTS = {} }, L = {} }
local env = setmetatable({ BFL_LOCALE_ENUS = {} }, { __index = _G })
setmetatable(BFL.L, { __index = env.BFL_LOCALE_ENUS })
env.BFL_LOCALE = BFL.L
function BFL:RegisterModule(name, value) self.modules[name] = value; return value end
function BFL:GetModule(name) return self.modules[name] end
function BFL:RegisterLocale(_, load) load() end
local function Load(file) return assert(loadfile(root .. "/" .. file, "t", env))("BetterFriendlist", BFL) end
Load("Locales/enUS.lua")
Load("Modules/Settings.lua")
local settings = BFL.modules.Settings
local function check(value, message) checks = checks + 1; assert(value, message) end
for _, locale in ipairs({ "enUS", "deDE", "esES", "esMX", "frFR", "itIT", "ptBR", "ruRU", "koKR", "zhCN", "zhTW" }) do
	for key in pairs(BFL.L) do BFL.L[key] = nil end
	if locale ~= "enUS" then Load("Locales/" .. locale .. ".lua") end
	for _, forever in ipairs({ false, true }) do
		BFL.IsForever = forever
		local name, info = settings:GetFormatFields(false), settings:GetFormatFields(true)
		check(#name == (forever and 11 or 10), locale .. " has incomplete name fields")
		check(#info == (forever and 16 or 15), locale .. " has incomplete info fields")
		for _, fields in ipairs({ name, info }) do
			local seen = {}
			for _, field in ipairs(fields) do
				check(field.token:match("^%%[a-z]+%%$") and not seen[field.token], "Invalid or duplicated copy token")
				check(field.description ~= "" and not field.description:find("|c", 1, true), "Missing or colored field description")
				seen[field.token] = true
			end
			check((seen["%ruleset%"] == true) == forever, "Ruleset field is shown on the wrong client")
		end
		local extra = {}; for _, field in ipairs(info) do extra[field.token] = true end
		check(extra["%accounts%"] and extra["%games%"] and extra["%statusonline%"], locale .. " is missing info-only fields")
	end
end
io.write(string.format("PASS: format references in all 11 locales, ordinary and Forever (%d checks)\n", checks))
