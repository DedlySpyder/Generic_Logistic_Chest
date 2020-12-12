require("util")

Storage = {}

function Storage.init()
	global.playerUiOpen = global.playerUiOpen or {} -- map or player index -> array of LuaEntity chests
	global.chestData = global.chestData or {} -- map of Util generated key (surface, position, name) -> {ghost=LuaEntity, replacementChestName=String, requestFilters, storageFilter, requestFromBufferToggle}
	
	global.playerChestData = global.playerChestData or {} -- map of player index -> name of the copied chest
	global.playerSelection = global.playerSelection or {} -- map of player index -> name of the selected chest
end

function Storage._getRequestFilters(entity)
	local requestFilters = {}
	for index=1, entity.request_slot_count do
		local itemStack = entity.get_request_slot(index)
		if itemStack then
			table.insert(requestFilters, {index=index, name=itemStack.name, count=itemStack.count})
		end
	end
	return requestFilters
end

function Storage._getStorageFilter(entity)
	if entity.prototype.logistic_mode == "storage" or (entity.name == "entity-ghost" and entity.ghost_prototype and entity.ghost_prototype.logistic_mode == "storage") then
		return entity.storage_filter
	end
end

function Storage._getRequestFromBuffers(entity)
	if entity.prototype.logistic_mode == "requester" or (entity.name == "entity-ghost" and entity.ghost_prototype and entity.ghost_prototype.logistic_mode == "requester") then
		return entity.request_from_buffers
	end
end


Storage.PlayerUiOpen = {}
function Storage.PlayerUiOpen.add(player, entity)
	if entity and entity.valid then
		Util.debugLog("Adding " .. entity.name .. " to " .. player.name .. "'s data")
		local chests = global.playerUiOpen[player.index] or {}
		
		if #chests == 0 or (chests[1] and chests[1].valid and chests[1].name == entity.name) then
			table.insert(chests, entity)
		else
			player.print({"Generic_Logistic_placed_warn_mismatched_chest"})
		end
		global.playerUiOpen[player.index] = chests
	end
end

function Storage.PlayerUiOpen.remove(player)
	Util.debugLog("Removing player data for  " .. player.name)
	global.playerUiOpen[player.index] = nil
end

-- Removes the entity from the first player (as only one should have it linked to them) and compacts the array
-- Returns the matching LuaPLayer if they do not have any chests left
function Storage.PlayerUiOpen.removeChest(entity)
	for playerIndex, chests in pairs(global.playerUiOpen) do
		local oldLength = #chests
		local newChests = Util.Table.filter(chests, function(chest) return chest ~= entity end)
		global.playerUiOpen[playerIndex] = newChests
		
		if #newChests == 0 and oldLength > 0 then
			return game.players[playerIndex]
		end
	end
end

-- Only returns the LuaEntity chest(s) for that player
function Storage.PlayerUiOpen.get(player)
	return global.playerUiOpen[player.index]
end


Storage.ChestData = {}
function Storage.ChestData.add(ghostEntity, replacementChestName, requestFilters, storageFilter, requestFromBufferToggle)
	local key = Util.getEntityDataKey(ghostEntity)
	global.chestData[key] = {ghost=ghostEntity, replacementChestName=replacementChestName, requestFilters=requestFilters, storageFilter=storageFilter, requestFromBufferToggle=requestFromBufferToggle}
end

function Storage.ChestData.addEntity(entity, replacementChestName, nameOverride)
	local requestFilters = Storage._getRequestFilters(entity)
	local storageFilter = Storage._getStorageFilter(entity)
	local requestFromBufferToggle = Storage._getRequestFromBuffers(entity)
	
	local key = Util.getEntityDataKey(entity, nameOverride)
	global.chestData[key] = {ghost=entity, replacementChestName=replacementChestName, requestFilters=requestFilters, storageFilter=storageFilter, requestFromBufferToggle=requestFromBufferToggle}
end

function Storage.ChestData.remove(entity)
	local key = Util.getEntityDataKey(entity)
	Storage.ChestData.removeByKey(key)
end

function Storage.ChestData.removeByKey(key)
	global.chestData[key] = nil
end

function Storage.ChestData.get(entity)
	local key = Util.getEntityDataKey(entity)
	return global.chestData[key], key
end

function Storage.ChestData.purge()
	for key, data in pairs(global.chestData) do
		local ghost = data.ghost
		if not (ghost and ghost.valid) then
			Util.debugLog("Purging chest data for " .. key)
			Storage.ChestData.removeByKey(key)
		end
	end
end


Storage.PlayerCopyData = {}
function Storage.PlayerCopyData.add(player, chestName)
	Util.debugLog("Adding " .. chestName .. " to " .. player.name .. "'s copy data")
	global.playerChestData[player.index] = chestName
end

function Storage.PlayerCopyData.remove(player)
	Util.debugLog("Removing player copy data for  " .. player.name)
	global.playerChestData[player.index] = nil
end

function Storage.PlayerCopyData.get(player)
	return global.playerChestData[player.index]
end


Storage.PlayerSelection = {}
function Storage.PlayerSelection.add(player, chestName)
	global.playerSelection[player.index] = chestName
end

function Storage.PlayerSelection.remove(player)
	global.playerSelection[player.index] = nil
end

function Storage.PlayerSelection.get(player)
	return global.playerSelection[player.index]
end
