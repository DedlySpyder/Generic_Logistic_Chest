Util = {}

Util.MOD_PREFIX = "Generic_Logistic_"

Util.DEBUG_MODE = settings.startup["Generic_Logistic_debug_mode"].value

if Util.DEBUG_MODE then
	Util.debugLog = function(message)
		if game then
			for _, player in pairs(game.players) do
				if player and player.valid then
					player.print("[" .. game.tick .. "] " .. message)
				end
			end
		else
			log(message)
		end
	end
else
	Util.debugLog = function(m) end
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

function Util.getEntityDataKey(entity)
	local name = entity.name
	if name == "entity-ghost" then
		name = entity.ghost_name
	end
	
	return entity.surface.name .. "_" .. entity.position.x .. "_" .. entity.position.y .. "_" .. name
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
			table.insert(newTable, func(v))
		else
			newTable[k] = func(v)
		end
	end
	return newTable
end
