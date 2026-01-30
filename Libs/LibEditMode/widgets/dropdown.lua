--[[Perfy has instrumented this file]] local Perfy_GetTime, Perfy_Trace, Perfy_Trace_Passthrough = Perfy_GetTime, Perfy_Trace, Perfy_Trace_Passthrough; Perfy_Trace(Perfy_GetTime(), "Enter", "(main chunk) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/widgets/dropdown.lua"); local MINOR = 13
local lib, minor = LibStub('LibEditMode')
if minor > MINOR then
	Perfy_Trace(Perfy_GetTime(), "Leave", "(main chunk) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/widgets/dropdown.lua"); return
end

local function showTooltip(self) Perfy_Trace(Perfy_GetTime(), "Enter", "showTooltip file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/widgets/dropdown.lua:7:6");
	if self.setting and self.setting.desc then
		SettingsTooltip:SetOwner(self, 'ANCHOR_NONE')
		SettingsTooltip:SetPoint('BOTTOMRIGHT', self, 'TOPLEFT')
		SettingsTooltip:SetText(self.setting.name, 1, 1, 1)
		SettingsTooltip:AddLine(self.setting.desc)
		SettingsTooltip:Show()
	end
Perfy_Trace(Perfy_GetTime(), "Leave", "showTooltip file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/widgets/dropdown.lua:7:6"); end

local function get(data) Perfy_Trace(Perfy_GetTime(), "Enter", "get file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/widgets/dropdown.lua:17:6");
	local value = data.get(lib:GetActiveLayoutName())
	if value then
		if data.multiple then
			assert(type(value) == 'table', "multiple choice dropdowns expects a table from 'get'")

			for _, v in next, value do
				if v == data.value then
					Perfy_Trace(Perfy_GetTime(), "Leave", "get file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/widgets/dropdown.lua:17:6"); return true
				end
			end
		else
			return Perfy_Trace_Passthrough("Leave", "get file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/widgets/dropdown.lua:17:6", value == data.value)
		end
	end
Perfy_Trace(Perfy_GetTime(), "Leave", "get file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/widgets/dropdown.lua:17:6"); end

local function set(data) Perfy_Trace(Perfy_GetTime(), "Enter", "set file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/widgets/dropdown.lua:34:6");
	data.set(lib:GetActiveLayoutName(), data.value, false)
Perfy_Trace(Perfy_GetTime(), "Leave", "set file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/widgets/dropdown.lua:34:6"); end

local dropdownMixin = {}
function dropdownMixin:Setup(data) Perfy_Trace(Perfy_GetTime(), "Enter", "dropdownMixin:Setup file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/widgets/dropdown.lua:39:0");
	self.setting = data
	self.Label:SetText(data.name)
	self:SetEnabled(not data.disabled)

	if data.generator then
		-- let the user have full control
		self.Dropdown:SetupMenu(function(owner, rootDescription) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/widgets/dropdown.lua:46:26");
			pcall(data.generator, owner, rootDescription, data)
		Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/widgets/dropdown.lua:46:26"); end)
	elseif data.values then
		self.Dropdown:SetupMenu(function(_, rootDescription) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/widgets/dropdown.lua:50:26");
			if data.height then
				rootDescription:SetScrollMode(data.height)
			end

			for _, value in next, data.values do
				if data.multiple then
					rootDescription:CreateCheckbox(value.text, get, set, {
						get = data.get,
						set = data.set,
						value = value.value or value.text,
						multiple = data.multiple,
					})
				else
					rootDescription:CreateRadio(value.text, get, set, {
						get = data.get,
						set = data.set,
						value = value.value or value.text,
						multiple = data.multiple,
					})
				end
			end
		Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/widgets/dropdown.lua:50:26"); end)
	end
Perfy_Trace(Perfy_GetTime(), "Leave", "dropdownMixin:Setup file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/widgets/dropdown.lua:39:0"); end

function dropdownMixin:SetEnabled(enabled) Perfy_Trace(Perfy_GetTime(), "Enter", "dropdownMixin:SetEnabled file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/widgets/dropdown.lua:76:0");
	self.Dropdown:SetEnabled(enabled)
	self.Label:SetTextColor((enabled and WHITE_FONT_COLOR or DISABLED_FONT_COLOR):GetRGB())
Perfy_Trace(Perfy_GetTime(), "Leave", "dropdownMixin:SetEnabled file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/widgets/dropdown.lua:76:0"); end

lib.internal:CreatePool(lib.SettingType.Dropdown, function() Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/widgets/dropdown.lua:81:50");
	local frame = CreateFrame('Frame', nil, UIParent, 'ResizeLayoutFrame')
	frame:SetScript('OnLeave', DefaultTooltipMixin.OnLeave)
	frame:SetScript('OnEnter', showTooltip)
	frame.fixedHeight = 32
	Mixin(frame, dropdownMixin)

	local label = frame:CreateFontString(nil, nil, 'GameFontHighlightMedium')
	label:SetPoint('LEFT')
	label:SetWidth(100)
	label:SetJustifyH('LEFT')
	frame.Label = label

	local dropdown = CreateFrame('DropdownButton', nil, frame, 'WowStyle1DropdownTemplate')
	dropdown:SetPoint('LEFT', label, 'RIGHT', 5, 0)
	dropdown:SetSize(200, 30)
	frame.Dropdown = dropdown

	Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/widgets/dropdown.lua:81:50"); return frame
end, function(_, frame) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/widgets/dropdown.lua:100:5");
	frame:Hide()
	frame.layoutIndex = nil
Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/widgets/dropdown.lua:100:5"); end)

Perfy_Trace(Perfy_GetTime(), "Leave", "(main chunk) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/widgets/dropdown.lua");