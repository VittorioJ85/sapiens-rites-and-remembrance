-- Match native fixed positive events: learnedSkill and hadChild use 1000 seconds.
-- Timers use the same simulated dt as serverStatusEffects, never wall-clock time.
local effects = {comfortDuration=1000.0, demolitionDuration=2000.0}

local function synchronize(state, timers)
    local types=(mjrequire "common/statusEffect").types
    local status=mjrequire "server/serverStatusEffects"
    for _,group in ipairs({{key="comfort",prefix="rrRemembered"},{key="demolition",prefix="rrGraveDemolished"}}) do
        local count,remaining=0,0
        for _,timer in pairs(timers[group.key]) do
            count=count+1; remaining=math.max(remaining,timer)
        end
        count=math.min(5,count)
        for level=1,5 do
            local index=types[group.prefix..level].index
            if level==count then
                status:setTimedEffect(state,index,remaining)
            elseif state.statusEffects[index] then
                status:removeEffect(state,index)
            end
        end
    end
end

local function loadTimers(state)
    if state.rrMemorialTimers then
        local copy={comfort={},demolition={}}
        for group,entries in pairs(state.rrMemorialTimers) do
            for id,timer in pairs(entries) do copy[group][id]=timer end
        end
        return copy
    end
    local timers={comfort={},demolition={}}
    local types=(mjrequire "common/statusEffect").types
    local oldLevel=0
    for level=1,5 do
        if state.statusEffects[types["rrRemembered"..level].index] then oldLevel=level end
    end
    -- Legacy receipts remain permanent duplicate guards, not permanent buffs.
    -- Give an existing untimed effect one full interval on first simulation update.
    if oldLevel>0 then
        for id in pairs(state.rrRememberedPeople or {}) do timers.comfort[id]=effects.comfortDuration end
        if not next(timers.comfort) then
            for level=1,oldLevel do timers.comfort["legacy:"..level]=effects.comfortDuration end
        end
    end
    state:remove("rrRemembranceCount")
    return timers
end

function effects.apply(state,personID,demolished)
    local timers=loadTimers(state)
    if demolished then
        timers.comfort[personID]=nil
        timers.demolition[personID]=effects.demolitionDuration
    else
        timers.comfort[personID]=effects.comfortDuration
    end
    state:set("rrMemorialTimers",timers)
    synchronize(state,timers)
end

function effects.update(state,dt)
    if dt<=0 then return end
    local elapsed=state.rrMemorialTimers and dt or 0
    local timers=loadTimers(state)
    if not next(timers.comfort) and not next(timers.demolition) then
        if not state.rrMemorialTimers then state:set("rrMemorialTimers",timers) end
        return
    end
    -- Copy before persisting: sharedState setters must observe a changed table.
    local updated={comfort={},demolition={}}
    for group,entries in pairs(timers) do
        for id,remaining in pairs(entries) do
            if remaining>elapsed then updated[group][id]=remaining-elapsed end
        end
    end
    state:set("rrMemorialTimers",updated)
    synchronize(state,updated)
end

return effects
