--[[Perfy has instrumented this file]] local Perfy_GetTime, Perfy_Trace, Perfy_Trace_Passthrough = Perfy_GetTime, Perfy_Trace, Perfy_Trace_Passthrough; Perfy_Trace(Perfy_GetTime(), "Enter", "(main chunk) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/widgets/checkbox.lua"); local MINOR = 13
local lib, minor = LibStub('LibEditMode')
if minor > MINOR then
	Perfy_Trace(Perfy_GetTime(), "Leave", "(main chunk) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/widgets/checkbox.lua"); return
end

local function showTooltip(self) Perfy_Trace(Perfy_GetTime(), "Enter", "showTooltip file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/widgets/checkbox.lua:7:6");
	if self.setting and self.setting.desc then
		SettingsTooltip:SetOwner(self, 'ANCHOR_NONE')
		SettingsTooltip:SetPoint('BOTTOMRIGHT', self, 'TOPLEFT')
		SettingsTooltip:SetText(self.setting.name, 1, 1, 1)
		SettingsTooltip:AddLine(self.setting.desc)
		SettingsTooltip:Show()
	end
Perfy_Trace(Perfy_GetTime(), "Leave", "showTooltip file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/widgets/checkbox.lua:7:6"); end

local checkboxMixin = {}
function checkboxMixin:Setup(data) Perfy_Trace(Perfy_GetTime(), "Enter", "checkboxMixin:Setup file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/widgets/checkbox.lua:18:0");
	self.setting = data
	self.Label:SetText(data.name)
	self:SetEnabled(not data.disabled)

	local value = data.get(lib:GetActiveLayoutName())
	if value == nil then
		value = data.default
	end

	self.checked = value
	self.Button:SetChecked(not not value) -- force boolean
Perfy_Trace(Perfy_GetTime(), "Leave", "checkboxMixin:Setup file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/widgets/checkbox.lua:18:0"); end

function checkboxMixin:OnCheckButtonClick() Perfy_Trace(Perfy_GetTime(), "Enter", "checkboxMixin:OnCheckButtonClick file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/widgets/checkbox.lua:32:0");
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	self.checked = not self.checked
	self.setting.set(lib:GetActiveLayoutName(), not not self.checked, false)
Perfy_Trace(Perfy_GetTime(), "Leave", "checkboxMixin:OnCheckButtonClick file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/widgets/checkbox.lua:32:0"); end

function checkboxMixin:SetEnabled(enabled) Perfy_Trace(Perfy_GetTime(), "Enter", "checkboxMixin:SetEnabled file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/widgets/checkbox.lua:38:0");
	self.Button:SetEnabled(enabled)
	self.Label:SetTextColor((enabled and WHITE_FONT_COLOR or DISABLED_FONT_COLOR):GetRGB())
Perfy_Trace(Perfy_GetTime(), "Leave", "checkboxMixin:SetEnabled file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/widgets/checkbox.lua:38:0"); end

lib.internal:CreatePool(lib.SettingType.Checkbox, function() Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/widgets/checkbox.lua:43:50");
	local frame = CreateFrame('Frame', nil, UIParent, 'EditModeSettingCheckboxTemplate')
	frame:SetScript('OnLeave', DefaultTooltipMixin.OnLeave)
	frame:SetScript('OnEnter', showTooltip)
	return Perfy_Trace_Passthrough("Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/widgets/checkbox.lua:43:50", Mixin(frame, checkboxMixin))
end, function(_, frame) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/widgets/checkbox.lua:48:5");
	frame:Hide()
	frame.layoutIndex = nil
Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/widgets/checkbox.lua:48:5"); end)

Perfy_Trace(Perfy_GetTime(), "Leave", "(main chunk) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/widgets/checkbox.lua");