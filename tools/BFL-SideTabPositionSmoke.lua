-- lua tools/BFL-SideTabPositionSmoke.lua <repo> <Retail UI source> <Forever UI source>
-- Exercise production layout/artwork and real native mouse handlers without a live client.
local root, retail, forever = assert(arg[1]), assert(arg[2]), assert(arg[3])
local function Read(path)
	local file = assert(io.open(path, "rb"))
	local text = file:read("*a"); file:close()
	return text:gsub("\r\n", "\n")
end
local source = Read(root .. "/Modules/FriendsUI.lua")
local compatSource = Read(root .. "/Utils/ClassicCompat.lua")
local checks = 0
local function Equal(actual, expected, message)
	checks = checks + 1
	assert(actual == expected, message .. ": " .. tostring(actual) .. " ~= " .. tostring(expected))
end
local function Method(text, class, name)
	local start = assert(text:find("function " .. class .. ":" .. name .. "(", 1, true), name)
	local finish = text:find("\nfunction ", start + 1, true) or (#text + 1)
	return text:sub(start, finish - 1)
end
local function Region(coords)
	local region = { coords = coords or { 0.11, 0.21, 0.11, 0.71, 0.41, 0.21, 0.41, 0.71 }, shown = true }
	function region:GetTexCoord() return table.unpack(self.coords) end
	function region:GetAtlas() return self.atlas end
	function region:GetTextureFileID() return self.file end
	function region:GetTextureFilePath() return nil end
	function region:SetTexture(file, wrapX, wrapY)
		self.textureWrites = (self.textureWrites or 0) + 1
		self.file, self.atlas, self.wrapX, self.wrapY = file, nil, wrapX, wrapY
	end
	region.SetAtlas = function(self, atlas, _, _, _, wrapX, wrapY)
		self.wrapX, self.wrapY = wrapX, wrapY
		self.atlas, self.file = atlas, atlas == "replacement" and 222 or 111
		if atlas == "replacement" then self:SetTexCoord(0.2, 0.6, 0.3, 0.8)
		else self:SetTexCoord(0.11, 0.41, 0.21, 0.71) end
	end
	function region:SetTexCoord(left, right, top, bottom)
		assert(select("#", left, right, top, bottom) == 4)
		self.coords = { left, top, left, bottom, right, top, right, bottom }
	end
	function region:ClearAllPoints() self.point = nil end
	function region:SetPoint(...) self.point = { ... } end
	function region:IsShown() return self.shown end
	return region
end
for _, flavor in ipairs({ { root = retail, name = "Retail", offset = -2 }, { root = forever, name = "Forever", offset = -4 } }) do
	local xml = Read(flavor.root .. "/Interface/AddOns/Blizzard_SharedXML/Mainline/SharedUIPanelTemplates.xml")
	local templateStart = assert(xml:find('name="LargeSideTabButtonTemplate"', 1, true))
	local templateEnd = assert(xml:find("</Frame>", templateStart, true))
	local maskAtlas = xml:sub(templateStart, templateEnd):match('<MaskTexture parentKey="Mask" atlas="([^"]+)"')
	local db, FriendsUI, Native = {}, { selectedSection = "friends" }, {}
	local definition = { id = "friends" }
	local BFL = { GetModule = function() return nil end }
	function BFL.GetAtlasInfo(atlas)
		if atlas == "replacement" then return { file = 222, leftTexCoord = 0.2, rightTexCoord = 0.6, topTexCoord = 0.3, bottomTexCoord = 0.8 } end
		return { file = 111, leftTexCoord = 0.11, rightTexCoord = 0.41, topTexCoord = 0.21, bottomTexCoord = 0.71 }
	end
	local env = setmetatable({
		FriendsUI = FriendsUI, SidePanelTabButtonMixin = Native, BFL = BFL,
		Compat = BFL, HasAtlas = function(atlas) return BFL.GetAtlasInfo(atlas) ~= nil end, ATLAS_FALLBACKS = {},
		GetDB = function() return db end,
		SetDBValue = function(key, value) db[key] = value end,
		SECTION_DEFINITIONS = { definition }, SECTION_BY_ID = { friends = definition },
		MODERN_THEMED_SIDE_TAB_OFFSET_X = -3, BetterFriendsFrame = {},
		unpack = table.unpack, PlaySound = function() end, SOUNDKIT = { IG_CHARACTER_INFO_TAB = 1 },
	}, { __index = _G })
	local function Execute(text) assert(load(text, "@" .. flavor.name .. " production", "t", env))() end
	local compatStart = assert(compatSource:find("function Compat.SetTextureOrAtlas(", 1, true))
	local compatEnd = assert(compatSource:find("\nfunction Compat.", compatStart + 1, true))
	Execute(compatSource:sub(compatStart, compatEnd - 1))
	for _, name in ipairs({ "GetSideTabPosition", "SetSideTabPosition", "GetSideTabIconAnchorOffsets",
		"AnchorSideTabContents", "ApplySideTabDirection", "LayoutNavigationTabs", "GetAuxiliaryWindowOffset", "CreateNavigationTabs",
		"RefreshAuxiliaryWindowAnchors" }) do
		Execute(Method(source, "FriendsUI", name))
	end
	local nativeSource = Read(flavor.root .. "/Interface/AddOns/Blizzard_SharedXML/Mainline/SharedUIPanelTemplates.lua")
	for _, name in ipairs({ "OnMouseDown", "OnMouseUp", "SetCustomOnMouseUpHandler" }) do
		Execute(Method(nativeSource, "SidePanelTabButtonMixin", name))
	end
	if flavor.name == "Forever" then
		for _, name in ipairs({ "GetFinalIconAnchorOffsets", "GetPressedIconAnchorOffsets" }) do
			Execute(Method(nativeSource, "SidePanelTabButtonMixin", name))
		end
		Execute(Method(Read(flavor.root .. "/Interface/AddOns/Blizzard_SharedXML/Camelot/SharedUIPanelTemplates.lua"),
			"SidePanelTabButtonMixin", "GetIconAnchorOffsetsForTabArt"))
	end
	local themed = false
	function FriendsUI:GetModernThemeColors() return {}, themed end
	function FriendsUI:GetFriendTabOrder() return { "friends" } end
	function FriendsUI:IsModernActive() return true end
	function FriendsUI:RefreshFriendTabSettings() self:LayoutNavigationTabs() end
	function FriendsUI:RefreshRaidInfoFrameAnchor() end
	function FriendsUI:SelectSection(id) self.selectedSection = id end
	env.CreateFrame = function()
		local tab = setmetatable({ Icon = Region(), Count = Region(), scripts = {} }, { __index = Native })
		for _, key in ipairs({ "Background", "SelectedTexture", "HighlightTexture", "TabGlow" }) do
			tab[key] = Region({ 0, 0, 0, 1, 1, 0, 1, 1 })
			tab[key].atlas = "common-sidetab"
		end
		if maskAtlas then
			tab.Mask = Region()
			tab.Mask.atlas, tab.Mask.file = maskAtlas, 111
			tab.Mask.wrapX, tab.Mask.wrapY = "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE"
		end
		function tab:HookScript(name, hook)
			local original = self.scripts[name] or Native[name]
			self.scripts[name] = function(...) if original then original(...) end; hook(...) end
		end
		function tab:SetScript(name, callback) self.scripts[name] = callback end
		function tab:ClearAllPoints() self.point = nil end
		function tab:SetPoint(...) self.point = { ... } end
		function tab:IsShown() return true end
		return tab
	end
	FriendsUI.root = {}
	Equal(FriendsUI:GetSideTabPosition(), "right", "old profiles default right")
	-- A reload starts with the stored side before any interactive theme change.
	db.modernSideTabPosition = "left"
	FriendsUI.currentTheme = "ellesmereui"
	FriendsUI:CreateNavigationTabs()
	local tab = FriendsUI.sideTabs[1]
	FriendsUI:RefreshFriendTabSettings()
	if tab.Mask then
		Equal(tab.Mask:GetAtlas(), "common-sidetab-mask", "saved EUI/left startup preserves the native icon mask atlas")
		Equal(tab.Mask.textureWrites or 0, 0, "saved EUI/left startup never converts a mask into raw atlas-sheet sampling")
	else
		Equal(tab.Mask, nil, "Retail template has no Forever mask")
	end
	FriendsUI.currentTheme = nil
	for _, side in ipairs({ "left", "left", "right", "left", "right" }) do
		FriendsUI:SetSideTabPosition(side)
		Equal(db.modernSideTabPosition, side, "setting is saved")
		Equal(tab.point[1], side == "left" and "TOPRIGHT" or "TOPLEFT", "rail anchor")
		Equal(tab.point[3], side == "left" and "TOPLEFT" or "TOPRIGHT", "frame anchor")
		Equal(FriendsUI:GetAuxiliaryWindowOffset(nil, side), 68, "tab-side window clearance")
		Equal(FriendsUI:GetAuxiliaryWindowOffset(12, side == "left" and "right" or "left"), 12, "opposite-side legacy clearance")
		for _, key in ipairs({ "Background", "SelectedTexture", "HighlightTexture", "TabGlow" }) do
			Equal(tab[key].coords[1], side == "left" and 0.41 or 0.11, key .. " keeps atlas bounds")
			Equal(tab[key].coords[4], 0.71, key .. " keeps vertical orientation")
		end
		Equal(tab.Icon.coords[1], 0.11, "icon is never mirrored")
		if tab.Mask then
			Equal(tab.Mask:GetAtlas(), "common-sidetab-mask", "direction changes retain the native content mask")
			Equal(tab.Mask.coords[1], 0.11, "direction changes never mirror content-mask UVs")
			Equal(tab.Mask.textureWrites or 0, 0, "direction changes never rewrite the mask texture")
			Equal(tab.Mask.wrapX, "CLAMPTOBLACKADDITIVE", "mask retains native horizontal sampling")
			Equal(tab.Mask.wrapY, "CLAMPTOBLACKADDITIVE", "mask retains native vertical sampling")
		end
		local x = side == "left" and -flavor.offset or flavor.offset
		tab.scripts.OnMouseDown(tab, "LeftButton")
		Equal(tab.Icon.point[4], x + 1, "native press keeps mirrored icon center")
		Equal(tab.Icon.point[5], 4, "press preserves count clearance")
		tab.scripts.OnMouseUp(tab, "LeftButton", false)
		Equal(tab.Icon.point[4], x, "release outside restores mirrored icon center")
		Equal(tab.Icon.point[5], 5, "release preserves count clearance")
	end
	FriendsUI:SetSideTabPosition("left")
	tab.Background.atlas = "replacement"
	tab.Background:SetTexCoord(0.2, 0.6, 0.3, 0.8)
	FriendsUI:ApplySideTabDirection(tab)
	Equal(tab.Background.coords[1], 0.6, "theme atlas replacement is mirrored from its own bounds")
	FriendsUI:SetSideTabPosition("right")
	Equal(tab.Background.coords[1], 0.2, "theme atlas replacement restores exact original bounds")
	tab.Background:SetTexture(333)
	FriendsUI:SetSideTabPosition("left")
	Equal(tab.Background:GetTextureFileID(), 333, "a skin replacement cannot resurrect the Blizzard shell")
	themed = true
	FriendsUI:SetSideTabPosition("left")
	Equal(tab.point[4], 3, "flat-theme overlap follows left edge")
	Equal(tab.Icon.point[4], 0, "flat-theme icon stays centered")
	Equal(tab.Count.point[4], 0, "flat-theme counter stays centered")
	FriendsUI.currentTheme = "elvui"
	FriendsUI:LayoutNavigationTabs()
	Equal(tab.point[4], -2, "ElvUI rail follows left edge")
	Equal(tab.point[5], -1, "ElvUI keeps its top offset")
	FriendsUI:SetSideTabPosition("invalid")
	Equal(FriendsUI:GetSideTabPosition(), "right", "invalid saved choice normalizes to default")
	local getAtlasInfo = BFL.GetAtlasInfo
	BFL.GetAtlasInfo = function() return nil end
	local unavailable = env.CreateFrame()
	db.modernSideTabPosition = "left"
	FriendsUI:ApplySideTabDirection(unavailable)
	Equal(unavailable.Background:GetAtlas(), "common-sidetab", "missing atlas API leaves unsupported artwork untouched")
	FriendsUI:SetSideTabPosition("right")
	if tab.Mask then
		Equal(tab.Mask:GetAtlas(), "common-sidetab-mask", "missing atlas API leaves the native content mask untouched")
		Equal(tab.Mask.coords[1], 0.11, "missing atlas API keeps the native mask coordinates")
		Equal(tab.Mask.wrapX, "CLAMPTOBLACKADDITIVE", "fallback preserves mask sampling")
	end
	BFL.GetAtlasInfo = getAtlasInfo
	io.write("[OK] " .. flavor.name .. " side-tab artwork, native press/release, layouts and settings\n")
end
io.write("[OK] Side-tab position smoke: " .. checks .. " assertions\n")
