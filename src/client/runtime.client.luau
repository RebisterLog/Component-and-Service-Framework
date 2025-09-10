local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local includes = Shared:WaitForChild("include")
local Network = require(includes:WaitForChild("Network"))
local ServicesSystem = require(includes:WaitForChild("ServicesSystem"))

print("[Client] Starting client")

local waitSync = Network:SyncRemotes()
waitSync:await()

ServicesSystem:Init()
