local mjm=mjrequire "common/mjm"
local vec2,vec3,vec4=mjm.vec2,mjm.vec3,mjm.vec4
local buttons=mjrequire "mainThread/ui/uiCommon/uiStandardButton"
local common=mjrequire "mainThread/ui/uiCommon/uiCommon"
local logic=mjrequire "mainThread/logicInterface"
local catalog=mjrequire "ritesRemembrance/catalog"
local requests=mjrequire "ritesRemembrance/requestScope"
local ui={session=0}

function ui:visible() return self.overlay and not self.overlay.hidden end
function ui:hide()
    if self.overlay then self.overlay.hidden=true end
    if self.materialViews then
        (mjrequire "mainThread/ui/uiCommon/uiSelectionLayout"):removeAnyActiveSelectionLayoutView()
        self.materialViews=nil
    end
    if self.pauseSpeed~=nil then
        local speed=self.pauseSpeed;self.pauseSpeed=nil
        if speed~=0 then
            self.world:setPlay()
            if speed==2 then self.world:setFastForward()
            elseif speed==9 then self.world:toggleSlowMotion() end
        end
    end
    if self.gameUI then self.gameUI:updateUIHidden() end
end
function ui:defer()
    if self.busy then return end
    self:hide()
    self.person=nil
    self.mode=nil
    self.delay=30 -- Escape postpones; it does not silently decline a memorial.
end
function ui:init(gameUI, world)
    requests.cancelAll(self)
    self.session=self.session+1
    self.gameUI,self.world=gameUI,world
    self.person,self.mode,self.busy,self.polling=nil,nil,false,false
    self.tribeID=world.tribeID
    self.delay=2
    self.pauseSpeed=nil
    self.researchNotified={}
    local updater=View.new(gameUI.view)
    updater.size=vec2(1,1)
    updater.masksEvents=false
    updater.update=function(dt) self:update(dt) end
    self.overlay=ColorView.new(gameUI.view)
    self.overlay.size=gameUI.view.size
    self.overlay.color=vec4(0,0,0,.70)
    self.overlay.baseOffset=vec3(0,0,100)
    self.overlay.hidden=true
    self.overlay.masksEvents=true
    local mapping=mjrequire "mainThread/keyMapping"
    self.overlay.keyChanged=function(isDown,code,modKey,isRepeat)
        if not self:visible() then return false end
        if isDown and not isRepeat and code==mapping:getMappingIndex("game","escape") then self:defer() end
        return true
    end
end
function ui:text(parent,text,y,size,x,width)
    local view=TextView.new(parent)
    view.font=Font(common.fontName,size or 18)
    view.relativePosition=ViewPosition(MJPositionCenter,MJPositionTop)
    view.baseOffset=vec3(x or 0,-y,2)
    view.color=mj.textColor
    view.wrapWidth=width or 720
    view.textAlignment=MJHorizontalAlignmentCenter
    view.text=text
    return view
end
function ui:button(parent,label,x,y,width,fn)
    local view=buttons:create(parent,vec2(width,36),buttons.types.standard_10x3)
    view.relativePosition=ViewPosition(MJPositionCenter,MJPositionTop)
    view.baseOffset=vec3(x,-y,3)
    buttons:setText(view,label)
    buttons:setClickFunction(view,function() if not self.busy then fn() end end)
    return view
end
function ui:request(data,callback)
    if self.busy then return end
    self.busy=true
    local session=self.session
    requests.call(self,"mutation","rrMemorialRequest",data,function(result)
        if session~=self.session then return end
        self.busy=false
        callback(result or {error="No server response. Please try again."})
    end)
end
function ui:render(message)
    if self.pauseSpeed==nil then
        local controls=mjrequire "mainThread/ui/timeControls"
        self.pauseSpeed=controls:getLocalSpeedPreference()
        self.world:setPaused()
        controls:updateLocalSpeedPreference(0)
    end
    if self.materialViews then
        (mjrequire "mainThread/ui/uiCommon/uiSelectionLayout"):removeAnyActiveSelectionLayoutView()
        self.materialViews=nil
    end
    self.overlay:removeAllSubviews()
    self.overlay.hidden=false
    local panel=ModelView.new(self.overlay)
    local model=mjrequire "common/model"
    panel:setModel(model:modelIndexForName("ui_bg_lg_16x9"))
    panel.relativePosition=ViewPosition(MJPositionCenter,MJPositionCenter)
    local choosing=self.mode=="choose"
    local height=self.mode=="materials" and 650 or (choosing and 565 or 365)
    panel.size=vec2(900,height)
    panel.scale3D=vec3(450,height*.5/(9/16),450)
    self:text(panel,"Rites and Remembrance",25,26)
    self:text(panel,self.person.name.." has died.",76,22,0,680)
    local objectViews=mjrequire "mainThread/ui/uiCommon/uiGameObjectView"
    local person=(mjrequire "ritesRemembrance/portrait").object(self.person)
    if person then
        local face=objectViews:create(panel,vec2(90,90),objectViews.types.backgroundCircleBordered)
        face.relativePosition=ViewPosition(MJPositionCenter,MJPositionTop)
        face.baseOffset=vec3(-370,-70,3)
        objectViews:setObject(face,person)
    end
    if self.mode=="research" then
        self:text(panel,"Discover Rites and Remembrance after Digging.",175,18)
        self:text(panel,"Memorial decisions begin with deaths after this discovery.",210,16)
        self:button(panel,"Decide later",0,285,200,function() self:defer() end)
        self.gameUI:updateUIHidden();return
    end
    if self.mode=="materials" then
        self:renderMaterials(panel,message)
        self.gameUI:updateUIHidden();return
    end
    self:text(panel,choosing and "Choose a memorial. Materials will be delivered by your tribe." or
        "Would you like to build a memorial for this tribe member?",148,18)
    if choosing then
        local choices=catalog
        for i,entry in ipairs(choices) do
            local key=entry.key
            local x=(i-(#choices+1)/2)*250
            local view=objectViews:create(panel,vec2(210,165),objectViews.types.standard)
            objectViews:setObject(view,{objectTypeIndex=(mjrequire "common/gameObject").types[key.."Preview"].index,sharedState={}})
            view.relativePosition=ViewPosition(MJPositionCenter,MJPositionTop)
            view.baseOffset=vec3(x,-188,3)
            local chooseButton=self:button(panel,entry.name,x,370,220,function() self:choose(key) end)
            local available=self.available and self.available[key]
            buttons:setDisabled(chooseButton,not available)
            self:text(panel,available and entry.cost or "Discover its material types to unlock",417,15,x,220)
        end
        self:button(panel,"Back",0,508,130,function() self.mode="ask";self:render() end)
    else
        self:button(panel,"Yes",-90,258,150,function() self.mode="choose";self:render() end)
        self:button(panel,"No",90,258,150,function()
            self:request({action="decline",id=self.person.id},function(result)
                if result.error then self:render(result.error);return end
                self:hide();self.person=nil;self.mode=nil;self.delay=1
            end)
        end)
    end
    if message then self:text(panel,message,height-32,14) end
    self.gameUI:updateUIHidden()
end
function ui:choose(key)
    self.selectedKey=key
    if catalog.find(key).personal then self.personalSelected=self.person.selected or self.personalSelected end
    self.mode="materials"
    self:render()
end
function ui:renderMaterials(panel,message)
    local entry=catalog.find(self.selectedKey)
    if entry.personal then return self:renderPersonalMaterials(panel,message) end
    local constructable=mjrequire "common/constructable"
    local helper=mjrequire "mainThread/ui/constructableUIHelper"
    local scroll=mjrequire "mainThread/ui/uiCommon/uiScrollView"
    local layout=mjrequire "mainThread/ui/uiCommon/uiSelectionLayout"
    local cfg=constructable.types[entry.key]
    local objectViews=mjrequire "mainThread/ui/uiCommon/uiGameObjectView"
    local preview=objectViews:create(panel,vec2(170,160),objectViews.types.standard)
    preview.relativePosition=ViewPosition(MJPositionCenter,MJPositionTop)
    preview.baseOffset=vec3(-195,-110,3)
    self:text(panel,entry.name,135,22,100,440)
    self:text(panel,entry.cost,174,17,100,440)
    self:text(panel,"Required materials",277,18,-210,390)
    self:text(panel,"Use only (allowed variants)",277,18,205,390)
    local left=scroll:create(panel,vec2(390,240),MJPositionInnerLeft)
    local right=scroll:create(panel,vec2(390,240),MJPositionInnerLeft)
    for i,view in ipairs({left,right}) do
        view.relativePosition=ViewPosition(MJPositionCenter,MJPositionTop)
        view.baseOffset=vec3(i==1 and -210 or 205,-315,3)
        layout:createForView(view)
    end
    self.materialViews={left,right}
    local place=self:button(panel,"Place build order",150,595,220,function() self:beginPlacement() end)
    self:button(panel,"Back",-150,595,160,function()self.mode="choose";self:render()end)
    local previewStatus=self:text(panel,"",176,14,-195,175)
    local function refreshPreview()
        local restricted=self.world:getConstructableRestrictedObjectTypes(cfg.index,false) or {}
        local composite,message=(mjrequire "ritesRemembrance/preview").build(entry.key,restricted)
        preview.hidden=not composite
        previewStatus.text=message or ""
        if composite then
            objectViews:setObject(preview,{objectTypeIndex=(mjrequire "common/gameObject").types[entry.key.."Preview"].index,
                sharedState={},compositeModelInfo=composite})
        end
    end
    helper:updateRequiredResources(left,right,cfg,function(blocked)buttons:setDisabled(place,blocked)end,refreshPreview)
    refreshPreview()
    if message then self:text(panel,message,565,14) end
end
function ui:renderPersonalMaterials(panel,message)
    local materials=mjrequire "ritesRemembrance/materials"
    local objects=mjrequire "common/gameObject"
    local objectViews=mjrequire "mainThread/ui/uiCommon/uiGameObjectView"
    local scroll=mjrequire "mainThread/ui/uiCommon/uiScrollView"
    local layout=mjrequire "mainThread/ui/uiCommon/uiSelectionLayout"
    local seen=self.world:getSeenResourceObjectTypes()
    local choices=materials.personalOptions(seen)
    self:text(panel,"Personal Memorial",135,22,130,440)
    self:text(panel,"Choose one known item. Your tribe delivers exactly one.",175,17,130,470)
    local list=scroll:create(panel,vec2(430,320),MJPositionInnerLeft)
    list.relativePosition=ViewPosition(MJPositionCenter,MJPositionTop)
    list.baseOffset=vec3(170,-230,3)
    layout:createForView(list);self.materialViews={list}
    local preview=objectViews:create(panel,vec2(210,210),objectViews.types.standard)
    preview.relativePosition=ViewPosition(MJPositionCenter,MJPositionTop)
    preview.baseOffset=vec3(-250,-240,3)
    local label=self:text(panel,"Select an item",465,18,-250,235)
    local place=self:button(panel,"Place build order",150,595,220,function()self:beginPlacement()end)
    self:button(panel,"Back",-150,595,160,function()self.mode="choose";self:render()end)
    local rowButtons={}
    local function refresh()
        local selected=self.personalSelected
        local valid=materials.restrictToPersonal(selected,seen)~=nil
        preview.hidden=not valid;buttons:setDisabled(place,not valid)
        if valid then
            objectViews:setObject(preview,{objectTypeIndex=selected,sharedState={}})
            label.text="1 "..objects.types[selected].name
        else label.text="Select an item" end
        for index,button in pairs(rowButtons) do
            buttons:setText(button,(index==selected and "[x] " or "[ ] ")..objects.types[index].name)
        end
    end
    for _,index in ipairs(choices) do
        local selectedIndex=index
        local row=View.new(list);row.size=vec2(410,42)
        local icon=objectViews:create(row,vec2(38,38),objectViews.types.standard)
        icon.relativePosition=ViewPosition(MJPositionInnerLeft,MJPositionCenter)
        objectViews:setObject(icon,{objectTypeIndex=index,sharedState={}})
        local button=buttons:create(row,vec2(360,38),buttons.types.standard_10x3)
        button.relativePosition=ViewPosition(MJPositionInnerRight,MJPositionCenter)
        buttons:setClickFunction(button,function()if not self.busy then self.personalSelected=selectedIndex;refresh() end end)
        rowButtons[index]=button;scroll:insertRow(list,row)
    end
    refresh()
    if #choices==0 then self:text(panel,"No known items are available.",555,16) end
    if message then self:text(panel,message,565,14) end
end
function ui:beginPlacement()
    local key=self.selectedKey
    local cfg=(mjrequire "common/constructable").types[key]
    local restricted=self.world:getConstructableRestrictedObjectTypes(cfg.index,false) or {}
    local selected=catalog.find(key).personal and self.personalSelected or nil
    self:request({action="choose",id=self.person.id,model=key,restricted=restricted,selected=selected},function(result)
        if result.error then self:render(result.error);return end
        self.person=result.person
        if selected then self.world.rrPersonalRestricted=(mjrequire "ritesRemembrance/materials").restrictToPersonal(selected,self.world:getSeenResourceObjectTypes()) end
        self.mode="placing"
        self:hide()
        local build=mjrequire "mainThread/ui/buildModeInteractUI"
        local constructable=mjrequire "common/constructable"
        build:show(constructable.types[key].index,false,false)
    end)
end
function ui:place(info,callback)
    if self.busy or self.mode~="placing" or not self.person then
        if callback then callback(nil) end
        return
    end
    local pos,rotation=info.pos,info.rotation
    local values={}
    for i=0,8 do values[i+1]=rotation["m"..i] end
    self:request({action="place",id=self.person.id,model=self.person.model,
        pos={pos.x,pos.y,pos.z},rotation=values,attachedToTerrain=info.attachedToTerrain==true},function(result)
        if callback then callback(result.objectID) end
        if result.error then
            (mjrequire "mainThread/ui/buildModeInteractUI"):hide()
            self.selectedKey=self.person.model
            self.mode="materials";self:render(result.error)
        else
            self.mode=nil;self.person=nil;self.delay=1
            (mjrequire "mainThread/ui/buildModeInteractUI"):hide()
        end
    end)
end
function ui:update(dt)
    if not self.gameUI:getWorldHasLoaded() or not self.world:hasSelectedTribeID() then return end
    if self.tribeID~=self.world.tribeID then
        requests.cancelAll(self)
        self.session=self.session+1;self.tribeID=self.world.tribeID
        self.person,self.mode,self.busy,self.polling=nil,nil,false,false
        self:hide();self.delay=2
    end
    if self.mode=="placing" then
        if not self.busy and (mjrequire "mainThread/ui/buildModeInteractUI"):hidden() then
            self.mode="choose";self:render("Placement cancelled. Choose a memorial or press Escape to decide later.")
        end
        return
    end
    if self:visible() or self.busy or self.polling or self.gameUI.view.hidden then return end
    self.delay=self.delay-(dt or 0)
    if self.delay>0 or not self.gameUI:canShowInvasivePopup() then return end
    if not (mjrequire "mainThread/ui/alertPanel"):hidden() or not logic:ready() then return end
    self.delay=2;self.polling=true
    local session=self.session
    requests.call(self,"poll","rrMemorialRequest",{action="poll"},function(result)
        if session~=self.session then return end
        self.polling=false
        if result and not result.error then
            self.available=result.available or {}
            local helper=mjrequire "common/planHelper"
            helper.rrResearchReady=helper.rrResearchReady or {}
            helper.rrResearchReady[self.tribeID]=result.researchReady==true
        end
        if result and result.person and self.gameUI:canShowInvasivePopup() then
            if result.researchLocked and self.researchNotified[self.tribeID] then return end
            if result.researchLocked then self.researchNotified[self.tribeID]=true end
            self.person=result.person
            self.mode=result.researchLocked and "research" or (result.person.status=="chosen" and "choose" or "ask")
            self:render()
        end
    end)
end
return ui
