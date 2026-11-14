local _, BFL = ...
local Flags = BFL:RegisterModule("SettingsNewFlags", {})

-- Stable option IDs and introduction revisions; labels and positions are not IDs.
Flags.definitions = {
	fontWindowTitle = { route="windowFonts", section="SETTINGS_WINDOW_TITLE_FONT", key="SETTINGS_FONT" },
	fontSizeWindowTitle = { route="windowFonts", section="SETTINGS_WINDOW_TITLE_FONT", key="SETTINGS_FONT_SIZE_NUM" },
	fontActionButton = { route="windowFonts", section="SETTINGS_ACTION_BUTTON_FONT", key="SETTINGS_FONT" },
	fontSizeActionButton = { route="windowFonts", section="SETTINGS_ACTION_BUTTON_FONT", key="SETTINGS_FONT_SIZE_NUM" },
	enableSettingsSmoothScrolling = { route="layout", key="SETTINGS_WINDOW_SMOOTH_SCROLLING" },
	useThemedDialogs = { route="theme", key="SETTINGS_BFL_INPUT_DIALOGS" },
	hideThemeAvatar = { route="theme", key="SETTINGS_THEME_HIDE_AVATAR", themed=true },
	modernSideTabPosition = { route="friendTabs", key="SETTINGS_MODERN_TAB_POSITION", mainline=true },
}
local REVISION = "3.1.2"

function Flags:IsAvailable(definition, review)
	if definition.mainline and not BFL.IsMainline then return false end
	if definition.themed then
		local theme = BFL:GetEffectiveTheme()
		if theme ~= "dark" and theme ~= "custom" and theme ~= "elvui" and theme ~= "ellesmereui" then return false end
	end
	local page = BFL.LegacySettingsCatalog.pages[definition.route]
	local _, reason = review.settings:GetLegacyTabAvailability(page[1])
	return reason ~= "client"
end

function Flags:IsUnread(id)
	local state = BFL:GetModule("DB"):Get("settingsNewReadState")
	return type(state) ~= "table" or state[id] ~= (self.definitions[id].revision or REVISION)
end

function Flags:RouteUnread(route, review)
	for id, definition in pairs(self.definitions) do
		if definition.route == route and self:IsAvailable(definition, review) and self:IsUnread(id) then return true end
	end
	return false
end

function Flags:SetBadge(row, shown, padding)
	row.BFL_NewBadgeShown = shown == true
	local badge = row.BFL_NewBadge
	if not badge and not shown then return 0 end
	if not badge then
		badge = BFL:GetModule("NewFeatureBadge"):Create(row)
		row.BFL_NewBadge = badge
	end
	badge:SetPoint("RIGHT", row, "RIGHT", -(padding or 0), 0)
	badge:SetFrameLevel(row:GetFrameLevel() + 2)
	badge:SetShown(shown)
	return shown and 50 or 0
end

function Flags:NavigationBadge(row, text, unread)
	row.label:SetText(text)
	row.BFL_NewBadgeWidth = self:SetBadge(row, unread, 8)
	row.label:ClearAllPoints()
	row.label:SetPoint("LEFT", row.labelInset, 0)
	row.label:SetWidth(math.max(1, row:GetWidth() - row.labelInset - 8 - row.BFL_NewBadgeWidth))
end

function Flags:LayoutRowBadge(row)
	local inset = row.BFL_NewTrailingSpace or 0
	row.BFL_NewAnchorOffsets = row.BFL_NewAnchorOffsets or setmetatable({}, { __mode = "k" })
	local regions = {}
	for _, child in ipairs({ row:GetChildren() }) do
		if child:IsObjectType("Button") or child:IsObjectType("EditBox") or child:IsObjectType("Slider")
			or child == row.DropDown or child == row.Slider or child == row.Input then
			regions[#regions + 1] = child
		end
	end
	for _, region in ipairs({ row:GetRegions() }) do
		if region:IsObjectType("FontString") then regions[#regions + 1] = region end
	end
	for _, region in ipairs(regions) do
		if region ~= row.BFL_NewBadge then
			local offsets = row.BFL_NewAnchorOffsets[region] or {}
			row.BFL_NewAnchorOffsets[region] = offsets
			for index = 1, region:GetNumPoints() do
				local point, relative, relativePoint, x, y = region:GetPoint(index)
				if relative == row and relativePoint:find("RIGHT", 1, true) then
					local old = offsets[point]
					local original = old and x == old.shifted and y == old.y and old.original or x
					local shifted = original - inset
					if x ~= shifted then region:SetPoint(point, relative, relativePoint, shifted, y) end
					offsets[point] = { original = original, shifted = shifted, y = y }
				end
			end
		end
	end
end

function Flags:RefreshNavigation(review)
	local catalog = BFL.LegacySettingsCatalog
	for index, category in ipairs(catalog.categories) do
		local unread
		for page=3,#category do unread = unread or self:RouteUnread(category[page], review) end
		self:NavigationBadge(review.navButtons[index], BFL.L[category[2]] or category[2], unread)
	end
	for _, row in ipairs(review.subButtons) do
		if row.route then
			self:NavigationBadge(row, BFL.L[catalog.pages[row.route][2]], self:RouteUnread(row.route, review))
		end
	end
end

function Flags:RefreshRow(row)
	local unread = false
	for _, id in pairs(row.BFL_NewSettingIDs or {}) do
		unread = unread or self:IsUnread(id)
	end
	self:SetBadge(row, unread)
	-- Reserve one common form column on pages with new options. Controls stay
	-- aligned with their neighbours and do not jump when a badge is read.
	row.BFL_NewTrailingSpace = row.BFL_ReserveNewColumn and 50 or 0
	if not row.BFL_NewBadge and row.BFL_NewTrailingSpace == 0 then
		if row.BFL_NewLayoutBound then self:LayoutRowBadge(row) end
		return
	end
	if not row.BFL_NewLayoutBound then
		row.BFL_NewLayoutBound = true
		local layout = row:GetScript("OnSizeChanged")
		-- This is a BFL component row. Restore its original anchors before its
		-- own layout runs, then reserve the column once; repeated resizing must
		-- not accumulate offsets or confuse changed dropdown/slider widths.
		row:SetScript("OnSizeChanged", function(frame, ...)
			local inset = frame.BFL_NewTrailingSpace
			frame.BFL_NewTrailingSpace = 0
			self:LayoutRowBadge(frame)
			frame.BFL_NewTrailingSpace = inset
			if layout then layout(frame, ...) end
			self:LayoutRowBadge(frame)
		end)
	end
	self:LayoutRowBadge(row)
end

function Flags:BindRow(review, row, section)
	row.BFL_NewSettingIDs = nil
	row.BFL_ReserveNewColumn = false
	for _, definition in pairs(self.definitions) do
		if definition.route == review.route and not row:IsObjectType("Button")
			and not row.BFL_SettingsExactSlots and self:IsAvailable(definition, review) then
			row.BFL_ReserveNewColumn = true
			break
		end
	end
	for slot, entry in pairs(row.BFL_SettingGuide or {}) do
		for id, definition in pairs(self.definitions) do
			if definition.route == review.route and definition.key == entry[3]
					and (not definition.section or definition.section == section) and self:IsAvailable(definition, review) then
				row.BFL_NewSettingIDs = row.BFL_NewSettingIDs or {}
				row.BFL_NewSettingIDs[slot] = id
			end
		end
	end
	self:RefreshRow(row)
	self:EnsureListener(review)
end

function Flags:MarkRead(id, review)
	if not self.definitions[id] or not self:IsUnread(id) then return end
	local old = BFL:GetModule("DB"):Get("settingsNewReadState")
	local state = {}
	for key, value in pairs(type(old)=="table" and old or {}) do state[key]=value end
	state[id] = self.definitions[id].revision or REVISION
	BFL:GetModule("DB"):Set("settingsNewReadState", state)
	for _, row in ipairs(review.controlRows or {}) do self:RefreshRow(row) end
	self:RefreshNavigation(review)
end

function Flags:ResetCurrentReadState()
	local db = BFL:GetModule("DB")
	local old, state = db:Get("settingsNewReadState"), {}
	for id, revision in pairs(type(old) == "table" and old or {}) do
		local definition = self.definitions[id]
		if not definition or (definition.revision or REVISION) ~= REVISION then state[id] = revision end
	end
	db:Set("settingsNewReadState", state)
	self.press = nil
	local review = BFL:GetModule("LegacySettingsReview")
	if review and review.active then
		for _, row in ipairs(review.controlRows or {}) do self:RefreshRow(row) end
		self:RefreshNavigation(review)
	end
end

function Flags:HandleClick(review, event, button)
	if button ~= "LeftButton" or not review.active then return end
	if not review.guideRowsByFrame then self.press=nil;return end
	if event == "GLOBAL_MOUSE_DOWN" then
		self.press = nil
		local row = review:GetHoveredGuideRow()
		local slot = row and review:GetGuideSlot(row)
		local id = slot and row.BFL_NewSettingIDs and row.BFL_NewSettingIDs[slot]
		if id then
			local x,y=GetCursorPosition()
			self.press={id=id,x=x,y=y}
		end
	else
		local press=self.press;self.press=nil
		local x,y=GetCursorPosition()
		if press and math.abs(x-press.x)<=6 and math.abs(y-press.y)<=6 then self:MarkRead(press.id, review) end
	end
end

function Flags:EnsureListener(review)
	if self.listener then return end
	local frame=CreateFrame("Frame",nil,review.frame)
	self.listener=frame
	frame:SetScript("OnEvent",function(_,event,button) self:HandleClick(review,event,button) end)
	local function Register()
		BFL.Compat.RegisterEvent(frame,"GLOBAL_MOUSE_DOWN")
		BFL.Compat.RegisterEvent(frame,"GLOBAL_MOUSE_UP")
	end
	frame:SetScript("OnShow",Register)
	frame:SetScript("OnHide",function() frame:UnregisterAllEvents();self.press=nil end)
	Register()
end
