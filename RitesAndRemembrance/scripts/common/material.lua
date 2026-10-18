local mod={loadOrder=25}
function mod:onload(material)
    local aliases=(mjrequire "ritesRemembrance/previewAssets").aliases
    local keys={}
    for name in pairs(aliases) do keys[#keys+1]=name end
    table.sort(keys) -- Material indices must agree on every engine thread.
    for _,name in ipairs(keys) do
        if not material.types[name] then
            -- Separate indices prevent two groups using rock/brick from sharing a remap.
            local copy=mj:cloneTable(material.types[aliases[name]])
            copy.key=name
            mj:insertIndexed(material.types,copy)
        end
    end
end
return mod
