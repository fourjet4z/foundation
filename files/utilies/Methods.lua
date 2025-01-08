--SX_VM_CNONE();





local Methods = {};

function Methods:Get(...)
    local methods = {...};
    local functions = {};

    for _, methodName in ipairs(methods) do
        local func = game[methodName];
        if (func and typeof(func) == "function") then
            table.insert(functions, func); --
        else;
            error("Failed to get Method: "..tostring(func));
        end;
    end;

    return table.unpack(functions);
end;

return Methods;
