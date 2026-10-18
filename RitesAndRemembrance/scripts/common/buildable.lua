local mod = {loadOrder=25}
function mod:onload(buildable)
    local constructable = mjrequire "common/constructable"
    local resource=mjrequire "common/resource"
    local skill=mjrequire "common/skill"
    for _, entry in ipairs(mjrequire "ritesRemembrance/catalog") do
        local requirements={}
        for _,r in ipairs(entry.requirements) do
            requirements[#requirements+1]={group=resource.groups[r.group].index,count=r.count}
        end
        buildable:addBuildable(entry.key, {
            name=entry.name, plural=entry.plural,
            summary="A personal memorial. Choose its position, then confirm placement.",
            modelName=entry.key, finalGameObjectTypeKey=entry.key,
            iconGameObjectType=entry.key.."Preview",
            inProgressGameObjectTypeKey="build_"..entry.key,
            classification=constructable.classifications.build.index,
            requiredResources=requirements, allowYTranslation=true, allowXZRotation=false,
            skills={required=skill.types.rrRemembrance.index},
            buildSequence=buildable.bringAndMoveSequence,
            noBuildUnderWater=true, requiresSlopeCheck=true, checkObjectCollisions=true,
            disallowsDecorationPlacing=true,
        })
    end
end
return mod
