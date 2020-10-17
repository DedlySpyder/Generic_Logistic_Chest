require("util")


Migrations = {}
Migrations.MOD_NAME = "Generic_Logistic_Chest"

function Migrations.handle(data)
	if data.mod_changes and data.mod_changes[Migrations.MOD_NAME] then
		local oldVersion = data.mod_changes[Migrations.MOD_NAME].old_version
		if oldVersion then
			if Migrations.versionCompare(oldVersion, "0.3.0") then
				Migrations.to_0_3_0()
			end
			if Migrations.versionCompare(oldVersion, "0.4.0") then
				Migrations.to_0_4_0()
			end
		end
	end
end

-- Returns true if oldVersion is older than newVersion
function Migrations.versionCompare(oldVersion, newVersion)
	_, _, oldMaj, oldMin, oldPat = string.find(oldVersion, "(%d+)%.(%d+)%.(%d+)")
	_, _, newMaj, newMin, newPat = string.find(newVersion, "(%d+)%.(%d+)%.(%d+)")
	
	local lt = function(o, n) return tonumber(o) < tonumber(n) end
	local gt = function(o, n) return tonumber(o) > tonumber(n) end
	
	if gt(oldMaj, newMaj) then return false
	elseif lt(oldMaj, newMaj) then return true end
	
	if gt(oldMin, newMin) then return false
	elseif lt(oldMin, newMin) then return true end
	
	if lt(oldPat, newPat) then return true end
	return false
end

function Migrations.to_0_3_0()
	global.playerUiOpen = global.genericChestPlayerData
	global.chestData = Util.Table.map(global.genericChestChestData or {}, function(data)
		local ghost = data.ghost
		if ghost and ghost.valid then
			local storageFilter = nil
			if ghost.ghost_prototype.logistic_mode == "storage" then
				storageFilter = ghost.storage_filter
			end
			
			return {ghost=ghost, replacementChestName=data.replacementChestName, requestFilters=data.request_filters, storageFilter=storageFilter}
		end
	end)
	
	Storage.init()
	Storage.ChestData.purge()
end

function Migrations.to_0_4_0()
	local newTable = {}
	for _, data in ipairs(global.playerUiOpen) do
		local player = data.player
		if player and player.valid then
			newTable[player.index] = {data.chest}
		end
	end
	global.playerUiOpen = newTable
end
