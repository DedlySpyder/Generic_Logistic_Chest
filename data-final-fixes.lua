if Util.DEBUG_MODE then
	Util.debugLog("Listing all logistic containers: ")
	for name, prototype in pairs(data.raw["logistic-container"]) do
		Util.debugLog("  " .. name)
		local recipe = data.raw["recipe"][name]
		if recipe and recipe.ingredients then
			Util.debugLog("    " .. serpent.line(recipe.ingredients))
		end
	end
end
