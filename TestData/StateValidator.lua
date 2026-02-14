-- TestData/StateValidator.lua
-- State Validation System for BetterFriendlist Testing
-- Version 1.0 - February 2026
--
-- Purpose:
-- Capture and compare addon state for regression detection.
-- Provides module-specific validators and snapshot comparisons.
--
-- Features:
-- - Take full addon state snapshots
-- - Compare snapshots to detect changes
-- - Module-specific validation rules
-- - Regression detection with detailed diffs
--
-- Usage:
--   /bfl test validate snapshot    - Take a snapshot
--   /bfl test validate compare     - Compare with previous
--   /bfl test validate module <n>  - Validate specific module
--   /bfl test validate all         - Run all validations

local ADDON_NAME, BFL = ...

-- Ensure TestData namespace exists
BFL.TestData = BFL.TestData or {}

-- Create StateValidator module
local StateValidator = {}
BFL.StateValidator = StateValidator

-- ============================================
-- CONSTANTS
-- ============================================

local SNAPSHOT_VERSION = 1
local MAX_SNAPSHOTS = 5

-- Modules to validate
StateValidator.VALIDATABLE_MODULES = {
	"DB",
	"Groups",
	"FriendsList",
	"PreviewMode",
	"Settings",
	"Statistics",
	"QuickFilters",
	"RaidFrame",
	"QuickJoin",
	"Broker",
	"StreamerMode",
}

-- ============================================
-- STATE
-- ============================================

-- Stored snapshots (circular buffer)
StateValidator.snapshots = {}
StateValidator.snapshotIndex = 0

-- Validation results
StateValidator.lastValidation = nil

-- ============================================
-- SNAPSHOT SYSTEM
-- ============================================

--[[
    Take a full state snapshot of the addon
    @param label string: Optional label for the snapshot
    @return table: Snapshot data
]]
function StateValidator:TakeSnapshot(label)
	local snapshot = {
		version = SNAPSHOT_VERSION,
		timestamp = GetTime(),
		realTime = time(),
		label = label or ("Snapshot " .. (self.snapshotIndex + 1)),
		modules = {},
		database = nil,
		ui = nil,
	}

	-- Capture each module's state
	for _, moduleName in ipairs(self.VALIDATABLE_MODULES) do
		local module = BFL:GetModule(moduleName)
		if module then
			snapshot.modules[moduleName] = self:CaptureModuleState(moduleName, module)
		end
	end

	-- Capture database state
	snapshot.database = self:CaptureDatabaseState()

	-- Capture UI state
	snapshot.ui = self:CaptureUIState()

	-- Store in circular buffer
	self.snapshotIndex = self.snapshotIndex + 1
	if self.snapshotIndex > MAX_SNAPSHOTS then
		self.snapshotIndex = 1
	end
	self.snapshots[self.snapshotIndex] = snapshot

	BFL:DebugPrint("|cff00ff00StateValidator:|r Snapshot taken: " .. snapshot.label)
	return snapshot
end

--[[
    Get a stored snapshot
    @param index number: Snapshot index (1 = most recent, 2 = previous, etc.)
    @return table or nil: Snapshot data
]]
function StateValidator:GetSnapshot(index)
	index = index or 1
	local actualIndex = self.snapshotIndex - index + 1
	if actualIndex < 1 then
		actualIndex = actualIndex + MAX_SNAPSHOTS
	end
	return self.snapshots[actualIndex]
end

--[[
    Capture state of a specific module
    @param moduleName string: Module name
    @param module table: Module reference
    @return table: Module state
]]
function StateValidator:CaptureModuleState(moduleName, module)
	local state = {
		name = moduleName,
		exists = module ~= nil,
	}

	if not module then
		return state
	end

	-- Module-specific capture logic
	if moduleName == "FriendsList" then
		state.friendCount = module.friendCount or 0
		state.onlineCount = module.onlineCount or 0
		state.isRefreshing = module.isRefreshing or false
		state.lastUpdate = module.lastUpdate or 0
		state.displayedFriends = module.displayedFriends and #module.displayedFriends or 0
	elseif moduleName == "Groups" then
		state.groupCount = 0
		if module.groups then
			for _ in pairs(module.groups) do
				state.groupCount = state.groupCount + 1
			end
		end
		state.expandedGroups = module.expandedGroups or {}
	elseif moduleName == "PreviewMode" then
		state.enabled = module.enabled or false
		state.mockFriendCount = module.mockData and module.mockData.friends and #module.mockData.friends or 0
	elseif moduleName == "Settings" then
		state.initialized = module.initialized or false
		state.currentTab = module.currentTab
	elseif moduleName == "Statistics" then
		state.dataPoints = module.data and self:CountTableEntries(module.data) or 0
	elseif moduleName == "QuickFilters" then
		state.activeFilter = module.activeFilter
		state.filterCount = module.filters and #module.filters or 0
	elseif moduleName == "RaidFrame" then
		state.visible = module.frame and module.frame:IsShown() or false
		state.memberCount = module.members and #module.members or 0
	elseif moduleName == "QuickJoin" then
		state.groupCount = module.groups and #module.groups or 0
		state.visible = module.frame and module.frame:IsShown() or false
	elseif moduleName == "Broker" then
		state.initialized = module.dataObject ~= nil
	elseif moduleName == "StreamerMode" then
		state.enabled = module.enabled or false
	elseif moduleName == "DB" then
		state.initialized = BetterFriendlistDB ~= nil
	end

	return state
end

--[[
    Capture database state
    @return table: Database snapshot
]]
function StateValidator:CaptureDatabaseState()
	if not BetterFriendlistDB then
		return { exists = false }
	end

	local db = BetterFriendlistDB

	return {
		exists = true,
		version = db.version,

		-- Settings counts
		groupCount = db.groups and self:CountTableEntries(db.groups) or 0,
		groupAssignmentCount = db.groupAssignments and self:CountTableEntries(db.groupAssignments) or 0,
		noteCount = db.friendNotes and self:CountTableEntries(db.friendNotes) or 0,

		-- Feature flags (just presence check)
		hasSettings = db.settings ~= nil,
		hasColumnWidths = db.columnWidths ~= nil,
		hasActivityData = db.activityData ~= nil,
		hasFavorites = db.favorites ~= nil,

		-- Test framework data
		testScenarioCount = db.testScenarios and self:CountTableEntries(db.testScenarios) or 0,
	}
end

--[[
    Capture UI state
    @return table: UI snapshot
]]
function StateValidator:CaptureUIState()
	local state = {
		mainFrameVisible = false,
		mainFrameWidth = 0,
		mainFrameHeight = 0,
		activeTab = nil,
		scrollPosition = 0,
	}

	-- Check main frame
	if BetterFriendsFrame then
		state.mainFrameVisible = BetterFriendsFrame:IsShown()
		state.mainFrameWidth = BetterFriendsFrame:GetWidth()
		state.mainFrameHeight = BetterFriendsFrame:GetHeight()
	end

	-- Check for scroll position if available
	local FriendsList = BFL:GetModule("FriendsList")
	if FriendsList and FriendsList.scrollFrame then
		local scroll = FriendsList.scrollFrame
		if scroll.GetVerticalScroll then
			state.scrollPosition = scroll:GetVerticalScroll()
		end
	end

	return state
end

-- ============================================
-- COMPARISON SYSTEM
-- ============================================

--[[
    Compare two snapshots and return differences
    @param snapshot1 table: First snapshot (older)
    @param snapshot2 table: Second snapshot (newer)
    @return table: Comparison result
]]
function StateValidator:CompareSnapshots(snapshot1, snapshot2)
	if not snapshot1 or not snapshot2 then
		return { error = "Missing snapshot(s)" }
	end

	local result = {
		snapshot1Label = snapshot1.label,
		snapshot2Label = snapshot2.label,
		timeDelta = snapshot2.timestamp - snapshot1.timestamp,
		differences = {},
		moduleChanges = {},
		databaseChanges = {},
		uiChanges = {},
		totalChanges = 0,
	}

	-- Compare modules
	for moduleName, newState in pairs(snapshot2.modules) do
		local oldState = snapshot1.modules[moduleName]
		local changes = self:CompareModuleStates(moduleName, oldState, newState)
		if changes and #changes > 0 then
			result.moduleChanges[moduleName] = changes
			result.totalChanges = result.totalChanges + #changes
		end
	end

	-- Compare database
	local dbChanges = self:CompareDatabaseStates(snapshot1.database, snapshot2.database)
	if dbChanges and #dbChanges > 0 then
		result.databaseChanges = dbChanges
		result.totalChanges = result.totalChanges + #dbChanges
	end

	-- Compare UI
	local uiChanges = self:CompareUIStates(snapshot1.ui, snapshot2.ui)
	if uiChanges and #uiChanges > 0 then
		result.uiChanges = uiChanges
		result.totalChanges = result.totalChanges + #uiChanges
	end

	return result
end

--[[
    Compare two module states
    @param moduleName string: Module name
    @param oldState table: Previous state
    @param newState table: Current state
    @return table: Array of changes
]]
function StateValidator:CompareModuleStates(moduleName, oldState, newState)
	local changes = {}

	if not oldState then
		table.insert(changes, { field = "module", old = "not present", new = "present" })
		return changes
	end

	if not newState then
		table.insert(changes, { field = "module", old = "present", new = "not present" })
		return changes
	end

	-- Compare each field
	for key, newValue in pairs(newState) do
		local oldValue = oldState[key]
		if key ~= "name" and self:ValuesAreDifferent(oldValue, newValue) then
			table.insert(changes, {
				field = key,
				old = self:FormatValue(oldValue),
				new = self:FormatValue(newValue),
			})
		end
	end

	return changes
end

--[[
    Compare database states
    @param oldDB table: Previous database state
    @param newDB table: Current database state
    @return table: Array of changes
]]
function StateValidator:CompareDatabaseStates(oldDB, newDB)
	local changes = {}

	if not oldDB or not newDB then
		return changes
	end

	local fieldsToCompare = {
		"groupCount",
		"groupAssignmentCount",
		"noteCount",
		"hasSettings",
		"hasColumnWidths",
		"hasActivityData",
		"hasFavorites",
		"testScenarioCount",
	}

	for _, field in ipairs(fieldsToCompare) do
		if self:ValuesAreDifferent(oldDB[field], newDB[field]) then
			table.insert(changes, {
				field = field,
				old = self:FormatValue(oldDB[field]),
				new = self:FormatValue(newDB[field]),
			})
		end
	end

	return changes
end

--[[
    Compare UI states
    @param oldUI table: Previous UI state
    @param newUI table: Current UI state
    @return table: Array of changes
]]
function StateValidator:CompareUIStates(oldUI, newUI)
	local changes = {}

	if not oldUI or not newUI then
		return changes
	end

	local fieldsToCompare = {
		"mainFrameVisible",
		"mainFrameWidth",
		"mainFrameHeight",
		"activeTab",
		"scrollPosition",
	}

	for _, field in ipairs(fieldsToCompare) do
		if self:ValuesAreDifferent(oldUI[field], newUI[field]) then
			table.insert(changes, {
				field = field,
				old = self:FormatValue(oldUI[field]),
				new = self:FormatValue(newUI[field]),
			})
		end
	end

	return changes
end

-- ============================================
-- MODULE VALIDATORS
-- ============================================

--[[
    Validate a specific module
    @param moduleName string: Module name
    @return table: Validation result {passed, errors, warnings}
]]
function StateValidator:ValidateModule(moduleName)
	local module = BFL:GetModule(moduleName)

	local result = {
		moduleName = moduleName,
		passed = true,
		errors = {},
		warnings = {},
	}

	if not module then
		result.passed = false
		table.insert(result.errors, "Module not found")
		return result
	end

	-- Run module-specific validation
	local validator = self.ModuleValidators[moduleName]
	if validator then
		validator(module, result)
	else
		-- Generic validation
		self:GenericModuleValidation(module, result)
	end

	result.passed = #result.errors == 0
	return result
end

--[[
    Generic validation for any module
    @param module table: Module reference
    @param result table: Result to populate
]]
function StateValidator:GenericModuleValidation(module, result)
	-- Check for common required methods
	if module.Initialize and type(module.Initialize) ~= "function" then
		table.insert(result.warnings, "Initialize is not a function")
	end
end

-- Module-specific validators
StateValidator.ModuleValidators = {}

StateValidator.ModuleValidators.FriendsList = function(module, result)
	-- Check required fields
	if module.friendCount == nil then
		table.insert(result.warnings, "friendCount not initialized")
	end

	-- Check friend data structure
	if module.displayedFriends then
		for i, friend in ipairs(module.displayedFriends) do
			if not friend.type then
				table.insert(result.errors, "Friend " .. i .. " missing 'type' field")
			end
			if friend.type == "bnet" and not friend.bnetIDAccount then
				table.insert(result.errors, "BNet friend " .. i .. " missing 'bnetIDAccount'")
			end
		end
	end

	-- Check for memory leaks (excessive friend count)
	if module.friendCount and module.friendCount > 1000 then
		table.insert(result.warnings, "Unusually high friend count: " .. module.friendCount)
	end
end

StateValidator.ModuleValidators.Groups = function(module, result)
	if not module.groups then
		table.insert(result.errors, "groups table not initialized")
		return
	end

	-- Validate each group
	for id, group in pairs(module.groups) do
		if not group.name then
			table.insert(result.errors, "Group " .. tostring(id) .. " missing 'name'")
		end
		if not group.id then
			table.insert(result.errors, "Group missing 'id' field")
		end
	end
end

StateValidator.ModuleValidators.PreviewMode = function(module, result)
	if module.enabled then
		-- When enabled, should have mock data
		if not module.mockData then
			table.insert(result.errors, "PreviewMode enabled but mockData is nil")
		elseif not module.mockData.friends then
			table.insert(result.warnings, "PreviewMode enabled but no mock friends")
		end
	end
end

StateValidator.ModuleValidators.DB = function(module, result)
	if not BetterFriendlistDB then
		table.insert(result.errors, "BetterFriendlistDB not initialized")
		return
	end

	local db = BetterFriendlistDB

	-- Check for corrupted data types
	if db.groups and type(db.groups) ~= "table" then
		table.insert(result.errors, "DB.groups is not a table")
	end

	if db.settings and type(db.settings) ~= "table" then
		table.insert(result.errors, "DB.settings is not a table")
	end

	if db.groupAssignments and type(db.groupAssignments) ~= "table" then
		table.insert(result.errors, "DB.groupAssignments is not a table")
	end
end

StateValidator.ModuleValidators.QuickFilters = function(module, result)
	if module.filters then
		for i, filter in ipairs(module.filters) do
			if not filter.id then
				table.insert(result.errors, "Filter " .. i .. " missing 'id'")
			end
			if not filter.name then
				table.insert(result.warnings, "Filter " .. i .. " missing 'name'")
			end
		end
	end
end

--[[
    Validate all modules
    @return table: Overall validation result
]]
function StateValidator:ValidateAll()
	local overallResult = {
		timestamp = time(),
		totalModules = 0,
		passedModules = 0,
		failedModules = 0,
		totalErrors = 0,
		totalWarnings = 0,
		moduleResults = {},
	}

	for _, moduleName in ipairs(self.VALIDATABLE_MODULES) do
		local result = self:ValidateModule(moduleName)
		overallResult.moduleResults[moduleName] = result
		overallResult.totalModules = overallResult.totalModules + 1

		if result.passed then
			overallResult.passedModules = overallResult.passedModules + 1
		else
			overallResult.failedModules = overallResult.failedModules + 1
		end

		overallResult.totalErrors = overallResult.totalErrors + #result.errors
		overallResult.totalWarnings = overallResult.totalWarnings + #result.warnings
	end

	self.lastValidation = overallResult
	return overallResult
end

-- ============================================
-- REGRESSION DETECTION
-- ============================================

--[[
    Check for potential regressions between snapshots
    @param snapshot1 table: Before snapshot
    @param snapshot2 table: After snapshot
    @return table: Regression report
]]
function StateValidator:DetectRegressions(snapshot1, snapshot2)
	local report = {
		potentialRegressions = {},
		positiveChanges = {},
		neutralChanges = {},
	}

	local comparison = self:CompareSnapshots(snapshot1, snapshot2)

	-- Analyze module changes for regressions
	for moduleName, changes in pairs(comparison.moduleChanges) do
		for _, change in ipairs(changes) do
			local regression = self:ClassifyChange(moduleName, change)
			if regression == "regression" then
				table.insert(report.potentialRegressions, {
					module = moduleName,
					change = change,
				})
			elseif regression == "positive" then
				table.insert(report.positiveChanges, {
					module = moduleName,
					change = change,
				})
			else
				table.insert(report.neutralChanges, {
					module = moduleName,
					change = change,
				})
			end
		end
	end

	return report
end

--[[
    Classify a change as regression, positive, or neutral
    @param moduleName string: Module name
    @param change table: Change details
    @return string: "regression", "positive", or "neutral"
]]
function StateValidator:ClassifyChange(moduleName, change)
	local field = change.field
	local oldVal = change.old
	local newVal = change.new

	-- Convert to numbers for comparison if applicable
	local oldNum = tonumber(oldVal)
	local newNum = tonumber(newVal)

	-- Regression indicators
	-- Counts going to 0 might be regression
	if newNum == 0 and oldNum and oldNum > 0 then
		if field:match("Count$") or field:match("count$") then
			return "regression"
		end
	end

	-- Module becoming non-existent
	if field == "exists" and newVal == "false" then
		return "regression"
	end

	-- Preview mode unexpectedly disabling
	if moduleName == "PreviewMode" and field == "enabled" then
		if oldVal == "true" and newVal == "false" then
			return "neutral" -- Intentional
		end
	end

	-- Positive indicators
	-- Increasing counts (more features loaded)
	if newNum and oldNum and newNum > oldNum then
		if field:match("Count$") or field:match("count$") then
			return "positive"
		end
	end

	return "neutral"
end

-- ============================================
-- UTILITY FUNCTIONS
-- ============================================

--[[
    Count entries in a table
    @param tbl table: Table to count
    @return number: Entry count
]]
function StateValidator:CountTableEntries(tbl)
	if not tbl then
		return 0
	end

	local count = 0
	for _ in pairs(tbl) do
		count = count + 1
	end
	return count
end

--[[
    Check if two values are different
    @param val1: First value
    @param val2: Second value
    @return boolean: Are different
]]
function StateValidator:ValuesAreDifferent(val1, val2)
	local type1 = type(val1)
	local type2 = type(val2)

	if type1 ~= type2 then
		return true
	end

	if type1 == "table" then
		-- Simple shallow comparison
		return self:CountTableEntries(val1) ~= self:CountTableEntries(val2)
	end

	return val1 ~= val2
end

--[[
    Format a value for display
    @param val: Value to format
    @return string: Formatted value
]]
function StateValidator:FormatValue(val)
	if val == nil then
		return "nil"
	elseif type(val) == "boolean" then
		return val and "true" or "false"
	elseif type(val) == "table" then
		return "table(" .. self:CountTableEntries(val) .. ")"
	else
		return tostring(val)
	end
end

-- ============================================
-- REPORTING
-- ============================================

--[[
    Print snapshot info
    @param snapshot table: Snapshot to print
]]
function StateValidator:PrintSnapshot(snapshot)
	if not snapshot then
		print("|cffff0000No snapshot available|r")
		return
	end

	print("|cff00ff00=== Snapshot: " .. snapshot.label .. " ===|r")
	print("  Time: " .. date("%Y-%m-%d %H:%M:%S", snapshot.realTime))
	print("")

	print("|cffffd200Modules:|r")
	for moduleName, state in pairs(snapshot.modules) do
		local status = state.exists and "|cff00ff00[+]|r" or "|cffff0000[x]|r"
		local details = {}

		for key, value in pairs(state) do
			if key ~= "name" and key ~= "exists" then
				table.insert(details, key .. "=" .. self:FormatValue(value))
			end
		end

		print(string.format("  %s %s: %s", status, moduleName, table.concat(details, ", ")))
	end
	print("")

	print("|cffffd200Database:|r")
	if snapshot.database then
		print("  Groups: " .. (snapshot.database.groupCount or 0))
		print("  Assignments: " .. (snapshot.database.groupAssignmentCount or 0))
		print("  Notes: " .. (snapshot.database.noteCount or 0))
	end
	print("")

	print("|cffffd200UI:|r")
	if snapshot.ui then
		print("  Frame Visible: " .. (snapshot.ui.mainFrameVisible and "Yes" or "No"))
		print(
			"  Frame Size: " .. math.floor(snapshot.ui.mainFrameWidth) .. "x" .. math.floor(snapshot.ui.mainFrameHeight)
		)
	end
end

--[[
    Print comparison result
    @param comparison table: Comparison result
]]
function StateValidator:PrintComparison(comparison)
	if comparison.error then
		print("|cffff0000Error:|r " .. comparison.error)
		return
	end

	print("|cff00ff00=== Comparison ===|r")
	print("  From: " .. comparison.snapshot1Label)
	print("  To:   " .. comparison.snapshot2Label)
	print("  Time Delta: " .. string.format("%.2f", comparison.timeDelta) .. " seconds")
	print("  Total Changes: " .. comparison.totalChanges)
	print("")

	if comparison.totalChanges == 0 then
		print("|cff888888No changes detected.|r")
		return
	end

	-- Module changes
	for moduleName, changes in pairs(comparison.moduleChanges) do
		print("|cffffd200" .. moduleName .. ":|r")
		for _, change in ipairs(changes) do
			print(string.format("  * %s: %s -> %s", change.field, change.old, change.new))
		end
	end

	-- Database changes
	if #comparison.databaseChanges > 0 then
		print("|cffffd200Database:|r")
		for _, change in ipairs(comparison.databaseChanges) do
			print(string.format("  * %s: %s -> %s", change.field, change.old, change.new))
		end
	end

	-- UI changes
	if #comparison.uiChanges > 0 then
		print("|cffffd200UI:|r")
		for _, change in ipairs(comparison.uiChanges) do
			print(string.format("  * %s: %s -> %s", change.field, change.old, change.new))
		end
	end
end

--[[
    Print validation result
    @param result table: Validation result (single module or overall)
]]
function StateValidator:PrintValidation(result)
	-- Check if it's overall result or single module
	if result.moduleResults then
		-- Overall result
		print("|cff00ff00=== Validation Summary ===|r")
		print(
			string.format(
				"  Modules: %d passed, %d failed (of %d)",
				result.passedModules,
				result.failedModules,
				result.totalModules
			)
		)
		print(string.format("  Issues: %d errors, %d warnings", result.totalErrors, result.totalWarnings))
		print("")

		-- List failed modules
		for moduleName, modResult in pairs(result.moduleResults) do
			if not modResult.passed or #modResult.warnings > 0 then
				local status = modResult.passed and "|cffffff00[!]|r" or "|cffff0000[x]|r"
				print(status .. " " .. moduleName)

				for _, err in ipairs(modResult.errors) do
					print("    |cffff0000ERROR:|r " .. err)
				end
				for _, warn in ipairs(modResult.warnings) do
					print("    |cffffff00WARN:|r " .. warn)
				end
			end
		end
	else
		-- Single module result
		local status = result.passed and "|cff00ff00PASS|r" or "|cffff0000FAIL|r"
		print("Module: " .. result.moduleName .. " - " .. status)

		if #result.errors > 0 then
			for _, err in ipairs(result.errors) do
				print("  |cffff0000ERROR:|r " .. err)
			end
		end

		if #result.warnings > 0 then
			for _, warn in ipairs(result.warnings) do
				print("  |cffffff00WARN:|r " .. warn)
			end
		end
	end
end

--[[
    Print regression report
    @param report table: Regression report
]]
function StateValidator:PrintRegressionReport(report)
	print("|cff00ff00=== Regression Analysis ===|r")

	if #report.potentialRegressions > 0 then
		print("|cffff0000Potential Regressions:|r")
		for _, item in ipairs(report.potentialRegressions) do
			print(
				string.format("  * [%s] %s: %s -> %s", item.module, item.change.field, item.change.old, item.change.new)
			)
		end
	else
		print("|cff00ff00No potential regressions detected.|r")
	end

	if #report.positiveChanges > 0 then
		print("")
		print("|cff00ff00Positive Changes:|r")
		for _, item in ipairs(report.positiveChanges) do
			print(
				string.format("  * [%s] %s: %s -> %s", item.module, item.change.field, item.change.old, item.change.new)
			)
		end
	end
end

-- ============================================
-- STATUS
-- ============================================

--[[
    Get current status
    @return table: Status info
]]
function StateValidator:GetStatus()
	return {
		snapshotCount = #self.snapshots,
		currentIndex = self.snapshotIndex,
		lastValidation = self.lastValidation and self.lastValidation.timestamp or nil,
	}
end

--[[
    Print status
]]
function StateValidator:PrintStatus()
	local status = self:GetStatus()

	print("|cff00ff00BFL StateValidator Status:|r")
	print("  Snapshots: " .. status.snapshotCount .. "/" .. MAX_SNAPSHOTS)
	print("  Current Index: " .. status.currentIndex)

	if status.lastValidation then
		print("  Last Validation: " .. date("%H:%M:%S", status.lastValidation))
	end

	-- List snapshots
	if status.snapshotCount > 0 then
		print("")
		print("|cffffd200Stored Snapshots:|r")
		for i = 1, status.snapshotCount do
			local snapshot = self.snapshots[i]
			if snapshot then
				local marker = i == self.snapshotIndex and " (current)" or ""
				print(
					string.format("  %d. %s [%.1fs ago]%s", i, snapshot.label, GetTime() - snapshot.timestamp, marker)
				)
			end
		end
	end
end

--[[
    Reset all state
]]
function StateValidator:Reset()
	wipe(self.snapshots)
	self.snapshotIndex = 0
	self.lastValidation = nil
	BFL:DebugPrint("|cff00ff00StateValidator:|r Reset complete")
end

return StateValidator
