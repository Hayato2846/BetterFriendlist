-- Run from the repository root with lua tools/BFL-RecentlyAddedSmoke.lua.
local events, timers = {}, {}
local wow, bnet = {}, {}
local wowCount, bnetCount = 0, 0
local connected, enabled, now = true, true, 1000000
local db = {
	Get = function(_, key, default)
		if key == "enableRecentlyAddedGroup" then
			return enabled
		end
		return default
	end,
}
local module
local BFL = {
	RegisterModule = function(_, _, value)
		module = value
		return value
	end,
	GetModule = function(_, name)
		return name == "DB" and db or nil
	end,
	RegisterEventCallback = function(_, event, callback)
		events[event] = callback
	end,
	Compat = { GetBNetFriendInfo = function(i) return bnet[i] end },
	CanUseWoWFriendList = function() return true end,
	GetNumWoWFriends = function() return wowCount end,
	GetWoWFriendInfoByIndex = function(i) return wow[i] end,
	NormalizeWoWFriendName = function(_, name) return name end,
	IsSecret = function() return false end,
	IsTitleFriend = function(info) return info.title end,
}
BNConnected = function() return connected end
BNGetNumFriends = function() return bnetCount end
time = function() return now end
wipe = function(t)
	for key in pairs(t) do
		t[key] = nil
	end
end
C_Timer = {
	NewTimer = function(_, callback)
		local timer = { callback = callback }
		function timer:Cancel()
			self.cancelled = true
		end
		timers[#timers + 1] = timer
		return timer
	end,
}
local function Settle()
	for _, timer in ipairs(timers) do
		if not timer.cancelled then
			timer.callback()
		end
	end
	timers = {}
end

BetterFriendlistDB = {}
assert(loadfile("Modules/RecentlyAdded.lua"))("BetterFriendlist", BFL)
module:Initialize()
Settle()
wowCount = 1
wow[1] = { name = "Existing-Realm" }
events.FRIENDLIST_UPDATE()
wowCount = 2
wow[2] = { name = "AlsoExisting-Realm" }
events.FRIENDLIST_UPDATE()
Settle()
assert(not module:IsFriendRecentlyAdded("wow_Existing-Realm"), "Late login data was counted as new")
assert(not module:IsFriendRecentlyAdded("wow_AlsoExisting-Realm"), "Partial startup data finalized the baseline")

wowCount = 0
events.FRIENDLIST_UPDATE()
wowCount = 1
events.FRIENDLIST_UPDATE()
wowCount = 2
events.FRIENDLIST_UPDATE()
assert(not module:IsFriendRecentlyAdded("wow_AlsoExisting-Realm"), "Temporarily missing friend was counted as new")
wowCount = 3
wow[3] = { name = "New-Realm" }
events.FRIENDLIST_UPDATE()
assert(module:IsFriendRecentlyAdded("wow_New-Realm"), "A genuine addition should be counted")
local originalTimestamp = BetterFriendlistDB.recentlyAddedTimestamps["wow_New-Realm"]
now = now + 30
wowCount = 2
events.FRIENDLIST_UPDATE()
wowCount = 3
events.FRIENDLIST_UPDATE()
assert(BetterFriendlistDB.recentlyAddedTimestamps["wow_New-Realm"] == originalTimestamp, "A temporary omission reset the age")

bnetCount = 3
bnet[1] = { battleTag = "Existing#1" }
bnet[2] = { title = true }
events.BN_FRIEND_LIST_SIZE_CHANGED()
Settle()
bnet[3] = { battleTag = "Existing#2" }
events.BN_FRIEND_INFO_CHANGED()
Settle()
assert(not module:IsFriendRecentlyAdded("bnet_Existing#2"), "An incomplete BNet list finalized the baseline")
bnetCount = 4
bnet[4] = { battleTag = "New#3" }
events.BN_FRIEND_LIST_SIZE_CHANGED()
assert(module:IsFriendRecentlyAdded("bnet_New#3"), "A genuine BNet addition should be counted")

connected = false
events.BN_DISCONNECTED()
bnetCount = 0
events.BN_FRIEND_LIST_SIZE_CHANGED()
Settle()
connected = true
events.BN_CONNECTED()
bnetCount = 4
events.BN_FRIEND_LIST_SIZE_CHANGED()
Settle()
assert(not module:IsFriendRecentlyAdded("bnet_Existing#1"), "Reconnect reset an existing friendship")
assert(BetterFriendlistDB.recentlyAddedTimestamps["bnet_New#3"] == now, "Reconnect reset a recent friendship's age")

enabled = false
wowCount = 4
wow[4] = { name = "WhileDisabled-Realm" }
events.FRIENDLIST_UPDATE()
enabled = true
module:OnFeatureEnabled()
Settle()
assert(not module:IsFriendRecentlyAdded("wow_WhileDisabled-Realm"), "Enabling backdated a friendship")
now = now + 7 * 86400
events.FRIENDLIST_UPDATE()
assert(next(BetterFriendlistDB.recentlyAddedTimestamps) == nil, "Expired timestamps should be pruned")
assert(BetterFriendlistDB.knownFriendUIDs["wow_New-Realm"], "Expiring a timestamp erased the identity")
io.write("Recently Added smoke passed\n")
