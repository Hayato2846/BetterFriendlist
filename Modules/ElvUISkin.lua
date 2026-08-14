-- Modules/ElvUISkin.lua
-- ElvUI Skinning Module for BetterFriendlist
-- Adds native ElvUI skin support

local ADDON_NAME, BFL = ...

-- Register Module
local ElvUISkin = BFL:RegisterModule("ElvUISkin", {})

local WHO_CLASSIC_DROPDOWN_X_OFFSET = -12
local WHO_CLASSIC_ELVUI_DROPDOWN_VISUAL_WIDTH = 106
local ELVUI_CLASSIC_STATUS_DROPDOWN_WIDTH = 57
local ELVUI_CLASSIC_MAIN_DROPDOWN_TEXT_Y_OFFSET = 0
local ELVUI_CLASSIC_WHO_COLUMN_DROPDOWN_Y_OFFSET = 2

local IsModernDropdown, CallElvUIHandler = BFL.IsModernDropdown
local classicDropdownSelectedValueFixes = setmetatable({}, { __mode = "k" })
local classicDropdownTextHookInstalled = false

local function GetTexturePathFromMarkup(text)
	if type(text) ~= "string" then
		return nil
	end
	return text:match("|T([^:|]+)")
end

local function NormalizeClassicDropdownTextureMarkup(text)
	if type(text) ~= "string" then
		return text
	end
	return text:gsub(":14:14:%-2:%-2", ":14:14:0:0")
end

local function GetClassicDropdownTextRegion(dropdown)
	if not dropdown then
		return nil
	end

	if dropdown.Text and dropdown.Text.SetText then
		return dropdown.Text
	end
	if dropdown.TextRegion and dropdown.TextRegion.SetText then
		return dropdown.TextRegion
	end
	if dropdown.SelectionText and dropdown.SelectionText.SetText then
		return dropdown.SelectionText
	end
	if dropdown.GetFontString then
		local fontString = dropdown:GetFontString()
		if fontString and fontString.SetText then
			return fontString
		end
	end

	local ddName = dropdown.GetName and dropdown:GetName()
	return ddName and _G[ddName .. "Text"] or nil
end

local function GetClassicDropdownButtonRegion(dropdown)
	if not dropdown then
		return nil
	end
	if dropdown.Button then
		return dropdown.Button
	end

	local ddName = dropdown.GetName and dropdown:GetName()
	return ddName and (_G[ddName .. "Button"] or _G[ddName .. "_Button"]) or nil
end

local function SetClassicDropdownSelectedIcon(dropdown, texturePath, xOffset, yOffset)
	if not (dropdown and texturePath) then
		return nil
	end

	local icon = dropdown.BFL_ClassicSelectedValueIcon
	if not icon then
		icon = dropdown:CreateTexture(nil, "OVERLAY")
		dropdown.BFL_ClassicSelectedValueIcon = icon
	end

	icon:SetTexture(texturePath)
	icon:SetSize(14, 14)
	icon:ClearAllPoints()
	icon:SetPoint("CENTER", dropdown, "CENTER", xOffset or -8, yOffset or 0)
	icon:Show()
	return icon
end

local function ApplyClassicDropdownSelectedValueFix(dropdown)
	local config = classicDropdownSelectedValueFixes[dropdown]
	if not config then
		return
	end

	local text = GetClassicDropdownTextRegion(dropdown)
	if not text then
		return
	end

	if config.normalizeTextureMarkup and text.GetText and text.SetText then
		text:SetText(NormalizeClassicDropdownTextureMarkup(text:GetText()))
	end

	if config.iconOnlySelectedValue and text.GetText and text.SetText then
		local currentText = text:GetText()
		local texturePath = GetTexturePathFromMarkup(currentText)
		if texturePath then
			dropdown.BFL_ClassicSelectedValueIconPath = texturePath
			SetClassicDropdownSelectedIcon(dropdown, texturePath, config.iconXOffset, config.iconYOffset)
			text:SetText("")
			if text.SetAlpha then
				text:SetAlpha(0)
			end
			return
		elseif dropdown.BFL_ClassicSelectedValueIconPath and (currentText == nil or currentText == "") then
			SetClassicDropdownSelectedIcon(
				dropdown,
				dropdown.BFL_ClassicSelectedValueIconPath,
				config.iconXOffset,
				config.iconYOffset
			)
			if text.SetAlpha then
				text:SetAlpha(0)
			end
			return
		end
	end

	if dropdown.BFL_ClassicSelectedValueIcon then
		dropdown.BFL_ClassicSelectedValueIcon:Hide()
	end
	dropdown.BFL_ClassicSelectedValueIconPath = nil
	if text.SetAlpha then
		text:SetAlpha(1)
	end

	local yOffset = config.textYOffset or 0
	text:ClearAllPoints()
	if config.centerSelectedValue then
		local textWidth = math.max((dropdown.BFL_ClassicDropdownWidth or dropdown:GetWidth() or 50) - 20, 1)
		local textHeight = dropdown.BFL_ClassicDropdownHeight or dropdown:GetHeight() or 24
		if text.SetSize then
			text:SetSize(textWidth, textHeight)
		end
		text:SetPoint("CENTER", dropdown, "CENTER", -10, yOffset)
		text:SetJustifyH("CENTER")
		if text.SetJustifyV then
			text:SetJustifyV("MIDDLE")
		end
	else
		local button = GetClassicDropdownButtonRegion(dropdown)
		text:SetPoint("LEFT", dropdown, "LEFT", 8, yOffset)
		if button then
			text:SetPoint("RIGHT", button, "RIGHT", -20, yOffset)
		else
			text:SetPoint("RIGHT", dropdown, "RIGHT", -20, yOffset)
		end
		text:SetJustifyH("LEFT")
	end
	text:SetWordWrap(false)
end

local function ScheduleClassicDropdownSelectedValueFix(dropdown)
	ApplyClassicDropdownSelectedValueFix(dropdown)
	if C_Timer and C_Timer.After then
		C_Timer.After(0, function()
			ApplyClassicDropdownSelectedValueFix(dropdown)
		end)
	end
end

local function RegisterClassicDropdownSelectedValueFix(dropdown)
	if not (dropdown and BFL and BFL.IsClassic) then
		return
	end

	classicDropdownSelectedValueFixes[dropdown] = {
		centerSelectedValue = true,
		iconOnlySelectedValue = true,
		iconXOffset = -8,
		iconYOffset = 0,
		normalizeTextureMarkup = true,
		textYOffset = 0,
	}
	ScheduleClassicDropdownSelectedValueFix(dropdown)

	if not classicDropdownTextHookInstalled and hooksecurefunc and BFL.SetDropdownText then
		classicDropdownTextHookInstalled = true
		hooksecurefunc(BFL, "SetDropdownText", function(updatedDropdown)
			ScheduleClassicDropdownSelectedValueFix(updatedDropdown)
		end)
	end

	if not dropdown.BFL_ClassicSelectedValueHookInstalled then
		dropdown.BFL_ClassicSelectedValueHookInstalled = true
		if dropdown.HookScript then
			dropdown:HookScript("OnShow", function(self)
				ScheduleClassicDropdownSelectedValueFix(self)
			end)
		end
		if hooksecurefunc then
			if dropdown.SetText then
				hooksecurefunc(dropdown, "SetText", function(self)
					ScheduleClassicDropdownSelectedValueFix(self)
				end)
			end
			if dropdown.Update then
				hooksecurefunc(dropdown, "Update", function(self)
					ScheduleClassicDropdownSelectedValueFix(self)
				end)
			end
			if dropdown.GenerateMenu then
				hooksecurefunc(dropdown, "GenerateMenu", function(self)
					ScheduleClassicDropdownSelectedValueFix(self)
				end)
			end
		end
	end
end

-- Helper to handle scrollbars across Retail and Classic
local function SkinScrollBar(S, scrollBar)
	if not scrollBar then
		return
	end

	-- Validation: Ensure scrollBar is an object
	if not scrollBar.IsObjectType then
		return
	end

	local isClassic = BFL and BFL.IsClassic

	if isClassic then
		-- Classic Override: Always use HandleScrollBar
		-- HandleTrimScrollBar does not exist or shouldn't be used in Classic environments
		if S.HandleScrollBar then
			S:HandleScrollBar(scrollBar)
		end
		return
	end

	-- Retail: Check for TrimScrollBar first
	if S.HandleTrimScrollBar then
		S:HandleTrimScrollBar(scrollBar)
	elseif S.HandleScrollBar then
		S:HandleScrollBar(scrollBar)
	end
end

local function GetWhoScrollBar(whoFrame)
	if not whoFrame then
		return nil
	end
	if whoFrame.ScrollBar then
		return whoFrame.ScrollBar
	end
	if whoFrame.ClassicScrollBar then
		return whoFrame.ClassicScrollBar
	end
	if whoFrame.ScrollFrame and whoFrame.ScrollFrame.ScrollBar then
		return whoFrame.ScrollFrame.ScrollBar
	end
	if whoFrame.ScrollFrame and whoFrame.ScrollFrame.GetName then
		return _G[whoFrame.ScrollFrame:GetName() .. "ScrollBar"]
	end
	return _G.BetterWhoScrollBar
end

local function ApplyWhoColumnDropdownAlignment(whoFrame)
	if not (BFL and BFL.IsClassic and whoFrame and whoFrame.ColumnDropdown and whoFrame.NameHeader) then
		return
	end

	local modernDropdown = IsModernDropdown(whoFrame.ColumnDropdown)
	local dropdownOffset = (not modernDropdown) and WHO_CLASSIC_DROPDOWN_X_OFFSET or 0
	whoFrame.ColumnDropdown:ClearAllPoints()
	whoFrame.ColumnDropdown:SetPoint(
		"TOPLEFT",
		whoFrame.NameHeader,
		"TOPRIGHT",
		-1 + dropdownOffset,
		ELVUI_CLASSIC_WHO_COLUMN_DROPDOWN_Y_OFFSET
	)
end

-- Normalize Classic dropdown hitbox/geometry after ElvUI skinning.
-- Without this, the clickable region can drift outside the visual box.
local function FixClassicDropdownHitbox(dropdown, width, height, textYOffset)
	if not (BFL and BFL.IsClassic and dropdown) then
		return
	end

	if width then
		dropdown.BFL_ClassicDropdownWidth = width
	end
	if height then
		dropdown.BFL_ClassicDropdownHeight = height
	end
	if textYOffset ~= nil then
		dropdown.BFL_ClassicDropdownTextYOffset = textYOffset
	end

	local targetWidth = dropdown.BFL_ClassicDropdownWidth
	local targetHeight = dropdown.BFL_ClassicDropdownHeight
	local targetTextYOffset = dropdown.BFL_ClassicDropdownTextYOffset or 0

	if targetWidth and IsModernDropdown(dropdown) and dropdown.SetWidth then
		dropdown:SetWidth(targetWidth)
	elseif targetWidth and BFL.SetDropdownWidth then
		BFL.SetDropdownWidth(dropdown, targetWidth)
		if dropdown.BFL_ClassicColumnLogicalWidth then
			dropdown:SetWidth(dropdown.BFL_ClassicColumnLogicalWidth)
		end
	end
	if targetHeight then
		dropdown:SetHeight(targetHeight)
	end

	local ddName = dropdown.GetName and dropdown:GetName()
	if not ddName then
		return
	end

	local button = _G[ddName .. "Button"]
	local text = _G[ddName .. "Text"]
	if button then
		button:ClearAllPoints()
		button:SetAllPoints(dropdown)
		button:SetHitRectInsets(0, 0, 0, 0)
		if targetHeight then
			button:SetHeight(targetHeight)
		end
	end

	if text and button then
		if classicDropdownSelectedValueFixes[dropdown] then
			ApplyClassicDropdownSelectedValueFix(dropdown)
		else
			text:ClearAllPoints()
			text:SetPoint("LEFT", dropdown, "LEFT", 8, targetTextYOffset)
			text:SetPoint("RIGHT", button, "RIGHT", -20, targetTextYOffset)
			text:SetJustifyH("LEFT")
			text:SetWordWrap(false)
		end
	end

	if not dropdown.BFL_ClassicDropdownHookInstalled then
		dropdown.BFL_ClassicDropdownHookInstalled = true
		if dropdown.HookScript then
			dropdown:HookScript("OnShow", function(self)
				C_Timer.After(0, function()
					if self and self.GetName then
						FixClassicDropdownHitbox(self)
					end
				end)
			end)
		end
		if button and button.HookScript then
			button:HookScript("OnClick", function()
				C_Timer.After(0, function()
					if dropdown and dropdown.GetName then
						FixClassicDropdownHitbox(dropdown)
					end
				end)
			end)
		end
	end
end

local function IsBFLTab(tab)
	local name = tab and tab.GetName and tab:GetName()
	return name
		and (
			string.find(name, "BetterFriendsFrameTab", 1, true)
			or string.find(name, "BetterFriendlistSettingsFrameTab", 1, true)
			or string.find(name, "BetterFriendsFrameBottomTab", 1, true)
		)
end

local function CenterBFLTabText(tab)
	if not IsBFLTab(tab) then
		return
	end

	local text = tab.Text or (tab.GetFontString and tab:GetFontString())
	if not text then
		return
	end

	text:ClearAllPoints()
	text:SetPoint("CENTER", tab, "CENTER", 0, 0)
	text:SetJustifyH("CENTER")
	text:SetJustifyV("MIDDLE")
end

local function CenterNamedTabs(prefix, count)
	for i = 1, count do
		CenterBFLTabText(_G[prefix .. i])
	end
end

local function CenterMainFrameTabs()
	CenterNamedTabs("BetterFriendsFrameTab", 4)
	CenterNamedTabs("BetterFriendsFrameBottomTab", 4)
end

local function DeferCenterBFLTab(tab)
	if C_Timer and C_Timer.After then
		C_Timer.After(0, function()
			CenterBFLTabText(tab)
		end)
	else
		CenterBFLTabText(tab)
	end
end

local function HookBFLTabCenter(tab)
	if not IsBFLTab(tab) or tab.BFL_ElvCenterHooked or not tab.HookScript then
		return
	end

	tab:HookScript("OnShow", CenterBFLTabText)
	tab:HookScript("OnSizeChanged", CenterBFLTabText)
	tab:HookScript("OnClick", DeferCenterBFLTab)
	tab.BFL_ElvCenterHooked = true
end

local function HookNamedTabs(prefix, count)
	for i = 1, count do
		HookBFLTabCenter(_G[prefix .. i])
	end
end

function ElvUISkin:Initialize()
	-- Check if ElvUI is loaded immediately
	self:RegisterTests(); if BFL.IsElvUIAvailable and BFL:IsElvUIAvailable() then
		self:RegisterSkin()
	else
		-- Wait for ElvUI to load (in case BFL loads first)
		-- Check for "ElvUI" or "ElvUI_Classic" or a valid ElvUI engine.
		local listener = CreateFrame("Frame")
		listener:RegisterEvent("ADDON_LOADED")
		listener:SetScript("OnEvent", function(f, event, addonName)
			if addonName == "ElvUI" or addonName == "ElvUI_Classic" or (BFL.IsElvUIAvailable and BFL:IsElvUIAvailable()) then
				if self:RegisterSkin() ~= false then
					f:UnregisterEvent("ADDON_LOADED")
				end
			end
		end)
	end
end

function ElvUISkin:RegisterSkin()
	local E = BFL.GetElvUIEngine and BFL:GetElvUIEngine(false)
	if not E then
		return false
	end
	-- Theme resolution may have cached the Blizzard fallback before ElvUI
	-- finished initializing. Availability changes are rare, explicit lifecycle
	-- events; invalidate here instead of probing ElvUI on every theme lookup.
	local ThemeManager = BFL:GetModule("ThemeManager")
	if ThemeManager and ThemeManager.InvalidateEffectiveTheme then
		ThemeManager:InvalidateEffectiveTheme()
	end

	local isEnabled = self:IsSkinEnabled()
	if not isEnabled then
		-- BFL:DebugPrint("|cff00ffffBFL ElvUI:|r Skin disabled in theme settings")
		return
	end
	self:InstallClassicPortraitGuard()
	-- BFL:DebugPrint("|cff00ffffBFL ElvUI:|r Registering skin...")
	local RealS = E:GetModule("Skins")
	if not RealS then
		-- BFL:DebugPrint("|cff00ffffBFL ElvUI:|r Skins module not found!")
		return false
	end

	-- Create Safety Proxy to prevent nil value crashes in ElvUI Skins module
	local S = setmetatable({}, {
		__index = function(t, k)
			local val = RealS[k]
			if type(val) == "function" then
				return function(_, arg1, ...)
					-- Protect Handlers from nil arguments
					if
						arg1 == nil
						and (
							k == "HandleButton"
							or k == "HandleCheckBox"
							or k == "HandleEditBox"
							or k == "HandleTab"
							or k == "HandleScrollBar"
							or k == "HandleDropDownBox"
							or k == "HandlePortraitFrame"
						)
					then
						-- Silently ignore nil calls to prevent crashes
						return
					end
					return val(RealS, arg1, ...) -- Pass RealS as self
				end
			else
				return val
			end
		end,
		__newindex = function(t, k, v)
			RealS[k] = v
		end,
	})
	self.ElvUIEngine, self.ElvUISkins, self.ElvUISkinProxy = E, RealS, S
	-- Register callback once; ThemeManager may re-apply after theme changes.
	-- The callback itself still covers ElvUI's normal addon skin pass.
	if S.AddCallbackForAddon and not self.ElvUICallbackRegistered then
		self.ElvUICallbackRegistered = true
		S:AddCallbackForAddon("BetterFriendlist", "BetterFriendlist", function()
			-- BFL:DebugPrint("|cff00ffffBFL ElvUI:|r Callback triggered")
			xpcall(function()
				self:SkinFrames(E, S)
			end, function(err)
				-- BFL:DebugPrint("|cffff0000BetterFriendlist ElvUI Skin Error:|r " .. tostring(err))
			end)
		end)
	end

	-- Force run if ElvUI is already initialized (Classic fix)
	if self:IsEngineInitialized(E, RealS) then
		-- BFL:DebugPrint("|cff00ffffBFL ElvUI:|r Direct call triggered (ElvUI initialized)")
		xpcall(function()
			self:SkinFrames(E, S)
		end, function(err)
			-- BFL:DebugPrint("|cffff0000BetterFriendlist ElvUI Skin Error:|r " .. tostring(err))
		end)
	else
		-- BFL:DebugPrint("|cff00ffffBFL ElvUI:|r Direct call skipped (ElvUI not initialized)")
	end

	return true
end

function ElvUISkin:SkinFrames(E, S)
	if not self:IsSkinEnabled() then self:HideClassicMainFrameShell(); return end
	local SettingsDesigner = BFL:GetModule("SettingsDesigner")
	if SettingsDesigner and SettingsDesigner.ApplyElvUISkin then
		SettingsDesigner:ApplyElvUISkin(E, S)
	end

	if not _G.BetterFriendsFrame then
		return
	end
	-- Ensure Tab Text is centered (Hook for updates)
	if not self.TabHookInstalled then
		-- On 12.0.0+ (HasSecretValues), global PanelTemplates hooks taint the
		-- execution context, causing "secret string conversion" errors in the
		-- chat system. Use per-tab hooks and BFL-owned tab functions there.
		HookNamedTabs("BetterFriendsFrameTab", 4)
		HookNamedTabs("BetterFriendsFrameBottomTab", 4)
		HookNamedTabs("BetterFriendlistSettingsFrameTab", 10)

		if not BFL.HasSecretValues then
			if _G.PanelTemplates_SelectTab then
				hooksecurefunc("PanelTemplates_SelectTab", CenterBFLTabText)
			end
			if _G.PanelTemplates_DeselectTab then
				hooksecurefunc("PanelTemplates_DeselectTab", CenterBFLTabText)
			end
		end

		if hooksecurefunc then
			if type(_G.BetterFriendsFrame_ShowTab) == "function" then
				hooksecurefunc("BetterFriendsFrame_ShowTab", CenterMainFrameTabs)
			end
			if type(_G.BetterFriendsFrame_ShowBottomTab) == "function" then
				hooksecurefunc("BetterFriendsFrame_ShowBottomTab", CenterMainFrameTabs)
			end
			if type(BFL.ApplyTabFonts) == "function" then
				hooksecurefunc(BFL, "ApplyTabFonts", CenterMainFrameTabs)
			end
		end

		self.TabHookInstalled = true
	end
	-- BFL:DebugPrint("ElvUISkin: SkinFrames started")
	local frame = _G.BetterFriendsFrame
	local FriendsUI = BFL.FriendsUI or BFL:GetModule("FriendsUI")
	local isModernFriendsUI = FriendsUI and FriendsUI.IsModernActive and FriendsUI:IsModernActive()
	if not isModernFriendsUI then
	self.lastAppliedStyle = "legacy"
	self:SkinClassicMainFrameShell(E, S, frame)
	-- Skin Main Frame
	-- BFL:DebugPrint("ElvUISkin: Skinning Main Frame")
	if frame.PortraitContainer or frame.portrait then
		-- Use pcall to safeguard against ElvUI PixelPerfect errors (nil comparisons)
		-- in case the frame isn't fully dimensioned yet
		pcall(function()
			S:HandlePortraitFrame(frame)
		end)
	end
	local portraitButton, shouldSkinPortrait = frame.PortraitButton, frame.PortraitButton ~= nil
	-- Skin Portrait Button (Changelog)
	if portraitButton then
		-- BFL:DebugPrint("ElvUISkin: Skinning PortraitButton")
		local button = portraitButton

		-- Classic: Hide portrait when ElvUI active and NOT in Simple Mode
		-- (Changelog will be accessible via Contacts Menu instead)
		if BFL.IsClassic then
			local DB = BFL:GetModule("DB")
			local simpleMode = DB and DB:Get("simpleMode", false) or false
			if not simpleMode then
				button:Hide()
				shouldSkinPortrait = false
			end
		end

		if shouldSkinPortrait then
			button:Show() -- Reset position and size to fit ElvUI style
			button:ClearAllPoints()
			button:SetPoint("TOPLEFT", frame, "TOPLEFT", 4, -4)
			button:SetSize(42, 42) -- Standard ElvUI icon size (square)
			button:SetFrameLevel(frame:GetFrameLevel() + 5)

			-- Create Backdrop
			button:CreateBackdrop("Transparent")

			-- Handle Icon
			if BFL.IsClassic then
				-- Classic: Hide the old circular icon and create a new square one
				if button.Icon then
					button.Icon:Hide()
				end

				-- Create new square icon without mask
				if not button.ElvUIIcon then
					button.ElvUIIcon = button:CreateTexture(nil, "ARTWORK")
					button.ElvUIIcon:SetTexture("Interface\\AddOns\\BetterFriendlist\\Textures\\PortraitIcon.blp")
				end
				button.ElvUIIcon:ClearAllPoints()
				button.ElvUIIcon:SetInside(button.backdrop)
				button.ElvUIIcon:SetTexCoord(unpack(E.TexCoords)) -- Square crop
				button.ElvUIIcon:Show()

				-- Reference for consistency
				button.Icon = button.ElvUIIcon
			elseif not button.Icon then
				-- Retail: Create a new texture
				button.Icon = button:CreateTexture(nil, "ARTWORK")
				button.Icon:SetInside(button.backdrop)
				button.Icon:SetTexture("Interface\\AddOns\\BetterFriendlist\\Textures\\PortraitIcon.blp")
				button.Icon:SetTexCoord(unpack(E.TexCoords))
				button.Icon:Show()
			end

			-- Hide original icon and mask (if different from button.Icon)
			if frame.PortraitIcon and frame.PortraitIcon ~= button.Icon then
				frame.PortraitIcon:Hide()
			end
			if frame.PortraitMask then
				frame.PortraitMask:Hide()
			end

			-- Handle Glow (New Version Indicator)
			if button.Glow then
				button.Glow:SetParent(button)
				button.Glow:ClearAllPoints()
				button.Glow:SetInside(button.backdrop)
				button.Glow:SetDrawLayer("OVERLAY")
				-- Use a cleaner glow texture for ElvUI
				button.Glow:SetTexture(E.Media.Textures.Highlight)
				button.Glow:SetVertexColor(1, 0.82, 0, 0.5)
			end

			-- Add Hover Effect
			button:HookScript("OnEnter", function(self)
				if self.backdrop then
					local color = E.media.rgbvaluecolor
					if color then
						self.backdrop:SetBackdropBorderColor(color.r, color.g, color.b)
					end
				end
			end)

			button:HookScript("OnLeave", function(self)
				if self.backdrop then
					local color = E.media.bordercolor
					if color then
						self.backdrop:SetBackdropBorderColor(unpack(color))
					end
				end
			end)
		end
	end
	self:HideClassicPortraitArtifacts(frame, shouldSkinPortrait and portraitButton or nil, true)
	if not isModernFriendsUI then
	-- Skin Tabs (Top)
	BFL:DebugPrint("ElvUISkin: Skinning Top Tabs")
	for i = 1, 4 do
		local tab = _G["BetterFriendsFrameTab" .. i]
		if tab then
			S:HandleTab(tab)
			HookBFLTabCenter(tab)

			-- Adjust text position
			local text = tab.Text or (tab.GetFontString and tab:GetFontString())
			if text then
				CenterBFLTabText(tab)
				local textHeight = text:GetStringHeight() or 0
				local tabHeight = math.max(32, textHeight + 20)
				tab:SetHeight(tabHeight)
			else
				tab:SetHeight(25)
			end
		end
	end

	-- Skin Tabs (Bottom)
	BFL:DebugPrint("ElvUISkin: Skinning Bottom Tabs")
	if BFL.IsClassic then
		-- Classic: skin all existing bottom tabs (Friends/Who/Guild/Raid) and compact spacing.
		local frameWidth = frame:GetWidth()
		if frameWidth <= 0 then
			frameWidth = 338
		end

		local tabs = {}
		for i = 1, 4 do
			local tab = _G["BetterFriendsFrameBottomTab" .. i]
			if tab then
				table.insert(tabs, tab)
			end
		end

		local numTabs = #tabs
		if numTabs > 0 then
			local spacing = -4
			local tabWidth = math.floor((frameWidth - (spacing * (numTabs - 1))) / numTabs)
			for i, tab in ipairs(tabs) do
				S:HandleTab(tab)
				HookBFLTabCenter(tab)
				tab:SetHeight(28)
				tab:SetWidth(tabWidth)
				tab:ClearAllPoints()
				if i == 1 then
					tab:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 0, 1)
				else
					local prevTab = tabs[i - 1]
					tab:SetPoint("LEFT", prevTab, "RIGHT", spacing, 0)
				end
				CenterBFLTabText(tab)
			end
		end
	else
		for i = 1, 4 do
			local tab = _G["BetterFriendsFrameBottomTab" .. i]
			if tab then
				S:HandleTab(tab)
				HookBFLTabCenter(tab)
				tab:SetHeight(28)
				tab:ClearAllPoints()
				if i == 1 then
					tab:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", -2, 1)
				else
					local prevTab = _G["BetterFriendsFrameBottomTab" .. (i - 1)]
					tab:SetPoint("LEFT", prevTab, "RIGHT", -5, 0)
				end
				CenterBFLTabText(tab)
			end
		end
	end
	end

	-- Skin Insets
	BFL:DebugPrint("ElvUISkin: Skinning Insets")
	if frame.Inset then
		frame.Inset:StripTextures()
		frame.Inset:CreateBackdrop("Transparent")
	end

	if frame.ListInset then
		frame.ListInset:StripTextures()
		frame.ListInset:CreateBackdrop("Transparent")
	end

	-- Skin WhoFrame Inset
	if frame.WhoFrame and frame.WhoFrame.ListInset then
		frame.WhoFrame.ListInset:StripTextures()
		frame.WhoFrame.ListInset:CreateBackdrop("Transparent")
	end

	-- Skin RecruitAFriendFrame
	BFL:DebugPrint("ElvUISkin: Skinning RAF")
	self:SkinRecruitAFriend(E, S, frame)

	-- Skin RecentAlliesFrame ScrollBar
	BFL:DebugPrint("ElvUISkin: Skinning RecentAllies")
	if frame.RecentAlliesFrame and frame.RecentAlliesFrame.ScrollBar then
		SkinScrollBar(S, frame.RecentAlliesFrame.ScrollBar)
	end

	-- Skin IgnoreListWindow
	BFL:DebugPrint("ElvUISkin: Skinning IgnoreList")
	if frame.IgnoreListWindow then
		S:HandlePortraitFrame(frame.IgnoreListWindow)

		if frame.IgnoreListWindow.Inset then
			frame.IgnoreListWindow.Inset:StripTextures()
			frame.IgnoreListWindow.Inset:CreateBackdrop("Transparent")
		end

		if frame.IgnoreListWindow.ScrollBar then
			SkinScrollBar(S, frame.IgnoreListWindow.ScrollBar)
		end

		if frame.IgnoreListWindow.UnignorePlayerButton then
			S:HandleButton(frame.IgnoreListWindow.UnignorePlayerButton)
		end

		-- Skin Global Ignore List Button (if active)
		if frame.IgnoreListWindow.GlobalIgnoreListButton then
			-- Fix: Check if GlobalIgnoreListButton is actually a button (it might be a frame in some cases)
			if frame.IgnoreListWindow.GlobalIgnoreListButton:IsObjectType("Button") then
				S:HandleButton(frame.IgnoreListWindow.GlobalIgnoreListButton)

				-- Preserve the Icon (HandleButton calls StripTextures which hides ARTWORK)
				if frame.IgnoreListWindow.GlobalIgnoreListButton.Icon then
					-- Move to OVERLAY to ensure it sits on top of the new backdrop
					frame.IgnoreListWindow.GlobalIgnoreListButton.Icon:SetDrawLayer("OVERLAY")

					-- Ensure it is visible
					frame.IgnoreListWindow.GlobalIgnoreListButton.Icon:SetAlpha(1)
					frame.IgnoreListWindow.GlobalIgnoreListButton.Icon:Show()
				end
			end
		end

		-- Skin EnhanceQoL Ignore List Button (if active)
		if frame.IgnoreListWindow.EnhanceQoLIgnoreButton then
			if frame.IgnoreListWindow.EnhanceQoLIgnoreButton:IsObjectType("Button") then
				S:HandleButton(frame.IgnoreListWindow.EnhanceQoLIgnoreButton)

				if frame.IgnoreListWindow.EnhanceQoLIgnoreButton.Icon then
					frame.IgnoreListWindow.EnhanceQoLIgnoreButton.Icon:SetDrawLayer("OVERLAY")
					frame.IgnoreListWindow.EnhanceQoLIgnoreButton.Icon:SetAlpha(1)
					frame.IgnoreListWindow.EnhanceQoLIgnoreButton.Icon:Show()
				end
			end
		end
		-- Classic portrait artifacts are handled after the portrait block.
	end
	-- Skin ScrollBars
	BFL:DebugPrint("ElvUISkin: Skinning ScrollBars")
	-- Friends List ScrollBar - Point 7

	-- Check for Retail Minimal, Standard, or Classic ScrollBar (often on ScrollFrame)
	local scrollBar = frame.MinimalScrollBar or frame.ScrollBar
	if not scrollBar and frame.ScrollFrame then
		-- Classic FauxScrollFrame often names it $parentScrollBar
		if frame.ScrollFrame.ScrollBar then
			scrollBar = frame.ScrollFrame.ScrollBar
		elseif frame.ScrollFrame:GetName() then
			scrollBar = _G[frame.ScrollFrame:GetName() .. "ScrollBar"]
		end
	end

	-- Explicit Check for Classic Manual ScrollBar (Fix Phase 27)
	if not scrollBar and BFL.IsClassic then
		local classicSB = _G["BetterFriendsClassicScrollFrameScrollBar"]
		if classicSB then
			scrollBar = classicSB
		end
	end

	if scrollBar then
		-- Use specific handler if available
		if frame.MinimalScrollBar and S.HandleMinimalScrollBar then
			pcall(S.HandleMinimalScrollBar, S, frame.MinimalScrollBar)
		else
			-- Fix: Wrap ScrollBar skinning in pcall to prevent crashes on malformed scrollbars
			pcall(SkinScrollBar, S, scrollBar)
		end
	else
		-- Classic: Hook InitializeClassicScrollFrame to skin ScrollBar immediately after creation
		if BFL.IsClassic then
			local FriendsList = BFL:GetModule("FriendsList")
			if FriendsList and FriendsList.InitializeClassicScrollFrame then
				hooksecurefunc(FriendsList, "InitializeClassicScrollFrame", function(self, scrollFrame)
					-- ScrollBar is created by FauxScrollFrameTemplate with name $parentScrollBar
					if scrollFrame and scrollFrame.FauxScrollFrame then
						local classicScrollBar = _G["BetterFriendsClassicScrollFrameScrollBar"]
						if classicScrollBar and not classicScrollBar.isSkinned then
							SkinScrollBar(S, classicScrollBar)
							classicScrollBar.isSkinned = true
							BFL:DebugPrint("ElvUISkin: Classic ScrollBar skinned")
						end
					end
				end)
			end
		end
	end

	-- Who Frame ScrollBar
	if frame.WhoFrame then
		local whoScrollBar = GetWhoScrollBar(frame.WhoFrame)
		if whoScrollBar then
			SkinScrollBar(S, whoScrollBar)
		end

		local WhoFrameModule = BFL:GetModule("WhoFrame")
		if
			BFL.IsClassic
			and WhoFrameModule
			and WhoFrameModule.InitializeClassicWhoFrame
			and hooksecurefunc
			and not self.ClassicWhoScrollBarHooked
		then
			self.ClassicWhoScrollBarHooked = true
			hooksecurefunc(WhoFrameModule, "InitializeClassicWhoFrame", function(_, whoFrame)
				local function SkinDelayedWhoScrollBar()
					if self:IsSkinEnabled() then
						local delayedWhoScrollBar = GetWhoScrollBar(whoFrame)
						if delayedWhoScrollBar then
							SkinScrollBar(S, delayedWhoScrollBar)
						end
					end
				end
				if C_Timer and C_Timer.After then
					C_Timer.After(0, SkinDelayedWhoScrollBar)
				else
					SkinDelayedWhoScrollBar()
				end
			end)
		end
	end

	-- Raid Frame ScrollBar
	if frame.RaidFrame and frame.RaidFrame.ScrollBar then
		SkinScrollBar(S, frame.RaidFrame.ScrollBar)
	end

	-- Skin Buttons
	BFL:DebugPrint("ElvUISkin: Skinning Buttons")
	-- Add Friend / Send Who / etc
	if frame.AddFriendButton then
		S:HandleButton(frame.AddFriendButton)
	end
	if frame.SendMessageButton then
		S:HandleButton(frame.SendMessageButton)
	end
	if frame.RecruitmentButton then
		S:HandleButton(frame.RecruitmentButton)
	end
	if isModernFriendsUI and FriendsUI.root then
		local modernRoot = FriendsUI.root
		if modernRoot.BottomActionBar and modernRoot.BottomActionBar.AddFriendButton then
			S:HandleButton(modernRoot.BottomActionBar.AddFriendButton)
		end
		if modernRoot.FilterBar and modernRoot.FilterBar.SortButton then
			S:HandleButton(modernRoot.FilterBar.SortButton)
		end
		if modernRoot.FilterBar and modernRoot.FilterBar.FilterDropdown and S.HandleDropDownBox then
			S:HandleDropDownBox(modernRoot.FilterBar.FilterDropdown, 92)
			modernRoot.FilterBar.FilterDropdown:SetSize(92, 30)
		end
		if modernRoot.FilterBar and modernRoot.FilterBar.RecentFilterDropdown and S.HandleDropDownBox then
			S:HandleDropDownBox(modernRoot.FilterBar.RecentFilterDropdown, 92)
			modernRoot.FilterBar.RecentFilterDropdown:SetSize(92, 30)
		end
		if modernRoot.BattleNetBar and modernRoot.BattleNetBar.MenuButton then
			S:HandleButton(modernRoot.BattleNetBar.MenuButton)
		end
	end

	-- Skin HelpButton
	if frame.HelpButton then
		-- Do not skin the framework of the HelpButton, only color the icon
		-- S:HandleButton(frame.HelpButton)
		if frame.HelpButton.Icon then
			frame.HelpButton.Icon:SetVertexColor(1, 1, 1)
		end
	end

	-- Point 2: MenuButton & SettingsButton
	if frame.FriendsTabHeader and frame.FriendsTabHeader.BattlenetFrame then
		if not isModernFriendsUI and frame.FriendsTabHeader.BattlenetFrame.ContactsMenuButton then
			pcall(S.HandleButton, S, frame.FriendsTabHeader.BattlenetFrame.ContactsMenuButton)
		end
		if frame.FriendsTabHeader.BattlenetFrame.SettingsButton then
			pcall(S.HandleButton, S, frame.FriendsTabHeader.BattlenetFrame.SettingsButton)
		end

		-- Classic: Reposition buttons 15px to the right (already anchored to bnet, which moved)
		-- No additional changes needed as they inherit bnet's new position
	end

	if frame.WhoFrame then
		if frame.WhoFrame.WhoButton then
			pcall(S.HandleButton, S, frame.WhoFrame.WhoButton)
		end
		if frame.WhoFrame.AddFriendButton then
			pcall(S.HandleButton, S, frame.WhoFrame.AddFriendButton)
		end
		if frame.WhoFrame.GroupInviteButton then
			pcall(S.HandleButton, S, frame.WhoFrame.GroupInviteButton)
		end

		-- EditBox
		if frame.WhoFrame.EditBox then
			S:HandleEditBox(frame.WhoFrame.EditBox)
			if frame.WhoFrame.EditBox.Backdrop then
				frame.WhoFrame.EditBox.Backdrop:StripTextures()
				frame.WhoFrame.EditBox.Backdrop:CreateBackdrop("Transparent")
			end
		end

		-- Dropdown
		if frame.WhoFrame.ColumnDropdown then
			local dropdown = frame.WhoFrame.ColumnDropdown
			local modernDropdown = IsModernDropdown(dropdown)
			if S.HandleDropDownBox then
				S:HandleDropDownBox(dropdown)
			elseif modernDropdown and S.HandleButton then
				S:HandleButton(dropdown)
			end

			-- Classic: Fix text clipping into arrow and restore selected value
			if BFL.IsClassic then
				if modernDropdown then
					if dropdown.GenerateMenu then
						dropdown:GenerateMenu()
					end
				else
					local ddName = dropdown:GetName()
					if ddName then
						local ddText = _G[ddName .. "Text"]
						local ddButton = _G[ddName .. "Button"]
						if ddText and ddButton then
							ddText:ClearAllPoints()
							ddText:SetPoint("LEFT", dropdown, "LEFT", 5, 2)
							ddText:SetPoint("RIGHT", ddButton, "LEFT", -2, 0)
							ddText:SetJustifyH("LEFT")
							ddText:SetWordWrap(false)
						end
					end
					-- Restore selected value text after skinning
					local WhoFrameModule = BFL:GetModule("WhoFrame")
					if WhoFrameModule and WhoFrameModule.GetSortValue and BFL.SetDropdownText then
						local sortValue = WhoFrameModule:GetSortValue() or 1
						local selectionTexts = { ZONE, GUILD, RACE }
						BFL.SetDropdownText(dropdown, selectionTexts[sortValue] or ZONE)
					end
				end
			end
		end
	end

	-- Skin TabHeader Elements
	BFL:DebugPrint("ElvUISkin: Skinning TabHeader")
	if frame.FriendsTabHeader then
		-- Battlenet Frame & Broadcast Frame
		if frame.FriendsTabHeader.BattlenetFrame then
			local bnet = frame.FriendsTabHeader.BattlenetFrame

			-- Skin Main Frame
			bnet:StripTextures()
			bnet:CreateBackdrop("Transparent")
			bnet.backdrop:SetPoint("TOPLEFT", 0, 0)
			bnet.backdrop:SetPoint("BOTTOMRIGHT", 0, 0)

			-- Classic: Reduce width to make room for StatusDropdown
			if BFL.IsClassic then
				bnet:SetWidth(180)
				-- Reposition 62px from right edge (use same anchor as Core.lua for consistency)
				bnet:ClearAllPoints()
				bnet:SetPoint("TOPRIGHT", frame.FriendsTabHeader, "TOPRIGHT", -62, -27)
			end

			if bnet.Tag then
				bnet.Tag:SetParent(bnet.backdrop)
			end
			-- Set initial border color to default (not blue)
			if E.media and E.media.bordercolor then
				bnet.backdrop:SetBackdropBorderColor(unpack(E.media.bordercolor))
			end

			-- Add Hover Effect without replacing BFL's own Battle.net scripts.
			bnet:EnableMouse(true)
			if bnet.HookScript and not bnet.BFL_ElvUIHoverHooked then
				bnet:HookScript("OnEnter", function(self)
					if self.backdrop then
						local c = _G.FRIENDS_BNET_NAME_COLOR
						if c then
							self.backdrop:SetBackdropBorderColor(c.r, c.g, c.b)
						end
					end
				end)
				bnet:HookScript("OnLeave", function(self)
					if self.backdrop then
						local c = E.media.bordercolor
						if c then
							self.backdrop:SetBackdropBorderColor(unpack(c))
						end
					end
				end)
				bnet.BFL_ElvUIHoverHooked = true
			end
			if bnet.BroadcastFrame then
				bnet.BroadcastFrame:StripTextures()
				bnet.BroadcastFrame:CreateBackdrop("Transparent")

				if bnet.BroadcastFrame.UpdateButton then
					S:HandleButton(bnet.BroadcastFrame.UpdateButton)
				end
				if bnet.BroadcastFrame.CancelButton then
					S:HandleButton(bnet.BroadcastFrame.CancelButton)
				end
				if bnet.BroadcastFrame.EditBox then
					S:HandleEditBox(bnet.BroadcastFrame.EditBox)
				end
			end

			if bnet.UnavailableInfoFrame then
				bnet.UnavailableInfoFrame:StripTextures()
				bnet.UnavailableInfoFrame:CreateBackdrop("Transparent")
			end
		end

		-- SearchBox
		if frame.FriendsTabHeader.SearchBox then
			S:HandleEditBox(frame.FriendsTabHeader.SearchBox)

			-- Classic: Position below dropdowns
			if BFL.IsClassic then
				frame.FriendsTabHeader.SearchBox:ClearAllPoints()
				frame.FriendsTabHeader.SearchBox:SetPoint(
					"TOP",
					frame.FriendsTabHeader.BattlenetFrame,
					"BOTTOM",
					0,
					-35
				)
				frame.FriendsTabHeader.SearchBox:SetPoint("LEFT", frame.Inset, "LEFT", 10, 0)
				frame.FriendsTabHeader.SearchBox:SetPoint("RIGHT", frame.Inset, "RIGHT", -10, 0)
			end
		end

		-- Dropdowns - Point 3: Fix width & Layout (Classic adjustments)
		-- Common function to skin and size dropdowns
		local function SkinAndSizeDropdown(dropdown, width, height)
			if not dropdown then
				return
			end
			if S.HandleDropDownBox then
				S:HandleDropDownBox(dropdown, width)
			end

			if BFL.IsClassic and not IsModernDropdown(dropdown) and BFL.SetDropdownWidth then
				BFL.SetDropdownWidth(dropdown, width)
			else
				dropdown:SetWidth(width)
			end
			dropdown:SetHeight(height)

			-- Also force the button to match height if needed
			local name = dropdown:GetName()
			if name then
				local button = _G[name .. "Button"]
				if button then
					button:SetHeight(height)
				end
			end
		end

		if frame.FriendsTabHeader.StatusDropdown then
			if BFL.IsClassic then
				-- Classic: ElvUI's arrow plus the status icon needs more room than the Blizzard skin.
				local dropdown = frame.FriendsTabHeader.StatusDropdown

				if S.HandleDropDownBox then
					S:HandleDropDownBox(dropdown, ELVUI_CLASSIC_STATUS_DROPDOWN_WIDTH)
				end

				FixClassicDropdownHitbox(dropdown, ELVUI_CLASSIC_STATUS_DROPDOWN_WIDTH, 24)

				-- Reposition: 1px gap left of BattlenetFrame
				dropdown:ClearAllPoints()
				dropdown:SetPoint("RIGHT", frame.FriendsTabHeader.BattlenetFrame, "LEFT", -1, 0)
			elseif isModernFriendsUI then
				SkinAndSizeDropdown(frame.FriendsTabHeader.StatusDropdown, 54, 30)
			else
				SkinAndSizeDropdown(frame.FriendsTabHeader.StatusDropdown, 70, 22)
			end
		end

		if frame.FriendsTabHeader.QuickFilterDropdown and not isModernFriendsUI then
			if BFL.IsClassic then
				-- Classic: Re-anchor with clearer spacing to avoid visual clipping with sort dropdowns.
				local dropdown = frame.FriendsTabHeader.QuickFilterDropdown
				local isModernDropdown = IsModernDropdown(dropdown)
				local width = isModernDropdown and 50 or 70
				if S.HandleDropDownBox then
					S:HandleDropDownBox(dropdown, width)
				end
				FixClassicDropdownHitbox(dropdown, width, 24, ELVUI_CLASSIC_MAIN_DROPDOWN_TEXT_Y_OFFSET)
				RegisterClassicDropdownSelectedValueFix(dropdown)
				-- Restore position (matches FriendsList.lua Classic layout)
				if frame.FriendsTabHeader.SearchBox then
					dropdown:ClearAllPoints()
					dropdown:SetPoint("TOPLEFT", frame.FriendsTabHeader.SearchBox, "TOPLEFT", isModernDropdown and 0 or -16, 32)
				end
			else
				SkinAndSizeDropdown(frame.FriendsTabHeader.QuickFilterDropdown, isModernFriendsUI and 105 or 50, 30)
			end
		end

		if frame.FriendsTabHeader.PrimarySortDropdown then
			if BFL.IsClassic then
				-- Classic: add spacing so controls don't overlap after skinning.
				local dropdown = frame.FriendsTabHeader.PrimarySortDropdown
				local isModernDropdown = IsModernDropdown(dropdown)
				local width = isModernDropdown and 50 or 70
				if S.HandleDropDownBox then
					S:HandleDropDownBox(dropdown, width)
				end
				FixClassicDropdownHitbox(dropdown, width, 24, ELVUI_CLASSIC_MAIN_DROPDOWN_TEXT_Y_OFFSET)
				RegisterClassicDropdownSelectedValueFix(dropdown)
				-- Anchor to QuickFilter with positive spacing.
				if frame.FriendsTabHeader.QuickFilterDropdown then
					dropdown:ClearAllPoints()
					dropdown:SetPoint("LEFT", frame.FriendsTabHeader.QuickFilterDropdown, "RIGHT", 6, 0)
				end
			else
				-- Retail: Keep existing size
				SkinAndSizeDropdown(frame.FriendsTabHeader.PrimarySortDropdown, 50, 30)

				-- Anchor to QuickFilter with positive spacing (ElvUI removes the transparent padding)
				frame.FriendsTabHeader.PrimarySortDropdown:ClearAllPoints()
				frame.FriendsTabHeader.PrimarySortDropdown:SetPoint(
					"LEFT",
					frame.FriendsTabHeader.QuickFilterDropdown,
					"RIGHT",
					5,
					0
				)
			end
		end

		if frame.FriendsTabHeader.SecondarySortDropdown then
			if BFL.IsClassic then
				-- Classic: add spacing so controls don't overlap after skinning.
				local dropdown = frame.FriendsTabHeader.SecondarySortDropdown
				local isModernDropdown = IsModernDropdown(dropdown)
				local width = isModernDropdown and 50 or 70
				if S.HandleDropDownBox then
					S:HandleDropDownBox(dropdown, width)
				end
				FixClassicDropdownHitbox(dropdown, width, 24, ELVUI_CLASSIC_MAIN_DROPDOWN_TEXT_Y_OFFSET)
				RegisterClassicDropdownSelectedValueFix(dropdown)
				-- Anchor to PrimarySort with positive spacing.
				if frame.FriendsTabHeader.PrimarySortDropdown then
					dropdown:ClearAllPoints()
					dropdown:SetPoint("LEFT", frame.FriendsTabHeader.PrimarySortDropdown, "RIGHT", 6, 0)
				end
			else
				-- Retail: Keep existing size
				SkinAndSizeDropdown(frame.FriendsTabHeader.SecondarySortDropdown, 50, 30)

				-- Anchor to PrimarySort
				frame.FriendsTabHeader.SecondarySortDropdown:ClearAllPoints()
				frame.FriendsTabHeader.SecondarySortDropdown:SetPoint(
					"LEFT",
					frame.FriendsTabHeader.PrimarySortDropdown,
					"RIGHT",
					5,
					0
				)
			end
		end
	end

	-- Skin Headers (Who Frame)
	BFL:DebugPrint("ElvUISkin: Skinning WhoFrame Headers")
	if frame.WhoFrame then
		local headers = { frame.WhoFrame.NameHeader, frame.WhoFrame.LevelHeader, frame.WhoFrame.ClassHeader }
		for _, header in ipairs(headers) do
			if header then
				S:HandleButton(header)
				header:SetHeight(22) -- Fixed height for headers
			end
		end

		-- Fix NameHeader alignment
		if frame.WhoFrame.NameHeader and frame.WhoFrame.ListInset then
			frame.WhoFrame.NameHeader:ClearAllPoints()
			frame.WhoFrame.NameHeader:SetPoint("BOTTOMLEFT", frame.WhoFrame.ListInset, "TOPLEFT", 0, 1)
		end

		-- Fix Dropdown height and alignment
		if frame.WhoFrame.ColumnDropdown then
			local modernDropdown = IsModernDropdown(frame.WhoFrame.ColumnDropdown)
			if BFL.IsClassic and not modernDropdown then
				FixClassicDropdownHitbox(frame.WhoFrame.ColumnDropdown, WHO_CLASSIC_ELVUI_DROPDOWN_VISUAL_WIDTH, 24)
			else
				frame.WhoFrame.ColumnDropdown:SetHeight(26) -- Match header height
			end

			ApplyWhoColumnDropdownAlignment(frame.WhoFrame)
		end

		-- Re-anchor LevelHeader
		if frame.WhoFrame.LevelHeader and frame.WhoFrame.ColumnDropdown then
			local dropdownOffset = (BFL.IsClassic and not IsModernDropdown(frame.WhoFrame.ColumnDropdown)) and WHO_CLASSIC_DROPDOWN_X_OFFSET or 0
			frame.WhoFrame.LevelHeader:ClearAllPoints()
			frame.WhoFrame.LevelHeader:SetPoint("LEFT", frame.WhoFrame.ColumnDropdown, "RIGHT", -1 - dropdownOffset, 0)
		end

		-- Re-anchor ClassHeader
		if frame.WhoFrame.ClassHeader and frame.WhoFrame.LevelHeader then
			frame.WhoFrame.ClassHeader:ClearAllPoints()
			frame.WhoFrame.ClassHeader:SetPoint("LEFT", frame.WhoFrame.LevelHeader, "RIGHT", -1, 0)
		end

		local WhoFrameModule = BFL:GetModule("WhoFrame")
		if
			BFL.IsClassic
			and WhoFrameModule
			and WhoFrameModule.UpdateResponsiveLayout
			and hooksecurefunc
			and not self.WhoHeaderAlignmentHooked
		then
			self.WhoHeaderAlignmentHooked = true
			hooksecurefunc(WhoFrameModule, "UpdateResponsiveLayout", function()
				if self:IsSkinEnabled() then
					ApplyWhoColumnDropdownAlignment(frame.WhoFrame)
				end
			end)
		end
	end

	-- Skin QuickJoin
	BFL:DebugPrint("ElvUISkin: Skinning QuickJoin")
	if frame.QuickJoinFrame then
		if frame.QuickJoinFrame.ContentInset then
			frame.QuickJoinFrame.ContentInset:StripTextures()
			frame.QuickJoinFrame.ContentInset:CreateBackdrop("Transparent")

			if frame.QuickJoinFrame.ContentInset.ScrollBar then
				SkinScrollBar(S, frame.QuickJoinFrame.ContentInset.ScrollBar)
			end
		end

		-- Point 4: Join Queue Button (Check both possible paths)
		if frame.QuickJoinFrame.JoinQueueButton then
			S:HandleButton(frame.QuickJoinFrame.JoinQueueButton)
		elseif frame.QuickJoinFrame.ContentInset and frame.QuickJoinFrame.ContentInset.JoinQueueButton then
			S:HandleButton(frame.QuickJoinFrame.ContentInset.JoinQueueButton)
		end
	end

	-- Skin Raid Frame
	BFL:DebugPrint("ElvUISkin: Skinning RaidFrame")
	if frame.RaidFrame then
		-- Fix: Use GroupsInset instead of ListInset
		if frame.RaidFrame.GroupsInset then
			frame.RaidFrame.GroupsInset:StripTextures()
			local modernRaidLayout = BFL.FriendsUI and BFL.FriendsUI:IsModernActive()
			if not modernRaidLayout then
				frame.RaidFrame.GroupsInset:CreateBackdrop("Transparent")
			end
		elseif frame.RaidFrame.ListInset then
			-- Fallback if ListInset exists
			frame.RaidFrame.ListInset:StripTextures()
			frame.RaidFrame.ListInset:CreateBackdrop("Transparent")
		end
		if frame.RaidFrame.ConvertToRaidButton then
			S:HandleButton(frame.RaidFrame.ConvertToRaidButton)
		end
		-- Point 8: Raid Info Button
		if frame.RaidFrame.ControlPanel and frame.RaidFrame.ControlPanel.RaidInfoButton then
			S:HandleButton(frame.RaidFrame.ControlPanel.RaidInfoButton)
		end
		if frame.RaidFrame.ControlPanel and frame.RaidFrame.ControlPanel.ReadyCheckButton then
			S:HandleButton(frame.RaidFrame.ControlPanel.ReadyCheckButton)
		end

		-- Skin EveryoneAssistCheckbox
		if frame.RaidFrame.ControlPanel and frame.RaidFrame.ControlPanel.EveryoneAssistCheckbox then
			S:HandleCheckBox(frame.RaidFrame.ControlPanel.EveryoneAssistCheckbox)
		end

		-- Skin RaidToolsButton
		if frame.RaidFrame.RaidToolsButton then
			S:HandleButton(frame.RaidFrame.RaidToolsButton)
		end
	end
	else
		self:HideClassicMainFrameShell()
		self:SkinModernFrames(E, S, frame, FriendsUI)
	end
	-- Hook Friends List (ScrollBox Items)
	BFL:DebugPrint("ElvUISkin: Hooking FriendsList")
	self:HookFriendsList(E, S)

	-- Skin Settings Frame
	BFL:DebugPrint("ElvUISkin: Skinning Settings")
	xpcall(function()
		self:SkinSettings(E, S)
		local Designer = BFL:GetModule("SettingsDesigner")
		if Designer and Designer.ApplyElvUISkin then
			Designer:ApplyElvUISkin(E, S)
		end
	end, function(err)
		BFL:DebugPrint("ElvUISkin: Error skinning Settings: " .. tostring(err))
	end)

	-- Skin Changelog
	BFL:DebugPrint("ElvUISkin: Skinning Changelog")
	xpcall(function()
		self:SkinChangelog(E, S)
	end, function(err)
		BFL:DebugPrint("ElvUISkin: Error skinning Changelog: " .. tostring(err))
	end)

	-- Skin HelpFrame
	BFL:DebugPrint("ElvUISkin: Skinning HelpFrame")
	xpcall(function()
		self:SkinHelpFrame(E, S)
	end, function(err)
		BFL:DebugPrint("ElvUISkin: Error skinning HelpFrame: " .. tostring(err))
	end)

	-- Skin Export Frame
	BFL:DebugPrint("ElvUISkin: Skinning ExportFrame")
	xpcall(function()
		self:SkinExportFrame(E, S)
	end, function(err)
		BFL:DebugPrint("ElvUISkin: Error skinning ExportFrame: " .. tostring(err))
	end)

	-- Skin Import Frame
	BFL:DebugPrint("ElvUISkin: Skinning ImportFrame")
	xpcall(function()
		self:SkinImportFrame(E, S)
	end, function(err)
		BFL:DebugPrint("ElvUISkin: Error skinning ImportFrame: " .. tostring(err))
	end)

	-- Skin Note Cleanup Wizard
	BFL:DebugPrint("ElvUISkin: Skinning NoteCleanupWizard")
	xpcall(function()
		self:SkinNoteCleanupWizard(E, S)
	end, function(err)
		BFL:DebugPrint("ElvUISkin: Error skinning NoteCleanupWizard: " .. tostring(err))
	end)

	-- Skin Backup Viewer
	BFL:DebugPrint("ElvUISkin: Skinning BackupViewer")
	xpcall(function()
		self:SkinBackupViewer(E, S)
	end, function(err)
		BFL:DebugPrint("ElvUISkin: Error skinning BackupViewer: " .. tostring(err))
	end)

	-- Skin Search Builder (WHO frame)
	BFL:DebugPrint("ElvUISkin: Skinning SearchBuilder")
	xpcall(function()
		self:SkinSearchBuilder(E, S)
	end, function(err)
		BFL:DebugPrint("ElvUISkin: Error skinning SearchBuilder: " .. tostring(err))
	end)

	if not self.SearchBuilderHookInstalled then
		local WhoFrameModule = BFL:GetModule("WhoFrame")
		if WhoFrameModule and WhoFrameModule.ToggleSearchBuilder then
			hooksecurefunc(WhoFrameModule, "ToggleSearchBuilder", function()
				xpcall(function()
					self:SkinSearchBuilder(E, S)
				end, function(err)
					BFL:DebugPrint("ElvUISkin: Error skinning SearchBuilder hook: " .. tostring(err))
				end)
			end)
			hooksecurefunc(WhoFrameModule, "SetBuilderDocked", function()
				xpcall(function()
					self:SkinSearchBuilder(E, S)
				end, function(err)
					BFL:DebugPrint("ElvUISkin: Error skinning SearchBuilder (dock) hook: " .. tostring(err))
				end)
			end)
			self.SearchBuilderHookInstalled = true
		end
	end

	-- Hook RaidTools (lazy frame creation)
	if not self.RaidToolsHookInstalled then
		local RaidToolsModule = BFL:GetModule("RaidTools")
		if RaidToolsModule and RaidToolsModule.CreateFrame then
			hooksecurefunc(RaidToolsModule, "CreateFrame", function()
				xpcall(function()
					self:SkinRaidTools(E, S)
				end, function(err)
					BFL:DebugPrint("ElvUISkin: Error skinning RaidTools: " .. tostring(err))
				end)
			end)
			self.RaidToolsHookInstalled = true
		end
	end

	-- Apply FontFix after Skinning to ensure correct font sizes
	local FontFix = BFL:GetModule("FontFix")
	if FontFix then
		BFL:DebugPrint("ElvUISkin: Re-applying FontFix")
		FontFix:ApplyFixedFonts()
	end
	if isModernFriendsUI then
		-- FriendsUI's theme pass calls RefreshModernSkin after restoring geometry.
		-- Do not call ApplyTheme here: that would recurse into this skin pipeline.
		-- The dedicated Modern branch above has already completed this pass.
	end

	BFL:DebugPrint("ElvUI Skin applied to BetterFriendlist")
end

function ElvUISkin:HookFriendsList(E, S)
	local FriendsList = BFL:GetModule("FriendsList")
	if not FriendsList then
		return
	end
	-- Explicitly skin Classic ScrollBar if it exists now (Backup for initialization order)
	if BFL.IsClassic then
		local classicSB = _G["BetterFriendsClassicScrollFrameScrollBar"]
		if classicSB and not classicSB.BFL_ElvUILegacyScrollSkinned then
			SkinScrollBar(S, classicSB)
			classicSB.BFL_ElvUILegacyScrollSkinned = true
		end
	end
	if self.FriendsListHooksInstalled then return end; self.FriendsListHooksInstalled = true
	hooksecurefunc(FriendsList, "UpdateGroupHeaderButton", function(_, button)
		if self:IsSkinEnabled() and self:IsModernFriendsUIActive() then
			self:SkinModernScrollableHeader(S, button)
		elseif not button.BFL_ElvUILegacyHeaderSkinned then
			CallElvUIHandler(S, "HandleButton", button)
			-- Strip the custom background texture if it exists
			if button.BG then
				button.BG:SetTexture(nil)
			end
			button.BFL_ElvUILegacyHeaderSkinned = true
		end
	end)
	-- Hook Friend Button
	hooksecurefunc(FriendsList, "UpdateFriendButton", function(_, button)
		if self:IsSkinEnabled() and self:IsModernFriendsUIActive() then
			self:SkinModernSocialCard(S, button)
		elseif not button.BFL_ElvUILegacyFriendSkinned then
			-- Don't full skin friend buttons as they are list items
			-- BFL: Travelpass button should NOT be skinned (User request)
			-- But we can skin the travel pass button in Retail only (not in Classic)
			-- if not BFL.IsClassic and button.travelPassButton then
			-- 	S:HandleButton(button.travelPassButton)
			-- 	-- Ensure icon remains visible and sized correctly
			-- 	if button.travelPassButton.NormalTexture then
			-- 		button.travelPassButton.NormalTexture:SetAlpha(1)
			-- 		button.travelPassButton.NormalTexture:SetSize(22, 22)
			-- 		button.travelPassButton.NormalTexture:SetPoint("CENTER")
			-- 	end
			-- end
			button.BFL_ElvUILegacyFriendSkinned = true
		end
	end)
	-- Hook Invite Header
	hooksecurefunc(FriendsList, "UpdateInviteHeaderButton", function(_, button)
		if self:IsSkinEnabled() and self:IsModernFriendsUIActive() then
			self:SkinModernScrollableHeader(S, button)
		elseif not button.BFL_ElvUILegacyInviteHeaderSkinned then
			CallElvUIHandler(S, "HandleButton", button)
			button.BFL_ElvUILegacyInviteHeaderSkinned = true
		end
	end)
	-- Hook Invite Button
	hooksecurefunc(FriendsList, "UpdateInviteButton", function(_, button)
		if self:IsSkinEnabled() and self:IsModernFriendsUIActive() then
			self:SkinModernSocialCard(S, button)
		elseif not button.BFL_ElvUILegacyInviteSkinned then
			if button.AcceptButton then
				CallElvUIHandler(S, "HandleButton", button.AcceptButton)
			end
			if button.DeclineButton then
				CallElvUIHandler(S, "HandleButton", button.DeclineButton)
			end
			button.BFL_ElvUILegacyInviteSkinned = true
		end
	end)
	-- Hook UpdateSearchBoxState to enforce ElvUI positioning in Classic Normal Mode
	if FriendsList.UpdateSearchBoxState then
		hooksecurefunc(FriendsList, "UpdateSearchBoxState", function()
			if BFL.IsClassic then
				local DB = BFL:GetModule("DB")
				local simpleMode = DB and DB:Get("simpleMode", false)
				if not simpleMode then
					local frame = _G.BetterFriendsFrame
					if
						frame
						and frame.FriendsTabHeader
						and frame.FriendsTabHeader.SearchBox
						and frame.FriendsTabHeader.BattlenetFrame
					then
						local searchBox = frame.FriendsTabHeader.SearchBox
						searchBox:ClearAllPoints()
						searchBox:SetPoint("TOP", frame.FriendsTabHeader.BattlenetFrame, "BOTTOM", 0, -35)
						searchBox:SetPoint("LEFT", frame.Inset, "LEFT", 10, 0)
						searchBox:SetPoint("RIGHT", frame.Inset, "RIGHT", -10, 0)
					end
				end
			end
		end)
	end
end
function ElvUISkin:SkinRecruitAFriend(E, S, frame)
	local raf = frame.RecruitAFriendFrame
	if not raf then
		return
	end
	-- Skin Main Elements
	if raf.Border then
		raf.Border:StripTextures()
	end
	if raf.Background then
		raf.Background:Hide()
	end

	-- Skin Reward Claiming
	if raf.RewardClaiming then
		-- ElvUI Style: Handle Background
		if raf.RewardClaiming.Background then
			raf.RewardClaiming.Background:SetAlpha(0)
		end

		-- Hide Parchment Elements
		local parchmentElements = {
			"Bracket_TopLeft",
			"Bracket_TopRight",
			"Bracket_BottomLeft",
			"Bracket_BottomRight",
			"Watermark",
		}
		for _, name in ipairs(parchmentElements) do
			if raf.RewardClaiming[name] then
				raf.RewardClaiming[name]:Hide()
			end
		end

		-- Create Backdrop
		raf.RewardClaiming:CreateBackdrop("Transparent")

		-- Skin Claim/View Button
		if raf.RewardClaiming.ClaimOrViewRewardButton then
			S:HandleButton(raf.RewardClaiming.ClaimOrViewRewardButton)
		end

		if raf.RewardClaiming.Inset then
			raf.RewardClaiming.Inset:StripTextures()
			raf.RewardClaiming.Inset:CreateBackdrop("Transparent")
		end

		-- Next Reward Icon
		if raf.RewardClaiming.NextRewardButton then
			local button = raf.RewardClaiming.NextRewardButton
			-- CRITICAL: Do NOT strip textures, it removes the Icon!
			button:CreateBackdrop("Transparent")

			if button.Icon then
				button.Icon:SetTexCoord(unpack(E.TexCoords))
				button.Icon:SetParent(button.backdrop)
				button.Icon:SetInside()
				button.Icon:SetDrawLayer("ARTWORK")
			end

			if button.IconBorder then
				button.IconBorder:SetAlpha(0)
			end
			if button.IconOverlay then
				button.IconOverlay:SetAlpha(0)
			end
			if button.CircleMask then
				button.CircleMask:Hide()
			end
		end
	end

	-- Skin Recruit List
	if raf.RecruitList then
		if raf.RecruitList.ScrollFrameInset then
			raf.RecruitList.ScrollFrameInset:StripTextures()
			raf.RecruitList.ScrollFrameInset:CreateBackdrop("Transparent")
		end

		if raf.RecruitList.ScrollBar then
			SkinScrollBar(S, raf.RecruitList.ScrollBar)
		end

		-- Header
		if raf.RecruitList.Header then
			if raf.RecruitList.Header.Background then
				raf.RecruitList.Header.Background:Hide()
			end
			raf.RecruitList.Header:StripTextures()
			raf.RecruitList.Header:CreateBackdrop("Transparent")
		end
	end

	-- Skin Splash Frame
	if raf.SplashFrame then
		raf.SplashFrame:StripTextures()
		raf.SplashFrame:CreateBackdrop("Transparent")

		if raf.SplashFrame.Background then
			raf.SplashFrame.Background:Hide()
		end
		if raf.SplashFrame.PictureFrame then
			raf.SplashFrame.PictureFrame:Hide()
		end
		if raf.SplashFrame.Watermark then
			raf.SplashFrame.Watermark:Hide()
		end
		if raf.SplashFrame.Bracket_TopLeft then
			raf.SplashFrame.Bracket_TopLeft:Hide()
		end
		if raf.SplashFrame.Bracket_TopRight then
			raf.SplashFrame.Bracket_TopRight:Hide()
		end
		if raf.SplashFrame.Bracket_BottomLeft then
			raf.SplashFrame.Bracket_BottomLeft:Hide()
		end
		if raf.SplashFrame.Bracket_BottomRight then
			raf.SplashFrame.Bracket_BottomRight:Hide()
		end

		if raf.SplashFrame.Picture then
			raf.SplashFrame.Picture:SetInside() -- Make picture fill the frame or adjust as needed
			-- ElvUI does this, but maybe we want to keep it centered?
			-- Let's stick to ElvUI logic:
			-- SplashFrame.Picture:SetInside()
		end

		if raf.SplashFrame.OKButton then
			S:HandleButton(raf.SplashFrame.OKButton)
		end
	end
end

function ElvUISkin:SkinSettings(E, S)
	local frame = _G.BetterFriendlistSettingsFrame
	if not frame then
		return
	end

	S:HandlePortraitFrame(frame)

	-- Skin Tabs (Top) - Point 4: Adjust height
	for i = 1, 10 do
		local tab = _G["BetterFriendlistSettingsFrameTab" .. i]
		if tab then
			-- Fixed: Removed IsShown() check to ensure all tabs (including Beta/Global Sync)
			-- are skinned even if hidden during initial load.
			-- Tabs should exist if XML defines them.
			S:HandleTab(tab)
			tab:SetHeight(28) -- Fixed height
			HookBFLTabCenter(tab)
			CenterBFLTabText(tab)
		end
	end

	-- Skin Main Inset
	if frame.MainInset then
		frame.MainInset:StripTextures()
		frame.MainInset:CreateBackdrop("Transparent")
	end

	-- Skin ScrollBar
	if frame.ContentScrollFrame and frame.ContentScrollFrame.ScrollBar then
		S:HandleScrollBar(frame.ContentScrollFrame.ScrollBar)
	end

	-- Hook Refresh functions to skin EditBoxes (Point 3)
	local Settings = BFL:GetModule("Settings")
	if Settings and not self.SettingsHooksInstalled then
		self.SettingsHooksInstalled = true
		local function SkinEditBoxesInTab(tab)
			if not tab or not tab.components then
				return
			end
			for _, comp in ipairs(tab.components) do
				-- Check if it's an EditBox (or container with EditBox)
				if comp:IsObjectType("EditBox") then
					S:HandleEditBox(comp)
				elseif comp:IsObjectType("Frame") then
					-- Check children for EditBox (like nameFormatContainer)
					for _, child in ipairs({ comp:GetChildren() }) do
						if child:IsObjectType("EditBox") then
							S:HandleEditBox(child)
						end
					end
				end
			end
		end

		local function SkinFilterSortEditor()
			local editor = _G.BetterFriendlistFilterSortEditorFrame
			if not editor then
				return
			end

			if not editor.BFL_ElvFrameSkinned then
				S:HandlePortraitFrame(editor)
				if editor.Inset then
					editor.Inset:StripTextures()
					editor.Inset:CreateBackdrop("Transparent")
				end
				editor.BFL_ElvFrameSkinned = true
			end

			if editor.ScrollFrame then
				if editor.ScrollFrame.ScrollBar then
					SkinScrollBar(S, editor.ScrollFrame.ScrollBar)
				else
					for _, child in ipairs({ editor.ScrollFrame:GetChildren() }) do
						if child:IsObjectType("Slider") then
							S:HandleScrollBar(child)
						end
					end
				end
			end
		end

		-- Hook RefreshCategories to skin the new vertical buttons
		hooksecurefunc(Settings, "RefreshCategories", function()
			local frame = _G.BetterFriendlistSettingsFrame
			if frame and frame.CategoryList then
				-- Skin the Category List container
				if not frame.CategoryList.isSkinned then
					frame.CategoryList:StripTextures()
					frame.CategoryList:CreateBackdrop("Transparent")
					frame.CategoryList.isSkinned = true
				end

				-- Skin Buttons
				local children = { frame.CategoryList:GetChildren() }
				for _, child in ipairs(children) do
					if child:IsObjectType("Button") and not child.isSkinned then
						S:HandleButton(child)
						-- Remove default highlight/selected textures as ElvUI adds its own
						child:SetHighlightTexture("")

						-- Adjust text position if needed
						if child.text then
							child.text:ClearAllPoints()
							child.text:SetPoint("LEFT", child, "LEFT", 30, 0)
						end

						-- Hook OnClick or similar if necessary to update selected state visual
						-- But our SelectCategory logic handles text color, which is fine.

						child.isSkinned = true
					end
				end
			end
		end)

		hooksecurefunc(Settings, "RefreshGeneralTab", function()
			local content = frame.ContentScrollFrame.Content
			if content and content.GeneralTab then
				SkinEditBoxesInTab(content.GeneralTab)
			end
		end)
		hooksecurefunc(Settings, "RefreshFriendTabsTab", function()
			for _, row in ipairs(Settings.friendTabSettingRows or {}) do
				if row.Visibility and not row.Visibility.BFL_ElvSkinned then
					S:HandleCheckBox(row.Visibility)
					row.Visibility.BFL_ElvSkinned = true
				end
			end
		end)
		hooksecurefunc(Settings, "EnsureFilterSortEditorPanel", SkinFilterSortEditor)
		hooksecurefunc(Settings, "RefreshFilterSortTab", SkinFilterSortEditor)

		-- Hook Global Sync Tab (Point 5: Skin dynamic headers and buttons)
		hooksecurefunc(Settings, "RefreshGlobalSyncTab", function()
			local content = frame.ContentScrollFrame.Content
			if content and content.GlobalSyncTab then
				local tab = content.GlobalSyncTab

				-- Skin Layout Headers (if they weren't caught by CreateHeader hook)
				-- We can iterate children to find unskinned buttons or headers
				local children = { tab:GetChildren() }
				for _, child in ipairs(children) do
					-- Case 1: Direct Button (unlikely in Global Sync, but possible)
					if child:IsObjectType("Button") and not child.isSkinned then
						-- Filter for the small action buttons (size 20x20 usually)
						local w, h = child:GetSize()
						if w < 30 and h < 30 then
							S:HandleButton(child)
							child.isSkinned = true
						end

					-- Case 2: Row Frame containing Button
					elseif child:IsObjectType("Frame") then
						-- Check children of the row for the action button
						local rowChildren = { child:GetChildren() }
						for _, btn in ipairs(rowChildren) do
							-- Skin Buttons (except Edit Note button which has a specific texture)
							if btn:IsObjectType("Button") and not btn.isSkinned then
								local w, h = btn:GetSize()
								if w < 30 and h < 30 then
									-- Check for Edit Note Icon
									local icon = btn:GetNormalTexture()
									local iconPath = icon and icon:GetTexture()
									local isEditNote = iconPath
										and (
											type(iconPath) == "string"
											and string.find(iconPath, "UI%-GuildButton%-PublicNote")
										)

									if not isEditNote then
										S:HandleButton(btn)
										btn.isSkinned = true
									end
								end
							end
						end
					end
				end
			end
		end)
	end

	-- Hook Components to skin dynamic elements
	if BFL.SettingsComponents then
		local C = BFL.SettingsComponents

		-- Checkbox
		if not C.IsSkinned then
			local oldCreateCheckbox = C.CreateCheckbox
			C.CreateCheckbox = function(...)
				local holder = oldCreateCheckbox(...)
				if holder and holder.checkBox then
					S:HandleCheckBox(holder.checkBox)
				end
				return holder
			end

			-- Double Checkbox
			local oldCreateDoubleCheckbox = C.CreateDoubleCheckbox
			C.CreateDoubleCheckbox = function(...)
				local holder = oldCreateDoubleCheckbox(...)
				if holder then
					if holder.LeftCheckbox then
						S:HandleCheckBox(holder.LeftCheckbox)
					end
					if holder.RightCheckbox then
						S:HandleCheckBox(holder.RightCheckbox)
					end
				end
				return holder
			end

			-- Slider
			local oldCreateSlider = C.CreateSlider
			C.CreateSlider = function(...)
				local holder = oldCreateSlider(...)
				if holder and holder.Slider then
					local slider = holder.Slider
					slider:StripTextures()
					slider:CreateBackdrop("Transparent")
					if slider.backdrop then
						slider.backdrop:SetPoint("TOPLEFT", 0, -5)
						slider.backdrop:SetPoint("BOTTOMRIGHT", 0, 5)
					end

					local thumb = slider:GetThumbTexture()
					if thumb then
						thumb:SetAlpha(0)
						if not slider.BFLThumb then
							local t = slider:CreateTexture(nil, "OVERLAY")
							t:SetTexture(E.Media.Textures.Melli or 130751)
							t:SetVertexColor(1, 0.82, 0)
							t:SetSize(10, 18)
							t:SetPoint("CENTER", thumb, "CENTER")
							slider.BFLThumb = t
						end
					end

					if slider.Back then
						S:HandleNextPrevButton(slider.Back, "left")
						slider.Back:SetSize(16, 16)
					end
					if slider.Forward then
						S:HandleNextPrevButton(slider.Forward, "right")
						slider.Forward:SetSize(16, 16)
					end
				end
				return holder
			end

			-- SliderWithColorPicker
			local oldCreateSliderColor = C.CreateSliderWithColorPicker
			C.CreateSliderWithColorPicker = function(...)
				local holder = oldCreateSliderColor(...)
				if holder and holder.Slider then
					-- Aggressive Skinning for MinimalSliderWithSteppersTemplate
					local slider = holder.Slider

					-- 1. Strip all textures (removes default Blizzard borders/track art)
					slider:StripTextures()

					-- 2. Create proper ElvUI Backdrop (The Track)
					slider:CreateBackdrop("Transparent")
					if slider.backdrop then
						slider.backdrop:SetPoint("TOPLEFT", 0, -5) -- Adjust height of track
						slider.backdrop:SetPoint("BOTTOMRIGHT", 0, 5)
					end

					-- 3. Handle Thumb
					local thumb = slider:GetThumbTexture()
					if thumb then
						thumb:SetAlpha(0) -- Hide default geometry

						if not slider.BFLThumb then
							local t = slider:CreateTexture(nil, "OVERLAY")
							t:SetTexture(E.Media.Textures.Melli or 130751)
							t:SetVertexColor(1, 0.82, 0)
							t:SetSize(10, 18)
							t:SetPoint("CENTER", thumb, "CENTER")
							slider.BFLThumb = t
						end
					end

					-- 4. Skin Stepper Buttons
					if slider.Back then
						S:HandleNextPrevButton(slider.Back, "left")
						slider.Back:SetSize(16, 16) -- Force size
					end
					if slider.Forward then
						S:HandleNextPrevButton(slider.Forward, "right")
						slider.Forward:SetSize(16, 16)
					end
				end
				return holder
			end

			-- Dropdown
			local oldCreateDropdown = C.CreateDropdown
			C.CreateDropdown = function(...)
				local holder = oldCreateDropdown(...)
				if holder and holder.DropDown then
					S:HandleDropDownBox(holder.DropDown)
				end
				return holder
			end

			-- Button
			local oldCreateButton = C.CreateButton
			C.CreateButton = function(...)
				local button = oldCreateButton(...)
				if button then
					S:HandleButton(button)
				end
				return button
			end

			-- List Item (Group Management)
			local oldCreateListItem = C.CreateListItem
			C.CreateListItem = function(...)
				local holder = oldCreateListItem(...)
				if holder then
					if holder.deleteButton then
						S:HandleButton(holder.deleteButton)
					end
					if holder.colorButton then
						S:HandleButton(holder.colorButton)
					end
					if holder.renameButton then
						S:HandleButton(holder.renameButton)
					end
					if holder.downButton then
						S:HandleButton(holder.downButton)
					end
					if holder.upButton then
						S:HandleButton(holder.upButton)
					end

					-- Skin the background if possible, or strip it
					if holder.bg then
						holder.bg:SetColorTexture(0, 0, 0, 0) -- Hide default bg
						holder:CreateBackdrop("Transparent")
					end
				end
				return holder
			end

			-- CheckboxDropdown (Favorite Icon row etc.)
			local oldCreateCheckboxDropdown = C.CreateCheckboxDropdown
			C.CreateCheckboxDropdown = function(...)
				local holder = oldCreateCheckboxDropdown(...)
				if holder then
					if holder.LeftCheckbox then
						S:HandleCheckBox(holder.LeftCheckbox)
					end
					if holder.RightDropdown then
						S:HandleDropDownBox(holder.RightDropdown)
					end
				end
				return holder
			end

			-- Input (Streamer Mode text field etc.)
			local oldCreateInput = C.CreateInput
			C.CreateInput = function(...)
				local holder = oldCreateInput(...)
				if holder and holder.Input then
					S:HandleEditBox(holder.Input)
				end
				return holder
			end

			-- ButtonRow (Reset buttons etc.)
			local oldCreateButtonRow = C.CreateButtonRow
			C.CreateButtonRow = function(...)
				local holder = oldCreateButtonRow(...)
				if holder then
					if holder.LeftButton then
						S:HandleButton(holder.LeftButton)
					end
					if holder.RightButton then
						S:HandleButton(holder.RightButton)
					end
				end
				return holder
			end

			C.IsSkinned = true
		end
	end
end

function ElvUISkin:SkinAppearanceOnboarding(frame, onboarding)
	if not self:IsSkinEnabled() or not frame then
		return false
	end
	local E = self.ElvUIEngine or (BFL.GetElvUIEngine and BFL:GetElvUIEngine(false))
	local S = self.ElvUISkinProxy or (E and E.GetModule and E:GetModule("Skins"))
	if not S then
		return false
	end

	if not frame.BFL_ElvOnboardingSkinned then
		S:HandlePortraitFrame(frame)
		if frame.MainInset then
			frame.MainInset:StripTextures()
			frame.MainInset:CreateBackdrop("Transparent")
		end
		for _, button in ipairs({ onboarding.backButton, onboarding.laterButton, onboarding.primaryButton }) do
			S:HandleButton(button)
		end
		frame.BFL_ElvOnboardingSkinned = true
	end
	if frame.PortraitContainer then
		frame.PortraitContainer:Hide()
	end
	if frame.portrait then
		frame.portrait:Hide()
	end
	for _, card in ipairs(onboarding.styleCards or {}) do
		if not card.BFL_ElvOnboardingSkinned then
			if card.SetBackdrop then
				card:SetBackdrop(nil)
			end
			card:CreateBackdrop("Transparent")
			S:HandleCheckBox(card.SelectControl)
			if card.Diagram.SetBackdrop then
				card.Diagram:SetBackdrop(nil)
			end
			card.Diagram:CreateBackdrop("Transparent")
			card.BFL_ElvOnboardingSkinned = true
		end
	end
	for _, card in ipairs(onboarding.themeCards or {}) do
		if not card.BFL_ElvOnboardingSkinned then
			if card.SetBackdrop then
				card:SetBackdrop(nil)
			end
			card:CreateBackdrop("Transparent")
			S:HandleCheckBox(card.SelectControl)
			card.BFL_ElvOnboardingSkinned = true
		end
	end
	for _, card in ipairs(onboarding.layoutCards or {}) do
		if not card.BFL_ElvOnboardingSkinned then
			if card.SetBackdrop then
				card:SetBackdrop(nil)
			end
			card:CreateBackdrop("Transparent")
			S:HandleCheckBox(card.Check)
			card.BFL_ElvOnboardingSkinned = true
		end
	end
	for _, row in ipairs({
		onboarding.summaryPanel and onboarding.summaryPanel.StyleRow,
		onboarding.summaryPanel and onboarding.summaryPanel.ThemeRow,
		onboarding.summaryPanel and onboarding.summaryPanel.SimpleModeRow,
		onboarding.summaryPanel and onboarding.summaryPanel.CompactModeRow,
	}) do
		if row and not row.BFL_ElvOnboardingSkinned then
			if row.SetBackdrop then
				row:SetBackdrop(nil)
			end
			row:CreateBackdrop("Transparent")
			row.BFL_ElvOnboardingSkinned = true
		end
	end
	return true
end

function ElvUISkin:SkinChangelog(E, S)
	local Changelog = BFL:GetModule("Changelog")
	if not Changelog then
		return
	end

	local function Skin()
		local frame = _G.BetterFriendlistChangelogFrame
		if not frame or frame.isSkinned then
			return
		end

		BFL:DebugPrint("ElvUISkin: Applying Skin to Changelog Window")
		S:HandlePortraitFrame(frame)

		-- Skin Main Inset
		if frame.MainInset then
			frame.MainInset:StripTextures()
			frame.MainInset:CreateBackdrop("Transparent")
		end

		-- Skin Buttons
		if frame.DiscordButton then
			S:HandleButton(frame.DiscordButton)
		end
		if frame.GitHubButton then
			S:HandleButton(frame.GitHubButton)
		end
		if frame.KoFiButton then
			S:HandleButton(frame.KoFiButton)
		end

		-- Skin ScrollBar
		if frame.ScrollBar then
			-- Retail
			SkinScrollBar(S, frame.ScrollBar)
		elseif frame.ScrollFrame then
			-- Classic or Fallback
			local children = { frame.ScrollFrame:GetChildren() }
			for _, child in ipairs(children) do
				if child:IsObjectType("Slider") then
					S:HandleScrollBar(child)
				end
			end
		end

		frame.isSkinned = true
	end

	hooksecurefunc(Changelog, "CreateChangelogWindow", Skin)
	Skin()
end

function ElvUISkin:SkinHelpFrame(E, S)
	local HelpFrame = BFL.HelpFrame or BFL:GetModule("HelpFrame")
	if not HelpFrame then
		return
	end

	local function Skin()
		local frame = _G.BetterFriendlistHelpFrame
		if not frame or frame.isSkinned then
			return
		end

		BFL:DebugPrint("ElvUISkin: Skinning HelpFrame")
		S:HandlePortraitFrame(frame)

		-- Skin Inset if it exists (ButtonFrameTemplate feature)
		if frame.Inset then
			frame.Inset:StripTextures()
			frame.Inset:CreateBackdrop("Transparent")
		end

		-- Skin ScrollBar
		if frame.ScrollBar then
			SkinScrollBar(S, frame.ScrollBar)
		elseif frame.ScrollFrame then
			-- Classic fallback or when using UIPanelScrollFrame
			if frame.ScrollFrame.ScrollBar then
				SkinScrollBar(S, frame.ScrollFrame.ScrollBar)
			elseif frame.ScrollFrame:GetName() then
				local scrollBar = _G[frame.ScrollFrame:GetName() .. "ScrollBar"]
				if scrollBar then
					SkinScrollBar(S, scrollBar)
				end
			end
		end

		frame.isSkinned = true
	end

	-- Hook creation
	hooksecurefunc(HelpFrame, "CreateFrame", Skin)
	-- Hook toggle as well just in case CreateFrame returns early but we missed skinning
	hooksecurefunc(HelpFrame, "Toggle", Skin)

	-- Try to skin immediately if it exists
	if _G.BetterFriendlistHelpFrame then
		Skin()
	end
end

-- Helper: Skin all UIPanelButtonTemplate / GameMenuButtonTemplate buttons in a frame
local function SkinChildButtons(S, parent)
	for _, child in ipairs({ parent:GetChildren() }) do
		if child:IsObjectType("Button") and not child.isSkinned then
			-- Skip close buttons (handled by HandlePortraitFrame)
			local name = child:GetName()
			if not name or not string.find(name, "CloseButton") then
				S:HandleButton(child)
				child.isSkinned = true
			end
		end
	end
end

-- Helper: Skin ScrollBar from UIPanelScrollFrameTemplate (legacy Slider-based)
-- UIPanelScrollFrameTemplate creates a classic Slider scrollbar, NOT a modern ScrollBar.
-- We must use S:HandleScrollBar() (for Slider), NOT SkinScrollBar/HandleTrimScrollBar.
local function SkinUIPanelScrollBar(S, scrollFrame)
	if not scrollFrame then
		return
	end
	-- Try direct ScrollBar child (some frames store it)
	if scrollFrame.ScrollBar then
		if scrollFrame.ScrollBar:IsObjectType("Slider") then
			pcall(S.HandleScrollBar, S, scrollFrame.ScrollBar)
		else
			pcall(SkinScrollBar, S, scrollFrame.ScrollBar)
		end
		return
	end
	-- Try named ScrollBar (UIPanelScrollFrameTemplate convention: $parentScrollBar)
	local name = scrollFrame:GetName()
	if name then
		local scrollBar = _G[name .. "ScrollBar"]
		if scrollBar then
			pcall(S.HandleScrollBar, S, scrollBar)
			return
		end
	end
	-- Fallback: find Slider child among all children
	for _, child in ipairs({ scrollFrame:GetChildren() }) do
		if child:IsObjectType("Slider") then
			pcall(S.HandleScrollBar, S, child)
			return
		end
	end
end

function ElvUISkin:SkinExportFrame(E, S)
	local Settings = BFL:GetModule("Settings")
	if not Settings then
		return
	end

	local function Skin()
		local frame = _G.BetterFriendlistExportFrame
		if not frame or frame.isSkinned then
			return
		end

		BFL:DebugPrint("ElvUISkin: Applying Skin to Export Frame")

		-- BasicFrameTemplateWithInset
		frame:StripTextures()
		frame:CreateBackdrop("Transparent")

		-- Close Button
		if frame.CloseButton then
			S:HandleCloseButton(frame.CloseButton)
		end

		-- Inset
		if frame.InsetFrame then
			frame.InsetFrame:StripTextures()
		end

		-- ScrollFrame & ScrollBar
		if frame.scrollFrame then
			SkinUIPanelScrollBar(S, frame.scrollFrame)
		end

		-- Skin all buttons (Copy All)
		SkinChildButtons(S, frame)

		frame.isSkinned = true
	end

	-- Hook creation
	hooksecurefunc(Settings, "CreateExportFrame", Skin)

	-- Try to skin immediately if it exists
	if _G.BetterFriendlistExportFrame then
		Skin()
	end
end

function ElvUISkin:SkinImportFrame(E, S)
	local Settings = BFL:GetModule("Settings")
	if not Settings then
		return
	end

	local function Skin()
		local frame = _G.BetterFriendlistImportFrame
		if not frame or frame.isSkinned then
			return
		end

		BFL:DebugPrint("ElvUISkin: Applying Skin to Import Frame")

		-- BasicFrameTemplateWithInset
		frame:StripTextures()
		frame:CreateBackdrop("Transparent")

		-- Close Button
		if frame.CloseButton then
			S:HandleCloseButton(frame.CloseButton)
		end

		-- Inset
		if frame.InsetFrame then
			frame.InsetFrame:StripTextures()
		end

		-- ScrollFrame & ScrollBar
		if frame.scrollFrame then
			SkinUIPanelScrollBar(S, frame.scrollFrame)
		end

		-- Skin all buttons (Import, Cancel)
		SkinChildButtons(S, frame)

		frame.isSkinned = true
	end

	-- Hook creation
	hooksecurefunc(Settings, "CreateImportFrame", Skin)

	-- Try to skin immediately if it exists
	if _G.BetterFriendlistImportFrame then
		Skin()
	end
end

function ElvUISkin:SkinNoteCleanupWizard(E, S)
	local NoteCleanupWizard = BFL.NoteCleanupWizard
	if not NoteCleanupWizard then
		return
	end

	local function Skin()
		local frame = _G.BetterFriendlistNoteCleanupWizard
		if not frame or frame.isSkinned then
			return
		end

		BFL:DebugPrint("ElvUISkin: Applying Skin to Note Cleanup Wizard")

		-- ButtonFrameTemplate
		S:HandlePortraitFrame(frame)

		-- Inset
		if frame.Inset then
			frame.Inset:StripTextures()
			frame.Inset:CreateBackdrop("Transparent")
		end

		-- ScrollFrame & ScrollBar
		if frame.scrollFrame then
			SkinUIPanelScrollBar(S, frame.scrollFrame)
		end

		-- Skin buttons and search boxes in all child frames (topBar children)
		for _, child in ipairs({ frame:GetChildren() }) do
			-- Skin buttons inside sub-frames (topBar)
			if child:IsObjectType("Frame") and not child:IsObjectType("Button") then
				for _, subChild in ipairs({ child:GetChildren() }) do
					if subChild:IsObjectType("Button") and not subChild.isSkinned then
						S:HandleButton(subChild)
						subChild.isSkinned = true
					end
					if subChild:IsObjectType("EditBox") and not subChild.isSkinned then
						S:HandleEditBox(subChild)
						subChild.isSkinned = true
					end
				end
			end
		end

		frame.isSkinned = true
	end

	-- Hook creation
	hooksecurefunc(NoteCleanupWizard, "CreateWizardFrame", Skin)

	-- Also hook Show in case frame was already created
	hooksecurefunc(NoteCleanupWizard, "Show", Skin)

	-- Try to skin immediately if it exists
	if _G.BetterFriendlistNoteCleanupWizard then
		Skin()
	end
end

function ElvUISkin:SkinBackupViewer(E, S)
	local NoteCleanupWizard = BFL.NoteCleanupWizard
	if not NoteCleanupWizard then
		return
	end

	local function Skin()
		local frame = _G.BetterFriendlistNoteBackupViewer
		if not frame or frame.isSkinned then
			return
		end

		BFL:DebugPrint("ElvUISkin: Applying Skin to Backup Viewer")

		-- ButtonFrameTemplate
		S:HandlePortraitFrame(frame)

		-- Inset
		if frame.Inset then
			frame.Inset:StripTextures()
			frame.Inset:CreateBackdrop("Transparent")
		end

		-- ScrollFrame & ScrollBar
		if frame.scrollFrame then
			SkinUIPanelScrollBar(S, frame.scrollFrame)
		end

		-- Skin buttons and search boxes in all child frames (topBar children)
		for _, child in ipairs({ frame:GetChildren() }) do
			-- Skin buttons inside sub-frames (topBar)
			if child:IsObjectType("Frame") and not child:IsObjectType("Button") then
				for _, subChild in ipairs({ child:GetChildren() }) do
					if subChild:IsObjectType("Button") and not subChild.isSkinned then
						S:HandleButton(subChild)
						subChild.isSkinned = true
					end
					if subChild:IsObjectType("EditBox") and not subChild.isSkinned then
						S:HandleEditBox(subChild)
						subChild.isSkinned = true
					end
				end
			end
		end

		frame.isSkinned = true
	end

	-- Hook creation
	hooksecurefunc(NoteCleanupWizard, "CreateBackupViewerFrame", Skin)

	-- Also hook ShowBackupViewer in case frame was already created
	hooksecurefunc(NoteCleanupWizard, "ShowBackupViewer", Skin)

	-- Try to skin immediately if it exists
	if _G.BetterFriendlistNoteBackupViewer then
		Skin()
	end
end

function ElvUISkin:SkinSearchBuilder(E, S)
	local WhoFrameModule = BFL:GetModule("WhoFrame")
	if not WhoFrameModule then
		return
	end

	local flyout = WhoFrameModule.builderFlyout
	if not flyout then
		return
	end

	-- Apply ElvUI backdrop
	flyout:StripTextures()
	flyout:CreateBackdrop("Transparent")

	-- Skin builder inputs and dropdowns
	local builder = WhoFrameModule.builder
	if builder then
		if builder.nameInput then
			self:SkinModernEditBox(S, builder.nameInput)
		end
		if builder.guildInput then
			self:SkinModernEditBox(S, builder.guildInput)
		end
		if builder.zoneInput then
			self:SkinModernEditBox(S, builder.zoneInput)
		end
		if builder.levelMin then
			self:SkinModernEditBox(S, builder.levelMin)
		end
		if builder.levelMax then
			self:SkinModernEditBox(S, builder.levelMax)
		end
		local isDocked = WhoFrameModule.builderDocked
		local isModernBuilder = self:IsModernFriendsUIActive()
			and WhoFrameModule.IsModernSearchBuilderEmbedded
			and WhoFrameModule:IsModernSearchBuilderEmbedded()
		local function SkinBuilderDropdown(dropdown)
			if not dropdown then
				return
			end
			if isModernBuilder and dropdown.BFL_ModernBuilderY then
				self:SkinModernDropdown(S, dropdown, dropdown:GetWidth())
				-- ElvUI dropdown chrome has different visual insets than the native
				-- SearchBoxTemplate. Align the frame tops and leave a deliberate
				-- four-pixel lead before the search/level input column.
				dropdown:ClearAllPoints()
				dropdown:SetPoint(
					"TOPLEFT",
					flyout,
					"TOPLEFT",
					69,
					dropdown.BFL_ModernBuilderY + 4
				)
				dropdown:SetPoint(
					"TOPRIGHT",
					flyout,
					"TOPRIGHT",
					-12,
					dropdown.BFL_ModernBuilderY + 4
				)
				dropdown:SetHeight(24)
				return
			end

			pcall(S.HandleDropDownBox, S, dropdown)
			local modernDropdown = IsModernDropdown(dropdown)
			if BFL.IsClassic and not modernDropdown then
				FixClassicDropdownHitbox(dropdown, isDocked and 105 or 115, 24)
				if not dropdown.BFL_OrigXOfs then
					local _, _, _, x, y = dropdown:GetPoint(1)
					dropdown.BFL_OrigXOfs = x or 0
					dropdown.BFL_OrigYOfs = y or 0
				end
				local point, relativeTo, relativePoint = dropdown:GetPoint(1)
				if point then
					dropdown:SetPoint(
						point,
						relativeTo,
						relativePoint,
						dropdown.BFL_OrigXOfs + 10,
						dropdown.BFL_OrigYOfs
					)
				end
			elseif modernDropdown then
				if not dropdown.BFL_OrigXOfs then
					local _, _, _, x, y = dropdown:GetPoint(1)
					dropdown.BFL_OrigXOfs = x or 0
					dropdown.BFL_OrigYOfs = y or 0
				end
				local point, relativeTo, relativePoint = dropdown:GetPoint(1)
				if point then
					dropdown:SetPoint(
						point,
						relativeTo,
						relativePoint,
						dropdown.BFL_OrigXOfs + 1,
						dropdown.BFL_OrigYOfs
					)
				end
			end
		end
		if builder.classDropdown then
			SkinBuilderDropdown(builder.classDropdown)
		end
		if builder.raceDropdown then
			SkinBuilderDropdown(builder.raceDropdown)
		end
	end

	-- Skin child buttons (close, search, reset)
	local dockBtn = WhoFrameModule.builderDockBtn
	for _, child in ipairs({ flyout:GetChildren() }) do
		if child:IsObjectType("Button") and not child.isSkinned then
			if child == dockBtn then
				-- Dock button uses a custom icon texture, don't skin it
				child.isSkinned = true
			else
				local w = child:GetWidth()
				if w <= 24 then
					pcall(S.HandleCloseButton, S, child)
				else
					S:HandleButton(child)
				end
				child.isSkinned = true
			end
		end
	end

	-- Skin docked container if it exists
	local container = WhoFrameModule.builderDockedContainer
	if container and not container.isSkinned then
		pcall(function()
			S:HandlePortraitFrame(container)
		end)
		container.isSkinned = true
	end
end

-- ============================================================================
-- RaidTools Skinning
-- ============================================================================

function ElvUISkin:SkinRaidTools(E, S)
	local frame = _G.BetterFriendlistRaidToolsFrame
	if not frame then
		return
	end

	-- Frame backdrop
	pcall(S.HandlePortraitFrame, S, frame)

	-- Close button
	if frame.CloseButton then
		pcall(S.HandleCloseButton, S, frame.CloseButton)
	end

	-- Dropdowns
	local sortDropdown = _G["BFLRaidToolsSortMode"]
	if sortDropdown then
		pcall(S.HandleDropDownBox, S, sortDropdown)
		if BFL.IsClassic then
			FixClassicDropdownHitbox(sortDropdown, 189, 24)
			if not sortDropdown.BFL_OrigXOfs then
				local p, rel, rp, x, y = sortDropdown:GetPoint(1)
				sortDropdown.BFL_OrigXOfs = x or 0
				sortDropdown.BFL_OrigYOfs = y or 0
			end
			local p, rel, rp = sortDropdown:GetPoint(1)
			if p then
				sortDropdown:SetPoint(p, rel, rp, sortDropdown.BFL_OrigXOfs + 16, sortDropdown.BFL_OrigYOfs)
			end
		end
		if BFL.IsRetail then
			sortDropdown:SetWidth(240)
		end
	end

	local preserveDropdown = _G["BFLRaidToolsPreserveGroups"]
	if preserveDropdown then
		pcall(S.HandleDropDownBox, S, preserveDropdown)
		if BFL.IsClassic then
			FixClassicDropdownHitbox(preserveDropdown, 189, 24)
			if not preserveDropdown.BFL_OrigXOfs then
				local p, rel, rp, x, y = preserveDropdown:GetPoint(1)
				preserveDropdown.BFL_OrigXOfs = x or 0
				preserveDropdown.BFL_OrigYOfs = y or 0
			end
			local p, rel, rp = preserveDropdown:GetPoint(1)
			if p then
				preserveDropdown:SetPoint(p, rel, rp, preserveDropdown.BFL_OrigXOfs + 16, preserveDropdown.BFL_OrigYOfs)
			end
		end
		if BFL.IsRetail then
			preserveDropdown:SetWidth(240)
		end
	end

	-- Checkboxes
	local balanceDps = _G["BFLRaidToolsBalanceDps"]
	if balanceDps then
		S:HandleCheckBox(balanceDps)
		if BFL.IsRetail then
			local p, rel, rp, x, y = balanceDps:GetPoint(1)
			if p then
				balanceDps:SetPoint(p, rel, rp, x - 3, y)
			end
		end
	end

	local resumeCheck = _G["BFLRaidToolsResumeCheck"]
	if resumeCheck then
		S:HandleCheckBox(resumeCheck)
		if BFL.IsRetail then
			local p, rel, rp, x, y = resumeCheck:GetPoint(1)
			if p then
				resumeCheck:SetPoint(p, rel, rp, x - 3, y)
			end
		end
	end

	-- Buttons
	if frame.sortButton then
		S:HandleButton(frame.sortButton)
	end
	if frame.splitButton then
		S:HandleButton(frame.splitButton)
	end
	if frame.splitOddsButton then
		S:HandleButton(frame.splitOddsButton)
	end
	if frame.promoteButton then
		S:HandleButton(frame.promoteButton)
	end

	-- RETAIL FINETUNING: Additional Retail-specific tweaks for RaidTools here
	if BFL.IsRetail then
	end

	-- CLASSIC FINETUNING: Additional Classic-specific tweaks for RaidTools here
	if BFL.IsClassic then
	end
end

local function HideClassicPortraitObject(object)
	if not object then
		return
	end
	if object.GetRegions then
		for _, region in ipairs({ object:GetRegions() }) do
			if region and region.SetAlpha then
				region:SetAlpha(0)
			end
			if region and region.Hide then
				region:Hide()
			end
		end
	end
	if object.SetAlpha then
		object:SetAlpha(0)
	end
	if object.Hide then
		object:Hide()
	end
end

local function IsFrameAncestorOf(candidate, child)
	if not (candidate and child and child.GetParent) then
		return false
	end

	local parent = child:GetParent()
	while parent do
		if parent == candidate then
			return true
		end
		parent = parent.GetParent and parent:GetParent()
	end
	return false
end

function ElvUISkin:HideClassicPortraitArtifacts(frame, keepButton, schedule)
	if not (BFL and BFL.IsClassic and frame) then
		return
	end

	local frameName = frame.GetName and frame:GetName()
	local candidates = {
		frame.PortraitIcon,
		frame.PortraitMask,
		frame.PortraitFrame,
		frame.PortraitContainer,
		frame.Portrait,
		frame.portrait,
		frame.CircleMask,
		frame.TopLeftCorner,
		frame.TopBorder,
		frame.LeftBorder,
		frame.BFL_SimpleModeTopLeftCorner,
		frame.PortraitOverlay,
		frameName and _G[frameName .. "Portrait"],
		frameName and _G[frameName .. "PortraitFrame"],
		frameName and _G[frameName .. "CircleMask"],
		frameName and _G[frameName .. "TopLeftCorner"],
		frameName and _G[frameName .. "TopBorder"],
		frameName and _G[frameName .. "LeftBorder"],
		frameName and _G[frameName .. "BFL_SimpleModeTopLeftCorner"],
		frameName and _G[frameName .. "PortraitOverlay"],
		_G.BetterFriendsFramePortraitFrame,
		_G.BetterFriendsFramePortrait,
		_G.BetterFriendsFrameTopLeftCorner,
		_G.BetterFriendsFrameTopBorder,
		_G.BetterFriendsFrameLeftBorder,
		_G.BetterFriendsFrameBFL_SimpleModeTopLeftCorner,
	}

	for _, object in ipairs(candidates) do
		if object and object ~= keepButton and not IsFrameAncestorOf(object, keepButton) then
			HideClassicPortraitObject(object)
		end
	end

	if schedule then
		self:ScheduleHideClassicPortraitArtifacts(frame, keepButton)
	end
end

function ElvUISkin:ScheduleHideClassicPortraitArtifacts(frame, keepButton)
	if not (BFL and BFL.IsClassic and frame and C_Timer and C_Timer.After) then
		return
	end

	local function HideDelayed()
		if self:IsSkinEnabled() then
			self:HideClassicPortraitArtifacts(frame, keepButton)
		end
	end

	C_Timer.After(0, HideDelayed)
	C_Timer.After(0.1, HideDelayed)
	C_Timer.After(0.25, HideDelayed)
end

function ElvUISkin:InstallClassicPortraitGuard()
	if not (BFL and BFL.IsClassic) or self.ClassicPortraitGuardInstalled then
		return
	end
	self.ClassicPortraitGuardInstalled = true

	local function HidePortraitArtifacts()
		if not self:IsSkinEnabled() then
			return
		end
		local frame = _G.BetterFriendsFrame
		if frame then
			self:HideClassicPortraitArtifacts(frame, frame.PortraitButton, true)
		end
	end

	if hooksecurefunc and type(BFL.UpdatePortraitVisibility) == "function" then
		hooksecurefunc(BFL, "UpdatePortraitVisibility", HidePortraitArtifacts)
	end
	HidePortraitArtifacts()
end

function ElvUISkin:IsSkinEnabled()
	if BFL.IsThemeActive and BFL:IsThemeActive("elvui") then
		return true
	end
	if not (BFL.IsElvUIAvailable and BFL:IsElvUIAvailable()) then
		return false
	end

	local theme
	local legacyEnabled = false
	local DB = BFL:GetModule("DB")
	if DB and DB.Get then
		theme = DB:Get("theme", nil)
		legacyEnabled = DB:Get("enableElvUISkin", false) == true
	elseif BetterFriendlistDB then
		theme = BetterFriendlistDB.theme
		legacyEnabled = BetterFriendlistDB.enableElvUISkin == true
	end

	if theme == "elvui" then
		return true
	end
	if theme and theme ~= "blizzard" then
		return false
	end
	return legacyEnabled == true
end

local function GetElvUIColor(color, fallbackR, fallbackG, fallbackB, fallbackA)
	if type(color) == "table" then
		return color.r or color[1] or fallbackR, color.g or color[2] or fallbackG, color.b or color[3] or fallbackB, color.a or color[4] or fallbackA
	end
	return fallbackR, fallbackG, fallbackB, fallbackA
end

function ElvUISkin:SkinClassicMainFrameShell(E, S, frame)
	if not (BFL and BFL.IsClassic and frame) then
		return
	end

	local shell = frame.BFL_ElvUIClassicShell
	if not shell then
		local template = _G.BackdropTemplateMixin and "BackdropTemplate" or nil
		shell = CreateFrame("Frame", nil, frame, template)
		shell:EnableMouse(false)
		frame.BFL_ElvUIClassicShell = shell
	end

	shell:ClearAllPoints()
	shell:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
	shell:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
	if shell.SetFrameStrata and frame.GetFrameStrata then
		shell:SetFrameStrata(frame:GetFrameStrata())
	end
	if shell.SetFrameLevel and frame.GetFrameLevel then
		shell:SetFrameLevel(math.max((frame:GetFrameLevel() or 1), 0))
	end

	if S and S.HandleFrame and not shell.BFL_ElvUIHandled then
		pcall(S.HandleFrame, S, shell, true)
		shell.BFL_ElvUIHandled = true
	end

	if shell.backdrop then
		shell.backdrop:ClearAllPoints()
		shell.backdrop:SetAllPoints(shell)
	end
	if shell.SetBackdrop then
		shell:SetBackdrop({
			bgFile = "Interface\\Buttons\\WHITE8X8",
			edgeFile = "Interface\\Buttons\\WHITE8X8",
			edgeSize = 1,
		})
	end
	if not shell.BFL_ElvUIClassicBg then
		shell.BFL_ElvUIClassicBg = shell:CreateTexture(nil, "BACKGROUND")
	end
	shell.BFL_ElvUIClassicBg:SetAllPoints(shell)

	local bgR, bgG, bgB, bgA = GetElvUIColor(E and E.media and E.media.backdropcolor, 0.06, 0.06, 0.06, 0.92)
	local borderR, borderG, borderB, borderA = GetElvUIColor(E and E.media and E.media.bordercolor, 0.18, 0.18, 0.18, 1)
	shell.BFL_ElvUIClassicBg:SetColorTexture(bgR, bgG, bgB, bgA)
	if shell.SetBackdropColor then
		shell:SetBackdropColor(bgR, bgG, bgB, bgA)
	end
	if shell.SetBackdropBorderColor then
		shell:SetBackdropBorderColor(borderR, borderG, borderB, borderA)
	end
	if shell.backdrop and shell.backdrop.SetBackdropColor then
		shell.backdrop:SetBackdropColor(bgR, bgG, bgB, bgA)
	end
	if shell.backdrop and shell.backdrop.SetBackdropBorderColor then
		shell.backdrop:SetBackdropBorderColor(borderR, borderG, borderB, borderA)
	end
	shell:Show()
end

function ElvUISkin:HideClassicMainFrameShell()
	local frame = _G.BetterFriendsFrame
	local shell = frame and frame.BFL_ElvUIClassicShell
	if shell then
		shell:Hide()
	end
end

CallElvUIHandler = function(S, handlerName, object, ...)
	if not (S and object) then
		return false
	end

	local handler = S[handlerName]
	if type(handler) ~= "function" then
		return false
	end

	return pcall(handler, S, object, ...)
end

local function SetTextureAlpha(texture, alpha)
	if texture and texture.SetAlpha then
		texture:SetAlpha(alpha)
	end
end

local function SetTextureColor(texture, r, g, b, a)
	if texture and texture.SetColorTexture then
		texture:SetColorTexture(r, g, b, a)
	elseif texture and texture.SetVertexColor then
		texture:SetVertexColor(r, g, b, a)
	end
end

local function EnsureTransparentBackdrop(frame, inset)
	if not (frame and frame.CreateBackdrop) then
		return nil
	end

	if not frame.backdrop then
		frame:CreateBackdrop("Transparent")
	end
	if frame.backdrop and inset and frame.backdrop.SetInside then
		frame.backdrop:SetInside(frame, inset, inset)
	end
	return frame.backdrop
end

local function GetModernElvUIBackdropColors(E)
	local bgR, bgG, bgB = GetElvUIColor(E and E.media and E.media.backdropcolor, 0.06, 0.06, 0.06, 1)
	local borderR, borderG, borderB = GetElvUIColor(E and E.media and E.media.bordercolor, 0.18, 0.18, 0.18, 1)
	return bgR, bgG, bgB, borderR, borderG, borderB
end

local function BackdropColorMatches(surface, getterName, r, g, b, a)
	local getter = surface and surface[getterName]
	if type(getter) ~= "function" then
		return nil
	end
	local ok, currentR, currentG, currentB, currentA = pcall(getter, surface)
	if not ok then
		return nil
	end
	local epsilon = 0.001
	return math.abs((currentR or 0) - r) <= epsilon
		and math.abs((currentG or 0) - g) <= epsilon
		and math.abs((currentB or 0) - b) <= epsilon
		and math.abs((currentA == nil and 1 or currentA) - (a == nil and 1 or a)) <= epsilon
end

local function ApplyModernElvUIBackdrop(E, control, overrideR, overrideG, overrideB)
	if not control then
		return nil
	end

	local surface = control.backdrop
	if not surface and control.SetBackdropColor then
		surface = control
	end
	if not surface then
		surface = EnsureTransparentBackdrop(control)
	end
	if not surface then
		return nil
	end

	local bgR, bgG, bgB, borderR, borderG, borderB = GetModernElvUIBackdropColors(E)
	local appliedR, appliedG, appliedB = overrideR or bgR, overrideG or bgG, overrideB or bgB
	local backdropMatches = BackdropColorMatches(surface, "GetBackdropColor", appliedR, appliedG, appliedB, 1)
	if
		surface.SetBackdropColor
		and (backdropMatches == false
			or (backdropMatches == nil
				and (surface.BFL_ElvUIBackdropR ~= appliedR
			or surface.BFL_ElvUIBackdropG ~= appliedG
			or surface.BFL_ElvUIBackdropB ~= appliedB)))
	then
		surface:SetBackdropColor(appliedR, appliedG, appliedB, 1)
		surface.BFL_ElvUIBackdropR = appliedR
		surface.BFL_ElvUIBackdropG = appliedG
		surface.BFL_ElvUIBackdropB = appliedB
	end
	local borderMatches = BackdropColorMatches(surface, "GetBackdropBorderColor", borderR, borderG, borderB, 1)
	if
		surface.SetBackdropBorderColor
		and (borderMatches == false
			or (borderMatches == nil
				and (surface.BFL_ElvUIBorderR ~= borderR
			or surface.BFL_ElvUIBorderG ~= borderG
			or surface.BFL_ElvUIBorderB ~= borderB)))
	then
		surface:SetBackdropBorderColor(borderR, borderG, borderB, 1)
		surface.BFL_ElvUIBorderR = borderR
		surface.BFL_ElvUIBorderG = borderG
		surface.BFL_ElvUIBorderB = borderB
	end
	-- Some BackdropTemplate controls expose SetBackdropColor on the control
	-- itself. Showing that surface would also show the entire control and can
	-- resurrect filters or action buttons owned by a previously selected tab.
	-- Only a dedicated ElvUI backdrop child needs to be made visible here.
	if surface ~= control and surface.Show then
		surface:Show()
	end
	return surface, bgR, bgG, bgB
end

local function HideModernDropdownArrow(dropdown)
	if not dropdown then
		return
	end
	for _, arrow in pairs({ dropdown.Arrow, dropdown.Button }) do
		if arrow and arrow.Hide then
			arrow:Hide()
		else
			SetTextureAlpha(arrow, 0)
		end
	end
end

local function HideButtonStateTextures(button)
	if not button then
		return
	end
	for _, texture in pairs({
		button.NormalTexture,
		button.PushedTexture,
		button.DisabledTexture,
		button.HighlightTexture,
		button.Left,
		button.Middle,
		button.Center,
		button.Right,
		button.GetNormalTexture and button:GetNormalTexture(),
		button.GetPushedTexture and button:GetPushedTexture(),
		button.GetDisabledTexture and button:GetDisabledTexture(),
		button.GetHighlightTexture and button:GetHighlightTexture(),
	}) do
		SetTextureAlpha(texture, 0)
	end
end

local function HideModernNativeChrome(control)
	if not control then
		return
	end

	for _, region in pairs({
		control.Backdrop,
		control.Background,
		control.Left,
		control.Middle,
		control.Center,
		control.Right,
		control.TopBorder,
		control.TopLeftBorder,
		control.TopRightBorder,
		control.BottomBorder,
		control.BottomLeftBorder,
		control.BottomRightBorder,
		control.LeftBorder,
		control.MiddleBorder,
		control.RightBorder,
		control.BFL_ModernHeaderBackground,
	}) do
		SetTextureAlpha(region, 0)
	end

	if control.NineSlice and control.NineSlice.StripTextures then
		control.NineSlice:StripTextures()
	end
end

local function HideModernOwnedSurface(frame)
	if not frame then
		return
	end
	for _, surface in pairs({
		frame.Background,
		frame.BFL_DarkBackdrop,
		frame.BFL_ModernThemeSurface,
	}) do
		if surface and surface.Hide then
			surface:Hide()
		else
			SetTextureAlpha(surface, 0)
		end
	end
end

local function SkinModernScrollBar(S, scrollBar)
	if not scrollBar then
		return
	end
	if not scrollBar.BFL_ElvUIModernScrollSkinned then
		SkinScrollBar(S, scrollBar)
		scrollBar.BFL_ElvUIModernScrollSkinned = true
	end
end

function ElvUISkin:IsModernFriendsUIActive()
	local FriendsUI = BFL.FriendsUI or BFL:GetModule("FriendsUI")
	return FriendsUI and FriendsUI.IsModernActive and FriendsUI:IsModernActive() == true
end

function ElvUISkin:IsEngineInitialized(E, S)
	return (E and (E.Initialized == true or E.initialized == true)) or (S and S.Initialized == true) or false
end

function ElvUISkin:SkinModernEditBox(S, editBox)
	if not editBox then
		return
	end

	if not editBox.BFL_ElvUIModernEditBoxSkinned then
		CallElvUIHandler(S, "HandleEditBox", editBox)
		editBox.BFL_ElvUIModernEditBoxSkinned = true
	end
	-- FriendsUI reapplies SearchBoxTemplate chrome during every section-layout
	-- pass. ElvUI owns the final surface, so suppress the native pieces every
	-- time without recreating the ElvUI backdrop.
	HideModernNativeChrome(editBox)
	if editBox.backdrop and editBox.backdrop.Show then
		editBox.backdrop:Show()
	end
	ApplyModernElvUIBackdrop(self.ElvUIEngine, editBox)
end

function ElvUISkin:SkinModernDropdown(S, dropdown, width)
	if not dropdown then
		return
	end

	if not dropdown.BFL_ElvUIModernDropdownSkinned then
		CallElvUIHandler(S, "HandleDropDownBox", dropdown, width or dropdown:GetWidth())
		dropdown.BFL_ElvUIModernDropdownSkinned = true
	end
	if width and dropdown.SetWidth then
		dropdown:SetWidth(width)
	end
	HideModernNativeChrome(dropdown)
	HideModernDropdownArrow(dropdown)
	if dropdown.backdrop and dropdown.backdrop.Show then
		dropdown.backdrop:Show()
	end
	ApplyModernElvUIBackdrop(self.ElvUIEngine, dropdown)
end

function ElvUISkin:SkinModernFilterDropdown(S, dropdown, width, height)
	if not dropdown then
		return
	end

	if not dropdown.BFL_ElvUIModernFilterSkinned then
		CallElvUIHandler(
			S,
			"HandleButton",
			dropdown,
			nil,
			nil,
			nil,
			nil,
			nil,
			nil,
			nil,
			nil,
			nil,
			nil,
			true,
			"right"
		)
		dropdown.BFL_ElvUIModernFilterSkinned = true
	end
	HideButtonStateTextures(dropdown)
	HideModernNativeChrome(dropdown)
	HideModernDropdownArrow(dropdown)
	if width and height then
		dropdown:SetSize(width, height)
	end
	ApplyModernElvUIBackdrop(self.ElvUIEngine, dropdown)
end

function ElvUISkin:SkinModernDirectoryHeader(S, header)
	if not header then
		return
	end

	if not header.BFL_ElvUIModernDirectoryHeaderSkinned then
		if header.StripTextures then
			header:StripTextures()
		end
		CallElvUIHandler(S, "HandleButton", header)
		header.BFL_ElvUIModernDirectoryHeaderSkinned = true
	end
	HideButtonStateTextures(header)
	HideModernNativeChrome(header)
	ApplyModernElvUIBackdrop(self.ElvUIEngine, header)
end

function ElvUISkin:SkinModernHeaderDropdown(S, dropdown)
	if not dropdown then
		return
	end

	self:SkinModernDirectoryHeader(S, dropdown)
	HideModernDropdownArrow(dropdown)
	if not dropdown.BFL_ElvUIHeaderArrow then
		local arrow = dropdown:CreateTexture(nil, "ARTWORK")
		local E = self.ElvUIEngine
		arrow:SetTexture(
			E and E.Media and E.Media.Textures and E.Media.Textures.ArrowUp
				or "Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up"
		)
		arrow:SetRotation(math.pi)
		arrow:SetSize(10, 10)
		arrow:SetPoint("RIGHT", dropdown, "RIGHT", -5, 0)
		dropdown.BFL_ElvUIHeaderArrow = arrow
	end
	dropdown.BFL_ElvUIHeaderArrow:Show()
end

function ElvUISkin:SkinModernPortrait(E, frame, FriendsUI)
	local portrait = FriendsUI and FriendsUI.root and FriendsUI.root.PortraitOverlay
	if not (portrait and frame) then
		return
	end

	-- PortraitFrameMixin restores the round portrait corner after layout and
	-- SetPortraitShown calls. ElvUI owns a square overlay instead, so suppress
	-- the restored native layer on every final skin pass.
	for _, region in pairs({
		frame.NineSlice and frame.NineSlice.TopLeftCorner,
		frame.Portrait,
		frame.portrait,
		frame.PortraitIcon,
		frame.PortraitMask,
		frame.PortraitOverlay,
		frame.ArtOverlayFrame,
	}) do
		if region and region.Hide then
			region:Hide()
		else
			SetTextureAlpha(region, 0)
		end
	end
	if frame.PortraitContainer then
		frame.PortraitContainer:SetAlpha(0)
	end

	portrait:ClearAllPoints()
	portrait:SetPoint("TOPLEFT", frame, "TOPLEFT", 4, -4)
	portrait:SetSize(42, 42)
	portrait:SetFrameLevel(frame:GetFrameLevel() + 5)
	local backdrop = EnsureTransparentBackdrop(portrait)
	if backdrop then
		backdrop:ClearAllPoints()
		backdrop:SetAllPoints(portrait)
		backdrop:Show()
	end
	ApplyModernElvUIBackdrop(E, portrait)

	local icon = portrait.Icon
	if icon then
		if portrait.Mask and icon.RemoveMaskTexture then
			pcall(icon.RemoveMaskTexture, icon, portrait.Mask)
		end
		icon:ClearAllPoints()
		if icon.SetInside and backdrop then
			icon:SetInside(backdrop)
		else
			icon:SetPoint("TOPLEFT", portrait, "TOPLEFT", 2, -2)
			icon:SetPoint("BOTTOMRIGHT", portrait, "BOTTOMRIGHT", -2, 2)
		end
		icon:SetTexture("Interface\\AddOns\\BetterFriendlist\\Textures\\PortraitIcon.blp")
		if E and E.TexCoords then
			icon:SetTexCoord(unpack(E.TexCoords))
		end
		icon:Show()
	end
	SetTextureAlpha(portrait.Mask, 0)
	portrait.BFL_ModernSquarePortrait = true
	portrait:Show()
end

function ElvUISkin:SkinModernActionButton(S, button)
	if not button then
		return
	end

	if not button.BFL_ElvUIModernActionSkinned then
		if S and S.SocialUI_HandleActionButton then
			CallElvUIHandler(S, "SocialUI_HandleActionButton", button)
		else
			EnsureTransparentBackdrop(button)
		end
		button.BFL_ElvUIModernActionSkinned = true
	end

	SetTextureAlpha(button.NormalTexture or (button.GetNormalTexture and button:GetNormalTexture()), 0)
	SetTextureAlpha(button.PushedTexture or (button.GetPushedTexture and button:GetPushedTexture()), 0)
	SetTextureAlpha(button.DisabledTexture or (button.GetDisabledTexture and button:GetDisabledTexture()), 0)
	local highlight = button.HighlightTexture or (button.GetHighlightTexture and button:GetHighlightTexture())
	if highlight then
		SetTextureColor(highlight, 1, 1, 1, 0.25)
		if highlight.SetAllPoints then
			highlight:SetAllPoints(button.backdrop or button)
		end
	end
	HideModernOwnedSurface(button)
	ApplyModernElvUIBackdrop(self.ElvUIEngine, button)
end

function ElvUISkin:SkinModernBorderlessActionButton(S, button)
	if not button then
		return
	end
	self:SkinModernActionButton(S, button)
	if button.backdrop and button.backdrop.Hide then
		button.backdrop:Hide()
	elseif button.SetBackdropColor then
		button:SetBackdropColor(0, 0, 0, 0)
		if button.SetBackdropBorderColor then
			button:SetBackdropBorderColor(0, 0, 0, 0)
		end
	end
end

function ElvUISkin:SkinModernButton(S, button)
	if not button then
		return
	end
	if not button.BFL_ElvUIModernButtonSkinned then
		CallElvUIHandler(S, "HandleButton", button)
		button.BFL_ElvUIModernButtonSkinned = true
	end
	HideButtonStateTextures(button)
	ApplyModernElvUIBackdrop(self.ElvUIEngine, button)
end

function ElvUISkin:SkinModernDeclineButton(S, button)
	if not button then
		return
	end
	if not button.Icon and button.CreateTexture then
		button.Icon = button:CreateTexture(nil, "ARTWORK")
		button.Icon:SetSize(14, 14)
		button.Icon:SetPoint("CENTER")
	end
	if not button.BFL_ElvUIModernDeclineSkinned then
		CallElvUIHandler(S, "HandleButton", button, nil, true)
		button.BFL_ElvUIModernDeclineSkinned = true
	end
	HideButtonStateTextures(button)
	ApplyModernElvUIBackdrop(self.ElvUIEngine, button)
	if button.Icon then
		button.Icon:Show()
	end
end

function ElvUISkin:SkinModernSideTab(tab)
	if not tab then
		return
	end

	tab:SetSize(30, 40)
	local backdrop = EnsureTransparentBackdrop(tab)
	if backdrop then
		backdrop:ClearAllPoints()
		backdrop:SetAllPoints(tab)
	end
	ApplyModernElvUIBackdrop(self.ElvUIEngine, tab)

	SetTextureAlpha(tab.Background, 0)
	if tab.SelectedTexture then
		if tab.SelectedTexture.SetDrawLayer then
			tab.SelectedTexture:SetDrawLayer("ARTWORK")
		end
		SetTextureColor(tab.SelectedTexture, 1, 0.82, 0, 0.3)
		tab.SelectedTexture:ClearAllPoints()
		tab.SelectedTexture:SetAllPoints(backdrop or tab)
	end
	if tab.HighlightTexture then
		if tab.HighlightTexture.SetDrawLayer then
			tab.HighlightTexture:SetDrawLayer("OVERLAY", 1)
		end
		SetTextureColor(tab.HighlightTexture, 1, 0.82, 0, 0.2)
		tab.HighlightTexture:ClearAllPoints()
		tab.HighlightTexture:SetAllPoints(backdrop or tab)
	end
	if tab.TabGlowAnimation and tab.TabGlowAnimation.Stop then
		tab.TabGlowAnimation:Stop()
	end
	SetTextureAlpha(tab.TabGlow, 0)
	if tab.TabGlow and tab.TabGlow.Hide then
		tab.TabGlow:Hide()
	end
	-- Keep Blizzard's glow suppressed because it still follows the wider native
	-- side-tab silhouette. ThemeGlow is BFL-owned and fits the compact ElvUI
	-- backdrop exactly, so use it for pending requests instead of disabling the
	-- notification altogether.
	if tab.ThemeGlow then
		if tab.ThemeGlow.SetDrawLayer then
			tab.ThemeGlow:SetDrawLayer("OVERLAY", 2)
		end
		tab.ThemeGlow:ClearAllPoints()
		tab.ThemeGlow:SetAllPoints(backdrop or tab)
		SetTextureColor(tab.ThemeGlow, 1, 0.82, 0, 0.2)
	end
	if tab.BFL_RequestGlowActive then
		if tab.ThemeGlow then
			tab.ThemeGlow:Show()
		end
		if
			tab.ThemeGlowAnimation
			and tab.ThemeGlowAnimation.Play
			and (not tab.ThemeGlowAnimation.IsPlaying or not tab.ThemeGlowAnimation:IsPlaying())
		then
			tab.ThemeGlowAnimation:Play()
		end
	else
		if tab.ThemeGlowAnimation and tab.ThemeGlowAnimation.Stop then
			tab.ThemeGlowAnimation:Stop()
		end
		if tab.ThemeGlow and tab.ThemeGlow.Hide then
			tab.ThemeGlow:Hide()
		end
	end
	for _, glow in pairs({ tab.Glow, tab.SelectedGlow, tab.NewFeatureGlow }) do
		SetTextureAlpha(glow, 0)
		if glow and glow.Hide then
			glow:Hide()
		end
	end
	if tab.Icon then
		tab.Icon:ClearAllPoints()
		tab.Icon:SetPoint("CENTER", backdrop or tab, "CENTER")
	end
	tab.BFL_ElvUIModernHighlightReady = true
	tab.BFL_ElvUIModernTabSkinned = true
end

function ElvUISkin:SkinModernSocialCard(S, button)
	if not button then
		return
	end

	local backdrop = EnsureTransparentBackdrop(button, 2)
	SetTextureAlpha(button.CardBackground or button.Background, 0)
	SetTextureAlpha(button.ThemeTint, 0)

	-- BFL's faction mask follows Blizzard's rounded card atlas. Transfer the
	-- color to ElvUI's rectangular backdrop and mix it with ElvUI's base color
	-- so the signal stays visible without the fully saturated red/blue blocks.
	local factionR, factionG, factionB
	if button.FactionTint and button.FactionTint.IsShown and button.FactionTint:IsShown() then
		if button.FactionTint.GetColorTexture then
			factionR, factionG, factionB = button.FactionTint:GetColorTexture()
		end
		button.FactionTint:Hide()
	end
	local bgR, bgG, bgB = GetModernElvUIBackdropColors(self.ElvUIEngine)
	if factionR and factionG and factionB and backdrop then
		local factionMix = 0.22
		ApplyModernElvUIBackdrop(
			self.ElvUIEngine,
			button,
			bgR * (1 - factionMix) + factionR * factionMix,
			bgG * (1 - factionMix) + factionG * factionMix,
			bgB * (1 - factionMix) + factionB * factionMix
		)
	else
		ApplyModernElvUIBackdrop(self.ElvUIEngine, button)
	end

	local highlight = button.highlight or button.Highlight or (button.GetHighlightTexture and button:GetHighlightTexture())
	if highlight then
		SetTextureColor(highlight, 0.24, 0.56, 1, 0.2)
		if highlight.SetInside then
			highlight:SetInside(backdrop or button)
		elseif highlight.SetAllPoints then
			highlight:SetAllPoints(backdrop or button)
		end
	end

	local selected = button.Selected or button.selected
	if selected then
		SetTextureColor(selected, 1, 0.82, 0, 0.2)
		if selected.SetAllPoints then
			selected:SetAllPoints(backdrop or button)
		end
	end

	for _, actionButton in pairs({
		button.travelPassButton,
		button.PartyButton,
		button.RAFSummonButton,
	}) do
		self:SkinModernBorderlessActionButton(S, actionButton)
	end
	if button.AcceptButton then
		local declineHeight = button.DeclineButton and button.DeclineButton.GetHeight and button.DeclineButton:GetHeight()
		if declineHeight and declineHeight > 0 then
			button.AcceptButton.baseHeight = button.DeclineButton.baseHeight or declineHeight
			button.AcceptButton:SetHeight(declineHeight)
		end
		self:SkinModernButton(S, button.AcceptButton)
	end
	if button.DeclineButton then
		self:SkinModernDeclineButton(S, button.DeclineButton)
	end
	button.BFL_ElvUIModernCardSkinned = true
end

function ElvUISkin:SkinModernScrollableHeader(S, button)
	if not button then
		return
	end
	-- Both group and request-section headers use ElvUI's opaque control surface.
	-- The collapse button remains a child and therefore keeps its existing icon
	-- and click behavior while the translucent Blizzard atlas is removed.
	self:SkinModernDirectoryHeader(S, button)
	button.BFL_ElvUIModernHeaderSkinned = true
	SetTextureAlpha(button.GetNormalTexture and button:GetNormalTexture(), 0)
	SetTextureAlpha(button.GetPushedTexture and button:GetPushedTexture(), 0)
end

function ElvUISkin:SkinModernDynamicRow(S, button)
	if not button then
		return
	end

	if button.HeaderText or button.ButtonText then
		self:SkinModernScrollableHeader(S, button)
	elseif button.CardBackground or button.Background or button.PartyButton or button.AcceptButton then
		self:SkinModernSocialCard(S, button)
	end
end

function ElvUISkin:SkinModernScrollBoxRows(S, scrollBox)
	if not (scrollBox and scrollBox.ForEachFrame) then
		return
	end

	scrollBox:ForEachFrame(function(button)
		self:SkinModernDynamicRow(S, button)
	end)
end

function ElvUISkin:SkinModernTabs(FriendsUI)
	local previous
	for _, tab in ipairs((FriendsUI and FriendsUI.sideTabs) or {}) do
		if tab and tab.IsShown and tab:IsShown() then
			self:SkinModernSideTab(tab)
			tab:ClearAllPoints()
			if previous then
				tab:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -1)
			else
				tab:SetPoint("TOPLEFT", _G.BetterFriendsFrame, "TOPRIGHT", 2, -1)
			end
			previous = tab
		end
	end
end

function ElvUISkin:InstallModernDynamicHooks(E, S, FriendsUI)
	if self.ModernDynamicHooksInstalled then
		return
	end
	self.ModernDynamicHooksInstalled = true

	local function SkinRow(button)
		if self:IsSkinEnabled() and self:IsModernFriendsUIActive() then
			self:SkinModernDynamicRow(S, button)
		end
	end

	if FriendsUI then
		if FriendsUI.ApplyModernPortrait then
			hooksecurefunc(FriendsUI, "ApplyModernPortrait", function()
				if self:IsSkinEnabled() and self:IsModernFriendsUIActive() then
					self:SkinModernPortrait(E, _G.BetterFriendsFrame, FriendsUI)
				end
			end)
		end
		if FriendsUI.InitializeRequestHeader then
			hooksecurefunc(FriendsUI, "InitializeRequestHeader", function(_, button)
				SkinRow(button)
			end)
		end
		if FriendsUI.InitializeRequestCard then
			hooksecurefunc(FriendsUI, "InitializeRequestCard", function(_, button)
				SkinRow(button)
			end)
		end
		if FriendsUI.RefreshNavigation then
			hooksecurefunc(FriendsUI, "RefreshNavigation", function()
				if self:IsSkinEnabled() and self:IsModernFriendsUIActive() then
					self:SkinModernTabs(FriendsUI)
				end
			end)
		end
		for _, methodName in ipairs({ "StartRequestGlow", "StopRequestGlow" }) do
			if FriendsUI[methodName] then
				hooksecurefunc(FriendsUI, methodName, function()
					if self:IsSkinEnabled() and self:IsModernFriendsUIActive() then
						self:SkinModernTabs(FriendsUI)
					end
				end)
			end
		end
	end

	for _, hookInfo in ipairs({
		{ "RecentAllies", "InitializeEntry" },
		{ "QuickJoin", "OnScrollBoxInitialize" },
		{ "RAF", "RecruitListButton_Init" },
		{ "GuildFrame", "UpdateMemberButton" },
		{ "WhoFrame", "InitButton" },
		{ "RaidFrame", "UpdateMemberButton" },
	}) do
		local module = BFL:GetModule(hookInfo[1])
		local methodName = hookInfo[2]
		if module and type(module[methodName]) == "function" then
			hooksecurefunc(module, methodName, function(_, button)
				SkinRow(button)
			end)
		end
	end
end

function ElvUISkin:SkinModernFrames(E, S, frame, FriendsUI)
	if not (frame and FriendsUI and FriendsUI.root and FriendsUI:IsModernActive()) then
		return false
	end

	self.lastAppliedStyle = "modern"

	if not frame.BFL_ElvUIModernFrameSkinned then
		CallElvUIHandler(S, "HandlePortraitFrame", frame)
		frame.BFL_ElvUIModernFrameSkinned = true
	end
	self:SkinModernPortrait(E, frame, FriendsUI)

	local root = FriendsUI.root
	SetTextureAlpha(root.ContentBackground, 0)
	SetTextureAlpha(root.ContentInsetTint, 0)
	SetTextureAlpha(root.TopFade, 0)
	SetTextureAlpha(root.BottomFade, 0)
	SetTextureAlpha(root.TopDivider, 0)
	SetTextureAlpha(root.BottomDivider, 0)
	if root.FilterBar then
		SetTextureAlpha(root.FilterBar.Background, 0)
	end
	if root.BattleNetBar then
		SetTextureAlpha(root.BattleNetBar.Background, 0)
		HideModernOwnedSurface(root.BattleNetBar)
		if root.BattleNetBar.backdrop and root.BattleNetBar.backdrop.Hide then
			root.BattleNetBar.backdrop:Hide()
		end
	end

	local header = frame.FriendsTabHeader
	local battleNetDisplay = header and header.BattlenetFrame
	if battleNetDisplay then
		if not battleNetDisplay.BFL_ElvUIModernDisplaySkinned then
			battleNetDisplay:StripTextures()
			battleNetDisplay.BFL_ElvUIModernDisplaySkinned = true
		end
		SetTextureAlpha(battleNetDisplay.Background, 0)
		HideModernOwnedSurface(battleNetDisplay)
		if battleNetDisplay.backdrop and battleNetDisplay.backdrop.Hide then
			battleNetDisplay.backdrop:Hide()
		end
		if battleNetDisplay.Tag and battleNetDisplay.Tag.SetTextColor then
			battleNetDisplay.Tag:SetTextColor(1, 1, 1)
		end
	end

	local statusDropdown = header and header.StatusDropdown
	if statusDropdown then
		self:SkinModernDropdown(S, statusDropdown, 54)
		statusDropdown:SetSize(54, 30)
	end
	if header and header.SearchBox then
		self:SkinModernEditBox(S, header.SearchBox)
	end

	local filterBar = root.FilterBar
	for _, dropdown in pairs({
		filterBar and filterBar.FilterDropdown,
		filterBar and filterBar.RecentFilterDropdown,
		filterBar and filterBar.SortButton,
	}) do
		if dropdown then
			self:SkinModernFilterDropdown(S, dropdown, 92, 29)
		end
	end

	self:SkinModernButton(S, root.BottomActionBar and root.BottomActionBar.AddFriendButton)
	self:SkinModernButton(
		S,
		root.RequestsFrame and root.RequestsFrame.RealIDWarning and root.RequestsFrame.RealIDWarning.ContinueButton
	)
	self:SkinModernActionButton(S, root.BattleNetBar and root.BattleNetBar.MenuButton)
	self:SkinModernBorderlessActionButton(S, root.BattleNetBar and root.BattleNetBar.CopyBattleTagButton)
	self:SkinModernBorderlessActionButton(S, frame.StreamerModeButton)
	self:SkinModernTabs(FriendsUI)

	local who = frame.WhoFrame
	if who then
		self:SkinModernEditBox(S, who.EditBox)
		self:SkinModernHeaderDropdown(S, who.ColumnDropdown)
		for _, headerButton in pairs({ who.NameHeader, who.LevelHeader, who.ClassHeader }) do
			self:SkinModernDirectoryHeader(S, headerButton)
		end
		for _, control in pairs({ who.WhoButton, who.AddFriendButton, who.GroupInviteButton }) do
			self:SkinModernButton(S, control)
		end
		for _, headerButton in pairs({ who.NameHeader, who.LevelHeader, who.ClassHeader }) do
			if headerButton then
				headerButton:SetHeight(28)
			end
		end
	end

	local guild = frame.GuildFrame
	if guild then
		self:SkinModernEditBox(S, guild.SearchBox)
		self:SkinModernFilterDropdown(S, guild.FilterDropdown, 92, 29)
		self:SkinModernFilterDropdown(S, guild.SortDropdown, 92, 29)
		for _, headerButton in pairs({
			guild.NameHeader,
			guild.RankHeader,
			guild.LevelHeader,
			guild.ZoneHeader,
			guild.ILvlHeader,
		}) do
			self:SkinModernDirectoryHeader(S, headerButton)
		end
		for _, control in pairs({
			guild.FilterAll,
			guild.FilterOnline,
			guild.FilterOffline,
			guild.ActionsButton,
			guild.InvitePlayerButton,
		}) do
			self:SkinModernButton(S, control)
		end
	end

	local quickJoin = frame.QuickJoinFrame
	local quickJoinInset = quickJoin and quickJoin.ContentInset
	self:SkinModernButton(S, quickJoinInset and quickJoinInset.JoinQueueButton)
	if quickJoinInset then
		SetTextureAlpha(quickJoinInset.Bg, 0)
		SetTextureAlpha(quickJoinInset.NineSlice, 0)
	end

	local raf = frame.RecruitAFriendFrame
	if raf then
		self:SkinModernButton(S, frame.RecruitmentButton)
		self:SkinModernButton(S, raf.RewardClaiming and raf.RewardClaiming.ClaimOrViewRewardButton)
		self:SkinModernButton(S, raf.SplashFrame and raf.SplashFrame.OKButton)
	end

	local raid = frame.RaidFrame
	if raid then
		self:SkinModernButton(S, raid.ConvertToRaidButton)
		self:SkinModernButton(S, raid.RaidToolsButton)
		self:SkinModernButton(S, raid.ControlPanel and raid.ControlPanel.RaidInfoButton)
		self:SkinModernButton(S, raid.ControlPanel and raid.ControlPanel.ReadyCheckButton)
		CallElvUIHandler(S, "HandleCheckBox", raid.ControlPanel and raid.ControlPanel.EveryoneAssistCheckbox)
	end

	local ignoreWindow = frame.IgnoreListWindow
	if ignoreWindow then
		self:SkinIgnoreListWindow(ignoreWindow, E, S)
	end

	local FriendsList = BFL:GetModule("FriendsList")
	for _, scrollBar in pairs({
		frame.MinimalScrollBar,
		frame.RecentAlliesFrame and frame.RecentAlliesFrame.ScrollBar,
		root.RequestsFrame and root.RequestsFrame.ScrollBar,
		root.RequestsFrame and root.RequestsFrame.RealIDWarning and root.RequestsFrame.RealIDWarning.ScrollBar,
		quickJoinInset and quickJoinInset.ScrollBar,
		raf and raf.RecruitList and raf.RecruitList.ScrollBar,
		who and who.ScrollBar,
		guild and guild.ScrollBar,
		raid and raid.ScrollBar,
	}) do
		SkinModernScrollBar(S, scrollBar)
	end

	for _, scrollBox in pairs({
		FriendsList and FriendsList.scrollBox,
		frame.RecentAlliesFrame and frame.RecentAlliesFrame.ScrollBox,
		root.RequestsFrame and root.RequestsFrame.ScrollBox,
		quickJoinInset and (quickJoinInset.ScrollBox or quickJoinInset.ScrollBoxContainer),
		raf and raf.RecruitList and raf.RecruitList.ScrollBox,
		who and who.ScrollBox,
		guild and guild.ScrollBox,
	}) do
		self:SkinModernScrollBoxRows(S, scrollBox)
	end

	self:SkinSearchBuilder(E, S)

	self:InstallModernDynamicHooks(E, S, FriendsUI)
	return true
end

function ElvUISkin:RefreshModernSkin()
	if self.applyingModernSkin or not self:IsSkinEnabled() or not self:IsModernFriendsUIActive() then
		return false
	end

	local E = self.ElvUIEngine or (BFL.GetElvUIEngine and BFL:GetElvUIEngine(false))
	local S = self.ElvUISkinProxy or (E and E.GetModule and E:GetModule("Skins"))
	local frame = _G.BetterFriendsFrame
	local FriendsUI = BFL.FriendsUI or BFL:GetModule("FriendsUI")
	if not (E and S and frame and FriendsUI) then
		return false
	end

	self.applyingModernSkin = true
	local ok, result = xpcall(function()
		return self:SkinModernFrames(E, S, frame, FriendsUI)
	end, function(err)
		return err
	end)
	self.applyingModernSkin = nil
	if not ok then
		return false
	end
	return result
end

function ElvUISkin:RegisterTests()
	if self.testsRegistered then
		return
	end
	local TestSuite = BFL:GetModule("TestSuite")
	if not (TestSuite and TestSuite.RegisterTest) then
		return
	end
	self.testsRegistered = true

	TestSuite:RegisterTest("ui", "ElvUISkin_InitializationContract", {
		action = function(V)
			V:Assert(self:IsEngineInitialized({ Initialized = true }, nil), "Current ElvUI initialization flag is supported")
			V:Assert(self:IsEngineInitialized({ initialized = true }, nil), "Legacy ElvUI initialization flag remains supported")
			V:Assert(self:IsEngineInitialized({}, { Initialized = true }), "Initialized Skins module is supported")
			V:Assert(not self:IsEngineInitialized({}, {}), "Uninitialized ElvUI is not treated as ready")
			local controlShown = false
			local hiddenControl = {
				SetBackdropColor = function() end,
				SetBackdropBorderColor = function() end,
				Show = function()
					controlShown = true
				end,
			}
			ApplyModernElvUIBackdrop({}, hiddenControl)
			V:Assert(not controlShown, "ElvUI backdrop refresh does not resurrect hidden controls")

			local backdropState = { r = 0, g = 0, b = 0, borderR = 0, borderG = 0, borderB = 0 }
			local repaired = {
				SetBackdropColor = function(_, r, g, b)
					backdropState.r, backdropState.g, backdropState.b = r, g, b
				end,
				GetBackdropColor = function()
					return backdropState.r, backdropState.g, backdropState.b, 1
				end,
				SetBackdropBorderColor = function(_, r, g, b)
					backdropState.borderR, backdropState.borderG, backdropState.borderB = r, g, b
				end,
				GetBackdropBorderColor = function()
					return backdropState.borderR, backdropState.borderG, backdropState.borderB, 1
				end,
			}
			local engine = { media = { backdropcolor = { 0.1, 0.2, 0.3 }, bordercolor = { 0.4, 0.5, 0.6 } } }
			ApplyModernElvUIBackdrop(engine, repaired)
			backdropState.r, backdropState.g, backdropState.b = 0.9, 0.8, 0.7
			backdropState.borderR, backdropState.borderG, backdropState.borderB = 0.7, 0.8, 0.9
			ApplyModernElvUIBackdrop(engine, repaired)
			V:AssertEqual(backdropState.r, 0.1, "ElvUI refresh repairs same-object backdrop drift")
			V:AssertEqual(backdropState.borderB, 0.6, "ElvUI refresh repairs same-object border drift")
		end,
	})

	TestSuite:RegisterTest("ui", "ElvUISkin_ModernGeometryContract", {
		condition = function()
			return self:IsSkinEnabled() and self:IsModernFriendsUIActive() and BFL.FriendsUI and BFL.FriendsUI.root
		end,
		action = function(V)
			self:RefreshModernSkin()
			local FriendsUI = BFL.FriendsUI
			local root = FriendsUI.root
			local header = BetterFriendsFrame and BetterFriendsFrame.FriendsTabHeader
			local portrait = root.PortraitOverlay
			V:AssertEqual(root.FilterBar.FilterDropdown:GetWidth(), 92, "Modern ElvUI filter keeps BFL width")
			V:AssertEqual(root.FilterBar.FilterDropdown:GetHeight(), 29, "Modern ElvUI filter keeps BFL height")
			V:AssertEqual(root.FilterBar.SortButton:GetWidth(), 92, "Modern ElvUI sort keeps BFL width")
			V:AssertEqual(root.FilterBar.SortButton:GetHeight(), 29, "Modern ElvUI sort keeps BFL height")
			V:AssertEqual(header.StatusDropdown:GetWidth(), 54, "Modern ElvUI status keeps the manifest width")
			V:AssertEqual(header.StatusDropdown:GetHeight(), 30, "Modern ElvUI status keeps the manifest height")
			V:Assert(header.SearchBox.BFL_ElvUIModernEditBoxSkinned, "Modern ElvUI owns the shared search field")
			V:Assert(root.FilterBar.FilterDropdown.BFL_ElvUIModernFilterSkinned, "Modern filter uses ElvUI filter chrome")
			local selectedSection = FriendsUI:GetSelectedSection()
			if selectedSection == "friends" and not FriendsUI:IsSimpleModeContactSection(selectedSection) then
				V:Assert(root.FilterBar.FilterDropdown:IsShown(), "Friends keeps its filter visible after the ElvUI pass")
				V:Assert(not root.FilterBar.RecentFilterDropdown:IsShown(), "Friends does not resurrect the Recent Allies filter")
				V:Assert(root.FilterBar.SortButton:IsShown(), "Friends keeps its sorter visible after the ElvUI pass")
			elseif selectedSection == "recent_allies" and not FriendsUI:IsSimpleModeContactSection(selectedSection) then
				V:Assert(not root.FilterBar.FilterDropdown:IsShown(), "Recent Allies does not resurrect the Friends filter")
				V:Assert(root.FilterBar.RecentFilterDropdown:IsShown(), "Recent Allies keeps its own filter visible")
				V:Assert(not root.FilterBar.SortButton:IsShown(), "Recent Allies does not resurrect the Friends sorter")
			end
			V:AssertEqual(portrait:GetWidth(), 42, "Modern ElvUI portrait matches the Legacy logo width")
			V:AssertEqual(portrait:GetHeight(), 42, "Modern ElvUI portrait matches the Legacy logo height")
			local point, relativeTo, relativePoint, x, y = portrait:GetPoint(1)
			V:AssertEqual(point, "TOPLEFT", "Modern ElvUI portrait uses the Legacy anchor")
			V:AssertEqual(relativeTo, BetterFriendsFrame, "Modern ElvUI portrait anchors to the main frame")
			V:AssertEqual(relativePoint, "TOPLEFT", "Modern ElvUI portrait aligns with the frame corner")
			V:AssertEqual(x, 4, "Modern ElvUI portrait keeps the Legacy horizontal inset")
			V:AssertEqual(y, -4, "Modern ElvUI portrait keeps the Legacy vertical inset")
			V:Assert(
				not root.BattleNetBar.Background or root.BattleNetBar.Background:GetAlpha() == 0,
				"Modern ElvUI suppresses the Battle.net bar background"
			)
			for _, button in ipairs({ root.BattleNetBar.CopyBattleTagButton, BetterFriendsFrame.StreamerModeButton }) do
				V:Assert(not button.backdrop or not button.backdrop:IsShown(), "Modern header icon buttons remain borderless")
			end
			local previousTab
			local selectedTabCount = 0
			for _, tab in ipairs(FriendsUI.sideTabs or {}) do
				if tab:IsShown() then
					V:AssertEqual(tab:GetWidth(), 30, "Modern ElvUI side tabs match SocialUI width")
					V:AssertEqual(tab:GetHeight(), 40, "Modern ElvUI side tabs match SocialUI height")
					V:Assert(tab.BFL_ElvUIModernHighlightReady, "Modern ElvUI side tabs own a fitted hover highlight")
					if tab.BFL_RequestGlowActive then
						V:Assert(tab.ThemeGlow and tab.ThemeGlow:IsShown(), "Modern ElvUI keeps the fitted request glow functional")
					else
						V:Assert(not tab.ThemeGlow or not tab.ThemeGlow:IsShown(), "Modern ElvUI hides idle request glows")
					end
					local selected = tab.sectionID == FriendsUI.selectedSection
					local selectedTextureShown = tab.SelectedTexture and tab.SelectedTexture:IsShown() or false
					V:AssertEqual(
						selectedTextureShown,
						selected,
						"Modern ElvUI exposes the selected texture only for the active side tab"
					)
					if selectedTextureShown then
						selectedTabCount = selectedTabCount + 1
					end
					local tabPoint, tabRelativeTo, tabRelativePoint, tabX, tabY = tab:GetPoint(1)
					V:AssertEqual(tabPoint, "TOPLEFT", "Modern ElvUI side tabs use top-left chaining")
					if previousTab then
						V:AssertEqual(tabRelativeTo, previousTab, "Modern ElvUI side tabs form one compact rail")
						V:AssertEqual(tabRelativePoint, "BOTTOMLEFT", "Modern ElvUI side tabs chain vertically")
						V:AssertEqual(tabX, 0, "Modern ElvUI side tabs share one horizontal edge")
						V:AssertEqual(tabY, -1, "Modern ElvUI side tabs keep a one-pixel gap")
					else
						V:AssertEqual(tabRelativeTo, BetterFriendsFrame, "Modern ElvUI side tabs anchor to the main frame")
						V:AssertEqual(tabRelativePoint, "TOPRIGHT", "Modern ElvUI side tabs begin at the frame top")
						V:AssertEqual(tabX, 2, "Modern ElvUI side tabs use SocialUI's horizontal offset")
						V:AssertEqual(tabY, -1, "Modern ElvUI side tabs use SocialUI's vertical offset")
					end
					previousTab = tab
				end
			end
			V:AssertEqual(selectedTabCount, 1, "Modern ElvUI keeps exactly one visible side tab selected")
			V:AssertEqual(self.lastAppliedStyle, "modern", "Modern ElvUI uses the dedicated skin pipeline")
		end,
	})
end

function ElvUISkin:SkinIgnoreListWindow(ignoreWindow, E, S)
	if not self:IsSkinEnabled() or not ignoreWindow then
		return false
	end
	E = E or self.ElvUIEngine or (BFL.GetElvUIEngine and BFL:GetElvUIEngine(false))
	S = S or self.ElvUISkinProxy or (E and E.GetModule and E:GetModule("Skins"))
	if not S then
		return false
	end

	if not ignoreWindow.BFL_ElvUIIgnoreListSkinned then
		CallElvUIHandler(S, "HandlePortraitFrame", ignoreWindow)
		if ignoreWindow.Inset then
			if ignoreWindow.Inset.StripTextures then
				ignoreWindow.Inset:StripTextures()
			end
			if ignoreWindow.Inset.CreateBackdrop then
				ignoreWindow.Inset:CreateBackdrop("Transparent")
			end
		end
		SkinScrollBar(S, ignoreWindow.ScrollBar or ignoreWindow.ClassicScrollBar)
		ignoreWindow.BFL_ElvUIIgnoreListSkinned = true
	end

	for _, button in ipairs({
		ignoreWindow.UnignorePlayerButton,
		ignoreWindow.GlobalIgnoreListButton,
		ignoreWindow.EnhanceQoLIgnoreButton,
	}) do
		if button and button.IsObjectType and button:IsObjectType("Button") then
			if not button.BFL_ElvUIIgnoreButtonSkinned then
				CallElvUIHandler(S, "HandleButton", button)
				button.BFL_ElvUIIgnoreButtonSkinned = true
			end
			if button.Icon then
				button.Icon:SetDrawLayer("OVERLAY")
				button.Icon:SetAlpha(1)
				button.Icon:Show()
			end
		end
	end
	return true
end
