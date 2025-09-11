export type RequestData = {
    args: {any}, -- Arguments to send

    include: {Player}, -- Arrays of exluded/included players
    exclude: {Player},

    position: Vector3, -- Center of the sphere for the request
    radius: number, -- Radius of the sphere
}

return {}