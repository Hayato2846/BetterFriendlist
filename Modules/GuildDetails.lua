local _, BFL = ...
local GuildDetails = BFL:RegisterModule("GuildDetails", {})

local function GetGuildActions()
	return BFL.GetModule and BFL:GetModule("GuildActions")
end

local function BuildMemberFromRosterIndex(index)
	if not index or not GetGuildRosterInfo then
		return nil
	end

	local fullName, rank, rankIndex, level, className, zone, note, officerNote, online, status,
		classFile, achievementPoints, achievementRank, isMobile, _, _, guid = GetGuildRosterInfo(index)
	if not fullName then
		return nil
	end

	return {
		index = index,
		guildIndex = index,
		fullName = fullName,
		name = Ambiguate and Ambiguate(fullName, "guild") or fullName,
		rank = rank,
		rankIndex = rankIndex,
		level = level,
		className = className,
		classFile = classFile,
		zone = zone,
		note = note,
		officerNote = officerNote,
		online = online,
		status = status,
		achievementPoints = achievementPoints,
		achievementRank = achievementRank,
		isMobile = isMobile,
		guid = guid,
	}
end

function GuildDetails:Initialize()
	self.frame = _G.BFL_GuildMemberDetailFrame
	if self.frame then
		self.frame:Hide()
	end
end

function GuildDetails:ShowForMember(guildIndex)
	self.currentIndex = guildIndex
	if self.frame then
		self.frame:Hide()
	end
end

function GuildDetails:UpdatePublicNote()
end

function GuildDetails:UpdateOfficerNote()
end

function GuildDetails:UpdatePromoteDemote()
end

function GuildDetails:UpdateActionButtons()
end

function GuildDetails:RunMemberAction(methodName)
	local actions = GetGuildActions()
	local member = BuildMemberFromRosterIndex(self.currentIndex)
	if actions and member and actions[methodName] then
		actions[methodName](actions, member)
	end
end

function GuildDetails:PromoteMember()
	self:RunMemberAction("PromoteMember")
end

function GuildDetails:DemoteMember()
	self:RunMemberAction("DemoteMember")
end

function GuildDetails:RemoveMember()
	self:RunMemberAction("RemoveMember")
end

function GuildDetails:InviteMember()
	self:RunMemberAction("InviteParty")
end

function GuildDetails:EditPublicNote()
end

function GuildDetails:EditOfficerNote()
end
