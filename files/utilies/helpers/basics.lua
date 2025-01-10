--SX_VM_CNONE();





local Utility = loadstring(game:HttpGet("https://raw.githubusercontent.com/fourjet4z/foundation/refs/heads/main/files/utilies/Utility.lua"))();
local Services = loadstring(game:HttpGet("https://raw.githubusercontent.com/fourjet4z/foundation/refs/heads/main/files/utilies/Services.lua"))();
local Methods = loadstring(game:HttpGet("https://raw.githubusercontent.com/fourjet4z/foundation/refs/heads/main/files/utilies/Methods.lua"))();
local Slave = loadstring(game:HttpGet("https://raw.githubusercontent.com/fourjet4z/foundation/refs/heads/main/files/utilies/Slave.lua"))();



local Players, UserInputService, RunService, Lighting = Services:Get('Players', 'UserInputService', 'RunService', "Lighting");


local basicsHelpers = {};

local IsA, IsAncestorOf = Methods:Get("game.IsA", "game.IsAncestorOf");

local bigSlave = Slave.SichNew();

local modelData = {};
function basicsHelpers.setClip(model, canCollide, canTouch) --if input properties are nil then keep default properties
    if (not model or not model.Parent or not IsAncestorOf(game, model)) then return; end;

    basicsHelpers.redoClip(model);

    local slave = Slave.SichNew();
    modelData[model] = {
        slave = slave,
        changedParts = {}
    };

    local function setModelProperties()
        for _, part in pairs(model:GetDescendants()) do
            if (IsA(part, "BasePart")) then
                local changes = modelData[model].changedParts[part] or {};

                if (canCollide ~= nil and part.CanCollide ~= canCollide) then
                    changes.CanCollide = part.CanCollide;
                    part.CanCollide = canCollide;
                end;

                if (canTouch ~= nil and part.CanTouch ~= canTouch) then
                    changes.CanTouch = part.CanTouch;
                    part.CanTouch = canTouch;
                end;

                if (next(changes)) then
                    slave:GiveTask(part.AncestryChanged:Connect(function()
                        if IsAncestorOf(model, part) then return; end;
                        modelData[model].changedParts[part] = nil;
                        slave:SichDestroy();
                    end));
                    modelData[model].changedParts[part] = changes;
                end;
            end;
        end;
    end;

    setModelProperties();

    slave:GiveTask(RunService.Stepped:Connect(setModelProperties));

    slave:GiveTask(model.AncestryChanged:Connect(function()
        if model.Parent or IsAncestorOf(game, model) then return; end;
        basicsHelpers.redoClip(model);
    end));
end;

function basicsHelpers.redoClip(model) --redo setClip
    local data = modelData[model];
    if (not data) then return; end;

    for part, changes in pairs(data.changedParts or {}) do
        if (part.Parent) then
            for property, value in pairs(changes or {}) do
                part[property] = value;
            end;
        end;
    end;

    data.slave:SichDestroy();
    modelData[model] = nil;
end;

local bdVelcs = {};
function basicsHelpers.noPhysics(obj, options)
    if (not obj.Parent or not IsAncestorOf(game, obj)) then return; end;

    if (options.offset) then
        obj.CFrame = CFrame.new(obj.CFrame.Position) * options.offset.Rotation;
    end;

    if (not bdVelcs[obj]) then
        local bdVelc = Instance.new("BodyVelocity");
        bdVelc.Name = "NoPhysics";
        bdVelc.MaxForce = Vector3.one * math.huge;
        bdVelc.Velocity = Vector3.zero;

        local slave = Slave.SichNew();
        bdVelcs[obj] = {
            slave = slave,
            bdVelc = bdVelc
        };

        local function handleDestruction(readd)
            basicsHelpers.destroyNoPhysics(obj);
            if (readd) then basicsHelpers.noPhysics(obj, options) end;
        end;

        slave:GiveTask(obj.AncestryChanged:Connect(function()
            handleDestruction(false);
        end));

        --readd if game delete "NoPhysics"
        slave:GiveTask(bdVelc.AncestryChanged:Connect(handleDestruction(true)));
        slave:GiveTask(bdVelc.Destroying:Connect(handleDestruction(true)));

        bdVelc.Parent = obj;
    end;
end;

function basicsHelpers.destroyNoPhysics(obj)
    local bdVelcData = bdVelcs[obj];
    if (not bdVelcData) then return; end;

    bdVelcData.slave:SichDestroy();
    bdVelcData.bdVelc:Destroy();
    bdVelcs[obj] = nil;
end;

function basicsHelpers.destroyPhysics(obj)
    local localBdVelcs = Utility:getInstancesClassNameOf(obj, "BodyVelocity", false) or {};
    for _, bdVelc in pairs(localBdVelcs) do
        bdVelc:Destroy();
    end;
end;

local lastFogsDensity = {};
function basicsHelpers.noFog(toggle)
    local atmospheres = Utility:getInstancesClassNameOf(Lighting, "Atmosphere", false) or {};
    for _, atmosphere in pairs(atmospheres) do
        if (not toggle) then
            bigSlave.noFog:RemoveAllTasks();
            if (lastFogsDensity[atmosphere]) then
                atmosphere.Density = lastFogsDensity[atmosphere];
            end;
            return;
        end;

        bigSlave.noFog:GiveTask(atmosphere:GetPropertyChangedSignal('Density'):Connect(function()
            atmosphere.Density = 0;
        end));

        lastFogsDensity[atmosphere] = atmosphere.Density or 0;
        atmosphere.Density = 0;
    end;
end;

function basicsHelpers.noBlur(toggle)
    local blurs = Utility:getInstancesClassNameOf(Lighting, "BlurEffect", false) or {};
    local depthOfFields = Utility:getInstancesClassNameOf(Lighting, "DepthOfFieldEffect", false) or {};
    for _, blur in pairs(blurs) do
        if (not toggle) then
            bigSlave.noBlur:RemoveAllTasks();
            blur.Enabled = true;
            return;
        end;

        bigSlave.noBlur:GiveTask(blur:GetPropertyChangedSignal('Enabled'):Connect(function()
            if not blur.Enabled then return; end;
            blur.Enabled = false;
        end));

        blur.Enabled = false;
    end;
    for _, dof in pairs(depthOfFields) do
        if (not toggle) then
            bigSlave.noBlur:RemoveAllTasks();
            dof.Enabled = true;
            return;
        end;

        bigSlave.noBlur:GiveTask(dof:GetPropertyChangedSignal('Enabled'):Connect(function()
            if not dof.Enabled then return; end;
            dof.Enabled = false;
        end));

        dof.Enabled = false;
    end;
end;

local oldAmbient, oldBritghtness = Lighting.Ambient, Lighting.Brightness;

function basicsHelpers.fullBright(toggle)
    if (not toggle) then
        bigSlave.fullBright:RemoveAllTasks();
        Lighting.Ambient, Lighting.Brightness = oldAmbient, oldBritghtness;
        return
    end;

    oldAmbient, oldBritghtness = Lighting.Ambient, Lighting.Brightness;

    bigSlave.fullBright:GiveTask(Lighting:GetPropertyChangedSignal('Ambient'):Connect(function()
        Lighting.Ambient = Color3.fromRGB(255, 255, 255);
    end));
    bigSlave.fullBright:GiveTask(Lighting:GetPropertyChangedSignal('Brightness'):Connect(function()
        Lighting.Brightness = 1;
    end));

    Lighting.Ambient, Lighting.Brightness = Color3.fromRGB(255, 255, 255), 1;
end;

return basicsHelpers;
