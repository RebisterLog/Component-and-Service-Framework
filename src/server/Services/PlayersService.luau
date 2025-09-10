local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local PlayerComponent = require(ServerScriptService.Server.Components.PlayerComponent)

local PlayersService: {
    Players: {[Player]: typeof(PlayerComponent)},

    AddPlayer: (self, player: Player) -> (),
    RemovePlayer: (self, player: Player) -> (),
} = {
    Players = {},
}
PlayersService.__index = PlayersService

function PlayersService:AddPlayer(player)
    if self.Players[player] then return end

    local component = PlayerComponent.new(player)
    self.Players[player] = component
end

function PlayersService:RemovePlayer(player)
    if not self.Players[player] then return end

    self.Players[player]:destroy()
    self.Players[player] = nil
end

function PlayersService:onStart()
    Players.PlayerAdded:Connect(function(player)
        self:AddPlayer(player)
    end)

    Players.PlayerRemoving:Connect(function(player)
        self:RemovePlayer(player)
    end)


    for i, player in Players:GetPlayers() do
        self:AddPlayer(player)
    end
end

return PlayersService