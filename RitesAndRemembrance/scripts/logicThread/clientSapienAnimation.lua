-- The native land animation selector has no static idle fallback: idle is a
-- complex animation function. Unknown actions therefore crash before the later
-- clientObjectAnimation hook can supply the remembrance pose (reports 69c24f,
-- 14e093). Route only our stationary client stages through native idle first.
local mod={loadOrder=25}
function mod:onload(animation)
    local init=animation.init
    function animation:init(...)
        local sequences=(mjrequire "common/actionSequence").types
        local actions=(mjrequire "common/action").types
        for _,key in ipairs({"rrRememberAncestors","rrRememberTogether","rrTribalCeremony"}) do
            local sequence=sequences[key]
            if sequence then
                local mapped={}
                for i,index in ipairs(sequence.actions) do
                    if index==actions.rrRememberAncestors.index or index==actions.rrGatherFamily.index or
                        index==actions.rrRememberTogether.index or index==actions.rrGatherTribe.index or
                        index==actions.rrTribalDance.index then
                        mapped[i]=actions.idle.index
                    else
                        mapped[i]=index
                    end
                end
                sequence.actions=mapped
            end
        end
        -- This module runs only in the logic VM. Server action definitions and
        -- AI timing remain custom; sequence IDs/progress and save data are intact.
        return init(self,...)
    end
end
return mod
