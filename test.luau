local function GetTableLength(t)
	local count = 0
	for _ in pairs(t) do
		count = count + 1
	end
	return count
end

local function isArray(t)
    local size = GetTableLength(t)
    return size == #t
end


local function printTable(t, indentLevel)
    indentLevel = indentLevel or 0
    local indent = string.rep("  ", indentLevel)

    if type(t) ~= "table" then
        print(indent .. tostring(t))
        return
    end

    local visited = {}
    local function _print(tbl, level)
        if visited[tbl] then
            print(string.rep("  ", level) .. "[circular reference]")
            return
        end
        visited[tbl] = true

        local currentIndent = string.rep("  ", level)
        print(currentIndent .. "{")
        for k, v in pairs(tbl) do
            local keyStr = type(k) == "string" and ("[" .. k .. "]") or ("[" .. tostring(k) .. "]")
            if type(v) == "table" then
                print(currentIndent .. "  " .. keyStr .. " =")
                _print(v, level + 1)
            else
                print(currentIndent .. "  " .. keyStr .. " = " .. tostring(v))
            end
        end
        print(currentIndent .. "}")
    end

    _print(t, indentLevel)
end

local function GetTableIndexesTree(tab, prefix)
	local tree = {}

	for index, value in pairs(tab) do
		local newPrefix = prefix and (prefix .. "." .. index) or index

		if type(value) == "table" then
			if GetTableLength(value) == 0 then
				table.insert(tree, newPrefix)
			else
				local subTree = GetTableIndexesTree(value, newPrefix)
				for _, path in pairs(subTree) do
					table.insert(tree, path)
				end
			end
		else
			table.insert(tree, newPrefix)
		end
	end

	return tree
end

local function setByPath(tab, path, value)
	local keys = string.split(path, ".")
	local current = tab

	for i = 1, #keys - 1 do
		local key = keys[i]
		if not current[key] then
			current[key] = {}
		end
		current = current[key]
	end

	current[keys[#keys]] = value
end

local function getByPath(tab, path, maxLevel: number?): (any?, number)
	local keys = string.split(path, ".")
	local current = tab

	for i, key in ipairs(keys) do
		if not current or type(current) ~= "table" then
			return nil, i
		end

        if maxLevel and i == maxLevel then
            return current[key], i
        end

		current = current[key] or current[tonumber(key)]
	end

	return current, #keys
end

local function MergeTables(pattern, template)
	local result = {}
	local changes = {}

	local patternPaths = GetTableIndexesTree(pattern)
    local templatePaths = GetTableIndexesTree(template)

	for _, path in pairs(patternPaths) do
		local templateValue = getByPath(template, path)
		local patternValue = getByPath(pattern, path)

        --CHANGED VALUE
        if templateValue ~= nil and patternValue ~= nil and templateValue ~= patternValue then
			setByPath(result, path, templateValue)
            table.insert(changes, {
                path = path,
                value = templateValue,
                action = "change"
            })

        --REMOVED VALUE
		elseif templateValue == nil and patternValue ~= nil then
			setByPath(result, path, patternValue)
            table.insert(changes, {
                path = path,
                value = patternValue,
                action = "remove"
            })
        else
            setByPath(result, path, patternValue)
		end
	end

    for _, path in pairs(templatePaths) do
		local templateValue, templateLevel = getByPath(template, path)
		local patternValue, patternLevel = getByPath(pattern, path)

        if templateLevel > patternLevel and templateValue ~= nil and patternValue == nil then
            print("ADDED NEW VALUE", path)
            local actualValue = getByPath(result, path, templateLevel - 1)
            table.insert(changes, {
                path = path,
                value = actualValue,
                action = "add"
            })
        end
        --ADDED NEW VALUE
        -- if templateValue ~= nil and patternValue == nil then
        --     setByPath(result, path, templateValue)
        --     table.insert(changes, {
        --         path = path,
        --         value = templateValue,
        --         action = "add"
        --     })
        -- end
    end

	return result, changes
end

local a = {
  Inventory = {
    {skin = "gg", name = "wp"},
  },

  Pets = {
    ["dog"] = {skin = "gg", name = "wp"},
  }
}

local b = {
  Inventory = {
    --  {skin = "gg", name = "wp"},
  },

  Pets = {
    ["dog"] = {skin = "gg", name = "wp"},
    ["cat"] = {skin = "gg", name = "wp"},
  }
}

local result, changes = MergeTables(a, b)
printTable(changes)