require("scripts.actions")
require("scripts.chest_groups")
require("scripts.config")
require("scripts.migrations")
require("scripts.storage")
require("scripts.ui")
require("scripts.util")



script.on_init(Storage.init)

script.on_configuration_changed(Migrations.handle)

-- ~~ Events ~~ --

function on_pre_entity_placed(event)
	local player = game.players[event.player_index]
	local position = event.position
	
	-- Shift building is covered by upgrading events
	if not event.shift_build then
		local entities = player.surface.find_entities_filtered{position=position, force=force}
		if #entities > 0 then
			for _, entity in ipairs(entities) do
				local name = entity.name
				local fullGroup = ChestGroups.getFullGroupWithOriginals(name)
				if fullGroup then
					local replacementName = fullGroup[name]
					local lastEvent = Storage.PlayerFastReplaceEvents.get(player, position)
					
					-- Exit fast replace if the old chest is a replacement, this allows for the generic to actually get built and the UI drawn
					-- Drag building triggers this constantly, so needed to introduce a slight lag to it. Otherwise, the normal chest gets replaced then the next tick the replacement turns into a generic
					if replacementName == name and game.tick > lastEvent + Config.PLAYER_FAST_REPLACE_LAG then return end
					
					Util.debugLog("Saving " .. replacementName .." entity on pre placed for " .. player.name)
					Storage.PlayerFastReplace.add(player, replacementName, entity)
					return
				end
			end
		end
	end
end

script.on_event(defines.events.on_pre_build, on_pre_entity_placed)

function on_entity_placed(event)
	local entity = event.created_entity
	local entityName = entity.name
	local player = game.players[event.player_index]
	
	-- If it is a generic chest, draw GUI and add it and the player match to the table
	local replacements = ChestGroups.getReplacementsFromGeneric(entityName)
	if replacements then
		local fastReplaceChestData = Storage.PlayerFastReplace.get(player)
		if fastReplaceChestData and fastReplaceChestData.replacementChestName ~= entityName then
			Storage.PlayerFastReplaceEvents.add(player, entity.position)
			Actions.switchChestFromChestData(entity, fastReplaceChestData, player)
			Storage.PlayerFastReplace.remove(player)
		else
			UI.Selection.draw(player, replacements, entity)
		end
		return
	end
	
	-- If the player just placed a replacement chest, and their cursor is empty, try to fill it with generics from their inventory
	local generic = ChestGroups.getGenericFromReplacement(entityName)
	if generic and Util.Player.isCursorEmpty(player) then
		local selection = Storage.PlayerSelection.get(player)
		if selection then
			local chestStack = player.get_main_inventory().find_item_stack(generic)
			if chestStack then
				Util.debugLog("Refilling cursor for " .. player.name .. " with " .. selection)
				chestStack.set_stack({name = selection, count = chestStack.count})
				player.cursor_stack.swap_stack(chestStack)
			end
		end
		return
	end
	
	-- Check for a ghost (from blueprints)
	if entityName == "entity-ghost" then
		local fullGroupList = ChestGroups.getFullGroupWithOriginalsList(entity.ghost_name)
		if fullGroupList then
			local force = entity.force
			local position = entity.position
			local foundReplacements = entity.surface.find_entities_filtered{position=position, name=fullGroupList, force=force}
			
			-- Any orignal/generic/replacement chest under the ghost should be deconstructed, to handle undo scenarios
			for _, replacement in ipairs(foundReplacements) do
				Util.debugLog("Manually marking " .. replacement.name .. " at " .. serpent.line(position) .. " for deconstruction")
				replacement.order_deconstruction(force, player)
			end
			return
		end
	end
end

script.on_event(defines.events.on_built_entity, on_entity_placed)

function on_entity_destroyed(event)
	local entity = event.entity
	
	-- If a generic chest is destroyed, check if a player was trying to change it
	local replacements = ChestGroups.getReplacementsFromGeneric(entity.name)
	if replacements then
		local player = Storage.PlayerUiOpen.removeChest(entity)
		if player then
			UI.Selection.destroy(player)
		end
	end
end

function build_script_raised_filters()
	local filters = {}
	for generic, _ in pairs(ChestGroups.getGenericToReplacementMapping()) do
		table.insert(filters, {filter="name", name=generic})
	end
	return filters
end

script.on_event(defines.events.on_pre_player_mined_item, on_entity_destroyed)
script.on_event(defines.events.on_robot_pre_mined, on_entity_destroyed)
script.on_event(defines.events.script_raised_destroy, on_entity_destroyed, build_script_raised_filters())
script.on_event(defines.events.on_entity_died, on_entity_destroyed)

function on_gui_click(event)
	local elementName = event.element.name
	Util.debugLog(elementName .. " clicked")
	
	-- Find the UI prefix (for this mod)
	local modSubString = string.sub(elementName, 1, #Util.MOD_PREFIX)
	if modSubString == Util.MOD_PREFIX then
		local player = game.players[event.player_index]
		
		if elementName == UI.Selection.CLOSE_BUTTON then
			UI.Selection.destroy(player)
			Storage.PlayerUiOpen.remove(player)
			
		else
			local buttonSubString = string.sub(elementName, #Util.MOD_PREFIX + 1, #UI.Selection.BUTTON_PREFIX)
			if buttonSubString == UI.Selection.BUTTON_PREFIX_DIFF then
				local replacementName = string.sub(elementName, #UI.Selection.BUTTON_PREFIX + 1, #elementName)
				
				local playerChests = Storage.PlayerUiOpen.get(player)
				local failedCount = 0
				for _, playerChest in ipairs(playerChests) do
					if not Actions.switchChest(playerChest, replacementName, player) then
						failedCount = failedCount + 1
					end
				end
				
				if failedCount > 0 then
					player.print({"Generic_Logistic_select_error_chest_not_valid", tostring(failedCount)})
				end
				
				UI.Selection.destroy(player)
				Storage.PlayerUiOpen.remove(player)
			end
		end
	end
end

script.on_event(defines.events.on_gui_click, on_gui_click)

function on_player_cursor_stack_changed(event)
	local player = game.players[event.player_index]
	if Util.Player.isCursorEmpty(player) then
		local selection = Storage.PlayerSelection.get(player)
		if selection then
			local chestStack = player.get_main_inventory().find_item_stack(selection)
			if chestStack then
				local chestStackName = chestStack.name
				local generic = ChestGroups.getGenericFromReplacement(chestStackName)
				if generic then
					Util.debugLog("Resetting " .. chestStackName .. " to " .. generic .. " for " .. player.name)
					chestStack.set_stack({name = generic, count = chestStack.count})
					Storage.PlayerSelection.remove(player)
				end
			end
		end
	end
end

script.on_event(defines.events.on_player_cursor_stack_changed, on_player_cursor_stack_changed)

function on_player_copied(event)
	local player = game.players[event.player_index]
	local entity = player.selected
	
	if entity then
		local entityName = entity.name
		local nameMapping = ChestGroups.getFullGroupWithOriginals(entityName)
		if nameMapping then
			local sourceName = nameMapping[entityName]
			Util.debugLog("Copying chest " .. entityName .. " as " .. sourceName .. " for " .. player.name)
			Storage.PlayerCopyData.add(player, sourceName)
		else
			Storage.PlayerCopyData.remove(player)
		end
	end
end

script.on_event("Generic_Logistic_copy_chest", on_player_copied)

function on_custom_build(event)
	local player = game.players[event.player_index]
	local entity = player.selected
	
	-- If a player attempts to build a generic on top of a same generic, the game does not fire an event (because nothing happens)
	-- So, this will open the UI for them
	if entity then
		local entityName = entity.name
		local replacements = ChestGroups.getReplacementsFromGeneric(entityName)
		local cursor = player.cursor_stack
		if replacements and cursor and cursor.valid_for_read and cursor.name == entityName then
			UI.Selection.draw(player, replacements, entity)
		end
	end
end

script.on_event("Generic_Logistic_build", on_custom_build)

function on_player_pasted(event)
	local player = game.players[event.player_index]
	local target = event.destination
	
	if target then
		local chestGroup = ChestGroups.getFullGroup(target.name)
		if chestGroup then
			local targetName = target.name
			Util.debugLog("Target (" .. targetName .. ") of paste by " .. player.name .. " is a generic chest")
			
			local sourceName = Storage.PlayerCopyData.get(player)
			if chestGroup[sourceName] then
				if targetName == sourceName then
					Util.debugLog("Source chest is the same as target chest, skipping paste")
					return
				end
				
				Util.debugLog("Pasting chest " .. sourceName .. " onto chest " .. target.name)
				local newChest = Actions.switchChest(target, sourceName, player)
				
				local replacements = ChestGroups.getReplacementsFromGeneric(sourceName)
				if replacements and newChest then
					UI.Selection.draw(player, replacements, newChest)
				end
			end
		end
	end
end

script.on_event(defines.events.on_pre_entity_settings_pasted, on_player_pasted)

function on_player_pipette(event)
	local player = game.players[event.player_index]
	local replacements = ChestGroups.getReplacementsFromGeneric(event.item.name)
	
	if replacements then
		local selectedEntity = player.selected
		if selectedEntity then
			local replacementName = selectedEntity.name
			if replacementName == "entity-ghost" then
				replacementName = selectedEntity.ghost_name
			end
			
			local cursorStack = player.cursor_stack
			if cursorStack and cursorStack.valid_for_read then
				-- Generic in the player's cursor from pipette
				cursorStack.set_stack({name = replacementName, count = cursorStack.count})
			else
				-- Generic ghost in the player's cursor
				player.cursor_ghost = replacementName
			end
			Storage.PlayerSelection.add(player, replacementName)
		end
	end
end

script.on_event(defines.events.on_player_pipette, on_player_pipette)

function build_on_select_scroll(scrollDistance)
	return function(event)
		local player = game.players[event.player_index]
		local cursorStack = player.cursor_stack
		
		local cursorChestName, count = nil, nil
		local isGhost = false
		if cursorStack and cursorStack.valid and cursorStack.valid_for_read then
			cursorChestName = cursorStack.name
			count = cursorStack.count
		else
			local ghost = player.cursor_ghost
			if ghost then
				cursorChestName = ghost.name
				isGhost = true
			end
		end
		
		if cursorChestName then
			local chestGroup = ChestGroups.getFullGroupList(cursorChestName)
			if chestGroup then
				local groupCount = #chestGroup
				local position = 0
				
				for i = 1, groupCount do
					if chestGroup[i] == cursorChestName then
						position = i
						break
					end
				end
				
				if position > 0 then
					local newPosition = position + scrollDistance
					
					-- Loop around the group
					if newPosition < 1 then
						newPosition = groupCount
					elseif newPosition > groupCount then
						newPosition = 1
					end
					
					local newChestName = chestGroup[newPosition]
					if isGhost then
						Util.debugLog("Scrolling ghost chest from " .. cursorChestName .. " to " .. newChestName .. " for " .. player.name)
						player.cursor_ghost = newChestName
					
					else
						Util.debugLog("Scrolling chest from " .. cursorChestName .. " to " .. newChestName .. " for " .. player.name)
						cursorStack.set_stack({name = newChestName, count = count})
						Storage.PlayerSelection.add(player, newChestName)
					end
				else
					Util.debugLog("ERROR: Did not find chest " .. cursorChestName .. " in chestGroup " .. serpent.line(chestGroup))
				end
			end
		end
	end
end

script.on_event("Generic_Logistic_select_scroll_up", build_on_select_scroll(1))
script.on_event("Generic_Logistic_select_scroll_down", build_on_select_scroll(-1))

script.on_nth_tick(Config.DATA_PURGE_PERIOD * 60 * 60, Storage.purge)
