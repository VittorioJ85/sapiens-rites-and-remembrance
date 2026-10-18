-- UI-only plans route to the existing authenticated memorial endpoints.
local actions={
    {key="rrRememberAncestors",name="Remember Ancestors",icon="icon_rrRemembrance",endpoint="rrRememberAncestors"},
    {key="rrRememberTogether",name="Remember Ancestors Together",icon="icon_tribe",endpoint="rrRememberTogether"},
    {key="rrFamilyTree",name="Family Tree",icon="icon_sapiens"},
}
function actions.forPlan(index)
    local types=(mjrequire "common/plan").types
    for _,entry in ipairs(actions) do
        local kind=types[entry.key]
        if kind and kind.index==index then return entry end
    end
end
return actions
