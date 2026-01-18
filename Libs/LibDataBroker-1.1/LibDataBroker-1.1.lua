--[[Perfy has instrumented this file]] local Perfy_GetTime, Perfy_Trace, Perfy_Trace_Passthrough = Perfy_GetTime, Perfy_Trace, Perfy_Trace_Passthrough; Perfy_Trace(Perfy_GetTime(), "Enter", "(main chunk) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibDataBroker-1.1/LibDataBroker-1.1.lua"); assert(LibStub, "LibDataBroker-1.1 requires LibStub")
assert(LibStub:GetLibrary("CallbackHandler-1.0", true), "LibDataBroker-1.1 requires CallbackHandler-1.0")

local lib, oldminor = LibStub:NewLibrary("LibDataBroker-1.1", 4)
if not lib then Perfy_Trace(Perfy_GetTime(), "Leave", "(main chunk) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibDataBroker-1.1/LibDataBroker-1.1.lua"); return end
oldminor = oldminor or 0


lib.callbacks = lib.callbacks or LibStub:GetLibrary("CallbackHandler-1.0"):New(lib)
lib.attributestorage, lib.namestorage, lib.proxystorage = lib.attributestorage or {}, lib.namestorage or {}, lib.proxystorage or {}
local attributestorage, namestorage, callbacks = lib.attributestorage, lib.namestorage, lib.callbacks

if oldminor < 2 then
	lib.domt = {
		__metatable = "access denied",
		__index = function(self, key) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibDataBroker-1.1/LibDataBroker-1.1.lua:16:12"); return Perfy_Trace_Passthrough("Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibDataBroker-1.1/LibDataBroker-1.1.lua:16:12", attributestorage[self] and attributestorage[self][key]) end,
	}
end

if oldminor < 3 then
	lib.domt.__newindex = function(self, key, value) Perfy_Trace(Perfy_GetTime(), "Enter", "domt.__newindex file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibDataBroker-1.1/LibDataBroker-1.1.lua:21:23");
		if not attributestorage[self] then attributestorage[self] = {} end
		if attributestorage[self][key] == value then Perfy_Trace(Perfy_GetTime(), "Leave", "domt.__newindex file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibDataBroker-1.1/LibDataBroker-1.1.lua:21:23"); return end
		attributestorage[self][key] = value
		local name = namestorage[self]
		if not name then Perfy_Trace(Perfy_GetTime(), "Leave", "domt.__newindex file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibDataBroker-1.1/LibDataBroker-1.1.lua:21:23"); return end
		callbacks:Fire("LibDataBroker_AttributeChanged", name, key, value, self)
		callbacks:Fire("LibDataBroker_AttributeChanged_"..name, name, key, value, self)
		callbacks:Fire("LibDataBroker_AttributeChanged_"..name.."_"..key, name, key, value, self)
		callbacks:Fire("LibDataBroker_AttributeChanged__"..key, name, key, value, self)
	Perfy_Trace(Perfy_GetTime(), "Leave", "domt.__newindex file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibDataBroker-1.1/LibDataBroker-1.1.lua:21:23"); end
end

if oldminor < 2 then
	function lib:NewDataObject(name, dataobj) Perfy_Trace(Perfy_GetTime(), "Enter", "lib:NewDataObject file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibDataBroker-1.1/LibDataBroker-1.1.lua:35:1");
		if self.proxystorage[name] then Perfy_Trace(Perfy_GetTime(), "Leave", "lib:NewDataObject file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibDataBroker-1.1/LibDataBroker-1.1.lua:35:1"); return end

		if dataobj then
			assert(type(dataobj) == "table", "Invalid dataobj, must be nil or a table")
			self.attributestorage[dataobj] = {}
			for i,v in pairs(dataobj) do
				self.attributestorage[dataobj][i] = v
				dataobj[i] = nil
			end
		end
		dataobj = setmetatable(dataobj or {}, self.domt)
		self.proxystorage[name], self.namestorage[dataobj] = dataobj, name
		self.callbacks:Fire("LibDataBroker_DataObjectCreated", name, dataobj)
		Perfy_Trace(Perfy_GetTime(), "Leave", "lib:NewDataObject file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibDataBroker-1.1/LibDataBroker-1.1.lua:35:1"); return dataobj
	end
end

if oldminor < 1 then
	function lib:DataObjectIterator() Perfy_Trace(Perfy_GetTime(), "Enter", "lib:DataObjectIterator file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibDataBroker-1.1/LibDataBroker-1.1.lua:54:1");
		return Perfy_Trace_Passthrough("Leave", "lib:DataObjectIterator file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibDataBroker-1.1/LibDataBroker-1.1.lua:54:1", pairs(self.proxystorage))
	end

	function lib:GetDataObjectByName(dataobjectname) Perfy_Trace(Perfy_GetTime(), "Enter", "lib:GetDataObjectByName file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibDataBroker-1.1/LibDataBroker-1.1.lua:58:1");
		return Perfy_Trace_Passthrough("Leave", "lib:GetDataObjectByName file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibDataBroker-1.1/LibDataBroker-1.1.lua:58:1", self.proxystorage[dataobjectname])
	end

	function lib:GetNameByDataObject(dataobject) Perfy_Trace(Perfy_GetTime(), "Enter", "lib:GetNameByDataObject file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibDataBroker-1.1/LibDataBroker-1.1.lua:62:1");
		return Perfy_Trace_Passthrough("Leave", "lib:GetNameByDataObject file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibDataBroker-1.1/LibDataBroker-1.1.lua:62:1", self.namestorage[dataobject])
	end
end

if oldminor < 4 then
	local next = pairs(attributestorage)
	function lib:pairs(dataobject_or_name) Perfy_Trace(Perfy_GetTime(), "Enter", "lib:pairs file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibDataBroker-1.1/LibDataBroker-1.1.lua:69:1");
		local t = type(dataobject_or_name)
		assert(t == "string" or t == "table", "Usage: ldb:pairs('dataobjectname') or ldb:pairs(dataobject)")

		local dataobj = self.proxystorage[dataobject_or_name] or dataobject_or_name
		assert(attributestorage[dataobj], "Data object not found")

		return Perfy_Trace_Passthrough("Leave", "lib:pairs file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibDataBroker-1.1/LibDataBroker-1.1.lua:69:1", next, attributestorage[dataobj], nil)
	end

	local ipairs_iter = ipairs(attributestorage)
	function lib:ipairs(dataobject_or_name) Perfy_Trace(Perfy_GetTime(), "Enter", "lib:ipairs file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibDataBroker-1.1/LibDataBroker-1.1.lua:80:1");
		local t = type(dataobject_or_name)
		assert(t == "string" or t == "table", "Usage: ldb:ipairs('dataobjectname') or ldb:ipairs(dataobject)")

		local dataobj = self.proxystorage[dataobject_or_name] or dataobject_or_name
		assert(attributestorage[dataobj], "Data object not found")

		return Perfy_Trace_Passthrough("Leave", "lib:ipairs file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibDataBroker-1.1/LibDataBroker-1.1.lua:80:1", ipairs_iter, attributestorage[dataobj], 0)
	end
end

Perfy_Trace(Perfy_GetTime(), "Leave", "(main chunk) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibDataBroker-1.1/LibDataBroker-1.1.lua");