local mod={loadOrder=25}
function mod:onload(status)
    local update=status.updateTimedEffects
    function status:updateTimedEffects(sapien,dt,...)
        local result=update(self,sapien,dt,...)
        -- Native expiry callbacks can remove a sapien. Never update a removed object.
        local gom=mjrequire "server/serverGOM"
        local current=gom:getObjectWithID(sapien.uniqueID)
        if current then
            (mjrequire "ritesRemembrance/memorialEffects").update(current.sharedState,dt)
            local state=current.sharedState
            local types=(mjrequire "common/statusEffect").types
            if state.rrTribalUnityWorkPercent and not state.statusEffects[types.rrTribalUnity.index] and
                not state.statusEffects[types.rrTribalUnityFull.index] then state:remove("rrTribalUnityWorkPercent") end
        end
        return result
    end
end
return mod
