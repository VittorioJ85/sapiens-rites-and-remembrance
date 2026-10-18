-- Server-owned ceremony lifecycle. Client messages never contain participants,
-- durations, rewards, transforms or paths. IDs resolve against the current world.
local ceremony={duration=30,gatherTimeout=300,previewLifetime=180,reinviteDelay=15,maxAutomaticInvites=3}
local m=mjrequire "common/mjm"
local validation=mjrequire "ritesRemembrance/validation"
local formation=mjrequire "ritesRemembrance/ceremonyFormation"
local rewards=mjrequire "ritesRemembrance/ceremonyRewards"
local selection=mjrequire "ritesRemembrance/ceremonySelection"
local function save(service,event) service:put("ceremony:"..event.tribe,event) end
local function active(event) return event and (event.phase=="gathering" or event.phase=="dancing") end
local function yearLength(service)
    local length=service.world:getYearLength()
    if type(length)=="number" and length>0 and length<math.huge then return length end
end
local function annualWait(service,event)
    if not event or not event.started then return 0 end
    -- Upgrade retained older ceremonies once; never restart their waiting period.
    if not event.nextCeremonyAt then
        local length=yearLength(service)
        if not length then return nil end
        event.nextCeremonyAt=event.started+length;save(service,event)
    end
    return math.max(0,event.nextCeremonyAt-service.world:getWorldTime())
end
local function current(sapien,event)
    local first=sapien and sapien.sharedState.orderQueue and sapien.sharedState.orderQueue[1]
    return first and first.orderTypeIndex==(mjrequire "common/order").types.rrTribalCeremony.index and
        first.context and first.context.rrCeremony==event.serial and first.context.rrTribe==event.tribe
end
function ceremony.eligible(sapien)
    local state=sapien.sharedState
    if state.dead then return false end
    if (mjrequire "common/statusEffect"):cantDoMostWorkDueToEffects(state.statusEffects) then return false end
    local types=(mjrequire "common/order").types
    for _,entry in ipairs(state.orderQueue or {}) do
        for _,key in ipairs({"fall","flee","fight","rrRememberAncestors","rrRememberTogether","rrTribalCeremony"}) do
            if types[key] and entry.orderTypeIndex==types[key].index then return false end
        end
    end
    return true
end
local function participants(service,tribe)
    local result,total={},0
    service.gom:callFunctionForAllSapiensInTribe(tribe,function(sapien)
        if not sapien.sharedState.dead then
            total=total+1
            if ceremony.eligible(sapien) then result[#result+1]=sapien end
        end
    end)
    table.sort(result,function(a,b)return a.uniqueID<b.uniqueID end)
    return result,total
end
local function population(service,tribe)
    local total=0
    service.gom:callFunctionForAllSapiensInTribe(tribe,function(sapien)
        if not sapien.sharedState.dead then total=total+1 end
    end)
    return total
end
local function invite(service,event,member,manual)
    local sapien=service.gom:getObjectWithID(member.id)
    if not sapien or sapien.sharedState.tribeID~=event.tribe then return false end
    local now=service.world:getWorldTime()
    if member.lastInvite and now-member.lastInvite<ceremony.reinviteDelay then return false end
    if not manual and (member.invites or 0)>=ceremony.maxAutomaticInvites then return false end
    -- Never restart a valid path or waiting participant: asynchronous paths need
    -- time to finish, and repeated cancellation can itself prevent arrival.
    if current(sapien,event) or not ceremony.eligible(sapien) then return false end
    local sapiens=mjrequire "server/serverSapien"
    if not sapiens:cancelAllOrders(sapien,false,true) then return false end
    (mjrequire "server/objects/serverSeat"):removeAnyNodeAssignmentForSapien(sapien)
    sapiens:dropHeldInventoryImmediately(sapien)
    local order=mjrequire "common/order"
    local path=order:createOrderPathInfo(nil,(mjrequire "common/pathFinding").proximityTypes.goalPos,nil,m.vec3(unpack(member.pos)))
    sapiens:addOrder(sapien,order.types.rrTribalCeremony.index,path,nil,{rrCeremony=event.serial,rrTribe=event.tribe},false)
    sapiens:cancelWaitOrder(sapien)
    member.lastInvite=now;member.invites=(member.invites or 0)+1
    return current(sapien,event)
end
function ceremony.reinvite(service,event,manual)
    local count=0
    for _,member in ipairs(event.members)do
        if invite(service,event,member,manual) then count=count+1 end
        if not manual and count>=8 then break end -- bound automatic work per server tick
    end
    if count>0 then save(service,event) end
    return count
end
local function release(service,event)
    local sapiens=mjrequire "server/serverSapien"
    for _,member in ipairs(event.members) do
        local sapien=service.gom:getObjectWithID(member.id)
        if current(sapien,event) then sapiens:cancelOrderAtQueueIndex(sapien,1,false) end
    end
end
function ceremony.cancel(service,event,message)
    if not active(event) then return end
    event.phase="cancelled";event.message=message or "The ceremony was cancelled. No bonus was granted."
    save(service,event);release(service,event)
end
local function arrived(service,event,member,stage)
    local sapien=service.gom:getObjectWithID(member.id)
    if not current(sapien,event) or sapien.sharedState.tribeID~=event.tribe or sapien.sharedState.dead then return nil end
    if (mjrequire "common/statusEffect"):cantDoMostWorkDueToEffects(sapien.sharedState.statusEffects) then return nil end
    local state=sapien.sharedState.actionState
    if state and state.sequenceTypeIndex==(mjrequire "common/actionSequence").types.rrTribalCeremony.index and
        state.progressIndex==stage and m.length2(sapien.pos-m.vec3(unpack(member.pos)))<=mj:mToP(1.1)^2 then return sapien end
end
function ceremony.begin(service,event,allowPartial)
    local tribeSize=population(service,event.tribe)
    if tribeSize<rewards.minimumPopulation then return false end
    local year=yearLength(service)
    if not year then return false end
    local ready={}
    for _,member in ipairs(event.members) do
        if arrived(service,event,member,2) then ready[#ready+1]=member end
    end
    if #ready==0 or (not allowPartial and #ready~=#event.members) then return false end
    -- Cancel only outstanding orders for this event; never cancel replacement jobs.
    local sapiens=mjrequire "server/serverSapien"
    for _,member in ipairs(event.members) do
        if not arrived(service,event,member,2) then
            local sapien=service.gom:getObjectWithID(member.id)
            if current(sapien,event) then sapiens:cancelOrderAtQueueIndex(sapien,1,false) end
        end
    end
    event.population=math.max(event.population or tribeSize,tribeSize)
    event.members=ready;event.phase="dancing";event.started=service.world:getWorldTime()
    -- Starting the dance consumes the yearly ceremony, even without a reward.
    event.nextCeremonyAt=event.started+year;save(service,event)
    local center=m.vec3(unpack(event.center))
    for _,member in ipairs(ready) do
        local sapien=service.gom:getObjectWithID(member.id)
        local up=m.normalize(sapien.pos)
        service.gom:setRotation(sapien.uniqueID,m.createUpAlignedRotationMatrix(up,m.normalize(center-sapien.pos)))
        sapiens:startNextAction(sapien);service.gom:saveObject(sapien.uniqueID)
    end
    return true
end
function ceremony.update(service,event,skipInvitations)
    if not active(event) then return end
    local now=service.world:getWorldTime()
    if event.phase=="gathering" then
        if ceremony.begin(service,event,false) then return end
        if now-event.created>=ceremony.gatherTimeout then
            ceremony.cancel(service,event,"The gathering timed out. Choose a more accessible place or begin with those present before the time limit.")
            return
        end
        if not skipInvitations then ceremony.reinvite(service,event,false) end
    else
        local remaining={}
        for _,member in ipairs(event.members) do
            if arrived(service,event,member,3) then remaining[#remaining+1]=member
            else
                local sapien=service.gom:getObjectWithID(member.id)
                if current(sapien,event) then (mjrequire "server/serverSapien"):cancelOrderAtQueueIndex(sapien,1,false) end
            end
        end
        if #remaining==0 then ceremony.cancel(service,event,"Nobody completed the dance. No bonus was granted.");return end
        if #remaining~=#event.members then event.members=remaining;save(service,event) end
        if now-event.started>=ceremony.duration then
            -- A death/departure must not inflate an ongoing ceremony's percentage;
            -- new arrivals increase the denominator. Only uninterrupted dancers count.
            local tribeSize=population(service,event.tribe)
            event.population=math.max(event.population or tribeSize,tribeSize)
            local reward=rewards.calculate(#event.members,event.population)
            if tribeSize<rewards.minimumPopulation then reward=rewards.calculate(0,tribeSize) end
            event.reward=reward
            if reward.days==0 then
                event.phase="completed";event.message=rewards.describe(reward).." No bonus was granted."
                save(service,event);release(service,event);return
            end
            local duration=reward.days*service.world:getDayLength()
            if not (duration>0 and duration<math.huge) then ceremony.cancel(service,event,"The world's day length is unavailable.");return end
            event.phase="completed";event.expires=now+duration
            event.message="Participants receive "..rewards.describe(reward).."."
            save(service,event) -- mark completion before granting, so repeated updates cannot stack rewards
            local status=mjrequire "server/serverStatusEffects"
            local types=(mjrequire "common/statusEffect").types
            local effect=reward.happiness==2 and types.rrTribalUnityFull.index or types.rrTribalUnity.index
            local moods=(mjrequire "common/mood").types
            for _,member in ipairs(event.members)do
                local sapien=service.gom:getObjectWithID(member.id)
                if sapien and not sapien.sharedState.dead and sapien.sharedState.tribeID==event.tribe then
                    sapien.sharedState:remove("statusEffects",types.rrTribalUnity.index)
                    sapien.sharedState:remove("statusEffects",types.rrTribalUnityFull.index)
                    sapien.sharedState:set("rrTribalUnityWorkPercent",reward.workPercent)
                    status:setTimedEffect(sapien.sharedState,effect,duration)
                    for _,index in ipairs({moods.happySad.index,moods.loyalty.index}) do
                        sapien.sharedState:set("moods",index,math.min(5,(sapien.sharedState.moods[index] or 3)+reward.happiness))
                    end
                    service.gom:saveObject(sapien.uniqueID)
                end
            end
            release(service,event)
        end
    end
end
local function response(service,event)
    local count=0
    for _,member in ipairs(event.members or {}) do if arrived(service,event,member,event.phase=="dancing" and 3 or 2) then count=count+1 end end
    local tribeSize=math.max(event.population or 0,population(service,event.tribe))
    return {ok=true,phase=event.phase,serial=event.serial,arrived=count,total=#event.members,population=tribeSize,
        reward=event.reward or rewards.calculate(event.phase=="preview" and #event.members or count,tribeSize),
        message=event.message,slots=event.members,excluded=event.excluded,
        remaining=math.max(0,(event.expires or 0)-service.world:getWorldTime()),
        gatherRemaining=math.max(0,event.created+ceremony.gatherTimeout-service.world:getWorldTime())}
end
function ceremony.request(service,clientID,request)
    if not service.db or type(request)~="table" then return {error="Ceremony service is unavailable."} end
    for key in pairs(request) do
        if key~="action" and key~="objectID" and key~="vertID" and key~="serial" and key~="selection" then return {error="Invalid ceremony request."} end
    end
    if not selection.valid(request.selection) then return {error="Invalid formation selection."} end
    local tribe=service.world:tribeIDForClientID(clientID)
    if not tribe or not service:unlocked(tribe) then return {error="First discover Rites and Remembrance."} end
    local event=service:get("ceremony:"..tribe)
    if active(event) then ceremony.update(service,event,request.action=="reinvite") end
    if request.action=="status" then return event and response(service,event) or {ok=true,phase="none"} end
    if request.action=="cancel" or request.action=="begin" or request.action=="reinvite" then
        if not active(event) or request.serial~=event.serial then return {error="This ceremony is no longer active."} end
        if request.action=="cancel" then ceremony.cancel(service,event)
        elseif request.action=="reinvite" then
            if event.phase~="gathering" then return {error="Invitations are closed once the dance starts."} end
            local count=ceremony.reinvite(service,event,true)
            local result=response(service,event)
            result.notice=count.." missing participants invited again. Existing paths are kept; retry delay is 15 seconds."
            return result
        elseif event.phase=="gathering" then
            if not ceremony.begin(service,event,true) then return {error="At least 25 tribe members, one arrived participant and a valid world year length are required to begin."} end
        end
        return response(service,event)
    end
    if request.action~="preview" and request.action~="gather" then return {error="Unknown ceremony action."} end
    if active(event) then return response(service,event) end
    local now=service.world:getWorldTime()
    local wait=annualWait(service,event)
    if wait==nil then return {error="The world's year length is unavailable."} end
    if wait>0 then
        local day=service.world:getDayLength()
        local remaining=type(day)=="number" and day>0 and day<math.huge and
            string.format("%.1f game days",math.ceil(wait/day*10)/10) or string.format("%.0f simulation seconds",math.ceil(wait))
        return {error="A tribal ceremony may be held only once per game year. Next ceremony in "..remaining.."."}
    end
    if event and event.expires and event.expires>now then return {error="Tribal Unity is still active. Wait until this ceremony's bonus expires."} end
    if request.action=="preview" then
        local target
        if validation.id(request.objectID) and not request.vertID then
            target=service.gom:getObjectWithID(request.objectID)
            if target and target.sharedState.tribeID and target.sharedState.tribeID~=tribe then target=nil end
        elseif validation.id(request.vertID) and not request.objectID then
            target=(mjrequire "server/serverTerrain"):getVertWithID(request.vertID)
        end
        if not target or not target.pos then return {error="Select one accessible object or ground location."} end
        local members,total=participants(service,tribe)
        if total<rewards.minimumPopulation then return {error="At least 25 tribe members are required for a tribal ceremony."} end
        if #members==0 then return {error="No tribe members can attend right now."} end
        if #members>formation.maxSlots then return {error="This ceremony supports up to 512 participants."} end
        local nearby=false
        for _,sapien in ipairs(members) do
            if m.length2(sapien.pos-target.pos)<=mj:mToP(200)^2 then nearby=true;break end
        end
        if not nearby then return {error="Choose a gathering place within 200 metres of your tribe."} end
        local slots=formation.create(target.pos,#members,function(pos,up)return formation.probe(service,pos,up)end)
        if not slots then return {error="There is not enough safe standing room. Choose a larger, flatter area."} end
        for i,slot in ipairs(slots) do slot.id=members[i].uniqueID end
        event={tribe=tribe,phase="preview",serial=(event and event.serial or 0)+1,created=now,
            center={target.pos.x,target.pos.y,target.pos.z},members=slots,excluded=total-#members,population=total}
        save(service,event)
        return response(service,event)
    end
    if not event or event.phase~="preview" or request.serial~=event.serial or now-event.created>ceremony.previewLifetime then
        return {error="The preview expired. Select the gathering place again."}
    end
    local total=population(service,tribe)
    if total<rewards.minimumPopulation then return {error="At least 25 tribe members are required for a tribal ceremony."} end
    local selected=selection.filter(event.members,request.selection)
    if #selected==0 then return {error="Select at least one standing place in the preview."} end
    for _,member in ipairs(selected) do
        local sapien=service.gom:getObjectWithID(member.id)
        if not sapien or sapien.sharedState.tribeID~=tribe or not ceremony.eligible(sapien) or
            not formation.probe(service,m.vec3(unpack(member.pos)),m.normalize(m.vec3(unpack(member.pos)))) then
            return {error="The gathering area or participants changed. Select the place again."}
        end
    end
    event.members=selected;event.population=total;event.phase="gathering";event.created=now;save(service,event)
    local activeTribes=service:get("ceremonyTribes") or {};activeTribes[tribe]=true;service:put("ceremonyTribes",activeTribes)
    for _,member in ipairs(event.members) do
        if not invite(service,event,member,true) then
            ceremony.cancel(service,event,"A participant could not leave their current activity.");return response(service,event)
        end
    end
    save(service,event)
    return response(service,event)
end
function ceremony.tick(service)
    if not service.db then return end
    local tribes=service:get("ceremonyTribes") or {}
    local changed=false
    for tribe in pairs(tribes) do
        local event=service:get("ceremony:"..tribe)
        if active(event) then ceremony.update(service,event) end
        if not active(event) then tribes[tribe]=nil;changed=true end
    end
    if changed then service:put("ceremonyTribes",tribes) end
end
return ceremony
