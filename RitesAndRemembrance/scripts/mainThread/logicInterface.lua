local mod={loadOrder=25}
function mod:onload(logic)
    local call=logic.callServerFunction
    function logic:callServerFunction(name,data,callback)
        local ceremony=(mjrequire "common/plan").types.rrTribalCeremony
        if name=="addPlans" and type(data)=="table" and ceremony and data.planTypeIndex==ceremony.index then
            local ids=data.objectOrVertIDs
            if type(ids)~="table" or #ids~=1 or not (mjrequire "ritesRemembrance/validation").id(ids[1]) then
                if callback then callback({error="Select one object or ground location."}) end
                return
            end
            local request={action="preview"}
            if data.baseVertID then request.vertID=ids[1] else request.objectID=ids[1] end
            (mjrequire "ritesRemembrance/ceremonyUI"):open(request)
            if callback then callback({ok=true}) end
            return
        end
        local entry=name=="addPlans" and type(data)=="table" and
            (mjrequire "ritesRemembrance/radialActions").forPlan(data.planTypeIndex)
        if not entry then
            if name=="addPlans" and type(data)=="table" then
                local constructable=(mjrequire "common/constructable").types[data.constructableTypeIndex]
                if constructable and (mjrequire "ritesRemembrance/catalog").find(constructable.key) then
                    return (mjrequire "ritesRemembrance/ui"):place(data,callback)
                end
            end
            return call(self,name,data,callback)
        end
        local ids=data.objectOrVertIDs
        if type(ids)~="table" or #ids~=1 or data.baseVertID or
            not (mjrequire "ritesRemembrance/validation").id(ids[1]) then
            if callback then callback({error="Select one completed family memorial."}) end
            return
        end
        -- Native radial buttons send addPlans. UI-only entries must not become
        -- work plans or reach the generic server dispatcher.
        return (mjrequire "mainThread/ui/inspect/inspectObjectUI"):rrPerformAction(entry,ids[1],callback)
    end
end
return mod
