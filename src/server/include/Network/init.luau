--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Promise = require(script.Promise)
local Remote = require(script.Remote)
local RemotesEnum = require(ReplicatedStorage.Shared.include.Network.RemotesEnum)
local types = require(script.types)

local Network: NetworkData = {
    isRemotesCreated = false,
    _remotes = {},
}
Network.__index = Network

type NetworkData = {
    isRemotesCreated: boolean,
    _remotes: {[string]: Remote.Remote}
}

export type Network = setmetatable<NetworkData, typeof(Network)>
export type RequestData = types.RequestData

function Network:CreateRemotes()
    print("[Network] Creating remotes")

    for i, remoteName in RemotesEnum do
        local instance = Instance.new("RemoteEvent")
        instance.Name = remoteName

        self._remotes[remoteName] = Remote.new(instance)

        instance.Parent = ReplicatedStorage
    end

    print("[Network] Remotes created")
end

function Network.get(name: string)
    local remote = Network._remotes[name]
    if not remote then return warn("[Network] Remote not found: %s", name) end
    return remote
end

return Network