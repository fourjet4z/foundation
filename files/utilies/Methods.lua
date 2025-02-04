--SX_VM_CNONE();




local Methods = {};

local sources = { game = game, Instance = Instance, math = math, string = string, table = table };

function Methods:Get(...)
    local requestedMethods = {};
    for _, methodName in ipairs({...}) do
        table.insert(requestedMethods, self[methodName]);
    end;
    return table.unpack(requestedMethods);
end;

local function getMethod(source, key)
    local success, method = pcall(function()
        return source[key];
    end);
    if (success and typeof(method) == "function") then
        return method;
    else
        return nil;
    end;
end;

setmetatable(Methods, {
    __index = function(self, methodName)
        local func = nil
        if (string.find(methodName, "%.")) then
            local parts = string.split(methodName, ".");
            local tableName, methodKey = parts[1], parts[2];
            local source = sources[tableName];
            if (source) then
                func = getMethod(source, methodKey);
            end;
        else
            for _, source in pairs(sources) do
                func = getMethod(source, methodName);
                if (func) then break; end;
            end;
        end;

        if (func) then
            rawset(self, methodName, func);
            return func;
        else
            error(("Failed to get Method: %s"):format(methodName));
            return nil;
        end;
    end;
});

return Methods;
