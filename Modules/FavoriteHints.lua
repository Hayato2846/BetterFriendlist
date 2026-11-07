-- Explain where to show a newly marked Battle.net favorite.
local _, BFL = ...
local FavoriteHints = BFL:RegisterModule("FavoriteHints", {})

function FavoriteHints:OnAdded()
	local db = BFL:GetModule("DB")
	local settings = BFL:GetModule("Settings")
	local hints = BFL:GetModule("FeatureHints")
	if not (db and settings and hints)
		or db:Get("showFavoritesGroup", true) ~= false or db:Get("enableFavoriteIcon", true) ~= false
	then return end

	local L = BFL.L
	local center = settings:IsSettingsCenterEnabled()
	local groupPath = center and (L.SETTINGS_CENTER_CATEGORY_GROUPS_SORTING .. " > " .. L.SETTINGS_CENTER_PAGE_GROUPS_BUILTINS)
		or (L.SETTINGS_TAB_GENERAL .. " > " .. L.SETTINGS_GROUP_MANAGEMENT)
	local iconPath = center and (L.SETTINGS_CENTER_CATEGORY_FRIENDS .. " > " .. L.SETTINGS_CENTER_PAGE_FRIENDS_DISPLAY)
		or (L.SETTINGS_TAB_GENERAL .. " > " .. L.SETTINGS_DISPLAY_OPTIONS)
	local groupLabel = string.format(L.SETTINGS_SHOW_GROUP_FMT, L.GROUP_FAVORITES)
	local iconLabel = L.SETTINGS_ENABLE_FAVORITE_ICON
	return hints:Show({
		id = "favorites.visibility",
		title = L.FAVORITE_HINT_TITLE,
		icon = "Interface\\AddOns\\BetterFriendlist\\Icons\\check-circle.blp",
		entries = {
			{
				label = groupLabel, text = L.FAVORITE_HINT_HIDDEN, path = groupPath .. " > " .. groupLabel,
				page = "groups.builtins", control = "showFavoritesGroup", category = 1, legacySection = "showFavoritesGroup",
			},
			{
				label = iconLabel, text = L.SETTINGS_ENABLE_FAVORITE_ICON_DESC, path = iconPath .. " > " .. iconLabel,
				page = "friends.display", control = "enableFavoriteIcon", category = 1, legacySection = "enableFavoriteIcon",
			},
		},
	})
end

function FavoriteHints:ObserveMenu(root)
	if not (ADD_FAVORITE_STATUS and root.AddMenuResponseCallback and root.EnumerateElementDescriptions) then return end
	for _, element in root:EnumerateElementDescriptions() do
		local label = BFL.Compat.GetMenuElementText(element)
		if not BFL:IsSecret(label) and label == ADD_FAVORITE_STATUS then
			root:AddMenuResponseCallback(function(_, selected)
				if not BFL:IsSecret(selected) and selected == element then self:OnAdded() end
			end)
			return
		end
	end
end
