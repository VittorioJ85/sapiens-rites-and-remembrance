local mod = {loadOrder=25}
function mod:onload(sapiens)
    local sequence=sapiens.actionSequenceTypeIndexForOrder
    function sapiens:actionSequenceTypeIndexForOrder(sapien,object,state)
        if state.orderTypeIndex==(mjrequire "common/order").types.rrTribalCeremony.index then
            return (mjrequire "common/actionSequence").types.rrTribalCeremony.index
        end
        if state.orderTypeIndex==(mjrequire "common/order").types.rrRememberTogether.index then
            return (mjrequire "common/actionSequence").types.rrRememberTogether.index
        end
        if state.orderTypeIndex==(mjrequire "common/order").types.rrRememberAncestors.index then
            return (mjrequire "common/actionSequence").types.rrRememberAncestors.index
        end
        return sequence(self,sapien,object,state)
    end
    local original = sapiens.updateStatusForFriendsOfDyingSapien
    function sapiens:updateStatusForFriendsOfDyingSapien(sapien, ...)
        (mjrequire "ritesRemembrance/service"):died(sapien)
        return original(self, sapien, ...)
    end
end
return mod
