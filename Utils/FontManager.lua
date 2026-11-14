-- BetterFriendlist - FontManager Module
-- Handles font sizing, scaling, compact mode, and Alphabet-aware FontFamilies

local _, BFL = ...

-- Create FontManager namespace
BFL.FontManager = {}
local FontManager = BFL.FontManager

local WINDOW_FONT_TARGETS = setmetatable({}, { __mode = "k" })

function FontManager:RegisterWindowFont(fontString, role)
	if not (fontString and fontString.GetFont) then return end
	if not WINDOW_FONT_TARGETS[fontString] then
		local path, size, flags = fontString:GetFont()
		WINDOW_FONT_TARGETS[fontString] = { path = path, size = size, flags = flags, role = role,
			fontObject = fontString.GetFontObject and fontString:GetFontObject() }
	end
end

function FontManager:GetWindowFontDefaults(role)
	local main = _G.BetterFriendsFrame
	local ui = BFL:GetModule("FriendsUI")
	local candidate
	if role == "ActionButton" then
		local button = main and main.AddFriendButton
		if ui and ui.IsModernActive and ui:IsModernActive() and ui.root and ui.root.BottomActionBar then
			button = ui.root.BottomActionBar.AddFriendButton
		end
		candidate = button and button:GetFontString()
	else
		candidate = main and ((main.TitleContainer and main.TitleContainer.TitleText) or main.TitleText)
	end
	local native = candidate and WINDOW_FONT_TARGETS[candidate]
	if native then return native.path, native.size, native.flags end
	for _, original in pairs(WINDOW_FONT_TARGETS) do
		if original.role == role then return original.path, original.size, original.flags end
	end
	return STANDARD_TEXT_FONT, 12, ""
end

function FontManager:ApplyWindowTextFont(target, path, size, flags, custom, originalObject)
	if not target.SetFontObject then return self:SafeSetFont(target, path, size, flags) end
	local r, g, b, a = target:GetTextColor()
	local x, y = target:GetShadowOffset()
	local sr, sg, sb, sa = target:GetShadowColor()
	local family = custom and self:GetOrCreateFontFamily(path, size, flags, false)
	if family then
		target:SetFontObject(family)
	else
		if not custom and originalObject then target:SetFontObject(originalObject) end
		self:SafeSetFont(target, path, size, flags)
	end
	-- Font families supply locale glyph fallbacks; themes still own text colors.
	target:SetTextColor(r, g, b, a)
	target:SetShadowOffset(x, y)
	target:SetShadowColor(sr, sg, sb, sa)
end

function FontManager:RefreshWindowFonts()
	local db = BFL:GetModule("DB")
	if not db then return end
	local function RegisterButton(button)
		if not (button and button.GetFontString) then return end
		local fontString = button:GetFontString()
		self:RegisterWindowFont(fontString, "ActionButton")
		local original = WINDOW_FONT_TARGETS[fontString]
		if original and not original.button then
			original.button, original.width, original.height = button, button:GetWidth(), button:GetHeight()
			if button.HookScript then
				local function RefreshState()
					if db:Get("fontActionButton", "") ~= "" or db:Get("fontSizeActionButton", 0) > 0 then
						self:RefreshWindowFonts()
					end
				end
				for _, event in ipairs({ "OnEnter", "OnLeave", "OnMouseDown", "OnMouseUp", "OnEnable", "OnDisable" }) do
					button:HookScript(event, RefreshState)
				end
			end
		end
	end
	local function RegisterWindow(frame)
		if not frame then return end
		self:RegisterWindowFont((frame.TitleContainer and frame.TitleContainer.TitleText) or frame.TitleText or frame.Title or frame.title, "WindowTitle")
		for _, key in ipairs({ "AddFriendButton", "button1", "button2", "applyButton", "createButton" }) do
			RegisterButton(frame[key])
		end
		RegisterButton(frame.BottomActionBar and frame.BottomActionBar.AddFriendButton)
	end
	RegisterWindow(_G.BetterFriendsFrame)
	local friendsUI = BFL:GetModule("FriendsUI")
	RegisterWindow(friendsUI and friendsUI.root)
	RegisterWindow(_G.BetterFriendlistSettingsFrame)
	local review = BFL:GetModule("LegacySettingsReview")
	RegisterWindow(review and review.frame)
	local editor = BFL:GetModule("FriendTagEditor")
	RegisterWindow(editor and editor.frame)
	RegisterButton(editor and editor.applyButton)
	local designer = BFL:GetModule("SettingsDesigner")
	RegisterWindow(designer and designer.GetFrame and designer:GetFrame())
	local dialogs = BFL:GetModule("Dialogs")
	RegisterWindow(dialogs and dialogs.inputDialog)
	for target, original in pairs(WINDOW_FONT_TARGETS) do
		local face = db:Get("font" .. original.role, "")
		local size = tonumber(db:Get("fontSize" .. original.role, 0)) or 0
		local custom = face ~= "" or size > 0
		if not original.appliedCustom then
			-- Until the player overrides it, the current theme owns the native font.
			original.path, original.size, original.flags = target:GetFont()
			original.fontObject = target.GetFontObject and target:GetFontObject()
			if original.button then
				original.width, original.height = original.button:GetWidth(), original.button:GetHeight()
			end
		end
		local path = face ~= "" and self:ResolveFontPath(face) or original.path
		local layoutPending = false
		if custom or original.appliedCustom then
			self:ApplyWindowTextFont(target, path, size > 0 and size or original.size, original.flags,
				face ~= "", original.fontObject)
		end
		if original.button and (custom or original.appliedCustom) then
			local width = custom and math.max(original.width, target:GetStringWidth() + 24) or original.width
			local height = custom and math.max(original.height, target:GetStringHeight() + 8) or original.height
			if math.abs(original.button:GetWidth() - width) > 0.01 or math.abs(original.button:GetHeight() - height) > 0.01 then
				if InCombatLockdown() and original.button:IsProtected() then
					layoutPending = true
					self.windowFontsAfterCombat = true
					if not self.windowFontCombatCallback then
						self.windowFontCombatCallback = true
						BFL:RegisterEventCallback("PLAYER_REGEN_ENABLED", function()
							if self.windowFontsAfterCombat then
								self.windowFontsAfterCombat = nil
								self:RefreshWindowFonts()
							end
						end)
					end
				else
					original.button:SetSize(width, height)
				end
			end
		end
		original.appliedCustom = custom or layoutPending
	end
	if dialogs and dialogs.inputDialog then dialogs:LayoutInputDialog() end
end

function FontManager:RefreshDisplayFonts()
	if InCombatLockdown() then return false end
	local visited, count = {}, 0
	local function Visit(frame, depth)
		if not frame or visited[frame] or depth > 10 or (frame.IsForbidden and frame:IsForbidden()) then return end
		visited[frame] = true
		local text = frame.GetFontString and frame:GetFontString()
		if text and text.GetFont then
			local object = text.GetFontObject and text:GetFontObject()
			local path, size, flags = text:GetFont()
			local override = not object
			if object and object.GetFont then
				local objectPath, objectSize, objectFlags = object:GetFont()
				override = path ~= objectPath or size ~= objectSize or (flags or "") ~= (objectFlags or "")
			end
			local r, g, b, a = text:GetTextColor()
			local x, y = text:GetShadowOffset()
			local sr, sg, sb, sa = text:GetShadowColor()
			local justifyH = text.GetJustifyH and text:GetJustifyH()
			local justifyV = text.GetJustifyV and text:GetJustifyV()
			local spacing = text.GetSpacing and text:GetSpacing()
			local alternate
			for _, state in ipairs({ "Normal", "Highlight", "Disabled" }) do
				local get, set = frame["Get" .. state .. "FontObject"], frame["Set" .. state .. "FontObject"]
				if get and set then
					local font = get(frame)
					if font then
						if font ~= object then alternate = font end
						set(frame, font)
					end
				end
			end
			-- Rebind instances, never mutate shared Blizzard/skin FontObjects.
			-- Preserve deliberate per-instance size/face overrides and theme colors.
			-- Swapping through an existing state font defeats same-object fast paths.
			if object and alternate and text.SetFontObject then text:SetFontObject(alternate) end
			if object and text.SetFontObject then text:SetFontObject(object) end
			if override and path and size then self:SafeSetFont(text, path, size, flags) end
			text:SetTextColor(r, g, b, a)
			text:SetShadowOffset(x, y)
			text:SetShadowColor(sr, sg, sb, sa)
			if justifyH and text.SetJustifyH then text:SetJustifyH(justifyH) end
			if justifyV and text.SetJustifyV then text:SetJustifyV(justifyV) end
			if spacing and text.SetSpacing then text:SetSpacing(spacing) end
			count = count + 1
		end
		if frame.GetChildren then
			for _, child in ipairs({ frame:GetChildren() }) do Visit(child, depth + 1) end
		end
	end
	Visit(BFL.MainFrame or _G.BetterFriendsFrame, 0)
	Visit(_G.BetterFriendlistSettingsFrame, 0)
	Visit(_G.BetterFriendlistHelpFrame, 0)
	for _, name in ipairs({ "FriendTagEditor", "IconSelector", "LegacySettingsReview" }) do
		local module = BFL:GetModule(name)
		Visit(module and module.frame, 0)
	end
	local designer = BFL:GetModule("SettingsDesigner")
	Visit(designer and designer.GetFrame and designer:GetFrame(), 0)
	local dialogs = BFL:GetModule("Dialogs")
	Visit(dialogs and dialogs.inputDialog, 0)
	self:RefreshWindowFonts()
	return count
end

function FontManager:ResetWindowFont(role)
	local db = BFL:GetModule("DB")
	db:Set("font" .. role, "")
	db:Set("fontSize" .. role, 0)
	self:RefreshWindowFonts()
end

-- ========================================
-- Dependencies
-- ========================================
local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
local GetDB = function()
	return BFL:GetModule("DB")
end

-- ========================================
-- Font Path Resolution
-- ========================================

-- Resolve a font name (e.g. "Friz Quadrata TT") to a file path.
-- Uses LibSharedMedia if available; falls back to STANDARD_TEXT_FONT
-- which is locale-aware (e.g. 2002.TTF on Korean, FRIZQT___CYR.TTF on Russian).
function FontManager:ResolveFontPath(fontName)
	if not fontName then
		return STANDARD_TEXT_FONT
	end
	-- Already a file path
	if fontName:find("\\") or fontName:find("/") then
		return fontName
	end
	-- Try LibSharedMedia (may be provided by another addon)
	local media = LibStub and LibStub("LibSharedMedia-3.0", true)
	if media then
		local path = media:Fetch("font", fontName)
		if path then
			return path
		end
	end
	-- Built-in alternative for clients without LibSharedMedia.
	if fontName == "Arial Narrow" then return "Fonts\\ARIALN.TTF" end
	if fontName == "Skurri" then return "Fonts\\skurri.ttf" end
	if fontName == "Morpheus" then return "Fonts\\MORPHEUS.ttf" end
	-- Unresolvable name: use locale-appropriate default
	return STANDARD_TEXT_FONT
end

-- ========================================
-- Advanced Font Family System
-- ========================================

local FONT_CACHE = {}
-- NOTE: "japanese" is excluded as it is not a standard CreateFontFamily member key in all client versions.
-- CJK characters for Japanese are typically covered by the "korean" or Chinese fonts in WoW's fallback system.
local ALPHABETS = { "roman", "korean", "simplifiedchinese", "traditionalchinese", "russian" }

-- Map Locale to Alphabet
local function GetLocaleAlphabet()
	local locale = GetLocale()
	if locale == "koKR" then
		return "korean"
	elseif locale == "zhCN" then
		return "simplifiedchinese"
	elseif locale == "zhTW" then
		return "traditionalchinese"
	elseif locale == "ruRU" then
		return "russian"
	-- jaJP uses standard fonts (often maps to Roman or Korean internally)
	-- We default to "roman" so the user's chosen font is used for the main text.
	else
		return "roman"
	end
end

local CURRENT_ALPHABET = GetLocaleAlphabet()
local FAMILY_COUNTER = 0
local SLUG_RENDERING_SUPPORTED = nil

local FONT_FLAG_ORDER = { "OUTLINE", "THICKOUTLINE", "MONOCHROME", "SLUG" }
local VALID_FONT_FLAGS = {
	OUTLINE = true,
	THICKOUTLINE = true,
	MONOCHROME = true,
	SLUG = true,
}

if table.freeze then
	table.freeze(ALPHABETS)
	table.freeze(FONT_FLAG_ORDER)
	table.freeze(VALID_FONT_FLAGS)
end

local FONT_FLAG_ALIASES = {
	NONE = "",
	NORMAL = "",
	THINOUTLINE = "OUTLINE",
}

-- Font flags are applied to every visible friend row. Keep the public set
-- helpers mutable, but cache the canonical strings used by the render path so
-- repeated SafeSetFont calls do not allocate parser and serializer tables.
local NORMALIZED_FONT_FLAG_CACHE = {
	[""] = "",
	NONE = "",
	NORMAL = "",
}
local RUNTIME_FONT_FLAG_CACHE = {}
local DEFAULT_UI_FONT_FLAG_CACHE = {}

local function GetFontFlagSet(flags)
	local flagSet = {}
	if flags == nil then
		return flagSet
	end

	for flag in tostring(flags):gmatch("[^,%s]+") do
		flag = string.upper(flag)
		flag = FONT_FLAG_ALIASES[flag] or flag
		if flag ~= "" and VALID_FONT_FLAGS[flag] then
			flagSet[flag] = true
		end
	end

	if flagSet.THICKOUTLINE then
		flagSet.OUTLINE = nil
	end

	return flagSet
end

local function SerializeFontFlags(flagSet)
	local flags = {}
	for _, flag in ipairs(FONT_FLAG_ORDER) do
		if flagSet[flag] then
			flags[#flags + 1] = flag
		end
	end
	return table.concat(flags, ",")
end

function FontManager:NormalizeFontFlags(flags)
	local cacheKey = tostring(flags or "")
	local cached = NORMALIZED_FONT_FLAG_CACHE[cacheKey]
	if cached ~= nil then
		return cached
	end

	local normalized = SerializeFontFlags(GetFontFlagSet(cacheKey))
	NORMALIZED_FONT_FLAG_CACHE[cacheKey] = normalized
	return normalized
end

function FontManager:GetFontFlagSet(flags)
	return GetFontFlagSet(flags)
end

function FontManager:SerializeFontFlags(flagSet)
	return SerializeFontFlags(flagSet or {})
end

function FontManager:AddFontFlag(flags, flag)
	local flagSet = GetFontFlagSet(flags)
	flag = FONT_FLAG_ALIASES[flag] or flag
	if flag and VALID_FONT_FLAGS[flag] then
		if flag == "OUTLINE" then
			flagSet.THICKOUTLINE = nil
		elseif flag == "THICKOUTLINE" then
			flagSet.OUTLINE = nil
		end
		flagSet[flag] = true
	end
	return SerializeFontFlags(flagSet)
end

function FontManager:RemoveFontFlag(flags, flag)
	local flagSet = GetFontFlagSet(flags)
	flag = FONT_FLAG_ALIASES[flag] or flag
	if flag and VALID_FONT_FLAGS[flag] then
		flagSet[flag] = nil
	end
	return SerializeFontFlags(flagSet)
end

function FontManager:IsSlugRenderingAvailable()
	if SLUG_RENDERING_SUPPORTED ~= nil then
		return SLUG_RENDERING_SUPPORTED
	end

	SLUG_RENDERING_SUPPORTED = false
	if not CreateFont then
		return false
	end

	local probeFont = _G.BFL_SlugProbeFont
	if not probeFont then
		local ok, createdFont = pcall(CreateFont, "BFL_SlugProbeFont")
		if not ok or not createdFont then
			return false
		end
		probeFont = createdFont
	end

	local fontPath = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
	local ok, result = pcall(probeFont.SetFont, probeFont, fontPath, 12, "SLUG")
	SLUG_RENDERING_SUPPORTED = ok and result ~= false
	return SLUG_RENDERING_SUPPORTED
end

function FontManager:GetFontFlags(flags)
	local normalized = self:NormalizeFontFlags(flags)
	local cached = RUNTIME_FONT_FLAG_CACHE[normalized]
	if cached ~= nil then
		return cached
	end

	local resolved = normalized
	if normalized:find("SLUG", 1, true) and not self:IsSlugRenderingAvailable() then
		resolved = self:RemoveFontFlag(normalized, "SLUG")
	end
	RUNTIME_FONT_FLAG_CACHE[normalized] = resolved
	return resolved
end

function FontManager:GetDefaultUIFontFlags(flags)
	local resolved = self:GetFontFlags(flags)
	local cached = DEFAULT_UI_FONT_FLAG_CACHE[resolved]
	if cached ~= nil then
		return cached
	end

	local defaultFlags = resolved
	if self:IsSlugRenderingAvailable() and not resolved:find("SLUG", 1, true) then
		defaultFlags = self:AddFontFlag(resolved, "SLUG")
	end
	DEFAULT_UI_FONT_FLAG_CACHE[resolved] = defaultFlags
	return defaultFlags
end

function FontManager:SafeSetFont(fontObject, fontPath, fontSize, flags)
	if not fontObject or not fontObject.SetFont or not fontPath or not fontSize then
		return false
	end

	local resolvedFlags = self:GetFontFlags(flags)
	local ok, result = pcall(fontObject.SetFont, fontObject, fontPath, fontSize, resolvedFlags)
	return ok and result ~= false
end

function FontManager:SetSmoothScalingIfAvailable(fontString, enabled)
	if not fontString or not fontString.SetSmoothScaling then
		return false
	end

	local ok = pcall(fontString.SetSmoothScaling, fontString, not not enabled)
	return ok
end

function FontManager:GetTextWidth(fontString, text)
	if not fontString then
		return 0
	end

	local measurementText = text
	if measurementText == nil and fontString.GetText then
		measurementText = fontString:GetText()
	end

	if measurementText ~= nil and fontString.GetUnboundedStringWidthForText then
		local ok, width = pcall(fontString.GetUnboundedStringWidthForText, fontString, measurementText)
		if ok and width then
			return width
		end
	end

	if text ~= nil and fontString.SetText and fontString.GetText then
		local originalText = fontString:GetText()
		fontString:SetText(text)
		local width = fontString.GetStringWidth and fontString:GetStringWidth() or 0
		fontString:SetText(originalText)
		return width or 0
	end

	return fontString.GetStringWidth and fontString:GetStringWidth() or 0
end

function FontManager:ApplyDefaultSlugToFontObject(fontObject)
	if not fontObject or not fontObject.GetFont or not fontObject.SetFont then
		return false
	end

	local fontPath, fontSize, flags = fontObject:GetFont()
	if not fontPath or not fontSize then
		return false
	end

	local resolvedFlags = self:GetFontFlags(flags)
	local slugFlags = self:GetDefaultUIFontFlags(flags)
	if slugFlags == resolvedFlags then
		return true
	end

	return self:SafeSetFont(fontObject, fontPath, fontSize, slugFlags)
end

function FontManager:ApplyDefaultSlugToFontString(fontString)
	if not fontString or not fontString.GetFont or not fontString.SetFont then
		return false
	end

	local fontPath, fontSize, flags = fontString:GetFont()
	if not fontPath or not fontSize then
		return false
	end

	local resolvedFlags = self:GetFontFlags(flags)
	local slugFlags = self:GetDefaultUIFontFlags(flags)
	if slugFlags == resolvedFlags then
		return true
	end

	return self:SafeSetFont(fontString, fontPath, fontSize, slugFlags)
end

-- Generate and Cache FontFamily
function FontManager:GetOrCreateFontFamily(fontPath, size, flags, shadow, useFontForNonLatinAlphabets)
	-- Normalize inputs
	size = math.floor(size + 0.5) -- Round to integer
	flags = self:GetFontFlags(flags)

	local shadowKey = shadow and "SHADOW" or "NONE"
	local alphabetKey = useFontForNonLatinAlphabets and "USER_NON_LATIN" or "SYSTEM_NON_LATIN"

	-- Create Cache Key
	local cacheKey = string.format("%s_%d_%s_%s_%s", fontPath, size, flags, shadowKey, alphabetKey)

	if FONT_CACHE[cacheKey] then
		return FONT_CACHE[cacheKey]
	end

	-- Create Unique Global Name
	FAMILY_COUNTER = FAMILY_COUNTER + 1
	local familyName = "BFL_GenFont_" .. FAMILY_COUNTER

	-- Build Family Members
	local members = {}
	local baseFont = _G["ChatFontNormal"] -- Safe fallback source

	for _, alphabet in ipairs(ALPHABETS) do
		local memberDef = {}

		memberDef.alphabet = alphabet
		memberDef.height = size
		memberDef.flags = flags

		if alphabet == "roman" or useFontForNonLatinAlphabets then
			-- Roman text always uses the chosen font. Non-latin alphabets use it only
			-- when explicitly enabled because many LSM fonts do not contain those glyphs.
			memberDef.file = fontPath
		elseif alphabet == CURRENT_ALPHABET then
			-- Non-roman locale: Prefer the system default for this alphabet
			-- because the user's chosen font (e.g. FRIZQT__.TTF) is unlikely
			-- to contain glyphs for Korean, Chinese, or Cyrillic.
			local defaultFile = nil
			if baseFont and baseFont.GetFontObjectForAlphabet then
				local defaultObj = baseFont:GetFontObjectForAlphabet(alphabet)
				if defaultObj then
					defaultFile, _, _ = defaultObj:GetFont()
				end
			end
			memberDef.file = defaultFile or fontPath
		else
			-- Secondary alphabet: Try to use system fallback
			local defaultFile = nil
			if baseFont then
				local defaultObj = baseFont:GetFontObjectForAlphabet(alphabet)
				if defaultObj then
					defaultFile, _, _ = defaultObj:GetFont()
				end
			end

			-- Keep user font as last resort if system default is missing
			memberDef.file = defaultFile or fontPath
		end

		table.insert(members, memberDef)
	end

	-- Create the Font Family Object
	local success, familyObj = pcall(CreateFontFamily, familyName, members)

	if not success or not familyObj then
		-- BFL:DebugPrint("CreateFontFamily failed for: " .. fontPath)
		return nil
	end

	-- Apply Shadow to all members
	local targetShadowParams = shadow and { 1, -1, 0, 0, 0, 1 } or { 0, 0, 0, 0, 0, 0 }

	for _, alphabet in ipairs(ALPHABETS) do
		local memberObj = familyObj:GetFontObjectForAlphabet(alphabet)
		if memberObj then
			memberObj:SetShadowOffset(targetShadowParams[1], targetShadowParams[2])
			memberObj:SetShadowColor(
				targetShadowParams[3],
				targetShadowParams[4],
				targetShadowParams[5],
				targetShadowParams[6]
			)
		end
	end

	-- Cache it
	FONT_CACHE[cacheKey] = familyObj
	return familyObj
end

-- ========================================
-- Font Family Logic
-- ========================================

-- Apply font to a FontString using the robust Family system
function FontManager:ApplyFont(fontString, fontPath, size, flags, shadow)
	if not fontString or not fontPath then
		return
	end

	-- Attempt to get/create the FontFamily object
	local familyObj = self:GetOrCreateFontFamily(fontPath, size, flags, shadow)

	if familyObj then
		-- Apply the Family Object
		fontString:SetFontObject(familyObj)
	else
		-- Fallback: Use SetFont directly if Family creation failed
		-- This loses alphabet backups but keeps text visible
		self:SafeSetFont(fontString, fontPath, size, flags)
		if shadow then
			fontString:SetShadowOffset(1, -1)
			fontString:SetShadowColor(0, 0, 0, 1)
		else
			fontString:SetShadowOffset(0, 0)
			fontString:SetShadowColor(0, 0, 0, 0)
		end
	end
	self:SetSmoothScalingIfAvailable(fontString, true)
end

-- ========================================
-- Public API
-- ========================================

-- Get button height based on compact mode setting
function FontManager:GetButtonHeight()
	local db = GetDB()
	if db and db:Get("compactMode", false) then
		return 24 -- Compact height
	end
	return 34 -- Normal height
end

-- Get font size multiplier based on settings
function FontManager:GetFontSizeMultiplier()
	-- REMOVED: Global scaling disabled (User Request 2026-01-20)
	return 1.0
end

-- Apply font size to a font string based on settings
function FontManager:ApplyFontSize(fontString)
	-- REMOVED: Global font scaling disabled (User Request 2026-01-20)
	-- No-op to preserve original XML/CreateFontString sizes
end

-- Get compact mode setting
function FontManager:GetCompactMode()
	local db = GetDB()
	if not db then
		return false
	end
	return db:Get("compactMode", false)
end

-- Set compact mode (triggers UI refresh)
function FontManager:SetCompactMode(enabled)
	local db = GetDB()
	if not db then
		return
	end

	db:Set("compactMode", enabled)

	-- Force full display refresh for immediate update
	if BFL and BFL.ForceRefreshFriendsList then
		BFL:ForceRefreshFriendsList()
	end
end

-- Set font size (triggers UI refresh)
function FontManager:SetFontSize(size)
	-- REMOVED: Global font scaling disabled (User Request 2026-01-20)
end

-- ========================================
-- Helper Functions
-- ========================================

-- Get recommended font object based on settings
function FontManager:GetRecommendedFont()
	local fontSize = self:GetFontSizeMultiplier()

	if fontSize < 0.9 then
		return "BetterFriendlistFontNormalSmall"
	elseif fontSize > 1.1 then
		return "BetterFriendlistFontNormal"
	else
		return "BetterFriendlistFontNormalSmall"
	end
end
