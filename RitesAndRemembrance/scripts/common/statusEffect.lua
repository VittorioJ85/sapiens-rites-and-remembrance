local mod={loadOrder=25}
function mod:onload(effects)
    local maps=mjrequire "common/typeMaps"
    maps:insert("statusEffect",effects.types,{key="rrTribalUnityFull",name="Tribal Unity — Majority Attendance",
        description="More than half the tribe completed the ceremony: +2 Happiness and +2 Tribe Loyalty for three game days. Productive work speed scales with attendance, up to +20%.",
        icon="icon_tribe",impact=2,affectsLoyalty=true})
    -- Native layout requires large impact icons before small impact icons.
    local fullPosition=#effects.orderedPositiveEffects+1
    for i,index in ipairs(effects.orderedPositiveEffects)do
        if effects.types[index].impact<=1 then fullPosition=i;break end
    end
    table.insert(effects.orderedPositiveEffects,fullPosition,effects.types.rrTribalUnityFull.index)
    maps:insert("statusEffect",effects.types,{key="rrTribalUnity",name="Tribal Unity",
        description="Ceremony participants gain +1 Happiness and Loyalty. Work speed scales with attendance. New ceremonies last three game days, or one day below 50% attendance; at least 25% must complete the dance.",
        icon="icon_tribe",impact=1,affectsLoyalty=true})
    table.insert(effects.orderedPositiveEffects,effects.types.rrTribalUnity.index)
    for level=1,5 do
        maps:insert("statusEffect",effects.types,{
            key="rrRemembered"..level,name="Family Remembered",icon="icon_rrRemembrance",impact=level,affectsLoyalty=true,
            description="Recently completed family memorials provide +"..level.." Happiness and Tribe Loyalty. Each bonus lasts 1,000 simulation seconds."})
        -- Native status layouts reserve large columns before placing small icons.
        -- Insert stronger bonuses before the first small effect, preserving the
        -- relative order of all existing effects and their gameplay impact.
        local position=#effects.orderedPositiveEffects+1
        if level>1 then
            for i,index in ipairs(effects.orderedPositiveEffects) do
                if effects.types[index].impact<=1 then position=i;break end
            end
        end
        table.insert(effects.orderedPositiveEffects,position,effects.types["rrRemembered"..level].index)
        maps:insert("statusEffect",effects.types,{
            key="rrGraveDemolished"..level,name="Family Memorial Demolished",icon="icon_rrRemembrance",impact=-level,affectsLoyalty=true,
            description="Demolished family memorials cause -"..level.." Happiness and Tribe Loyalty. Each penalty lasts 2,000 simulation seconds."})
        local negativePosition=#effects.orderedNegativeEffects+1
        if level>1 then
            for i,index in ipairs(effects.orderedNegativeEffects) do
                if effects.types[index].impact>=-1 then negativePosition=i;break end
            end
        end
        table.insert(effects.orderedNegativeEffects,negativePosition,effects.types["rrGraveDemolished"..level].index)
    end
    maps:insert("statusEffect",effects.types,{key="rrAncestorsRemembered",name="Remembered Ancestors",
        description="A quiet visit to a family memorial provides +1 Happiness for 1,000 simulation seconds.",
        icon="icon_rrRemembrance",impact=1,affectsLoyalty=false})
    table.insert(effects.orderedPositiveEffects,effects.types.rrAncestorsRemembered.index)
    maps:insert("statusEffect",effects.types,{key="rrFamilyRemembered",name="Remembered Together",
        description="Remembering with family provides +1 Happiness and +1 Tribe Loyalty for 2,000 simulation seconds.",
        icon="icon_rrRemembrance",impact=1,affectsLoyalty=true})
    table.insert(effects.orderedPositiveEffects,effects.types.rrFamilyRemembered.index)
end
return mod
