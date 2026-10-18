local mod={loadOrder=25}
function mod:onload(action)
    (mjrequire "common/typeMaps"):insert("action",action.types,{key="rrRememberAncestors",
        name="Remember Ancestors",inProgress="Remembering ancestors",restNeedModifier=0.0})
    local maps=mjrequire "common/typeMaps"
    maps:insert("action",action.types,{key="rrGatherTribe",name="Gather Tribe",
        inProgress="Waiting for the tribe",restNeedModifier=0.0})
    maps:insert("action",action.types,{key="rrTribalDance",name="Tribal Ceremony",
        inProgress="Dancing with the tribe",restNeedModifier=0.0})
    maps:insert("action",action.types,{key="rrGatherFamily",name="Gather Family",
        inProgress="Waiting for family",restNeedModifier=0.0})
    maps:insert("action",action.types,{key="rrRememberTogether",name="Remember Ancestors Together",
        inProgress="Remembering ancestors together",restNeedModifier=0.0})
end
return mod
