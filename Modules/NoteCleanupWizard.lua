-- NoteCleanupWizard.lua
-- Wizard UI for cleaning up FriendGroups-style notes (#Group1#Group2 suffixes)

local ADDON_NAME, BFL = ...

local NoteCleanupWizard = {}
BFL.NoteCleanupWizard = NoteCleanupWizard

local L = BFL.L or BFL_L
local DB

-- ========================================
-- Constants
-- ========================================
local WIZARD_WIDTH = 780
local WIZARD_HEIGHT = 520
local ROW_HEIGHT = 26
local COLUMN_PADDING = 8
local HEADER_HEIGHT = 22
local SCROLL_BAR_WIDTH = 20
local STATUS_COL_WIDTH = 26

-- Column widths (relative to content area)
local COL_ACCOUNT = 0.20
local COL_BATTLETAG = 0.20
local COL_NOTE = 0.28
local COL_CLEANED = 0.32

-- ========================================
-- Local State
-- ========================================
local wizardFrame = nil
local backupViewerFrame = nil
local friendData = {} -- All scanned friends
local filteredData = {} -- After search filter
local rowFrames = {} -- Reusable row frames
local searchText = ""
local backupRowFrames = {} -- Reusable row frames for backup viewer
local backupFilteredData = {} -- Filtered backup data
local backupSearchText = ""
local isApplying = false
local isRestoring = false

-- ========================================
-- Helper: Get streamer-safe display name
-- ========================================
local function GetStreamerSafeAccountName(data)
	if not (BFL.StreamerMode and BFL.StreamerMode:IsActive()) then
		return data.accountName
	end

	-- In Streamer Mode, never show the Real ID (accountName)
	local mode = BetterFriendlistDB and BetterFriendlistDB.streamerModeNameFormat or "battletag"

	-- Default safe name: BattleTag (short, without #number)
	local safeName
	if data.battleTag and data.battleTag ~= "" then
		safeName = data.battleTag:match("([^#]+)") or data.battleTag
	elseif not data.isBNet then
		-- WoW-only friends: character name is safe
		safeName = data.characterName or data.accountName
	else
		safeName = "Unknown"
	end

	if mode == "note" then
		local note = data.originalNote or data.backedUpNote or ""
		if note ~= "" then
			safeName = note
		end
	end

	return safeName
end

-- ========================================
-- Helper: Parse FriendGroups note
-- ========================================
local function ParseFriendGroupsNote(noteText)
	if not noteText or noteText == "" then
		return "", {}
	end
	local parts = { strsplit("#", noteText) }
	local actualNote = parts[1] or ""
	local groups = {}
	for i = 2, #parts do
		local groupName = strtrim(parts[i])
		if groupName ~= "" then
			table.insert(groups, groupName)
		end
	end
	return actualNote, groups
end

-- ========================================
-- Helper: Check if note has FriendGroups data
-- ========================================
local function NoteHasGroups(noteText)
	if not noteText or noteText == "" then
		return false
	end
	return noteText:find("#") ~= nil
end

-- ========================================
-- Scan all BNet friends
-- ========================================
function NoteCleanupWizard:ScanFriends()
	isApplying = false
	friendData = {}

	local numBNetFriends = BNGetNumFriends()
	for i = 1, numBNetFriends do
		local accountInfo = C_BattleNet.GetFriendAccountInfo(i)
		if accountInfo then
			local noteText = accountInfo.note or ""
			local actualNote, groups = ParseFriendGroupsNote(noteText)

			table.insert(friendData, {
				index = i,
				accountName = accountInfo.accountName or "",
				battleTag = accountInfo.battleTag or "",
				bnetAccountID = accountInfo.bnetAccountID,
				originalNote = noteText,
				cleanedNote = actualNote,
				groups = groups,
				hasGroups = #groups > 0,
				isBNet = true,
			})
		end
	end

	-- Also scan WoW-only friends
	if C_FriendList and C_FriendList.GetNumFriends then
		local numWoWFriends = C_FriendList.GetNumFriends()
		for i = 1, numWoWFriends do
			local friendInfo = C_FriendList.GetFriendInfoByIndex(i)
			if friendInfo then
				local noteText = friendInfo.notes or ""
				local actualNote, groups = ParseFriendGroupsNote(noteText)

				table.insert(friendData, {
					index = i,
					accountName = friendInfo.name or "",
					battleTag = "",
					characterName = friendInfo.name,
					originalNote = noteText,
					cleanedNote = actualNote,
					groups = groups,
					hasGroups = #groups > 0,
					isBNet = false,
				})
			end
		end
	end

	self:ApplyFilter()
end

-- ========================================
-- Filter friends by search text
-- ========================================
function NoteCleanupWizard:ApplyFilter()
	filteredData = {}
	local query = searchText:lower()

	for _, data in ipairs(friendData) do
		if query == "" then
			table.insert(filteredData, data)
		else
			local displayName = GetStreamerSafeAccountName(data)
			local matchName = displayName:lower():find(query, 1, true)
			local matchTag = data.battleTag:lower():find(query, 1, true)
			local matchNote = data.originalNote:lower():find(query, 1, true)
			local matchCleaned = data.cleanedNote:lower():find(query, 1, true)
			if matchName or matchTag or matchNote or matchCleaned then
				table.insert(filteredData, data)
			end
		end
	end

	self:RefreshRows()
end

-- ========================================
-- Backup notes to DB
-- ========================================
function NoteCleanupWizard:BackupNotes()
	if not BetterFriendlistDB then
		return
	end

	local backup = {}
	for _, data in ipairs(friendData) do
		local key = data.isBNet and data.battleTag or data.characterName
		if key and key ~= "" then
			backup[key] = {
				originalNote = data.originalNote,
				accountName = data.accountName,
				battleTag = data.battleTag,
				isBNet = data.isBNet,
				timestamp = time(),
			}
		end
	end

	BetterFriendlistDB.noteBackup = backup
	BFL:DebugPrint("|cff00ff00BetterFriendlist:|r " .. string.format(L.WIZARD_BACKUP_SUCCESS, #friendData))
end

-- ========================================
-- Apply cleaned notes
-- ========================================
function NoteCleanupWizard:ApplyCleanedNotes()
	if isApplying then
		return
	end

	-- Collect entries that need updating and mark as pending
	local toUpdate = {}
	for _, data in ipairs(friendData) do
		if data.originalNote ~= data.cleanedNote then
			data.status = "pending"
			table.insert(toUpdate, data)
		else
			data.status = nil
		end
	end

	if #toUpdate == 0 then
		self:RefreshRows()
		return
	end

	isApplying = true
	self:RefreshRows()

	local currentIndex = 0
	local successCount = 0
	local errorCount = 0

	local function ProcessNext()
		if not isApplying then
			return
		end

		currentIndex = currentIndex + 1
		if currentIndex > #toUpdate then
			isApplying = false
			NoteCleanupWizard:RefreshRows()
			BFL:DebugPrint("|cff00ff00BetterFriendlist:|r " .. string.format(L.WIZARD_APPLY_SUCCESS, successCount))
			return
		end

		local data = toUpdate[currentIndex]
		local success, err = pcall(function()
			if data.isBNet and data.bnetAccountID then
				BNSetFriendNote(data.bnetAccountID, data.cleanedNote)
			elseif not data.isBNet and data.characterName then
				C_FriendList.SetFriendNotes(data.characterName, data.cleanedNote)
			end
		end)

		if success then
			data.status = "success"
			data.originalNote = data.cleanedNote
			successCount = successCount + 1
		else
			data.status = "error"
			errorCount = errorCount + 1
			BFL:DebugPrint(
				"|cffff0000BetterFriendlist:|r Error: " .. (data.accountName or "?") .. " - " .. tostring(err)
			)
		end

		NoteCleanupWizard:RefreshRows()
		C_Timer.After(0.05, ProcessNext)
	end

	-- Start processing after brief delay to show pending state
	C_Timer.After(0.1, ProcessNext)
end

-- ========================================
-- Create a single table row
-- ========================================
local function CreateRow(parent, index)
	local row = CreateFrame("Frame", nil, parent)
	row:SetHeight(ROW_HEIGHT)

	-- Alternating background
	row.bg = row:CreateTexture(nil, "BACKGROUND")
	row.bg:SetAllPoints()

	-- Status icon (pending/success/error)
	row.statusIcon = row:CreateTexture(nil, "ARTWORK")
	row.statusIcon:SetSize(16, 16)
	row.statusIcon:Hide()

	local contentWidth = parent:GetWidth()

	-- Account Name column
	row.accountName = row:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontHighlightSmall")
	row.accountName:SetJustifyH("LEFT")
	row.accountName:SetWordWrap(false)

	-- BattleTag column
	row.battleTag = row:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontHighlightSmall")
	row.battleTag:SetJustifyH("LEFT")
	row.battleTag:SetWordWrap(false)

	-- Original Note column
	row.noteText = row:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontHighlightSmall")
	row.noteText:SetJustifyH("LEFT")
	row.noteText:SetWordWrap(false)

	-- Cleaned Note (EditBox)
	row.cleanedInput = CreateFrame("EditBox", nil, row, "InputBoxTemplate")
	row.cleanedInput:SetAutoFocus(false)
	row.cleanedInput:SetHeight(18)
	row.cleanedInput:SetFontObject("BetterFriendlistFontHighlightSmall")

	row.cleanedInput:SetScript("OnEscapePressed", function(self)
		self:ClearFocus()
	end)

	row.cleanedInput:SetScript("OnEnterPressed", function(self)
		self:ClearFocus()
	end)

	return row
end

-- ========================================
-- Layout a row with column widths
-- ========================================
local function LayoutRow(row, contentWidth)
	local availWidth = contentWidth - STATUS_COL_WIDTH
	local colW1 = math.floor(availWidth * COL_ACCOUNT)
	local colW2 = math.floor(availWidth * COL_BATTLETAG)
	local colW3 = math.floor(availWidth * COL_NOTE)

	-- Status icon at far left
	row.statusIcon:ClearAllPoints()
	row.statusIcon:SetPoint("LEFT", row, "LEFT", (STATUS_COL_WIDTH - 16) / 2, 0)

	local offset = STATUS_COL_WIDTH

	row.accountName:ClearAllPoints()
	row.accountName:SetPoint("LEFT", row, "LEFT", offset + COLUMN_PADDING, 0)
	row.accountName:SetWidth(colW1 - COLUMN_PADDING * 2)

	row.battleTag:ClearAllPoints()
	row.battleTag:SetPoint("LEFT", row, "LEFT", offset + colW1 + COLUMN_PADDING, 0)
	row.battleTag:SetWidth(colW2 - COLUMN_PADDING * 2)

	row.noteText:ClearAllPoints()
	row.noteText:SetPoint("LEFT", row, "LEFT", offset + colW1 + colW2 + COLUMN_PADDING, 0)
	row.noteText:SetWidth(colW3 - COLUMN_PADDING * 2)

	row.cleanedInput:ClearAllPoints()
	row.cleanedInput:SetPoint("LEFT", row, "LEFT", offset + colW1 + colW2 + colW3 + COLUMN_PADDING, 0)
	row.cleanedInput:SetPoint("RIGHT", row, "RIGHT", -COLUMN_PADDING, 0)
end

-- ========================================
-- Refresh visible rows
-- ========================================
function NoteCleanupWizard:RefreshRows()
	if not wizardFrame then
		return
	end

	local scrollChild = wizardFrame.scrollChild
	if not scrollChild then
		return
	end

	local contentWidth = scrollChild:GetWidth()

	-- Hide all existing rows
	for _, row in ipairs(rowFrames) do
		row:Hide()
	end

	-- Create/reuse rows for filtered data
	for i, data in ipairs(filteredData) do
		local row = rowFrames[i]
		if not row then
			row = CreateRow(scrollChild, i)
			rowFrames[i] = row
		end

		-- Position
		row:ClearAllPoints()
		row:SetPoint("LEFT", scrollChild, "LEFT", 0, 0)
		row:SetPoint("RIGHT", scrollChild, "RIGHT", 0, 0)

		if i == 1 then
			row:SetPoint("TOP", scrollChild, "TOP", 0, 0)
		else
			row:SetPoint("TOP", rowFrames[i - 1], "BOTTOM", 0, 0)
		end

		-- Background color based on status (traffic light system)
		if data.status == "success" then
			if i % 2 == 0 then
				row.bg:SetColorTexture(0.05, 0.25, 0.05, 0.6)
			else
				row.bg:SetColorTexture(0.04, 0.20, 0.04, 0.4)
			end
		elseif data.status == "error" then
			if i % 2 == 0 then
				row.bg:SetColorTexture(0.30, 0.05, 0.05, 0.6)
			else
				row.bg:SetColorTexture(0.25, 0.04, 0.04, 0.4)
			end
		elseif data.status == "pending" then
			if i % 2 == 0 then
				row.bg:SetColorTexture(0.30, 0.25, 0.05, 0.6)
			else
				row.bg:SetColorTexture(0.25, 0.20, 0.04, 0.4)
			end
		elseif data.hasGroups then
			if i % 2 == 0 then
				row.bg:SetColorTexture(0.2, 0.15, 0.05, 0.5)
			else
				row.bg:SetColorTexture(0.18, 0.12, 0.03, 0.3)
			end
		else
			if i % 2 == 0 then
				row.bg:SetColorTexture(0.15, 0.15, 0.15, 0.5)
			else
				row.bg:SetColorTexture(0.1, 0.1, 0.1, 0.3)
			end
		end

		-- Status icon
		if data.status == "pending" then
			row.statusIcon:SetTexture("Interface\\RaidFrame\\ReadyCheck-Waiting")
			row.statusIcon:Show()
		elseif data.status == "success" then
			row.statusIcon:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
			row.statusIcon:Show()
		elseif data.status == "error" then
			row.statusIcon:SetTexture("Interface\\RaidFrame\\ReadyCheck-NotReady")
			row.statusIcon:Show()
		else
			row.statusIcon:Hide()
		end

		LayoutRow(row, contentWidth)

		-- Set data (respect Streamer Mode for account names)
		row.accountName:SetText(GetStreamerSafeAccountName(data))
		row.battleTag:SetText(data.battleTag)

		-- Color original note: highlight the #groups part in orange
		if data.hasGroups then
			local actualNote, _ = ParseFriendGroupsNote(data.originalNote)
			local groupPart = data.originalNote:sub(#actualNote + 1)
			row.noteText:SetText(actualNote .. "|cffff8800" .. groupPart .. "|r")
		else
			row.noteText:SetText(data.originalNote)
		end

		-- Set cleaned note input
		row.cleanedInput:SetText(data.cleanedNote)

		-- Store reference to data for the EditBox callback
		row.cleanedInput.dataRef = data
		row.cleanedInput:SetScript("OnTextChanged", function(self, userInput)
			if userInput and self.dataRef then
				self.dataRef.cleanedNote = self:GetText()
			end
		end)

		row:Show()
	end

	-- Update scroll child height
	local totalHeight = #filteredData * ROW_HEIGHT
	scrollChild:SetHeight(math.max(totalHeight, 1))

	-- Update count label
	if wizardFrame.countLabel then
		-- Check if apply progress should be shown
		local pendingCount = 0
		local successCount = 0
		local errorCount = 0
		for _, data in ipairs(friendData) do
			if data.status == "pending" then
				pendingCount = pendingCount + 1
			end
			if data.status == "success" then
				successCount = successCount + 1
			end
			if data.status == "error" then
				errorCount = errorCount + 1
			end
		end

		local totalStatusCount = pendingCount + successCount + errorCount

		if totalStatusCount > 0 then
			wizardFrame.countLabel:SetText(
				string.format(
					L.WIZARD_APPLY_PROGRESS_FMT,
					successCount + errorCount,
					totalStatusCount,
					successCount,
					errorCount
				)
			)
		else
			local totalWithGroups = 0
			local totalChanged = 0
			for _, data in ipairs(friendData) do
				if data.hasGroups then
					totalWithGroups = totalWithGroups + 1
				end
				if data.originalNote ~= data.cleanedNote then
					totalChanged = totalChanged + 1
				end
			end
			wizardFrame.countLabel:SetText(
				string.format(L.WIZARD_STATUS_FMT, #filteredData, #friendData, totalWithGroups, totalChanged)
			)
		end
	end
end

-- ========================================
-- Create the Wizard Frame
-- ========================================
function NoteCleanupWizard:CreateWizardFrame()
	if wizardFrame then
		return wizardFrame
	end

	-- Main frame
	local frame = CreateFrame("Frame", "BetterFriendlistNoteCleanupWizard", UIParent, "ButtonFrameTemplate")
	frame:SetSize(WIZARD_WIDTH, WIZARD_HEIGHT)
	frame:SetPoint("CENTER")
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:SetClampedToScreen(true)
	frame:SetFrameStrata("DIALOG")
	frame:SetToplevel(true)

	-- Allow dragging
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", function(self)
		self:StartMoving()
	end)
	frame:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
	end)

	-- Title
	frame:SetTitle(L.WIZARD_TITLE)

	-- Close button
	if frame.CloseButton then
		frame.CloseButton:SetScript("OnClick", function()
			frame:Hide()
		end)
	end

	-- Portrait icon
	if frame.PortraitContainer and frame.PortraitContainer.portrait then
		frame.PortraitContainer.portrait:SetTexture("Interface\\AddOns\\BetterFriendlist\\Textures\\PortraitIcon")
	elseif frame.portrait then
		frame.portrait:SetTexture("Interface\\AddOns\\BetterFriendlist\\Textures\\PortraitIcon")
	end

	-- ========================================
	-- Description
	-- ========================================
	local descText = frame:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontHighlightSmall")
	descText:SetPoint("TOPLEFT", frame, "TOPLEFT", 70, -32)
	descText:SetPoint("RIGHT", frame, "RIGHT", -30, 0)
	descText:SetJustifyH("LEFT")
	descText:SetWordWrap(true)
	descText:SetText(L.WIZARD_DESC)

	-- ========================================
	-- Top Bar: Search + Buttons
	-- ========================================
	local topBar = CreateFrame("Frame", nil, frame)
	topBar:SetHeight(30)
	topBar:SetPoint("TOPLEFT", frame.Inset or frame, "TOPLEFT", 8, -8)
	topBar:SetPoint("TOPRIGHT", frame.Inset or frame, "TOPRIGHT", -8, -8)

	-- Search box
	local searchBox = CreateFrame("EditBox", nil, topBar, "SearchBoxTemplate")
	searchBox:SetSize(200, 22)
	searchBox:SetPoint("LEFT", topBar, "LEFT", 4, 0)
	searchBox:SetAutoFocus(false)

	if searchBox.Instructions then
		searchBox.Instructions:SetText(L.WIZARD_SEARCH_PLACEHOLDER)
	end

	searchBox:SetScript("OnTextChanged", function(self, userInput)
		if SearchBoxTemplate_OnTextChanged then
			SearchBoxTemplate_OnTextChanged(self)
		end
		searchText = self:GetText() or ""
		NoteCleanupWizard:ApplyFilter()
	end)

	-- Backup button
	local backupBtn = CreateFrame("Button", nil, topBar, "UIPanelButtonTemplate")
	backupBtn:SetSize(140, 24)
	backupBtn:SetText(L.WIZARD_BACKUP_BTN)
	backupBtn:SetPoint("RIGHT", topBar, "RIGHT", 0, 0)
	if backupBtn.SetNormalFontObject then
		backupBtn:SetNormalFontObject("BetterFriendlistFontNormal")
	end

	backupBtn:SetScript("OnClick", function()
		NoteCleanupWizard:BackupNotes()
		-- Visual feedback
		backupBtn:SetText("|cff00ff00" .. L.WIZARD_BACKUP_DONE .. "|r")
		C_Timer.After(2, function()
			if backupBtn and backupBtn:IsShown() then
				backupBtn:SetText(L.WIZARD_BACKUP_BTN)
			end
		end)
	end)

	backupBtn:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(L.WIZARD_BACKUP_BTN, 1, 1, 1)
		GameTooltip:AddLine(L.WIZARD_BACKUP_TOOLTIP, 1, 1, 1, true)
		GameTooltip:Show()
	end)
	backupBtn:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	-- View Backup button
	local viewBackupBtn = CreateFrame("Button", nil, topBar, "UIPanelButtonTemplate")
	viewBackupBtn:SetSize(140, 24)
	viewBackupBtn:SetText(L.WIZARD_VIEW_BACKUP_BTN)
	viewBackupBtn:SetPoint("RIGHT", backupBtn, "LEFT", -8, 0)
	if viewBackupBtn.SetNormalFontObject then
		viewBackupBtn:SetNormalFontObject("BetterFriendlistFontNormal")
	end

	viewBackupBtn:SetScript("OnClick", function()
		NoteCleanupWizard:ShowBackupViewer()
	end)

	viewBackupBtn:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(L.WIZARD_VIEW_BACKUP_BTN, 1, 1, 1)
		GameTooltip:AddLine(L.WIZARD_VIEW_BACKUP_TOOLTIP, 1, 1, 1, true)
		GameTooltip:Show()
	end)
	viewBackupBtn:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	-- Apply button
	local applyBtn = CreateFrame("Button", nil, topBar, "UIPanelButtonTemplate")
	applyBtn:SetSize(140, 24)
	applyBtn:SetText(L.WIZARD_APPLY_BTN)
	applyBtn:SetPoint("RIGHT", viewBackupBtn, "LEFT", -8, 0)
	if applyBtn.SetNormalFontObject then
		applyBtn:SetNormalFontObject("BetterFriendlistFontNormal")
	end

	applyBtn:SetScript("OnClick", function()
		-- Show confirmation dialog
		StaticPopupDialogs["BETTERFRIENDLIST_NOTE_CLEANUP_CONFIRM"] = {
			text = L.WIZARD_APPLY_CONFIRM,
			button1 = L.WIZARD_APPLY_BTN,
			button2 = L.BUTTON_CANCEL or "Cancel",
			OnAccept = function()
				NoteCleanupWizard:ApplyCleanedNotes()
			end,
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
			preferredIndex = 3,
		}
		StaticPopup_Show("BETTERFRIENDLIST_NOTE_CLEANUP_CONFIRM")
	end)

	applyBtn:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(L.WIZARD_APPLY_BTN, 1, 1, 1)
		GameTooltip:AddLine(L.WIZARD_APPLY_TOOLTIP, 1, 1, 1, true)
		GameTooltip:Show()
	end)
	applyBtn:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	-- ========================================
	-- Column Headers
	-- ========================================
	local headerBar = CreateFrame("Frame", nil, frame)
	headerBar:SetHeight(HEADER_HEIGHT)
	headerBar:SetPoint("TOPLEFT", topBar, "BOTTOMLEFT", 0, -4)
	headerBar:SetPoint("TOPRIGHT", topBar, "BOTTOMRIGHT", 0, -4)

	headerBar.bg = headerBar:CreateTexture(nil, "BACKGROUND")
	headerBar.bg:SetAllPoints()
	headerBar.bg:SetColorTexture(0.2, 0.2, 0.2, 0.8)

	local headerWidth = WIZARD_WIDTH - 40 - SCROLL_BAR_WIDTH
	local availHeaderWidth = headerWidth - STATUS_COL_WIDTH
	local colW1 = math.floor(availHeaderWidth * COL_ACCOUNT)
	local colW2 = math.floor(availHeaderWidth * COL_BATTLETAG)
	local colW3 = math.floor(availHeaderWidth * COL_NOTE)

	local h1 = headerBar:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontNormal")
	h1:SetPoint("LEFT", headerBar, "LEFT", STATUS_COL_WIDTH + COLUMN_PADDING, 0)
	h1:SetText(L.WIZARD_COL_ACCOUNT)
	h1:SetJustifyH("LEFT")

	local h2 = headerBar:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontNormal")
	h2:SetPoint("LEFT", headerBar, "LEFT", STATUS_COL_WIDTH + colW1 + COLUMN_PADDING, 0)
	h2:SetText(L.WIZARD_COL_BATTLETAG)
	h2:SetJustifyH("LEFT")

	local h3 = headerBar:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontNormal")
	h3:SetPoint("LEFT", headerBar, "LEFT", STATUS_COL_WIDTH + colW1 + colW2 + COLUMN_PADDING, 0)
	h3:SetText(L.WIZARD_COL_NOTE)
	h3:SetJustifyH("LEFT")

	local h4 = headerBar:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontNormal")
	h4:SetPoint("LEFT", headerBar, "LEFT", STATUS_COL_WIDTH + colW1 + colW2 + colW3 + COLUMN_PADDING, 0)
	h4:SetText(L.WIZARD_COL_CLEANED)
	h4:SetJustifyH("LEFT")

	-- ========================================
	-- Scroll Frame for the table
	-- ========================================
	local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
	scrollFrame:SetPoint("TOPLEFT", headerBar, "BOTTOMLEFT", 0, -2)
	scrollFrame:SetPoint("BOTTOMRIGHT", frame.Inset or frame, "BOTTOMRIGHT", -SCROLL_BAR_WIDTH - 8, 36)

	local scrollChild = CreateFrame("Frame", nil, scrollFrame)
	scrollChild:SetWidth(scrollFrame:GetWidth() or (WIZARD_WIDTH - 40 - SCROLL_BAR_WIDTH))
	scrollChild:SetHeight(1) -- Will be updated dynamically
	scrollFrame:SetScrollChild(scrollChild)

	frame.scrollChild = scrollChild
	frame.scrollFrame = scrollFrame

	-- Update scrollChild width when frame resizes
	scrollFrame:SetScript("OnSizeChanged", function(self, width, height)
		scrollChild:SetWidth(width)
		NoteCleanupWizard:RefreshRows()
	end)

	-- ========================================
	-- Bottom Bar: Status
	-- ========================================
	local bottomBar = CreateFrame("Frame", nil, frame)
	bottomBar:SetHeight(28)
	bottomBar:SetPoint("BOTTOMLEFT", frame.Inset or frame, "BOTTOMLEFT", 8, 4)
	bottomBar:SetPoint("BOTTOMRIGHT", frame.Inset or frame, "BOTTOMRIGHT", -8, 4)

	local countLabel = bottomBar:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontHighlightSmall")
	countLabel:SetPoint("LEFT", bottomBar, "LEFT", 4, 0)
	countLabel:SetJustifyH("LEFT")
	frame.countLabel = countLabel

	wizardFrame = frame
	frame:Hide()

	return frame
end

-- ========================================
-- Get backup data as sorted array
-- ========================================
function NoteCleanupWizard:GetBackupData()
	local data = {}
	if not BetterFriendlistDB or not BetterFriendlistDB.noteBackup then
		return data
	end

	for key, entry in pairs(BetterFriendlistDB.noteBackup) do
		-- Try to find current note for this friend
		local currentNote = ""
		if entry.isBNet and entry.battleTag and entry.battleTag ~= "" then
			local numBNetFriends = BNGetNumFriends()
			for i = 1, numBNetFriends do
				local accountInfo = C_BattleNet.GetFriendAccountInfo(i)
				if accountInfo and accountInfo.battleTag == entry.battleTag then
					currentNote = accountInfo.note or ""
					break
				end
			end
		elseif not entry.isBNet then
			if C_FriendList and C_FriendList.GetNumFriends then
				local numWoWFriends = C_FriendList.GetNumFriends()
				for i = 1, numWoWFriends do
					local friendInfo = C_FriendList.GetFriendInfoByIndex(i)
					if friendInfo and friendInfo.name == key then
						currentNote = friendInfo.notes or ""
						break
					end
				end
			end
		end

		table.insert(data, {
			key = key,
			accountName = entry.accountName or "",
			battleTag = entry.battleTag or "",
			backedUpNote = entry.originalNote or "",
			currentNote = currentNote,
			isBNet = entry.isBNet,
			timestamp = entry.timestamp or 0,
			noteChanged = currentNote ~= (entry.originalNote or ""),
		})
	end

	-- Sort alphabetically by account name
	table.sort(data, function(a, b)
		return a.accountName:lower() < b.accountName:lower()
	end)

	return data
end

-- ========================================
-- Apply backup filter
-- ========================================
function NoteCleanupWizard:ApplyBackupFilter()
	local allData = self:GetBackupData()
	backupFilteredData = {}
	local query = backupSearchText:lower()

	for _, entry in ipairs(allData) do
		if query == "" then
			table.insert(backupFilteredData, entry)
		else
			local displayName = GetStreamerSafeAccountName(entry)
			local matchName = displayName:lower():find(query, 1, true)
			local matchTag = entry.battleTag:lower():find(query, 1, true)
			local matchBackup = entry.backedUpNote:lower():find(query, 1, true)
			local matchCurrent = entry.currentNote:lower():find(query, 1, true)
			if matchName or matchTag or matchBackup or matchCurrent then
				table.insert(backupFilteredData, entry)
			end
		end
	end

	self:RefreshBackupRows()
end

-- ========================================
-- Restore notes from backup (sequential with status icons)
-- ========================================
function NoteCleanupWizard:RestoreBackup()
	if isRestoring then
		return
	end

	if not BetterFriendlistDB or not BetterFriendlistDB.noteBackup then
		return
	end

	-- Collect entries that need restoring and mark as pending
	local toRestore = {}
	for _, data in ipairs(backupFilteredData) do
		if data.noteChanged then
			data.status = "pending"
			table.insert(toRestore, data)
		else
			data.status = nil
		end
	end

	if #toRestore == 0 then
		self:RefreshBackupRows()
		return
	end

	isRestoring = true
	self:RefreshBackupRows()

	local currentIndex = 0
	local successCount = 0
	local errorCount = 0

	local function ProcessNext()
		if not isRestoring then
			return
		end

		currentIndex = currentIndex + 1
		if currentIndex > #toRestore then
			isRestoring = false
			NoteCleanupWizard:RefreshBackupRows()
			BFL:DebugPrint("|cff00ff00BetterFriendlist:|r " .. string.format(L.WIZARD_RESTORE_SUCCESS, successCount))
			-- Refresh main wizard if open
			C_Timer.After(0.3, function()
				if wizardFrame and wizardFrame:IsShown() then
					NoteCleanupWizard:ScanFriends()
				end
			end)
			return
		end

		local data = toRestore[currentIndex]
		local backupEntry = BetterFriendlistDB.noteBackup[data.key]
		local success, err = pcall(function()
			if data.isBNet and data.battleTag and data.battleTag ~= "" then
				local numBNetFriends = BNGetNumFriends()
				for i = 1, numBNetFriends do
					local accountInfo = C_BattleNet.GetFriendAccountInfo(i)
					if accountInfo and accountInfo.battleTag == data.battleTag then
						BNSetFriendNote(accountInfo.bnetAccountID, data.backedUpNote or "")
						break
					end
				end
			elseif not data.isBNet then
				C_FriendList.SetFriendNotes(data.key, data.backedUpNote or "")
			end
		end)

		if success then
			data.status = "success"
			data.currentNote = data.backedUpNote
			data.noteChanged = false
			successCount = successCount + 1
		else
			data.status = "error"
			errorCount = errorCount + 1
			BFL:DebugPrint(
				"|cffff0000BetterFriendlist:|r Error: " .. (data.accountName or "?") .. " - " .. tostring(err)
			)
		end

		NoteCleanupWizard:RefreshBackupRows()
		C_Timer.After(0.05, ProcessNext)
	end

	-- Start processing after brief delay to show pending state
	C_Timer.After(0.1, ProcessNext)
end

-- ========================================
-- Create a single backup viewer row
-- ========================================
local function CreateBackupRow(parent)
	local row = CreateFrame("Frame", nil, parent)
	row:SetHeight(ROW_HEIGHT)

	row.bg = row:CreateTexture(nil, "BACKGROUND")
	row.bg:SetAllPoints()

	-- Status icon (pending/success/error)
	row.statusIcon = row:CreateTexture(nil, "ARTWORK")
	row.statusIcon:SetSize(16, 16)
	row.statusIcon:Hide()

	-- Account Name column
	row.accountName = row:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontHighlightSmall")
	row.accountName:SetJustifyH("LEFT")
	row.accountName:SetWordWrap(false)

	-- BattleTag column
	row.battleTag = row:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontHighlightSmall")
	row.battleTag:SetJustifyH("LEFT")
	row.battleTag:SetWordWrap(false)

	-- Backed Up Note column
	row.backedUpNote = row:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontHighlightSmall")
	row.backedUpNote:SetJustifyH("LEFT")
	row.backedUpNote:SetWordWrap(false)

	-- Current Note column
	row.currentNote = row:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontHighlightSmall")
	row.currentNote:SetJustifyH("LEFT")
	row.currentNote:SetWordWrap(false)

	return row
end

-- Column widths for backup viewer
local BCOL_ACCOUNT = 0.20
local BCOL_BATTLETAG = 0.20
local BCOL_BACKUP = 0.30
local BCOL_CURRENT = 0.30

-- ========================================
-- Layout a backup viewer row
-- ========================================
local function LayoutBackupRow(row, contentWidth)
	local availWidth = contentWidth - STATUS_COL_WIDTH
	local colW1 = math.floor(availWidth * BCOL_ACCOUNT)
	local colW2 = math.floor(availWidth * BCOL_BATTLETAG)
	local colW3 = math.floor(availWidth * BCOL_BACKUP)

	-- Status icon at far left
	row.statusIcon:ClearAllPoints()
	row.statusIcon:SetPoint("LEFT", row, "LEFT", (STATUS_COL_WIDTH - 16) / 2, 0)

	local offset = STATUS_COL_WIDTH

	row.accountName:ClearAllPoints()
	row.accountName:SetPoint("LEFT", row, "LEFT", offset + COLUMN_PADDING, 0)
	row.accountName:SetWidth(colW1 - COLUMN_PADDING * 2)

	row.battleTag:ClearAllPoints()
	row.battleTag:SetPoint("LEFT", row, "LEFT", offset + colW1 + COLUMN_PADDING, 0)
	row.battleTag:SetWidth(colW2 - COLUMN_PADDING * 2)

	row.backedUpNote:ClearAllPoints()
	row.backedUpNote:SetPoint("LEFT", row, "LEFT", offset + colW1 + colW2 + COLUMN_PADDING, 0)
	row.backedUpNote:SetWidth(colW3 - COLUMN_PADDING * 2)

	row.currentNote:ClearAllPoints()
	row.currentNote:SetPoint("LEFT", row, "LEFT", offset + colW1 + colW2 + colW3 + COLUMN_PADDING, 0)
	row.currentNote:SetPoint("RIGHT", row, "RIGHT", -COLUMN_PADDING, 0)
end

-- ========================================
-- Refresh backup viewer rows
-- ========================================
function NoteCleanupWizard:RefreshBackupRows()
	if not backupViewerFrame then
		return
	end

	local scrollChild = backupViewerFrame.scrollChild
	if not scrollChild then
		return
	end

	local contentWidth = scrollChild:GetWidth()

	-- Hide all existing rows
	for _, row in ipairs(backupRowFrames) do
		row:Hide()
	end

	-- Create/reuse rows for filtered data
	for i, data in ipairs(backupFilteredData) do
		local row = backupRowFrames[i]
		if not row then
			row = CreateBackupRow(scrollChild)
			backupRowFrames[i] = row
		end

		-- Position
		row:ClearAllPoints()
		row:SetPoint("LEFT", scrollChild, "LEFT", 0, 0)
		row:SetPoint("RIGHT", scrollChild, "RIGHT", 0, 0)

		if i == 1 then
			row:SetPoint("TOP", scrollChild, "TOP", 0, 0)
		else
			row:SetPoint("TOP", backupRowFrames[i - 1], "BOTTOM", 0, 0)
		end

		-- Background color based on status (traffic light system)
		if data.status == "success" then
			if i % 2 == 0 then
				row.bg:SetColorTexture(0.05, 0.25, 0.05, 0.6)
			else
				row.bg:SetColorTexture(0.04, 0.20, 0.04, 0.4)
			end
		elseif data.status == "error" then
			if i % 2 == 0 then
				row.bg:SetColorTexture(0.30, 0.05, 0.05, 0.6)
			else
				row.bg:SetColorTexture(0.25, 0.04, 0.04, 0.4)
			end
		elseif data.status == "pending" then
			if i % 2 == 0 then
				row.bg:SetColorTexture(0.30, 0.25, 0.05, 0.6)
			else
				row.bg:SetColorTexture(0.25, 0.20, 0.04, 0.4)
			end
		elseif data.noteChanged then
			if i % 2 == 0 then
				row.bg:SetColorTexture(0.1, 0.2, 0.1, 0.5)
			else
				row.bg:SetColorTexture(0.08, 0.18, 0.08, 0.3)
			end
		else
			if i % 2 == 0 then
				row.bg:SetColorTexture(0.15, 0.15, 0.15, 0.5)
			else
				row.bg:SetColorTexture(0.1, 0.1, 0.1, 0.3)
			end
		end

		-- Status icon
		if data.status == "pending" then
			row.statusIcon:SetTexture("Interface\\RaidFrame\\ReadyCheck-Waiting")
			row.statusIcon:Show()
		elseif data.status == "success" then
			row.statusIcon:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
			row.statusIcon:Show()
		elseif data.status == "error" then
			row.statusIcon:SetTexture("Interface\\RaidFrame\\ReadyCheck-NotReady")
			row.statusIcon:Show()
		else
			row.statusIcon:Hide()
		end

		LayoutBackupRow(row, contentWidth)

		-- Set data (respect Streamer Mode for account names)
		row.accountName:SetText(GetStreamerSafeAccountName(data))
		row.battleTag:SetText(data.battleTag)
		row.backedUpNote:SetText(data.backedUpNote)

		-- Highlight current note differently if it differs from backup
		if data.noteChanged then
			row.currentNote:SetText("|cffff8800" .. data.currentNote .. "|r")
		else
			row.currentNote:SetText(data.currentNote)
		end

		row:Show()
	end

	-- Update scroll child height
	local totalHeight = #backupFilteredData * ROW_HEIGHT
	scrollChild:SetHeight(math.max(totalHeight, 1))

	-- Update count label
	if backupViewerFrame.countLabel then
		local totalChanged = 0
		local allData = self:GetBackupData()
		for _, entry in ipairs(allData) do
			if entry.noteChanged then
				totalChanged = totalChanged + 1
			end
		end

		-- Format the timestamp from most recent backup entry
		local latestTimestamp = 0
		if BetterFriendlistDB and BetterFriendlistDB.noteBackup then
			for _, entry in pairs(BetterFriendlistDB.noteBackup) do
				if entry.timestamp and entry.timestamp > latestTimestamp then
					latestTimestamp = entry.timestamp
				end
			end
		end

		local timeStr = ""
		if latestTimestamp > 0 then
			timeStr = date("%Y-%m-%d %H:%M", latestTimestamp)
		end

		-- Check if restore progress should be shown
		local pendingCount = 0
		local sCount = 0
		local eCount = 0
		for _, entry in ipairs(backupFilteredData) do
			if entry.status == "pending" then
				pendingCount = pendingCount + 1
			elseif entry.status == "success" then
				sCount = sCount + 1
			elseif entry.status == "error" then
				eCount = eCount + 1
			end
		end

		local totalStatusCount = pendingCount + sCount + eCount

		if totalStatusCount > 0 then
			backupViewerFrame.countLabel:SetText(
				string.format(L.WIZARD_APPLY_PROGRESS_FMT, sCount + eCount, totalStatusCount, sCount, eCount)
			)
		else
			backupViewerFrame.countLabel:SetText(
				string.format(L.WIZARD_BACKUP_STATUS_FMT, #backupFilteredData, #allData, totalChanged, timeStr)
			)
		end
	end
end

-- ========================================
-- Create the Backup Viewer Frame
-- ========================================
function NoteCleanupWizard:CreateBackupViewerFrame()
	if backupViewerFrame then
		return backupViewerFrame
	end

	local frame = CreateFrame("Frame", "BetterFriendlistNoteBackupViewer", UIParent, "ButtonFrameTemplate")
	frame:SetSize(WIZARD_WIDTH, WIZARD_HEIGHT)
	frame:SetPoint("CENTER")
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:SetClampedToScreen(true)
	frame:SetFrameStrata("DIALOG")
	frame:SetToplevel(true)

	-- Allow dragging
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", function(self)
		self:StartMoving()
	end)
	frame:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
	end)

	-- Title
	frame:SetTitle(L.WIZARD_BACKUP_VIEWER_TITLE)

	-- Close button
	if frame.CloseButton then
		frame.CloseButton:SetScript("OnClick", function()
			frame:Hide()
		end)
	end

	-- Portrait icon
	if frame.PortraitContainer and frame.PortraitContainer.portrait then
		frame.PortraitContainer.portrait:SetTexture("Interface\\AddOns\\BetterFriendlist\\Textures\\PortraitIcon")
	elseif frame.portrait then
		frame.portrait:SetTexture("Interface\\AddOns\\BetterFriendlist\\Textures\\PortraitIcon")
	end

	-- ========================================
	-- Description
	-- ========================================
	local descText = frame:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontHighlightSmall")
	descText:SetPoint("TOPLEFT", frame, "TOPLEFT", 70, -32)
	descText:SetPoint("RIGHT", frame, "RIGHT", -30, 0)
	descText:SetJustifyH("LEFT")
	descText:SetWordWrap(true)
	descText:SetText(L.WIZARD_BACKUP_VIEWER_DESC)

	-- ========================================
	-- Top Bar: Search + Restore Button
	-- ========================================
	local topBar = CreateFrame("Frame", nil, frame)
	topBar:SetHeight(30)
	topBar:SetPoint("TOPLEFT", frame.Inset or frame, "TOPLEFT", 8, -8)
	topBar:SetPoint("TOPRIGHT", frame.Inset or frame, "TOPRIGHT", -8, -8)

	-- Search box
	local searchBox = CreateFrame("EditBox", nil, topBar, "SearchBoxTemplate")
	searchBox:SetSize(200, 22)
	searchBox:SetPoint("LEFT", topBar, "LEFT", 4, 0)
	searchBox:SetAutoFocus(false)

	if searchBox.Instructions then
		searchBox.Instructions:SetText(L.WIZARD_SEARCH_PLACEHOLDER)
	end

	searchBox:SetScript("OnTextChanged", function(self, userInput)
		if SearchBoxTemplate_OnTextChanged then
			SearchBoxTemplate_OnTextChanged(self)
		end
		backupSearchText = self:GetText() or ""
		NoteCleanupWizard:ApplyBackupFilter()
	end)

	-- Backup button (create new backup from Backup Viewer)
	local backupBtn = CreateFrame("Button", nil, topBar, "UIPanelButtonTemplate")
	backupBtn:SetSize(140, 24)
	backupBtn:SetText(L.WIZARD_BACKUP_BTN)
	backupBtn:SetPoint("RIGHT", topBar, "RIGHT", 0, 0)
	if backupBtn.SetNormalFontObject then
		backupBtn:SetNormalFontObject("BetterFriendlistFontNormal")
	end

	backupBtn:SetScript("OnClick", function()
		-- Need to scan friends first to have data for backup
		NoteCleanupWizard:ScanFriends()
		NoteCleanupWizard:BackupNotes()
		-- Visual feedback
		backupBtn:SetText("|cff00ff00" .. L.WIZARD_BACKUP_DONE .. "|r")
		C_Timer.After(2, function()
			if backupBtn and backupBtn:IsShown() then
				backupBtn:SetText(L.WIZARD_BACKUP_BTN)
			end
		end)
		-- Refresh backup viewer to show updated data
		C_Timer.After(0.5, function()
			if backupViewerFrame and backupViewerFrame:IsShown() then
				NoteCleanupWizard:ApplyBackupFilter()
			end
		end)
	end)

	backupBtn:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(L.WIZARD_BACKUP_BTN, 1, 1, 1)
		GameTooltip:AddLine(L.WIZARD_BACKUP_TOOLTIP, 1, 1, 1, true)
		GameTooltip:Show()
	end)
	backupBtn:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	-- Restore button
	local restoreBtn = CreateFrame("Button", nil, topBar, "UIPanelButtonTemplate")
	restoreBtn:SetSize(160, 24)
	restoreBtn:SetText(L.WIZARD_RESTORE_BTN)
	restoreBtn:SetPoint("RIGHT", backupBtn, "LEFT", -8, 0)
	if restoreBtn.SetNormalFontObject then
		restoreBtn:SetNormalFontObject("BetterFriendlistFontNormal")
	end

	restoreBtn:SetScript("OnClick", function()
		StaticPopupDialogs["BETTERFRIENDLIST_NOTE_RESTORE_CONFIRM"] = {
			text = L.WIZARD_RESTORE_CONFIRM,
			button1 = L.WIZARD_RESTORE_BTN,
			button2 = L.BUTTON_CANCEL or "Cancel",
			OnAccept = function()
				NoteCleanupWizard:RestoreBackup()
			end,
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
			preferredIndex = 3,
		}
		StaticPopup_Show("BETTERFRIENDLIST_NOTE_RESTORE_CONFIRM")
	end)

	restoreBtn:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(L.WIZARD_RESTORE_BTN, 1, 1, 1)
		GameTooltip:AddLine(L.WIZARD_RESTORE_TOOLTIP, 1, 1, 1, true)
		GameTooltip:Show()
	end)
	restoreBtn:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	-- ========================================
	-- Column Headers
	-- ========================================
	local headerBar = CreateFrame("Frame", nil, frame)
	headerBar:SetHeight(HEADER_HEIGHT)
	headerBar:SetPoint("TOPLEFT", topBar, "BOTTOMLEFT", 0, -4)
	headerBar:SetPoint("TOPRIGHT", topBar, "BOTTOMRIGHT", 0, -4)

	headerBar.bg = headerBar:CreateTexture(nil, "BACKGROUND")
	headerBar.bg:SetAllPoints()
	headerBar.bg:SetColorTexture(0.2, 0.2, 0.2, 0.8)

	local headerWidth = WIZARD_WIDTH - 40 - SCROLL_BAR_WIDTH
	local availHeaderWidth = headerWidth - STATUS_COL_WIDTH
	local colW1 = math.floor(availHeaderWidth * BCOL_ACCOUNT)
	local colW2 = math.floor(availHeaderWidth * BCOL_BATTLETAG)
	local colW3 = math.floor(availHeaderWidth * BCOL_BACKUP)

	local h1 = headerBar:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontNormal")
	h1:SetPoint("LEFT", headerBar, "LEFT", STATUS_COL_WIDTH + COLUMN_PADDING, 0)
	h1:SetText(L.WIZARD_COL_ACCOUNT)
	h1:SetJustifyH("LEFT")

	local h2 = headerBar:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontNormal")
	h2:SetPoint("LEFT", headerBar, "LEFT", STATUS_COL_WIDTH + colW1 + COLUMN_PADDING, 0)
	h2:SetText(L.WIZARD_COL_BATTLETAG)
	h2:SetJustifyH("LEFT")

	local h3 = headerBar:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontNormal")
	h3:SetPoint("LEFT", headerBar, "LEFT", STATUS_COL_WIDTH + colW1 + colW2 + COLUMN_PADDING, 0)
	h3:SetText(L.WIZARD_COL_BACKED_UP)
	h3:SetJustifyH("LEFT")

	local h4 = headerBar:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontNormal")
	h4:SetPoint("LEFT", headerBar, "LEFT", STATUS_COL_WIDTH + colW1 + colW2 + colW3 + COLUMN_PADDING, 0)
	h4:SetText(L.WIZARD_COL_CURRENT)
	h4:SetJustifyH("LEFT")

	-- ========================================
	-- Scroll Frame
	-- ========================================
	local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
	scrollFrame:SetPoint("TOPLEFT", headerBar, "BOTTOMLEFT", 0, -2)
	scrollFrame:SetPoint("BOTTOMRIGHT", frame.Inset or frame, "BOTTOMRIGHT", -SCROLL_BAR_WIDTH - 8, 36)

	local scrollChild = CreateFrame("Frame", nil, scrollFrame)
	scrollChild:SetWidth(scrollFrame:GetWidth() or (WIZARD_WIDTH - 40 - SCROLL_BAR_WIDTH))
	scrollChild:SetHeight(1)
	scrollFrame:SetScrollChild(scrollChild)

	frame.scrollChild = scrollChild
	frame.scrollFrame = scrollFrame

	scrollFrame:SetScript("OnSizeChanged", function(self, width, height)
		scrollChild:SetWidth(width)
		NoteCleanupWizard:RefreshBackupRows()
	end)

	-- ========================================
	-- Bottom Bar: Status
	-- ========================================
	local bottomBar = CreateFrame("Frame", nil, frame)
	bottomBar:SetHeight(28)
	bottomBar:SetPoint("BOTTOMLEFT", frame.Inset or frame, "BOTTOMLEFT", 8, 4)
	bottomBar:SetPoint("BOTTOMRIGHT", frame.Inset or frame, "BOTTOMRIGHT", -8, 4)

	local countLabel = bottomBar:CreateFontString(nil, "ARTWORK", "BetterFriendlistFontHighlightSmall")
	countLabel:SetPoint("LEFT", bottomBar, "LEFT", 4, 0)
	countLabel:SetJustifyH("LEFT")
	frame.countLabel = countLabel

	backupViewerFrame = frame
	frame:Hide()

	return frame
end

-- ========================================
-- Show the Backup Viewer
-- ========================================
function NoteCleanupWizard:ShowBackupViewer()
	if not BetterFriendlistDB or not BetterFriendlistDB.noteBackup or not next(BetterFriendlistDB.noteBackup) then
		-- No backup available - show message
		StaticPopupDialogs["BETTERFRIENDLIST_NO_BACKUP"] = {
			text = L.WIZARD_NO_BACKUP,
			button1 = OKAY or "OK",
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
			preferredIndex = 3,
		}
		StaticPopup_Show("BETTERFRIENDLIST_NO_BACKUP")
		return
	end

	local frame = self:CreateBackupViewerFrame()
	self:ApplyBackupFilter()
	frame:Show()
end

-- ========================================
-- Show the Wizard
-- ========================================
function NoteCleanupWizard:Show()
	local frame = self:CreateWizardFrame()
	self:ScanFriends()
	frame:Show()
end

-- ========================================
-- Hide the Wizard
-- ========================================
function NoteCleanupWizard:Hide()
	if wizardFrame then
		wizardFrame:Hide()
	end
end
