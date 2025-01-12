--SX_VM_CNONE();





local Methods = {};

local sources = {game = game, math = math, string = string, table = table};

function Methods:Get(...)
    local methods = {...};
    local functions = {};

    local function getMethod(source, key, name)
        local success, method = pcall(function()
            return source[key];
        end);
        if (success) then
            if (typeof(method) ~= "function") then
                error(("Failed to get Method - not a Function: %s"):format(name));
                return nil;
            end;
            return method;
        end;
        return nil;
    end;

    for _, methodName in ipairs(methods) do
        local func = nil;

        if (string.find(methodName, "%.")) then
            local parts = string.split(methodName, ".");
            local tableName, methodKey = parts[1], parts[2];

            local source = sources[tableName];
            if (source) then
                func = getMethod(source, methodKey, methodName);
            end;
        else
            for _, source in pairs(sources) do
                func = getMethod(source, methodName, methodName);
                if (func) then break; end;
            end;
        end;

        if (func) then
            table.insert(functions, func); -- clonefunction(func)
        else
            error(("Failed to get Method: %s"):format(methodName));
        end;
    end;

    return table.unpack(functions);
end;

return Methods;
