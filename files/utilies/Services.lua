--SX_VM_CNONE();





local Services = {};
local vim = getvirtualinputmanager and getvirtualinputmanager();

function Services:Get(...)
    local requestedServices = {};

    for _, serviceName in ipairs({...}) do
        table.insert(requestedServices, self[serviceName]);
    end

    return table.unpack(requestedServices);
end

setmetatable(Services, {
    __index = function(self, serviceName)
        local success, service = pcall(function()
            return game:GetService(serviceName);
        end);

        if (serviceName == "VirtualInputManager") then
            if (vim) then
                return vim;
            end;
            --service.Name = getServerConstant("VirtualInputManager ");
        end;

        if (success) then
            rawset(self, serviceName, service);
            return service;
        else;
            error("Failed to get service: "..tostring(serviceName));
            return nil;
        end;
    end;
});

return Services;
