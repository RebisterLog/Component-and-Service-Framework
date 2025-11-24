--!native

local MergeTables = require(script.MergeTables)

local listeners: {() -> ()} = {}

local function deepCopy(t)
    local copy = {}
    for k, v in pairs(t) do
        if type(v) == "table" then
            copy[k] = deepCopy(v)
        else
            copy[k] = v
        end
    end
    return copy
end

local Proxy = {}

function Proxy.new(t: {})
    assert(type(t) == "table", "Cannot observe non-table")

    local proxy = {}
    proxy.__type = "ProxyTable"
    proxy.__source = t

    local mt = {
        __call = function(self, newData)
            if newData then
                assert(type(newData) == "table", "Cannot mutate by non-table")
                proxy.__source = newData

                for i, listener in listeners do
                    listener()
                end
            end

            return table.freeze(proxy.__source)
        end
    }

    table.freeze(proxy)

    return setmetatable(proxy, mt)
end

function Proxy.mutate<T>(proxy: T, callback: (T) -> ())
    local draft = deepCopy(proxy())

    callback(draft)

    local updated, changes = MergeTables(proxy(), draft)
    proxy(updated)
end

type Selector<T> = (T) -> any
function Proxy.subscribe<C>(selector: Selector<C>, callback: (newValue: any, oldValue: any) -> ())
    assert(type(callback) == "function", "Callback must be a function")
    assert(type(selector) == "function" or type(selector) == "table", "Selector must be a function or table")

    local oldValue = selector()
    local listener = function()
        local newValue = selector()
        if newValue ~= oldValue then
            oldValue = newValue
            callback(newValue, oldValue)
        end
    end

    table.insert(listeners, listener)

    return function()
        table.remove(listeners, table.find(listeners, listener))
    end
end

function Proxy.notify()
    for i, listener in listeners do
        listener()
    end
end

function Proxy.isProxy(t)
    local mt = getmetatable(t)
    return mt and mt.__type == "ProxyTable"
end

return Proxy