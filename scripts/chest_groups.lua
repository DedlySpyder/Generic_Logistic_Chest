require("util")

ChestGroups = {}

ChestGroups._cache = {}
ChestGroups._cache.GENERIC_TO_REPLACEMENT = nil
ChestGroups._cache.REPLACEMENT_TO_GENERIC = nil
ChestGroups._cache.FULL_GROUPING = nil
ChestGroups._cache.FULL_GROUPING_LIST = nil
ChestGroups._cache.FULL_GROUPING_WITH_ORIGINALS = nil

-- Returns the chest group and whether it should be cached or not
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
		end), true
	elseif game then
		return Util.Table.filter(ChestGroups._RAW, function(group)
			return game.active_mods[group.mod]
		end), true
	else
		Util.debugLog("WARN: Could not find mods or game, returning all chest groups")
		return ChestGroups._RAW, false
	end
end

-- Returns a map of generic chest -> replacement chest
function ChestGroups.getGenericToReplacementMapping()
	if not ChestGroups._cache.GENERIC_TO_REPLACEMENT then
		Util.debugLog("No cache found for generic to replacement mapping, generating now")
		local rawChestGroups, cache = ChestGroups.getGroups()
		local mapping = {}
		for _, group in ipairs(rawChestGroups) do
			local replacements = Util.Table.map(group.replacements, function(r) return Util.MOD_PREFIX .. r end)
			mapping[Util.MOD_PREFIX .. group.name] = replacements
		end
		
		if not cache then
			Util.debugLog("Skipping cache setting")
			return mapping, false
		end
		ChestGroups._cache.GENERIC_TO_REPLACEMENT = mapping
	end
	return ChestGroups._cache.GENERIC_TO_REPLACEMENT, true
end

-- Returns a map of replacement chest -> generic chest
function ChestGroups.getReplacementToGenericMapping()
	if not ChestGroups._cache.REPLACEMENT_TO_GENERIC then
		Util.debugLog("No cache found for replacement to generic mapping, generating now")
		local genericMapping, cache = ChestGroups.getGenericToReplacementMapping()
		local mapping = {}
		for generic, replacements in pairs(genericMapping) do
			for _, replacement in ipairs(replacements) do
				mapping[replacement] = generic
			end
		end
		
		if not cache then
			Util.debugLog("Skipping cache setting")
			return mapping
		end
		ChestGroups._cache.REPLACEMENT_TO_GENERIC = mapping
	end
	return ChestGroups._cache.REPLACEMENT_TO_GENERIC
end

-- Returns a map of chest -> chest group (map of name -> true)
function ChestGroups.getFullGroupsMapping()
	if not ChestGroups._cache.FULL_GROUPING then
		Util.debugLog("No cache found for full groups mapping, generating now")
		local rawChestGroups, cache = ChestGroups.getGroups()
		local mapping = {}
		for _, group in ipairs(rawChestGroups) do
			local finalGroup = {[Util.MOD_PREFIX .. group.name] = true}
			local replacements = Util.Table.map(group.replacements, function(r) return Util.MOD_PREFIX .. r end)
			for _, replacement in ipairs(replacements) do
				finalGroup[replacement] = true
			end
			
			for chest, _ in pairs(finalGroup) do
				mapping[chest] = finalGroup
			end
		end
		
		if not cache then
			Util.debugLog("Skipping cache setting")
			return mapping, false
		end
		ChestGroups._cache.FULL_GROUPING = mapping
	end
	return ChestGroups._cache.FULL_GROUPING, true
end

-- Returns a map of chest -> chest group (list of chests)
function ChestGroups.getFullGroupsListMapping()
	if not ChestGroups._cache.FULL_GROUPING_LIST then
		Util.debugLog("No cache found for full groups list mapping, generating now")
		local rawChestGroups, cache = ChestGroups.getGroups()
		local mapping = {}
		for _, group in ipairs(rawChestGroups) do
			local finalGroup = {Util.MOD_PREFIX .. group.name}
			local replacements = Util.Table.map(group.replacements, function(r) return Util.MOD_PREFIX .. r end)
			for _, replacement in ipairs(replacements) do
				table.insert(finalGroup, replacement)
			end
			
			for _, chest in pairs(finalGroup) do
				mapping[chest] = finalGroup
			end
		end
		
		if not cache then
			Util.debugLog("Skipping cache setting")
			return mapping, false
		end
		ChestGroups._cache.FULL_GROUPING_LIST = mapping
	end
	return ChestGroups._cache.FULL_GROUPING_LIST
end

-- Returns a map of chest -> {map of chest names (including originals) -> generic chest name version}
function ChestGroups.getFullGroupsWithOriginalsMapping()
	if not ChestGroups._cache.FULL_GROUPING_WITH_ORIGINALS then
		Util.debugLog("No cache found for full grouping with originals mapping, generating now")
		local rawChestGroups, cache = ChestGroups.getGroups()
		local mapping = {}
		for _, group in ipairs(rawChestGroups) do
			local finalGroup = {[Util.MOD_PREFIX .. group.name] = Util.MOD_PREFIX .. group.name}
			
			local orignalReplacements = group.replacements
			for _, replacement in ipairs(orignalReplacements) do
				finalGroup[replacement] = Util.MOD_PREFIX .. replacement
			end
			
			local replacements = Util.Table.map(orignalReplacements, function(r) return Util.MOD_PREFIX .. r end)
			for _, replacement in ipairs(replacements) do
				finalGroup[replacement] = replacement
			end
			
			for chest, _ in pairs(finalGroup) do
				mapping[chest] = finalGroup
			end
		end
		
		if not cache then
			Util.debugLog("Skipping cache setting")
			return mapping
		end
		ChestGroups._cache.FULL_GROUPING_WITH_ORIGINALS = mapping
	end
	return ChestGroups._cache.FULL_GROUPING_WITH_ORIGINALS
end


-- ~~ Getters/Tests ~~ --

function ChestGroups.getReplacementsFromGeneric(generic)
	return ChestGroups.getGenericToReplacementMapping()[generic]
end

function ChestGroups.getGenericFromReplacement(replacement)
	return ChestGroups.getReplacementToGenericMapping()[replacement]
end

function ChestGroups.getFullGroup(name)
	return ChestGroups.getFullGroupsMapping()[name]
end

function ChestGroups.getFullGroupList(name)
	return ChestGroups.getFullGroupsListMapping()[name]
end

function ChestGroups.getFullGroupWithOriginals(name)
	return ChestGroups.getFullGroupsWithOriginalsMapping()[name]
end


-- ~~ Raw data ~~ --

ChestGroups._RAW = {
	{
		mod = "base",
		name = "logistic-chest",
		localeName = "Generic_Logistic_base_logistic_chest",
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
		localeName = "Generic_Logistic_Warehousing_storehouse",
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
		localeName = "Generic_Logistic_Warehousing_warehouse",
		generic = "warehouse-storage",
		ingredients = {{"warehouse-basic", 1}, {"Generic_Logistic_logistic-chest", 1}, {"steel-plate", 10}, {"iron-stick", 15}},
		replacements = {
			"warehouse-passive-provider",
			"warehouse-active-provider",
			"warehouse-storage",
			"warehouse-requester",
			"warehouse-buffer"
		}
	},
	{
		mod = "boblogistics",
		name = "logistic-chest-2",
		localeName = "Generic_Logistic_boblogistic_logistic_chest_2",
		generic = "logistic-chest-storage-2",
		ingredients = {{"Generic_Logistic_logistic-chest", 1}, {"processing-unit", 1}},
		replacements = {
			"logistic-chest-passive-provider-2",
			"logistic-chest-active-provider-2",
			"logistic-chest-storage-2",
			"logistic-chest-requester-2",
			"logistic-chest-buffer-2"
		}
	},
	{
		mod = "boblogistics",
		name = "logistic-chest-3",
		localeName = "Generic_Logistic_boblogistic_logistic_chest_3",
		generic = "logistic-chest-storage-3",
		ingredients = {{"Generic_Logistic_logistic-chest-2", 1}, {"processing-unit", 1}},
		replacements = {
			"logistic-chest-passive-provider-3",
			"logistic-chest-active-provider-3",
			"logistic-chest-storage-3",
			"logistic-chest-requester-3",
			"logistic-chest-buffer-3"
		}
	}
	--[[
,
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
