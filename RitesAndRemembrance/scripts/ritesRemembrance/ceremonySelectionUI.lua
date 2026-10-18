-- Native selection controls/assets and multiSelectUI mouse conventions, scoped
-- to ceremony slots. The native singleton selects world objects and has no
-- custom-data callback, so it must not be repurposed or have its globals changed.
local selector={}
function selector.create(parent,slots,interactive,onChange)
    local m=mjrequire "common/mjm"
    local model=mjrequire "common/model"
    local material=mjrequire "common/material"
    local selection=mjrequire "ritesRemembrance/ceremonySelection"
    local popup=mjrequire "mainThread/ui/uiCommon/uiPopUpButton"
    local result={slots=slots,mode="radius",maxRadius=1,markers={}}
    for _,slot in ipairs(slots)do result.maxRadius=math.max(result.maxRadius,math.sqrt(slot.x^2+slot.y^2)+1) end
    result.selection={kind="radius",radius=result.maxRadius}
    local half=155
    local scale=(half-10)/result.maxRadius
    local area=View.new(parent);result.area=area
    area.relativePosition=ViewPosition(MJPositionCenter,MJPositionTop)
    area.baseOffset=m.vec3(-110,-200,2);area.size=m.vec2(half*2,half*2)
    area.masksEvents=interactive
    local function centered(view,x,y,z)
        view.relativePosition=ViewPosition(MJPositionCenter,MJPositionCenter)
        view.baseOffset=m.vec3(x or 0,y or 0,z or 0);view.masksEvents=false
    end
    local background=ModelView.new(area);centered(background)
    background:setModel(model:modelIndexForName("ui_radarBackground_inset"))
    background.scale3D=m.vec3(half,half,half);background.size=area.size;background.alpha=.85
    local highlight=ModelView.new(area);centered(highlight,0,0,1);highlight.alpha=.35
    local center=ColorView.new(area);centered(center,0,0,3)
    center.size=m.vec2(10,10);center.color=m.vec4(1,.72,.25,1)
    for _,slot in ipairs(slots)do
        local dot=ColorView.new(area);centered(dot,slot.x*scale,slot.y*scale,3)
        dot.size=m.vec2(6,6);result.markers[#result.markers+1]=dot
    end
    function result:refresh()
        local shape=self.selection
        local count=0
        local emptyHighlight=false
        for i,slot in ipairs(self.slots)do
            local included=selection.contains(shape,slot)
            self.markers[i].color=included and m.vec4(.5,.85,1,1) or m.vec4(.3,.3,.3,.65)
            if included then count=count+1 end
        end
        if shape.kind=="radius" then
            emptyHighlight=shape.radius<=0
            local size=math.max(.01,shape.radius*scale)
            highlight:setModel(model:modelIndexForName("ui_radarBackground"),{default=material.types.ui_selected.index})
            highlight.size=m.vec2(size*2,size*2);highlight.scale3D=m.vec3(size,size,size)
            highlight.baseOffset=m.vec3(0,0,1)
        else
            local width,height=math.abs(shape.x2-shape.x1)*scale,math.abs(shape.y2-shape.y1)*scale
            emptyHighlight=width<.1 or height<.1
            width,height=math.max(.01,width),math.max(.01,height)
            highlight:setModel(model:modelIndexForName("ui_boxSelect"),{default=material.types.ui_selected.index})
            highlight.size=m.vec2(width,height);highlight.scale3D=m.vec3(width*.5,height*.5,half)
            highlight.baseOffset=m.vec3((shape.x1+shape.x2)*.5*scale,(shape.y1+shape.y2)*.5*scale,1)
        end
        highlight.hidden=not interactive or emptyHighlight
        self.count=count
        if onChange then onChange(count,shape) end
    end
    local function point(loc)
        return math.max(-result.maxRadius,math.min(result.maxRadius,(loc.x-half)/scale)),
            math.max(-result.maxRadius,math.min(result.maxRadius,(loc.y-half)/scale))
    end
    local function drag(loc)
        local x,y=point(loc)
        if result.mode=="radius" then
            result.selection={kind="radius",radius=math.min(result.maxRadius,math.sqrt(x*x+y*y))}
        elseif result.origin then
            result.selection={kind="box",x1=result.origin.x,y1=result.origin.y,x2=x,y2=y}
        end
        result:refresh()
    end
    if interactive then
        area.mouseDown=function(button,loc)
            if button~=0 then return end
            local x,y=point(loc);result.origin={x=x,y=y};drag(loc)
        end
        area.mouseDragged=drag
        area.mouseUp=function(button,loc)if button==0 then drag(loc);result.origin=nil end end
        area.mouseWheel=function(_,scroll)
            if result.mode=="radius" then
                result.selection.radius=math.max(0,math.min(result.maxRadius,result.selection.radius-5*scroll.y))
                result:refresh()
            end
        end
        local popovers=View.new(parent);popovers.size=parent.size;popovers.baseOffset=m.vec3(0,0,15);popovers.masksEvents=false
        local control=popup:create(parent,popovers,m.vec2(210,40),m.vec2(230,130));result.control=control
        control.relativePosition=ViewPosition(MJPositionCenter,MJPositionTop);control.baseOffset=m.vec3(240,-245,4)
        popup:setItems(control,{{name="Radius Select",iconModelName="icon_multiSelectRadial"},
            {name="Box Select",iconModelName="icon_multiSelectRect"}})
        popup:setSelection(control,1)
        popup:setSelectionFunction(control,function(index)
            result.origin=nil;result.mode=index==1 and "radius" or "box"
            local r=result.maxRadius
            result.selection=result.mode=="radius" and {kind="radius",radius=r} or {kind="box",x1=-r,y1=-r,x2=r,y2=r}
            result:refresh()
        end)
    end
    function result:close()if self.control then popup:hidePopupMenu(self.control)end end
    result:refresh()
    return result
end
return selector
