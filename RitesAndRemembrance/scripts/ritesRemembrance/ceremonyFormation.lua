-- Deterministic slots on the planet's tangent plane. No models or world objects
-- are spawned: native path goals and physics validate the actual standing areas.
local formation={spacing=2.4,maxSlots=512,maxRings=24}
local m=mjrequire "common/mjm"
function formation.basis(center)
    local up=m.normalize(center)
    local reference=math.abs(up.y)<0.9 and m.vec3(0,1,0) or m.vec3(1,0,0)
    local right=m.normalize(m.cross(up,reference))
    return up,right,m.cross(up,right)
end
function formation.create(center,count,probe)
    if count<1 or count>formation.maxSlots then return nil end
    local up,right,forward=formation.basis(center)
    local result={}
    for ring=1,formation.maxRings do
        local radius=ring*formation.spacing
        local capacity=math.floor(2*math.pi*radius/formation.spacing)
        local needed=math.min(capacity,count-#result)
        -- Evenly distribute a partial final ring, rather than bunching at one side.
        for i=1,capacity do
            local angle=(i-1)*2*math.pi/(needed==capacity and capacity or needed)
            if i>needed then angle=(i-needed-.5)*2*math.pi/capacity end
            local x,y=math.cos(angle)*radius,math.sin(angle)*radius
            local desired=center+right*mj:mToP(x)+forward*mj:mToP(y)
            local pos=probe(desired,up)
            if pos then
                local separate=true
                for _,slot in ipairs(result) do
                    if m.length2(pos-m.vec3(unpack(slot.pos)))<mj:mToP(formation.spacing*.85)^2 then separate=false;break end
                end
                if separate then result[#result+1]={pos={pos.x,pos.y,pos.z},x=x,y=y} end
            end
            if #result==count then return result end
        end
    end
end
function formation.probe(service,desired,up)
    local world=mjrequire "common/worldHelper"
    local physics=mjrequire "common/physics"
    local sets=mjrequire "common/physicsSets"
    local pos=world:getBelowSurfacePos(desired,2.0,sets.walkable,nil,false)
    if not pos or m.length2(pos)<(1+mj:mToP(.05))^2 then return nil end
    if math.abs(m.length(pos)-m.length(desired))>mj:mToP(1.5) then return nil end
    local normal=world:getWalkableUpVector(pos)
    if not normal or m.dot(m.normalize(normal),up)<.85 then return nil end
    -- Use a tangent look direction, not the surface normal.
    local _,right=formation.basis(pos)
    local rotation=m.createUpAlignedRotationMatrix(up,right)
    local hit=physics:boxTest(pos+up*mj:mToP(.95),rotation,m.vec3(.6,.85,.6)*mj:mToP(1),false,sets.pathColliders)
    if not hit or hit.hasHitObject then return nil end
    return pos
end
return formation
