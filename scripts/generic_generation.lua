local Logger = require("__DedLib__/modules/logger").create{modName = "Generic_Logistic_Chest"}
local Math = require("__DedLib__/modules/math")

local Config = require("scripts/config")
local DataUtil = require("scripts/data_util")

Generic_Logistic_Generator = {}

-- Keyed by name
-- Contains {generic, replacements}
Generic_Logistic_Generator._groups = {}

-- A Table that contains the following:
--		mod						- Name of the mod that needs to be enabled for this group
-- 		name					- Name to use for the generic chest (this should be general like "logistic-chest")
-- 		localeName				- Localized string name to use for the generic chest
-- 		generic					- The entity name to base the generic chest of this group off of
-- 		ingredients				- The ingredients used for the generic chest
-- 		replacements			- A list of entity names to base the replacement chests off of
function Generic_Logistic_Generator.addGenericGroup(data)
	Generic_Logistic_Generator._groups[data.name] = data
end

-- This should be called after all groups are added
-- Though it will clear the current groups in case it is used multiple times, it will cause longer game load times
function Generic_Logistic_Generator.generate()
	Logger:trace("Generating generic logistic prototypes...")
	Generic_Logistic_Generator._cache.cacheAllPrototypes()
	
	for name, data in pairs(Generic_Logistic_Generator._groups) do
		local success, msg = pcall(Generic_Logistic_Generator.generateGroup, name, data)
		if not success then
			Logger:fatal("Failed to generate logistic chest for group %s: %s", name, data)
			Logger:fatal_block(DataUtil.dumpLogisticChests())
			for _, chest in ipairs(data.replacements) do
				if not Generic_Logistic_Generator._cache.ENTITY_CACHE[chest] then
					error('Failed to generate generic logistic chest "' .. chest .. '" for mod "' .. data.mod .. '". Please report this error to the mod portal with the factorio-current.log')
				end
			end
			error('Failed to generate generic logistic chest(s) for mod "' .. data.mod .. '". Please report this error to the mod portal with the factorio-current.log\n' .. msg)
		end
	end
	-- Logger:trace_block("Adding prototypes: %s", Generic_Logistic_Generator._internal.NEW_PROTOTYPES)
	data:extend(Generic_Logistic_Generator._internal.NEW_PROTOTYPES)
	
	Generic_Logistic_Generator.createTempChest(Generic_Logistic_Generator._internal.LARGEST_SIZE)
	
	Generic_Logistic_Generator._groups = {}
	Generic_Logistic_Generator._cache.clear()
end

function Generic_Logistic_Generator.generateGroup(name, data)
	Logger:info("Generating prototypes for generic group %s", name)
	local genericName = Config.MOD_PREFIX .. name
	local localeName = data.localeName
	local genericEntityBase = data.generic
	
	local baseEntities = table.deepcopy(data.replacements)
	table.insert(baseEntities, genericEntityBase)
	local tech = Generic_Logistic_Generator._internal.choseLatestTech(baseEntities)
	local genericOrder = Generic_Logistic_Generator._internal.calculateGenericOrder(baseEntities)

	Logger:info("Generic chest name: %s", genericName)
	table.insert(Generic_Logistic_Generator._internal.NEW_PROTOTYPES, Generic_Logistic_Generator._internal.createGenericChestItem(genericEntityBase, genericName, localeName, genericOrder))
	table.insert(Generic_Logistic_Generator._internal.NEW_PROTOTYPES, Generic_Logistic_Generator._internal.createGenericChestEntity(genericEntityBase, genericName, localeName))
	table.insert(Generic_Logistic_Generator._internal.NEW_PROTOTYPES, Generic_Logistic_Generator._internal.createGenericChestRecipe(genericEntityBase, genericName, data.ingredients, tech, genericOrder))
	
	local size = Generic_Logistic_Generator._cache.ENTITY_CACHE[genericEntityBase].inventory_size
	if size > Generic_Logistic_Generator._internal.LARGEST_SIZE then
		Generic_Logistic_Generator._internal.LARGEST_SIZE = size
	end
	
	for _, replacement in ipairs(data.replacements) do
		Logger:info("Generating replacement prototypes for %s", replacement)
		table.insert(Generic_Logistic_Generator._internal.NEW_PROTOTYPES, Generic_Logistic_Generator._internal.createReplacementItem(replacement))
		table.insert(Generic_Logistic_Generator._internal.NEW_PROTOTYPES, Generic_Logistic_Generator._internal.createReplacementEntity(replacement, genericName))
	end
	
	Generic_Logistic_Generator._internal.GROUP_COUNT = Generic_Logistic_Generator._internal.GROUP_COUNT + 1
end

function Generic_Logistic_Generator.createTempChest(size)
	Logger:info("Creating temp chest of size %s", size)
	data:extend({{
		type = "container",
		name = Config.MOD_PREFIX .. "temp",
		icon = "__Generic_Logistic_Chest__/graphics/generic_chest_icon.png",
		icon_size = 64,
		flags = {"not-blueprintable", "not-deconstructable", "not-on-map", "hidden", "hide-alt-info", "not-flammable", "no-copy-paste", "not-selectable-in-game", "not-upgradable"},
		collision_mask = {},
		inventory_size = size,
		picture =
		{
			filename = "__Generic_Logistic_Chest__/graphics/generic_chest_icon.png",
			size = 64
		}
	}})
end



Generic_Logistic_Generator._internal = {}
Generic_Logistic_Generator._internal.GROUP_COUNT = 0
Generic_Logistic_Generator._internal.LARGEST_SIZE = 0
Generic_Logistic_Generator._internal.NEW_PROTOTYPES = {}

function Generic_Logistic_Generator._internal.generifyIcons(item, isReplacement)
	-- Move the icon spec back to icons if it doesn't already exist
	if not item.icons then
		item.icons = {
			{
				icon = item.icon,
				icon_size = item.icon_size,
				icon_mipmaps = item.icon_mipmaps
			}
		}
		item.icon = nil
		item.icon_size = nil
		item.icon_mipmaps = nil
	end
	if isReplacement then
		table.insert(item.icons, {
			icon = "__Generic_Logistic_Chest__/graphics/generic_replacement_icon.png",
			icon_size = 64
		})
	else
		table.insert(item.icons, {
			icon = "__Generic_Logistic_Chest__/graphics/generic_chest_icon.png",
			icon_size = 64
		})
	end
end

-- entity		- the LuaEntity to modify
-- newLayerFunc	- a function that will accept the current sprite's size and return a new layer to add to the sprite on top
function Generic_Logistic_Generator._internal.generifySprite(entity, newLayerFunc)
	local sprite = entity.animation or entity.picture
	if not sprite.layers then
		sprite = {layers={sprite}}
	end
	
	local firstLayer = sprite.layers[1]
	local oldSpriteSize = Math.min(firstLayer.height, firstLayer.width, firstLayer.size)
	table.insert(sprite.layers, newLayerFunc(oldSpriteSize))
	
	if entity.animation then
		local repeatCount = firstLayer.repeat_count or firstLayer.frame_count
		sprite.layers[#sprite.layers].repeat_count = repeatCount
		sprite.layers[#sprite.layers].hr_version.repeat_count = repeatCount
		entity.animation = sprite
	else
		-- The sprite was a picture
		entity.picture = sprite
	end
end

-- Replacement Chest Generation
function Generic_Logistic_Generator._internal.createReplacementItem(entityName)
	local item = table.deepcopy(Generic_Logistic_Generator._cache.ITEM_RESULT_CACHE[entityName])
	item.localised_name = Generic_Logistic_Generator._internal.getReplacementLocalisedName(item)
	item.localised_description = {"item-description." .. item.name}
	item.name = Config.MOD_PREFIX .. item.name
	item.order = "zzzzzzzzzzzzzzzzzzzz"
	item.flags = {"hidden"}
	item.place_result = Config.MOD_PREFIX .. item.place_result -- This should never exist as an item, but just in case
	
	Generic_Logistic_Generator._internal.generifyIcons(item, true)
	return item
end

function Generic_Logistic_Generator._internal.getReplacementLocalisedName(item)
	if item.localised_name then return {"Generic_Logistic_generic_prefix", item.localised_name} end

	local entity = Generic_Logistic_Generator._cache.ENTITY_CACHE[item.place_result]
	if entity then
		if entity.localised_name then
			return {"Generic_Logistic_generic_prefix", entity.localised_name}
		else
			return {"Generic_Logistic_generic_prefix", {"entity-name." .. entity.name}}
		end
	end
	Logger:fatal("Failed to find the localized name for %s", item)
	error("Failed to create generic logistic item for " .. item.name .. ". Please report this error to the mod portal with the factorio-current.log")
end

function Generic_Logistic_Generator._internal.createReplacementEntity(entityName, genericChestName)
	local entity = table.deepcopy(Generic_Logistic_Generator._cache.ENTITY_CACHE[entityName])
	entity.localised_name = {"Generic_Logistic_generic_prefix", entity.localised_name or {"entity-name." .. entity.name}}
	entity.localised_description = {"entity-description." .. entity.name}
	entity.name = Config.MOD_PREFIX .. entity.name
	entity.minable.result = genericChestName
	entity.placeable_by = {
		item = genericChestName,
		count = 1
	}
	
	Generic_Logistic_Generator._internal.generifyIcons(entity, true)
	
	local normalSize = 128
	local hrSize = 256
	Generic_Logistic_Generator._internal.generifySprite(entity, function(oldSpriteSize)
		return {
			filename = "__Generic_Logistic_Chest__/graphics/generic_replacement.png",
			size = normalSize,
			scale = oldSpriteSize / normalSize / 2,
			shift = {oldSpriteSize / 256, oldSpriteSize / 256},
			hr_version = {
				filename = "__Generic_Logistic_Chest__/graphics/generic_replacement_hr.png",
				size = hrSize,
				scale = oldSpriteSize / hrSize / 2,
				shift = {oldSpriteSize / 256, oldSpriteSize / 256}
			}
		}
	end)
	return entity
end

function Generic_Logistic_Generator._internal.choseLatestTech(baseEntityNames)
	local technologies = {}
	for _, entityName in ipairs(baseEntityNames) do
		local item = Generic_Logistic_Generator._cache.ITEM_RESULT_CACHE[entityName]
		local recipe = Generic_Logistic_Generator._cache.RECIPE_RESULT_CACHE[item.name]
		local tech = Generic_Logistic_Generator._cache.TECH_CACHE[recipe.name]
		technologies[tech.name] = tech -- Distinct techs only
	end
	
	local latestTech = nil
	for _, tech in pairs(technologies) do
		if latestTech and tech.prerequisites then
			if latestTech.prerequisites then
				for _, prereq in ipairs(tech.prerequisites) do
					if prereq == latestTech.name then
						latestTech = tech
					end
				end
			else
				-- If a tech doesn't have prerequisites, then it must be at the root of the tech tree anyways
				latestTech = tech
			end
		else
			latestTech = tech
		end
	end
	
	return latestTech
end

function Generic_Logistic_Generator._internal.calculateGenericOrder(baseEntityNames)
	local lowestOrder = nil
	for _, name in ipairs(baseEntityNames) do
		local order = Generic_Logistic_Generator._cache.ITEM_RESULT_CACHE[name].order
		if not lowestOrder or order < lowestOrder then
			lowestOrder = order
		end
	end
	
	if lowestOrder then
		return string.sub(lowestOrder, 1, #lowestOrder - 1)
	else
		return "a[storage]-0" .. Generic_Logistic_Generator._internal.GROUP_COUNT
	end
end

-- Generic Chest Generation
function Generic_Logistic_Generator._internal.createGenericChestItem(entityName, genericChestName, localeName, order)
	local item = table.deepcopy(Generic_Logistic_Generator._cache.ITEM_RESULT_CACHE[entityName])
	item.localised_name = {"Generic_Logistic_generic_prefix", {localeName}}
	item.localised_description = {"Generic_Logistic_generic_logistic_chest_description", {localeName}}
	item.name = genericChestName
	item.order = order
	item.place_result = genericChestName
	
	if item.flags then
		table.insert(item.flags, "primary-place-result")
	else
		item.flags = {"primary-place-result"}
	end
	
	Generic_Logistic_Generator._internal.generifyIcons(item)
	return item
end

function Generic_Logistic_Generator._internal.createGenericChestEntity(entityName, genericChestName, localeName)
	local entity = table.deepcopy(Generic_Logistic_Generator._cache.ENTITY_CACHE[entityName])
	entity.localised_name = {"Generic_Logistic_generic_prefix", {localeName}}
	entity.localised_description = {"Generic_Logistic_generic_logistic_chest_description", {localeName}}
	entity.name = genericChestName
	entity.minable.result = genericChestName
	
	Generic_Logistic_Generator._internal.generifyIcons(entity)
	
	local normalSize = 512
	local hrSize = 1024
	Generic_Logistic_Generator._internal.generifySprite(entity, function(oldSpriteSize)
		return {
			filename = "__Generic_Logistic_Chest__/graphics/generic_chest.png",
			size = normalSize,
			scale = oldSpriteSize / normalSize,
			hr_version = {
				filename = "__Generic_Logistic_Chest__/graphics/generic_chest_hr.png",
				size = hrSize,
				scale = oldSpriteSize / hrSize
			}
		}
	end)
	return entity
end

function Generic_Logistic_Generator._internal.createGenericChestRecipe(entityName, genericChestName, ingredients, tech, order)
	local recipe = table.deepcopy(Generic_Logistic_Generator._cache.RECIPE_RESULT_CACHE[Generic_Logistic_Generator._cache.ITEM_RESULT_CACHE[entityName].name])
	
	recipe.name = genericChestName
	recipe.enabled = false
	recipe.ingredients = ingredients
	recipe.results = nil
	recipe.result = genericChestName
	recipe.result_count = 1
	recipe.order = order
	
	table.insert(tech.effects, {
		type = "unlock-recipe",
		recipe = recipe.name
	})
	
	return recipe
end


-- Cache stuff from data.raw
Generic_Logistic_Generator._cache = {}
function Generic_Logistic_Generator._cache.clear()
	Generic_Logistic_Generator._cache.ENTITY_CACHE = {} -- cached by name
	Generic_Logistic_Generator._cache.ITEM_CACHE = {} -- cached by name
	Generic_Logistic_Generator._cache.ITEM_RESULT_CACHE = {} -- cached by place_result
	Generic_Logistic_Generator._cache.RECIPE_CACHE = {} -- cached by name
	Generic_Logistic_Generator._cache.RECIPE_RESULT_CACHE = {} -- cached by result
	Generic_Logistic_Generator._cache.TECH_CACHE = {} -- cached by result
end
Generic_Logistic_Generator._cache.clear() -- Initialize the caches


function Generic_Logistic_Generator._cache.cacheAllPrototypes()
	Logger:trace("Caching relevant prototypes...")
	local entityNames = {}
	for _, group in pairs(Generic_Logistic_Generator._groups) do
		entityNames[group.generic] = true
		for _, replacement in ipairs(group.replacements) do
			entityNames[replacement] = true
		end
	end

	Logger:trace_block("Caching the following prototypes: %s", entityNames)
	Generic_Logistic_Generator._cache.cacheEntities(entityNames)
	Generic_Logistic_Generator._cache.cacheItems()
	Generic_Logistic_Generator._cache.cacheRecipes()
	Generic_Logistic_Generator._cache.cacheTechnologies()
end


function Generic_Logistic_Generator._cache.cacheEntities(entityNames)
	for name, prototype in pairs(data.raw["logistic-container"]) do
		if entityNames[name] then
			Logger:debug("Caching entity %s", name)
			Generic_Logistic_Generator._cache.ENTITY_CACHE[name] = prototype
		end
	end
end

function Generic_Logistic_Generator._cache.cacheItems()
	for name, item in pairs(data.raw["item"]) do
		local placeResult = item.place_result
		if placeResult and Generic_Logistic_Generator._cache.ENTITY_CACHE[placeResult] then
			Logger:debug("Caching item %s", name)
			Generic_Logistic_Generator._cache.ITEM_CACHE[name] = true
			Generic_Logistic_Generator._cache.ITEM_RESULT_CACHE[placeResult] = item
		end
	end
end

function Generic_Logistic_Generator._cache.cacheRecipes()
	for name, recipe in pairs(data.raw["recipe"]) do
		local result = recipe.result
		if result and Generic_Logistic_Generator._cache.ITEM_CACHE[result] then
			Logger:debug("Caching recipe %s", name)
			Generic_Logistic_Generator._cache.RECIPE_CACHE[name] = true --TODO - make sure this change is still good
			Generic_Logistic_Generator._cache.RECIPE_RESULT_CACHE[result] = recipe
		end
	end
end


function Generic_Logistic_Generator._cache.cacheTechnologies()
	for name, tech in pairs(data.raw["technology"]) do
		if tech.effects then
			for _, effect in ipairs(tech.effects) do
				if effect.type == "unlock-recipe" and Generic_Logistic_Generator._cache.RECIPE_CACHE[effect.recipe] then
					Logger:debug("Caching technology %s", name)
					Generic_Logistic_Generator._cache.TECH_CACHE[effect.recipe] = tech
				end
			end
		end
	end
end
