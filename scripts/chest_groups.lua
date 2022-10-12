local Logger = require("__DedLib__/modules/logger").create{modName = "Generic_Logistic_Chest"}
local Table = require("__DedLib__/modules/table")

local Config = require("config")

ChestGroups = {}

ChestGroups._cache = {}
ChestGroups._cache.GENERIC_TO_REPLACEMENT = nil
ChestGroups._cache.REPLACEMENT_TO_GENERIC = nil
ChestGroups._cache.FULL_GROUPING = nil
ChestGroups._cache.FULL_GROUPING_LIST = nil
ChestGroups._cache.FULL_GROUPING_WITH_ORIGINALS = nil
ChestGroups._cache.FULL_GROUPING_WITH_ORIGINALS_LIST = nil

function ChestGroups._groupIsEnabled(group)
	local enabled = group.enabled
	if group.enabled then
		local enabledType = type(enabled)
		if enabledType == "string" then
			local value = settings.startup[enabled].value
			Logger:info("Flag for %s is set to %s", group.mod, value)
			return value
		end
	else
		-- Enabled by default
		return true
	end
end

-- Returns the chest group and whether it should be cached or not
function ChestGroups.getGroups()
	Logger:trace("Looking up chest groups")
	if mods then
		return Table.filter(ChestGroups._RAW, function(group)
			if mods[group.mod] then
				Logger:info("Found group for %s prerequisite mod %s enabled", group.name, group.mod)
				return ChestGroups._groupIsEnabled(group)
			else
				Logger:info("Skipping group for %s prerequisite mod %s disabled", group.name, group.mod)
				return false
			end
		end), true
	elseif game then
		return Table.filter(ChestGroups._RAW, function(group)
			if game.active_mods[group.mod] then
				Logger:info("Found group for %s prerequisite mod %s enabled", group.name, group.mod)
				return ChestGroups._groupIsEnabled(group)
			else
				Logger:info("Skipping group for %s prerequisite mod %s disabled", group.name, group.mod)
				return false
			end
		end), true
	else
		Logger:warn("Could not find active mod list, returning all chest groups")
		return ChestGroups._RAW, false
	end
end

-- Returns a map of generic chest -> replacement chest
function ChestGroups.getGenericToReplacementMapping()
	if not ChestGroups._cache.GENERIC_TO_REPLACEMENT then
		Logger:info("No cache found for generic to replacement mapping, generating now")
		local rawChestGroups, cache = ChestGroups.getGroups()
		local mapping = {}
		for _, group in ipairs(rawChestGroups) do
			local replacements = Table.map(group.replacements, function(r) return Config.MOD_PREFIX .. r end)
			mapping[Config.MOD_PREFIX .. group.name] = replacements
		end
		
		if not cache then
			Logger:info("Skipping caching...")
			return mapping, false
		end
		ChestGroups._cache.GENERIC_TO_REPLACEMENT = mapping
		Logger:debug("Cached generic to replacement mapping")
		Logger:trace(mapping)
	end
	return ChestGroups._cache.GENERIC_TO_REPLACEMENT, true
end

-- Returns a map of replacement chest -> generic chest
function ChestGroups.getReplacementToGenericMapping()
	if not ChestGroups._cache.REPLACEMENT_TO_GENERIC then
		Logger:info("No cache found for replacement to generic mapping, generating now")
		local genericMapping, cache = ChestGroups.getGenericToReplacementMapping()
		local mapping = {}
		for generic, replacements in pairs(genericMapping) do
			for _, replacement in ipairs(replacements) do
				mapping[replacement] = generic
			end
		end
		
		if not cache then
			Logger:info("Skipping caching...")
			return mapping
		end
		ChestGroups._cache.REPLACEMENT_TO_GENERIC = mapping
		Logger:debug("Cached replacement to generic mapping")
		Logger:trace(mapping)
	end
	return ChestGroups._cache.REPLACEMENT_TO_GENERIC
end

-- Returns a map of chest -> chest group (map of name -> true)
function ChestGroups.getFullGroupsMapping()
	if not ChestGroups._cache.FULL_GROUPING then
		Logger:info("No cache found for full groups mapping, generating now")
		local rawChestGroups, cache = ChestGroups.getGroups()
		local mapping = {}
		for _, group in ipairs(rawChestGroups) do
			local finalGroup = {[Config.MOD_PREFIX .. group.name] = true}
			local replacements = Table.map(group.replacements, function(r) return Config.MOD_PREFIX .. r end)
			for _, replacement in ipairs(replacements) do
				finalGroup[replacement] = true
			end
			
			for chest, _ in pairs(finalGroup) do
				mapping[chest] = finalGroup
			end
		end
		
		if not cache then
			Logger:info("Skipping caching...")
			return mapping, false
		end
		ChestGroups._cache.FULL_GROUPING = mapping
		Logger:debug("Cached full groups mapping")
		Logger:trace(mapping)
	end
	return ChestGroups._cache.FULL_GROUPING, true
end

-- Returns a map of chest -> chest group (list of chests)
function ChestGroups.getFullGroupsListMapping()
	if not ChestGroups._cache.FULL_GROUPING_LIST then
		Logger:info("No cache found for full groups list mapping, generating now")
		local rawChestGroups, cache = ChestGroups.getGroups()
		local mapping = {}
		for _, group in ipairs(rawChestGroups) do
			local finalGroup = {Config.MOD_PREFIX .. group.name}
			local replacements = Table.map(group.replacements, function(r) return Config.MOD_PREFIX .. r end)
			for _, replacement in ipairs(replacements) do
				table.insert(finalGroup, replacement)
			end
			
			for _, chest in pairs(finalGroup) do
				mapping[chest] = finalGroup
			end
		end
		
		if not cache then
			Logger:info("Skipping caching...")
			return mapping, false
		end
		ChestGroups._cache.FULL_GROUPING_LIST = mapping
		Logger:debug("Cached full groups list mapping")
		Logger:trace(mapping)
	end
	return ChestGroups._cache.FULL_GROUPING_LIST
end

-- Returns a map of chest -> {map of chest names (including originals) -> generic chest name version}
function ChestGroups.getFullGroupsWithOriginalsMapping()
	if not ChestGroups._cache.FULL_GROUPING_WITH_ORIGINALS then
		Logger:info("No cache found for full grouping with originals mapping, generating now")
		local rawChestGroups, cache = ChestGroups.getGroups()
		local mapping = {}
		for _, group in ipairs(rawChestGroups) do
			local finalGroup = {[Config.MOD_PREFIX .. group.name] = Config.MOD_PREFIX .. group.name}
			
			local orignalReplacements = group.replacements
			for _, replacement in ipairs(orignalReplacements) do
				finalGroup[replacement] = Config.MOD_PREFIX .. replacement
			end
			
			local replacements = Table.map(orignalReplacements, function(r) return Config.MOD_PREFIX .. r end)
			for _, replacement in ipairs(replacements) do
				finalGroup[replacement] = replacement
			end
			
			for chest, _ in pairs(finalGroup) do
				mapping[chest] = finalGroup
			end
		end
		
		if not cache then
			Logger:info("Skipping caching...")
			return mapping
		end
		ChestGroups._cache.FULL_GROUPING_WITH_ORIGINALS = mapping
		Logger:debug("Cached full grouping with originals mapping")
		Logger:trace(mapping)
	end
	return ChestGroups._cache.FULL_GROUPING_WITH_ORIGINALS
end

-- Returns a map of chest -> chest group (list of chests) (including originals)
function ChestGroups.getFullGroupsWithOriginalsListMapping()
	if not ChestGroups._cache.FULL_GROUPING_WITH_ORIGINALS_LIST then
		Logger:info("No cache found for full grouping with originals list mapping, generating now")
		local rawChestGroups, cache = ChestGroups.getGroups()
		local mapping = {}
		for _, group in ipairs(rawChestGroups) do
			local finalGroup = {Config.MOD_PREFIX .. group.name}
			mapping[Config.MOD_PREFIX .. group.name] = finalGroup
			for _, replacement in ipairs(group.replacements) do
				table.insert(finalGroup, replacement)
				
				local modReplacement = Config.MOD_PREFIX .. replacement
				table.insert(finalGroup, modReplacement)
				mapping[modReplacement] = finalGroup
			end
		end
		
		if not cache then
			Logger:info("Skipping caching...")
			return mapping
		end
		ChestGroups._cache.FULL_GROUPING_WITH_ORIGINALS_LIST = mapping
		Logger:debug("Cached full grouping with originals list mapping")
		Logger:trace(mapping)
	end
	return ChestGroups._cache.FULL_GROUPING_WITH_ORIGINALS_LIST
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

function ChestGroups.getFullGroupWithOriginalsList(name)
	return ChestGroups.getFullGroupsWithOriginalsListMapping()[name]
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
	},
	{
		mod = "aai-containers",
		name = "aai-strongbox",
		localeName = "Generic_Logistic_aai_containers_strongbox",
		generic = "aai-strongbox-storage",
		ingredients = {{"aai-strongbox", 1}, {"processing-unit", 4}},
		replacements = {
			"aai-strongbox-passive-provider",
			"aai-strongbox-active-provider",
			"aai-strongbox-storage",
			"aai-strongbox-requester",
			"aai-strongbox-buffer"
		}
	},
	{
		mod = "aai-containers",
		name = "aai-storehouse",
		localeName = "Generic_Logistic_aai_containers_storehouse",
		generic = "aai-storehouse-storage",
		ingredients = {{"aai-storehouse", 1}, {"processing-unit", 10}},
		replacements = {
			"aai-storehouse-passive-provider",
			"aai-storehouse-active-provider",
			"aai-storehouse-storage",
			"aai-storehouse-requester",
			"aai-storehouse-buffer"
		}
	},
	{
		mod = "aai-containers",
		name = "aai-warehouse",
		localeName = "Generic_Logistic_aai_containers_warehouse",
		generic = "aai-warehouse-storage",
		ingredients = {{"aai-warehouse", 1}, {"processing-unit", 20}},
		replacements = {
			"aai-warehouse-passive-provider",
			"aai-warehouse-active-provider",
			"aai-warehouse-storage",
			"aai-warehouse-requester",
			"aai-warehouse-buffer"
		}
	},
	{
		mod = "angelsaddons-storage",
		name = "angels-warehouse",
		localeName = "Generic_Logistic_angels_warehouse",
		generic = "angels-warehouse-storage",
		ingredients = {{"angels-warehouse", 1}, {"processing-unit", 20}},
		replacements = {
			"angels-warehouse-passive-provider",
			"angels-warehouse-active-provider",
			"angels-warehouse-storage",
			"angels-warehouse-requester",
			"angels-warehouse-buffer"
		}
	},
	{
		mod = "angelsaddons-storage",
		name = "angels-silo",
		localeName = "Generic_Logistic_angels_silo",
		generic = "silo-storage",
		ingredients = {{"silo", 1}, {"processing-unit", 20}},
		replacements = {
			"silo-passive-provider",
			"silo-active-provider",
			"silo-storage",
			"silo-requester",
			"silo-buffer"
		}
	},
	{
		mod = "Krastorio2",
		name = "kr-medium-container",
		localeName = "Generic_Logistic_Krastorio2_medium_container",
		generic = "kr-medium-storage-container",
		ingredients = {{"kr-medium-container", 1}, {"processing-unit", 5}},
		replacements = {
			"kr-medium-passive-provider-container",
			"kr-medium-active-provider-container",
			"kr-medium-storage-container",
			"kr-medium-requester-container",
			"kr-medium-buffer-container"
		}
	},
	{
		mod = "Krastorio2",
		name = "kr-big-container",
		localeName = "Generic_Logistic_Krastorio2_big_container",
		generic = "kr-big-storage-container",
		ingredients = {{"kr-big-container", 1}, {"processing-unit", 5}},
		replacements = {
			"kr-big-passive-provider-container",
			"kr-big-active-provider-container",
			"kr-big-storage-container",
			"kr-big-requester-container",
			"kr-big-buffer-container"
		}
	},
	{
		mod = "pyindustry",
		name = "py-deposit",
		localeName = "Generic_Logistic_pyindustry_deposit",
		generic = "py-deposit-storage",
		ingredients = {
			{"py-deposit-basic", 1},
			{"Generic_Logistic_logistic-chest", 1},
			{"iron-plate", 20},
			{"processing-unit", 5},
			{"steel-chest", 15}
		},
		replacements = {
			"py-deposit-passive-provider",
			"py-deposit-active-provider",
			"py-deposit-storage",
			"py-deposit-requester",
			"py-deposit-buffer"
		}
	},
	{
		mod = "pyindustry",
		name = "py-shed",
		localeName = "Generic_Logistic_pyindustry_shed",
		generic = "py-shed-storage",
		ingredients = {
			{"py-shed-basic", 1},
			{"Generic_Logistic_logistic-chest", 1},
			{"iron-plate", 5},
			{"processing-unit", 2},
			{"steel-chest", 5}
		},
		replacements = {
			"py-shed-passive-provider",
			"py-shed-active-provider",
			"py-shed-storage",
			"py-shed-requester",
			"py-shed-buffer"
		}
	},
	{
		mod = "pyindustry",
		name = "py-storehouse",
		localeName = "Generic_Logistic_pyindustry_storehouse",
		generic = "py-storehouse-storage",
		ingredients = {
			{"py-storehouse-basic", 1},
			{"Generic_Logistic_logistic-chest", 1},
			{"iron-plate", 5},
			{"processing-unit", 2},
			{"steel-chest", 5}
		},
		replacements = {
			"py-storehouse-passive-provider",
			"py-storehouse-active-provider",
			"py-storehouse-storage",
			"py-storehouse-requester",
			"py-storehouse-buffer"
		}
	},
	{
		mod = "pyindustry",
		name = "py-warehouse",
		localeName = "Generic_Logistic_pyindustry_warehouse",
		generic = "py-warehouse-storage",
		ingredients = {
			{"py-warehouse-basic", 1},
			{"Generic_Logistic_logistic-chest", 1},
			{"iron-plate", 20},
			{"processing-unit", 5},
			{"steel-chest", 15}
		},
		replacements = {
			"py-warehouse-passive-provider",
			"py-warehouse-active-provider",
			"py-warehouse-storage",
			"py-warehouse-requester",
			"py-warehouse-buffer"
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
