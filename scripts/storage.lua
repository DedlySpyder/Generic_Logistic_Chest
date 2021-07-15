local LoggerLib = require("__DedLib__/modules/logger")
local Logger = LoggerLib.create("Main")
local Table = require("__DedLib__/modules/table")

local Config = require("config")

Storage = {}

function Storage.init()
	Logger:debug("Initializing storage...")
	global.playerUiOpen = global.playerUiOpen or {} -- map or player index -> array of LuaEntity chests

	global.playerChestData = global.playerChestData or {} -- map of player index -> name of the copied chest
	global.playerSelection = global.playerSelection or {} -- map of player index -> name of the selected chest
	global.playerFastReplace = global.playerFastReplace or {} -- map of player index -> {replacementChestName=String, requestFilters, storageFilter, requestFromBufferToggle}
	global.playerFastReplaceEvents = global.playerFastReplaceEvents or {} -- map of player index -> map of absolutePosition -> tick of event
end

function Storage.purge()
	Storage.PlayerFastReplaceEvents.purge()
end

function Storage.getAbsolutePosition(surface, position)
	return surface.name .. "_" ..position.x .. "_" .. position.y
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


-- ~~ Player UI Open ~~ --
Storage.PlayerUiOpen = {}
Storage.PlayerUiOpen._LOGGER = LoggerLib.create("PlayerUiOpen")
function Storage.PlayerUiOpen.add(player, entity)
	if entity and entity.valid then
		Storage.PlayerUiOpen._LOGGER:debug("Adding %s to %s's data", entity, player)
		local chests = global.playerUiOpen[player.index] or {}
		
		if #chests == 0 or (chests[1] and chests[1].valid and chests[1].name == entity.name) then
			table.insert(chests, entity)
		else
			Storage.PlayerUiOpen._LOGGER:warn("Different generic chest was placed, not including it in normal selection")
			player.print({"Generic_Logistic_placed_warn_mismatched_chest"})
		end
		global.playerUiOpen[player.index] = chests
	end
end

function Storage.PlayerUiOpen.remove(player)
	Storage.PlayerUiOpen._LOGGER:debug("Removing player data for %s", player)
	global.playerUiOpen[player.index] = nil
end

-- Removes the entity from the first player (as only one should have it linked to them) and compacts the array
-- Returns the matching LuaPLayer if they do not have any chests left
function Storage.PlayerUiOpen.removeChest(entity)
	Storage.PlayerUiOpen._LOGGER:debug("Removing chest data for %s", entity)
	for playerIndex, chests in pairs(global.playerUiOpen) do
		local oldLength = #chests
		local newChests = Table.filter(chests, function(chest) return chest ~= entity end)
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


-- ~~ Player Copy Data ~~ --
Storage.PlayerCopyData = {}
Storage.PlayerCopyData._LOGGER = LoggerLib.create("PlayerCopyData")
function Storage.PlayerCopyData.add(player, chestName)
	Storage.PlayerCopyData._LOGGER:debug("Adding %s to %s's data", chestName, player)
	global.playerChestData[player.index] = chestName
end

function Storage.PlayerCopyData.remove(player)
	Storage.PlayerCopyData._LOGGER:debug("Removing player data for %s", player)
	global.playerChestData[player.index] = nil
end

function Storage.PlayerCopyData.get(player)
	return global.playerChestData[player.index]
end


-- ~~ Player Selection ~~ --
Storage.PlayerSelection = {}
Storage.PlayerSelection._LOGGER = LoggerLib.create("PlayerSelection")
function Storage.PlayerSelection.add(player, chestName)
	Storage.PlayerSelection._LOGGER:debug("Adding %s to %s's data", chestName, player)
	global.playerSelection[player.index] = chestName
end

function Storage.PlayerSelection.remove(player)
	Storage.PlayerSelection._LOGGER:debug("Removing player data for %s", player)
	global.playerSelection[player.index] = nil
end

function Storage.PlayerSelection.get(player)
	return global.playerSelection[player.index]
end


-- ~~ Player Fast Replace ~~ --
-- Must be kept in line with chest data for chest filters
Storage.PlayerFastReplace = {}
Storage.PlayerFastReplace._LOGGER = LoggerLib.create("PlayerFastReplace")
function Storage.PlayerFastReplace.add(player, replacementChestName, oldEntity)
	Storage.PlayerFastReplace._LOGGER:debug("Adding replacement %s for %s to %s's data", replacementChestName, oldEntity, player)
	local requestFilters = Storage._getRequestFilters(oldEntity)
	local storageFilter = Storage._getStorageFilter(oldEntity)
	local requestFromBufferToggle = Storage._getRequestFromBuffers(oldEntity)
	
	global.playerFastReplace[player.index] = {replacementChestName=replacementChestName, requestFilters=requestFilters, storageFilter=storageFilter, requestFromBufferToggle=requestFromBufferToggle}
end

function Storage.PlayerFastReplace.remove(player)
	Storage.PlayerFastReplace._LOGGER:debug("Removing player data for %s", player)
	global.playerFastReplace[player.index] = nil
end

function Storage.PlayerFastReplace.get(player)
	return global.playerFastReplace[player.index]
end


-- ~~ Player Fast Replace Events ~~ --
Storage.PlayerFastReplaceEvents = {}
Storage.PlayerFastReplaceEvents._LOGGER = LoggerLib.create("PlayerFastReplaceEvents")
function Storage.PlayerFastReplaceEvents.add(player, position)
	local absolutePosition = Storage.getAbsolutePosition(player.surface, position)
	Storage.PlayerFastReplace._LOGGER:debug("Adding event data for %s at %s (absolute: %s)", player, position, absolutePosition)

	if not global.playerFastReplaceEvents[player.index] then
		global.playerFastReplaceEvents[player.index] = {}
	end
	
	global.playerFastReplaceEvents[player.index][absolutePosition] = game.tick
end

function Storage.PlayerFastReplaceEvents.get(player, position)
	Storage.PlayerFastReplace._LOGGER:debug("Getting event data for %s at %s", player, position)
	local playerData = global.playerFastReplaceEvents[player.index]
	if playerData then
		local absolutePosition = Storage.getAbsolutePosition(player.surface, position)
		return global.playerFastReplaceEvents[player.index][absolutePosition] or game.tick
	end
	return game.tick
end

function Storage.PlayerFastReplaceEvents.purge()
	Storage.PlayerFastReplaceEvents._LOGGER:debug("Attempting to purge data...")
	local currentTick = game.tick
	local lag = Config.PLAYER_FAST_REPLACE_LAG
	for playerIndex, positions in pairs(global.playerFastReplaceEvents) do
		for pos, tick in pairs(positions) do
			if currentTick > tick + lag then
				Storage.PlayerFastReplaceEvents._LOGGER:trace("Purging player event data for %s - %s", playerIndex, pos)
				positions[pos] = nil
			end
		end
	end
end
