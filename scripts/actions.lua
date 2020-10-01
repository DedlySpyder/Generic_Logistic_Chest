require("chest_groups")
require("storage")
require("util")

local REPLACEMENT_CHEST_MAPPING = ChestGroups.getReplacementToGenericMapping()

Actions = {}

function Actions.switchGhost(ghostEntity)
	local oldGhostName = ghostEntity.ghost_name
	local genericChestName = REPLACEMENT_CHEST_MAPPING[oldGhostName]
	if genericChestName then
		Util.debugLog("Swapping ghost of " .. oldGhostName .. " to " .. genericChestName)
		
		local surface = ghost.surface
		local position = ghost.position
		local force = ghost.force
		
		local requestFilters = {}
		
		--if (ghost_name == "generic-logistic-chest-requester") then -- TODO might need something for this
		for index=1, ghost.request_slot_count do
			local itemStack = ghost.get_request_slot(index)
			if itemStack then
				table.insert(requestFilters, {index=index, name=itemStack.name, count=itemStack.count})
			end
		end
		--end
		
		-- Destroy the old ghost and create a new one
		ghost.destroy()
		
		local newGhost = surface.create_entity{name="entity-ghost", inner_name=genericChestName, position=position, force=force}
		Storage.ChestData.add(newGhost, oldGhostName, requestFilters)
	end
end

-- Returns the new entity
function Actions.switchChest(entity, replacementName, requestFilters)
	if entity and entity.valid then
		local surface = entity.surface
		local position = entity.position
		local force = entity.force
		
		Util.debugLog("Switching chest " .. entity.name .. " at (" .. position.x .. "," .. position.y .. ") on " .. surface.name .. " with " .. replacementName)
		
		-- Save the contents before destorying the chest
		local chestContents = entity.get_inventory(defines.inventory.chest).get_contents()
		entity.destroy()
		
		local newChest = surface.create_entity{name=replacementName, position=position, force=force, request_filters=requestFilters}
		for item, count in pairs(chestContents) do
			local itemStack = {name=item, count=count}
			
			-- Insert what can be inserted, and spill the rest on the ground
			if newChest.can_insert(itemStack) then
				local inserted = newChest.insert(itemStack)
				if inserted < count then
					itemStack.count = itemStack.count - inserted
					newChest.surface.spill_item_stack(newChest.position, itemStack)
				end
			else
				newChest.surface.spill_item_stack(newChest.position, itemStack)
			end
		end
		
		return newChest
	end
end
