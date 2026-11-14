local _, BFL = ...
local Badge = BFL:RegisterModule("NewFeatureBadge", {})

local SCALE = .8

function Badge:Create(parent)
	local holder = CreateFrame("Frame", nil, parent)
	holder.BFL_DarkManagedSubtree = true
	holder:EnableMouse(false)
	holder:SetClipsChildren(false)
	holder:SetSize(44, 24)
	local label = CreateFrame("Frame", nil, holder, "NewFeatureLabelTemplate")
	label:SetScale(SCALE)
	label:SetPoint("CENTER")
	label:EnableMouse(false)
	label:Show()
	holder.Label, holder.NativeLabel = label.Label, label
	return holder
end

function Badge:AttachToMenu(description)
	if not (MenuTemplates and MenuTemplates.AttachNewFeatureFrame) then return end
	description:AddInitializer(function(button)
		-- Menu-owned attachments are released/reset with the pooled row. Never
		-- leave a persistent BFL child or a skin hook on shared Blizzard menus.
		local label = MenuTemplates.AttachNewFeatureFrame(button)
		label:SetScale(SCALE)
		label:EnableMouse(false)
		label:ClearAllPoints()
		label:SetPoint("CENTER", button.fontString, "RIGHT", label:GetTextWidth() / 2 + 8 / SCALE, 0)
	end)
end
