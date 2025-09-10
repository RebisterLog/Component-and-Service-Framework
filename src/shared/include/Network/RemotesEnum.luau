local function makeEnum<T>(arr: {T}): { [T]: T }
    local enum = {}

    for i, v in arr do
        enum[v] = v
    end

    return enum
end

return makeEnum({
    "Replica", -- For replication of player data and game data

    "StartVFX", -- VFX's stuff
    "StopVFX",

    "StartSkill", -- Skills stuff
    "StopSkill",
})