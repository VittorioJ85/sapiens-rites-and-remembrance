local mod={loadOrder=25}
function mod:onload(craftable)
    local load=craftable.load
    function craftable:load(...)
        load(self,...)
        local resource=mjrequire "common/resource"
        local action=mjrequire "common/action"
        local requirements={}
        for _,r in ipairs({{group=resource.groups.rr_researchEarth.index,count=4}}) do
            r.afterAction={actionTypeIndex=action.types.inspect.index,duration=20,durationWithoutSkill=20}
            requirements[#requirements+1]=r
        end
        self:addCraftable("rrOffering",{name="Remembrance Offering",plural="Remembrance Offerings",
            summary="Explore how to honor a lost tribe member.",
            hasNoOutput=true,classification=(mjrequire "common/constructable").classifications.research.index,
            buildSequence=self.researchBuildSequence,inProgressBuildModel="rrOffering",
            requiredResources=requirements})
    end
end
return mod
