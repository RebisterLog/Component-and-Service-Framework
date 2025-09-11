local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local PlayerComponent = require(ServerScriptService.Server.Components.PlayerComponent)
local ComponentSystem = require(ReplicatedStorage.Shared.include.ComponentSystem)
local PlayerCharacterComponent = require(ServerScriptService.Server.Components.PlayerCharacter)

local CharacterGiver: {
    player: typeof(PlayerComponent)
} = {}
CharacterGiver.__index = CharacterGiver

function CharacterGiver:onStart()
    print("[CharacterGiver] Starting", self.player.instance.Name)

    self.player.instance.CharacterAdded:Connect(function(character)
        ComponentSystem:AddComponent(character, PlayerCharacterComponent)
    end)

    if not self.player.instance.Character then return end
    ComponentSystem:AddComponent(self.player.instance.Character, PlayerCharacterComponent)
end

function CharacterGiver:onDestroy()
    print("[CharacterGiver] Destroyed", self.player.instance.Name)

end

return CharacterGiver