require("scripts.util")

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
Generic_Logistic_Generator.addGenericGroup = function(data)
	Generic_Logistic_Generator._groups[data.name] = data
end

-- This should be called after all groups are added
-- Though it will clear the current groups in case it is used multiple times, it will cause longer game load times
Generic_Logistic_Generator.generate = function()
	Generic_Logistic_Generator._cache.cacheAllPrototypes()
	
	local newPrototypes = {}
	for name, data in pairs(Generic_Logistic_Generator._groups) do
		Util.debugLog("Generating prototypes for generic group " .. name)
		
		local genericName = Util.MOD_PREFIX .. name
		local localeName = data.localeName
		local genericEntityBase = data.generic
		
		Util.debugLog("Generic chest name: " .. genericName)
		table.insert(newPrototypes, Generic_Logistic_Generator._internal.createGenericChestItem(genericEntityBase, genericName, localeName))
		table.insert(newPrototypes, Generic_Logistic_Generator._internal.createGenericChestEntity(genericEntityBase, genericName, localeName))
		table.insert(newPrototypes, Generic_Logistic_Generator._internal.createGenericChestRecipe(genericEntityBase, genericName, data.ingredients))
		
		for _, replacement in ipairs(data.replacements) do
			Util.debugLog("Generating replacement prototypes for " .. replacement)
			table.insert(newPrototypes, Generic_Logistic_Generator._internal.createReplacementItem(replacement))
			table.insert(newPrototypes, Generic_Logistic_Generator._internal.createReplacementEntity(replacement, genericName))
		end
		
		Generic_Logistic_Generator._internal.GROUP_COUNT = Generic_Logistic_Generator._internal.GROUP_COUNT + 1
	end
	data:extend(newPrototypes)
	
	Generic_Logistic_Generator._groups = {}
	Generic_Logistic_Generator._cache.clear()
end




Generic_Logistic_Generator._internal = {}
Generic_Logistic_Generator._internal.GROUP_COUNT = 0

Generic_Logistic_Generator._internal.generifyIcons = function(item, isReplacement)
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
Generic_Logistic_Generator._internal.generifySprite = function(entity, newLayerFunc)
	local sprite = entity.animation or entity.picture
	if not sprite.layers then
		sprite = {layers={sprite}}
	end
	
	local firstLayer = sprite.layers[1]
	local oldSpriteSize = Util.mathMin({firstLayer.height, firstLayer.width, firstLayer.size})
	table.insert(sprite.layers, newLayerFunc(oldSpriteSize))
	
	if entity.animation then
		local repeatCount = firstLayer.frame_count or firstLayer.repeat_count
		sprite.layers[#sprite.layers].repeat_count = repeatCount
		sprite.layers[#sprite.layers].hr_version.repeat_count = repeatCount
		entity.animation = sprite
	else
		-- The sprite was a picture
		entity.picture = sprite
	end
end

-- Replacement Chest Generation
Generic_Logistic_Generator._internal.createReplacementItem = function(entityName)
	local item =  table.deepcopy(Generic_Logistic_Generator._cache.ITEM_RESULT_CACHE[entityName])
	item.localised_name = {"Generic_Logistic_generic_prefix", {"item-name." .. item.name}}
	item.localised_description = {"item-description." .. item.name}
	item.name = Util.MOD_PREFIX .. item.name
	item.flags = {"hidden"}
	item.place_result = Util.MOD_PREFIX .. item.place_result -- This should never exist as an item, but just in case
	
	Generic_Logistic_Generator._internal.generifyIcons(item, true)
	return item
end

Generic_Logistic_Generator._internal.createReplacementEntity = function(entityName, genericChestName)
	local entity = table.deepcopy(Generic_Logistic_Generator._cache.ENTITY_CACHE[entityName])
	entity.localised_name = {"Generic_Logistic_generic_prefix", {"entity-name." .. entity.name}}
	entity.localised_description = {"entity-description." .. entity.name}
	entity.name = Util.MOD_PREFIX .. entity.name
	entity.minable.result = genericChestName
	
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

-- Generic Chest Generation
Generic_Logistic_Generator._internal.createGenericChestItem = function(entityName, genericChestName, localeName)
	local item = table.deepcopy(Generic_Logistic_Generator._cache.ITEM_RESULT_CACHE[entityName])
	item.localised_name = {"Generic_Logistic_generic_prefix", {localeName}}
	item.localised_description = {"Generic_Logistic_generic_logistic_chest_description", {localeName}}
	item.name = genericChestName
	--item.flags = nil -- TODO -- ??
	item.order = "b[storage]-c" .. Generic_Logistic_Generator._internal.GROUP_COUNT
	item.place_result = genericChestName
	
	Generic_Logistic_Generator._internal.generifyIcons(item)
	return item
end

Generic_Logistic_Generator._internal.createGenericChestEntity = function(entityName, genericChestName, localeName)
	local entity = table.deepcopy(Generic_Logistic_Generator._cache.ENTITY_CACHE[entityName])
	entity.localised_name = {"Generic_Logistic_generic_prefix", {localeName}}
	entity.localised_description = {"Generic_Logistic_generic_logistic_chest_description", {localeName}}
	entity.name = genericChestName
	entity.minable.result = genericChestName
	entity.logistic_slots_count = nil
	entity.logistic_mode = "passive-provider"
	
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

Generic_Logistic_Generator._internal.createGenericChestRecipe = function(entityName, genericChestName, ingredients)
	local recipe = table.deepcopy(Generic_Logistic_Generator._cache.RECIPE_RESULT_CACHE[Generic_Logistic_Generator._cache.ITEM_RESULT_CACHE[entityName].name])
	recipe.name = genericChestName
	recipe.enabled = false
	recipe.ingredients = ingredients
	recipe.results = nil
	recipe.result = genericChestName
	recipe.result_count = 1
	
	table.insert(data.raw["technology"]["logistic-system"].effects, {
		type = "unlock-recipe",
		recipe = recipe.name
	})
	
	return recipe
end


-- Cache stuff from data.raw
Generic_Logistic_Generator._cache = {}
Generic_Logistic_Generator._cache.clear = function ()
	Generic_Logistic_Generator._cache.ENTITY_CACHE = {} -- cached by name
	Generic_Logistic_Generator._cache.ITEM_CACHE = {} -- cached by name
	Generic_Logistic_Generator._cache.ITEM_RESULT_CACHE = {} -- cached by place_result
	Generic_Logistic_Generator._cache.RECIPE_RESULT_CACHE = {} -- cached by result
end
Generic_Logistic_Generator._cache.clear() -- Initialize the caches


Generic_Logistic_Generator._cache.cacheAllPrototypes = function()
	local entityNames = {}
	for _, group in pairs(Generic_Logistic_Generator._groups) do
		entityNames[group.generic] = true
		for _, replacement in ipairs(group.replacements) do
			entityNames[replacement] = true
		end
	end
	
	Util.debugLog("Caching the following prototypes:")
	Util.debugLog(serpent.block(entityNames)) 
	Generic_Logistic_Generator._cache.cacheEntities(entityNames)
	Generic_Logistic_Generator._cache.cacheItems()
	Generic_Logistic_Generator._cache.cacheRecipes()
end


Generic_Logistic_Generator._cache.cacheEntities = function(entityNames)
	for name, prototype in pairs(data.raw["logistic-container"]) do
		if entityNames[name] then
			Util.debugLog("Caching entity " .. name)
			Generic_Logistic_Generator._cache.ENTITY_CACHE[name] = prototype
		end
	end
end

Generic_Logistic_Generator._cache.cacheItems = function()
	for _, item in pairs(data.raw["item"]) do
		local placeResult = item.place_result
		if placeResult and Generic_Logistic_Generator._cache.ENTITY_CACHE[placeResult] then
			Util.debugLog("Caching item " .. item.name)
			Generic_Logistic_Generator._cache.ITEM_CACHE[item.name] = true
			Generic_Logistic_Generator._cache.ITEM_RESULT_CACHE[placeResult] = item
		end
	end
end

Generic_Logistic_Generator._cache.cacheRecipes = function()
	for _, recipe in pairs(data.raw["recipe"]) do
		local result = recipe.result
		if result and Generic_Logistic_Generator._cache.ITEM_CACHE[result] then
			Util.debugLog("Caching recipe " .. recipe.name)
			Generic_Logistic_Generator._cache.RECIPE_RESULT_CACHE[result] = recipe
		end
	end
end


