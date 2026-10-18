local mod={loadOrder=25}
function mod:onload(panel)
    local inspect,statusView,currentObjectID,message
    local generation=0
    local requests=mjrequire "ritesRemembrance/requestScope"
    local requestOwner={}
    local keepInspection=false
    function panel:rrKeepInspectionAfterAction()
        local keep=keepInspection and currentObjectID~=nil
        keepInspection=false
        return keep
    end
    local load=panel.load
    function panel:load(gameUI,inspectUI,...)
        requests.cancelAll(requestOwner)
        generation=generation+1;currentObjectID=nil;message=nil;keepInspection=false
        inspect=inspectUI
        load(self,gameUI,inspectUI,...)
        local mjm=mjrequire "common/mjm"
        statusView=TextView.new(inspect.containerView)
        statusView.font=Font((mjrequire "mainThread/ui/uiCommon/uiCommon").fontName,14)
        statusView.color=mj.textColor
        statusView.relativePosition=ViewPosition(MJPositionInnerLeft,MJPositionBottom)
        statusView.baseOffset=mjm.vec3(124,10,4)
        statusView.hidden=true
    end
    function panel:rrPerformAction(entry,id,callback)
        local object=inspect and inspect.baseObjectOrVertInfo
        if not object or currentObjectID~=id or inspect.selectedObjectOrVertInfoCount~=1 or
            not object.sharedState.rrMemorial or not (mjrequire "common/gameObject").types[object.objectTypeIndex].isBuiltObject then
            if callback then callback({error="Select one completed family memorial."}) end
            return
        end
        if not entry.endpoint then
            (mjrequire "ritesRemembrance/familyLink").open(inspect,object.sharedState.rrMemorial)
            if callback then callback({ok=true}) end
            return
        end
        keepInspection=true
        if requestOwner.rrPendingRequests and requestOwner.rrPendingRequests[id] then return end
        message="Checking family availability..."
        self:updateObjectInfo()
        local token=generation
        requests.call(requestOwner,id,entry.endpoint,{objectID=id},function(result)
            if currentObjectID==id and token==generation then
                message=result and (result.error or result.message or ((result.name or "A relative").." is going to remember.")) or "Please try again."
                self:updateObjectInfo()
            end
            if callback then callback(result) end
        end)
    end
    local update=panel.updateObjectInfo
    function panel:updateObjectInfo(...)
        update(self,...)
        local object=inspect.baseObjectOrVertInfo
        local memorial=object and object.sharedState and object.sharedState.rrMemorial
        local selectedID=memorial and inspect.selectedObjectOrVertInfoCount==1 and object.uniqueID or nil
        if selectedID~=currentObjectID then generation=generation+1;message=nil;keepInspection=false end
        currentObjectID=selectedID
        statusView.hidden=true;statusView.text=""
        if selectedID then
            inspect:setTitleText("In memory of "..memorial.name.." (age "..memorial.age..")",false)
            local person=(mjrequire "ritesRemembrance/portrait").object(memorial)
            if person then inspect:setIconForObject(person) end
            -- Native sizing measures nameTextEntry, not our titleTextView.
            -- Include the actual rendered title width and a right margin.
            local contentWidth=math.max(inspect.defaultContentWidth,inspect.titleTextView.size.x+12)
            inspect.contentExtraWidth=math.max(inspect.contentExtraWidth,contentWidth-inspect.defaultContentWidth)
            if message then
                statusView.wrapWidth=contentWidth
                statusView.text=message;statusView.hidden=false
                inspect.contentExtraHeight=inspect.contentExtraHeight+statusView.size.y+8
            end
        end
    end
    local hide=panel.hide
    function panel:hide(...)
        requests.cancelAll(requestOwner)
        if statusView then statusView.hidden=true end
        generation=generation+1;currentObjectID=nil;message=nil;keepInspection=false
        return hide(self,...)
    end
end
return mod
