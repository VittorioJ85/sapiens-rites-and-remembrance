local mod={loadOrder=25}
function mod:onload(animation)
    local change=animation.changeAnimation
    function animation:changeAnimation(object,index,groupIndex,speed)
        local state=object.sharedState and object.sharedState.actionState
        local sequence=(mjrequire "common/actionSequence").types.rrRememberAncestors
        local together=(mjrequire "common/actionSequence").types.rrRememberTogether
        local tribal=(mjrequire "common/actionSequence").types.rrTribalCeremony
        if state and tribal and state.sequenceTypeIndex==tribal.index and state.progressIndex==3 then
            local group=(mjrequire "common/animationGroups").groups[groupIndex]
            local dance=group and group.animations.rrTribalDance
            if dance then
                index=dance.index
                local seed=0
                for i=1,#object.uniqueID do seed=(seed+object.uniqueID:byte(i))%7 end
                speed=.94+seed*.02
            end
        end
        if state and ((sequence and state.sequenceTypeIndex==sequence.index and state.progressIndex==2) or
            (together and state.sequenceTypeIndex==together.index and state.progressIndex==3)) then
            local group=(mjrequire "common/animationGroups").groups[groupIndex]
            local remembrance=group and group.animations.rrRememberAncestors
            if remembrance then index=remembrance.index;speed=1.0 end
        end
        return change(self,object,index,groupIndex,speed)
    end
end
return mod
