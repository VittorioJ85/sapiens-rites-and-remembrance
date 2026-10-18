local mod={loadOrder=25}
function mod:onload(ai)
    local visit=mjrequire "ritesRemembrance/ancestorVisit"
    local service=mjrequire "ritesRemembrance/service"
    local family=mjrequire "ritesRemembrance/familyVisit"
    local actions=(mjrequire "common/action").types
    -- Rendezvous phases advance centrally. Keep native danger/movement handling.
    for _,key in ipairs({"rrGatherFamily","rrRememberTogether","rrGatherTribe","rrTribalDance"}) do
        ai.updateInfos[actions[key].index]={checkFrequency=math.huge,allowCompletionWithoutSkill=true}
    end
    ai.updateInfos[(mjrequire "common/action").types.rrRememberAncestors.index]={
        checkFrequency=visit.duration,allowCompletionWithoutSkill=true,
        completionFunction=function(allowed,sapien,grave,orderState)
            if allowed then visit.complete(service,sapien,grave,orderState) end
        end,
    }
    local update=ai.frequentUpdate
    function ai:frequentUpdate(sapien,dt,speed,...)
        speed=(mjrequire "ritesRemembrance/workBonus").speed(sapien.sharedState,speed)
        local current=sapien.sharedState.orderQueue and sapien.sharedState.orderQueue[1]
        if current and current.orderTypeIndex==(mjrequire "common/order").types.rrTribalCeremony.index then
            local event=service.db and service:get("ceremony:"..sapien.sharedState.tribeID)
            if not event or not current.context or event.serial~=current.context.rrCeremony or
                (event.phase~="gathering" and event.phase~="dancing") then
                (mjrequire "server/serverSapien"):cancelOrderAtQueueIndex(sapien,1,false)
                return
            end
        end
        if current and current.orderTypeIndex==(mjrequire "common/order").types.rrRememberTogether.index then
            -- Let native threats, fatigue and path failures cancel first. A
            -- cancelled participant invalidates the whole ceremony's reward.
            local result=update(self,sapien,dt,speed,...)
            if dt>0 and speed>0.0001 then family.tick(service,sapien,current) end
            return result
        end
        if current and current.orderTypeIndex==(mjrequire "common/order").types.rrRememberAncestors.index then
            local grave=service.gom:getObjectWithID(current.objectID)
            if not visit.familyRecord(service,grave,sapien) then
                (mjrequire "server/serverSapien"):cancelOrderAtQueueIndex(sapien,1,false)
                return
            end
        end
        -- Native movement, danger checks, timing, completion and cancellation.
        return update(self,sapien,dt,speed,...)
    end
end
return mod
