local mod={loadOrder=25}
function mod:onload(skill)
    local maps=mjrequire "common/typeMaps"
    maps:insert("skill",skill.types,{key="rrRemembrance",name="Rites and Remembrance",
        description="Honor the dead by building personal memorials.",icon="icon_rrRemembrance"})
    skill.validTypes=maps:createValidTypesArray("skill",skill.types)
end
return mod
