require("scripts.actions")
require("scripts.chest_groups")
require("scripts.migrations")
require("scripts.storage")
require("scripts.ui")
require("scripts.util")



script.on_init(Storage.init)

script.on_configuration_changed(Migrations.handle)



-- ~~ Events ~~ --

function on_entity_placed(event)
	local entity = event.created_entity
	local player = game.players[event.player_index]
	
	-- If it is a generic chest, draw GUI and add it and the player match to the table
	local replacements = ChestGroups.getReplacementsFromGeneric(entity.name)
	if replacements then
		Storage.PlayerUiOpen.add(player, entity)
		UI.Selection.draw(player, replacements)
	end
	
	-- Check for a ghost (from blueprints)
	if entity.name == "entity-ghost" then
		Actions.switchGhost(entity)
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

function on_robot_built_entity(event)
	local entity = event.created_entity
	
	local replacements = ChestGroups.getReplacementsFromGeneric(entity.name)
	if replacements then
		local chestData = Storage.ChestData.get(entity)
		if chestData then
			local storageKey = Util.getEntityDataKey(entity)
			Actions.switchChest(entity, chestData.replacementChestName, chestData.requestFilters, chestData.storageFilter)
			Storage.ChestData.removeByKey(storageKey)
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
					if not Actions.switchChest(playerChest, replacementName) then
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

script.on_nth_tick(settings.global["Generic_Logistic_chest_data_purge_period"].value * 60 * 60, Storage.ChestData.purge)
