--[[Perfy has instrumented this file]] local Perfy_GetTime, Perfy_Trace, Perfy_Trace_Passthrough = Perfy_GetTime, Perfy_Trace, Perfy_Trace_Passthrough; Perfy_Trace(Perfy_GetTime(), "Enter", "(main chunk) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/pools.lua"); local MINOR = 13
local lib, minor = LibStub('LibEditMode')
if minor > MINOR then
	Perfy_Trace(Perfy_GetTime(), "Leave", "(main chunk) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/pools.lua"); return
end

local Acquire = CreateUnsecuredObjectPool().Acquire
local function acquire(self, parent) Perfy_Trace(Perfy_GetTime(), "Enter", "acquire file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/pools.lua:8:6");
	local obj, new = Acquire(self)
	obj:SetParent(parent)
	Perfy_Trace(Perfy_GetTime(), "Leave", "acquire file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/pools.lua:8:6"); return obj, new
end

local pools = {}
function lib.internal:CreatePool(kind, creationFunc, resetterFunc) Perfy_Trace(Perfy_GetTime(), "Enter", "internal:CreatePool file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/pools.lua:15:0");
	local pool = CreateUnsecuredObjectPool(creationFunc, resetterFunc)
	pool.Acquire = acquire
	pools[kind] = pool
Perfy_Trace(Perfy_GetTime(), "Leave", "internal:CreatePool file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/pools.lua:15:0"); end

function lib.internal:GetPool(kind) Perfy_Trace(Perfy_GetTime(), "Enter", "internal:GetPool file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/pools.lua:21:0");
	return Perfy_Trace_Passthrough("Leave", "internal:GetPool file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/pools.lua:21:0", pools[kind])
end

function lib.internal:ReleaseAllPools() Perfy_Trace(Perfy_GetTime(), "Enter", "internal:ReleaseAllPools file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/pools.lua:25:0");
	for _, pool in next, pools do
		pool:ReleaseAll()
	end
Perfy_Trace(Perfy_GetTime(), "Leave", "internal:ReleaseAllPools file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/pools.lua:25:0"); end

Perfy_Trace(Perfy_GetTime(), "Leave", "(main chunk) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/pools.lua");