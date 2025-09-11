local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Schemas = ReplicatedStorage.Shared.Schemas

local MergeTables = require(ReplicatedStorage.Shared.Utilities.MergeTables)
local PlayerComponent = require(ServerScriptService.Server.Components.PlayerComponent)
local ComponentSystem = require(ReplicatedStorage.Shared.include.ComponentSystem)
local Lapis = require(ReplicatedStorage.Shared.include.Lapis)

-- Shemas for player data
local PlayerSaveData = require(Schemas.PlayerSaveData)
local PlayerDynamicData = require(Schemas.PlayerDynamicData)

local PlayersService: {
    Players: {[Player]: typeof(PlayerComponent)},
    PlayerCollection: Lapis.Collection<{}>,

    AddPlayer: (self, player: Player) -> (),
    RemovePlayer: (self, player: Player) -> (),
} = {
    Players = {},
    PlayerCollection = {}
}
PlayersService.__index = PlayersService

function PlayersService:AddPlayer(player)
    if self.Players[player] then return end

    local component = ComponentSystem:AddComponent(player, PlayerComponent)
    self.PlayerCollection
        :load(`Player_{player.UserId}`, { player.UserId })
        :andThen(function(document)
            if player.Parent == nil then
				document:close():catch(warn)
				return
			end

            -- Reconcile the player's data to new version of data
			document:write(MergeTables(PlayerSaveData, document:read()))
            
            component:LoadDataDocument(document)
            component:Init()
        end)
        :catch(function(message)
			warn(`[Main] Player {player.Name}'s data failed to load: {message}`)
			player:Kick("Data failed to load.")
		end)

    self.Players[player] = component
end

function PlayersService:RemovePlayer(player)
    if not self.Players[player] then return end

    self.Players[player]:destroy()
    self.Players[player] = nil
end

function PlayersService:onStart()
    self.PlayerCollection = Lapis.createCollection("TLAData", {
        defaultData = PlayerSaveData,
    })

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