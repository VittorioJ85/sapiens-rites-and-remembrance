-- Resolve the same first allowed resource variant used by native build previews.
-- Geometry is prepositioned per group, while materials come from native models.
local preview={}
function preview.build(key,restricted)
    local catalog=mjrequire "ritesRemembrance/catalog"
    local entry=catalog.find(key)
    if not entry then return nil,"Unknown memorial design." end
    if entry and entry.personal then return nil,"Choose one known item." end
    local assets=(mjrequire "ritesRemembrance/previewAssets").models[key]
    local objects=mjrequire "common/gameObject"
    local resource=mjrequire "common/resource"
    local model=mjrequire "common/model"
    local result={paths={},materialRemap={}}
    local hash={"rr-preview-v5",key}
    for _,requirement in ipairs(entry.requirements) do
        local group=requirement.group
        local allowed=objects:getAvailableGameObjectTypeIndexesForRestrictedResource(
            {group=resource.groups[group].index},restricted,nil)
        local selected=allowed and allowed[1]
        if not selected then return nil,"Allow a material in each category." end
        local index=objects:simpleModelIndexForGameObjectTypeAndSubdivLevel(selected,mj.SUBDIVISIONS-1)
        local native=index and model:modelInfoForModelIndex(index)
        local part=native and assets[group][native.path]
        -- Never substitute a misleading default for an unsupported modded mesh.
        if not part then return nil,"Preview unavailable for this material." end
        result.paths[#result.paths+1]={path=part.path}
        hash[#hash+1]=tostring(selected)
        for alias,original in pairs(part.materials) do
            result.materialRemap[alias]=(native.materialRemap and native.materialRemap[original]) or original
        end
    end
    result.hash=table.concat(hash,":")
    return result
end
return preview
