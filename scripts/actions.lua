require("chest_groups")
require("storage")
require("util")


Actions = {}

function Actions._getRequestFilters(entity)
	local requestFilters = {}
	for index=1, entity.request_slot_count do
		local itemStack = entity.get_request_slot(index)
		if itemStack then
			table.insert(requestFilters, {index=index, name=itemStack.name, count=itemStack.count})
		end
	end
	return requestFilters
end

function Actions._getStorageFilter(entity)
	if entity.prototype.logistic_mode == "storage" or (entity.name == "entity-ghost" and entity.ghost_prototype and entity.ghost_prototype.logistic_mode == "storage") then
		return entity.storage_filter
	end
end

function Actions.switchGhost(ghostEntity)
	local oldGhostName = ghostEntity.ghost_name
	local genericChestName = ChestGroups.getGenericFromReplacement(oldGhostName)
	if genericChestName then
		Util.debugLog("Swapping ghost of " .. oldGhostName .. " to " .. genericChestName)
		
		local surface = ghostEntity.surface
		local position = ghostEntity.position
		local force = ghostEntity.force
		
		-- Save logistic filter data for when the replacement is built
		local storageFilter = Actions._getStorageFilter(ghostEntity)
		local requestFilters = Actions._getRequestFilters(ghostEntity)
		
		-- Save the circuit connections for the new ghost
		local connectionDefinitions = ghostEntity.circuit_connection_definitions
		
		-- Destroy the old ghost and create a new one
		ghostEntity.destroy()
		
		local newGhost = surface.create_entity{name="entity-ghost", inner_name=genericChestName, position=position, force=force, fast_replace=true}
		
		for _, connectionDefinition in pairs(connectionDefinitions) do
			newGhost.connect_neighbour(connectionDefinition)
		end
		
		Storage.ChestData.add(newGhost, oldGhostName, requestFilters, storageFilter)
	end
end

-- Returns the new entity
function Actions.switchChest(entity, replacementName, requestFilters, storageFilter)
	if entity and entity.valid then
		local surface = entity.surface
		local position = entity.position
		local force = entity.force
		Util.debugLog("Switching chest " .. entity.name .. " at (" .. position.x .. "," .. position.y .. ") on " .. surface.name .. " with " .. replacementName)
		
		-- Fast replace can handle moving items and spilling excess, but it will also spill the generic chest, and does so last, so finding it could be hard to judge
		local tempChest = surface.create_entity{name=Util.MOD_PREFIX .. "temp", position=position, force=force}
		Actions.swapInventories(entity, tempChest)
		
		local newChest
		if surface.can_fast_replace{name=replacementName, position=position, force=force} then
			newChest = surface.create_entity{
				name=replacementName,
				position=position,
				force=force,
				request_filters=requestFilters,
				fast_replace=true,
				spill=false,
				create_build_effect_smoke=false
			}
		else
			-- If fast replace doesn't work (maybe a mod chest doesn't have fast replace available?) then manually do what I can
			requestFilters = requestFilters or Actions._getRequestFilters(entity)
			storageFilter = storageFilter or Actions._getStorageFilter(entity)
			local connectionDefs = entity.circuit_connection_definitions
			
			entity.destroy()
			newChest = surface.create_entity{name=replacementName, position=position, force=force, request_filters=requestFilters}
			
			for _, def in ipairs(connectionDefs) do
				newChest.connect_neighbour(def)
			end
		end
		
		Actions.swapInventories(tempChest, newChest)
		tempChest.destroy()
		
		if storageFilter and newChest.prototype.logistic_mode == "storage" then
			newChest.storage_filter = storageFilter
		end
		
		return newChest
	end
end

function Actions.swapInventories(sourceChest, destinationChest)
	local inventory = sourceChest.get_inventory(defines.inventory.chest)
	local chestContents = {}
	for i=1, #inventory do
		chestContents[i] = inventory[i]
	end
	
	for _, itemStack in pairs(chestContents) do
		-- Insert what can be inserted, and spill the rest on the ground
		if destinationChest.can_insert(itemStack) then
			local inserted = destinationChest.insert(itemStack)
			if inserted < itemStack.count then
				itemStack.count = itemStack.count - inserted
				destinationChest.surface.spill_item_stack(destinationChest.position, itemStack)
			end
		else
			destinationChest.surface.spill_item_stack(destinationChest.position, itemStack)
		end
	end
end
