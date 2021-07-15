local Logger = require("__DedLib__/modules/logger").create()

require("chest_groups")
local Config = require("config")
require("storage")


Actions = {}

-- Returns the new entity
-- This overloaded version works for fastReplace and ghost chest data
function Actions.switchChestFromChestData(entity, chestData, player)
	Logger:trace("Switching chest from chest data: %s", chestData)
	return Actions.switchChest(entity, chestData.replacementChestName, player, chestData.requestFilters, chestData.storageFilter, chestData.requestFromBufferToggle)
end

function Actions.switchChest(entity, replacementName, player, requestFilters, storageFilter, requestFromBufferToggle)
	Logger:trace("Switching chest for <%s> <%s> <%s> <%s> <%s> <%s>", entity, replacementName, player, requestFilters, storageFilter, requestFromBufferToggle)
	if entity and entity.valid then
		local entityName = entity.name
		local surface = entity.surface
		local position = entity.position
		local force = entity.force
		Logger:info("Switching chest %s at (%s,%s) on %s with %s", entityName, position.x, position.y, surface, replacementName)

		-- Fast replace can handle moving items and spilling excess, but it will also spill the generic chest, and does so last, so finding it could be hard to judge
		local tempChest = surface.create_entity{name=Config.MOD_PREFIX .. "temp", position=position, force=force}
		Actions.swapInventories(entity, tempChest)
		
		local newChest
		if surface.can_fast_replace{name=replacementName, position=position, force=force} then
			Logger:debug("Fast replacing chest")
			newChest = surface.create_entity{
				name=replacementName,
				position=position,
				force=force,
				player=player,
				request_filters=requestFilters,
				fast_replace=true,
				spill=false,
				create_build_effect_smoke=false
			}
			
			-- Fast replacing with a player adds a new chest to their inventory
			if player then
				Logger:debug("Player is fast replacing, removing generic...")
				local cursor = player.cursor_stack
				if cursor and cursor.valid_for_read and cursor.name == entityName then
					Logger:info("Removing item from %s's cursor <%s>", player.name, cursor)
					cursor.count = cursor.count - 1
				else
					local generic = ChestGroups.getGenericFromReplacement(replacementName) or replacementName
					Logger:info("Removing %s from %s's inventory", generic, player.name)
					player.get_main_inventory().remove{name=generic, count=1}
				end
			end
			
			-- The inventory is going to be manually transferred, so it can be spilled without duplicating the generic chest
			newChest.get_inventory(defines.inventory.chest).clear()
		else
			Logger:info("Unable to fast replace chest, attempting to do it manually...")
			-- If fast replace doesn't work (maybe a mod chest doesn't have fast replace available?) then manually do what I can
			requestFilters = requestFilters or Storage._getRequestFilters(entity)
			storageFilter = storageFilter or Storage._getStorageFilter(entity)
			requestFromBufferToggle = requestFromBufferToggle or Storage._getRequestFromBuffers(entity)
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
		
		if requestFromBufferToggle and newChest.prototype.logistic_mode == "requester" then
			newChest.request_from_buffers = requestFromBufferToggle
		end
		
		return newChest
	end
end

function Actions.swapInventories(sourceChest, destinationChest)
	Logger:trace("Attempting to swap inventories from <%s> to <%s>", sourceChest, destinationChest)
	local inventory = sourceChest.get_inventory(defines.inventory.chest)
	
	-- This is super heavy, and MOST of the time this is unneeded
	if inventory.is_empty() then
		Logger:debug("Inventory of %s is empty, skipping inventory swap...", sourceChest)
		return
	end

	Logger:info("Inventory of %s is non-empty, so transferring items...", sourceChest)
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
