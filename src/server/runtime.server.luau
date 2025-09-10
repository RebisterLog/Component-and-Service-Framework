local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Network = require(ServerScriptService.Server.include.Network)
local ServiceSystem = require(ReplicatedStorage.Shared.include.ServicesSystem)

print("[Server] Starting server")
Network:CreateRemotes()
ServiceSystem:Init()