-- Engine-independent state-machine tests, using the installation's real vector
-- implementation. Physics/network/AI scheduling are controlled test doubles.
local modules={}
function mjrequire(name)
    if modules[name] then return modules[name] end
    if name:match('^ritesRemembrance/') then modules[name]=dofile(ROOT..'/RitesAndRemembrance/scripts/'..name..'.lua')
    else error(name) end
    return modules[name]
end
local m=dofile(GAME..'/GameResources/scripts/common/mjm.lua');modules['common/mjm']=m
mj={mToP=function(_,n)return n/100000 end}
local function clone(t)
    if type(t)~='table' then return t end
    local r={};for k,v in pairs(t)do r[k]=clone(v)end;return r
end
local function state(t)
    function t:remove(key,index)if index then self[key][index]=nil else self[key]=nil end end
    function t:set(...)
        local args={...};local current=self
        for i=1,#args-2 do current[args[i]]=current[args[i]] or {};current=current[args[i]] end
        current[args[#args-1]]=args[#args]
    end
    return t
end
local function types(keys)
    local t={};for _,k in ipairs(keys)do t[k]={index=k,key=k}end;return t
end
modules['common/typeMaps']={insert=function(_,_,t,v)v.index=v.key;t[v.key]=v end}
local order={types=types({'fall','fight','flee','rrRememberAncestors','rrRememberTogether'})}
modules['common/order']=order;dofile(ROOT..'/RitesAndRemembrance/scripts/common/order.lua'):onload(order)
-- Extract the real native path/order constructors, including their public signatures.
local function source(name)local f=assert(io.open(GAME..'/GameResources/scripts/'..name..'.lua'));local s=f:read('*a');f:close();return s end
local native=assert(source('common/order'):match('(function order:createOrderPathInfo.-)\nreturn order'))
local chunk=assert(loadstring(native));setfenv(chunk,setmetatable({order=order},{__index=_G}));chunk()
modules['common/action']={types=types({'moveTo','idle','dig','inspect','knap','chop','sit','playDrum','throwProjectile'})}
dofile(ROOT..'/RitesAndRemembrance/scripts/common/action.lua'):onload(modules['common/action'])
modules['common/actionSequence']={types={}}
dofile(ROOT..'/RitesAndRemembrance/scripts/common/actionSequence.lua'):onload(modules['common/actionSequence'])
local effects={types={},orderedPositiveEffects={},orderedNegativeEffects={},cantDoMostWorkDueToEffects=function(_,e)return e.unconscious end}
modules['common/statusEffect']=effects;dofile(ROOT..'/RitesAndRemembrance/scripts/common/statusEffect.lua'):onload(effects)
modules['common/mood']={types=types({'happySad','loyalty'})}
modules['common/skill']={types=types({'researching'})}
modules['common/pathFinding']={proximityTypes={goalPos=1}}
local saves,rewards,interrupts=0,0,0
local people={}
local center=m.vec3(0,1.001,0)
local function person(id,tribe)
    return {uniqueID=id,pos=center,sharedState=state({tribeID=tribe or 'a',statusEffects={},moods={happySad=3,loyalty=4},orderQueue={}})}
end
local function resetPeople(total)
    people={a=person('a'),b=person('b'),foreign=person('foreign','b')}
    for i=3,(total or 40)do local id=string.format('p%02d',i);people[id]=person(id)end
end
resetPeople()
local targets={rock={uniqueID='rock',pos=center,sharedState={}},foreignRock={uniqueID='foreignRock',pos=center,sharedState={tribeID='b'}}}
local records={}
local now=10
local world={tribeIDForClientID=function(_,id)if id=='alice' then return 'a' elseif id=='bob' then return 'b'end end,
    getWorldTime=function()return now end,getDayLength=function()return 2880 end,getYearLength=function()return 23040 end}
local gom={getObjectWithID=function(_,id)return people[id] or targets[id]end,
    callFunctionForAllSapiensInTribe=function(_,tribe,fn)for _,p in pairs(people)do if p.sharedState.tribeID==tribe then fn(p)end end end,
    saveObject=function()saves=saves+1 end,setRotation=function(_,id,rotation)assert(rotation);people[id].rotation=rotation end}
local service={world=world,gom=gom,db=true,get=function(_,k)return clone(records[k])end,
    put=function(_,k,v)records[k]=clone(v)end,unlocked=function(_,tribe)return tribe=='a' end}
local sapiens={cancelAllOrders=function(_,p)interrupts=interrupts+1;p.sharedState.orderQueue={};return true end,
    cancelOrderAtQueueIndex=function(_,p)p.sharedState.orderQueue={};p.sharedState.actionState=nil end,
    dropHeldInventoryImmediately=function()end,cancelWaitOrder=function()end,
    startNextAction=function(_,p)p.sharedState.actionState.progressIndex=p.sharedState.actionState.progressIndex+1 end,
    addOrder=function(_,p,kind,path,obj,context)
        assert(not obj and path.goalPosOrNil and path.proximityType==1)
        p.sharedState.orderQueue={order:createOrder(kind,p,path,obj,context)}
        p.sharedState.actionState={sequenceTypeIndex='rrTribalCeremony',progressIndex=1}
    end}
modules['server/serverSapien']=sapiens
modules['server/objects/serverSeat']={removeAnyNodeAssignmentForSapien=function()end}
modules['server/serverTerrain']={getVertWithID=function(_,id)if id=='ground' then return {pos=center}end end}
modules['server/serverStatusEffects']={setTimedEffect=function(_,s,index,duration)
    rewards=rewards+1;s:set('statusEffects',index,{timer=duration})
end}
local blocked=false
modules['common/physicsSets']={walkable=1,pathColliders=2}
modules['common/worldHelper']={getBelowSurfacePos=function(_,pos)return pos end,getWalkableUpVector=function(_,pos)return m.normalize(pos)end}
modules['common/physics']={boxTest=function()return {hasHitObject=blocked}end}
local ceremony=mjrequire 'ritesRemembrance/tribalCeremony'
local formation=mjrequire 'ritesRemembrance/ceremonyFormation'
local function request(data,client)return ceremony.request(service,client or 'alice',data)end
local function event()return service:get('ceremony:a')end
local function prepare(shape)
    local p=request({action='preview',vertID='ground'});assert(p.phase=='preview',p.error)
    assert(p.population>=25 and interrupts==0)
    local result=request({action='gather',serial=p.serial,selection=shape});assert(result.phase=='gathering',result.error)
    return result
end
local function arrive(id)
    for _,slot in ipairs(event().members)do if slot.id==id then
        people[id].pos=m.vec3(unpack(slot.pos));people[id].sharedState.actionState.progressIndex=2
    end end
end
assert(request({action='preview',objectID='rock'},'nobody').error)
assert(request({action='preview',objectID='rock'},'bob').error)
assert(request({action='preview',objectID='foreignRock'}).error)
assert(request({action='preview',objectID='rock',duration=1}).error)
assert(request({action='preview',objectID='rock',vertID='ground'}).error)
assert(request({action='preview',objectID='missing'}).error)
blocked=true;assert(request({action='preview',objectID='rock'}).error);blocked=false
local p=request({action='preview',objectID='rock'});now=now+181
assert(request({action='gather',serial=p.serial}).error and interrupts==0)
local p=prepare();assert(interrupts==40)
assert(request({action='gather',serial=p.serial}).phase=='gathering' and interrupts==40)
assert(request({action='preview',objectID='rock'}).serial==p.serial and interrupts==40)
assert(request({action='begin',serial=p.serial+1}).error)
assert(request({action='begin',serial=p.serial}).error)
arrive('a');ceremony.tick(service);assert(event().phase=='gathering')
for _,slot in ipairs(event().members)do arrive(slot.id)end
ceremony.tick(service);assert(event().phase=='dancing')
assert(people.a.rotation and people.b.rotation)
-- Persisted events are re-read by a newly initialized service; no transient barrier state.
service= setmetatable({db=true,world=world,gom=gom},{__index=service})
now=now+29;ceremony.tick(service);assert(rewards==0)
now=now+1;ceremony.tick(service);assert(event().phase=='completed' and rewards==40)
assert(people.a.sharedState.moods.happySad==5 and people.a.sharedState.moods.loyalty==5)
assert(people.a.sharedState.statusEffects.rrTribalUnityFull.timer==8640)
assert(people.a.sharedState.rrTribalUnityWorkPercent==20)
assert(not people.foreign.sharedState.statusEffects.rrTribalUnity)
assert(#people.a.sharedState.orderQueue==0)
ceremony.tick(service);assert(rewards==40)
assert(request({action='preview',objectID='rock'}).error)
assert(request({action='cancel',serial=p.serial}).error)
-- The annual restriction outlives the reward and survives a service reload.
local annualEnd=event().nextCeremonyAt
assert(annualEnd==event().started+world:getYearLength())
now=event().expires+1
assert(request({action='preview',objectID='rock'}).error:find('once per game year',1,true))
local saved=event();saved.nextCeremonyAt=nil;service:put('ceremony:a',saved)
assert(request({action='gather',serial=p.serial}).error:find('once per game year',1,true))
assert(event().nextCeremonyAt==annualEnd,'Migration uses the old dance start, not the current time')
now=annualEnd-1;assert(request({action='preview',objectID='rock'}).error)
now=annualEnd;assert(request({action='preview',objectID='rock'}).phase=='preview')
local function fresh(total)
    records={};resetPeople(total);interrupts=0;rewards=0;now=now+10000
end
local rewardRules=mjrequire 'ritesRemembrance/ceremonyRewards'
for _,case in ipairs({{40,2,20,3},{30,2,15,3},{24,2,12,3},{20,1,10,3},{19,1,10,1},{10,1,5,1},{9,0,0,0}})do
    fresh();local p=prepare()
    local selected={}
    for i,slot in ipairs(event().members)do if i<=case[1]then arrive(slot.id);selected[slot.id]=true end end
    assert(request({action='begin',serial=p.serial}).phase=='dancing')
    now=now+30;ceremony.tick(service)
    local final=event();assert(final.phase=='completed')
    assert(final.reward.happiness==case[2] and final.reward.workPercent==case[3] and final.reward.days==case[4])
    assert(rewards==(case[2]>0 and case[1] or 0))
    for id,sapien in pairs(people)do
        local effect=sapien.sharedState.statusEffects.rrTribalUnity or sapien.sharedState.statusEffects.rrTribalUnityFull
        if selected[id] and case[2]>0 then assert(effect and effect.timer==2880*case[4])
        else assert(not effect,'Nonparticipants must never receive a reward')end
    end
end
fresh(24);assert(request({action='preview',objectID='rock'}).error)
fresh(25);local p=prepare();assert(p.total==25)
assert(rewardRules.calculate(6,25).days==0 and rewardRules.calculate(7,25).workPercent==6)
assert(rewardRules.calculate(51,100).happiness==2 and rewardRules.calculate(50,100).happiness==1)
assert(rewardRules.calculate(49,100).days==1 and rewardRules.calculate(50,100).days==3)
fresh();local p=prepare();for _,slot in ipairs(event().members)do arrive(slot.id)end;ceremony.tick(service)
people.b.sharedState.orderQueue={{orderTypeIndex='flee'}}
ceremony.tick(service);assert(event().phase=='dancing' and #event().members==39 and rewards==0)
assert(people.b.sharedState.orderQueue[1].orderTypeIndex=='flee')
now=now+30;ceremony.tick(service);assert(event().reward.happiness==2 and rewards==39)
assert(not people.b.sharedState.statusEffects.rrTribalUnity)
-- A changing roster cannot manufacture a majority or bypass the minimum tribe.
fresh();local p=prepare()
for i,slot in ipairs(event().members)do if i<=20 then arrive(slot.id)end end
assert(request({action='begin',serial=p.serial}).phase=='dancing')
local dancers={};for _,slot in ipairs(event().members)do dancers[slot.id]=true end
for id,sapien in pairs(people)do if id~='foreign' and not dancers[id] then sapien.sharedState.dead=true;break end end
now=now+30;ceremony.tick(service)
assert(event().reward.population==40 and event().reward.happiness==1)
fresh(25);local p=prepare();for _,slot in ipairs(event().members)do arrive(slot.id)end;ceremony.tick(service)
people.b.sharedState.dead=true;now=now+30;ceremony.tick(service)
assert(event().phase=='completed' and event().reward.days==0 and rewards==0)
fresh();prepare();now=now+301;ceremony.tick(service)
assert(event().phase=='cancelled' and #people.a.sharedState.orderQueue==0 and rewards==0)
fresh();local p=prepare();assert(request({action='cancel',serial=p.serial}).phase=='cancelled' and rewards==0)
assert(request({action='preview',objectID='rock'}).phase=='preview','Cancelled gathering does not consume the year')
fresh();local p=prepare();arrive('a')
assert(request({action='begin',serial=p.serial}).phase=='dancing')
assert(request({action='cancel',serial=p.serial}).phase=='cancelled')
assert(request({action='preview',objectID='rock'}).error:find('once per game year',1,true))
fresh();local p=prepare();arrive('a');assert(request({action='begin',serial=p.serial}).phase=='dancing')
now=now+30;ceremony.tick(service)
assert(rewards==0 and request({action='preview',objectID='rock'}).error:find('once per game year',1,true))
fresh();local p=prepare();arrive('a')
local nativeYear=world.getYearLength;world.getYearLength=function()return 0/0 end
assert(request({action='begin',serial=p.serial}).error and event().phase=='gathering')
world.getYearLength=function()return 40000 end
assert(request({action='begin',serial=p.serial}).phase=='dancing')
assert(event().nextCeremonyAt==now+40000)
world.getYearLength=nativeYear
assert(event().nextCeremonyAt==now+40000,'Changing year length does not reset an existing cooldown')
print('PASS: annual gate, exact expiry, legacy migration, cancelled gathering versus started dance, no-reward ceremony, custom/invalid year length and persisted deadline')
fresh();people.b.sharedState.orderQueue={{orderTypeIndex='flee'}}
assert(not ceremony.eligible(people.b));people.b.sharedState.orderQueue={{orderTypeIndex='build'}};assert(ceremony.eligible(people.b))
-- Lost summons previously stayed missing forever; recover ordinary replacement work.
fresh();local p=prepare();people.b.sharedState.orderQueue={{orderTypeIndex='build'}}
now=now+16;ceremony.tick(service);assert(people.b.sharedState.orderQueue[1].orderTypeIndex=='rrTribalCeremony')
local issued=interrupts;ceremony.tick(service);assert(interrupts==issued,'Do not restart valid paths')
people.b.sharedState.orderQueue={{orderTypeIndex='flee'}};now=now+16;ceremony.tick(service)
assert(people.b.sharedState.orderQueue[1].orderTypeIndex=='flee')
people.b.sharedState.orderQueue={{orderTypeIndex='build'}};ceremony.tick(service)
assert(people.b.sharedState.orderQueue[1].orderTypeIndex=='rrTribalCeremony')
people.b.sharedState.orderQueue={{orderTypeIndex='build'}};now=now+16;ceremony.tick(service)
assert(people.b.sharedState.orderQueue[1].orderTypeIndex=='build','Automatic retries are bounded')
local reply=request({action='reinvite',serial=p.serial});assert(reply.notice and people.b.sharedState.orderQueue[1].orderTypeIndex=='rrTribalCeremony')
assert(request({action='reinvite',serial=p.serial+1}).error)
assert(order.types.rrTribalCeremony.allowToFinishEvenWhenVeryTired)
-- Selection is bounded geometry; the client never supplies member IDs or paths.
local selection=mjrequire 'ritesRemembrance/ceremonySelection'
for _,shape in ipairs({{kind='radius',radius=5},{kind='box',x1=-8,y1=-8,x2=0,y2=8}})do
    fresh();local preview=request({action='preview',vertID='ground'})
    local expected=selection.filter(preview.slots,shape)
    assert(#expected>0 and #expected<40)
    local chosen=request({action='gather',serial=preview.serial,selection=shape})
    assert(chosen.total==#expected and interrupts==#expected)
end
fresh();local preview=request({action='preview',objectID='rock'})
for _,shape in ipairs({{kind='radius',radius=-1},{kind='radius',radius=0/0},{kind='radius',radius=1000},
    {kind='box',x1=0,y1=0,x2=1},{kind='radius',radius=4,members={'a'}}})do
    assert(request({action='gather',serial=preview.serial,selection=shape}).error)
end
assert(request({action='gather',serial=preview.serial,selection={kind='radius',radius=0}}).error)
for _,count in ipairs({1,2,6,20,100,512})do
    local slots=assert(formation.create(center,count,function(pos)return pos end))
    assert(#slots==count)
    for i=1,#slots do for j=i+1,#slots do
        assert(m.length2(m.vec3(unpack(slots[i].pos))-m.vec3(unpack(slots[j].pos)))>=mj:mToP(2.4*.85)^2)
    end end
end
assert(not formation.create(center,513,function(pos)return pos end))
assert(not formation.create(center,1,function()return nil end))
print('PASS: population 25 gate, radius/box validation, participant-only attendance thresholds, full/partial/interrupted dance, 1/3-day rewards, bounded automatic/manual reinvites, unchanged valid paths and emergency orders, duplicate/cooldown protection, circles through 512')
-- Verify the hook preserves other multipliers and excludes research/movement/combat.
local bonus=mjrequire 'ritesRemembrance/workBonus'
local s=people.a.sharedState;s.statusEffects.rrTribalUnity={timer=1};s.orderQueue={{context={}}}
local sequences=modules['common/actionSequence'].types
for _,key in ipairs({'dig','knap','chop','moveTo','inspect','sit','playDrum','throwProjectile'})do
    sequences.test={actions={key}};s.actionState={sequenceTypeIndex='test',progressIndex=1}
    local expected=(key=='dig' or key=='knap' or key=='chop') and 1.65 or 1.5
    assert(math.abs(bonus.speed(s,1.5)-expected)<.00001)
end
sequences.test.actions={'dig'};s.orderQueue[1].context.researchTypeIndex=1
assert(bonus.speed(s,1.5)==1.5)
s.orderQueue[1].context={};s.statusEffects.rrTribalUnity=nil
assert(bonus.speed(s,1.5)==1.5)
for _,effect in ipairs({'rrTribalUnity','rrTribalUnityFull'})do
    s.statusEffects[effect]={timer=10}
    for _,percent in ipairs({5,10,12,15,20})do
        s.rrTribalUnityWorkPercent=percent
        assert(math.abs(bonus.speed(s,1.5)-1.5*(1+percent/100))<.00001)
    end
    s.statusEffects[effect]=nil
    assert(bonus.speed(s,1.5)==1.5,'A stale saved percentage alone never grants work speed')
end
print('PASS: legacy 10% and attendance-scaled productive work compose with existing multipliers; research, movement, combat, social actions and expired effects retain native speed')
