-- Loaded only when Hammerstone's optional options module exists in this world.
local mod={loadOrder=25}
function mod:onload(ui)
    local create=ui.createControls
    function ui:createControls(parent,popovers,key,options,values)
        if key~="ritesRemembrance" then return create(self,parent,popovers,key,options,values) end
        local mjm=mjrequire "common/mjm"
        local common=mjrequire "mainThread/ui/uiCommon/uiCommon"
        local text=TextView.new(parent)
        text.font=Font(common.fontName,18)
        text.color=mj.textColor
        text.relativePosition=ViewPosition(MJPositionInnerLeft,MJPositionTop)
        text.baseOffset=mjm.vec3(20,-20,1)
        text.wrapWidth=550
        text.text="Rites and Remembrance — by Vittorio\n\nAfter Digging and a tribal death, investigate soil or clay. Only later deaths prompt memorial decisions.\n\nBuild a Gravestone, Funerary Urn or Personal Memorial. Burial: +1 Happiness/Loyalty for 1,000 seconds. Demolition: -1 for 2,000 seconds.\n\nRemember Ancestors: +1 Happiness for 1,000 seconds. Remember Together: +1 Happiness/Loyalty for 2,000 seconds and stronger family relationships.\n\nTribal Ceremony (once per game year): select an object or ground in the circular menu, then choose a radius or box. Requires 25 tribe members and 25% attendance for rewards.\n\nParticipants gain +2 Happiness/Loyalty above 50% attendance, otherwise +1. Work speed: attendance percentage x 0.2, rounded (100% = +20%). Duration: 3 game days, or 1 day below 50%.\n\nMissing invitations retry automatically; Invite Again allows more attempts. Visits interrupt ordinary work. Their own bonuses do not stack or refresh; timers pause with the game. A grave's circular menu also opens the optional Family Tree."
    end
end
return mod
