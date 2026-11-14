-- lua tools/BFL-SettingsPreviewDockSmoke.lua <repo>
-- Production layout, docking geometry, persistence and tooltip transitions; no real profile.
local root, checks = arg[1] or ".", 0
local function check(value, message) checks = checks + 1; assert(value, message) end
local function equal(actual, expected, message)
	local same = type(actual) == "number" and type(expected) == "number" and math.abs(actual-expected)<.001 or actual == expected
	check(same, message .. ": " .. tostring(actual))
end
local BFL = { modules = {}, L = {} }
function BFL:RegisterModule(name, value) self.modules[name] = value; return value end
function BFL:GetModule(name) return self.modules[name] end
local theme="dark"
function BFL:GetEffectiveTheme() return theme end
function BFL:GetThemeAccentColor() return .2,.7,.5,1 end
local profile = {}
local db = {}
function db:Get(key) return profile[key] end
function db:Set(key, value) profile[key] = value end
BFL.modules.DB = db
local screen = { GetWidth=function() return 1600 end, GetHeight=function() return 900 end,
	GetSize=function() return 1600,900 end,
	GetEffectiveScale=function() return .8 end }
local tooltip = { shown=false }
function tooltip:GetOwner() return self.owner end
function tooltip:SetOwner(owner) self.owner=owner end
function tooltip:SetText(text) self.title=text; self.lines={} end
function tooltip:AddLine(text) self.lines[#self.lines+1]=text end
function tooltip:Show() self.shown=true end
function tooltip:Hide() self.shown=false end
function tooltip:IsShown() return self.shown end
function tooltip:GetFrameLevel() return 20 end
local env = setmetatable({ BFL=BFL, UIParent=screen, BFL_Tooltip=tooltip }, {__index=_G})
env._G=env
assert(loadfile(root .. "/Utils/WindowGeometry.lua", "t", env))("BetterFriendlist",BFL)
assert(loadfile(root .. "/Modules/SettingsPreviewDock.lua", "t", env))("BetterFriendlist",BFL)
local dock, geometry = BFL.modules.SettingsPreviewDock, BFL.WindowGeometry
local function region(parent, width, height)
	local f = {parent=parent,width=width or 360,height=height or 600,shown=true,points={},level=10}
	function f:GetParent() return self.parent end
	function f:SetParent(value) self.parent=value end
	function f:GetFrameLevel() return self.level end
	function f:SetFrameLevel(value) self.level=value end
	function f:GetFrameStrata() return "DIALOG" end
	function f:SetFrameStrata(value) self.strata=value end
	function f:GetEffectiveScale() return self.scale or self.parent:GetEffectiveScale() end
	function f:GetWidth() return self.width end
	function f:GetHeight() return self.height end
	function f:SetWidth(value) self.width=value end
	function f:SetHeight(value) self.height=value end
	function f:SetSize(w,h) self.width,self.height=w,h end
	function f:GetRect() return self.left or 0,self.bottom or 0,self.width,self.height end
	function f:GetTop() return (self.bottom or 0)+self.height end
	function f:ClearAllPoints() self.points={} end
	function f:SetPoint(point,relative,relativePoint,x,y)
		self.points[point]={point,relative,relativePoint,x,y}
		if not self.dockWindow then return end
		local rx,ry,rw,rh=geometry:GetRect(relative)
		local ratio=geometry:GetRatio(self)
		self.left=(rx+(relativePoint:find("RIGHT") and rw or 0))/ratio+x
		if point:find("RIGHT") then self.left=self.left-self.width end
		self.bottom=(ry+rh)/ratio+y-self.height
	end
	function f:SetShown(value) self.shown=not not value end
	function f:Show() self.shown=true end
	function f:Hide() self.shown=false end
	function f:IsShown() return self.shown end
	function f:IsVisible() return self.shown and (not self.parent or not self.parent.IsVisible or self.parent:IsVisible()) end
	function f:SetResizeBounds(...) self.resizeBounds={...};self.boundsApplications=(self.boundsApplications or 0)+1 end
	function f:StopMovingOrSizing() self.stopped=true end
	function f:SetRotation(value) self.rotation=value end
	function f:SetTexture(value) self.texture=value end
	function f:SetVertexColor(...) self.color={...} end
	function f:SetAllPoints(value) self.allPoints=value end
	function f:SetTexCoord(...) self.coords={...} end
	return f
end
local owner=region(screen,600,520)
owner.MainInset=region(owner,500,460)
owner.NineSlice=region(owner);owner.NineSlice.level=500
owner.TitleContainer=region(owner);owner.TitleContainer.level=510
owner.CloseButton=region(owner,24,24)
function owner.CloseButton:GetRect()
	local x,y,w,h=owner:GetRect()
	return x+w-self.width+1,y+h-self.height,self.width,self.height
end
local preview,help=region(owner.MainInset),region(owner.MainInset)
local sample=region(preview)
sample.BFL_DarkBackdrop=region(sample)
sample.BFL_DarkBackdrop.level=999
local window=region(owner,380,520)
window.dockWindow=true
window.Inset=region(window)
window.content=region(window.Inset,356,472)
local toggle=region(owner)
toggle.Icon=region(toggle)
dock.toggle=toggle
window.grip=region(window)
local texture=region(window.grip)
function window.grip:GetNormalTexture() return texture end
function window.grip:GetHighlightTexture() return texture end
function window.grip:GetPushedTexture() return texture end
dock.window=window
local review={active=true,frame=owner,preview=preview,hoverHelp=help,sidebar=region(owner),
	support=region(owner),scroll=region(owner.MainInset),content=region(owner.MainInset),
	visibleNavRows={},sample="friends",guideRows={{}},route="rows"}
review.sampleWidgets={sample}
function review:LayoutSupport() end
function review:QueueSample() self.renderRequests=(self.renderRequests or 0)+1 end
function review:RefreshHeight() end
function review:LayoutSettingHelp() self.helpLayouts=(self.helpLayouts or 0)+1; self.hoverHelp:SetShown(self.helpVisible) end
local file=assert(io.open(root .. "/Modules/LegacySettingsReview.lua","rb"))
local source=file:read("*a"):gsub("\r\n","\n");file:close()
env.Review=review
for _,name in ipairs({"Layout","LayoutPreview","HideSettingTooltip","UpdateSettingTooltip","UpdateSettingHelpHover"}) do
	local start=assert(source:find("function Review:"..name.."(",1,true))
	local finish=source:find("\nfunction ",start+1,true) or #source+1
	local localFunction=source:find("\nlocal function ",start+1,true)
	if localFunction and localFunction<finish then finish=localFunction end
	assert(load(source:sub(start,finish-1),name,"t",env))()
end
for _,ratio in ipairs({.5,1,1.5}) do
	owner.scale=.8*ratio
	owner.left,owner.bottom=(1500-600*ratio)/ratio,100/ratio
	owner.MainInset.width=500
	profile={settingsPreviewWidth=380,settingsPreviewCollapsed=false}
	review:Layout()
	equal(sample.BFL_DarkBackdrop:GetFrameLevel(),sample:GetFrameLevel()-1,"moving preview leaves its backing above the sample")
	check(window:IsVisible(),"narrow settings have no preview window")
	equal(preview:GetParent(),window.content,"preview did not move into the detached window")
	equal(help:GetParent(),window.content,"help and preview separated")
	local x,_,w=geometry:GetRect(window)
	local ox=geometry:GetRect(owner)
	check(x+w<=ox+.01,"detached preview overlaps settings at the right screen edge")
	equal(dock.side,"left","preview did not choose the free side")
	equal(review.scroll.points.TOPLEFT[2],owner.MainInset,"preview still pushes settings down")
	owner.left=24/ratio; dock:Anchor()
	x=geometry:GetRect(window)
	local _,_,ow=geometry:GetRect(owner)
	check(x>=24+ow,"moving settings did not reanchor preview beside them")
	equal(dock.side,"right","preview did not switch with available screen space")
	review.pinnedGuideID="a-setting"
	dock:SetCollapsed(true)
	equal(profile.settingsPreviewCollapsed,true,"collapse state was not saved")
	check(not window:IsShown() and toggle:IsVisible(),"collapse leaves a preview title bar or loses the Settings edge button")
	owner.left=(1500-600*ratio)/ratio;dock:FollowOwner()
	equal(dock.side,"left","collapsed edge button stopped following the free side")
	check(review.helpTooltips and not help:IsVisible(),"collapse did not switch to tooltip help")
	check(not preview:IsVisible(),"collapsed preview still renders")
	equal(review.pinnedGuideID,nil,"collapsed tooltip mode retained pinned help")
	owner.MainInset.width=1000
	review:Layout()
	check(not window:IsShown(),"wide settings keep the external window open")
	equal(preview:GetParent(),owner.MainInset,"wide settings did not reintegrate preview")
	check(help:IsVisible() and not review.helpTooltips,"wide settings did not restore rich help")
	equal(profile.settingsPreviewCollapsed,true,"embedding overwrote the external collapse preference")
	owner.MainInset.width=500
	review:Layout()
	check(review.helpTooltips,"returning to narrow settings forgot the collapse preference")
	dock:SetCollapsed(false)
	equal(profile.settingsPreviewCollapsed,false,"a valid expanded false value was lost")
	check(help:IsVisible(),"opening the preview did not restore help")
	owner.left=24/ratio;dock:FollowOwner()
	dock.resizing=true
	local requests,layouts=review.renderRequests,review.helpLayouts
	for tick=1,60 do window:SetSize(340+tick,400+tick);dock:ResizeContent() end
	equal(review.renderRequests,requests,"live resizing repeatedly rebuilds sample friends")
	equal(review.helpLayouts,layouts,"live resizing repeatedly rebuilds and skins comparisons")
	dock:StopResize()
	equal(review.renderRequests,requests+1,"releasing resize must update the sample once")
	equal(profile.settingsPreviewWidth,400,"resized width was not saved")
	equal(profile.settingsPreviewHeight,460,"resized height was not saved")
	check(window.resizeBounds[2]<window.resizeBounds[4],"resize bounds still lock the height")
	check(window.stopped,"mouse release did not stop sizing")
	dock:Hide();review:Layout()
	equal(window:GetWidth(),400,"reopening lost the chosen width")
	equal(window:GetHeight(),460,"reopening lost the chosen height")
end
profile={settingsPreviewWidth=380,settingsPreviewCollapsed=false}
owner.scale=.8*1.5;owner.left=400/1.5
dock:FollowOwner()
local constrainedLeft,_,constrainedWidth=geometry:GetRect(window)
check(constrainedLeft+constrainedWidth<=400+.01,"large UI scale makes the preview overlap Settings")
equal(profile.settingsPreviewWidth,380,"temporary screen fitting overwrote the chosen width")
owner.left=24/1.5;dock:FollowOwner()
equal(window:GetWidth(),380,"more space did not restore the chosen width")
profile={settingsPreviewWidth=320,settingsPreviewCollapsed=false};review:Layout()
equal(window:GetWidth(),320,"profile switch retained another profile's width")
profile={settingsPreviewWidth=0/0,settingsPreviewCollapsed="false"}
local width,collapsed=dock:GetState()
equal(width,380,"invalid imported width is not normalized")
equal(collapsed,false,"invalid imported collapsed state is treated as true")
profile={settingsPreviewWidth=math.huge}
width=dock:GetState();equal(width,560,"unbounded imported width is not constrained")
-- Reproduce Settings sitting beside the friends window at all supported scales.
for _, ratio in ipairs({.5,1,1.5}) do
 owner.scale=.8*ratio;owner.width=520;owner.left=500/ratio;owner.MainInset.width=500
 local friends=region(screen,160,520);friends.scale=owner.scale
 friends.left=(500+owner.width*ratio+8)/ratio;friends.bottom=owner.bottom
 env.BetterFriendsFrame=friends
 profile={settingsPreviewWidth=380,settingsPreviewHeight=600,settingsPreviewCollapsed=false}
 dock.side=nil;review:Layout()
 equal(dock.side,"left","preview docks over the open friends window")
 local px,_,pw=geometry:GetRect(window);local sx=geometry:GetRect(owner)
 check(px+pw<=sx+.01,"preview overlaps Settings")
 check(window:IsVisible(),"usable free side is incorrectly hidden")
 local point=toggle.points.TOPLEFT or toggle.points.TOPRIGHT
 check(point[1]==point[3] and point[5]<0,"preview toggle projects outside the Settings title bar")
 for offset=0,12 do owner.left=(500-offset)/ratio;friends.left=(500-offset+owner.width*ratio+8)/ratio;dock:FollowOwner();equal(dock.side,"left","preview changes sides during a small drag") end
 owner.left=20/ratio;friends.left=(20+owner.width*ratio+8)/ratio;dock:FollowOwner()
 check(not window:IsShown() and review.helpTooltips,"no free space leaves preview overlapping another BFL window")
 equal(profile.settingsPreviewCollapsed,false,"temporary space constraint overwrites the collapse preference")
 equal(profile.settingsPreviewWidth,380,"temporary space constraint overwrites the saved width")
 owner.left=500/ratio;friends.left=(500+owner.width*ratio+8)/ratio;dock:FollowOwner()
 check(window:IsVisible() and not review.helpTooltips,"making space does not restore preview automatically")
end
owner.scale=.8;owner.height=300;owner.bottom=0;owner.left=500
window:SetHeight(600)
local above=region(screen,400,50);above.left=0;above.bottom=500
env.BetterFriendsFrame=above
local fittedLeft=dock:GetDockSpace()
check(fittedLeft<160,"vertical screen fitting ignores a friends window above Settings")
BFL.modules.FriendsUI={GetAuxiliaryWindowOffset=function(_,_,side) return side=="right" and 68 or 5 end}
local withRail=dock:GetDockSpace()
equal(withRail,fittedLeft-68,"the friends tab rail is not reserved beside the preview")
BFL.modules.FriendsUI=nil
env.BetterFriendsFrame=nil
dock:FollowOwner();dock:FollowOwner()
local boundsBefore,rendersBefore=window.boundsApplications,review.renderRequests
for _=1,60 do dock:FollowOwner() end
equal(window.boundsApplications,boundsBefore,"steady preview movement polling reapplies native resize bounds")
equal(review.renderRequests,rendersBefore,"steady preview movement polling repeatedly renders sample friends")
theme="ellesmereui";dock:Anchor()
equal(toggle:GetHeight(),25,"EUI preview button does not fill its 25px title strip")
local titlePoint=toggle.points.TOPLEFT or toggle.points.TOPRIGHT
equal(titlePoint[5],0,"EUI preview button leaves a gap above the title strip")
theme="dark";dock:Anchor()
equal(toggle:GetHeight(),22,"other themes inherit EUI-specific button dimensions")
local savedScale=owner.scale
theme="blizzard"
for _,scale in ipairs({.5,1,1.5}) do
	owner.scale=screen:GetEffectiveScale()*scale
	for _,size in ipairs({24,32}) do
		owner.CloseButton:SetSize(size,size)
		for _,side in ipairs({"left","right"}) do
			dock.nextSide=side;dock:Anchor()
			equal(toggle:GetHeight(),size,"Blizzard preview toggle does not match close-button height")
			equal(toggle:GetWidth(),size+6,"preview toggle did not gain the requested width")
			equal(toggle.Icon:GetHeight(),math.floor(size*2/3+.5),"Blizzard arrow does not scale with the button")
			local point=toggle.points.TOPLEFT or toggle.points.TOPRIGHT
			equal(point[5],0,"Blizzard preview toggle is below the close button")
			equal(point[4],dock.side=="left" and -1 or -size-1,"Blizzard preview toggle is not aligned to the native frame edge")
		end
	end
end
owner.scale=savedScale;owner.CloseButton:SetSize(24,24)
theme="dark";dock:Anchor()
equal(toggle:GetHeight(),22,"Blizzard dimensions leak into another theme")
equal(toggle.Icon:GetHeight(),14,"Blizzard icon dimensions leak into another theme")
theme="blizzard";toggle.atlasName="128-RedButton";dock:Anchor()
local nativeHeight=owner.CloseButton:GetHeight()
local artworkInset=nativeHeight/16
local artworkPoint=toggle.points.TOPLEFT or toggle.points.TOPRIGHT
equal(toggle:GetHeight(),nativeHeight+artworkInset,"shared artwork top margin is not compensated")
equal(artworkPoint[5],artworkInset,"shared artwork does not extend upwards")
equal(artworkPoint[5]-toggle:GetHeight(),-nativeHeight,"artwork correction moves the aligned lower edge")
equal(toggle.Icon.points.CENTER[5],0,"preview arrow is not centered vertically in its button")
equal(toggle.Icon.color[1],1,"Blizzard arrow is not yellow")
equal(toggle.Icon.color[2],1,"Blizzard arrow still uses the darker gold accent")
equal(toggle.Icon.color[3],0,"Blizzard arrow has a blue tint")
theme="elvui";dock:Anchor()
equal(toggle:GetHeight(),22,"native artwork correction leaks into the ElvUI skin")
equal(toggle.Icon.points.CENTER[5],0,"native artwork correction leaves the ElvUI arrow off-center")
equal(toggle.Icon.color[1],.2,"native yellow leaks into the ElvUI arrow")
equal(toggle:GetWidth(),30,"wider toggle is missing in ElvUI")
toggle.atlasName=nil;theme="dark";dock:Anchor()
for _,side in ipairs({"left","right"}) do
	for _,collapsed in ipairs({false,true}) do
		dock.side,dock.collapsed=side,collapsed;dock:RefreshToggleIcon()
		local direction=(side=="left")==collapsed and "left" or "right"
		equal(toggle.Icon.texture,"Interface\\AddOns\\BetterFriendlist\\Icons\\chevron-"..direction..".blp","preview arrow has the wrong direction")
		equal(toggle.Icon.points.CENTER[4],0,"preview arrow is not centered horizontally in its button")
		check(not toggle.BFL_SettingsIconButton,"preview toggle bypasses the shared button skin")
	end
end
check(toggle:GetFrameLevel()>owner.TitleContainer:GetFrameLevel(),"native title artwork covers the preview toggle")
check(toggle:GetFrameLevel()>owner.NineSlice:GetFrameLevel(),"native frame border covers the preview toggle")
local row={BFL_SettingGuide={{"Setting title","Complete setting explanation"}}}
review.helpTooltips=true
function review:IsHelpInteractionLocked() return false end
function review:GetHoveredGuideRow() return self.hoveredRow end
function review:GetGuideSlot() return 1 end
function review:ShowSettingHelpHighlight(value) self.highlighted=value end
review.hoveredRow=row
tooltip.BFL_DarkBackdrop=region(nil)
review:UpdateSettingHelpHover()
check(tooltip:IsShown(),"collapsed setting row has no tooltip")
equal(tooltip:GetOwner(),row,"tooltip does not belong to the hovered row")
equal(tooltip.title,"Setting title","tooltip has the wrong setting title")
equal(tooltip.lines[1],"Complete setting explanation","tooltip loses the guide description")
equal(tooltip.BFL_DarkBackdrop:GetFrameLevel(),19,"tooltip backing covers the help text after raising")
equal(review.highlighted,row,"tooltip mode lost the row hover highlight")
review.hoveredRow=nil;review:UpdateSettingHelpHover()
check(not tooltip:IsShown(),"leaving the row leaves a stale tooltip")
review.hoveredRow=row;review:UpdateSettingHelpHover()
local foreign={};tooltip:SetOwner(foreign);tooltip:Show()
review:HideSettingTooltip()
check(tooltip:IsShown(),"help cleanup hid another BFL tooltip")
review.active=false;dock:Hide()
check(not window:IsShown(),"closing settings left the external preview visible")
io.write(string.format("PASS: preview docking, responsive layout, persistence and tooltip help (%d checks)\n",checks))
