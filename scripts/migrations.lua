local Logger = require("__DedLib__/modules/logger").create()
local Table = require("__DedLib__/modules/table")

require("util")


Migrations = {}
Migrations.MOD_NAME = "Generic_Logistic_Chest"

function Migrations.handle(data)
	if data.mod_changes and data.mod_changes[Migrations.MOD_NAME] then
		local oldVersion = data.mod_changes[Migrations.MOD_NAME].old_version
		Logger:info("Migrating from mod version %s", oldVersion)
		if oldVersion then
			if Migrations.versionCompare(oldVersion, "0.3.0") then
				Migrations.to_0_3_0()
			end
			if Migrations.versionCompare(oldVersion, "0.4.0") then
				Migrations.to_0_4_0()
			end
			if Migrations.versionCompare(oldVersion, "0.4.3") or
				Migrations.versionCompare(oldVersion, "0.4.5") or
				Migrations.versionCompare(oldVersion, "0.4.7") then
					Storage.init()
			end
			if Migrations.versionCompare(oldVersion, "0.5.0") then
				Migrations.to_0_5_0()
			end
		end
	end
	
	if data.mod_changes or data.migration_applied then
		Migrations.unlockGenericRecipes()
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

function Migrations.unlockGenericRecipes()
	Logger:info("Unlocking generic recipes")
	local generics = ChestGroups.getGenericToReplacementMapping()
	local recipes = game.recipe_prototypes
	for _, techPrototype in pairs(game.technology_prototypes) do
		local effects = techPrototype.effects
		if effects then
			for _, modifier in ipairs(effects) do
				local recipeName = modifier.recipe
				if modifier.type == "unlock-recipe" and generics[recipeName] then
					-- Found a tech that unlocks a generic recipe
					-- Check each force and enable the recipe if it is researched
					for _, force in pairs(game.forces) do
						local recipe = force.recipes[recipeName]
						local tech = force.technologies[techPrototype.name]
						if tech and tech.researched and recipe then
							recipe.enabled = true
						end
					end
				end
			end
		end
	end
end

function Migrations.to_0_3_0()
	global.playerUiOpen = global.genericChestPlayerData
	global.chestData = Table.map(global.genericChestChestData or {}, function(data)
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
	
	Storage.init()
end

function Migrations.to_0_5_0()
	-- This actually holds ghosts and entities that are being upgraded
	for _, data in pairs(global.chestData) do
		local entity = data.ghost
		local replacementName = data.replacementChestName
		if entity and entity.valid then
			if entity.name == "entity-ghost" then
				local surface = entity.surface
				local position = entity.position
				local force = entity.force

				-- Save logistic filter data for when the replacement is built
				local requestFilters = data.requestFilters
				local storageFilter = data.storageFilter
				local requestFromBufferToggle = data.requestFromBufferToggle

				-- Save the circuit connections for the new ghost
				local connectionDefinitions = entity.circuit_connection_definitions

				-- Destroy the old ghost and create a new one
				entity.destroy()

				local newGhost = surface.create_entity{name="entity-ghost", inner_name=replacementName, position=position, force=force, request_filters=data.requestFilters}

				if storageFilter and newGhost.ghost_prototype.logistic_mode == "storage" then
					newGhost.storage_filter = storageFilter
				end

				if requestFromBufferToggle and newGhost.ghost_prototype.logistic_mode == "requester" then
					newGhost.request_from_buffers = requestFromBufferToggle
				end

				for _, connectionDefinition in pairs(connectionDefinitions) do
					newGhost.connect_neighbour(connectionDefinition)
				end
			else
				entity.cancel_upgrade(entity.force, entity.last_user)
				entity.order_upgrade{force=entity.force, target=replacementName, player=entity.last_user}
			end
		end
	end
	global.chestData = nil
end
