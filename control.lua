--Toggles debug mode
debug_mode = false

--Constant for checking for stale data
local check_for_table_removal = 60*60*10

supportedChests = {	"generic-logistic-chest-passive-provider",
					"generic-logistic-chest-active-provider",
					"generic-logistic-chest-storage",
					"generic-logistic-chest-requester",
					"generic-logistic-chest-buffer"}

--Check when an entity is placed
function on_entity_placed(event)
	local entity = event.created_entity
	local player = game.players[event.player_index]
	
	--If it is a generic chest, draw GUI and add it and the player match to the table
	if (entity.name == "generic-logistic-chest") then
		drawSelectionGUI(player)
		global.genericChestPlayerData = doesGenericChestPlayerDataExistOrCreate(global.genericChestPlayerData)
		
		table.insert(global.genericChestPlayerData, {player=player, chest=entity})
		debugLog(#global.genericChestPlayerData)
	end
	
	--Check for a ghost (from blueprints)
	if (entity.name == "entity-ghost") then
		switchGhost(entity)
	end
end

script.on_event(defines.events.on_built_entity, on_entity_placed)

--Check when a robot builds something
function on_robot_built_entity(event)
	local entity = event.created_entity
	
	if (entity.name == "generic-logistic-chest") then
		--This could occur if the player is just building a generic chest without blueprints
		if (global.genericChestChestData ~= nil) then
			for _, chestData in ipairs(global.genericChestChestData) do
				--Have to compare the values (position to position did not work, assuming it is comparing by exact table location in memory)
				if (entity.position.x == chestData.position.x and entity.position.y == chestData.position.y) then
					--Obtain the data needed to make the replacement chest
					local surface = entity.surface
					local force = entity.force
					
					--Destroy the generic chest and make the replacement
					entity.destroy()
					surface.create_entity{name=chestData.replacementChestName, position=chestData.position, force=force, request_filters=chestData.request_filters}
					
					--Remove the entry from the global table
					local newFunction = function (arg) return arg.ghost == chestData.ghost end --Function that returns true or false if the entities match
					global.genericChestChestData = removeFromTable(newFunction, global.genericChestChestData)
					debugLog(#global.genericChestChestData)
					return
				end
			end
		end
	end
end

script.on_event(defines.events.on_robot_built_entity, on_robot_built_entity)

--Check on a GUI click
function on_gui_click(event)
	local elementName = event.element.name
	debugLog(elementName.." clicked")
	
	--Find the button header (for this mod)
	local modSubString = string.sub(elementName, 1, 14)
	debugLog(modSubString)
	
	if (modSubString == "genericChests_") then
		local player = game.players[event.player_index]
		
		--Find the exact button name
		local modButton = string.sub(elementName, 15, #elementName)
		debugLog(modButton)
		
		--Do work depending on the button
		if (modButton == "passiveProvider") then
			switchChest(player, "generic-logistic-chest-passive-provider")
		elseif (modButton == "activeProvider") then
			switchChest(player, "generic-logistic-chest-active-provider")
		elseif (modButton == "storage") then
			switchChest(player, "generic-logistic-chest-storage")
		elseif (modButton == "requester") then
			switchChest(player, "generic-logistic-chest-requester")
		elseif (modButton == "buffer") then
			switchChest(player, "generic-logistic-chest-buffer")
		elseif (modButton == "close") then
			destroySlectionGUI(player)
		end
	end
end

script.on_event(defines.events.on_gui_click, on_gui_click)

--Check on tick (60 per second)
function on_tick()
	--Check every 10 minutes
	if ((game.tick % check_for_table_removal) == 57) then
		global.genericChestChestData = doesGenericChestChestDataExistOrCreate(global.genericChestChestData)
		
		--Remove any entries in the table if the ghost timed out
		for _, chestData in ipairs(global.genericChestChestData) do
			if not chestData.ghost.valid then
				local newFunction = function (arg) return arg.ghost == chestData.ghost end --Function that returns true or false if the entities match
				global.genericChestChestData = removeFromTable(newFunction, global.genericChestChestData)
			end
		end
		debugLog(#global.genericChestChestData)
	end
end

script.on_event(defines.events.on_tick, on_tick)

--Internal Scripts

--GUI Scripts
--Draw the selection GUI
function drawSelectionGUI(player)
	if (player ~= nil) then
		--The frame to hold everything
		local selectionGUI = player.gui.center.add{type="frame", name="genericChestSelectionFrame", direction="vertical", caption={"generic-chest-select-chest"}}
		
		--The flow to hold the buttons
		local selectionButtonFlow = selectionGUI.add{type="flow", direction="horizontal"}
		
		--The selection buttons
		selectionButtonFlow.add{type="sprite-button", name="genericChests_passiveProvider", sprite="item/logistic-chest-passive-provider"}
		selectionButtonFlow.add{type="sprite-button", name="genericChests_activeProvider", sprite="item/logistic-chest-active-provider"}
		selectionButtonFlow.add{type="sprite-button", name="genericChests_storage", sprite="item/logistic-chest-storage"}
		selectionButtonFlow.add{type="sprite-button", name="genericChests_requester", sprite="item/logistic-chest-requester"}
		selectionButtonFlow.add{type="sprite-button", name="genericChests_buffer", sprite="item/logistic-chest-buffer"}
		
		--Close button
		selectionGUI.add{type="button", name="genericChests_close", caption={"generic-chest-close"}}
	end
end

--Destroys the selection GUI
function destroySlectionGUI(player)
	if (player.gui.center.genericChestSelectionFrame ~= nil and player.gui.center.genericChestSelectionFrame.valid) then
		player.gui.center.genericChestSelectionFrame.destroy()
	end
	
	--Remove the playerData from the table
	for _, playerData in pairs(global.genericChestPlayerData) do
		if (playerData.player == player) then
			local newFunction = function (arg) return arg.chest == playerData.chest end --Function that returns true or false if the entities match
			global.genericChestPlayerData = removeFromTable(newFunction, global.genericChestPlayerData)
			debugLog(#global.genericChestPlayerData)
		end
	end
end

--Swaps the ghost of a replacement chest to the generic chest
function switchGhost(ghost)
	for _, chestName in ipairs(supportedChests) do
		if (chestName == ghost.ghost_name) then
			global.genericChestChestData = doesGenericChestChestDataExistOrCreate(global.genericChestChestData)
			
			--Obtain necessary data to make a new ghost
			local surface = ghost.surface
			local position = ghost.position
			local force = ghost.force
			
			--This is to check for requester chests (or similar chests in the future)
			local ghost_name = ghost.ghost_name 
			
			--Requester fitlers table
			local request_filters = {index=nil, name=nil, count=nil}
			
			--Check for requester-like chests (will need to stay up to date on new similar chests)
			if (ghost_name == "generic-logistic-chest-requester") then
				for index=1, 10 do
					local itemStack = ghost.get_request_slot(index)
					if (itemStack ~= nil) then
						table.insert(request_filters, {index=index, name=itemStack.name, count=itemStack.count})
					end
				end
			end
			
			--Destroy the old ghost and create a new one
			ghost.destroy()
			local entity = surface.create_entity{name="entity-ghost", inner_name="generic-logistic-chest", position=position, force=force}
			
			--Insert the new ghost into the table
			table.insert(global.genericChestChestData, {ghost=entity, position=position, replacementChestName=chestName, request_filters=request_filters})
			debugLog(#global.genericChestChestData)
			return
		end
	end
end

--Replaces the generic chest with a replacement
function switchChest(player, chestName)
	for _, playerData in pairs(global.genericChestPlayerData) do
		if (playerData.player == player) then
			--Obtain the position
			local position = playerData.chest.position
			
			--Obtain the old chest's full inventory
			local chestContents = playerData.chest.get_inventory(defines.inventory.chest).get_contents()
			
			--Destroy the old chest and replace it
			playerData.chest.destroy()
			local newChest = player.surface.create_entity{name=chestName, position=position, force=player.force}
			
			--Replace items in the new chest
			for item, count in pairs(chestContents) do
				local itemStack = {name=item, count=count}
				
				--Insert what can be inserted, and spill the rest on the ground
				if (newChest.can_insert(itemStack)) then
					local inserted = newChest.insert(itemStack)
					if (inserted ~= count) then
						itemStack.count = itemStack.count - inserted
						newChest.surface.spill_item_stack(newChest.position, itemStack)
					end
				else
					newChest.surface.spill_item_stack(newChest.position, itemStack)
				end
			end
		end
	end
	
	--Destroy the GUI
	destroySlectionGUI(player)
end

--Initialize global.genericChestPlayerData
function doesGenericChestPlayerDataExistOrCreate(checkTable)
	if checkTable == nil then
		return {player=nil, chest=nil}
	else
		return checkTable
	end
end

--Initialize global.genericChestChestData
function doesGenericChestChestDataExistOrCreate(checkTable)
	if checkTable == nil then
		return {ghost=nil, position=nil, replacementChestName=nil, request_filters=nil}
	else
		return checkTable
	end
end

--Removes an entity from a global table
--Works by adding everything except the old entry to a new table and overwritting the old table
function removeFromTable(func, oldTable)
	if (oldTable == nil) then return nil end
	local newTable = {}
	for _, row in ipairs(oldTable) do
		if not func(row) then table.insert(newTable, row) end
	end
	return newTable
end

--Debug messages
function debugLog(message)
	if debug_mode then
		game.player.print(message)
	end
end 