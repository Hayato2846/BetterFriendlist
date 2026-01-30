--[[Perfy has instrumented this file]] local Perfy_GetTime, Perfy_Trace, Perfy_Trace_Passthrough = Perfy_GetTime, Perfy_Trace, Perfy_Trace_Passthrough; Perfy_Trace(Perfy_GetTime(), "Enter", "(main chunk) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/widgets/slider.lua"); local MINOR = 13
local lib, minor = LibStub('LibEditMode')
if minor > MINOR then
	Perfy_Trace(Perfy_GetTime(), "Leave", "(main chunk) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/widgets/slider.lua"); return
end

local function showTooltip(self) Perfy_Trace(Perfy_GetTime(), "Enter", "showTooltip file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/widgets/slider.lua:7:6");
	if self.setting and self.setting.desc then
		SettingsTooltip:SetOwner(self, 'ANCHOR_NONE')
		SettingsTooltip:SetPoint('BOTTOMRIGHT', self, 'TOPLEFT')
		SettingsTooltip:SetText(self.setting.name, 1, 1, 1)
		SettingsTooltip:AddLine(self.setting.desc)
		SettingsTooltip:Show()
	end
Perfy_Trace(Perfy_GetTime(), "Leave", "showTooltip file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/widgets/slider.lua:7:6"); end

local sliderMixin = {}
function sliderMixin:Setup(data) Perfy_Trace(Perfy_GetTime(), "Enter", "sliderMixin:Setup file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/widgets/slider.lua:18:0");
	self.setting = data
	self.Label:SetText(data.name)
	self:SetEnabled(not data.disabled)

	self.initInProgress = true
	self.formatters = {}
	self.formatters[MinimalSliderWithSteppersMixin.Label.Right] = CreateMinimalSliderFormatter(MinimalSliderWithSteppersMixin.Label.Right, data.formatter)

	local stepSize = data.valueStep or 1
	local steps = (data.maxValue - data.minValue) / stepSize
	self.Slider:Init(data.get(lib:GetActiveLayoutName()) or data.default, data.minValue or 0, data.maxValue or 1, steps, self.formatters)
	self.initInProgress = false
Perfy_Trace(Perfy_GetTime(), "Leave", "sliderMixin:Setup file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/widgets/slider.lua:18:0"); end

function sliderMixin:OnSliderValueChanged(value) Perfy_Trace(Perfy_GetTime(), "Enter", "sliderMixin:OnSliderValueChanged file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/widgets/slider.lua:33:0");
	if not self.initInProgress then
		self.setting.set(lib:GetActiveLayoutName(), value, false)
	end
Perfy_Trace(Perfy_GetTime(), "Leave", "sliderMixin:OnSliderValueChanged file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/widgets/slider.lua:33:0"); end

function sliderMixin:SetEnabled(enabled) Perfy_Trace(Perfy_GetTime(), "Enter", "sliderMixin:SetEnabled file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/widgets/slider.lua:39:0");
	self.Slider:SetEnabled(enabled)
	self.Label:SetTextColor((enabled and WHITE_FONT_COLOR or DISABLED_FONT_COLOR):GetRGB())
	self.EditBox:SetShown(enabled)
Perfy_Trace(Perfy_GetTime(), "Leave", "sliderMixin:SetEnabled file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/widgets/slider.lua:39:0"); end

local function onEditFocus(self) Perfy_Trace(Perfy_GetTime(), "Enter", "onEditFocus file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/widgets/slider.lua:45:6");
	local parent = self:GetParent()

	-- hide slider
	parent.Slider:Hide()

	-- resize editbox to take up the available space
	self:ClearAllPoints()
	self:SetPoint('RIGHT', parent.Slider.RightText, 5, 0)
	self:SetPoint('TOPLEFT', parent.Slider)
	self:SetPoint('BOTTOMLEFT', parent.Slider)

	-- set editbox text to current slider value
	-- TODO: maybe flatten the value here
	self:SetText(parent.Slider.Slider:GetValue())
	self:SetCursorPosition(0)
Perfy_Trace(Perfy_GetTime(), "Leave", "onEditFocus file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/widgets/slider.lua:45:6"); end

local function onEditSubmit(self) Perfy_Trace(Perfy_GetTime(), "Enter", "onEditSubmit file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/widgets/slider.lua:63:6");
	local parent = self:GetParent()

	-- get bounds and value
	local min, max = parent.Slider.Slider:GetMinMaxValues()
	local value = self:GetText()

	-- trigger change if value is a valid number
	if tonumber(value) then
		-- use bounds when updating value
		parent.Slider:SetValue(math.min(math.max(value, min), max))
	end

	self:ClearFocus()
Perfy_Trace(Perfy_GetTime(), "Leave", "onEditSubmit file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/widgets/slider.lua:63:6"); end

local function onEditReset(self) Perfy_Trace(Perfy_GetTime(), "Enter", "onEditReset file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/widgets/slider.lua:79:6");
	local parent = self:GetParent()
	parent.Slider:Show()

	self:SetText('')
	self:ClearFocus()

	self:ClearAllPoints()
	self:SetPoint('RIGHT', parent.Slider.RightText, 5, 0)
	self:SetPoint('TOPLEFT', parent.Slider.RightText)
	self:SetPoint('BOTTOMLEFT', parent.Slider.RightText)
Perfy_Trace(Perfy_GetTime(), "Leave", "onEditReset file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/widgets/slider.lua:79:6"); end

lib.internal:CreatePool(lib.SettingType.Slider, function() Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/widgets/slider.lua:92:48");
	local frame = CreateFrame('Frame', nil, UIParent, 'EditModeSettingSliderTemplate')
	frame:SetScript('OnLeave', DefaultTooltipMixin.OnLeave)
	frame:SetScript('OnEnter', showTooltip)
	Mixin(frame, sliderMixin)

	frame:SetHeight(32)
	frame.Slider:SetWidth(200)
	frame.Slider.MinText:Hide()
	frame.Slider.MaxText:Hide()
	frame.Label:SetPoint('LEFT')

	local editBox = CreateFrame('EditBox', nil, frame, 'InputBoxTemplate')
	editBox:SetPoint('TOPLEFT', frame.Slider.RightText)
	editBox:SetPoint('BOTTOMLEFT', frame.Slider.RightText)
	editBox:SetPoint('RIGHT', frame.Slider.RightText, 5, 0)
	editBox:SetAutoFocus(false)
	editBox:SetJustifyH('CENTER')
	editBox:SetScript('OnEditFocusGained', onEditFocus)
	editBox:SetScript('OnEnterPressed', onEditSubmit)
	editBox:SetScript('OnEscapePressed', onEditReset)
	editBox:SetScript('OnEditFocusLost', onEditReset)
	frame.EditBox = editBox

	frame:OnLoad()
	Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/widgets/slider.lua:92:48"); return frame
end, function(_, frame) Perfy_Trace(Perfy_GetTime(), "Enter", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/widgets/slider.lua:118:5");
	frame:Hide()
	frame.layoutIndex = nil
Perfy_Trace(Perfy_GetTime(), "Leave", "(anonymous) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/widgets/slider.lua:118:5"); end)

Perfy_Trace(Perfy_GetTime(), "Leave", "(main chunk) file://c:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\BetterFriendlist\\Libs/LibEditMode/widgets/slider.lua");