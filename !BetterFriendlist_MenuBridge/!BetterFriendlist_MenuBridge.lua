local ADDON_NAME = ...
local CAPTURE_GLOBAL = "BetterFriendlist_MenuBridgeCaptures"

local Store = _G[CAPTURE_GLOBAL]
if type(Store) ~= "table" then
	Store = {}
	_G[CAPTURE_GLOBAL] = Store
end

Store.version = 1
Store.addonName = ADDON_NAME
Store.captures = Store.captures or {}
Store.lookup = Store.lookup or {}
Store.installAttempts = Store.installAttempts or 0
Store.hookInstalled = Store.hookInstalled == true

local function GetSourceAddonName()
	if not debugstack then
		return nil
	end

	local ok, stack = pcall(debugstack, 2, 16, 0)
	if not ok or type(stack) ~= "string" then
		return nil
	end

	for addonName in stack:gmatch("[Ii]nterface[/\\][Aa]dd[Oo]ns[/\\]([^/\\:\r\n]+)") do
		if addonName ~= ADDON_NAME and addonName ~= "BetterFriendlist" and not addonName:match("^Blizzard_") then
			return addonName
		end
	end
	return nil
end

local function RecordModifyMenu(tag, callback)
	if type(tag) ~= "string" or type(callback) ~= "function" then
		return
	end

	local addonName = GetSourceAddonName()
	if not addonName then
		return
	end

	local key = tag .. "\001" .. addonName .. "\001" .. tostring(callback)
	if Store.lookup[key] then
		return
	end

	Store.lookup[key] = true
	Store.captures[#Store.captures + 1] = {
		tag = tag,
		callback = callback,
		addonName = addonName,
	}
end

local function InstallHook()
	if Store.hookInstalled then
		return true
	end

	Store.installAttempts = (Store.installAttempts or 0) + 1
	if not (hooksecurefunc and Menu and Menu.ModifyMenu) then
		return false
	end

	local ok = pcall(hooksecurefunc, Menu, "ModifyMenu", RecordModifyMenu)
	Store.hookInstalled = ok == true
	return Store.hookInstalled
end

if not InstallHook() then
	local frame = CreateFrame("Frame")
	frame:RegisterEvent("ADDON_LOADED")
	frame:RegisterEvent("PLAYER_LOGIN")
	frame:SetScript("OnEvent", function(self)
		if InstallHook() then
			self:UnregisterAllEvents()
			self:SetScript("OnEvent", nil)
		end
	end)
end
