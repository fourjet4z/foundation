--SX_VM_CNONE();





local Utility = loadstring(game:HttpGet("https://raw.githubusercontent.com/fourjet4z/foundation/refs/heads/main/files/utilies/Utility.lua"))();
local Services = loadstring(game:HttpGet("https://raw.githubusercontent.com/fourjet4z/foundation/refs/heads/main/files/utilies/Services.lua"))();
local Methods = loadstring(game:HttpGet("https://raw.githubusercontent.com/fourjet4z/foundation/refs/heads/main/files/utilies/Methods.lua"))();
local Slave = loadstring(game:HttpGet("https://raw.githubusercontent.com/fourjet4z/foundation/refs/heads/main/files/utilies/Slave.lua"))();



local Players, UserInputService, RunService, Lighting, HttpService, TeleportService = Services:Get(
    "Players",
    "UserInputService",
    "RunService",
    "Lighting",
    "HttpService",
    "TeleportService"
);

PlaceId, JobId = game.PlaceId, game.JobId

local plrLcal = Players.LocalPlayer

local basics = {};

local IsA, IsAncestorOf = Methods:Get("game.IsA", "game.IsAncestorOf");

local bigSlave = Slave.SichNew();

local modelData = {};
function basics.setClip(model, canCollide, canTouch, redoOlds) --if input properties are nil then keep default properties
    if (not model or not IsAncestorOf(game, model)) then return; end;

    basics.redoClip(model, redoOlds);

    local slave = Slave.SichNew();
    modelData[model] = {
        slave = slave,
        changedParts = {}
    };

    local baseParts = {};
    local function onPartAdded(part)
        if (IsA(part, "BasePart")) then
            if (not modelData[model] or baseParts[part]) then return; end;
            baseParts[part] = true;
        end;
    end

    local function onPartRemoving(part)
        if (IsA(part, "BasePart")) then
            if (not modelData[model]) then return; end;
            baseParts[part] = nil;
            modelData[model].changedParts[part] = nil;
        end;
    end;

    slave:GiveTask(Utility.listenToDescendantAdded(model, onPartAdded, {listenToDestroying = true}))
    slave:GiveTask(Utility.listenToDescendantRemoving(model, onPartRemoving))

    local function setModelProperties()
        for part, _ in pairs(baseParts) do
            if (model and not IsAncestorOf(model, part)) then
                modelData[model].changedParts[part] = nil;
                baseParts[part] = nil;
                continue;
            end;

            local changes = {};
            if (canCollide ~= nil and part.CanCollide ~= canCollide) then
                changes.CanCollide = part.CanCollide;
                part.CanCollide = canCollide;
            end;

            if (canTouch ~= nil and part.CanTouch ~= canTouch) then
                changes.CanTouch = part.CanTouch;
                part.CanTouch = canTouch;
            end;

            if (next(changes)) then
                modelData[model].changedParts[part] = changes;
            end;
        end;
    end;

    slave:GiveTask(RunService.Heartbeat:Connect(setModelProperties));

    slave:GiveTask(model.AncestryChanged:Connect(function()
        if (IsAncestorOf(game, model)) then return; end;
        basics.redoClip(model, redoOlds);
    end));
end;

function basics.redoClip(model, redoOlds) --redo setClip
    local data = modelData[model];
    if (not data) then return; end;

    if redoOlds then
        for part, changes in pairs(data.changedParts or {}) do
            if (part.Parent) then
                for property, value in pairs(changes or {}) do
                    part[property] = value;
                end;
            end;
        end;
    end;

    data.slave:SichDestroy();
    modelData[model] = nil;
end;

local bdVelcs = {};
function basics.noPhysics(part, options)
    if (not part or not IsAncestorOf(game, part)
    or not IsA(part, "BasePart")) then return; end;

    if (options) then
        if (options.offset) then
            part.CFrame = CFrame.new(part.CFrame.Position) * options.offset.Rotation;
        end;
    end;

    if not bdVelcs[part] then
        local slave = Slave.SichNew();
        bdVelcs[part] = {
            slave = slave,
            bdVelc = nil
        };

        local function setNoPhysics()
            if (not part) then return; end;
            local oldBdVelc, newBdVelc, bdVelc = bdVelcs[part].bdVelc, nil, nil
            if (not oldBdVelc or not IsAncestorOf(part, oldBdVelc)) then
                if (oldBdVelc) then
                    oldBdVelc:Destroy();
                end
                newBdVelc = Instance.new("BodyVelocity")
            end
            bdVelc = newBdVelc or oldBdVelc
            -- if (newBdVelc) then bdVelc.Name = "NoPhysics"; end;
            bdVelc.MaxForce = Vector3.one * math.huge;
            bdVelc.Velocity = Vector3.zero;
            bdVelc.Parent = part;

            if newBdVelc then
                bdVelcs[part].bdVelc = bdVelc
            end
        end

        slave:GiveTask(RunService.Stepped:Connect(setNoPhysics));

        slave:GiveTask(part.AncestryChanged:Connect(function()
            if (IsAncestorOf(game, part)) then return; end;
            basics.destroyNoPhysics(part);
        end));
    end;
end;

function basics.destroyNoPhysics(part)
    local bdVelcData = bdVelcs[part];
    if (not bdVelcData) then return; end;

    bdVelcData.slave:SichDestroy();
    if bdVelcData.bdVelc then
        bdVelcData.bdVelc:Destroy();
    end;
    bdVelcs[part] = nil;
end;

function basics.destroyPhysics(part)
    local localBdVelcs = Utility:getInstancesClassNameOf(part, "BodyVelocity", false) or {};
    for _, bdVelc in pairs(localBdVelcs) do
        bdVelc:Destroy();
    end;
end;

local lastFogsDensity = {};
function basics.noFog(toggle)
    local atmospheres = Utility:getInstancesClassNameOf(Lighting, "Atmosphere", false) or {};
    for _, atmosphere in pairs(atmospheres) do
        if (not toggle) then
            bigSlave.noFog:RemoveAllTasks();
            if (lastFogsDensity[atmosphere]) then
                atmosphere.Density = lastFogsDensity[atmosphere];
            end;
            return;
        end;

        bigSlave.noFog:GiveTask(atmosphere:GetPropertyChangedSignal("Density"):Connect(function()
            atmosphere.Density = 0;
        end));

        lastFogsDensity[atmosphere] = atmosphere.Density or 0;
        atmosphere.Density = 0;
    end;
end;

function basics.noBlur(toggle)
    local blurs = Utility:getInstancesClassNameOf(Lighting, "BlurEffect", false) or {};
    local depthOfFields = Utility:getInstancesClassNameOf(Lighting, "DepthOfFieldEffect", false) or {};
    for _, blur in pairs(blurs) do
        if (not toggle) then
            bigSlave.noBlur:RemoveAllTasks();
            blur.Enabled = true;
            return;
        end;

        bigSlave.noBlur:GiveTask(blur:GetPropertyChangedSignal("Enabled"):Connect(function()
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

        bigSlave.noBlur:GiveTask(dof:GetPropertyChangedSignal("Enabled"):Connect(function()
            if not dof.Enabled then return; end;
            dof.Enabled = false;
        end));

        dof.Enabled = false;
    end;
end;

local oldAmbient, oldBritghtness = Lighting.Ambient, Lighting.Brightness;

function basics.fullBright(toggle)
    if (not toggle) then
        bigSlave.fullBright:RemoveAllTasks();
        Lighting.Ambient, Lighting.Brightness = oldAmbient, oldBritghtness;
        return
    end;

    oldAmbient, oldBritghtness = Lighting.Ambient, Lighting.Brightness;

    bigSlave.fullBright:GiveTask(Lighting:GetPropertyChangedSignal("Ambient"):Connect(function()
        Lighting.Ambient = Color3.fromRGB(255, 255, 255);
    end));
    bigSlave.fullBright:GiveTask(Lighting:GetPropertyChangedSignal("Brightness"):Connect(function()
        Lighting.Brightness = 1;
    end));

    Lighting.Ambient, Lighting.Brightness = Color3.fromRGB(255, 255, 255), 1;
end;

local Api = "https://games.roblox.com/v1/games/"

local function fetchServersData(limit, cursor, sort, placeId)
	local format = string.format("%s%d/servers/Public?sortOrder=%s&limit=%d&excludeFullGames=true", Api, placeId, sort, limit)
	local url = string.format("%s%s", format, (cursor and string.format("&cursor=%s", cursor)) or "")

	local success, response = pcall(function()
		return HttpService:JSONDecode(game:HttpGet(url))
	end)

	if success and response and response.data then
		return response.data, response.nextPageCursor
	end

	return nil, nil
end

local function serversGet(serverLimit, getTimes, sort, onlyGetJobId, delay)
	getTimes = getTimes or 1
	serverLimit = (serverLimit <= 100 and serverLimit) or 100

	local serversTable = {}
	local nextPage
	repeat
		local servers
		repeat
			print("looping,in")
			servers, nextPage = fetchServersData(serverLimit, nextPage, sort, PlaceId)
			if not servers then task.wait(math.random(175, 300)/100) end
			if delay then task.wait(delay) end
		until servers

		for _, server in ipairs(servers) do
			if type(server) == "table" and server.playing > 0 and server.maxPlayers > server.playing and server.id ~= JobId then
				local insertPos = tostring(sort) == "Asc" and 1 or #serversTable + 1
				table.insert(serversTable, insertPos, (onlyGetJobId and server.id) or server)
			end
		end

		getTimes = getTimes - 1
	until not nextPage or getTimes <= 0

	print("servers counted:", #serversTable)
	return serversTable
end

--sortByLowPlayers: true - lowplayer, :false - random
function basics:sHop(sAmmount, sAmmountMultipliedTime, sortByLowPlayers, onlyGetJobId, sGetDelay, sHopDelay) --sAmmount = sLimit <= 100 (had to be <= 100)
	if sHopDelay then task.wait(sHopDelay) end
	local sort = sortByLowPlayers and "Asc" or "Desc"
	local serversTable = serversGet(sAmmount, sAmmountMultipliedTime, sort, onlyGetJobId, sGetDelay)
	while true do
        if #serversTable > 0 then
			local serverIndex = (sortByLowPlayers and 1) or math.random(1, #serversTable)
			local serverId = (onlyGetJobId and serversTable[serverIndex]) or serversTable[serverIndex].id

            print("Serverhopping")   -- using pcall(function()/print might get instanly banned/detected
            local success,_ = pcall(function()
                TeleportService:TeleportToPlaceInstance(PlaceId, serverId, plrLcal)    -- using pcall(function()/print might get instanly banned/detected
            end)

            if success then
                local newJobId = game.JobId
                if newJobId ~= JobId then
                    print("Serverhopped")
                    return
                end
            end

            table.remove(serversTable, serverIndex)
            task.wait(0.3)
        else
            print("Serverhop", "Couldn't find a server.")
			return
        end
    end
end
--use: sHop(100, 1, false, true, 0, 0)

return basics;
