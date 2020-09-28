CHEST_GROUPS = {
	{
		mod = "base",
		name = "logistic-chest",
		localeName = "Generic_Logistic_logistic-chest",
		generic = "logistic-chest-storage",
		ingredients = {{"steel-chest", 1}, {"processing-unit", 2}},
		replacements = {
			"logistic-chest-passive-provider",
			"logistic-chest-active-provider",
			"logistic-chest-storage",
			"logistic-chest-requester",
			"logistic-chest-buffer"
		}
	},
	{
		mod = "Warehousing",
		name = "storehouse",
		localeName = "Generic_Logistic_storehouse",
		generic = "storehouse-storage",
		ingredients = {{"storehouse-basic", 1}, {"Generic_Logistic_logistic-chest", 1}, {"iron-stick", 4}},
		replacements = {
			"storehouse-passive-provider",
			"storehouse-active-provider",
			"storehouse-storage",
			"storehouse-requester",
			"storehouse-buffer"
		}
	},
	{
		mod = "Warehousing",
		name = "warehouse",
		localeName = "Generic_Logistic_warehouse",
		generic = "warehouse-storage",
		ingredients = {{"warehouse-basic", 1}, {"Generic_Logistic_logistic-chest", 1}, {"steel-plate", 10}, {"iron-stick", 15}},
		replacements = {
			"warehouse-passive-provider",
			"warehouse-active-provider",
			"warehouse-storage",
			"warehouse-requester",
			"warehouse-buffer"
		}
	}
	--[[
	{
		mod = "modName",
		name = "chestName",
		localeName = "localeNameString",
		generic = "storageChest",
		ingredients = INGREDIENTS,
		replacements = {
			"passiveProvider",
			"activeProvider",
			"storageChest",
			"requester",
			"buffer"
		}
	}
	]]--
}
