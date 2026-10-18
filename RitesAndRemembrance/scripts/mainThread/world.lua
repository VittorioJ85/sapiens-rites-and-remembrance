local mod={loadOrder=25}
function mod:onload(world)
    local get=world.getConstructableRestrictedObjectTypes
    function world:getConstructableRestrictedObjectTypes(index,isTool)
        local personal=(mjrequire "common/constructable").types.rr_personal
        if not isTool and personal and index==personal.index and self.rrPersonalRestricted then
            return self.rrPersonalRestricted
        end
        return get(self,index,isTool)
    end
end
return mod
