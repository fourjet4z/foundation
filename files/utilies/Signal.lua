-- SX_VM_CNONE()





local Signal = {}
Signal.__index = Signal
Signal.ClassName = "Signal"

function Signal.new()
    return setmetatable({
        _event = Instance.new("BindableEvent"),
        _argData = nil
    }, Signal)
end

function Signal.isSignal(object)
    return typeof(object) == "table" and getmetatable(object) == Signal
end

function Signal:Fire(...)
    if not self._event then return end
    self._argData = table.pack(...)
    self._event:Fire()
    task.defer(function()
        self._argData = nil
    end)
end

function Signal:Connect(handler)
    if not self._event then return end
    if type(handler) ~= "function" then
        error(("connect(%s)"):format(typeof(handler)), 2)
    end
    return self._event.Event:Connect(function()
        if self._argData then
            handler(table.unpack(self._argData, 1, self._argData.n))
        end
    end)
end

function Signal:Wait()
    if not self._event then return end
    self._event.Event:Wait()
    return table.unpack(self._argData, 1, self._argData.n)
end

---
function Signal:DisconnectAll()
    if not self._event then return end
    for _, conn in pairs(self._event.Event:GetConnections()) do
        conn:Disconnect()
    end
end

function Signal:Destroy()
    if self._event then
        self._event:Destroy()
        self._event = nil
    end
    self._argData = nil
    setmetatable(self, nil)
end

return Signal
