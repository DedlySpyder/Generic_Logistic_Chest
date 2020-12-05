Util = {}

Util.MOD_PREFIX = "Generic_Logistic_"

Util.DEBUG_MODE = settings.startup["Generic_Logistic_debug_mode"].value

Util._DEBUG_LOG_CACHE = {message="", count=0}

if Util.DEBUG_MODE then
	Util.debugLog = function(message)
		if game then
			local formattedMessage = "[" .. game.tick .. "] " .. message
			if Util._DEBUG_LOG_CACHE.message == formattedMessage then
				Util._DEBUG_LOG_CACHE.count = Util._DEBUG_LOG_CACHE.count + 1
				formattedMessage = "[" .. game.tick .. "][" .. Util._DEBUG_LOG_CACHE.count .. "] " .. message
			else
				Util._DEBUG_LOG_CACHE.message = formattedMessage
				Util._DEBUG_LOG_CACHE.count = 1
			end
			
			for _, player in pairs(game.players) do
				if player and player.valid then
					player.print(formattedMessage)
				end
			end
		else
			log(message)
		end
	end
else
	Util.debugLog = function(m) end
end

-- Only for use in the data stage
Util.dumpLogisticChests = function()
	if data and data.raw then
		log("Listing all logistic containers: ")
		for name, prototype in pairs(data.raw["logistic-container"]) do
			log("  " .. name)
			local recipe = data.raw["recipe"][name]
			if recipe and recipe.ingredients then
				log("    " .. serpent.line(recipe.ingredients))
			end
		end
	end
end


function Util.mathMin(nums)
	local t = {}
	for _, num in ipairs(nums) do
		if num ~= nil then
			table.insert(t, num)
		end
	end
	return math.min(unpack(t))
end

function Util.mathMax(nums)
	local t = {}
	for _, num in ipairs(nums) do
		if num ~= nil then
			table.insert(t, num)
		end
	end
	return math.max(unpack(t))
end

function Util.getEntityDataKey(entity)
	local name = entity.name
	if name == "entity-ghost" then
		name = entity.ghost_name
	end
	
	return entity.surface.name .. "_" .. entity.position.x .. "_" .. entity.position.y .. "_" .. name
end


Util.Player = {}
function Util.Player.isCursorEmpty(player)
	return not player.cursor_stack or not player.cursor_stack.valid_for_read
end


Util.Table = {}

-- Filter either a table or an array, if the function returns true then the value will stay
function Util.Table.filter(tbl, func)
	local newTable = {}
	local isArr = #tbl > 0
	for k, v in pairs(tbl) do
		if func(v) then
			if isArr then
				table.insert(newTable, v)
			else
				newTable[k] = v
			end
		end
	end
	return newTable
end

function Util.Table.map(tbl, func)
	local newTable = {}
	local isArr = #tbl > 0
	for k, v in pairs(tbl) do
		if isArr then
			local newValue = func(v)
			if newValue then
				table.insert(newTable, newValue)
			end
		else
			newTable[k] = func(v)
		end
	end
	return newTable
end
