-- Sync.lua - Модуль синхронизации с использованием Remo
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local include = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("include")

local Remo = require(include:WaitForChild("remo")) -- Замените на реальный путь к Remo
local t = require(include:WaitForChild("t")) -- Библиотека для валидации (опционально)
local Proxy = require(include:WaitForChild("Proxy")) -- Замените на реальный путь

type Remotes = {
    syncData: Remo.ServerToClient<{path: {any}, patch: any, isFullSync: boolean?}>,
    requestSync: Remo.ClientToServer<{}>
}

local remotes: Remotes = Remo.createRemotes({
    syncData = Remo.remote(),
    requestSync = Remo.remote()
})

-- Серверная часть
local ServerSync = {}
ServerSync.__index = ServerSync

function ServerSync.new(proxyTable, player)
    local self = setmetatable({}, ServerSync)
    self.proxyTable = proxyTable
    self.player = player
    self.isSyncing = false
    self.isDestroyed = false
    
    -- Подписка на все изменения
    self.unsubscribe = Proxy.subscribe(proxyTable, {}, function(oldValue, newValue, path)
        if self.isSyncing or self.isDestroyed then return end
        
        -- Получаем значение по пути через прокси
        local value = proxyTable
        for _, key in ipairs(path) do
            if type(value) ~= "table" then break end
            value = value[key]
        end
        
        remotes.syncData:fire(self.player, {
            path = path,
            patch = Proxy.deepCopy(value),
            isFullSync = false
        })
    end)
    
    -- Обработка запросов
    self.requestConnection = remotes.requestSync:connect(function(requestPlayer)
        if requestPlayer == player and not self.isDestroyed then
            self:sendFullState()
        end
    end)
    
    return self
end

function ServerSync:sendFullState()
    if self.isDestroyed then return end
    self.isSyncing = true
    remotes.syncData:fire(self.player, {
        path = {},
        patch = Proxy.deepCopy(self.proxyTable.__source),
        isFullSync = true
    })
    self.isSyncing = false
end

function ServerSync:destroy()
    self.isDestroyed = true
    if self.unsubscribe then
        self.unsubscribe()
        self.unsubscribe = nil
    end
    if self.requestConnection then
        self.requestConnection:Disconnect()
        self.requestConnection = nil
    end
end

-- Клиентская часть
local ClientSync = {}
ClientSync.__index = ClientSync

function ClientSync.new(proxyTable)
    local self = setmetatable({}, ClientSync)
    self.proxyTable = proxyTable
    self.isInitialized = false
    self.isDestroyed = false
    
    -- Обработка данных
    self.syncConnection = remotes.syncData:connect(function(data)
        if self.isDestroyed then return end
        self:applyData(data)
    end)
    
    remotes.requestSync:fire()
    return self
end

-- Применяем изменения ЧЕРЕЗ ПРОКСИ, а не напрямую к __source
function ClientSync:applyData(data)
    if self.isDestroyed then return end

    if data.isFullSync then
        self.isInitialized = false
        Proxy.batch(self.proxyTable, function()
            -- Очищаем текущее состояние (кроме __source)
            for k in pairs(self.proxyTable) do
                if k ~= "__source" then
                    self.proxyTable[k] = nil
                end
            end
            -- Применяем данные через прокси
            for k, v in pairs(data.patch) do
                if k ~= "__source" then
                    self.proxyTable[k] = Proxy.deepCopy(v)
                end
            end
        end)
        self.isInitialized = true
        print("[CLIENT] ✅ Полная синхронизация выполнена")
    else
        if not self.isInitialized then
            print("[CLIENT] ⚠️ Пропускаем частичное обновление")
            return
        end

        -- 🔥 КЛЮЧЕВОЕ ИСПРАВЛЕНИЕ: Применяем ЧЕРЕЗ ПРОКСИ, но используем clean данные
        local path = data.path
        if #path == 0 then
            -- Обновление корня
            Proxy.batch(self.proxyTable, function()
                for k, v in pairs(data.patch) do
                    if k ~= "__source" then
                        self.proxyTable[k] = Proxy.deepCopy(v)
                    end
                end
            end)
        else
            -- Идем по пути через прокси
            local target = self.proxyTable
            for i = 1, #path - 1 do
                local key = path[i]
                if type(target) ~= "table" then
                    error("Invalid path")
                    return
                end
                if target[key] == nil then
                    target[key] = {}
                elseif type(target[key]) ~= "table" then
                    target[key] = {}
                end
                target = target[key]
            end

            -- Применяем значение к последнему ключу
            local lastKey = path[#path]
            if lastKey ~= nil then
                local cleanValue = Proxy.deepCopy(data.patch)  -- Убираем __source!
                Proxy.batch(self.proxyTable, function()
                    target[lastKey] = cleanValue
                end)
            end
        end
        print(`[CLIENT] ✅ Обновление применено по пути: {table.concat(path, " → ")}`)
    end
end

function ClientSync:destroy()
    self.isDestroyed = true
    if self.syncConnection then
        self.syncConnection:Disconnect()
        self.syncConnection = nil
    end
end

return {
    Server = ServerSync,
    Client = ClientSync,
    remotes = remotes
}