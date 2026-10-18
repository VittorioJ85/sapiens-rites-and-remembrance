-- A non-pausing ceremony panel: members must be able to move while it is open.
-- The preview is an overhead diagram of server-validated slots, not a model mockup.
local ui={}
local requests=mjrequire "ritesRemembrance/requestScope"
function ui:visible()return self.overlay and not self.overlay.hidden end
function ui:hide()
    if self.selector then self.selector:close();self.selector=nil end
    requests.cancelAll(self);self.busy=false;self.polling=false
    self.generation=(self.generation or 0)+1
    self.renderedPhase,self.renderedSerial,self.statusText=nil,nil,nil
    if self.overlay then self.overlay.hidden=true end
    if self.gameUI then self.gameUI:updateUIHidden() end
end
function ui:init(gameUI,world)
    requests.cancelAll(self)
    -- A previous world's views may already be destroyed; discard their handles.
    self.selector=nil
    self.generation=(self.generation or 0)+1
    self.gameUI,self.world,self.tribe=gameUI,world,world.tribeID
    self.busy,self.polling,self.result=false,false,nil
    self.renderedPhase,self.renderedSerial,self.statusText=nil,nil,nil
    local m=mjrequire "common/mjm"
    self.overlay=ColorView.new(gameUI.view)
    self.overlay.size=gameUI.view.size;self.overlay.color=m.vec4(0,0,0,.65)
    self.overlay.baseOffset=m.vec3(0,0,102);self.overlay.hidden=true;self.overlay.masksEvents=true
    self.overlay.update=function(dt)
        if world.tribeID~=self.tribe then self:hide();self.tribe=world.tribeID;self.result=nil;return end
        if not self:visible() or self.busy or self.polling then return end
        local phase=self.result and self.result.phase
        if phase~="gathering" and phase~="dancing" then return end
        self.pollDelay=(self.pollDelay or 0)-dt
        if self.pollDelay<=0 then self.pollDelay=1;self:send({action="status"},true) end
    end
    self.overlay.keyChanged=function(isDown,code,modKey,isRepeat)
        if not self:visible() then return false end
        if isDown and not isRepeat and code==(mjrequire "mainThread/keyMapping"):getMappingIndex("game","escape") then self:hide() end
        return true
    end
end
function ui:send(request,poll)
    if self.busy or (poll and self.polling) then return end
    if poll then self.polling=true else
        requests.cancelAll(self);self.polling=false;self.busy=true
        self.generation=(self.generation or 0)+1
    end
    local generation=self.generation
    requests.call(self,poll and "poll" or "mutation","rrTribalCeremony",request,function(result)
        if generation~=self.generation or not self:visible() then return end
        self.busy=false;self.polling=false
        if result.error then self.message=result.error else self.result=result;self.message=result.notice end
        self:render()
    end)
end
function ui:open(request)
    if not self.overlay then return end
    self:hide();self.overlay.hidden=false;self.result=nil;self.message="Checking the gathering place..."
    self:render();self:send(request)
    self.gameUI:updateUIHidden()
end
function ui:render()
    local m=mjrequire "common/mjm"
    local helpers=mjrequire "ritesRemembrance/ui"
    local buttons=mjrequire "mainThread/ui/uiCommon/uiStandardButton"
    local result=self.result or {}
    local phase=result.phase
    local rewards=mjrequire "ritesRemembrance/ceremonyRewards"
    local population=result.population or result.total or 0
    local text=self.message or result.message or ""
    if not self.message and phase=="preview" then
        text="Tribe: "..population.." members. "..(result.excluded or 0).." unable to attend. Select standing places below."
    elseif not self.message and phase=="gathering" then
        text="Gathering: "..result.arrived.." / "..result.total.."  |  "..math.ceil(result.gatherRemaining).." seconds remaining"
    elseif not self.message and phase=="dancing" then text="The tribe is dancing together..." end
    -- Polling updates one label; it does not rebuild hundreds of slot views.
    if self.statusText and self.renderedPhase==phase and self.renderedSerial==result.serial and self.renderedTotal==result.total then
        self.statusText.text=text
        if phase~="preview" then self.rewardText.text=rewards.describe(result.reward or rewards.calculate(result.arrived or 0,population)) end
        return
    end
    if self.selector then self.selector:close();self.selector=nil end
    self.overlay:removeAllSubviews()
    self.renderedPhase,self.renderedSerial=phase,result.serial
    self.renderedTotal=result.total
    local panel=ModelView.new(self.overlay)
    panel:setModel((mjrequire "common/model"):modelIndexForName("ui_bg_lg_16x9"))
    panel.relativePosition=ViewPosition(MJPositionCenter,MJPositionCenter)
    panel.size=m.vec2(900,650);panel.scale3D=m.vec3(450,325/(9/16),450)
    helpers:text(panel,"Tribal Ceremony",24,30)
    self.rewardText=helpers:text(panel,rewards.describe(result.reward or rewards.calculate(0,population)),72,18,0,850)
    helpers:text(panel,"Once per game year. Minimum tribe: 25. Participant rewards require 25% attendance.",103,17,0,860)
    self.statusText=helpers:text(panel,text,138,18,0,850)
    if result.slots then
        local countText=helpers:text(panel,"",205,18,240,250)
        self.selector=(mjrequire "ritesRemembrance/ceremonySelectionUI").create(panel,result.slots,phase=="preview",function(count,shape)
            countText.text=string.format("Selected: %d / %d (%.1f%%)",count,population,population>0 and count/population*100 or 0)
            if phase=="preview" then self.rewardText.text="If all selected attend: "..rewards.describe(rewards.calculate(count,population)) end
        end)
        if phase=="preview" then
            helpers:text(panel,"Drag to select.\nRadius: use the mouse wheel.\nBlue places will be invited.\nGrey places stay at work.",315,17,240,260)
        end
        helpers:text(panel,"Gold: ceremony centre   Blue: selected standing places",520,16)
    end
    local function button(label,x,width,fn,y)
        local view=buttons:create(panel,m.vec2(width,36),buttons.types.standard_10x3)
        view.relativePosition=ViewPosition(MJPositionCenter,MJPositionTop);view.baseOffset=m.vec3(x,-(y or 590),3)
        buttons:setText(view,label);buttons:setClickFunction(view,function()if label=="Close" or not self.busy then fn() end end)
    end
    button("Close",-270,130,function()self:hide()end)
    if phase=="preview" then
        button("Gather Selected",190,210,function()self:send({action="gather",serial=result.serial,selection=self.selector and self.selector.selection})end)
    elseif phase=="gathering" or phase=="dancing" then
        button("Cancel Ceremony",-55,220,function()self:send({action="cancel",serial=result.serial})end)
        if phase=="gathering" then
            button("Begin with Those Present",215,270,function()self:send({action="begin",serial=result.serial})end)
            button("Invite Again",240,210,function()self:send({action="reinvite",serial=result.serial})end,330)
        end
    end
end
return ui
