require("util")

Storage = {}

function Storage.init()
	global.playerUiOpen = global.playerUiOpen or {} -- array of {player=LuaPlayer, chest=LuaEntity}
	global.chestData = global.chestData or {} -- array of {ghost=LuaEntity, replacementChestName=String, requestFilters=Table of request slots, storageFilter=LuaItemPrototype}
end



Storage.PlayerUiOpen = {}
function Storage.PlayerUiOpen.add(player, entity)
	Storage.PlayerUiOpen.remove(player)
	
	Util.debugLog("Adding " .. entity.name .. " to " .. player.name .. "'s data")
	table.insert(global.playerUiOpen, {player=player, chest=entity})
end

function Storage.PlayerUiOpen.remove(player)
	Util.debugLog("Removing player data for  " .. player.name)
	global.playerUiOpen = Util.Table.filter(global.playerUiOpen, function(data) return data.player ~= player end)
end

-- Only returns the LuaEntity fopr that chest
function Storage.PlayerUiOpen.get(player)
	for _, data in ipairs(global.playerUiOpen) do
		if data.player == player then
			return data.chest
		end
	end
end


Storage.ChestData = {}
function Storage.ChestData.add(ghostEntity, replacementChestName, requestFilters, storageFilter)
	local key = Util.getEntityDataKey(ghostEntity)
	global.chestData[key] = {ghost=ghostEntity, replacementChestName=replacementChestName, requestFilters=requestFilters, storageFilter=storageFilter}
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
	return global.chestData[key]
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
