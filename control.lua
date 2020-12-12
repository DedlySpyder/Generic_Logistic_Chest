require("scripts.actions")
require("scripts.chest_groups")
require("scripts.migrations")
require("scripts.storage")
require("scripts.ui")
require("scripts.util")



script.on_init(Storage.init)

script.on_configuration_changed(Migrations.handle)



-- ~~ Events ~~ --

function on_pre_entity_placed(event)
	local player = game.players[event.player_index]
	
	-- Shift building is covered by upgrading events
	if not event.shift_build then
		local entities = player.surface.find_entities_filtered{position=event.position, force=force}
		if #entities > 0 then
			for _, entity in ipairs(entities) do
				local name = entity.name
				local fullGroup = ChestGroups.getFullGroupWithOriginals(name)
				if fullGroup then
					local replacementName = fullGroup[name]
					Util.debugLog("Saving " .. replacementName .." entity on pre placed for " .. player.name)
					Storage.PlayerFastReplace.add(player, replacementName, entity)
				end
				return
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
		if fastReplaceChestData and fastReplaceChestData.replacementChestName  ~= entityName then
			Actions.switchChestFromChestData(entity, fastReplaceChestData, player)
			Storage.PlayerFastReplace.remove(player)
		else
			Storage.PlayerUiOpen.add(player, entity)
			UI.Selection.draw(player, replacements)
		end
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
	end
	
	-- Check for a ghost (from blueprints)
	if entityName == "entity-ghost" then
		if not Actions.switchGhost(entity) then
			-- If the normal switch didn't happen, then see if a generic was placed on top of a replacement, this likely means that the player is undoing the selection UI action
			local replacements = ChestGroups.getReplacementsFromGeneric(entity.ghost_name)
			if replacements then
				local force = entity.force
				local position = entity.position
				local foundReplacements = entity.surface.find_entities_filtered{position=position, name=replacements, force=force}
				
				if #foundReplacements > 0 then
					local replacement = foundReplacements[1]
					Util.debugLog("Manually marking " .. replacement.name .. " at " .. serpent.line(position) .. " for deconstruction")
					replacement.order_deconstruction(force, player)
				end
			end
		end
	end
end

script.on_event(defines.events.on_built_entity, on_entity_placed)

function on_marked_for_upgrade(event)
	local entity  = event.entity
	local targetName = event.target.name
	
	if ChestGroups.getFullGroup(targetName) then
		Actions.switchUpgrade(entity, targetName)
	end
end

script.on_event(defines.events.on_marked_for_upgrade, on_marked_for_upgrade)

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

function on_robot_built_entity(event)
	local entity = event.created_entity
	
	local replacements = ChestGroups.getReplacementsFromGeneric(entity.name)
	if replacements then
		local chestData, key = Storage.ChestData.get(entity)
		if chestData then
			Actions.switchChestFromChestData(entity, chestData)
			Storage.ChestData.removeByKey(key)
		end
	end
end

script.on_event(defines.events.on_robot_built_entity, on_robot_built_entity)

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
			Storage.PlayerUiOpen.add(player, entity)
			UI.Selection.draw(player, replacements)
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
				Actions.switchChest(target, sourceName, player)
			end
		end
	end
end

script.on_event(defines.events.on_pre_entity_settings_pasted, on_player_pasted)

function build_on_select_scroll(scrollDistance)
	return function(event)
		local player = game.players[event.player_index]
		local cursorStack = player.cursor_stack
		if cursorStack and cursorStack.valid and cursorStack.valid_for_read then
			local cursorChestName = cursorStack.name
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
					Util.debugLog("Scrolling chest from " .. cursorChestName .. " to " .. newChestName .. " for " .. player.name)
					cursorStack.set_stack({name = newChestName, count = cursorStack.count})
					Storage.PlayerSelection.add(player, newChestName)
				else
					Util.debugLog("ERROR: Did not find chest " .. cursorChestName .. " in chestGroup " .. serpent.line(chestGroup))
				end
			end
		end
	end
end

script.on_event("Generic_Logistic_select_scroll_up", build_on_select_scroll(1))
script.on_event("Generic_Logistic_select_scroll_down", build_on_select_scroll(-1))


script.on_nth_tick(settings.global["Generic_Logistic_chest_data_purge_period"].value * 60 * 60, Storage.ChestData.purge)
