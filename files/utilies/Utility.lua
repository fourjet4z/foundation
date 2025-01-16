--SX_VM_CNONE();





local Services = loadstring(game:HttpGet("https://raw.githubusercontent.com/fourjet4z/foundation/refs/heads/main/files/utilies/Services.lua"))();
local Methods = loadstring(game:HttpGet("https://raw.githubusercontent.com/fourjet4z/foundation/refs/heads/main/files/utilies/Methods.lua"))();
local Signal = loadstring(game:HttpGet("https://raw.githubusercontent.com/fourjet4z/foundation/refs/heads/main/files/utilies/Signal.lua"))();



local Players, CoreGui, CollectionService = Services:Get("Players", "CoreGui", "CollectionService");
local plrLcal = Players.LocalPlayer;

local Utility = {};

local mathFloor, stringFind, stringLower, IsA, IsAncestorOf = Methods:Get("math.floor", "string.find", "string.lower", "game.IsA", "game.IsAncestorOf")

function Utility:getPlr(plr)
    if (not plr) then return; end;
    return Players:FindFirstChild(tostring(plr))
end

function Utility:isPlrTeamate() end --custom needed

function Utility:getPlrCharc() end --custom needed

function Utility:isPlrCharcHasRequiredInstances() end --custom needed

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

local holder, plrsHolders = Instance.new("Folder", CoreGui), {};
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

local function onPlrAdded(plr)
    addPlrHolder(plr);
end;

local function onPlrRemoving(plr)
    removePlrHolder(plr);
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

    local direction = (atCFrame.Position - cameraPos).unit;
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
    return self:getDescendantsIncludeClassNameOf(obj, "BasePart", true, true)
end;

function Utility:getinstanceWithGetDescendantsOf(obj, instance)
    for _, descendant in pairs(obj:GetDescendants()) do
        if (descendant == instance) then
            return descendant;
        end;
    end;
end;

function Utility:getinstanceWithGetChildrenOf(obj, instance)
    for _, child in pairs(obj:GetChildren()) do
        if (child == instance) then
            return child;
        end;
    end;
end;

function Utility:getDescendantsIncludeNameOf(obj, name, selfInstance, oneInstance)
    local valids = {};
    if (selfInstance and stringFind(stringLower(obj.Name), name)) then
        if oneInstance then return obj; end
        table.insert(valids, obj);
    end;
    for _, validDescendant in pairs(obj:GetDescendants()) do
        if (stringFind(stringLower(validDescendant.Name), name)) then
            if oneInstance then return validDescendant; end
            table.insert(valids, validDescendant);
        end;
    end;
    return not oneInstance and valids
end;

function Utility:geChildrenIncludeNameOf(obj, name, selfInstance, oneInstance)
    local valids = {};
    if (selfInstance and stringFind(stringLower(obj.Name), name)) then
        if oneInstance then return obj; end
        table.insert(valids, obj);
    end;
    for _, validChild in pairs(obj:GetChildren()) do
        if (stringFind(stringLower(validChild.Name), name)) then
            if oneInstance then return validChild; end
            table.insert(valids, validChild);
        end;
    end;
    return not oneInstance and valids
end;

function Utility:getDescendantsIncludeClassNameOf(obj, className, selfInstance, oneInstance)
    local valids = {};
    if (selfInstance and IsA(obj, className)) then
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

function Utility:getChildrenIncludeClassNameOf(obj, className, selfInstance, oneInstance)
    local valids = {};
    if (selfInstance and IsA(obj, className)) then
        if oneInstance then return obj; end
        table.insert(valids, obj);
    end;
    for _, validChild in pairs(obj:GetChildren()) do
        if (IsA(validChild, className)) then
            if oneInstance then return validChild; end
            table.insert(valids, validChild);
        end;
    end;
    return not oneInstance and valids
end;

function Utility.getSmallestSize(part)
    if (not IsA(part, "BasePart")) then return nil; end;
    local partSize = part.Size;
    return math.min(partSize.X, partSize.Y, partSize.Y);
end;

function Utility:mergeTables(defaults, overrides, ignoreKeyNotInDefaults) --only override key_value ~= nil
    local merged = {};
    for key, value in pairs(defaults) do
        if (typeof(value) == "table" and typeof(overrides[key]) == "table") then
            merged[key] = self:mergeTables(value, overrides[key], ignoreKeyNotInDefaults);
        else
            if (overrides[key] ~= nil) then
                merged[key] = overrides[key];
            else
                merged[key] = value;
            end;
        end;
    end;
    for key, value in pairs(overrides) do
        if (defaults[key] == nil) then
            if (ignoreKeyNotInDefaults) then
                print("Key ignored: " .. tostring(key))
            else
                merged[key] = value
            end;
        end;
    end;
    return merged;
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
