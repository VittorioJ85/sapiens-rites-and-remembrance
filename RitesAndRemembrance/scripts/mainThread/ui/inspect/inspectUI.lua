local mod={loadOrder=25}
function mod:onload(inspect)
    local link=mjrequire "ritesRemembrance/familyLink"
    local load=inspect.load
    function inspect:load(...)
        link.reset()
        return load(self,...)
    end
    local hide=inspect.hideUIPanel
    function inspect:hideUIPanel(...)
        local result=hide(self,...)
        link.close()
        return result
    end
    local show=inspect.showModalPanelView
    function inspect:showModalPanelView(container,...)
        local result=show(self,container,...)
        if link.container and link.container~=container then link.close() end
        return result
    end
end
return mod
