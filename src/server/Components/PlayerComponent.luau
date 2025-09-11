local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Schemas = ReplicatedStorage.Shared.Schemas
local PlayerSaveData = require(Schemas.PlayerSaveData)
local PlayerDynamicData = require(Schemas.PlayerDynamicData)

local Network = require(ServerScriptService.Server.include.Network)
local ClassSystem = require(ReplicatedStorage.Shared.include.ClassSystem)
local componentTypes = require(ReplicatedStorage.Shared.include.ComponentSystem.types)
local ComponentSystem = require(ReplicatedStorage.Shared.include.ComponentSystem)
local Component = require(ReplicatedStorage.Shared.include.ComponentSystem.Component)
local ConcatTables = require(ReplicatedStorage.Shared.Utilities.ConcatTables)

local Lapis = require(ReplicatedStorage.Shared.include.Lapis)
local Charm = require(ReplicatedStorage.Shared.include.charm)
local CharmSync = require(ReplicatedStorage.Shared.include["charm-sync"])

local RequestSyncEvent = Network.get("RequestSync")
local SyncEvent = Network.get("SyncData")

type Props = {
    document: Lapis.Document<typeof(PlayerSaveData)>?,
    data: Charm.Atom<typeof(PlayerSaveData) & typeof(PlayerDynamicData)>,
    syncer: CharmSync.ServerSyncer?,
    atom: Charm.Atom<typeof(PlayerSaveData) & typeof(PlayerDynamicData)>,
}

local function ExcludeTableKeys(tblToClear, blacklistedKeys)
    local exitTable = {}

    for index, value in pairs(tblToClear) do
        if blacklistedKeys[index] == nil then
            exitTable[index] = tblToClear[index]
        end
    end

    return exitTable
end

local PlayerComponent = ClassSystem.Create("PlayerComponent").extends(Component) :: componentTypes.ComponentClass<Player> & Props

function PlayerComponent:onStart()
    print("[PlayerComponent] Starting", self.instance.Name)
end

function PlayerComponent:onDestroy()
    if not self.document then return warn("[PlayerComponent] No document") end
    local dataToSave = ExcludeTableKeys(self.atom(), PlayerDynamicData)
    print("[PlayerComponent] Data to save:", dataToSave)

    self.document:write(dataToSave)
    self.document:close():catch(warn)

    print("[PlayerComponent] Player left, data was saved:", self.instance.Name)
end

function PlayerComponent:Init()
    if not self.document then return warn("[PlayerComponent] No document") end
    self.data = ConcatTables(self.document:read(), table.clone(PlayerDynamicData))
    self.atom = Charm.atom(self.data)

    self.syncer = CharmSync.server({
        atoms = {self.atom},
        interval = 0,
        preserveHistory = false,
        autoSerialize = true,
    })

    self.syncer:connect(function(player, ...)
        SyncEvent:Fire({
            include = {player},
            args = {...}
        }:: Network.RequestData)
    end)

    RequestSyncEvent:Connect(function(player)
        if player ~= self.instance then return end
        self.syncer:hydrate(player)
    end)
end

function PlayerComponent:LoadDataDocument(document: Lapis.Document<typeof(PlayerSaveData)>)
    self.document = document
end

ComponentSystem:RegisterComponent(PlayerComponent, {})
return PlayerComponent