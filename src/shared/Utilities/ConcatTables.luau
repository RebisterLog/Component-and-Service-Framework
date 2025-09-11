return function<T>(...: {T}): {T}
    local newTable = {}

    for i, tbl in {...} do
        if not (typeof(tbl) == "table") then continue end

        for i, v in tbl do
            newTable[i] = v
        end
    end

    return newTable
end