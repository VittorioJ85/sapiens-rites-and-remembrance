local mod={loadOrder=25}
function mod:onload(placeholders)
    local original=placeholders.addModels
    function placeholders:addModels(...)
        original(self,...)
        local resource=mjrequire "common/resource"
        for key,slots in pairs(mjrequire "ritesRemembrance/modelSlots") do
            local defs={}
            for _,slot in ipairs(slots) do
                -- Delivery slots are managed by native construction inventory.
                -- A default model here would show an extra resource on the finished grave.
                if slot.storage then
                    defs[#defs+1]={key=slot.key,offsetToStorageBoxWalkableHeight=true}
                else
                    local group=resource.groups[slot.group]
                    defs[#defs+1]={key=slot.key,defaultModelName=slot.model,
                        resourceGroupIndex=group and group.index,
                        resourceTypeIndex=not group and resource.types[slot.group].index or nil}
                end
            end
            self:addModel(key,defs)
        end
        self:addModel("rr_personal",{
            {key="rr_personalItem_1",defaultModelName="stoneBlock",resourceGroupIndex=resource.groups.rr_personalItem.index,
                offsetToStorageBoxWalkableHeight=true},
            {key="rr_personalItem_store",offsetToStorageBoxWalkableHeight=true},
        })
    end
end
return mod
