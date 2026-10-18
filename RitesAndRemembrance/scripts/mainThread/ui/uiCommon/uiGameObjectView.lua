local mod={loadOrder=25}
function mod:onload(objectViews)
    local original=objectViews.setObject
    function objectViews:setObject(view,object,restricted,seen)
        local entry=(mjrequire "ritesRemembrance/catalog").forObject(object)
        if not entry then return original(self,view,object,restricted,seen) end

        -- Hover cards and build markers request world objects directly. Their
        -- placeholder assemblies need the same concrete UI mesh as the dialog.
        -- Substitute only the local thumbnail; never modify the world object.
        local state=object.sharedState or {}
        if entry.personal then
            local selected=(state.rrMemorial and state.rrMemorial.selected) or
                (mjrequire "ritesRemembrance/materials").personalSelection(restricted or state.restrictedResourceObjectTypes or {})
            if selected then return original(self,view,{objectTypeIndex=selected,sharedState={}},nil,nil) end
            return self:setModelName(view,"icon_rrRemembrance")
        end
        local composite=(mjrequire "ritesRemembrance/preview").build(entry.key,
            restricted or state.restrictedResourceObjectTypes or {})
        if not composite then
            -- A symbolic icon is preferable to depicting unsupported materials.
            return self:setModelName(view,"icon_rrRemembrance")
        end
        return original(self,view,{
            objectTypeIndex=(mjrequire "common/gameObject").types[entry.key.."Preview"].index,
            sharedState={},compositeModelInfo=composite,
        },nil,nil)
    end
end
return mod
