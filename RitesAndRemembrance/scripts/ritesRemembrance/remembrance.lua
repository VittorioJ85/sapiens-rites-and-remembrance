-- Store family IDs before native death processing removes relationship links.
local remembrance={}
function remembrance.capture(sapien)
    local ids={}
    for id,relation in pairs(sapien.lazyPrivateState and sapien.lazyPrivateState.relationships or {}) do
        if relation.familyRelationshipType or relation.isPartner then ids[#ids+1]=id end
    end
    return ids
end
function remembrance.complete(service,object,memorial)
    local types=(mjrequire "common/gameObject").types
    if not types[object.objectTypeIndex].isBuiltObject then return end
    local row=service:get("person:"..memorial.id)
    if not row or row.bonusGranted then return end
    local mood=mjrequire "common/mood"
    for _,id in ipairs(row.familyIDs or {}) do
        local relative=service.gom:getObjectWithID(id)
        if relative and relative.objectTypeIndex==types.sapien.index and relative.sharedState.tribeID==row.tribeID then
            local state=relative.sharedState
            -- Per-person receipt prevents repeated completion/save callbacks from stacking.
            if not (state.rrRememberedPeople and state.rrRememberedPeople[memorial.id]) then
                (mjrequire "ritesRemembrance/memorialEffects").apply(state,memorial.id,false)
                state:set("rrRememberedPeople",memorial.id,true)
                for _,index in ipairs({mood.types.happySad.index,mood.types.loyalty.index}) do
                    state:set("moods",index,math.min(5,(state.moods[index] or 3)+1))
                end
                service.gom:saveObject(id)
            end
        end
    end
    row.bonusGranted=true;service:put("person:"..row.id,row)
end
function remembrance.demolished(service,memorial,wasBuilt)
    local row=service:get("person:"..memorial.id)
    -- A cancelled, unfinished order is not the demolition of a grave.
    if not row or row.demolitionGranted or not (row.bonusGranted or wasBuilt) then return end
    local types=(mjrequire "common/gameObject").types
    local mood=mjrequire "common/mood"
    for _,id in ipairs(row.familyIDs or {}) do
        local relative=service.gom:getObjectWithID(id)
        if relative and relative.objectTypeIndex==types.sapien.index and relative.sharedState.tribeID==row.tribeID then
            local state=relative.sharedState;
            (mjrequire "ritesRemembrance/memorialEffects").apply(state,memorial.id,true)
            for _,index in ipairs({mood.types.happySad.index,mood.types.loyalty.index}) do
                state:set("moods",index,math.max(0,(state.moods[index] or 3)-1))
            end
            service.gom:saveObject(id)
        end
    end
    row.demolitionGranted=true;service:put("person:"..row.id,row)
end
return remembrance
