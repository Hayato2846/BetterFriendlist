local ADDON_NAME, BFL = ...
local ScrollbarStyle = BFL:RegisterModule("ScrollbarStyle", {
	bars = setmetatable({}, { __mode = "k" }),
	widgets = setmetatable({}, { __mode = "k" }),
	retired = setmetatable({}, { __mode = "k" }),
})
local TEXTURES = { "Begin", "Middle", "End", "Texture", "Overlay" }

local function IsSecret(value)
	return BFL.IsSecret and BFL:IsSecret(value) or issecretvalue and issecretvalue(value) or false
end

local function CanRead(frame, allowProtected)
	if IsSecret(frame) or not frame then return false end
	local ok, allowed = pcall(function()
		for _, check in ipairs({ "CanBeAccessedInContext", "IsForbidden", "IsProtected" }) do
			if (check ~= "IsProtected" or not allowProtected) and type(frame[check]) == "function" then
				local value = frame[check](frame)
				if IsSecret(value) then return false end
				if check == "CanBeAccessedInContext" then
					if value ~= true then return false end
				elseif value then return false end
			end
		end
		return true
	end)
	return ok and allowed == true
end

function ScrollbarStyle:CanAccess(frame)
	return CanRead(frame, false)
end

function ScrollbarStyle:IsModern(bar)
	if not CanRead(bar, true) then return false end
	local ok, modern = pcall(function()
		return type(bar.GetThumb) == "function" and bar.Track ~= nil and bar.Back ~= nil and bar.Forward ~= nil
	end)
	return ok and modern == true
end

local function IsShared(frame)
	if frame == _G.FriendsFriendsFrame or frame == _G.WorldFrame then return true end
	for index = 1, STATICPOPUP_NUMDIALOGS or 4 do
		if frame == _G["StaticPopup" .. index] then return true end
	end
	-- Blizzard's pooled menu proxies expose these methods; names are not ownership.
	return type(frame.GetOwnerRegion) == "function" and type(frame.SetMenuDescription) == "function"
end

local function CheckChain(frame, owner)
	local foundOwner = owner == nil
	for _ = 1, 48 do
		if IsSecret(frame) then return "blocked" end
		if frame == UIParent then return foundOwner and "ok" or "lost" end
		if not frame then return "lost" end
		if not CanRead(frame, false) then return "blocked" end
		if IsShared(frame) then return "lost" end
		if frame == owner then foundOwner = true end
		frame = frame:GetParent()
	end
	return "lost"
end

local function Parts(bar)
	return { bar.Track, bar.Back, bar.Forward, bar:GetThumb() }
end

function ScrollbarStyle:CheckState(state)
	local ok, status = pcall(function()
		local result = CheckChain(state.bar, state.owner)
		if result ~= "ok" then return result end
		local parts = Parts(state.bar)
		for index, entry in ipairs(state.entries) do
			if IsSecret(parts[index]) then return "blocked" end
			if parts[index] ~= entry.widget then return "lost" end
		end
		return "ok"
	end)
	return ok and status or "blocked"
end

local function CheckWidget(entry)
	if not CanRead(entry.widget, false) then return "blocked" end
	if entry.widget:GetParent() ~= entry.parent then return "lost" end
	for _, item in ipairs(entry.textures) do
		if not CanRead(item.texture, false) then return "blocked" end
		if entry.widget[item.key] ~= item.texture or item.texture:GetParent() ~= entry.widget then return "lost" end
	end
	return "ok"
end

local function Restore(entry, onlyOurPaint)
	if CheckChain(entry.widget) ~= "ok" then return end
	local enabled = not entry.widget.IsEnabled or entry.widget:IsEnabled()
	for _, item in ipairs(entry.textures) do
		local texture = item.texture
		if CanRead(texture, false) and texture:GetParent() == entry.widget then
			local r, g, b, a = texture:GetVertexColor()
			local last = item.last
			if not onlyOurPaint or last and r == last[1] and g == last[2] and b == last[3] and a == last[4]
				and texture:IsDesaturated() == item.lastDesaturated then
				local color = item.color
				texture:SetVertexColor(color[1], color[2], color[3], color[4])
				local desaturated = item.desaturated
				if entry.widget.desaturateIfDisabled then desaturated = not enabled end
				texture:SetDesaturated(desaturated)
			end
		end
	end
end

function ScrollbarStyle:Retire(state)
	state.active = false
	self.bars[state.bar] = nil
	self.retired[state.bar] = true
	for _, entry in ipairs(state.entries) do
		self.widgets[entry.widget] = nil
		-- Cleanup never writes to protected, inaccessible or shared Blizzard trees.
		pcall(Restore, entry, true)
	end
end

function ScrollbarStyle:GetAccent()
	local theme = BFL:GetEffectiveTheme()
	if theme == "blizzard" then return end
	if theme == "elvui" then
		local skin = BFL:GetModule("ElvUISkin")
		local engine = skin and skin.ElvUIEngine or (BFL.GetElvUIEngine and BFL:GetElvUIEngine(true))
		local color = engine and engine.media and engine.media.rgbvaluecolor
		if color then return color[1], color[2], color[3] end
	end
	if theme == "dark" or theme == "custom" or theme == "ellesmereui" or theme == "elvui" then
		return BFL:GetThemeAccentColor()
	end
end

function ScrollbarStyle:Paint(entry)
	local ok, status = pcall(CheckWidget, entry)
	if not ok or status == "blocked" then return end
	if status ~= "ok" then self:Retire(entry.state); return end
	local widget = entry.widget
	local r, g, b = self:GetAccent()
	local enabled = not widget.IsEnabled or widget:IsEnabled()
	if not r then Restore(entry, false) end
	for _, item in ipairs(entry.textures) do
		local texture = item.texture
		if r then
			texture:SetDesaturated(true)
			texture:SetVertexColor(enabled and r or 1, enabled and g or 1, enabled and b or 1, item.color[4])
		end
		item.last = { texture:GetVertexColor() }
		item.lastDesaturated = texture:IsDesaturated()
	end
end

function ScrollbarStyle:RefreshWidget(widget)
	if IsSecret(widget) then return end
	local entry = self.widgets[widget]
	if not (entry and entry.state.active) then return end
	local status = self:CheckState(entry.state)
	if status == "lost" then self:Retire(entry.state)
	elseif status == "ok" then self:Paint(entry) end
end

-- Call only at BFL's own XML/Lua creation sites, never from a skin tree walk.
function ScrollbarStyle:Register(bar, owner)
	if not self:CanAccess(bar) or not self:CanAccess(owner) or owner == UIParent
		or self.retired[bar] or not self:IsModern(bar) then return false end
	if self.bars[bar] then return self.bars[bar].owner == owner and self:Apply(bar) end
	local state = { bar = bar, owner = owner, entries = {}, active = false }
	local ok, valid = pcall(function()
		if CheckChain(bar, owner) ~= "ok" then return false end
		local parts = Parts(bar)
		if #parts ~= 4 then return false end
		for _, widget in ipairs(parts) do
			if not CanRead(widget, false) or CheckChain(widget, bar) ~= "ok" then return false end
			local entry = { widget = widget, parent = widget:GetParent(), textures = {}, state = state }
			for _, key in ipairs(TEXTURES) do
				local texture = widget[key]
				if texture then
					if not CanRead(texture, false) or texture:GetParent() ~= widget then return false end
					entry.textures[#entry.textures + 1] = { key = key, texture = texture,
						color = { texture:GetVertexColor() }, desaturated = texture:IsDesaturated() }
				end
			end
			state.entries[#state.entries + 1] = entry
		end
		return true
	end)
	if not ok or not valid then return false end
	self.bars[bar] = state
	bar.BFL_NativeScrollbarStyle = true
	for _, entry in ipairs(state.entries) do
		self.widgets[entry.widget] = entry
		local function Refresh() self:RefreshWidget(entry.widget) end
		for _, event in ipairs({ "OnShow", "OnEnable", "OnDisable" }) do
			if not entry.widget.HasScript or entry.widget:HasScript(event) then entry.widget:HookScript(event, Refresh) end
		end
		if type(entry.widget.OnButtonStateChanged) == "function" then hooksecurefunc(entry.widget, "OnButtonStateChanged", Refresh) end
	end
	bar:HookScript("OnShow", function() self:Apply(bar) end)
	hooksecurefunc(bar, "SetParent", function() self:Apply(bar) end)
	state.active = true
	return self:Apply(bar)
end

function ScrollbarStyle:Apply(bar)
	if IsSecret(bar) then return false end
	local state = self.bars[bar]
	if not (state and state.active) then return false end
	local status = self:CheckState(state)
	if status == "lost" then self:Retire(state); return false end
	if status ~= "ok" then return false end
	for _, entry in ipairs(state.entries) do
		if not state.active then return false end
		self:Paint(entry)
	end
	return state.active
end

function ScrollbarStyle:Refresh()
	for bar in pairs(self.bars) do self:Apply(bar) end
end
