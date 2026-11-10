-- The visible input stays in the original Blizzard view and receives real clicks.
local root = assert(arg[1], "repository root required"):gsub("[\\/]$", "")
local env, hooks, events = {}, {}, {}
setmetatable(env, { __index = _G })
env.unpack = table.unpack or unpack
local inCombat, selectedTab = false, 2
env.InCombatLockdown = function() return inCombat end
local pendingSearch, pendingLayout
env.C_Timer = {
	After = function(_, callback)
		assert(not pendingLayout, "layout should be coalesced within a frame")
		pendingLayout = callback
	end,
	NewTimer = function(_, callback)
		local timer = { callback = callback, Cancel = function(self) self.cancelled = true end }
		pendingSearch = timer
		return timer
	end,
}
local function flushLayout()
	local callback = assert(pendingLayout, "expected layout to be pending")
	pendingLayout = nil
	callback()
end
env.PanelTemplates_GetSelectedTab = function() return selectedTab end
env.hooksecurefunc = function(_, method, callback) hooks[method] = callback end
local secret = {}
env.issecrettable = function(value) return value == secret end
local Frame = {}
Frame.__index = Frame
function Frame:IsShown() return self.shown end
function Frame:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
function Frame:Show() self.shown = true end
function Frame:Hide() self.shown = false end
function Frame:SetShown(shown) self.shown = shown end
function Frame:GetParent() return self.parent end
function Frame:SetParent(parent) self.parent = parent end
function Frame:GetNumPoints() return #self.points end
function Frame:GetPoint(index) return env.unpack(self.points[index], 1, 5) end
function Frame:SetPoint(...) self.points[#self.points + 1] = { ... } end
function Frame:ClearAllPoints() self.points = {}; self.fill = nil end
function Frame:SetAllPoints(frame)
	self.fill = frame
	self.points = { { "TOPLEFT", frame, "TOPLEFT", 0, 0 }, { "BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0 } }
end
function Frame:GetSize(ignoreRect)
	if not ignoreRect and self.rectWidth then return self.rectWidth, self.rectHeight end
	return self.width, self.height
end
function Frame:SetSize(width, height) self.width, self.height = width, height end
function Frame:GetFrameStrata() return self.strata end
function Frame:SetFrameStrata(strata) self.strata = strata end
function Frame:GetFrameLevel() return self.level end
function Frame:SetFrameLevel(level) self.level = level end
function Frame:IsProtected() return self.protected or false end
function Frame:IsForbidden() return self.forbidden or false end
function Frame:IsAnchoringRestricted() return self.anchoringRestricted or false end
function Frame:IsMouseEnabled() return not self.noMouse end
function Frame:HookScript(name, callback) self.scripts[name] = callback end
function Frame:HasFocus() return self.focus end
function Frame:ClearFocus() self.focus = nil end
function Frame:SetFocus() error("no scripted focus transfer") end
function Frame:SetText() error("no scripted native text entry") end
function Frame:GetText() return self.text end
function Frame:GetAlpha() return self.alpha end
function Frame:SetAlpha(alpha) self.alpha = alpha end
function Frame:GetFontObject() return self.font end
function Frame:SetFontObject() error("the native search font object must be left alone") end
function Frame:GetTextInsets() return env.unpack(self.insets) end
function Frame:SetTextInsets(...) self.insets = { ... } end
local function newFrame(parent, shown)
	return setmetatable({ parent = parent, shown = shown, points = {}, scripts = {}, text = "",
		width = 400, height = 600, strata = "MEDIUM", level = 1 }, Frame)
end
env.UIParent = newFrame(nil, true)
local blizzard = newFrame(env.UIParent, false)
local view = newFrame(blizzard, false)
blizzard.FriendsList = view
view:SetPoint("TOPLEFT", blizzard, "TOPLEFT", 5, -10)
view.FilterBar = newFrame(view, true)
local box = newFrame(view.FilterBar, true)
box.font, box.insets = "Blizzard font", { 22, 22, 0, 0 }
for _, key in ipairs({ "Background", "searchIcon", "Instructions" }) do
	box[key] = newFrame(box, true)
	box[key]:SetAlpha(0.75)
end
view.FilterBar.SearchBar = box
box:SetPoint("LEFT", view.FilterBar, "LEFT", 15, 0)
view.RefreshSearchResults = function() error("addon called Blizzard's search") end
local function branch(nodes) return { GetNodes = function() return nodes end } end
local rootNode = branch({ branch({ {
	GetData = function() return { friendIndex = 95, accountInfo = { bnetAccountID = 150 } } end,
} }) })
view.ScrollBox = newFrame(view, true)
view.ScrollBox.GetDataProvider = function() return { GetRootNode = function() return rootNode end } end
local bflFrame = newFrame(env.UIParent, true)
bflFrame.FriendsTabHeader = newFrame(bflFrame, true)
local bflBox = newFrame(bflFrame.FriendsTabHeader, true)
bflBox.font, bflBox.insets = "BFL font", { 16, 20, 0, 0 }
bflBox.Instructions = newFrame(bflBox, true)
bflBox.Instructions:SetAlpha(0.8)
bflFrame.FriendsTabHeader.SearchBox = bflBox
env.BetterFriendsFrame = bflFrame
env.C_AddOns = { LoadAddOn = function(name)
	assert(name == "Blizzard_SocialUI")
	env.SocialUIFrame = blizzard
	events.ADDON_LOADED(name)
end }
local friends = { searchText = "" }
local refreshes = {}
local section, streamer, socialUIEnabled = "friends", false, false
local BFL = {
	IsSecret = function(_, value) return value == secret end,
	GetModule = function(_, key) if key == "FriendsList" then return friends end end,
	RegisterEventCallback = function(_, key, callback) events[key] = callback end,
	ScheduleFriendsListRefresh = function(_, reason) refreshes[#refreshes + 1] = reason end,
	StreamerMode = { IsActive = function() return streamer end },
	FriendsUI = {
		IsSocialUIEnabled = function() return socialUIEnabled end,
		IsModernActive = function() return true end,
		GetSelectedSection = function() return section end,
	},
}
function friends:SetSearchText(text, skipRefresh)
	if self.searchText == text then return end
	self.searchText = text
	if not skipRefresh then BFL:ScheduleFriendsListRefresh("search") end
end
local main = assert(io.open(root .. "/BetterFriendlist.lua", "r"))
local source = main:read("*a")
main:close()
local inputStart = assert(source:find("function BetterFriendsFrame_OnSearchFocusGained", 1, true))
local inputEnd = assert(source:find("local function SuspendBetterFriendsFrameUIPanelForCombat", inputStart, true))
local input = [[
local BFL, GetFriendsList = ...
local searchText = ""
local function CancelSearchDebounceTimer()
	if BFL.searchDebounceTimer then
		BFL.searchDebounceTimer:Cancel()
		BFL.searchDebounceTimer = nil
	end
end
]] .. source:sub(inputStart, inputEnd - 1)
assert(load(input, "BFL search input routing", "t", env))(BFL, function() return friends end)
assert(loadfile(root .. "/Modules/NativeFriendsSearch.lua", "t", env))("BetterFriendlist", BFL)
local search = BFL.NativeFriendsSearch
local function updateLayout()
	search:QueueLayout()
	while pendingLayout do flushLayout() end
end
updateLayout()
assert(not env.SocialUIFrame and not box.fill and bflBox:IsMouseEnabled(),
	"an unavailable native view leaves the local search field usable")
socialUIEnabled = true
inCombat = true
view:SetSize(320, 480)
view.rectWidth, view.rectHeight = 347, 512
updateLayout()
assert(search:IsInputHosted(bflBox), "the resolved rect must not veto an assigned native view size")
local assignedWidth, assignedHeight = view:GetSize(true)
assert(assignedWidth == 400 and assignedHeight == 600)
assert(not blizzard:IsVisible() and view:IsVisible(), "only the hosted friends view is running")
assert(box:GetParent() == view.FilterBar and box.fill == bflBox, "the real search field keeps its original input hierarchy")
assert(view:GetParent() == bflFrame, "both search fields must share BFL's top-level input order")
assert(box:GetFrameLevel() > bflBox:GetFrameLevel() and box:GetFrameStrata() == bflBox:GetFrameStrata(),
	"the native input must be above the fallback field within the BFL window")
assert(bflBox:IsVisible() and bflBox:IsMouseEnabled(), "the original BFL control remains available")
assert(not view.ScrollBox:IsShown(), "the native list is not rendered as a second list")
assert(box.Background:GetAlpha() == 0 and box.searchIcon:GetAlpha() == 0 and box.Instructions:GetAlpha() == 0)
assert(box:GetFontObject() == "Blizzard font" and box:GetTextInsets() == bflBox:GetTextInsets())
inCombat = false
box.text = "Mapko"
hooks.RefreshSearchResults(view)
box.scripts.OnTextChanged(box)
local nativeTimer = pendingSearch
bflBox.Instructions:Show() -- The BFL search template responds to its own empty field.
env.BetterFriendsFrame_OnSearchTextChanged(bflBox)
assert(pendingSearch == nativeTimer and not nativeTimer.cancelled, "the empty fallback field cannot replace the native query")
assert(bflBox.Instructions:GetAlpha() == 0, "the placeholder remains invisible after the local template shows it")
pendingSearch.callback()
local contact = { type = "bnet", bnetAccountID = 150 }
assert(friends.searchText == "mapko" and search:Matches(contact, friends.searchText))
inCombat = true
updateLayout()
assert(search:IsInputHosted(bflBox) and search:Matches(contact, "mapko"), "entering combat preserves native input")
inCombat = false
env.BetterFriendsFrame_OnSearchTextChanged(bflBox)
assert(pendingSearch == nativeTimer, "a later local event cannot queue another refresh")
assert(not search:Matches({ type = "bnet", bnetAccountID = secret }, friends.searchText))
streamer = true
assert(not search:Matches(contact, friends.searchText))
streamer = false
box.scripts.OnTextChanged(box)
local interruptedSearch = pendingSearch
refreshes = {}
box.text = ""
hooks.RefreshSearchResults(view)
assert(#refreshes == 0, "empty native results cannot schedule a rebuild with the old filter")
box.scripts.OnTextChanged(box)
assert(interruptedSearch.cancelled and BFL.searchDebounceTimer == nil, "clearing cancels pending input without starting another debounce")
assert(bflBox.Instructions:GetAlpha() == 0.8 and friends.searchText == "", "clearing restores the placeholder and immediately clears the BFL query")
assert(not search:Matches(contact, "mapko") and #refreshes == 1 and refreshes[1] == "search",
	"clearing drops old matches and schedules a render from the BFL cache")

box.text = "Mapko"
hooks.RefreshSearchResults(view)
box.scripts.OnTextChanged(box)
pendingSearch.callback()
assert(search:Matches(contact, friends.searchText), "search still works after clearing")
refreshes = {}
events.BN_FRIEND_LIST_SIZE_CHANGED(true)
assert(not search:Matches(contact, friends.searchText) and refreshes[1] == "native-friend-search")
section = "recent_allies"
updateLayout()
assert(not box.fill and box.points[1][2] == view.FilterBar and view:GetParent() == blizzard)
assignedWidth, assignedHeight = view:GetSize(true)
assert(assignedWidth == 320 and assignedHeight == 480, "rollback restores the assigned size instead of the old rect")
view.rectWidth, view.rectHeight = nil, nil
assert(box.Background:GetAlpha() == 0.75 and box.searchIcon:GetAlpha() == 0.75 and box.Instructions:GetAlpha() == 0.75)
assert(box:GetFontObject() == "Blizzard font" and box:GetTextInsets() == 22)
section = "friends"
updateLayout()
bflFrame:Hide()
search:OnFrameHide()
search:OnFrameHide()
assert(not view:IsVisible() and box.fill == bflBox, "OnHide must leave native edit box geometry alone")
flushLayout()
assert(not box.fill and box.Background:GetAlpha() == 0.75, "the next frame restores the native edit box")
bflFrame:Show()
updateLayout()
search:UseLocalSearch()
updateLayout()
assert(not box.fill and bflBox:IsVisible(), "the fallback can be used for the rest of the visit")
selectedTab = 1
local lastNativeTimer = pendingSearch
bflBox.text = "Local input"
env.BetterFriendsFrame_OnSearchTextChanged(bflBox)
assert(pendingSearch ~= lastNativeTimer, "the local field can queue a refresh once native input is released")
pendingSearch.callback()
assert(friends.searchText == "local input")
bflBox.text = ""
env.BetterFriendsFrame_OnSearchTextChanged(bflBox)
assert(friends.searchText == "" and BFL.searchDebounceTimer == nil, "local clear also removes the filter immediately")
search:OnFrameHide()
updateLayout()
assert(box.fill == bflBox)
blizzard:Show()
blizzard.scripts.OnShow()
assert(view:GetParent() == blizzard and view.points[1][2] == blizzard and view.ScrollBox:IsShown())
assert(not box.fill and box.points[1][2] == view.FilterBar)

blizzard:Hide()
socialUIEnabled = false
updateLayout()
assert(box.fill == bflBox and search:IsInputHosted(bflBox),
	"an existing native search field can be used while the old Blizzard window is active")
box.text = "Mapko"
hooks.RefreshSearchResults(view)
box.scripts.OnTextChanged(box)
pendingSearch.callback()
assert(friends.searchText == "mapko" and search:Matches(contact, friends.searchText))

local function drainLayout()
	while pendingLayout do flushLayout() end
end

local function closeBFL()
	bflFrame:Hide()
	env.BetterFriendsFrame_OnSearchHide()
	drainLayout()
end

local function openBFL()
	bflFrame:Show()
	updateLayout()
end

local function originalLayout()
	assert(view:GetParent() == blizzard and view:GetNumPoints() == 1 and view.points[1][2] == blizzard)
	local width, height = view:GetSize()
	assert(width == 320 and height == 480)
	assert(not view:IsShown() and view.ScrollBox:IsShown())
	assert(box:IsShown() and not box.fill and box:GetNumPoints() == 1 and box.points[1][2] == view.FilterBar)
	assert(box:GetFrameStrata() == "MEDIUM" and box:GetFrameLevel() == 1)
	assert(box:GetTextInsets() == 22 and box.Background:GetAlpha() == 0.75
		and box.searchIcon:GetAlpha() == 0.75 and box.Instructions:GetAlpha() == 0.75)
	assert(bflBox.Instructions:GetAlpha() == 0.8)
	assert(not search:IsInputHosted(bflBox) and not search:Matches(contact, "mapko"))
end

closeBFL()
view:SetSize(320, 480)
bflBox:SetFrameStrata("HIGH")
box.text = "Mapko"
inCombat = true
selectedTab = 1

for _, blocked in ipairs({
	{ view, "protected", true },
	{ view.ScrollBox, "protected", true },
	{ box, "forbidden", true },
	{ bflFrame, "protected", true },
	{ bflBox, "anchoringRestricted", true },
	{ env.UIParent, "anchoringRestricted", true },
	{ box, "protected", secret },
}) do
	local frame, key, value = env.unpack(blocked)
	frame[key] = value
	openBFL()
	originalLayout()
	closeBFL()
	frame[key] = nil
end

local function failAttachment(object, method, mode)
	local setter = object[method]
	object[method] = function(self, ...)
		object[method] = setter
		if mode == "ignored" then return end
		setter(self, ...)
		error("injected failure after " .. method)
	end
	openBFL()
	originalLayout()
	assert(object[method] == setter, "the injected failure must have been exercised")
	closeBFL()
end

for _, failure in ipairs({
	{ view, "SetParent" }, { view, "ClearAllPoints" }, { view, "SetPoint" }, { view, "SetSize" },
	{ view.ScrollBox, "SetShown" }, { box, "ClearAllPoints" }, { box, "SetAllPoints" },
	{ box, "SetFrameStrata" }, { box, "SetFrameLevel" }, { box, "SetTextInsets" },
	{ box.Background, "SetAlpha" }, { bflBox.Instructions, "SetAlpha" }, { view, "SetShown" },
}) do
	failAttachment(failure[1], failure[2], "error")
end
failAttachment(view, "SetParent", "ignored")
failAttachment(view, "SetSize", "ignored")
local reportedAnchorFailure
search:SetLayoutTrace(function(stage, detail)
	if stage == "attach" and detail:find("search box SetAllPoints", 1, true) then
		reportedAnchorFailure = true
	end
end)
failAttachment(box, "SetAllPoints", "ignored")
search:SetLayoutTrace(nil)
assert(reportedAnchorFailure, "the listener should identify a failed native search-box anchor")
failAttachment(box, "SetFrameLevel", "ignored")
box.noMouse = true
openBFL()
originalLayout()
closeBFL()
box.noMouse = nil

local viewSetParent = view.SetParent
local attachAttempts = 0
view.SetParent = function(self, parent)
	if parent == bflFrame then attachAttempts = attachAttempts + 1 end
	if parent == blizzard and inCombat then return end
	viewSetParent(self, parent)
end
local setAllPoints = box.SetAllPoints
box.SetAllPoints = function()
	box.SetAllPoints = setAllPoints
	error("could not anchor the input")
end
openBFL()
assert(not search:IsInputHosted(bflBox) and view:GetParent() == bflFrame and not box:IsShown())
updateLayout()
assert(attachAttempts == 1, "a pending rollback blocks a second attachment")
inCombat = false
closeBFL()
events.PLAYER_REGEN_ENABLED()
drainLayout()
originalLayout()
view.SetParent = viewSetParent

local loadAddOn = env.C_AddOns.LoadAddOn
local loadAttempts = 0
env.C_AddOns.LoadAddOn = function()
	loadAttempts = loadAttempts + 1
	return false, "INJECTED_LOAD_FAILURE"
end
inCombat = true
env.SocialUIFrame = nil
openBFL()
updateLayout()
assert(loadAttempts == 1, "a failed load must not be retried on every layout")
bflBox.text = "Local input"
env.BetterFriendsFrame_OnSearchTextChanged(bflBox, true)
pendingSearch.callback()
assert(friends.searchText == "local input")
env.SocialUIFrame = blizzard
events.ADDON_LOADED("Blizzard_SocialUI")
drainLayout()
inCombat = false
events.PLAYER_REGEN_ENABLED()
drainLayout()
assert(not search:IsInputHosted(bflBox) and friends.searchText == "local input",
	"native availability must not replace input during a local visit")
closeBFL()
env.C_AddOns.LoadAddOn = loadAddOn

inCombat = true
openBFL()
assert(search:IsInputHosted(bflBox), "first opening in combat works with the loaded native view")
hooks.RefreshSearchResults(view)
box.scripts.OnTextChanged(box)
pendingSearch.callback()
assert(search:Matches(contact, "mapko"))
local readProvider = view.ScrollBox.GetDataProvider
view.ScrollBox.GetDataProvider = function() return secret end
hooks.RefreshSearchResults(view)
assert(not search:Matches(contact, "mapko"), "unreadable results clear the previously matching query")
view.ScrollBox.GetDataProvider = readProvider
box.text = "Stale query"
box.scripts.OnTextChanged(box)
local oldTimer = pendingSearch
blizzard:Show()
blizzard.scripts.OnShow()
oldTimer.callback()
assert(friends.searchText == "", "a released native query cannot commit after its debounce")
originalLayout()
hooks.RefreshSearchResults(view)
assert(not search:Matches(contact, "stale query"), "the standalone Blizzard window cannot publish BFL results")

io.write("Native friend search smoke passed.\n")
