local mod={loadOrder=25}
function mod:onload(common)
    local setup=common.setup
    -- Dance poses exist in the native skeleton enum but are not exported as
    -- animations. Resolve the named enum from the setup closure, read-only.
    -- Bounded traversal tolerates a wrapping mod; never hard-code frame indexes.
    local function nativeFrames(fn,depth,seen)
        if not debug or not debug.getupvalue or depth>4 or seen[fn] then return nil end
        seen[fn]=true
        for i=1,64 do
            local name,value=debug.getupvalue(fn,i)
            if not name then break end
            if name=="keyframes" and type(value)=="table" and value.dance1 and value.dance2 and value.dance3 and value.dance4 then return value end
            if type(value)=="function" then
                local found=nativeFrames(value,depth+1,seen)
                if found then return found end
            end
        end
    end
    local danceFrames=nativeFrames(setup,0,{})
    function common:setup(info,...)
        setup(self,info,...)
        local frames=info.animations
        -- Public 0.6.1.3 lacks crouchLow. Resolve optional poses by capability;
        -- never invent skeleton frame indexes or copy animation triggers.
        local function pose(name)
            local animation=frames[name]
            return animation and animation.keyframes and animation.keyframes[1] and animation.keyframes[1][1]
        end
        local stand=assert(pose("stand"),"Remembrance requires the native stand pose")
        local sit=pose("sitFocus") or pose("sit1") or stand
        local crouch=pose("crouchLow") or pose("crouch") or sit
        -- A new eight-second sequence using the game's compatible skeleton poses.
        -- No tools, particles or crafting sound triggers are copied.
        mj:insertIndexed(frames,{key="rrRememberAncestors",keyframes={
            {stand,0.7},
            {crouch,1.0},
            {sit,1.0},
            {sit,3.6},
            {crouch,1.0},
            {stand,0.7},
        }})
        local dance={}
        for _,name in ipairs({"dance1","dance2","dance3","dance4","dance3","dance2"}) do
            dance[#dance+1]={danceFrames and danceFrames[name] or sit,.5}
        end
        mj:insertIndexed(frames,{key="rrTribalDance",keyframes=dance})
    end
end
return mod
