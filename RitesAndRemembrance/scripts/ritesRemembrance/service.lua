local catalog = mjrequire "ritesRemembrance/catalog"
local validation = mjrequire "ritesRemembrance/validation"
local service = {}

function service:init(world, gom)
    self.world, self.gom = world, gom
    self.db = world:getDatabase("ritesRemembrance_v1", true)
    local schema = self.db:dataForKey("schema")
    assert(schema==nil or schema==1, "Unsupported Rites and Remembrance save format")
    if not schema then self.db:setDataForKey(1,"schema") end
end
function service:get(key) return self.db:dataForKey(key) end
function service:put(key, value) self.db:setDataForKey(value,key) end
function service:prepareTribe(tribe)
    local key="policy4:"..tribe
    if self:get(key) then return end
    local queueKey="queue:"..tribe
    local q=self:get(queueKey)
    if q and q.tail>0 then
        local lastID=self:get(queueKey..":"..q.tail)
        local person=lastID and self:get("person:"..lastID)
        self:put("loss:"..tribe,{person=person})
        -- O(1) migration: preserve records and built graves, skip old decisions.
        q.head=q.tail+1;self:put(queueKey,q)
    end
    self:put(key,true)
end

function service:died(sapien)
    if not self.db or not sapien or not validation.id(sapien.uniqueID) then return end
    local state=sapien.sharedState
    if not state or not validation.id(state.tribeID) then return end
    local client=self.world:clientIDForTribeID(state.tribeID)
    if not client or client==mj.serverClientID then return end
    self:prepareTribe(state.tribeID)
    local key="person:"..sapien.uniqueID
    if self:get(key) then return end -- repeated death callbacks are harmless
    local constants=mjrequire "common/sapienConstants"
    local row={id=sapien.uniqueID, tribeID=state.tribeID, name=state.name or "Unknown",
        age=math.floor(constants:getAgeValue(state))+5,
        deathTime=self.world:getWorldTime(), status=self:unlocked(state.tribeID) and "pending" or "beforeResearch",
        portrait=(mjrequire "ritesRemembrance/portrait").capture(sapien),
        familyIDs=(mjrequire "ritesRemembrance/remembrance").capture(sapien)}
    self:put(key,row)
    self:put("loss:"..state.tribeID,{person=row})
    if row.status=="beforeResearch" then return end
    row.eligible=true;self:put(key,row)
    local queueKey="queue:"..state.tribeID
    local queue=self:get(queueKey) or {head=1,tail=0}
    queue.tail=queue.tail+1
    self:put(queueKey..":"..queue.tail,row.id)
    self:put(queueKey,queue)
end

local function public(row)
    return {id=row.id,name=row.name,age=row.age,deathTime=row.deathTime,status=row.status,model=row.model,portrait=row.portrait,selected=row.selected}
end
function service:next(tribe)
    self:prepareTribe(tribe)
    if not self:unlocked(tribe) then
        local loss=self:get("loss:"..tribe)
        return {person=loss and loss.person and public(loss.person),researchLocked=true}
    end
    local key="queue:"..tribe
    local q=self:get(key) or {head=1,tail=0}
    -- Bound the work per poll; a large historical queue never blocks a frame.
    for _=1,32 do
        if q.head>q.tail then return {} end
        local id=self:get(key..":"..q.head)
        local row=id and self:get("person:"..id)
        if row and row.eligible and (row.status=="pending" or row.status=="chosen") then
            local entry=catalog.find(row.model)
            if row.status=="chosen" and not entry then
                -- Unplaced old selections can be chosen again; placed objects
                -- and in-progress construction orders are never migrated.
                row.status="pending";row.model=nil;row.restricted=nil;row.selected=nil
                self:put("person:"..id,row)
            end
            return {person=public(row),researchLocked=not self:unlocked(tribe),researchReady=self:canResearch(tribe)}
        end
        q.head=q.head+1
        self:put(key,q)
    end
    return {}
end
function service:unlocked(tribe)
    return self.world:discoveryIsCompleteForTribe(tribe,(mjrequire "common/research").types.rrRemembrance.index)
end
function service:canResearch(tribe)
    self:prepareTribe(tribe)
    local ready=self:get("loss:"..tribe)~=nil and self.world:discoveryIsCompleteForTribe(tribe,
        (mjrequire "common/research").types.digging.index) or false
    local helper=mjrequire "common/planHelper"
    helper.rrResearchReady=helper.rrResearchReady or {}
    helper.rrResearchReady[tribe]=ready
    return ready
end

function service:request(clientID, request)
    if not self.db then return {error="Memorial archive is not ready."} end
    if not validation.request(request) then return {error="Invalid memorial request."} end
    local tribe=self.world:tribeIDForClientID(clientID)
    if not validation.id(tribe) then return {error="No player tribe."} end
    self:prepareTribe(tribe)
    if request.action=="poll" then
        local result=self:next(tribe)
        result.researchReady=self:canResearch(tribe)
        result.available={}
        local seen=self.world:seenResourceObjectTypesForTribe(tribe)
        for _,entry in ipairs(catalog) do
            result.available[entry.key]=(mjrequire "ritesRemembrance/materials").available(entry,seen)
        end
        return result
    end
    if not self:unlocked(tribe) then return {error="Discover Rites and Remembrance before creating memorials."} end
    local key="person:"..request.id
    local row=self:get(key)
    if not row or row.tribeID~=tribe then return {error="This person does not belong to your tribe."} end
    if request.action=="place" and row.status=="placed" then return {objectID=row.objectID} end
    if not row.eligible then return {error="Memorial decisions begin with deaths after discovery."} end
    if row.status~="pending" and row.status~="chosen" then return {error="This memorial decision is already complete."} end
    if request.action=="decline" then
        row.status="declined"; self:put(key,row); return {ok=true}
    elseif request.action=="choose" then
        if not (mjrequire "ritesRemembrance/materials").available(catalog.find(request.model),self.world:seenResourceObjectTypesForTribe(tribe)) then
            return {error="Discover the required material types to unlock this memorial."}
        end
        local materials=mjrequire "ritesRemembrance/materials"
        local entry=catalog.find(request.model)
        local restricted
        if entry.personal then
            restricted=materials.restrictToPersonal(request.selected,self.world:seenResourceObjectTypesForTribe(tribe))
        else restricted=materials.validate(entry,request.restricted) end
        if not restricted then return {error="Allow at least one valid material for each requirement."} end
        row.status="chosen"; row.model=request.model;row.restricted=restricted;row.selected=entry.personal and request.selected or nil; self:put(key,row)
        return {person=public(row)}
    end
    if row.status~="chosen" or row.model~=request.model then return {error="Choose a memorial before placing it."} end
    local mjm=mjrequire "common/mjm"
    local materials=mjrequire "ritesRemembrance/materials"
    local restricted
    if catalog.find(row.model).personal then
        restricted=materials.restrictToPersonal(row.selected,self.world:seenResourceObjectTypesForTribe(tribe))
    else restricted=materials.validate(catalog.find(row.model),row.restricted or {}) end
    if not restricted then return {error="Choose valid construction materials again."} end
    local objectID=(mjrequire "server/planManager"):rrCreateBuild(tribe,row,
        mjm.vec3(unpack(request.pos)),mjm.mat3(unpack(request.rotation)),request.attachedToTerrain,restricted)
    if not objectID then return {error="The memorial could not be placed. Please try another position."} end
    row=self:get(key) or row -- creative-mode completion may already have saved bonus receipts
    row.objectID=objectID; row.status="placed"; self:put(key,row)
    return {objectID=objectID}
end
function service:memorialForObject(id)
    return self.db and self:get("object:"..id)
end
return service
