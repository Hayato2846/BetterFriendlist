-- lua tools/BFL-CopyDialogSmoke.lua <repo>
-- Production private-dialog lifecycle, copy actions and pooled-native isolation.
local root,checks=arg[1] or ".",0
local function check(v,m) checks=checks+1;assert(v,m) end
local modules,profile={}, {useThemedDialogs=true}
local BFL={L={SETTINGS_CENTER_SUPPORT_COPY_LINKS="Copy Links"}}
function BFL:RegisterModule(n,m) modules[n]=m;return m end
function BFL:GetModule(n) return modules[n] end
function BFL:GetEffectiveTheme() return "dark" end
function BFL:UsesDarkSkinTheme() return true end
BFL.WindowGeometry={GetRatio=function() return 1 end}
modules.DB={Get=function(_,key,default) if profile[key]==nil then return default end;return profile[key] end}
modules.SkinEngine={IsActive=function() return true end}
for _,name in ipairs({"SkinFrame","SkinButton","SkinEditBox"}) do modules.SkinEngine[name]=function(_,w) w.skinned=true end end
local env=setmetatable({BFL=BFL,StaticPopupDialogs={},UISpecialFrames={},CLOSE="Close",CANCEL="Cancel"},{__index=_G})
env._G=env
local controlDown=false;env.IsControlKeyDown=function() return controlDown end
local function frame(parent)
 local w={parent=parent,children={},shown=true,enabled=true,width=380,height=188,level=10,scripts={},points={},text=""}
 if parent then parent.children[#parent.children+1]=w end
 function w:GetParent() return self.parent end
 function w:SetParent(p) self.parent=p end
 function w:GetChildren() return table.unpack(self.children) end
 function w:SetSize(x,y) self.width,self.height=x,y end
 function w:SetWidth(x) self.width=x end
 function w:SetHeight(y) self.height=y end
 function w:GetWidth() return self.width end
 function w:GetHeight() return self.height end
 function w:GetFrameLevel() return self.level end
 function w:SetFrameLevel(v) self.level=v end
 function w:GetFrameStrata() return self.strata or "DIALOG" end
 function w:SetFrameStrata(v) self.strata=v end
 function w:SetScript(event,fn) self.scripts[event]=fn end
 function w:SetPoint(...) self.points[#self.points+1]={...} end
 function w:ClearAllPoints() self.points={} end
 function w:Hide() local old=self.shown;self.shown=false;if old and self.scripts.OnHide then self.scripts.OnHide(self) end end
 function w:Show() self.shown=true end
 function w:SetShown(v) if v then self:Show() else self:Hide() end end
 function w:IsShown() return self.shown end
 function w:IsVisible() return self.shown end
 function w:Enable() self.enabled=true end
 function w:IsEnabled() return self.enabled end
 function w:SetText(v) self.text=v;if self.scripts.OnTextChanged then self.scripts.OnTextChanged(self,false) end end
 function w:GetText() return self.text end
 function w:GetStringWidth() return #self.text*7 end
 function w:GetStringHeight() return 14 end
 function w:GetFontString() self.font=self.font or frame();return self.font end
 function w:SetFocus() self.focused=true end
 function w:ClearFocus() self.focused=false end
 function w:HighlightText() self.selected=true end
 function w:SetNumeric(v) self.numeric=v end
 function w:SetMaxLetters(v) self.maxLetters=v end
 function w:CreateFontString() return frame(self) end
 for _,name in ipairs({"SetToplevel","SetClampedToScreen","EnableMouse","SetMovable","RegisterForDrag","SetWordWrap","SetAutoFocus","Raise","SetBackdrop"}) do w[name]=function() end end
 return w
end
local parent=frame();parent.width,parent.height=1600,900;env.UIParent=parent
function env.CreateFrame(_,name,owner) local w=frame(owner);if name then env[name]=w end;return w end
local native=frame(parent);native.EditBox=frame(native)
function env.StaticPopup_Show(which)
 native.which=which;env.StaticPopupDialogs[which].OnShow(native);native:Show();return native
end
assert(loadfile(root.."/Modules/Dialogs.lua","t",env))("BetterFriendlist",BFL)
local dialogs=modules.Dialogs
for _,value in ipairs({"https://discord.gg/example","https://github.com/owner/project/issues","https://ko-fi.com/example","Friend-Realm"}) do
 local w=dialogs:ShowCopy(value,"Copy",350)
 check(w~=native and w.skinned and w.EditBox.skinned and w.button1.skinned,"copy action skips the private themed dialog")
 check(w.EditBox:GetText()==value and w.EditBox.selected and w.EditBox.focused,"copy value is not selected and focused")
 check(not w.button2:IsShown() and w.button1.points[1][1]=="BOTTOM","copy dialog does not have a single centered Close button")
 check(w.EditBox:GetWidth()==350 and w:GetWidth()>=398,"copy input clips beyond its dialog")
 w.EditBox.scripts.OnEscapePressed();check(not w:IsShown(),"Escape does not close copy dialog")
 dialogs:ShowCopy(value,"Copy",350);controlDown=true;w.EditBox.scripts.OnKeyUp(w.EditBox,"C");check(not w:IsShown(),"Ctrl-C does not close the private copy dialog")
end
env.StaticPopupDialogs.BETTER_FRIENDLIST_CREATE_GROUP={text="Create Group",button1="Create",button2="Cancel"}
local group=dialogs:ShowInput("BETTER_FRIENDLIST_CREATE_GROUP")
check(group.button2:IsShown() and group.button1.points[1][1]=="BOTTOMRIGHT","copy-only layout leaked into Create Group")
group.EditBox.scripts.OnKeyUp(group.EditBox,"C")
check(group:IsShown(),"copy-only key handling leaked into a normal input dialog")
check(group.EditBox:GetText()=="" and group.EditBox.numeric==false and group.EditBox.maxLetters==0,"copy text/input restrictions leaked into Create Group")
group:Hide();profile.useThemedDialogs=false
local result=dialogs:ShowCopy("Copied Name","Copy",300)
check(result==native and native.EditBox:GetText()=="Copied Name","native-dialog preference is ignored for copy workflows")
check(native.EditBox.scripts.OnKeyUp==nil,"a copy handler was installed on a shared native edit box")
check(not native.skinned and not native.EditBox.skinned,"a shared native popup was skinned by BFL")
-- The friend-menu tag entry must use the same private/native preference.
local file=assert(io.open(root.."/Modules/FriendTags.lua","rb"));local source=file:read("*a"):gsub("\r\n","\n");file:close()
local first=assert(source:find("function FriendTags:ShowCustomTagDialog(",1,true))
local last=assert(source:find("\nfunction ",first+1,true))
local tags={};env.FriendTags=tags
env.StaticPopupDialogs.BFL_FRIEND_TAGS_CREATE_CUSTOM_TAG={text="Tag for %s",button1="Create",button2="Cancel",OnShow=function(w) w.EditBox:SetText("") end}
assert(load(source:sub(first,last-1),"friend-menu tag dialog","t",env))()
profile.useThemedDialogs=true
local friend={id="isolated-friend"}
tags:ShowCustomTagDialog(friend,"Example",function() end)
check(dialogs.inputDialog:IsShown() and dialogs.inputDialog.data.friend==friend,"friend-menu custom tag still bypasses BFL dialogs")
check(dialogs.inputDialog.button2:IsShown() and dialogs.inputDialog.EditBox:GetText()=="","copy layout/value leaked into friend-menu tag creation")
dialogs.inputDialog:Hide();profile.useThemedDialogs=false
tags:ShowCustomTagDialog(friend,"Example",function() end)
check(native.which=="BFL_FRIEND_TAGS_CREATE_CUSTOM_TAG","native preference is ignored by friend-menu tag creation")
io.write(string.format("PASS: copy dialogs, single-button layout, keyboard handling and native preference (%d checks)\n",checks))
