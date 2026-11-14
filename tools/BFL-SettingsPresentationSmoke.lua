-- lua tools/BFL-SettingsPresentationSmoke.lua <repo>
-- Exercise production routing and adapter dispatch without shared native popups.
local root, checks = arg[1] or ".", 0
local function check(value,message) checks=checks+1;assert(value,message) end
local function read(path) local f=assert(io.open(root.."/"..path,"rb"));local s=f:read("*a"):gsub("\r\n","\n");f:close();return s end
local function method(path,owner,name,env)
 local s=read(path);local a=assert(s:find("function "..owner..":"..name.."(",1,true));local b=s:find("\nfunction ",a+1,true) or #s+1
 local c=s:find("\nlocal function ",a+1,true);if c and c<b then b=c end
 assert(load(s:sub(a,b-1),name,"t",env))()
end
local modules,theme={},"blizzard"
local BFL={L={},modules=modules}
function BFL:RegisterModule(name,m) modules[name]=m;return m end
function BFL:GetModule(name) return modules[name] end
function BFL:GetEffectiveTheme() return theme end
function BFL:UsesDarkSkinTheme() return theme=="dark" or theme=="custom" end
local settings={}
function settings:ShowLegacy(category,section) self.opened={category,section};self.opens=(self.opens or 0)+1 end
modules.Settings=settings
local env=setmetatable({BFL=BFL,Settings=settings,BetterFriendlistDB={enableSettingsCenterBeta=true}}, {__index=_G})
for _,name in ipairs({"IsSettingsCenterEnabled","ShowSettingsCenter","Show","ShowChangelog"}) do method("Modules/Settings.lua","Settings",name,env) end
check(not settings:IsSettingsCenterEnabled(),"saved beta opt-in can still reopen Settings Center")
settings:Show();settings:ShowSettingsCenter();settings:ShowChangelog()
check(settings.opens==3,"settings/changelog/compatibility link did not open standard Settings")
check(env.BetterFriendlistDB.enableSettingsCenterBeta==true,"routing rewrote an imported profile")
local toc=read("BetterFriendlist.toc")
check(not toc:find("LibSettingsDesigner",1,true) and not toc:find("Modules\\SettingsDesigner.lua",1,true),"retired Center still loads")
check(not read("Data/LegacySettingsCatalog.lua"):find("SETTINGS_ENABLE_SETTINGS_CENTER",1,true),"retired option remains searchable")
local hints={frame={Hide=function() end}}
local hintEnv=setmetatable({BFL=BFL,FeatureHints=hints,HasAction=function() return true end},{__index=_G})
method("Modules/FeatureHints.lua","FeatureHints","OpenEntry",hintEnv)
hints:OpenEntry({page="groups.management",category=3,legacySection="groupManagement"})
check(settings.opened[1]==3 and settings.opened[2]=="groupManagement","hint lost its direct standard-Settings destination")
local function widget()
 return {SetBackdrop=function(self,value) self.nativeBackdrop=value end,SetBackdropColor=function() end,SetBackdropBorderColor=function() end}
end
local frame=widget();frame.EditBox=widget();frame.button1=widget();frame.button2=widget()
local eui={IsSkinEnabled=function() return theme=="ellesmereui" end}
eui.facade={Shell=function(w) w.theme=theme end,EditBox=function(w) w.theme=theme end}
function eui:SkinActionButton(w) if w then w.theme=theme end end
local euiEnv=setmetatable({EllesmereUISkin=eui,SafeCall=function(api,key,...) return api[key](...) end},{__index=_G})
method("Modules/EllesmereUISkin.lua","EllesmereUISkin","SkinInputDialog",euiEnv)
modules.EllesmereUISkin=eui
local elv={}
function elv:SkinModernEditBox(_,w) if w then w.theme=theme end end
function elv:SkinModernButton(_,w) w.theme=theme end
local elvEnv=setmetatable({ElvUISkin=elv,GetActiveSettingsSkin=function() return theme=="elvui" and {} end,
 EnsureTransparentBackdrop=function(w) w.backdrop={} end,ApplyModernElvUIBackdrop=function(_,w) w.theme=theme end},{__index=_G})
method("Modules/ElvUISkin.lua","ElvUISkin","SkinInputDialog",elvEnv)
modules.ElvUISkin=elv
modules.SkinEngine={IsActive=function() return BFL:UsesDarkSkinTheme() end,RestoreFrame=function(w) w.theme=nil end}
for _,key in ipairs({"SkinFrame","SkinEditBox","SkinButton"}) do modules.SkinEngine[key]=function(_,w) w.theme=theme end end
local dialogs={inputDialog=frame}
local dialogEnv=setmetatable({BFL=BFL,Dialogs=dialogs},{__index=_G})
method("Modules/Dialogs.lua","Dialogs","RefreshInputDialogTheme",dialogEnv)
local shared={theme="FrameColor"};dialogEnv.StaticPopup1=shared
for _,nextTheme in ipairs({"blizzard","dark","custom","ellesmereui","elvui"}) do
 theme=nextTheme;dialogs:RefreshInputDialogTheme()
 for _,w in ipairs({frame,frame.EditBox,frame.button1,frame.button2}) do check(w.theme==(theme~="blizzard" and theme or nil),"private input dialog control missed "..theme) end
 check(shared.theme=="FrameColor","BFL changed a shared popup")
end
local styled={}
function eui:SkinCheckbox(w) if w then styled[w]=true end end
function eui:SkinIconButton() end
method("Modules/EllesmereUISkin.lua","EllesmereUISkin","SkinRequestedActionControls",euiEnv)
theme="ellesmereui"
local assist={};eui:SkinRequestedActionControls({RaidFrame={ControlPanel={EveryoneAssistCheckbox=assist}}})
check(styled[assist],"EUI Assist All checkbox was skipped")
-- Execute the real list icon construction with atlas, legacy texture and custom references.
assert(loadfile(root.."/Modules/FilterSortRegistry.lua","t",env))("BetterFriendlist",BFL)
local registry=modules.FilterSortRegistry
BFL.HasAtlas=function() return true end
BFL.GetAtlasOrTextureMarkup=function(atlas,_,height,width) return string.format("|A%s:%d:%d|a",atlas,height,width) end
check(registry:GetQuickFilterIcon("wowonline")==registry:GetQuickFilterIcon("wow"),"WoW Online and WoW Only use different built-in icons")
BFL.Compat={GetAtlasInfo=function() return {width=96,height=64} end}
check(registry:FormatIcon("logo-wow-forever",24):find(":27:18",1,true),"Forever icon loses its native aspect ratio or remains undersized")
local source=read("Modules/Settings.lua")
local first=assert(source:find('\t\tlocal iconButton = CreateFrame("Button", nil, row)',1,true))
local last=assert(source:find('\n\t\tlocal name = row:CreateFontString',first,true))
for _,ref in ipairs({"logo-wow-retail","logo-wow-forever","friends-status-online","Interface\\Icons\\INV_Misc_QuestionMark",12345}) do
 local icon
 local rowEnv=setmetatable({Registry=registry,entry={icon=ref},SelectEntry=function() end,
  CreateFrame=function() local w={};function w:SetSize() end;function w:SetPoint() end;function w:SetHighlightTexture() end;function w:SetScript() end
   function w:CreateFontString() icon={SetPoint=function() end,SetText=function(self,text) self.text=text end};return icon end;return w end},{__index=_G})
 assert(load(source:sub(first,last-1),"production list icon","t",rowEnv))()
 check(icon.text==registry:FormatIcon(ref,24),"Settings list disagrees with the shared menu icon formatter")
end
-- Use the actual EUI state binder for both Modern buttons and Classic dropdowns.
local euiSource=read("Modules/EllesmereUISkin.lua")
local a=assert(euiSource:find("local function ReflectControlState(",1,true))
local b=assert(euiSource:find("local function SkinWidget(",a,true))
local stateEnv=setmetatable({EllesmereUISkin=eui},{__index=_G})
assert(load(euiSource:sub(a,b-1).."\nBind=BindControlState", "EUI control state", "t", stateEnv))()
local function control(classic)
 local w={alpha=1,enabled=true,hooks={}}
 function w:GetAlpha() return self.alpha end
 function w:SetAlpha(v) self.alpha=v end
 function w:IsEnabled() return self.enabled end
 function w:HookScript(event,callback) self.hooks[event]=callback end
 function w:HasScript() return true end
 w.Text={SetTextColor=function(self,r,g,blue) self.gray=r==g and g==blue and r==.5 end}
 if classic then
  w.Button={enabled=true,hooks={},IsEnabled=w.IsEnabled,HookScript=w.HookScript,HasScript=w.HasScript}
  w.IsEnabled=nil
 end
 return w
end
theme="ellesmereui"
for _,classic in ipairs({false,true}) do
 local w=control(classic);local target=classic and w.Button or w
 stateEnv.Bind(w)
 check(w.alpha==1,"enabled EUI control was dimmed")
 target.enabled=false;target.hooks.OnDisable()
 check(w.alpha==.4 and w.Text.gray,"disabled EUI control still looks active")
 target.enabled=true;target.hooks.OnEnable()
 check(w.alpha==1 and not w.Text.gray,"re-enabling EUI control loses its normal appearance")
end
-- Disabled rows must still provide their hover/pin feedback.
local review={content={},ApplyModernSettingSelection=function() return true end,GetGuideBoundary=function() return 0 end}
local tint={fill={}}
function tint:ClearAllPoints() end;function tint:SetPoint() end;function tint:SetFrameLevel() end
function tint:Show() self.shown=true end
function tint:Hide() self.shown=false end
review.hoverTint=tint
local hoverEnv=setmetatable({Review=review,BFL=BFL},{__index=_G})
method("Modules/LegacySettingsReview.lua","Review","ShowSettingHelpHighlight",hoverEnv)
review:ShowSettingHelpHighlight({BFL_SettingDisabled=true,GetWidth=function() return 300 end,GetFrameLevel=function() return 10 end},1)
check(tint.shown,"disabled setting rows suppress their hover highlight")
-- The real hover callback must not exclude Tab Position or any Friend Tabs slot.
local hoverRow={BFL_SettingGuide={{"Tab Position","Description"}}}
review.active=true;review.guideRowsByFrame={};review.route="friendTabs"
review.IsHelpInteractionLocked=function() return false end
review.GetHoveredGuideRow=function() return hoverRow end
review.GetGuideSlot=function() return 1 end
review.ShowSettingHelp=function() end
review.ShowSettingHelpHighlight=function() review.highlighted=true end
method("Modules/LegacySettingsReview.lua","Review","UpdateSettingHelpHover",hoverEnv)
review:UpdateSettingHelpHover()
check(review.highlighted,"Friend Tabs settings suppress their hover highlight")
review.highlighted=false;hoverRow.BFL_SettingsExactSlots=true
review:UpdateSettingHelpHover()
check(not review.highlighted,"sortable tab visibility/order fields lost their deliberate hover exception")
-- Layout/reopening restores native portrait corners even after the first skin.
local elvSource=read("Modules/ElvUISkin.lua")
local headerStart=assert(elvSource:find("local function SkinSettingsPreviewHeader(",1,true))
local headerEnd=assert(elvSource:find("local function SkinSettingsPreviewScene(",headerStart,true))
local skins=0
local shellEnv=setmetatable({CallElvUIHandler=function() skins=skins+1;return true end,
 SetTextureAlpha=function() end,ApplyModernElvUIBackdrop=function(_,w) w.backdropRestored=true end},{__index=_G})
assert(load(elvSource:sub(headerStart,headerEnd-1).."\nSkinPreviewHeader=SkinSettingsPreviewHeader","ElvUI preview shell","t",shellEnv))()
local function visible()
 return {shown=true,IsShown=function(self) return self.shown end,Hide=function(self) self.shown=false end}
end
local header=visible();header.native=visible();header.native.NineSlice=visible();header.native.Bg=visible()
header.topSurface={};header.tag={};header.battleNet={}
local adapter={SkinModernEditBox=function() end,SkinModernDropdown=function() end,SkinModernButton=function() end}
for _=1,3 do
 header.native.NineSlice.shown=true;header.native.Bg.shown=true
 shellEnv.SkinPreviewHeader(adapter,{}, {},header)
 check(not header.native.NineSlice.shown and not header.native.Bg.shown,"ElvUI preview restores native shell artwork after reopening")
 check(header.native.backdropRestored,"ElvUI preview loses its backdrop after layout")
end
check(skins==1,"preview refresh repeatedly rebuilds the ElvUI frame")
-- Build the preview toggle through the actual Settings action factory, then
-- execute its real style dispatch and ElvUI button renderer (not the icon path).
local components,creationEnv={},{}
BFL.SettingsComponents=components
setmetatable(creationEnv,{__index=_G})
creationEnv.BFL,creationEnv.Components,creationEnv.FIELD_WIDTH=BFL,components,170
local function texture()
 return {alpha=1,SetAlpha=function(self,v) self.alpha=v end,SetSize=function() end,SetPoint=function() end}
end
creationEnv.CreateFrame=function(_,_,parent,template)
 local w={template=template,normal=texture(),pushed=texture(),disabled=texture(),highlight=texture()}
 w.NormalTexture=w.disabled -- Native fields can alias a different state texture.
 function w:GetNormalTexture() return self.normal end
 function w:GetPushedTexture() return self.pushed end
 function w:GetDisabledTexture() return self.disabled end
 function w:GetHighlightTexture() return self.highlight end
 function w:SetSize() end;function w:SetText() end
 function w:SetNormalFontObject() end;function w:SetHighlightFontObject() end;function w:SetDisabledFontObject() end
 function w:CreateTexture() return texture() end
 return w
end
method("Modules/SettingsComponents.lua","Components","GetActionButtonTemplate",creationEnv)
method("Modules/SettingsComponents.lua","Components","CreateButton",creationEnv)
local dock={};creationEnv.Dock=dock
method("Modules/SettingsPreviewDock.lua","Dock","CreateToggle",creationEnv)
local style={};local styleEnv=setmetatable({BFL=BFL,LegacySettingsStyle=style},{__index=_G})
method("Modules/LegacySettingsStyle.lua","LegacySettingsStyle","SkinActions",styleEnv)
elvEnv.SetTextureAlpha=function(t,v) if t then t:SetAlpha(v) end end
elvEnv.CallElvUIHandler=function(_,handler,w) check(handler=="HandleButton","preview bypasses the standard ElvUI button handler");w.handled=true;return true end
elvEnv.ApplyModernElvUIBackdrop=function(_,w) w.surfaceShown=true end
local stateStart=assert(elvSource:find("local function HideButtonStateTextures(",1,true))
local stateEnd=assert(elvSource:find("local function HideModernNativeChrome(",stateStart,true))
assert(load(elvSource:sub(stateStart,stateEnd-1).."\nHideButtonStateTexturesExport=HideButtonStateTextures","native states","t",elvEnv))()
elvEnv.HideButtonStateTextures=elvEnv.HideButtonStateTexturesExport
method("Modules/ElvUISkin.lua","ElvUISkin","SkinModernButton",elvEnv)
method("Modules/ElvUISkin.lua","ElvUISkin","SkinSettingsActions",elvEnv)
theme="elvui"
for _,mode in ipairs({{true,true},{true,false},{false,false}}) do
 BFL.IsMainline=mode[1];modules.FriendsUI={IsModernActive=function() return mode[2] end}
 local toggle=dock:CreateToggle({})
 local reference=components:CreateButton({},"Reference")
 check(toggle.template==reference.template,"preview uses a different template from the other Settings buttons")
 check(toggle.template==(mode[1] and mode[2] and "SharedButtonTemplate" or "UIPanelButtonTemplate"),"preview ignores client/layout template selection")
 check(not toggle.BFL_SettingsIconButton,"preview uses the borderless icon skin")
 style:SkinActions({toggle})
 check(toggle.handled and toggle.BFL_ElvUIModernButtonSkinned and toggle.surfaceShown,"ElvUI never skins the preview as a full Settings button")
 check(toggle.normal.alpha==0 and toggle.pushed.alpha==0 and toggle.disabled.alpha==0,"native button artwork remains above the ElvUI skin")
 check(toggle.Icon.alpha==1,"ElvUI skin hides the preview arrow")
 toggle.normal.alpha=1;style:SkinActions({toggle})
 check(toggle.normal.alpha==0 and toggle.surfaceShown,"preview skin is lost on a repeated refresh")
end
io.write(string.format("PASS: Settings retirement, private dialog themes, Assist All and list icons (%d checks)\n",checks))
