require("config")

Util = {}

Util.MOD_PREFIX = "Generic_Logistic_"

-- Only for use in the data stage
Util.dumpLogisticChests = function()
	if data and data.raw then
		log("Listing all logistic containers: ")
		for name, prototype in pairs(data.raw["logistic-container"]) do
			log("  " .. name)
			local recipe = data.raw["recipe"][name]
			if recipe and recipe.ingredients then
				log("    " .. serpent.line(recipe.ingredients))
			end
		end
	end
end


function Util.getAbsolutePosition(surface, position)
	return surface.name .. "_" ..position.x .. "_" .. position.y
end


Util.Player = {}
function Util.Player.isCursorEmpty(player)
	return not player.cursor_stack or not player.cursor_stack.valid_for_read
end


Util.Table = {}

-- Filter either a table or an array, if the function returns true then the value will stay
function Util.Table.filter(tbl, func)
	local newTable = {}
	local isArr = #tbl > 0
	for k, v in pairs(tbl) do
		if func(v) then
			if isArr then
				table.insert(newTable, v)
			else
				newTable[k] = v
			end
		end
	end
	return newTable
end

function Util.Table.map(tbl, func)
	local newTable = {}
	local isArr = #tbl > 0
	for k, v in pairs(tbl) do
		if isArr then
			local newValue = func(v)
			if newValue then
				table.insert(newTable, newValue)
			end
		else
			newTable[k] = func(v)
		end
	end
	return newTable
end
