local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require(ReplicatedStorage.Shared.include.Signal)
local ClassSystem = require(ReplicatedStorage.Shared.include.ClassSystem)

local CharacterComponent = ClassSystem.CreateAbstract("Character")

function CharacterComponent:constructor(instance: Instance)
    self.instance = instance
    self.Destroyed = Signal.new()

    if self.onStart then
        self:onStart()
    end
end

function CharacterComponent:destroy()
    if self.onDestroy then
        self:onDestroy()
    end
    
    self.Destroyed:Fire()
end

return CharacterComponent