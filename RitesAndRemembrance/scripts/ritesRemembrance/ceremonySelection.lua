-- The same centre-distance / axis-aligned bounds used by native multiSelectUI,
-- applied to trusted preview slots instead of unrelated world object IDs.
local selection={}
local function finite(v)return type(v)=="number" and v==v and math.abs(v)<=100 end
function selection.valid(shape)
    if shape==nil then return true end -- legacy/unfiltered preview
    if type(shape)~="table" then return false end
    local fields=shape.kind=="radius" and {kind=true,radius=true} or
        shape.kind=="box" and {kind=true,x1=true,y1=true,x2=true,y2=true}
    if not fields then return false end
    for k in pairs(shape)do if not fields[k] then return false end end
    if shape.kind=="radius" then return finite(shape.radius) and shape.radius>=0 end
    return finite(shape.x1) and finite(shape.y1) and finite(shape.x2) and finite(shape.y2)
end
function selection.contains(shape,slot)
    if not shape then return true end
    if shape.kind=="radius" then return slot.x^2+slot.y^2<=shape.radius^2+.000001 end
    return slot.x>=math.min(shape.x1,shape.x2) and slot.x<=math.max(shape.x1,shape.x2) and
        slot.y>=math.min(shape.y1,shape.y2) and slot.y<=math.max(shape.y1,shape.y2)
end
function selection.filter(slots,shape)
    local result={}
    for _,slot in ipairs(slots)do if selection.contains(shape,slot)then result[#result+1]=slot end end
    return result
end
return selection
