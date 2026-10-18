local mod={loadOrder=25}
function mod:onload(helper)
    local function addCeremony(self,plans,selected,tribe)
        local skills=self.completedSkillsByTribeID and self.completedSkillsByTribeID[tribe]
        local remembrance=(mjrequire "common/skill").types.rrRemembrance
        if not skills or not remembrance or not skills[remembrance.index] or not selected or #selected~=1 then return plans end
        local copy={}
        for _,info in ipairs(plans or {}) do copy[#copy+1]=info end
        copy[#copy+1]={planTypeIndex=(mjrequire "common/plan").types.rrTribalCeremony.index,hasNonQueuedAvailable=true}
        return copy
    end
    local available=helper.availablePlansForObjectInfos
    function helper:availablePlansForObjectInfos(base,objects,tribe,...)
        local plans=addCeremony(self,available(self,base,objects,tribe,...),objects,tribe)
        if not plans or (self.rrResearchReady and self.rrResearchReady[tribe]) then return plans end
        local research=mjrequire "common/research"
        -- Storage areas generate their own research actions, bypassing loose
        -- resources. Filter the shared menu entry point so both obey the gate.
        -- Preserve the source list in case another adapter caches its results.
        local filtered={}
        for _,info in ipairs(plans) do
            if info.researchTypeIndex~=research.types.rrRemembrance.index then filtered[#filtered+1]=info end
        end
        return filtered
    end
    local verts=helper.availablePlansForVertInfos
    function helper:availablePlansForVertInfos(base,selected,tribe,...)
        return addCeremony(self,verts(self,base,selected,tribe,...),selected,tribe)
    end
    local original=helper.init
    function helper:init(...)
        -- Tribe IDs may be reused when loading a different world in one session.
        self.rrResearchReady={}
        original(self,...)
        local catalog=mjrequire "ritesRemembrance/catalog"
        local objects=mjrequire "common/gameObject"
        local function memorialPlans(self,base,selected,tribeID)
            local owned={}
            for _,object in ipairs(selected) do
                if catalog.forObject(object) and object.sharedState and object.sharedState.tribeID==tribeID then
                    owned[#owned+1]=object
                end
            end
            if #owned==0 then return {} end
            local plans={self:getDeconstructionPlanInfo(owned,tribeID,false)}
            -- Visits identify one deceased person, never a mixed/multi selection.
            if #selected==1 and #owned==1 and objects.types[owned[1].objectTypeIndex].isBuiltObject and
                owned[1].sharedState.rrMemorial then
                local types=(mjrequire "common/plan").types
                for _,entry in ipairs(mjrequire "ritesRemembrance/radialActions") do
                    if entry.endpoint or (mjrequire "ritesRemembrance/familyLink").available() then
                        plans[#plans+1]={planTypeIndex=types[entry.key].index,hasNonQueuedAvailable=true}
                    end
                end
            end
            return plans
        end
        for _,entry in ipairs(catalog) do
            self.availablePlansFunctionsByObjectType[objects.types[entry.key].index]=memorialPlans
        end
    end
end
return mod
