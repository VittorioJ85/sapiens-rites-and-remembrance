local mod={loadOrder=25}
function mod:onload(sequences)
    local action=mjrequire "common/action"
    local maps=mjrequire "common/typeMaps"
    maps:insert("actionSequence",sequences.types,{key="rrTribalCeremony",
        actions={action.types.moveTo.index,action.types.rrGatherTribe.index,action.types.rrTribalDance.index},assignedTriggerIndex=2})
    maps:insert("actionSequence",sequences.types,{key="rrRememberAncestors",
        actions={action.types.moveTo.index,action.types.rrRememberAncestors.index},assignedTriggerIndex=2})
    maps:insert("actionSequence",sequences.types,{key="rrRememberTogether",
        actions={action.types.moveTo.index,action.types.rrGatherFamily.index,action.types.rrRememberTogether.index},assignedTriggerIndex=2})
end
return mod
