local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local include = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("include")

local Schemas = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Schemas")
local PlayerSaveData = require(Schemas:WaitForChild("PlayerSaveData"))
local PlayerDynamicData = require(Schemas:WaitForChild("PlayerDynamicData"))

local Network = require(include:WaitForChild("Network"))
local ConcatTables = require(include.Parent:WaitForChild("Utilities"):WaitForChild("ConcatTables"))

local Charm = require(include:WaitForChild("charm"))
local CharmSync = require(include:WaitForChild("charm-sync"))
local Promise = require(include:WaitForChild("Promise"))

local RequestSyncEvent = Network.get("RequestSync")
local SyncEvent = Network.get("SyncData")

local PlayerController: {
    atom: Charm.Atom<typeof(PlayerSaveData) & typeof(PlayerDynamicData)>,
    syncer: CharmSync.ClientSyncer,
    GetPlayerAtom: (self) -> Charm.Atom<typeof(PlayerSaveData) & typeof(PlayerDynamicData)>
} = {}
PlayerController.__index = PlayerController

function PlayerController:onStart()
    self.atom = Charm.atom(ConcatTables(PlayerSaveData, PlayerDynamicData))
    self.syncer = CharmSync.client({
        atoms = {self.atom},
        ignoreUnhydrated = true,
    })

    SyncEvent:Connect(function(data)
        self.syncer:sync(data)
    end)

    Promise.new(function(resolve, reject, onCancel)
        local cleanup, requestsConnection

        onCancel(function()
            cleanup()
            requestsConnection:Disconnect()
        end)

        cleanup = SyncEvent:Connect(function(data)
            cleanup()
            requestsConnection:Disconnect()

            self.syncer:sync(data)
            resolve()
        end)

        requestsConnection = RunService.Heartbeat:Connect(function()
            RequestSyncEvent:Fire()
        end)
    end):await()
end

function PlayerController:GetPlayerAtom()
    return self.atom
end

return PlayerController