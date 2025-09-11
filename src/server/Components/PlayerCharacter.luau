local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ClassSystem = require(ReplicatedStorage.Shared.include.ClassSystem)
local Component = require(ReplicatedStorage.Shared.include.ComponentSystem.Component)
local CharacterComponent = require(ServerScriptService.Server.Components.CharacterComponent)


local PlayerCharacterComponent = ClassSystem.Create("PlayerCharacter").extends(CharacterComponent)

function PlayerCharacterComponent:onStart()
    print("[PlayerCharacter] Added character for", self.instance.Name)
end

function PlayerCharacterComponent:onDestroy()
    print("[PlayerCharacter] Character destroyed:", self.instance.Name)
end

return PlayerCharacterComponent