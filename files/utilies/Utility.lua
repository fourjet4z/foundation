--SX_VM_CNONE();





local Services = loadstring(game:HttpGet("https://raw.githubusercontent.com/fourjet4z/foundation/refs/heads/main/files/utilies/Services.lua"))();
local Methods = loadstring(game:HttpGet("https://raw.githubusercontent.com/fourjet4z/foundation/refs/heads/main/files/utilies/Methods.lua"))();
local Signal = loadstring(game:HttpGet("https://raw.githubusercontent.com/fourjet4z/foundation/refs/heads/main/files/utilies/Signal.lua"))();



local Players, CoreGui, CollectionService = Services:Get("Players", "CoreGui", "CollectionService");
local plrLcal = Players.LocalPlayer;

local Utility = {};

Utility.onPlrAdded = Signal.SichNew();
Utility.onPlrCharcAdded = Signal.SichNew();
Utility.onPlrLcalCharcAdded = Signal.SichNew();

local mathFloor, stringLower, IsA, IsAncestorOf = Methods:Get("math.floor", "string.lower", "game.IsA", "game.IsAncestorOf")

local plrsData = {};
local holder, plrsHolders = Instance.new("Folder", CoreGui), {};

function Utility:getPlrCharc(plr)
    local plrData = self:getPlrData(plr);
    if (not plrData.alive) then return; end;

    local maxHealth, health = plrData.maxHealth, plrData.health;
    return plrData.charc, maxHealth, (health / maxHealth) * 100, mathFloor(health), plrData.rootPart;
end;

function Utility:isTeamMate(plr)
    local plrData, plrLcalData = self:getPlrData(plr), self:getPlrData(plrLcal);
    local plrTeam, plrLcalTeam = plrData.team, plrLcalData.team;

    if (plrTeam == nil or plrLcalTeam == nil) then
        return false;
    end;

    return plrTeam == plrLcalTeam;
end;

function Utility:getPlrRootPart(plr)
    local plrData = self:getPlrData(plr);
    return plrData and plrData.rootPart;
end;

local function onPlrCharcAdded(plr)
    local plrData = plrsData[plr];
    if (not plrData) then return; end;

    local charc = plr.Character;
    if (not charc) then return; end;

    local localAlive = true;

    plrData.parts = {};

    Utility.listenToChildAdded(charc, function(obj)
	local objLoweredName = stringLower(obj.Name)
        if (IsA(obj, "Humanoid")) then
            plrData.hum = obj;
        elseif (objLoweredName == "humanoidrootpart") then
            plrData.rootPart = obj;
        elseif (objLoweredName == "head") then
            plrData.head = obj;
        end;
    end);

    if (plr == plrLcal) then
        Utility.listenToDescendantAdded(charc, function(obj)
            if (IsA(obj, "BasePart")) then
                table.insert(plrData.parts, obj);

                local conn;
                conn = obj.AncestryChanged:Connect(function()
                    if (IsAncestorOf(charc, obj)) then return; end;
                    conn:Disconnect();
                    table.remove(plrData.parts, table.find(plrData.parts, obj));
                end);
            end;
        end);
    end;

    local function onPrimaryPartChanged()
        plrData.primaryPart = charc.PrimaryPart;
        plrData.alive = plrData.primaryPart ~= nil;
    end

    local hum = charc:WaitForChild("Humanoid", 30);
    if (not hum) then
        warn("[Utility] [onPlrCharcAdded] player is missing humanoid: "..plr:GetFullName());
        return;
    end;
    if (not IsAncestorOf(game, plr) or not IsAncestorOf(game, charc)) then return; end;

    charc:GetPropertyChangedSignal("PrimaryPart"):Connect(onPrimaryPartChanged);
    if (charc.PrimaryPart) then
        onPrimaryPartChanged();
    end;

    plrData.charc = charc;
    plrData.hum = hum;
    plrData.alive = true;
    plrData.health = plrData.hum.Health;
    plrData.maxHealth = plrData.hum.MaxHealth;

    hum.Destroying:Connect(function()
        plrData.alive = false;
        localAlive = false;
    end);

    hum.Died:Connect(function()
        plrData.alive = false;
        localAlive = false;
    end);

    hum:GetPropertyChangedSignal("Health"):Connect(function()
        plrData.health = hum.Health;
    end);

    hum:GetPropertyChangedSignal("MaxHealth"):Connect(function()
        plrData.maxHealth = hum.MaxHealth;
    end);

    local function fire()
        if (not localAlive) then return; end;
        Utility.onPlrCharcAdded:Fire(plrData);

        if (plr == plrLcal) then
            Utility.onPlrLcalCharcAdded:Fire(plrData);
        end;
    end;

    --if (library.OnLoad) then
        --library.OnLoad:Connect(fire);
    --else
        fire();
    --end;
end;

function Utility:getPlrData(plr)
    return plrsData[plr] or {};
end;

function Utility.listenToChildAdded(folder, listener, options)
    assert(typeof(folder) == "Instance", "listenToChildAdded: Argument #1 (folder) must be an Instance");
    assert(
        typeof(listener) == "function" or (typeof(listener) == "table" and typeof(listener.new) == "function"),
        "listenToChildAdded: Argument #2 (listener) must be a function or a table with a 'new' method"
    );

    options = options or {listenToDestroying = false};

    local createListener = typeof(listener) == "table" and listener.new or listener;

    local function onChildAdded(child)
        local listenerObject = createListener(child);

        if (options.listenToDestroying and listenerObject) then
            child.Destroying:Connect(function()
                local removeListener = typeof(listener) == "table" and (listener.Destroy or listener.Remove) or listenerObject;

                if (typeof(removeListener) == "function") then
                    removeListener(child);
                else
                    warn("[Utility] Potential memory leak: removeListener is not defined for", folder);
                end;
            end);
        end;
    end;

    --debug.profilebegin(string.format("Utility.listenToChildAdded(%s)", folder:GetFullName()));

    for _, child in pairs(folder:GetChildren()) do
        task.spawn(onChildAdded, child);
    end;

    --debug.profileend();

    return folder.ChildAdded:Connect(createListener);
end;

function Utility.listenToChildRemoving(folder, listener)
    assert(typeof(folder) == "Instance", "listenToChildRemoving: Argument #1 (folder) must be an Instance");
    assert(
        typeof(listener) == "function" or (typeof(listener) == "table" and typeof(listener.new) == "function"),
        "listenToChildRemoving: Argument #2 (listener) must be a function or a table with a 'new' method"
    );

    local createListener = typeof(listener) == "table" and listener.new or listener;

    return folder.ChildRemoved:Connect(createListener);
end;

function Utility.listenToDescendantAdded(folder, listener, options)
    assert(typeof(folder) == "Instance", "listenToDescendantAdded: Argument #1 (folder) must be an Instance");
    assert(
        typeof(listener) == "function" or (typeof(listener) == "table" and typeof(listener.new) == "function"),
        "listenToDescendantAdded: Argument #2 (listener) must be a function or a table with a 'new' method"
    );

    options = options or {listenToDestroying = false};

    local createListener = typeof(listener) == "table" and listener.new or listener;

    local function onDescendantAdded(child)
        local listenerObject = createListener(child);

        if (options.listenToDestroying and listenerObject) then
            child.Destroying:Connect(function()
                local removeListener = typeof(listener) == "table" and (listener.Destroy or listener.Remove) or listenerObject;

                if (typeof(removeListener) == "function") then
                    removeListener(child);
                else
                    warn("[Utility] removeListener is not definded possible memory leak for", folder);
                end;
            end);
        end;
    end

    --debug.profilebegin(string.format("Utility.listenToDescendantAdded(%s)", folder:GetFullName()));

    for _, child in next, folder:GetDescendants() do
        task.spawn(onDescendantAdded, child);
    end;

    --debug.profileend();

    return folder.DescendantAdded:Connect(onDescendantAdded);
end;

function Utility.listenToDescendantRemoving(folder, listener)
    assert(typeof(folder) == "Instance", "listenToDescendantRemoving: Argument #1 (folder) must be an Instance");
    assert(
        typeof(listener) == "function" or (typeof(listener) == "table" and typeof(listener.new) == "function"),
        "listenToDescendantRemoving: Argument #2 (listener) must be a function or a table with a 'new' method"
    );

    local createListener = typeof(listener) == "table" and listener.new or listener;

    return folder.DescendantRemoving:Connect(createListener);
end;

function Utility.listenToTagAdded(tagName, listener)
    for _, v in next, CollectionService:GetTagged(tagName) do
        task.spawn(listener, v);
    end;

    return CollectionService:GetInstanceAddedSignal(tagName):Connect(listener);
end;

local function addPlrHolder(plr)
    local plrHolder = Instance.new("Folder", holder);
    plrHolder.Name = plr.Name; -- Utility.randomString()

    plrsHolders[plr] = plrHolder;
end;

local function removePlrHolder(plr)
    local plrHolder = plrsHolders[plr];
    if not plrHolder then return; end;

    plrHolder:Destroy();
    plrsHolders[plr] = nil;
end;

local function addPlrData(plr)
    local plrData = {};

    plrData.plr = plr;
    plrData.team = plr.Team;
    plrData.parts = {};

    plrsData[plr] = plrData;

    local function fire()
        Utility.onPlrAdded:Fire(plr);
    end;

    task.spawn(onPlrCharcAdded, plr);

    plr.CharacterAdded:Connect(function()
        onPlrCharcAdded(plr);
    end);

    plr:GetPropertyChangedSignal("Team"):Connect(function()
        plrData.team = plr.Team;
    end);

    --if (library.OnLoad) then
        --library.OnLoad:Connect(fire);
    --else
        fire();
    --end;
end;

local function removePlrData(plr)
    plrsData[plr] = nil;
end;

local function onPlrAdded(plr)
    addPlrHolder(plr);
    addPlrData(plr);
end;

local function onPlrRemoving(plr)
    removePlrHolder(plr);
    removePlrData(plr);
end;

for _, plr in next, Players:GetPlayers() do
    task.spawn(onPlrAdded, plr);
end;

Players.PlayerAdded:Connect(onPlrAdded);
Players.PlayerRemoving:Connect(onPlrRemoving);

function Utility:renderOverload(data) end;

function Utility:countTable(t)
    local found = 0;

    for i, v in next, t do
        found = found + 1;
    end;

    return found;
end;

function Utility.isBetweenAt(pos1, po2, factorDis)
    local betweenDis = (pos1 - po2).Magnitude
    return factorDis and factorDis >= betweenDis, betweenDis
end

function Utility.lookAt(atCFrame)
    local camera = workspace.CurrentCamera;
    local cameraPos = camera.CFrame.Position;

    atCFrame = typeof(atCFrame) == "Vector3" and CFrame.new(atCFrame) or CFrame.new(atCFrame.Position);

    local direction = (atCFrame - cameraPos).unit;
    local newCF = CFrame.new(cameraPos, cameraPos + direction);
    camera.CFrame = newCF;
end;

function Utility:roundVector(vector) --ignore Y value, set to 0
    return Vector3.new(vector.X, 0, vector.Z);
end;

function Utility.randomString()
	local length = math.random(10,20);
	local array = {};
	for i = 1, length do
		array[i] = string.char(math.random(33, 126));
	end;
	return table.concat(array);
end;

function Utility:getBasePart(obj)
    return self:getInstancesClassNameOf(obj, "BasePart", true)
end;

function Utility:getInstancesClassNameOf(obj, className, oneInstance)
    local valids = {};
    if (IsA(obj, className)) then
        if oneInstance then return obj; end
        table.insert(valids, obj);
    end;
    for _, validDescendant in pairs(obj:GetDescendants()) do
        if (IsA(validDescendant, className)) then
            if oneInstance then return validDescendant; end
            table.insert(valids, validDescendant);
        end;
    end;
    return not oneInstance and valids
end;

function Utility.find(t, c)
    for i, v in next, t do
        if (c(v, i)) then
            return v, i;
        end;
    end;

    return nil;
end;

function Utility.map(t, c)
    local ret = {};

    for i, v in next, t do
        local val = c(v, i);
        if (val) then
            table.insert(ret, val);
        end;
    end;

    return ret;
end;

return Utility;
