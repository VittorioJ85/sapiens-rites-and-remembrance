local mod={loadOrder=25}
function mod:onload(order)
    local maps=mjrequire "common/typeMaps"
    maps:insert("order",order.types,{key="rrTribalCeremony",name="Tribal Ceremony",
        inProgressName="Gathering for a tribal ceremony",icon="icon_tribe",allowToFinishEvenWhenVeryTired=true})
    maps:insert("order",order.types,{key="rrRememberAncestors",
        name="Remember Ancestors",inProgressName="Remembering ancestors",icon="icon_rrRemembrance",
        allowToFinishEvenWhenVeryTired=true})
    maps:insert("order",order.types,{key="rrRememberTogether",
        name="Remember Ancestors Together",inProgressName="Gathering to remember ancestors",icon="icon_rrRemembrance",
        allowToFinishEvenWhenVeryTired=true})
end
return mod
