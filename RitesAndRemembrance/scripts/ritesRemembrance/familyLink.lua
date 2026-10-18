local link={}
local owner,cachedParent,cachedContainer,cachedPanel,cachedFamily
local function invalidateRequest(instance)
    instance.serial=(instance.serial or 0)+1
    if instance.cancelRequest then instance.cancelRequest();instance.cancelRequest=nil end
end
function link.reset()
    -- A reloaded inspector owns new native views. Invalidate replies without
    -- touching a retired view (hide/closeTree may access native UI objects).
    if cachedFamily then
        cachedFamily.hidden=true
        invalidateRequest(cachedFamily)
        -- The project's Family Tree has separate branch and settings requests.
        -- Their normal close methods touch native views; retire only their
        -- request state here, leaving view destruction to the native parent.
        local tree=cachedFamily.tree
        if tree then
            tree.active=false;tree.drag=nil
            if tree.model then tree.model:close() end
            local timer=mjrequire "common/timer"
            for id in pairs(tree.timers or {}) do timer:removeTimer(id) end
            tree.timers={};cachedFamily.tree=nil
        end
        if cachedFamily.settings then
            invalidateRequest(cachedFamily.settings);cachedFamily.settings=nil
        end
    end
    link.panel,link.container=nil,nil
    owner,cachedParent,cachedContainer,cachedPanel,cachedFamily=nil,nil,nil,nil,nil
end
function link.available()
    local manager=mjrequire "common/modManager"
    for _,enabled in ipairs(manager.enabledModDirNamesAndVersionsByType.world or {}) do
        local info=manager.modInfosByTypeByDirName.world[enabled.name]
        if enabled.name=="FamilyTree" or (info and info.name=="Family Tree") then return true end
    end
    return false
end
function link.open(inspect,memorial)
    if not link.available() then return end
    if owner~=inspect or cachedParent~=inspect.modalPanelView then link.reset() else link.close() end
    if not cachedContainer then
        local family={}
        -- Reuse Family Tree's implementation with independent navigation state.
        -- Its living-person panel retains its own singleton instance.
        for key,value in pairs(mjrequire "familyTree/ui") do
            if type(value)=="function" then family[key]=value end
        end
        family.serial=0
        local container=View.new(inspect.modalPanelView)
        container.size=inspect.modalPanelView.size
        container.relativePosition=ViewPosition(MJPositionCenter,MJPositionCenter)
        container.hidden=true
        family:init(container)
        local panel={}
        function panel:hide()
            if not family.hidden then family:hide() end
            -- Native inspectUI can retain currentModalContainerView when its
            -- main view is already hidden. Never destroy that borrowed view.
            -- Reuse one container for this inspector; its parent owns teardown.
            container.hidden=true
        end
        function panel:popUI() return family:popUI() end
        owner,cachedParent,cachedContainer,cachedPanel,cachedFamily=inspect,inspect.modalPanelView,container,panel,family
    end
    inspect:setModalPanelTitleAndObject("Family of "..memorial.name,nil)
    inspect:showModalPanelView(cachedContainer,cachedPanel)
    -- showModalPanelView does nothing if the same view is still selected.
    cachedContainer.hidden=false
    inspect.modalPanelView.hidden=false
    link.container=cachedContainer;link.panel=cachedPanel
    cachedFamily:show({uniqueID=memorial.id,sharedState={name=memorial.name}})
end
function link.close()
    if link.panel then link.panel:hide() end
    link.panel,link.container=nil,nil
end
return link
