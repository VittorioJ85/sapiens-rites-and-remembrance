-- Only the server resolves relatives, chooses the visitor and grants comfort.
local visit={duration=8.0,bonusDuration=1000.0}

function visit.familyRecord(service,grave,sapien)
    local objects=(mjrequire "common/gameObject").types
    if not grave or not (mjrequire "ritesRemembrance/catalog").forObject(grave) or
        not objects[grave.objectTypeIndex].isBuiltObject then return nil end
    if not sapien or sapien.objectTypeIndex~=objects.sapien.index then return nil end
    local tribe=sapien.sharedState.tribeID
    if grave.sharedState.tribeID~=tribe then return nil end
    local memorial=service:memorialForObject(grave.uniqueID)
    local record=memorial and service:get("person:"..memorial.id)
    if not record or record.tribeID~=tribe or record.demolitionGranted then return nil end
    for _,id in ipairs(record.familyIDs or {}) do if id==sapien.uniqueID then return record end end
end

function visit.hasRemembranceBonus(sapien)
    local status=mjrequire "common/statusEffect"
    local effects=sapien.sharedState.statusEffects
    return effects[status.types.rrAncestorsRemembered.index] or effects[status.types.rrFamilyRemembered.index]
end

function visit.eligible(sapien)
    local state=sapien.sharedState
    local status=mjrequire "common/statusEffect"
    if visit.hasRemembranceBonus(sapien) then return false end
    if status:cantDoMostWorkDueToEffects(state.statusEffects) then return false end
    return true
end

function visit.canSummon(sapien)
    if not visit.eligible(sapien) then return false end
    local types=(mjrequire "common/order").types
    for _,current in ipairs(sapien.sharedState.orderQueue or {}) do
        -- Falling cannot be cancelled by the engine. Existing visits must not
        -- be replaced by a duplicate request or a competing family ceremony.
        if current.orderTypeIndex==types.fall.index or current.orderTypeIndex==types.rrRememberAncestors.index or
            current.orderTypeIndex==types.rrRememberTogether.index or
            (types.rrTribalCeremony and current.orderTypeIndex==types.rrTribalCeremony.index) then return false end
    end
    return true
end

function visit.summon(sapien,grave,orderTypeIndex,context)
    if not visit.canSummon(sapien) then return false end
    local sapiens=mjrequire "server/serverSapien"
    -- Use native cancellation to wake sleepers, detach hauling/logistics,
    -- release work assignments and clear held-item order contexts. Clear manual
    -- work assignments too, so they do not reclaim the summoned participant.
    if not sapiens:cancelAllOrders(sapien,false,true) then return false end
    (mjrequire "server/objects/serverSeat"):removeAnyNodeAssignmentForSapien(sapien)
    sapiens:dropHeldInventoryImmediately(sapien)
    local ai=mjrequire "server/sapienAI/ai"
    local path=mjrequire "common/pathFinding"
    if not ai:addOrderIfAble(sapien,orderTypeIndex,grave.uniqueID,context,path.proximityTypes.reachable,mj:mToP(2.0)) then return false end
    sapiens:cancelWaitOrder(sapien)
    return true
end

function visit.request(service,clientID,request)
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
    local order=mjrequire "common/order"
    local candidates={}
    local living,withBonus=0,0
    for _,id in ipairs(record.familyIDs or {}) do
        local sapien=service.gom:getObjectWithID(id)
        if visit.familyRecord(service,grave,sapien) then
            living=living+1
            if visit.hasRemembranceBonus(sapien) then withBonus=withBonus+1 end
            for _,current in ipairs(sapien.sharedState.orderQueue or {}) do
                if current.objectID==grave.uniqueID and (current.orderTypeIndex==order.types.rrRememberAncestors.index or
                    current.orderTypeIndex==order.types.rrRememberTogether.index) then
                    return {ok=true,message="A remembrance visit is already in progress at this memorial."}
                end
            end
            if visit.canSummon(sapien) then candidates[#candidates+1]=sapien end
        end
    end
    if living==0 then return {error="No living family members in your tribe can remember at this memorial."} end
    if withBonus==living then
        return {error="All living family members already have a remembrance bonus. Try again after it expires."}
    end
    local math3=mjrequire "common/mjm"
    table.sort(candidates,function(a,b)
        local ad,bd=math3.length2(a.pos-grave.pos),math3.length2(b.pos-grave.pos)
        if ad==bd then return a.uniqueID<b.uniqueID end
        return ad<bd
    end)
    for _,sapien in ipairs(candidates) do
        if visit.summon(sapien,grave,order.types.rrRememberAncestors.index,{rrMemorialID=memorial.id}) then
            return {ok=true,name=sapien.sharedState.name or "A family member"}
        end
    end
    return {error="No family member can attend right now. Relatives without an active remembrance bonus may be unwell, on another visit, or unable to reach the grave."}
end

function visit.complete(service,sapien,grave,orderState)
    local record=visit.familyRecord(service,grave,sapien)
    if not record or not orderState.context or orderState.context.rrMemorialID~=record.id or not visit.eligible(sapien) then return false end
    if (mjrequire "common/mjm").length2(sapien.pos-grave.pos)>mj:mToP(3.0)^2 then return false end
    local status=mjrequire "common/statusEffect";
    (mjrequire "server/serverStatusEffects"):setTimedEffect(sapien.sharedState,status.types.rrAncestorsRemembered.index,visit.bonusDuration)
    local happy=(mjrequire "common/mood").types.happySad.index
    sapien.sharedState:set("moods",happy,math.min(5,(sapien.sharedState.moods[happy] or 3)+1))
    service.gom:saveObject(sapien.uniqueID)
    return true
end
return visit
