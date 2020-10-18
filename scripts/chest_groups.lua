require("util")

ChestGroups = {}

ChestGroups._cache = {}
ChestGroups._cache.GENERIC_TO_REPLACEMENT = nil
ChestGroups._cache.REPLACEMENT_TO_GENERIC = nil

function ChestGroups.getGroups()
	Util.debugLog("Looking up chest groups")
	if mods then
		return Util.Table.filter(ChestGroups._RAW, function(group)
			if mods[group.mod] then
				Util.debugLog("Found group for " .. group.name .. " prerequisite mod " .. group.mod .. " enabled")
				return true
			else
				Util.debugLog("Skipping group for " .. group.name .. " prerequisite mod " .. group.mod .. " disabled")
			end
		end)
	elseif game then
		return Util.Table.filter(ChestGroups._RAW, function(group)
			return game.active_mods[group.mod]
		end)
	else
		Util.debugLog("WARN: Could not find mods or game, returning all chest groups")
		return ChestGroups._RAW
	end
end

function ChestGroups.getGenericToReplacementMapping()
	if not ChestGroups._cache.GENERIC_TO_REPLACEMENT then
		local mapping = {}
		for _, group in ipairs(ChestGroups.getGroups()) do
			local replacements = Util.Table.map(group.replacements, function(r) return Util.MOD_PREFIX .. r end)
			mapping[Util.MOD_PREFIX .. group.name] = replacements
		end
		ChestGroups._cache.GENERIC_TO_REPLACEMENT = mapping
	end
	return ChestGroups._cache.GENERIC_TO_REPLACEMENT
end

function ChestGroups.getReplacementToGenericMapping()
	if not ChestGroups._cache.REPLACEMENT_TO_GENERIC then
		local genericMapping = ChestGroups.getGenericToReplacementMapping()
		local mapping = {}
		for generic, replacements in pairs(genericMapping) do
			for _, replacement in ipairs(replacements) do
				mapping[replacement] = generic
			end
		end
		ChestGroups._cache.REPLACEMENT_TO_GENERIC = mapping
	end
	return ChestGroups._cache.REPLACEMENT_TO_GENERIC
end

ChestGroups._RAW = {
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
