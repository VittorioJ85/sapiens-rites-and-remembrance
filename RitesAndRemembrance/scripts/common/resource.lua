local mod={loadOrder=25}
function mod:onload(resource)
    local maps=mjrequire "common/typeMaps"
    for _,group in ipairs((mjrequire "ritesRemembrance/catalog").groups) do
        local types={}
        for _,key in ipairs(group.types) do types[#types+1]=resource.types[key].index end
        maps:insert("resourceGroup",resource.groups,{key=group.key,name=group.name,plural=group.name,
            resourceTypes=types,displayGameObjectTypeIndex=maps.types.gameObject[group.display]})
        resource:updateGroupContainedTypesHashForAddition(resource.groups[group.key].index)
    end
    local function itemTypes()
        local result,seen={},{}
        for _,entry in pairs(resource.types) do
            if type(entry)=="table" and entry.index and not seen[entry.index] then
                seen[entry.index]=true;result[#result+1]=entry.index
            end
        end
        table.sort(result,function(a,b)return tostring(a)<tostring(b)end)
        return result
    end
    maps:insert("resourceGroup",resource.groups,{key="rr_personalItem",name="Personal memorial item",plural="Personal memorial items",
        resourceTypes=itemTypes(),displayGameObjectTypeIndex=maps.types.gameObject.stoneBlock})
    resource:updateGroupContainedTypesHashForAddition(resource.groups.rr_personalItem.index)
    local init=resource.mjInit
    function resource:mjInit(...)
        -- Include resource types registered later by other enabled mods.
        self.groups.rr_personalItem.resourceTypes=itemTypes()
        return init(self,...)
    end
end
return mod
