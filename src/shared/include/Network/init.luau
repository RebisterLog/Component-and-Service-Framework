--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Promise = require(script.Promise)
local Remote = require(script.Remote)
local RemotesEnum = require(script.RemotesEnum)

local Network: NetworkData = {
    isRemotesReplicated = false,
    _remotes = {},
}
Network.__index = Network

type NetworkData = {
    isRemotesReplicated: boolean,
    _remotes: {[string]: Remote.Remote}
}

export type Network = setmetatable<NetworkData, typeof(Network)>

local function isAllRemotesReplicated() -- Checks if all remotes replicated
    for i, remoteName in RemotesEnum do
        if not ReplicatedStorage:WaitForChild(remoteName) then
            return false
        end
    end

    return true
end

function Network:_loadRemotes() -- Precreating remotes objects
    if not self.isRemotesReplicated then return warn("[Network] Remotes not replicated") end
    for i, remoteName in RemotesEnum do
        self._remotes[remoteName] = Remote.new(ReplicatedStorage:WaitForChild(remoteName))
    end
end

function Network:SyncRemotes() -- Yields thread until all remotes not replicated
    print("[Network] Syncing remotes")

    return Promise.new(function(resolve, reject, onCancel)
        local checkConnection: RBXScriptConnection
        checkConnection = ReplicatedStorage.ChildAdded:Connect(function(child)
            self.isRemotesReplicated = isAllRemotesReplicated()
            if self.isRemotesReplicated then
                self.isRemotesReplicated = true
                checkConnection:Disconnect()
                self:_loadRemotes()
                print("[Network] Remotes were suscessfully synced")
                resolve()
            end
        end)

        onCancel(function()
            checkConnection:Disconnect()
        end)

        if self.isRemotesReplicated or isAllRemotesReplicated() then
            self.isRemotesReplicated = true
            checkConnection:Disconnect()
            self:_loadRemotes()
            print("[Network] Remotes were suscessfully synced")
            resolve()
            return
        end
    end)
end

function Network.get(name)
    local remote = Network._remotes[name]
    if not remote then return warn("[Network] Remote not found: %s", name) end
    return remote
end

return Network