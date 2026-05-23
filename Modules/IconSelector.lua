-- Modules/IconSelector.lua
-- Icon selector for BFL icon references and Blizzard macro icons.

local ADDON_NAME, BFL = ...

local IconSelector = BFL:RegisterModule("IconSelector", {})

local BFL_ICON_PREFIX = "Interface\\AddOns\\BetterFriendlist\\Icons\\"
local L = BFL.L or {}

BFL.BFLIconCatalog = {
	BFL_ICON_PREFIX .. "activity",
	BFL_ICON_PREFIX .. "airplay",
	BFL_ICON_PREFIX .. "alert-circle",
	BFL_ICON_PREFIX .. "alert-octagon",
	BFL_ICON_PREFIX .. "alert-triangle",
	BFL_ICON_PREFIX .. "align-center",
	BFL_ICON_PREFIX .. "align-justify",
	BFL_ICON_PREFIX .. "align-left",
	BFL_ICON_PREFIX .. "align-right",
	BFL_ICON_PREFIX .. "anchor",
	BFL_ICON_PREFIX .. "aperture",
	BFL_ICON_PREFIX .. "archive",
	BFL_ICON_PREFIX .. "arrow-down",
	BFL_ICON_PREFIX .. "arrow-down-circle",
	BFL_ICON_PREFIX .. "arrow-down-left",
	BFL_ICON_PREFIX .. "arrow-down-right",
	BFL_ICON_PREFIX .. "arrow-left",
	BFL_ICON_PREFIX .. "arrow-left-circle",
	BFL_ICON_PREFIX .. "arrow-right",
	BFL_ICON_PREFIX .. "arrow-right-circle",
	BFL_ICON_PREFIX .. "arrow-up",
	BFL_ICON_PREFIX .. "arrow-up-circle",
	BFL_ICON_PREFIX .. "arrow-up-left",
	BFL_ICON_PREFIX .. "arrow-up-right",
	BFL_ICON_PREFIX .. "at-sign",
	BFL_ICON_PREFIX .. "award",
	BFL_ICON_PREFIX .. "bar-chart",
	BFL_ICON_PREFIX .. "bar-chart-2",
	BFL_ICON_PREFIX .. "battery",
	BFL_ICON_PREFIX .. "battery-charging",
	BFL_ICON_PREFIX .. "bell",
	BFL_ICON_PREFIX .. "bell-off",
	BFL_ICON_PREFIX .. "bluetooth",
	BFL_ICON_PREFIX .. "bold",
	BFL_ICON_PREFIX .. "book",
	BFL_ICON_PREFIX .. "bookmark",
	BFL_ICON_PREFIX .. "book-open",
	BFL_ICON_PREFIX .. "box",
	BFL_ICON_PREFIX .. "briefcase",
	BFL_ICON_PREFIX .. "calendar",
	BFL_ICON_PREFIX .. "camera",
	BFL_ICON_PREFIX .. "camera-off",
	BFL_ICON_PREFIX .. "cast",
	BFL_ICON_PREFIX .. "check",
	BFL_ICON_PREFIX .. "check-circle",
	BFL_ICON_PREFIX .. "check-square",
	BFL_ICON_PREFIX .. "chevron-down",
	BFL_ICON_PREFIX .. "chevron-left",
	BFL_ICON_PREFIX .. "chevron-right",
	BFL_ICON_PREFIX .. "chevrons-down",
	BFL_ICON_PREFIX .. "chevrons-left",
	BFL_ICON_PREFIX .. "chevrons-right",
	BFL_ICON_PREFIX .. "chevrons-up",
	BFL_ICON_PREFIX .. "chevron-up",
	BFL_ICON_PREFIX .. "chrome",
	BFL_ICON_PREFIX .. "circle",
	BFL_ICON_PREFIX .. "class",
	BFL_ICON_PREFIX .. "clipboard",
	BFL_ICON_PREFIX .. "clock",
	BFL_ICON_PREFIX .. "cloud",
	BFL_ICON_PREFIX .. "cloud-drizzle",
	BFL_ICON_PREFIX .. "cloud-lightning",
	BFL_ICON_PREFIX .. "cloud-off",
	BFL_ICON_PREFIX .. "cloud-rain",
	BFL_ICON_PREFIX .. "cloud-snow",
	BFL_ICON_PREFIX .. "code",
	BFL_ICON_PREFIX .. "codepen",
	BFL_ICON_PREFIX .. "codesandbox",
	BFL_ICON_PREFIX .. "coffee",
	BFL_ICON_PREFIX .. "columns",
	BFL_ICON_PREFIX .. "command",
	BFL_ICON_PREFIX .. "compass",
	BFL_ICON_PREFIX .. "copy",
	BFL_ICON_PREFIX .. "corner-down-left",
	BFL_ICON_PREFIX .. "corner-down-right",
	BFL_ICON_PREFIX .. "corner-left-down",
	BFL_ICON_PREFIX .. "corner-left-up",
	BFL_ICON_PREFIX .. "corner-right-down",
	BFL_ICON_PREFIX .. "corner-right-up",
	BFL_ICON_PREFIX .. "corner-up-left",
	BFL_ICON_PREFIX .. "corner-up-right",
	BFL_ICON_PREFIX .. "cpu",
	BFL_ICON_PREFIX .. "credit-card",
	BFL_ICON_PREFIX .. "crop",
	BFL_ICON_PREFIX .. "crosshair",
	BFL_ICON_PREFIX .. "database",
	BFL_ICON_PREFIX .. "delete",
	BFL_ICON_PREFIX .. "disc",
	BFL_ICON_PREFIX .. "discord",
	BFL_ICON_PREFIX .. "divide",
	BFL_ICON_PREFIX .. "divide-circle",
	BFL_ICON_PREFIX .. "divide-square",
	BFL_ICON_PREFIX .. "dollar-sign",
	BFL_ICON_PREFIX .. "download",
	BFL_ICON_PREFIX .. "download-cloud",
	BFL_ICON_PREFIX .. "dribbble",
	BFL_ICON_PREFIX .. "droplet",
	BFL_ICON_PREFIX .. "edit",
	BFL_ICON_PREFIX .. "edit-2",
	BFL_ICON_PREFIX .. "edit-3",
	BFL_ICON_PREFIX .. "external-link",
	BFL_ICON_PREFIX .. "eye",
	BFL_ICON_PREFIX .. "eye-off",
	BFL_ICON_PREFIX .. "facebook",
	BFL_ICON_PREFIX .. "faction",
	BFL_ICON_PREFIX .. "fast-forward",
	BFL_ICON_PREFIX .. "feather",
	BFL_ICON_PREFIX .. "figma",
	BFL_ICON_PREFIX .. "file",
	BFL_ICON_PREFIX .. "file-minus",
	BFL_ICON_PREFIX .. "file-plus",
	BFL_ICON_PREFIX .. "file-text",
	BFL_ICON_PREFIX .. "film",
	BFL_ICON_PREFIX .. "filter",
	BFL_ICON_PREFIX .. "filter-all",
	BFL_ICON_PREFIX .. "filter-bnet",
	BFL_ICON_PREFIX .. "filter-hide-afk",
	BFL_ICON_PREFIX .. "filter-offline",
	BFL_ICON_PREFIX .. "filter-online",
	BFL_ICON_PREFIX .. "filter-retail",
	BFL_ICON_PREFIX .. "filter-wow",
	BFL_ICON_PREFIX .. "flag",
	BFL_ICON_PREFIX .. "folder",
	BFL_ICON_PREFIX .. "folder-minus",
	BFL_ICON_PREFIX .. "folder-plus",
	BFL_ICON_PREFIX .. "framer",
	BFL_ICON_PREFIX .. "frown",
	BFL_ICON_PREFIX .. "game",
	BFL_ICON_PREFIX .. "gift",
	BFL_ICON_PREFIX .. "git-branch",
	BFL_ICON_PREFIX .. "git-commit",
	BFL_ICON_PREFIX .. "github",
	BFL_ICON_PREFIX .. "gitlab",
	BFL_ICON_PREFIX .. "git-merge",
	BFL_ICON_PREFIX .. "git-pull-request",
	BFL_ICON_PREFIX .. "globe",
	BFL_ICON_PREFIX .. "grid",
	BFL_ICON_PREFIX .. "guild",
	BFL_ICON_PREFIX .. "hard-drive",
	BFL_ICON_PREFIX .. "hash",
	BFL_ICON_PREFIX .. "headphones",
	BFL_ICON_PREFIX .. "heart",
	BFL_ICON_PREFIX .. "help-circle",
	BFL_ICON_PREFIX .. "hexagon",
	BFL_ICON_PREFIX .. "home",
	BFL_ICON_PREFIX .. "image",
	BFL_ICON_PREFIX .. "inbox",
	BFL_ICON_PREFIX .. "info",
	BFL_ICON_PREFIX .. "instagram",
	BFL_ICON_PREFIX .. "italic",
	BFL_ICON_PREFIX .. "key",
	BFL_ICON_PREFIX .. "kofi",
	BFL_ICON_PREFIX .. "layers",
	BFL_ICON_PREFIX .. "layout",
	BFL_ICON_PREFIX .. "level",
	BFL_ICON_PREFIX .. "life-buoy",
	BFL_ICON_PREFIX .. "link",
	BFL_ICON_PREFIX .. "link-2",
	BFL_ICON_PREFIX .. "linkedin",
	BFL_ICON_PREFIX .. "list",
	BFL_ICON_PREFIX .. "loader",
	BFL_ICON_PREFIX .. "lock",
	BFL_ICON_PREFIX .. "log-in",
	BFL_ICON_PREFIX .. "log-out",
	BFL_ICON_PREFIX .. "mail",
	BFL_ICON_PREFIX .. "map",
	BFL_ICON_PREFIX .. "map-pin",
	BFL_ICON_PREFIX .. "maximize",
	BFL_ICON_PREFIX .. "maximize-2",
	BFL_ICON_PREFIX .. "meh",
	BFL_ICON_PREFIX .. "menu",
	BFL_ICON_PREFIX .. "message-circle",
	BFL_ICON_PREFIX .. "message-square",
	BFL_ICON_PREFIX .. "mic",
	BFL_ICON_PREFIX .. "mic-off",
	BFL_ICON_PREFIX .. "minimize",
	BFL_ICON_PREFIX .. "minimize-2",
	BFL_ICON_PREFIX .. "minus",
	BFL_ICON_PREFIX .. "minus-circle",
	BFL_ICON_PREFIX .. "minus-square",
	BFL_ICON_PREFIX .. "monitor",
	BFL_ICON_PREFIX .. "moon",
	BFL_ICON_PREFIX .. "more-horizontal",
	BFL_ICON_PREFIX .. "more-vertical",
	BFL_ICON_PREFIX .. "mouse-pointer",
	BFL_ICON_PREFIX .. "move",
	BFL_ICON_PREFIX .. "music",
	BFL_ICON_PREFIX .. "name",
	BFL_ICON_PREFIX .. "navigation",
	BFL_ICON_PREFIX .. "navigation-2",
	BFL_ICON_PREFIX .. "octagon",
	BFL_ICON_PREFIX .. "package",
	BFL_ICON_PREFIX .. "paperclip",
	BFL_ICON_PREFIX .. "pause",
	BFL_ICON_PREFIX .. "pause-circle",
	BFL_ICON_PREFIX .. "pen-tool",
	BFL_ICON_PREFIX .. "percent",
	BFL_ICON_PREFIX .. "phone",
	BFL_ICON_PREFIX .. "phone-call",
	BFL_ICON_PREFIX .. "phone-forwarded",
	BFL_ICON_PREFIX .. "phone-incoming",
	BFL_ICON_PREFIX .. "phone-missed",
	BFL_ICON_PREFIX .. "phone-off",
	BFL_ICON_PREFIX .. "phone-outgoing",
	BFL_ICON_PREFIX .. "pie-chart",
	BFL_ICON_PREFIX .. "play",
	BFL_ICON_PREFIX .. "play-circle",
	BFL_ICON_PREFIX .. "plus",
	BFL_ICON_PREFIX .. "plus-circle",
	BFL_ICON_PREFIX .. "plus-square",
	BFL_ICON_PREFIX .. "pocket",
	BFL_ICON_PREFIX .. "power",
	BFL_ICON_PREFIX .. "printer",
	BFL_ICON_PREFIX .. "radio",
	BFL_ICON_PREFIX .. "realm",
	BFL_ICON_PREFIX .. "refresh-ccw",
	BFL_ICON_PREFIX .. "refresh-cw",
	BFL_ICON_PREFIX .. "repeat",
	BFL_ICON_PREFIX .. "rewind",
	BFL_ICON_PREFIX .. "rotate-ccw",
	BFL_ICON_PREFIX .. "rotate-cw",
	BFL_ICON_PREFIX .. "rss",
	BFL_ICON_PREFIX .. "save",
	BFL_ICON_PREFIX .. "scissors",
	BFL_ICON_PREFIX .. "search",
	BFL_ICON_PREFIX .. "send",
	BFL_ICON_PREFIX .. "server",
	BFL_ICON_PREFIX .. "settings",
	BFL_ICON_PREFIX .. "share",
	BFL_ICON_PREFIX .. "share-2",
	BFL_ICON_PREFIX .. "shield",
	BFL_ICON_PREFIX .. "shield-off",
	BFL_ICON_PREFIX .. "shopping-bag",
	BFL_ICON_PREFIX .. "shopping-cart",
	BFL_ICON_PREFIX .. "shuffle",
	BFL_ICON_PREFIX .. "sidebar",
	BFL_ICON_PREFIX .. "skip-back",
	BFL_ICON_PREFIX .. "skip-forward",
	BFL_ICON_PREFIX .. "slack",
	BFL_ICON_PREFIX .. "slash",
	BFL_ICON_PREFIX .. "sliders",
	BFL_ICON_PREFIX .. "smartphone",
	BFL_ICON_PREFIX .. "smile",
	BFL_ICON_PREFIX .. "speaker",
	BFL_ICON_PREFIX .. "square",
	BFL_ICON_PREFIX .. "star",
	BFL_ICON_PREFIX .. "status",
	BFL_ICON_PREFIX .. "stop-circle",
	BFL_ICON_PREFIX .. "sun",
	BFL_ICON_PREFIX .. "sunrise",
	BFL_ICON_PREFIX .. "sunset",
	BFL_ICON_PREFIX .. "table",
	BFL_ICON_PREFIX .. "tablet",
	BFL_ICON_PREFIX .. "tag",
	BFL_ICON_PREFIX .. "target",
	BFL_ICON_PREFIX .. "terminal",
	BFL_ICON_PREFIX .. "thermometer",
	BFL_ICON_PREFIX .. "thumbs-down",
	BFL_ICON_PREFIX .. "thumbs-up",
	BFL_ICON_PREFIX .. "toggle-left",
	BFL_ICON_PREFIX .. "toggle-right",
	BFL_ICON_PREFIX .. "tool",
	BFL_ICON_PREFIX .. "trash",
	BFL_ICON_PREFIX .. "trash-2",
	BFL_ICON_PREFIX .. "trello",
	BFL_ICON_PREFIX .. "trending-down",
	BFL_ICON_PREFIX .. "trending-up",
	BFL_ICON_PREFIX .. "triangle",
	BFL_ICON_PREFIX .. "truck",
	BFL_ICON_PREFIX .. "tv",
	BFL_ICON_PREFIX .. "twitch",
	BFL_ICON_PREFIX .. "twitter",
	BFL_ICON_PREFIX .. "type",
	BFL_ICON_PREFIX .. "umbrella",
	BFL_ICON_PREFIX .. "underline",
	BFL_ICON_PREFIX .. "unlock",
	BFL_ICON_PREFIX .. "upload",
	BFL_ICON_PREFIX .. "upload-cloud",
	BFL_ICON_PREFIX .. "user",
	BFL_ICON_PREFIX .. "user-check",
	BFL_ICON_PREFIX .. "user-minus",
	BFL_ICON_PREFIX .. "user-plus",
	BFL_ICON_PREFIX .. "users",
	BFL_ICON_PREFIX .. "user-x",
	BFL_ICON_PREFIX .. "video",
	BFL_ICON_PREFIX .. "video-off",
	BFL_ICON_PREFIX .. "voicemail",
	BFL_ICON_PREFIX .. "volume",
	BFL_ICON_PREFIX .. "volume-1",
	BFL_ICON_PREFIX .. "volume-2",
	BFL_ICON_PREFIX .. "volume-x",
	BFL_ICON_PREFIX .. "watch",
	BFL_ICON_PREFIX .. "wifi",
	BFL_ICON_PREFIX .. "wifi-off",
	BFL_ICON_PREFIX .. "wind",
	BFL_ICON_PREFIX .. "x",
	BFL_ICON_PREFIX .. "x-circle",
	BFL_ICON_PREFIX .. "x-octagon",
	BFL_ICON_PREFIX .. "x-square",
	BFL_ICON_PREFIX .. "youtube",
	BFL_ICON_PREFIX .. "zap",
	BFL_ICON_PREFIX .. "zap-off",
	BFL_ICON_PREFIX .. "zone",
	BFL_ICON_PREFIX .. "zoom-in",
	BFL_ICON_PREFIX .. "zoom-out",
}

local function GetText(key, fallback)
	return (L and L[key]) or fallback or key
end

local function GetRegistry()
	return BFL:GetModule("FilterSortRegistry")
end

local function FormatIcon(iconRef, size)
	local Registry = GetRegistry()
	if Registry and Registry.FormatIcon then
		return Registry:FormatIcon(iconRef, size)
	end
	size = size or 16
	return string.format("|T%s:%d:%d:0:0|t", tostring(iconRef or BFL_ICON_PREFIX .. "filter-all"), size, size)
end

local function CollectMacroIcons()
	local icons = {}
	local function Add(icon)
		if icon then
			table.insert(icons, icon)
		end
	end

	if C_Macro and C_Macro.GetMacroIcons then
		local ok, result = pcall(C_Macro.GetMacroIcons)
		if ok and type(result) == "table" then
			for _, icon in ipairs(result) do
				Add(icon)
			end
		end
	end

	if #icons == 0 and GetMacroIcons then
		local ok, result = pcall(GetMacroIcons)
		if ok and type(result) == "table" then
			for _, icon in ipairs(result) do
				Add(icon)
			end
		else
			local target = {}
			ok = pcall(GetMacroIcons, target)
			if ok then
				for _, icon in ipairs(target) do
					Add(icon)
				end
			end
		end
	end

	if #icons == 0 then
		icons = {
			134400,
			134414,
			134400,
			132212,
			132269,
			132316,
			136243,
			136235,
			135826,
			135940,
			135994,
			236447,
			237555,
			4620679,
		}
	end

	return icons
end

local function GetIconName(icon)
	if type(icon) == "number" then
		return tostring(icon)
	end
	local name = tostring(icon or "")
	return name:match("([^\\]+)$") or name
end

function IconSelector:Initialize()
	self.blizzardIcons = nil
end

function IconSelector:GetBFLIcons()
	return BFL.BFLIconCatalog or {}
end

function IconSelector:GetBlizzardIcons()
	if not self.blizzardIcons then
		self.blizzardIcons = CollectMacroIcons()
	end
	return self.blizzardIcons
end

function IconSelector:CreateFrame()
	if self.frame then
		return self.frame
	end

	local frame = CreateFrame("Frame", "BetterFriendlistIconSelectorFrame", UIParent, "BasicFrameTemplateWithInset")
	frame:SetSize(430, 450)
	frame:SetFrameStrata("DIALOG")
	frame:SetPoint("CENTER")
	frame:Hide()
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

	frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	frame.title:SetPoint("TOP", 0, -8)
	frame.title:SetText(GetText("ICON_SELECTOR_TITLE", "Select Icon"))

	frame.search = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
	frame.search:SetSize(180, 20)
	frame.search:SetPoint("TOPLEFT", 22, -35)
	frame.search:SetAutoFocus(false)
	frame.search:SetText("")

	frame.bflButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	frame.bflButton:SetSize(82, 22)
	frame.bflButton:SetPoint("LEFT", frame.search, "RIGHT", 12, 0)
	frame.bflButton:SetText("BFL")

	frame.blizzardButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	frame.blizzardButton:SetSize(100, 22)
	frame.blizzardButton:SetPoint("LEFT", frame.bflButton, "RIGHT", 6, 0)
	frame.blizzardButton:SetText(GetText("ICON_SELECTOR_BLIZZARD", "Blizzard"))

	frame.scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
	frame.scroll:SetPoint("TOPLEFT", 20, -66)
	frame.scroll:SetPoint("BOTTOMRIGHT", -30, 42)
	frame.content = CreateFrame("Frame", nil, frame.scroll)
	frame.content:SetSize(360, 330)
	frame.scroll:SetScrollChild(frame.content)

	frame.close = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	frame.close:SetSize(90, 22)
	frame.close:SetPoint("BOTTOMRIGHT", -18, 13)
	frame.close:SetText(GetText("BUTTON_CANCEL", "Cancel"))
	frame.close:SetScript("OnClick", function()
		frame:Hide()
	end)

	frame.buttons = {}
	frame.activeSource = "bfl"

	frame.bflButton:SetScript("OnClick", function()
		frame.activeSource = "bfl"
		IconSelector:RefreshFrame()
	end)
	frame.blizzardButton:SetScript("OnClick", function()
		frame.activeSource = "blizzard"
		IconSelector:RefreshFrame()
	end)
	frame.search:SetScript("OnTextChanged", function()
		IconSelector:RefreshFrame()
	end)

	self.frame = frame
	return frame
end

function IconSelector:AcquireButton(index)
	local frame = self.frame
	local button = frame.buttons[index]
	if button then
		return button
	end

	button = CreateFrame("Button", nil, frame.content)
	button:SetSize(30, 30)
	button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
	button.icon = button:CreateTexture(nil, "ARTWORK")
	button.icon:SetAllPoints()
	frame.buttons[index] = button
	return button
end

function IconSelector:RefreshFrame()
	local frame = self.frame
	if not frame then
		return
	end

	local icons = frame.activeSource == "blizzard" and self:GetBlizzardIcons() or self:GetBFLIcons()
	local search = (frame.search:GetText() or ""):lower()
	local columns = 10
	local size = 30
	local gap = 6
	local visibleIndex = 0
	local maxIcons = 800

	for _, icon in ipairs(icons) do
		local name = GetIconName(icon):lower()
		if search == "" or name:find(search, 1, true) then
			visibleIndex = visibleIndex + 1
			if visibleIndex > maxIcons then
				break
			end
			local button = self:AcquireButton(visibleIndex)
			local column = (visibleIndex - 1) % columns
			local row = math.floor((visibleIndex - 1) / columns)
			button:ClearAllPoints()
			button:SetPoint("TOPLEFT", frame.content, "TOPLEFT", column * (size + gap), -row * (size + gap))
			button.icon:SetTexture(icon)
			button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
			button.iconRef = icon
			button:SetScript("OnClick", function(self)
				if frame.callback then
					frame.callback(self.iconRef)
				end
				frame:Hide()
			end)
			button:Show()
		end
	end

	for index = visibleIndex + 1, #frame.buttons do
		frame.buttons[index]:Hide()
	end

	local rows = math.ceil(math.max(visibleIndex, 1) / columns)
	frame.content:SetHeight(math.max(330, rows * (size + gap)))
	frame.bflButton:SetEnabled(frame.activeSource ~= "bfl")
	frame.blizzardButton:SetEnabled(frame.activeSource ~= "blizzard")
end

function IconSelector:Show(owner, initialIcon, callback, options)
	local frame = self:CreateFrame()
	frame.callback = callback
	frame.activeSource = (options and options.source) or "bfl"
	frame.search:SetText("")
	frame.title:SetText(GetText("ICON_SELECTOR_TITLE", "Select Icon") .. " " .. FormatIcon(initialIcon, 18))
	frame:ClearAllPoints()
	if owner and owner.GetCenter then
		frame:SetPoint("CENTER", owner, "CENTER")
	else
		frame:SetPoint("CENTER")
	end
	self:RefreshFrame()
	frame:Show()
end

function IconSelector:FormatIcon(iconRef, size)
	return FormatIcon(iconRef, size)
end

function BFL.ShowIconSelector(owner, initialIcon, callback, options)
	return IconSelector:Show(owner, initialIcon, callback, options)
end

function BFL.FormatIcon(iconRef, size)
	return FormatIcon(iconRef, size)
end

