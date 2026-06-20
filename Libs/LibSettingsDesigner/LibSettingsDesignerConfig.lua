-- LibSettingsDesigner
-- License: https://raw.githubusercontent.com/R41z0r/LibSettingsDesigner/main/LICENSE.md
-- Do not remove this notice from redistributed copies.

local addonName, addon = ...
addon = addon or _G[addonName] or {}
addon.LibSettingsDesigner = addon.LibSettingsDesigner or {}

local MINOR = 1
local lib = addon.LibSettingsDesigner.Config or {}
addon.LibSettingsDesigner.Config = lib
lib.MINOR = MINOR

local apps = lib.apps or {}
lib.apps = apps

local function wipeTable(tbl)
	if not tbl then
		return {}
	end
	for key in pairs(tbl) do
		tbl[key] = nil
	end
	return tbl
end

local function copyTable(source, target)
	target = target or {}
	if type(source) ~= "table" then
		return target
	end
	for key, value in pairs(source) do
		target[key] = value
	end
	return target
end

local function cloneValue(value, depth)
	if type(value) ~= "table" then
		return value
	end
	depth = (depth or 0) + 1
	if depth > 5 then
		return copyTable(value)
	end
	local clone = {}
	for key, child in pairs(value) do
		clone[key] = cloneValue(child, depth)
	end
	return clone
end

local function normalizeID(text)
	text = tostring(text or ""):lower()
	text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
	text = text:gsub("[^%w]+", ".")
	text = text:gsub("^%.+", ""):gsub("%.+$", "")
	text = text:gsub("%.+", ".")
	if text == "" then
		text = "settings"
	end
	return text
end

local function normalizeSearchText(text)
	text = tostring(text or ""):lower()
	text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
	text = text:gsub("[^%w]+", " ")
	text = text:gsub("^%s+", ""):gsub("%s+$", "")
	return text
end

local colorValuesEqual

local function valuesEqual(a, b, depth)
	depth = (depth or 0) + 1
	if depth > 5 then
		return a == b
	end
	if a == b then
		return true
	end
	if type(a) == "number" and type(b) == "number" then
		return math.abs(a - b) <= 0.000001
	end
	if type(a) ~= type(b) then
		return false
	end
	if type(a) ~= "table" then
		return false
	end
	if colorValuesEqual and colorValuesEqual(a, b) then
		return true
	end
	for key, value in pairs(a) do
		if not valuesEqual(value, b[key], depth) then
			return false
		end
	end
	for key in pairs(b) do
		if a[key] == nil then
			return false
		end
	end
	return true
end

function colorValuesEqual(a, b)
	if type(a) ~= "table" or type(b) ~= "table" then
		return false
	end
	if type(a.r) ~= "number" or type(a.g) ~= "number" or type(a.b) ~= "number" then
		return false
	end
	if type(b.r) ~= "number" or type(b.g) ~= "number" or type(b.b) ~= "number" then
		return false
	end
	local alphaA = type(a.a) == "number" and a.a or 1
	local alphaB = type(b.a) == "number" and b.a or 1
	return valuesEqual(a.r, b.r) and valuesEqual(a.g, b.g) and valuesEqual(a.b, b.b) and valuesEqual(alphaA, alphaB)
end

local function resolveControlDefault(control)
	if not control then
		return nil, false
	end
	if control.default ~= nil then
		if type(control.default) == "function" then
			local ok, value = pcall(control.default)
			if ok and value ~= nil then
				return value, true
			end
			return nil, false
		end
		return control.default, true
	end
	if type(control.dbDefault) == "function" then
		local ok, value, hasDefault = pcall(control.dbDefault, control)
		if ok and (hasDefault == true or value ~= nil) then
			return value, true
		end
	elseif control.dbDefault ~= nil then
		return control.dbDefault, true
	end
	if control.setting then
		local methods = { "GetDefaultValue", "GetDefault" }
		for _, method in ipairs(methods) do
			if type(control.setting[method]) == "function" then
				local ok, value = pcall(control.setting[method], control.setting)
				if ok then
					return value, true
				end
			end
		end
	end
	return nil, false
end

local function getCategoryKey(category)
	if not category then
		return nil
	end
	if type(category) == "table" then
		if category.GetID then
			local ok, id = pcall(category.GetID, category)
			if ok and id ~= nil then
				return "id:" .. tostring(id)
			end
		end
		if category.GetName then
			local ok, name = pcall(category.GetName, category)
			if ok and name ~= nil then
				return "name:" .. tostring(name)
			end
		end
	end
	return tostring(category)
end

local function addSearchBlob(parts, value)
	if value == nil or value == false then
		return
	end
	if type(value) == "table" then
		for _, entry in ipairs(value) do
			addSearchBlob(parts, entry)
		end
		return
	end
	parts[#parts + 1] = normalizeSearchText(value)
end

local AppMixin = {}

function AppMixin:IsPageVisible(page)
	if type(page) == "string" then
		page = self.pagesByID[page]
	end
	if not page or page.hidden == true or page.visible == false then
		return false
	end
	if type(page.hiddenWhen) == "function" then
		local ok, hidden = pcall(page.hiddenWhen, page, self)
		if ok and hidden == true then
			return false
		end
	end
	local visibleFunc = type(page.isVisible) == "function" and page.isVisible
		or type(page.visibleWhen) == "function" and page.visibleWhen
		or type(page.visible) == "function" and page.visible
	if visibleFunc then
		local ok, visible = pcall(visibleFunc, page, self)
		if not ok or visible == false then
			return false
		end
	end
	return true
end

function AppMixin:IsControlVisible(control)
	if type(control) == "string" then
		control = self.controlsByID[control]
	end
	if not control or control.hidden == true or control.visible == false then
		return false
	end
	local page = control.pageID and self.pagesByID[control.pageID]
	if not self:IsPageVisible(page) then
		return false
	end
	if type(control.hiddenWhen) == "function" then
		local ok, hidden = pcall(control.hiddenWhen, control, self)
		if ok and hidden == true then
			return false
		end
	end
	local visibleFunc = type(control.isVisible) == "function" and control.isVisible
		or type(control.visibleWhen) == "function" and control.visibleWhen
		or type(control.visible) == "function" and control.visible
	if visibleFunc then
		local ok, visible = pcall(visibleFunc, control, self)
		if not ok or visible == false then
			return false
		end
	end
	return true
end

local LEGACY_CONTROL_METADATA_FIELDS = {
	"buttonText",
	"bindingIndex",
	"callback",
	"clampToRange",
	"clearColor",
	"colorizeLabel",
	"customDefaultText",
	"customText",
	"addEntry",
	"addButtonText",
	"addPopupText",
	"addPopupTitle",
	"emptyText",
	"dropdownDefault",
	"dropdownDesc",
	"dropdownFormatter",
	"dropdownGet",
	"dropdownKey",
	"dropdownList",
	"dropdownListFunc",
	"dropdownName",
	"dropdownOptionfunc",
	"dropdownOptions",
	"dropdownOrder",
	"dropdownSet",
	"dropdownSetting",
	"dropdownSuffix",
	"dropdownText",
	"dropdownValueFormatter",
	"dropdownValues",
	"entries",
	"formatter",
	"formatOptions",
	"formatOrder",
	"formatEntryLabel",
	"frameHeight",
	"frameWidth",
	"generator",
	"getColor",
	"getDefaultColor",
	"getHeight",
	"getPlaybackChannel",
	"getEntries",
	"getSelection",
	"getInheritedColor",
	"hasOverride",
	"groupID",
	"groupTitle",
	"hasOpacity",
	"height",
	"hidden",
	"hiddenWhen",
	"hideSummary",
	"inputWidth",
	"isMainToggle",
	"isSelected",
	"isSelectedFunc",
	"isVisible",
	"justifyH",
	"list",
	"listFunc",
	"max",
	"maxChars",
	"menuHeight",
	"min",
	"modernGroup",
	"multiline",
	"multilineHeight",
	"newTagID",
	"note",
	"notes",
	"numeric",
	"onClick",
	"optionfunc",
	"options",
	"placeholder",
	"placeholderText",
	"playbackChannel",
	"previewSoundFunc",
	"previewTooltip",
	"readOnly",
	"reloadRequired",
	"reloadReason",
	"requiresReload",
	"requiresUIReload",
	"refreshOnChange",
	"release",
	"removeEntry",
	"render",
	"moveEntry",
	"orderList",
	"rowHeight",
	"rowActions",
	"richNote",
	"richNotes",
	"setColor",
	"setEntryFormat",
	"setSelected",
	"setSelectedFunc",
	"setSelection",
	"showAddButton",
	"showEntryID",
	"showRemoveButton",
	"selectionSource",
	"soundResolver",
	"step",
	"subvar",
	"suffix",
	"summary",
	"tooltip",
	"uiRole",
	"valueFormatter",
	"values",
	"visible",
	"visibleWhen",
	"entryToggle",
}

local function sortByOrderAndTitle(a, b)
	local ao = tonumber(a.order) or 1000
	local bo = tonumber(b.order) or 1000
	if ao ~= bo then
		return ao < bo
	end
	return tostring(a.title or a.id) < tostring(b.title or b.id)
end

local function rebuildSearchBlob(app, control)
	local parts = {}
	local page = app.pagesByID[control.pageID or ""]
	local group = page and page.groupsByID and page.groupsByID[control.groupID or ""]
	local category = page and app.categoriesByID[page.category or ""]
	addSearchBlob(parts, control.label or control.title or control.text or control.id)
	addSearchBlob(parts, control.description or control.desc)
	addSearchBlob(parts, control.key or control.settingKey)
	addSearchBlob(parts, control.keywords or control.searchtags)
	addSearchBlob(parts, page and page.title)
	addSearchBlob(parts, group and group.title)
	addSearchBlob(parts, category and category.title)
	local notes = control.notes
	if type(notes) == "string" then
		notes = { { text = notes } }
	elseif type(notes) ~= "table" then
		notes = {}
	end
	for _, note in ipairs(notes) do
		addSearchBlob(parts, note.title)
		addSearchBlob(parts, note.text)
		for _, block in ipairs(note.blocks or {}) do
			addSearchBlob(parts, type(block) == "table" and (block.title or block.text) or block)
		end
	end
	control.searchBlob = table.concat(parts, " ")
end

local function buildSearchEntryBlob(app, page, entry)
	local parts = {}
	local category = page and app.categoriesByID[page.category or ""]
	addSearchBlob(parts, entry.label or entry.title or entry.text or entry.id)
	addSearchBlob(parts, entry.description or entry.desc)
	addSearchBlob(parts, entry.keywords or entry.searchtags)
	addSearchBlob(parts, entry.focusID or entry.focusId)
	addSearchBlob(parts, page and page.title)
	addSearchBlob(parts, category and category.title)
	return table.concat(parts, " ")
end

local function rebuildPageSearchEntries(app, page)
	page._searchEntries = {}
	if type(page.searchEntries) ~= "table" then
		return
	end
	for index, entry in ipairs(page.searchEntries) do
		if type(entry) == "table" then
			local id = entry.id or entry.key or (page.id .. ".search." .. tostring(index))
			local result = copyTable(entry, {
				id = id,
				pageID = page.id,
				_pageResult = true,
				_searchEntry = true,
			})
			result.focusID = result.focusID or result.focusId or result.controlID or result.controlId
			result.label = result.label or result.title or result.text or id
			result.searchBlob = buildSearchEntryBlob(app, page, result)
			page._searchEntries[#page._searchEntries + 1] = result
		end
	end
end

local function noteHasContent(note)
	if type(note.text) == "string" and note.text:gsub("%s+", "") ~= "" then
		return true
	end
	if type(note.blocks) == "table" then
		for _, block in ipairs(note.blocks) do
			if type(block) == "string" and block:gsub("%s+", "") ~= "" then
				return true
			end
			if type(block) == "table" and ((type(block.text) == "string" and block.text:gsub("%s+", "") ~= "") or block.image or block.texture) then
				return true
			end
		end
	end
	return false
end

function AppMixin:RegisterCategory(data)
	if type(data) ~= "table" or not data.id then
		return nil
	end
	local category = self.categoriesByID[data.id]
	if category then
		copyTable(data, category)
	else
		category = copyTable(data, {})
		self.categoriesByID[category.id] = category
		self.categories[#self.categories + 1] = category
	end
	table.sort(self.categories, sortByOrderAndTitle)
	return category
end

function AppMixin:RegisterPage(data)
	if type(data) ~= "table" or not data.id then
		return nil
	end
	local page = self.pagesByID[data.id]
	if page then
		copyTable(data, page)
	else
		page = copyTable(data, {})
		page.groups = page.groups or {}
		page.groupsByID = page.groupsByID or {}
		page.controls = page.controls or {}
		self.pagesByID[page.id] = page
		self.pages[#self.pages + 1] = page
	end
	if page.category and not self.categoriesByID[page.category] then
		self:RegisterCategory({ id = page.category, title = page.category, order = 1000 })
	end
	table.sort(self.pages, sortByOrderAndTitle)
	rebuildPageSearchEntries(self, page)
	return page
end

function AppMixin:RegisterGroup(pageID, data)
	local page = self.pagesByID[pageID]
	if not page or type(data) ~= "table" then
		return nil
	end
	local id = data.id or normalizeID(data.title or data.name or "group")
	local group = page.groupsByID[id]
	if group then
		copyTable(data, group)
	else
		group = copyTable(data, { id = id, pageID = pageID })
		page.groupsByID[id] = group
		page.groups[#page.groups + 1] = group
	end
	table.sort(page.groups, sortByOrderAndTitle)
	return group
end

function AppMixin:RegisterPageNote(pageID, data)
	local page = self.pagesByID[pageID]
	if not page then
		return nil
	end
	local note
	if type(data) == "table" then
		note = copyTable(data, {})
	else
		note = { text = data }
	end
	if not noteHasContent(note) then
		return nil
	end
	page.aboutNotes = page.aboutNotes or {}
	for _, existing in ipairs(page.aboutNotes) do
		if existing.text == note.text then
			return existing
		end
	end
	page.aboutNotes[#page.aboutNotes + 1] = note
	table.sort(page.aboutNotes, sortByOrderAndTitle)
	return note
end

function AppMixin:RegisterControlNote(controlID, data)
	local control = self.controlsByID[controlID]
	if not control then
		return nil
	end
	local note
	if type(data) == "table" then
		note = copyTable(data, {})
	else
		note = { text = data }
	end
	if not noteHasContent(note) then
		return nil
	end
	control.notes = control.notes or {}
	for _, existing in ipairs(control.notes) do
		if existing.text == note.text then
			return existing
		end
	end
	control.notes[#control.notes + 1] = note
	table.sort(control.notes, sortByOrderAndTitle)
	rebuildSearchBlob(self, control)
	return note
end

function AppMixin:RegisterControl(pageID, data)
	local page = self.pagesByID[pageID]
	if not page or type(data) ~= "table" then
		return nil
	end
	local id = data.id or data.key or data.var
	if not id or id == "" then
		id = pageID .. "." .. tostring(#self.controls + 1)
	end
	local control = self.controlsByID[id]
	if control then
		copyTable(data, control)
	else
		control = copyTable(data, { id = id })
		self.controlsByID[id] = control
		self.controls[#self.controls + 1] = control
		page.controls[#page.controls + 1] = control
	end
	control.pageID = pageID
	if control.groupID then
		self:RegisterGroup(pageID, { id = control.groupID, title = control.groupTitle or control.groupID })
	end
	rebuildSearchBlob(self, control)
	table.sort(page.controls, sortByOrderAndTitle)
	return control
end

function AppMixin:RegisterLegacyCategory(category, data)
	local key = getCategoryKey(category)
	if not key then
		return nil
	end
	data = data or {}
	local categoryID = data.categoryID or data.modernCategory or normalizeID(data.title or data.name or key)
	self.legacyCategories[key] = categoryID
	if data.title and not self.categoriesByID[categoryID] then
		self:RegisterCategory({
			id = categoryID,
			title = data.title,
			iconAtlas = data.iconAtlas,
			order = data.order,
		})
	end
	return categoryID
end

function AppMixin:RegisterLegacySection(section, data)
	if not section then
		return nil
	end
	data = data or {}
	local categoryID = data.categoryID
	if not categoryID then
		categoryID = self.legacyCategories[getCategoryKey(data.category)] or "advanced"
	end
	local stablePageName = data.pageKey or data.newTagID or data.var or data.key or data.title or data.name or "settings"
	local pageID = data.pageID or (categoryID .. "." .. normalizeID(stablePageName))
	local page = self:RegisterPage({
		id = pageID,
		category = categoryID,
		title = data.title or data.name or pageID,
		description = data.description,
		pageKey = data.pageKey,
		iconAtlas = data.iconAtlas,
		icon = data.icon,
		iconKey = data.iconKey,
		mainToggleID = data.mainToggleID,
		newTagID = data.newTagID,
		visible = data.visible,
		isVisible = data.isVisible,
		visibleWhen = data.visibleWhen,
		hiddenWhen = data.hiddenWhen,
		order = data.order or 500,
		legacy = true,
	})
	self.legacySections[section] = pageID
	return page and page.id
end

function AppMixin:RegisterLegacyControl(data)
	if type(data) ~= "table" then
		return nil
	end
	local pageID = data.pageID
	if not pageID and data.parentSection then
		pageID = self.legacySections[data.parentSection]
	end
	if not pageID and data.legacyCategory then
		local categoryID = self.legacyCategories[getCategoryKey(data.legacyCategory)] or "advanced"
		pageID = categoryID .. ".settings"
		self:RegisterPage({
			id = pageID,
			category = categoryID,
			title = data.legacyCategoryTitle or "Settings",
			order = 900,
			legacy = true,
		})
	end
	if not pageID then
		pageID = self.defaultPageID or "dashboard"
	end
	if not self.pagesByID[pageID] then
		self:RegisterPage({
			id = pageID,
			category = "advanced",
			title = pageID,
			order = 900,
			legacy = true,
		})
	end

	local control = {
		id = data.id or data.key or data.var,
		type = data.type or data.sType,
		label = data.label or data.text or data.name or data.key or data.var,
		description = data.description or data.desc,
		key = data.key or data.var,
		default = data.default,
		dbDefault = data.dbDefault,
		keywords = data.keywords or data.searchtags,
		level = data.level or "basic",
		order = data.order,
		setting = data.setting,
		getValue = data.getValue or data.get,
		setValue = data.setValue or data.set,
		parentCheck = data.parentCheck,
		isEnabled = data.isEnabled,
		legacy = true,
	}
	for _, field in ipairs(LEGACY_CONTROL_METADATA_FIELDS) do
		if data[field] ~= nil then
			control[field] = data[field]
		end
	end
	if control.modernGroup and not control.groupID then
		control.groupID = control.modernGroup
	end
	if not control.id or control.id == "" then
		control.id = pageID .. "." .. tostring(#self.controls + 1)
	end
	return self:RegisterControl(pageID, control)
end

function AppMixin:GetCategories()
	table.sort(self.categories, sortByOrderAndTitle)
	return self.categories
end

function AppMixin:GetPages(categoryID)
	local pages = wipeTable(self._tmpPages)
	for _, page in ipairs(self.pages) do
		if self:IsPageVisible(page) and (not categoryID or page.category == categoryID) then
			pages[#pages + 1] = page
		end
	end
	table.sort(pages, sortByOrderAndTitle)
	return pages
end

function AppMixin:GetPageControls(pageOrID)
	local page = type(pageOrID) == "string" and self.pagesByID[pageOrID] or pageOrID
	local controls = wipeTable(self._tmpControls)
	self._tmpControls = controls
	if not page then
		return controls
	end
	for _, control in ipairs(page.controls or {}) do
		if self:IsControlVisible(control) then
			controls[#controls + 1] = control
		end
	end
	table.sort(controls, sortByOrderAndTitle)
	return controls
end

local function normalizeCount(value)
	local count = tonumber(value)
	if not count then
		return nil
	end
	return math.max(0, math.floor(count))
end

local function resolvePageCount(app, page, resolverNames, valueNames)
	if type(page) ~= "table" then
		return nil
	end
	for _, name in ipairs(resolverNames or {}) do
		local resolver = page[name]
		if type(resolver) == "function" then
			local ok, value = pcall(resolver, app, page)
			local count = ok and normalizeCount(value)
			if count ~= nil then
				return count
			end
		end
	end
	for _, name in ipairs(valueNames or {}) do
		local count = normalizeCount(page[name])
		if count ~= nil then
			return count
		end
	end
	return nil
end

function AppMixin:GetPageSettingCount(pageOrID)
	local page = type(pageOrID) == "string" and self.pagesByID[pageOrID] or pageOrID
	if not page or not self:IsPageVisible(page) then
		return 0
	end
	local explicitCount = resolvePageCount(self, page, {
		"getSettingCount",
		"getSettingsCount",
		"getControlCount",
	}, {
		"settingCount",
		"settingsCount",
		"controlCount",
	})
	if explicitCount ~= nil then
		return explicitCount
	end
	return #self:GetPageControls(page)
end

function AppMixin:GetPageCustomizedCount(pageOrID)
	local page = type(pageOrID) == "string" and self.pagesByID[pageOrID] or pageOrID
	if not page or not self:IsPageVisible(page) then
		return 0
	end
	local explicitCount = resolvePageCount(self, page, {
		"getCustomizedCount",
		"getChangedCount",
	}, {
		"customizedCount",
		"changedCount",
	})
	if explicitCount ~= nil then
		return explicitCount
	end
	local count = 0
	for _, control in ipairs(page.controls or {}) do
		if self:IsControlVisible(control) and self:IsControlCustomized(control) then
			count = count + 1
		end
	end
	return count
end

function AppMixin:GetCategoryCustomizedCount(categoryID)
	if not categoryID then
		return 0
	end
	local count = 0
	for _, page in ipairs(self.pages) do
		if page.category == categoryID and self:IsPageVisible(page) then
			count = count + self:GetPageCustomizedCount(page)
		end
	end
	return count
end

function AppMixin:GetPage(pageID)
	return self.pagesByID[pageID]
end

function AppMixin:GetDefaultPageID()
	return self.defaultPageID or (self.pages[1] and self.pages[1].id)
end

function AppMixin:SetDefaultPage(pageID)
	self.defaultPageID = pageID
end

local function notifyReloadPendingChanged(app)
	local ui = addon.LibSettingsDesigner and addon.LibSettingsDesigner.UI
	if ui and type(ui.RefreshTopbarForApp) == "function" then
		ui.RefreshTopbarForApp(app)
	end
end

function AppMixin:IsReloadPending()
	if self.opts and type(self.opts.getReloadPending) == "function" then
		local ok, pending = pcall(self.opts.getReloadPending, self)
		if ok then
			return pending == true
		end
	end
	return self.reloadPending == true
end

function AppMixin:GetReloadPendingReason()
	if self.opts and type(self.opts.getReloadPendingReason) == "function" then
		local ok, reason = pcall(self.opts.getReloadPendingReason, self)
		if ok and reason ~= nil then
			return reason
		end
	end
	return self.reloadPendingReason
end

function AppMixin:SetReloadPending(pending, reason, control)
	pending = pending == true
	self.reloadPending = pending
	self.reloadPendingReason = pending and reason or nil
	self.reloadPendingControlID = pending and control and control.id or nil
	if self.opts and type(self.opts.setReloadPending) == "function" then
		pcall(self.opts.setReloadPending, pending, reason, control, self)
	end
	notifyReloadPendingChanged(self)
	return pending
end

function AppMixin:MarkReloadPending(reason, control)
	return self:SetReloadPending(true, reason, control)
end

function AppMixin:ClearReloadPending()
	return self:SetReloadPending(false)
end

function AppMixin:GetControlValue(control)
	if control.setting and control.setting.GetValue then
		local ok, value = pcall(control.setting.GetValue, control.setting)
		if ok then
			return value
		end
	end
	if type(control.getSelection) == "function" then
		local ok, value = pcall(control.getSelection, control)
		if ok then
			return value
		end
		ok, value = pcall(control.getSelection)
		if ok then
			return value
		end
	end
	if type(control.getValue) == "function" then
		local ok, value = pcall(control.getValue)
		if ok then
			return value
		end
	end
	local db = self.opts and self.opts.db and self.opts.db()
	if type(db) == "table" and control.key ~= nil then
		return db[control.key]
	end
	return control.default
end

function AppMixin.GetControlDefault(_, control)
	local default, hasDefault = resolveControlDefault(control)
	if not hasDefault then
		return nil, false
	end
	return cloneValue(default), true
end

local function getEffectiveControlValue(app, control, default, hasDefault)
	local value = app:GetControlValue(control)
	if value == nil and hasDefault then
		return default
	end
	return value
end

local function getStoredControlValue(app, control)
	local db = app and app.opts and app.opts.db and app.opts.db()
	if type(db) == "table" and control and control.key ~= nil and db[control.key] ~= nil then
		if control.subvar and type(db[control.key]) == "table" then
			return db[control.key][control.subvar], db[control.key][control.subvar] ~= nil
		end
		return db[control.key], true
	end
	return nil, false
end

function AppMixin:SetControlValue(control, value)
	local function finish(success)
		if success and control and (control.requiresReload == true or control.reloadRequired == true or control.requiresUIReload == true) then
			self:MarkReloadPending(control.reloadReason or control.label or control.title or control.id, control)
		end
		return success == true
	end
	if control.setting and control.setting.SetValue then
		local ok = pcall(control.setting.SetValue, control.setting, value)
		if ok then
			return finish(true)
		end
	end
	if type(control.setSelection) == "function" then
		local ok = pcall(control.setSelection, value, control)
		if ok then
			return finish(true)
		end
		ok = pcall(control.setSelection, value)
		if ok then
			return finish(true)
		end
	end
	if type(control.setValue) == "function" then
		local ok = pcall(control.setValue, value)
		if ok then
			return finish(true)
		end
		ok = pcall(control.setValue, nil, value)
		return finish(ok == true)
	end
	local db = self.opts and self.opts.db and self.opts.db()
	if type(db) == "table" and control.key ~= nil then
		db[control.key] = value
		return finish(true)
	end
	return finish(false)
end

function AppMixin:IsControlEnabled(control)
	local _ = self
	if type(control.isEnabled) == "function" then
		local ok, enabled = pcall(control.isEnabled)
		if ok and enabled == false then
			return false
		end
	end
	if type(control.parentCheck) == "function" then
		local ok, enabled = pcall(control.parentCheck)
		if ok and enabled == false then
			return false
		end
	end
	return true
end

function AppMixin:IsNewTagActive(tagID)
	local resolver = self.opts and self.opts.isNewTag
	if type(resolver) ~= "function" or not tagID then
		return false
	end
	local ok, result = pcall(resolver, tagID)
	return ok and result == true
end

function AppMixin:IsPageNew(page)
	if not page then
		return false
	end
	return self:IsNewTagActive(page.newTagID)
		or self:IsNewTagActive(page.id)
		or self:IsNewTagActive(page.pageKey)
		or self:IsNewTagActive(page.key)
end

function AppMixin:IsControlNew(control)
	if not control then
		return false
	end
	return self:IsNewTagActive(control.newTagID)
		or self:IsNewTagActive(control.id)
		or self:IsNewTagActive(control.key)
end

function AppMixin:GetSearchResults(query, limit)
	local rawQuery = tostring(query or "")
	local newOnly = false
	local terms = {}
	for term in rawQuery:gmatch("%S+") do
		local normalized = normalizeSearchText(term)
		if term:lower() == "tag:new" or normalized == "tag new" or normalized == "tag.new" then
			newOnly = true
		elseif normalized ~= "" then
			terms[#terms + 1] = normalized
		end
	end
	local results = wipeTable(self._tmpSearch)
	if #terms == 0 and not newOnly then
		return results
	end
	for _, control in ipairs(self.controls) do
		if self:IsControlVisible(control) and (not newOnly or self:IsControlNew(control)) then
			local blob = control.searchBlob or ""
			local matched = true
			for _, term in ipairs(terms) do
				if not blob:find(term, 1, true) then
					matched = false
					break
				end
			end
			if matched then
				results[#results + 1] = control
				if limit and #results >= limit then
					break
				end
			end
		end
	end
	for _, page in ipairs(self.pages) do
		if self:IsPageVisible(page) then
			for _, entry in ipairs(page._searchEntries or {}) do
				local entryIsNew = self:IsPageNew(page)
					or self:IsNewTagActive(entry.newTagID)
					or self:IsNewTagActive(entry.id)
				if not newOnly or entryIsNew then
					local blob = entry.searchBlob or ""
					local matched = true
					for _, term in ipairs(terms) do
						if not blob:find(term, 1, true) then
							matched = false
							break
						end
					end
					if matched then
						results[#results + 1] = entry
						if limit and #results >= limit then
							return results
						end
					end
				end
			end
		end
	end
	return results
end

function AppMixin:IsControlCustomized(control)
	if not control or control.trackCustomized == false then
		return false
	end
	if control.type == "button" or control.type == "keybind" then
		return false
	end
	if not self:IsControlEnabled(control) then
		return false
	end
	local default, hasDefault = resolveControlDefault(control)
	if not hasDefault then
		return false
	end
	local storedValue, hasStoredValue = getStoredControlValue(self, control)
	if control and control.key ~= nil and not hasStoredValue then
		return false
	end
	if hasStoredValue then
		if control and control.type == "colorpicker" and colorValuesEqual(storedValue, default) then
			return false
		end
		return not valuesEqual(storedValue, default)
	end
	local value = getEffectiveControlValue(self, control, default, hasDefault)
	return not valuesEqual(value, default)
end

function AppMixin:GetStats()
	local customized = 0
	local booleanTrue = 0
	local controlsWithDefaults = 0
	local newControls = 0
	local controls = 0
	local pages = 0
	for _, page in ipairs(self.pages) do
		if self:IsPageVisible(page) then
			pages = pages + 1
		end
	end
	for _, control in ipairs(self.controls) do
		if self:IsControlVisible(control) then
			controls = controls + 1
			local default, hasDefault = resolveControlDefault(control)
			if hasDefault then
				controlsWithDefaults = controlsWithDefaults + 1
				if self:IsControlCustomized(control) then
					customized = customized + 1
				end
			end
			if control.type == "toggle" or control.type == "checkbox" then
				if getEffectiveControlValue(self, control, default, hasDefault) == true then
					booleanTrue = booleanTrue + 1
				end
			end
			if self:IsControlNew(control) then
				newControls = newControls + 1
			end
		end
	end
	return {
		categories = #self.categories,
		pages = pages,
		controls = controls,
		newControls = newControls,
		customized = customized,
		customizable = controlsWithDefaults,
		booleanTrue = booleanTrue,
		enabled = customized,
	}
end

local function registerBlizzardSettingsBridge(app)
	if not (app and app.opts and app.opts.blizzardSettingsRoot == true) then
		return
	end
	if app.blizzardSettingsCategory then
		return
	end
	if not (Settings and Settings.RegisterVerticalLayoutCategory and Settings.RegisterAddOnCategory) then
		return
	end
	if not (_G.CreateSettingsButtonInitializer and _G.SettingsPanel and _G.SettingsPanel.GetLayout) then
		return
	end
	local title = app.opts.blizzardSettingsTitle or app.opts.title or app.id
	local ok, category = pcall(Settings.RegisterVerticalLayoutCategory, title)
	if not ok or not category then
		return
	end
	pcall(Settings.RegisterAddOnCategory, category)
	if category.SetShouldSortAlphabetically then
		pcall(category.SetShouldSortAlphabetically, category, false)
	end
	local layout = _G.SettingsPanel:GetLayout(category)
	if not layout or not layout.AddInitializer then
		return
	end
	local function openSettings()
		if type(app.opts.openSettings) == "function" then
			app.opts.openSettings(app)
		end
	end
	local locale = type(app.opts.locale) == "table" and app.opts.locale or nil
	local buttonText = app.opts.blizzardSettingsButtonText or app.opts.settingsButtonText
		or (locale and (locale.configCenterTitle or locale.configCenterSettings))
		or "Settings"
	local button = _G.CreateSettingsButtonInitializer(title, buttonText, openSettings, nil, false)
	layout:AddInitializer(button)
	app.blizzardSettingsCategory = category
end

function lib:RegisterAddOn(id, opts)
	local _ = self
	assert(id, "addon id required")
	local app = apps[id]
	if app then
		app.opts = opts or app.opts or {}
		registerBlizzardSettingsBridge(app)
		return app
	end
	app = {
		id = id,
		opts = opts or {},
		categories = {},
		categoriesByID = {},
		pages = {},
		pagesByID = {},
		controls = {},
		controlsByID = {},
		legacyCategories = {},
		legacySections = {},
		_tmpPages = {},
		_tmpControls = {},
		_tmpSearch = {},
	}
	for key, value in pairs(AppMixin) do
		app[key] = value
	end
	apps[id] = app
	registerBlizzardSettingsBridge(app)
	return app
end

function lib:GetAddOn(id)
	local _ = self
	return apps[id]
end

function lib:NormalizeID(text)
	local _ = self
	return normalizeID(text)
end
