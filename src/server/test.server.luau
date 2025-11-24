local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Загрузка модулей
local Proxy = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("include"):WaitForChild("Proxy"))
local Sync = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("include"):WaitForChild("Sync"))

-- Функция для подсчета элементов в ассоциативной таблице
local function tableSize(tbl)
    local count = 0
    for _ in pairs(tbl) do
        count += 1
    end
    return count
end

-- Минимальные данные игрока
local PlayerData = {
    Money = 1000,
    Inventory = {},
    Pets = {}
}

-- Обработка подключения игрока
Players.PlayerAdded:Connect(function(player)
    local proxyTable = Proxy.observe(PlayerData, function(path, oldValue, newValue)
        print(`[SERVER] 🌍 Глобальный обработчик: изменение по пути '{table.concat(path, " → ")}'`)
        print(`    Старое значение: {tostring(oldValue)}`)
        print(`    Новое значение: {tostring(newValue)}`)
    end)
    
    local sync = Sync.Server.new(proxyTable, player)
    
    -- Циклические изменения каждые 10 секунд
    task.spawn(function()
        local counter = 1
        while player.Parent do
            task.wait(10)
            print(`\n[SERVER] ⏰ Циклическое обновление #{counter}...`)
            
            print("[SERVER] 📦 Начало пакетной операции")
            Proxy.batch(proxyTable, function()

                local newItem = {
                    id = "item_" .. os.time() .. "_" .. counter,
                    name = "Item #" .. counter,
                    rarity = math.random(1, 5)
                }
                Proxy.insert(proxyTable.Inventory, 1, newItem)

                local petId = "pet_" .. counter
                proxyTable.Pets[petId] = {
                    id = petId,
                    name = "Pet #" .. counter,
                    level = counter,
                    type = math.random() > 0.5 and "dragon" or "wolf"
                }
                print(`[SERVER] 🐉 Питомец добавлен: {petId} - {proxyTable.Pets[petId].name}`)
            end)
            print("[SERVER] ✅ Пакетная операция завершена")
            print("[SERVER] 📊 Текущее состояние данных:", proxyTable)
            counter += 1
        end
        
        sync:destroy()
    end)
end)