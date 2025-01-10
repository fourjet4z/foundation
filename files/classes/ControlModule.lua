--SX_VM_CNONE();





local Services = loadstring(game:HttpGet("https://raw.githubusercontent.com/fourjet4z/foundation/refs/heads/main/files/utilies/Services.lua"))();



local ContextActionService, HttpService = Services:Get("ContextActionService", "HttpService");

local ControlModule = {};
ControlModule.__index = ControlModule;

local bindings = {
    { key = "forward", value = -1, keyCode = Enum.KeyCode.W },
    { key = "backward", value = 1, keyCode = Enum.KeyCode.S },
    { key = "left", value = -1, keyCode = Enum.KeyCode.A },
    { key = "right", value = 1, keyCode = Enum.KeyCode.D }
};
function ControlModule.new()
    local bindingsMovementValues = {};
    for _, binding in ipairs(bindings) do
        bindingsMovementValues[binding.key] = 0;
    end;

    local self = setmetatable({
        movementValues = bindingsMovementValues
    }, ControlModule);

    self:init();
    return self;
end;

function ControlModule:init()
    local defaultResult = Enum.ContextActionResult.Pass;

    local function handleMovement(key, value)
        return function(_, inputState)
            self.movementValues[key] = (inputState == Enum.UserInputState.Begin) and value or 0;
            return defaultResult;
        end;
    end;

    for _, binding in ipairs(bindings) do --ipairs needed
        ContextActionService:BindAction(
            HttpService:GenerateGUID(false), --Generate a unique identifier
            handleMovement(binding.key, binding.value),
            false,
            binding.keyCode
        );
    end;
end;

function ControlModule:GetMoveVector()
    local values = self.movementValues;
    return Vector3.new(values.left + values.right, 0, values.forward + values.backward);
end;

return ControlModule.new();
