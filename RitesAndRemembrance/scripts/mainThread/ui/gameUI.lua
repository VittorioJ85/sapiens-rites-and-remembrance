local mod={loadOrder=25}
function mod:onload(gameUI)
    local ui=mjrequire "ritesRemembrance/ui"
    local ceremony=mjrequire "ritesRemembrance/ceremonyUI"
    local function visible()return ui:visible() or ceremony:visible()end
    local init=gameUI.init
    function gameUI:init(controller,world,...)
        init(self,controller,world,...)
        ui:init(self,world)
        ceremony:init(self,world)
    end
    local panel=gameUI.hasUIPanelDisplayed
    function gameUI:hasUIPanelDisplayed(...) return visible() or panel(self,...) end
    local mouse=gameUI.shouldShowMouse
    function gameUI:shouldShowMouse(...) return visible() or mouse(self,...) end
    local invasive=gameUI.canShowInvasivePopup
    function gameUI:canShowInvasivePopup(...) return not visible() and invasive(self,...) end
    local pop=gameUI.popUI
    function gameUI:popUI(...)
        if ceremony:visible() then ceremony:hide();return true end
        if ui:visible() then ui:defer();return true end
        return pop(self,...)
    end
    -- Block world interactions while the memorial dialog owns input. Normal UI
    -- buttons still receive events from the view hierarchy.
    for _,name in ipairs({"interact","rightClick","mouseDown","mouseUp"}) do
        local original=gameUI[name]
        gameUI[name]=function(self,...)
            if visible() then return end
            return original(self,...)
        end
    end
end
return mod
