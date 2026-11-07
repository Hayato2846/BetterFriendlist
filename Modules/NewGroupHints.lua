local _, BFL = ...
local NewGroupHints = BFL:RegisterModule("NewGroupHints", {})

function NewGroupHints:OnCreated(friends, memberUID)
	local hints = BFL:GetModule("FeatureHints")
	local settings = BFL:GetModule("Settings")
	local db = BFL:GetModule("DB")
	if not (hints and settings and db) then return end

	local hideEmpty = db:Get("hideEmptyGroups", false)
	local member = memberUID and friends:ResolveFriendByUID(memberUID)
	if member and BFL.IsSecret and BFL:IsSecret(member.connected) then return end
	local hasSearch = (friends.searchText or "") ~= ""
	local hasQuickFilter = (friends.filterMode or "all") ~= "all"
	local quickFilters = BFL:GetModule("QuickFilters")
	local activeTags = quickFilters and quickFilters:GetActiveTagFilterDefinitions()
	local hasTagFilter = activeTags and #activeTags > 0
	local hasFilter = hasQuickFilter or hasTagFilter
	local visibleMember = member and friends:PassesFilters(member)
	local hiddenWithoutOnline = hideEmpty and not (member and member.connected)
	-- Tag-only filters remove rows but keep empty headers unless Hide Empty Groups is active.
	local hiddenByView = not visibleMember and (hasSearch or hasQuickFilter or (hideEmpty and member and hasTagFilter))
	if not (hiddenWithoutOnline or hiddenByView) then return end

	local L = BFL.L
	local entries = {}
	if hiddenWithoutOnline then
		local root = settings:IsSettingsCenterEnabled()
				and (L.SETTINGS_CENTER_CATEGORY_GROUPS_SORTING .. " > " .. L.SETTINGS_CENTER_PAGE_GROUPS_BUILTINS)
			or L.SETTINGS_TAB_GENERAL
		entries[#entries + 1] = {
			label = L.SETTINGS_HIDE_EMPTY_GROUPS,
			text = string.format(L.NEW_GROUP_HINT_EMPTY, L.SETTINGS_HIDE_EMPTY_GROUPS),
			path = root .. " > " .. L.SETTINGS_HIDE_EMPTY_GROUPS,
			page = "groups.builtins", control = "hideEmptyGroups",
			category = 1, legacySection = "hideEmptyGroups",
		}
	end
	if hiddenByView then
		local text = hasSearch and hasFilter and L.NEW_GROUP_HINT_SEARCH_FILTER
			or hasSearch and L.NEW_GROUP_HINT_SEARCH or L.NEW_GROUP_HINT_FILTER
		entries[#entries + 1] = {
			label = L.FILTER_ALL,
			text = text,
			actionText = L.NEW_GROUP_HINT_SHOW_ALL,
			onClick = function()
				if hasSearch then BFL:ClearFriendsListSearch() end
				if hasFilter and quickFilters then quickFilters:ResetFilters() end
				BFL:ForceRefreshFriendsList()
			end,
		}
	end
	hints:Show({
		id = hiddenWithoutOnline and (hiddenByView and "newGroup.emptyAndFiltered" or "newGroup.empty")
			or (hasSearch and "newGroup.search" or "newGroup.filter"),
		title = L.NEW_GROUP_HINT_TITLE,
		icon = "Interface\\AddOns\\BetterFriendlist\\Icons\\check-circle.blp",
		entries = entries,
	})
end
