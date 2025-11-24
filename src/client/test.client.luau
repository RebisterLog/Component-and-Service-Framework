local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

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

-- Функция для итерации без __source
local function safePairs(tbl)
    local keys = {}
    for k in pairs(tbl) do
        if k ~= "__source" then
            table.insert(keys, k)
        end
    end
    local i = 0
    return function()
        i = i + 1
        if i <= #keys then
            local k = keys[i]
            return k, tbl[k]
        end
    end
end

local LocalData = {
    Money = 0,
    Inventory = {},
    Pets = {}
}

local proxyTable = Proxy.observe(LocalData, function(path, oldValue, newValue)
    print(`[CLIENT] 🌍 Глобальный обработчик: изменение по пути '{table.concat(path, " → ")}'`)
end)

print("[CLIENT] 🚀 Клиент запущен и ожидает синхронизации...")
task.wait(1)
local sync = Sync.Client.new(proxyTable)

-- Подписки
local moneySubscription = Proxy.subscribe(proxyTable, "Money", function(oldValue, newValue)
    print(`[CLIENT] 💰 Деньги обновлены: {oldValue} → {newValue}`)
end)

local inventorySubscription = Proxy.subscribe(proxyTable, "Inventory", function(oldValue, newValue)
    -- Подсчитываем реальное количество предметов (без __source)
    local count = 0
    for _ in safePairs(newValue) do
        count += 1
    end
    print(`[CLIENT] 🎒 Инвентарь обновлен. Количество предметов: {count}`)
    
    -- Выводим только числовые индексы
    for i = 1, #newValue do
        local item = newValue[i]
        if item and item.name then
            print(`    [ITEM {i}] {item.name} (редкость: {item.rarity})`)
        end
    end
end)

local petsSubscription = Proxy.subscribe(proxyTable, "Pets", function(oldValue, newValue)
    print(`[CLIENT] 🐉 Питомцы обновлены.`, newValue)
end)