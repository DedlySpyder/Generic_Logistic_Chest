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
