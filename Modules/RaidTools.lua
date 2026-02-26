-- Modules/RaidTools.lua
-- Raid Tools: Sort, Split, and Utility functions for raid management

local ADDON_NAME, BFL = ...
local RaidTools = BFL:RegisterModule("RaidTools", {})

local L

-- Frame reference (lazy-init)
local toolsFrame = nil

-- Processing state
local processing = false
local processStart = 0
local targetUnits = nil
local processTimer = nil
local stepCount = 0
local totalTargetPlayers = 0
local progressHigh = 0

-- Reorder phase state
local PHASE_GROUPS = 1 -- Move players to correct groups
local PHASE_EVACUATE = 2 -- Evacuate a group for within-group reordering
local PHASE_REFILL = 3 -- Refill group in target order
local sortPhase = PHASE_GROUPS
local reorderGroup = 0 -- group currently being reordered
local tempGroup = 0 -- temp group for evacuation
local refillOrder = {} -- names in target order for refill
local refillIdx = 1 -- current index in refillOrder
local reorderedGroups = {} -- set of groups already reordered

-- Constants
local SORT_TIMEOUT = 15
local MAX_STEPS = 120
local DROP_THRESHOLD = 5 -- Auto-cancel if this many players leave
local DROP_WINDOW = 2 -- within this many seconds

-- Disbanding detection state
local lastDropTime = 0
local dropCount = 0
local lastRaidSize = 0

-- Combat pause/resume state
local paused = false
local pausedSortMode = nil -- "sort", "split", "splitOdds"

-- Spec detection state (session-only cache)
local specCache = {} -- { ["Player-Realm"] = specID }
local inspectQueue = {} -- array of unit names to inspect
local inspectInProgress = nil -- name currently being inspected
local INSPECT_INTERVAL = 1.5 -- seconds between inspections

-- Meter snapshot state
local meterSnapshot = {} -- { ["Player-Realm"] = totalAmount }
local meterAvgDamage = 0 -- average for DPS without data
local meterAvgHealing = 0 -- average for healers without data

-- Ambiguous classes: may be melee or ranged depending on spec
local AMBIGUOUS_CLASSES = {
	[2] = true, -- Paladin
	[3] = true, -- Hunter
	[5] = true, -- Priest (Disc/Holy ranged, Shadow ranged - but confirm)
	[6] = true, -- Death Knight
	[7] = true, -- Shaman
	[10] = true, -- Monk
	[11] = true, -- Druid
	[13] = true, -- Evoker
}

-- Max groups for sort based on difficulty
local GROUP_LIMIT_MYTHIC = 4
local GROUP_LIMIT_FLEX = 6

-- ============================================================================
-- Spec Priority Tables (inspired by NSRT)
-- ============================================================================

-- Melee specs (includes melee healers for split positioning)
local MELEE_SPECS = {
	[263] = true, -- Shaman: Enhancement
	[255] = true, -- Hunter: Survival
	[259] = true, -- Rogue: Assassination
	[260] = true, -- Rogue: Outlaw
	[261] = true, -- Rogue: Subtlety
	[71] = true, -- Warrior: Arms
	[72] = true, -- Warrior: Fury
	[251] = true, -- Death Knight: Frost
	[252] = true, -- Death Knight: Unholy
	[103] = true, -- Druid: Feral
	[70] = true, -- Paladin: Retribution
	[269] = true, -- Monk: Windwalker
	[577] = true, -- Demon Hunter: Havoc
	[65] = true, -- Paladin: Holy (melee healer)
	[270] = true, -- Monk: Mistweaver (melee healer)
}

-- Map specID to its natural role (for role vs spec mismatch detection)
local SPEC_ROLE = {
	-- Tanks
	[268] = "TANK",
	[66] = "TANK",
	[104] = "TANK",
	[73] = "TANK",
	[581] = "TANK",
	[250] = "TANK",
	-- Healers
	[65] = "HEALER",
	[270] = "HEALER",
	[1468] = "HEALER",
	[105] = "HEALER",
	[264] = "HEALER",
	[256] = "HEALER",
	[257] = "HEALER",
}

-- Spec sort priority (lower = sorted first)
-- Tanks 1-6, Melee 7-19, Ranged 20-33, Healers 34-40
local SPEC_PRIORITY = {
	[0] = 100, -- Unknown/offline

	-- Tanks
	[268] = 1, -- Brewmaster
	[66] = 2, -- Prot Pally
	[104] = 3, -- Guardian Druid
	[73] = 4, -- Prot Warrior
	[581] = 5, -- Veng DH
	[250] = 6, -- Blood DK

	-- Melee DPS
	[263] = 7, -- Enhancement Shaman
	[255] = 8, -- Survival Hunter
	[251] = 9, -- Frost DK
	[252] = 10, -- Unholy DK
	[259] = 11, -- Assassination Rogue
	[260] = 12, -- Outlaw Rogue
	[261] = 13, -- Subtlety Rogue
	[71] = 14, -- Arms Warrior
	[72] = 15, -- Fury Warrior
	[103] = 16, -- Feral Druid
	[70] = 17, -- Retribution Paladin
	[269] = 18, -- Windwalker Monk
	[577] = 19, -- Havoc DH

	-- Ranged DPS
	[1480] = 20, -- Devourer DH
	[1473] = 21, -- Augmentation Evoker
	[1467] = 22, -- Devastation Evoker
	[262] = 23, -- Elemental Shaman
	[258] = 24, -- Shadow Priest
	[102] = 25, -- Balance Druid
	[265] = 26, -- Affliction Warlock
	[266] = 27, -- Demonology Warlock
	[267] = 28, -- Destruction Warlock
	[64] = 29, -- Frost Mage
	[62] = 30, -- Arcane Mage
	[63] = 31, -- Fire Mage
	[253] = 32, -- Beast Mastery Hunter
	[254] = 33, -- Marksmanship Hunter

	-- Healers
	[65] = 34, -- Holy Paladin
	[270] = 35, -- Mistweaver Monk
	[1468] = 36, -- Preservation Evoker
	[105] = 37, -- Restoration Druid
	[264] = 38, -- Restoration Shaman
	[256] = 39, -- Discipline Priest
	[257] = 40, -- Holy Priest
}

-- Role-based priority fallback (when spec is unknown)
local ROLE_PRIORITY = {
	TANK = 3, -- After tanks
	MELEE = 12, -- Middle of melee DPS range
	RANGED = 27, -- Middle of ranged DPS range
	DAMAGER = 15, -- Generic DPS fallback
	HEALER = 37, -- Middle of healers
	NONE = 50, -- Unknown role
}

-- THMR mode: Tanks > Healers > Melee > Ranged
local ROLE_PRIORITY_THMR = {
	TANK = 3,
	HEALER = 10,
	MELEE = 20, -- Middle of melee range
	RANGED = 34, -- Middle of ranged range
	DAMAGER = 25, -- Generic DPS fallback
	NONE = 50,
}

-- THMR spec priority: Tanks(1-6) > Healers(7-13) > Melee(14-26) > Ranged(27-40)
local SPEC_PRIORITY_THMR = {
	[0] = 100,

	-- Tanks (same as TMRH)
	[268] = 1,
	[66] = 2,
	[104] = 3,
	[73] = 4,
	[581] = 5,
	[250] = 6,

	-- Healers (moved up)
	[65] = 7,
	[270] = 8,
	[1468] = 9,
	[105] = 10,
	[264] = 11,
	[256] = 12,
	[257] = 13,

	-- Melee DPS
	[263] = 14,
	[255] = 15,
	[251] = 16,
	[252] = 17,
	[259] = 18,
	[260] = 19,
	[261] = 20,
	[71] = 21,
	[72] = 22,
	[103] = 23,
	[70] = 24,
	[269] = 25,
	[577] = 26,

	-- Ranged DPS
	[1480] = 27,
	[1473] = 28,
	[1467] = 29,
	[262] = 30,
	[258] = 31,
	[102] = 32,
	[265] = 33,
	[266] = 34,
	[267] = 35,
	[64] = 36,
	[62] = 37,
	[63] = 38,
	[253] = 39,
	[254] = 40,
}

-- Classes that can provide Bloodlust/Heroism (by classID)
local LUST_CLASSES = {
	[3] = true, -- Hunter
	[7] = true, -- Shaman
	[8] = true, -- Mage
	[13] = true, -- Evoker
}

-- Classes that can provide Battle Resurrection (by classID)
local BRES_CLASSES = {
	[2] = true, -- Paladin
	[6] = true, -- Death Knight
	[9] = true, -- Warlock
	[11] = true, -- Druid
}

-- Pure melee classes (always melee regardless of spec)
local PURE_MELEE_CLASSES = {
	[4] = true, -- Rogue
	[1] = true, -- Warrior
	[12] = true, -- Demon Hunter (Havoc/Vengeance both melee; Devourer is ranged but rare)
}

-- Pure ranged classes (always ranged regardless of spec)
local PURE_RANGED_CLASSES = {
	[8] = true, -- Mage
	[9] = true, -- Warlock
}

-- ============================================================================
-- Position categories for split balancing
-- ============================================================================
local POS_MELEE_DPS = 1
local POS_MELEE_HEALER = 2
local POS_RANGED_DPS = 3
local POS_RANGED_HEALER = 4
local POS_TANK = 5

-- ============================================================================
-- Module Lifecycle
-- ============================================================================

function RaidTools:Initialize()
	L = BFL.L

	-- Pause or abort sort when entering combat
	BFL:RegisterEventCallback("PLAYER_REGEN_DISABLED", function()
		if processing then
			local DB = BFL:GetModule("DB")
			local resumeEnabled = DB and DB:Get("raidToolsResumeAfterCombat", true) or false
			if resumeEnabled and pausedSortMode then
				-- Pause: save mode and stop, will resume after combat
				paused = true
				BFL:DebugPrint("RaidTools: Pausing sort due to combat (will resume)")
				StopProcessing(L.RAID_TOOLS_STATUS_PAUSED_COMBAT or "Paused - in combat")
			else
				-- Hard abort
				paused = false
				pausedSortMode = nil
				BFL:DebugPrint("RaidTools: Aborting sort due to combat")
				StopProcessing(L.RAID_TOOLS_STATUS_ABORTED_COMBAT or "Aborted - entered combat")
			end
		end
	end, 10)

	-- Resume sort after combat ends
	BFL:RegisterEventCallback("PLAYER_REGEN_ENABLED", function()
		if paused and pausedSortMode then
			local DB = BFL:GetModule("DB")
			local resumeEnabled = DB and DB:Get("raidToolsResumeAfterCombat", true) or false
			if resumeEnabled and not InCombatLockdown() then
				local mode = pausedSortMode
				paused = false
				pausedSortMode = nil
				BFL:DebugPrint("RaidTools: Resuming " .. mode .. " after combat")
				RaidTools:UpdateStatusText(L.RAID_TOOLS_STATUS_RESUMING or "Resuming...")
				-- Re-run from scratch (idempotent: already-correct positions skipped)
				C_Timer.After(0.5, function()
					if mode == "sort" then
						RaidTools:SortByRole()
					elseif mode == "split" then
						RaidTools:SplitGroups(false)
					elseif mode == "splitOdds" then
						RaidTools:SplitGroups(true)
					end
				end)
			else
				paused = false
				pausedSortMode = nil
			end
		end
	end, 10)

	-- Spec detection via inspection (only available when GetInspectSpecialization exists)
	if GetInspectSpecialization then
		BFL:RegisterEventCallback("INSPECT_READY", function(_, guid)
			if not guid then
				return
			end
			-- Find the unit matching this GUID
			local unitName = inspectInProgress
			if unitName then
				for i = 1, MAX_RAID_MEMBERS do
					local name = GetRaidRosterInfo(i)
					if name == unitName then
						local unit = "raid" .. i
						if UnitGUID(unit) == guid then
							local specID = GetInspectSpecialization(unit)
							if specID and specID > 0 then
								specCache[unitName] = specID
								BFL:DebugPrint("RaidTools: Cached spec " .. specID .. " for " .. unitName)
							end
						end
						break
					end
				end
			end
			inspectInProgress = nil
			-- Continue queue processing
			if #inspectQueue > 0 then
				RaidTools:ProcessInspectQueue()
			end
		end, 50)
	end
end

-- ============================================================================
-- Spec Inspection System
-- ============================================================================

function RaidTools:BuildInspectQueue()
	if not GetInspectSpecialization then
		return
	end

	inspectQueue = {}
	if not IsInRaid() then
		return
	end

	for i = 1, MAX_RAID_MEMBERS do
		local name = GetRaidRosterInfo(i)
		if not name then
			break
		end

		local unit = "raid" .. i
		if not UnitExists(unit) then
			break
		end

		local _, _, classID = UnitClass(unit)

		-- Skip self (detected via GetSpecialization), already cached, pure classes, disconnected
		if
			not UnitIsUnit(unit, "player")
			and not specCache[name]
			and classID
			and AMBIGUOUS_CLASSES[classID]
			and UnitIsConnected(unit)
		then
			table.insert(inspectQueue, name)
		end
	end
end

function RaidTools:ProcessInspectQueue()
	if not GetInspectSpecialization then
		return
	end
	if InCombatLockdown() then
		return
	end
	if #inspectQueue == 0 then
		inspectInProgress = nil
		return
	end

	-- Pop next from queue
	local targetName = table.remove(inspectQueue, 1)

	-- Find the unit
	for i = 1, MAX_RAID_MEMBERS do
		local name = GetRaidRosterInfo(i)
		if name == targetName then
			local unit = "raid" .. i
			if UnitIsConnected(unit) and CanInspect(unit) then
				inspectInProgress = targetName
				NotifyInspect(unit)
				-- Schedule next inspection after interval
				self.inspectTimer = C_Timer.NewTimer(INSPECT_INTERVAL, function()
					self.inspectTimer = nil
					-- If no INSPECT_READY came, skip and continue
					if inspectInProgress then
						inspectInProgress = nil
					end
					if #inspectQueue > 0 then
						RaidTools:ProcessInspectQueue()
					end
				end)
				return
			end
			break
		end
	end

	-- Unit not found or can't inspect, try next
	if #inspectQueue > 0 then
		self:ProcessInspectQueue()
	end
end

function RaidTools:StopInspecting()
	inspectInProgress = nil
	inspectQueue = {}
	if self.inspectTimer then
		self.inspectTimer:Cancel()
		self.inspectTimer = nil
	end
end

-- ============================================================================
-- Meter Data Collection (C_DamageMeter primary, Details! fallback)
-- ============================================================================

-- Build short-name to full-name lookup for cross-realm matching
local function BuildShortNameLookup()
	local lookup = {}
	for i = 1, MAX_RAID_MEMBERS do
		local name = GetRaidRosterInfo(i)
		if not name then
			break
		end
		-- Strip realm: "Player-Realm" -> "Player"
		local shortName = name:match("^([^%-]+)")
		if shortName then
			lookup[shortName] = name
		end
	end
	return lookup
end

local function GetBlizzardMeterSnapshot()
	if not C_DamageMeter or not C_DamageMeter.IsDamageMeterAvailable then
		return false
	end
	if not C_DamageMeter.IsDamageMeterAvailable() then
		return false
	end

	-- Session types: 0=Overall, 1=Current, 2=Expired
	-- Meter types: 0=DamageDone, 2=HealingDone
	local damageSession = C_DamageMeter.GetCombatSessionFromType(0, 0)
	local healingSession = C_DamageMeter.GetCombatSessionFromType(0, 2)
	if not damageSession and not healingSession then
		return false
	end

	local shortNameLookup = BuildShortNameLookup()
	local found = false

	if damageSession and damageSession.combatSources then
		for _, source in ipairs(damageSession.combatSources) do
			local rosterName = shortNameLookup[source.name] or source.name
			found = true
			meterSnapshot[rosterName] = (meterSnapshot[rosterName] or 0) + (source.totalAmount or 0)
		end
	end

	if healingSession and healingSession.combatSources then
		for _, source in ipairs(healingSession.combatSources) do
			local rosterName = shortNameLookup[source.name] or source.name
			found = true
			meterSnapshot[rosterName] = (meterSnapshot[rosterName] or 0) + (source.totalAmount or 0)
		end
	end

	return found
end

local DETAILS_SEGMENTS = { "overall", "current" }

local function GetDetailsMeterSnapshot()
	if not Details or not Details.GetActor then
		return false
	end

	local found = false
	for _, segment in ipairs(DETAILS_SEGMENTS) do
		-- Check if this segment has any data
		if Details:GetActor(segment, 1) or Details:GetActor(segment, 2) then
			found = true
			for i = 1, MAX_RAID_MEMBERS do
				local name = GetRaidRosterInfo(i)
				if not name then
					break
				end
				local damage = Details:GetActor(segment, 1, name)
				local healing = Details:GetActor(segment, 2, name)
				meterSnapshot[name] = (damage and damage.total or 0) + (healing and healing.total or 0)
			end
			break -- Use first segment that has data
		end
	end

	return found
end

local function CalculateMeterAverages(units)
	local countDamage, totalDamage = 0, 0
	local countHealing, totalHealing = 0, 0

	for _, unit in ipairs(units) do
		local amount = meterSnapshot[unit.name]
		if amount and amount > 0 then
			if unit.role == "HEALER" then
				countHealing = countHealing + 1
				totalHealing = totalHealing + amount
			elseif unit.role == "DAMAGER" then
				countDamage = countDamage + 1
				totalDamage = totalDamage + amount
			end
		end
	end

	meterAvgDamage = (countDamage > 0) and (totalDamage / countDamage) or 0
	meterAvgHealing = (countHealing > 0) and (totalHealing / countHealing) or 0
end

function RaidTools:BuildMeterSnapshot(units)
	wipe(meterSnapshot)
	meterAvgDamage = 0
	meterAvgHealing = 0

	local source = nil

	-- Try C_DamageMeter first (Midnight/12.0+)
	if GetBlizzardMeterSnapshot() then
		source = "Blizzard Damage Meter"
	elseif GetDetailsMeterSnapshot() then
		source = "Details!"
	end

	if source then
		CalculateMeterAverages(units)
		BFL:DebugPrint("RaidTools: Meter snapshot from " .. source .. " (" .. self:CountMeterEntries() .. " entries)")
	else
		BFL:DebugPrint("RaidTools: No meter data available")
	end

	return source ~= nil
end

function RaidTools:CountMeterEntries()
	local count = 0
	for _ in pairs(meterSnapshot) do
		count = count + 1
	end
	return count
end

function RaidTools:HasMeterAddon()
	-- Check if any supported meter source exists
	if C_DamageMeter then
		return true
	end
	if _G.Details then
		return true
	end
	return false
end

local function GetPlayerMeter(name, role)
	local amount = meterSnapshot[name]
	if amount and amount > 0 then
		return amount
	end
	-- Fallback to average for role
	if role == "HEALER" then
		return meterAvgHealing
	end
	return meterAvgDamage
end

-- ============================================================================
-- Data Collection
-- ============================================================================

local function GetMaxGroupForDifficulty()
	if not IsInInstance() then
		return GROUP_LIMIT_FLEX
	end
	local difficultyID = select(3, GetInstanceInfo()) or 0
	if difficultyID == 16 then -- Mythic
		return GROUP_LIMIT_MYTHIC
	end
	return GROUP_LIMIT_FLEX
end

local function DeterminePosition(role, classID, isMelee)
	if role == "TANK" then
		return POS_TANK
	elseif role == "HEALER" then
		return isMelee and POS_MELEE_HEALER or POS_RANGED_HEALER
	else
		return isMelee and POS_MELEE_DPS or POS_RANGED_DPS
	end
end

local function IsMeleeClass(classID, role, name)
	if PURE_MELEE_CLASSES[classID] then
		return true
	end
	if PURE_RANGED_CLASSES[classID] then
		return false
	end

	-- Check spec cache first (most accurate)
	if name and specCache[name] then
		local specID = specCache[name]
		if MELEE_SPECS[specID] then
			return true
		end
		-- Known spec but not melee -> ranged
		return false
	end

	-- Hybrid classes: use role + class heuristic as fallback
	-- Hunters are generally ranged (Survival is the exception but we can't detect without spec)
	if classID == 3 then
		return false
	end -- Hunter -> default ranged
	-- Priests are always ranged
	if classID == 5 then
		return false
	end -- Priest -> always ranged

	-- For hybrid melee/ranged classes, tanks are melee
	if role == "TANK" then
		return true
	end

	-- Paladin: Ret/Prot melee, Holy ranged-ish but treated as melee healer
	if classID == 2 then
		return true
	end -- Paladin -> default melee
	-- DK: always melee
	if classID == 6 then
		return true
	end -- DK -> always melee
	-- Monk: WW/BM melee, MW ranged-ish but treated as melee healer
	if classID == 10 then
		return true
	end -- Monk -> default melee
	-- Druid: depends on spec, default ranged for DPS (Balance more common than Feral)
	if classID == 11 then
		return role == "TANK"
	end -- Druid DPS -> default ranged
	-- Shaman: Enhance melee, Ele/Resto ranged
	if classID == 7 then
		return false
	end -- Shaman DPS -> default ranged
	-- Evoker: all ranged
	if classID == 13 then
		return false
	end -- Evoker -> always ranged

	return false
end

-- Build list of non-preserved groups up to maxGroup
local function BuildAvailableGroups(maxGroup, preserveGroups)
	local available = {}
	for g = 1, maxGroup do
		if not preserveGroups[g] then
			table.insert(available, g)
		end
	end
	return available
end

-- Remap slot-indexed results from virtual groups (1,2,3...) to actual available groups
local function RemapSlots(slotted, availableGroups)
	local remapped = {}
	for slot, unit in pairs(slotted) do
		local virtualGroup = math.ceil(slot / 5)
		local posInGroup = ((slot - 1) % 5) + 1
		local actualGroup = availableGroups[virtualGroup]
		if actualGroup then
			remapped[(actualGroup - 1) * 5 + posInGroup] = unit
		end
	end
	return remapped
end

function RaidTools:CollectRosterData(maxGroup, preserveGroups)
	local units = {}
	local total = { ALL = 0, TANK = 0, HEALER = 0, DAMAGER = 0 }
	local posCount = { 0, 0, 0, 0, 0 }
	preserveGroups = preserveGroups or {}

	for i = 1, MAX_RAID_MEMBERS do
		local name, _, subgroup = GetRaidRosterInfo(i)
		if not name then
			break
		end

		local unit = "raid" .. i
		if not UnitExists(unit) then
			break
		end

		local _, _, classID = UnitClass(unit)

		-- Skip players in preserved groups or beyond max group
		if not preserveGroups[subgroup] and subgroup <= maxGroup then
			local role = UnitGroupRolesAssigned(unit)
			if role == "NONE" then
				role = "DAMAGER"
			end

			-- Detect own spec if possible (more reliable than inspect)
			if UnitIsUnit(unit, "player") and GetSpecialization then
				local specIndex = GetSpecialization()
				if specIndex and GetSpecializationInfo then
					local specID = GetSpecializationInfo(specIndex)
					if specID then
						specCache[name] = specID
					end
				end
			end

			local isMelee = IsMeleeClass(classID or 0, role, name)
			local pos = DeterminePosition(role, classID or 0, isMelee)

			total[role] = (total[role] or 0) + 1
			total.ALL = total.ALL + 1
			posCount[pos] = posCount[pos] + 1

			table.insert(units, {
				name = name,
				raidIndex = i,
				subgroup = subgroup,
				classID = classID or 0,
				role = role,
				pos = pos,
				isMelee = isMelee,
				canLust = LUST_CLASSES[classID] or false,
				canBRes = BRES_CLASSES[classID] or false,
				guid = UnitGUID(unit),
				processed = false,
			})
		end
	end

	return units, total, posCount
end

-- ============================================================================
-- Sort Algorithm
-- ============================================================================

local function GetSortPriority(unit)
	local DB = BFL:GetModule("DB")
	local sortMode = DB and DB:Get("raidToolsSortMode", "tmrh") or "tmrh"
	local isTHMR = sortMode == "thmr"

	-- Use spec-based priority only when spec role matches the assigned role
	if unit.name and specCache[unit.name] then
		local specID = specCache[unit.name]
		local specRole = SPEC_ROLE[specID] or "DAMAGER"
		if specRole == unit.role then
			local specPriority = isTHMR and SPEC_PRIORITY_THMR or SPEC_PRIORITY
			if specPriority[specID] then
				return specPriority[specID]
			end
		end
	end

	-- Fallback to role-based priority (differentiate melee/ranged for DPS)
	local rolePriority = isTHMR and ROLE_PRIORITY_THMR or ROLE_PRIORITY
	if unit.role == "DAMAGER" then
		if unit.isMelee then
			return rolePriority.MELEE or rolePriority.DAMAGER
		else
			return rolePriority.RANGED or rolePriority.DAMAGER
		end
	end
	local priority = rolePriority[unit.role] or rolePriority.NONE
	return priority
end

local function SortByPriority(units)
	table.sort(units, function(a, b)
		local pa = GetSortPriority(a)
		local pb = GetSortPriority(b)
		if pa ~= pb then
			return pa < pb
		end
		-- Tie-break by name for deterministic order
		return a.name < b.name
	end)
end

local function ShiftLeader(units)
	if not units or #units == 0 then
		return units
	end

	local leaderIdx = 0
	local goalIdx = 0

	for i, v in ipairs(units) do
		if UnitIsGroupLeader(v.name) then
			leaderIdx = i
			if v.role == "TANK" then
				-- Keep leader at the start of their group-of-5
				goalIdx = math.floor((i - 1) / 5) * 5 + 1
			end
			-- Non-tank leaders stay at their priority-sorted position
			break
		end
	end

	if leaderIdx > 0 and goalIdx > 0 and leaderIdx ~= goalIdx then
		local leader = units[leaderIdx]
		if leaderIdx > goalIdx then
			for i = leaderIdx, goalIdx + 1, -1 do
				units[i] = units[i - 1]
			end
		else
			for i = leaderIdx, goalIdx - 1 do
				units[i] = units[i + 1]
			end
		end
		units[goalIdx] = leader
	end

	return units
end

-- ============================================================================
-- Split Algorithm (inspired by NSRT cascading priority)
-- ============================================================================

function RaidTools:SplitRoster(units, total, posCount, odds, balanceDps)
	local sides = { left = {}, right = {} }
	local classes = { left = {}, right = {} }
	local specs = { left = {}, right = {} } -- Using classID as proxy since we don't have spec
	local pos = { left = { 0, 0, 0, 0, 0 }, right = { 0, 0, 0, 0, 0 } }
	local roles = { left = { count = 0 }, right = { count = 0 } }
	local lust = { left = false, right = false }
	local bres = { left = 0, right = 0 }
	local dpsMeter = { left = 0, right = 0 } -- DPS balance tracking

	-- Process by role order: TANK, then HEALER, then DAMAGER
	local roleOrder = { "TANK", "HEALER", "DAMAGER" }

	for _, currentRole in ipairs(roleOrder) do
		roles.left.count = 0
		roles.right.count = 0

		-- Count how many of this role exist
		local roleTotal = total[currentRole] or 0

		-- Count current role assignments per side
		for _, u in ipairs(sides.left) do
			if u.role == currentRole then
				roles.left.count = roles.left.count + 1
			end
		end
		for _, u in ipairs(sides.right) do
			if u.role == currentRole then
				roles.right.count = roles.right.count + 1
			end
		end

		for _, v in ipairs(units) do
			if v.role == currentRole then
				local side

				if currentRole == "TANK" then
					-- Tanks: simple alternation
					side = roles.left.count <= roles.right.count and "left" or "right"
				elseif #sides.left >= total.ALL / 2 then
					side = "right"
				elseif #sides.right >= total.ALL / 2 then
					side = "left"
				elseif roles.left.count >= roleTotal / 2 then
					side = "right"
				elseif roles.right.count >= roleTotal / 2 then
					side = "left"
				elseif pos.left[v.pos] >= posCount[v.pos] / 2 then
					side = "right"
				elseif pos.right[v.pos] >= posCount[v.pos] / 2 then
					side = "left"
				elseif classes.right[v.classID] and not classes.left[v.classID] then
					side = "left"
				elseif classes.left[v.classID] and not classes.right[v.classID] then
					side = "right"
				elseif not classes.left[v.classID] and not classes.right[v.classID] then
					side = pos.left[v.pos] > pos.right[v.pos] and "right" or "left"
				elseif v.canBRes and (bres.left <= 1 or bres.right <= 1) then
					side = (bres.left <= 1 and bres.left <= bres.right) and "left" or "right"
				elseif v.canLust and (not lust.left or not lust.right) then
					side = not lust.left and "left" or "right"
				elseif balanceDps and currentRole == "DAMAGER" then
					side = dpsMeter.left <= dpsMeter.right and "left" or "right"
				else
					side = #sides.left > #sides.right and "right" or "left"
				end

				table.insert(sides[side], v)
				classes[side][v.classID] = true
				pos[side][v.pos] = pos[side][v.pos] + 1
				if v.canLust then
					lust[side] = true
				end
				if v.canBRes then
					bres[side] = bres[side] + 1
				end
				if balanceDps and currentRole == "DAMAGER" then
					dpsMeter[side] = dpsMeter[side] + GetPlayerMeter(v.name, v.role)
				end
				roles[side].count = roles[side].count + 1
			end
		end
	end

	-- Re-sort each side internally
	SortByPriority(sides.left)
	SortByPriority(sides.right)

	-- Shift leader in each side
	ShiftLeader(sides.left)
	ShiftLeader(sides.right)

	-- Map sides to group positions
	local result = {}

	if odds then
		-- Evens/Odds: left -> groups 1,3,5 (positions 1-5, 11-15, 21-25)
		-- right -> groups 2,4,6 (positions 6-10, 16-20, 26-30)
		for i, v in ipairs(sides.left) do
			local idx = i
			if i > 10 then
				idx = i + 10
			elseif i > 5 then
				idx = i + 5
			end
			result[idx] = v
		end
		for i, v in ipairs(sides.right) do
			local idx
			if i > 10 then
				idx = i + 15
			elseif i > 5 then
				idx = i + 10
			else
				idx = i + 5
			end
			result[idx] = v
		end
	else
		-- Normal: left -> first groups, right -> second groups
		for i, v in ipairs(sides.left) do
			result[i] = v
		end
		local offset
		if total.ALL > 20 then
			offset = 15
		elseif total.ALL > 10 then
			offset = 10
		else
			offset = 5
		end
		for i, v in ipairs(sides.right) do
			result[i + offset] = v
		end
	end

	return result
end

-- ============================================================================
-- Swap Engine (delta-based, event-driven, 3-phase)
-- Phase 1 (GROUPS): Move players to correct groups via delta
-- Phase 2 (EVACUATE): Move all players out of a group that needs reordering
-- Phase 3 (REFILL): Move players back in target order (insertion order = position)
-- ============================================================================

local function ScheduleSafetyTimer()
	if processTimer then
		processTimer:Cancel()
	end
	processTimer = C_Timer.NewTimer(1.0, function()
		processTimer = nil
		if processing then
			ProcessOneDelta()
		end
	end)
end

local function StopProcessing(statusMessage)
	processing = false
	targetUnits = nil
	stepCount = 0
	totalTargetPlayers = 0
	progressHigh = 0
	sortPhase = PHASE_GROUPS
	reorderGroup = 0
	tempGroup = 0
	refillOrder = {}
	refillIdx = 1
	reorderedGroups = {}
	lastDropTime = 0
	dropCount = 0
	lastRaidSize = 0
	if processTimer then
		processTimer:Cancel()
		processTimer = nil
	end

	local RaidTools = BFL:GetModule("RaidTools")
	if RaidTools then
		RaidTools:UpdateStatusText(statusMessage or L.RAID_TOOLS_STATUS_DONE or "Done!")
		RaidTools:UpdateButtonStates()
	end
end

-- Build a list of players who are in the wrong group.
-- Returns: delta (list), groupSizes (table)
local function BuildDelta()
	if not targetUnits then
		return {}, {}
	end

	local nameToIndex = {}
	local nameToGroup = {}
	local groupSizes = {}
	for g = 1, 8 do
		groupSizes[g] = 0
	end

	for i = 1, MAX_RAID_MEMBERS do
		local name, _, subgroup = GetRaidRosterInfo(i)
		if not name then
			break
		end
		nameToIndex[name] = i
		nameToGroup[name] = subgroup
		groupSizes[subgroup] = groupSizes[subgroup] + 1
	end

	local delta = {}
	for slot = 1, MAX_RAID_MEMBERS do
		local unit = targetUnits[slot]
		if unit then
			local targetGrp = math.ceil(slot / 5)
			local currentGrp = nameToGroup[unit.name]
			if currentGrp and currentGrp ~= targetGrp then
				table.insert(delta, {
					name = unit.name,
					raidIndex = nameToIndex[unit.name],
					currentGroup = currentGrp,
					targetGroup = targetGrp,
				})
			end
		end
	end

	return delta, groupSizes
end

-- Find an empty group to use as temp for evacuation
local function FindTempGroup(groupSizes, avoidGroup)
	for g = 8, 1, -1 do
		if g ~= avoidGroup and groupSizes[g] == 0 then
			return g
		end
	end
	-- No empty group, find one with the most room
	local best, bestRoom = 0, 0
	for g = 8, 1, -1 do
		if g ~= avoidGroup then
			local room = 5 - groupSizes[g]
			if room > bestRoom then
				bestRoom = room
				best = g
			end
		end
	end
	return best > 0 and best or 8
end

-- Check within-group order: compare raidIndex-iteration order with target order
local function IsGroupOrderCorrect(groupNum)
	if not targetUnits then
		return true
	end

	-- Build target name order for this group
	local targetOrder = {}
	local startSlot = (groupNum - 1) * 5 + 1
	local endSlot = groupNum * 5
	for slot = startSlot, endSlot do
		if targetUnits[slot] then
			table.insert(targetOrder, targetUnits[slot].name)
		end
	end

	if #targetOrder <= 1 then
		return true
	end

	-- Get current order by iterating raidIndex (ascending)
	local currentOrder = {}
	for i = 1, MAX_RAID_MEMBERS do
		local name, _, subgroup = GetRaidRosterInfo(i)
		if not name then
			break
		end
		if subgroup == groupNum then
			table.insert(currentOrder, name)
		end
	end

	if #currentOrder ~= #targetOrder then
		return false
	end
	for i = 1, #targetOrder do
		if targetOrder[i] ~= currentOrder[i] then
			return false
		end
	end
	return true
end

-- Find the first group that needs within-group reordering
local function FindGroupNeedingReorder()
	if not targetUnits then
		return 0
	end

	-- Determine which groups have target players
	local groupHasPlayers = {}
	for slot = 1, MAX_RAID_MEMBERS do
		if targetUnits[slot] then
			groupHasPlayers[math.ceil(slot / 5)] = true
		end
	end

	for g = 1, 8 do
		if groupHasPlayers[g] and not reorderedGroups[g] and not IsGroupOrderCorrect(g) then
			return g
		end
	end
	return 0
end

-- Forward declaration
local ProcessOneDelta

local function CountCorrectPositions()
	if not targetUnits then
		return 0
	end
	local correct = 0
	local nameToGroup = {}
	for i = 1, MAX_RAID_MEMBERS do
		local name, _, subgroup = GetRaidRosterInfo(i)
		if not name then
			break
		end
		nameToGroup[name] = subgroup
	end
	for slot = 1, MAX_RAID_MEMBERS do
		local unit = targetUnits[slot]
		if unit then
			local targetGrp = math.ceil(slot / 5)
			if nameToGroup[unit.name] == targetGrp then
				correct = correct + 1
			end
		end
	end
	return correct
end

local function UpdateProgress()
	local RaidTools = BFL:GetModule("RaidTools")
	if not RaidTools then
		return
	end
	local done = CountCorrectPositions()
	if done > progressHigh then
		progressHigh = done
	end
	local progressText =
		string.format(L.RAID_TOOLS_STATUS_PROGRESS or "Sorting... (%d/%d)", progressHigh, totalTargetPlayers)
	RaidTools:UpdateStatusText(progressText)
end

ProcessOneDelta = function()
	if not processing or not targetUnits then
		return
	end

	-- Timeout check
	if GetTime() - processStart > SORT_TIMEOUT then
		BFL:DebugPrint("RaidTools: Sort timed out after " .. SORT_TIMEOUT .. "s")
		StopProcessing()
		return
	end

	-- Step limit
	stepCount = stepCount + 1
	if stepCount > MAX_STEPS then
		BFL:DebugPrint("RaidTools: Max steps reached (" .. MAX_STEPS .. ")")
		StopProcessing()
		return
	end

	-- ====== PHASE 1: Group-level sorting ======
	if sortPhase == PHASE_GROUPS then
		local delta, groupSizes = BuildDelta()

		if #delta == 0 then
			-- All in correct groups, check within-group order
			local grp = FindGroupNeedingReorder()
			if grp == 0 then
				StopProcessing()
				return
			end

			-- Transition to evacuate phase
			sortPhase = PHASE_EVACUATE
			reorderGroup = grp
			tempGroup = FindTempGroup(groupSizes, grp)

			-- Build refill order
			refillOrder = {}
			local startSlot = (reorderGroup - 1) * 5 + 1
			local endSlot = reorderGroup * 5
			for slot = startSlot, endSlot do
				if targetUnits[slot] then
					table.insert(refillOrder, targetUnits[slot].name)
				end
			end
			refillIdx = 1
			-- Fall through to PHASE_EVACUATE below
		else
			-- Move one player to correct group
			local first = delta[1]

			if groupSizes[first.targetGroup] < 5 then
				SetRaidSubgroup(first.raidIndex, first.targetGroup)
			else
				local swapPartner = nil

				for _, d in ipairs(delta) do
					if
						d.name ~= first.name
						and d.currentGroup == first.targetGroup
						and d.targetGroup == first.currentGroup
					then
						swapPartner = d
						break
					end
				end

				if not swapPartner then
					for _, d in ipairs(delta) do
						if d.name ~= first.name and d.currentGroup == first.targetGroup then
							swapPartner = d
							break
						end
					end
				end

				if not swapPartner then
					for i = 1, MAX_RAID_MEMBERS do
						local name, _, subgroup = GetRaidRosterInfo(i)
						if name and subgroup == first.targetGroup and i ~= first.raidIndex then
							swapPartner = { raidIndex = i }
							break
						end
					end
				end

				if swapPartner then
					SwapRaidSubgroup(first.raidIndex, swapPartner.raidIndex)
				else
					BFL:DebugPrint("RaidTools: Cannot find swap partner for " .. first.name)
				end
			end

			UpdateProgress()
			ScheduleSafetyTimer()
			return
		end
	end

	-- ====== PHASE 2: Evacuate group for reordering ======
	if sortPhase == PHASE_EVACUATE then
		for i = 1, MAX_RAID_MEMBERS do
			local name, _, subgroup = GetRaidRosterInfo(i)
			if not name then
				break
			end
			if subgroup == reorderGroup then
				SetRaidSubgroup(i, tempGroup)
				UpdateProgress()
				ScheduleSafetyTimer()
				return
			end
		end

		-- Group is now empty, transition to refill
		sortPhase = PHASE_REFILL
		-- Fall through to PHASE_REFILL
	end

	-- ====== PHASE 3: Refill group in target order ======
	if sortPhase == PHASE_REFILL then
		if refillIdx > #refillOrder then
			-- Group done, mark as reordered and check for more
			reorderedGroups[reorderGroup] = true
			sortPhase = PHASE_GROUPS
			ProcessOneDelta()
			return
		end

		local targetName = refillOrder[refillIdx]
		for i = 1, MAX_RAID_MEMBERS do
			local name = GetRaidRosterInfo(i)
			if name == targetName then
				SetRaidSubgroup(i, reorderGroup)
				refillIdx = refillIdx + 1
				UpdateProgress()
				ScheduleSafetyTimer()
				return
			end
		end

		-- Player not found (left raid?), skip
		refillIdx = refillIdx + 1
		ProcessOneDelta()
		return
	end
end

function RaidTools:StartArrangement(sortedUnits)
	if processing then
		BFL:DebugPrint("RaidTools: Sort already in progress")
		return
	end

	if BFL:IsActionRestricted() then
		self:UpdateStatusText(L.RAID_TOOLS_STATUS_ERROR_COMBAT or "Cannot sort during combat")
		return
	end

	if not IsInRaid() then
		self:UpdateStatusText(L.RAID_TOOLS_STATUS_ERROR_NOT_IN_RAID or "Not in a raid group")
		return
	end

	if not UnitIsGroupLeader("player") and not UnitIsGroupAssistant("player") then
		self:UpdateStatusText(L.RAID_TOOLS_STATUS_ERROR_NOT_LEADER or "Requires raid leader or assistant")
		return
	end

	-- Store target state
	targetUnits = sortedUnits
	processing = true
	processStart = GetTime()
	stepCount = 0
	progressHigh = 0
	sortPhase = PHASE_GROUPS
	reorderGroup = 0
	tempGroup = 0
	refillOrder = {}
	refillIdx = 1
	reorderedGroups = {}

	-- Initialize disbanding detection
	lastRaidSize = GetNumGroupMembers()
	lastDropTime = 0
	dropCount = 0

	-- Count total players for progress display
	totalTargetPlayers = 0
	for _ in pairs(sortedUnits) do
		totalTargetPlayers = totalTargetPlayers + 1
	end

	self:UpdateStatusText(L.RAID_TOOLS_STATUS_SORTING or "Sorting...")
	self:UpdateButtonStates()

	-- Start processing
	ProcessOneDelta()

	-- Register for roster updates to continue processing
	if not self.rosterEventRegistered then
		BFL:RegisterEventCallback("GROUP_ROSTER_UPDATE", function()
			if processing then
				-- Disbanding detection: track rapid player drops
				local currentSize = GetNumGroupMembers()
				if currentSize < lastRaidSize then
					local now = GetTime()
					local dropped = lastRaidSize - currentSize
					if now - lastDropTime < DROP_WINDOW then
						dropCount = dropCount + dropped
					else
						dropCount = dropped
					end
					lastDropTime = now
					if dropCount >= DROP_THRESHOLD then
						BFL:DebugPrint("RaidTools: Raid disbanding detected (" .. dropCount .. " drops)")
						StopProcessing(L.RAID_TOOLS_STATUS_DISBANDED or "Aborted - raid is disbanding")
						return
					end
				end
				lastRaidSize = currentSize

				if processTimer then
					processTimer:Cancel()
					processTimer = nil
				end
				processTimer = C_Timer.NewTimer(0.05, function()
					processTimer = nil
					if processing then
						ProcessOneDelta()
					end
				end)
			end
		end, 90)
		self.rosterEventRegistered = true
	end
end

-- ============================================================================
-- Public Sort/Split Functions
-- ============================================================================

function RaidTools:CanExecute()
	if BFL:IsActionRestricted() then
		return false, "combat"
	end
	if not IsInRaid() then
		return false, "not_in_raid"
	end
	if not UnitIsGroupLeader("player") and not UnitIsGroupAssistant("player") then
		return false, "not_leader"
	end
	if processing then
		return false, "in_progress"
	end
	return true
end

function RaidTools:SortByRole()
	local canDo, reason = self:CanExecute()
	if not canDo then
		self:ShowError(reason)
		return
	end

	-- Cancel any pending resume and track current mode
	paused = false
	pausedSortMode = "sort"

	local DB = BFL:GetModule("DB")
	local preserveGroups = DB and DB:Get("raidToolsPreserveGroups", {}) or {}
	local maxGroup = GetMaxGroupForDifficulty()
	local units = self:CollectRosterData(maxGroup, preserveGroups)
	local availableGroups = BuildAvailableGroups(maxGroup, preserveGroups)

	SortByPriority(units)
	ShiftLeader(units)

	-- Convert list to slot-indexed table, then remap to available groups
	local slotted = {}

	-- Debug: print sorted result
	BFL:DebugPrint(
		"RaidTools: Sort result ("
			.. #units
			.. " players, mode="
			.. (DB and DB:Get("raidToolsSortMode", "tmrh") or "tmrh")
			.. "):"
	)
	for i, v in ipairs(units) do
		local virtualGroup = math.ceil(i / 5)
		local actualGroup = availableGroups[virtualGroup] or virtualGroup
		local prio = GetSortPriority(v)
		local specID = specCache[v.name] or "none"
		BFL:DebugPrint(
			"  "
				.. i
				.. " (G"
				.. actualGroup
				.. "): "
				.. v.name
				.. " role="
				.. v.role
				.. " melee="
				.. tostring(v.isMelee)
				.. " prio="
				.. prio
				.. " spec="
				.. tostring(specID)
		)
		slotted[i] = v
	end

	slotted = RemapSlots(slotted, availableGroups)
	self:StartArrangement(slotted)
end

function RaidTools:SplitGroups(odds)
	local canDo, reason = self:CanExecute()
	if not canDo then
		self:ShowError(reason)
		return
	end

	-- Cancel any pending resume and track current mode
	paused = false
	pausedSortMode = odds and "splitOdds" or "split"

	local DB = BFL:GetModule("DB")
	local preserveGroups = DB and DB:Get("raidToolsPreserveGroups", {}) or {}
	local maxGroup = GetMaxGroupForDifficulty()
	local units, total, posCount = self:CollectRosterData(maxGroup, preserveGroups)
	local availableGroups = BuildAvailableGroups(maxGroup, preserveGroups)

	-- Build meter snapshot if DPS balancing is enabled
	local balanceDps = DB and DB:Get("raidToolsBalanceDps", false) or false
	local hasMeterData = false
	if balanceDps then
		hasMeterData = self:BuildMeterSnapshot(units)
	end

	-- Sort by priority first
	SortByPriority(units)

	-- Run split algorithm
	local slotted = self:SplitRoster(units, total, posCount, odds, balanceDps and hasMeterData)

	-- Remap virtual group slots to actual available groups
	slotted = RemapSlots(slotted, availableGroups)

	self:StartArrangement(slotted)
end

function RaidTools:PromoteTanksToAssist()
	if BFL:IsActionRestricted() then
		self:UpdateStatusText(L.RAID_TOOLS_STATUS_ERROR_COMBAT or "Cannot do this during combat")
		return
	end

	if not IsInRaid() then
		self:UpdateStatusText(L.RAID_TOOLS_STATUS_ERROR_NOT_IN_RAID or "Not in a raid group")
		return
	end

	if not UnitIsGroupLeader("player") then
		self:UpdateStatusText(L.RAID_TOOLS_STATUS_ERROR_LEADER_ONLY or "Requires raid leader")
		return
	end

	local promoted = 0
	for i = 1, MAX_RAID_MEMBERS do
		local name, rank = GetRaidRosterInfo(i)
		if not name then
			break
		end

		local unit = "raid" .. i
		if UnitGroupRolesAssigned(unit) == "TANK" and rank == 0 then
			PromoteToAssistant(unit)
			promoted = promoted + 1
		end
	end

	if promoted > 0 then
		self:UpdateStatusText(string.format(L.RAID_TOOLS_STATUS_PROMOTED or "Promoted %d tanks", promoted))
	else
		self:UpdateStatusText(L.RAID_TOOLS_STATUS_NO_TANKS or "No tanks to promote")
	end
end

function RaidTools:ShowError(reason)
	if reason == "combat" then
		self:UpdateStatusText(L.RAID_TOOLS_STATUS_ERROR_COMBAT or "Cannot sort during combat")
	elseif reason == "not_in_raid" then
		self:UpdateStatusText(L.RAID_TOOLS_STATUS_ERROR_NOT_IN_RAID or "Not in a raid group")
	elseif reason == "not_leader" then
		self:UpdateStatusText(L.RAID_TOOLS_STATUS_ERROR_NOT_LEADER or "Requires raid leader or assistant")
	elseif reason == "in_progress" then
		self:UpdateStatusText(L.RAID_TOOLS_STATUS_SORTING or "Sorting...")
	end
end

-- ============================================================================
-- Frame Creation (lazy-init, mirrors HelpFrame pattern)
-- ============================================================================

function RaidTools:UpdateStatusText(text)
	if toolsFrame and toolsFrame.statusText then
		toolsFrame.statusText:SetText(text or "")
	end
end

function RaidTools:UpdateButtonStates()
	if not toolsFrame then
		return
	end

	local canDo = self:CanExecute()
	local inRaid = IsInRaid()
	local isLeader = UnitIsGroupLeader("player")

	if toolsFrame.sortButton then
		toolsFrame.sortButton:SetEnabled(canDo)
	end
	if toolsFrame.splitButton then
		toolsFrame.splitButton:SetEnabled(canDo)
	end
	if toolsFrame.splitOddsButton then
		toolsFrame.splitOddsButton:SetEnabled(canDo)
	end
	if toolsFrame.promoteButton then
		-- Promote requires raid leader specifically
		local canPromote = inRaid and isLeader and not BFL:IsActionRestricted()
		toolsFrame.promoteButton:SetEnabled(canPromote)
		if not canPromote and inRaid and not isLeader then
			toolsFrame.promoteButton.disabledTooltip = L.RAID_TOOLS_STATUS_ERROR_LEADER_ONLY or "Requires raid leader"
		else
			toolsFrame.promoteButton.disabledTooltip = nil
		end
	end
	if toolsFrame.balanceDpsCheck then
		local hasMeter = self:HasMeterAddon()
		toolsFrame.balanceDpsCheck:SetEnabled(hasMeter)
		-- Update label font to match enabled/disabled state
		local balanceText = toolsFrame.balanceDpsCheck.Text or _G["BFLRaidToolsBalanceDpsText"]
		if balanceText then
			balanceText:SetFontObject(hasMeter and "BetterFriendlistFontNormal" or "BetterFriendlistFontDisable")
		end
		if not hasMeter then
			local DB = BFL:GetModule("DB")
			if DB:Get("raidToolsBalanceDps", false) then
				DB:Set("raidToolsBalanceDps", false)
			end
			toolsFrame.balanceDpsCheck:SetChecked(false)
		end
	end
end

local function CreateToolButton(parent, text, yOffset, onClick, tooltipText)
	local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	button:SetSize(240, 22)
	button:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, yOffset)
	button:SetText(text)

	button:SetNormalFontObject("BetterFriendlistFontNormal")
	button:SetHighlightFontObject("BetterFriendlistFontHighlight")
	button:SetDisabledFontObject("BetterFriendlistFontDisable")

	button:SetScript("OnClick", onClick)
	button:SetMotionScriptsWhileDisabled(true)

	if tooltipText then
		button:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			if not self:IsEnabled() and self.disabledTooltip then
				GameTooltip:SetText(self.disabledTooltip, 1, 0.2, 0.2, 1, true)
			else
				GameTooltip:SetText(tooltipText, 1, 1, 1, 1, true)
			end
			GameTooltip:Show()
		end)
		button:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)
	end

	return button
end

local function CreateSectionHeader(parent, text, yOffset)
	local header = parent:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontNormal")
	header:SetPoint("TOPLEFT", parent, "TOPLEFT", 15, yOffset)
	header:SetJustifyH("LEFT")
	header:SetText(text)
	header:SetTextColor(1.0, 0.82, 0)
	return header
end

function RaidTools:CreateFrame()
	if toolsFrame then
		return toolsFrame
	end

	local frame = CreateFrame("Frame", "BetterFriendlistRaidToolsFrame", BetterFriendsFrame, "ButtonFrameTemplate")
	frame:SetSize(280, 400)
	frame:SetPoint("TOPLEFT", BetterFriendsFrame, "TOPRIGHT", 5, 0)
	frame:SetFrameStrata("HIGH")
	frame:EnableMouse(true)
	frame:SetMovable(false)
	frame:Hide()

	-- Setup ButtonFrameTemplate
	if frame.portrait then
		frame.portrait:Hide()
	end
	if frame.PortraitContainer then
		frame.PortraitContainer:Hide()
	end

	if ButtonFrameTemplate_HidePortrait then
		ButtonFrameTemplate_HidePortrait(frame)
	end
	if ButtonFrameTemplate_HideAttic then
		ButtonFrameTemplate_HideAttic(frame)
	end

	-- Title
	if frame.TitleContainer and frame.TitleContainer.TitleText then
		frame.TitleContainer.TitleText:SetText(L.RAID_TOOLS_TITLE or "Raid Tools")
	end

	-- Content container
	local content = CreateFrame("Frame", nil, frame)
	content:SetPoint("TOPLEFT", 12, -30)
	content:SetPoint("BOTTOMRIGHT", -12, 10)

	local DB = BFL:GetModule("DB")
	local yPos = -10

	-- Section: Sort
	CreateSectionHeader(content, L.RAID_TOOLS_SORT_HEADER or "Sort", yPos)
	yPos = yPos - 25

	local dropdownXOffset = BFL.HasModernDropdown and 10 or -6

	local sortModeOptions = {
		labels = {
			L.RAID_TOOLS_SORT_MODE_TMRH or "Tanks > Melee > Ranged > Healers",
			L.RAID_TOOLS_SORT_MODE_THMR or "Tanks > Healers > Melee > Ranged",
		},
		values = { "tmrh", "thmr" },
	}
	local sortModeDropdown = BFL.CreateDropdown(content, "BFLRaidToolsSortMode", 236)
	sortModeDropdown:SetPoint("TOPLEFT", content, "TOPLEFT", dropdownXOffset, yPos)
	BFL.InitializeDropdown(sortModeDropdown, sortModeOptions, function(val)
		return val == DB:Get("raidToolsSortMode", "tmrh")
	end, function(val)
		DB:Set("raidToolsSortMode", val)
	end)
	yPos = yPos - 33

	frame.sortButton = CreateToolButton(content, L.RAID_TOOLS_SORT_DEFAULT or "Sort Raid", yPos, function()
		RaidTools:SortByRole()
	end, L.RAID_TOOLS_SORT_DEFAULT_DESC or "Arranges raid members by role using the selected sort order")
	yPos = yPos - 35

	-- Section: Split
	CreateSectionHeader(content, L.RAID_TOOLS_SPLIT_HEADER or "Split", yPos)
	yPos = yPos - 20

	frame.splitButton = CreateToolButton(content, L.RAID_TOOLS_SPLIT_GROUPS or "Split in Half", yPos, function()
		RaidTools:SplitGroups(false)
	end, L.RAID_TOOLS_SPLIT_GROUPS_DESC or "Divides the raid into two balanced halves")
	yPos = yPos - 30

	frame.splitOddsButton = CreateToolButton(
		content,
		L.RAID_TOOLS_SPLIT_EVENS_ODDS or "Split Odd/Even",
		yPos,
		function()
			RaidTools:SplitGroups(true)
		end,
		L.RAID_TOOLS_SPLIT_EVENS_ODDS_DESC or "Divides the raid into odd (1, 3, 5) and even (2, 4, 6) groups"
	)
	yPos = yPos - 28

	-- Balance DPS Checkbox
	local balanceCheck = CreateFrame("CheckButton", "BFLRaidToolsBalanceDps", content, "UICheckButtonTemplate")
	balanceCheck:SetPoint("TOPLEFT", content, "TOPLEFT", 10, yPos)
	local balanceText = balanceCheck.Text or _G["BFLRaidToolsBalanceDpsText"]
	if balanceText then
		balanceText:SetText(L.RAID_TOOLS_SPLIT_BALANCE_DPS or "Balance DPS")
		balanceText:SetFontObject("BetterFriendlistFontNormal")
	end
	balanceCheck:SetChecked(DB:Get("raidToolsBalanceDps", false))
	balanceCheck:SetScript("OnClick", function(self)
		local checked = self:GetChecked()
		if checked and not RaidTools:HasMeterAddon() then
			self:SetChecked(false)
			RaidTools:UpdateStatusText(L.RAID_TOOLS_STATUS_NO_METER_DATA or "No damage meter data available")
			return
		end
		DB:Set("raidToolsBalanceDps", checked)
	end)
	frame.balanceDpsCheck = balanceCheck
	yPos = yPos - 35

	-- Section: Options
	CreateSectionHeader(content, L.RAID_TOOLS_SETTINGS_HEADER or "Options", yPos)
	yPos = yPos - 25

	-- Preserve Groups Dropdown (Multi-Select)
	local preserveLabel = content:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontNormal")
	preserveLabel:SetPoint("TOPLEFT", content, "TOPLEFT", 15, yPos)
	preserveLabel:SetText(L.RAID_TOOLS_SETTING_GROUP_OFFSET or "Preserve Groups")
	preserveLabel:SetTextColor(1, 1, 1)
	yPos = yPos - 18

	local preserveOptions = {
		labels = {},
		values = {},
	}
	for g = 1, 8 do
		preserveOptions.labels[g] = (L.RAID_TOOLS_SETTING_GROUP_N or "Group %d"):format(g)
		preserveOptions.values[g] = g
	end

	local function getPreserveText()
		local preserved = DB:Get("raidToolsPreserveGroups", {})
		local selected = {}
		for g = 1, 8 do
			if preserved[g] then
				table.insert(selected, tostring(g))
			end
		end
		if #selected == 0 then
			return L.RAID_TOOLS_SETTING_OFFSET_NONE or "None"
		end
		return table.concat(selected, ", ")
	end

	local preserveDropdown = BFL.CreateDropdown(content, "BFLRaidToolsPreserveGroups", 236)
	preserveDropdown:SetPoint("TOPLEFT", content, "TOPLEFT", dropdownXOffset, yPos)
	BFL.InitializeMultiSelectDropdown(preserveDropdown, preserveOptions, function(val)
		local preserved = DB:Get("raidToolsPreserveGroups", {})
		return preserved[val] == true
	end, function(val, checked)
		local preserved = DB:Get("raidToolsPreserveGroups", {})
		preserved[val] = checked or nil
		DB:Set("raidToolsPreserveGroups", preserved)
	end, getPreserveText)
	yPos = yPos - 30

	-- Resume After Combat Checkbox
	local resumeCheck = CreateFrame("CheckButton", "BFLRaidToolsResumeCheck", content, "UICheckButtonTemplate")
	resumeCheck:SetPoint("TOPLEFT", content, "TOPLEFT", 10, yPos)
	local resumeText = resumeCheck.Text or _G["BFLRaidToolsResumeCheckText"]
	if resumeText then
		resumeText:SetText(L.RAID_TOOLS_SETTING_RESUME_COMBAT or "Auto-resume after combat")
		resumeText:SetFontObject("BetterFriendlistFontNormal")
	end
	resumeCheck:SetChecked(DB:Get("raidToolsResumeAfterCombat", true))
	resumeCheck:SetScript("OnClick", function(self)
		DB:Set("raidToolsResumeAfterCombat", self:GetChecked())
	end)
	yPos = yPos - 30

	-- Promote Tanks
	frame.promoteButton = CreateToolButton(content, L.RAID_TOOLS_PROMOTE_TANKS or "Promote Tanks", yPos, function()
		RaidTools:PromoteTanksToAssist()
	end, L.RAID_TOOLS_PROMOTE_TANKS_DESC or "Gives raid assistant to all players with the Tank role")

	-- Status text at the very bottom of the frame (below content, on grey border area)
	local statusText = frame:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontHighlight")
	statusText:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 14, 8)
	statusText:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -14, 8)
	statusText:SetJustifyH("CENTER")
	statusText:SetText("")
	frame.statusText = statusText

	-- Sound and events
	frame:SetScript("OnShow", function()
		-- Close HelpFrame when opening Tools
		if BFL.HelpFrame then
			BFL.HelpFrame:Hide()
		end
		RaidTools:UpdateButtonStates()
		RaidTools:UpdateStatusText("")
		-- Start spec inspection for raid members
		RaidTools:BuildInspectQueue()
		if #inspectQueue > 0 then
			RaidTools:ProcessInspectQueue()
		end
	end)

	frame:SetScript("OnHide", function()
		paused = false
		pausedSortMode = nil
		RaidTools:StopInspecting()
	end)

	toolsFrame = frame
	return frame
end

-- ============================================================================
-- Toggle / Show / Hide
-- ============================================================================

function RaidTools:Toggle()
	local frame = self:CreateFrame()

	if frame:IsShown() then
		frame:Hide()
	else
		frame:Show()
	end
end

function RaidTools:Show()
	local frame = self:CreateFrame()
	frame:Show()
end

function RaidTools:Hide()
	if toolsFrame then
		toolsFrame:Hide()
	end
end

function RaidTools:IsShown()
	return toolsFrame and toolsFrame:IsShown()
end

-- Global Click Handler (called from XML)
function BetterRaidFrame_RaidToolsButton_OnClick(self)
	local RT = BFL:GetModule("RaidTools")
	if RT then
		RT:Toggle()
	end
end
