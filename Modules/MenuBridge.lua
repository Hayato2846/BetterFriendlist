local ADDON_NAME, BFL = ...
local MenuBridge = BFL:RegisterModule("MenuBridge", {})

local PROVIDER_VERSION = 1
local MENU_UNIT_PREFIX = "MENU_UNIT_"
local EARLY_CAPTURE_GLOBAL = "BetterFriendlist_MenuBridgeCaptures"

local DESCRIPTION_METHODS = {
	CreateButton = true,
	CreateCheckbox = true,
	CreateDivider = true,
	CreateRadio = true,
	CreateTemplate = true,
	CreateTitle = true,
	SetScrollMode = true,
}

local function IsSecret(value)
	return BFL.IsSecret and BFL:IsSecret(value)
end

local function SafeValue(tableValue, key)
	if not tableValue then
		return nil
	end

	local ok, value = pcall(function()
		return tableValue[key]
	end)
	if not ok or IsSecret(value) then
		return nil
	end
	return value
end

local function NormalizeMenuType(menuType)
	if type(menuType) ~= "string" then
		return nil
	end
	local normalized = menuType:gsub("^" .. MENU_UNIT_PREFIX, "")
	return normalized
end

local function GetMenuTag(menuType)
	if type(menuType) ~= "string" then
		return nil
	end
	if menuType:match("^MENU_") then
		return menuType
	end
	local normalized = NormalizeMenuType(menuType)
	if not normalized or normalized == "" then
		return nil
	end
	return MENU_UNIT_PREFIX .. normalized
end

local function NormalizeMenuTypes(menuTypes)
	local normalized = {}
	if type(menuTypes) ~= "table" then
		return normalized
	end

	for key, value in pairs(menuTypes) do
		local menuType
		if type(key) == "number" then
			menuType = NormalizeMenuType(value)
		elseif value then
			menuType = NormalizeMenuType(key)
		end
		if menuType then
			normalized[menuType] = true
		end
	end
	return normalized
end

local function GetDBValue(key, fallback)
	local DB = BFL:GetModule("DB")
	if DB and DB.Get then
		local value = DB:Get(key, fallback)
		if value ~= nil then
			return value
		end
	end
	if BetterFriendlistDB and BetterFriendlistDB[key] ~= nil then
		return BetterFriendlistDB[key]
	end
	return fallback
end

local function GetSourceAddonName()
	if not debugstack then
		return nil
	end

	local ok, stack = pcall(debugstack, 3, 12, 0)
	if not ok or type(stack) ~= "string" then
		return nil
	end

	for addonName in stack:gmatch("[Ii]nterface[/\\][Aa]dd[Oo]ns[/\\]([^/\\:\r\n]+)") do
		if addonName ~= ADDON_NAME and not addonName:match("^Blizzard_") then
			return addonName
		end
	end
	return nil
end

local function SafeAddOnTitle(addonName)
	if type(addonName) ~= "string" or addonName == "" then
		return nil
	end
	if BFL.Compat and BFL.Compat.GetAddOnMetadata then
		local title = BFL.Compat.GetAddOnMetadata(addonName, "Title")
		if type(title) == "string" and title ~= "" then
			local cleanTitle = title:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
			return cleanTitle
		end
	end
	return addonName
end

local function CopySafeFields(source, keys)
	if not source then
		return nil
	end

	local copy
	for _, key in ipairs(keys) do
		local value = SafeValue(source, key)
		local valueType = type(value)
		if valueType == "string" or valueType == "number" or valueType == "boolean" then
			copy = copy or {}
			copy[key] = value
		end
	end
	return copy
end

local function ResolveBNetAccountInfo(accountID)
	if type(accountID) ~= "number" then
		accountID = tonumber(accountID)
	end
	if not accountID or not (C_BattleNet and C_BattleNet.GetAccountInfoByID) then
		return nil
	end

	local ok, accountInfo = pcall(C_BattleNet.GetAccountInfoByID, accountID)
	if ok and not IsSecret(accountInfo) then
		return accountInfo
	end
	return nil
end

local function BuildSafeAccountInfo(contextData, accountID)
	local accountInfo = SafeValue(contextData, "accountInfo") or ResolveBNetAccountInfo(accountID)
	if not accountInfo then
		return nil
	end

	local safeAccountInfo = CopySafeFields(accountInfo, {
		"battleTag",
		"bnetAccountID",
		"isBattleTagFriend",
		"isFavorite",
		"isFriend",
		"lastOnlineTime",
	})

	local gameAccountInfo = SafeValue(accountInfo, "gameAccountInfo")
	local safeGameAccountInfo = CopySafeFields(gameAccountInfo, {
		"areaName",
		"characterLevel",
		"characterName",
		"className",
		"clientProgram",
		"factionName",
		"gameAccountID",
		"isGameAFK",
		"isGameBusy",
		"isInCurrentRegion",
		"isOnline",
		"realmDisplayName",
		"realmName",
		"richPresence",
		"wowProjectID",
	})

	if safeGameAccountInfo then
		safeAccountInfo = safeAccountInfo or {}
		safeAccountInfo.gameAccountInfo = safeGameAccountInfo
	end

	if safeAccountInfo and next(safeAccountInfo) then
		return safeAccountInfo
	end
	return nil
end

local function SameAddOnName(left, right)
	if type(left) ~= "string" or type(right) ~= "string" then
		return false
	end
	return left:lower() == right:lower()
end

local function CreateExternalSection(rootDescription, safeContext)
	local section = {
		created = false,
		contextData = safeContext,
		tag = safeContext and safeContext.menuTag,
	}
	local wrappers = {}

	local function EnsureSection()
		if section.created then
			return true
		end
		if not (rootDescription and rootDescription.CreateButton) then
			return false
		end
		if rootDescription.CreateDivider then
			rootDescription:CreateDivider()
		end
		if rootDescription.CreateTitle then
			local L = BFL.L or {}
			rootDescription:CreateTitle(L.MENU_EXTERNAL_ADDONS or "AddOns")
		end
		section.created = true
		return true
	end

	local function CallRootMethod(methodName, ...)
		if not EnsureSection() then
			return nil
		end
		local method = rootDescription and rootDescription[methodName]
		if type(method) ~= "function" then
			return nil
		end
		return method(rootDescription, ...)
	end

	setmetatable(section, {
		__index = function(_, key)
			if not DESCRIPTION_METHODS[key] then
				return nil
			end
			if not wrappers[key] then
				wrappers[key] = function(_, ...)
					return CallRootMethod(key, ...)
				end
			end
			return wrappers[key]
		end,
	})

	return section
end

MenuBridge.providers = {}
MenuBridge.providerOrder = {}
MenuBridge.dynamicModifiersByTag = {}
MenuBridge.dynamicModifierOrder = {}
MenuBridge.dynamicModifierLookup = {}
MenuBridge.earlyCaptureScanIndex = 0
MenuBridge.lazyWarmupDone = false
MenuBridge.lazyWarmupAttempts = 0
MenuBridge.lazyWarmupCaptured = 0
MenuBridge.lazyWarmupLastError = nil
MenuBridge.detectedMenus = {}
MenuBridge.modifyMenuDiagnosticInstalled = false

function MenuBridge:IsEnabled()
	if not BFL.HasSecretValues then
		return false
	end
	if GetDBValue("enableBetaFeatures", false) ~= true then
		return false
	end
	return GetDBValue("externalMenuBridgeEnabled", false) == true
end

function MenuBridge:RefreshEnabledState()
	self:InstallModifyMenuDiagnostic()
end

function MenuBridge:RegisterProvider(provider)
	if type(provider) ~= "table" or type(provider.populate) ~= "function" then
		return false
	end

	local id = provider.id or provider.addonName or ("provider-" .. tostring(#self.providerOrder + 1))
	if type(id) ~= "string" or id == "" then
		return false
	end

	local normalized = NormalizeMenuTypes(provider.menuTypes)
	if not next(normalized) then
		return false
	end

	local entry = {
		id = id,
		version = provider.version or PROVIDER_VERSION,
		addonName = provider.addonName,
		label = provider.label,
		menuTypes = normalized,
		canShow = provider.canShow,
		populate = provider.populate,
		allowInCombat = provider.allowInCombat == true,
		fallbackIfDynamicModifier = provider.fallbackIfDynamicModifier == true,
		disabled = false,
		lastError = nil,
	}

	if not self.providers[id] then
		self.providerOrder[#self.providerOrder + 1] = id
	end
	self.providers[id] = entry
	return true
end

function MenuBridge:CreateSafeContext(contextData, menuType)
	local normalizedMenuType = NormalizeMenuType(menuType)
	local safeContext = {
		menuType = normalizedMenuType,
		menuTag = GetMenuTag(menuType),
		which = normalizedMenuType,
		bflOrigin = ADDON_NAME,
	}

	local safeKeys = {
		"name",
		"server",
		"realm",
		"guid",
		"unit",
		"bnetIDAccount",
		"battleTag",
		"friendsList",
		"index",
		"friendsIndex",
		"uid",
		"lineID",
		"chatType",
		"chatTarget",
		"isOffline",
		"isGuildMember",
		"bflWhoPlayerMenu",
		"bfl_streamerDisplayName",
		"fromPlayerFrame",
		"isMobile",
		"isRafRecruit",
		"realmID",
		"whoIndex",
	}

	for _, key in ipairs(safeKeys) do
		local value = SafeValue(contextData, key)
		local valueType = type(value)
		if valueType == "string" or valueType == "number" or valueType == "boolean" then
			safeContext[key] = value
		end
	end

	safeContext.accountInfo = BuildSafeAccountInfo(contextData, safeContext.bnetIDAccount)

	return safeContext
end

function MenuBridge:RegisterDynamicModifier(tag, callback, addonName, source)
	if type(callback) ~= "function" then
		return false
	end
	local menuType = NormalizeMenuType(tag)
	if type(tag) ~= "string" or not menuType or menuType == "" then
		return false
	end
	if type(addonName) ~= "string" or addonName == "" then
		return false
	end

	local key = tag .. "\001" .. addonName .. "\001" .. tostring(callback)
	if self.dynamicModifierLookup[key] then
		return true
	end

	local entry = {
		key = key,
		tag = tag,
		menuType = menuType,
		callback = callback,
		addonName = addonName,
		addonTitle = SafeAddOnTitle(addonName) or addonName,
		source = source or "runtime",
		disabled = false,
		lastError = nil,
		replayCount = 0,
	}

	self.dynamicModifierLookup[key] = entry
	self.dynamicModifiersByTag[tag] = self.dynamicModifiersByTag[tag] or {}
	self.dynamicModifiersByTag[tag][#self.dynamicModifiersByTag[tag] + 1] = entry
	self.dynamicModifierOrder[#self.dynamicModifierOrder + 1] = entry
	return true
end

function MenuBridge:GetEarlyCaptureStore()
	local store = _G[EARLY_CAPTURE_GLOBAL]
	if type(store) == "table" then
		return store
	end
	return nil
end

function MenuBridge:ImportEarlyCaptures()
	local store = self:GetEarlyCaptureStore()
	if not store or type(store.captures) ~= "table" then
		return 0
	end

	local imported = 0
	local startIndex = (self.earlyCaptureScanIndex or 0) + 1
	for index = startIndex, #store.captures do
		local capture = store.captures[index]
		if type(capture) == "table" then
			if self:RegisterDynamicModifier(capture.tag, capture.callback, capture.addonName, "early") then
				imported = imported + 1
			end
		end
	end
	self.earlyCaptureScanIndex = #store.captures
	return imported
end

function MenuBridge:GetDynamicModifierCount()
	return #self.dynamicModifierOrder
end

function MenuBridge:WarmUpLazyModifiers(owner)
	if self.lazyWarmupDone then
		return false
	end
	if not self:IsEnabled() then
		return false
	end
	if BFL.IsActionRestricted and BFL:IsActionRestricted() then
		return false
	end
	if not (
		Menu
		and Menu.GetManager
		and MenuUtil
		and MenuUtil.CreateRootMenuDescription
		and MenuVariants
		and MenuVariants.GetDefaultContextMenuMixin
	) then
		return false
	end

	self.lazyWarmupAttempts = (self.lazyWarmupAttempts or 0) + 1
	self.lazyWarmupDone = true
	self.lazyWarmupLastError = nil
	self:InstallModifyMenuDiagnostic()
	self:ImportEarlyCaptures()
	local beforeCount = self:GetDynamicModifierCount()

	local ok, err = pcall(function()
		local manager = Menu.GetManager()
		if not (manager and manager.OpenContextMenu) then
			return
		end

		local warmupOwner = owner or UIParent
		local menuMixin = (warmupOwner and warmupOwner.menuMixin) or MenuVariants.GetDefaultContextMenuMixin()
		local description = MenuUtil.CreateRootMenuDescription(menuMixin)
		manager:OpenContextMenu(warmupOwner, description)
		if manager.CloseMenus then
			manager:CloseMenus()
		end
	end)

	self:ImportEarlyCaptures()
	self.lazyWarmupCaptured = math.max(0, self:GetDynamicModifierCount() - beforeCount)
	if not ok then
		self.lazyWarmupLastError = tostring(err)
	end
	return ok == true
end

function MenuBridge:DisableDynamicModifier(entry, errorValue)
	entry.disabled = true
	entry.lastError = tostring(errorValue or "unknown error")
end

function MenuBridge:HasDynamicModifierForAddon(menuTag, addonName)
	local entries = self.dynamicModifiersByTag[menuTag]
	if not entries then
		return false
	end
	for _, entry in ipairs(entries) do
		if not entry.disabled and SameAddOnName(entry.addonName, addonName) then
			return true
		end
	end
	return false
end

function MenuBridge:IsProviderEligible(provider, owner, safeContext)
	if provider.disabled then
		return false
	end
	if not provider.menuTypes[safeContext.menuType] then
		return false
	end
	if not provider.allowInCombat and BFL.IsActionRestricted and BFL:IsActionRestricted() then
		return false
	end
	if provider.fallbackIfDynamicModifier and provider.addonName and self:HasDynamicModifierForAddon(safeContext.menuTag, provider.addonName) then
		return false
	end
	if provider.canShow then
		local ok, result = pcall(provider.canShow, owner, safeContext)
		if not ok then
			self:DisableProvider(provider, result)
			return false
		end
		return result == true
	end
	return true
end

function MenuBridge:DisableProvider(provider, errorValue)
	provider.disabled = true
	provider.lastError = tostring(errorValue or "unknown error")
end

function MenuBridge:ReplayDynamicModifiers(owner, section, safeContext)
	local entries = self.dynamicModifiersByTag[safeContext.menuTag]
	if not entries then
		return false
	end
	if BFL.IsActionRestricted and BFL:IsActionRestricted() then
		return false
	end

	for _, entry in ipairs(entries) do
		if not entry.disabled then
			local ok, err = pcall(entry.callback, owner, section, safeContext)
			if ok then
				entry.replayCount = entry.replayCount + 1
			else
				self:DisableDynamicModifier(entry, err)
			end
		end
	end

	return section.created == true
end

function MenuBridge:PopulateMenu(owner, rootDescription, contextData, menuType)
	if not self:IsEnabled() then
		return false
	end
	if not (rootDescription and rootDescription.CreateButton and contextData and menuType) then
		return false
	end

	self:ImportEarlyCaptures()

	local safeContext = self:CreateSafeContext(contextData, menuType)
	if not safeContext.menuType then
		return false
	end

	local section = CreateExternalSection(rootDescription, safeContext)
	self:ReplayDynamicModifiers(owner, section, safeContext)

	for _, id in ipairs(self.providerOrder) do
		local provider = self.providers[id]
		if provider and self:IsProviderEligible(provider, owner, safeContext) then
			local ok, result = pcall(provider.populate, owner, section, safeContext)
			if not ok then
				self:DisableProvider(provider, result)
			elseif result == false and provider.required then
				provider.disabled = true
			end
		end
	end

	return section.created == true
end

function MenuBridge:RecordModifyMenuRegistration(tag, callback)
	if not BFL.HasSecretValues then
		return
	end
	if type(tag) ~= "string" then
		return
	end

	local menuType = NormalizeMenuType(tag)
	if not menuType or menuType == "" then
		return
	end

	local addonName = GetSourceAddonName()
	if not addonName then
		return
	end

	local record = self.detectedMenus[tag]
	if not record then
		record = {
			menuType = menuType,
			count = 0,
			addons = {},
		}
		self.detectedMenus[tag] = record
	end
	record.count = record.count + 1
	record.addons[addonName] = SafeAddOnTitle(addonName) or addonName

	self:RegisterDynamicModifier(tag, callback, addonName)
end

function MenuBridge:InstallModifyMenuDiagnostic()
	if self.modifyMenuDiagnosticInstalled then
		return
	end
	if not BFL.HasSecretValues then
		return
	end
	if not (hooksecurefunc and Menu and Menu.ModifyMenu) then
		return
	end

	local ok = pcall(hooksecurefunc, Menu, "ModifyMenu", function(tag, callback)
		MenuBridge:RecordModifyMenuRegistration(tag, callback)
	end)
	if ok then
		self.modifyMenuDiagnosticInstalled = true
	end
end

function MenuBridge:GetDynamicModifierDiagnostics()
	self:ImportEarlyCaptures()

	local diagnostics = {}
	for tag, entries in pairs(self.dynamicModifiersByTag) do
		local tagInfo = {
			count = 0,
			addons = {},
		}
		for _, entry in ipairs(entries) do
			tagInfo.count = tagInfo.count + 1
			tagInfo.addons[entry.addonName] = {
				title = entry.addonTitle,
				source = entry.source,
				disabled = entry.disabled == true,
				lastError = entry.lastError,
				replayCount = entry.replayCount,
			}
		end
		diagnostics[tag] = tagInfo
	end
	return diagnostics
end

function MenuBridge:GetEarlyCaptureDiagnostics()
	local store = self:GetEarlyCaptureStore()
	if not store then
		return {
			present = false,
			captureCount = 0,
			importedCount = self.earlyCaptureScanIndex or 0,
		}
	end

	return {
		present = true,
		addonName = store.addonName,
		version = store.version,
		hookInstalled = store.hookInstalled == true,
		installAttempts = store.installAttempts or 0,
		captureCount = type(store.captures) == "table" and #store.captures or 0,
		importedCount = self.earlyCaptureScanIndex or 0,
	}
end

function MenuBridge:GetLazyWarmupDiagnostics()
	return {
		done = self.lazyWarmupDone == true,
		attempts = self.lazyWarmupAttempts or 0,
		captured = self.lazyWarmupCaptured or 0,
		lastError = self.lazyWarmupLastError,
	}
end

function MenuBridge:Initialize()
	self:InstallModifyMenuDiagnostic()
	self:ImportEarlyCaptures()
end

function MenuBridge:GetDiagnostics()
	self:ImportEarlyCaptures()

	return {
		enabled = self:IsEnabled(),
		hookInstalled = self.modifyMenuDiagnosticInstalled == true,
		earlyCapture = self:GetEarlyCaptureDiagnostics(),
		lazyWarmup = self:GetLazyWarmupDiagnostics(),
		detectedMenus = self.detectedMenus,
		dynamicModifiers = self:GetDynamicModifierDiagnostics(),
	}
end

function MenuBridge:OnPlayerLogin()
	self:RefreshEnabledState()
end

BFL.RegisterExternalMenuProvider = function(selfOrProvider, provider)
	if provider == nil and selfOrProvider ~= BFL then
		provider = selfOrProvider
	end
	return MenuBridge:RegisterProvider(provider)
end

BFL.GetExternalMenuBridgeDiagnostics = function()
	return MenuBridge:GetDiagnostics()
end
