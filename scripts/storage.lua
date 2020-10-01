require("util")

Storage = {}

function Storage.init() -- TODO - call this and migrate
	global.playerUiOpen = global.playerUiOpen or {} -- LuaPlayer -> chest LuaEntity
	global.chestData = global.chestData or {} -- array of {ghost=LuaEntity, replacementChestName=String, requestFilters=Table of request slots}
end
--[[
global.genericChestPlayerData was array of {player=player, chest=entity}
global.genericChestChestData reanmed to global.chestData
	- {ghost=LuaEntity, position=Position, replacementChestName=String, request_filters=nil} to >> {ghost=[same], replacementChestName=[same], requestFilters=[same as request_filters]}
]]--



Storage.PlayerUiOpen = {}
function Storage.PlayerUiOpen.add(player, entity)
	global.playerUiOpen[player] = entity
end

function Storage.PlayerUiOpen.remove(player)
	global.playerUiOpen[player] = nil
end

function Storage.PlayerUiOpen.get(player)
	return global.playerUiOpen[player]
end


Storage.ChestData = {}
function Storage.ChestData.add(ghostEntity, replacementChestName, requestFilters)
	local key = Util.getEntityDataKey(ghostEntity)
	global.chestData[key] = {ghost=ghostEntity, replacementChestName=replacementChestName, requestFilters=requestFilters}
end

function Storage.ChestData.remove(entity)
	local key = Util.getEntityDataKey(entity)
	global.chestData[key] = nil
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
			Storage.ChestData.removeByKey(key)
		end
	end
end
