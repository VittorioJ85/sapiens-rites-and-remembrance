local modules={}
function mjrequire(name)
    if not modules[name] and name:match('^ritesRemembrance/') then modules[name]=dofile(ROOT..'/RitesAndRemembrance/scripts/'..name..'.lua')end
    return assert(modules[name],name)
end
local function vector(x,y,z,w)return {x=x,y=y,z=z,w=w}end
modules['common/mjm']={vec2=vector,vec3=vector,vec4=vector}
local created=0
local function view(parent)
    created=created+1
    local v={children={},hidden=false,size=vector(1200,800)}
    if parent then parent.children[#parent.children+1]=v end
    function v:removeAllSubviews()self.children={}end
    function v:setModel()end
    return v
end
View={new=view};ColorView=View;ModelView=View
ViewPosition=function(...)return {...}end
MJPositionCenter=1;MJPositionTop=2
local buttons={types={standard_10x3=1},create=function(_,parent)return view(parent)end,
    setText=function(_,v,text)v.text=text end,setClickFunction=function(_,v,fn)v.click=fn end}
modules['mainThread/ui/uiCommon/uiStandardButton']=buttons
modules['common/model']={modelIndexForName=function(_,name)return name end}
modules['common/material']={types={ui_selected={index=1}}}
modules['mainThread/ui/uiCommon/uiPopUpButton']={create=function(_,parent)return view(parent)end,
    setItems=function(_,v,items)v.items=items end,setSelection=function(_,v,index)v.selection=index end,
    setSelectionFunction=function(_,v,fn)v.select=fn end,hidePopupMenu=function(_,v)v.closed=true end}
modules['ritesRemembrance/ui']={text=function(_,parent,text)local v=view(parent);v.text=text;return v end}
modules['mainThread/keyMapping']={getMappingIndex=function()return 1 end}
local pending,timers,nextTimer={}, {},0
modules['common/timer']=dofile(GAME..'/GameResources/scripts/common/timer.lua')
modules['common/timer']:setBridge({addCallbackTimer=function(_,delay,fn)nextTimer=nextTimer+1;timers[nextTimer]=fn;return nextTimer end,
    removeTimer=function(_,id)timers[id]=nil end})
local logic={callServerFunction=function(_,name,data,callback)pending[#pending+1]={name=name,data=data,callback=callback}end}
modules['mainThread/logicInterface']=logic
local plan={types={rrTribalCeremony={index='ceremony'},fill={index='fill'},clear={index='clear'}}}
modules['common/plan']=plan
modules['common/skill']={types={rrRemembrance={index='remember'}}}
modules['common/research']={types={rrRemembrance={index='remember'}}}
modules['common/constructable']={types={}}
local ui=mjrequire 'ritesRemembrance/ceremonyUI'
local world={tribeID='a'}
local gameUI={view=view(),updateUIHidden=function()end}
ui:init(gameUI,world)
local helper={completedSkillsByTribeID={a={}},availablePlansForObjectInfos=function()return {{planTypeIndex='keep'}}end,
    availablePlansForVertInfos=function()return {{planTypeIndex='ground'}}end}
dofile(ROOT..'/RitesAndRemembrance/scripts/common/planHelper.lua'):onload(helper)
assert(#helper:availablePlansForObjectInfos({},{{}},'a')==1)
helper.completedSkillsByTribeID.a.remember=true
assert(#helper:availablePlansForObjectInfos({},{{}},'a')==2)
assert(#helper:availablePlansForVertInfos({},{{}},'a')==2)
assert(#helper:availablePlansForVertInfos({},{{},{}},'a')==1)
assert(#helper:availablePlansForVertInfos({},{{}},'b')==1)
dofile(ROOT..'/RitesAndRemembrance/scripts/mainThread/logicInterface.lua'):onload(logic)
local f=assert(io.open(GAME..'/GameResources/scripts/mainThread/ui/actionUI.lua'));local source=f:read('*a');f:close()
local wheel={hide=function(self)self.hidden=true end,animateOutForOptionSelected=function()error('Must not dismiss ceremony owner')end}
local chunk=assert(loadstring(assert(source:match('(local function sendPlan.-)\nlocal cachedAvailibilityResult'))..'\nreturn sendPlan'))
setfenv(chunk,setmetatable({logicInterface=logic,plan=plan,actionUI=wheel},{__index=_G}))
local send=chunk()
dofile(ROOT..'/RitesAndRemembrance/scripts/mainThread/ui/actionUI.lua'):onload(wheel)
send('ceremony',{}, {'rock'});wheel:animateOutForOptionSelected()
assert(wheel.hidden and ui:visible())
assert(#pending==1 and pending[1].name=='rrTribalCeremony' and pending[1].data.objectID=='rock')
local function button(text,node)
    node=node or ui.overlay
    if node.text==text and node.click then return node end
    for _,child in ipairs(node.children)do local found=button(text,child);if found then return found end end
end
local slots={{id='a',pos={0,1,0},x=2.4,y=0}}
pending[1].callback({ok=true,phase='preview',serial=1,total=1,population=40,excluded=0,slots=slots})
assert(button('Gather Selected'))
button('Gather Selected').click();button('Gather Selected').click();assert(#pending==2)
assert(pending[2].data.action=='gather' and pending[2].data.serial==1)
assert(pending[2].data.selection.kind=='radius' and not pending[2].data.selection.members)
pending[2].callback({ok=true,phase='gathering',serial=1,total=1,arrived=0,gatherRemaining=300,slots=slots})
local before=created
ui.overlay.update(2);assert(#pending==3 and pending[3].data.action=='status')
pending[3].callback({ok=true,phase='gathering',serial=1,total=1,arrived=1,gatherRemaining=299,slots=slots})
assert(created==before,'Polling should reuse the diagram views')
assert(ui.statusText.text:find('1 / 1',1,true))
ui.overlay.update(2);local stale=pending[4]
button('Begin with Those Present').click();assert(pending[5].data.action=='begin')
stale.callback({ok=true,phase='completed',serial=1,total=1,arrived=1,slots=slots,message='stale'})
assert(ui.result.phase=='gathering')
pending[5].callback({ok=true,phase='dancing',serial=1,total=1,arrived=1,slots=slots})
assert(ui.result.phase=='dancing' and not button('Begin with Those Present'))
button('Cancel Ceremony').click();local late=pending[6]
button('Close').click();assert(not ui:visible() and next(timers)==nil)
late.callback({ok=true,phase='completed',serial=1,total=1,arrived=1,slots=slots})
assert(not ui:visible())
wheel.baseVert={uniqueID='ground'};send('ceremony',{}, {'ground'})
assert(pending[7].data.vertID=='ground' and not pending[7].data.objectID)
local timeout=timers[nextTimer];timers[nextTimer]=nil;timeout()
assert(not ui.busy and ui.message:find('unknown',1,true))
local count=#pending
logic:callServerFunction('addPlans',{planTypeIndex='ceremony',objectOrVertIDs={'one','two'}})
assert(#pending==count)
ui:open({action='preview',objectID='rock'});local obsolete=pending[#pending]
world.tribeID='b';ui.overlay.update(1)
obsolete.callback({ok=true,phase='preview',serial=7,total=1,excluded=0,slots=slots})
assert(not ui:visible() and ui.result==nil and next(timers)==nil)
-- Native control callbacks: radius wheel/drag, reverse box drag and full reset.
local selection=mjrequire 'ritesRemembrance/ceremonySelectionUI'
local chosen=selection.create(view(),{{x=-2,y=0},{x=2,y=0},{x=0,y=4}},true)
assert(chosen.count==3 and #chosen.control.items==2)
chosen.area.mouseWheel(nil,{y=1});assert(chosen.count==0)
chosen.area.mouseDown(0,{x=155+3*29,y=155});assert(chosen.count==2)
chosen.area.mouseUp(0,{x=155+3*29,y=155})
chosen.control.select(2);assert(chosen.count==3 and chosen.selection.kind=='box')
chosen.area.mouseDown(0,{x=155+3*29,y=155+1*29})
chosen.area.mouseDragged({x=155-3*29,y=155-1*29})
chosen.area.mouseUp(0,{x=155-3*29,y=155-1*29});assert(chosen.count==2)
chosen.control.select(1);assert(chosen.count==3)
chosen:close();assert(chosen.control.closed)
ui:open({action='preview',objectID='rock'})
pending[#pending].callback({ok=true,phase='gathering',serial=9,total=1,population=40,arrived=0,gatherRemaining=100,slots=slots})
button('Invite Again').click();assert(pending[#pending].data.action=='reinvite' and pending[#pending].data.serial==9)
pending[#pending].callback({ok=true,phase='gathering',serial=9,total=1,population=40,arrived=0,gatherRemaining=100,slots=slots,notice='Invited again'})
assert(ui.statusText.text=='Invited again');ui:hide()
print('PASS: researched-only radial object/terrain entry, native sendPlan routing, preview diagram, progress without view churn, duplicate/late/lost replies, partial-start/cancel controls, closing and tribe changes')
