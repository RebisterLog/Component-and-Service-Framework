local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Schemas = ReplicatedStorage.Shared.Schemas
local PlayerSaveData = require(Schemas.PlayerSaveData)

local ClassSystem = require(ReplicatedStorage.Shared.include.ClassSystem)
local ComponentSystem = require(ReplicatedStorage.Shared.include.ComponentSystem)
local Component = require(ReplicatedStorage.Shared.include.ComponentSystem.Component)
local Lapis = require(ReplicatedStorage.Shared.include.Lapis)

local PlayerComponent = ClassSystem.Create("PlayerComponent").extends(Component)

function PlayerComponent:onStart()
    print("[PlayerComponent] Starting", self.instance.Name)
end

function PlayerComponent:onDestroy()
    print("[PlayerComponent] Destroying", self.instance.Name)
end

function PlayerComponent:LoadDataDocument(document: Lapis.Document<typeof(PlayerSaveData)>)
    
end

ComponentSystem:RegisterComponent(PlayerComponent, {})
return PlayerComponent