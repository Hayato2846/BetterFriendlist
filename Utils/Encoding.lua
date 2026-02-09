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
	local r = ""
	local y = 0
	local b = { 0, 0, 0 }
	for i = 1, #s, 1 do
		b[y + 1] = string.byte(s, i)
		y = y + 1
		if y == 3 then
			r = r .. string.sub(b64chars, math.floor(b[1] / 4) + 1, math.floor(b[1] / 4) + 1)
			r = r
				.. string.sub(
					b64chars,
					math.floor(((b[1] % 4) * 16) + (b[2] / 16)) + 1,
					math.floor(((b[1] % 4) * 16) + (b[2] / 16)) + 1
				)
			r = r
				.. string.sub(
					b64chars,
					math.floor(((b[2] % 16) * 4) + (b[3] / 64)) + 1,
					math.floor(((b[2] % 16) * 4) + (b[3] / 64)) + 1
				)
			r = r .. string.sub(b64chars, (b[3] % 64) + 1, (b[3] % 64) + 1)
			y = 0
		end
	end
	if y == 1 then
		r = r .. string.sub(b64chars, math.floor(b[1] / 4) + 1, math.floor(b[1] / 4) + 1)
		r = r .. string.sub(b64chars, math.floor(((b[1] % 4) * 16)) + 1, math.floor(((b[1] % 4) * 16)) + 1)
		r = r .. "=="
	elseif y == 2 then
		r = r .. string.sub(b64chars, math.floor(b[1] / 4) + 1, math.floor(b[1] / 4) + 1)
		r = r
			.. string.sub(
				b64chars,
				math.floor(((b[1] % 4) * 16) + (b[2] / 16)) + 1,
				math.floor(((b[1] % 4) * 16) + (b[2] / 16)) + 1
			)
		r = r .. string.sub(b64chars, math.floor(((b[2] % 16) * 4)) + 1, math.floor(((b[2] % 16) * 4)) + 1)
		r = r .. "="
	end
	return r
end

local function fallback_decode(s)
	s = string.gsub(s, "[^" .. b64chars .. "=]", "")
	local r = ""
	local z = 0
	local b = { 0, 0, 0, 0 }
	for i = 1, #s, 1 do
		local c = string.byte(s, i)
		if c >= 65 and c <= 90 then
			b[z + 1] = c - 65
		elseif c >= 97 and c <= 122 then
			b[z + 1] = c - 71
		elseif c >= 48 and c <= 57 then
			b[z + 1] = c + 4
		elseif c == 43 then
			b[z + 1] = 62
		elseif c == 47 then
			b[z + 1] = 63
		elseif c == 61 then
			break
		end
		z = z + 1
		if z == 4 then
			r = r .. string.char(((b[1] * 4) + math.floor(b[2] / 16)))
			r = r .. string.char(((b[2] % 16) * 16) + math.floor(b[3] / 4))
			r = r .. string.char(((b[3] % 4) * 64) + b[4])
			z = 0
		end
	end
	return r
end

-- Public API
function BFL:Base64Encode(text)
	if not text then
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
	if not text then
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
