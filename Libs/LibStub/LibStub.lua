--[[Perfy has instrumented this file]] local Perfy_GetTime, Perfy_Trace, Perfy_Trace_Passthrough = Perfy_GetTime, Perfy_Trace, Perfy_Trace_Passthrough; Perfy_Trace(Perfy_GetTime(), "Enter", "(main chunk) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibStub/LibStub.lua"); -- LibStub is a simple versioning stub meant for use in Libraries.  http://www.wowace.com/addons/libstub/ for more info
-- LibStub is hereby placed in the Public Domain
-- Credits: Kaelten, Cladhaire, ckknight, Mikk, Ammo, Nevcairiel, joshborke
local LIBSTUB_MAJOR, LIBSTUB_MINOR = "LibStub", 2
local LibStub = _G[LIBSTUB_MAJOR]

-- Check to see is this version of the stub is obsolete
if not LibStub or LibStub.minor < LIBSTUB_MINOR then
	LibStub = LibStub or {libs = {}, minors = {} }
	_G[LIBSTUB_MAJOR] = LibStub
	LibStub.minor = LIBSTUB_MINOR
	
	-- LibStub:NewLibrary(major, minor)
	-- major (string) - the major version of the library
	-- minor (string or number ) - the minor version of the library
	-- 
	-- returns nil if a newer or same version of the lib is already present
	-- returns empty library object or old library object if upgrade is needed
	function LibStub:NewLibrary(major, minor) Perfy_Trace(Perfy_GetTime(), "Enter", "LibStub:NewLibrary file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibStub/LibStub.lua:19:1");
		assert(type(major) == "string", "Bad argument #2 to `NewLibrary' (string expected)")
		minor = assert(tonumber(strmatch(minor, "%d+")), "Minor version must either be a number or contain a number.")
		
		local oldminor = self.minors[major]
		if oldminor and oldminor >= minor then Perfy_Trace(Perfy_GetTime(), "Leave", "LibStub:NewLibrary file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibStub/LibStub.lua:19:1"); return nil end
		self.minors[major], self.libs[major] = minor, self.libs[major] or {}
		return Perfy_Trace_Passthrough("Leave", "LibStub:NewLibrary file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibStub/LibStub.lua:19:1", self.libs[major], oldminor)
	end
	
	-- LibStub:GetLibrary(major, [silent])
	-- major (string) - the major version of the library
	-- silent (boolean) - if true, library is optional, silently return nil if its not found
	--
	-- throws an error if the library can not be found (except silent is set)
	-- returns the library object if found
	function LibStub:GetLibrary(major, silent) Perfy_Trace(Perfy_GetTime(), "Enter", "LibStub:GetLibrary file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibStub/LibStub.lua:35:1");
		if not self.libs[major] and not silent then
			error(("Cannot find a library instance of %q."):format(tostring(major)), 2)
		end
		return Perfy_Trace_Passthrough("Leave", "LibStub:GetLibrary file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibStub/LibStub.lua:35:1", self.libs[major], self.minors[major])
	end
	
	-- LibStub:IterateLibraries()
	-- 
	-- Returns an iterator for the currently registered libraries
	function LibStub:IterateLibraries() Perfy_Trace(Perfy_GetTime(), "Enter", "LibStub:IterateLibraries file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibStub/LibStub.lua:45:1"); 
		return Perfy_Trace_Passthrough("Leave", "LibStub:IterateLibraries file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibStub/LibStub.lua:45:1", pairs(self.libs)) 
	end
	
	setmetatable(LibStub, { __call = LibStub.GetLibrary })
end


Perfy_Trace(Perfy_GetTime(), "Leave", "(main chunk) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibStub/LibStub.lua");