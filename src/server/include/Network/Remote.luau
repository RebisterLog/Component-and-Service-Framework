--!strict
local Players = game:GetService("Players")
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

export type RequestData = {
    args: {any}, -- Arguments to send

    include: {Player}, -- Arrays of exluded/included players
    exclude: {Player},

    position: Vector3, -- Center of the sphere for the request
    radius: number, -- Radius of the sphere
}

function Remote:Fire(data: RequestData)
    data.exclude = data.exclude or {}
    data.include = data.include or {}
    data.args = data.args or {}
    -- If it's an exclude request
    if #data.exclude > 0 then
        local players: {Player} = Players:GetPlayers()
        for i, player in players do
            if not table.find(data.exclude, player) then

                -- If it's radius request
                if data.radius and data.position then
                    local distance = (player:DistanceFromCharacter(data.position)).magnitude
                    if distance > data.radius then
                        continue
                    end
                end
                
                self._instance:FireClient(player, table.unpack(data.args))
            end
        end

    -- If it's an include request
    else
        for i, player in data.include do
            -- If it's radius request
            if data.radius and data.position then
                local distance = (player:DistanceFromCharacter(data.position)).magnitude
                if distance > data.radius then
                    continue
                end
            end

            self._instance:FireClient(player, table.unpack(data.args))
        end
    end
    
end

function Remote:FireAll(data: RequestData)
    for i, player in Players:GetPlayers() do
        -- If it's radius request
        if data.radius and data.position then
            local distance = (player:DistanceFromCharacter(data.position)).magnitude
            if distance > data.radius then
                continue
            end
        end

        self._instance:FireClient(player, table.unpack(data.args))
    end
end

function Remote.new(instance: RemoteEvent)
    local remote = {
        _instance = instance,
        _listeners = {},
    }

    instance.OnServerEvent:Connect(function(player, ...)
        for _, listener in remote._listeners do
            listener(player, ...)
        end
    end)

    return setmetatable(remote, Remote)
end

return Remote