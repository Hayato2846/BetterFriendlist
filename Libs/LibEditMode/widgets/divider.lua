--[[Perfy has instrumented this file]] local Perfy_GetTime, Perfy_Trace, Perfy_Trace_Passthrough = Perfy_GetTime, Perfy_Trace, Perfy_Trace_Passthrough; Perfy_Trace(Perfy_GetTime(), "Enter", "(main chunk) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/widgets/divider.lua"); local MINOR = 13
local lib, minor = LibStub('LibEditMode')
if minor > MINOR then
	Perfy_Trace(Perfy_GetTime(), "Leave", "(main chunk) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/widgets/divider.lua"); return
end

lib.SettingType.Divider = 'divider'

local dividerMixin = {}
function dividerMixin:Setup(data) Perfy_Trace(Perfy_GetTime(), "Enter", "dividerMixin:Setup file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/widgets/divider.lua:10:0");
	self.setting = data
	self.Label:SetText(data.name)
Perfy_Trace(Perfy_GetTime(), "Leave", "dividerMixin:Setup file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/widgets/divider.lua:10:0"); end

lib.internal:CreatePool(lib.SettingType.Divider, function() Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/widgets/divider.lua:15:49");
	local frame = Mixin(CreateFrame('Frame', nil, UIParent), dividerMixin)
	frame:SetSize(330, 16)

	local texture = frame:CreateTexture(nil, 'ARTWORK')
	texture:SetAllPoints()
	texture:SetTexture([[Interface\FriendsFrame\UI-FriendsFrame-OnlineDivider]])

	local label = frame:CreateFontString(nil, nil, 'GameFontHighlightLarge')
	label:SetAllPoints()
	frame.Label = label

	Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/widgets/divider.lua:15:49"); return frame
end, function(_, frame) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/widgets/divider.lua:28:5");
	frame:Hide()
	frame.Label:SetText()
	frame.layoutIndex = nil
Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/widgets/divider.lua:28:5"); end)

Perfy_Trace(Perfy_GetTime(), "Leave", "(main chunk) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/widgets/divider.lua");