local mod={loadOrder=25}
function mod:onload(gom)
    local service=mjrequire "ritesRemembrance/service"
    local catalog=mjrequire "ritesRemembrance/catalog"
    local create=gom.createGameObject
    function gom:createGameObject(data,...)
        local memorial=service.creatingMemorial
        local isMemorial=memorial and catalog.forObject({objectTypeIndex=data.objectTypeIndex})
        if isMemorial then
            data.sharedState.rrMemorial=memorial
            data.sharedState.name=catalog.find(memorial.model).name.." - "..memorial.name
        end
        local id=create(self,data,...)
        if id and isMemorial then service:put("object:"..id,memorial) end
        return id
    end
    local remove=gom.removeGameObject
    function gom:removeGameObject(id,...)
        local object=self:getObjectWithID(id)
        local memorial=object and catalog.forObject(object) and service:memorialForObject(id)
        local wasBuilt=object and (mjrequire "common/gameObject").types[object.objectTypeIndex].isBuiltObject
        local result=remove(self,id,...)
        if memorial and not self:getObjectWithID(id) then
            (mjrequire "ritesRemembrance/remembrance").demolished(service,memorial,wasBuilt)
        end
        return result
    end
    local change=gom.changeObjectType
    function gom:changeObjectType(id,newType,...)
        local result=change(self,id,newType,...)
        local memorial=service:memorialForObject(id)
        local object=self:getObjectWithID(id)
        if memorial and catalog.forObject(object) then
            -- Native completion/deconstruction replaces sharedState before this
            -- call. Restore the saved personal data across either conversion.
            object.sharedState:set("rrMemorial",memorial)
            object.sharedState:set("name",catalog.find(memorial.model).name.." - "..memorial.name)
            self:saveObject(id)
            local remembrance=mjrequire "ritesRemembrance/remembrance"
            remembrance.complete(service,object,memorial)
        end
        return result
    end
end
return mod
