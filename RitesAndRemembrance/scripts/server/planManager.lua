local mod = {loadOrder=25}
function mod:onload(manager)
    local researchPlan=manager.addResearchPlan
    function manager:addResearchPlan(tribe,planIndex,base,ids,objectType,researchIndex,craftableIndex,...)
        local research=mjrequire "common/research"
        if researchIndex==research.types.rrRemembrance.index then
            if not (mjrequire "ritesRemembrance/service"):canResearch(tribe) then return nil end
            local offering=(mjrequire "common/constructable").types.rrOffering.index
            if craftableIndex and craftableIndex~=offering then return nil end
            craftableIndex=offering
        end
        return researchPlan(self,tribe,planIndex,base,ids,objectType,researchIndex,craftableIndex,...)
    end
    local original=manager.addBuildOrPlantPlan
    function manager:addBuildOrPlantPlan(tribeID, planIndex, constructableIndex, ...)
        local entry=(mjrequire "common/constructable").types[constructableIndex]
        -- Reject generic build/clone requests for these restricted objects.
        if entry and (mjrequire "ritesRemembrance/catalog").find(entry.key) then return nil end
        return original(self,tribeID,planIndex,constructableIndex,...)
    end
    -- Only the validated memorial request calls this internal server method.
    function manager:rrCreateBuild(tribe,row,pos,rotation,attached,restricted)
        local service=mjrequire "ritesRemembrance/service"
        local constructable=mjrequire "common/constructable"
        local plan=mjrequire "common/plan"
        service.creatingMemorial={id=row.id,name=row.name,age=row.age,deathTime=row.deathTime,
            model=row.model,portrait=row.portrait,selected=row.selected}
        local ok,result=pcall(original,self,tribe,plan.types.build.index,constructable.types[row.model].index,
            nil,pos,rotation,nil,nil,attached,nil,restricted,nil,false)
        service.creatingMemorial=nil
        if not ok then error(result) end
        return result
    end
    local deconstruct=manager.addDeconstructPlan
    function manager:addDeconstructPlan(tribeID,objectID,...)
        local gom=mjrequire "server/serverGOM"
        local object=gom:getObjectWithID(objectID)
        if (mjrequire "ritesRemembrance/catalog").forObject(object) then
            if not object.sharedState or object.sharedState.tribeID~=tribeID then return false end
            if object.sharedState.constructionConstructableTypeIndex or object.sharedState.inProgressConstructableTypeIndex then
                return deconstruct(self,tribeID,objectID,...)
            end
            -- Memorials were placed without resources or construction jobs.
            -- Native removal clears physics and world state, including for
            -- version 0.1.0 objects without construction metadata. Keep the
            -- archived decision complete so demolition never reopens a popup.
            gom:removeGameObject(objectID)
            return true
        end
        return deconstruct(self,tribeID,objectID,...)
    end
end
return mod
