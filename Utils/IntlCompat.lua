-- Utils/IntlCompat.lua
-- Capability-gated Unicode search and locale-aware sort helpers.

local ADDON_NAME, BFL = ...

local IntlCompat = {}
BFL.IntlCompat = IntlCompat

local function GetIntlAPI()
	if IntlCompat._testAPI ~= nil then
		return IntlCompat._testAPI or nil
	end
	return C_Intl
end

local function IsSecretValue(value)
	if BFL.IsSecret and BFL:IsSecret(value) then
		return true
	end
	return false
end

local function GetSafeText(value, nilFallback)
	-- Secret values must be rejected before any comparison, conversion, or
	-- boolean test. C_Intl accepts secret arguments only from untainted code.
	if IsSecretValue(value) then
		return nil
	end
	if value == nil then
		return nilFallback
	end

	local ok, text = pcall(tostring, value)
	if not ok or IsSecretValue(text) or type(text) ~= "string" or text:sub(1, 2) == "|K" then
		return nil
	end
	return text
end

local function GetCollationStrength(name)
	local strengths = IntlCompat._testStrengths or (Enum and Enum.CollationStrength)
	return strengths and strengths[name] or nil
end

local function GetFallbackSearchText(value)
	local text = GetSafeText(value)
	if not text or text == "" then
		return text or ""
	end
	if BFL.StripAccents then
		return BFL:StripAccents(text)
	end
	return text:lower()
end

function IntlCompat.CanUseIntl()
	local api = GetIntlAPI()
	return api ~= nil
		and type(api.FindStringMatches) == "function"
		and type(api.CompareStrings) == "function"
		and type(api.GetSortKey) == "function"
		and GetCollationStrength("Primary") ~= nil
		and GetCollationStrength("Tertiary") ~= nil
end

function IntlCompat.NormalizeForSearch(value)
	local text = GetSafeText(value)
	if not text or text == "" then
		return text or ""
	end

	local api = GetIntlAPI()
	if IntlCompat.CanUseIntl() and type(api.FoldCase) == "function" then
		local ok, result = pcall(api.FoldCase, text)
		if ok and not IsSecretValue(result) and type(result) == "string" then
			return result
		end
	end
	return GetFallbackSearchText(text)
end

function IntlCompat.Contains(textValue, queryValue)
	local text = GetSafeText(textValue, "")
	local query = GetSafeText(queryValue, "")
	if not text or not query then
		return false
	end
	if query == "" then
		return true
	end

	if IntlCompat.CanUseIntl() then
		local api = GetIntlAPI()
		local ok, matches = pcall(api.FindStringMatches, text, query, GetCollationStrength("Primary"))
		if ok and not IsSecretValue(matches) and type(matches) == "table" then
			return next(matches) ~= nil
		end
	end

	local normalizedText = GetFallbackSearchText(text)
	local normalizedQuery = GetFallbackSearchText(query)
	return normalizedText:find(normalizedQuery, 1, true) ~= nil
end

function IntlCompat.Equals(leftValue, rightValue)
	local left = GetSafeText(leftValue, "")
	local right = GetSafeText(rightValue, "")
	if not left or not right then
		return false
	end

	if IntlCompat.CanUseIntl() then
		local api = GetIntlAPI()
		local ok, result = pcall(api.CompareStrings, left, right, GetCollationStrength("Primary"))
		if ok and not IsSecretValue(result) and type(result) == "number" then
			return result == 0
		end
	end
	return GetFallbackSearchText(left) == GetFallbackSearchText(right)
end

function IntlCompat.GetSortKey(value)
	local text = GetSafeText(value)
	if not text or text == "" then
		return ""
	end

	if IntlCompat.CanUseIntl() then
		local api = GetIntlAPI()
		local ok, sortKey = pcall(api.GetSortKey, text, GetCollationStrength("Tertiary"))
		if ok and not IsSecretValue(sortKey) and type(sortKey) == "string" and sortKey ~= "" then
			return sortKey
		end
	end
	return GetFallbackSearchText(text)
end

return IntlCompat
