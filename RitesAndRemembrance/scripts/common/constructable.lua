local mod={loadOrder=25}
function mod:onload(constructable)
    local create=constructable.createGameObjectTypeIndexMap
    function constructable:createGameObjectTypeIndexMap(objectTypesByResource,...)
        local resource=mjrequire "common/resource"
        local group=resource.groups.rr_personalItem
        local available={}
        -- Resource definitions without a corresponding object cannot be delivered.
        -- This map is finalized only here, after all game-object registrations.
        for _,index in ipairs(group.resourceTypes) do
            local objects=objectTypesByResource[index]
            if objects and objects[1] then available[#available+1]=index end
        end
        group.resourceTypes=available;group.containsTypesSet={}
        resource:updateGroupContainedTypesHashForAddition(group.index)
        local result=create(self,objectTypesByResource,...)
        -- Native decoration indexing clears totals for excluded constructables.
        -- Memorials exclude decoration shortcuts, but still require real delivery.
        for _,entry in ipairs(mjrequire "ritesRemembrance/catalog") do
            local cfg=self.types[entry.key]
            if cfg then
                local total=0
                for _,required in ipairs(cfg.requiredResources) do total=total+required.count end
                cfg.requiredResourceTotalCount=total
            end
        end
        return result
    end
end
return mod
