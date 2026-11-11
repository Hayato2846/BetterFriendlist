-- Lua 5.4: lua tools/BFL-EncodingSmoke.lua <repo>
-- RFC 4648 vectors and an independent Python-generated binary fixture.
local repo = arg[1] or "."
local BFL = {}
local secret = {}
function BFL:IsSecret(value) return value == secret end
local env = setmetatable({}, { __index = _G })
assert(loadfile(repo .. "/Utils/Encoding.lua", "t", env))("BetterFriendlist", BFL)
local checks = 0
local function equal(actual, expected, message)
	checks = checks + 1
	assert(actual == expected, message)
end
for _, vector in ipairs({ { "", "" }, { "f", "Zg==" }, { "fo", "Zm8=" }, { "foo", "Zm9v" },
	{ "foob", "Zm9vYg==" }, { "fooba", "Zm9vYmE=" }, { "foobar", "Zm9vYmFy" } }) do
	equal(BFL:Base64Encode(vector[1]), vector[2], "RFC encoding")
	equal(BFL:Base64Decode(vector[2]), vector[1], "RFC decoding preserves padded tails")
end
local bytes = {}
for byte = 0, 255 do bytes[#bytes + 1] = string.char(byte) end
local binary = table.concat(bytes)
local fixture = "AAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8gISIjJCUmJygpKissLS4vMDEyMzQ1Njc4OTo7PD0+P0BBQkNERUZHSElKS0xNTk9QUVJTVFVWV1hZWltcXV5fYGFiY2RlZmdoaWprbG1ub3BxcnN0dXZ3eHl6e3x9fn+AgYKDhIWGh4iJiouMjY6PkJGSk5SVlpeYmZqbnJ2en6ChoqOkpaanqKmqq6ytrq+wsbKztLW2t7i5uru8vb6/wMHCw8TFxsfIycrLzM3Oz9DR0tPU1dbX2Nna29zd3t/g4eLj5OXm5+jp6uvs7e7v8PHy8/T19vf4+fr7/P3+/w=="
equal(BFL:Base64Encode(binary), fixture, "All 256 byte values match Python base64")
equal(BFL:Base64Decode(fixture), binary, "All 256 byte values decode without loss")
for _, suffix in ipairs({ "", "a", "ab" }) do
	local value = string.rep(binary, 5) .. suffix
	equal(BFL:Base64Decode(BFL:Base64Encode(value)), value, "All padding classes roundtrip binary data")
end
equal(BFL:Base64Decode(" YQ==\r\n"), "a", "Whitespace around a padded value is accepted")
equal(BFL:Base64Decode("YQ"), "a", "A valid unpadded final byte is retained")
equal(BFL:Base64Decode("YWI"), "ab", "A valid unpadded final pair is retained")
for _, invalid in ipairs({ "A", "YQ=", "=YQ=", "YQ===", "YQ==YQ==", "YW@Jj", "AA=A", "AB==", "AAB=" }) do
	equal(BFL:Base64Decode(invalid), nil, "Malformed or noncanonical Base64 is rejected: " .. invalid)
end
equal(BFL:Base64Encode(secret), nil, "Restricted input is not inspected")
equal(BFL:Base64Decode(secret), nil, "Restricted encoded input is not inspected")
equal(BFL:Base64Decode(42), nil, "Non-string input is rejected")
env.C_EncodingUtil = { EncodeBase64 = function() return "native-encoded" end,
	DecodeBase64 = function() return "native-decoded" end }
equal(BFL:Base64Encode("x"), "native-encoded", "Native encoding remains preferred")
equal(BFL:Base64Decode("eA=="), "native-decoded", "Native decoding remains preferred")
env.C_EncodingUtil.DecodeBase64 = function() return nil end
equal(BFL:Base64Decode("YQ=="), "a", "Native rejection falls back without dropping the final byte")
io.write("[OK] Encoding smoke: " .. checks .. " checks passed\n")
error("BFL CI verification: deliberate smoke failure")
