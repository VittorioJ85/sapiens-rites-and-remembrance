-- Keep only appearance data, never the entire live Sapien shared state.
local portrait={}
local fields={"name","tribeID","lifeStageIndex","ageFraction","isFemale","skinColorFraction",
    "hairColorGene","eyeColorGene","pregnant","hasBaby"}
function portrait.capture(sapien)
    local state=sapien.sharedState
    if not state.skinColorFraction or not state.hairColorGene or not state.lifeStageIndex then return nil end
    local saved={}
    for _,key in ipairs(fields) do saved[key]=state[key] end
    return saved
end
function portrait.object(person)
    if not person or not person.portrait then return nil end
    return {uniqueID=person.id,objectTypeIndex=(mjrequire "common/gameObject").types.sapien.index,
        sharedState=person.portrait}
end
return portrait
