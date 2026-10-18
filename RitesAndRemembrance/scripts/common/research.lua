local mod={loadOrder=25}
function mod:onload(research)
    local load=research.load
    function research:load(...)
        load(self,...)
        local skill=mjrequire "common/skill"
        self:addResearch("rrRemembrance",{
            name="Rites and Remembrance",icon="icon_rrRemembrance",
            description="Discover how to honor the dead with personal memorials.",
            clueText="Craft",
            skillTypeIndex=skill.types.rrRemembrance.index,
            constructableTypeIndex=(mjrequire "common/constructable").types.rrOffering.index,
            resourceTypeIndexes={(mjrequire "common/resource").types.dirt.index,(mjrequire "common/resource").types.clay.index},
            researchRequiredForVisibilityDiscoverySkillTypeIndexes={skill.types.digging.index},
            initialResearchSpeedLearnMultiplier=0.1,
        })
    end
end
return mod
