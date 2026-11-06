local ADDON_NAME, BFL = ...

-- Helper for Base64 Encoding/Decoding
-- Uses C_EncodingUtil (C++) if available (Retail/Modern)
-- Falls back to pure Lua implementation (Classic Compatibility)

-- Lua Base64 Implementation (Fallback)
-- Sourced from standard Lua Base64 implementations
local b64chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local b64map = {}
for i = 1, 64 do
	b64map[string.byte(b64chars, i)] = i - 1
end

local function fallback_encode(s)
	local chunks = {}
	for i = 1, #s, 3 do
		local a, b, c = string.byte(s, i, i + 2)
		local first = math.floor(a / 4) + 1
		local second = (a % 4) * 16 + math.floor((b or 0) / 16) + 1
		local third = ((b or 0) % 16) * 4 + math.floor((c or 0) / 64) + 1
		local fourth = (c or 0) % 64 + 1
		chunks[#chunks + 1] = b64chars:sub(first, first) .. b64chars:sub(second, second)
			.. (b and b64chars:sub(third, third) or "=") .. (c and b64chars:sub(fourth, fourth) or "=")
	end
	return table.concat(chunks)
end

local function fallback_decode(s)
	s = s:gsub("%s", "")
	if #s % 4 == 1 then return nil end
	local padding = s:find("=", 1, true)
	if padding and (#s % 4 ~= 0 or #s - padding > 1 or s:sub(padding):find("[^=]")) then return nil end
	local chunks = {}
	for i = 1, #s, 4 do
		local a, b, c, d = s:byte(i, i + 3)
		local first, second = b64map[a], b64map[b]
		if first == nil or second == nil then return nil end
		local byte1 = first * 4 + math.floor(second / 16)
		if c == nil or c == 61 then
			if (d ~= nil and d ~= 61) or i + 3 < #s or second % 16 ~= 0 then return nil end
			chunks[#chunks + 1] = string.char(byte1)
		else
			local third = b64map[c]
			if third == nil then return nil end
			local byte2 = (second % 16) * 16 + math.floor(third / 4)
			if d == nil or d == 61 then
				if i + 3 < #s or third % 4 ~= 0 then return nil end
				chunks[#chunks + 1] = string.char(byte1, byte2)
			else
				local fourth = b64map[d]
				if fourth == nil then return nil end
				chunks[#chunks + 1] = string.char(byte1, byte2, (third % 4) * 64 + fourth)
			end
		end
	end
	return table.concat(chunks)
end

-- Public API
function BFL:Base64Encode(text)
	if (BFL.IsSecret and BFL:IsSecret(text)) or type(text) ~= "string" then
		return nil
	end
	local success, result = pcall(function()
		if C_EncodingUtil and C_EncodingUtil.EncodeBase64 then
			return C_EncodingUtil.EncodeBase64(text)
		else
			return fallback_encode(text)
		end
	end)

	if success then
		return result
	else
		-- BFL:DebugPrint("Base64 Encode Error: " .. tostring(result))
		return nil
	end
end

function BFL:Base64Decode(text)
	if (BFL.IsSecret and BFL:IsSecret(text)) or type(text) ~= "string" then
		return nil
	end

	local success, result = pcall(function()
		if C_EncodingUtil and C_EncodingUtil.DecodeBase64 then
			local decoded = C_EncodingUtil.DecodeBase64(text)
			if decoded then
				return decoded
			end
			-- Fallback if native fails (unlikely, but safe)
			return fallback_decode(text)
		else
			return fallback_decode(text)
		end
	end)

	if success then
		return result
	else
		-- BFL:DebugPrint("Base64 Decode Error: " .. tostring(result))
		return nil
	end
end
