-- lua tools/BFL-SettingsNewFlagsSmoke.lua <repo>
local root,checks=arg[1] or ".",0
local function check(v,m) checks=checks+1;assert(v,m) end
local profile={};local modules={};local BFL={L={},IsMainline=true,Compat={}}
function BFL:RegisterModule(n,m) modules[n]=m;return m end
function BFL:GetModule(n) return modules[n] end
local theme="dark";function BFL:GetEffectiveTheme() return theme end
local db={Get=function(_,k) return profile[k] end,Set=function(_,k,v) profile[k]=v end};modules.DB=db
modules.Changelog={GetNewBadge=function() error("Settings still use an inline badge texture") end}
local env=setmetatable({BFL=BFL},{__index=_G})
assert(loadfile(root.."/Data/LegacySettingsCatalog.lua","t",env))("BFL",BFL)
assert(loadfile(root.."/Modules/SettingsNewFlags.lua","t",env))("BFL",BFL)
local flags=modules.SettingsNewFlags
function flags:EnsureListener() end
local function region(parent,kind)
 local r={parent=parent,kind=kind or "Frame",width=174,height=24,level=1,points={},children={},regions={},scripts={},text=""}
 if parent then local list=kind=="FontString" and parent.regions or parent.children;list[#list+1]=r end
 function r:IsObjectType(t) return self.kind==t or t=="Button" and self.kind=="CheckButton" end
 function r:GetChildren() return table.unpack(self.children) end
 function r:GetRegions() return table.unpack(self.regions) end
 function r:GetNumPoints() return #self.points end
 function r:GetPoint(i) return table.unpack(self.points[i]) end
 function r:SetPoint(point,relative,relativePoint,x,y)
  if type(relative)=="number" then x,y=relative,relativePoint;relative,relativePoint=self.parent,point end
  if not relative then relative,relativePoint,x,y=self.parent,point,0,0 end
  local item={point,relative,relativePoint,x or 0,y or 0}
  for i,old in ipairs(self.points) do if old[1]==point then self.points[i]=item;return end end
  self.points[#self.points+1]=item
 end
 function r:ClearAllPoints() self.points={} end
 function r:SetText(v) self.text=v end
 function r:GetText() return self.text end
 function r:SetSize(w,h) self.width,self.height=w,h end
 function r:SetWidth(w) self.width=w;if self.scripts.OnSizeChanged then self.scripts.OnSizeChanged(self,w,self.height) end end
 function r:GetWidth() return self.width end
 function r:GetFrameLevel() return self.level end
 function r:SetFrameLevel(v) self.level=v end
 function r:SetShown(v) self.shown=v end
 function r:Show() self.shown=true end
 function r:SetScale(v) self.scale=v end
 function r:EnableMouse(v) self.mouse=v end
 function r:SetClipsChildren(v) self.clipped=v end
 function r:CreateFontString() return region(self,"FontString") end
 function r:GetScript(event) return self.scripts[event] end
 function r:SetScript(event,callback) self.scripts[event]=callback end
 return r
end
env.NEW_CAPS="NEW"
local frameCreations=0
env.CreateFrame=function(_,_,parent,template)
 frameCreations=frameCreations+1
 local frame=region(parent);frame.template=template
 if template=="NewFeatureLabelTemplate" then frame.Label=region(frame,"FontString");frame.Label:SetText(env.NEW_CAPS) end
 return frame
end
assert(loadfile(root.."/Modules/NewFeatureBadge.lua","t",env))("BFL",BFL)
local function label(text,parent) local l=region(parent,"FontString");l.text=text;return l end
local function navigation(text,route)
 local n=region();n.label=label(text,n);n.labelInset=route and 24 or 10;n.route=route;return n
end
local review={route="theme",active=true,guideRowsByFrame={},controlRows={},navButtons={},subButtons={},settings={GetLegacyTabAvailability=function() return true end}}
for i,c in ipairs(BFL.LegacySettingsCatalog.categories) do review.navButtons[i]=navigation(c[2]);BFL.L[c[2]]=c[2] end
for _,p in pairs(BFL.LegacySettingsCatalog.pages) do BFL.L[p[2]]=p[2] end
local function row(key,section)
 local r=region();r.width=600;r.BFL_SettingGuide={{key,"",key}};r.Label=label(key,r)
 r.DropDown=region(r);r.controlWidth=170
 r.DropDown:SetPoint("RIGHT",r,"RIGHT",0,0)
 r.Label:SetPoint("LEFT",r,"LEFT",0,0);r.Label:SetPoint("RIGHT",r,"RIGHT",-190,0)
 r:SetScript("OnSizeChanged",function(self)
  self.DropDown:SetPoint("RIGHT",self,"RIGHT",0,0)
  self.Label:SetPoint("RIGHT",self,"RIGHT",-self.controlWidth-20,0)
 end)
 review.controlRows[#review.controlRows+1]=r
 flags:BindRow(review,r,section);return r
end
local input=row("SETTINGS_BFL_INPUT_DIALOGS");local avatar=row("SETTINGS_THEME_HIDE_AVATAR")
review.subButtons={navigation("","theme"),navigation("","layout")}
flags:RefreshNavigation(review)
check(review.navButtons[4].BFL_NewBadgeShown,"unvisited parent has no New flag")
check(input.BFL_NewBadgeShown,"new setting row has no badge")
check(not profile.settingsNewReadState,"viewing Settings marks options read")
flags:MarkRead("useThemedDialogs",review)
check(not input.BFL_NewBadgeShown and avatar.BFL_NewBadgeShown,"reading one setting reads its neighbour")
check(flags:RouteUnread("theme",review),"subcategory cleared before all settings read")
flags:MarkRead("hideThemeAvatar",review)
check(not flags:RouteUnread("theme",review),"subcategory did not clear immediately")
check(review.navButtons[4].BFL_NewBadgeShown,"parent cleared while another subcategory has unread options")
for id,d in pairs(flags.definitions) do if d.route=="windowFonts" or d.route=="layout" then flags:MarkRead(id,review) end end
check(not review.navButtons[4].BFL_NewBadgeShown,"parent remains after all child flags read")
local before=profile.settingsNewReadState;flags:MarkRead("useThemedDialogs",review)
check(profile.settingsNewReadState==before,"repeated clicks rewrite read state")
profile={};theme="blizzard"
check(not flags:IsAvailable(flags.definitions.hideThemeAvatar,review),"hidden avatar setting creates a badge")
BFL.IsMainline=false
check(not flags:RouteUnread("friendTabs",review),"unsupported Classic option creates a phantom flag")
BFL.IsMainline=true;theme="dark"
review.route="windowFonts"
local font=row("SETTINGS_FONT","SETTINGS_WINDOW_TITLE_FONT")
check(font.BFL_NewSettingIDs[1]=="fontWindowTitle","identical translated Font labels lose their scope")
local action=row("SETTINGS_FONT","SETTINGS_ACTION_BUTTON_FONT")
check(action.BFL_NewSettingIDs[1]=="fontActionButton","window/action font IDs collide")
local x,y=20,20;env.GetCursorPosition=function() return x,y end
function review:GetHoveredGuideRow() return font end
function review:GetGuideSlot() return 1 end
flags:HandleClick(review,"GLOBAL_MOUSE_DOWN","LeftButton");x=40;flags:HandleClick(review,"GLOBAL_MOUSE_UP","LeftButton")
check(flags:IsUnread("fontWindowTitle"),"dragging reads a setting")
x=20;flags:HandleClick(review,"GLOBAL_MOUSE_DOWN","LeftButton");flags:HandleClick(review,"GLOBAL_MOUSE_UP","LeftButton")
check(not flags:IsUnread("fontWindowTitle") and flags:IsUnread("fontActionButton"),"click reads the wrong slot")
check(not profile.changelogReadState,"setting clicks change Changelog read state")
local saved=profile;profile={};check(flags:IsUnread("fontWindowTitle"),"profile change leaks read state")
profile=saved;check(not flags:IsUnread("fontWindowTitle"),"reopening loses read state")
flags.definitions.fontWindowTitle.revision="next"
check(flags:IsUnread("fontWindowTitle"),"a newer setting revision is silently already read")
profile={};review.route="theme"
local padded=row("SETTINGS_BFL_INPUT_DIALOGS")
local function rightOffset(item) for _,point in ipairs(item.points) do if point[1]=="RIGHT" then return point[4] end end end
check(padded.Label:GetText()=="SETTINGS_BFL_INPUT_DIALOGS","badge still prefixes or indents the setting label")
local neighbour=row("SETTINGS_THEME_DROPDOWN")
check(rightOffset(neighbour.DropDown)==rightOffset(padded.DropDown),"badged and ordinary setting controls are misaligned")
check(rightOffset(padded.DropDown)==-50,"control overlaps the trailing badge")
check(not padded.BFL_NewBadge.clipped and padded.BFL_NewBadge.width==44,"compact badge slot cuts off the atlas shadow")
check(padded.BFL_NewBadge.NativeLabel.template=="NewFeatureLabelTemplate","Settings do not use the native New label")
check(padded.BFL_NewBadge.NativeLabel.scale==.8 and padded.BFL_NewBadge.Label:GetText()==env.NEW_CAPS,"native badge changes its scale or localized text")
check(not padded.BFL_NewBadge.mouse and not padded.BFL_NewBadge.NativeLabel.mouse,"new badge blocks setting clicks")
local sharedBadge=padded.BFL_NewBadge
for _,name in ipairs({"blizzard","dark","custom","elvui","ellesmereui"}) do
 theme=name;flags:RefreshRow(padded)
 check(padded.BFL_NewBadge==sharedBadge and sharedBadge.BFL_DarkManagedSubtree,"theme refresh rebuilds or exposes the native badge to recursive skinning")
end
theme="dark"
local background=region(padded);background:SetPoint("RIGHT",padded,"RIGHT",0,0)
flags:RefreshRow(padded)
check(rightOffset(background)==0,"badge padding shrinks a decorative theme backing")
for i=1,30 do padded:SetWidth(600+i);flags:RefreshRow(padded) end
check(rightOffset(padded.DropDown)==-50,"repeated resize accumulates badge padding")
padded.controlWidth=220;padded:SetWidth(700)
check(rightOffset(padded.Label)==-290,"a changed control width loses badge padding")
flags:MarkRead("useThemedDialogs",review)
check(rightOffset(padded.DropDown)==-50 and rightOffset(padded.Label)==-290,"reading makes setting controls jump horizontally")
check(not padded.BFL_NewBadge.shown,"reading leaves the trailing badge visible")
check(review.navButtons[4].label.text==BFL.L.SETTINGS_TAB_APPEARANCE,"badge still prefixes the navigation label")
local actionButton=region(nil,"Button");actionButton.BFL_SettingGuide={{"Reset","","RESET"}}
local actionText=label("Reset",actionButton);actionText:SetPoint("RIGHT",actionButton,"RIGHT",-10,0)
flags:BindRow(review,actionButton)
check(rightOffset(actionText)==-10,"badge column changes action-button text insets")
review.route="automatic";flags:BindRow(review,neighbour)
check(rightOffset(neighbour.DropDown)==0,"a reused row keeps padding from another settings page")
modules.LegacySettingsReview=review
profile.settingsNewReadState={useThemedDialogs="3.1.2",fontWindowTitle="next",previousOption="3.0.0"}
profile.changelogReadState={unchanged=true}
local changelogState=profile.changelogReadState
flags:ResetCurrentReadState()
check(flags:IsUnread("useThemedDialogs"),"current settings flags remain read after reset")
check(profile.settingsNewReadState.fontWindowTitle=="next" and profile.settingsNewReadState.previousOption=="3.0.0","reset erases another settings revision")
check(profile.changelogReadState==changelogState,"reset changes changelog read state")
check(review.navButtons[4].BFL_NewBadgeShown,"reset does not immediately update category badges")
review.active=false;flags:ResetCurrentReadState()
check(flags:IsUnread("useThemedDialogs"),"reset requires open settings")
-- Menus attach through Blizzard's compositor rather than retaining custom
-- child frames or skin markers on pooled menu rows.
local pooled=region();pooled.GetTextWidth=function() return 24 end
local menuButton=region();menuButton.fontString=region(menuButton,"FontString")
env.MenuTemplates={AttachNewFeatureFrame=function(parent) check(parent==menuButton,"badge attaches to another menu row");return pooled end}
local description={AddInitializer=function(self,callback) self.initialize=callback end}
modules.NewFeatureBadge:AttachToMenu(description)
local beforeFrames=frameCreations;description.initialize(menuButton)
check(frameCreations==beforeFrames,"menu badge allocates persistent child frames")
check(pooled.scale==.8 and pooled.mouse==false and not pooled.BFL_DarkManagedSubtree,"menu badge leaves a BFL skin marker on a shared frame")
check(pooled.points[1][2]==menuButton.fontString,"menu badge is detached from its item text")
io.write(string.format("PASS: per-setting New flags, click reading and category aggregation (%d checks)\n",checks))
