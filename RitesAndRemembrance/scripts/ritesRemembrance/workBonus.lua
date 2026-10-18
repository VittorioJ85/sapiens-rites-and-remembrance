-- Adjust only the active productive action's time step, not the world clock,
-- status-effect timers, needs, research, travel or native skill multipliers.
local bonus={}
local productive={knap=true,knapCrude=true,grind=true,potteryCraft=true,smithHammer=true,
    toolAssembly=true,spinCraft=true,thresh=true,scrapeWood=true,butcher=true,fireStickCook=true,
    smeltMetal=true,patDown=true,chop=true,buildMoveComponent=true,dig=true,mine=true,
    chiselStone=true,clear=true,gather=true,gatherBush=true,reachUp=true}
function bonus.speed(state,speed)
    local effect=(mjrequire "common/statusEffect").types.rrTribalUnity
    local full=(mjrequire "common/statusEffect").types.rrTribalUnityFull
    local order=state.orderQueue and state.orderQueue[1]
    local actionState=state.actionState
    if effect and state.statusEffects and (state.statusEffects[effect.index] or (full and state.statusEffects[full.index])) and order and actionState and
        not (order.context and order.context.researchTypeIndex) then
        local sequence=(mjrequire "common/actionSequence").types[actionState.sequenceTypeIndex]
        local index=sequence and sequence.actions[actionState.progressIndex]
        local action=index and (mjrequire "common/action").types[index]
        if action and productive[action.key] then
            -- Existing 0.8.0 buffs retain 10% until their original timer expires.
            local percent=state.rrTribalUnityWorkPercent or (full and state.statusEffects[full.index] and 20 or 10)
            return speed*(1+math.max(0,math.min(20,percent))*.01)
        end
    end
    return speed
end
return bonus
