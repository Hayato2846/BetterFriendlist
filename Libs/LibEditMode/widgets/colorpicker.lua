--[[Perfy has instrumented this file]] local Perfy_GetTime, Perfy_Trace, Perfy_Trace_Passthrough = Perfy_GetTime, Perfy_Trace, Perfy_Trace_Passthrough; Perfy_Trace(Perfy_GetTime(), "Enter", "(main chunk) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/widgets/colorpicker.lua"); local MINOR = 13
local lib, minor = LibStub('LibEditMode')
if minor > MINOR then
	Perfy_Trace(Perfy_GetTime(), "Leave", "(main chunk) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/widgets/colorpicker.lua"); return
end

local function showTooltip(self) Perfy_Trace(Perfy_GetTime(), "Enter", "showTooltip file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/widgets/colorpicker.lua:7:6");
	if self.setting and self.setting.desc then
		SettingsTooltip:SetOwner(self, 'ANCHOR_NONE')
		SettingsTooltip:SetPoint('BOTTOMRIGHT', self, 'TOPLEFT')
		SettingsTooltip:SetText(self.setting.name, 1, 1, 1)
		SettingsTooltip:AddLine(self.setting.desc)
		SettingsTooltip:Show()
	end
Perfy_Trace(Perfy_GetTime(), "Leave", "showTooltip file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/widgets/colorpicker.lua:7:6"); end

local function onColorChanged(self) Perfy_Trace(Perfy_GetTime(), "Enter", "onColorChanged file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/widgets/colorpicker.lua:17:6");
	local r, g, b = ColorPickerFrame:GetColorRGB()
	if self.colorInfo.hasOpacity then
		local a = ColorPickerFrame:GetColorAlpha()
		self:OnColorChanged(CreateColor(r, g, b, a))
	else
		self:OnColorChanged(CreateColor(r, g, b))
	end
Perfy_Trace(Perfy_GetTime(), "Leave", "onColorChanged file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/widgets/colorpicker.lua:17:6"); end

local function onColorCancel(self) Perfy_Trace(Perfy_GetTime(), "Enter", "onColorCancel file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/widgets/colorpicker.lua:27:6");
	self:OnColorChanged(self.oldValue)
Perfy_Trace(Perfy_GetTime(), "Leave", "onColorCancel file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/widgets/colorpicker.lua:27:6"); end

local colorPickerMixin = {}
function colorPickerMixin:Setup(data) Perfy_Trace(Perfy_GetTime(), "Enter", "colorPickerMixin:Setup file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/widgets/colorpicker.lua:32:0");
	self.setting = data
	self.Label:SetText(data.name)
	self:SetEnabled(not data.disabled)

	local value = data.get(lib:GetActiveLayoutName())
	if value == nil then
		value = data.default
	end

	local r, g, b, a = value:GetRGBA()
	self.colorInfo = {
		swatchFunc = GenerateClosure(onColorChanged, self),
		opacityFunc = GenerateClosure(onColorChanged, self),
		cancelFunc = GenerateClosure(onColorCancel, self),
		r = r,
		g = g,
		b = b,
		opacity = a,
		hasOpacity = data.hasOpacity
	}

	self.Swatch:SetColorRGB(r, g, b)
Perfy_Trace(Perfy_GetTime(), "Leave", "colorPickerMixin:Setup file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/widgets/colorpicker.lua:32:0"); end

function colorPickerMixin:OnColorChanged(color) Perfy_Trace(Perfy_GetTime(), "Enter", "colorPickerMixin:OnColorChanged file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/widgets/colorpicker.lua:57:0");
	self.setting.set(lib:GetActiveLayoutName(), color, false)

	local r, g, b, a = color:GetRGBA()
	self.Swatch:SetColorRGB(r, g, b)

	-- update colorInfo for next run
	self.colorInfo.r = r
	self.colorInfo.g = g
	self.colorInfo.b = b
	self.colorInfo.opacity = a
Perfy_Trace(Perfy_GetTime(), "Leave", "colorPickerMixin:OnColorChanged file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/widgets/colorpicker.lua:57:0"); end

function colorPickerMixin:SetEnabled(enabled) Perfy_Trace(Perfy_GetTime(), "Enter", "colorPickerMixin:SetEnabled file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/widgets/colorpicker.lua:70:0");
	self.Swatch:SetEnabled(enabled)
	self.Label:SetTextColor((enabled and WHITE_FONT_COLOR or DISABLED_FONT_COLOR):GetRGB())
Perfy_Trace(Perfy_GetTime(), "Leave", "colorPickerMixin:SetEnabled file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/widgets/colorpicker.lua:70:0"); end

local function onSwatchClick(self) Perfy_Trace(Perfy_GetTime(), "Enter", "onSwatchClick file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/widgets/colorpicker.lua:75:6");
	local parent = self:GetParent()
	local info = parent.colorInfo

	-- store current/previous colors for reset capabilities
	parent.oldValue = CreateColor(info.r, info.g, info.b, info.opacity)

	ColorPickerFrame:SetupColorPickerAndShow(info)
Perfy_Trace(Perfy_GetTime(), "Leave", "onSwatchClick file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/widgets/colorpicker.lua:75:6"); end

lib.internal:CreatePool(lib.SettingType.ColorPicker, function() Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/widgets/colorpicker.lua:85:53");
	local frame = CreateFrame('Frame', nil, UIParent, 'ResizeLayoutFrame')
	frame.fixedHeight = 32 -- default attribute
	frame:Hide() -- default state
	frame:SetScript('OnLeave', DefaultTooltipMixin.OnLeave)
	frame:SetScript('OnEnter', showTooltip)

	-- recreate EditModeSetting* widgets
	local Label = frame:CreateFontString(nil, 'ARTWORK', 'GameFontHighlightMedium')
	Label:SetPoint('LEFT')
	Label:SetSize(100, 32)
	Label:SetJustifyH('LEFT')
	frame.Label = Label

	local Swatch = CreateFrame('Button', nil, frame, 'ColorSwatchTemplate')
	Swatch:SetSize(32, 32)
	Swatch:SetPoint('LEFT', Label, 'RIGHT', 5, 0)
	Swatch:SetScript('OnClick', onSwatchClick)
	frame.Swatch = Swatch

	return Perfy_Trace_Passthrough("Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/widgets/colorpicker.lua:85:53", Mixin(frame, colorPickerMixin))
end, function(_, frame) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/widgets/colorpicker.lua:106:5");
	frame:Hide()
	frame.layoutIndex = nil
Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/widgets/colorpicker.lua:106:5"); end)

Perfy_Trace(Perfy_GetTime(), "Leave", "(main chunk) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/widgets/colorpicker.lua");