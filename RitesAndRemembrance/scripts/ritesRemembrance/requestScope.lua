-- Bound client waiting, not server execution. Never replay a timed-out write:
-- its outcome is unknown until a later poll/inspection retrieves server state.
local requests={timeout=10}
function requests.cancelAll(owner)
    for _,cancel in pairs(owner.rrPendingRequests or {}) do cancel() end
    owner.rrPendingRequests=nil
end
function requests.call(owner,key,endpoint,data,callback)
    local pending=owner.rrPendingRequests or {}
    owner.rrPendingRequests=pending
    if pending[key] then return false end
    local timer=mjrequire "common/timer"
    local done,timerID=false,nil
    local function cancel()
        if done then return end
        done=true;pending[key]=nil
        if timerID then timer:removeTimer(timerID);timerID=nil end
    end
    local function complete(result)
        if done then return end
        cancel()
        callback(result or {error="No server response. Close this window and try again."})
    end
    pending[key]=cancel
    timerID=timer:addCallbackTimer(requests.timeout,function()
        -- Native one-shot timers remove themselves before invoking callbacks.
        timerID=nil
        complete({error="No server response. The result is unknown. Close this window and try again.",timedOut=true})
    end)
    local logic=mjrequire "mainThread/logicInterface"
    logic:callServerFunction(endpoint,data,complete)
    return true
end
return requests
