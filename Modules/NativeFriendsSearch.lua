local _, BFL = ...

local NativeSearch = {}
BFL.NativeFriendsSearch = NativeSearch

local observedView, query, matches
local host, target, layoutPending, localOnly
local changingLayout, releaseRequested, attachFailed, loadAttempted

local function IsReadable(value, kind)
	return not BFL:IsSecret(value) and type(value) == kind
		and (kind ~= "table" or not (issecrettable and issecrettable(value)))
end

-- A temporary listener can subscribe from LuaWorkbench without enabling chat logging.
local function TraceLayout(stage, detail)
	local listener = NativeSearch.layoutTrace
	if type(listener) == "function" then pcall(listener, stage, detail) end
end

function NativeSearch:SetLayoutTrace(listener)
	self.layoutTrace = listener
end

local function DescribeLayoutError(value)
	if not IsReadable(value, "string") then return "unreadable error" end
	-- Keep client strings and search data out of the trace.
	local line = value:match("NativeFriendsSearch%.lua:(%d+)")
	return line and ("NativeFriendsSearch.lua:" .. line) or "client API error"
end

local function ReadResults(scrollBox)
	local provider = scrollBox:GetDataProvider()
	if not IsReadable(provider, "table") then return end
	local root = provider:GetRootNode()
	if not IsReadable(root, "table") then return end
	local sections = root:GetNodes()
	if not IsReadable(sections, "table") then return end
	local results = {}
	for _, section in ipairs(sections) do
		if not IsReadable(section, "table") then return end
		local children = section:GetNodes()
		if BFL:IsSecret(children) then return end
		if children ~= nil then
			if not IsReadable(children, "table") then return end
			for _, node in ipairs(children) do
				if not IsReadable(node, "table") then return end
				local data = node:GetData()
				if not IsReadable(data, "table") or BFL:IsSecret(data.friendIndex) then return end
				if IsReadable(data.friendIndex, "number") then
					if not IsReadable(data.accountInfo, "table") then return end
					local id = data.accountInfo.bnetAccountID
					if BFL:IsSecret(id) then return end
					if IsReadable(id, "number") and id > 0 then results[id] = true end
				end
			end
		end
	end
	return results
end

local function InvalidateDisplay()
	local friends = BFL:GetModule("FriendsList")
	if friends and query and friends.searchText == query then
		friends.lastBuildInputs = nil
		BFL:ScheduleFriendsListRefresh("native-friend-search", 0.05)
	end
end

local function ClearResults(skipRefresh)
	if not skipRefresh then InvalidateDisplay() end
	query, matches = nil, nil
end

local function CaptureNativeResults(view)
	if not host or view ~= host.view or view ~= observedView then return end
	local box = host.box
	local text = box:GetText()
	if changingLayout then
		if host.attaching and not releaseRequested and IsReadable(text, "string") then
			host.refreshedText = text
		end
		return
	end
	if not target or not view:IsVisible() or not box:IsVisible() then return end
	local readable = IsReadable(text, "string")
	local empty = readable and text == ""
	-- OnTextChanged clears the BFL filter and schedules the unfiltered render.
	ClearResults(empty)
	if not readable or empty then return end
	local results = ReadResults(view.ScrollBox)
	if results then
		query, matches = text:lower(), results
		InvalidateDisplay()
	end
end

local function OnNativeSearch(view)
	if not pcall(CaptureNativeResults, view) then ClearResults() end
end

local function Pack(...)
	return { n = select("#", ...), ... }
end

local function ReadValues(...)
	local values = Pack(...)
	for index = 1, values.n do
		assert(not BFL:IsSecret(values[index]), "Unreadable frame layout")
	end
	return values
end

local function SameValues(a, b)
	if a.n ~= b.n then return false end
	for index = 1, a.n do
		if a[index] ~= b[index] then return false end
	end
	return true
end

local function SameAnchors(a, b)
	if a.n ~= b.n then return false end
	for first = 1, a.n, 5 do
		local second = 1
		while second <= b.n and b[second] ~= a[first] do second = second + 5 end
		if second > b.n then return false end
		for offset = 1, 4 do
			if a[first + offset] ~= b[second + offset] then return false end
		end
	end
	return true
end

local function CanUseRegion(region, changing, anchoring)
	if not region then return false, "missing" end
	local forbidden = region:IsForbidden()
	if not IsReadable(forbidden, "boolean") then return false, "forbidden status unreadable" end
	if forbidden then return false, "forbidden" end
	if changing and region.IsProtected then
		local protected = region:IsProtected()
		if not IsReadable(protected, "boolean") then return false, "protection status unreadable" end
		if protected and InCombatLockdown() then return false, "combat protection" end
	end
	if anchoring and region.IsAnchoringRestricted then
		local restricted = region:IsAnchoringRestricted()
		if not IsReadable(restricted, "boolean") then return false, "anchor restriction status unreadable" end
		if restricted then return false, "restricted anchors" end
	end
	return true
end

local function IsHidden(frame)
	local ok, visible = pcall(frame.IsVisible, frame)
	return ok and IsReadable(visible, "boolean") and not visible
end

local function ReadPoints(frame)
	local count = frame:GetNumPoints()
	assert(IsReadable(count, "number"), "Unreadable anchor count")
	local points = { n = count * 5 }
	for index = 1, count do
		local point, relative, relativePoint, x, y = unpack(ReadValues(frame:GetPoint(index)), 1, 5)
		local offset = (index - 1) * 5
		points[offset + 1], points[offset + 2], points[offset + 3] = point, relative, relativePoint or point
		points[offset + 4], points[offset + 5] = x or 0, y or 0
	end
	return points
end

local function WritePoints(frame, points)
	frame:ClearAllPoints()
	assert(frame:GetNumPoints() == 0, "Could not clear anchors")
	for index = 1, points.n, 5 do
		frame:SetPoint(unpack(points, index, index + 4))
	end
end

local function AddState(session, object, getter, setter, ...)
	local readValue = type(getter) == "function" and getter
	local function read()
		return ReadValues((readValue or object[getter])(object))
	end
	local state = {
		object = object, read = read, before = read(), after = Pack(...),
		write = function(values) object[setter](object, unpack(values, 1, values.n)) end,
		parent = setter == "SetParent", operation = setter,
	}
	session.states[#session.states + 1] = state
	return state
end

local function AddAnchors(session, frame, write, ...)
	local function read() return ReadPoints(frame) end
	local before = read()
	for index = 2, before.n, 5 do
		local relative = before[index]
		assert(not relative or CanUseRegion(relative, false, true), "Original anchor is restricted")
	end
	session.states[#session.states + 1] = {
		object = frame, read = read, before = before, after = Pack(...),
		write = function(values) WritePoints(frame, values) end, apply = write, same = SameAnchors,
		operation = write and "SetAllPoints" or "SetPoint",
	}
end

local function SetState(state, restoring)
	local values = restoring and state.before or state.after
	local same = state.same or SameValues
	if same(state.read(), values) then return end
	local anchoring = state.same == SameAnchors
	assert(CanUseRegion(state.object, true, anchoring), "Frame layout is restricted")
	if anchoring then
		for index = 2, values.n, 5 do
			local relative = values[index]
			assert(not relative or CanUseRegion(relative, false, true), "Anchor target is restricted")
		end
	elseif state.parent then
		assert(CanUseRegion(values[1]), "Frame parent is restricted")
	end
	if not restoring and state.apply then
		state.apply()
	else
		state.write(values)
	end
	assert(same(state.read(), values), "Frame layout did not change as requested")
end

local function LayoutMatches(session, restoring)
	for _, state in ipairs(session.states) do
		local same = state.same or SameValues
		if not same(state.read(), restoring and state.before or state.after) then return false, state end
	end
	return true
end

local function DescribeStep(session, state)
	if not state then return "final visibility or ownership check" end
	local region = state.object
	local label = region == session.view and "view" or region == session.box and "search box"
		or region == session.view.ScrollBox and "scroll box" or "decoration"
	return label .. " " .. state.operation
end

local function RollBack(session)
	local restored = true
	for _, state in ipairs(session.states) do
		-- Try the independent restores even when one frame refuses a change.
		if state ~= session.viewVisibility and not pcall(SetState, state, true) then restored = false end
	end
	if not pcall(SetState, session.viewVisibility, true) or not restored then return false end
	local ok, matchesLayout = pcall(LayoutMatches, session, true)
	return ok and matchesLayout
end

local function ReleaseFocus(box)
	if CanUseRegion(box, true) and box:HasFocus() then box:ClearFocus() end
end

local function HideIfAllowed(region)
	if CanUseRegion(region, true) then region:Hide() end
end

local function HideDisplacedInput(session)
	if session.view:GetParent() ~= session.friendsFrame then return end
	pcall(HideIfAllowed, session.box)
	if session.box:IsShown() then pcall(HideIfAllowed, session.view) end
end

function NativeSearch:ReleaseInput()
	if changingLayout then
		releaseRequested = true
		return
	end
	if not host then return end
	local session = host
	local wasHosted = target ~= nil
	target = nil
	changingLayout = true
	ClearResults()
	BFL:ClearNativeFriendsSearchText(session)
	if wasHosted then pcall(ReleaseFocus, session.box) end
	if RollBack(session) then
		host = nil
	else
		attachFailed = true
		TraceLayout("rollback", "pending")
		pcall(HideDisplacedInput, session)
	end
	changingLayout = nil
	releaseRequested = nil
end

function NativeSearch:IsInputHosted(search)
	return target ~= nil and target == search
end

function NativeSearch:IsInputSession(session, text)
	return target ~= nil and host == session and session.inputText == text
end

function NativeSearch:UseLocalSearch()
	localOnly = true
	self:ReleaseInput()
end

function NativeSearch:OnFrameHide()
	localOnly = nil
	attachFailed = nil
	loadAttempted = nil
	-- Let the client's Hide finish before restoring the native EditBox.
	self:QueueLayout()
end

local function PublishText(box)
	local ok, text = pcall(box.GetText, box)
	local readable = ok and IsReadable(text, "string")
	host.inputText = readable and text:lower() or nil
	local empty = host.inputText == ""
	if not host.inputText or empty or (query and query ~= host.inputText) then ClearResults(empty) end
	if not readable then
		BFL:ClearNativeFriendsSearchText(host)
		return
	end
	if target.Instructions then
		pcall(function()
			if CanUseRegion(target.Instructions, true) then
				target.Instructions:SetAlpha(text == "" and host.placeholderAlpha or 0)
			end
		end)
	end
	BFL:SetNativeFriendsSearchText(text, host)
end

local function SyncInputInsets(box, search)
	if not CanUseRegion(box, true) then return end
	local desired = ReadValues(search:GetTextInsets())
	if not SameValues(ReadValues(box:GetTextInsets()), desired) then
		box:SetTextInsets(unpack(desired, 1, desired.n))
	end
end

function NativeSearch:Observe(frame)
	local view = frame and frame.FriendsList
	if not (view and view.FilterBar and view.FilterBar.SearchBar and view.ScrollBox
		and type(view.RefreshSearchResults) == "function") or view == observedView then return end
	ClearResults()
	observedView = view
	hooksecurefunc(view, "RefreshSearchResults", OnNativeSearch)
	if type(view.Refresh) == "function" then hooksecurefunc(view, "Refresh", OnNativeSearch) end
	local box = view.FilterBar.SearchBar
	box:HookScript("OnTextChanged", function(editBox)
		if target then PublishText(editBox) end
	end)
	frame:HookScript("OnShow", function() NativeSearch:ReleaseInput() end)
end

local function GetSearchTarget()
	local frame = BetterFriendsFrame
	local header = frame and frame.FriendsTabHeader
	local search = header and header.SearchBox
	local ui = BFL.FriendsUI
	if not (search and search:IsVisible() and ui) then return nil, "BFL search is hidden" end
	-- The native friends view can already exist while the legacy Blizzard window is active.
	if not observedView and not ui:IsSocialUIEnabled() then return nil, "Blizzard Social UI is unavailable" end
	if C_SocialRestrictions and C_SocialRestrictions.IsFriendsDisabled then
		local restricted = C_SocialRestrictions.IsFriendsDisabled()
		if not IsReadable(restricted, "boolean") or restricted then return nil, "friends access restricted" end
	end
	if ui:IsModernActive() then
		if ui:GetSelectedSection() ~= "friends" then return nil, "BFL friends section is inactive" end
	elseif (PanelTemplates_GetSelectedTab(frame) or 1) ~= 1
		or (PanelTemplates_GetSelectedTab(header) or 1) ~= 1
	then
		return nil, "BFL friends tab is inactive"
	end
	return search
end

local function CaptureLayout(frame, view, search, friendsFrame)
	local box, scrollBox = view.FilterBar.SearchBar, view.ScrollBox
	local visible, shown = frame:IsVisible(), box:IsShown()
	if visible ~= false or shown ~= true or view:GetParent() ~= frame then
		return nil, "Blizzard window, search visibility, or view parent"
	end
	for _, check in ipairs({
		{ "Blizzard window", frame }, { "BFL window", friendsFrame, true, true },
		{ "UIParent", UIParent, false, true }, { "BFL search", search, true, true },
		{ "Blizzard view", view, true, true }, { "Blizzard search", box, true, true },
		{ "Blizzard scroll box", scrollBox, true },
	}) do
		local allowed, reason = CanUseRegion(check[2], check[3], check[4])
		if not allowed then return nil, check[1] .. ": " .. reason end
	end
	-- Preserve the native widget and its secure handlers.
	if view:IsProtected() ~= false or box:IsProtected() ~= false then return nil, "protected native view or search" end
	if issecurevariable and not (issecurevariable(box, "OnSearchTextChanged")
		and issecurevariable(view, "RefreshSearchResults")) then return nil, "native search handler is tainted" end

	local session = { frame = frame, view = view, box = box, friendsFrame = friendsFrame, states = {} }
	AddState(session, view, "GetParent", "SetParent", friendsFrame)
	AddAnchors(session, view, nil, "TOPLEFT", UIParent, "BOTTOMRIGHT", 200, -200)
	-- Snapshot and verify the assigned dimensions. The anchor-resolved rect
	-- can still reflect the old layout immediately after changing the anchors.
	AddState(session, view, function(region) return region:GetSize(true) end, "SetSize", 400, 600)
	AddState(session, scrollBox, "IsShown", "SetShown", false)
	-- The native OnShow refresh should run before applying the overlay.
	-- Rollback handles visibility last to restore the original geometry first.
	session.viewVisibility = AddState(session, view, "IsShown", "SetShown", true)
	AddAnchors(session, box, function()
		box:ClearAllPoints()
		assert(box:GetNumPoints() == 0, "Could not clear input anchors")
		box:SetAllPoints(search)
	end, "TOPLEFT", search, "TOPLEFT", 0, 0, "BOTTOMRIGHT", search, "BOTTOMRIGHT", 0, 0)
	AddState(session, box, "GetFrameStrata", "SetFrameStrata", unpack(ReadValues(search:GetFrameStrata()), 1, 1))
	local level = search:GetFrameLevel()
	assert(IsReadable(level, "number"), "Unreadable search frame level")
	AddState(session, box, "GetFrameLevel", "SetFrameLevel", level + 1)
	local insets = ReadValues(search:GetTextInsets())
	AddState(session, box, "GetTextInsets", "SetTextInsets", unpack(insets, 1, insets.n))
	AddState(session, box, "IsShown", "SetShown", true)
	for _, key in ipairs({ "Background", "searchIcon", "Instructions" }) do
		local region = box[key]
		if region then
			if not CanUseRegion(region, true) then return nil, "Blizzard search decoration " .. key end
			AddState(session, region, "GetAlpha", "SetAlpha", 0)
		end
	end
	local text = box:GetText()
	if not IsReadable(text, "string") then return nil, "native input text is unreadable" end
	if search.Instructions then
		if not CanUseRegion(search.Instructions, true) then return nil, "BFL placeholder is restricted" end
		local alpha = search.Instructions:GetAlpha()
		if not IsReadable(alpha, "number") then return nil, "BFL placeholder opacity is unreadable" end
		session.placeholderAlpha = alpha
		AddState(session, search.Instructions, "GetAlpha", "SetAlpha", text == "" and alpha or 0)
	end
	return session
end

local function ApplyLayout(session, frame)
	for _, state in ipairs(session.states) do
		session.step = state
		SetState(state, false)
		if releaseRequested then return false, "released during attach" end
	end
	session.step = nil
	local layoutOK, state = LayoutMatches(session, false)
	if not layoutOK then return false, "final layout mismatch at " .. DescribeStep(session, state) end
	return frame.FriendsList == session.view and frame:IsVisible() == false
		and session.view:IsVisible() == true and session.box:IsVisible() == true and session.box:IsMouseEnabled() == true,
		"final visibility or ownership check"
end

function NativeSearch:UpdateLayout()
	if changingLayout or (host and not target) then return end
	local eligible, search, targetReason = pcall(GetSearchTarget)
	if not eligible then
		targetReason, search = DescribeLayoutError(search), nil
	end
	if search and target == search and not localOnly and IsHidden(host.frame) then
		pcall(SyncInputInsets, host.box, search)
		return
	end
	self:ReleaseInput()
	if not search then
		TraceLayout("search target", targetReason)
		return
	end
	if host or localOnly or attachFailed then
		TraceLayout("skipped", host and "pending rollback" or localOnly and "local input selected" or "previous attach failed")
		return
	end
	if not SocialUIFrame and C_AddOns and C_AddOns.LoadAddOn then
		if loadAttempted then return end
		loadAttempted = true
		pcall(C_AddOns.LoadAddOn, "Blizzard_SocialUI")
	end
	local frame = SocialUIFrame
	self:Observe(frame)
	local view = observedView
	if not frame or not view or frame.FriendsList ~= view then
		TraceLayout("capture", "native view is missing")
		return
	end
	local captured, session, reason = pcall(CaptureLayout, frame, view, search, BetterFriendsFrame)
	if not captured or not session then
		TraceLayout("capture", captured and reason or DescribeLayoutError(session))
		return
	end
	changingLayout = true
	host = session
	session.attaching = true
	local ok, ready, detail = pcall(ApplyLayout, session, frame)
	session.attaching = nil
	changingLayout = nil
	if not ok or not ready or releaseRequested then
		TraceLayout("attach", ok and detail or (DescribeStep(session, session.step) .. " " .. DescribeLayoutError(ready)))
		attachFailed = true
		self:ReleaseInput()
		return
	end
	target = search
	TraceLayout("attached")
	PublishText(session.box)
	if session.inputText and session.refreshedText and session.refreshedText:lower() == session.inputText then
		OnNativeSearch(view)
	end
	session.refreshedText = nil
end

function NativeSearch:QueueLayout()
	if layoutPending then return end
	layoutPending = true
	C_Timer.After(0, function()
		layoutPending = nil
		self:UpdateLayout()
	end)
end

function NativeSearch:Matches(friend, text)
	if not (target and matches and query == text and friend.type == "bnet") then return false end
	if BFL.StreamerMode and BFL.StreamerMode:IsActive() then return false end
	local id = friend.bnetAccountID
	return IsReadable(id, "number") and matches[id] == true
end

BFL:RegisterEventCallback("ADDON_LOADED", function(addon)
	if addon == "Blizzard_SocialUI" then
		NativeSearch:Observe(SocialUIFrame)
		NativeSearch:QueueLayout()
	end
end)
local function OnRosterChanged()
	ClearResults()
end
BFL:RegisterEventCallback("BN_FRIEND_LIST_SIZE_CHANGED", OnRosterChanged)
BFL:RegisterEventCallback("BN_DISCONNECTED", OnRosterChanged)
BFL:RegisterEventCallback("PLAYER_REGEN_ENABLED", function()
	attachFailed = nil
	loadAttempted = nil
	if host and not target then NativeSearch:ReleaseInput() end
	NativeSearch:QueueLayout()
end)
NativeSearch:Observe(SocialUIFrame)
