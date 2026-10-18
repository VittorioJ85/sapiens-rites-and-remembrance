local validation = {}
function validation.id(value)
    return type(value)=="string" and #value>0 and #value<=128 and not value:find("[:%c%s]")
end
local function finite(v) return type(v)=="number" and v==v and math.abs(v)<math.huge end
local function numbers(value, count)
    if type(value)~="table" then return false end
    for k, v in pairs(value) do
        if type(k)~="number" or k~=math.floor(k) or k<1 or k>count or not finite(v) then return false end
    end
    for i=1,count do if not finite(value[i]) then return false end end
    return true
end
function validation.placement(p, r)
    if not numbers(p,3) or not numbers(r,9) then return false end
    -- Sapiens positions use a unit planet. Accept terrain elevations, but reject
    -- non-finite, subterranean and arbitrarily remote coordinates.
    local radius2=p[1]^2+p[2]^2+p[3]^2
    if radius2<.99^2 or radius2>1.02^2 then return false end
    for row=0,2 do
        local n=0
        for col=1,3 do n=n+r[row*3+col]^2 end
        if math.abs(n-1)>.002 then return false end
        for other=row+1,2 do
            local dot=0
            for col=1,3 do dot=dot+r[row*3+col]*r[other*3+col] end
            if math.abs(dot)>.002 then return false end
        end
    end
    local det=r[1]*(r[5]*r[9]-r[6]*r[8])-r[2]*(r[4]*r[9]-r[6]*r[7])+r[3]*(r[4]*r[8]-r[5]*r[7])
    return math.abs(det-1)<.003
end
function validation.request(request)
    if type(request)~="table" then return false end
    local allowed={poll={action=true}, decline={action=true,id=true},
        choose={action=true,id=true,model=true,restricted=true,selected=true},
        place={action=true,id=true,model=true,pos=true,rotation=true,attachedToTerrain=true}}
    local fields=allowed[request.action]
    if not fields then return false end
    for field in pairs(request) do if not fields[field] then return false end end
    if request.action=="poll" then return true end
    if not validation.id(request.id) then return false end
    if request.action=="decline" then return true end
    if not (mjrequire "ritesRemembrance/catalog").find(request.model) then return false end
    if request.action=="choose" then return type(request.restricted)=="table" end
    return type(request.attachedToTerrain)=="boolean" and validation.placement(request.pos,request.rotation)
end
return validation
