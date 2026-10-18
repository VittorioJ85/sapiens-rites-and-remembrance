local mod={loadOrder=25}
function mod:onload(plan)
    local maps=mjrequire "common/typeMaps"
    maps:insert("plan",plan.types,{key="rrTribalCeremony",name="Gather for Tribal Ceremony",icon="icon_tribe"})
    for _,entry in ipairs(mjrequire "ritesRemembrance/radialActions") do
        maps:insert("plan",plan.types,{key=entry.key,name=entry.name,icon=entry.icon})
    end
end
return mod
