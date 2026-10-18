-- Stable keys are part of the save format. Never rename them in an update.
local catalog = {
    {key="rr_gravestone", name="Gravestone", plural="Gravestones", height=.92,
        requirements={{group="rr_soil",count=4},{group="rockAny",count=1}},
        cost="4 Soil / Sand / Clay\n1 Large Rock (soft or hard)"},
    {key="rr_urn", name="Funerary Urn", plural="Funerary Urns", height=1.11,
        requirements={{group="rr_tile",count=3},{group="rr_urnMaterial",count=1}},
        cost="3 Tiles, stacked\n1 Urn"},
    {key="rr_personal",name="Personal Memorial",plural="Personal Memorials",height=1.5,personal=true,
        requirements={{group="rr_personalItem",count=1}},cost="1 object of your choice\nChoose one known item"},
}
catalog.groups={
    {key="rr_researchEarth",name="Soil or Clay",types={"dirt","clay"},display="dirt"},
    {key="rr_soil",name="Soil, Sand or Clay",types={"dirt","sand","clay"},display="dirt"},
    {key="rr_tile",name="Tiles (Fired, Unfired or Wet)",types={"firedTile","mudTileDry","mudTileWet"},display="firedTile"},
    {key="rr_urnMaterial",name="Urn (Fired, Unfired or Wet)",types={"firedUrn","unfiredUrnDry","unfiredUrnWet"},display="firedUrn"},
}
function catalog.find(key)
    for _, entry in ipairs(catalog) do if entry.key == key then return entry end end
end
function catalog.forObject(object)
    local kind=object and (mjrequire "common/gameObject").types[object.objectTypeIndex]
    return kind and catalog.find(kind.key:gsub("^build_",""))
end
return catalog
