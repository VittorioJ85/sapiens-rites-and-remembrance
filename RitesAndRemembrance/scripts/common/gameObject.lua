local mod = {loadOrder=25}
function mod:onload(gameObject)
    local original = gameObject.addGameObjects
    function gameObject:addGameObjects(...)
        original(self, ...)
        local mjm = mjrequire "common/mjm"
        for _, entry in ipairs(mjrequire "ritesRemembrance/catalog") do
            local height = entry.height
            -- A concrete mesh avoids the engine's empty composite icons. It uses
            -- the same source geometry and native materials as the default grave.
            self:addGameObject(entry.key.."Preview",{
                name=entry.name,plural=entry.plural,modelName=entry.personal and "stoneBlock" or entry.key.."Preview",scale=1,
                iconIsUniquePerObject=true,
                -- Keep the shared padded frame; halve camera distance to fill the UI.
                objectViewOffsetFunction=function()return mjm.vec3(0,0,0)end,
                objectViewCameraOffsetFunction=function()return mjm.vec3(.35,.25,.75)end,
            })
            for _,prefix in ipairs({"","build_"}) do
            self:addGameObject(prefix..entry.key, {
                name=entry.name, plural=entry.plural, modelName=entry.key, scale=1.0,
                hasPhysics=true, isPathFindingCollider=true,
                isBuiltObject=prefix=="",isInProgressBuildObject=prefix~="",
                -- Construction inventory is supplied by the native build plan.
                preventGrassAndSnow=true, disallowAnyCollisionsOnPlacement=true,
                markerPositions={{worldOffset=mjm.vec3(0, mj:mToP(height), 0)}},
                objectViewOffsetFunction=function() return mjm.vec3(0,height*.5,0) end,
                objectViewCameraOffsetFunction=function() return mjm.vec3(.7,.5,1) end,
            })
            end
        end
    end
end
return mod
