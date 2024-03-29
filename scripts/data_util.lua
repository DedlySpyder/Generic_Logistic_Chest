local DataUtil = {}

-- Only for use in the data stage
function DataUtil.dumpLogisticChests()
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

return DataUtil
