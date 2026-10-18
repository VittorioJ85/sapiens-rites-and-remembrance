-- A saved, server-owned rendezvous. No participant IDs or rewards come from clients.
local family={bonusDuration=2000.0,gatherTimeout=300.0,relationshipGain=0.1}
local visit=mjrequire "ritesRemembrance/ancestorVisit"

local function currentOrder(sapien,event)
    local first=sapien.sharedState.orderQueue and sapien.sharedState.orderQueue[1]
    if first and first.orderTypeIndex==(mjrequire "common/order").types.rrRememberTogether.index and
        first.objectID==event.graveID and first.context and first.context.rrFamilyVisit==event.serial then return first end
end

local function save(service,event)
    service:put("familyVisit:"..event.graveID,event)
end

function family.cancel(service,event)
    if event.phase=="completed" or event.phase=="cancelled" then return end
    event.phase="cancelled";save(service,event)
    local sapiens=mjrequire "server/serverSapien"
    for _,id in ipairs(event.members) do
        local sapien=service.gom:getObjectWithID(id)
        -- Never cancel a replacement job, combat order or a newer ceremony.
        if sapien and currentOrder(sapien,event) then sapiens:cancelOrderAtQueueIndex(sapien,1,false) end
    end
end

function family.request(service,clientID,request)
    if type(request)~="table" or not (mjrequire "ritesRemembrance/validation").id(request.objectID) then
        return {error="Invalid memorial request."}
    end
    for key in pairs(request) do if key~="objectID" then return {error="Invalid memorial request."} end end
    local tribe=service.world:tribeIDForClientID(clientID)
    local grave=service.gom:getObjectWithID(request.objectID)
    if not tribe or not grave or grave.sharedState.tribeID~=tribe or not service:unlocked(tribe) then
        return {error="Choose a completed memorial in your tribe."}
    end
    local memorial=service:memorialForObject(grave.uniqueID)
    local record=memorial and service:get("person:"..memorial.id)
    if not record then return {error="No family record is available for this memorial."} end
    local previous=service:get("familyVisit:"..grave.uniqueID)
    if previous and previous.phase~="completed" and previous.phase~="cancelled" then
        family.update(service,previous)
        previous=service:get("familyVisit:"..grave.uniqueID)
        if previous.phase~="completed" and previous.phase~="cancelled" then
            return {error="The family is already gathering or remembering here."}
        end
    end
    local members,seen={},{}
    local types=(mjrequire "common/gameObject").types
    for _,id in ipairs(record.familyIDs or {}) do
        local sapien=service.gom:getObjectWithID(id)
        if sapien and sapien.objectTypeIndex==types.sapien.index and sapien.sharedState.tribeID==tribe and not seen[id] then
            if not visit.familyRecord(service,grave,sapien) then return {error="Choose a completed family memorial."} end
            if visit.hasRemembranceBonus(sapien) then
                return {error=(sapien.sharedState.name or "A family member").." already has a remembrance bonus. The family can remember together after all remembrance bonuses expire."}
            end
            if not visit.canSummon(sapien) then
                return {error=(sapien.sharedState.name or "A relative").." cannot attend due to their condition, a fall or another visit."}
            end
            seen[id]=true;members[#members+1]=id
        end
    end
    if #members==0 then return {error="No living relatives in your tribe are available."} end
    table.sort(members)
    local event={graveID=grave.uniqueID,memorialID=record.id,members=members,phase="gathering",
        serial=(previous and previous.serial or 0)+1,created=service.world:getWorldTime()}
    save(service,event)
    for _,id in ipairs(members) do
        local sapien=service.gom:getObjectWithID(id)
        if not visit.summon(sapien,grave,(mjrequire "common/order").types.rrRememberTogether.index,
            {rrMemorialID=record.id,rrFamilyVisit=event.serial}) then
            family.cancel(service,event)
            return {error="The whole family could not be assigned. Please try again when everyone can reach the grave."}
        end
    end
    return {ok=true,message="All "..#members.." living relatives are gathering at the memorial."}
end

function family.update(service,event)
    if event.phase=="completed" or event.phase=="cancelled" then return end
    local grave=service.gom:getObjectWithID(event.graveID)
    local now=service.world:getWorldTime()
    if not grave or (event.phase=="gathering" and now-event.created>family.gatherTimeout) then
        family.cancel(service,event);return
    end
    local participants,allArrived={},true
    for _,id in ipairs(event.members) do
        local sapien=service.gom:getObjectWithID(id)
        if not visit.familyRecord(service,grave,sapien) or not currentOrder(sapien,event) or not visit.eligible(sapien) then
            family.cancel(service,event);return
        end
        local state=sapien.sharedState.actionState
        local progress=state and state.sequenceTypeIndex==(mjrequire "common/actionSequence").types.rrRememberTogether.index and state.progressIndex
        local close=(mjrequire "common/mjm").length2(sapien.pos-grave.pos)<=mj:mToP(3)^2
        if event.phase=="remembering" and (progress~=3 or not close) then family.cancel(service,event);return end
        if progress~=2 or not close then allArrived=false end
        participants[#participants+1]=sapien
    end
    local sapiens=mjrequire "server/serverSapien"
    if event.phase=="gathering" and allArrived then
        event.phase="remembering";event.started=now;save(service,event)
        -- Advance everyone in one server update: early arrivals wait, rather than
        -- finishing separate visits before their relatives reach the memorial.
        for _,sapien in ipairs(participants) do sapiens:startNextAction(sapien);service.gom:saveObject(sapien.uniqueID) end
    elseif event.phase=="remembering" and now-event.started>=visit.duration then
        event.phase="completed";save(service,event)
        local effects=mjrequire "server/serverStatusEffects"
        local effect=(mjrequire "common/statusEffect").types.rrFamilyRemembered.index
        local mood=(mjrequire "common/mood").types
        for _,sapien in ipairs(participants) do
            effects:setTimedEffect(sapien.sharedState,effect,family.bonusDuration)
            for _,index in ipairs({mood.happySad.index,mood.loyalty.index}) do
                sapien.sharedState:set("moods",index,math.min(5,(sapien.sharedState.moods[index] or 3)+1))
            end
            -- Native social API clamps values and persists lazy relationship state.
            -- Both directions are intentional; no family/partner flags are changed.
            for _,other in ipairs(participants) do
                if other.uniqueID~=sapien.uniqueID then
                    sapiens:addToBondAndMood(sapien,other.uniqueID,family.relationshipGain,family.relationshipGain)
                end
            end
            sapiens:completeOrder(sapien)
            service.gom:saveObject(sapien.uniqueID)
        end
    end
end

function family.tick(service,sapien,orderState)
    local event=service:get("familyVisit:"..orderState.objectID)
    if not event or not orderState.context or event.serial~=orderState.context.rrFamilyVisit or
        event.phase=="completed" or event.phase=="cancelled" then
        local first=sapien.sharedState.orderQueue and sapien.sharedState.orderQueue[1]
        if first==orderState then (mjrequire "server/serverSapien"):cancelOrderAtQueueIndex(sapien,1,false) end
        return false
    end
    family.update(service,event)
    return currentOrder(sapien,event)~=nil
end
return family
