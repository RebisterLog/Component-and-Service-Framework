--!strict
local Remote: RemoteData = {}
Remote.__index = Remote

type RemoteData = {
    _instance: RemoteEvent,
    _listeners: {(...any) -> ()}
}

export type Remote = setmetatable<RemoteData, typeof(Remote)>

function Remote:Connect(listener: (...any) -> ())
    self._listeners[listener] = listener

    -- Returning cleanup function
    return function()
        self._listeners[listener] = nil
    end
end

function Remote:Fire(...)
    self._instance:FireServer(...)
end

function Remote.new(instance: RemoteEvent)
    local remote = {
        _instance = instance,
        _listeners = {},
    }

    instance.OnClientEvent:Connect(function(...)
        for _, listener in remote._listeners do
            listener(...)
        end
    end)

    return setmetatable(remote, Remote)
end

return Remote