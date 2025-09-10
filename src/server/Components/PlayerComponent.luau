local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ClassSystem = require(ReplicatedStorage.Shared.include.ClassSystem)
local ComponentSystem = require(ReplicatedStorage.Shared.include.ComponentSystem)
local Component = require(ReplicatedStorage.Shared.include.ComponentSystem.Component)

local PlayerComponent = ClassSystem.Create("PlayerComponent").extends(Component)

function PlayerComponent:onStart()
    print("[PlayerComponent] Starting", self.instance.Name)
end

function PlayerComponent:onDestroy()
    print("[PlayerComponent] Destroying", self.instance.Name)
end

ComponentSystem:RegisterComponent(PlayerComponent, {})
return PlayerComponent