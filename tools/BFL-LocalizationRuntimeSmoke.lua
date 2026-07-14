local repoRoot = assert(arg[1], "repository root argument is required")
local separator = package.config:sub(1, 1)

local function join(...)
	return table.concat({ ... }, separator)
end

local function loadAddonFile(relativePath, addonTable)
	local normalizedPath = relativePath:gsub("/", separator)
	local path = join(repoRoot, normalizedPath)
	local chunk, loadError = loadfile(path)
	assert(chunk, loadError)
	return chunk("BetterFriendlist", addonTable)
end

function GetLocale()
	return "enUS"
end

function wipe(target)
	for key in pairs(target) do
		target[key] = nil
	end
	return target
end

local BFL = {}
loadAddonFile("Locales/Locales.lua", BFL)
loadAddonFile("Locales/enUS.lua", BFL)

local translatedLocales = {
	"deDE", "esES", "esMX", "frFR", "itIT",
	"ptBR", "ruRU", "koKR", "zhCN", "zhTW",
}

for _, locale in ipairs(translatedLocales) do
	loadAddonFile("Locales/" .. locale .. ".lua", BFL)
end

local expectedKeys = {}
for key in pairs(BFL_LOCALE_ENUS) do
	table.insert(expectedKeys, key)
end
table.sort(expectedKeys)
assert(#expectedKeys > 0, "enUS locale loaded without keys")

local criticalKeys = {
	"BROKER_SETTINGS_INSTRUCTIONS",
	"CORE_COMPAT_ACTIVE",
	"CORE_HELP_INVITE",
	"RAID_NO_MOCK_DATA",
	"SETTINGS_CENTER_HELP_SLASH",
	"SETTINGS_INGAME_MODE_TOOLTIP_DESC",
}

for _, locale in ipairs(translatedLocales) do
	BFL.MissingKeys = {}
	BFL:SetLocale(locale)

	local loadedCount = 0
	for _ in pairs(BFL_LOCALE) do
		loadedCount = loadedCount + 1
	end
	assert(loadedCount == #expectedKeys, string.format(
		"%s loaded %d keys; expected %d", locale, loadedCount, #expectedKeys
	))

	for _, key in ipairs(expectedKeys) do
		local value = BFL.L[key]
		assert(type(value) == "string" and value ~= "", locale .. "/" .. key .. " is empty or non-string")
	end

	local missing = {}
	for key in pairs(BFL.MissingKeys) do
		table.insert(missing, key)
	end
	table.sort(missing)
	assert(#missing == 0, locale .. " used enUS fallback keys: " .. table.concat(missing, ", "))

	for _, key in ipairs(criticalKeys) do
		assert(BFL_LOCALE[key] ~= nil, locale .. "/" .. key .. " was not loaded into the active locale")
	end

	io.write(string.format("[OK] %s: %d keys, no runtime fallback\n", locale, loadedCount))
end

io.write(string.format(
	"[OK] Localization runtime smoke passed for %d translated locales and %d keys.\n",
	#translatedLocales,
	#expectedKeys
))
