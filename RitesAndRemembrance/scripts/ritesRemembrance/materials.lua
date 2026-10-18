local materials={}
function materials.requirements(entry)
    local resource=mjrequire "common/resource"
    local result={}
    for _,r in ipairs(entry.requirements) do result[#result+1]={group=resource.groups[r.group].index,count=r.count} end
    return result
end
function materials.validate(entry,restricted)
    if type(restricted)~="table" then return nil end
    local objects=mjrequire "common/gameObject"
    local allowed={}
    local requirements=materials.requirements(entry)
    for _,r in ipairs(requirements) do
        for _,index in ipairs(objects:getAvailableGameObjectTypeIndexesForRestrictedResource(r,nil,nil) or {}) do allowed[index]=true end
    end
    local clean={};local count=0
    for index,value in pairs(restricted) do
        count=count+1
        if (not entry.personal and count>512) or not allowed[index] or type(value)~="boolean" then return nil end
        if value then clean[index]=true end
    end
    for _,r in ipairs(requirements) do
        local possible=objects:getAvailableGameObjectTypeIndexesForRestrictedResource(r,clean,nil)
        if not possible or not possible[1] then return nil end
        if entry.personal and #possible~=1 then return nil end
    end
    return clean
end
function materials.personalOptions(seen)
    local objects=mjrequire "common/gameObject"
    local entry=(mjrequire "ritesRemembrance/catalog").find("rr_personal")
    local result,added={},{}
    for _,index in ipairs(objects:getAvailableGameObjectTypeIndexesForRestrictedResource(materials.requirements(entry)[1],nil,nil) or {}) do
        if not added[index] and (not seen or seen[index]) then result[#result+1]=index;added[index]=true end
    end
    table.sort(result,function(a,b)
        local an,bn=objects.types[a].name or tostring(a),objects.types[b].name or tostring(b)
        if an==bn then return tostring(a)<tostring(b) end
        return an<bn
    end)
    return result
end
function materials.restrictToPersonal(index,seen)
    if not index or not seen or not seen[index] then return nil end
    local restricted,found={},false
    for _,candidate in ipairs(materials.personalOptions()) do
        if candidate==index then found=true else restricted[candidate]=true end
    end
    return found and restricted or nil
end
function materials.personalSelection(restricted)
    local objects=mjrequire "common/gameObject"
    local entry=(mjrequire "ritesRemembrance/catalog").find("rr_personal")
    local allowed=objects:getAvailableGameObjectTypeIndexesForRestrictedResource(materials.requirements(entry)[1],restricted,nil)
    return allowed and #allowed==1 and allowed[1] or nil
end
-- Like native crafting unlocks, discovery persists even when stock is exhausted.
function materials.available(entry,seen)
    local objects=mjrequire "common/gameObject"
    for _,requirement in ipairs(materials.requirements(entry)) do
        local found=false
        for _,index in ipairs(objects:getAvailableGameObjectTypeIndexesForRestrictedResource(requirement,nil,nil) or {}) do
            if seen and seen[index] then found=true;break end
        end
        if not found then return false end
    end
    return true
end
return materials
