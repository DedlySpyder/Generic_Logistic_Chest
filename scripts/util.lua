require("config")

Util = {}

Util.MOD_PREFIX = "Generic_Logistic_"

-- Only for use in the data stage
Util.dumpLogisticChests = function()
	if data and data.raw then
		local chests = {}
		for name, _ in pairs(data.raw["logistic-container"]) do
			local recipe = data.raw["recipe"][name]
			if recipe and recipe.ingredients then
				chests[name] = recipe.ingredients
			else
				chests[name] = recipe
			end
		end
		return chests
	end
end


function Util.getAbsolutePosition(surface, position)
	return surface.name .. "_" ..position.x .. "_" .. position.y
end
