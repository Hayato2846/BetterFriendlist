--------------------------------------------------------------------------------
---- BFL_QTip TooltipManager (forked from LibQTip-2.0)
--------------------------------------------------------------------------------

local ADDON_NAME, BFL = ...
local QTip = BFL.QTip

local ScriptManager = QTip.ScriptManager

local TooltipManager = QTip.TooltipManager

TooltipManager.ActiveReleases = TooltipManager.ActiveReleases or {}
TooltipManager.ActiveTooltips = TooltipManager.ActiveTooltips or {}
TooltipManager.ColumnHeap = TooltipManager.ColumnHeap or {}
TooltipManager.ColumnPrototype = TooltipManager.ColumnPrototype or setmetatable({}, QTip.FrameMetatable)
TooltipManager.ColumnMetatable = TooltipManager.ColumnMetatable or { __index = TooltipManager.ColumnPrototype }
TooltipManager.LayoutRegistry = TooltipManager.LayoutRegistry or {}
TooltipManager.RowHeap = TooltipManager.RowHeap or {}
TooltipManager.RowPrototype = TooltipManager.RowPrototype or setmetatable({}, QTip.FrameMetatable)
TooltipManager.RowMetatable = TooltipManager.RowMetatable or { __index = TooltipManager.RowPrototype }
TooltipManager.TableHeap = TooltipManager.TableHeap or {}
TooltipManager.TimerHeap = TooltipManager.TimerHeap or {}
TooltipManager.TooltipHeap = TooltipManager.TooltipHeap or {}
TooltipManager.TooltipPrototype = TooltipManager.TooltipPrototype or setmetatable({}, QTip.FrameMetatable)
TooltipManager.TooltipMetatable = TooltipManager.TooltipMetatable or { __index = TooltipManager.TooltipPrototype }

TooltipManager.DefaultBackdrop = TooltipManager.DefaultBackdrop
	or {
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
	}

TooltipManager.DefaultHighlightTexturePath = [[Interface\QuestFrame\UI-QuestTitleHighlight]]

local PixelSize = {
	CellPadding = 10,
	HorizontalCellMargin = 6,
	VerticalCellMargin = 3,
}

TooltipManager.PixelSize = TooltipManager.PixelSize or PixelSize

--------------------------------------------------------------------------------
---- Methods
--------------------------------------------------------------------------------

function TooltipManager:AcquireCell(tooltip, row, column, cellProvider)
	local cell = cellProvider:AcquireCell()

	cell.ColumnIndex = column.Index
	cell.RowIndex = row.Index
	cell.Tooltip = tooltip

	cell:SetParent(tooltip.ScrollChild)
	cell:SetFrameLevel(tooltip.ScrollChild:GetFrameLevel() + 3)
	cell:SetPoint("LEFT", column)
	cell:SetPoint("RIGHT", tooltip.Columns[cell.ColumnIndex + cell.ColSpan - 1])
	cell:SetPoint("TOP", row)
	cell:SetPoint("BOTTOM", row)
	cell:SetJustifyH(column.HorizontalJustification)
	cell:Show()

	column.Cells[row.Index] = cell
	row.Cells[column.Index] = cell

	cell.FontString:SetFontObject(
		cell.Tooltip:GetRow(cell.RowIndex).IsHeading and cell.Tooltip:GetDefaultHeadingFont()
			or cell.Tooltip:GetDefaultFont()
	)

	return cell
end

function TooltipManager:AcquireColumn(tooltip, columnIndex, horizontalJustification)
	local column = tremove(self.ColumnHeap)

	if not column then
		column = setmetatable(CreateFrame("Frame", nil, nil, "BackdropTemplate"), self.ColumnMetatable)
	end

	local scrollChild = tooltip.ScrollChild

	column:SetParent(scrollChild)
	column:SetFrameLevel(scrollChild:GetFrameLevel() + 1)
	column:SetWidth(1)
	column:SetPoint("TOP", scrollChild)
	column:SetPoint("BOTTOM", scrollChild)

	if columnIndex > 1 then
		local horizontalMargin = tooltip.HorizontalCellMargin or TooltipManager.PixelSize.HorizontalCellMargin

		column:SetPoint("LEFT", tooltip.Columns[columnIndex - 1], "RIGHT", horizontalMargin, 0)
		TooltipManager:SetTooltipSize(tooltip, tooltip.Width + horizontalMargin, tooltip.Height)
	else
		column:SetPoint("LEFT", tooltip.ScrollChild)
	end

	column.Cells = column.Cells or {}
	column.HorizontalJustification = horizontalJustification
	column.Index = columnIndex
	column.Tooltip = tooltip
	column.Width = 0

	column:Show()

	return column
end

function TooltipManager:AcquireRow(tooltip, rowIndex)
	local row = tremove(self.RowHeap)

	if not row then
		row = setmetatable(CreateFrame("Frame", nil, nil, "BackdropTemplate"), self.RowMetatable)
	end

	row:SetParent(tooltip.ScrollChild)
	row:SetFrameLevel(tooltip.ScrollChild:GetFrameLevel() + 2)
	row:SetHeight(1)
	row:SetPoint("LEFT", tooltip.ScrollChild)
	row:SetPoint("RIGHT", tooltip.ScrollChild)

	if rowIndex > 1 then
		local verticalMargin = tooltip.VerticalCellMargin or TooltipManager.PixelSize.VerticalCellMargin

		row:SetPoint("TOP", tooltip.Rows[rowIndex - 1], "BOTTOM", 0, -verticalMargin)
		TooltipManager:SetTooltipSize(tooltip, tooltip.Width, tooltip.Height + verticalMargin)
	else
		row:SetPoint("TOP", tooltip.ScrollChild)
	end

	row:Show()

	row.Cells = row.Cells or {}
	row.ColSpanCells = row.ColSpanCells or {}
	row.Height = 0
	row.Index = rowIndex
	row.Tooltip = tooltip

	return row
end

function TooltipManager:AcquireTimer(tooltip)
	local timer = tremove(self.TimerHeap) or CreateFrame("Frame")

	timer:SetParent(tooltip)

	return timer
end

function TooltipManager:AcquireTooltip(key)
	local tooltip = tremove(self.TooltipHeap)

	if not tooltip then
		local cellPadding = PixelSize.CellPadding

		tooltip = setmetatable(CreateFrame("Frame", nil, UIParent, "TooltipBackdropTemplate"), self.TooltipMetatable)

		local highlightFrame = CreateFrame("Frame", nil, UIParent)
		highlightFrame:SetFrameStrata("TOOLTIP")
		highlightFrame:Hide()
		tooltip.HighlightFrame = highlightFrame

		local highlightTexture = highlightFrame:CreateTexture(nil, "OVERLAY")
		highlightTexture:SetTexture(self.DefaultHighlightTexturePath)
		highlightTexture:SetBlendMode("ADD")
		highlightTexture:SetAllPoints(highlightFrame)
		tooltip.HighlightTexture = highlightTexture

		local scrollFrame = CreateFrame("ScrollFrame", nil, tooltip)
		scrollFrame:SetPoint("TOP", tooltip, "TOP", 0, -cellPadding)
		scrollFrame:SetPoint("BOTTOM", tooltip, "BOTTOM", 0, cellPadding)
		scrollFrame:SetPoint("LEFT", tooltip, "LEFT", cellPadding, 0)
		scrollFrame:SetPoint("RIGHT", tooltip, "RIGHT", -cellPadding, 0)
		tooltip.ScrollFrame = scrollFrame

		local scrollChild = CreateFrame("Frame", nil, tooltip.ScrollFrame)
		scrollFrame:SetScrollChild(scrollChild)
		tooltip.ScrollChild = scrollChild
	end

	tooltip.ColSpanWidths = tooltip.ColSpanWidths or {}
	tooltip.Columns = tooltip.Columns or {}
	tooltip.DefaultCellProvider = QTip.DefaultCellProvider
	tooltip.DefaultFont = GameTooltipText
	tooltip.DefaultHeadingFont = GameTooltipHeaderText
	tooltip.Height = 0
	tooltip.HorizontalCellMargin = tooltip.HorizontalCellMargin or PixelSize.HorizontalCellMargin
	tooltip.Key = key
	tooltip.Rows = tooltip.Rows or {}
	tooltip.Scripts = tooltip.Scripts or {}
	tooltip.ScrollStep = 10
	tooltip.VerticalCellMargin = tooltip.VerticalCellMargin or PixelSize.VerticalCellMargin
	tooltip.Width = 0

	tooltip.layoutType = GameTooltip.layoutType

	NineSlicePanelMixin.OnLoad(tooltip.NineSlice)

	if GameTooltip.layoutType then
		tooltip.NineSlice:SetCenterColor(GameTooltip.NineSlice:GetCenterColor())
		tooltip.NineSlice:SetBorderColor(GameTooltip.NineSlice:GetBorderColor())
	end

	tooltip:SetAlpha(1)
	tooltip:SetClampedToScreen(false)
	tooltip:SetFrameStrata("TOOLTIP")
	tooltip:SetScale(GameTooltip:GetScale())
	tooltip:SetAutoHideDelay(nil)
	tooltip:Hide()

	self:AdjustTooltipSize(tooltip)

	return tooltip
end

function TooltipManager:AdjustCellSizes(tooltip)
	local colSpanWidths = tooltip.ColSpanWidths
	local columns = tooltip.Columns
	local horizontalMargin = tooltip.HorizontalCellMargin or PixelSize.HorizontalCellMargin

	while next(colSpanWidths) do
		local maxNeedColumns
		local maxNeedWidthPerColumn = 0

		for columnRange, width in pairs(colSpanWidths) do
			local left, right = columnRange:match("^(%d+)%-(%d+)$")

			left = tonumber(left)
			right = tonumber(right)

			for columnIndex = left, right - 1 do
				width = width - columns[columnIndex].Width - horizontalMargin
			end

			width = width - columns[right].Width

			if width <= 0 then
				colSpanWidths[columnRange] = nil
			else
				width = width / (right - left + 1)

				if width > maxNeedWidthPerColumn then
					maxNeedColumns = columnRange
					maxNeedWidthPerColumn = width
				end
			end
		end

		if maxNeedColumns then
			local leftIndex, rightIndex = maxNeedColumns:match("^(%d+)%-(%d+)$")

			for columnIndex = leftIndex, rightIndex do
				local column = columns[columnIndex]

				self:AdjustColumnWidth(column, column.Width + maxNeedWidthPerColumn)
			end

			colSpanWidths[maxNeedColumns] = nil
		end
	end

	local rows = tooltip.Rows

	for _, row in ipairs(rows) do
		if #row.Cells > 0 then
			local rowHeight = 0

			for _, cell in ipairs(row.Cells) do
				if cell then
					rowHeight = max(rowHeight, cell:GetContentHeight())
				end
			end

			if rowHeight > 0 then
				self:SetTooltipSize(tooltip, tooltip.Width, tooltip.Height + rowHeight - row.Height)

				row.Height = rowHeight
				row:SetHeight(rowHeight)
			end
		end
	end
end

function TooltipManager:AdjustColumnWidth(column, width)
	if width <= column.Width then
		return
	end

	local tooltip = column.Tooltip
	self:SetTooltipSize(tooltip, tooltip.Width + width - column.Width, tooltip.Height)

	column.Width = width
	column:SetWidth(width)
end

function TooltipManager:AdjustTooltipSize(tooltip)
	local horizontalMargin = tooltip.HorizontalCellMargin or PixelSize.HorizontalCellMargin

	TooltipManager:SetTooltipSize(
		tooltip,
		max(0, (horizontalMargin * (#tooltip.Columns - 1)) + (horizontalMargin / 2)),
		2
	)
end

function TooltipManager:CleanupLayouts()
	self:Hide()

	for tooltip in pairs(self.LayoutRegistry) do
		tooltip:UpdateLayout()
	end

	wipe(self.LayoutRegistry)
end

function TooltipManager:RegisterForCleanup(tooltip)
	self.LayoutRegistry[tooltip] = true
	self:Show()
end

function TooltipManager:ReleaseCell(cell)
	cell:Hide()
	cell:SetParent(nil)
	cell:ClearAllPoints()
	cell:ClearBackdrop()

	ScriptManager:ClearScripts(cell)

	cell.CellProvider:ReleaseCell(cell)
	cell.CellProvider = nil
end

function TooltipManager:ReleaseColumn(column)
	column:Hide()
	column:SetParent(nil)
	column:ClearAllPoints()
	column:ClearBackdrop()

	wipe(column.Cells)

	column.HorizontalJustification = "LEFT"
	column.Index = 0
	column.Tooltip = nil
	column.Width = 0

	ScriptManager:ClearScripts(column)

	tinsert(self.ColumnHeap, column)
end

function TooltipManager:ReleaseRow(row)
	row:Hide()
	row:SetParent(nil)
	row:ClearAllPoints()
	row:ClearBackdrop()

	for _, cell in pairs(row.Cells) do
		self:ReleaseCell(cell)
	end

	wipe(row.Cells)
	wipe(row.ColSpanCells)

	row.Height = 0
	row.Index = 0
	row.IsHeading = nil
	row.Tooltip = nil

	ScriptManager:ClearScripts(row)

	tinsert(self.RowHeap, row)
end

function TooltipManager:ReleaseTimer(timerFrame)
	timerFrame.AlternateFrame = nil
	timerFrame:Hide()
	timerFrame:SetParent(nil)
	timerFrame:SetScript("OnUpdate", nil)

	ScriptManager:ClearScripts(timerFrame)

	tinsert(self.TimerHeap, timerFrame)
end

function TooltipManager:ReleaseTooltip(tooltip)
	if self.ActiveReleases[tooltip] then
		return
	end

	self.ActiveReleases[tooltip] = true
	self.ActiveTooltips[tooltip.Key] = nil

	tooltip:Hide()

	QTip.CallbackRegistry:Fire("OnReleaseTooltip", tooltip)

	self.ActiveReleases[tooltip] = nil

	tooltip.Key = nil
	tooltip.MaxHeight = nil

	tooltip:SetAutoHideDelay(nil)
	tooltip:Clear()
	tooltip:ClearAllPoints()
	tooltip:SetHighlightTexture(self.DefaultHighlightTexturePath)
	tooltip:SetHighlightTexCoord(0, 1, 0, 1)

	if tooltip.Slider then
		tooltip.Slider:SetValue(0)
		tooltip.Slider:Hide()
		tooltip.ScrollFrame:SetPoint("RIGHT", tooltip, "RIGHT", -PixelSize.CellPadding, 0)
		tooltip:EnableMouseWheel(false)
	end

	for columnIndex, column in ipairs(tooltip.Columns) do
		tooltip.Columns[columnIndex] = self:ReleaseColumn(column)
	end

	wipe(tooltip.ColSpanWidths)
	wipe(tooltip.Columns)
	wipe(tooltip.Rows)

	for scriptType in pairs(tooltip.Scripts) do
		ScriptManager:RawSetScript(tooltip, scriptType, nil)
	end

	wipe(tooltip.Scripts)

	self.LayoutRegistry[tooltip] = nil

	tinsert(self.TooltipHeap, tooltip)
end

function TooltipManager:SetTooltipSize(tooltip, width, height)
	tooltip.Height = height
	tooltip.Width = width

	tooltip:SetSize(2 * PixelSize.CellPadding + width, 2 * PixelSize.CellPadding + height)

	tooltip.ScrollChild:SetSize(width, height)
end

--------------------------------------------------------------------------------
---- Layout Handling
--------------------------------------------------------------------------------

TooltipManager:SetScript("OnUpdate", TooltipManager.CleanupLayouts)
