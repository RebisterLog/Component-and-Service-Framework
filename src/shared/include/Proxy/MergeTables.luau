--!native

local function GetTableLength(t)
	local count = 0
	for _ in pairs(t) do
		count += 1
	end
	return count
end

local function GetTableIndexesTree(tab, prefix)
	local tree = {}

	for index, value in pairs(tab) do
		local newPrefix = prefix and (prefix .. "." .. index) or index

		if typeof(value) == "table" then
			if GetTableLength(value) == 0 then
				table.insert(tree, newPrefix)
			else
				local subTree = GetTableIndexesTree(value, newPrefix)
				for _, path in ipairs(subTree) do
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

local function getByPath(tab, path)
	local keys = string.split(path, ".")
	local current = tab

	for _, key in pairs(keys) do
		if not current or typeof(current) ~= "table" then
			return nil
		end
		current = current[key]
	end

	return current
end

local function MergeTables(pattern, template): ({}, {[string]: any})
	local result = {}
	local changes = {}

	local patternPaths = GetTableIndexesTree(pattern)

	for _, path in pairs(patternPaths) do
		local templateValue = getByPath(template, path)
		local patternValue = getByPath(pattern, path)

		if templateValue ~= nil then
			setByPath(result, path, templateValue)
			changes[path] = templateValue
		else
			setByPath(result, path, patternValue)
		end
	end

	return result, changes
end

return MergeTables
