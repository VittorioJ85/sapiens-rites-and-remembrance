local mod={loadOrder=25}
function mod:onload(actionUI)
    local finish=actionUI.animateOutForOptionSelected
    function actionUI:animateOutForOptionSelected(...)
        if (mjrequire "ritesRemembrance/ceremonyUI"):visible() then return self:hide() end
        local link=mjrequire "ritesRemembrance/familyLink"
        -- Native sendPlan is followed by this job-style dismissal. Family Tree
        -- opens a modal instead: dismiss only the wheel, preserving its owner.
        if link.container and not link.container.hidden then
            return self:hide()
        end
        local panel=mjrequire "mainThread/ui/inspect/inspectObjectUI"
        if panel.rrKeepInspectionAfterAction and panel:rrKeepInspectionAfterAction() then
            -- Keep server validation feedback visible below the memorial name.
            return self:hide()
        end
        return finish(self,...)
    end
end
return mod
