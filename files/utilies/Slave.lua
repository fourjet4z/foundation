-- SX_VM_CNONE();





local Signal = loadstring(game:HttpGet("https://raw.githubusercontent.com/fourjet4z/blseoxx/refs/heads/main/files/utilies/Signal.lua"))()



local Slave = {};
Slave.__index = Slave;
Slave.ClassName = "Slave";

function Slave.new()
    return setmetatable({
        _tasks = {};
    }, Slave);
end;

function Slave.__index(self, index)
    if (Slave[index]) then
        return Slave[index];
    else
        return self._tasks[index];
    end;
end;

function Slave:__newindex(index, newTask)
    if (Slave[index] ~= nil) then
        error(("'%s' is reserved for Slave"):format(tostring(index)), 2);
    end;

    local tasks = self._tasks;
    local oldTask = tasks[index];

    if oldTask == newTask then
        return;
    end;

	if oldTask then
        self:_cleanup(oldTask);
    end;

    tasks[index] = newTask;
end;

function Slave:_cleanup(task)
    if (type(task) == "function") then
        task();
    elseif (typeof(task) == "RBXScriptConnection") then
        task:Disconnect();
	elseif (Signal.isSignal(task)) then
		task:Destroy();
	elseif (typeof(task) == "table") then
		task:Remove();
    elseif (typeof(task) == "thread") then
        task.cancel(task);
    elseif (task.Destroy) then
        task:Destroy();
    end;
end;

function Slave.isSlave(value)
    return typeof(value) == "table" and getmetatable(value) == Slave;
end;

function Slave:GiveTask(task)
    if (not task) then
        error("Task cannot be false or nil", 2);
    end;

    local taskId = #self._tasks + 1;
    self[taskId] = task;
    return taskId;
end;

function Slave:RemoveTask(index)
    local task = self._tasks[index];
    if (task) then
        self._tasks[index] = nil;
        self:_cleanup(task);
    end;
end;

function Slave:DoCleaning()
    local tasks = self._tasks;

    for index, task in pairs(tasks) do
        if typeof(task) == "RBXScriptConnection" then
            task:Disconnect();
            tasks[index] = nil;
        end;
    end;

    for index, task in pairs(tasks) do
        tasks[index] = nil;
        self:_cleanup(task);
    end;
end;

function Slave:Destroy()
	if (self._tasks) then
		self:DoCleaning();
		self._tasks = nil;
	end;
    setmetatable(self, nil);
end;

return Slave;
