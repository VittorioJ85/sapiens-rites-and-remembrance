local service = mjrequire "ritesRemembrance/service"
local mod = {loadOrder=25}
function mod:onload(world)
    local original = world.setBridge
    function world:setBridge(...)
        service.db=nil
        original(self, ...)
        service:init(self, mjrequire "server/serverGOM")
        self.rrCeremonyTick=nil
        local server=mjrequire "server/server"
        server:registerNetFunction("rrTribalCeremony",function(clientID,request)
            return (mjrequire "ritesRemembrance/tribalCeremony").request(service,clientID,request)
        end)
        server:registerNetFunction("rrMemorialRequest", function(clientID, request)
            return service:request(clientID, request)
        end)
        server:registerNetFunction("rrRememberAncestors",function(clientID,request)
            return (mjrequire "ritesRemembrance/ancestorVisit").request(service,clientID,request)
        end)
        server:registerNetFunction("rrRememberTogether",function(clientID,request)
            return (mjrequire "ritesRemembrance/familyVisit").request(service,clientID,request)
        end)
    end
    local update=world.update
    function world:update(dt,worldTime,speed,...)
        local result=update(self,dt,worldTime,speed,...)
        if dt>0 and speed>0.0001 and (not self.rrCeremonyTick or worldTime-self.rrCeremonyTick>=.5) then
            self.rrCeremonyTick=worldTime;
            (mjrequire "ritesRemembrance/tribalCeremony").tick(service)
        end
        return result
    end
end
return mod
