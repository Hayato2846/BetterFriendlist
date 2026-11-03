-- Local text queries only. Loading a query never dispatches a server request.
local ADDON_NAME, BFL = ...
local WhoSearches = BFL:RegisterModule("WhoSearches", {})
local MAX_PRESETS, MAX_HISTORY, MAX_QUERY_BYTES = 12, 32, 256

local function SafeQuery(value)
	if (BFL.IsSecret and BFL:IsSecret(value)) or type(value) ~= "string" then return nil end
	local query = value:match("^%s*(.-)%s*$")
	if query == "" or #query > MAX_QUERY_BYTES or query:find("[%c]") then return nil end
	return query
end

local function QueryLabel(query)
	local characters, width = {}, 0
	-- Bound menu width without splitting UTF-8. Wide glyphs count twice.
	for character in query:gmatch("[\1-\127\194-\244][\128-\191]*") do
		width = width + (#character > 1 and 2 or 1)
		if width > 48 then characters[#characters + 1] = "…"; break end
		characters[#characters + 1] = character
	end
	return (table.concat(characters):gsub("|", "||"))
end

function WhoSearches:GetEntries(key, limit)
	local db = BFL:GetModule("DB")
	local source = db and db:Get(key)
	local entries, seen = {}, {}
	if type(source) == "table" and not (BFL.IsSecret and BFL:IsSecret(source)) then
		for _, value in ipairs(source) do
			local query = SafeQuery(value)
			if query and not seen[query] then
				entries[#entries + 1], seen[query] = query, true
				if #entries >= limit then break end
			end
		end
	end
	return entries
end

function WhoSearches:Record(value)
	local query = SafeQuery(value)
	local db = BFL:GetModule("DB")
	if not query or not db or db:Get("whoSearchHistoryEnabled", true) ~= true then return false end
	local configuredMax = db:Get("whoSearchHistoryMax", 8)
	if BFL.IsSecret and BFL:IsSecret(configuredMax) then configuredMax = nil end
	local limit = tonumber(configuredMax) or 8
	if limit ~= limit then limit = 8 end
	limit = math.floor(math.max(1, math.min(MAX_HISTORY, limit)))
	local entries = self:GetEntries("whoSearchHistory", MAX_HISTORY)
	for i = #entries, 1, -1 do
		if entries[i] == query then table.remove(entries, i) end
	end
	table.insert(entries, 1, query)
	while #entries > limit do table.remove(entries) end
	db:Set("whoSearchHistory", entries)
	return true
end

function WhoSearches:Save(value)
	local query = SafeQuery(value)
	local db = BFL:GetModule("DB")
	if not query or not db then return false end
	local entries = self:GetEntries("whoSearchPresets", MAX_PRESETS)
	for _, entry in ipairs(entries) do if entry == query then return true end end
	if #entries >= MAX_PRESETS then return false end
	entries[#entries + 1] = query
	db:Set("whoSearchPresets", entries)
	return true
end

function WhoSearches:Remove(value)
	value = SafeQuery(value)
	local db = BFL:GetModule("DB")
	if not db or not value then return false end
	local entries = self:GetEntries("whoSearchPresets", MAX_PRESETS)
	for i = #entries, 1, -1 do if entries[i] == value then table.remove(entries, i) end end
	db:Set("whoSearchPresets", entries)
end

function WhoSearches:Load(editBox, value)
	local query = SafeQuery(value)
	if not editBox or not query then return false end
	editBox:SetText(query)
	local who = BFL:GetModule("WhoFrame")
	if who and who.builder then who:ApplyQueryToBuilder(query) end
	-- Focus stays with the menu. The user explicitly presses Search or Enter.
	return true
end

function WhoSearches:GetCurrentQuery(editBox)
	local who = BFL:GetModule("WhoFrame")
	if who and who.builderFlyout and who.builderFlyout:IsShown() then
		return SafeQuery(who:ComposeBuilderQuery())
	end
	return SafeQuery(editBox:GetText())
end

function WhoSearches:OpenMenu(owner, editBox)
	local L, db = BFL.L, BFL:GetModule("DB")
	if not db then return end
	local presets = self:GetEntries("whoSearchPresets", MAX_PRESETS)
	local currentQuery = self:GetCurrentQuery(editBox)
	local items = {
		{ type = "title", text = L.WHO_SAVED_SEARCHES },
		{ text = L.WHO_SAVE_SEARCH, disabled = not currentQuery or #presets >= MAX_PRESETS,
			func = function() self:Save(currentQuery) end },
	}
	for _, value in ipairs(presets) do
		local query = value
		items[#items + 1] = { text = QueryLabel(query), tooltip = query:gsub("|", "||"), tooltipIsWarning = false, children = {
			{ text = L.WHO_LOAD_SEARCH, func = function() self:Load(editBox, query) end },
			{ text = L.WHO_REMOVE_SEARCH, destructive = true, func = function() self:Remove(query) end },
		} }
	end
	items[#items + 1] = { type = "divider" }
	items[#items + 1] = { type = "title", text = L.WHO_RECENT_SEARCHES }
	items[#items + 1] = { type = "checkbox", text = L.WHO_HISTORY_ENABLED,
		checked = function() return db:Get("whoSearchHistoryEnabled", true) == true end,
		func = function()
			local enabled = db:Get("whoSearchHistoryEnabled", true) ~= true
			db:Set("whoSearchHistoryEnabled", enabled)
			if not enabled then db:Set("whoSearchHistory", {}) end
		end }
	if db:Get("whoSearchHistoryEnabled", true) == true then
		for _, value in ipairs(self:GetEntries("whoSearchHistory", MAX_HISTORY)) do
			local query = value
			items[#items + 1] = { text = QueryLabel(query), tooltip = query:gsub("|", "||"), tooltipIsWarning = false,
				func = function() self:Load(editBox, query) end }
		end
	end
	items[#items + 1] = { text = L.WHO_CLEAR_HISTORY, destructive = true,
		func = function() db:Set("whoSearchHistory", {}) end }
	BFL.OpenSimpleContextMenu(owner, "BFLWhoSearchesMenu", items)
end

function WhoSearches:AttachButton(editBox, builderToggle)
	local button = editBox.BFL_SearchesButton
	if not button then
		button = CreateFrame("Button", nil, editBox)
		button.BFL_DarkNoButtonChrome = true
		button:SetSize(16, 16)
		local icon = button:CreateTexture(nil, "ARTWORK")
		icon:SetTexture("Interface\\AddOns\\BetterFriendlist\\Icons\\star")
		icon:SetSize(12, 12)
		icon:SetPoint("CENTER")
		button:SetScript("OnClick", function() self:OpenMenu(button, editBox) end)
		button:SetScript("OnEnter", function()
			BFL_Tooltip:SetOwner(button, "ANCHOR_RIGHT")
			BFL_Tooltip:AddLine(BFL.L.WHO_SAVED_SEARCHES)
			BFL_Tooltip:Show()
		end)
		button:SetScript("OnLeave", function() BFL_Tooltip:Hide() end)
		editBox.BFL_SearchesButton = button
	end
	button:ClearAllPoints()
	button:SetPoint("RIGHT", builderToggle, "LEFT", -3, 0)
	button:SetFrameLevel(builderToggle:GetFrameLevel())
	local left, _, top, bottom = editBox:GetTextInsets()
	editBox:SetTextInsets(left, 58, top, bottom)
	button:Show()
end
